local Ui = {
	DefaultEditorContent = [=[--[[
	Wyvern Spy, Wyvern Spy
	Hooks rewritten and many more fixes!

	
]]]=],
	LogLimit = 100,
    SeasonLabels = { 
        January = "⛄ %s ⛄", 
        February = "🌨️ %s 🏂", 
        March = "🌹 %s🌺 ", 
        April = "🐣 %s ✝️", 
        May = "🐝 %s 🌞", 
        June = "🌲 %s 🥕", 
        July = "🌊 %s 🌅", 
        August = "☀️ %s 🌞", 
        September = "🍁 %s 🍁", 
        October = "🎃 %s 🎃", 
        November = "🍂 %s 🍂", 
        December = "🎄 %s 🎁"
    },
	Scales = {
		["Mobile"] = UDim2.fromOffset(480, 280),
		["Desktop"] = UDim2.fromOffset(600, 400),
	},
    BaseConfig = {
        Theme = "WyvernSpy",
        NoScroll = true,
    },
	OptionTypes = {
		boolean = "Checkbox",
		number = "InputInt",
	},
	DisplayRemoteInfo = {
		"MetaMethod",
		"Method",
		"Remote",
		"CallingScript",
		"IsActor",
		"Id"
	},

    Window = nil,
    RandomSeed = Random.new(tick()),
	Logs = setmetatable({}, {__mode = "k"}),
	LogQueue = setmetatable({}, {__mode = "v"}),
} 

type table = {
	[any]: any
}

type Log = {
	Remote: Instance,
	Method: string,
	Args: table,
	IsReceive: boolean?,
	MetaMethod: string?,
	OrignalFunc: ((...any) -> ...any)?,
	CallingScript: Instance?,
	CallingFunction: ((...any) -> ...any)?,
	ClassData: table?,
	ReturnValues: table?,
	RemoteData: table?,
	Id: string,
	Selectable: table,
	HeaderData: table,
	ValueSwaps: table,
	Timestamp: number,
	IsExploit: boolean
}

--// Compatibility
local SetClipboard = setclipboard or toclipboard or set_clipboard

--// Libraries
local ReGui = nil

--// Modules
local Flags
local Generation
local Process
local Hook 
local Config
local Communication
local Files

local ActiveData = nil
local RemotesCount = 0

local TextFont = Font.fromEnum(Enum.Font.BuilderSans)
local FontSuccess = true -- system BuilderSans; custom font optional
local CommChannel

function Ui:Init(Data)
    local Modules = Data.Modules

	--// Modules
	Flags = Modules.Flags
	Generation = Modules.Generation
	Process = Modules.Process
	Hook = Modules.Hook
	Config = Modules.Config
	Communication = Modules.Communication
	Files = Modules.Files

	--// ReGui: use pure-Instance compat library (no prefab asset — works on Real)
	--// Original Dear-ReGui requires rbxassetid://71968920594655 via LoadLocalAsset which crashes Real.
	local CompatUrl = `{Data.Configuration.RepoUrl}/src/ui/ReGuiCompat.lua`
	local CompatSource = game:HttpGet(CompatUrl)
	ReGui = loadstring(CompatSource, "ReGuiCompat")()
	warn("[Wyvern Spy] Using ReGuiCompat (no prefab asset)")

	self:LoadFont()
	self:LoadReGui()
	self:CheckScale()
end

function Ui:SetCommChannel(NewCommChannel: BindableEvent)
	CommChannel = NewCommChannel
end

function Ui:CheckScale()
	local BaseConfig = self.BaseConfig
	local Scales = self.Scales

	local IsMobile = ReGui:IsMobileDevice()
	local Device = IsMobile and "Mobile" or "Desktop"

	BaseConfig.Size = Scales[Device]
end

function Ui:SetClipboard(Content: string)
	pcall(function()
		SetClipboard(Content)
	end)
	self:ShowToast("Copied")
end

function Ui:ShowToast(Message: string, Duration: number?)
	Duration = Duration or 1.4
	local Window = self.Window
	if not Window or not Window.Instance then
		pcall(warn, "[Wyvern] " .. tostring(Message))
		return
	end
	pcall(function()
		local host = Window.Instance
		local old = host:FindFirstChild("WyvernToast")
		if old then old:Destroy() end
		local toast = Instance.new("TextLabel")
		toast.Name = "WyvernToast"
		toast.AnchorPoint = Vector2.new(0.5, 1)
		toast.Position = UDim2.new(0.5, 0, 1, -12)
		toast.Size = UDim2.fromOffset(160, 28)
		toast.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
		toast.TextColor3 = Color3.fromRGB(230, 230, 235)
		toast.Font = Enum.Font.GothamMedium
		toast.TextSize = 13
		toast.Text = tostring(Message)
		toast.ZIndex = 50
		toast.Parent = host
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = toast
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(60, 60, 68)
		s.Thickness = 1
		s.Parent = toast
		task.delay(Duration, function()
			pcall(function() toast:Destroy() end)
		end)
	end)
end


function Ui:LoadFont()
	-- Prefer sleek system UI font; optional custom override if present
	local okF, face = pcall(Font.fromEnum, Enum.Font.BuilderSans)
	TextFont = (okF and face) or Font.fromEnum(Enum.Font.Gotham)
	FontSuccess = true
	pcall(function()
		if ReGui and ReGui.SetFont then
			ReGui:SetFont(TextFont, 14)
		end
	end)
	local FontFile = self.FontJsonFile
	if not FontFile or not Files then return end
	local AssetId = Files:LoadCustomasset(FontFile)
	if not AssetId then return end
	local Ok, NewFont = pcall(Font.new, AssetId)
	if Ok and NewFont then
		-- Custom font only applied to code editor path if user ships one
		warn("[Wyvern Spy] Optional custom font asset loaded")
	end
end

function Ui:SetFontFile(FontFile: string)
	self.FontJsonFile = FontFile
end

function Ui:FontWasSuccessful()
	if FontSuccess then return end

	--// Error message
	self:ShowModal({
		"Unfortunately your executor was unable to download the font and therefore switched to the Dark theme",
		"\nIf you would like to use the ImGui theme, \nplease download the font (assets/ProggyClean.ttf)",
		"and put put it in your workspace folder\n(Wyvern Spy/assets)"
	})
end

function Ui:LoadReGui()
	local ThemeConfig = Config.ThemeConfig
	ThemeConfig.TextFont = TextFont

	if ReGui.SetFont then
		ReGui:SetFont(TextFont, ThemeConfig.TextSize or 13)
	end


	ReGui:DefineTheme("WyvernSpy", ThemeConfig)
end

type CreateButtons = {
	Base: table?,
	Buttons: table,
	NoTable: boolean?
}
function Ui:CreateButtons(Parent, Data: CreateButtons)
	local Base = Data.Base or {}
	local Buttons = Data.Buttons
	local NoTable = Data.NoTable
	local MaxColumns = Data.MaxColumns or 3

	-- Default: compact buttons that stay inside the window
	if not Base.Size then
		Base.Size = UDim2.fromOffset(110, 26)
	end
	-- Clamp full-width sizes that blow out horizontal layouts
	if Base.Size and Base.Size.X.Scale >= 1 then
		Base.Size = UDim2.fromOffset(120, Base.Size.Y.Offset > 0 and Base.Size.Y.Offset or 26)
	end
	Base.FlexFill = true

	if NoTable then
		for _, Button in next, Buttons do
			ReGui:CheckConfig(Button, Base)
			Parent:Button(Button)
		end
		return
	end

	-- Wrap into rows of MaxColumns so buttons never spill outside the window
	local col = 0
	local row = Parent:Row()
	for _, Button in next, Buttons do
		if col >= MaxColumns then
			row = Parent:Row()
			col = 0
		end
		ReGui:CheckConfig(Button, Base)
		row:Button(Button)
		col += 1
	end
end

function Ui:CreateWindow(WindowConfig)
    local BaseConfig = self.BaseConfig
	local Config = Process:DeepCloneTable(BaseConfig)
	Process:Merge(Config, WindowConfig)

	--// Create Window
	local Window = ReGui:Window(Config)

	--// Switch to DarkTheme instead of the ImGui theme if the font cannot be loaded
	if not FontSuccess then 
		Window:SetTheme("DarkTheme")
	end
	
	--// Create Window
	return Window
end

type AskConfig = {
	Title: string,
	Content: table,
	Options: table
}
function Ui:AskUser(Config: AskConfig): string
	local Window = self.Window
	local Answered = false

	--// Create modal
	local ModalWindow = Window:PopupModal({
		Title = Config.Title
	})
	ModalWindow:Label({
		Text = table.concat(Config.Content, "\n"),
		TextWrapped = true
	})
	ModalWindow:Separator()

	--// Answers
	local Row = ModalWindow:Row({
		Expanded = true
	})
	for _, Answer in next, Config.Options do
		Row:Button({
			Text = Answer,
			Callback = function()
				Answered = Answer
				ModalWindow:ClosePopup()
			end,
		})
	end

	repeat wait() until Answered
	return Answered
end

function Ui:CreateMainWindow()
	local Window = self:CreateWindow()
	self.Window = Window

	--// Check if the font was successfully downloaded
	self:FontWasSuccessful()

	--// UiVisible flag callback
	Flags:SetFlagCallback("UiVisible", function(self, Visible)
		Window:SetVisible(Visible)
	end)

	self:BeginSpamWatch()
	return Window
end

function Ui:ShowModal(Lines: table)
	local Window = self.Window
	local Message = table.concat(Lines, "\n")

	--// Modal Window
	local ModalWindow = Window:PopupModal({
		Title = "Wyvern"
	})
	ModalWindow:Label({
		Text = Message,
		RichText = true,
		TextWrapped = true
	})
	ModalWindow:Button({
		Text = "Okay",
		Callback = function()
			ModalWindow:ClosePopup()
		end,
	})
end

function Ui:ShowUnsupportedExecutor(Name: string)
	Ui:ShowModal({
		"Unfortunately Wyvern Spy is not supported on your executor",
		"Your executor may not support all features",
		`\nYour executor: {Name}`
	})
end

function Ui:ShowUnsupported(FuncName: string)
	Ui:ShowModal({
		"Unfortunately Wyvern Spy is not supported on your executor",
		`\nMissing function: {FuncName}`
	})
end

function Ui:CreateOptionsForDict(Parent, Dict: table, Callback)
	local Options = {}

	--// Dictonary wrap
	for Key, Value in next, Dict do
		Options[Key] = {
			Value = Value,
			Label = Key,
			Callback = function(_, Value)
				Dict[Key] = Value

				--// Invoke callback
				if not Callback then return end
				Callback()
			end
		}
	end

	--// Create elements
	self:CreateElements(Parent, Options)
end

function Ui:CheckKeybindLayout(Container, KeyCode: Enum.KeyCode, Callback)
	if not KeyCode then return Container end

	--// Create Row layout
	Container = Container:Row({
		HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
	})

	--// Add Keybind element
	Container:Keybind({
		Label = "",
		Value = KeyCode,
		LayoutOrder = 2,
		IgnoreGameProcessed = false,
		Callback = function()
			--// Check if keybinds are enabled
			local Enabled = Flags:GetFlagValue("KeybindsEnabled")
			if not Enabled then return end

			--// Invoke callback
			Callback()
		end,
	})

	return Container
end

function Ui:CreateElements(Parent, Options)
	local OptionTypes = self.OptionTypes
	local MaxColumns = 2 -- stay inside window width
	local col = 0
	local row = Parent:Row()

	for Name, Data in Options do
		local Value = Data.Value
		local Type = typeof(Value)

		ReGui:CheckConfig(Data, {
			Class = OptionTypes[Type],
			Label = Name,
		})
		
		local Class = Data.Class
		assert(Class, `No {Type} type exists for option`)

		if col >= MaxColumns then
			row = Parent:Row()
			col = 0
		end

		local Container = row:NextColumn()
		local Checkbox = nil

		local Keybind = Data.Keybind
		Container = self:CheckKeybindLayout(Container, Keybind, function()
			Checkbox:Toggle()
		end)
		
		Checkbox = Container[Class](Container, Data)
		col += 1
	end
end


function Ui:TypePip(ClassData, Remote): string
	local cn = ""
	pcall(function()
		if ClassData and ClassData.IsRemoteFunction then
			cn = "F"
		elseif Remote and typeof(Remote) == "Instance" then
			local n = Remote.ClassName
			if n == "UnreliableRemoteEvent" then
				cn = "U"
			elseif n == "RemoteFunction" or n == "BindableFunction" then
				cn = "F"
			elseif n == "BindableEvent" then
				cn = "B"
			else
				cn = "E"
			end
		else
			cn = "E"
		end
	end)
	if cn == "" then cn = "?" end
	return "[" .. cn .. "]"
end

function Ui:UpdateListStatus()
	local label = self.RemotesListEmpty
	if not label or not label.Instance then return end
	local paused = false
	pcall(function()
		paused = Flags:GetFlagValue("Paused") == true
	end)
	local hasLogs = false
	if self.Logs then
		for _ in pairs(self.Logs) do
			hasLogs = true
			break
		end
	end
	if paused and not hasLogs then
		label.Instance.Text = "Paused — enable capture in Options"
		label.Instance.Visible = true
	elseif paused and hasLogs then
		label.Instance.Text = "Paused — list frozen"
		label.Instance.Visible = true
	elseif not hasLogs then
		label.Instance.Text = "No traffic yet"
		label.Instance.Visible = true
	else
		label.Instance.Visible = false
	end
end

function Ui:TypeBadge(Value): string
	local ty = typeof(Value)
	if ty == "table" and type(Value) == "table" and Value.__t then
		return tostring(Value.__t)
	end
	if ty == "Instance" then
		local ok, cn = pcall(function() return Value.ClassName end)
		return ok and cn or "Instance"
	end
	return ty
end

function Ui:TypeBadgeColor(Value): Color3
	local badge = self:TypeBadge(Value)
	local map = {
		string = Color3.fromRGB(180, 220, 150),
		number = Color3.fromRGB(150, 200, 255),
		boolean = Color3.fromRGB(230, 180, 120),
		nil = Color3.fromRGB(140, 140, 150),
		table = Color3.fromRGB(200, 170, 255),
		Instance = Color3.fromRGB(120, 200, 220),
		Vector3 = Color3.fromRGB(130, 210, 190),
		Vector2 = Color3.fromRGB(130, 210, 190),
		CFrame = Color3.fromRGB(160, 190, 230),
		Color3 = Color3.fromRGB(255, 170, 140),
		EnumItem = Color3.fromRGB(220, 200, 140),
		buffer = Color3.fromRGB(170, 170, 190),
		["function"] = Color3.fromRGB(255, 150, 180),
	}
	if map[badge] then return map[badge] end
	-- ClassName-ish (Part, RemoteEvent, etc.)
	if typeof(Value) == "Instance" or (typeof(Value) == "table" and Value.__t == "Instance") then
		return Color3.fromRGB(120, 200, 220)
	end
	return Color3.fromRGB(180, 185, 195)
end

function Ui:FormatArgPreview(Value, Limit: number?): string
	Limit = Limit or 80
	local ty = typeof(Value)
	if ty == "table" and Value.__t then
		ty = Value.__t
		if Value.path then return "Instance " .. tostring(Value.path):sub(1, Limit) end
		if Value.str then return tostring(Value.str):sub(1, Limit) end
	end
	if ty == "Instance" then
		local ok, p = pcall(function() return Value:GetFullName() end)
		return (ok and p or tostring(Value)):sub(1, Limit)
	end
	local s = tostring(Value)
	if #s > Limit then s = s:sub(1, Limit) .. "…" end
	return s
end


function Ui:UpdateSpamIndicator()
	local active = false
	pcall(function()
		active = getgenv and getgenv()._WVS_SPAM == true
	end)
	self.SpamActive = active
	pcall(function()
		local win = self.Window and self.Window.Instance
		if not win then return end
		local chip = win:FindFirstChild("StatusChip", true)
		if not chip then return end
		if active then
			chip.Visible = true
			chip.BackgroundTransparency = 0
			chip.BackgroundColor3 = Color3.fromRGB(48, 22, 26)
			chip.Text = "  SPAM · tap to stop  "
			chip.TextColor3 = Color3.fromRGB(255, 160, 165)
		else
			chip.Visible = false
			chip.BackgroundTransparency = 1
			chip.Text = ""
		end
	end)
end

function Ui:StopSpam()
	pcall(function()
		if getgenv then getgenv()._WVS_SPAM = false end
	end)
	self.SpamActive = false
	self:UpdateSpamIndicator()
	self:ShowToast("Spam stopped")
end

function Ui:BeginSpamWatch()
	if self._spamWatch then return end
	self._spamWatch = true
	task.spawn(function()
		while self._spamWatch do
			self:UpdateSpamIndicator()
			pcall(function()
				local win = self.Window and self.Window.Instance
				local chip = win and win:FindFirstChild("StatusChip", true)
				if chip and chip:IsA("TextButton") and not chip:GetAttribute("Bound") then
					chip:SetAttribute("Bound", true)
					chip.MouseButton1Click:Connect(function()
						self:StopSpam()
					end)
				end
			end)
			task.wait(0.35)
		end
	end)
end

function Ui:CreateWindowContent(Window)
	-- Cobalt-inspired: left rail (filters + list) | right detail tabs
	local Layout = Window:List({
		UiPadding = 0,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		VerticalFlex = Enum.UIFlexAlignment.Fill,
		FillDirection = Enum.FillDirection.Horizontal,
		Fill = true,
	})

	local Mobile = false
	pcall(function()
		Mobile = ReGui:IsMobileDevice() == true
	end)
	self.IsMobileUi = Mobile
	local sideW = Mobile and 180 or 240
	local searchH = Mobile and 34 or 28

	local Sidebar = Layout:List({
		UiPadding = Mobile and 6 or 8,
		FillDirection = Enum.FillDirection.Vertical,
		Size = UDim2.new(0, sideW, 1, 0),
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
	})

	-- Search
	local SearchBox = Sidebar:InputText({
		Label = "",
		Placeholder = "Search…",
		Value = "",
		Size = UDim2.new(1, 0, 0, searchH),
		Callback = function(_, text)
			self.ListSearch = (text or ""):lower()
			self:ApplyListFilter()
		end,
	})
	self.SearchBox = SearchBox
	self.ListSearch = ""

	self.RemotesList = Sidebar:Canvas({
		Scroll = true,
		UiPadding = 4,
		AutomaticSize = Enum.AutomaticSize.None,
		FlexMode = Enum.UIFlexMode.Fill,
		Size = UDim2.new(1, 0, 1, -(searchH + 8)),
	})
	pcall(function()
		local inst = self.RemotesList.Instance
		if inst and inst:IsA("ScrollingFrame") then
			inst.ScrollBarThickness = Mobile and 8 or 5
			inst.ScrollingDirection = Enum.ScrollingDirection.Y
		end
	end)
	self.RemotesListEmpty = self.RemotesList:Label({
		Text = "No traffic yet",
		TextColor3 = Color3.fromRGB(120, 120, 130),
	})

	local InfoSelector = Layout:TabSelector({
		NoAnimation = true,
		Size = UDim2.new(1, -(sideW + 8), 1, 0),
	})

	self.InfoSelector = InfoSelector
	self.CanvasLayout = Layout

	self:MakeEditorTab(InfoSelector)
	self:MakeOptionsTab(InfoSelector)
	if Config.Debug then
		self:ConsoleTab(InfoSelector)
	end
	self:UpdateListStatus()
	-- Refresh status when pause toggles
	pcall(function()
		Flags:SetFlagCallback("Paused", function()
			self:UpdateListStatus()
		end)
	end)
end

function Ui:EntrySearchBlob(entry): string
	local parts = {}
	if entry then
		parts[#parts + 1] = tostring(entry.Remote or "")
		parts[#parts + 1] = tostring(entry.RemotePath or "")
		parts[#parts + 1] = tostring(entry.Method or "")
		local args = entry.Args
		if typeof(args) == "table" then
			local n = math.min(table.maxn(args), 6)
			for i = 1, n do
				local v = args[i]
				if typeof(v) == "string" then
					parts[#parts + 1] = v
				elseif typeof(v) == "number" or typeof(v) == "boolean" then
					parts[#parts + 1] = tostring(v)
				elseif typeof(v) == "Instance" then
					parts[#parts + 1] = tostring(v)
				elseif typeof(v) == "table" and v.__t == "Instance" and v.path then
					parts[#parts + 1] = tostring(v.path)
				end
			end
		end
	end
	return string.lower(table.concat(parts, " "))
end

function Ui:ApplyListFilter()
	local q = self.ListSearch or ""
	local Logs = self.Logs
	if not Logs then return end
	local any = false
	for _, Header in pairs(Logs) do
		local headerShow = (q == "")
		if q ~= "" then
			local blob = string.lower(tostring(Header.RemoteName or ""))
			if Header.Data then
				blob ..= " " .. self:EntrySearchBlob(Header.Data)
			end
			if Header.Entries then
				for _, entry in ipairs(Header.Entries) do
					blob ..= " " .. self:EntrySearchBlob(entry)
				end
			end
			headerShow = string.find(blob, q, 1, true) ~= nil
		end

		local node = Header.TreeNode
		if node and node.Instance then
			node.Instance.Visible = headerShow
		end
		if Header.Entries then
			for _, entry in ipairs(Header.Entries) do
				if entry.Selectable and entry.Selectable.Instance then
					local es = headerShow
					if q ~= "" and headerShow then
						-- keep entry visible if its own blob matches OR header matched via another entry
						es = true
					end
					entry.Selectable.Instance.Visible = es
					if es then any = true end
				end
			end
		end
		if headerShow then any = true end
	end
	if self.RemotesListEmpty and self.RemotesListEmpty.Instance then
		-- only force empty visibility when no match and not using UpdateListStatus paused text
		if q ~= "" then
			self.RemotesListEmpty.Instance.Text = any and "" or "No matches"
			self.RemotesListEmpty.Instance.Visible = not any
		else
			self:UpdateListStatus()
		end
	end
end

function Ui:ConsoleTab(InfoSelector)
	local Tab = InfoSelector:CreateTab({
		Name = "Console"
	})

	local Console
	local ButtonsRow = Tab:Row()

	ButtonsRow:Button({
		Text = "Clear",
		Callback = function()
			Console:Clear()
		end
	})
	ButtonsRow:Button({
		Text = "Copy",
		Callback = function()
			toclipboard(Console:GetValue())
		end
	})
	ButtonsRow:Button({
		Text = "Pause",
		Callback = function(self)
			local Enabled = not Console.Enabled
			local Text = Enabled and "Pause" or "Paused"
			self.Text = Text

			--// Update console
			Console.Enabled = Enabled
		end,
	})
	ButtonsRow:Expand()

	--// Create console
	Console = Tab:Console({
		Text = "-- Wyvern Spy",
		ReadOnly = true,
		Border = false,
		Fill = true,
		Enabled = true,
		AutoScroll = true,
		RichText = true,
		MaxLines = 50
	})

	self.Console = Console
end

function Ui:ConsoleLog(...: string?)
	local Console = self.Console
	if not Console then return end

	Console:AppendText(...)
end

function Ui:MakeOptionsTab(InfoSelector)
	local Tab = InfoSelector:CreateTab({
		Name = "Options"
	})

	--// Add global options
	Tab:Separator({Text="Logs"})
	self:CreateButtons(Tab, {
		Base = {
			Size = UDim2.fromOffset(118, 26),
		},
		MaxColumns = 3,
		Buttons = {
			{
				Text = "Clear logs",
				Callback = function()
					local Tab = ActiveData and ActiveData.Tab or nil

					--// Remove the Remote tab
					if Tab then
						InfoSelector:RemoveTab(Tab)
					end

					--// Clear all log elements
					ActiveData = nil
					self:ClearLogs()
				end,
			},
			{
				Text = "Clear blocks",
				Callback = function()
					Process:UpdateAllRemoteData("Blocked", false)
				end,
			},
			{
				Text = "Clear excludes",
				Callback = function()
					Process:UpdateAllRemoteData("Excluded", false)
				end,
			},
			
			{
				Text = "Copy Github",
				Callback = function()
					self:SetClipboard("https://github.com/Lucsqxxx/spy")
				end,
			},
			{
				Text = "Edit Spoofs",
				Callback = function()
					self:EditFile("Return spoofs.lua", true, function(Window, Content: string)
						Window:Close()
						CommChannel:Fire("UpdateSpoofs", Content)
					end)
				end,
			}
		}
	})

	--// Flag options
	Tab:Separator({Text="Settings"})
	self:CreateElements(Tab, Flags:GetFlags())

	self:AddDetailsSection(Tab)
end

function Ui:AddDetailsSection(OptionsTab)
	OptionsTab:Separator({Text="Information"})
	OptionsTab:BulletText({
		Rows = {
			"Wyvern Spy - Wyvern Spy",
			"Wyvern Spy - Wyvern Spy",
			""
		}
	})
end

local function MakeActiveDataCallback(Name: string)
	return function(...)
		if not ActiveData then return end
		return ActiveData[Name](ActiveData, ...)
	end
end

function Ui:MakeEditorTab(InfoSelector)
	local Default = self.DefaultEditorContent
	local SyntaxColors = Config.SyntaxColors

	--// Create tab
	local EditorTab = InfoSelector:CreateTab({
		Name = "Editor"
	})
	self.EditorTab = EditorTab

	--// IDE (fills space above the button row)
	local CodeEditor = EditorTab:CodeEditor({
		Fill = true,
		Editable = true,
		FontSize = 13,
		Colors = SyntaxColors,
		FontFace = Font.fromEnum(Enum.Font.RobotoMono),
		Text = Default
	})

	-- L1: primary actions visible; overflow in More menu (no cramped 7-button row)
	local ButtonsRow = EditorTab:Row({
		Size = UDim2.new(1, 0, 0, 28),
	})
	self:CreateButtons(ButtonsRow, {
		NoTable = true,
		Buttons = {
			{
				Text = "Copy",
				Callback = function()
					local Script = CodeEditor:GetText()
					self:SetClipboard(Script)
				end
			},
			{
				Text = "Run",
				Callback = function()
					local Script = CodeEditor:GetText()
					local Func, Error = loadstring(Script, "WyvernSpy-USERSCRIPT")
					if not Func then
						-- ED-10: surface line number from compiler error
						local line = nil
						local errStr = tostring(Error or "")
						local a, b = string.match(errStr, "%:(%d+)%s*:")
						if not a then a = string.match(errStr, "[Ll]ine%s*(%d+)") end
						line = tonumber(a)
						local msg = {"Error running script!", errStr}
						if line then
							table.insert(msg, "→ Near line " .. tostring(line))
							pcall(function()
								if CodeEditor.HighlightLine then
									CodeEditor:HighlightLine(line)
								elseif CodeEditor._box then
									-- soft hint via toast only
								end
							end)
						end
						self:ShowModal(msg)
						self:ShowToast(line and ("Error line " .. line) or "Script error", 2)
						return
					end
					local ok, runErr = pcall(Func)
					if not ok then
						local errStr = tostring(runErr or "")
						local a = string.match(errStr, "%:(%d+)%s*:") or string.match(errStr, "[Ll]ine%s*(%d+)")
						local line = tonumber(a)
						self:ShowModal({"Runtime error!", errStr, line and ("→ Near line " .. line) or nil})
						self:ShowToast(line and ("Error line " .. line) or "Runtime error", 2)
					end
				end
			},
			{
				Text = "Repeat",
				Callback = MakeActiveDataCallback("RepeatCall")
			},
			{
				Text = "Build",
				Callback = MakeActiveDataCallback("BuildScript")
			},
			{
				Text = "More",
				Callback = function(Btn)
					self:MakeButtonMenu(Btn, {}, {
						["Get return"] = function()
							if ActiveData then
								ActiveData:GetReturn()
							end
						end,
						["Script options"] = function()
							if ActiveData then
								ActiveData:ScriptOptions(Btn)
							end
						end,
						["Pop-out editor"] = function()
							local Script = CodeEditor:GetText()
							local Tile = ActiveData and ActiveData.Task or "Wyvern Spy"
							self:MakeEditorPopoutWindow(Script, { Title = Tile })
						end,
						["Toggle wrap"] = function()
							-- ED-5
							pcall(function()
								if CodeEditor.SetWrapped then
									local on = not (CodeEditor._wrapped == true)
									CodeEditor:SetWrapped(on)
									self:ShowToast(on and "Wrap on" or "Wrap off")
								elseif CodeEditor._box then
									CodeEditor._box.TextWrapped = not CodeEditor._box.TextWrapped
									CodeEditor._wrapped = CodeEditor._box.TextWrapped
									self:ShowToast(CodeEditor._wrapped and "Wrap on" or "Wrap off")
								end
							end)
						end,
					})
				end
			},
		}
	})

	
	self.CodeEditor = CodeEditor
end

function Ui:ShouldFocus(Tab): boolean
	local InfoSelector = self.InfoSelector
	local ActiveTab = InfoSelector.ActiveTab

	--// If there is an empty tab
	if not ActiveTab then
		return true
	end

	return InfoSelector:CompareTabs(ActiveTab, Tab)
end

function Ui:MakeEditorPopoutWindow(Content: string, WindowConfig: table)
	local Window = self:CreateWindow(WindowConfig)
	local Buttons = WindowConfig.Buttons or {}
	local Colors = Config.SyntaxColors

	local CodeEditor = Window:CodeEditor({
		Text = Content,
		Editable = true,
		Fill = true,
		FontSize = 13,
		Colors = Colors,
		FontFace = TextFont
	})

	--// Default buttons
	table.insert(Buttons, {
		Text = "Copy",
		Callback = function()
			local Script = CodeEditor:GetText()
			self:SetClipboard(Script)
		end
	})

	--// Buttons
	local ButtonsRow = Window:Row()
	self:CreateButtons(ButtonsRow, {
		NoTable = true,
		Buttons = Buttons
	})

	Window:Center()
	return CodeEditor, Window
end

function Ui:EditFile(FilePath: string, InFolder: boolean, OnSaveFunc: ((table, string) -> nil)?)
	local Folder = Files.FolderName
	local CodeEditor, Window

	--// Relative to Wyvern Spy folder
	if InFolder then
		FilePath = `{Folder}/{FilePath}`
	end

	--// Get file content
	local Content = readfile(FilePath)
	Content = Content:gsub("\r\n", "\n")
	
	local Buttons = {
		{
			Text = "Save",
			Callback = function()
				local Script = CodeEditor:GetText()
				local Success, Error = loadstring(Script, "WyvernSpy-Editor")

				--// Syntax check
				if not Success then
					self:ShowModal({"Error saving file!\n", Error})
					return
				end
				
				--// Save contents
				writefile(FilePath, Script)

				--// Invoke on save function
				if OnSaveFunc then
					OnSaveFunc(Window, Script)
				end
			end
		}
	}

	--// Create Editor Window
	CodeEditor, Window = self:MakeEditorPopoutWindow(Content, {
		Title = `Editing: {FilePath}`,
		Buttons = Buttons
	})
end

type MenuOptions = {
	[string]: (GuiButton, ...any) -> nil
}
function Ui:MakeButtonMenu(Button: Instance, Unpack: table, Options: MenuOptions)
	local Window = self.Window
	local Popup = Window:PopupCanvas({
		RelativeTo = Button,
		MaxSizeX = 500,
	})

	--// Create Selectables for string, function
	for Name, Func in Options do
		 Popup:Selectable({
			Text = Name,
			Callback = function()
				Func(Process:Unpack(Unpack))
			end,
		})
	end
end

function Ui:RemovePreviousTab(Title: string): boolean
	--// No previous tabs
	if not ActiveData then 
		return false 
	end

	--// TabSelector
	local InfoSelector = self.InfoSelector

	--// Previous elements
	local PreviousTab = ActiveData.Tab
	local PreviousSelectable = ActiveData.Selectable

	--// Remove previous tab and set selectable focus
	local TabFocused = self:ShouldFocus(PreviousTab)
	InfoSelector:RemoveTab(PreviousTab)
	PreviousSelectable:SetSelected(false)

	--// Create new tab
	return TabFocused
end

function Ui:MakeTableHeaders(Table, Rows: table)
	local HeaderRow = Table:HeaderRow()
	for _, Catagory in Rows do
		local Column = HeaderRow:NextColumn()
		Column:Label({
			Text = tostring(Catagory),
			TextColor3 = Color3.fromRGB(140, 170, 220),
		})
	end
end

function Ui:Decompile(Editor: table, Script: Script)
	local Header = "--Decompiled with Wyvern Spy"
	Editor:SetText("--Decompiling... ")

	--// Decompile script
	local Decompiled, IsError = Process:Decompile(Script)

	--// Add header for successful decompilations
	if not IsError then
		Decompiled = `{Header}\n{Decompiled}`
	end

	Editor:SetText(Decompiled)
end

type DisplayTableConfig = {
	Rows: table,
	Flags: table?,
	ToDisplay: table,
	Table: table
}
function Ui:DisplayTable(Parent, Config: DisplayTableConfig): table
	--// Configuration
	local Rows = Config.Rows
	local Flags = Config.Flags
	local DataTable = Config.Table
	local ToDisplay = Config.ToDisplay

	Flags.MaxColumns = #Rows

	--// Create table
	local Table = Parent:Table(Flags)

	--// Table headers
	self:MakeTableHeaders(Table, Rows)

	--// Table layout
	for RowIndex, Name in ToDisplay do
		local Row = Table:Row()
		
		--// Create Columns
		for Count, Catagory in Rows do
			local Column = Row:NextColumn()
			
			--// Value text
			local Value = Catagory == "Name" and Name or DataTable[Name]
			if not Value then continue end

			--// Create filtered label
			local String = self:FilterName(`{Value}`, 150)
			Column:Label({Text=String})
		end
	end

	return Table
end

function Ui:SetFocusedRemote(Data)
	--// Unpack remote data
	local Remote = Data.Remote
	local Method = Data.Method
	local IsReceive = Data.IsReceive
	local Script = Data.CallingScript
	local ClassData = Data.ClassData
	local HeaderData = Data.HeaderData
	local ValueSwaps = Data.ValueSwaps
	local Args = Data.Args
	local Id = Data.Id

	--// Flags
	local TableArgs = Flags:GetFlagValue("TableArgs")
	local NoVariables = Flags:GetFlagValue("NoVariables")

	--// Unpack info
	local RemoteData = Process:GetRemoteData(Id)
	local IsRemoteFunction = ClassData.IsRemoteFunction
	local RemoteName = self:FilterName(`{Remote}`, 50)

	--// UI data
	local CodeEditor = self.CodeEditor
	local ToDisplay = self.DisplayRemoteInfo
	local InfoSelector = self.InfoSelector

	local TabFocused = self:RemovePreviousTab()
	local Tab = InfoSelector:CreateTab({
		Name = self:FilterName(`Remote: {RemoteName}`, 50),
		Focused = TabFocused
	})

	--// Create new parser
	local Module = Generation:NewParser({
		NoVariables = NoVariables
	})
	local Parser = Module.Parser
	local Formatter = Module.Formatter
	Formatter:SetValueSwaps(ValueSwaps)

	--// Set this log to be selected
	ActiveData = Data
	Data.Tab = Tab
	Data.Selectable:SetSelected(true)

	local function SetIDEText(Content: string, Task: string?)
		Data.Task = Task or "Wyvern Spy"
		if not CodeEditor then
			warn("[Wyvern Spy] CodeEditor missing")
			return
		end
		local Ok, Err = pcall(function()
			CodeEditor:SetText(tostring(Content or ""))
		end)
		if not Ok then
			warn("[Wyvern Spy] SetText failed:", Err)
			-- Fallback: try .Text on instance
			pcall(function()
				if CodeEditor._box then
					CodeEditor._box.Text = tostring(Content or "")
				elseif CodeEditor.Instance then
					local box = CodeEditor.Instance:FindFirstChildWhichIsA("TextBox", true)
					if box then box.Text = tostring(Content or "") end
				end
			end)
		end
		-- Switch to Editor tab so the user sees the script
		pcall(function()
			local et = self.EditorTab
			if et and et._button then
				-- fire same as clicking Editor tab
				for _, t in (InfoSelector._tabs or {}) do
					t.Instance.Visible = false
					if t._button then t._button.BackgroundColor3 = Color3.fromRGB(48, 56, 78) end
				end
				et.Instance.Visible = true
				et._button.BackgroundColor3 = Color3.fromRGB(55, 95, 160)
				InfoSelector.ActiveTab = et
			end
		end)
	end
	local function DataConnection(Name, ...)
		local Args = {...}
		return function()
			return Data[Name](Data, Process:Unpack(Args))
		end
	end
	local function ScriptCheck(Script, NoMissingCheck: boolean): boolean?
		--// Reject client events
		if IsReceive then 
			Ui:ShowModal({
				"Recieves do not have a script because it's a Connection"
			})
			return 
		end

		--// Check if script exists
		if not Script and not NoMissingCheck then 
			Ui:ShowModal({"The Script has been destroyed by the game "})
			return
		end

		return true
	end

	--// Functions
	function Data:ScriptOptions(Button: GuiButton)
		Ui:MakeButtonMenu(Button, {self}, {
			["Caller Info"] = DataConnection("GenerateInfo"),
			["Decompile"] = DataConnection("Decompile", "SourceScript"),
			["Decompile Calling"] = DataConnection("Decompile", "CallingScript"),
			["Repeat Call"] = DataConnection("RepeatCall"),
			["Save Bytecode"] = DataConnection("SaveBytecode"),
		})
	end
	function Data:BuildScript(Button: GuiButton)
		Ui:MakeButtonMenu(Button, {self}, {
			["Save"] = DataConnection("SaveScript"),
			["Call Remote"] = DataConnection("MakeScript", "Remote"),
			["Minimal"] = DataConnection("MakeScript", "Minimal"),
			["Edit & Repeat"] = DataConnection("MakeScript", "Edit"),
			["Block Remote"] = DataConnection("MakeScript", "Block"),
			["Repeat For"] = DataConnection("MakeScript", "Repeat"),
			["Spam Remote"] = DataConnection("MakeScript", "Spam"),
			["Undo Spam"] = DataConnection("MakeScript", "UndoSpam")
		})
	end
	function Data:SaveScript()
		local FilePath = Generation:TimeStampFile(self.Task)
		writefile(FilePath, CodeEditor:GetText())

		Ui:ShowModal({"Saved script to", FilePath})
	end
	function Data:SaveBytecode()
		--// Problem check
		if not ScriptCheck(Script, true) then return end

		--// getscriptbytecode
    	local Success, Bytecode = pcall(getscriptbytecode, Script)
		if not Success then
			Ui:ShowModal({"Failed to get Scripte bytecode "})
			return
		end

		--// Save file
		local PathBase = `{Script} %s.txt`
		local FilePath = Generation:TimeStampFile(PathBase)
		writefile(FilePath, Bytecode)

		Ui:ShowModal({"Saved bytecode to", FilePath})
	end
	function Data:MakeScript(ScriptType: string)
		local Script = Generation:RemoteScript(Module, self, ScriptType)
		SetIDEText(Script, `Editing: {RemoteName}.lua`)
		if ScriptType == "Spam" then
			Ui:ShowToast("Run script to start spam")
		elseif ScriptType == "UndoSpam" then
			Ui:StopSpam()
			Ui:ShowToast("Undo Spam ready — or already stopped")
		end
	end
	function Data:RepeatCall()
		local Signal = Hook:Index(Remote, Method)

		if IsReceive then
			firesignal(Signal, Process:Unpack(Args))
		else
			Signal(Remote, Process:Unpack(Args))
		end
	end
	function Data:GetReturn()
		local ReturnValues = self.ReturnValues

		--// Error messages
		if not IsRemoteFunction then
			Ui:ShowModal({"The Remote is not a Remote Function "})
			return
		end
		if not ReturnValues then
			Ui:ShowModal({"No return values "})
			return
		end

		--// Generate script
		local Script = Generation:TableScript(Module, ReturnValues)
		SetIDEText(Script, `Return Values for: {RemoteName}`)
	end
	function Data:GenerateInfo()
		--// Problem check
		if not ScriptCheck(nil, true) then return end

		--// Generate script
		local Script = Generation:AdvancedInfo(Module, self)
		SetIDEText(Script, `Advanced Info for: {RemoteName}`)
	end
	function Data:Decompile(WhichScript: string)
		local DecompilePopout = Flags:GetFlagValue("DecompilePopout")
		local ToDecompile = Data[WhichScript]
		local Editor = CodeEditor

		--// Problem check
		if not ScriptCheck(ToDecompile, true) then return end
		local Task = Ui:FilterName(`Viewing: {ToDecompile}.lua`, 200)
		
		--// Automatically Pop-out the editor for decompiling if enabled
		if DecompilePopout then
			Editor = Ui:MakeEditorPopoutWindow("", {
				Title = Task
			})
		end

		Ui:Decompile(Editor, ToDecompile)
	end
	
	--// RemoteOptions
	self:CreateOptionsForDict(Tab, RemoteData, function()
		Process:UpdateRemoteData(Id, RemoteData)
	end)

	--// Instance options
	self:CreateButtons(Tab, {
		Base = {
			Size = UDim2.fromOffset(130, 26),
		},
		MaxColumns = 2,
		Buttons = {
			{
				Text = "Copy script path",
				Callback = function()
					SetClipboard(Parser:MakePathString({
						Object = Script,
						NoVariables = true
					}))
				end,
			},
			{
				Text = "Copy remote path",
				Callback = function()
					local path = Data.RemotePath
					if not path then
						path = Parser:MakePathString({
							Object = Remote,
							NoVariables = true
						})
					end
					SetClipboard(path)
				end,
			},
			{
				Text = "Copy args",
				Callback = function()
					local ok, script = pcall(function()
						return Generation:TableScript(Module, Args)
					end)
					SetClipboard(ok and script or self:FormatArgPreview(Args, 500))
				end,
			},
			{
				Text = "Remove log",
				Callback = function()
					InfoSelector:RemoveTab(Tab)
					Data.Selectable:Remove()
					HeaderData:Remove()
					ActiveData = nil
				end,
			},
			{
				Text = "Dump logs",
				Callback = function()
					local Logs = HeaderData.Entries
					local FilePath = Generation:DumpLogs(Logs)
					self:ShowModal({"Saved dump to", FilePath})
				end,
			},
			{
				Text = "View Connections",
				Callback = function()
					local Method = ClassData.Receive[1]
					local Signal = Remote[Method]
					self:ViewConnections(RemoteName, Signal)
				end,
			}
		}
	})

	--// Remote information table
	self:DisplayTable(Tab, {
		Rows = {"Name", "Value"},
		Table = Data,
		ToDisplay = ToDisplay,
		Flags = {
			Border = true,
			RowBackground = true,
			MaxColumns = 2
		}
	})

	-- 3.3 Copy value / path per argument
	Tab:Label({ Text = "Arguments", TextColor3 = Color3.fromRGB(150, 152, 160) })
	local argList = Args
	if typeof(argList) == "table" then
		local maxn = table.maxn(argList)
		if maxn == 0 then
			for k in next, argList do
				maxn = math.max(maxn, typeof(k) == "number" and k or 0)
			end
		end
		for i = 1, math.min(maxn, 24) do
			local val = argList[i]
			local badge = self:TypeBadge(val)
			local badgeColor = self:TypeBadgeColor(val)
			local preview = self:FormatArgPreview(val, 40)
			local argPath = "args[" .. tostring(i) .. "]"
			local rowH = self.IsMobileUi and 34 or 28
			local row = Tab:Row({ Size = UDim2.new(1, 0, 0, rowH) })
			row:Label({
				Text = string.format("[%s]", badge),
				TextColor3 = badgeColor,
			})
			row:Label({
				Text = string.format("%s  %s", argPath, preview),
				TextColor3 = Color3.fromRGB(210, 212, 220),
			})
			row:Button({
				Text = "Copy",
				Size = UDim2.fromOffset(self.IsMobileUi and 52 or 48, self.IsMobileUi and 28 or 24),
				Callback = function()
					local text
					if typeof(val) == "Instance" then
						local ok, p = pcall(function() return val:GetFullName() end)
						text = ok and p or tostring(val)
					elseif typeof(val) == "table" then
						local ok, s = pcall(function()
							return Generation:TableScript(Module, { val })
						end)
						text = ok and s or self:FormatArgPreview(val, 400)
					else
						text = tostring(val)
					end
					self:SetClipboard(text)
				end,
			})
			row:Button({
				Text = "Path",
				Size = UDim2.fromOffset(self.IsMobileUi and 52 or 48, self.IsMobileUi and 28 or 24),
				Callback = function()
					self:SetClipboard(argPath)
				end,
			})
		end
	end
	
	--// Arguments table script
	if TableArgs then
		local Parsed = Generation:TableScript(Module, Args)
		SetIDEText(Parsed, `Arguments for {RemoteName}`)
		return
	end

	--// Remote call script
	Data:MakeScript("Remote")
end

function Ui:ViewConnections(RemoteName: string, Signal: RBXScriptConnection)
	local Window = self:CreateWindow({
		Title = `Connections for: {RemoteName}`,
		Size = UDim2.fromOffset(450, 250)
	})

	local ToDisplay = {
		"Enabled",
		"LuaConnection",
		"Script"
	}

	--// Get Filtered connections
	local Connections = Process:FilterConnections(Signal, ToDisplay)

	--// Table
	local Table = Window:Table({
		Border = true,
		RowBackground = true,
		MaxColumns = 3
	})

	local ButtonsForValues = {
		["Script"] = function(Row, Value)
			Row:Button({
				Text = "Decompile",
				Callback = function()
					local Task = self:FilterName(`Viewing: {Value}.lua`, 200)
					local Editor = self:MakeEditorPopoutWindow(nil, {
						Title = Task
					})
					self:Decompile(Editor, Value)
				end
			})
		end,
		["Enabled"] = function(Row, Enabled, Connection)
			Row:Button({
				Text = Enabled and "Disable" or "Enable",
				Callback = function(self)
					Enabled = not Enabled
					self.Text = Enabled and "Disable" or "Enable"

					--// Enable or disable the connection
					if Enabled then
						Connection:Enable()
					else
						Connection:Disable()
					end
				end
			})
		end
	}

	--// Make headers on the table
	self:MakeTableHeaders(Table, ToDisplay)

	for _, Connection in Connections do
		local Row = Table:Row()

		for _, Property in ToDisplay do
			local Column = Row:NextColumn()
			local ColumnRow = Column:Row()

			local Value = Connection[Property]
			local Callback = ButtonsForValues[Property]

			--// Value label
			ColumnRow:Label({Text=`{Value}`})

			--// Add buttons
			if Callback then
				Callback(ColumnRow, Value, Connection)
			end
		end
	end

	--// Center Window
	Window:Center()
end

function Ui:GetRemoteHeader(Data: Log)
	local LogLimit = self.LogLimit
	pcall(function()
		local v = Flags:GetFlagValue("LogsPerRemote")
		if typeof(v) == "number" and v > 0 then
			LogLimit = math.floor(v)
		end
	end)
	local Logs = self.Logs
	local RemotesList = self.RemotesList

	--// Remote info
	local Id = Data.Id
	local Remote = Data.Remote
	local RemoteName = self:FilterName(`{Remote}`, 30)

	--// NoTreeNodes
	local NoTreeNodes = Flags:GetFlagValue("NoTreeNodes")

	--// Check for existing TreeNode
	local Existing = Logs[Id]
	if Existing then return Existing end

	--// Header data
	local HeaderData = {	
		LogCount = 0,
		Data = Data,
		Entries = {}
	}

	--// Increment treenode count
	RemotesCount += 1

	--// Create new treenode element
	if not NoTreeNodes then
		local Pip = self:TypePip(Data.ClassData, Remote)
		HeaderData.TreeNode = RemotesList:TreeNode({
			LayoutOrder = -1 * RemotesCount,
			Title = string.format("%s %s  ·  0", Pip, RemoteName)
		})
		HeaderData.RemoteName = RemoteName
		HeaderData.TypePip = Pip
	end

	function HeaderData:CheckLimit()
		local Entries = self.Entries
		if #Entries < LogLimit then return end
			
		--// Get and remove last element
		local Log = table.remove(Entries, 1)
		Log.Selectable:Remove()
	end

	function HeaderData:LogAdded(Data)
		self.LogCount += 1
		self:CheckLimit()
		table.insert(self.Entries, Data)
		-- Count on header (SetTitle keeps full string; avoids stuck x0 / truncation glitches)
		if self.TreeNode then
			local pip = self.TypePip or ""
			local name = self.RemoteName or "Remote"
			local count = self.LogCount or 0
			local label = string.format("%s %s  ·  %d", pip, name, count)
			if self.TreeNode.SetTitle then
				self.TreeNode:SetTitle(label)
			elseif self.TreeNode.Instance then
				local h = self.TreeNode.Instance:FindFirstChild("Header")
				if h then
					h.Text = "▾  " .. label
				end
			end
		end
		return self
	end

	function HeaderData:Remove()
		--// Remove TreeNode
		local TreeNode = self.TreeNode
		if TreeNode then
			TreeNode:Remove()
		end

		--// Clear tables from memory
		Logs[Id] = nil
		table.clear(HeaderData)
	end

	Logs[Id] = HeaderData
	return HeaderData
end

function Ui:ClearLogs()
	local Logs = self.Logs
	local RemotesList = self.RemotesList

	RemotesCount = 0
	RemotesList:ClearChildElements()
	table.clear(Logs)

	-- restore empty label after clear
	self.RemotesListEmpty = RemotesList:Label({
		Text = "No traffic yet",
		TextColor3 = Color3.fromRGB(120, 120, 130),
	})
	self:UpdateListStatus()
end

function Ui:QueueLog(Data)
	local LogQueue = self.LogQueue
	Process:Merge(Data, {
		Args = Process:DeepCloneTable(Data.Args),
	})

	if Data.ReturnValues then
        Data.ReturnValues = Process:DeepCloneTable(Data.ReturnValues)
    end
	
    table.insert(LogQueue, Data)
end

function Ui:ProcessLogQueue()
	local Queue = self.LogQueue
    if #Queue <= 0 then return end

	--// Create a log element for each in the Queue
    for Index, Data in next, Queue do
        self:CreateLog(Data)
        table.remove(Queue, Index)
    end
end

function Ui:BeginLogService()
	coroutine.wrap(function()
		while true do
			self:ProcessLogQueue()
			task.wait()
		end
	end)()
end

function Ui:FilterName(Name: string, CharacterLimit: number?): string
	local Trimmed = Name:sub(1, CharacterLimit or 20)
	local Filtred = Trimmed:gsub("[\n\r]", "")
	Filtred = Generation:MakePrintable(Filtred)

	return Filtred
end

function Ui:CreateLog(Data: Log)
	--// Unpack log data
    local Remote = Data.Remote
	local Method = Data.Method
    local Args = Data.Args
    local IsReceive = Data.IsReceive
	local Id = Data.Id
	local Timestamp = Data.Timestamp
	local IsExploit = Data.IsExploit
	
	local IsNilParent = Hook:Index(Remote, "Parent") == nil
	local RemoteData = Process:GetRemoteData(Id)

	--// Paused
	local Paused = Flags:GetFlagValue("Paused")
	if Paused then return end

	self:UpdateListStatus()

	--// Check caller (Ignore exploit calls)
	local LogExploit = Flags:GetFlagValue("LogExploit")
	if not LogExploit and IsExploit then return end

	--// IgnoreNil
	local IgnoreNil = Flags:GetFlagValue("IgnoreNil")
	if IgnoreNil and IsNilParent then return end

    --// LogRecives check
	local LogRecives = Flags:GetFlagValue("LogRecives")
	if not LogRecives and IsReceive then return end

	local SelectNewest = Flags:GetFlagValue("SelectNewest")
	local NoTreeNodes = Flags:GetFlagValue("NoTreeNodes")

    --// Excluded check
    if RemoteData.Excluded then return end

	--// Deserialize arguments
	Args = Communication:DeserializeTable(Args)

	--// Deep clone data
	local ClonedArgs = Process:DeepCloneTable(Args)
	Data.Args = ClonedArgs
	Data.ValueSwaps = Generation:MakeValueSwapsTable(Timestamp)

	--// Generate log title
	local Color = Config.MethodColors[Method:lower()]
	local Text = NoTreeNodes and `{Remote} | {Method}` or Method

	--// FindStringForName check
	local FindString = Flags:GetFlagValue("FindStringForName")
	if FindString then
		for _, Arg in next, ClonedArgs do
			if typeof(Arg) == "string" then
				local Filtred = self:FilterName(Arg)
				Text = `{Filtred} | {Text}`
				break
			end
		end
	end

	--// Fetch HeaderData by the RemoteID used for stacking
	local Header = self:GetRemoteHeader(Data)
	local RemotesList = self.RemotesList

	-- M1: burst / duplicate fingerprint counts
	Header.Fingerprints = Header.Fingerprints or {}
	local fp = Data.Fingerprint or (Method .. ":?")
	Header.Fingerprints[fp] = (Header.Fingerprints[fp] or 0) + 1
	local burst = Header.Fingerprints[fp]
	Data.BurstCount = burst
	if burst > 1 then
		Text = `{Text}  ×{burst}`
	end

	local LogCount = Header.LogCount
	local TreeNode = Header.TreeNode 
	local Parent = TreeNode or RemotesList

	if NoTreeNodes then
		RemotesCount += 1
		LogCount = RemotesCount
	end

	Data.HeaderData = Header
	Data.Selectable = Parent:Selectable({
		Text = Text,
        LayoutOrder = -1 * LogCount,
		TextColor3 = Color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Callback = function()
			self:SetFocusedRemote(Data)
		end,
    })

	-- Watch / highlight new logs briefly
	pcall(function()
		if Flags:GetFlagValue("WatchNew") and Data.Selectable.SetSelected then
			Data.Selectable:SetSelected(true)
			task.delay(1.2, function()
				pcall(function()
					if ActiveData ~= Data then
						Data.Selectable:SetSelected(false)
					end
				end)
			end)
		end
	end)

	Header:LogAdded(Data)

	--// Auto select check
	local GroupSelected = ActiveData and ActiveData.HeaderData == Header
	if SelectNewest and GroupSelected then
		self:SetFocusedRemote(Data)
	end
end

return Ui
