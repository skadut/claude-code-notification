# uninstall.ps1 — Remove claude-code-notification

$ErrorActionPreference = 'Stop'
$HooksDir     = "$env:USERPROFILE\.claude\hooks"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
$HookCmd      = '& "$env:USERPROFILE\.claude\hooks\cc-notif.ps1"'

# 1. Remove hooks from settings.json
if (Test-Path $SettingsPath) {
    $s = Get-Content $SettingsPath -Raw | ConvertFrom-Json
    $removed = $false
    foreach ($evt in 'Stop', 'Notification') {
        if ($s.hooks -and $s.hooks.PSObject.Properties[$evt]) {
            # -like matches both v1 (bare path) and v2 (path + -HookEvent) commands.
            $filtered = @($s.hooks.$evt) | Where-Object {
                $keep = $true
                foreach ($h in @($_.hooks)) {
                    if ($h.command -like "$HookCmd*") { $keep = $false; break }
                }
                $keep
            }
            if ($filtered.Count -eq 0) {
                $s.hooks.PSObject.Properties.Remove($evt)
            } else {
                $s.hooks.$evt = @($filtered)
            }
            $removed = $true
            Write-Host "[OK] $evt hook removed from settings.json" -ForegroundColor Green
        } else {
            Write-Host "[--] No $evt hook found in settings.json" -ForegroundColor Cyan
        }
    }
    if ($removed) {
        $s | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
    }
} else {
    Write-Host "[--] settings.json not found" -ForegroundColor Cyan
}

# 2. Remove installed files
$files = @(
    "$HooksDir\cc-notif.ps1",
    "$HooksDir\cc-notif-config.json",
    "$HooksDir\cc-notif-config.ps1.bak"
)
foreach ($f in $files) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Host "[OK] Deleted: $f" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Uninstalled. Your other Stop hooks (if any) are preserved." -ForegroundColor White
