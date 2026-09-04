# Troubleshooting

## No notification at all

**Restart Claude Code.** `settings.json` is read at startup.

**Check the hooks are registered:**

```powershell
(Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw | ConvertFrom-Json).hooks |
  ConvertTo-Json -Depth 10
```

You should see both a `Stop` and a `Notification` entry pointing at
`cc-notif.ps1`. If not, re-run `.\install.ps1`.

**Test the script directly:**

```powershell
'{"session_id":"test1234"}' | powershell -NoProfile -File "$env:USERPROFILE\.claude\hooks\cc-notif.ps1" -HookEvent Stop
```

A toast should appear. If this works but the hook does not, the problem is in
`settings.json`, not the script.

## Toast never appears, but no error

Windows may be suppressing it:

- **Focus assist / Do Not Disturb** — turn it off
- Settings → System → Notifications — make sure notifications are on
- Some Windows builds hide toasts from unregistered app IDs; the script falls
  back to a balloon tip automatically when the toast API is unavailable, but
  not when Windows silently drops a successful toast

## No sound

Check, in order:

1. `sound` in your config points at a file that exists
2. The extension is `.mp3`, `.wav`, or `.wma` — others are ignored
3. `soundDuration` is greater than `0`
4. The path uses doubled backslashes if you edited the JSON by hand

Run `.\config.ps1` and use `b` to browse — it validates the file before saving.

For the "needs input" notification specifically: if `askSound` is empty, `sound`
is used. If both are empty, it is silent by design.

## Sound is cut off

`soundDuration` is a hard stop. Raise it to at least the length of your file.

## "Running scripts is disabled on this system"

PowerShell's execution policy is blocking the script. Either run it once with a
bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Or allow local scripts for your user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## The file picker does not appear

It may have opened behind your terminal window — check the taskbar. The script
sets the dialog topmost, but some terminal setups still steal focus.

If it never opens, type the full path instead.

## Session name is wrong or shows 8 random characters

The script reads the session name from the transcript in
`%USERPROFILE%\.claude\projects\`. It falls back to the session ID prefix when:

- The transcript has not been written yet — common on a very short first session
- The session has no `/rename` title and no recorded `cwd`

Give the session a name with `/rename`, and it will show up next time.

## "Needs input" fires more often than expected

The `Notification` hook fires whenever Claude Code asks for input or permission
— including permission prompts, not just questions. To keep only the "done"
notification, remove the `Notification` entry from `settings.json` and restart.

## Upgraded, but the new notification never fires

Your existing config predates `askMessage` / `askSound`. That is fine —
defaults apply. But if the `Notification` hook is missing from `settings.json`,
re-run `.\install.ps1`; it appends what is missing without disturbing the rest.
