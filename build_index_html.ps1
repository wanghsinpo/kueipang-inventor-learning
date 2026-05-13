## build_index_html.ps1
## Generates index.html — visual thumbnail browser for all round folders.
## Opens in browser; thumbnails link to folder contents.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File build_index_html.ps1

$desk  = Join-Path $env:USERPROFILE 'Desktop\test'
$csv   = Join-Path $desk 'parts_index.csv'
$outHtml = Join-Path $desk 'index.html'

# Load CSV if exists
$indexData = @{}
if (Test-Path $csv) {
    Import-Csv $csv | ForEach-Object {
        $indexData[$_.Folder] = $_
    }
}

# Gather all round folders
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' } | Sort-Object Name

$rows = foreach ($f in $folders) {
    $thumbRel = "$($f.Name)/thumbnail.bmp"
    $thumbAbs = Join-Path $f.FullName 'thumbnail.bmp'
    $hasThumb = Test-Path $thumbAbs

    $csvRow = $indexData[$f.Name]
    $result  = if ($csvRow) { $csvRow.Result  } else { '' }
    $od      = if ($csvRow) { $csvRow.OD_mm   } else { '' }
    $idR     = if ($csvRow) { $csvRow.ID_R_mm } else { '' }
    $thick   = if ($csvRow) { $csvRow.Thick_mm} else { '' }
    $vol     = if ($csvRow) { $csvRow.Vol_mm3 } else { '' }

    $colorClass = switch ($result) {
        'PASS' { 'pass' }
        'FAIL' { 'fail' }
        'SKIP' { 'skip' }
        'DEFER' { 'defer' }
        'DOC'  { 'doc' }
        default { 'unknown' }
    }

    $imgTag = if ($hasThumb) {
        "<img src='$thumbRel' width='160' height='120' loading='lazy' onerror='this.style.display=&quot;none&quot;'>"
    } else {
        "<div class='no-thumb'>No thumbnail</div>"
    }

    $idStr = if ($idR -ne '') { "ID_R=$idR" } else { '' }
    $dimStr = @($od, $idStr, $thick) | Where-Object { $_ -ne '' } | ForEach-Object { $_ }

    @"
<div class='card $colorClass' title='$($f.Name)'>
  <a href='$($f.Name)/' target='_blank'>$imgTag</a>
  <div class='label'>
    <span class='name'>$($f.Name -replace '^round\d+_','')</span>
    <span class='dims'>$($dimStr -join ' | ')</span>
    <span class='vol'>$(if ($vol) { "Vol=$vol mm³" })</span>
    <span class='result result-$($result.ToLower())'>$result</span>
  </div>
</div>
"@
}

$passCount  = ($folders | Where-Object { $indexData[$_.Name] -and $indexData[$_.Name].Result -eq 'PASS' }).Count
$failCount  = ($folders | Where-Object { $indexData[$_.Name] -and $indexData[$_.Name].Result -eq 'FAIL' }).Count
$skipCount  = ($folders | Where-Object { $indexData[$_.Name] -and $indexData[$_.Name].Result -eq 'SKIP' }).Count
$deferCount = ($folders | Where-Object { $indexData[$_.Name] -and $indexData[$_.Name].Result -eq 'DEFER' }).Count
$docCount   = ($folders | Where-Object { $indexData[$_.Name] -and $indexData[$_.Name].Result -eq 'DOC' }).Count
$thumbCount = ($folders | Where-Object { Test-Path (Join-Path $_.FullName 'thumbnail.bmp') }).Count

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Inventor Parts Browser — $($folders.Count) parts</title>
<style>
  body { font-family: Arial, sans-serif; background: #1a1a2e; color: #eee; margin: 0; padding: 16px; }
  h1 { color: #f0c040; margin: 0 0 8px 0; }
  .stats { color: #aaa; margin-bottom: 16px; font-size: 14px; }
  .stats span { margin-right: 16px; }
  .pass-c { color: #4caf50; } .fail-c { color: #f44336; } .skip-c { color: #ff9800; } .defer-c { color: #a371f7; } .doc-c { color: #888; }
  .filter-bar { margin-bottom: 12px; }
  .filter-bar input { background: #2a2a4a; border: 1px solid #555; color: #eee; padding: 6px 12px; border-radius: 4px; width: 300px; font-size: 14px; }
  .filter-bar button { background: #2a2a5a; border: 1px solid #777; color: #eee; padding: 6px 12px; border-radius: 4px; cursor: pointer; margin-left: 8px; }
  .filter-bar button:hover { background: #3a3a7a; }
  .grid { display: flex; flex-wrap: wrap; gap: 12px; }
  .card { width: 180px; background: #16213e; border-radius: 8px; overflow: hidden; border: 2px solid #333; transition: border-color 0.2s; }
  .card:hover { border-color: #f0c040; }
  .card.pass { border-left: 4px solid #4caf50; }
  .card.fail { border-left: 4px solid #f44336; }
  .card.skip { border-left: 4px solid #ff9800; }
  .card.defer { border-left: 4px solid #a371f7; }
  .card.doc { border-left: 4px solid #888; }
  .card img { display: block; width: 160px; height: 120px; object-fit: contain; background: #0f3460; margin: 10px auto 0; }
  .no-thumb { width: 160px; height: 120px; background: #0f3460; display: flex; align-items: center; justify-content: center; color: #555; font-size: 12px; margin: 10px auto 0; }
  .label { padding: 6px 8px; font-size: 11px; }
  .name { display: block; color: #e0e0e0; font-weight: bold; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-bottom: 2px; }
  .dims { display: block; color: #aaa; font-size: 10px; }
  .vol { display: block; color: #88aacc; font-size: 10px; }
  .result { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 10px; font-weight: bold; margin-top: 3px; }
  .result-pass { background: #1b5e20; color: #a5d6a7; }
  .result-fail { background: #b71c1c; color: #ef9a9a; }
  .result-skip { background: #e65100; color: #ffcc80; }
  .result-defer { background: #4a148c; color: #ce93d8; }
  .result-doc { background: #424242; color: #bbbbbb; }
  .result- { background: #333; color: #999; }
  a { text-decoration: none; }
</style>
</head>
<body>
<h1>🔧 Inventor Parts Browser
  <a href='stats.html' style='font-size: 13px; color: #888; margin-left: 12px'>📊 Stats Dashboard</a>
  <a href='motor_flange_demo/evolution.html' style='font-size: 13px; color: #888; margin-left: 12px'>🎨 Motor Flange v1-v16</a>
  <a href='motor_flange_demo/compare.html' style='font-size: 13px; color: #888; margin-left: 12px'>📸 Photo vs Model</a>
</h1>
<div class='stats'>
  <span>Total: <b>$($folders.Count)</b></span>
  <span class='pass-c'>✔ PASS: <b>$passCount</b></span>
  <span class='fail-c'>✘ FAIL: <b>$failCount</b></span>
  <span class='skip-c'>⚡ SKIP: <b>$skipCount</b></span>
  <span class='defer-c'>◇ DEFER: <b>$deferCount</b></span>
  <span class='doc-c'>📄 DOC: <b>$docCount</b></span>
  <span>📷 Thumbnails: <b>$thumbCount</b></span>
</div>
<div class='filter-bar'>
  <input type='text' id='search' placeholder='Search by name, dimensions...' oninput='filterCards()'>
  <button onclick="showOnly('all')">All</button>
  <button onclick="showOnly('pass')">PASS</button>
  <button onclick="showOnly('fail')">FAIL</button>
  <button onclick="showOnly('skip')">SKIP</button>
  <button onclick="showOnly('defer')">DEFER</button>
  <button onclick="showOnly('doc')">DOC</button>
</div>
<div class='grid' id='grid'>
$($rows -join "`n")
</div>
<script>
function filterCards() {
  var q = document.getElementById('search').value.toLowerCase();
  document.querySelectorAll('.card').forEach(function(c) {
    c.style.display = (!q || c.title.toLowerCase().includes(q) || c.innerText.toLowerCase().includes(q)) ? '' : 'none';
  });
}
function showOnly(cls) {
  document.querySelectorAll('.card').forEach(function(c) {
    c.style.display = (cls === 'all' || c.classList.contains(cls)) ? '' : 'none';
  });
  document.getElementById('search').value = '';
}
</script>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml" -ForegroundColor Cyan
Write-Host "Cards: $($rows.Count)  Thumbnails shown: $thumbCount" -ForegroundColor Green
