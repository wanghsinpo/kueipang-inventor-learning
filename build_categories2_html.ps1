## build_categories2_html.ps1
## Enhanced categories page with clickable category headers + part listing.

$desk = "$env:USERPROFILE\Desktop\test"
$csv = Import-Csv (Join-Path $desk 'parts_index.csv')
$outHtml = Join-Path $desk 'categories2.html'

function Get-Category($name) {
    $n = ($name -replace '^round\d+_','').ToLower()
    if ($n -match 'stator') { return 'Stator' }
    if ($n -match 'rotor') { return 'Rotor' }
    if ($n -match 'screw|bolt|m\d+x') { return 'Screw' }
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
    if ($n -match 'gearbox|gear') { return 'Gearbox' }
    if ($n -match 'connector|fitting') { return 'Connector' }
    if ($n -match 'cover|housing|base') { return 'Cover/Housing' }
    return 'Other'
}

$groups = @{}
foreach ($row in $csv) {
    $cat = Get-Category $row.Folder
    if (-not $groups.ContainsKey($cat)) {
        $groups[$cat] = New-Object 'System.Collections.ArrayList'
    }
    [void]$groups[$cat].Add($row)
}

$body = ""
$sorted = $groups.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending
foreach ($g in $sorted) {
    $cat = $g.Key
    $parts = $g.Value
    $pass = ($parts | Where-Object { $_.Result -eq 'PASS' }).Count
    $passPct = if ($parts.Count -gt 0) { [Math]::Round($pass * 100.0 / $parts.Count, 1) } else { 0 }
    $catId = ($cat -replace '\W','_').ToLower()

    $partList = ""
    foreach ($p in $parts | Sort-Object Folder) {
        $rClass = $p.Result.ToLower()
        $dims = ''
        if ($p.OD_mm) { $dims = "OD$($p.OD_mm)" }
        if ($p.Thick_mm) { $dims += " T$($p.Thick_mm)" }
        $partList += "<li class='$rClass'><a href='$($p.Folder)/'>$($p.Folder -replace '^round\d+_','')</a> <span class='dim'>$dims</span></li>`n"
    }

    $body += @"
<details class='cat' id='$catId'>
  <summary>
    <span class='cat-name'>$cat</span>
    <span class='cat-stats'>$($parts.Count) parts • $pass PASS ($passPct%)</span>
  </summary>
  <ul class='part-list'>
$partList
  </ul>
</details>
"@
}

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Parts by Category (Expandable)</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; max-width: 1200px; margin: 0 auto; }
  h1 { color: #f0c040; }
  details.cat { background: #161b22; border-radius: 6px; margin-bottom: 8px; padding: 0; }
  summary { padding: 12px 16px; cursor: pointer; display: flex; justify-content: space-between; }
  summary:hover { background: #1c2128; }
  .cat-name { color: #58a6ff; font-weight: bold; font-size: 16px; }
  .cat-stats { color: #8b949e; font-size: 13px; }
  .part-list { list-style: none; padding: 0 16px 12px 16px; margin: 0; columns: 3; column-gap: 16px; }
  .part-list li { padding: 4px 0; font-size: 12px; }
  .part-list a { color: #c9d1d9; text-decoration: none; }
  .part-list a:hover { color: #58a6ff; text-decoration: underline; }
  .part-list .dim { color: #8b949e; font-size: 11px; }
  li.pass a::before { content: '✓ '; color: #3fb950; }
  li.fail a::before { content: '✘ '; color: #f85149; }
  li.skip a::before { content: '⚡ '; color: #d29922; }
  li.doc a::before { content: '📄 '; }
  li.defer a::before { content: '◇ '; color: #a371f7; }
  @media (max-width: 800px) { .part-list { columns: 1; } }
</style>
</head>
<body>
<h1>📦 Parts by Category — Expandable</h1>
<p style='color: #8b949e'>Click each category to expand/collapse part list.</p>

$body

<p style='color: #8b949e; font-size: 11px; margin-top: 24px'>
  <a href='index.html'>← Browser</a> •
  <a href='stats.html'>📊 Stats</a> •
  <a href='categories.html'>Categories (chart view)</a>
</p>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml"
