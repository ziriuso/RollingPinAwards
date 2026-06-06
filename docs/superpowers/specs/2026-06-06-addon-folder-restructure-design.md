# Addon Folder Restructure Design

## Intent

Move the installable WoW addon into one `RollingPinAwards/` folder so repository infrastructure does not get mixed with runtime addon files. This keeps tests, tools, docs, GitHub workflows, and generated artifacts clearly outside the package that WoW and CurseForge consume.

## Layout

The repository root owns project infrastructure:

- `.github/`
- `docs/`
- `tests/`
- `tools/`
- `README.md`
- `LICENSE`

The `RollingPinAwards/` folder owns the installable addon payload:

- `RollingPinAwards/RollingPinAwards.toc`
- `RollingPinAwards/Bootstrap.lua`
- `RollingPinAwards/Core/`
- `RollingPinAwards/Data/`
- `RollingPinAwards/Domain/`
- `RollingPinAwards/Libs/`
- `RollingPinAwards/Media/`
- `RollingPinAwards/Sync/`
- `RollingPinAwards/UI/`

TOC entries remain relative to the addon folder, for example `Core/Events.lua` and `UI/MainFrame.lua`. In-game media paths also remain `Interface\AddOns\RollingPinAwards\...` because the installed addon folder name does not change.

## Tooling

Tests use a shared helper to resolve addon runtime paths from the repo root. The WoW stub loader reads `RollingPinAwards/RollingPinAwards.toc` and executes TOC entries relative to `RollingPinAwards/`, matching how WoW loads files from an installed addon folder.

The CurseForge package builder copies the `RollingPinAwards/` folder directly into the release zip. It no longer assembles a package from root-level runtime folders, which prevents root infrastructure from being mistaken for addon payload.

## Verification

The release workflow, package script, TOC tests, media tests, and full Lua suite must pass after the move. A local package build should produce a zip with a single top-level `RollingPinAwards/` folder containing the TOC and runtime folders.
