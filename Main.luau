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
	-- Actors: injecting into every actor can crash large games. Keep off unless needed.
	NoActors = true,
	FolderName = "Sigma Spy",
	Directory = "Sigma Spy",

	-- Primary source for modules (your GitHub)
	RepoUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main",

	-- Parser (bundled single-file on your repo)
	ParserUrl = "https://raw.githubusercontent.com/Lucsqxxx/spy/refs/heads/main/dist/Parser.luau",

	-- Prefer local modules when running from a folder that supports readfile
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

--// Custom font (optional)
local FontContent = Files:GetAsset("ProggyClean.ttf", true)
if FontContent then
	local FontJsonFile = Files:CreateFont("ProggyClean", FontContent)
	if FontJsonFile then
		Ui:SetFontFile(FontJsonFile)
	end
end

--// Initialize modules
Process:CheckConfig(Config)
Files:LoadModules(Modules, {
	Modules = Modules,
	Services = Services,
	Configuration = Configuration,
})

--// Create main window
local Window = Ui:CreateMainWindow()

--// Executor / environment check
local Supported = Process:CheckIsSupported()
if not Supported then
	Window:Close()
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

--// Build UI content
Ui:CreateWindowContent(Window)
Ui:SetCommChannel(Event)
Ui:BeginLogService()

--// Actor script + hooks (NoActors=true by default to avoid crashes)
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

--// Function patches default OFF (patching pcall/getfenv can crash some executors)
local EnablePatches = false
local AskOk, AskResult = pcall(function()
	return Ui:AskUser({
		Title = "Enable function patches?",
		Content = {
			"Usually leave this as No.",
			"On some executors, patches can reduce detections.",
			"On others, they can freeze or crash Roblox.",
			"",
			"Recommended: No",
		},
		Options = { "No", "Yes" },
	})
end)
if AskOk and AskResult == "Yes" then
	EnablePatches = true
end

--// Start hooks
pcall(function()
	Event:Fire("BeginHooks", {
		PatchFunctions = EnablePatches,
	})
end)

print("[Sigma Spy] Loaded successfully.")
