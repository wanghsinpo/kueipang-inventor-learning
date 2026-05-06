$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round623_stator-94x53-s24-bottom-623616',
    'round624_stator-94x53-s24-bottom-inner4-608768',
    'round625_rotor-94x53-r34-325632',
    'round626_stator-94x53-s24-inner2-545280',
    'round627_rotor-140x90-r48-75-629248',
    'round628_rotor-90x48-r8-465408',
    'round629_rotor-90x48-r34-60-314368',
    'round630_stator-94x53-s24-bottom-inner2-605696'
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
Write-Host "All done R623-R630"
