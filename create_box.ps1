## create_box.ps1
## Create a rectangular box part in Inventor from explicit dimensions.
## No real.ipt needed — dimensions come from parameters.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File create_box.ps1 `
##       -W 50 -D 50 -H 5.5 -Name "al_spacer" -OutFolder "C:\...\round_xxx"
##
## All dims in mm.

param(
    [double]$W         = 50.0,    # Width  (mm) — X axis
    [double]$D         = 50.0,    # Depth  (mm) — Y axis
    [double]$H         = 10.0,    # Height (mm) — Z axis (extrude direction)
    [string]$Name      = "box_part",
    [string]$OutFolder = (Split-Path $MyInvocation.MyCommand.Path)
)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

$kPart = 12290
$kJoin = 20481
$kPos  = 20993

# ---- nag-watcher ----
if (-not ('NagBox' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagBox {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcherBox([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW_B {
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
            [NW_B]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW_B]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW_B]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW_B]::IsWindowVisible($h) -and
                    ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW_B]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

Write-Host "=== create_box.ps1 ===" -ForegroundColor Cyan
Write-Host "  W=$W mm  D=$D mm  H=$H mm  Name=$Name" -ForegroundColor DarkGray

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
$nagJob = Start-NagWatcherBox $invPid

# ---- new part document ----
try { $inv.Documents.CloseAll($false) } catch { }
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd  = $doc.ComponentDefinition
$tg  = $inv.TransientGeometry
$xy  = $cd.WorkPlanes.Item(3)   # XY plane

# ---- sketch: rectangle centered at origin ----
$s  = $cd.Sketches.Add($xy)
$p1 = $tg.CreatePoint2d((MM (-$W / 2.0)), (MM (-$D / 2.0)))
$p2 = $tg.CreatePoint2d((MM ( $W / 2.0)), (MM ( $D / 2.0)))
$null = $s.SketchLines.AddAsTwoPointRectangle($p1, $p2)

# ---- extrude ----
$prof = $s.Profiles.AddForSolid()
$ed   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof, $kJoin)
$ed.SetDistanceExtent((MM $H), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed)

# ---- measure result ----
$body  = $cd.SurfaceBodies.Item(1)
$rb    = $body.RangeBox
$outVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
$xOut   = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 3)
$yOut   = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 3)
$zOut   = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 3)

Write-Host ("  Result: BBox {0} x {1} x {2} mm  Vol={3} mm3" -f $xOut, $yOut, $zOut, $outVol) -ForegroundColor Green

# ---- expected volume ----
$expectedVol = $W * $D * $H
$diffPct = (($outVol - $expectedVol) / $expectedVol) * 100.0
Write-Host ("  Expected (formula): {0:F3} mm3  diff={1:F3}%" -f $expectedVol, $diffPct) -ForegroundColor DarkGray

# ---- stop nag watcher ----
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }

# ---- save ----
$outPath = Join-Path $OutFolder "$Name.ipt"
$doc.SaveAs($outPath, $false)
Write-Host "  Saved: $outPath" -ForegroundColor Cyan
Write-Host "=== DONE ===" -ForegroundColor Green
