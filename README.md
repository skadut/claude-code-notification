# claude-code-notification

Windows 11 desktop notification hook for Claude Code.  
Shows the **session name**, a **custom message**, and plays a **custom sound** when a session finishes.

## Setup — 30 seconds

```powershell
# 1. Clone
git clone https://github.com/YOUR_USERNAME/claude-code-notification
cd claude-code-notification

# 2. Install (patches ~/.claude/settings.json automatically)
.\install.ps1

# 3. Customize
notepad "$env:USERPROFILE\.claude\hooks\cc-notif-config.ps1"
```

That's it. Start any Claude Code session and finish it — notification fires on stop.

## Config

Edit `~/.claude/hooks/cc-notif-config.ps1`:

```powershell
$NotifTitle   = "Claude Code"
$NotifMessage = "Session '{0}' done!"   # {0} = session name
$SoundPath    = "C:\path\to\sound.mp3"  # .mp3 or .wav — leave empty to disable
$SoundDuration = 3                       # seconds to let it play
```

| Variable | Description |
|---|---|
| `$NotifTitle` | Notification header text |
| `$NotifMessage` | Body text. `{0}` is replaced with the session name. |
| `$SoundPath` | Full path to `.mp3` or `.wav`. Empty = no sound. |
| `$SoundDuration` | How many seconds to play before auto-close. |

## Session name resolution

Priority order:
1. Custom title set via `/rename` in Claude Code
2. Project folder name (from session `cwd`)
3. First 8 chars of session ID

## How it works

Claude Code fires its `Stop` hook when a session ends. `install.ps1` registers `cc-notif.ps1` as that hook in `~/.claude/settings.json`. The script:

1. Reads the session ID from stdin (Claude Code passes it as JSON)
2. Resolves the session name from `~/.claude/projects/`
3. Shows a Windows balloon notification
4. Plays your sound file via WinMM (no extra installs)

## Files

| File | Purpose |
|---|---|
| `notify.ps1` | Hook script — copy of this is installed to `~/.claude/hooks/cc-notif.ps1` |
| `config.example.ps1` | Config template — copied to `~/.claude/hooks/cc-notif-config.ps1` on first install |
| `install.ps1` | One-command installer |

## Manual install

If you prefer not to run the installer:

1. Copy `notify.ps1` → `~/.claude/hooks/cc-notif.ps1`
2. Copy `config.example.ps1` → `~/.claude/hooks/cc-notif-config.ps1` and edit it
3. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
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
    ]
  }
}
```

## Requirements

- Windows 10/11
- PowerShell 5.1+ (built-in)
- Claude Code CLI
