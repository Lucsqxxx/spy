--[[
	Sigma Spy – DIAGNOSTIC (no print dependency)
	Uses warn, notifications, writefile, rconsole, clipboard.
]]

local function Out(msg)
	msg = "[Sigma Spy] " .. tostring(msg)

	pcall(function() warn(msg) end)
	pcall(function() print(msg) end)

	-- Many executors
	pcall(function() rconsoleprint(msg .. "\n") end)
	pcall(function() rconsoleinfo(msg) end)
	pcall(function() rconsolelog(msg) end)

	-- On-screen notification
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Sigma Spy",
			Text = msg,
			Duration = 5,
		})
	end)

	-- Workspace file log
	pcall(function()
		if writefile and appendfile then
			if isfile and isfile("SigmaSpyLog.txt") then
				appendfile("SigmaSpyLog.txt", msg .. "\n")
			else
				writefile("SigmaSpyLog.txt", msg .. "\n")
			end
		elseif writefile then
			writefile("SigmaSpyLog.txt", msg .. "\n")
		end
	end)
end

Out("step 1: script started")

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

Out("step 2: config ok")

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

Out("step 3: fetching Files.lua")
local filesSrc, err = HttpGet(base .. "/src/utils/Files.lua")
if not filesSrc then
	Out("FAILED Files.lua: " .. tostring(err))
	return
end
Out("step 4: Files fetched len=" .. tostring(#filesSrc))

local ok, FilesOrErr = pcall(function()
	return loadstring(filesSrc, "Files")()
end)
if not ok then
	Out("FAILED load Files: " .. tostring(FilesOrErr))
	return
end
Out("step 5: Files module loaded")

Out("step 6: loading core modules (no UI)")
local names = {
	{ "Process", "/src/core/Process.lua" },
	{ "Hook", "/src/core/Hook.lua" },
	{ "Communication", "/src/core/Communication.lua" },
	{ "Flags", "/src/utils/Flags.lua" },
	{ "Generation", "/src/generation/Generation.lua" },
}

for _, info in names do
	local name, path = info[1], info[2]
	Out("fetch " .. name)
	local src, e = HttpGet(base .. path)
	if not src then
		Out("FAIL fetch " .. name .. ": " .. tostring(e))
	else
		local lok, mod = pcall(function()
			return loadstring(src, name)()
		end)
		if not lok then
			Out("FAIL run " .. name .. ": " .. tostring(mod))
		else
			Out("ok " .. name)
		end
	end
end

Out("step 7: DIAGNOSTIC COMPLETE (no UI/hooks)")
Out("If Roblox stayed open, core is fine. Crash was likely UI/ReGui/hooks.")

pcall(function()
	if setclipboard then
		setclipboard("Sigma Spy diagnostic completed OK")
	end
end)
