[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TagName,
    [string]$OutputDirectory = ".\artifacts\release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ReleaseMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    if ($Tag -notmatch '^v(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z\.\-]+)?)$') {
        throw "Tag '$Tag' must look like v1.2.3, v1.2.3-beta.1, or v1.2.3-alpha.1."
    }

    $version = $Matches.version
    $normalized = $version.ToLowerInvariant()
    $releaseType = "release"
    if ($normalized.Contains("-alpha")) {
        $releaseType = "alpha"
    } elseif ($normalized.Contains("-beta")) {
        $releaseType = "beta"
    }

    [pscustomobject]@{
        Version = $version
        ReleaseType = $releaseType
        IsPrerelease = ($releaseType -ne "release")
        FileName = "RollingPinAwards-$version.zip"
        ReleaseName = "Rolling Pin Awards $Tag"
    }
}

function Set-GitHubOutputs {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Values
    )

    if (-not $env:GITHUB_OUTPUT) {
        return
    }

    foreach ($entry in $Values.GetEnumerator()) {
        "$($entry.Key)=$($entry.Value)" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$metadata = Get-ReleaseMetadata -Tag $TagName

$resolvedOutputDirectory = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
$stagingRoot = Join-Path $resolvedOutputDirectory "staging"
$packageRoot = Join-Path $stagingRoot "package"
$sourceAddonRoot = Join-Path $repoRoot "RollingPinAwards"
$packagePath = Join-Path $resolvedOutputDirectory $metadata.FileName

New-Item -ItemType Directory -Force -Path $resolvedOutputDirectory | Out-Null
if (Test-Path $stagingRoot) {
    Remove-Item -Recurse -Force $stagingRoot
}
if (-not (Test-Path $sourceAddonRoot)) {
    throw "Required addon folder 'RollingPinAwards' was not found under $repoRoot."
}
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null
Copy-Item -Recurse -Force -Path $sourceAddonRoot -Destination $packageRoot

if (Test-Path $packagePath) {
    Remove-Item -Force $packagePath
}

Compress-Archive -Path (Join-Path $packageRoot "*") -DestinationPath $packagePath -CompressionLevel Optimal

$result = [pscustomobject]@{
    tag = $TagName
    version = $metadata.Version
    releaseType = $metadata.ReleaseType
    isPrerelease = $metadata.IsPrerelease
    releaseName = $metadata.ReleaseName
    packageName = $metadata.FileName
    packagePath = $packagePath
}

Set-GitHubOutputs -Values @{
    version = $result.version
    release_type = $result.releaseType
    is_prerelease = $result.isPrerelease.ToString().ToLowerInvariant()
    release_name = $result.releaseName
    package_name = $result.packageName
    package_path = $result.packagePath
}

$result | ConvertTo-Json -Depth 4
