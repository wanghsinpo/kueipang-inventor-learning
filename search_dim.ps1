## search_dim.ps1
## Search parts by dimension range with flexible matching.
##
## Usage:
##   powershell -File search_dim.ps1 -OD 50 -Thick 10 -Tol 5         # within 5% tolerance
##   powershell -File search_dim.ps1 -OD 220 -OD2 240 -Thick 25      # OD range 220-240
##   powershell -File search_dim.ps1 -Vol 500000 -Vol2 600000        # vol range

param(
    [double]$OD = 0,
    [double]$OD2 = 0,
    [double]$Thick = 0,
    [double]$Thick2 = 0,
    [double]$Vol = 0,
    [double]$Vol2 = 0,
    [double]$Tol = 5    # default 5%
)

$desk = "$env:USERPROFILE\Desktop\test"
$csv = Import-Csv (Join-Path $desk 'parts_index.csv')

function InRange($actual, $target, $target2, $tolPct) {
    if (-not $actual) { return $false }
    $a = [double]$actual
    if ($target -gt 0 -and $target2 -gt 0) {
        return ($a -ge $target -and $a -le $target2)
    }
    if ($target -gt 0) {
        $minA = $target * (1 - $tolPct/100)
        $maxA = $target * (1 + $tolPct/100)
        return ($a -ge $minA -and $a -le $maxA)
    }
    return $true
}

$results = $csv | Where-Object {
    (InRange $_.OD_mm $OD $OD2 $Tol) -and
    (InRange $_.Thick_mm $Thick $Thick2 $Tol) -and
    (InRange $_.Vol_mm3 $Vol $Vol2 $Tol)
}

Write-Host "Found $($results.Count) matches:" -ForegroundColor Cyan
$results | Sort-Object { [double]$_.OD_mm } | ForEach-Object {
    Write-Host ("  {0,-50}  OD={1,-7} T={2,-7} Vol={3,-12} [{4}]" -f $_.Folder, $_.OD_mm, $_.Thick_mm, $_.Vol_mm3, $_.Result)
}
