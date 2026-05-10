## batch_thumbnails.ps1
## Export 400x300 BMP thumbnail for every round folder that has a my_attempt_v3.ipt
## (or real.ipt as fallback). Skips folders that already have thumbnail.bmp.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File batch_thumbnails.ps1
##   powershell -ExecutionPolicy Bypass -File batch_thumbnails.ps1 -Force   # re-generate all
##   powershell -ExecutionPolicy Bypass -File batch_thumbnails.ps1 -Folder "C:\...\round1000_xxx"

param(
    [string]$Folder   = "",          # single folder; empty = all round_* under Desktop\test
    [switch]$Force    = $false,      # re-generate even if thumbnail.bmp exists
    [int]$Width       = 400,
    [int]$Height      = 300
)

$ErrorActionPreference = 'Stop'

# ---- nag-watcher ----
if (-not ('NagThumb' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagThumb {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcherThumb([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW_T {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stop = (Get-Date).AddHours(2)
        while ((Get-Date) -lt $stop) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [NW_T]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW_T]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW_T]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW_T]::IsWindowVisible($h) -and
                    ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW_T]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

# ---- connect to Inventor ----
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
    Write-Host "Attached to running Inventor." -ForegroundColor Green
} catch {
    Write-Host "Launching Inventor..." -ForegroundColor Yellow
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep -Seconds 5
}
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagWatcherThumb $invPid

# ---- gather folders ----
$desk = Join-Path $env:USERPROFILE 'Desktop\test'
if ($Folder -ne "") {
    $folders = @(Get-Item $Folder)
} else {
    $folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' } | Sort-Object Name
}
Write-Host "Processing $($folders.Count) folders..." -ForegroundColor Cyan

$done = 0; $skipped = 0; $failed = 0

foreach ($f in $folders) {
    $thumbPath = Join-Path $f.FullName 'thumbnail.bmp'
    if (-not $Force -and (Test-Path $thumbPath)) {
        $skipped++
        continue
    }

    # Prefer my_attempt_v3.ipt; fallback to real.ipt
    $iptPath = Join-Path $f.FullName 'my_attempt_v3.ipt'
    if (-not (Test-Path $iptPath)) {
        $iptPath = Join-Path $f.FullName 'real.ipt'
    }
    if (-not (Test-Path $iptPath)) {
        Write-Host "  SKIP $($f.Name) — no .ipt found" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    try {
        # close all first
        try { $inv.Documents.CloseAll($false) } catch { }

        # open the part
        $doc = $inv.Documents.Open($iptPath, $true)
        Start-Sleep -Milliseconds 300

        # zoom to fit
        $view = $inv.ActiveView
        $view.Fit()
        Start-Sleep -Milliseconds 200

        # export thumbnail
        $view.SaveAsBitmap($thumbPath, $Width, $Height)
        $doc.Close($false)

        $done++
        Write-Host ("  [{0,3}] {1} → thumbnail.bmp ({2} KB)" -f $done, $f.Name, [Math]::Round((Get-Item $thumbPath).Length/1024)) -ForegroundColor Green
    } catch {
        $failed++
        Write-Host "  FAIL $($f.Name): $_" -ForegroundColor Red
        try { $inv.Documents.CloseAll($false) } catch { }
    }
}

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
Write-Host "`n=== DONE: done=$done skipped=$skipped failed=$failed ===" -ForegroundColor Cyan
