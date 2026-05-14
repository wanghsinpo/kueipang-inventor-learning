## quality_check.ps1
## Analyze PASS parts for potential quality issues:
## - Volume close to threshold (8-10% diff = borderline)
## - Method = back-calc (volume match but geometric approximation)
## - Vol > 100k mm3 (large parts more important to be accurate)

$desk = "$env:USERPROFILE\Desktop\test"

$borderline = New-Object 'System.Collections.ArrayList'
$backcalc = New-Object 'System.Collections.ArrayList'
$largeBackcalc = New-Object 'System.Collections.ArrayList'

$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }
$processed = 0
foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (-not (Test-Path $rm)) { continue }
    $content = Get-Content $rm -Raw

    # Skip non-PASS
    if ($content -notmatch 'Result:\s*PASS') { continue }

    # Extract diff
    $diff = 0
    if ($content -match 'Diff[^|]*\|\s*(-?\d+\.?\d*)\s*%') {
        $diff = [double]$matches[1]
    }

    $isBackcalc = ($content -match 'back-?calc' -or $content -match 'Method.*back')
    $vol = 0
    if ($content -match '(?:Real|Inventor)\s*Vol[^|]*\|\s*(\d+\.?\d*)') {
        $vol = [double]$matches[1]
    }

    # Borderline: |diff| between 7-10%
    if ([Math]::Abs($diff) -ge 7 -and [Math]::Abs($diff) -le 10) {
        [void]$borderline.Add(@{ Folder = $f.Name; Diff = $diff; BackCalc = $isBackcalc; Vol = $vol })
    }
    # Back-calc parts (volume-equivalent only, shape approximated)
    if ($isBackcalc) {
        [void]$backcalc.Add(@{ Folder = $f.Name; Diff = $diff; Vol = $vol })
    }
    # Large back-calc parts (Vol > 100k mm³)
    if ($isBackcalc -and $vol -gt 100000) {
        [void]$largeBackcalc.Add(@{ Folder = $f.Name; Diff = $diff; Vol = $vol })
    }
    $processed++
}

Write-Host "Quality analysis: $processed parts" -ForegroundColor Cyan
Write-Host ""
Write-Host "Borderline (|diff| 7-10%): $($borderline.Count)" -ForegroundColor Yellow
$borderline | ForEach-Object {
    Write-Host "  $($_.Folder)  diff=$($_.Diff)%  backcalc=$($_.BackCalc)"
}
Write-Host ""
Write-Host "Back-calc PASS (shape approximated): $($backcalc.Count)" -ForegroundColor Cyan
Write-Host "  (volume PASS but geometric shape may not match real)"
Write-Host ""
Write-Host "Large back-calc (Vol >100k, priority to verify): $($largeBackcalc.Count)" -ForegroundColor Magenta
$largeBackcalc | Sort-Object { $_.Vol } -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Host "  $($_.Folder)  Vol=$([Math]::Round($_.Vol/1000,1))k mm³  diff=$($_.Diff)%"
}

# Save report
$out = "$desk\quality_report.csv"
$rows = @()
foreach ($b in $borderline) { $rows += [PSCustomObject]@{ Type='Borderline'; Folder=$b.Folder; Diff=$b.Diff; Vol=$b.Vol; BackCalc=$b.BackCalc } }
foreach ($b in $largeBackcalc) { $rows += [PSCustomObject]@{ Type='LargeBackcalc'; Folder=$b.Folder; Diff=$b.Diff; Vol=$b.Vol; BackCalc=$true } }
$rows | Export-Csv $out -NoTypeInformation -Encoding utf8
Write-Host ""
Write-Host "Report: $out" -ForegroundColor Cyan
