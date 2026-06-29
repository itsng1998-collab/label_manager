param(
    [switch]$SkipClone
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$nativeRoot = Join-Path $root 'third_party/native'
$buildRoot = Join-Path $nativeRoot 'build'
$installRoot = Join-Path $nativeRoot 'install'

New-Item -ItemType Directory -Force $nativeRoot | Out-Null

function Set-ContentIfChanged($path, $value, $encoding) {
    if ((Test-Path $path) -and ((Get-Content $path -Raw) -eq $value)) {
        return
    }
    Set-Content -Path $path -Value $value -Encoding $encoding
}

function Get-NativeSourceLastWriteTimeUtc($path) {
    $latest = Get-Item -LiteralPath $path
    Get-ChildItem -LiteralPath $path -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
        ForEach-Object {
            if ($_.LastWriteTimeUtc -gt $latest.LastWriteTimeUtc) {
                $latest = $_
            }
        }
    return $latest.LastWriteTimeUtc
}

function New-NativeArchive($name, $path) {
    $archive = Join-Path $nativeRoot "$name.zip"
    if ((Test-Path $archive) -and ((Get-NativeSourceLastWriteTimeUtc $path) -le (Get-Item $archive).LastWriteTimeUtc)) {
        return
    }
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("label_manager_native_archive_{0}_{1}" -f $name, [System.Guid]::NewGuid().ToString('N'))
    $temporaryModule = Join-Path $temporaryRoot $name
    New-Item -ItemType Directory -Force $temporaryModule | Out-Null
    try {
        Get-ChildItem -LiteralPath $path -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $temporaryModule -Recurse -Force
        }
        Compress-Archive -Path (Join-Path $temporaryModule '*') -DestinationPath $archive -Force
        Write-Host "Updated native archive: $archive"
    } finally {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Expand-NativeArchive($name, $path) {
    $archive = Join-Path $nativeRoot "$name.zip"
    if (-not (Test-Path $archive)) {
        return $false
    }
    New-Item -ItemType Directory -Force $path | Out-Null
    Expand-Archive -LiteralPath $archive -DestinationPath $path -Force
    return $true
}

function Ensure-Repo($name, $url) {
    $path = Join-Path $nativeRoot $name
    if (Test-Path $path) {
        return $path
    }
    if (Expand-NativeArchive $name $path) {
        return $path
    }
    if ($SkipClone) {
        throw "Missing $name source at $path and archive at $(Join-Path $nativeRoot "$name.zip")"
    }
    git clone $url $path
    New-NativeArchive $name $path
    return $path
}

$zlibSource = Ensure-Repo 'zlib' 'https://github.com/madler/zlib.git'
$xlsxSource = Ensure-Repo 'libxlsxwriter' 'https://github.com/jmcnamara/libxlsxwriter.git'
$rtfSource = Ensure-Repo 'rtf2html' 'https://github.com/lvu/rtf2html.git'

$rtfCMake = @'
cmake_minimum_required(VERSION 3.16)
project(rtf2html LANGUAGES CXX)

add_executable(rtf2html
  fmt_opts.cpp
  rtf2html.cpp
  rtf_keyword.cpp
  rtf_table.cpp
)

target_compile_features(rtf2html PRIVATE cxx_std_17)
target_compile_definitions(rtf2html PRIVATE _CRT_SECURE_NO_WARNINGS)
target_include_directories(rtf2html PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
'@
Set-ContentIfChanged (Join-Path $rtfSource 'CMakeLists.txt') $rtfCMake ASCII

$rtfTablePath = Join-Path $rtfSource 'rtf_table.cpp'
$rtfTable = Get-Content $rtfTablePath -Raw
$rtfTable = $rtfTable -replace 'std::bind2nd\(\s*std::mem_fun\(&table_cell_def::right_equals\),\s*\(\*cell_def\)->Right\)', ' [&](table_cell_def* candidate) { return candidate->right_equals((*cell_def)->Right); } '
$rtfTable = $rtfTable -replace 'std::bind2nd\(\s*std::mem_fun\(&table_cell_def::right_equals\),\s*left\)', ' [&](table_cell_def* candidate) { return candidate->right_equals(left); } '
$rtfTable = $rtfTable -replace 'std::bind2nd\(\s*std::mem_fun\(&table_cell_def::left_equals\),\s*right\)', ' [&](table_cell_def* candidate) { return candidate->left_equals(right); } '
Set-ContentIfChanged $rtfTablePath $rtfTable UTF8

New-NativeArchive 'zlib' $zlibSource
New-NativeArchive 'libxlsxwriter' $xlsxSource
New-NativeArchive 'rtf2html' $rtfSource

$zlibInstall = Join-Path $installRoot 'zlib'
cmake -S $zlibSource -B (Join-Path $buildRoot 'zlib') -A x64 "-DCMAKE_INSTALL_PREFIX=$zlibInstall"
cmake --build (Join-Path $buildRoot 'zlib') --config Release --target install
cmake --build (Join-Path $buildRoot 'zlib') --config Debug --target zlibstatic

$zlibInclude = Join-Path $zlibInstall 'include'
$zlibRelease = Join-Path $buildRoot 'zlib/Release/libzs.lib'
$zlibDebug = Join-Path $buildRoot 'zlib/Debug/libzsd.lib'

cmake -S $xlsxSource -B (Join-Path $buildRoot 'libxlsxwriter') -A x64 -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DUSE_NO_MD5=ON "-DZLIB_INCLUDE_DIR=$zlibInclude" "-DZLIB_LIBRARY=$zlibRelease"
cmake --build (Join-Path $buildRoot 'libxlsxwriter') --config Release --target xlsxwriter

cmake -S $xlsxSource -B (Join-Path $buildRoot 'libxlsxwriter_debug') -A x64 -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DUSE_NO_MD5=ON "-DZLIB_INCLUDE_DIR=$zlibInclude" "-DZLIB_LIBRARY=$zlibDebug"
cmake --build (Join-Path $buildRoot 'libxlsxwriter_debug') --config Debug --target xlsxwriter

cmake -S $rtfSource -B (Join-Path $buildRoot 'rtf2html') -A x64
cmake --build (Join-Path $buildRoot 'rtf2html') --config Release --target rtf2html

Write-Host 'Native RTF XLSX dependencies are ready:'
Write-Host "  rtf2html:      $(Join-Path $buildRoot 'rtf2html/Release/rtf2html.exe')"
Write-Host "  xlsxwriter:    $(Join-Path $buildRoot 'libxlsxwriter/Release/xlsxwriter.lib')"
Write-Host "  xlsxwriter(d): $(Join-Path $buildRoot 'libxlsxwriter_debug/Debug/xlsxwriter.lib')"
Write-Host "  zlib:          $zlibRelease"
Write-Host "  zlib(d):       $zlibDebug"