param(
    [switch]$SkipClone
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$nativeRoot = Join-Path $root 'third_party/native'
$source = Join-Path $nativeRoot 'freetype'
$archive = Join-Path $nativeRoot 'freetype.zip'
$build = Join-Path $nativeRoot 'build/freetype'
$tag = 'VER-2-13-3'

function Resolve-CMake {
    $command = Get-Command cmake -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    $visualStudioCMake = 'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
    if (Test-Path $visualStudioCMake) {
        return $visualStudioCMake
    }
    throw 'CMake was not found.'
}

New-Item -ItemType Directory -Force $nativeRoot | Out-Null
if (-not (Test-Path $source)) {
    if (Test-Path $archive) {
        New-Item -ItemType Directory -Force $source | Out-Null
        Expand-Archive -LiteralPath $archive -DestinationPath $source -Force
    } elseif ($SkipClone) {
        throw "Missing FreeType source and archive: $archive"
    } else {
        git clone --depth 1 --branch $tag https://github.com/freetype/freetype.git $source
    }
}

if (-not (Test-Path $archive)) {
    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("label_manager_freetype_{0}" -f [System.Guid]::NewGuid().ToString('N'))
    $temporarySource = Join-Path $temporaryRoot 'freetype'
    New-Item -ItemType Directory -Force $temporarySource | Out-Null
    try {
        Get-ChildItem -LiteralPath $source -Force |
            Where-Object { $_.Name -ne '.git' } |
            ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $temporarySource -Recurse -Force
            }
        Compress-Archive -Path (Join-Path $temporarySource '*') -DestinationPath $archive -Force
    } finally {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$cmake = Resolve-CMake
& $cmake -S $source -B $build -A x64 `
    -DFT_DISABLE_ZLIB=ON `
    -DFT_DISABLE_BZIP2=ON `
    -DFT_DISABLE_PNG=ON `
    -DFT_DISABLE_HARFBUZZ=ON `
    -DFT_DISABLE_BROTLI=ON `
    -DBUILD_SHARED_LIBS=OFF
& $cmake --build $build --config Debug --target freetype
& $cmake --build $build --config Release --target freetype

Write-Host 'FreeType native dependency is ready:'
Write-Host "  Debug:   $(Join-Path $build 'Debug/freetyped.lib')"
Write-Host "  Release: $(Join-Path $build 'Release/freetype.lib')"