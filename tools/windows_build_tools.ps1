[CmdletBinding()]
param()

Set-StrictMode -Version Latest

function Get-RequiredWindowsBuildTools {
    param(
        [string]$IssPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'inno_setup_installer.iss')
    )

    if (-not (Test-Path -LiteralPath $IssPath -PathType Leaf)) {
        throw "Inno Setup script not found: $IssPath"
    }

    $content = Get-Content -LiteralPath $IssPath -Raw
    if ($content -notmatch 'vcruntime140_1\.dll' -and $content -notmatch 'msvcp140_2\.dll') {
        throw "Unable to determine Microsoft C++ runtime version from: $IssPath"
    }

    [pscustomobject]@{
        RuntimeLabel = 'Microsoft Visual C++ 2015-2022'
        ToolsetYear = '2022'
        VisualStudioVersionRange = '[17.0,18.0)'
        WingetId = 'Microsoft.VisualStudio.2022.BuildTools'
        ProductIds = @(
            'Microsoft.VisualStudio.Product.BuildTools',
            'Microsoft.VisualStudio.Product.Community',
            'Microsoft.VisualStudio.Product.Professional',
            'Microsoft.VisualStudio.Product.Enterprise'
        )
        RequiredComponents = @(
            'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
        )
        WingetOverride = '--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --norestart'
    }
}

function Assert-WindowsBuildToolsSupportedOs {
    $version = [System.Environment]::OSVersion.Version
    if ($version.Major -lt 10) {
        throw "Visual Studio Build Tools 2022 installation is supported on Windows 10 or later. Current OS version: $version"
    }
}

function Assert-PowerShellSupportedVersion {
    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw "PowerShell 5.1 or later is required. Current PowerShell version: $($PSVersionTable.PSVersion)"
    }
}

function Find-VsWhere {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $command = Get-Command vswhere.exe -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        return $command.Source
    }

    return $null
}

function Find-WindowsBuildToolsInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Requirement
    )

    $vswhere = Find-VsWhere
    if (-not $vswhere) {
        return $null
    }

    $args = @(
        '-latest',
        '-products'
    ) + $Requirement.ProductIds + @(
        '-version', $Requirement.VisualStudioVersionRange,
        '-requires'
    ) + $Requirement.RequiredComponents + @(
        '-property', 'installationPath'
    )

    $installationPath = (& $vswhere @args 2>$null | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($installationPath)) {
        return $null
    }

    $installationPath = $installationPath.Trim()
    $msBuildPath = Join-Path $installationPath 'MSBuild\Current\Bin\MSBuild.exe'
    if (-not (Test-Path -LiteralPath $msBuildPath -PathType Leaf)) {
        return $null
    }

    [pscustomobject]@{
        InstallationPath = (Resolve-Path -LiteralPath $installationPath).Path
        MSBuildPath = (Resolve-Path -LiteralPath $msBuildPath).Path
        ToolsetYear = $Requirement.ToolsetYear
    }
}

function Install-WindowsBuildTools {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Requirement
    )

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw @"
Visual Studio Build Tools $($Requirement.ToolsetYear) was not found, and winget.exe is unavailable.

Automatic installation is supported only on Windows 10/11 environments where winget is available.

Please either:
1. Run this project on a Windows 10/11 PC with winget enabled, then rerun:
   .\flutter.ps1 pub get

or

2. Manually install Visual Studio Build Tools $($Requirement.ToolsetYear) with Desktop development with C++ workload, then rerun:
   .\flutter.ps1 pub get
"@
    }

    Write-Host "[INFO] Installing Visual Studio Build Tools $($Requirement.ToolsetYear) with C++ workload..."
    & $winget.Source install --id $Requirement.WingetId --exact --source winget --accept-package-agreements --accept-source-agreements --override $Requirement.WingetOverride
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "winget failed to install $($Requirement.WingetId). ExitCode=$exitCode"
    }
}

function Use-WindowsBuildToolsInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Installation
    )

    $msBuildDir = Split-Path -Parent $Installation.MSBuildPath
    if (($env:Path -split ';') -notcontains $msBuildDir) {
        $env:Path = "$msBuildDir;$env:Path"
    }
    $env:GYP_MSVS_VERSION = $Installation.ToolsetYear
    $env:GYP_MSVS_OVERRIDE_PATH = $Installation.InstallationPath
    $env:LABEL_MANAGER_MSBUILD_PATH = $Installation.MSBuildPath
    $env:LABEL_MANAGER_VSINSTALLDIR = $Installation.InstallationPath
}

function Ensure-WindowsBuildTools {
    param(
        [string]$IssPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'inno_setup_installer.iss'),
        [bool]$InstallIfMissing = $true
    )

    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return $null
    }

    Assert-PowerShellSupportedVersion
    Assert-WindowsBuildToolsSupportedOs

    $requirement = Get-RequiredWindowsBuildTools -IssPath $IssPath
    $installation = Find-WindowsBuildToolsInstallation -Requirement $requirement
    if (-not $installation -and $InstallIfMissing) {
        Install-WindowsBuildTools -Requirement $requirement
        $installation = Find-WindowsBuildToolsInstallation -Requirement $requirement
    }

    if (-not $installation) {
        throw "Visual Studio Build Tools $($requirement.ToolsetYear) with C++ workload is not installed."
    }

    Use-WindowsBuildToolsInstallation -Installation $installation
    Write-Host "[INFO] Using MSBuild: $($installation.MSBuildPath)"
    return $installation
}