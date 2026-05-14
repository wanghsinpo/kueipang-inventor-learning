## find_best_models.ps1
## Identify the BEST-fitting models in pipeline (smallest |diff|).
## Output: top 30 with diff < 0.5%, useful as reference for accuracy.

$desk = "$env:USERPROFILE\Desktop\test"
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }

$results = New-Object 'System.Collections.ArrayList'

foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (-not (Test-Path $rm)) { continue }
    $content = Get-Content $rm -Raw
    if ($content -notmatch 'Result:\s*PASS') { continue }

    # Find Diff value (explicit line)
    if ($content -match 'Diff[^|]*\|\s*(-?\d+\.?\d*)\s*%') {
        $lastDiff = [Math]::Abs([double]$matches[1])
    } elseif ($content -match ':\s*\*?\*?(-?\d+\.?\d*)%\*?\*?') {
        # Old format: "- auto_ring_v2: **-32.34%**"
        $lastDiff = [Math]::Abs([double]$matches[1])
    } else {
        continue
    }

    # Extract Method
    $method = 'unknown'
    if ($content -match 'Method[^|]*\|\s*([^|\n]+)') {
        $method = $matches[1].Trim()
    }

    [void]$results.Add(@{ Folder = $f.Name; AbsDiff = $lastDiff; Method = $method })
}

# Sort by abs diff ascending
$sorted = $results | Sort-Object { $_.AbsDiff }
Write-Host "Top 30 best-fitting PASS models:" -ForegroundColor Cyan
$sorted | Select-Object -First 30 | ForEach-Object {
    $diffPad = ('{0:F4}%' -f $_.AbsDiff).PadLeft(10)
    Write-Host "  $diffPad  $($_.Folder)  [$($_.Method)]"
}
Write-Host ""
Write-Host "Distribution:"
$buckets = @{
    '0%'     = ($sorted | Where-Object { $_.AbsDiff -lt 0.001 }).Count
    '0-0.1%' = ($sorted | Where-Object { $_.AbsDiff -ge 0.001 -and $_.AbsDiff -lt 0.1 }).Count
    '0.1-1%' = ($sorted | Where-Object { $_.AbsDiff -ge 0.1 -and $_.AbsDiff -lt 1 }).Count
    '1-3%'   = ($sorted | Where-Object { $_.AbsDiff -ge 1 -and $_.AbsDiff -lt 3 }).Count
    '3-5%'   = ($sorted | Where-Object { $_.AbsDiff -ge 3 -and $_.AbsDiff -lt 5 }).Count
    '5-10%'  = ($sorted | Where-Object { $_.AbsDiff -ge 5 -and $_.AbsDiff -lt 10 }).Count
}
foreach ($b in $buckets.GetEnumerator()) {
    Write-Host ("  {0,-8}: {1}" -f $b.Key, $b.Value)
}

# Save
$sorted | ForEach-Object { [PSCustomObject]@{
    Folder = $_.Folder
    AbsDiff = $_.AbsDiff
    Method = $_.Method
}} | Export-Csv "$desk\best_models.csv" -NoTypeInformation -Encoding utf8
Write-Host "`nSaved: best_models.csv"
