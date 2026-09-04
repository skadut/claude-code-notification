# notify.ps1 — Claude Code notification hook (Windows Toast + custom sound)
#   -Event Stop          fired when a session finishes
#   -Event Notification  fired when Claude asks for input / permission
param([ValidateSet('Stop', 'Notification')][string]$HookEvent = 'Stop')

$cfgPath = "$PSScriptRoot\cc-notif-config.json"
$cfg = $null
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json } catch {}
}

$isAsk = $HookEvent -eq 'Notification'

# Defaults (null-check so user can set empty string or 0 intentionally)
$title    = if ($null -ne $cfg.title)         { $cfg.title }         else { 'Claude Code' }
$sndDur   = if ($null -ne $cfg.soundDuration) { $cfg.soundDuration } else { 3 }
$locale   = if ($null -ne $cfg.locale)        { $cfg.locale }        else { 'en' }

$defaultMsg = if ($isAsk) { "Session '{0}' needs your input" } else { "Session '{0}' done!" }
$cfgMsg     = if ($isAsk) { $cfg.askMessage } else { $cfg.message }
$msgTpl     = if ($null -ne $cfgMsg) { $cfgMsg } else { $defaultMsg }

# askSound falls back to sound when unset
$sndPath = if ($null -ne $cfg.sound) { $cfg.sound } else { '' }
if ($isAsk -and $cfg.askSound) { $sndPath = $cfg.askSound }

# Locale templates (applied only when message is left at the default)
$localeMsgs = @{
    'en' = @{ Stop = "Session '{0}' done!"; Notification = "Session '{0}' needs your input" }
    'id' = @{ Stop = "Sesi '{0}' selesai!"; Notification = "Sesi '{0}' butuh input kamu" }
}
if ($msgTpl -eq $defaultMsg -and $localeMsgs.ContainsKey($locale)) {
    $msgTpl = $localeMsgs[$locale][$HookEvent]
}

# Read session payload from stdin
$raw = [Console]::In.ReadToEnd()
$hookMsg = ''
try { $j = $raw | ConvertFrom-Json; $sid = $j.session_id; $hookMsg = [string]$j.message } catch { $sid = '' }
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

# Claude's own notification text is more specific than the template — prefer it.
if ($isAsk -and $hookMsg) { $body = "$name`: $hookMsg" }

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
