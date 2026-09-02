# uninstall.ps1 — Remove claude-code-notification

$ErrorActionPreference = 'Stop'
$HooksDir     = "$env:USERPROFILE\.claude\hooks"
$SettingsPath = "$env:USERPROFILE\.claude\settings.json"
$HookCmd      = '& "$env:USERPROFILE\.claude\hooks\cc-notif.ps1"'

# 1. Remove hook from settings.json
if (Test-Path $SettingsPath) {
    $s = Get-Content $SettingsPath -Raw | ConvertFrom-Json
    if ($s.hooks -and $s.hooks.PSObject.Properties['Stop']) {
        $filtered = @($s.hooks.Stop) | Where-Object {
            $keep = $true
            foreach ($h in @($_.hooks)) {
                if ($h.command -eq $HookCmd) { $keep = $false; break }
            }
            $keep
        }
        if ($filtered.Count -eq 0) {
            $s.hooks.PSObject.Properties.Remove('Stop')
        } else {
            $s.hooks.Stop = @($filtered)
        }
        $s | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
        Write-Host "[OK] Hook removed from settings.json" -ForegroundColor Green
    } else {
        Write-Host "[--] No Stop hook found in settings.json" -ForegroundColor Cyan
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
