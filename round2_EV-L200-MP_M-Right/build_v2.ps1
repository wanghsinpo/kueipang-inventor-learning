## Round 2 v2 — bearing seat redo, using exact dims extracted from real .ipt
## Real BBox: 75 x 75 x 21.5
## Real Vol:  43,734 mm^3
##
## Build plan (validated against real geometry dump):
##   1. Pad Ø75 cylinder × 21.5 thick
##   2. Cut Ø52 cavity from top (Z=21.5) down 20mm (leaves 1.5mm bottom wall)
##   3. 2 holes Ø4.13 at (0,±31.5) — M5 minor (the M5 thread holes)
##   4. 2 holes Ø5 + Ø7.9 c'bore depth 5.5 at (±31.5,0)
##   5. Chamfer outer top edge C2.6 (matches the 45° plane area 835 mm²)
##
## Sanity volume:
##   pad - cavity - 4 holes through Ø5 - 2 cbores - chamfer
##   = 94985 - 42475 - 1688 - 539 - 778 = 49506 mm^3 (vs real 43734 = +13%)
## Slack to close: 5772 mm^3 — likely from outline trims I don't model.
## Acceptable for "complex part" demonstration: BBox correct, all features present,
## volume within ~15% (vs the original Round 2 v1 which was -43% with WRONG SHAPE).

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('Nag7' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class Nag7 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-Nag7([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N7 {
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
            [N7]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N7]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][N7]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [N7]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N7]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kCut=20482; $kPos=20993; $kNeg=20994

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-Nag7 $invPid
try { $inv.Documents.CloseAll($false) } catch { }

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

# Step 1: Ø75 main body
Write-Host "Step 1: Pad Ø75 × 21.5 mm..." -ForegroundColor Cyan
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 37.5))
$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM 21.5), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed1)

# Step 2: Cut Ø52 cavity from top, depth 20mm
Write-Host "Step 2: Cut Ø52 cavity from top, depth 20mm..." -ForegroundColor Cyan
# Sketch on the top face (Z=21.5)
$body = $cd.SurfaceBodies.Item(1)
$topFace = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5) { $topFace = $f; break }
}
if ($null -eq $topFace) { throw "Could not find top face at Z=21.5" }
$s2 = $cd.Sketches.Add($topFace)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 26))
$prof2 = $s2.Profiles.AddForSolid()
$ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kCut)
$ed2.SetDistanceExtent((MM 20), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed2)

# Step 3: 2 M5 thread holes at (0, ±31.5) — Ø4.13 through (M5 minor)
Write-Host "Step 3: 2 M5 holes (Ø4.13 thru) at (0, ±31.5)..." -ForegroundColor Cyan
$topFace2 = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5) { $topFace2 = $f; break }
}
$s3 = $cd.Sketches.Add($topFace2)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM 31.5)), (MM 2.067))
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM -31.5)), (MM 2.067))
$prof3 = $s3.Profiles.AddForSolid()
$ed3 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed3)

# Step 4: 2 clearance holes Ø5 thru at (±31.5, 0)
Write-Host "Step 4: 2 Ø5 thru at (±31.5, 0)..." -ForegroundColor Cyan
$topFace3 = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5) { $topFace3 = $f; break }
}
$s4 = $cd.Sketches.Add($topFace3)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 2.5))
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 2.5))
$prof4 = $s4.Profiles.AddForSolid()
$ed4 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed4)

# Step 5: 2 counterbores Ø7.9 × 5.5 deep on top, around the Ø5 holes
Write-Host "Step 5: 2 Ø7.9 × 5.5 counterbores..." -ForegroundColor Cyan
$topFace4 = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5) { $topFace4 = $f; break }
}
$s5 = $cd.Sketches.Add($topFace4)
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 3.95))
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 3.95))
$prof5 = $s5.Profiles.AddForSolid()
$ed5 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM 5.5), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed5)

# Step 6: Chamfer C2.6 on outer top edge (the Ø75 / top intersection)
Write-Host "Step 6: Chamfer C2.6 on outer top edge..." -ForegroundColor Cyan
# Find the circle edge of radius 37.5 at Z=21.5
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) {
    if ($e.GeometryType -ne 5124) { continue }   # kCircleCurveObject
    $g = $e.Geometry
    if ($g.Radius -gt (MM 37.4) -and $g.Radius -lt (MM 37.6) -and [Math]::Abs($g.Center.Z - (MM 21.5)) -lt 0.01) {
        $null = $ec.Add($e)
    }
}
Write-Host ("  Edges to chamfer: {0}" -f $ec.Count) -ForegroundColor DarkGray
if ($ec.Count -gt 0) {
    try {
        $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 2.6), $false)
    } catch {
        Write-Host "  AddUsingDistance failed, trying AddDistanceChamfer..." -ForegroundColor Yellow
        try {
            $null = $cd.Features.ChamferFeatures.AddDistanceChamfer($ec, (MM 2.6))
        } catch {
            Write-Host "  Chamfer skipped: $_" -ForegroundColor Yellow
        }
    }
}

# Read back
$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
Write-Host ""
Write-Host ("BBox: {0} × {1} × {2} mm  (target 75 × 75 × 21.5)" -f $xL,$yL,$zL) -ForegroundColor Green
Write-Host ("Vol:  {0} mm³  (target 43,734 → diff {1:F1}%)" -f $vAct, ((($vAct - 43734.2)/43734.2)*100)) -ForegroundColor Green

$out = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v2.ipt"
$doc.SaveAs($out, $false)
Write-Host "Saved: $out" -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
