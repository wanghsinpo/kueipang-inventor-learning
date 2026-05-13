## classify_unknowns.ps1
## Process result.md files that don't have explicit Result: PASS/FAIL label.
## Extract diff% from free-form text and classify automatically.

$desk = "$env:USERPROFILE\Desktop\test"
$csvPath = Join-Path $desk 'parts_index.csv'

$rows = Import-Csv $csvPath

$classified = 0; $stillUnknown = 0
foreach ($row in $rows) {
    if ($row.Result -ne 'UNKNOWN') { continue }
    $rm = Join-Path $desk "$($row.Folder)\result.md"
    if (-not (Test-Path $rm)) { continue }
    $content = Get-Content $rm -Raw

    # Find ALL diff percentages
    $matches_arr = [regex]::Matches($content, '(-?\d+\.?\d*)\s*%')
    if ($matches_arr.Count -eq 0) {
        $stillUnknown++
        continue
    }
    # Use the LAST diff% (usually the final result)
    $lastDiff = [double]$matches_arr[$matches_arr.Count - 1].Groups[1].Value

    if ([Math]::Abs($lastDiff) -le 10) {
        $row.Result = 'PASS'
    } else {
        $row.Result = 'FAIL'
    }
    $classified++
}

$rows | Export-Csv $csvPath -NoTypeInformation -Encoding utf8

Write-Host "Classified $classified previously-UNKNOWN parts" -ForegroundColor Cyan
Write-Host "Still UNKNOWN: $stillUnknown" -ForegroundColor Yellow

# Stats
$pass = ($rows | Where-Object { $_.Result -eq 'PASS' }).Count
$fail = ($rows | Where-Object { $_.Result -eq 'FAIL' }).Count
$skip = ($rows | Where-Object { $_.Result -eq 'SKIP' }).Count
$defer = ($rows | Where-Object { $_.Result -eq 'DEFER' }).Count
$unknown = ($rows | Where-Object { $_.Result -eq 'UNKNOWN' }).Count
Write-Host "Final: PASS=$pass  FAIL=$fail  SKIP=$skip  DEFER=$defer  UNKNOWN=$unknown" -ForegroundColor Green
