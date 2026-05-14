## analyze_methods.ps1
## Categorize PASS parts by modeling method (back-calc / simple ring / manual / etc.)
## Useful to understand pipeline strategy distribution.

$desk = "$env:USERPROFILE\Desktop\test"
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }

$methods = @{}
foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (-not (Test-Path $rm)) { continue }
    $content = Get-Content $rm -Raw

    # Find method line
    $method = 'unspecified'
    if ($content -match 'Method[^|]*\|\s*([^|\n]+)') {
        $method = $matches[1].Trim()
    } elseif ($content -match 'auto_ring_v(\d)') {
        $method = "auto_ring_v$($matches[1])"
    } elseif ($content -match 'auto_v(\d)') {
        $method = "auto_v$($matches[1])"
    }

    # Normalize
    if ($method -match 'back') { $method = 'back-calc' }
    elseif ($method -match 'simple|direct') { $method = 'simple-ring' }
    elseif ($method -match 'manual.*screw') { $method = 'manual-screw' }
    elseif ($method -match 'manual.*box|leg') { $method = 'manual-box+legs' }
    elseif ($method -match 'hollow') { $method = 'thin-wall-hollow' }
    elseif ($method -match 'box') { $method = 'box-extrude' }
    elseif ($method -match 'manual') { $method = 'manual-other' }

    if (-not $methods.ContainsKey($method)) { $methods[$method] = 0 }
    $methods[$method]++
}

Write-Host "Method distribution:" -ForegroundColor Cyan
$methods.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0,5}: {1}" -f $_.Value, $_.Name)
}

# Save
$rows = $methods.GetEnumerator() | ForEach-Object {
    [PSCustomObject]@{ Method = $_.Name; Count = $_.Value }
}
$rows | Sort-Object Count -Descending | Export-Csv "$desk\method_distribution.csv" -NoTypeInformation -Encoding utf8
Write-Host ""
Write-Host "Saved: method_distribution.csv"
