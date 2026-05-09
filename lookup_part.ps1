## lookup_part.ps1
## Find matching round folder by OD / ID / Thick / Volume.
## Usage:
##   powershell -File lookup_part.ps1 -OD 220 -Thick 25
##   powershell -File lookup_part.ps1 -Vol 500000 -Tol 5
##   powershell -File lookup_part.ps1 -OD 70 -ID 50 -Thick 10

param(
    [double]$OD    = -1,   # outer diameter mm (-1 = ignore)
    [double]$ID    = -1,   # inner diameter mm (-1 = ignore); note this is DIAMETER not radius
    [double]$Thick = -1,   # thickness mm (-1 = ignore)
    [double]$Vol   = -1,   # volume mm3 (-1 = ignore)
    [double]$Tol   = 3.0   # tolerance % for matching
)

$desk  = Join-Path $env:USERPROFILE 'Desktop\test'
$csv   = Join-Path $desk 'parts_index.csv'
if (-not (Test-Path $csv)) { throw "parts_index.csv not found. Run the index builder first." }

$index = Import-Csv $csv

function PctDiff($a, $b) {
    if ($b -eq 0) { return 999 }
    return [Math]::Abs(($a - $b) / $b) * 100.0
}

$hits = $index | Where-Object { $_.Result -eq 'PASS' } | ForEach-Object {
    $row = $_
    # CSV values are strings — parse safely
    $rowOD    = if ($row.OD_mm    -match '^\d') { [double]$row.OD_mm    } else { -1 }
    $rowIDR   = if ($row.ID_R_mm  -match '^\d') { [double]$row.ID_R_mm  } else { -1 }
    $rowThick = if ($row.Thick_mm -match '^\d') { [double]$row.Thick_mm } else { -1 }
    $rowVol   = if ($row.Vol_mm3  -match '^\d') { [double]$row.Vol_mm3  } else { -1 }

    $odOk    = ($OD    -lt 0) -or ($rowOD    -gt 0 -and (PctDiff $OD    $rowOD)    -le $Tol)
    # ID param is diameter; index stores radius
    $idOk    = ($ID    -lt 0) -or ($rowIDR   -gt 0 -and (PctDiff ($ID/2) $rowIDR)  -le $Tol)
    $thickOk = ($Thick -lt 0) -or ($rowThick -gt 0 -and (PctDiff $Thick $rowThick) -le $Tol)
    $volOk   = ($Vol   -lt 0) -or ($rowVol   -gt 0 -and (PctDiff $Vol   $rowVol)   -le $Tol)
    if ($odOk -and $idOk -and $thickOk -and $volOk) { $row }
}

if ($hits) {
    Write-Host "=== MATCHES (tol=$Tol%) ===" -ForegroundColor Green
    $hits | Select-Object Folder, OD_mm, ID_R_mm, Thick_mm, Vol_mm3 | Format-Table -AutoSize
} else {
    Write-Host "No match found (tol=$Tol%)." -ForegroundColor Yellow
    Write-Host "Try increasing -Tol or relaxing some parameters."
}
