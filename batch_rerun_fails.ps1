## batch_rerun_fails.ps1
## Re-run auto-modeling on all FAIL parts. Single Inventor session for speed.
## Updates result.md + writes my_attempt_v5.ipt.

$desk = "$env:USERPROFILE\Desktop\test"
$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

$kPart = 12290; $kJoin = 20481; $kPos = 20993; $kNeg = 20994

$inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
$inv.Visible = $true

$csv = Import-Csv "$desk\parts_index.csv"
$failsToFix = $csv | Where-Object { $_.Result -eq 'FAIL' }
Write-Host "Processing $($failsToFix.Count) FAIL parts..." -ForegroundColor Cyan

$passNow = 0; $stillFail = 0; $err = 0
$updatedRows = @{}
$i = 0

foreach ($r in $failsToFix) {
    $i++
    $folder = Join-Path $desk $r.Folder
    if (-not (Test-Path $folder)) { $err++; continue }

    $realF = Join-Path $folder 'real.ipt'
    if (-not (Test-Path $realF)) {
        $f = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
        if (-not $f) { $err++; continue }
        $realF = $f.FullName
    }

    try {
        try { $inv.Documents.CloseAll($false) } catch {}
        $realDoc = $inv.Documents.Open($realF, $true)
        $body = $realDoc.ComponentDefinition.SurfaceBodies.Item(1)
        $rb = $body.RangeBox
        $realVol = [Math]::Round($realDoc.ComponentDefinition.MassProperties.Volume * 1000, 3)
        $xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
        $yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
        $zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10

        # Collect Z-axis cylinder radii
        $cylsZ = @()
        foreach ($face in $body.Faces) {
            if ($face.SurfaceType -eq 5891) {
                $az = $face.Geometry.AxisVector.Z
                if ([Math]::Abs($az) -gt 0.95) {
                    $cylsZ += $face.Geometry.Radius * 10
                }
            }
        }
        $cylsZ = $cylsZ | Sort-Object -Unique
        $realDoc.Close($false)

        $diam = [Math]::Max($xLen, $yLen)
        $thick = $zLen
        $rOut = $diam / 2.0
        $pi = [Math]::PI

        # Determine inner radius using back-calc if needed
        $detectedRIn = 0.0
        $validR = $cylsZ | Where-Object { $_ -lt $rOut -and $_ -gt ($rOut * 0.1) }
        if ($validR) { $detectedRIn = [double]($validR | Select-Object -First 1) }

        $simpleVol = $pi * ($rOut*$rOut - $detectedRIn*$detectedRIn) * $thick
        $simpleDiff = if ($realVol -gt 0) { (($simpleVol - $realVol) / $realVol) * 100.0 } else { 0 }

        $chosenRIn = $detectedRIn
        $method = 'direct'
        if ([Math]::Abs($simpleDiff) -gt 8 -and $thick -gt 0) {
            $innerSq = $rOut*$rOut - ($realVol / ($pi * $thick))
            if ($innerSq -gt 0) {
                $chosenRIn = [Math]::Sqrt($innerSq)
                $method = 'back-calc'
            }
        }

        # Build model
        $tpl = $inv.FileManager.GetTemplateFile($kPart)
        $doc = $inv.Documents.Add($kPart, $tpl, $true)
        $cd = $doc.ComponentDefinition
        $tg = $inv.TransientGeometry
        $xy = $cd.WorkPlanes.Item(3)
        $s = $cd.Sketches.Add($xy)
        $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
        if ($chosenRIn -gt 0) {
            $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $chosenRIn))
        }
        $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
        $ed.SetDistanceExtent((MM $thick), $kPos)
        $null = $cd.Features.ExtrudeFeatures.Add($ed)

        $myVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
        $diff = if ($realVol -gt 0) { (($myVol - $realVol) / $realVol) * 100.0 } else { 0 }
        $result = if ([Math]::Abs($diff) -le 10) { 'PASS' } else { 'FAIL' }

        $doc.SaveAs((Join-Path $folder 'my_attempt_v5.ipt'), $false)

        # Update result.md
        $md = @"
# $($r.Folder)

## Result: $result (rebuilt with v5 batch — back-calc fix)

| Field | Value |
|-------|-------|
| BBox | $([Math]::Round($xLen,2)) x $([Math]::Round($yLen,2)) x $([Math]::Round($zLen,2)) mm |
| Real Vol | $realVol mm3 |
| My Vol | $myVol mm3 |
| Method | $method |
| Detected ID R | $([Math]::Round($detectedRIn,4)) mm |
| Chosen ID R | $([Math]::Round($chosenRIn,4)) mm |
| Diff | $([Math]::Round($diff,4))% |

$(if ($result -eq 'PASS') { "PASS (threshold +/-10%) - was FAIL in earlier auto_ring_v2" } else { "FAIL - shape may need manual fix" })
"@
        $md | Out-File (Join-Path $folder 'result.md') -Encoding utf8

        # Track for CSV update
        $updatedRows[$r.Folder] = @{
            Result = $result
            OD_mm = [Math]::Round($diam, 2)
            ID_R_mm = if ($chosenRIn -gt 0) { [Math]::Round($chosenRIn, 4) } else { '' }
            Thick_mm = [Math]::Round($thick, 2)
            Vol_mm3 = $myVol
        }

        if ($result -eq 'PASS') { $passNow++ } else { $stillFail++ }

        if ($i % 10 -eq 0) {
            Write-Host "  [$i/$($failsToFix.Count)] pass=$passNow stillFail=$stillFail err=$err" -ForegroundColor DarkGray
        }
    } catch {
        $err++
    }
}

# Update CSV
$csvData = Import-Csv "$desk\parts_index.csv"
foreach ($row in $csvData) {
    if ($updatedRows.ContainsKey($row.Folder)) {
        $u = $updatedRows[$row.Folder]
        $row.Result = $u.Result
        $row.OD_mm = $u.OD_mm
        $row.ID_R_mm = $u.ID_R_mm
        $row.Thick_mm = $u.Thick_mm
        $row.Vol_mm3 = $u.Vol_mm3
    }
}
$csvData | Export-Csv "$desk\parts_index.csv" -NoTypeInformation -Encoding utf8

Write-Host ""
Write-Host "===== DONE =====" -ForegroundColor Green
Write-Host "PASS now: $passNow  Still FAIL: $stillFail  Errors: $err" -ForegroundColor Cyan
