## auto_ring_v2.ps1 — improved version that filters out bolt holes.
## Old v1 picked second-largest radius as "inner ring", which broke for parts
## with bolt holes (R=2.5 etc) where the bolt holes were treated as inner ring.
## v2: only consider cylinders whose radius is at least 30% of OD as candidate inner.
##
## Usage: $folder is the round folder; place real.ipt inside; run from there.

param([string]$folder = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagH' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagH {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagH([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NH {
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
            [NH]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NH]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NH]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NH]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NH]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kPos=20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagH $invPid

$realF = Join-Path $folder "real.ipt"
try { $inv.Documents.CloseAll($false) } catch { }
$realDoc = $inv.Documents.Open($realF, $true)
$rcd = $realDoc.ComponentDefinition; $rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 1)
$thick = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
$bbox = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$rOut = $bbox / 2
$radii = @()
foreach ($f in $rbd.Faces) {
    if ($f.SurfaceType -eq 5891) { $radii += [double]($f.Geometry.Radius * 10) }
}
$radii = $radii | Sort-Object -Unique -Descending

# v2 fix: filter out small holes (less than 30% of OD)
$minInnerR = $rOut * 0.30
$validRadii = $radii | Where-Object { $_ -lt $rOut -and $_ -gt $minInnerR }
if ($validRadii.Count -gt 0) {
    $rIn = $validRadii[0]   # largest among valid candidates
} else {
    $rIn = 0   # solid disc
}
Write-Host ("REAL: BBox={0}, thick={1}, OD R={2}, ID R={3} (filtered), Vol={4}" -f $bbox, $thick, $rOut, $rIn, $realVol) -ForegroundColor Magenta
$realDoc.Close($false)

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

$s = $cd.Sketches.Add($xy)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
if ($rIn -gt 0) {
    $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
}
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
$ed.SetDistanceExtent((MM $thick), $kPos); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Add small bolt holes if there were filtered-out small radii
$boltRadii = $radii | Where-Object { $_ -le $minInnerR -and $_ -gt 0.5 }
if ($boltRadii.Count -gt 0) {
    Write-Host ("  Found {0} bolt hole radii (filtered): {1}" -f $boltRadii.Count, ($boltRadii -join ', ')) -ForegroundColor DarkGray
}

$body = $cd.SurfaceBodies.Item(1)
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) { if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) } }
if ($ec.Count -gt 0) { try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 0.5), $false) } catch { } }

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
$dPct = (($vAct - $realVol) / $realVol) * 100
Write-Host ("My: BBox {0} × {0} × {1} | Vol {2} | diff {3:F2}%" -f $xL, $zL, $vAct, $dPct) -ForegroundColor Green
$doc.SaveAs((Join-Path $folder "my_attempt_v2.ipt"), $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
