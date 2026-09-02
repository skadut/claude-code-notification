# notify.ps1 — Claude Code Stop hook (Windows Toast + custom sound)

$cfgPath = "$PSScriptRoot\cc-notif-config.json"
$cfg = $null
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json } catch {}
}

# Defaults
$title    = if ($cfg.title)    { $cfg.title }    else { 'Claude Code' }
$msgTpl   = if ($cfg.message)  { $cfg.message }  else { "Session '{0}' done!" }
$sndPath  = if ($cfg.sound)    { $cfg.sound }    else { '' }
$sndDur   = if ($cfg.soundDuration) { $cfg.soundDuration } else { 3 }
$locale   = if ($cfg.locale)   { $cfg.locale }   else { 'en' }

# Locale templates (used only when message is default)
$localeMsgs = @{
    'en' = "Session '{0}' done!"
    'id' = "Sesi '{0}' selesai!"
    'ja' = "Session '{0}' done!"
    'zh' = "Session '{0}' done!"
}
if ($msgTpl -eq "Session '{0}' done!" -and $localeMsgs.ContainsKey($locale)) {
    $msgTpl = $localeMsgs[$locale]
}

# Read session payload from stdin
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json; $sid = $j.session_id } catch { $sid = '' }

# Resolve session name: custom title > cwd folder > sid prefix
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

$body = $msgTpl -f $name

# --- Windows Toast notification ---
try {
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml(@"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$([System.Security.SecurityElement]::Escape($title))</text>
      <text>$([System.Security.SecurityElement]::Escape($body))</text>
    </binding>
  </visual>
</toast>
"@)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show($toast)
} catch {
    # Fallback to balloon if WinRT unavailable
    Add-Type -AssemblyName System.Windows.Forms
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Information
    $n.Visible = $true
    $n.ShowBalloonTip(6000, $title, $body, [System.Windows.Forms.ToolTipIcon]::None)
    Start-Sleep 2
    $n.Dispose()
}

# --- Play custom sound ---
if ($sndPath -and (Test-Path $sndPath)) {
    $ext = [System.IO.Path]::GetExtension($sndPath).ToLower()
    if ($ext -in '.mp3', '.wav', '.wma') {
        try {
            Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class WinMM {
    [DllImport("winmm.dll")]
    public static extern int mciSendString(string cmd, System.Text.StringBuilder ret, int retLen, System.IntPtr hwnd);
}
'@ -ErrorAction SilentlyContinue
            $alias = "snd_$PID"
            [WinMM]::mciSendString("open `"$sndPath`" type mpegvideo alias $alias", $null, 0, 0) | Out-Null
            [WinMM]::mciSendString("play $alias", $null, 0, 0) | Out-Null
            Start-Sleep $sndDur
            [WinMM]::mciSendString("close $alias", $null, 0, 0) | Out-Null
        } catch {}
    }
}
