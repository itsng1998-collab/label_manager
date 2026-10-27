Set-StrictMode -Version Latest

function Find-Iscc {
    param([string]$UserProvided)
    if ($UserProvided) {
        if (Test-Path -LiteralPath $UserProvided -PathType Leaf) {
            return (Resolve-Path -LiteralPath $UserProvided).Path
        }
        throw "ISCC.exe not found at user-provided path: $UserProvided"
    }
    $candidates = @(
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    return $null
}

function Install-InnoSetup {
    param([string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6'))

    $version = '6.5.4'
    $uri = "https://github.com/jrsoftware/issrc/releases/download/is-6_5_4/innosetup-$version.exe"
    $expectedHash = 'FA73BF47A4DA250D185D07561C2BFDA387E5E20DB77E4570004CF6A133CC10B1'
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("label_inno_" + [guid]::NewGuid())
    [void](New-Item -ItemType Directory -Path $tempDir)
    $installer = Join-Path $tempDir "innosetup-$version.exe"
    $protocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        Write-Host "[INFO] Inno Setup not found. Downloading official installer: version=$version"
        [Net.ServicePointManager]::SecurityProtocol = $protocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $uri -OutFile $installer -UseBasicParsing -TimeoutSec 120
        if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expectedHash) {
            throw 'Inno Setup installer SHA256 mismatch. Installation cancelled.'
        }
        Write-Host "[INFO] Installing Inno Setup for current user: $InstallDir"
        $arguments = @('/CURRENTUSER', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART',
            '/SP-', '/NOICONS', '/TASKS=', ('/DIR="{0}"' -f $InstallDir))
        $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Inno Setup installation failed. ExitCode=$($process.ExitCode)"
        }
        Write-Host '[OK] Inno Setup installation completed. Resuming packaging.'
    } finally {
        [Net.ServicePointManager]::SecurityProtocol = $protocol
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}

function Ensure-InnoSetup {
    param([string]$UserProvided)

    $compiler = Find-Iscc -UserProvided $UserProvided
    if ($compiler) { return $compiler }
    Install-InnoSetup
    $compiler = Find-Iscc
    if (-not $compiler) { throw 'Inno Setup installation finished but ISCC.exe was not found.' }
    return $compiler
}