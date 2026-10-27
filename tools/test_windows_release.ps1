[CmdletBinding()]
param([string]$IsccPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe")

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$shell = (Get-Process -Id $PID).Path
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("label_release_test_" + [guid]::NewGuid())
$utf8 = New-Object System.Text.UTF8Encoding($false)
$passed = 0

function Assert-Test {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Host "PASS: $Name"
}

function Invoke-Packaging {
    param([string]$Mode = 'ok', [switch]$NoZip)
    $ErrorActionPreference = 'Continue'
    $env:LABEL_MANAGER_TEST_ISCC = $Mode
    $arguments = @('-NoProfile', '-File', (Join-Path $temp 'inno_setup_installer.ps1'),
        '-IsccPath', (Join-Path $temp 'mock_iscc.ps1'))
    if ($NoZip) { $arguments += '-NoZip' }
    $output = & $shell @arguments 2>&1 | Out-String
    return [pscustomobject]@{ Code = $LASTEXITCODE; Output = $output }
}

try {
    [void](New-Item (Join-Path $temp 'tools') -ItemType Directory -Force)
    foreach ($relative in @('build_windows.ps1', 'flutter.ps1', 'inno_setup_installer.ps1',
        'inno_setup_installer.iss', 'tools\windows_release.ps1', 'tools\inno_setup_tools.ps1')) {
        Copy-Item (Join-Path $projectRoot $relative) (Join-Path $temp $relative)
    }
    . (Join-Path $temp 'tools\windows_release.ps1')
    [System.IO.File]::WriteAllText((Join-Path $temp 'pubspec.yaml'), "name: release_test`nversion: 1.2.3`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $temp 'version.txt'), '1.2.3', $utf8)
    $release = Join-Path $temp 'build\windows\x64\runner\Release'
    [void](New-Item (Join-Path $release 'data\flutter_assets') -ItemType Directory -Force)
    foreach ($relative in @('flutter_windows.dll', 'godex_font_helper.exe', 'data\icudtl.dat',
        'data\app.so', 'data\flutter_assets\AssetManifest.bin', 'vcruntime140.dll',
        'vcruntime140_1.dll', 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll')) {
        [System.IO.File]::WriteAllText((Join-Path $release $relative), 'fixture', $utf8)
    }
    $source = Join-Path $temp 'fixture.cs'
    [System.IO.File]::WriteAllText($source, '[assembly:System.Reflection.AssemblyFileVersion("1.2.3.0")] class Fixture { static void Main() {} }', $utf8)
    & "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe" /nologo /target:winexe /platform:x64 "/out:$release\label_manager.exe" $source
    if ($LASTEXITCODE -ne 0) { throw 'Fixture compilation failed.' }
    Assert-WindowsReleaseBundle -ReleaseDir $release -Version '1.2.3'
    Assert-Test ((Get-WindowsReleaseVersion -ProjectRoot $temp) -eq '1.2.3') 'valid x64 bundle and version'
    try { Assert-WindowsReleaseBundle -ReleaseDir $release -Version '1.2.4'; throw 'accepted mismatch' }
    catch { Assert-Test ($_.Exception.Message -like 'Release EXE version mismatch:*') 'EXE version mismatch rejected' }
    $exe = Join-Path $release 'label_manager.exe'
    $bytes = [System.IO.File]::ReadAllBytes($exe)
    $invalidBytes = $bytes.Clone()
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    $invalidBytes[$peOffset + 4] = 0x4C
    $invalidBytes[$peOffset + 5] = 0x01
    [System.IO.File]::WriteAllBytes($exe, $invalidBytes)
    try { Assert-WindowsReleaseBundle -ReleaseDir $release -Version '1.2.3'; throw 'accepted x86' }
    catch { Assert-Test ($_.Exception.Message -like 'Release EXE must be Windows x64*') 'x86 bundle rejected' }
    [System.IO.File]::WriteAllBytes($exe, $bytes)

    [System.IO.File]::WriteAllText((Join-Path $temp 'mock_iscc.ps1'), @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CompilerArgs)
$out = ($CompilerArgs | Where-Object { $_.StartsWith('/O') }).Substring(2)
$name = ($CompilerArgs | Where-Object { $_.StartsWith('/F') }).Substring(2)
Write-Output "mock compiler version=1.2.3 mode=$env:LABEL_MANAGER_TEST_ISCC"
if ($env:LABEL_MANAGER_TEST_ISCC -eq 'fail') { $global:LASTEXITCODE = 7; return }
if ($env:LABEL_MANAGER_TEST_ISCC -ne 'missing') {
    [System.IO.File]::WriteAllText((Join-Path $out "$name.exe"), 'installer fixture')
}
$global:LASTEXITCODE = 0
'@, $utf8)
    [System.IO.File]::WriteAllText((Join-Path $temp 'version.txt'), '1.0.0', $utf8)
    $result = Invoke-Packaging
    Assert-Test ($result.Code -ne 0 -and $result.Output -match 'Version mismatch') 'stale version.txt rejected'
    [System.IO.File]::WriteAllText((Join-Path $temp 'version.txt'), '1.2.3', $utf8)
    $runtimePath = Join-Path $release 'msvcp140.dll'
    Remove-Item $runtimePath
    $result = Invoke-Packaging
    Assert-Test ($result.Code -ne 0 -and $result.Output -match 'Release file missing') 'missing CRT rejected before packaging'
    [System.IO.File]::WriteAllText($runtimePath, 'fixture', $utf8)

    $result = Invoke-Packaging
    Assert-Test ($result.Code -eq 0) "packaging success ($($result.Output.Trim()))"
    $out = Join-Path $temp 'installer'
    $zip = Join-Path $out 'Setup_LabelManager_v1.2.3.zip'
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash
    Assert-Test ((Get-Content "$zip.sha256" -Raw).StartsWith($hash)) 'SHA256 retained and matches ZIP'
    Assert-Test (@(Get-ChildItem $out -Filter '*.log').Count -gt 0) 'compiler logs retained'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
    try { Assert-Test ($archive.Entries.Count -eq 1 -and $archive.Entries[0].Name -eq 'Setup_LabelManager_v1.2.3.exe') 'ZIP contains only expected installer' }
    finally { $archive.Dispose() }

    $result = Invoke-Packaging -Mode missing
    Assert-Test ($result.Code -ne 0 -and $result.Output -match 'Expected compiled EXE not found') 'old installer cannot substitute for missing output'
    $result = Invoke-Packaging -Mode fail
    Assert-Test ($result.Code -ne 0 -and $result.Output -match 'compilation failed') 'compiler failure propagates'
    Remove-Item $zip, "$zip.sha256"
    $result = Invoke-Packaging -NoZip
    Assert-Test ($result.Code -eq 0 -and -not (Test-Path $zip)) 'NoZip creates EXE only'

    $iss = Get-Content (Join-Path $temp 'inno_setup_installer.iss') -Raw
    Assert-Test ($iss -match '(?m)^AppId=\{\{A1B2C3D4-E5F6-47A8-9ABC-0123456789AB\}\r?$' -and
        $iss -match 'ArchitecturesAllowed=x64compatible' -and $iss -notmatch 'Flags:.*external') 'ISS stable AppId, architecture and embedded runtime'
    if (-not (Test-Path $IsccPath -PathType Leaf)) { throw "Inno Setup 6.3+ required for ISS validation: $IsccPath" }
    $compileOutput = & $IsccPath /Q /O- '/DAppVersion=1.2.3' (Join-Path $temp 'inno_setup_installer.iss') 2>&1 | Out-String
    Assert-Test ($LASTEXITCODE -eq 0) "real ISCC validates ISS ($($compileOutput.Trim()))"
    Remove-Item (Join-Path $release 'vcruntime140.dll')
    try {
        $ErrorActionPreference = 'Continue'
        $compileOutput = & $IsccPath /Q /O- '/DAppVersion=1.2.3' (Join-Path $temp 'inno_setup_installer.iss') 2>&1 | Out-String
        $compileExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = 'Stop'
    }
    Assert-Test ($compileExitCode -ne 0 -and $compileOutput -match 'bundle the Microsoft C\+\+ x64 runtime') 'direct ISS compilation rejects missing CRT'
    $crtDir = Join-Path $temp 'vs\VC\Redist\MSVC\14.44.35112\x64\Microsoft.VC143.CRT'
    [void](New-Item $crtDir -ItemType Directory -Force)
    foreach ($name in @('vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll')) {
        [System.IO.File]::WriteAllText((Join-Path $crtDir $name), 'runtime fixture', $utf8)
    }
    [System.IO.File]::WriteAllText((Join-Path $temp 'tools\windows_build_tools.ps1'), @'
Set-StrictMode -Version Latest
function Ensure-WindowsBuildTools {
    param([string]$IssPath, [bool]$InstallIfMissing)
    return [pscustomobject]@{ InstallationPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'vs') }
}
'@, $utf8)
    [void](New-Item (Join-Path $temp 'third_party\example') -ItemType Directory -Force)
    [System.IO.File]::WriteAllText((Join-Path $temp 'third_party\example\pubspec.yaml'), 'name: example', $utf8)
    $launcher = Join-Path $temp 'flutter.bat'
    [System.IO.File]::WriteAllText($launcher, "@echo off`r`necho args=%*`r`nexit /b 0`r`n", $utf8)
    [void](New-Item (Join-Path $temp '.tmp') -ItemType Directory -Force)
    [System.IO.File]::WriteAllText((Join-Path $temp '.tmp\flutter_launcher_path.txt'), $launcher, $utf8)
    [System.IO.File]::WriteAllText((Join-Path $temp 'version.txt'), '1.0.0', $utf8)
    $buildOutput = & $shell -NoProfile -File (Join-Path $temp 'build_windows.ps1') 2>&1 | Out-String
    Assert-Test ($LASTEXITCODE -eq 0 -and $buildOutput -match 'Flutter target 1/1: root' -and
        $buildOutput -match 'args=build windows --release' -and
        $buildOutput -notmatch 'Flutter target .*third_party') "root-only x64 Release build ($($buildOutput.Trim()))"
    Assert-Test ((Get-Content (Join-Path $temp 'version.txt') -Raw) -eq '1.2.3' -and
        (Get-Content (Join-Path $release 'vcruntime140.dll') -Raw) -eq 'runtime fixture') 'successful build copies CRT and updates version.txt'
    [System.IO.File]::WriteAllText($launcher, "@echo off`r`nexit /b 9`r`n", $utf8)
    [System.IO.File]::WriteAllText((Join-Path $temp 'version.txt'), '1.0.0', $utf8)
    $buildOutput = & $shell -NoProfile -File (Join-Path $temp 'build_windows.ps1') 2>&1 | Out-String
    Assert-Test ($LASTEXITCODE -eq 9 -and (Get-Content (Join-Path $temp 'version.txt') -Raw) -eq '1.0.0') 'build failure propagates without stamping version'
    & {
        . (Join-Path $projectRoot 'tools\inno_setup_tools.ps1')
        $script:installCalls = 0
        function Find-Iscc { param([string]$UserProvided) return 'existing-iscc' }
        function Install-InnoSetup { $script:installCalls++ }
        Assert-Test ((Ensure-InnoSetup) -eq 'existing-iscc' -and $script:installCalls -eq 0) 'existing ISCC skips installation'
        function Find-Iscc { param([string]$UserProvided) if ($script:installCalls -gt 0) { return 'installed-iscc' } }
        Assert-Test ((Ensure-InnoSetup) -eq 'installed-iscc' -and $script:installCalls -eq 1) 'missing ISCC installs once and resumes with detected compiler'
        function Find-Iscc { param([string]$UserProvided) return $null }
        try { Ensure-InnoSetup; throw 'accepted missing compiler' }
        catch { Assert-Test ($_.Exception.Message -like '*ISCC.exe was not found*') 'successful install without compiler is rejected' }
        function Install-InnoSetup { throw 'install failure fixture' }
        try { Ensure-InnoSetup; throw 'accepted install failure' }
        catch { Assert-Test ($_.Exception.Message -eq 'install failure fixture') 'installation failure stops packaging' }
    }
    & {
        . (Join-Path $projectRoot 'tools\inno_setup_tools.ps1')
        try { Ensure-InnoSetup -UserProvided (Join-Path $temp 'missing\ISCC.exe'); throw 'accepted invalid override' }
        catch { Assert-Test ($_.Exception.Message -like 'ISCC.exe not found at user-provided path:*') 'invalid explicit IsccPath does not trigger installation' }
        $script:processCalls = 0
        function Invoke-WebRequest { param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec) [System.IO.File]::WriteAllText($OutFile, 'installer fixture') }
        function Get-FileHash { param($LiteralPath, $Algorithm) return [pscustomobject]@{ Hash = 'WRONG' } }
        function Start-Process { param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) $script:processCalls++; return [pscustomobject]@{ ExitCode = 0 } }
        try { Install-InnoSetup -InstallDir (Join-Path $temp 'inno'); throw 'accepted invalid hash' }
        catch { Assert-Test ($_.Exception.Message -like '*SHA256 mismatch*' -and $script:processCalls -eq 0) 'download hash mismatch never executes installer' }
        function Get-FileHash { param($LiteralPath, $Algorithm) return [pscustomobject]@{ Hash = 'FA73BF47A4DA250D185D07561C2BFDA387E5E20DB77E4570004CF6A133CC10B1' } }
        function Start-Process {
            param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru)
            Assert-Test ($Wait -and $PassThru -and $ArgumentList -contains '/CURRENTUSER' -and
                $ArgumentList -contains '/VERYSILENT' -and $ArgumentList -contains '/NORESTART') 'automatic install is silent, current-user and waits for completion'
            return [pscustomobject]@{ ExitCode = 0 }
        }
        Install-InnoSetup -InstallDir (Join-Path $temp 'inno')
        function Start-Process { param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) return [pscustomobject]@{ ExitCode = 5 } }
        try { Install-InnoSetup -InstallDir (Join-Path $temp 'inno'); throw 'accepted failed installer' }
        catch { Assert-Test ($_.Exception.Message -like '*installation failed. ExitCode=5') 'nonzero installer exit code is rejected' }
    }
    Write-Host "SUCCESS: $passed Windows release checks passed."
} finally {
    Remove-Item Env:\LABEL_MANAGER_TEST_ISCC -ErrorAction SilentlyContinue
    if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
}