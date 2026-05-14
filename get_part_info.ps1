## get_part_info.ps1
## Show all available info about a specific part folder.
##
## Usage:
##   powershell -File get_part_info.ps1 -Folder round1116_m6x55-0002-185856
##   powershell -File get_part_info.ps1 -Pattern "m6x55"
##   powershell -File get_part_info.ps1 -Pattern "stator" -ShowAll

param(
    [string]$Folder = "",
    [string]$Pattern = "",
    [switch]$ShowAll = $false
)

$desk = "$env:USERPROFILE\Desktop\test"

if ($Pattern) {
    # Find matches
    $matches_arr = Get-ChildItem $desk -Directory | Where-Object {
        $_.Name -match '^round' -and $_.Name -match $Pattern
    }
    Write-Host "Found $($matches_arr.Count) folders matching '$Pattern'" -ForegroundColor Cyan
    foreach ($f in $matches_arr) {
        Write-Host "  $($f.Name)"
    }
    if ($matches_arr.Count -gt 0 -and -not $ShowAll) {
        Write-Host ""
        Write-Host "Use -Folder <name> or -ShowAll to see details"
        exit
    }
    if ($ShowAll) {
        foreach ($f in $matches_arr) {
            & $PSCommandPath -Folder $f.Name
            Write-Host ""
        }
        exit
    }
    return
}

if (-not $Folder) {
    Write-Host "Usage: -Folder <name> or -Pattern <regex>"
    exit
}

$folderPath = Join-Path $desk $Folder
if (-not (Test-Path $folderPath)) {
    # Try fuzzy match
    $found = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match $Folder } | Select-Object -First 1
    if ($found) {
        $folderPath = $found.FullName
        $Folder = $found.Name
        Write-Host "Matched: $Folder" -ForegroundColor Yellow
    } else {
        Write-Host "Folder not found: $Folder" -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "===== $Folder =====" -ForegroundColor Cyan

# Files
Write-Host ""
Write-Host "Files:" -ForegroundColor Yellow
Get-ChildItem $folderPath | ForEach-Object {
    $size = if ($_.Length -gt 1KB) { "$([Math]::Round($_.Length/1KB, 1))KB" } else { "$($_.Length)B" }
    Write-Host ("  {0,-40} {1,10}  {2}" -f $_.Name, $size, $_.LastWriteTime.ToString('yyyy-MM-dd'))
}

# Result.md
Write-Host ""
Write-Host "result.md:" -ForegroundColor Yellow
$rm = Join-Path $folderPath 'result.md'
if (Test-Path $rm) {
    Get-Content $rm | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  (no result.md)" -ForegroundColor Gray
}

# CSV entry
Write-Host ""
Write-Host "parts_index.csv:" -ForegroundColor Yellow
$csv = Import-Csv (Join-Path $desk 'parts_index.csv')
$row = $csv | Where-Object { $_.Folder -eq $Folder } | Select-Object -First 1
if ($row) {
    $row | Format-List
} else {
    Write-Host "  (not in CSV)" -ForegroundColor Gray
}
