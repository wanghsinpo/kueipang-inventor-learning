$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round639_stator-90x48-s24-outer4-657408',
    'round640_stator-140x90-s36-507392',
    'round641_rotor-121x72-r48-308736',
    'round642_rotor-90x47-r18-t30-350208',
    'round643_rotor-90x47-t80-298496',
    'round644_rotor-90x47-t60-302080',
    'round645_stator-90x47-s24-576000',
    'round646_stator-90x47-s24-bottom-481792'
)
foreach ($r in $rounds) {
    Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    $folder = Join-Path $desk $r
    Write-Host "=== $r ==="
    $out = powershell -ExecutionPolicy Bypass -File auto_ring_v3.ps1 -folder $folder 2>&1
    $out | Select-String -Pattern "BACKCALC|REAL:|My:|diff|SKIP|ERROR|BBox" | Select-Object -Last 5
    Write-Host "---"
}
Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "All done."
