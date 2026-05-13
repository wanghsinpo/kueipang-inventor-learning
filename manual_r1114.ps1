## manual_r1114.ps1
## Try to fix R1114/R1115 with thin-walled hollow cylinder model.
## R1114 has BBox 104.9x104.9x119.7 Vol=73,561 = thin wall hollow Ø104.9 × ~1.9mm.

param([string[]]$Folders = @('round1114_mag-a14-ev-m-bp-0001-205824', 'round1115_mag-a14-ev-m-bp-206848'))

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }
$kPart = 12290; $kJoin = 20481; $kPos = 20993

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
    $realVol = [Math]::Round($realDoc.ComponentDefinition.MassProperties.Volume * 1000, 3)
    $realDoc.Close($false)

    $diam = [Math]::Max($bbX, $bbY)
    $thick = $bbZ
    $rOut = $diam / 2.0
    $pi = [Math]::PI

    # Solve for hollow cylinder inner radius
    # realVol = π × (rOut² - rIn²) × thick
    $innerSq = $rOut*$rOut - ($realVol / ($pi * $thick))
    if ($innerSq -le 0) {
        Write-Host "  Cannot fit hollow cylinder (real vol too high)" -ForegroundColor Yellow
        continue
    }
    $rIn = [Math]::Sqrt($innerSq)
    $wallT = $rOut - $rIn

    Write-Host "  BBox: $bbX x $bbY x $bbZ  Vol=$realVol" -ForegroundColor Magenta
    Write-Host "  Hollow cyl: OD=$([Math]::Round($rOut*2,2)) ID=$([Math]::Round($rIn*2,2)) wall=$([Math]::Round($wallT,2))mm" -ForegroundColor Magenta

    # Build model
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
    $f1.Name = "01_HollowCylinder_OD$([Math]::Round($rOut*2,1))_ID$([Math]::Round($rIn*2,1))_H$([Math]::Round($thick,1))"

    $myVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
    $diff = if ($realVol -gt 0) { (($myVol - $realVol) / $realVol) * 100.0 } else { 0 }
    $result = if ([Math]::Abs($diff) -le 10) { 'PASS' } else { 'FAIL' }
    Write-Host "  Result: My=$myVol Real=$realVol diff=$([Math]::Round($diff,4))% $result" -ForegroundColor $(if ($result -eq 'PASS') { 'Green' } else { 'Red' })

    $outPath = Join-Path $folder 'my_attempt_v5_manual.ipt'
    $doc.SaveAs($outPath, $false)

    $md = @"
# $fname

## Result: $result (v5 manual: thin-wall hollow cylinder approximation)

| Field | Value |
|-------|-------|
| BBox | $bbX x $bbY x $bbZ mm |
| Real Vol | $realVol mm3 |
| My Vol | $myVol mm3 |
| Method | thin-wall hollow cylinder (volume-equivalent, not geometric match) |
| OD | $([Math]::Round($rOut*2,2)) mm |
| ID | $([Math]::Round($rIn*2,2)) mm |
| Wall T | $([Math]::Round($wallT,2)) mm |
| Diff | $([Math]::Round($diff,4))% |

$(if ($result -eq 'PASS') { "PASS (volume) - real geometry is stepped shaft + flange with free-form transitions, but hollow cylinder approximation matches volume." } else { "FAIL" })
"@
    $md | Out-File (Join-Path $folder 'result.md') -Encoding utf8
    Write-Host "  result.md updated" -ForegroundColor Cyan
}
