# notify.ps1 — Claude Code Stop hook
# Installed to: ~/.claude/hooks/cc-notif.ps1

# Load user config (dot-source)
$cfg = "$PSScriptRoot\cc-notif-config.ps1"
if (Test-Path $cfg) { . $cfg }

# Defaults
if (!$NotifTitle)    { $NotifTitle    = "Claude Code" }
if (!$NotifMessage)  { $NotifMessage  = "Session '{0}' done!" }
if (!$SoundDuration) { $SoundDuration = 3 }

# Read session payload from stdin
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json; $sid = $j.session_id } catch { $sid = '' }

# Resolve session name: custom title → project cwd folder → sid prefix
$name = ''
$jf = Get-ChildItem "$env:USERPROFILE\.claude\projects" -Filter "$sid.jsonl" -Recurse -ErrorAction SilentlyContinue |
      Select-Object -First 1

if ($jf) {
    try {
        $tl = Select-String -Path $jf.FullName -Pattern '"type":"custom-title"' | Select-Object -First 1
        if ($tl) { $name = ($tl.Line | ConvertFrom-Json).customTitle }
    } catch {}

    if (!$name) {
        try {
            $cwd = Get-Content $jf.FullName -First 20 | ForEach-Object {
                try { $l = $_ | ConvertFrom-Json; if ($l.cwd) { $l.cwd } } catch {}
            } | Select-Object -First 1
            if ($cwd) { $name = Split-Path $cwd -Leaf }
        } catch {}
    }
}
if (!$name) { $name = if ($sid) { $sid.Substring(0, [Math]::Min(8, $sid.Length)) } else { 'unknown' } }

$body = $NotifMessage -f $name

# Show Windows notification balloon
Add-Type -AssemblyName System.Windows.Forms
$n           = New-Object System.Windows.Forms.NotifyIcon
$n.Icon      = [System.Drawing.SystemIcons]::Information
$n.Visible   = $true
$n.ShowBalloonTip(6000, $NotifTitle, $body, [System.Windows.Forms.ToolTipIcon]::None)

# Play custom sound via WinMM (supports .mp3 / .wav)
if ($SoundPath -and (Test-Path $SoundPath)) {
    try {
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class WinMM {
    [DllImport("winmm.dll")]
    public static extern int mciSendString(string cmd, System.Text.StringBuilder ret, int retLen, System.IntPtr hwnd);
}
'@ -ErrorAction SilentlyContinue
        [WinMM]::mciSendString("open `"$SoundPath`" type mpegvideo alias snd", $null, 0, 0) | Out-Null
        [WinMM]::mciSendString('play snd', $null, 0, 0) | Out-Null
        Start-Sleep $SoundDuration
        [WinMM]::mciSendString('close snd', $null, 0, 0) | Out-Null
    } catch {}
}

Start-Sleep 1
$n.Dispose()
