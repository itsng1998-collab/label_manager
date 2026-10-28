#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Sdk', 'Packages', 'WindowsTools', 'Windows', 'Android', 'Installer', 'iOS')][string]$Target = 'Windows',
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug',
    [switch]$SdkPathOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'build_environment.ps1')
if ($SdkPathOnly) {
    $logDir = Join-Path $projectRoot '.tmp'
    [void](New-Item $logDir -ItemType Directory -Force)
    & { $script:sdkResult = Initialize-BuildEnvironment -ProjectRoot $projectRoot -Target Sdk } *> (Join-Path $logDir 'sdk_prepare.log')
    Write-Output (Split-Path -Parent (Split-Path -Parent $script:sdkResult))
} else {
    Initialize-BuildEnvironment -ProjectRoot $projectRoot -Target $Target -Configuration $Configuration | Out-Null
}