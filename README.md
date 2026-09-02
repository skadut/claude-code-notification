# claude-code-notification

Windows 10/11 desktop notification hook for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).  
Shows the **session name**, a **custom message**, and plays a **custom sound** when a session finishes.

Uses modern Windows Toast notifications with a fallback to legacy balloons.

## Quick Setup

```powershell
git clone https://github.com/skadut/claude-code-notification
cd claude-code-notification
.\install.ps1
```

Then edit your config:

```powershell
notepad "$env:USERPROFILE\.claude\hooks\cc-notif-config.json"
```

Done. Notifications fire on every session stop.

## Config

`~/.claude/hooks/cc-notif-config.json`:

```json
{
  "title": "Claude Code",
  "message": "Session '{0}' done!",
  "sound": "C:\\path\\to\\sound.mp3",
  "soundDuration": 3,
  "locale": "en"
}
```

| Key | Description |
|---|---|
| `title` | Notification header |
| `message` | Body text. `{0}` = session name |
| `sound` | Path to `.mp3`, `.wav`, or `.wma`. Empty = no sound |
| `soundDuration` | Fixed playback time in seconds (recommended: 3) |
| `locale` | Language for default message: `en`, `id` (more welcome via PR) |

### Sound tips

- Keep sounds short — **3 seconds or less** is ideal
- [myinstants.com](https://www.myinstants.com/) has a large library of short notification sounds ready to download
- Supported formats: `.mp3`, `.wav`, `.wma`

## Session Name Resolution

Priority order:
1. Custom title set via `/rename` in Claude Code
2. Project folder name (from session working directory)
3. First 8 characters of session ID

## Uninstall

```powershell
cd claude-code-notification
.\uninstall.ps1
```

Removes the hook from `settings.json` and deletes installed files. Other Stop hooks are preserved.

## How It Works

Claude Code fires a `Stop` hook when a session ends. The installer registers `cc-notif.ps1` in `~/.claude/settings.json`. On stop, the script:

1. Reads the session ID from stdin (JSON payload from Claude Code)
2. Resolves the session name from `~/.claude/projects/`
3. Shows a Windows Toast notification (falls back to balloon on older systems)
4. Plays your sound file via WinMM

## Files

| File | Purpose |
|---|---|
| `notify.ps1` | Hook script — installed as `~/.claude/hooks/cc-notif.ps1` |
| `config.example.json` | Config template — installed as `~/.claude/hooks/cc-notif-config.json` |
| `install.ps1` | One-command installer (appends to existing hooks, never overwrites) |
| `uninstall.ps1` | Clean removal |

## Manual Install

1. Copy `notify.ps1` → `~/.claude/hooks/cc-notif.ps1`
2. Copy `config.example.json` → `~/.claude/hooks/cc-notif-config.json` and edit
3. Add to `~/.claude/settings.json` under `hooks.Stop`:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "& \"$env:USERPROFILE\\.claude\\hooks\\cc-notif.ps1\"",
      "shell": "powershell",
      "async": true
    }
  ]
}
```

## Upgrading

Run `install.ps1` again — it updates the hook script and migrates old `.ps1` configs to `.json` automatically.

## Requirements

- Windows 10/11
- PowerShell 5.1+ (built-in)
- Claude Code CLI

## License

MIT
