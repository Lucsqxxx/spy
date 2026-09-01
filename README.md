# Wyvern Spy

remote spy for roblox by lucsqx

basically watches remotes (RemoteEvent / RemoteFunction), shows the args, and can spit out scripts so you can call them again.

## how to run

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/spy/main/Main.luau"))()
```

thats it. paste it in your executor and go.

## what it does

- logs remotes when they fire / get invoked
- groups them so the same remote doesnt spam the list forever
- if the same args come through again it just bumps the count (like `×3`)
- if the args change you get a new row
- sidebar search so you can find stuff
- editor tab to build / copy scripts
- options for pause, log limits, keybinds, etc
- edit return spoofs if you want

ui is built with **WyvernUI** (our own thing, no random gui library downloads)

## what your executor needs

required:
- `hookmetamethod`
- `getnamecallmethod`
- `HttpGet`
- `loadstring`

nice to have:
- `getcustomasset` (logo / font)
- `writefile` / `readfile` / `makefolder` (saving spoofs + cache)
- `cloneref`, `newcclosure`, `checkcaller` (hooks behave better)

if something important is missing it should just tell you instead of dying randomly.

## folders

```
Main.luau          ← load this
src/               ← actual code
  core/            hooks + processing
  ui/              ui + WyvernUI
  generation/      script building
assets/            logo + font
dist/Parser.luau   arg formatting
templates/         optional config overrides
```

## in-app options (quick)

| thing | what it does |
|-------|--------------|
| Paused | stop logging |
| Logs per remote | how many unique arg rows to keep |
| Highlight new logs | flash new stuff |
| Log receives | also log incoming |
| UI Visible | hide / show the window |
| Keybinds Enabled | keybinds on/off |

## script templates

Call, Minimal, Edit & Repeat, Spam, Undo Spam, Block, Repeat — pick one from the editor when you have a remote selected.

## heads up

some games hate hooks and will kick you. thats on them, not really a "spy bug".

also always use the loadstring above so you get whatever is on `main` right now.

## license

MIT — see LICENSE. made by lucsqx (2026)
