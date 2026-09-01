# Wyvern Spy

A lightweight **Roblox remote spy** for inspecting `RemoteEvent` / `RemoteFunction` traffic, viewing arguments, and generating call scripts.

**Author:** lucsqx

---

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/spy/main/Main.luau"))()
```

---

## Features

- Capture outgoing and incoming remote traffic
- Group logs per remote with type icons
- Deduplicate identical argument sets (`×N` hit counts)
- Separate rows when arguments change
- Script editor with build templates (Call, Minimal, Spam, Block, …)
- Search remotes in the sidebar
- Return spoofs editor
- Options for pause, log limits, keybinds, UI visibility
- Built-in UI toolkit (**WyvernUI**) — pure Instances, no external GUI library assets

---

## Supported executors

Works on executors that provide:

| API | Purpose |
|-----|---------|
| `hookmetamethod` | Intercept remote calls |
| `getnamecallmethod` | Identify the called method |
| `HttpGet` | Fetch modules from this repo |
| `loadstring` | Compile loaded modules |

**Optional** (better experience):

| API | Purpose |
|-----|---------|
| `getcustomasset` | Logo / font assets |
| `writefile` / `makefolder` / `readfile` | Cache assets and spoofs |
| `cloneref` | Safer instance references |
| `newcclosure` / `checkcaller` | Hook stability |

If a required API is missing, Wyvern Spy will fail early with a clear message instead of crashing silently.

---

## Project layout

```
Main.luau              Entry point (load this)
assets/
  wyvern_logo.png      Title-bar logo
  ProggyClean.ttf      Optional code font
dist/
  Parser.luau          Value parser for script generation
src/
  core/                Hook, Process, Communication
  ui/                  Ui + WyvernUI toolkit
  generation/          Script generation
  config/              Defaults + return spoofs
  utils/               Files, Flags
templates/             Optional user config overrides
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
| Undo Spam | Stop spam loops |
| Block | Block the remote |
| Repeat | Fire N times |

---

## Notes

- Some games detect metamethod hooks and may kick after traffic is logged. That is game-side behavior.
- Prefer the loadstring above so you always pull the latest `main` branch.

---

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 lucsqx.
