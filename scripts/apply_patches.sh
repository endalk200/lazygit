#!/usr/bin/env bash

set -euo pipefail

patch_dir="${1:-patches/series}"
series_file="$patch_dir/series"

if [ ! -d "$patch_dir" ]; then
  echo "Patch directory '$patch_dir' does not exist."
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean; aborting."
  echo "Commit, stash, or discard your changes before applying patches."
  exit 1
fi

patches=()
if [ -f "$series_file" ]; then
  while IFS= read -r patch_name; do
    if [ -z "$patch_name" ]; then
      continue
    fi

    patch_path="$patch_dir/$patch_name"
    if [ ! -f "$patch_path" ]; then
      echo "Patch listed in series file does not exist: $patch_path"
      exit 1
    fi
    patches+=("$patch_path")
  done <"$series_file"
else
  for patch_path in "$patch_dir"/*.patch; do
    if [ -f "$patch_path" ]; then
      patches+=("$patch_path")
    fi
  done
fi

if [ "${#patches[@]}" -eq 0 ]; then
  echo "No patches found in '$patch_dir'."
  exit 0
fi

echo "Applying ${#patches[@]} patch(es) from '$patch_dir'..."
if ! git am -3 "${patches[@]}"; then
  echo
  echo "Patch application failed."
  echo "Resolve conflicts, then run 'git am --continue'."
  echo "Or run 'git am --abort' to restore your branch."
  exit 1
fi

echo "Patch series applied successfully."
