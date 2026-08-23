--[[
	Sigma Spy (Reworked) – stable boot
	Hooks OFF by default. UI loaded with heavy error protection.
]]

local function Out(...)
	local parts = {...}
	for i = 1, #parts do parts[i] = tostring(parts[i]) end
	local msg = "[Sigma Spy] " .. table.concat(parts, " ")
	pcall(warn, msg)
	pcall(print, msg)
	pcall(function()
		if writefile then
			local line = msg .. "\n"
			if appendfile and isfile and isfile("SigmaSpyLog.txt") then
				appendfile("SigmaSpyLog.txt", line)
			else
				writefile("SigmaSpyLog.txt", line)
			end
		end
	end)
end

Out("boot start")

local Configuration = {
	UseWorkspace = false,
	NoActors = true,
	SafeMode = true, -- true = no remote hooks (UI only)
	PreferLocal = false,
	FolderName = "Sigma Spy",
	Directory = "Sigma Spy",
	RepoUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main",
	ParserUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main/dist/Parser.luau",
}

local Parameters = { ... }
if typeof(Parameters[1]) == "table" then
	for k, v in Parameters[1] do
		Configuration[k] = v
	end
end

local Services = setmetatable({}, {
	__index = function(_, Name)
		local S = game:GetService(Name)
		if cloneref then
			return cloneref(S)
		end
		return S
	end,
})

local function HttpGet(Url)
	local ok, res = pcall(function()
		return game:HttpGet(Url)
	end)
	if ok and typeof(res) == "string" and #res > 0 then
		return res
	end
	return nil
end

local Base = Configuration.RepoUrl:gsub("/+$", "")

Out("loading Files")
local FilesSource = HttpGet(Base .. "/src/utils/Files.lua")
if not FilesSource then
	Out("FATAL: cannot fetch Files.lua")
	return
end

local Files = loadstring(FilesSource, "Files")()
Files:PushConfig(Configuration)
Files:Init({ Services = Services })
Out("Files ok")

local ModuleMap = {
	Process = "/src/core/Process.lua",
	Hook = "/src/core/Hook.lua",
	Flags = "/src/utils/Flags.lua",
	Generation = "/src/generation/Generation.lua",
	Communication = "/src/core/Communication.lua",
	Ui = "/src/ui/Ui.lua",
}

local Scripts = {
	Configuration = Configuration,
	Files = Files,
	Config = Files:GetModule(Configuration.FolderName .. "/Config", "Config"),
	ReturnSpoofs = Files:GetModule(Configuration.FolderName .. "/Return spoofs", "Return Spoofs"),
}

for Name, Path in ModuleMap do
	Out("loading", Name)
	local src = HttpGet(Base .. Path)
	if not src then
		Out("MISSING", Name)
	else
		Scripts[Name] = src
	end
end

Out("compiling libraries")
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

if not (Process and Hook and Ui and Generation and Communication) then
	Out("FATAL: critical module missing")
	return
end
Out("libraries ok")

-- Skip custom font (getcustomasset can crash some clients)
Out("init modules")
pcall(function()
	Process:CheckConfig(Config)
end)

-- LoadModules calls Ui:Init which loads ReGui — protect this
local initOk, initErr = pcall(function()
	Files:LoadModules(Modules, {
		Modules = Modules,
		Services = Services,
		Configuration = Configuration,
	})
end)
if not initOk then
	Out("LoadModules error:", initErr)
	Out("Trying Ui init alone...")
	local uOk, uErr = pcall(function()
		Ui:Init({
			Modules = Modules,
			Services = Services,
			Configuration = Configuration,
		})
	end)
	if not uOk then
		Out("FATAL Ui:Init:", uErr)
		Out("ReGui/UI cannot load on this executor. Spy hooks-only mode not available without UI rewrite.")
		return
	end
end
Out("modules inited")

Out("creating window")
local Window
local wOk, wErr = pcall(function()
	Window = Ui:CreateMainWindow()
end)
if not wOk then
	Out("FATAL CreateMainWindow:", wErr)
	return
end
Out("window ok")

local Supported = true
pcall(function()
	Supported = Process:CheckIsSupported()
end)
if not Supported then
	Out("executor not supported")
	pcall(function() Window:Close() end)
	return
end

Out("communication")
local ChannelId, Event
local cOk, cErr = pcall(function()
	ChannelId, Event = Communication:CreateChannel()
	Communication:AddCommCallback("QueueLog", function(...)
		Ui:QueueLog(...)
	end)
	Communication:AddCommCallback("Print", function(...)
		Ui:ConsoleLog(...)
	end)
end)
if not cOk then
	Out("comm error:", cErr)
end

pcall(function()
	local LP = Services.Players.LocalPlayer
	Generation:SetSwapsCallback(function(self)
		self:AddSwap(LP, { String = "LocalPlayer" })
		if LP.Character then
			self:AddSwap(LP.Character, { String = "Character", NextParent = LP })
		end
	end)
end)

Out("window content")
pcall(function()
	Ui:CreateWindowContent(Window)
	if Event then
		Ui:SetCommChannel(Event)
		Ui:BeginLogService()
	end
end)

-- Hooks only if SafeMode is false
if Configuration.SafeMode then
	Out("SafeMode ON — hooks disabled (UI only)")
else
	Out("enabling hooks")
	pcall(function()
		Hook:LoadHooks("", ChannelId)
	end)
	pcall(function()
		if Event then
			Event:Fire("BeginHooks", { PatchFunctions = false })
		end
	end)
end

Out("LOADED SUCCESSFULLY")
