#!/usr/bin/env bash

set -euo pipefail

branch_name="${1:-patches/ai-generated-commit-message}"
base_ref="${2:-upstream/master}"
patch_dir="${3:-patches/series}"

if git diff --quiet && git diff --cached --quiet; then
  echo "Working tree is clean; nothing to split into patch commits."
  exit 1
fi

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Base ref '$base_ref' not found locally."
  echo "Try: git fetch upstream"
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  echo "Branch '$branch_name' already exists; aborting."
  exit 1
fi

git checkout -b "$branch_name"
git reset

add_existing_paths() {
  local paths_to_add=()
  for path in "$@"; do
    if [ -e "$path" ]; then
      paths_to_add+=("$path")
    fi
  done

  if [ "${#paths_to_add[@]}" -gt 0 ]; then
    git add "${paths_to_add[@]}"
  fi
}

commit_group() {
  local message="$1"
  shift

  add_existing_paths "$@"
  if git diff --cached --quiet; then
    return
  fi

  git commit -m "$message"
}

commit_group "feat(config): add AI commit message configuration" \
  pkg/config/user_config.go \
  schema/config.json \
  schema-master/config.json

commit_group "feat(gui): generate commit message from external command" \
  pkg/gui/controllers/helpers/commits_helper.go \
  pkg/gui/controllers/helpers/commits_helper_test.go \
  pkg/gui/controllers/commit_message_controller.go \
  pkg/gui/controllers/commit_description_controller.go \
  pkg/gui/context/commit_message_context.go

commit_group "feat(i18n): add generate commit message strings" \
  pkg/i18n/english.go

commit_group "docs(config): document AI commit message settings" \
  docs/Config.md \
  docs-master/Config.md \
  docs-master/keybindings/Keybindings_en.md \
  docs-master/keybindings/Keybindings_ja.md \
  docs-master/keybindings/Keybindings_ko.md \
  docs-master/keybindings/Keybindings_nl.md \
  docs-master/keybindings/Keybindings_pl.md \
  docs-master/keybindings/Keybindings_pt.md \
  docs-master/keybindings/Keybindings_ru.md \
  docs-master/keybindings/Keybindings_zh-CN.md \
  docs-master/keybindings/Keybindings_zh-TW.md

commit_group "test(integration): cover AI commit message generation" \
  pkg/integration/tests/test_list.go \
  pkg/integration/tests/commit/generate_commit_message.go \
  pkg/integration/tests/commit/generate_commit_message_malformed_response.go

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Warning: uncommitted files remain after grouped commits."
  echo "They are left untouched and were not included in the patch series."
  git status --short
fi

scripts/refresh_patches.sh "$base_ref" "$patch_dir"

echo
echo "Patch branch '$branch_name' is ready and patch files were generated in '$patch_dir'."
