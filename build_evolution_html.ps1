## build_evolution_html.ps1
## Auto-generate motor_flange_demo/evolution.html from all existing motor_flange_v*.ipt files.

$desk = "$env:USERPROFILE\Desktop\test"
$dir = Join-Path $desk 'motor_flange_demo'
$outHtml = Join-Path $dir 'evolution.html'

# Find all versions
$versions = Get-ChildItem $dir -Filter 'motor_flange_v*.ipt' | ForEach-Object {
    if ($_.Name -match 'motor_flange_v(\d+)\.ipt') { [int]$matches[1] }
} | Sort-Object -Unique

# Description for each version (ASCII-safe)
$descMap = @{}
$descMap[1]  = 'v1: initial 5 features'
$descMap[2]  = 'v2: added 5 missing (Pocket/CB/M4s/dowels/key)'
$descMap[3]  = 'v3: circle chamfers'
$descMap[4]  = 'v4: plate edge chamfer'
$descMap[5]  = 'v5: corner countersink'
$descMap[6]  = 'v6: hub base fillet'
$descMap[7]  = 'v7: fix fillet/chamfer order'
$descMap[8]  = 'v8: inner keyway + fix M4 angle'
$descMap[9]  = 'v9: outer keyway U-shape'
$descMap[10] = 'v10: STEP+STL export'
$descMap[11] = 'v11: dowel position tweak'
$descMap[12] = 'v12: Plate 88x88 + Hub D52'
$descMap[13] = 'v13: Hub H 8->10'
$descMap[14] = 'v14: Pocket depth 3->4'
$descMap[15] = 'v15: Hub top edge fillet R0.3'
$descMap[16] = 'v16: cleaner chamfer tree'
$descMap[17] = 'v17: checkpoint'
$descMap[18] = 'v18: Plate chamfer 1.0->1.5'
$descMap[19] = 'v19: param polish'
$descMap[20] = 'v20: milestone'
$descMap[21] = 'v21: checkpoint'
$descMap[22] = 'v22: bore 32->30 variant'
$descMap[23] = 'v23: hub fillet R2'
$descMap[24] = 'v24: hub fillet R1'
$descMap[25] = 'v25: back to R1.5 (recommended)'
$descMap[26] = 'v26: checkpoint'
$descMap[27] = 'v27: PlateT 14'
$descMap[28] = 'v28: HubD 55'
$descMap[29] = 'v29: reset hub'
$descMap[30] = 'v30: chamfer 14->10'
$descMap[31] = 'v31: dowel D4'
$descMap[32] = 'v32: PlateT back to 12'
$descMap[33] = 'v33: PlateT 15'
$descMap[34] = 'v34: HubH 12'
$descMap[35] = 'v35: CBDepth 6'
$descMap[36] = 'v36: PocketDepth 5'
$descMap[37] = 'v37: InnerKey D5'
$descMap[38] = 'v38: InnerKey W10'
$descMap[39] = 'v39: M6 mount holes'
$descMap[40] = 'v40: CSink D16'
$descMap[41] = 'v41: compact 75mm'
$descMap[42] = 'v42: large 100mm'

$cards = ""
foreach ($v in $versions) {
    $desc = if ($descMap.ContainsKey($v)) { $descMap[$v] } else { "v$v" }
    $thumb = "evolution_v$v.bmp"
    $thumbPath = Join-Path $dir $thumb
    $img = if (Test-Path $thumbPath) {
        "<img src='$thumb' alt='v$v'>"
    } else {
        "<div style='width:100%; height:120px; background:#222; color:#666; display:flex; align-items:center; justify-content:center; font-size:11px'>no preview</div>"
    }
    $stepLink = if (Test-Path (Join-Path $dir "motor_flange_v$v.step")) { "<a href='motor_flange_v$v.step'>.step</a>" } else { '' }
    $stlLink  = if (Test-Path (Join-Path $dir "motor_flange_v$v.stl"))  { "<a href='motor_flange_v$v.stl'>.stl</a>"  } else { '' }

    $cards += "<div class='ver'><h3>v$v</h3><div class='desc'>$desc</div>$img<div class='links'><a href='motor_flange_v$v.ipt'>.ipt</a> $stepLink $stlLink</div></div>`n"
}

$latest = $versions[-1]
$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>Motor Flange Evolution v1 to v$latest</title>
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
<h1>Motor Flange Evolution v1 -> v$latest ($($versions.Count) versions)</h1>
<p>Each version changes 1-2 parameters or features from previous.</p>

<div class='grid'>
$cards
</div>

<p style='color: #888; font-size: 11px; margin-top: 24px'>
  <a href='compare.html'>Photo vs Model</a> |
  <a href='../index.html'>Parts browser</a>
</p>
</body>
</html>
"@

$html | Out-File $outHtml -Encoding utf8
Write-Host "Written: $outHtml ($($versions.Count) versions)"
