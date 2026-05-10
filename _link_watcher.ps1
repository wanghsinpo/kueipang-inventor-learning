Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class LW {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
$invPid = (Get-Process -Name Inventor | Select-Object -First 1).Id
$stop = (Get-Date).AddHours(2)
while ((Get-Date) -lt $stop) {
    $wins = [System.Collections.Generic.List[IntPtr]]::new()
    [LW]::EnumWindows({param($h,$l)
        $sb = New-Object Text.StringBuilder 256
        [void][LW]::GetWindowText($h, $sb, 256)
        [uint32]$wp = 0
        [void][LW]::GetWindowThreadProcessId($h, [ref]$wp)
        if ($wp -eq $invPid -and [LW]::IsWindowVisible($h) -and ($sb.ToString() -match '读取链接|Resolve Link')) {
            $script:wins.Add($h)
        }
        $true
    }, [IntPtr]::Zero) | Out-Null
    foreach ($w in $wins) {
        $btns = [System.Collections.Generic.List[IntPtr]]::new()
        [LW]::EnumChildWindows($w, {param($h,$l)
            $sb = New-Object Text.StringBuilder 64
            [void][LW]::GetWindowText($h, $sb, 64)
            if ($sb.ToString() -match '全部跳|Skip All') { $script:btns.Add($h) }
            $true
        }, [IntPtr]::Zero) | Out-Null
        foreach ($btn in $btns) { [void][LW]::PostMessage($btn, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero) }
    }
    Start-Sleep -Milliseconds 250
}
