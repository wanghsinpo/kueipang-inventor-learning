## compare.ps1 — Open both my_attempt and real flinger; print mass-property comparison.

$ErrorActionPreference = 'Stop'

if (-not ('NagCloser2' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NagCloser2 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint procId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcher2([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($targetPid)
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NI2 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint procId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stopAt = (Get-Date).AddMinutes(5)
        while ((Get-Date) -lt $stopAt) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [NI2]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NI2]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0; [void][NI2]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $targetPid -and [NI2]::IsWindowVisible($h)) {
                    $t = $sb.ToString()
                    if ($t -match 'Configurator' -or $t -match 'Sign In' -or $t -match 'Welcome') { $script:hits.Add($h) }
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NI2]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$myFile   = "$env:USERPROFILE\Desktop\test\round1_EV-L200-MP_Flinger\my_attempt_flinger.ipt"
$realFile = "$env:USERPROFILE\Desktop\test\round1_EV-L200-MP_Flinger\real_flinger.ipt"

Write-Host "Connecting to Inventor..." -ForegroundColor Cyan
$invType = [Type]::GetTypeFromProgID('Inventor.Application')
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance($invType); Start-Sleep 2
}
$inv.Visible = $true

$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagWatcher2 $invPid

try { $inv.Documents.CloseAll($false) } catch { }

Write-Host "Opening MY attempt..." -ForegroundColor Cyan
$myDoc = $inv.Documents.Open($myFile, $true)

Write-Host "Opening REAL .ipt..." -ForegroundColor Cyan
$realDoc = $inv.Documents.Open($realFile, $true)

function Show-Stats($doc, $label) {
    Write-Host "`n=== $label ===" -ForegroundColor Yellow
    $cd = $doc.ComponentDefinition
    $body = $cd.SurfaceBodies.Item(1)
    $mp = $cd.MassProperties

    # Bounding box (cm in API)
    $rb = $body.RangeBox
    $xMin = [Math]::Round($rb.MinPoint.X * 10, 3)
    $yMin = [Math]::Round($rb.MinPoint.Y * 10, 3)
    $zMin = [Math]::Round($rb.MinPoint.Z * 10, 3)
    $xMax = [Math]::Round($rb.MaxPoint.X * 10, 3)
    $yMax = [Math]::Round($rb.MaxPoint.Y * 10, 3)
    $zMax = [Math]::Round($rb.MaxPoint.Z * 10, 3)
    $xLen = [Math]::Round($xMax - $xMin, 3)
    $yLen = [Math]::Round($yMax - $yMin, 3)
    $zLen = [Math]::Round($zMax - $zMin, 3)

    Write-Host ("Bounding (mm): X=[{0}, {1}] len={2}" -f $xMin, $xMax, $xLen)
    Write-Host ("              Y=[{0}, {1}] len={2}" -f $yMin, $yMax, $yLen)
    Write-Host ("              Z=[{0}, {1}] len={2}" -f $zMin, $zMax, $zLen)

    # Volume (cm^3 in API) -> mm^3
    $volMm3 = [Math]::Round($mp.Volume * 1000.0, 3)
    Write-Host ("Volume: {0} mm^3" -f $volMm3)

    # Surface area
    $areaMm2 = [Math]::Round($mp.Area * 100.0, 3)
    Write-Host ("Surface Area: {0} mm^2" -f $areaMm2)

    # Counts
    Write-Host ("Bodies: {0}, Faces: {1}, Edges: {2}" -f $cd.SurfaceBodies.Count, $body.Faces.Count, $body.Edges.Count)
    Write-Host ("Features: {0}" -f $cd.Features.Count)
    foreach ($f in $cd.Features) {
        Write-Host ("  - {0} ({1})" -f $f.Name, $f.Type)
    }
    return @{
        XLen = $xLen; YLen = $yLen; ZLen = $zLen
        Volume = $volMm3; Area = $areaMm2
        Faces = $body.Faces.Count; Edges = $body.Edges.Count
        Features = $cd.Features.Count
    }
}

$myStats   = Show-Stats $myDoc   "MY attempt (from PDF only)"
$realStats = Show-Stats $realDoc "REAL .ipt"

Write-Host "`n=== DIFF ===" -ForegroundColor Magenta
Write-Host ("X length: my={0} real={1} delta={2:F2}" -f $myStats.XLen, $realStats.XLen, ($myStats.XLen - $realStats.XLen))
Write-Host ("Y length: my={0} real={1} delta={2:F2}" -f $myStats.YLen, $realStats.YLen, ($myStats.YLen - $realStats.YLen))
Write-Host ("Z length: my={0} real={1} delta={2:F2}" -f $myStats.ZLen, $realStats.ZLen, ($myStats.ZLen - $realStats.ZLen))
Write-Host ("Volume:   my={0} real={1} delta_pct={2:F1}%" -f $myStats.Volume, $realStats.Volume, ((($myStats.Volume - $realStats.Volume) / $realStats.Volume) * 100))
Write-Host ("Area:     my={0} real={1} delta_pct={2:F1}%" -f $myStats.Area, $realStats.Area, ((($myStats.Area - $realStats.Area) / $realStats.Area) * 100))
Write-Host ("Faces:    my={0} real={1}" -f $myStats.Faces, $realStats.Faces)
Write-Host ("Edges:    my={0} real={1}" -f $myStats.Edges, $realStats.Edges)
Write-Host ("Features: my={0} real={1}" -f $myStats.Features, $realStats.Features)

try {
    $nagJob | Stop-Job -ErrorAction SilentlyContinue
    $nagJob | Remove-Job -ErrorAction SilentlyContinue
} catch { }

Write-Host "`nBoth files left open in Inventor." -ForegroundColor Green
