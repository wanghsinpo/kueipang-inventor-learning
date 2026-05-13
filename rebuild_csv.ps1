## rebuild_csv.ps1
## Parse ALL result.md files to rebuild parts_index.csv with comprehensive coverage.
## The previous CSV only had 218/1116 rows (R985-R1126 batch).

$desk = "$env:USERPROFILE\Desktop\test"
$csvPath = Join-Path $desk 'parts_index.csv'

# Load existing CSV as starting point (preserves manually-set values)
$existing = @{}
if (Test-Path $csvPath) {
    Import-Csv $csvPath | ForEach-Object { $existing[$_.Folder] = $_ }
}

$rows = New-Object 'System.Collections.ArrayList'
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' } | Sort-Object Name

$updated = 0; $created = 0; $unchanged = 0; $noresult = 0
foreach ($f in $folders) {
    $rm = Join-Path $f.FullName 'result.md'
    if (-not (Test-Path $rm)) {
        # Keep existing entry if any
        if ($existing.ContainsKey($f.Name)) {
            [void]$rows.Add($existing[$f.Name])
            $unchanged++
        } else {
            $noresult++
        }
        continue
    }

    $content = Get-Content $rm -Raw

    # Extract Result
    $result = 'UNKNOWN'
    if ($content -match 'Result:\s*(PASS|FAIL|SKIP|DEFER)') { $result = $matches[1] }

    # Extract dimensions
    $od = ''; $idR = ''; $thick = ''; $vol = ''

    # BBox format: "## BBox: 50 × 50 × 5 mm" or "| BBox | 50 x 50 x 5 mm |"
    if ($content -match 'BBox[^\d-]*(-?\d+\.?\d*)\s*[xX×]\s*(-?\d+\.?\d*)\s*[xX×]\s*(-?\d+\.?\d*)') {
        $bbX = [double]$matches[1]; $bbY = [double]$matches[2]; $bbZ = [double]$matches[3]
        $od = [Math]::Round([Math]::Max($bbX, $bbY), 2)
        $thick = [Math]::Round($bbZ, 2)
    }
    # ID/Chosen ID R
    if ($content -match 'Chosen ID R[^|]*\|\s*(\d+\.?\d*)\s*mm') {
        $idR = [Math]::Round([double]$matches[1], 4)
    } elseif ($content -match 'ID[^|]*\|\s*D?(\d+\.?\d*)\s*mm') {
        $val = [double]$matches[1]
        # If "D=12.34" extracted, val is OD; if just number, ambiguous
        $idR = [Math]::Round($val / 2.0, 4)   # treat as diameter
    }
    # Volume
    if ($content -match '(?:Inventor|Real|My)\s*Vol[^|]*\|\s*(\d+\.?\d*)') {
        $vol = [Math]::Round([double]$matches[1], 3)
    }

    # Create row
    $row = [PSCustomObject]@{
        Folder   = $f.Name
        Result   = $result
        OD_mm    = $od
        ID_R_mm  = $idR
        Thick_mm = $thick
        Vol_mm3  = $vol
    }

    if ($existing.ContainsKey($f.Name)) {
        $old = $existing[$f.Name]
        if ($old.Result -ne $result -or $old.OD_mm -ne $od -or $old.Thick_mm -ne $thick) {
            $updated++
        } else {
            $unchanged++
        }
    } else {
        $created++
    }

    [void]$rows.Add($row)
}

$rows | Export-Csv $csvPath -NoTypeInformation -Encoding utf8

Write-Host "CSV rebuild complete: $($rows.Count) rows" -ForegroundColor Cyan
Write-Host "  Created: $created  Updated: $updated  Unchanged: $unchanged  NoResult: $noresult" -ForegroundColor Gray

# Stats
$pass = ($rows | Where-Object { $_.Result -eq 'PASS' }).Count
$fail = ($rows | Where-Object { $_.Result -eq 'FAIL' }).Count
$skip = ($rows | Where-Object { $_.Result -eq 'SKIP' }).Count
$defer = ($rows | Where-Object { $_.Result -eq 'DEFER' }).Count
$unknown = ($rows | Where-Object { $_.Result -eq 'UNKNOWN' }).Count
Write-Host "  PASS: $pass  FAIL: $fail  SKIP: $skip  DEFER: $defer  UNKNOWN: $unknown" -ForegroundColor Yellow
