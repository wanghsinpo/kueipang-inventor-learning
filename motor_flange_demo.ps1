## motor_flange_demo.ps1
## Feature-by-feature parametric model — built from photo proportions.
## Each feature stays editable in Inventor's tree (double-click to modify).
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File motor_flange_demo.ps1
##   powershell -ExecutionPolicy Bypass -File motor_flange_demo.ps1 -PlateW 90 -HubD 55
##
## All dims in mm. Each Sketch + Extrude is an independent feature.

param(
    [double]$PlateW          = 88.0,   # plate overall width (X)
    [double]$PlateH          = 88.0,   # plate overall height (Y)
    [double]$PlateT          = 12.0,   # plate thickness (Z)
    [double]$Chamf           = 12.0,   # corner chamfer cut (45°)
    [double]$HubD            = 52.0,   # raised hub diameter
    [double]$HubH            = 10.0,   # hub height above plate
    [double]$BoreD           = 32.0,   # center through bore diameter
    [double]$HoleD           = 6.5,    # 4 corner mounting hole diameter
    [double]$HoleX           = 36.0,   # mounting hole offset from center (X)
    [double]$HoleY           = 36.0,   # mounting hole offset from center (Y)
    [double]$KeyW            = 14.0,   # keyway notch width
    [double]$KeyDepth        = 6.0,    # keyway notch depth into plate edge
    [string]$Name            = "motor_flange_v1",
    [string]$OutFolder       = "$env:USERPROFILE\Desktop\test\motor_flange_demo"
)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }   # mm → cm (Inventor internal)

$kPart = 12290; $kJoin = 20481; $kCut = 20482; $kPos = 20993; $kNeg = 20994

# ---- nag-watcher (dismiss Configurator dialogs) ----
if (-not ('NagMF' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagMF {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcherMF([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW_MF {
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
            [NW_MF]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW_MF]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW_MF]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW_MF]::IsWindowVisible($h) -and
                    ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW_MF]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

Write-Host "=== motor_flange_demo.ps1 ===" -ForegroundColor Cyan
Write-Host "  Plate: $PlateW x $PlateH x $PlateT  Chamf: $Chamf" -ForegroundColor DarkGray
Write-Host "  Hub:   D$HubD x H$HubH    Bore: D$BoreD" -ForegroundColor DarkGray
Write-Host "  Holes: 4x D$HoleD at offset (X=$HoleX, Y=$HoleY)" -ForegroundColor DarkGray
Write-Host "  Keyway: $KeyW W x $KeyDepth deep on bottom edge" -ForegroundColor DarkGray

# ---- connect to Inventor ----
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
    Write-Host "Attached to Inventor." -ForegroundColor Green
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep -Seconds 3
}
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagWatcherMF $invPid

# ---- new part ----
try { $inv.Documents.CloseAll($false) } catch { }
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd  = $doc.ComponentDefinition
$tg  = $inv.TransientGeometry

# ================================================================
# Feature 01 — Base octagonal plate
# ================================================================
Write-Host "[01] BasePlate (octagon 88x88, chamf 12, t=12)..." -ForegroundColor Yellow
$xy = $cd.WorkPlanes.Item(3)   # XY plane
$s1 = $cd.Sketches.Add($xy)

# 8-vertex octagon (square with 45° chamfered corners) — pre-compute each value
$hw    = [double]($PlateW / 2.0)
$hh    = [double]($PlateH / 2.0)
$c     = [double]$Chamf
$mhw   = [double](-$hw)
$mhh   = [double](-$hh)
$hhmc  = [double]($hh - $c)
$mhhpc = [double]($mhh + $c)
$mhwpc = [double]($mhw + $c)
$hwmc  = [double]($hw - $c)

# Build 8 SketchPoints individually (CLAUDE.md 坑 #2 — must use SketchPoint not Point2d for shared endpoints)
$sp = New-Object 'System.Collections.ArrayList'
$p0 = $tg.CreatePoint2d((MM $mhw),   (MM $hhmc))
$p1 = $tg.CreatePoint2d((MM $mhwpc), (MM $hh))
$p2 = $tg.CreatePoint2d((MM $hwmc),  (MM $hh))
$p3 = $tg.CreatePoint2d((MM $hw),    (MM $hhmc))
$p4 = $tg.CreatePoint2d((MM $hw),    (MM $mhhpc))
$p5 = $tg.CreatePoint2d((MM $hwmc),  (MM $mhh))
$p6 = $tg.CreatePoint2d((MM $mhwpc), (MM $mhh))
$p7 = $tg.CreatePoint2d((MM $mhw),   (MM $mhhpc))
[void]$sp.Add($s1.SketchPoints.Add($p0, $false))
[void]$sp.Add($s1.SketchPoints.Add($p1, $false))
[void]$sp.Add($s1.SketchPoints.Add($p2, $false))
[void]$sp.Add($s1.SketchPoints.Add($p3, $false))
[void]$sp.Add($s1.SketchPoints.Add($p4, $false))
[void]$sp.Add($s1.SketchPoints.Add($p5, $false))
[void]$sp.Add($s1.SketchPoints.Add($p6, $false))
[void]$sp.Add($s1.SketchPoints.Add($p7, $false))

# connect 8 SketchPoints → 8 lines (closed loop, shared endpoints)
for ($i = 0; $i -lt 8; $i++) {
    $a = $sp[$i]
    $b = $sp[($i + 1) % 8]
    $null = $s1.SketchLines.AddByTwoPoints($a, $b)
}

$prof1 = $s1.Profiles.AddForSolid()
$ed1   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM $PlateT), $kPos)
$f1    = $cd.Features.ExtrudeFeatures.Add($ed1)
$f1.Name = "01_BasePlate_${PlateW}x${PlateH}x${PlateT}"
Write-Host "  ✓ $($f1.Name)" -ForegroundColor Green

# ---- offset work plane at top of plate (more reliable than face lookup) ----
$wpTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM $PlateT))
$wpTop.Visible = $false

# ================================================================
# Feature 02 — Raised hub on top face
# ================================================================
Write-Host "[02] Hub (Ø$HubD x h$HubH on top face)..." -ForegroundColor Yellow
$s2 = $cd.Sketches.Add($wpTop)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($HubD / 2.0)))
$prof2 = $s2.Profiles.AddForSolid()
$ed2   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kJoin)
$ed2.SetDistanceExtent((MM $HubH), $kPos)
$f2    = $cd.Features.ExtrudeFeatures.Add($ed2)
$f2.Name = "02_Hub_D${HubD}xH${HubH}"
Write-Host "  ✓ $($f2.Name)" -ForegroundColor Green

# ================================================================
# Feature 03 — Center through bore
# ================================================================
Write-Host "[03] CenterBore (Ø$BoreD cut all)..." -ForegroundColor Yellow
# Offset work plane at top of hub
$wpHubTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + $HubH)))
$wpHubTop.Visible = $false
$s3 = $cd.Sketches.Add($wpHubTop)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($BoreD / 2.0)))
$prof3 = $s3.Profiles.AddForSolid()
$ed3   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
# Cut downward through plate + hub
$ed3.SetDistanceExtent((MM ($PlateT + $HubH + 1)), $kNeg)
$f3    = $cd.Features.ExtrudeFeatures.Add($ed3)
$f3.Name = "03_CenterBore_D${BoreD}"
Write-Host "  ✓ $($f3.Name)" -ForegroundColor Green

# ================================================================
# Feature 04 — 4 corner mounting holes (sketch + extrude cut)
# ================================================================
Write-Host "[04] MountingHoles (4x Ø$HoleD)..." -ForegroundColor Yellow
# Use an offset work plane slightly above the plate top (predictable coordinates)
$xyOffset = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + 0.01)))
$xyOffset.Visible = $false
$s4 = $cd.Sketches.Add($xyOffset)

# 4 circles at corner offsets (±HoleX, ±HoleY)
foreach ($x in @(-$HoleX, $HoleX)) {
    foreach ($y in @(-$HoleY, $HoleY)) {
        $null = $s4.SketchCircles.AddByCenterRadius(
            $tg.CreatePoint2d((MM $x), (MM $y)), (MM ($HoleD / 2.0)))
    }
}
$prof4 = $s4.Profiles.AddForSolid()
$ed4   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM ($PlateT + $HubH + 2)), $kNeg)
$f4    = $cd.Features.ExtrudeFeatures.Add($ed4)
$f4.Name = "04_MountingHoles_4xD${HoleD}"
Write-Host "  ✓ $($f4.Name)" -ForegroundColor Green

# ================================================================
# Feature 05 — Keyway notch on bottom edge
# ================================================================
Write-Host "[05] Keyway (W$KeyW x D$KeyDepth)..." -ForegroundColor Yellow
$s5 = $cd.Sketches.Add($xyOffset)
$kx1 = -$KeyW / 2.0
$kx2 =  $KeyW / 2.0
$ky1 = -$hh - 1                  # below bottom edge (so cut crosses through)
$ky2 = -$hh + $KeyDepth          # into the plate
$p1 = $tg.CreatePoint2d((MM $kx1), (MM $ky1))
$p2 = $tg.CreatePoint2d((MM $kx2), (MM $ky2))
$null = $s5.SketchLines.AddAsTwoPointRectangle($p1, $p2)
$prof5 = $s5.Profiles.AddForSolid()
$ed5   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM ($PlateT + 2)), $kNeg)
$f5    = $cd.Features.ExtrudeFeatures.Add($ed5)
$f5.Name = "05_Keyway_W${KeyW}xD${KeyDepth}"
Write-Host "  ✓ $($f5.Name)" -ForegroundColor Green

# ---- measure ----
$body = $cd.SurfaceBodies.Item(1)
$rb   = $body.RangeBox
$vol  = [Math]::Round($cd.MassProperties.Volume * 1000, 1)
$bbW  = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 1)
$bbH  = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 1)
$bbT  = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 1)
Write-Host ""
Write-Host "Result: BBox $bbW x $bbH x $bbT mm  Vol=$vol mm³" -ForegroundColor Magenta

# ---- save ----
if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }
$outPath = Join-Path $OutFolder "$Name.ipt"
$doc.SaveAs($outPath, $false)
Write-Host "Saved: $outPath" -ForegroundColor Cyan

# ---- screenshot (iso view) ----
try {
    $view = $inv.ActiveView
    $view.Fit()
    Start-Sleep -Milliseconds 200
    $thumbPath = Join-Path $OutFolder "preview.bmp"
    $view.SaveAsBitmap($thumbPath, 800, 600)
    Write-Host "Preview: $thumbPath" -ForegroundColor Cyan
} catch { Write-Host "Preview failed: $_" -ForegroundColor DarkYellow }

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch {}
Write-Host "=== DONE ===" -ForegroundColor Green
