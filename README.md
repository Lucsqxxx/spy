# Wyvern Spy

A lightweight **Roblox remote spy** for inspecting `RemoteEvent` / `RemoteFunction` traffic, viewing arguments, and generating call scripts.

**Author:** lucsqx  
**Executor focus:** Real (and similar) — pure Instance UI (`ReGuiCompat`), no ReGui prefab assets.

---

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/spy/main/Main.luau"))()
```

---

## Features

- Capture **outgoing** and **incoming** remote traffic
- Group logs **per remote** with type icons
- **Deduplicate** identical argument sets (`×N` hit counts)
- Separate rows when arguments **change**
- Editor with script templates (Call, Minimal, Spam, Block, …)
- Options: pause, logs-per-remote limit, highlight new, keybinds, UI visible
- Search remotes in the sidebar
- Self-hosted from this repo (no third-party raw mirrors required)

---

## Requirements

Your executor should support:

| API | Used for |
|-----|----------|
| `hookmetamethod` | Remote interception |
| `HttpGet` / `loadstring` | Loading modules |
| `getcustomasset` (optional) | Logo / font assets |
| `writefile` / `makefolder` (optional) | Caching assets |

---

## Project layout

```
Main.luau                 Entry point (load this)
assets/
  wyvern_logo.png         Title-bar logo
  ProggyClean.ttf         Optional code font
dist/
  Parser.luau             Bundled Roblox value parser
src/
  core/                   Hook, Process, Communication
  ui/                     Ui + ReGuiCompat
  generation/             Script generation
  config/                 Defaults + return spoofs
  utils/                  Files, Flags
templates/                Optional user config overrides
```

---

## Options (in-app)

| Option | Description |
|--------|-------------|
| **Paused** | Stop capturing new logs |
| **Logs per remote** | Max unique argument rows kept per remote |
| **Highlight new logs** | Brief highlight on new rows |
| **Log receives** | Log client-side receive events |
| **Ignore nil parents** | Skip remotes with nil parent |
| **UI Visible** | Toggle main window |
| **Keybinds Enabled** | Enable bound keys |

---

## Script templates

| Template | Purpose |
|----------|---------|
| Call | Fire / invoke once with captured args |
| Minimal | Shortest call form |
| Edit & Repeat | Edit args in the editor, then run |
| Spam | Loop until stopped |
| Undo Spam | Sets stop flag for spam loops |
| Block | Block the remote |
| Repeat | Fire N times |

---

## Notes

- Some games detect metamethod hooks and may kick after traffic is logged. That is server-side behavior, not a UI bug.
- Prefer the loadstring above so you always get the latest `main` branch.

---

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 lucsqx.
