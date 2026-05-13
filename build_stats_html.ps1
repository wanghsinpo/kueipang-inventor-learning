## build_stats_html.ps1
## Generates stats.html — a one-page dashboard of pipeline progress.
## Reads result.md files and parts_index.csv.

$desk = "$env:USERPROFILE\Desktop\test"
$csv  = Join-Path $desk 'parts_index.csv'
$outHtml = Join-Path $desk 'stats.html'

$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }
$totalFolders = $folders.Count

# Parse all result.md to extract Result type
$resultCounts = @{ PASS = 0; FAIL = 0; SKIP = 0; DEFER = 0; UNKNOWN = 0 }
$diffs = @()
foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (Test-Path $rm) {
        $content = Get-Content $rm -Raw
        if     ($content -match 'Result:\s*PASS')  { $resultCounts['PASS']++ }
        elseif ($content -match 'Result:\s*FAIL')  { $resultCounts['FAIL']++ }
        elseif ($content -match 'Result:\s*SKIP')  { $resultCounts['SKIP']++ }
        elseif ($content -match 'Result:\s*DEFER') { $resultCounts['DEFER']++ }
        else { $resultCounts['UNKNOWN']++ }
        # Try extract diff %
        if ($content -match 'Diff[^|]*\|\s*(-?\d+\.?\d*)\s*%') {
            $diffs += [double]$matches[1]
        }
    }
}

$thumbCount = ($folders | Where-Object { Test-Path (Join-Path $_.FullName 'thumbnail.bmp') }).Count
$realIptCount = ($folders | Where-Object { Test-Path (Join-Path $_.FullName 'real.ipt') }).Count
$myAttemptCount = ($folders | Where-Object {
    (Test-Path (Join-Path $_.FullName 'my_attempt_v3.ipt')) -or
    (Test-Path (Join-Path $_.FullName 'my_attempt_v4.ipt')) -or
    (Test-Path (Join-Path $_.FullName 'my_attempt_v5.ipt')) -or
    (Test-Path (Join-Path $_.FullName 'my_attempt_v5_manual.ipt'))
}).Count

# CSV stats
$csvData = if (Test-Path $csv) { Import-Csv $csv } else { @() }
$csvPass = ($csvData | Where-Object { $_.Result -eq 'PASS' }).Count
$csvFail = ($csvData | Where-Object { $_.Result -eq 'FAIL' }).Count
$csvDefer = ($csvData | Where-Object { $_.Result -eq 'DEFER' }).Count

# Diff histogram (within ±10%)
$diffHistogram = @{}
foreach ($d in $diffs) {
    $bucket = [Math]::Round($d, 0)
    if ($bucket -lt -10) { $bucket = -11 }   # group beyond range
    elseif ($bucket -gt 10) { $bucket = 11 }
    if (-not $diffHistogram.ContainsKey($bucket)) { $diffHistogram[$bucket] = 0 }
    $diffHistogram[$bucket]++
}
$maxHist = ($diffHistogram.Values | Measure-Object -Maximum).Maximum

# Top FAIL/edge cases
$edgeCases = @()
foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (Test-Path $rm) {
        $c = Get-Content $rm -Raw
        if ($c -match 'Diff[^|]*\|\s*(-?\d+\.?\d*)\s*%') {
            $d = [double]$matches[1]
            if ([Math]::Abs($d) -gt 5) {
                $edgeCases += @{ Name = $f.Name; Diff = $d }
            }
        }
    }
}
$edgeCases = $edgeCases | Sort-Object { [Math]::Abs($_.Diff) } -Descending | Select-Object -First 20

# Recent commits (last 30)
$gitLog = & git -C $desk log --pretty='%h|%ar|%s' -30 2>&1
$recentCommits = $gitLog | ForEach-Object {
    $parts = $_ -split '\|'
    if ($parts.Count -ge 3) {
        @{ Hash = $parts[0]; When = $parts[1]; Subject = ($parts[2..($parts.Count-1)] -join '|') }
    }
}

# Build HTML
$histHtml = ""
$buckets = -11..11
foreach ($b in $buckets) {
    $cnt = if ($diffHistogram.ContainsKey($b)) { $diffHistogram[$b] } else { 0 }
    $h = if ($maxHist -gt 0) { [Math]::Round($cnt * 100.0 / $maxHist, 1) } else { 0 }
    $label = if ($b -eq -11) { '<-10' } elseif ($b -eq 11) { '>+10' } else { "$b" }
    $color = if ([Math]::Abs($b) -gt 10) { '#f44' } elseif ([Math]::Abs($b) -gt 5) { '#fa0' } else { '#4c4' }
    $histHtml += "<div class='hbar'><div class='hbar-fill' style='height: ${h}%; background: $color' title='$cnt parts'></div><div class='hbar-label'>$label</div></div>`n"
}

$edgeHtml = ""
foreach ($e in $edgeCases) {
    $color = if ([Math]::Abs($e.Diff) -gt 10) { '#f44' } else { '#fa0' }
    $sign = if ($e.Diff -gt 0) { '+' } else { '' }
    $edgeHtml += "<tr><td><a href='$($e.Name)/' target='_blank'>$($e.Name)</a></td><td style='color: $color; text-align: right'>$sign$([Math]::Round($e.Diff,2))%</td></tr>`n"
}

$commitHtml = ""
foreach ($c in $recentCommits) {
    if ($c) {
        $commitHtml += "<tr><td class='hash'>$($c.Hash)</td><td class='when'>$($c.When)</td><td>$($c.Subject)</td></tr>`n"
    }
}

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Pipeline Stats Dashboard</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; padding: 24px; }
  h1 { color: #f0c040; margin: 0 0 12px 0; font-size: 22px; }
  h2 { color: #58a6ff; margin: 24px 0 12px 0; font-size: 17px; border-bottom: 1px solid #21262d; padding-bottom: 6px; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; margin: 16px 0; }
  .stat-card { background: #161b22; padding: 14px; border-radius: 6px; border: 1px solid #30363d; }
  .stat-num { font-size: 28px; font-weight: bold; }
  .stat-label { color: #8b949e; font-size: 12px; margin-top: 2px; }
  .pass { color: #3fb950; }
  .fail { color: #f85149; }
  .skip { color: #d29922; }
  .defer { color: #a371f7; }
  .histogram { display: flex; height: 180px; gap: 2px; padding: 12px; background: #161b22; border-radius: 6px; align-items: flex-end; }
  .hbar { flex: 1; display: flex; flex-direction: column; align-items: center; }
  .hbar-fill { width: 100%; min-height: 1px; border-radius: 2px 2px 0 0; }
  .hbar-label { font-size: 10px; color: #8b949e; padding-top: 4px; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; background: #161b22; border-radius: 6px; overflow: hidden; }
  th { text-align: left; padding: 8px 12px; background: #21262d; color: #8b949e; font-size: 12px; font-weight: 600; }
  td { padding: 8px 12px; border-top: 1px solid #21262d; font-size: 13px; }
  td.hash { color: #58a6ff; font-family: 'Consolas', monospace; font-size: 11px; }
  td.when { color: #8b949e; font-size: 11px; }
  a { color: #58a6ff; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .progress { background: #21262d; border-radius: 4px; height: 16px; overflow: hidden; margin-top: 6px; position: relative; }
  .progress-fill { background: linear-gradient(90deg, #3fb950, #58a6ff); height: 100%; }
  .progress-text { position: absolute; top: 0; left: 8px; line-height: 16px; font-size: 11px; color: #fff; }
</style>
</head>
<body>
<h1>🔧 Inventor COM Pipeline — Stats Dashboard</h1>

<div class='stats-grid'>
  <div class='stat-card'><div class='stat-num'>$totalFolders</div><div class='stat-label'>Total folders</div></div>
  <div class='stat-card'><div class='stat-num pass'>$($resultCounts['PASS'])</div><div class='stat-label'>PASS</div></div>
  <div class='stat-card'><div class='stat-num fail'>$($resultCounts['FAIL'])</div><div class='stat-label'>FAIL</div></div>
  <div class='stat-card'><div class='stat-num skip'>$($resultCounts['SKIP'])</div><div class='stat-label'>SKIP</div></div>
  <div class='stat-card'><div class='stat-num defer'>$($resultCounts['DEFER'])</div><div class='stat-label'>DEFER</div></div>
  <div class='stat-card'><div class='stat-num'>$thumbCount</div><div class='stat-label'>Thumbnails</div></div>
</div>

<h2>📊 Volume Diff Distribution (auto-modeled parts)</h2>
<div class='histogram'>
$histHtml
</div>
<p style='color: #8b949e; font-size: 11px'>Green = within ±5% • Orange = ±5-10% • Red = exceeds ±10%</p>

<h2>📈 Pipeline Progress</h2>
<div class='progress'><div class='progress-fill' style='width: $([Math]::Round($thumbCount/$totalFolders*100,1))%'></div><div class='progress-text'>Thumbnails: $thumbCount / $totalFolders ($([Math]::Round($thumbCount/$totalFolders*100,1))%)</div></div>
<div class='progress' style='margin-top: 4px'><div class='progress-fill' style='width: $([Math]::Round($myAttemptCount/$totalFolders*100,1))%'></div><div class='progress-text'>My_attempt files: $myAttemptCount / $totalFolders ($([Math]::Round($myAttemptCount/$totalFolders*100,1))%)</div></div>

<h2>🎯 Top Edge Cases (|diff| > 5%)</h2>
<table>
  <tr><th>Folder</th><th style='text-align: right'>Diff</th></tr>
$edgeHtml
</table>

<h2>📝 Recent Commits</h2>
<table>
  <tr><th>Hash</th><th>When</th><th>Subject</th></tr>
$commitHtml
</table>

<p style='color: #8b949e; font-size: 11px; margin-top: 24px'>Generated by build_stats_html.ps1 at $(Get-Date -Format 'yyyy-MM-dd HH:mm') — <a href='index.html'>← Back to browser</a></p>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml" -ForegroundColor Cyan
Write-Host "Folders: $totalFolders  PASS: $($resultCounts['PASS'])  FAIL: $($resultCounts['FAIL'])" -ForegroundColor Green
