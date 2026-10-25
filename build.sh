#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# Never publish archives from a tree that fails the repository checks.
./validate.sh

command -v zip >/dev/null 2>&1 || {
  echo "error: 'zip' is required to build Skill archives" >&2
  exit 1
}
command -v unzip >/dev/null 2>&1 || {
  echo "error: 'unzip' is required to verify Skill archives" >&2
  exit 1
}

shopt -s nullglob
skills=()
for dir in */; do
  [[ -f "${dir}SKILL.md" ]] && skills+=("${dir%/}")
done

if ((${#skills[@]} == 0)); then
  echo "error: no Skill directories containing SKILL.md were found" >&2
  exit 1
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai-skills-build.XXXXXX")"
trap 'rm -rf -- "$temp_dir"' EXIT
staging_dir="$temp_dir/staged"
mkdir -p "$staging_dir"

# Build and verify every archive before replacing any existing release files.
for skill in "${skills[@]}"; do
  archive="${skill}.zip"
  temp_archive="$staging_dir/$archive"

  if ! zip -q -r "$temp_archive" "$skill"; then
    echo "error: failed to package $skill" >&2
    exit 1
  fi
  if ! unzip -tq "$temp_archive" >/dev/null; then
    echo "error: archive verification failed for $skill" >&2
    exit 1
  fi
  if ! unzip -Z1 "$temp_archive" | grep -Fx "$skill/SKILL.md" >/dev/null; then
    echo "error: archive is missing $skill/SKILL.md" >&2
    exit 1
  fi
done

for skill in "${skills[@]}"; do
  archive="${skill}.zip"
  mv -f -- "$staging_dir/$archive" "$archive"
  echo "Built and verified $archive"
done
