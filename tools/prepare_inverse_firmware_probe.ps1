param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][string]$SpecPath,
    [ValidateSet('Black', 'White')][string]$ClipFill = 'Black',
    [ValidateRange(0, 19)][int]$Darkness = -1,
    [ValidateRange(0, 19)][int]$RestoreDarkness = -1
)

$ErrorActionPreference = 'Stop'
$inputPath = (Resolve-Path -LiteralPath $Path).Path
$spec = Get-Content -Raw -LiteralPath $SpecPath | ConvertFrom-Json
$bytes = [System.IO.File]::ReadAllBytes($inputPath)
$cp949 = [System.Text.Encoding]::GetEncoding(949)

$offset = 0
$pattern = $null
$labelStartOffset = $null
$endCommandOffset = $null
while ($offset -lt $bytes.Length) {
    if ($bytes[$offset] -in 10, 13) { $offset++; continue }
    $start = $offset
    while ($offset -lt $bytes.Length -and $bytes[$offset] -notin 10, 13) { $offset++ }
    $command = [System.Text.Encoding]::ASCII.GetString($bytes, $start, $offset - $start)
    if ($command -eq '^L') {
        if ($null -ne $labelStartOffset) { throw 'Expected exactly one ^L command' }
        $labelStartOffset = $start
    } elseif ($command -match '^Q(\d+),(\d+),(\d+),(\d+)$') {
        if ($null -ne $pattern) { throw 'Expected exactly one Q pattern' }
        $originX = [int]$Matches[1]
        $originY = [int]$Matches[2]
        $stride = [int]$Matches[3]
        $height = [int]$Matches[4]
        if ($offset -ge $bytes.Length -or $bytes[$offset] -ne 13) {
            throw 'Expected CR before Q binary payload'
        }
        $payloadOffset = $offset + 1
        $payloadLength = $stride * $height
        if ($payloadOffset + $payloadLength -gt $bytes.Length) {
            throw 'Q payload is truncated'
        }
        $pattern = [pscustomobject]@{
            OriginX = $originX
            OriginY = $originY
            Stride = $stride
            Height = $height
            PayloadOffset = $payloadOffset
        }
        $offset = $payloadOffset + $payloadLength
    } elseif ($command -eq 'E') {
        $endCommandOffset = $start
        break
    } elseif ($command -notmatch '^(\^[ODCPQWL][0-9.,-]*)$') {
        throw "Unsupported command at byte $start"
    }
}

if ($null -eq $labelStartOffset -or $null -eq $pattern -or
    $null -eq $endCommandOffset) {
    throw 'PRN must contain one ^L, one Q pattern, and a following E'
}
if (($Darkness -lt 0) -ne ($RestoreDarkness -lt 0)) {
    throw 'Darkness and RestoreDarkness must be specified together'
}

$modified = [byte[]]$bytes.Clone()
foreach ($clip in $spec.clips) {
    $left = [int]$clip.left
    $top = [int]$clip.top
    $right = [int]$clip.right
    $bottom = [int]$clip.bottom
    if ($left -lt $pattern.OriginX -or $top -lt $pattern.OriginY -or
        $right -gt $pattern.OriginX + $pattern.Stride * 8 -or
        $bottom -gt $pattern.OriginY + $pattern.Height -or
        $right -le $left -or $bottom -le $top) {
        throw "Inverse clip is outside Q pattern: $left,$top,$right,$bottom"
    }
    for ($y = $top; $y -lt $bottom; $y++) {
        $localY = $y - $pattern.OriginY
        for ($x = $left; $x -lt $right; $x++) {
            $localX = $x - $pattern.OriginX
            $index = $pattern.PayloadOffset + $localY * $pattern.Stride +
                [int][Math]::Floor($localX / 8)
            $mask = 128 -shr ($localX % 8)
            if ($ClipFill -eq 'Black') {
                $modified[$index] = $modified[$index] -bor $mask
            } else {
                $modified[$index] = $modified[$index] -band (255 -bxor $mask)
            }
        }
    }
}

$nativeCommands = [System.Collections.Generic.List[byte]]::new()
foreach ($field in $spec.fields) {
    $xMultiply = [int]$field.xMultiply
    $yMultiply = [int]$field.yMultiply
    $rotation = [int]$field.rotation
    $text = [string]$field.text
    if ($xMultiply -lt 1 -or $xMultiply -gt 8 -or
        $yMultiply -lt 1 -or $yMultiply -gt 8) {
        throw 'AZ1 xMultiply/yMultiply must be between 1 and 8'
    }
    if ($rotation -lt 0 -or $rotation -gt 7) {
        throw 'AZ1 rotation must be between 0 and 7'
    }
    if ($text.Contains("`r") -or $text.Contains("`n")) {
        throw 'AZ1 text must not contain CR or LF'
    }
    $prefix = 'AZ1,{0},{1},{2},{3},{4},{5}I,' -f
        [int]$field.x, [int]$field.y, $xMultiply, $yMultiply,
        [int]$field.gap, $rotation
    $nativeCommands.AddRange([System.Text.Encoding]::ASCII.GetBytes($prefix))
    $nativeCommands.AddRange($cp949.GetBytes($text))
    $nativeCommands.Add(13)
    $nativeCommands.Add(10)
}

$outputDirectory = Split-Path -Parent $OutputPath
if ([string]::IsNullOrWhiteSpace($outputDirectory) -or
    !(Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw 'Output directory must already exist'
}
if (Test-Path -LiteralPath $OutputPath) {
    throw 'Output PRN already exists'
}

$setupCommands = if ($Darkness -ge 0) {
    [System.Text.Encoding]::ASCII.GetBytes(("^H{0:D2}`r`n" -f $Darkness))
} else {
    [byte[]]::new(0)
}
$restoreCommands = if ($RestoreDarkness -ge 0) {
    [System.Text.Encoding]::ASCII.GetBytes(("^H{0:D2}`r`n" -f $RestoreDarkness))
} else {
    [byte[]]::new(0)
}
$result = [byte[]]::new(
    $modified.Length + $setupCommands.Length + $nativeCommands.Count +
        $restoreCommands.Length
)
[Array]::Copy($modified, 0, $result, 0, $labelStartOffset)
[Array]::Copy(
    $setupCommands,
    0,
    $result,
    $labelStartOffset,
    $setupCommands.Length
)
$middleLength = $endCommandOffset - $labelStartOffset
[Array]::Copy(
    $modified,
    $labelStartOffset,
    $result,
    $labelStartOffset + $setupCommands.Length,
    $middleLength
)
$nativeOffset = $endCommandOffset + $setupCommands.Length
$nativeCommands.CopyTo($result, $nativeOffset)
$tailOffset = $nativeOffset + $nativeCommands.Count
[Array]::Copy(
    $modified,
    $endCommandOffset,
    $result,
    $tailOffset,
    $modified.Length - $endCommandOffset
)
$restoreOffset = $tailOffset + $modified.Length - $endCommandOffset
[Array]::Copy(
    $restoreCommands,
    0,
    $result,
    $restoreOffset,
    $restoreCommands.Length
)
[System.IO.File]::WriteAllBytes($OutputPath, $result)
Write-Output "inverseFirmwareProbe=$OutputPath"
Write-Output "qPattern=$($pattern.OriginX),$($pattern.OriginY),$($pattern.Stride),$($pattern.Height) clipFill=$ClipFill darkness=$Darkness restoreDarkness=$RestoreDarkness clips=$($spec.clips.Count) fields=$($spec.fields.Count) bytes=$($result.Length)"
