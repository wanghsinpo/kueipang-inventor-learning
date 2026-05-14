## build_evolution_html.ps1
## Auto-generate motor_flange_demo/evolution.html from all existing motor_flange_v*.ipt files.

$desk = "$env:USERPROFILE\Desktop\test"
$dir = Join-Path $desk 'motor_flange_demo'
$outHtml = Join-Path $dir 'evolution.html'

# Find all versions
$versions = Get-ChildItem $dir -Filter 'motor_flange_v*.ipt' | ForEach-Object {
    if ($_.Name -match 'motor_flange_v(\d+)\.ipt') {
        [int]$matches[1]
    }
} | Sort-Object -Unique

$descMap = @{
    1='初版 5 features'; 2='加 5 個遺漏 (Pocket/CounterBore/M4s/dowels/key)'; 3='加圓孔倒角'
    4='加 plate edge chamfer'; 5='加 corner countersink'; 6='加 hub base fillet'
    7='修 fillet+chamfer 順序'; 8='加 inner keyway + 修 M4 角度'; 9='outer keyway U 形'
    10='STEP+STL export'; 11='dowel 位置調整'; 12='Plate 88x88 + Hub D52'
    13='Hub H 8→10'; 14='Pocket depth 3→4'; 15='Hub top edge fillet R0.3'
    16='Cleaner chamfer tree'; 17='checkpoint'; 18='Plate chamfer 1.0→1.5'
    19='param polish'; 20='milestone'; 21='checkpoint'
    22='bore Ø30 variant'; 23='hub fillet R2'; 24='hub fillet R1'; 25='back to R1.5 (recommended)'
    26='checkpoint'; 27='PlateT 14'; 28='HubD 55'; 29='reset hub'; 30='chamfer 10'
    31='dowel Ø4'; 32='PlateT back to 12'; 33='PlateT 15'; 34='HubH 12'; 35='CBDepth 6'
    36='PocketDepth 5'; 37='InnerKey D5'; 38='InnerKey W10'; 39='M6 mount holes'; 40='CSink Ø16'
    41='compact 75mm'; 42='large 100mm'
}

$cards = ""
foreach ($v in $versions) {
    $desc = if ($descMap.ContainsKey($v)) { $descMap[$v] } else { '...' }
    $thumb = "evolution_v$v.bmp"
    $thumbPath = Join-Path $dir $thumb
    $img = if (Test-Path $thumbPath) {
        "<img src='$thumb' alt='v$v'>"
    } else {
        "<div style='width:100%; height:120px; background:#222; color:#666; display:flex; align-items:center; justify-content:center; font-size:11px'>no preview</div>"
    }
    $stepLink = if (Test-Path (Join-Path $dir "motor_flange_v$v.step")) {
        "<a href='motor_flange_v$v.step'>.step</a>"
    } else { '' }
    $stlLink = if (Test-Path (Join-Path $dir "motor_flange_v$v.stl")) {
        "<a href='motor_flange_v$v.stl'>.stl</a>"
    } else { '' }

    $cards += @"
<div class='ver'>
  <h3>v$v</h3>
  <div class='desc'>$desc</div>
  $img
  <div class='links'><a href='motor_flange_v$v.ipt'>.ipt</a> $stepLink $stlLink</div>
</div>
"@
}

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Motor Flange Evolution v1 → v$($versions[-1])</title>
<style>
  body { font-family: Arial, sans-serif; background: #1a1a2e; color: #eee; margin: 0; padding: 16px; }
  h1 { color: #f0c040; margin: 0 0 8px 0; }
  p { color: #aaa; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 12px; }
  .ver { background: #16213e; border-radius: 6px; padding: 10px; border: 2px solid #333; }
  .ver h3 { color: #58a6ff; margin: 0 0 4px 0; font-size: 14px; }
  .ver .desc { color: #aaa; font-size: 11px; margin-bottom: 8px; min-height: 26px; }
  .ver img { display: block; width: 100%; max-width: 240px; border-radius: 4px; background: #0f3460; }
  .ver .links { font-size: 10px; color: #888; margin-top: 6px; }
  .ver .links a { color: #58a6ff; margin-right: 8px; text-decoration: none; }
</style>
</head>
<body>
<h1>🔧 Motor Flange — v1 → v$($versions[-1]) Evolution ($($versions.Count) versions)</h1>
<p>從用戶照片建模的演化過程。每個版本只變 1-2 個參數或 feature。</p>

<div class='grid'>
$cards
</div>

<p style='color: #888; font-size: 11px; margin-top: 24px'>
  <a href='compare.html'>← Photo vs Model comparison</a> •
  <a href='../index.html'>← Parts browser</a>
</p>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml ($($versions.Count) versions)"
