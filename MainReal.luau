--[[
	Sigma Spy for executor "Real"
	- No ReGui (crashes Real via LoadLocalAsset)
	- Simple log UI
	- Hooks ON, NoActors, no function patches
]]

local function Out(...)
	local t = { ... }
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

Out("boot (Real / simple UI)")

local Configuration = {
	UseWorkspace = false,
	NoActors = true,
	SafeMode = false, -- hooks enabled
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

local core = {
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

for Name, Path in core do
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
local Flags = Modules.Flags

if not (Process and Hook and Communication) then
	Out("FATAL core")
	return
end
Out("core ok")

-- Process:Init hooks Instance.new — keep it (needed for remote tracking)
-- Do not set SafeMode true or Instance.new hook is skipped
pcall(function()
	Process:CheckConfig(Config)
end)
pcall(function()
	Files:LoadModules(Modules, {
		Modules = Modules,
		Services = Services,
		Configuration = Configuration,
	})
end)
Out("inited")

---------------------------------------------------------------------
-- Simple UI
---------------------------------------------------------------------
local LogLines = {}
local MaxLogs = 80
local ListFrame

local function AddLogLine(text)
	text = tostring(text)
	table.insert(LogLines, 1, text)
	while #LogLines > MaxLogs do
		table.remove(LogLines)
	end
	if not ListFrame then
		return
	end
	-- refresh labels (simple)
	for _, child in ListFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, line in ipairs(LogLines) do
		if i > 25 then
			break
		end
		local Lab = Instance.new("TextLabel")
		Lab.Size = UDim2.new(1, -8, 0, 18)
		Lab.BackgroundTransparency = 1
		Lab.Text = line
		Lab.TextColor3 = Color3.fromRGB(200, 200, 210)
		Lab.TextSize = 12
		Lab.Font = Enum.Font.Code
		Lab.TextXAlignment = Enum.TextXAlignment.Left
		Lab.TextTruncate = Enum.TextTruncate.AtEnd
		Lab.LayoutOrder = i
		Lab.Parent = ListFrame
	end
end

local Screen
local uiOk, uiErr = pcall(function()
	local LP = Services.Players.LocalPlayer
	Screen = Instance.new("ScreenGui")
	Screen.Name = "SigmaSpyReal"
	Screen.ResetOnSpawn = false
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function()
		Screen.Parent = game:GetService("CoreGui")
	end)
	if not Screen.Parent then
		Screen.Parent = LP:WaitForChild("PlayerGui")
	end

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = UDim2.fromOffset(420, 320)
	Main.Position = UDim2.new(0.5, -210, 0.2, 0)
	Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.Draggable = true
	Main.Parent = Screen
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -80, 0, 32)
	Title.Position = UDim2.fromOffset(12, 4)
	Title.BackgroundTransparency = 1
	Title.Text = "Sigma Spy  |  Real"
	Title.TextColor3 = Color3.fromRGB(230, 230, 240)
	Title.TextSize = 16
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Main

	local Close = Instance.new("TextButton")
	Close.Size = UDim2.fromOffset(28, 28)
	Close.Position = UDim2.new(1, -36, 0, 4)
	Close.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
	Close.Text = "X"
	Close.TextColor3 = Color3.fromRGB(255, 200, 200)
	Close.Font = Enum.Font.GothamBold
	Close.Parent = Main
	Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)
	Close.MouseButton1Click:Connect(function()
		Screen:Destroy()
	end)

	local Status = Instance.new("TextLabel")
	Status.Name = "Status"
	Status.Size = UDim2.new(1, -16, 0, 20)
	Status.Position = UDim2.fromOffset(8, 36)
	Status.BackgroundTransparency = 1
	Status.Text = "Hooks: starting..."
	Status.TextColor3 = Color3.fromRGB(140, 200, 140)
	Status.TextSize = 12
	Status.Font = Enum.Font.Gotham
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.Parent = Main

	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Size = UDim2.new(1, -16, 1, -70)
	Scroll.Position = UDim2.fromOffset(8, 60)
	Scroll.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
	Scroll.CanvasSize = UDim2.fromOffset(0, 500)
	Scroll.Parent = Main
	Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)

	ListFrame = Instance.new("Frame")
	ListFrame.Size = UDim2.new(1, -4, 1, 0)
	ListFrame.BackgroundTransparency = 1
	ListFrame.Parent = Scroll
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = ListFrame

	AddLogLine("Ready. Waiting for remotes...")
end)

if not uiOk then
	Out("UI error:", uiErr)
else
	Out("UI ok")
end

---------------------------------------------------------------------
-- Communication + hooks
---------------------------------------------------------------------
Out("setting up communication")
local ChannelId, Event
local cOk, cErr = pcall(function()
	ChannelId, Event = Communication:CreateChannel()
	Communication:AddCommCallback("QueueLog", function(Data)
		-- Data may be remote log table
		local ok2, line = pcall(function()
			if typeof(Data) == "table" then
				local remote = Data.Remote
				local method = Data.Method or "?"
				local name = typeof(remote) == "Instance" and remote.Name or tostring(remote)
				local recv = Data.IsReceive and "RECV" or "SEND"
				return string.format("[%s] %s  %s", recv, method, name)
			end
			return tostring(Data)
		end)
		AddLogLine(ok2 and line or tostring(Data))
	end)
	Communication:AddCommCallback("Print", function(...)
		local t = { ... }
		for i = 1, #t do t[i] = tostring(t[i]) end
		AddLogLine(table.concat(t, " "))
	end)
end)
if not cOk then
	Out("comm error:", cErr)
end

pcall(function()
	local LP = Services.Players.LocalPlayer
	if Generation and Generation.SetSwapsCallback then
		Generation:SetSwapsCallback(function(self)
			self:AddSwap(LP, { String = "LocalPlayer" })
			if LP.Character then
				self:AddSwap(LP.Character, { String = "Character", NextParent = LP })
			end
		end)
	end
end)

Out("loading hooks (NoActors, no patches)")
local hOk, hErr = pcall(function()
	Hook:LoadHooks("", ChannelId)
end)
if not hOk then
	Out("LoadHooks error:", hErr)
	AddLogLine("LoadHooks error: " .. tostring(hErr))
else
	Out("LoadHooks ok")
end

pcall(function()
	if Event then
		Event:Fire("BeginHooks", { PatchFunctions = false })
	end
end)

AddLogLine("Hooks active. Play the game to see remotes.")
if Screen and Screen:FindFirstChild("Main") then
	local st = Screen.Main:FindFirstChild("Status")
	if st then
		st.Text = "Hooks: ON  |  Actors: OFF  |  Patches: OFF"
	end
end

Out("LOADED — hooks on, simple UI")
