## refresh_all.ps1
## Master refresh: rebuild CSV + all dashboards + reports in one go.

$desk = "$env:USERPROFILE\Desktop\test"
Set-Location $desk

Write-Host "=== Refreshing all dashboards ===" -ForegroundColor Cyan

Write-Host "`n[1/8] rebuild_csv.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File rebuild_csv.ps1 | Out-Null

Write-Host "[2/8] classify_unknowns.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File classify_unknowns.ps1 | Out-Null

Write-Host "[3/8] build_index_html.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File build_index_html.ps1 | Out-Null

Write-Host "[4/8] build_stats_html.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File build_stats_html.ps1 | Out-Null

Write-Host "[5/8] build_categories_html.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File build_categories_html.ps1 | Out-Null

Write-Host "[6/8] build_categories2_html.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File build_categories2_html.ps1 | Out-Null

Write-Host "[7/8] find_duplicates.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File find_duplicates.ps1 | Out-Null

Write-Host "[8/8] quality_check.ps1..." -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File quality_check.ps1 | Out-Null

Write-Host "`n=== All dashboards refreshed ===" -ForegroundColor Green

# Show final stats
$csv = Import-Csv "$desk\parts_index.csv"
$pass = ($csv | Where-Object { $_.Result -eq 'PASS' }).Count
$fail = ($csv | Where-Object { $_.Result -eq 'FAIL' }).Count
$skip = ($csv | Where-Object { $_.Result -eq 'SKIP' }).Count
$doc = ($csv | Where-Object { $_.Result -eq 'DOC' }).Count
$defer = ($csv | Where-Object { $_.Result -eq 'DEFER' }).Count
$unk = ($csv | Where-Object { $_.Result -eq 'UNKNOWN' }).Count
Write-Host ""
Write-Host "Stats:"
Write-Host "  PASS:    $pass"
Write-Host "  FAIL:    $fail"
Write-Host "  SKIP:    $skip"
Write-Host "  DEFER:   $defer"
Write-Host "  DOC:     $doc"
Write-Host "  UNKNOWN: $unk"
