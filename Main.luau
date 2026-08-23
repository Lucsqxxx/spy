--[[
	Sigma Spy (Reworked)
	Clean entry point – local-first with remote fallback.

	Usage:
		loadstring(game:HttpGet(".../Main.luau"))()
		or
		loadstring(game:HttpGet(".../Main.luau"))({ RepoUrl = "https://..." })
]]

--// Base Configuration (override via first argument)
local Configuration = {
	UseWorkspace = false,
	-- Actors: injecting into every actor can crash large games.
	NoActors = true,
	-- SafeMode: UI only — no metamethod/remote hooks (prevents hard crashes).
	-- Set to false once stable, or pass { SafeMode = false } when loading.
	SafeMode = true,
	FolderName = "Sigma Spy",
	Directory = "Sigma Spy",

	RepoUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main",
	ParserUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main/dist/Parser.luau",
	PreferLocal = true,
}

--// Apply user overwrites
local Parameters = { ... }
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
	for Key, Value in Overwrites do
		Configuration[Key] = Value
	end
end

--// Service proxy (cloneref when available)
local Services = setmetatable({}, {
	__index = function(_, Name: string): Instance
		local Service = game:GetService(Name)
		if cloneref then
			return cloneref(Service)
		end
		return Service
	end,
})

--// Safe HttpGet
local function HttpGet(Url: string): string?
	local Ok, Result = pcall(function()
		return game:HttpGet(Url)
	end)
	if Ok and typeof(Result) == "string" and #Result > 0 then
		return Result
	end
	return nil
end

--// Try local file first, then remote
local function LoadSource(RelativePath: string, RemotePath: string?): string?
	-- Local attempt (executors that support readfile + listfiles)
	if Configuration.PreferLocal and readfile then
		local Candidates = {
			`SigmaSpy/{RelativePath}`,
			`{RelativePath}`,
			`src/{RelativePath}`,
		}
		for _, Path in Candidates do
			local Ok, Content = pcall(readfile, Path)
			if Ok and typeof(Content) == "string" and #Content > 0 then
				return Content
			end
		end
	end

	-- Remote fallback
	local Base = Configuration.RepoUrl:gsub("/+$", "")
	local Url = RemotePath or `{Base}/{RelativePath}`
	return HttpGet(Url)
end

--// Bootstrap Files module (needed early)
local FilesSource = LoadSource("src/utils/Files.lua", `{Configuration.RepoUrl}/src/utils/Files.lua`)
	or LoadSource("lib/Files.lua", `{Configuration.RepoUrl}/src/utils/Files.lua`)

if not FilesSource then
	warn("[Sigma Spy] Failed to load Files module. Check RepoUrl or local paths.")
	return
end

local Files = loadstring(FilesSource)()
Files:PushConfig(Configuration)
Files:Init({
	Services = Services,
})

local Folder = Files.FolderName

--// Module map (local path → remote fallback path)
local ModuleMap = {
	-- User config (created/loaded by Files)
	Config = { Local = nil, Remote = nil, Template = "Config" },
	ReturnSpoofs = { Local = nil, Remote = nil, Template = "Return Spoofs" },

	-- Libraries (paths match the new project structure)
	Process = {
		Local = "src/core/Process.lua",
		Remote = `{Configuration.RepoUrl}/src/core/Process.lua`,
	},
	Hook = {
		Local = "src/core/Hook.lua",
		Remote = `{Configuration.RepoUrl}/src/core/Hook.lua`,
	},
	Flags = {
		Local = "src/utils/Flags.lua",
		Remote = `{Configuration.RepoUrl}/src/utils/Flags.lua`,
	},
	Ui = {
		Local = "src/ui/Ui.lua",
		Remote = `{Configuration.RepoUrl}/src/ui/Ui.lua`,
	},
	Generation = {
		Local = "src/generation/Generation.lua",
		Remote = `{Configuration.RepoUrl}/src/generation/Generation.lua`,
	},
	Communication = {
		Local = "src/core/Communication.lua",
		Remote = `{Configuration.RepoUrl}/src/core/Communication.lua`,
	},
}

--// Build Scripts table for Files loader
local Scripts = {
	Config = Files:GetModule(`{Folder}/Config`, "Config"),
	ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
	Configuration = Configuration,
	Files = Files,
}

for Name, Info in ModuleMap do
	if Info.Local or Info.Remote then
		local Source = LoadSource(Info.Local or "", Info.Remote)
		if Source then
			Scripts[Name] = Source
		else
			warn(`[Sigma Spy] Missing module: {Name}`)
		end
	end
end

--// Load all libraries
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

if not (Process and Hook and Ui and Generation and Communication) then
	warn("[Sigma Spy] Critical modules failed to load.")
	return
end

--// Custom font (optional — skip in SafeMode; getcustomasset can crash some clients)
if not Configuration.SafeMode then
	pcall(function()
		local FontContent = Files:GetAsset("ProggyClean.ttf", true)
		if FontContent then
			local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
			if FontJsonFile then
				Ui:SetFontFile(FontJsonFile)
			end
		end
	end)
end

--// Initialize modules
pcall(function()
	Process:CheckConfig(Config)
end)
Files:LoadModules(Modules, {
	Modules = Modules,
	Services = Services,
	Configuration = Configuration,
})

--// Create main window
local Window
local WinOk, WinErr = pcall(function()
	Window = Ui:CreateMainWindow()
end)
if not WinOk then
	warn("[Sigma Spy] UI failed to create:", WinErr)
	return
end

--// Executor / environment check
local Supported = Process:CheckIsSupported()
if not Supported then
	pcall(function() Window:Close() end)
	return
end

--// Communication channel
local ChannelId, Event = Communication:CreateChannel()
Communication:AddCommCallback("QueueLog", function(...)
	Ui:QueueLog(...)
end)
Communication:AddCommCallback("Print", function(...)
	Ui:ConsoleLog(...)
end)

--// Generation value swaps
pcall(function()
	local Players = Services.Players
	local LocalPlayer = Players.LocalPlayer
	Generation:SetSwapsCallback(function(self)
		self:AddSwap(LocalPlayer, {
			String = "LocalPlayer",
		})
		if LocalPlayer.Character then
			self:AddSwap(LocalPlayer.Character, {
				String = "Character",
				NextParent = LocalPlayer,
			})
		end
	end)
end)

--// Build UI content
pcall(function()
	Ui:CreateWindowContent(Window)
	Ui:SetCommChannel(Event)
	Ui:BeginLogService()
end)

--// Hooks (skipped in SafeMode to prevent Roblox hard crashes)
if Configuration.SafeMode then
	print("[Sigma Spy] SafeMode ON — UI only, hooks disabled.")
	print("[Sigma Spy] To enable hooks: load with { SafeMode = false }")
else
	local ActorCode = ""
	if not Configuration.NoActors then
		local Ok, Result = pcall(function()
			return Files:MakeActorScript(Scripts, ChannelId)
		end)
		if Ok then
			ActorCode = Result
		else
			warn("[Sigma Spy] MakeActorScript failed:", Result)
		end
	end

	local OkHooks, HooksErr = pcall(function()
		Hook:LoadHooks(ActorCode, ChannelId)
	end)
	if not OkHooks then
		warn("[Sigma Spy] LoadHooks failed:", HooksErr)
	end

	-- Function patches default OFF
	local EnablePatches = false

	pcall(function()
		Event:Fire("BeginHooks", {
			PatchFunctions = EnablePatches,
		})
	end)
end

print("[Sigma Spy] Loaded successfully.")
