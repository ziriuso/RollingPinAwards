param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FilterTerms = @()
)

function Resolve-LuaRuntime {
  if ($env:RPA_LUA) {
    if (Test-Path $env:RPA_LUA) {
      return (Resolve-Path $env:RPA_LUA).Path
    }

    Write-Error "RPA_LUA points to a missing Lua runtime: $env:RPA_LUA"
    return $null
  }

  $localLua = Join-Path $PSScriptRoot "..\tools\lua\lua.exe"
  if (Test-Path $localLua) {
    return (Resolve-Path $localLua).Path
  }

  $pathLua = Get-Command lua -ErrorAction SilentlyContinue
  if ($pathLua) {
    return $pathLua.Source
  }

  return $null
}

$lua = Resolve-LuaRuntime
$filter = ($FilterTerms -join " ").Trim()
$specFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*_spec.lua" -File |
  Sort-Object -Property Name |
  ForEach-Object { "tests/$($_.Name)" }

if (-not $lua) {
  Write-Error "No Lua runtime found. Set RPA_LUA, add tools\lua\lua.exe, or install lua on PATH."
  exit 1
}

$env:RPA_TEST_FILTER = $filter
$env:RPA_TEST_SPECS = ($specFiles -join ";")
& $lua (Join-Path $PSScriptRoot "run.lua")
exit $LASTEXITCODE
