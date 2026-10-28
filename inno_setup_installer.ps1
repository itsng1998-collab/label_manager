#Requires -Version 5.1
<#
  inno_setup_installer.ps1
  - Resolve-Path로 안전 실행(Method A)
  - /Qp -> /Q -> (없음) 자동 폴백
  - ISCC 출력 로그는 Tee-Object로 캡처(/L 미지원 대응)
    - Release 버전/필수 파일 확인, 컴파일 로그 및 SHA256 보존
#>

[CmdletBinding()]
param(
    [string]$IssFile     = 'inno_setup_installer.iss',
    [string]$VersionFile = 'version.txt',
    [string]$OutputDir   = 'installer',
    [string]$IsccPath,
    [switch]$NoZip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----- 변수 선제 초기화 (StrictMode 안정) -----
$ISCC    = $null
$absIss  = $null
$absOut  = $null
$logPath = $null
$exePath = $null
$zipPath = $null
$shaPath = $null

# ----- 1) 작업 디렉터리 이동 -----
if ($PSScriptRoot) {
    Set-Location -Path $PSScriptRoot
    $scriptDir = $PSScriptRoot
} else {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location -Path $scriptDir
}

# ----- Helpers -----
function Get-FirstNonEmptyLine {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "File not found: $Path" }
    $line = Get-Content -LiteralPath $Path | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1
    if (-not $line) { throw "No non-empty line in $Path" }
    return $line.Trim()
}

function Resolve-ProjectPath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path $scriptDir $Path
}

# ----- 2) 버전/파일명 확정 -----
. (Join-Path $scriptDir 'tools\windows_release.ps1')
$XAPP_VERSION = Get-WindowsReleaseVersion -ProjectRoot $scriptDir
$versionPath = Resolve-ProjectPath $VersionFile
if (Test-Path -LiteralPath $versionPath) {
    $builtVersion = Get-FirstNonEmptyLine -Path $versionPath
    if ($builtVersion -ne $XAPP_VERSION) {
        throw "Version mismatch: version.txt=$builtVersion pubspec=$XAPP_VERSION. Rerun build_windows.ps1."
    }
} else {
    throw "Build version file not found: $versionPath. Run build_windows.ps1 successfully first."
}
Assert-WindowsReleaseBundle -ReleaseDir (Join-Path $scriptDir 'build\windows\x64\runner\Release') -Version $XAPP_VERSION
$baseName     = "Setup_LabelManager_v$XAPP_VERSION"
Write-Host "[INFO] Loaded version: $XAPP_VERSION"
Write-Host "[INFO] Output base name: $baseName"

# ----- 3) ISCC 경로 확정 -----
try {
    if ($IsccPath) {
        . (Join-Path $scriptDir 'tools\inno_setup_tools.ps1')
        $resolved = Ensure-InnoSetup -UserProvided $IsccPath
    } else {
        . (Join-Path $scriptDir 'tools\build_environment.ps1')
        $resolved = Initialize-BuildEnvironment -ProjectRoot $scriptDir -Target Installer
    }
    $ISCC     = (Resolve-Path -LiteralPath $resolved).Path
} catch {
    Write-Error "ISCC.exe not found or not accessible. $($_.Exception.Message)"
    exit 1
}
if (-not (Test-Path -LiteralPath $ISCC)) { Write-Error "ISCC path invalid: $ISCC"; exit 1 }
Write-Host "[INFO] ISCC: $ISCC"

# ----- 4) .ISS 경로 확정 -----
if ([string]::IsNullOrWhiteSpace($IssFile)) { Write-Error "IssFile is empty."; exit 1 }
$issPathCandidate = Resolve-ProjectPath $IssFile
if (-not (Test-Path -LiteralPath $issPathCandidate)) {
    Write-Error "ISS file not found: $issPathCandidate"
    exit 1
}
$absIss = (Resolve-Path -LiteralPath $issPathCandidate).Path
Write-Host "[INFO] ISS: $absIss"

# ----- 5) 출력 폴더/로그 경로 준비 -----
$absOut = Resolve-ProjectPath $OutputDir
if (-not (Test-Path -LiteralPath $absOut)) { New-Item -ItemType Directory -Path $absOut | Out-Null }
$absOut  = (Resolve-Path -LiteralPath $absOut).Path
$logPath = Join-Path $absOut "build_$($XAPP_VERSION)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
"=== ISCC Compile Log === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -LiteralPath $logPath -Encoding UTF8

# ----- 6) 컴파일 (조용 옵션 폴백 + 로그 캡처) -----
$commonArgs = @("/O$absOut", "/F$baseName", "/DAppVersion=$XAPP_VERSION", $absIss)
$quietCandidates  = @('/Qp', '/Q', '')
$compileSucceeded = $false
$exitCode         = 1

Write-Host "[INFO] Compiling..."
$exePath = Join-Path $absOut "$baseName.exe"
if (Test-Path -LiteralPath $exePath) { Remove-Item -LiteralPath $exePath -Force }
foreach ($q in $quietCandidates) {
    $compilerArgs = @()
    if ($q) { $compilerArgs += $q }
    $compilerArgs += $commonArgs

    Add-Content -LiteralPath $logPath -Value "`n--- Attempt with quiet flag: '$q' ---"
    $compileOutput = & $ISCC @compilerArgs 2>&1 | Tee-Object -FilePath $logPath -Append
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) { $compileSucceeded = $true; break }

    $outText = ($compileOutput | Out-String)
    if ($outText -match 'Unknown option') { continue } else { break }
}
if (-not $compileSucceeded) {
    Write-Error "Inno Setup compilation failed. ExitCode=$exitCode (see log: $logPath)"
    exit $exitCode
}
Write-Host "[OK] Compile success."

# ----- 7) 산출물 확인 -----
$exePath = Join-Path $absOut "$baseName.exe"
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf) -or
    (Get-Item -LiteralPath $exePath).Length -eq 0) {
    throw "Expected compiled EXE not found or empty: $exePath (see log: $logPath)"
}
Write-Host "[INFO] EXE: $exePath"

# ----- 8) ZIP 압축 (+ SHA256) -----
if (-not $NoZip) {
    try {
        $zipPath = [System.IO.Path]::ChangeExtension($exePath, '.zip')
        Write-Host "[INFO] Create ZIP archive: $zipPath"
        if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
        Compress-Archive -LiteralPath $exePath -DestinationPath $zipPath -Force
        Write-Host "[OK] ZIP created."

        $fileHash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
        if ($null -eq $fileHash) { throw "Get-FileHash returned null." }
        $shaPath = "$zipPath.sha256"
        "$($fileHash.Hash)  $(Split-Path $zipPath -Leaf)" | Out-File -LiteralPath $shaPath -Encoding ASCII
        Write-Host "[OK] SHA256: $shaPath"
    } catch {
        Write-Error "Packaging failed: $($_.Exception.Message)"
        exit 1
    }
}

# ----- 9) 재현 및 배포 무결성 확인을 위해 로그/해시 보존 -----
Write-Host "[INFO] Compile log retained: $logPath"

Write-Host "[DONE] Build pipeline completed successfully."
exit 0
