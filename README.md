# wsrun_cli

**Run your VS Code workspace launch configs from any terminal.**

A Flutter-first TUI that reads any `.code-workspace` file, lists all `launch.configurations` as a navigable picker, and lets you run, hot-reload, restart, connect, and open DevTools — without leaving the terminal.

Built with [nocterm](https://pub.dev/packages/nocterm) — Flutter-like components, reactive state, auto-scrolling logs.

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

`wsrun` finds the nearest `.code-workspace` file and opens the interactive TUI picker.

Pass an explicit file with `-w`:

```bash
wsrun -w path/to/my.code-workspace
```

To run directly from source using the included sample fixture:

```bash
dart run bin/wsrun_cli.dart -w test/fixtures/sample.code-workspace
```

---

## CLI Commands

```bash
wsrun                                         # interactive TUI picker (default)
wsrun list                                    # print all launch configs as a table
wsrun run "app_alpha STG"                     # run by config name
wsrun run --index 0                           # run by index
wsrun attach                                  # open connect screen for running processes
wsrun info                                    # show parsed workspace summary
wsrun --workspace path/to.code-workspace      # explicit workspace file path
```

---

## TUI Screens

### Picker (default)

```
┌──────────────────────────────────────────────────────────┐
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
│  ↑↓ navigate   / filter   enter run   a connect   q quit │
└──────────────────────────────────────────────────────────┘
```

- **`/`** activates inline filter — type to narrow configs, `Enter`/`Esc` to exit filter
- **`↑↓`** navigates the list
- **`Enter`** runs the selected config
- **`a`** opens the connect screen
- **`q`** quits

### Running App

Log output auto-scrolls to the latest line. Scroll up manually to inspect older output — auto-scroll resumes when you reach the bottom.

```
┌─ app_alpha STG ──────────────────────────── ● RUNNING ───┐
│  ▸ Launching on iPhone 15 Pro (iOS 17.4)...              │
│  ▸ Syncing files to device...                            │
│  ▸ Flutter run key commands.                             │
│  ▸ 🔥 To hot reload press "r".                           │
│  ▸ 💻 Flutter DevTools: http://127.0.0.1:9100?uri=...    │
├──────────────────────────────────────────────────────────┤
│  r reload   R restart   s screenshot   p perf   q stop   │
└──────────────────────────────────────────────────────────┘
```

### Connect Screen (`wsrun attach`)

Scans for running Flutter processes via `flutter attach --list`.

```
┌─ wsrun — connect ────────────────────────────────────────┐
│  ❯ app_alpha  │  iPhone 15 Pro  │  ws://127.0.0.1:52738  │
│    app_beta   │  Android Pixel  │  ws://127.0.0.1:52739  │
├──────────────────────────────────────────────────────────┤
│  ↑↓ navigate   enter connect   q back                    │
└──────────────────────────────────────────────────────────┘
```

---

## Key Bindings (Running App)

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `s` | Screenshot |
| `p` | Performance overlay |
| `q` | Stop app + back to picker |
| `Q` | Force kill + back to picker |

---

## Workspace Parsing

- Finds `.code-workspace` in the current directory (or from `--workspace` flag)
- If multiple `.code-workspace` files exist, prompts to choose
- Parses JSONC (JSON with `//` and `/* */` comments — same as VS Code)
- Resolves `${workspaceFolder:NAME}` variables to absolute paths

Example resolution:
```json
"folders": [{ "name": "App Alpha", "path": "apps/app_alpha" }]

"cwd": "${workspaceFolder:App Alpha}"
→ /absolute/path/to/monorepo/apps/app_alpha
```

---

## Project Structure

```
wsrun_cli/
├── bin/
│   └── wsrun_cli.dart             # entry point, argument parsing
├── lib/
│   ├── wsrun_cli.dart             # public barrel export
│   ├── core/                      # zero UI dependencies
│   │   ├── models/
│   │   │   ├── launch_config.dart
│   │   │   ├── workspace_folder.dart
│   │   │   └── workspace_file.dart
│   │   ├── workspace_parser.dart  # JSONC parser + deserializer
│   │   ├── folder_resolver.dart   # ${workspaceFolder:X} → absolute path
│   │   ├── flutter_process.dart   # spawn process, stream stdout/stderr
│   │   └── devtools_detector.dart # extracts DevTools + VM service URLs
│   └── tui/                       # nocterm UI layer
│       ├── tui_app.dart           # integration bridge: core ↔ TUI
│       ├── models/                # UI-only data contracts (no core imports)
│       │   ├── tui_config.dart
│       │   ├── tui_log_line.dart
│       │   ├── tui_attach_target.dart
│       │   └── tui_process_handle.dart
│       ├── screens/
│       │   ├── app_shell.dart     # root router (picker | running | connect)
│       │   ├── picker_screen.dart # config list + inline filter
│       │   ├── running_screen.dart# live log + key controls
│       │   └── connect_screen.dart# attach target list
│       ├── components/
│       │   ├── config_list.dart   # selectable list with cursor highlight
│       │   ├── log_viewer.dart    # auto-scrolling log tail (AutoScrollController)
│       │   └── status_bar.dart    # bottom key hint bar
│       └── inputs/
│           ├── filter_input.dart  # inline text filter component
│           └── list_controller.dart # cursor + scroll offset state
├── test/
│   ├── core/
│   └── fixtures/
│       └── sample.code-workspace
└── pubspec.yaml
```

---

## Architecture

`core/` has **no dependency on `tui/`**. The TUI layer communicates through callbacks and UI-local model types — it never imports core directly.

```
bin/wsrun_cli.dart
       │
lib/tui/tui_app.dart        ← integration bridge
       ├── core/             ← business logic (workspace parsing, process management)
       └── tui/screens/      ← nocterm components (no core imports)
```

This means `core/` can be reused by a future Zed extension, Flutter desktop launcher, or web UI with zero changes.

---

## Dependencies

```yaml
dependencies:
  args: ^2.4.0        # CLI argument parsing
  path: ^1.9.0        # cross-platform path joining
  process_run: ^0.14.0# spawn and manage child processes
  nocterm: ^0.6.0     # Flutter-like TUI framework
```

---

## Roadmap

| Version | Scope |
|---------|-------|
| **0.1.0** | TUI picker, `flutter run`, hot reload/restart, stop, return to picker |
| **0.2.0** | DevTools URL detection + open in browser, web URL detection |
| **0.3.0** | Connect mode — scan running Flutter processes and attach |
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

