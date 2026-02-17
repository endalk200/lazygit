#!/bin/sh

set -euo pipefail

default_base_ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo "origin/master")
base_ref="${1:-$default_base_ref}"
branch_name="${2:-update-docs-for-release}"

st=$(git status --porcelain)
if [ -n "$st" ]; then
    echo "Working directory is not clean; aborting."
    exit 1
fi

if diff -r -q docs docs-master > /dev/null && diff -r -q schema schema-master > /dev/null; then
    echo "No changes to docs or schema; nothing to do."
    exit 0
fi

if git show-ref --verify --quiet refs/heads/"$branch_name"; then
    echo "Branch '$branch_name' already exists; aborting."
    exit 1
fi

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    echo "Base ref '$base_ref' does not exist; aborting."
    exit 1
fi

git checkout -b "$branch_name" --no-track "$base_ref"

git rm -r docs schema
cp -r docs-master docs
cp -r schema-master schema
git add docs schema
git commit -m "Update docs and schema for release"

git push -u origin "$branch_name"
