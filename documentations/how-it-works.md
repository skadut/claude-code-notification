# How it works

## Hook events

`install.ps1` registers one script, `cc-notif.ps1`, against two Claude Code hook
events in `%USERPROFILE%\.claude\settings.json`:

| Event | Fires when | Flag passed |
|---|---|---|
| `Stop` | A session finishes responding | `-HookEvent Stop` |
| `Notification` | Claude asks for input or permission | `-HookEvent Notification` |

Both entries run with `async = true`, so a slow sound never blocks Claude Code.

The registered command looks like:

```
& "$env:USERPROFILE\.claude\hooks\cc-notif.ps1" -HookEvent Stop
```

## What the script does

1. Reads `cc-notif-config.json` from its own directory. Missing or malformed
   config is not fatal — defaults apply.
2. Picks the message and sound for the event. `Notification` uses `askMessage`
   and `askSound`, falling back to `sound` when `askSound` is empty.
3. Reads the hook payload from stdin as JSON, taking `session_id` and, for
   `Notification`, Claude's own `message` text.
4. Resolves a session name (below).
5. Shows a toast, then plays the sound.

## Session name resolution

Claude Code passes only a session ID, so the script looks up
`%USERPROFILE%\.claude\projects\**\<session_id>.jsonl` and tries, in order:

1. **Custom title** — the `customTitle` set by `/rename`
2. **Working directory** — leaf folder name of the session's `cwd`
3. **Session ID prefix** — first 8 characters
4. `unknown`, if there is no session ID at all

## Notification body

For `Stop`, the body is `message` with `{0}` replaced by the session name.

For `Notification`, if Claude supplied its own text, that is used instead —
prefixed with the session name, e.g.
`my-project: Claude needs your permission to use Bash`.
Claude's text says *what* is being asked, which the template cannot. When no
text is supplied, `askMessage` is used.

## Toast

Uses the WinRT `Windows.UI.Notifications` toast API with a `ToastGeneric`
two-line binding. Text is XML-escaped, so quotes and `&` in your message are
safe.

If WinRT is unavailable, it falls back to a legacy `NotifyIcon` balloon tip.

## Sound

Played through `winmm.dll`'s `mciSendString` — no extra dependencies, and it
handles MP3 as well as WAV. The script opens the file under a PID-scoped alias,
plays it, sleeps `soundDuration` seconds, then closes the alias.

`soundDuration` is a hard stop, not a length: a 10-second file with
`soundDuration: 3` plays the first 3 seconds.
