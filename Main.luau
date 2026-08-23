--[[
	Sigma Spy – MINIMAL DIAGNOSTIC BOOT
	No UI, no hooks, no ReGui. Only prints steps to find the crash point.
]]

print("[Sigma Spy] step 1: script started")

local Configuration = {
	RepoUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main",
	ParserUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main/dist/Parser.luau",
	NoActors = true,
	SafeMode = true,
	PreferLocal = false,
	FolderName = "Sigma Spy",
	Directory = "Sigma Spy",
	UseWorkspace = false,
}

local Parameters = { ... }
if typeof(Parameters[1]) == "table" then
	for k, v in Parameters[1] do
		Configuration[k] = v
	end
end

print("[Sigma Spy] step 2: config ok")

local function HttpGet(url)
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		return nil, tostring(res)
	end
	return res
end

local base = Configuration.RepoUrl:gsub("/+$", "")

print("[Sigma Spy] step 3: fetching Files.lua")
local filesSrc, err = HttpGet(base .. "/src/utils/Files.lua")
if not filesSrc then
	warn("[Sigma Spy] FAILED Files.lua:", err)
	return
end
print("[Sigma Spy] step 4: Files.lua fetched, len=" .. #filesSrc)

local ok, Files = pcall(function()
	return loadstring(filesSrc, "Files")()
end)
if not ok then
	warn("[Sigma Spy] FAILED load Files:", Files)
	return
end
print("[Sigma Spy] step 5: Files module loaded")

print("[Sigma Spy] step 6: fetch core modules (no UI)")
local names = {
	{ "Process", "/src/core/Process.lua" },
	{ "Hook", "/src/core/Hook.lua" },
	{ "Communication", "/src/core/Communication.lua" },
	{ "Flags", "/src/utils/Flags.lua" },
	{ "Generation", "/src/generation/Generation.lua" },
}

for _, info in names do
	local name, path = info[1], info[2]
	print("[Sigma Spy] fetching " .. name)
	local src, e = HttpGet(base .. path)
	if not src then
		warn("[Sigma Spy] FAILED fetch " .. name .. ":", e)
	else
		local lok, mod = pcall(function()
			return loadstring(src, name)()
		end)
		if not lok then
			warn("[Sigma Spy] FAILED compile/run " .. name .. ":", mod)
		else
			print("[Sigma Spy] ok " .. name)
		end
	end
end

print("[Sigma Spy] step 7: skip UI / ReGui / hooks (diagnostic)")
print("[Sigma Spy] DIAGNOSTIC COMPLETE – if you see this, core modules are fine")
print("[Sigma Spy] Crash was likely ReGui/UI. Report which step number was last printed.")
