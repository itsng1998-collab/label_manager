$ErrorActionPreference = 'Stop'

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$buildToolsScript = Join-Path $ScriptRoot 'tools\windows_build_tools.ps1'
if (-not (Test-Path -LiteralPath $buildToolsScript -PathType Leaf)) {
	throw "Windows build tools helper not found: $buildToolsScript"
}
. $buildToolsScript
Ensure-WindowsBuildTools -IssPath (Join-Path $ScriptRoot 'inno_setup_installer.iss') -InstallIfMissing $true | Out-Null

#flutter pub run pub_version_plus:main build
dart run (Join-Path $ScriptRoot 'lib\utils\generate_version.dart')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$flutterScript = Join-Path $ScriptRoot 'flutter.ps1'
& $flutterScript build windows
exit $LASTEXITCODE
