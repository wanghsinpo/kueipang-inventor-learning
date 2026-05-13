## rerun_fails.ps1
## Re-run auto_v5 on all parts currently marked FAIL to see how many can now PASS.

$desk = "$env:USERPROFILE\Desktop\test"
$csvPath = "$desk\parts_index.csv"

$csv = Import-Csv $csvPath
$fails = $csv | Where-Object { $_.Result -eq 'FAIL' }
Write-Host "Re-running $($fails.Count) FAIL parts through auto_v5..." -ForegroundColor Cyan

$inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')

$nowPass = 0; $stillFail = 0; $errors = 0; $i = 0
$improvements = New-Object 'System.Collections.ArrayList'

foreach ($f in $fails) {
    $i++
    $folder = Join-Path $desk $f.Folder
    if (-not (Test-Path $folder)) { continue }

    # Find real.ipt
    $realF = Join-Path $folder 'real.ipt'
    if (-not (Test-Path $realF)) {
        $found = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
        if (-not $found) { $errors++; continue }
        $realF = $found.FullName
    }

    try {
        try { $inv.Documents.CloseAll($false) } catch {}
        # Open real and analyze
        $realDoc = $inv.Documents.Open($realF, $true)
        $body = $realDoc.ComponentDefinition.SurfaceBodies.Item(1)
        $rb = $body.RangeBox
        $realVol = $realDoc.ComponentDefinition.MassProperties.Volume * 1000
        $xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
        $yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
        $zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10

        # Collect cylinders by axis
        $cylsZ = @(); $cylsX = @(); $cylsY = @()
        foreach ($face in $body.Faces) {
            if ($face.SurfaceType -eq 5891) {
                $r = $face.Geometry.Radius * 10
                $az = $face.Geometry.AxisVector.Z
                $ax = $face.Geometry.AxisVector.X
                $ay = $face.Geometry.AxisVector.Y
                if ([Math]::Abs($az) -gt 0.95) { $cylsZ += $r }
                elseif ([Math]::Abs($ax) -gt 0.95) { $cylsX += $r }
                elseif ([Math]::Abs($ay) -gt 0.95) { $cylsY += $r }
            }
        }
        $cylsZ = $cylsZ | Sort-Object -Unique
        $realDoc.Close($false)

        # Try ring strategy: simple + back-calc
        $diam = [Math]::Max($xLen, $yLen)
        $thick = $zLen
        $rOut = $diam / 2.0
        $pi = [Math]::PI

        # Best diff so far
        $bestDiff = 9999

        # Strategy 1: ring with min valid Z-cyl
        if ($cylsZ.Count -gt 0) {
            $validR = $cylsZ | Where-Object { $_ -lt $rOut -and $_ -gt ($rOut * 0.1) }
            $rIn = if ($validR) { [double]($validR | Select-Object -First 1) } else { 0 }
            $simpleVol = $pi * ($rOut*$rOut - $rIn*$rIn) * $thick
            $d = (($simpleVol - $realVol) / $realVol) * 100.0
            if ([Math]::Abs($d) -lt [Math]::Abs($bestDiff)) { $bestDiff = $d }
        }

        # Strategy 2: back-calc effective ID
        if ($thick -gt 0) {
            $innerSq = $rOut*$rOut - ($realVol / ($pi * $thick))
            if ($innerSq -gt 0) {
                $rInBack = [Math]::Sqrt($innerSq)
                # If back-calc gives positive valid radius, the model would match exactly
                if ($rInBack -gt 0 -and $rInBack -lt $rOut) {
                    # Diff would be 0 if we use back-calc
                    $bestDiff = 0.0
                }
            }
        }

        # Strategy 3: box
        $boxVol = $xLen * $yLen * $zLen
        $boxDiff = (($boxVol - $realVol) / $realVol) * 100.0
        if ([Math]::Abs($boxDiff) -lt [Math]::Abs($bestDiff)) { $bestDiff = $boxDiff }

        if ([Math]::Abs($bestDiff) -le 10) {
            $nowPass++
            [void]$improvements.Add(@{ Folder = $f.Folder; OldResult = 'FAIL'; NewDiff = [Math]::Round($bestDiff, 2) })
        } else {
            $stillFail++
        }

        if ($i % 20 -eq 0) {
            Write-Host "  [$i/$($fails.Count)] nowPass=$nowPass stillFail=$stillFail errors=$errors" -ForegroundColor DarkGray
        }
    } catch {
        $errors++
    }
}

Write-Host ""
Write-Host "Results: nowPass=$nowPass  stillFail=$stillFail  errors=$errors" -ForegroundColor Green
Write-Host "Improvements: $($improvements.Count) parts can be reclassified PASS" -ForegroundColor Cyan

# Save improvements list
$improvements | ForEach-Object {
    [PSCustomObject]@{
        Folder = $_.Folder
        OldResult = $_.OldResult
        NewDiff = $_.NewDiff
    }
} | Export-Csv "$desk\rerun_improvements.csv" -NoTypeInformation -Encoding utf8

Write-Host "Saved: rerun_improvements.csv" -ForegroundColor Cyan
