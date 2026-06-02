# Rolling Pin Awards Handoff

## Repo
- Path: `C:\Users\Ziri\OneDrive - ShipWreckCove\Documents\RollingPinAwards`
- Branch: `codex/rolling-pin-awards-mvp`

## Current State
- UI polish pass is largely implemented and deployed locally to both Retail and PTR.
- Custom media icons are wired in under `Media/`.
- Burnt and Golden rolling pin award types are implemented across direct awards, nominations, history, dashboard, and leaderboard.
- Leaderboard supports `Burnt`, `Golden`, and `Combined` modes.
- Alias merge management was moved to an admin modal.
- Test suite is green.

## Priority Blocker
- Live WoW client still shows the decorative parchment or shade layer over tab contents.
- This is the top-priority next task.
- Local tests currently prove:
  - `contentHost` exists
  - `contentHost` clips children
  - `contentHost` frame level is above `innerShade`
  - `innerShade` is on `BACKGROUND` strata
- Despite that, the real client still renders the brown overlay above content.

## Most Relevant Files
- `UI/Components.lua`
- `UI/MainFrame.lua`
- `UI/Styles.lua`
- `tests/WoWStubs.lua`
- `tests/bridge_spec.lua`

## Likely Next Investigation
1. Re-check the live content panel composition in `UI/Components.lua`, especially `CreateContentPanel`.
2. Consider replacing `innerShade` from a child `Frame` with a background `Texture`, since sibling `Frame` ordering appears unreliable in live WoW here.
3. If needed, move decorative treatment onto the panel backdrop itself and keep all interactive content inside a clean child host with no sibling shade frame.
4. Re-test in game after every layering tweak; this issue is reproducing live despite the harness being green.

## Verification
- Full suite command:
  - `powershell -ExecutionPolicy Bypass -File .\tests\run.ps1`
- Last known result before handoff:
  - full suite passed

## Local Deploy Targets
- Retail:
  - `C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\RollingPinAwards`
- PTR:
  - `C:\Gaming\World of Warcraft\_xptr_\Interface\AddOns\RollingPinAwards`

## Untracked Local-Only Items Left Alone
- `.figma-make-inspect/`
- `.research/`

## Resume Order
1. Read this handoff.
2. Inspect `UI/Components.lua` and the latest `CreateContentPanel` layering fix.
3. Run the full test suite.
4. Fix the live overlay bug in game.
5. Only after that, continue any remaining UI polish cleanup.
