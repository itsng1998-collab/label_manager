param([Parameter(Mandatory = $true)][string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$directory = New-Item -ItemType Directory -Force -Path $OutputDirectory
$prefix = Join-Path $directory.FullName 'synthetic'
$bitmap = [System.Drawing.Bitmap]::new(620, 480)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.FillRectangle([System.Drawing.Brushes]::Black, 15, 83, 8, 2)
    $bitmap.SetPixel(15, 83, [System.Drawing.Color]::White)
    $bitmap.SetPixel(22, 84, [System.Drawing.Color]::White)
    $bitmap.Save($prefix + '_comparison.bmp', [System.Drawing.Imaging.ImageFormat]::Bmp)
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
[System.IO.File]::WriteAllText($prefix + '.txt', 'clip=15,83,23,85')
$path = Join-Path $directory.FullName 'synthetic.prn'
$header = [System.Text.Encoding]::ASCII.GetBytes("^L`r`nQ15,83,1,2`r")
$tail = [System.Text.Encoding]::ASCII.GetBytes("`r`nE`r`n")
$cases = @(
    @{ Bytes = [byte[]]@(127, 254); Expected = 'sourceWhite=2 whiteLost=0 whiteGained=0 mismatches=0' },
    @{ Bytes = [byte[]]@(255, 254); Expected = 'sourceWhite=2 whiteLost=1 whiteGained=0 mismatches=1' },
    @{ Bytes = [byte[]]@(127, 252); Expected = 'sourceWhite=2 whiteLost=0 whiteGained=1 mismatches=1' }
)
foreach ($case in $cases) {
    [System.IO.File]::WriteAllBytes($path, [byte[]]($header + $case.Bytes + $tail))
    $report = & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path -SourcePrefix $prefix
    if (!($report | Where-Object { $_.Contains($case.Expected) })) {
        throw "Pixel comparison mismatch: $($report -join '; ')"
    }
}
[System.IO.File]::WriteAllBytes($path, [byte[]]($header + [byte[]]@(13)))
$rejected = $false
try { & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path -SourcePrefix $prefix | Out-Null }
catch { $rejected = $_.Exception.Message -eq 'Q payload is truncated or outside the diagnostic page' }
if (!$rejected) { throw 'Truncated binary payload was not rejected' }
[System.IO.File]::WriteAllBytes($path, [byte[]]($header + [byte[]]@(13, 10) + $tail))
$report = & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path -SourcePrefix $prefix
if (!($report | Where-Object { $_.Contains('sourceWhite=2 whiteLost=0 whiteGained=9 mismatches=9') })) {
    throw 'CR/LF binary bytes were interpreted as command delimiters'
}
$paddingHeader = [System.Text.Encoding]::ASCII.GetBytes("^L`r`nQ0,479,1,8`r")
[System.IO.File]::WriteAllBytes($path, [byte[]]($paddingHeader + [byte[]]::new(8) + $tail))
$report = & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path -SourcePrefix $prefix
if (!($report | Where-Object { $_.Contains('whitePaddingPixels=56') })) {
    throw 'Zero-filled block alignment padding was not accepted'
}
$padding = [byte[]]::new(8)
$padding[7] = 128
[System.IO.File]::WriteAllBytes($path, [byte[]]($paddingHeader + $padding + $tail))
$rejected = $false
try { & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path -SourcePrefix $prefix | Out-Null }
catch { $rejected = $_.Exception.Message -eq 'Q has nonwhite pixels outside the diagnostic page' }
if (!$rejected) { throw 'Nonwhite page overflow was not rejected' }
[System.IO.File]::WriteAllBytes($path, [byte[]]($header + [byte[]]@(127, 254) + $tail))
$preview = & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path
if (!($preview | Where-Object { $_.StartsWith('decodedImage=') }) -or
    ($preview | Where-Object { $_.StartsWith('clip=') })) {
    throw 'Preview-only mode did not stay separate from source comparison'
}
$decoded = [System.Drawing.Bitmap]::new([System.IO.Path]::ChangeExtension($path, '.png'))
try {
    if ($decoded.Width -ne 640 -or $decoded.Height -ne 480 -or
        $decoded.GetPixel(15, 83).R -ne 255 -or
        $decoded.GetPixel(16, 83).R -ne 0) {
        throw 'Preview-only image pixel contract failed'
    }
} finally { $decoded.Dispose() }
$secondHeader = [System.Text.Encoding]::ASCII.GetBytes("`r`nQ30,90,1,1`r")
[System.IO.File]::WriteAllBytes($path, [byte[]](
    $header + [byte[]]@(127, 254) + $secondHeader + [byte[]]@(128) + $tail))
$preview = & "$PSScriptRoot/inspect_inverse_driver_file.ps1" -Path $path
$decoded = [System.Drawing.Bitmap]::new([System.IO.Path]::ChangeExtension($path, '.png'))
try {
    if ($decoded.GetPixel(16, 83).R -ne 0 -or $decoded.GetPixel(30, 90).R -ne 0 -or
        $decoded.GetPixel(31, 90).R -ne 255) {
        throw 'Multi-pattern preview pixel contract failed'
    }
} finally { $decoded.Dispose() }
Write-Output 'inverseDriverFileParser=PASS cases=9'