[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$LogPath,

  # 요구사항: 스크립트가 추가로 출력/생성하는 로그도 항상 `.tmp/test.log`에 남긴다.
  # 단, 분석 파서가 다시 읽을 때 오염되지 않도록 안전한 접두사/치환을 적용한다.
  [string]$TestLogPath,

  [int]$ContextLines = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
  $scriptPath = $PSCommandPath
  if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptPath = $MyInvocation.MyCommand.Path
  }
  if (-not [string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptRoot = Split-Path -Parent $scriptPath
  }
}

if ([string]::IsNullOrWhiteSpace($LogPath)) {
  $LogPath = (Join-Path -Path (Join-Path -Path $scriptRoot -ChildPath '..') -ChildPath '.tmp\test.log')
}
if ([string]::IsNullOrWhiteSpace($TestLogPath)) {
  $TestLogPath = (Join-Path -Path (Join-Path -Path $scriptRoot -ChildPath '..') -ChildPath '.tmp\test.log')
}

function Write-TestLogLine {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Message
  )

  try {
    if ([string]::IsNullOrEmpty($Message)) {
      return
    }

    $dir = Split-Path -Parent $TestLogPath
    if (-not (Test-Path -LiteralPath $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # IMPORTANT: 분석 대상 키워드와 충돌하는 문자열은 치환해, 다음 분석에서 오염되지 않게 한다.
    $safe = $Message
    $safe = $safe -replace 'toolbar_filter_summary', 'tfs_summary'
    $safe = $safe -replace 'toolbar_filter_fallback', 'tfs_fallback'
    $safe = $safe -replace 'toolbar_filter_emergency', 'tfs_emergency'
      $safe = $safe -replace 'toolbar_compact_escape_attempt', 'tfs_compact_escape_attempt'
      $safe = $safe -replace 'toolbar_compact_escape_result', 'tfs_compact_escape_result'

    $ts = (Get-Date).ToString('o')
    Add-Content -LiteralPath $TestLogPath -Value ("$ts [analyze_toolbar_log] $safe") -Encoding UTF8
  } catch {
    # best-effort: 로깅 실패는 무시한다.
  }
}

function Write-Report {
  param(
    [AllowEmptyString()][string]$Message = '',
    [switch]$NoTestLog
  )

  Write-Host $Message
  if (-not $NoTestLog) {
    Write-TestLogLine -Message $Message
  }
}

$runId = [guid]::NewGuid().ToString('n')
Write-TestLogLine -Message "BEGIN runId=$runId logPath=$LogPath contextLines=$ContextLines"

function Try-ExtractJson {
  param(
    [Parameter(Mandatory = $true)][string]$Line
  )

  function ConvertFrom-JsonCompat {
    param(
      [Parameter(Mandatory = $true)][string]$Json,
      [int]$Depth = 80
    )

    $cmd = Get-Command ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and $cmd.Parameters.ContainsKey('Depth')) {
      return ($Json | ConvertFrom-Json -Depth $Depth)
    }

    Add-Type -AssemblyName System.Web.Extensions | Out-Null
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $serializer.RecursionLimit = [Math]::Max(10, $Depth)
    $serializer.MaxJsonLength = [int]::MaxValue
    return $serializer.DeserializeObject($Json)
  }

  # Prefer the " ui {..}" payload (already JSON)
  $uiIndex = $Line.IndexOf(' ui ')
  if ($uiIndex -ge 0) {
    $candidate = $Line.Substring($uiIndex + 4).Trim()
    if ($candidate.StartsWith('{') -and $candidate.EndsWith('}')) {
      try { return (ConvertFrom-JsonCompat -Json $candidate -Depth 80) } catch { }
    }
  }

  # Next, try payload={...}
  $payloadKey = ' payload='
  $payloadIndex = $Line.IndexOf($payloadKey)
  if ($payloadIndex -ge 0) {
    $candidate = $Line.Substring($payloadIndex + $payloadKey.Length).Trim()
    if ($candidate.StartsWith('{') -and $candidate.EndsWith('}')) {
      try { return (ConvertFrom-JsonCompat -Json $candidate -Depth 120) } catch { }
    }
  }

  return $null
}

function Get-UiEventObject {
  param(
    [Parameter(Mandatory = $true)]$Obj
  )

  function Get-PropValue {
    param(
      [Parameter(Mandatory = $true)]$Target,
      [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Target) { return $null }

    if ($Target -is [System.Collections.IDictionary]) {
      # Some IDictionary implementations (e.g., Hashtable) implement IDictionary.Contains explicitly,
      # so call via Keys collection for compatibility.
      if ($Target.Keys -contains $Name) { return $Target[$Name] }
      return $null
    }

    $p = $Target.PSObject.Properties[$Name]
    if ($null -ne $p) { return $p.Value }

    return $null
  }

  # Case A: already the event object (ui {...})
  if ($null -ne (Get-PropValue -Target $Obj -Name 'event')) { return $Obj }

  # Case B: wrapper payload { type: "fs_ui_log", payload: {event: ...}}
  $payload = Get-PropValue -Target $Obj -Name 'payload'
  if ($null -ne $payload -and $null -ne (Get-PropValue -Target $payload -Name 'event')) { return $payload }

  # Case C: sometimes payload is nested twice
  $payload2 = $null
  if ($null -ne $payload) {
    $payload2 = Get-PropValue -Target $payload -Name 'payload'
  }
  if ($null -ne $payload2 -and $null -ne (Get-PropValue -Target $payload2 -Name 'event')) { return $payload2 }

  return $null
}

if (-not (Test-Path -LiteralPath $LogPath)) {
  throw "Log file not found: $LogPath"
}

$lines = Get-Content -LiteralPath $LogPath -Encoding UTF8

$versions = New-Object System.Collections.Generic.HashSet[string]
$summaryCount = 0
$minVisible = $null
$maxVisible = $null

$modeCounts = @{}
$compactCount = 0
$emergencyTrueCount = 0
$fallbackTrueCount = 0

$compactEscapeAttemptCount = 0
$compactEscapeResultCount = 0
$compactEscapeSuccessCount = 0

$visibleLe1Indices = New-Object System.Collections.Generic.List[int]

$fallbackLineIndices = New-Object System.Collections.Generic.List[int]
$emergencyLineIndices = New-Object System.Collections.Generic.List[int]

$compactEscapeAttemptLineIndices = New-Object System.Collections.Generic.List[int]
$compactEscapeResultLineIndices = New-Object System.Collections.Generic.List[int]

for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]

  if ($line -match '"v"\s*:\s*"(fsjs-[^"]+)"') {
    [void]$versions.Add($Matches[1])
  }

  if ($line -match 'toolbar_filter_fallback') {
    $fallbackLineIndices.Add($i) | Out-Null
  }

  if ($line -match 'toolbar_filter_emergency') {
    $emergencyLineIndices.Add($i) | Out-Null
  }

    if ($line -match 'toolbar_compact_escape_attempt') {
      $compactEscapeAttemptLineIndices.Add($i) | Out-Null
      $obj = Try-ExtractJson -Line $line
      if ($null -ne $obj) {
        $evt = Get-UiEventObject -Obj $obj
        if ($null -ne $evt) {
          $evtName = $evt
          if ($evt -is [System.Collections.IDictionary]) { $evtName = $evt['event'] } else { $evtName = $evt.event }
          if ($evtName -eq 'toolbar_compact_escape_attempt') { $compactEscapeAttemptCount++ }
        }
      }
    }

    if ($line -match 'toolbar_compact_escape_result') {
      $compactEscapeResultLineIndices.Add($i) | Out-Null
      $obj = Try-ExtractJson -Line $line
      if ($null -ne $obj) {
        $evt = Get-UiEventObject -Obj $obj
        if ($null -ne $evt) {
          $evtName = $evt
          if ($evt -is [System.Collections.IDictionary]) { $evtName = $evt['event'] } else { $evtName = $evt.event }
          if ($evtName -eq 'toolbar_compact_escape_result') {
            $compactEscapeResultCount++
            $success = if ($evt -is [System.Collections.IDictionary]) { $evt['success'] } else { $evt.success }
            if ($true -eq $success) { $compactEscapeSuccessCount++ }
          }
        }
      }
    }

  if ($line -notmatch 'toolbar_filter_summary') { continue }

  $obj = Try-ExtractJson -Line $line
  if ($null -eq $obj) { continue }

  $evt = Get-UiEventObject -Obj $obj
  if ($null -eq $evt) { continue }

  $evtName = $evt
  if ($evt -is [System.Collections.IDictionary]) { $evtName = $evt['event'] } else { $evtName = $evt.event }
  if ($evtName -ne 'toolbar_filter_summary') { continue }

  $summaryCount++

  $visible = if ($evt -is [System.Collections.IDictionary]) { $evt['visibleActions'] } else { $evt.visibleActions }
  if ($visible -is [ValueType]) {
    if ($null -eq $minVisible -or $visible -lt $minVisible) { $minVisible = $visible }
    if ($null -eq $maxVisible -or $visible -gt $maxVisible) { $maxVisible = $visible }

    if ($visible -le 1) {
      $visibleLe1Indices.Add($i) | Out-Null
    }
  }

  $compactMode = if ($evt -is [System.Collections.IDictionary]) { $evt['compactMode'] } else { $evt.compactMode }
  $emergencyActive = if ($evt -is [System.Collections.IDictionary]) { $evt['emergencyActive'] } else { $evt.emergencyActive }
  $fallbackActive = if ($evt -is [System.Collections.IDictionary]) { $evt['fallbackActive'] } else { $evt.fallbackActive }

  if ($true -eq $compactMode) { $compactCount++ }
  if ($true -eq $emergencyActive) { $emergencyTrueCount++ }
  if ($true -eq $fallbackActive) { $fallbackTrueCount++ }

  $modeVal = if ($evt -is [System.Collections.IDictionary]) { $evt['mode'] } else { $evt.mode }
  $mode = [string]$modeVal
  if ([string]::IsNullOrWhiteSpace($mode)) { $mode = '(none)' }
  if (-not $modeCounts.ContainsKey($mode)) { $modeCounts[$mode] = 0 }
  $modeCounts[$mode] = [int]$modeCounts[$mode] + 1
}

Write-Report "=== FortuneSheet toolbar log analysis ==="
Write-Report "Log: $LogPath"
Write-Report "Lines: $($lines.Count)"
Write-Report ""

if ($versions.Count -gt 0) {
  Write-Report "Versions (v):"
  $versions | Sort-Object | ForEach-Object { Write-Host "  - $_" }
  # 버전 목록은 길어질 수 있어 test.log에는 개별 라인을 남기지 않는다.
  Write-Report "" -NoTestLog
} else {
  Write-Report "Versions (v): (none found)"
  Write-Report ""
}

Write-Report "toolbar_filter_summary: $summaryCount"
Write-Report "compactMode:true count: $compactCount"
Write-Report "emergencyActive:true count: $emergencyTrueCount"
Write-Report "fallbackActive:true count: $fallbackTrueCount"
Write-Report "toolbar_compact_escape_attempt count: $compactEscapeAttemptCount"
Write-Report "toolbar_compact_escape_result count: $compactEscapeResultCount"
Write-Report "toolbar_compact_escape_result success:true count: $compactEscapeSuccessCount"
Write-Report "visibleActions min/max: $minVisible / $maxVisible"
Write-Report "visibleActions<=1 occurrences (from summary): $($visibleLe1Indices.Count)"
Write-Report "toolbar_filter_fallback lines: $($fallbackLineIndices.Count)"
Write-Report "toolbar_filter_emergency lines: $($emergencyLineIndices.Count)"
Write-Report ""

Write-Report "Top modes:" 
$modeCounts.GetEnumerator() |
  Sort-Object -Property Value -Descending |
  Select-Object -First 10 |
  ForEach-Object { Write-Host ("  - {0}: {1}" -f $_.Key, $_.Value) }
Write-Report "" -NoTestLog

function Print-Context {
  param(
    [Parameter(Mandatory = $true)][int]$Index,
    [Parameter(Mandatory = $true)][string]$Header
  )

  $start = [Math]::Max(0, $Index - $ContextLines)
  $end = [Math]::Min($lines.Count - 1, $Index + $ContextLines)

  Write-Host "--- $Header (lineIndex=$Index) ---"
  for ($j = $start; $j -le $end; $j++) {
    $prefix = if ($j -eq $Index) { '>>' } else { '  ' }
    Write-Host ("{0} [{1}] {2}" -f $prefix, $j, $lines[$j])
  }
  Write-Host ""
}

if ($visibleLe1Indices.Count -gt 0) {
  Write-Report "Contexts for visibleActions<=1 (first 5):" -NoTestLog
  $visibleLe1Indices | Select-Object -First 5 | ForEach-Object {
    Print-Context -Index $_ -Header 'visibleActions<=1'
  }
} else {
  Write-Report "No visibleActions<=1 found in toolbar_filter_summary." 
  Write-Report ""
}

if ($fallbackLineIndices.Count -gt 0) {
  Write-Report "Contexts for toolbar_filter_fallback lines (first 5):" -NoTestLog
  $fallbackLineIndices | Select-Object -First 5 | ForEach-Object {
    Print-Context -Index $_ -Header 'toolbar_filter_fallback'
  }
} else {
  Write-Report "No toolbar_filter_fallback lines found." 
  Write-Report ""
}

if ($emergencyLineIndices.Count -gt 0) {
  Write-Report "Contexts for toolbar_filter_emergency lines (first 5):" -NoTestLog
  $emergencyLineIndices | Select-Object -First 5 | ForEach-Object {
    Print-Context -Index $_ -Header 'toolbar_filter_emergency'
  }
} else {
  Write-Report "No toolbar_filter_emergency lines found." 
  Write-Report ""
}

  if ($compactEscapeAttemptLineIndices.Count -gt 0) {
    Write-Report "Contexts for toolbar_compact_escape_attempt lines (first 5):" -NoTestLog
    $compactEscapeAttemptLineIndices | Select-Object -First 5 | ForEach-Object {
      Print-Context -Index $_ -Header 'toolbar_compact_escape_attempt'
    }
  } else {
    Write-Report "No toolbar_compact_escape_attempt lines found." 
    Write-Report ""
  }

  if ($compactEscapeResultLineIndices.Count -gt 0) {
    Write-Report "Contexts for toolbar_compact_escape_result lines (first 5):" -NoTestLog
    $compactEscapeResultLineIndices | Select-Object -First 5 | ForEach-Object {
      Print-Context -Index $_ -Header 'toolbar_compact_escape_result'
    }
  } else {
    Write-Report "No toolbar_compact_escape_result lines found." 
    Write-Report ""
  }

Write-TestLogLine -Message "END runId=$runId"
