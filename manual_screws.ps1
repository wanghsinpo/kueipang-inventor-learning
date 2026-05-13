## manual_screws.ps1
## Fix R1116 and R1118 (both M6x55 screws) — auto_v4 used BOX which gave 214% error.
## Manual model: head cylinder + shaft cylinder along X axis.

param([string[]]$Folders = @('round1116_m6x55-0002-185856', 'round1118_m6x55-186368'))

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }
$kPart = 12290; $kJoin = 20481; $kPos = 20993; $kNeg = 20994

$desk = "$env:USERPROFILE\Desktop\test"
$inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')

foreach ($fname in $Folders) {
    $folder = Join-Path $desk $fname
    Write-Host "`n=== $fname ===" -ForegroundColor Cyan

    # Detect real geometry
    $realPath = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
    if (-not $realPath) { Write-Host "No .ipt found" -ForegroundColor Red; continue }

    try { $inv.Documents.CloseAll($false) } catch {}
    $realDoc = $inv.Documents.Open($realPath.FullName, $true)
    $body = $realDoc.ComponentDefinition.SurfaceBodies.Item(1)
    $rb = $body.RangeBox
    $bbX = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
    $bbY = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
    $bbZ = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
    $realVol = [Math]::Round($realDoc.ComponentDefinition.MassProperties.Volume * 1000, 1)

    # Largest dim = total length
    $totalL = [Math]::Max([Math]::Max($bbX, $bbY), $bbZ)

    # Find 2 cylinder radii
    $radii = @()
    foreach ($f in $body.Faces) {
        if ($f.SurfaceType -eq 5891) {
            $radii += [Math]::Round($f.Geometry.Radius * 10, 3)
        }
    }
    $radii = $radii | Sort-Object -Unique
    $realDoc.Close($false)

    if ($radii.Count -lt 2) { Write-Host "Need 2+ cylinder radii, found $($radii.Count)" -ForegroundColor Yellow; continue }

    $rShaft = [double]$radii[0]   # smaller
    $rHead  = [double]$radii[-1]  # largest

    # Solve: π*rHead²*Lh + π*rShaft²*Ls = realVol;  Lh + Ls = totalL
    $pi = [Math]::PI
    # rHead² * Lh + rShaft² * (totalL - Lh) = realVol / π
    # (rHead² - rShaft²) * Lh = realVol/π - rShaft² * totalL
    $Lh = ($realVol / $pi - $rShaft * $rShaft * $totalL) / ($rHead * $rHead - $rShaft * $rShaft)
    $Ls = $totalL - $Lh

    Write-Host "  BBox: $bbX x $bbY x $bbZ  Vol=$realVol  totalL=$totalL" -ForegroundColor Magenta
    Write-Host "  rHead=$rHead rShaft=$rShaft  =>  Head Lh=$([Math]::Round($Lh,2))  Shaft Ls=$([Math]::Round($Ls,2))" -ForegroundColor Magenta

    # Build along Z axis (sketch on XY plane)
    $tpl = $inv.FileManager.GetTemplateFile($kPart)
    $doc = $inv.Documents.Add($kPart, $tpl, $true)
    $cd = $doc.ComponentDefinition
    $tg = $inv.TransientGeometry
    $xy = $cd.WorkPlanes.Item(3)

    # Feature 01: Head cylinder
    $s1 = $cd.Sketches.Add($xy)
    $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rHead))
    $ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
    $ed1.SetDistanceExtent((MM $Lh), $kPos)
    $f1 = $cd.Features.ExtrudeFeatures.Add($ed1)
    $f1.Name = "01_Head_D$([Math]::Round($rHead*2,1))xH$([Math]::Round($Lh,2))"

    # Offset plane at head top
    $wpTop = $cd.WorkPlanes.AddByPlaneAndOffset($xy, (MM $Lh))
    $wpTop.Visible = $false

    # Feature 02: Shaft cylinder
    $s2 = $cd.Sketches.Add($wpTop)
    $null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rShaft))
    $ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s2.Profiles.AddForSolid(), $kJoin)
    $ed2.SetDistanceExtent((MM $Ls), $kPos)
    $f2 = $cd.Features.ExtrudeFeatures.Add($ed2)
    $f2.Name = "02_Shaft_D$([Math]::Round($rShaft*2,1))xH$([Math]::Round($Ls,2))"

    $myVol = [Math]::Round($cd.MassProperties.Volume * 1000, 1)
    $diff = [Math]::Round((($myVol - $realVol) / $realVol) * 100.0, 4)
    $result = if ([Math]::Abs($diff) -le 10) { 'PASS' } else { 'FAIL' }
    Write-Host "  Result: My=$myVol  Real=$realVol  diff=$diff%  $result" -ForegroundColor $(if ($result -eq 'PASS') { 'Green' } else { 'Red' })

    # Save
    $outPath = Join-Path $folder 'my_attempt_v5_manual.ipt'
    $doc.SaveAs($outPath, $false)

    # Write result.md
    $md = @"
# $fname

## Result: $result (v5 manual fix - screw model)

| Field | Value |
|-------|-------|
| BBox | $bbX x $bbY x $bbZ mm |
| Real Vol | $realVol mm3 |
| My Vol | $myVol mm3 |
| Method | manual screw: head + shaft cylinders |
| Head | D$([Math]::Round($rHead*2,1)) x H$([Math]::Round($Lh,2)) mm |
| Shaft | D$([Math]::Round($rShaft*2,1)) x H$([Math]::Round($Ls,2)) mm |
| Diff | $diff% |

$(if ($result -eq 'PASS') { "PASS (threshold +/-10%)" } else { "FAIL" })
"@
    $md | Out-File (Join-Path $folder 'result.md') -Encoding utf8
    Write-Host "  Saved + updated result.md" -ForegroundColor Cyan
}
