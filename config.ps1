# config.ps1 — Interactive config editor for claude-code-notification

Write-Host ""
Write-Host "=== Claude Code Notification Config ===" -ForegroundColor Cyan
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

# Sound
Write-Host ""
Write-Host "Sound file path (.mp3 / .wav / .wma, empty to disable)" -ForegroundColor Yellow
Write-Host "  Current: $(if ($cfg.sound) { $cfg.sound } else { '(none)' })" -ForegroundColor Gray
$v = Read-Host "  New value (type 'none' to clear)"
if ($v -eq 'none') { $cfg.sound = '' }
elseif ($v -ne '') {
    if (Test-Path $v) {
        $ext = [System.IO.Path]::GetExtension($v).ToLower()
        if ($ext -in '.mp3', '.wav', '.wma') {
            $cfg.sound = $v
        } else {
            Write-Host "  [!!] Unsupported format ($ext). Skipped." -ForegroundColor Red
        }
    } else {
        Write-Host "  [!!] File not found: $v. Skipped." -ForegroundColor Red
    }
}

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
$cfg | ConvertTo-Json -Depth 5 | Set-Content $ConfigPath -Encoding utf8

Write-Host ""
Write-Host "--- Saved ---" -ForegroundColor Green
Write-Host "  File:     $ConfigPath"
Write-Host "  Title:    $($cfg.title)"
Write-Host "  Message:  $($cfg.message -f 'my-project')"
Write-Host "  Sound:    $(if ($cfg.sound) { $cfg.sound } else { '(disabled)' })"
Write-Host "  Duration: $($cfg.soundDuration)s"
Write-Host "  Locale:   $($cfg.locale)"
Write-Host ""
