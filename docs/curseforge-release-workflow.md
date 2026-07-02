# CurseForge Release Workflow

Rolling Pin Awards supports tag-driven CurseForge publishing.

The published zip contains one addon folder:

- `RollingPinAwards/`

The same built zip is attached to the matching GitHub Release.

## Release Channels

The workflow derives the CurseForge release type from the git tag:

- `v1.0.1-alpha.1` -> `alpha`
- `v1.0.1-beta.1` -> `beta`
- `v1.0.1` -> `release`

Use plain semantic version tags for stable public releases.

## GitHub Actions Workflow

Workflow file:

- `.github/workflows/release-curseforge.yml`

Trigger:

- pushes to tags matching `v*`

Behavior:

1. checks out the repo
2. installs Lua on the Windows runner
3. runs `.\tests\run.ps1`
4. copies the installable `RollingPinAwards/` addon folder into a staging package
5. builds `RollingPinAwards-<version>.zip`
6. uploads that zip to CurseForge
7. creates or updates the matching GitHub Release
8. attaches the same zip to the GitHub Release

## Maintainer Release Checklist

Use this checklist when cutting a stable release.

1. Confirm the worktree is clean and current:

```powershell
cd "C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards"
git status -sb
git rev-parse --abbrev-ref HEAD
git rev-parse --short HEAD
```

2. Update release version surfaces before tagging:

- `RollingPinAwards/RollingPinAwards.toc`: update `## Version:` to the semantic version without `v`.
- `RollingPinAwards/RollingPinAwards.toc`: keep `## Interface:` aligned with supported WoW clients. For the 1.4.0 release this is `120007, 120005`.
- `tests/release_workflow_spec.lua`: update the expected version when the release version changes.
- User-facing docs that mention release behavior, usually `README.md`, `docs/testing.md`, and `docs/superpowers/handoffs/latest-handoff.md` when the current checkpoint changes.

3. Run the full release gate:

```powershell
$env:RPA_LUA=(Resolve-Path '.\tools\lua\lua54.exe').Path
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

4. Build the package locally if you want to inspect the zip before tagging:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\release\Build-CurseForgePackage.ps1 -TagName v1.4.0 -OutputDirectory .\artifacts\release
```

5. Commit and push the release-prep checkpoint:

```powershell
git add RollingPinAwards README.md docs tests .github/workflows/release-curseforge.yml tools/release
git commit -m "chore: prepare 1.4.0 curseforge release"
git push origin codex/rolling-pin-awards-mvp
```

6. Create and push the release tag when ready to publish:

```powershell
git tag v1.4.0
git push origin v1.4.0
```

7. Watch the tag-triggered workflow:

```powershell
gh run list --workflow release-curseforge.yml --limit 5
gh run watch <run-id>
```

8. Confirm the release and artifact:

```powershell
gh release view v1.4.0 --json name,tagName,isPrerelease,assets,url
```

The stable release should have `isPrerelease: false`, a `RollingPinAwards-1.4.0.zip` asset, and a successful CurseForge upload step in the workflow log.

## Required GitHub Repository Settings

### Repository secret

Create this in:

- `GitHub repo -> Settings -> Secrets and variables -> Actions -> Secrets`

Secret name:

- `CF_API_TOKEN`

This must be the CurseForge API token. Never store the token in the repository, workflow YAML, scripts, docs, commit messages, or tags.

### Repository variables

Create these in:

- `GitHub repo -> Settings -> Secrets and variables -> Actions -> Variables`

Required variable:

- `CF_PROJECT_ID`

Set it to:

- `1563031`

Optional variable:

- `CF_GAME_VERSION_IDS`

This can be a single CurseForge game version id or a comma-separated list if automatic TOC-interface resolution ever needs an override.

If `CF_GAME_VERSION_IDS` is not set, the publish script will:

1. read `## Interface:` from `RollingPinAwards/RollingPinAwards.toc`
2. convert the first interface value to a retail version string like `12.0.7`
3. query CurseForge for the matching WoW game version id
