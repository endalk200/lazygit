# Patch Maintenance Runbook

This runbook defines how to keep the fork aligned with upstream while preserving custom features as a patch queue.

## One-time setup

1. Ensure remotes are configured:
   - `origin`: `endalk200/lazygit`
   - `upstream`: `jesseduffield/lazygit`
2. Enable rerere so recurring conflicts are auto-resolved after the first manual fix:
   - `git config --global rerere.enabled true`
   - `git config --global rerere.autoupdate true`

## Patch queue structure

- Patch files live in `patches/series/`.
- Patch order is defined in `patches/series/series`.
- Scripts:
  - `scripts/bootstrap_patch_branch.sh`
  - `scripts/refresh_patches.sh`
  - `scripts/apply_patches.sh`

## Bootstrap the first patch branch

If your feature exists as uncommitted changes, run:

```bash
scripts/bootstrap_patch_branch.sh
```

The script:

- creates `patches/ai-generated-commit-message`
- groups commits by logical area
- generates `git format-patch` files into `patches/series/`

## Routine upstream sync

1. Fetch upstream:
   - `git fetch upstream`
2. Create sync branch from upstream:
   - `git checkout -b sync/upstream-$(date +%Y%m%d)-$(git rev-parse --short upstream/master) upstream/master`
3. Apply patch queue:
   - `scripts/apply_patches.sh`
4. Validate:
   - `go test ./... -short`
   - `go run cmd/integration_test/main.go cli GenerateCommitMessage GenerateCommitMessageMalformedResponse`
5. Push branch and open PR to `origin/master`.

You can also rely on `.github/workflows/sync-upstream.yml` for the automated version of this flow.

## Refresh patches after edits

When you change custom commits on your patch branch:

```bash
scripts/refresh_patches.sh
```

This rewrites patch files and updates `patches/series/series`.

## Release checklist

1. Confirm patch queue applies cleanly to latest upstream.
2. Confirm docs/schema consistency:
   - `diff -r -q docs docs-master`
   - `diff -r -q schema schema-master`
3. Run targeted validations:
   - `go test ./... -short`
   - `go run cmd/integration_test/main.go cli GenerateCommitMessage GenerateCommitMessageMalformedResponse`
4. Create release tag using fork scheme:
   - `vX.Y.Z-endalk.N`
5. Run release workflow (`.github/workflows/release.yml`) and verify:
   - all expected assets are present
   - `checksums.txt` is uploaded
6. Confirm tap update workflow opened a formula PR in `endalk200/homebrew`.

## Rollback and recovery

If release binaries are broken:

1. Cut a new patch release tag with incremented suffix (do not reuse tag):
   - `vX.Y.Z-endalk.(N+1)`
2. Re-run release workflow for the fixed tag.
3. Close superseded tap PR and merge the new one.

If patch application fails:

1. Resolve conflicts.
2. Continue: `git am --continue`
3. Or abort: `git am --abort`
4. After successful resolution, regenerate patches:
   - `scripts/refresh_patches.sh`

If tap update produced a bad formula PR:

1. Close or revert the PR in `endalk200/homebrew`.
2. Re-run the updater workflow with the corrected release tag.

## Health checks

- `sync-upstream.yml` runs on a schedule to detect drift and conflicts early.
- `update-homebrew-tap.yml` updates formulae when new fork releases are published.
- If either workflow fails, inspect logs and fix before cutting the next release.
