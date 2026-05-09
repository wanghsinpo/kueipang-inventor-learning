## create_ring.ps1
## Create a ring/spacer part in Inventor from explicit dimensions.
## No real.ipt needed — dimensions come from parameters.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File create_ring.ps1 `
##       -OD 70 -ID 50 -Thick 10 -Name "my_spacer" -OutFolder "C:\...\round_xxx"
##
## All dims in mm.

param(
    [double]$OD      = 70.0,   # Outer diameter (mm)
    [double]$ID      = 0.0,    # Inner diameter (mm); 0 = solid disc
    [double]$Thick   = 10.0,   # Thickness / height (mm)
    [string]$Name    = "ring_part",
    [string]$OutFolder = (Split-Path $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }   # mm -> cm (Inventor internal)

$kPart = 12290
$kJoin = 20481
$kPos  = 20993

# ---- nag-watcher (kills Configurator 360 / Sign-In dialogs) ----
if (-not ('NagCreate' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagCreate {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcher([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW2 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stop = (Get-Date).AddMinutes(5)
        while ((Get-Date) -lt $stop) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [NW2]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW2]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW2]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW2]::IsWindowVisible($h) -and
                    ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW2]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

Write-Host "=== create_ring.ps1 ===" -ForegroundColor Cyan
Write-Host "  OD=$OD mm  ID=$ID mm  Thick=$Thick mm  Name=$Name" -ForegroundColor DarkGray

# ---- connect to Inventor ----
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
    Write-Host "  Attached to running Inventor." -ForegroundColor Green
} catch {
    Write-Host "  Launching Inventor..." -ForegroundColor Yellow
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep -Seconds 3
}
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagWatcher $invPid

# ---- new part document ----
try { $inv.Documents.CloseAll($false) } catch { }
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd  = $doc.ComponentDefinition
$tg  = $inv.TransientGeometry
$xy  = $cd.WorkPlanes.Item(3)   # XY plane

# ---- sketch: outer circle + optional inner circle ----
$s = $cd.Sketches.Add($xy)
$rOut = $OD / 2.0
$rIn  = $ID / 2.0
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM $rOut))
if ($rIn -gt 0.001) {
    $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM $rIn))
}

# ---- extrude ----
$prof = $s.Profiles.AddForSolid()
$ed   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof, $kJoin)
$ed.SetDistanceExtent((MM $Thick), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed)

# ---- chamfer all circular edges (like auto_ring_v3) ----
$body = $cd.SurfaceBodies.Item(1)
$ec   = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) }
}
if ($ec.Count -gt 0) {
    $wallMm = $rOut
    if ($rIn -gt 0) { $wallMm = $rOut - $rIn }
    $sizeChamfer = [Math]::Min($OD * 0.01, [Math]::Min($Thick * 0.10, $wallMm * 0.10))
    $chamferMm   = [Math]::Min(0.5, [Math]::Max(0.05, $sizeChamfer))
    try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM $chamferMm), $false) } catch { }
}

# ---- measure result ----
$body2  = $cd.SurfaceBodies.Item(1)
$rb     = $body2.RangeBox
$outVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
$xOut   = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 3)
$zOut   = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 3)

Write-Host ("  Result: BBox {0} x {0} x {1} mm  Vol={2} mm3" -f $xOut, $zOut, $outVol) -ForegroundColor Green

# ---- expected volume (annulus formula) ----
$expectedVol = [Math]::PI * (($rOut*$rOut) - ($rIn*$rIn)) * $Thick
$diffPct = (($outVol - $expectedVol) / $expectedVol) * 100.0
Write-Host ("  Expected (formula): {0:F3} mm3  diff={1:F3}%" -f $expectedVol, $diffPct) -ForegroundColor DarkGray

# ---- stop nag watcher ----
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }

# ---- save ----
$outPath = Join-Path $OutFolder "$Name.ipt"
$doc.SaveAs($outPath, $false)
Write-Host "  Saved: $outPath" -ForegroundColor Cyan
Write-Host "=== DONE ===" -ForegroundColor Green
