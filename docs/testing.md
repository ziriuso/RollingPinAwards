# Testing

The repo uses a lightweight Lua test harness under `tests/`.

## Run The Full Suite

```powershell
$env:RPA_LUA='C:\path\to\lua.exe'
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1
```

## Run A Filtered Slice

```powershell
$env:RPA_LUA='C:\path\to\lua.exe'
powershell -ExecutionPolicy Bypass -File .\tests\run.ps1 "guild member can"
```

`tests/run.ps1` looks for a runtime in this order:

1. `RPA_LUA`
2. `tools\lua\lua.exe`
3. `lua` on `PATH`

The suite exercises addon bootstrap, guild context, SavedVariables behavior, permissions, nominations, voting, awards, commands, bridge view models, sync validation, mutation broadcasts, native comm fallback, and sync diagnostics.

It also includes Ace3-aware stubs so lifecycle, AceDB profile setup, chat-command registration, serialized comm transport, and comm registration can be verified without a live WoW client.

The harness intentionally skips executing files under `Libs/` during plain Lua tests. Embedded-library presence and TOC load order are verified separately so packaging stays covered without requiring the full WoW client runtime.

Release workflow coverage lives in `tests/release_workflow_spec.lua`. It verifies the advertised TOC release version, the CurseForge workflow wiring, the package/publish scripts, and the CurseForge description document.
