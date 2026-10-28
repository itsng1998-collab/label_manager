#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $PSScriptRoot 'build_environment.ps1'
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("label_environment_test_" + [guid]::NewGuid())
$savedEnvironment = @{}
foreach ($name in @('PATH', 'LOCALAPPDATA', 'JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'FLUTTER_ROOT', 'FLUTTER_HOME')) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}
$script:passed = 0
function Assert-Test {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Host "PASS: $Name"
}
function Write-Fixture {
    param([string]$Path, [string]$Text = 'fixture')
    [void](New-Item (Split-Path -Parent $Path) -ItemType Directory -Force)
    [System.IO.File]::WriteAllText($Path, $Text)
}
try {
    [void](New-Item $temp -ItemType Directory)
    $env:LOCALAPPDATA = Join-Path $temp 'local app data'
    . $helper
    function Test-Success { $global:LASTEXITCODE = 0 }
    function Test-Failure { $global:LASTEXITCODE = 19 }
    Invoke-BuildTool Test-Success
    Assert-Test $true 'successful prerequisite command continues'
    try { Invoke-BuildTool Test-Failure; throw 'accepted failure' }
    catch { Assert-Test ($_.Exception.Message -like '*exit=19*') 'failed prerequisite command stops build' }
    Assert-Test (-not (Test-WindowsSdk -KitsRoot $temp)) 'missing Windows SDK rejected'
    Write-Fixture "$temp\Include\10.0.26100.0\um\Windows.h"
    Write-Fixture "$temp\Lib\10.0.26100.0\um\x64\kernel32.lib"
    Assert-Test (-not (Test-WindowsSdk -KitsRoot $temp)) 'incomplete Windows SDK rejected'
    Write-Fixture "$temp\bin\10.0.26100.0\x64\rc.exe"
    Assert-Test (Test-WindowsSdk -KitsRoot $temp) 'complete Windows SDK accepted'
    Assert-Test ((Find-BuildTool 'nonexistent' @("$temp\bin\10.0.26100.0\x64\rc.exe")) -like '*rc.exe') 'explicit tool candidate detected'
    & {
        . $helper
        $script:userPathFixture = '%LOCALAPPDATA%\Existing;C:\Other'
        $script:userPathWrites = 0
        function Get-BuildUserPath { return $script:userPathFixture }
        function Set-BuildUserPath { param($Value) $script:userPathFixture = $Value; $script:userPathWrites++ }
        $directory = "$env:LOCALAPPDATA\Programs\Flutter\bin"
        Register-FlutterUserPath $directory
        Assert-Test ($script:userPathFixture -eq "%LOCALAPPDATA%\Existing;C:\Other;$directory") 'user PATH registration preserves existing entries and variables'
        Register-FlutterUserPath $directory
        Assert-Test ($script:userPathWrites -eq 1) 'user PATH registration is idempotent'
        $script:userPathFixture = '%LOCALAPPDATA%\Programs\Flutter\bin\'
        Register-FlutterUserPath $directory.ToUpperInvariant()
        Assert-Test ($script:userPathWrites -eq 1) 'PATH duplicate check expands variables and ignores case and trailing separator'
        $script:userPathFixture = ''
        Register-FlutterUserPath $directory
        Assert-Test ($script:userPathFixture -eq $directory -and $script:userPathWrites -eq 2) 'empty user PATH accepts Flutter directory'
        function Set-BuildUserPath { param($Value) throw 'user PATH write failure fixture' }
        $script:userPathFixture = ''
        try { Register-FlutterUserPath $directory; throw 'accepted PATH failure' }
        catch { Assert-Test ($_.Exception.Message -eq 'user PATH write failure fixture') 'user PATH registration failure is propagated' }
    }
    & {
        . $helper
        $protocol = [Net.ServicePointManager]::SecurityProtocol
        function Invoke-RestMethod {
            param($Uri, $TimeoutSec)
            Assert-Test (([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) -ne 0) 'legacy shell metadata request enables TLS 1.2'
            return 'metadata fixture'
        }
        $metadata = Read-BuildMetadata 'https://fixture'
        Assert-Test ($metadata -eq 'metadata fixture' -and [Net.ServicePointManager]::SecurityProtocol -eq $protocol) 'metadata success restores protocol setting'
        function Invoke-RestMethod { param($Uri, $TimeoutSec) throw 'network failure fixture' }
        try { Read-BuildMetadata 'https://fixture'; throw 'accepted network failure' }
        catch { Assert-Test ($_.Exception.Message -eq 'network failure fixture' -and [Net.ServicePointManager]::SecurityProtocol -eq $protocol) 'metadata failure restores protocol and stops setup' }
    }
    & {
        . $helper
        $script:events = @()
        function Initialize-FlutterSdk { param($ProjectRoot) $script:events += 'sdk'; return 'fixture-flutter' }
        function Initialize-WindowsToolchain { param($ProjectRoot) $script:events += 'windows' }
        function Initialize-AndroidToolchain { param($ProjectRoot, $Flutter) $script:events += 'android' }
        function Initialize-BuildPackages { param($ProjectRoot, $Flutter) $script:events += 'packages' }
        Assert-Test ((Initialize-BuildEnvironment $temp -Target Sdk) -eq 'fixture-flutter' -and ($script:events -join ',') -eq 'sdk') 'SDK profile avoids unrelated installations'
        $script:events = @()
        Initialize-BuildEnvironment $temp -Target WindowsTools | Out-Null
        Assert-Test (($script:events -join ',') -eq 'windows') 'native tools profile avoids Flutter/pub'
        $script:events = @()
        Initialize-BuildEnvironment $temp -Target Android | Out-Null
        Assert-Test (($script:events -join ',') -eq 'sdk,android,packages') 'Android prepares SDK before packages'
        Write-Fixture "$temp\third_party\native\freetype\include\ft2build.h"
        Write-Fixture "$temp\third_party\native\build\freetype\Debug\freetyped.lib"
        Write-Fixture "$temp\third_party\native\build\freetype\Release\freetype.lib"
        $script:events = @()
        Initialize-BuildEnvironment $temp -Target Windows -SkipPackages | Out-Null
        Assert-Test (($script:events -join ',') -eq 'windows,sdk') 'existing native library skips native rebuild and optional pub'
        function Initialize-BuildPackages { param($ProjectRoot, $Flutter) throw 'pub failure fixture' }
        try { Initialize-BuildEnvironment $temp -Target Packages; throw 'accepted pub failure' }
        catch { Assert-Test ($_.Exception.Message -eq 'pub failure fixture') 'package restore failure stops preparation' }
        try { Initialize-BuildEnvironment $temp -Target iOS; throw 'accepted iOS on Windows' }
        catch { Assert-Test ($_.Exception.Message -like '*iOS requires macOS*') 'unsupported iOS host rejected before installing tools' }
    }
    & {
        . $helper
        $script:gitInstalled = $false
        $script:installCalls = 0
        function Find-BuildTool {
            param($Name, $Candidates)
            if ($Name -eq 'winget.exe') { return 'winget.exe' }
            if ($script:gitInstalled) { return 'C:\fixture\git.exe' }
        }
        function Invoke-BuildTool { param($Executable, $Arguments) $script:installCalls++; $script:gitInstalled = $true }
        Initialize-BuildGit
        Assert-Test ($script:installCalls -eq 1) 'missing Git installs once and is rediscovered'
        Initialize-BuildGit
        Assert-Test ($script:installCalls -eq 1) 'existing Git skips install'
        function Find-BuildTool { param($Name, $Candidates) return $null }
        try { Initialize-BuildGit; throw 'accepted missing winget' }
        catch { Assert-Test ($_.Exception.Message -like '*Git is missing*') 'missing Git installer gives actionable failure'
        }
    }
    & {
        . $helper
        $script:downloadHash = $null
        $script:flutterDownloadCount = 0
        $script:registeredFlutterPath = $null
        function Initialize-BuildGit {}
        function Register-FlutterUserPath { param($Directory) $script:registeredFlutterPath = $Directory }
        function Find-BuildTool {
            param($Name, $Candidates)
            foreach ($candidate in $Candidates) { if (Test-Path $candidate) { return $candidate } }
            return $null
        }
        $archiveRoot = Join-Path $temp 'flutter-archive'
        Write-Fixture "$archiveRoot\flutter\bin\flutter.bat"
        Write-Fixture "$archiveRoot\flutter\bin\cache\dart-sdk\version" '3.11.5'
        $archive = Join-Path $temp 'flutter-fixture.zip'
        Compress-Archive "$archiveRoot\flutter" $archive
        $script:flutterFixtureArchive = $archive
        function Invoke-RestMethod {
            param($Uri, $TimeoutSec)
            $script:flutterDownloadCount++
            return [pscustomobject]@{ base_url = 'https://fixture'; current_release = [pscustomobject]@{ stable = 'sdk-hash' };
                releases = @([pscustomobject]@{ hash = 'sdk-hash'; dart_sdk_arch = 'x64'; archive = 'flutter.zip'; sha256 = 'expected-sha' }) }
        }
        function Save-BuildDownload { param($Uri, $Path, $Hash, $Algorithm) $script:downloadHash = $Hash; Copy-Item $script:flutterFixtureArchive $Path }
        function Invoke-BuildTool { param($Executable, $Arguments) }
        $sdkRoot = Join-Path $temp 'new-project'
        Write-Fixture "$sdkRoot\pubspec.yaml" "name: fixture`nenvironment:`n  sdk: ^3.11.5`n"
        $env:FLUTTER_ROOT = Join-Path $temp 'old-flutter'
        Write-Fixture "$env:FLUTTER_ROOT\bin\flutter.bat"
        Write-Fixture "$env:FLUTTER_ROOT\bin\cache\dart-sdk\version" '3.10.0'
        $launcher = Initialize-FlutterSdk $sdkRoot
        Assert-Test ((Test-Path $launcher) -and $script:downloadHash -eq 'expected-sha') 'missing Flutter downloads hash-verified official archive'
        Assert-Test ($launcher -eq "$env:LOCALAPPDATA\Programs\Flutter\bin\flutter.bat") 'outdated Flutter installs in per-user Programs outside workspace'
        Assert-Test ($script:registeredFlutterPath -eq (Split-Path -Parent $launcher)) 'installed Flutter bin is registered in user PATH'
        Assert-Test ((Get-Content "$sdkRoot\.tmp\flutter_launcher_path.txt" -Raw) -eq $launcher) 'downloaded Flutter is cached for following build'
        Assert-Test ((Get-Content "$env:FLUTTER_ROOT\bin\cache\dart-sdk\version" -Raw) -eq '3.10.0') 'old system SDK is not modified'
        $reused = Initialize-FlutterSdk $sdkRoot
        Assert-Test ($reused -eq $launcher -and $script:flutterDownloadCount -eq 1) 'per-user SDK wins over old environment SDK without redownloading'
        Remove-Item "$env:LOCALAPPDATA\Programs\Flutter" -Recurse -Force
        function Find-BuildTool {
            param($Name, $Candidates)
            foreach ($candidate in $Candidates) {
                if ($candidate -eq "$env:LOCALAPPDATA\Programs\Flutter\bin\flutter.bat" -and (Test-Path $candidate)) { return $candidate }
            }
            return $null
        }
        $missingProject = Join-Path $temp 'missing-flutter-project'
        Write-Fixture "$missingProject\pubspec.yaml" "name: fixture`nenvironment:`n  sdk: ^3.11.5`n"
        $installed = Initialize-FlutterSdk $missingProject
        Assert-Test ($installed -eq $launcher -and $script:flutterDownloadCount -eq 2) 'absent Flutter installs in per-user Programs'
        Assert-Test (-not (Test-Path "$missingProject\.tmp\toolchains\flutter")) 'new Flutter installation does not create workspace SDK'
        Assert-Test (-not (Test-Path "$env:LOCALAPPDATA\Programs\flutter.zip")) 'download archive is removed after installation'
        $sharedProject = Join-Path $temp 'shared-flutter-project'
        Write-Fixture "$sharedProject\pubspec.yaml" "name: fixture`nenvironment:`n  sdk: ^3.11.5`n"
        $shared = Initialize-FlutterSdk $sharedProject
        Assert-Test ($shared -eq $launcher -and $script:flutterDownloadCount -eq 2) 'another workspace reuses per-user SDK without redownloading'
        Write-Fixture "$env:LOCALAPPDATA\Programs\Flutter\bin\cache\dart-sdk\version" '3.10.0'
        $updated = Initialize-FlutterSdk $sharedProject
        Assert-Test ($updated -eq $launcher -and $script:flutterDownloadCount -eq 3 -and
            (Get-Content "$env:LOCALAPPDATA\Programs\Flutter\bin\cache\dart-sdk\version" -Raw) -eq '3.11.5') 'outdated per-user SDK is updated at the same location'
    }
    & {
        . $helper
        $androidProject = Join-Path $temp 'android-project'
        $sdk = Join-Path $androidProject '.tmp\toolchains\android-sdk'
        $java = Join-Path $androidProject '.tmp\toolchains\jdk\bin\java.exe'
        Write-Fixture $java
        Write-Fixture "$androidProject\.tmp\toolchains\jdk\release" 'JAVA_VERSION="17.0.13"'
        Write-Fixture "$sdk\cmdline-tools\latest\bin\sdkmanager.bat"
        Write-Fixture "$sdk\licenses\android-sdk-license"
        $flutter = Join-Path $androidProject 'flutter\bin\flutter.bat'
        Write-Fixture "$androidProject\flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt" 'val compileSdkVersion: Int = 36; val ndkVersion = "28.2.13676358"'
        $env:ANDROID_HOME = $sdk
        function Find-BuildTool { param($Name, $Candidates) if ($Name -eq 'java.exe') { return $java } }
        $script:sdkPackages = @()
        function Invoke-BuildTool { param($Executable, $Arguments) $script:sdkPackages = $Arguments }
        Initialize-AndroidToolchain $androidProject $flutter
        Assert-Test ($script:sdkPackages -contains 'platforms;android-36' -and $script:sdkPackages -contains 'ndk;28.2.13676358') 'Android packages follow installed Flutter requirements'
        Remove-Item "$sdk\licenses\android-sdk-license"
        try { Initialize-AndroidToolchain $androidProject $flutter; throw 'accepted missing license' }
        catch { Assert-Test ($_.Exception.Message -like '*licenses require your acceptance*') 'Android license is not silently accepted' }
    }
    $tasks = Get-Content (Join-Path $root '.vscode\tasks.json') -Raw | ConvertFrom-Json
    $launch = Get-Content (Join-Path $root '.vscode\launch.json') -Raw | ConvertFrom-Json
    foreach ($configuration in $launch.configurations) {
        Assert-Test ($configuration.preLaunchTask -in $tasks.tasks.label) "launch preflight exists: $($configuration.name)"
    }
    foreach ($task in $tasks.tasks) {
        $properties = @($task.PSObject.Properties.Name)
        if ($properties -contains 'dependsOn') { Assert-Test ($task.dependsOn -in $tasks.tasks.label) "task dependency exists: $($task.label)" }
        foreach ($argument in $task.args) {
            if ($argument -like '${workspaceFolder}/*.ps1') {
                Assert-Test (Test-Path ($argument.Replace('${workspaceFolder}', $root))) "task script exists: $($task.label)"
            }
        }
    }
    foreach ($relative in @('build_windows.ps1', 'build_android.ps1', 'flutter.ps1', 'inno_setup_installer.ps1',
        'tools\build_environment.ps1', 'tools\prepare_build.ps1', 'tools\windows_build_tools.ps1',
        'tools\inno_setup_tools.ps1', 'tools\windows_release.ps1', 'tools\build_native_freetype.ps1',
        'tools\build_native_rtf_xlsx.ps1')) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root $relative), [ref]$tokens, [ref]$parseErrors)
        Assert-Test ($parseErrors.Count -eq 0 -and $ast.ScriptRequirements.RequiredPSVersion -eq [version]'5.1') "current shell syntax and PowerShell 5.1 baseline: $relative"
    }
    Write-Host "SUCCESS: $script:passed build environment checks passed."
} finally {
    foreach ($name in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name]) }
    if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
}