# config.ps1 — Interactive config editor for claude-code-notification

Write-Host ""
Write-Host "=== Claude Code Notification Config ===" -ForegroundColor Cyan
Write-Host ""

# Prompt for an audio file: accepts a typed path, 'b' to open the Explorer
# picker, or 'none' to clear. Returns $null when nothing should change.
function Read-SoundPath {
    param([string]$Label, [string]$Current)

    Write-Host ""
    Write-Host "$Label (.mp3 / .wav / .wma)" -ForegroundColor Yellow
    Write-Host "  Current: $(if ($Current) { $Current } else { '(none)' })" -ForegroundColor Gray
    Write-Host "  Type 'b' to browse, 'none' to clear, Enter to keep." -ForegroundColor Gray
    $v = Read-Host "  New value"

    if ($v -in 'b', 'browse') {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title  = "Pick a notification sound"
        $dlg.Filter = "Audio (*.mp3;*.wav;*.wma)|*.mp3;*.wav;*.wma|All files (*.*)|*.*"
        if ($Current -and (Test-Path $Current)) {
            $dlg.InitialDirectory = Split-Path $Current -Parent
        }
        # Owner form keeps the dialog above the console instead of behind it.
        $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }
        $v = if ($dlg.ShowDialog($owner) -eq 'OK') { $dlg.FileName } else { '' }
        $owner.Dispose()
        if ($v -eq '') { Write-Host "  Cancelled. Skipped." -ForegroundColor Gray }
    }

    if ($v -eq 'none') { return '' }
    if ($v -eq '') { return $null }

    if (!(Test-Path $v)) {
        Write-Host "  [!!] File not found: $v. Skipped." -ForegroundColor Red
        return $null
    }
    $ext = [System.IO.Path]::GetExtension($v).ToLower()
    if ($ext -notin '.mp3', '.wav', '.wma') {
        Write-Host "  [!!] Unsupported format ($ext). Skipped." -ForegroundColor Red
        return $null
    }
    return $v
}
Write-Host ""

# Step 1: Ask for config path
$DefaultPath = "$env:USERPROFILE\.claude\hooks\cc-notif-config.json"
Write-Host "Config file path" -ForegroundColor Yellow
Write-Host "  Default: $DefaultPath" -ForegroundColor Gray
$ConfigPath = Read-Host "  Path (Enter for default)"
if ($ConfigPath -eq '') { $ConfigPath = $DefaultPath }

if (!(Test-Path $ConfigPath)) {
    Write-Host ""
    Write-Host "File not found: $ConfigPath" -ForegroundColor Red
    Write-Host "Run install.ps1 first, or check the path." -ForegroundColor Yellow
    exit 1
}

# Step 2: Load and edit
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
Write-Host ""
Write-Host "Editing: $ConfigPath" -ForegroundColor Green
Write-Host "Press Enter to keep current value." -ForegroundColor Gray

# Older config files predate askMessage/askSound — add the property if missing.
function Set-Field {
    param([string]$Name, $Value)
    if ($cfg.PSObject.Properties[$Name]) { $cfg.$Name = $Value }
    else { $cfg | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}


# Title
Write-Host ""
Write-Host "Notification title" -ForegroundColor Yellow
Write-Host "  Current: $($cfg.title)" -ForegroundColor Gray
$v = Read-Host "  New value"
if ($v -ne '') { $cfg.title = $v }

# Message
Write-Host ""
Write-Host "Notification message ({0} = session name)" -ForegroundColor Yellow
Write-Host "  Current: $($cfg.message)" -ForegroundColor Gray
$v = Read-Host "  New value"
if ($v -ne '') { $cfg.message = $v }

# Ask message
Write-Host ""
Write-Host "Input-needed message ({0} = session name)" -ForegroundColor Yellow
Write-Host "  Current: $(if ($cfg.askMessage) { $cfg.askMessage } else { '(default)' })" -ForegroundColor Gray
$v = Read-Host "  New value"
if ($v -ne '') { Set-Field 'askMessage' $v }

# Done sound
$v = Read-SoundPath "Sound when a session finishes" $cfg.sound
if ($null -ne $v) { Set-Field 'sound' $v }

# Ask sound
$v = Read-SoundPath "Sound when Claude needs your input (empty = same as above)" $cfg.askSound
if ($null -ne $v) { Set-Field 'askSound' $v }

# Sound Duration
Write-Host ""
Write-Host "Sound duration in seconds" -ForegroundColor Yellow
Write-Host "  Current: $($cfg.soundDuration)" -ForegroundColor Gray
$v = Read-Host "  New value"
if ($v -ne '') {
    try { $cfg.soundDuration = [int]$v } catch {
        Write-Host "  [!!] Not a number. Skipped." -ForegroundColor Red
    }
}

# Locale
Write-Host ""
Write-Host "Locale (en, id)" -ForegroundColor Yellow
Write-Host "  Current: $($cfg.locale)" -ForegroundColor Gray
$v = Read-Host "  New value"
if ($v -ne '' -and $v -in 'en', 'id') { $cfg.locale = $v }
elseif ($v -ne '') { Write-Host "  [!!] Unknown locale. Skipped." -ForegroundColor Red }

# Step 3: Save
# PS 5.1 escapes ' < > & as \uXXXX; decode them so the file stays hand-editable.
$json = $cfg | ConvertTo-Json -Depth 5
$map = @{ '\u0027' = "'"; '\u003c' = '<'; '\u003e' = '>'; '\u0026' = '&' }
foreach ($k in $map.Keys) { $json = $json.Replace($k, $map[$k]) }
$json | Set-Content $ConfigPath -Encoding utf8

Write-Host ""
Write-Host "--- Saved ---" -ForegroundColor Green
Write-Host "  File:     $ConfigPath"
Write-Host "  Title:    $($cfg.title)"
Write-Host "  Message:  $($cfg.message -f 'my-project')"
Write-Host "  Ask msg:  $($cfg.askMessage -f 'my-project')"
Write-Host "  Sound:    $(if ($cfg.sound) { $cfg.sound } else { '(disabled)' })"
Write-Host "  Ask snd:  $(if ($cfg.askSound) { $cfg.askSound } else { '(same as above)' })"
Write-Host "  Duration: $($cfg.soundDuration)s"
Write-Host "  Locale:   $($cfg.locale)"
Write-Host ""
