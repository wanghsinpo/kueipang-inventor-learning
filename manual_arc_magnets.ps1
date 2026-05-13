## manual_arc_magnets.ps1
## Fix R1124, R1125 — auto_v4 classified as BOX but they're actually rings
## (only 2 cyl faces out of ~68, so ratio < 15% triggered BOX path incorrectly).

param([string[]]$Folders = @('round1124_50x18-magnet-0002-235008', 'round1125_50x18-magnet-0001-237056'))

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }
$kPart = 12290; $kJoin = 20481; $kPos = 20993; $kNeg = 20994

$desk = "$env:USERPROFILE\Desktop\test"
$inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')

foreach ($fname in $Folders) {
    $folder = Join-Path $desk $fname
    Write-Host "`n=== $fname ===" -ForegroundColor Cyan

    $realPath = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
    if (-not $realPath) { Write-Host "No .ipt" -ForegroundColor Red; continue }

    try { $inv.Documents.CloseAll($false) } catch {}
    $realDoc = $inv.Documents.Open($realPath.FullName, $true)
    $body = $realDoc.ComponentDefinition.SurfaceBodies.Item(1)
    $rb = $body.RangeBox
    $bbX = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
    $bbY = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
    $bbZ = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
    $realVol = [Math]::Round($realDoc.ComponentDefinition.MassProperties.Volume * 1000, 1)

    # Find 2 cylinder radii with Z axis
    $zCylR = @()
    foreach ($f in $body.Faces) {
        if ($f.SurfaceType -eq 5891) {
            $axZ = $f.Geometry.AxisVector.Z
            if ([Math]::Abs($axZ) -gt 0.95) {
                $zCylR += [Math]::Round($f.Geometry.Radius * 10, 3)
            }
        }
    }
    $realDoc.Close($false)
    $zCylR = $zCylR | Sort-Object -Unique

    if ($zCylR.Count -lt 2) { Write-Host "Need 2 Z-axis cylinders, got $($zCylR.Count)" -ForegroundColor Yellow; continue }

    $rOut = [double]$zCylR[-1]
    $rIn  = [double]$zCylR[0]
    $thick = [double]$bbZ

    Write-Host "  BBox: $bbX x $bbY x $bbZ  Vol=$realVol" -ForegroundColor Magenta
    Write-Host "  rOut=$rOut rIn=$rIn thick=$thick" -ForegroundColor Magenta

    # Build ring
    $tpl = $inv.FileManager.GetTemplateFile($kPart)
    $doc = $inv.Documents.Add($kPart, $tpl, $true)
    $cd = $doc.ComponentDefinition
    $tg = $inv.TransientGeometry
    $xy = $cd.WorkPlanes.Item(3)

    $s1 = $cd.Sketches.Add($xy)
    $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
    $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
    $ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
    $ed1.SetDistanceExtent((MM $thick), $kPos)
    $f1 = $cd.Features.ExtrudeFeatures.Add($ed1)
    $f1.Name = "01_Ring_OD$([Math]::Round($rOut*2,1))_ID$([Math]::Round($rIn*2,1))_T$([Math]::Round($thick,1))"

    $myVol = [Math]::Round($cd.MassProperties.Volume * 1000, 1)
    $diff = [Math]::Round((($myVol - $realVol) / $realVol) * 100.0, 4)
    $result = if ([Math]::Abs($diff) -le 10) { 'PASS' } else { 'FAIL' }
    Write-Host "  Result: My=$myVol Real=$realVol diff=$diff% $result" -ForegroundColor $(if ($result -eq 'PASS') { 'Green' } else { 'Red' })

    $outPath = Join-Path $folder 'my_attempt_v5_manual.ipt'
    $doc.SaveAs($outPath, $false)

    $md = @"
# $fname

## Result: $result (v5 manual ring fix)

| Field | Value |
|-------|-------|
| BBox | $bbX x $bbY x $bbZ mm |
| Real Vol | $realVol mm3 |
| My Vol | $myVol mm3 |
| Method | manual ring (auto_v4 wrongly chose BOX path) |
| OD | $([Math]::Round($rOut*2,2)) mm |
| ID | $([Math]::Round($rIn*2,2)) mm |
| Thick | $([Math]::Round($thick,2)) mm |
| Diff | $diff% |

$(if ($result -eq 'PASS') { "PASS (threshold +/-10%)" } else { "FAIL" })
"@
    $md | Out-File (Join-Path $folder 'result.md') -Encoding utf8
    Write-Host "  result.md updated" -ForegroundColor Cyan
}
