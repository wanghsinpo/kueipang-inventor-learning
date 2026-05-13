## find_duplicates.ps1
## Detect parts with identical/near-identical dimensions (BBox + volume).
## Output: duplicates.csv listing groups of likely-duplicate parts.

param([double]$Tolerance = 0.1)   # 0.1mm BBox match, 1% vol match

$desk = "$env:USERPROFILE\Desktop\test"
$csv = Import-Csv "$desk\parts_index.csv"
# Only consider PASS parts with valid dims
$valid = $csv | Where-Object {
    $_.Result -eq 'PASS' -and $_.OD_mm -and $_.Thick_mm -and $_.Vol_mm3 -and
    [double]$_.Vol_mm3 -gt 0
}
Write-Host "Comparing $($valid.Count) valid PASS parts..." -ForegroundColor Cyan

# Build groups by (OD rounded, Thick rounded, Vol)
$groups = @{}
foreach ($p in $valid) {
    $od = [Math]::Round([double]$p.OD_mm, 1)
    $t  = [Math]::Round([double]$p.Thick_mm, 1)
    $v  = [Math]::Round([double]$p.Vol_mm3 / 100.0, 0) * 100  # bin by 100 mm³
    $key = "$od|$t|$v"
    if (-not $groups.ContainsKey($key)) { $groups[$key] = New-Object 'System.Collections.ArrayList' }
    [void]$groups[$key].Add($p.Folder)
}

$dupGroups = $groups.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value.Count } -Descending
Write-Host "Found $($dupGroups.Count) duplicate groups (containing $($dupGroups | ForEach-Object { $_.Value.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum) total parts)" -ForegroundColor Yellow

# Export
$rows = New-Object 'System.Collections.ArrayList'
$gNum = 0
foreach ($g in $dupGroups) {
    $gNum++
    $parts = $g.Key -split '\|'
    $od = $parts[0]; $t = $parts[1]; $v = $parts[2]
    foreach ($folder in $g.Value) {
        [void]$rows.Add([PSCustomObject]@{
            Group = $gNum
            Count = $g.Value.Count
            OD_mm = $od
            Thick_mm = $t
            Vol_mm3 = $v
            Folder = $folder
        })
    }
}

$rows | Export-Csv "$desk\duplicates.csv" -NoTypeInformation -Encoding utf8
Write-Host "Saved: duplicates.csv" -ForegroundColor Cyan

# Show top groups
Write-Host ""
Write-Host "Top 10 largest duplicate groups:"
$dupGroups | Select-Object -First 10 | ForEach-Object {
    $p = $_.Key -split '\|'
    Write-Host ""
    Write-Host "  Group ($($_.Value.Count) parts) OD=$($p[0]) T=$($p[1]) Vol=$($p[2]):" -ForegroundColor Yellow
    foreach ($f in $_.Value) {
        Write-Host "    $f"
    }
}
