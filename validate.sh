#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path.cwd()
errors: list[str] = []
skill_dirs = sorted(
    path.parent for path in root.glob("*/SKILL.md") if path.parent.is_dir()
)

if not skill_dirs:
    errors.append("no Skill directories containing SKILL.md were found")

def visible_markdown(text: str) -> str:
    # Code examples are not links that the documentation validator should resolve.
    text = re.sub(r"(?ms)^\s*(```|~~~).*?^\s*\1\s*$", "", text)
    return re.sub(r"`[^`]*`", "", text)

def check_local_links(file: Path, text: str) -> None:
    # Covers inline Markdown links and images; reference-style definitions are
    # also included because their destination uses the same parenthesized form.
    for match in re.finditer(r"!?\[[^\]]*\]\(([^)]+)\)", visible_markdown(text)):
        target = match.group(1).strip().split(maxsplit=1)[0].strip("<>")
        if not target or target.startswith(("https://", "http://", "mailto:", "#", "data:")):
            continue
        if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target):
            if target.startswith("file:"):
                errors.append(f"{file.relative_to(root)}: machine-local file URL: {target}")
            continue
        path_part = target.split("#", 1)[0].split("?", 1)[0]
        if not path_part:
            continue
        resolved = (file.parent / path_part).resolve()
        if not resolved.exists():
            errors.append(f"{file.relative_to(root)}: broken local link: {target}")

def check_routed_references(skill_dir: Path, file: Path, text: str) -> None:
    # Skill routers commonly render paths as inline code rather than Markdown
    # links. Validate those too, relative to the Skill root.
    for target in sorted(set(re.findall(r"(?<![\w./-])references/[A-Za-z0-9._/-]+\.md", text))):
        if not (skill_dir / target).is_file():
            errors.append(
                f"{file.relative_to(root)}: missing routed reference: {target}"
            )

for skill_dir in skill_dirs:
    skill_file = skill_dir / "SKILL.md"
    text = skill_file.read_text(encoding="utf-8")
    relative = skill_file.relative_to(root)

    if not text.startswith("---\n"):
        errors.append(f"{relative}: missing YAML frontmatter opening delimiter")
    else:
        parts = text.split("---", 2)
        if len(parts) < 3 or not parts[1].strip():
            errors.append(f"{relative}: missing or empty YAML frontmatter")
        else:
            frontmatter = parts[1]
            for field in ("name", "description"):
                if not re.search(rf"(?m)^{field}:\s*\S", frontmatter):
                    errors.append(f"{relative}: frontmatter missing non-empty '{field}'")

    for markdown in sorted(skill_dir.rglob("*.md")):
        try:
            content = markdown.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            errors.append(f"{markdown.relative_to(root)}: not valid UTF-8")
            continue
        check_local_links(markdown, content)
        check_routed_references(skill_dir, markdown, content)

    agents = skill_dir / "AGENTS.md"
    claude = skill_dir / "CLAUDE.md"
    if agents.exists() != claude.exists():
        errors.append(
            f"{skill_dir.name}: AGENTS.md and CLAUDE.md must either both exist or both be absent"
        )
    if agents.exists() and claude.exists() and agents.read_bytes() != claude.read_bytes():
        errors.append(
            f"{skill_dir.name}: AGENTS.md and CLAUDE.md differ; keep the agent instructions in sync"
        )

# Root-level project documentation should not introduce broken local links
# or machine-specific file URLs either.
for markdown in sorted(root.glob("*.md")):
    if markdown.is_file():
        check_local_links(markdown, markdown.read_text(encoding="utf-8"))

if errors:
    print(f"Validation failed ({len(errors)} issue(s)):", file=sys.stderr)
    for error in errors:
        print(f"  - {error}", file=sys.stderr)
    sys.exit(1)

print(f"Validation passed: {len(skill_dirs)} Skills; frontmatter, local links, and paired agent configs checked.")
PY
