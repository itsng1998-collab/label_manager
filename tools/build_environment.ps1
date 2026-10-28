#Requires -Version 5.1
Set-StrictMode -Version 3.0

function Invoke-BuildTool {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [string[]]$Arguments = @()
    )

    & $Executable @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Build prerequisite command failed: $Executable $($Arguments -join ' ') (exit=$LASTEXITCODE)"
    }
}

function Add-BuildToolPath {
    param([Parameter(Mandatory = $true)][string]$Directory)

    if (($env:Path -split ';') -notcontains $Directory) {
        $env:Path = "$Directory;$env:Path"
    }
}

function Get-BuildUserPath {
    return [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Set-BuildUserPath {
    param([string]$Value)

    [Environment]::SetEnvironmentVariable('Path', $Value, 'User')
}

function Register-FlutterUserPath {
    param([string]$Directory)

    $userPath = [string](Get-BuildUserPath)
    $entries = @($userPath -split ';' | ForEach-Object {
        [Environment]::ExpandEnvironmentVariables($_.Trim()).TrimEnd('\')
    })
    if ($entries -notcontains $Directory.TrimEnd('\')) {
        $updatedPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $Directory } else { "$userPath;$Directory" }
        Set-BuildUserPath $updatedPath
        Write-Host "[SETUP] Registered Flutter in user PATH: $Directory"
    } else {
        Write-Host "[READY] Flutter already registered in user PATH: $Directory"
    }
}

function Find-BuildTool {
    param([string]$Name, [string[]]$Candidates = @())

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command -and $command.Source) { return $command.Source }
    return $null
}

function Test-WindowsSdk {
    param([string]$KitsRoot = "${env:ProgramFiles(x86)}\Windows Kits\10")

    $includeRoot = Join-Path $KitsRoot 'Include'
    if (-not (Test-Path -LiteralPath $includeRoot -PathType Container)) { return $false }
    foreach ($directory in Get-ChildItem -LiteralPath $includeRoot -Directory) {
        if ($directory.Name -notmatch '^10\.0\.\d+\.0$') { continue }
        if ([version]$directory.Name -lt [version]'10.0.17763.0') { continue }
        $version = $directory.Name
        if ((Test-Path (Join-Path $directory.FullName 'um\Windows.h')) -and
            (Test-Path (Join-Path $KitsRoot "Lib\$version\um\x64\kernel32.lib")) -and
            (Test-Path (Join-Path $KitsRoot "bin\$version\x64\rc.exe"))) { return $true }
    }
    return $false
}

function Save-BuildDownload {
    param([string]$Uri, [string]$Path, [string]$Hash, [string]$Algorithm = 'SHA256')

    $protocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $protocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Uri -OutFile $Path -UseBasicParsing -TimeoutSec 600
        if ((Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash -ne $Hash) {
            throw "Downloaded build prerequisite checksum mismatch: $Uri"
        }
    } finally {
        [Net.ServicePointManager]::SecurityProtocol = $protocol
    }
}

function Read-BuildMetadata {
    param([string]$Uri, [switch]$Xml)

    $protocol = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $protocol -bor [Net.SecurityProtocolType]::Tls12
        if ($Xml) { return [xml](Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 120).Content }
        return Invoke-RestMethod -Uri $Uri -TimeoutSec 120
    } finally {
        [Net.ServicePointManager]::SecurityProtocol = $protocol
    }
}

function Initialize-BuildGit {
    $git = Find-BuildTool 'git.exe' @("$env:LOCALAPPDATA\Programs\Git\cmd\git.exe", "$env:ProgramFiles\Git\cmd\git.exe")
    if (-not $git) {
        $winget = Find-BuildTool 'winget.exe'
        if (-not $winget) { throw 'Git is missing. Install Git for Windows or App Installer (winget), then rerun the task.' }
        Invoke-BuildTool $winget @('install', '--id', 'Git.Git', '--exact', '--scope', 'user', '--silent',
            '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        $git = Find-BuildTool 'git.exe' @("$env:LOCALAPPDATA\Programs\Git\cmd\git.exe", "$env:ProgramFiles\Git\cmd\git.exe")
    }
    if (-not $git) { throw 'Git installation completed but git.exe was not found.' }
    Add-BuildToolPath (Split-Path -Parent $git)
}

function Initialize-FlutterSdk {
    param([string]$ProjectRoot)

    Initialize-BuildGit
    $cache = Join-Path $ProjectRoot '.tmp\flutter_launcher_path.txt'
    $programs = Join-Path $env:LOCALAPPDATA 'Programs'
    $userFlutter = Join-Path $programs 'Flutter\bin\flutter.bat'
    $candidates = @("$ProjectRoot\.tmp\toolchains\flutter\bin\flutter.bat", 'C:\Flutter\bin\flutter.bat')
    if (Test-Path $cache) { $candidates = @((Get-Content $cache -Raw).Trim()) + $candidates }
    foreach ($name in @('FLUTTER_ROOT', 'FLUTTER_HOME')) {
        $root = [Environment]::GetEnvironmentVariable($name)
        if ($root) { $candidates = @((Join-Path $root 'bin\flutter.bat')) + $candidates }
    }
    $candidates = @($userFlutter, "$ProjectRoot\.tmp\toolchains\flutter\bin\flutter.bat") + $candidates
    $flutter = Find-BuildTool 'flutter.bat' $candidates
    $minimumDart = $null
    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    if ((Test-Path $pubspecPath) -and (Get-Content $pubspecPath -Raw) -match '(?m)^\s+sdk:\s*\^([\d.]+)\s*$') {
        $minimumDart = [version]$Matches[1]
    }
    if ($flutter -and $minimumDart) {
        $dartVersionFile = Join-Path (Split-Path -Parent $flutter) 'cache\dart-sdk\version'
        if (Test-Path $dartVersionFile) {
            $dartVersion = (Get-Content $dartVersionFile -Raw).Trim().Split('-')[0]
            if ([version]$dartVersion -lt $minimumDart) {
                Write-Host "[SETUP] Existing Flutter Dart $dartVersion is below required $minimumDart; installing SDK at $userFlutter."
                $flutter = $null
            }
        }
    }
    if (-not $flutter) {
        Write-Host "[SETUP] Flutter SDK missing or outdated; downloading official stable SDK to $userFlutter."
        $metadata = Read-BuildMetadata 'https://storage.googleapis.com/flutter_infra_release/flutter/releases/releases_windows.json'
        $release = $metadata.releases | Where-Object { $_.hash -eq $metadata.current_release.stable -and $_.dart_sdk_arch -eq 'x64' } | Select-Object -First 1
        if (-not $release) { throw 'Official Flutter stable x64 SDK metadata was not found.' }
        [void](New-Item $programs -ItemType Directory -Force)
        $archive = Join-Path $programs 'flutter.zip'
        try {
            Save-BuildDownload "$($metadata.base_url)/$($release.archive)" $archive $release.sha256
            Expand-Archive -LiteralPath $archive -DestinationPath $programs -Force
        } finally { Remove-Item $archive -Force -ErrorAction SilentlyContinue }
        $flutter = $userFlutter
        Invoke-BuildTool $flutter @('--version')
    }
    Add-BuildToolPath (Split-Path -Parent $flutter)
    Register-FlutterUserPath (Split-Path -Parent $flutter)
    [void](New-Item (Split-Path -Parent $cache) -ItemType Directory -Force)
    [System.IO.File]::WriteAllText($cache, $flutter)
    Write-Host "[READY] Flutter: $flutter"
    return $flutter
}

function Initialize-WindowsToolchain {
    param([string]$ProjectRoot)

    Initialize-BuildGit
    . (Join-Path $ProjectRoot 'tools\windows_build_tools.ps1')
    $installation = Ensure-WindowsBuildTools -IssPath (Join-Path $ProjectRoot 'inno_setup_installer.iss')
    if (-not (Test-WindowsSdk)) {
        Install-WindowsBuildTools -Requirement (Get-RequiredWindowsBuildTools -IssPath (Join-Path $ProjectRoot 'inno_setup_installer.iss'))
        if (-not (Test-WindowsSdk)) { throw 'Windows SDK is still missing after installation. Restart Windows if requested, then rerun the task.' }
    }
    $cmake = Find-BuildTool 'cmake.exe' @((Join-Path $installation.InstallationPath 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'))
    if (-not $cmake) { throw 'CMake is missing from Visual Studio. Install the C++ CMake tools component, then rerun the task.' }
    Add-BuildToolPath (Split-Path -Parent $cmake)
    $env:LABEL_MANAGER_CMAKE_PATH = $cmake
    $env:CMAKE_GENERATOR = 'Visual Studio 17 2022'
    Write-Host "[READY] Windows SDK and CMake: $cmake"
}

function Initialize-BuildPackages {
    param([string]$ProjectRoot, [string]$Flutter)

    $directories = @(Get-ChildItem (Join-Path $ProjectRoot 'third_party') -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'pubspec.yaml') } | ForEach-Object { $_.FullName }) + @($ProjectRoot)
    foreach ($directory in $directories) {
        Push-Location $directory
        try {
            Invoke-BuildTool $Flutter @('pub', 'get')
        } finally { Pop-Location }
    }
}

function Set-BuildToolJunction {
    param([string]$Link, [string]$Target)

    if ([System.IO.Path]::GetFullPath($Link) -eq [System.IO.Path]::GetFullPath($Target)) { return }
    if (Test-Path -LiteralPath $Link) { return }
    [void](New-Item (Split-Path -Parent $Link) -ItemType Directory -Force)
    [void](New-Item -ItemType Junction -Path $Link -Target $Target)
}

function Initialize-AndroidToolchain {
    param([string]$ProjectRoot, [string]$Flutter)

    $toolchains = Join-Path $ProjectRoot '.tmp\toolchains'
    [void](New-Item $toolchains -ItemType Directory -Force)
    $java = Find-BuildTool 'java.exe' @("$toolchains\jdk\bin\java.exe", "$env:JAVA_HOME\bin\java.exe", "$env:ProgramFiles\Android\Android Studio\jbr\bin\java.exe")
    if (-not $java) {
        $java = $null
    } else {
        $releaseFile = Join-Path (Split-Path -Parent (Split-Path -Parent $java)) 'release'
        if ((Test-Path $releaseFile) -and (Get-Content $releaseFile -Raw) -match 'JAVA_VERSION="(\d+)') {
            if ([int]$Matches[1] -lt 17) { $java = $null }
        } else { $java = $null }
    }
    if (-not $java) {
        Write-Host '[SETUP] JDK missing; downloading Eclipse Temurin 17.'
        $assets = Read-BuildMetadata 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows'
        $package = $assets[0].binary.package
        $archive = Join-Path $toolchains 'jdk.zip'
        $staging = Join-Path $toolchains 'jdk-download'
        try {
            Save-BuildDownload $package.link $archive $package.checksum
            Expand-Archive $archive $staging -Force
            $extracted = Get-ChildItem $staging -Directory | Select-Object -First 1
            Move-Item $extracted.FullName (Join-Path $toolchains 'jdk')
        } finally {
            Remove-Item $archive, $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
        $java = Join-Path $toolchains 'jdk\bin\java.exe'
    }
    $env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $java)
    Set-BuildToolJunction (Join-Path $toolchains 'jdk') $env:JAVA_HOME
    Add-BuildToolPath (Split-Path -Parent $java)
    $sdk = $env:ANDROID_HOME
    if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
    if (-not $sdk) {
        $adb = Find-BuildTool 'adb.exe'
        if ($adb) { $sdk = Split-Path -Parent (Split-Path -Parent $adb) }
    }
    if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    [void](New-Item $sdk -ItemType Directory -Force)
    $env:ANDROID_HOME = $sdk
    $env:ANDROID_SDK_ROOT = $sdk
    Set-BuildToolJunction (Join-Path $toolchains 'android-sdk') $sdk
    $manager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
    if (-not (Test-Path $manager)) {
        Write-Host '[SETUP] Android command-line tools missing; downloading from Google.'
        [xml]$repository = Read-BuildMetadata 'https://dl.google.com/android/repository/repository2-1.xml' -Xml
        $archiveNode = $repository.SelectSingleNode("//*[local-name()='remotePackage' and @path='cmdline-tools;latest']//*[local-name()='archive'][*[local-name()='host-os']='windows']/*[local-name()='complete']")
        if (-not $archiveNode) { throw 'Google Android command-line tools metadata was not found.' }
        $archive = Join-Path $toolchains 'android-tools.zip'
        $staging = Join-Path $toolchains 'android-tools-download'
        try {
            $checksum = $archiveNode.SelectSingleNode("*[local-name()='checksum']").InnerText.Trim()
            $url = $archiveNode.SelectSingleNode("*[local-name()='url']").InnerText.Trim()
            Save-BuildDownload "https://dl.google.com/android/repository/$url" $archive $checksum 'SHA1'
            Expand-Archive $archive $staging -Force
            [void](New-Item (Join-Path $sdk 'cmdline-tools') -ItemType Directory -Force)
            Move-Item (Join-Path $staging 'cmdline-tools') (Join-Path $sdk 'cmdline-tools\latest')
        } finally { Remove-Item $archive, $staging -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if (-not (Test-Path (Join-Path $sdk 'licenses\android-sdk-license'))) {
        throw "Android licenses require your acceptance. Run: & '$manager' --sdk_root='$sdk' --licenses; then rerun the task."
    }
    $flutterRoot = Split-Path -Parent (Split-Path -Parent $Flutter)
    $gradle = Get-Content (Join-Path $flutterRoot 'packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt') -Raw
    $packages = @('platform-tools', 'build-tools;35.0.0', 'cmake;3.22.1')
    foreach ($entry in @(@('compileSdkVersion', 'platforms;android-'), @('ndkVersion', 'ndk;'))) {
        if ($gradle -notmatch ($entry[0] + '\s*(?::\s*\w+)?\s*=\s*"?([\d.]+)')) {
            throw "Unable to read Flutter Android $($entry[0]) requirement."
        }
        $packages += "$($entry[1])$($Matches[1])"
    }
    Invoke-BuildTool $manager (@("--sdk_root=$sdk") + $packages)
    Add-BuildToolPath (Join-Path $sdk 'platform-tools')
    Write-Host "[READY] Android SDK: $sdk; JAVA_HOME=$env:JAVA_HOME"
}

function Initialize-BuildEnvironment {
    param(
        [string]$ProjectRoot,
        [ValidateSet('Sdk', 'Packages', 'WindowsTools', 'Windows', 'Android', 'Installer', 'iOS')][string]$Target = 'Windows',
        [ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug',
        [switch]$SkipPackages
    )

    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or $Target -eq 'iOS') {
        throw 'This bootstrap supports Windows hosts. iOS requires macOS, Xcode and CocoaPods; Windows cannot install or build iOS.'
    }
    Write-Host "[ENV] Preparing target=$Target configuration=$Configuration"
    if ($Target -eq 'Installer') {
        . (Join-Path $ProjectRoot 'tools\inno_setup_tools.ps1')
        return Ensure-InnoSetup
    }
    if ($Target -in @('WindowsTools', 'Windows')) { Initialize-WindowsToolchain $ProjectRoot }
    if ($Target -eq 'WindowsTools') { return }
    $flutter = Initialize-FlutterSdk $ProjectRoot
    if ($Target -eq 'Sdk') { return $flutter }
    if ($Target -eq 'Android') { Initialize-AndroidToolchain $ProjectRoot $flutter }
    if ($Target -eq 'Windows') {
        $native = Join-Path $ProjectRoot 'third_party\native'
        $library = if ($Configuration -eq 'Debug') { 'Debug\freetyped.lib' } else { 'Release\freetype.lib' }
        if (-not (Test-Path (Join-Path $native 'freetype\include\ft2build.h')) -or
            -not (Test-Path (Join-Path $native "build\freetype\$library"))) {
            & (Join-Path $ProjectRoot 'tools\build_native_freetype.ps1') -SkipEnvironment
            if (-not (Test-Path (Join-Path $native "build\freetype\$library"))) { throw 'FreeType native dependency preparation failed.' }
        }
    }
    if (-not $SkipPackages) { Initialize-BuildPackages $ProjectRoot $flutter }
    Write-Host "[READY] Build prerequisites prepared: target=$Target"
    return $flutter
}