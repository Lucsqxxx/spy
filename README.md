# spy

A modern, cleaned-up remote spy for Roblox executors.

Logs RemoteEvents, RemoteFunctions, UnreliableRemoteEvents, and Bindables. Generates ready-to-use scripts (call, spam, repeat, block). Includes a full GUI with syntax-highlighted editor.

Originally based on Sigma Spy by depso. This version focuses on cleaner structure, reliable loading, better documentation, and maintainability.

## Features

- Hook send + receive for:
  - `RemoteEvent` / `UnreliableRemoteEvent`
  - `RemoteFunction`
  - `BindableEvent` / `BindableFunction`
- Real-time log UI with filtering
- Script generation (single call, spam, repeat, block hooks)
- Actor support via communication channels
- Customizable config (colors, variable names, blacklists, themes)
- Value serialization via included Roblox-Parser
- Optional function patches for certain executors

## Project Structure

```
SigmaSpy/
├── Main.luau                 # Single entry point
├── README.md
├── assets/
│   └── ProggyClean.ttf
├── src/
│   ├── config/
│   │   ├── Config.lua
│   │   └── ReturnSpoofs.lua
│   ├── core/
│   │   ├── Communication.lua
│   │   ├── Hook.lua
│   │   └── Process.lua
│   ├── generation/
│   │   └── Generation.lua
│   ├── ui/
│   │   ├── ReGui.lua
│   │   └── Ui.lua
│   └── utils/
│       ├── Files.lua
│       └── Flags.lua
├── templates/                # User-editable copies (created at runtime)
└── vendor/
    └── Roblox-Parser/        # Value → Lua source formatter
```

## Usage

### Quick load (executor)

```lua
loadstring(game:HttpGet("YOUR_RAW_MAIN_URL/Main.luau"))()
```

Or if you host the whole folder:

```lua
-- Prefer loading Main.luau which then pulls the rest from the same base URL
```

### Local / development

Place the entire `SigmaSpy` folder where your executor can read files (or use a file-system compatible executor).  
`Main.luau` will try local modules first when possible.

### Configuration

On first run the tool creates a folder (default name `Sigma Spy`) containing:

- `Config.lua` – main options
- `Return spoofs.lua` – return value overrides

Edit these and rejoin / reload to apply.

Key config options:

| Option | Description |
|--------|-------------|
| `ForceUseCustomComm` | Force custom communication channel |
| `NoReceiveHooking` | Disable receive hooks |
| `BlackListedServices` | Services to ignore (e.g. RobloxReplicatedStorage) |
| `VariableNames` | Random variable name patterns for generated scripts |
| `SyntaxColors` | Editor colors |
| `MethodColors` | Log method colors |
| `ThemeConfig` | UI theme base + text size |

## Executor Compatibility

**Supported** (most modern executors with `hookmetamethod` + `hookfunction` + `newcclosure`):

- Wave, Potassium, SirHurt, and most others that implement the standard API surface

**Not supported / blocked**:

- Xeno
- Solara
- JJSploit

Some executors get automatic config overwrites for better stability.

## How it works (short)

1. `Main.luau` loads modules and creates the UI window.
2. Compatibility checks run (`identifyexecutor`, required functions).
3. A communication channel is created (supports Actors).
4. Hooks are installed on metamethods / functions.
5. Remote traffic is captured, processed, and queued to the UI.
6. User can inspect logs, generate scripts, or block remotes.

## Credits

- Original Sigma Spy concept & large parts of the codebase: depso
- Roblox-Parser: depthso / Depso (GNU GPLv3)
- ReGui UI library: included from original
- Rework / structure / docs: cleaned and reorganized for maintainability

## License

The included Roblox-Parser is under GNU GPLv3.  
The rest of this rework is provided as-is for educational and personal use. Respect Roblox ToS and applicable laws.

## Contributing / Extending

- Core logic lives in `src/core/`
- UI in `src/ui/`
- Script templates & generation in `src/generation/`
- User options in `src/config/`

Feel free to fork and improve.
