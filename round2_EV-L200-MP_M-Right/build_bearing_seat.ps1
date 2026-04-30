## build_bearing_seat.ps1 — Round 2: EV-L200-MP M side bearing seat (right)
## A 3-lug triangular flange with central bore (bearing housing).
## Key R1 lessons applied:
##   - SketchPoints first, then connect
##   - nag-watcher to dismiss Configurator 360
##   - Sanity-check volume before saving

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagCloser3' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NagCloser3 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint procId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcher3([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($targetPid)
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class N3 {
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
            [N3]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N3]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0; [void][N3]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $targetPid -and [N3]::IsWindowVisible($h)) {
                    $t = $sb.ToString()
                    if ($t -match 'Configurator' -or $t -match 'Sign In' -or $t -match 'Welcome') {
                        $script:hits.Add($h)
                    }
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) {
                [void][N3]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
            }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

# ---- Inventor enums ----
$kPart = 12290
$kJoin = 20481
$kCut  = 20482
$kPos  = 20993
$kNeg  = 20994

# ---- Connect ----
Write-Host "Connecting to Inventor..." -ForegroundColor Cyan
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep 2
}
$inv.Visible = $true

$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagWatcher3 $invPid
Write-Host "  Nag-watcher started." -ForegroundColor DarkGray

try { $inv.Documents.CloseAll($false) } catch { }

Write-Host "Creating new metric part..." -ForegroundColor Cyan
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

$xy = $cd.WorkPlanes.Item(3)

# ---- Sanity check before drawing ----
$THICK = 9.0     # mm
$D_OUTER = 75.0   # main body outer
$D_INNER = 52.0   # main body bore
$LUG_DIA = 15.0   # lug cylinder diameter
$LUG_PCD = 47.0   # lug center radius from origin
$HOLE_DIA = 5.0   # mounting holes through lug

# Quick volume estimate (mm^3): main cylinder - bore + 3 lugs (overlap small, ignore)
$vMain = [Math]::PI * (($D_OUTER/2.0) * ($D_OUTER/2.0)) * $THICK
$vBore = [Math]::PI * (($D_INNER/2.0) * ($D_INNER/2.0)) * $THICK
$vLug  = [Math]::PI * (($LUG_DIA/2.0) * ($LUG_DIA/2.0)) * $THICK * 3
$vHole = [Math]::PI * (($HOLE_DIA/2.0) * ($HOLE_DIA/2.0)) * $THICK * 3
$vEst  = $vMain - $vBore + $vLug - $vHole
Write-Host ("Estimated volume (sanity): {0:N0} mm^3" -f $vEst) -ForegroundColor Magenta

# ---- Step 1: Pad main cylinder Ø75 ----
Write-Host "Step 1: Main body Ø$D_OUTER x ${THICK}mm..." -ForegroundColor Cyan
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($D_OUTER/2.0)))
$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM $THICK), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed1)

# ---- Step 2: Add 3 lugs (joined) ----
Write-Host "Step 2: 3 lug bosses Ø$LUG_DIA at PCD $LUG_PCD..." -ForegroundColor Cyan
# Hard-coded lug centers at 90°, 210°, 330° on PCD 47:
# (47 cos 90°, 47 sin 90°)   = (0,    47)
# (47 cos 210°, 47 sin 210°) = (-40.7, -23.5)
# (47 cos 330°, 47 sin 330°) = (40.7, -23.5)
$lugCenters = @(
    @( 0.0,   47.0),
    @(-40.7, -23.5),
    @( 40.7, -23.5)
)

$s2 = $cd.Sketches.Add($xy)
foreach ($c in $lugCenters) {
    $null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $c[0]), (MM $c[1])), (MM ($LUG_DIA/2.0)))
}
$prof2 = $s2.Profiles.AddForSolid()
$ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kJoin)
$ed2.SetDistanceExtent((MM $THICK), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed2)

# ---- Step 3: Central bore Ø52 through ----
Write-Host "Step 3: Central bore Ø$D_INNER through..." -ForegroundColor Cyan
$s3 = $cd.Sketches.Add($xy)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($D_INNER/2.0)))
$prof3 = $s3.Profiles.AddForSolid()
$ed3 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM ($THICK + 2)), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed3)

# ---- Step 4: 3 mounting holes Ø5 through ----
Write-Host "Step 4: 3 mounting holes Ø$HOLE_DIA through..." -ForegroundColor Cyan
$s4 = $cd.Sketches.Add($xy)
foreach ($c in $lugCenters) {
    $null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $c[0]), (MM $c[1])), (MM ($HOLE_DIA/2.0)))
}
$prof4 = $s4.Profiles.AddForSolid()
$ed4 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM ($THICK + 2)), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed4)

# ---- Save ----
$out = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt.ipt"
Write-Host "Saving to $out ..." -ForegroundColor Cyan
$doc.SaveAs($out, $false)

# Read actual volume
$mp = $cd.MassProperties
$vAct = [Math]::Round($mp.Volume * 1000, 0)
Write-Host ("Actual volume of my model: {0:N0} mm^3 (estimated {1:N0})" -f $vAct, [Math]::Round($vEst, 0)) -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
Write-Host "Done." -ForegroundColor Green
