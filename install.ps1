# install.ps1 — One-command setup for claude-code-notification
# Run from the repo root: .\install.ps1

$ErrorActionPreference = 'Stop'
$HooksDir     = "$env:USERPROFILE\.claude\hooks"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
$ScriptDir    = $PSScriptRoot

# 1. Ensure hooks dir exists
New-Item -ItemType Directory -Force $HooksDir | Out-Null

# 2. Install hook script
Copy-Item "$ScriptDir\notify.ps1" "$HooksDir\cc-notif.ps1" -Force
Write-Host "[OK] Hook installed: $HooksDir\cc-notif.ps1" -ForegroundColor Green

# 3. Create config if missing
$ConfigDest = "$HooksDir\cc-notif-config.ps1"
if (!(Test-Path $ConfigDest)) {
    Copy-Item "$ScriptDir\config.example.ps1" $ConfigDest
    Write-Host "[OK] Config created: $ConfigDest" -ForegroundColor Green
    Write-Host "     -> Edit it to set your message and sound path." -ForegroundColor Yellow
} else {
    Write-Host "[--] Config already exists, skipping: $ConfigDest" -ForegroundColor Cyan
}

# 4. Patch ~/.claude/settings.json
$hookCmd = '& "$env:USERPROFILE\.claude\hooks\cc-notif.ps1"'
$newHookGroup = [PSCustomObject]@{
    hooks = @([PSCustomObject]@{
        type    = "command"
        command = $hookCmd
        shell   = "powershell"
        async   = $true
    })
}

if (Test-Path $SettingsPath) {
    $s = Get-Content $SettingsPath -Raw | ConvertFrom-Json
} else {
    $s = [PSCustomObject]@{}
}

if (!$s.PSObject.Properties['hooks']) {
    $s | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{})
}

# Replace Stop hooks entirely (this project IS the Stop hook)
if ($s.hooks.PSObject.Properties['Stop']) {
    $s.hooks.Stop = @($newHookGroup)
} else {
    $s.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @($newHookGroup)
}

$s | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
Write-Host "[OK] settings.json updated." -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete. Next step:" -ForegroundColor White
Write-Host "  Edit $ConfigDest" -ForegroundColor Yellow
Write-Host "  Set `$SoundPath to your .mp3/.wav and customize `$NotifMessage." -ForegroundColor Yellow
