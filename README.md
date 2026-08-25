# Wyvern Spy

Remote spy for Roblox.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucsqxxx/spy/main/Main.luau"))()
```

## Requirements

- Executor with `hookmetamethod` / `HttpGet` / `loadstring`
- **Real** and similar: uses ReGuiCompat (no ReGui prefab asset)

## Options (high level)

| Option | Meaning |
|--------|---------|
| Logs per remote | Max entries kept per remote section |
| Highlight new logs | Flash new list rows |
| Log receives | Client events |
| Paused | Stop capturing |

## Build templates

| Template | Purpose |
|----------|---------|
| Call / Minimal | Fire once |
| Edit & Repeat | Edit args, then Run |
| Spam | Loop until Undo Spam |
| Undo Spam | Stops spam (`_WVS_SPAM = false`) |
| Block / Repeat | Block or fire N times |

## License

MIT — see [LICENSE](LICENSE).
