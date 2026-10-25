#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-skills-test.XXXXXX")"
trap 'rm -rf -- "$TEST_DIR"' EXIT

# Copy the working tree, including uncommitted edits, without Git metadata or
# generated archives so the regression test cannot alter the user's outputs.
find "$ROOT_DIR" -mindepth 1 -maxdepth 1 \
  ! -name '.git' ! -name '*.zip' -exec cp -R {} "$TEST_DIR/" \;
cd "$TEST_DIR"

echo "[1/4] Build all Skill archives in an isolated copy"
./build.sh

skill_count=0
for skill_dir in */; do
  [[ -f "${skill_dir}SKILL.md" ]] || continue
  skill="${skill_dir%/}"
  archive="$skill.zip"
  [[ -f "$archive" ]] || { echo "error: missing $archive" >&2; exit 1; }
  unzip -tq "$archive" >/dev/null
  unzip -Z1 "$archive" | grep -Fx "$skill/SKILL.md" >/dev/null || {
    echo "error: $archive does not contain $skill/SKILL.md" >&2
    exit 1
  }
  skill_count=$((skill_count + 1))
done

archive_count=$(find . -maxdepth 1 -type f -name '*.zip' | wc -l | tr -d ' ')
[[ "$archive_count" -eq "$skill_count" ]] || {
  echo "error: found $archive_count archives for $skill_count Skills" >&2
  exit 1
}
echo "Verified $archive_count archives for $skill_count Skills."

echo "[2/4] Save checksums before simulating a packaging failure"
shasum ./*.zip > "$TEST_DIR/archive-checksums.before"
real_zip="$(command -v zip)"
fake_bin="$TEST_DIR/fake-bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/zip" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
count_file="${ZIP_TEST_COUNT_FILE:?}"
count=0
[[ ! -f "$count_file" ]] || count="$(cat "$count_file")"
count=$((count + 1))
printf '%s\n' "$count" > "$count_file"
if [[ "$count" -eq 2 ]]; then
  echo "simulated zip failure" >&2
  exit 42
fi
exec "${ZIP_TEST_REAL_ZIP:?}" "$@"
SH
chmod +x "$fake_bin/zip"

echo "[3/4] Confirm a mid-build failure preserves existing archives"
if PATH="$fake_bin:$PATH" ZIP_TEST_REAL_ZIP="$real_zip" \
  ZIP_TEST_COUNT_FILE="$TEST_DIR/zip-call-count" ./build.sh; then
  echo "error: build unexpectedly succeeded with simulated zip failure" >&2
  exit 1
fi
shasum ./*.zip > "$TEST_DIR/archive-checksums.after"
cmp -s "$TEST_DIR/archive-checksums.before" "$TEST_DIR/archive-checksums.after" || {
  echo "error: failed build modified one or more existing archives" >&2
  diff -u "$TEST_DIR/archive-checksums.before" "$TEST_DIR/archive-checksums.after" || true
  exit 1
}

echo "[4/4] Run repository validation after the failure case"
./validate.sh
echo "Build regression tests passed."
