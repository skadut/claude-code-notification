# Configuration

Config lives at `%USERPROFILE%\.claude\hooks\cc-notif-config.json`.

Edit it interactively — recommended:

```powershell
.\config.ps1
```

Or open it directly:

```powershell
notepad "$env:USERPROFILE\.claude\hooks\cc-notif-config.json"
```

## Keys

| Key | Default | What it does |
|---|---|---|
| `title` | `Claude Code` | Toast title, both events |
| `message` | `Session '{0}' done!` | Shown when a session finishes |
| `askMessage` | `Session '{0}' needs your input` | Shown when Claude asks for input |
| `sound` | `""` | Audio file for "done". Empty = silent |
| `askSound` | `""` | Audio file for "needs input". Empty = reuse `sound` |
| `soundDuration` | `3` | Seconds to let the sound play before stopping it |
| `locale` | `en` | `en` or `id`. Only applies while messages are at their defaults |

`{0}` is replaced with the session name.

Supported audio: `.mp3`, `.wav`, `.wma`.

## Example

```json
{
  "title": "Claude Code",
  "message": "Session '{0}' done!",
  "askMessage": "Session '{0}' needs your input",
  "sound": "C:\Users\me\sounds\done.mp3",
  "askSound": "C:\Users\me\sounds\ping.wav",
  "soundDuration": 3,
  "locale": "en"
}
```

Backslashes in JSON paths must be doubled. `config.ps1` handles this for you.

## Picking a sound

At either sound prompt in `config.ps1`:

| Input | Result |
|---|---|
| `b` | Opens the Windows file picker, filtered to audio files |
| a path | Used directly, if it exists and the format is supported |
| `none` | Clears the sound |
| Enter | Keeps the current value |

## Locales

`locale` swaps the built-in default text. It is ignored once you set your own
`message` / `askMessage` — your text always wins.

| Locale | Done | Needs input |
|---|---|---|
| `en` | `Session '{0}' done!` | `Session '{0}' needs your input` |
| `id` | `Sesi '{0}' selesai!` | `Sesi '{0}' butuh input kamu` |
