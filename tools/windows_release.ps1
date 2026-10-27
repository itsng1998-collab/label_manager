Set-StrictMode -Version Latest

function Get-WindowsReleaseVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $pubspec = Get-Content -LiteralPath (Join-Path $ProjectRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\s*\r?$') {
        throw 'pubspec.yaml must contain a MAJOR.MINOR.PATCH version without a build suffix.'
    }
    return $Matches[1]
}

function Copy-WindowsReleaseRuntime {
    param(
        [Parameter(Mandatory = $true)][string]$InstallationPath,
        [Parameter(Mandatory = $true)][string]$ReleaseDir
    )

    if (-not (Test-Path -LiteralPath $ReleaseDir -PathType Container)) {
        throw "Release directory not found: $ReleaseDir"
    }
    $redistRoot = Join-Path $InstallationPath 'VC\Redist\MSVC'
    $crtDir = Get-ChildItem -LiteralPath $redistRoot -Directory |
        Where-Object { $_.Name -match '^\d+(\.\d+)+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\Microsoft.VC143.CRT' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        Select-Object -First 1
    if (-not $crtDir) { throw "Visual C++ x64 redistributable DLLs not found: $redistRoot" }
    Copy-Item -Path (Join-Path $crtDir '*.dll') -Destination $ReleaseDir -Force
    Write-Host "[INFO] Bundled Microsoft C++ x64 runtime: $crtDir"
}

function Assert-WindowsReleaseBundle {
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseDir,
        [Parameter(Mandatory = $true)][string]$Version
    )

    $requiredFiles = @(
        'label_manager.exe', 'flutter_windows.dll', 'godex_font_helper.exe',
        'data\icudtl.dat', 'data\app.so', 'data\flutter_assets\AssetManifest.bin',
        'vcruntime140.dll', 'vcruntime140_1.dll',
        'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll'
    )
    foreach ($relativePath in $requiredFiles) {
        $path = Join-Path $ReleaseDir $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-Item -LiteralPath $path).Length -eq 0) {
            throw "Release file missing or empty: $path. Run build_windows.ps1 successfully first."
        }
    }
    $exe = Get-Item -LiteralPath (Join-Path $ReleaseDir 'label_manager.exe')
    $info = $exe.VersionInfo
    $exeVersion = '{0}.{1}.{2}' -f $info.FileMajorPart, $info.FileMinorPart, $info.FileBuildPart
    if ($exeVersion -ne $Version) {
        throw "Release EXE version mismatch: exe=$exeVersion pubspec=$Version. Rerun build_windows.ps1."
    }
    $stream = [System.IO.File]::OpenRead($exe.FullName)
    $reader = New-Object System.IO.BinaryReader($stream)
    try {
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw 'Release EXE is not a PE executable.' }
        $stream.Position = 0x3C
        $stream.Position = $reader.ReadInt32()
        if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x8664) {
            throw 'Release EXE must be Windows x64 (AMD64).'
        }
    } finally {
        $reader.Dispose()
    }
    Write-Host "[OK] Release bundle validated: version=$exeVersion arch=x64"
}