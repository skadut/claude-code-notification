# claude-code-notification

Desktop notification hook for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
Toasts you when a session **finishes** — and when it **needs your input**.

> **Windows only.** Windows 10/11 + PowerShell. macOS and Linux are not supported yet.

- Shows the session name, a custom message, and plays a custom sound
- Separate message + sound for "done" vs "needs input"
- Pick sounds with an Explorer file picker — no path typing

---

## Install

```powershell
git clone https://github.com/skadut/claude-code-notification
cd claude-code-notification
.\install.ps1
.\config.ps1
```

Git Bash / CMD: prefix each script with `powershell -ExecutionPolicy Bypass -File`.

Restart Claude Code. Done.

## Configure

```powershell
.\config.ps1
```

Walks through every setting. At a sound prompt, type `b` to browse, `none` to clear.

## Uninstall

```powershell
.\uninstall.ps1
```

Your other hooks are preserved.

---

## Docs

| | |
|---|---|
| [Configuration](documentations/configuration.md) | Every config key, locales, message templates |
| [How it works](documentations/how-it-works.md) | Hook events, session-name resolution, toast + sound internals |
| [Install details](documentations/install.md) | Per-terminal steps, what gets written where, manual setup |
| [Troubleshooting](documentations/troubleshooting.md) | No toast, no sound, execution policy, upgrading from v1 |

## License

MIT — see [LICENSE](LICENSE).
