## build_flinger.ps1 — Round 1: EV-L200-MP Flinger
## Build by reading the PDF only (no peeking at the .ipt).
## A revolved part: half-section sketched in XY plane, revolved about X axis.

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

# ---------- Helper: Win32 P/Invoke for closing nag dialogs ----------
if (-not ('NagCloser' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NagCloser {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint procId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Close-NagDialogs([uint32]$invPid, [string]$titleSubstring) {
    $found = [System.Collections.Generic.List[IntPtr]]::new()
    [NagCloser]::EnumWindows({param($h,$l)
        $sb = New-Object Text.StringBuilder 256
        [void][NagCloser]::GetWindowText($h, $sb, 256)
        [uint32]$wp = 0
        [void][NagCloser]::GetWindowThreadProcessId($h, [ref]$wp)
        if ($wp -eq $invPid -and [NagCloser]::IsWindowVisible($h) -and $sb.ToString() -match $titleSubstring) {
            $script:found.Add($h)
        }
        $true
    }, [IntPtr]::Zero) | Out-Null
    foreach ($h in $found) {
        [void][NagCloser]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
    }
    return $found.Count
}

# Async nag-closer: starts a background job that polls for nag dialogs and
# closes them. Stop with $job | Stop-Job; Remove-Job.
function Start-NagWatcher([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($targetPid)
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NagInner {
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
            [NagInner]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NagInner]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NagInner]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $targetPid -and [NagInner]::IsWindowVisible($h)) {
                    $t = $sb.ToString()
                    if ($t -match 'Configurator' -or $t -match 'Sign In' -or $t -match 'Welcome') {
                        $script:hits.Add($h)
                    }
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) {
                [void][NagInner]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
            }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

# Inventor enums
$kPartDocumentObject       = 12290
$kJoinOperation            = 20481
$kPositiveExtentDirection  = 20993

Write-Host "Connecting to Inventor..." -ForegroundColor Cyan
$invType = [Type]::GetTypeFromProgID('Inventor.Application')
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance($invType)
    Start-Sleep -Seconds 2
}
$inv.Visible = $true

# Start the nag-watcher so any Configurator 360 / Sign In dialog gets closed
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagWatcher $invPid
Write-Host "  Nag-watcher started (job $($nagJob.Id))." -ForegroundColor DarkGray

Write-Host "Closing existing docs..." -ForegroundColor DarkYellow
try { $inv.Documents.CloseAll($false) } catch { }

Write-Host "Creating new metric part..." -ForegroundColor Cyan
$tpl = $inv.FileManager.GetTemplateFile($kPartDocumentObject)
$partDoc = $inv.Documents.Add($kPartDocumentObject, $tpl, $true)
$cd = $partDoc.ComponentDefinition
$tg = $inv.TransientGeometry

# Use XY workplane (3). The X axis will be the axis of revolution.
$xy = $cd.WorkPlanes.Item(3)
$s = $cd.Sketches.Add($xy)

# Half-section profile (X = axial along axis, Y = radius from axis).
# 10 vertices, closed polygon. Going CCW starting at left-end inner-bore corner.
$pts = @(
    @(0,    12),     # 0: left end, inner bore corner
    @(0,    24.5),   # 1: left end, outer edge (Ø49 / 2)
    @(4.5,  24.5),   # 2: flange right shoulder (after 4.5 axial)
    @(4.5,  21.5),   # 3: drop into groove (Ø43 / 2)
    @(8.0,  21.5),   # 4: groove ends (4.5 + 3.5 axial)
    @(8.0,  19.5),   # 5: drop to shaft body (Ø39 / 2)
    @(12.0, 19.5),   # 6: end of shaft body (8 + 4 axial)
    @(12.0, 14.0),   # 7: drop to journal (Ø28 / 2)
    @(15.5, 14.0),   # 8: right end, journal outer (12 + 3.5 axial)
    @(15.5, 12)      # 9: right end, inner bore corner
)

# Build sketch points first, then lines between them. This avoids the
# E_FAIL we hit when mixing Point2d and SketchPoint args to AddByTwoPoints.
$sketchPts = @()
foreach ($pt in $pts) {
    $p = $tg.CreatePoint2d((MM $pt[0]), (MM $pt[1]))
    $sp = $s.SketchPoints.Add($p, $false)
    $sketchPts += $sp
}

# Connect consecutive sketch points; final iteration closes the polygon.
for ($i = 0; $i -lt $sketchPts.Count; $i++) {
    $a = $sketchPts[$i]
    $b = $sketchPts[($i + 1) % $sketchPts.Count]
    $null = $s.SketchLines.AddByTwoPoints($a, $b)
}

Write-Host "  Lines created: $($s.SketchLines.Count)" -ForegroundColor DarkGray

# Need an axis of revolution. Use the X-axis (a 2D construction line on Y=0).
# Easiest: project the X-axis from origin into the sketch.
# In Inventor, you reference WorkAxis 1 = X axis.
$xAxis = $cd.WorkAxes.Item(1)

# Build the revolve
$prof = $s.Profiles.AddForSolid()
$revFeats = $cd.Features.RevolveFeatures
$rev = $revFeats.AddFull($prof, $xAxis, $kJoinOperation)

Write-Host "Revolved." -ForegroundColor Green

# Save
$out = "$env:USERPROFILE\Desktop\test\round1_EV-L200-MP_Flinger\my_attempt_flinger.ipt"
Write-Host "Saving to $out ..." -ForegroundColor Cyan
$partDoc.SaveAs($out, $false)
Write-Host "Done." -ForegroundColor Green

# Clean up nag-watcher job
try {
    $nagJob | Stop-Job -ErrorAction SilentlyContinue
    $nagJob | Remove-Job -ErrorAction SilentlyContinue
} catch { }
