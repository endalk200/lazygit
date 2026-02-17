# Patch Maintenance

This directory stores the custom patch queue that is replayed on top of `upstream/master`.

## Layout

- `series/` contains `git format-patch` outputs.
- `series/series` pins patch application order.

## Common tasks

1. Bootstrap grouped commits and generate patches from your current working tree:
   - `scripts/bootstrap_patch_branch.sh`
2. Regenerate patch files after editing commits on your patch branch:
   - `scripts/refresh_patches.sh`
3. Apply the patch queue onto a fresh upstream sync branch:
   - `scripts/apply_patches.sh`

If patch application fails, resolve conflicts and run `git am --continue`, or abort with `git am --abort`.
