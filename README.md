# wsrun_cli

**Run your VS Code workspace launch configs from any terminal.**

A Flutter-first TUI that reads any `.code-workspace` file, lists all `launch.configurations` as a navigable picker, and lets you run, hot-reload, restart, attach, and open DevTools — without leaving the terminal.

Works in any terminal: Zed, iTerm, VS Code integrated terminal, CI pipelines.

- **Language:** Pure Dart (no Flutter dependency)
- **Platforms:** macOS, Linux, Windows
- **Dart SDK:** ≥ 3.0

---

## Install

```bash
dart pub global activate wsrun_cli
```

Add to PATH once (if not already):

```bash
# add to ~/.zshrc or ~/.bashrc
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

---

## Quick Start

```bash
cd your-monorepo/
wsrun
```

That's it. `wsrun` finds the nearest `.code-workspace` file and opens the interactive TUI picker.

---

## CLI Commands

```bash
wsrun                                         # interactive TUI picker (default)
wsrun list                                    # print all launch configs as a table
wsrun run "app_alpha STG"                     # run by config name
wsrun run --index 0                           # run by index
wsrun attach                                  # interactive attach picker
wsrun info                                    # show parsed workspace summary
wsrun --workspace path/to.code-workspace      # explicit workspace file path
```

---

## TUI Screens

### Picker (default)

```
┌─ wsrun_cli ──────────────────────────────────────────────┐
│  📂  my-app.code-workspace                   11 configs  │
├──────────────────────────────────────────────────────────┤
│  🔍  type to filter...                                   │
├──────────────────────────────────────────────────────────┤
│  ❯ 🇺🇸🟢🧪  app_alpha STG                              │
│    🇺🇸🟢🚀  app_alpha PROD                              │
│    🇬🇧🟢🧪  app_beta STG                               │
│    🇬🇧🟢🚀  app_beta PROD                              │
│    🇩🇪🔵🧪  app_gamma STG                              │
│    🇩🇪🔵🚀  app_gamma PROD                             │
│    👨🏼‍🎨       widgetbook                                  │
├──────────────────────────────────────────────────────────┤
│  ↑↓ navigate   / filter   ENTER run   A attach   Q quit  │
└──────────────────────────────────────────────────────────┘
```

### Running App

```
┌─ 🇺🇸🟢🧪 app_alpha STG ─────────────────── ● RUNNING ───────┐
│  flutter run lib/main.dart --flavor dev                  │
├──────────────────────────────────────────────────────────┤
│  ▸ Launching on iPhone 15 Pro (iOS 17.4)...              │
│  ▸ Flutter run key commands.                             │
│  ▸ 🔥 To hot reload press "r".                           │
│  ▸ 💻 Flutter DevTools: http://127.0.0.1:9100?uri=...    │
├──────────────────────────────────────────────────────────┤
│  r reload   R restart   d DevTools   s screenshot   Q ←  │
└──────────────────────────────────────────────────────────┘
```

---

## Key Bindings (Running App)

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `d` | Open DevTools in browser |
| `s` | Screenshot |
| `p` | Performance overlay |
| `w` | Open web app in browser |
| `q` | Stop app + back to picker |
| `Q` | Force kill + back to picker |

---

## Workspace Parsing

- Finds `.code-workspace` in the current directory (or from `--workspace` flag)
- If multiple `.code-workspace` files exist, prompts to choose
- Parses JSONC (JSON with `//` comments — same as VS Code)
- Resolves `${workspaceFolder:NAME}` variables to absolute paths

Example resolution:
```json
"folders": [{ "name": "App Alpha", "path": "apps/app_alpha" }]

"cwd": "${workspaceFolder:App Alpha}"
→ /absolute/path/to/monorepo/apps/app_alpha
```

---

## Roadmap

| Version | Scope |
|---------|-------|
| **0.1.0** | TUI picker, `flutter run`, hot reload/restart, stop, return to picker |
| **0.2.0** | DevTools URL detection, web app URL detection |
| **0.3.0** | Attach mode — scan running Flutter processes and attach |
| **0.4.0** | Multi-app — run multiple configs simultaneously |
| **1.0.0** | Stable public API, verified pub.dev publisher |

---

## Install from Source

```bash
# from GitHub
dart pub global activate --source git https://github.com/soycodigorafa/wsrun_cli

# local development
dart pub global activate --source path ./wsrun_cli
```

---

## License

MIT — see [LICENSE](LICENSE).
