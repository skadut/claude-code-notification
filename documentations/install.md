# Install

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (ships with Windows) or newer
- Claude Code

macOS and Linux are **not supported**. The scripts use Windows-only APIs
(WinRT toasts, `winmm.dll`, `System.Windows.Forms`).

## Per terminal

### PowerShell

```powershell
git clone https://github.com/skadut/claude-code-notification
cd claude-code-notification
.\install.ps1
.\config.ps1
```

### Git Bash

```bash
git clone https://github.com/skadut/claude-code-notification
cd claude-code-notification
powershell -ExecutionPolicy Bypass -File ./install.ps1
powershell -ExecutionPolicy Bypass -File ./config.ps1
```

### Windows CMD

```cmd
git clone https://github.com/skadut/claude-code-notification
cd claude-code-notification
powershell -ExecutionPolicy Bypass -File install.ps1
powershell -ExecutionPolicy Bypass -File config.ps1
```

Restart Claude Code so it reloads `settings.json`.

## What gets written

| Path | Purpose |
|---|---|
| `%USERPROFILE%\.claude\hooks\cc-notif.ps1` | The hook script |
| `%USERPROFILE%\.claude\hooks\cc-notif-config.json` | Your settings |
| `%USERPROFILE%\.claude\settings.json` | Two hook entries: `Stop` and `Notification` |

Installing is safe to repeat. Existing hooks from other tools are **appended
to, never replaced**, and an existing config file is left untouched.

## Upgrading from an older version

Just run `.\install.ps1` again. It:

- Overwrites `cc-notif.ps1` with the current version
- Keeps your existing config, so your message and sound survive
- Adds the `Notification` hook without touching your `Stop` hook
- Migrates a legacy `cc-notif-config.ps1` to JSON, renaming the old file `.bak`

Your config will lack `askMessage` / `askSound` until you run `.\config.ps1`.
Until then, defaults apply — `askSound` falls back to `sound`.

## Manual setup

If you prefer not to run `install.ps1`:

1. Copy `notify.ps1` to `%USERPROFILE%\.claude\hooks\cc-notif.ps1`
2. Copy `config.example.json` to `%USERPROFILE%\.claude\hooks\cc-notif-config.json`
3. Add to `%USERPROFILE%\.claude\settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "& \"$env:USERPROFILE\.claude\hooks\cc-notif.ps1\" -HookEvent Stop",
            "shell": "powershell",
            "async": true
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "& \"$env:USERPROFILE\.claude\hooks\cc-notif.ps1\" -HookEvent Notification",
            "shell": "powershell",
            "async": true
          }
        ]
      }
    ]
  }
}
```

## Uninstall

```powershell
.\uninstall.ps1
```

Removes both hook entries and the installed files. Hooks belonging to other
tools are preserved.
