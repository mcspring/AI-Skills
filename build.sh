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

shopt -s nullglob
skills=()
for dir in */; do
  [[ -f "${dir}SKILL.md" ]] && skills+=("${dir%/}")
done

if ((${#skills[@]} == 0)); then
  echo "error: no Skill directories containing SKILL.md were found" >&2
  exit 1
fi

for skill in "${skills[@]}"; do
  archive="${skill}.zip"
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai-skills-build.XXXXXX")"
  temp_archive="$temp_dir/$archive"
  trap 'rm -rf -- "${temp_dir:-}"' EXIT

  if ! zip -q -r "$temp_archive" "$skill"; then
    echo "error: failed to package $skill" >&2
    exit 1
  fi
  mv -f -- "$temp_archive" "$archive"
  rm -rf -- "$temp_dir"
  temp_dir=""
  trap - EXIT
  echo "Built $archive"
done
