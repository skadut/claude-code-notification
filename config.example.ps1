# cc-notif-config.ps1 — Claude Code notification config
# Copy this file to ~/.claude/hooks/cc-notif-config.ps1 and edit.

# Notification title (string)
$NotifTitle = "Claude Code"

# Notification body. Use {0} for session name.
$NotifMessage = "Session '{0}' done!"

# Full path to sound file (.mp3 or .wav). Leave empty to disable.
$SoundPath = ""

# Seconds to let the sound play before closing.
$SoundDuration = 3
