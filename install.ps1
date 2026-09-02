# install.ps1 — One-command setup for claude-code-notification

$ErrorActionPreference = 'Stop'
$HooksDir     = "$env:USERPROFILE\.claude\hooks"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
$ScriptDir    = $PSScriptRoot
$HookCmd      = '& "$env:USERPROFILE\.claude\hooks\cc-notif.ps1"'

# 1. Ensure hooks dir
New-Item -ItemType Directory -Force $HooksDir | Out-Null

# 2. Install hook script
Copy-Item "$ScriptDir\notify.ps1" "$HooksDir\cc-notif.ps1" -Force
Write-Host "[OK] Hook installed: $HooksDir\cc-notif.ps1" -ForegroundColor Green

# 3. Config: migrate old .ps1 config or create new .json
$OldConfig = "$HooksDir\cc-notif-config.ps1"
$NewConfig = "$HooksDir\cc-notif-config.json"

if ((Test-Path $OldConfig) -and !(Test-Path $NewConfig)) {
    Write-Host "[!!] Found old .ps1 config — migrating to .json" -ForegroundColor Yellow
    try {
        $raw = Get-Content $OldConfig -Raw
        $extract = { param($varName, $default)
            if ($raw -match ('\$' + $varName + '\s*=\s*[''"](.+?)[''"]')) { $Matches[1] } else { $default }
        }
        $extractNum = { param($varName, $default)
            if ($raw -match ('\$' + $varName + '\s*=\s*(\d+)')) { [int]$Matches[1] } else { $default }
        }
        $migrated = @{
            title         = & $extract 'NotifTitle'   'Claude Code'
            message       = & $extract 'NotifMessage' "Session '{0}' done!"
            sound         = & $extract 'SoundPath'    ''
            soundDuration = & $extractNum 'SoundDuration' 3
            locale        = 'en'
        }
        $migrated | ConvertTo-Json -Depth 5 | Set-Content $NewConfig -Encoding utf8
        Rename-Item $OldConfig "$OldConfig.bak"
        Write-Host "[OK] Migrated config: $NewConfig (old renamed to .bak)" -ForegroundColor Green
    } catch {
        Write-Host "[!!] Migration failed, creating fresh config" -ForegroundColor Red
        Copy-Item "$ScriptDir\config.example.json" $NewConfig
    }
} elseif (!(Test-Path $NewConfig)) {
    Copy-Item "$ScriptDir\config.example.json" $NewConfig
    Write-Host "[OK] Config created: $NewConfig" -ForegroundColor Green
    Write-Host "     -> Edit it to set your message and sound." -ForegroundColor Yellow
} else {
    Write-Host "[--] Config exists, skipping: $NewConfig" -ForegroundColor Cyan
}

# 4. Patch settings.json — APPEND to existing Stop hooks, don't overwrite
if (Test-Path $SettingsPath) {
    $s = Get-Content $SettingsPath -Raw | ConvertFrom-Json
} else {
    $s = [PSCustomObject]@{}
}

if (!$s.PSObject.Properties['hooks']) {
    $s | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{})
}

$newHookEntry = [PSCustomObject]@{
    type    = "command"
    command = $HookCmd
    shell   = "powershell"
    async   = $true
}
$newHookGroup = [PSCustomObject]@{ hooks = @($newHookEntry) }

if ($s.hooks.PSObject.Properties['Stop']) {
    $existing = @($s.hooks.Stop)
    # Check if our hook is already registered
    $alreadyInstalled = $false
    foreach ($group in $existing) {
        foreach ($h in @($group.hooks)) {
            if ($h.command -eq $HookCmd) { $alreadyInstalled = $true; break }
        }
        if ($alreadyInstalled) { break }
    }
    if (!$alreadyInstalled) {
        $s.hooks.Stop = @($existing) + @($newHookGroup)
        Write-Host "[OK] Hook appended to existing Stop hooks." -ForegroundColor Green
    } else {
        Write-Host "[--] Hook already registered in Stop hooks." -ForegroundColor Cyan
    }
} else {
    $s.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @($newHookGroup)
    Write-Host "[OK] Stop hook registered." -ForegroundColor Green
}

$s | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
Write-Host "[OK] settings.json saved." -ForegroundColor Green

Write-Host ""
Write-Host "Done! Edit your config:" -ForegroundColor White
Write-Host "  notepad `"$NewConfig`"" -ForegroundColor Yellow
