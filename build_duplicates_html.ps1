## build_duplicates_html.ps1
## Generate duplicates.html — visual page of duplicate part groups.

$desk = "$env:USERPROFILE\Desktop\test"
$dupCsv = Join-Path $desk 'duplicates.csv'
if (-not (Test-Path $dupCsv)) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $desk 'find_duplicates.ps1') | Out-Null
}
$dups = Import-Csv $dupCsv

# Group by Group column
$groups = $dups | Group-Object Group | Sort-Object { [int]$_.Name }

$body = ""
foreach ($g in $groups) {
    $items = $g.Group
    $p = $items[0]
    $count = $items.Count
    $od = $p.OD_mm
    $t = $p.Thick_mm
    $v = $p.Vol_mm3
    $body += "<div class='group'>`n  <h3>Group $($g.Name) — $count parts &nbsp;<span class='dim'>OD$od T$t Vol≈$v mm³</span></h3>`n  <div class='parts'>`n"
    foreach ($it in $items) {
        $folder = $it.Folder
        $thumb = "$folder/thumbnail.bmp"
        $body += "    <div class='part'><a href='$folder/' target='_blank'><img src='$thumb' onerror='this.style.display=&quot;none&quot;'></a><div class='name'>$($folder -replace '^round\d+_','')</div></div>`n"
    }
    $body += "  </div>`n</div>`n"
}

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Duplicate Parts</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; max-width: 1200px; margin: 0 auto; }
  h1 { color: #f0c040; }
  .group { background: #161b22; border-radius: 6px; padding: 12px; margin-bottom: 16px; }
  .group h3 { color: #58a6ff; margin: 0 0 8px 0; font-size: 14px; }
  .group .dim { color: #8b949e; font-size: 12px; font-weight: normal; }
  .parts { display: flex; flex-wrap: wrap; gap: 10px; }
  .part { width: 120px; }
  .part img { width: 100%; height: 90px; object-fit: contain; background: #0f3460; border-radius: 4px; }
  .part .name { color: #c9d1d9; font-size: 10px; word-break: break-all; padding-top: 4px; line-height: 1.3; }
  a { color: #58a6ff; text-decoration: none; }
</style>
</head>
<body>
<h1>🔁 Duplicate Parts</h1>
<p style='color: #8b949e'>$($groups.Count) groups containing $($dups.Count) parts (same OD/Thick/Vol).</p>

$body

<p style='color: #8b949e; font-size: 11px; margin-top: 24px'>
  <a href='index.html'>← Browser</a> •
  <a href='stats.html'>📊 Stats</a>
</p>
</body>
</html>
"@

$out = Join-Path $desk 'duplicates.html'
$html | Out-File $out -Encoding utf8
Write-Host "Written: $out"
