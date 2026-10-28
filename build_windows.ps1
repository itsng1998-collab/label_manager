#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $ScriptRoot 'tools\build_environment.ps1')
Initialize-BuildEnvironment -ProjectRoot $ScriptRoot -Target Windows -Configuration Release | Out-Null
$buildToolsScript = Join-Path $ScriptRoot 'tools\windows_build_tools.ps1'
if (-not (Test-Path -LiteralPath $buildToolsScript -PathType Leaf)) {
	throw "Windows build tools helper not found: $buildToolsScript"
}
. $buildToolsScript
$installation = Ensure-WindowsBuildTools -IssPath (Join-Path $ScriptRoot 'inno_setup_installer.iss') -InstallIfMissing $true
. (Join-Path $ScriptRoot 'tools\windows_release.ps1')
$version = Get-WindowsReleaseVersion -ProjectRoot $ScriptRoot

Push-Location -LiteralPath $ScriptRoot
try {
	$flutterScript = Join-Path $ScriptRoot 'flutter.ps1'
	& $flutterScript -RootOnly -SkipEnvironment build windows --release
	$buildExitCode = $LASTEXITCODE
	if ($buildExitCode -eq 0) {
		$releaseDir = Join-Path $ScriptRoot 'build\windows\x64\runner\Release'
		Copy-WindowsReleaseRuntime -InstallationPath $installation.InstallationPath -ReleaseDir $releaseDir
		Assert-WindowsReleaseBundle -ReleaseDir $releaseDir -Version $version
		[System.IO.File]::WriteAllText((Join-Path $ScriptRoot 'version.txt'), $version)
		Write-Host "[OK] Windows x64 Release ready: version=$version path=$releaseDir"
	}
} finally {
	Pop-Location
}

exit $buildExitCode
