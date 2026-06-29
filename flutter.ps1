[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $FlutterArgs
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CacheDir = Join-Path $ScriptRoot '.tmp'
$CacheFile = Join-Path $CacheDir 'flutter_launcher_path.txt'

function Test-IsPubGetCommand {
    param([string[]] $Arguments)

    return $Arguments.Count -ge 2 -and
        $Arguments[0] -eq 'pub' -and
        $Arguments[1] -eq 'get'
}

function Test-FlutterLauncher {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $fileName = [System.IO.Path]::GetFileName($Path).ToLowerInvariant()
    return $fileName -in @('flutter.exe', 'flutter.bat', 'flutter')
}

function Resolve-FlutterLauncher {
    if (Test-Path -LiteralPath $CacheFile -PathType Leaf) {
        $cached = (Get-Content -LiteralPath $CacheFile -Raw).Trim()
        if (Test-FlutterLauncher $cached) {
            return (Resolve-Path -LiteralPath $cached).Path
        }
    }

    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($name in @('flutter.exe', 'flutter.bat', 'flutter')) {
        $commands = Get-Command $name -All -ErrorAction SilentlyContinue
        foreach ($command in $commands) {
            if ($command.Source) {
                $candidates.Add($command.Source)
            } elseif ($command.Definition) {
                $candidates.Add($command.Definition)
            }
        }
    }

    foreach ($envName in @('FLUTTER_ROOT', 'FLUTTER_HOME')) {
        $value = [Environment]::GetEnvironmentVariable($envName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            foreach ($name in @('flutter.exe', 'flutter.bat', 'flutter')) {
                $candidates.Add((Join-Path $value "bin\$name"))
            }
        }
    }

    foreach ($root in @('C:\flutter', "$env:LOCALAPPDATA\flutter", "$env:ProgramFiles\flutter")) {
        if (-not [string]::IsNullOrWhiteSpace($root)) {
            foreach ($name in @('flutter.exe', 'flutter.bat', 'flutter')) {
                $candidates.Add((Join-Path $root "bin\$name"))
            }
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-FlutterLauncher $candidate) {
            $resolved = (Resolve-Path -LiteralPath $candidate).Path
            if (-not (Test-Path -LiteralPath $CacheDir -PathType Container)) {
                New-Item -ItemType Directory -Path $CacheDir | Out-Null
            }
            Set-Content -LiteralPath $CacheFile -Value $resolved -Encoding UTF8
            return $resolved
        }
    }

    throw 'Unable to find flutter.exe, flutter.bat, or flutter on PATH, FLUTTER_ROOT, FLUTTER_HOME, or common install paths.'
}

function Format-CommandPreview {
    param(
        [string] $Executable,
        [string[]] $Arguments
    )

    $parts = @("& `"$Executable`"")
    foreach ($argument in $Arguments) {
        $escaped = $argument.Replace('`', '``').Replace('"', '`"')
        $parts += "`"$escaped`""
    }
    return ($parts -join ' ')
}

function Get-ThirdPartyPackageDirectories {
    $thirdPartyDir = Join-Path $ScriptRoot 'third_party'
    if (-not (Test-Path -LiteralPath $thirdPartyDir -PathType Container)) {
        return @()
    }

    $packages = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    Get-ChildItem -LiteralPath $thirdPartyDir -Directory | Sort-Object Name | ForEach-Object {
        $pubspec = Join-Path $_.FullName 'pubspec.yaml'
        if (-not (Test-Path -LiteralPath $pubspec -PathType Leaf)) {
            return
        }
        $packages.Add($_)
    }
    return @($packages)
}

function Invoke-FlutterCommand {
    param(
        [string] $Executable,
        [string[]] $Arguments,
        [string] $WorkingDirectory,
        [string] $DisplayName,
        [int] $Index,
        [int] $Total
    )

    $preview = Format-CommandPreview -Executable $Executable -Arguments $Arguments
    Write-Host ""
    Write-Host "== Flutter target ${Index}/${Total}: $DisplayName =="
    Write-Host "Directory: $WorkingDirectory"
    Write-Host "Command: $preview"
    Push-Location -LiteralPath $WorkingDirectory
    try {
        & $Executable @Arguments
        $exitCode = $LASTEXITCODE
        Write-Host "== Finished $DisplayName with exit code $exitCode =="
        return $exitCode
    } finally {
        Pop-Location
    }
}

$flutter = Resolve-FlutterLauncher
if (Test-IsPubGetCommand $FlutterArgs) {
    $buildToolsScript = Join-Path $ScriptRoot 'tools\windows_build_tools.ps1'
    if (Test-Path -LiteralPath $buildToolsScript -PathType Leaf) {
        . $buildToolsScript
        Ensure-WindowsBuildTools -IssPath (Join-Path $ScriptRoot 'inno_setup_installer.iss') -InstallIfMissing $true | Out-Null
    } else {
        throw "Windows build tools helper not found: $buildToolsScript"
    }
}
$commandPreview = Format-CommandPreview -Executable $flutter -Arguments $FlutterArgs
Write-Host "Flutter launcher: $flutter"
Write-Host "Command: $commandPreview"

$firstFailure = 0
$thirdPartyPackages = @(Get-ThirdPartyPackageDirectories)
$totalTargets = $thirdPartyPackages.Count + 1
$targetIndex = 0

foreach ($package in $thirdPartyPackages) {
    $targetIndex += 1
    $displayName = "third_party\$($package.Name)"
    $exitCode = Invoke-FlutterCommand -Executable $flutter -Arguments $FlutterArgs -WorkingDirectory $package.FullName -DisplayName $displayName -Index $targetIndex -Total $totalTargets
    if ($exitCode -ne 0 -and $firstFailure -eq 0) {
        $firstFailure = $exitCode
    }
}

$targetIndex += 1
$rootExitCode = Invoke-FlutterCommand -Executable $flutter -Arguments $FlutterArgs -WorkingDirectory $ScriptRoot -DisplayName 'root' -Index $targetIndex -Total $totalTargets
if ($rootExitCode -ne 0 -and $firstFailure -eq 0) {
    $firstFailure = $rootExitCode
}

exit $firstFailure
