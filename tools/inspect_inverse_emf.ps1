param([Parameter(Mandatory = $true)][string]$Path)

$ErrorActionPreference = 'Stop'
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
$offset = 0
$names = @{
    18 = 'SetBkMode'; 24 = 'SetTextColor'; 25 = 'SetBkColor'
    37 = 'SelectObject'; 39 = 'CreateBrushIndirect'; 43 = 'Rectangle'
    76 = 'BitBlt'; 82 = 'CreateFont'; 84 = 'ExtTextOutW'
}
while ($offset -lt $bytes.Length) {
    $type = [BitConverter]::ToUInt32($bytes, $offset)
    $size = [BitConverter]::ToUInt32($bytes, $offset + 4)
    if ($size -lt 8 -or $offset + $size -gt $bytes.Length) {
        throw "Invalid EMF record at $offset"
    }
    if ($names.ContainsKey([int]$type)) {
        $detail = ''
        switch ($type) {
            { $_ -in 18, 24, 25, 37 } {
                $detail = 'value=0x{0:X8}' -f [BitConverter]::ToUInt32($bytes, $offset + 8)
            }
            39 {
                $detail = 'brush={0} style={1} color=0x{2:X8}' -f [BitConverter]::ToUInt32($bytes, $offset + 8), [BitConverter]::ToUInt32($bytes, $offset + 12), [BitConverter]::ToUInt32($bytes, $offset + 16)
            }
            43 {
                $detail = 'rect=' + ((8, 12, 16, 20 | ForEach-Object { [BitConverter]::ToInt32($bytes, $offset + $_) }) -join ',')
            }
            84 {
                $count = [BitConverter]::ToUInt32($bytes, $offset + 44)
                $stringOffset = [BitConverter]::ToUInt32($bytes, $offset + 48)
                $options = [BitConverter]::ToUInt32($bytes, $offset + 52)
                $rectangle = (56, 60, 64, 68 | ForEach-Object { [BitConverter]::ToInt32($bytes, $offset + $_) }) -join ','
                $text = if ($count -gt 0 -and ($options -band 16) -eq 0) {
                    [System.Text.Encoding]::Unicode.GetString($bytes, $offset + $stringOffset, $count * 2)
                } else { '<glyphs-or-empty>' }
                $detail = "count=$count options=$options rect=$rectangle text=[$text]"
            }
        }
        [PSCustomObject]@{ Offset = $offset; Type = $names[[int]$type]; Detail = $detail }
    }
    $offset += $size
}