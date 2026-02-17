#!/usr/bin/env bash

set -euo pipefail

base_ref="${1:-upstream/master}"
patch_dir="${2:-patches/series}"
series_file="$patch_dir/series"

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Base ref '$base_ref' does not exist locally."
  echo "Try: git fetch upstream"
  exit 1
fi

mkdir -p "$patch_dir"

# Remove previously generated patch files to keep the directory deterministic.
rm -f "$patch_dir"/*.patch

git format-patch "$base_ref"..HEAD --output-directory "$patch_dir"

: >"$series_file"
for patch in "$patch_dir"/*.patch; do
  if [ ! -e "$patch" ]; then
    continue
  fi
  basename "$patch" >>"$series_file"
done

if [ ! -s "$series_file" ]; then
  echo "No commits found in range '$base_ref..HEAD'; no patch series generated."
  exit 0
fi

echo "Wrote patch series to '$patch_dir'."
echo "Patch count: $(wc -l <"$series_file" | tr -d ' ')"
