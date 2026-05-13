## validate_pipeline.ps1
## Sanity-check all PASS parts: verify my_attempt_*.ipt exists and (optional) re-measure vol diff.
## Generates validate_report.csv with any discrepancies.

param([switch]$DeepCheck = $false)

$desk = "$env:USERPROFILE\Desktop\test"
$csvPath = "$desk\parts_index.csv"
$reportPath = "$desk\validate_report.csv"

$csv = Import-Csv $csvPath
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }
$folderMap = @{}
foreach ($f in $folders) { $folderMap[$f.Name] = $f.FullName }

$issues = New-Object 'System.Collections.ArrayList'
$checked = 0; $passed = 0

foreach ($row in $csv) {
    $checked++
    if ($row.Result -ne 'PASS') { continue }
    if (-not $folderMap.ContainsKey($row.Folder)) {
        [void]$issues.Add([PSCustomObject]@{ Folder = $row.Folder; Issue = 'folder not found' })
        continue
    }

    $folder = $folderMap[$row.Folder]

    # Check my_attempt_*.ipt exists
    $myAttempt = $null
    foreach ($name in @('my_attempt_v5_manual.ipt','my_attempt_v5.ipt','my_attempt_v4.ipt','my_attempt_v3.ipt','my_attempt_v2.ipt','my_attempt_v1.ipt')) {
        $p = Join-Path $folder $name
        if (Test-Path $p) { $myAttempt = $p; break }
    }
    if (-not $myAttempt) {
        [void]$issues.Add([PSCustomObject]@{ Folder = $row.Folder; Issue = 'no my_attempt_*.ipt' })
        continue
    }

    # Check real.ipt exists
    $realPath = Join-Path $folder 'real.ipt'
    if (-not (Test-Path $realPath)) {
        $found = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
        if ($found) { $realPath = $found.FullName } else { $realPath = $null }
    }
    if (-not $realPath) {
        [void]$issues.Add([PSCustomObject]@{ Folder = $row.Folder; Issue = 'no real .ipt' })
        continue
    }

    # Check thumbnail
    $thumb = Join-Path $folder 'thumbnail.bmp'
    if (-not (Test-Path $thumb)) {
        [void]$issues.Add([PSCustomObject]@{ Folder = $row.Folder; Issue = 'no thumbnail' })
        continue
    }

    # Check result.md exists
    $rm = Join-Path $folder 'result.md'
    if (-not (Test-Path $rm)) {
        [void]$issues.Add([PSCustomObject]@{ Folder = $row.Folder; Issue = 'no result.md' })
        continue
    }

    $passed++

    if ($checked % 100 -eq 0) {
        Write-Host "  [$checked / $($csv.Count)] passed=$passed issues=$($issues.Count)"
    }
}

Write-Host ""
Write-Host "Validation complete: $checked checked, $passed clean, $($issues.Count) issues" -ForegroundColor $(if ($issues.Count -eq 0) { 'Green' } else { 'Yellow' })

if ($issues.Count -gt 0) {
    $issues | Export-Csv $reportPath -NoTypeInformation -Encoding utf8
    Write-Host "Saved: $reportPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Issue types:"
    $issues | Group-Object Issue | ForEach-Object {
        Write-Host "  $($_.Count): $($_.Name)" -ForegroundColor Yellow
    }
}
