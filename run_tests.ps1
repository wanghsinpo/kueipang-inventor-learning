## run_tests.ps1
## Self-test: verify all dashboards / scripts can be rebuilt without errors.

$desk = "$env:USERPROFILE\Desktop\test"
Set-Location $desk

$tests = @(
    @{ Name = 'rebuild_csv';        Cmd = 'rebuild_csv.ps1' }
    @{ Name = 'classify_unknowns';  Cmd = 'classify_unknowns.ps1' }
    @{ Name = 'build_index_html';   Cmd = 'build_index_html.ps1' }
    @{ Name = 'build_stats_html';   Cmd = 'build_stats_html.ps1' }
    @{ Name = 'build_categories_html';  Cmd = 'build_categories_html.ps1' }
    @{ Name = 'build_categories2_html'; Cmd = 'build_categories2_html.ps1' }
    @{ Name = 'find_duplicates';    Cmd = 'find_duplicates.ps1' }
    @{ Name = 'quality_check';      Cmd = 'quality_check.ps1' }
    @{ Name = 'find_best_models';   Cmd = 'find_best_models.ps1' }
    @{ Name = 'analyze_methods';    Cmd = 'analyze_methods.ps1' }
    @{ Name = 'validate_pipeline';  Cmd = 'validate_pipeline.ps1' }
    @{ Name = 'search_dim';         Cmd = 'search_dim.ps1 -OD 50 -Tol 5' }
    @{ Name = 'get_part_info';      Cmd = 'get_part_info.ps1 -Pattern m6x55' }
)

$pass = 0
$fail = 0
$failures = New-Object 'System.Collections.ArrayList'

foreach ($t in $tests) {
    Write-Host -NoNewline "Test: $($t.Name)... "
    try {
        $result = powershell -ExecutionPolicy Bypass -Command "& '$desk\$($t.Cmd)' 2>&1" 2>&1
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "PASS" -ForegroundColor Green
            $pass++
        } else {
            Write-Host "FAIL (exit=$LASTEXITCODE)" -ForegroundColor Red
            $fail++
            [void]$failures.Add("$($t.Name): exit $LASTEXITCODE")
        }
    } catch {
        Write-Host "FAIL ($_)" -ForegroundColor Red
        $fail++
        [void]$failures.Add("$($t.Name): $_")
    }
}

Write-Host ""
Write-Host "===== $pass PASS, $fail FAIL =====" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
if ($failures.Count -gt 0) {
    Write-Host "Failures:"
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}
