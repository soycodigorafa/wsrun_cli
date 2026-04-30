# wsrun_cli

**pub.dev public package** | CLI command: `wsrun`  
**Install:** `dart pub global activate wsrun_cli`  
**Tagline:** "Run your VS Code workspace from any terminal"

---

## Overview

A universal terminal tool for developers working in VS Code multi-root workspaces. Reads any
`.code-workspace` file, presents all `launch.configurations` as a navigable TUI list, and lets
you run, hot-reload, debug, attach, and open DevTools for Flutter apps — all from the terminal.

Works in any terminal: Zed, iTerm, VS Code integrated terminal, CI pipelines.

**Language:** Pure Dart (no Flutter dependency)  
**Platforms:** macOS, Linux, Windows  
**Dart SDK:** ≥ 3.0

---

## Install & Quick Start

```bash
# install once
dart pub global activate wsrun_cli

# add to PATH once (if not already)
export PATH="$PATH":"$HOME/.pub-cache/bin"   # add to ~/.zshrc or ~/.bashrc

# use anywhere
cd your-monorepo/
wsrun
```

---

## CLI Commands

```bash
wsrun                                         # interactive TUI (default)
wsrun list                                    # print all launch configs as a table
wsrun run "app_alpha STG"                      # run by name, no picker
wsrun run --index 0                           # run by index
wsrun attach                                  # interactive attach picker
wsrun info                                    # show parsed workspace summary
wsrun --workspace path/to.code-workspace      # explicit workspace file path
```

---

## User Experience

### Picker Screen (default view)

```
┌─ wsrun_cli ──────────────────────────────────────────────┐
│  📂  dc-wl-groceries-app.code-workspace          11 configs     │
├─────────────────────────────────────────────────────────────────┤
│  🔍  type to filter...                                          │
├─────────────────────────────────────────────────────────────────┤
│  ❯ 🇺🇸🟢🧪  app_alpha STG                                      │
│    🇺🇸🟢🚀  app_alpha PROD                                      │
│    🇬🇧🟢🧪  app_beta STG                                        │
│    🇬🇧🟢🚀  app_beta PROD                                       │
│    🇬🇧🔴🧪  app_delta STG                                       │
│    🇬🇧🔴🚀  app_delta PROD                                      │
│    🇩🇪🔵🧪  app_gamma STG                                       │
│    🇩🇪🔵🚀  app_gamma PROD                                      │
│    🇫🇷🟢🧪  app_epsilon STG                                     │
│    🇫🇷🟢🚀  app_epsilon PROD                                    │
│    👨🏼‍🎨       widgetbook                                          │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate   / filter   ENTER run   A attach   Q quit        │
└─────────────────────────────────────────────────────────────────┘
```

### Running App Screen

After selecting a config and pressing ENTER:

```
┌─ 🇺🇸🟢🧪 app_alpha STG ─────────────────── ● RUNNING ──────────┐
│  flutter run lib/main.dart --flavor dev --dart-define-from-file  │
│  env/development.env.json                                        │
├─────────────────────────────────────────────────────────────────┤
│  ▸ Launching on iPhone 15 Pro (iOS 17.4)...                     │
│  ▸ Syncing files to device...                                    │
│  ▸ Flutter run key commands.                                     │
│  ▸ 🔥 To hot reload press "r".                                  │
│  ▸ 💻 Flutter DevTools: http://127.0.0.1:9100?uri=...           │
├─────────────────────────────────────────────────────────────────┤
│  r reload   R restart   d DevTools   s screenshot   Q stop+back │
└─────────────────────────────────────────────────────────────────┘
```

### Attach Screen (`wsrun attach`)

```
┌─ wsrun_cli — attach ─────────────────────────────────────┐
│  Scanning for running Flutter processes...                       │
├─────────────────────────────────────────────────────────────────┤
│  ❯ app_alpha  │  iPhone 15 Pro  │  vm://127.0.0.1:12345/ws      │
│    app_beta   │  Android Pixel  │  vm://127.0.0.1:12346/ws      │
├─────────────────────────────────────────────────────────────────┤
│  ↑↓ navigate   ENTER attach   Q quit                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Bindings (Running App Screen)

| Key | Action | Implementation |
|-----|--------|----------------|
| `r` | Hot reload | forwards `r\n` to flutter process stdin |
| `R` | Hot restart | forwards `R\n` to flutter process stdin |
| `d` | Open DevTools | parses DevTools URL from output, opens in browser |
| `s` | Screenshot | forwards `s\n` to flutter process stdin |
| `p` | Performance overlay | forwards `p\n` to flutter process stdin |
| `w` | Open web app | parses `http://localhost:PORT` from output, opens browser |
| `q` | Stop app + back to picker | forwards `q\n`, awaits process exit, returns to picker |
| `Q` | Force kill + back | SIGTERM process tree, returns to picker |

---

## Workspace Parsing

### What it reads

- Finds `.code-workspace` in the current directory (or path from `--workspace` flag)
- If multiple `.code-workspace` files exist, prompts to choose
- Parses JSONC (JSON with comments — VS Code allows `//` comments in the file)
- Extracts `folders` array and `launch.configurations` array

### Variable resolution

`${workspaceFolder:NAME}` is resolved by:
1. Finding the folder entry in `folders` where `name` matches `NAME`
2. Using its `path` value, joined with the workspace file's directory

Example:
```json
"folders": [{ "name": "🇺🇸 🟢 App Alpha", "path": "apps/app_alpha" }]

"cwd": "${workspaceFolder:🇺🇸 🟢 App Alpha}"
→ resolves to: /absolute/path/to/monorepo/apps/app_alpha
```

### Flutter command translation

| `.code-workspace` field | Flutter CLI |
|------------------------|-------------|
| `"program": "lib/main.dart"` | positional arg `lib/main.dart` |
| `"args": ["--flavor", "dev"]` | `--flavor dev` |
| `"args": ["--dart-define-from-file", "env/dev.json"]` | `--dart-define-from-file env/dev.json` |
| `"cwd"` (resolved) | working directory for process spawn |

---

## Project Structure

```
wsrun_cli/
├── bin/
│   └── wsrun.dart                    # entry point, argument parsing (package:args)
├── lib/
│   ├── wsrun_cli.dart       # public barrel file
│   ├── core/                       # zero UI dependencies — reusable by any future skin
│   │   ├── models/
│   │   │   ├── launch_config.dart         # name, cwd, program, args, type
│   │   │   ├── workspace_folder.dart      # name, path
│   │   │   └── workspace_file.dart        # parsed file aggregate
│   │   ├── workspace_parser.dart          # JSONC parser + deserializer
│   │   ├── folder_resolver.dart           # ${workspaceFolder:X} → absolute path
│   │   ├── flutter_process.dart           # spawn process, stream stdout, forward stdin
│   │   └── devtools_detector.dart         # regex to extract DevTools + VM service URLs
│   └── tui/                        # current presentation skin
│       ├── tui_app.dart                   # top-level state machine
│       ├── screens/
│       │   ├── picker_screen.dart         # launch config list + filter
│       │   ├── running_screen.dart        # live output + controls
│       │   └── attach_screen.dart         # flutter attach picker
│       ├── components/
│       │   ├── box.dart                   # ANSI border drawing
│       │   ├── list.dart                  # scrollable list with highlight
│       │   ├── log_tail.dart              # scrolling stdout view
│       │   └── status_bar.dart            # bottom key hint bar
│       └── input/
│           ├── raw_terminal.dart          # stdin raw mode on/off
│           └── key_events.dart            # key event types (arrows, enter, chars)
├── test/
│   ├── core/
│   │   ├── workspace_parser_test.dart
│   │   ├── folder_resolver_test.dart
│   │   └── flutter_process_test.dart
│   └── fixtures/
│       └── sample.code-workspace          # test fixture
└── pubspec.yaml
```

---

## pubspec.yaml

```yaml
name: wsrun_cli
description: Run VS Code workspace launch configurations from any terminal. Flutter-first TUI.
version: 0.1.0
homepage: https://github.com/YOUR_ORG/wsrun_cli

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  args: ^2.4.0           # CLI argument parsing
  path: ^1.9.0           # cross-platform path joining
  dart_console: ^1.1.0   # cross-platform raw terminal + ANSI colors
  process_run: ^0.14.0   # spawn and manage child processes

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0

executables:
  wsrun: wsrun               # dart pub global activate → `wsrun` command
```

---

## Architecture Principle

`core/` has **no dependency on `tui/`**. The presentation layer is a replaceable skin.

```
Today                         Future options
─────                         ─────────────
tui/  ──────┐                 zed_extension/  ──┐
            │                 flutter_desktop/  ─┤──► core/  (unchanged)
            └──► core/        web_server/  ──────┘
```

When Zed ships a custom extension UI API — or when a Flutter desktop wrapper is wanted —
`core/` is imported directly with zero changes to the business logic.

---

## Roadmap

| Version | Scope |
|---------|-------|
| **0.1.0** | Parse workspace, TUI picker with filter, `flutter run`, hot reload/restart, stop, return to picker |
| **0.2.0** | DevTools URL detection + open in browser, web app URL detection + open in browser |
| **0.3.0** | Attach mode — scan for running Flutter processes, pick and attach |
| **0.4.0** | Multi-app — run multiple configs simultaneously, stacked status view |
| **1.0.0** | Stable public API, full README, pub.dev verified publisher |
| **future** | Zed extension wrapper using `core/`; Flutter desktop launcher using `core/` |

---

## Distribution

```bash
# from pub.dev (once published)
dart pub global activate wsrun_cli

# from git repo (private/pre-release)
dart pub global activate --source git https://github.com/YOUR_ORG/wsrun_cli

# from monorepo subdirectory
dart pub global activate --source git https://github.com/YOUR_ORG/monorepo --git-path tools/wsrun_cli

# local development
dart pub global activate --source path ./tools/wsrun_cli
```

---

## Notes

- The tool is **not tied to this monorepo**. It reads any `.code-workspace` file it finds in `cwd`.
- Supports all `"type": "dart"` launch configurations, not just Flutter.
- Commented-out configurations in the workspace file (`//` or `/* */`) are ignored — same behavior as VS Code.
- The `name` field is displayed verbatim, including emojis.
