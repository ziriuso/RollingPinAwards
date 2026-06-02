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

The suite exercises addon bootstrap, guild context, SavedVariables behavior, permissions, nominations, voting, awards, commands, bridge view models, and sync validation.
