## build_categories_html.ps1
## Generate categories.html — group parts by name pattern (stator/rotor/ring/etc.)

$desk = "$env:USERPROFILE\Desktop\test"
$csv = Import-Csv (Join-Path $desk 'parts_index.csv')
$outHtml = Join-Path $desk 'categories.html'

# Detect category from folder name
function Get-Category($name) {
    $n = ($name -replace '^round\d+_','').ToLower()
    if ($n -match 'stator') { return 'Stator' }
    if ($n -match 'rotor') { return 'Rotor' }
    if ($n -match 'screw|bolt|m\d+x') { return 'Screw / Bolt' }
    if ($n -match 'magnet') { return 'Magnet' }
    if ($n -match 'bearing') { return 'Bearing' }
    if ($n -match 'sleeve') { return 'Sleeve' }
    if ($n -match 'spacer') { return 'Spacer' }
    if ($n -match 'ring') { return 'Ring' }
    if ($n -match 'shaft') { return 'Shaft' }
    if ($n -match 'flange') { return 'Flange' }
    if ($n -match 'disc') { return 'Disc' }
    if ($n -match 'flinger') { return 'Flinger' }
    if ($n -match 'tube|pipe') { return 'Tube' }
    if ($n -match 'bushing') { return 'Bushing' }
    if ($n -match 'punch') { return 'Punch' }
    if ($n -match 'seal') { return 'Seal' }
    if ($n -match 'washer|gasket') { return 'Washer' }
    if ($n -match 'gearbox|gear') { return 'Gearbox / Gear' }
    if ($n -match 'connector|fitting') { return 'Connector' }
    if ($n -match 'cover|housing|base') { return 'Cover / Housing' }
    return 'Other'
}

# Group + count
$groups = @{}
foreach ($row in $csv) {
    $cat = Get-Category $row.Folder
    if (-not $groups.ContainsKey($cat)) {
        $groups[$cat] = @{ Total = 0; PASS = 0; FAIL = 0; SKIP = 0; DOC = 0; Parts = New-Object 'System.Collections.ArrayList' }
    }
    $groups[$cat].Total++
    $groups[$cat][$row.Result]++
    [void]$groups[$cat].Parts.Add($row)
}

# Build HTML
$catRows = ""
$sorted = $groups.GetEnumerator() | Sort-Object { $_.Value.Total } -Descending
foreach ($g in $sorted) {
    $cat = $g.Key
    $info = $g.Value
    $passPct = if ($info.Total -gt 0) { [Math]::Round($info.PASS / $info.Total * 100, 0) } else { 0 }
    $catRows += @"
<div class='cat-row'>
  <div class='cat-name'>$cat</div>
  <div class='cat-count'>$($info.Total) parts</div>
  <div class='cat-bar'>
    <div class='bar pass' style='width: $($info.PASS / $info.Total * 100)%' title='PASS $($info.PASS)'></div>
    <div class='bar fail' style='width: $($info.FAIL / $info.Total * 100)%' title='FAIL $($info.FAIL)'></div>
    <div class='bar skip' style='width: $($info.SKIP / $info.Total * 100)%' title='SKIP $($info.SKIP)'></div>
    <div class='bar doc' style='width: $($info.DOC / $info.Total * 100)%' title='DOC $($info.DOC)'></div>
  </div>
  <div class='cat-pct'>$passPct% PASS</div>
</div>
"@
}

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Parts by Category</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; max-width: 1100px; margin: 0 auto; }
  h1 { color: #f0c040; }
  .cat-row { display: grid; grid-template-columns: 200px 100px 1fr 100px; align-items: center; gap: 12px; padding: 8px; border-bottom: 1px solid #21262d; }
  .cat-name { color: #58a6ff; font-weight: bold; }
  .cat-count { color: #8b949e; font-size: 13px; }
  .cat-bar { background: #161b22; height: 18px; border-radius: 4px; overflow: hidden; display: flex; }
  .bar { height: 100%; }
  .bar.pass { background: #3fb950; }
  .bar.fail { background: #f85149; }
  .bar.skip { background: #d29922; }
  .bar.doc { background: #888; }
  .cat-pct { color: #3fb950; font-size: 13px; font-weight: bold; text-align: right; }
  a { color: #58a6ff; }
</style>
</head>
<body>
<h1>📦 Parts by Category</h1>
<p style='color: #8b949e'>Auto-grouped from folder names. Total: $($csv.Count) parts.</p>

$catRows

<p style='color: #8b949e; font-size: 11px; margin-top: 24px'>
  <a href='index.html'>← Browser</a> •
  <a href='stats.html'>📊 Stats</a> •
  <a href='cheatsheet.html'>📖 Cheatsheet</a>
</p>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml" -ForegroundColor Cyan
Write-Host "$($groups.Count) categories"
