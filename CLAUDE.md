# Sapientia — Project Instructions

## Git Workflow — OneFlow (develop + master variation)

**This is the default Git method for this repository.** Reference: https://www.endoflineblog.com/oneflow-a-git-branching-model-and-workflow#variation-develop-master

- **`main`** (master role): release history only. Every commit on `main` is a released version, tagged `x.y.z`. Never commit work directly to `main`.
- **`develop`**: the integration branch where all day-to-day work lands. Feature and release branches start from and return to `develop`.
- **Feature branches** (`feature/<name>`): used when implementing a new feature. Branch off `develop`, integrate back into `develop` (rebase or merge per feature), then delete.
- **Release branches** (`release/x.y.z`): branch off `develop` when preparing a release ("Release branches method"). Version bumps and release-only fixes happen here. When done: tag the release, merge into `main`, merge back into `develop`, then delete the branch.

Current release in progress: `release/3.0.0` (Sapientia rebrand + iOS redesign).
