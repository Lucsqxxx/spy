if getgenv and getgenv()._WyvernLoaded then return end
if getgenv then getgenv()._WyvernLoaded = true end

local Configuration = {
	UseWorkspace = false,
	NoActors = true,
	SafeMode = false,
	PreferLocal = false,
	FolderName = "Wyvern Spy",
	Directory = "Wyvern Spy",
	RepoUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main",
	ParserUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main/dist/Parser.luau",
}

local Parameters = { ... }
if typeof(Parameters[1]) == "table" then
	for k, v in Parameters[1] do
		Configuration[k] = v
	end
end

local function Out(...)
	local t = { ... }
	for i = 1, #t do t[i] = tostring(t[i]) end
	local msg = "[Wyvern Spy] " .. table.concat(t, " ")
	pcall(warn, msg)
	pcall(print, msg)
end

Out("boot")

local Services = setmetatable({}, {
	__index = function(_, Name)
		local S = game:GetService(Name)
		return cloneref and cloneref(S) or S
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
local CACHE_VER = "20260829h"

Out("loading Files")
local FilesSource = HttpGet(Base .. "/src/utils/Files.lua?v=" .. CACHE_VER)
if not FilesSource then
	Out("FATAL Files")
	return
end
local Files = loadstring(FilesSource, "Files")()
Files:PushConfig(Configuration)
pcall(function()
	Files:Init({ Services = Services })
end)

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
}
pcall(function()
	Scripts.Config = Files:GetModule(Configuration.FolderName .. "/Config", "Config")
	Scripts.ReturnSpoofs = Files:GetModule(Configuration.FolderName .. "/Return spoofs", "Return Spoofs")
end)

for Name, Path in ModuleMap do
	Out("loading", Name)
	local src = HttpGet(Base .. Path .. "?v=" .. CACHE_VER)
	if src then
		Scripts[Name] = src
	else
		Out("missing", Name)
	end
end

Out("loading font")
pcall(function()
	local fontBody = HttpGet(Base .. "/assets/ProggyClean.ttf")
	if fontBody and writefile then
		local folder = Configuration.FolderName or "Wyvern Spy"
		pcall(makefolder, folder)
		pcall(makefolder, folder .. "/assets")
		local ttfPath = folder .. "/assets/ProggyClean.ttf"
		writefile(ttfPath, fontBody)
		local assetId = Files:LoadCustomasset(ttfPath)
		if assetId then
			local jsonPath = Files:CreateFont("ProggyClean", assetId)
			if jsonPath and Ui and Ui.SetFontFile then
			end
			Configuration._FontTtf = ttfPath
			Configuration._FontJson = jsonPath
			Configuration._FontAsset = assetId
			Out("font ready")
		else
			Out("font getcustomasset failed")
		end
	end
end)

Out("compiling")
local Modules = Files:LoadLibraries(Scripts)
local Process, Hook, Ui, Generation, Communication, Config =
	Modules.Process, Modules.Hook, Modules.Ui, Modules.Generation, Modules.Communication, Modules.Config

if not (Process and Hook and Ui and Communication) then
	Out("FATAL modules")
	return
end

pcall(function()
	Process:CheckConfig(Config)
end)

if Configuration._FontJson then
	pcall(function()
		Modules.Ui:SetFontFile(Configuration._FontJson)
		Out("font file set")
	end)
end
Out("Ui:Init (ReGui + prefab patch)")
local initOk, initErr = pcall(function()
	Files:LoadModules(Modules, {
		Modules = Modules,
		Services = Services,
		Configuration = Configuration,
	})
end)
if not initOk then
	Out("Init error:", initErr)
end

Out("CreateMainWindow")
local Window
local winOk, winErr = pcall(function()
	Window = Ui:CreateMainWindow()
end)

if not winOk or not Window then
	Out("ReGui window FAILED:", winErr)
	Out("Your executor still cannot load ReGui prefabs. Use MainReal.luau (simple UI).")
	return
end
Out("ReGui window OK!")

local Supported = true
pcall(function()
	Supported = Process:CheckIsSupported()
end)
if not Supported then
	pcall(function()
		Window:Close()
	end)
	Out("unsupported executor")
	return
end

local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)
Communication:AddCommCallback("Print", function(...)
	Ui:ConsoleLog(...)
end)

pcall(function()
	local LP = Services.Players.LocalPlayer
	Generation:SetSwapsCallback(function(self)
		self:AddSwap(LP, { String = "LocalPlayer" })
		if LP.Character then
			self:AddSwap(LP.Character, { String = "Character", NextParent = LP })
		end
	end)
end)

pcall(function()
	Ui:CreateWindowContent(Window)
	Ui:SetCommChannel(Event)
	Ui:BeginLogService()
end)

Out("hooks")
pcall(function()
	Hook:LoadHooks("", ChannelId)
end)
pcall(function()
	Event:Fire("BeginHooks", { PatchFunctions = false })
end)

Out("LOADED with ReGui")
