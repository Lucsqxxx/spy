--[[
	Sigma Spy – MinimalUI boot (no ReGui asset load)
	Hooks OFF. Simple ScreenGui instead of ReGui (avoids LoadLocalAsset crash).
]]

local function Out(...)
	local t = {...}
	for i = 1, #t do t[i] = tostring(t[i]) end
	local msg = "[Sigma Spy] " .. table.concat(t, " ")
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

Out("boot start (MinimalUI)")

local Configuration = {
	UseWorkspace = false,
	NoActors = true,
	SafeMode = true,
	MinimalUI = true, -- skip ReGui
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

Out("loading Files")
local FilesSource = HttpGet(Base .. "/src/utils/Files.lua")
if not FilesSource then
	Out("FATAL: Files.lua")
	return
end
local Files = loadstring(FilesSource, "Files")()
Files:PushConfig(Configuration)
pcall(function()
	Files:Init({ Services = Services })
end)
Out("Files ok")

-- Load core only (no Ui module = no ReGui)
local coreNames = {
	Process = "/src/core/Process.lua",
	Hook = "/src/core/Hook.lua",
	Communication = "/src/core/Communication.lua",
	Flags = "/src/utils/Flags.lua",
	Generation = "/src/generation/Generation.lua",
}

local Scripts = {
	Configuration = Configuration,
	Files = Files,
}
pcall(function()
	Scripts.Config = Files:GetModule(Configuration.FolderName .. "/Config", "Config")
	Scripts.ReturnSpoofs = Files:GetModule(Configuration.FolderName .. "/Return spoofs", "Return Spoofs")
end)

for Name, Path in coreNames do
	Out("loading", Name)
	local src = HttpGet(Base .. Path)
	if src then
		Scripts[Name] = src
	else
		Out("missing", Name)
	end
end

Out("compiling")
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Generation = Modules.Generation
local Communication = Modules.Communication
local Config = Modules.Config

if not (Process and Hook and Communication) then
	Out("FATAL core modules")
	return
end
Out("core ok")

-- SafeMode: skip Instance.new hook in Process:Init
Configuration.SafeMode = true
pcall(function()
	Files:LoadModules(Modules, {
		Modules = Modules,
		Services = Services,
		Configuration = Configuration,
	})
end)
Out("inited")

-- Minimal ScreenGui (NO ReGui)
Out("creating minimal UI")
local guiOk, guiErr = pcall(function()
	local PlayerGui = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
	local Screen = Instance.new("ScreenGui")
	Screen.Name = "SigmaSpyMinimal"
	Screen.ResetOnSpawn = false
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function()
		Screen.Parent = game:GetService("CoreGui")
	end)
	if not Screen.Parent then
		Screen.Parent = PlayerGui
	end

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.fromOffset(320, 140)
	Frame.Position = UDim2.new(0.5, -160, 0.15, 0)
	Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Frame.BorderSizePixel = 0
	Frame.Parent = Screen

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Frame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -16, 0, 28)
	Title.Position = UDim2.fromOffset(8, 8)
	Title.BackgroundTransparency = 1
	Title.Text = "Sigma Spy (Minimal UI)"
	Title.TextColor3 = Color3.fromRGB(220, 220, 230)
	Title.TextSize = 16
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Frame

	local Body = Instance.new("TextLabel")
	Body.Size = UDim2.new(1, -16, 1, -48)
	Body.Position = UDim2.fromOffset(8, 40)
	Body.BackgroundTransparency = 1
	Body.Text = "Loaded without ReGui (avoids crash).\nHooks: OFF (SafeMode)\nCore modules: OK\n\nFull UI needs a ReGui-compatible executor."
	Body.TextColor3 = Color3.fromRGB(180, 180, 190)
	Body.TextSize = 13
	Body.Font = Enum.Font.Gotham
	Body.TextXAlignment = Enum.TextXAlignment.Left
	Body.TextYAlignment = Enum.TextYAlignment.Top
	Body.TextWrapped = true
	Body.Parent = Frame
end)

if not guiOk then
	Out("minimal UI failed:", guiErr)
else
	Out("minimal UI ok")
end

Out("LOADED SUCCESSFULLY (minimal)")
Out("ReGui skipped — this executor hard-crashes on ReGui prefab asset load")
