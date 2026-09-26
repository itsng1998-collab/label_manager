param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$SourcePrefix
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
$source = if ($SourcePrefix) {
    [System.Drawing.Bitmap]::new((Resolve-Path ($SourcePrefix + '_comparison.bmp')).Path)
} else { $null }
$decoded = [System.Drawing.Bitmap]::new(640, 480)
$graphics = [System.Drawing.Graphics]::FromImage($decoded)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.Dispose()
try {
    $offset = 0
    $patterns = 0
    while ($offset -lt $bytes.Length) {
        if ($bytes[$offset] -in 10, 13) { $offset++; continue }
        $start = $offset
        while ($offset -lt $bytes.Length -and $bytes[$offset] -notin 10, 13) { $offset++ }
        $command = [System.Text.Encoding]::ASCII.GetString($bytes, $start, $offset - $start)
        if ($command -match '^Q(\d+),(\d+),(\d+),(\d+)$') {
            $originX = [int]$Matches[1]
            $originY = [int]$Matches[2]
            $stride = [int]$Matches[3]
            $height = [int]$Matches[4]
            if ($offset -ge $bytes.Length -or $bytes[$offset] -ne 13) { throw 'Expected CR before Q binary payload' }
            $offset++
            $length = $stride * $height
            if ($offset + $length -gt $bytes.Length -or $originX + $stride * 8 -gt 647 -or $originY + $height -gt 487) {
                throw 'Q payload is truncated or outside the diagnostic page'
            }
            $paddingPixels = 0
            for ($row = 0; $row -lt $height; $row++) {
                for ($column = 0; $column -lt $stride * 8; $column++) {
                    $value = $bytes[$offset + $row * $stride + [int][Math]::Floor($column / 8)]
                    $black = ($value -band (128 -shr ($column % 8))) -ne 0
                    if ($originX + $column -ge 640 -or $originY + $row -ge 480) {
                        if ($black) { throw 'Q has nonwhite pixels outside the diagnostic page' }
                        $paddingPixels++
                    } elseif ($black) {
                        $decoded.SetPixel($originX + $column, $originY + $row, [System.Drawing.Color]::Black)
                    }
                }
            }
            $offset += $length
            $patterns++
            Write-Output "pattern=$originX,$originY,$stride,$height whitePaddingPixels=$paddingPixels"
        } elseif ($command -match '^AZ1,(-?\d+),(-?\d+),([1-8]),([1-8]),(-?\d+),([0-7])I,') {
            Write-Output "nativeInverse=$($Matches[1]),$($Matches[2]) scale=$($Matches[3])x$($Matches[4]) rotation=$($Matches[6])"
        } elseif ($command -match '^\^H(0\d|1\d)$') {
            Write-Output "darkness=$([int]$Matches[1])"
        } elseif ($command -notmatch '^(\^[ODCPQWL][0-9.,-]*|E)$') {
            throw "Unsupported command at byte $start"
        }
    }
    if ($patterns -lt 1 -or ($SourcePrefix -and $patterns -ne 1)) {
        throw 'Expected exactly one Q pattern in this probe'
    }
    $imagePath = [System.IO.Path]::ChangeExtension((Resolve-Path $Path).Path, '.png')
    $decoded.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "decodedImage=$imagePath"
    if (!$source) { return }
    $clipLine = Get-Content ($SourcePrefix + '.txt') | Where-Object { $_.StartsWith('clip=') } | Select-Object -First 1
    if ($clipLine -notmatch '^clip=(-?\d+),(-?\d+),(-?\d+),(-?\d+)$') { throw 'Missing inverse clip' }
    $left, $top, $right, $bottom = 1..4 | ForEach-Object { [int]$Matches[$_] }
    $lost = 0
    $gained = 0
    $white = 0
    for ($row = $top; $row -lt $bottom; $row++) {
        for ($column = $left; $column -lt $right; $column++) {
            $before = $source.GetPixel($column, $row).R -eq 255
            $after = $decoded.GetPixel($column, $row).R -eq 255
            if ($before) { $white++ }
            if ($before -and !$after) { $lost++ }
            if (!$before -and $after) { $gained++ }
        }
    }
    Write-Output "clip=$left,$top,$right,$bottom sourceWhite=$white whiteLost=$lost whiteGained=$gained mismatches=$($lost + $gained)"
} finally {
    if ($source) { $source.Dispose() }
    $decoded.Dispose()
}
