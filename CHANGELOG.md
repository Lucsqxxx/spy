# Changelog

## Reworked (2026-08)

### Structure
- New clean folder layout (`src/core`, `src/ui`, `src/generation`, `src/config`, `src/utils`)
- Single entry point: `Main.luau`
- Roblox-Parser moved under `vendor/`
- Font asset placed in `assets/`

### Loading
- Local-first module loading (tries `readfile` before `HttpGet`)
- Configurable `RepoUrl` via loadstring argument
- Clearer error messages when modules fail to load
- Removed dual/conflicting host URLs from the main entry

### Config & Docs
- Proper `README.md` with usage, structure, and compatibility notes
- Cleaned `Config.lua` (better variable name defaults, comments)
- Removed informal / emotional comments from core files
- Added this changelog

### Behavior
- Same core features retained (hooks, logging, generation, UI, actors)
- Executor blacklist and config overwrites preserved
- Optional function-patches prompt kept

### Known limitations
- Full offline bundle (single file) not yet generated
- ReGui and Ui modules are largely original (large surface area)
- Remote fallback still depends on a reachable `RepoUrl`
