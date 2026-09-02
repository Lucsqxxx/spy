--[[
  WyvernUI — pure Instance UI toolkit for Wyvern Spy
  Theme tokens: see WyvernTheme.lua / Config.UiColors (ApplyTheme)
  Sections: theme → primitives → Element:_create widgets → Window
]]


local WyvernUI = {
	Version = "compat-3.1",
	DefaultTitle = "Wyvern Spy",
	Themes = {},
	Windows = {},
	Initialised = true,
	
	DefaultFont = Font.fromEnum(Enum.Font.Gotham),
	DefaultFontMedium = Font.fromEnum(Enum.Font.GothamMedium),
	DefaultFontBold = Font.fromEnum(Enum.Font.GothamBold),
	DefaultCodeFont = Font.fromEnum(Enum.Font.Code),
	DefaultTextSize = 14,
}

pcall(function()
	WyvernUI.DefaultFont = Font.fromEnum(Enum.Font.BuilderSans)
	WyvernUI.DefaultFontMedium = Font.fromEnum(Enum.Font.BuilderSansMedium)
	WyvernUI.DefaultFontBold = Font.fromEnum(Enum.Font.BuilderSansBold)
end)
pcall(function()
	WyvernUI.DefaultCodeFont = Font.fromEnum(Enum.Font.RobotoMono)
end)

function WyvernUI:SetFont(fontFace, textSize)
	if fontFace then
		self.DefaultFont = fontFace
	end
	if textSize then
		self.DefaultTextSize = textSize
	end
end

local function safeFont(enumName, fallback)
	local ok, f = pcall(function()
		return Enum.Font[enumName]
	end)
	if ok and f then return f end
	return fallback
end

local function applyFont(gui, style)
	
	style = style or "ui"
	pcall(function()
		if style == "code" then
			local f = safeFont("RobotoMono", Enum.Font.Code)
			gui.Font = f
			pcall(function() gui.FontFace = Font.fromEnum(f) end)
		elseif style == "bold" then
			local f = safeFont("BuilderSansBold", Enum.Font.GothamBold)
			gui.Font = f
			pcall(function() gui.FontFace = Font.fromEnum(f) end)
		elseif style == "medium" then
			local f = safeFont("BuilderSansMedium", Enum.Font.GothamMedium)
			gui.Font = f
			pcall(function() gui.FontFace = Font.fromEnum(f) end)
		else
			local f = safeFont("BuilderSans", Enum.Font.Gotham)
			gui.Font = f
			pcall(function() gui.FontFace = Font.fromEnum(f) end)
		end
		if not gui.TextSize or gui.TextSize < 12 then
			gui.TextSize = WyvernUI.DefaultTextSize or 14
		end
	end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function mergeTheme(target, src)
	if typeof(src) ~= "table" or typeof(target) ~= "table" then return end
	for k, v in src do
		if typeof(v) == "Color3" then
			target[k] = v
		end
	end
end

local C = {
	-- Premium dark + soft glass (reference-inspired, not feature copy)
	Bg = Color3.fromRGB(24, 26, 32),
	BgDark = Color3.fromRGB(18, 20, 26),
	BgGlass = Color3.fromRGB(32, 34, 42),
	Title = Color3.fromRGB(30, 32, 40),
	TitleBot = Color3.fromRGB(26, 28, 34),
	Panel = Color3.fromRGB(36, 38, 48),
	PanelAlt = Color3.fromRGB(42, 44, 56),
	Input = Color3.fromRGB(44, 46, 58),
	Border = Color3.fromRGB(62, 64, 78),
	BorderSoft = Color3.fromRGB(50, 52, 64),
	Text = Color3.fromRGB(232, 234, 242),
	TextDim = Color3.fromRGB(148, 150, 165),
	TextMute = Color3.fromRGB(110, 112, 128),
	Accent = Color3.fromRGB(186, 190, 230),
	AccentDim = Color3.fromRGB(130, 134, 180),
	AccentSoft = Color3.fromRGB(70, 72, 100),
	AccentGlow = Color3.fromRGB(200, 204, 240),
	RowAlt = Color3.fromRGB(30, 32, 40),
	RowHover = Color3.fromRGB(48, 50, 64),
	Danger = Color3.fromRGB(220, 105, 115),
	Warn = Color3.fromRGB(230, 190, 100),
	Green = Color3.fromRGB(120, 210, 160),
	Yellow = Color3.fromRGB(230, 200, 100),
	TabActive = Color3.fromRGB(186, 190, 230),
	TabIdle = Color3.fromRGB(40, 42, 54),
	TabTextActive = Color3.fromRGB(24, 26, 34),
	TabTextIdle = Color3.fromRGB(168, 170, 185),
	Btn = Color3.fromRGB(48, 50, 64),
	BtnHover = Color3.fromRGB(58, 60, 76),
	BtnPress = Color3.fromRGB(40, 42, 54),
	Select = Color3.fromRGB(52, 54, 72),
	SelectActive = Color3.fromRGB(72, 74, 100),
	Check = Color3.fromRGB(186, 190, 230),
	CheckOff = Color3.fromRGB(48, 50, 62),
	LineNum = Color3.fromRGB(100, 102, 118),
	Gutter = Color3.fromRGB(20, 22, 28),
	Rail = Color3.fromRGB(20, 22, 28),
	RailActive = Color3.fromRGB(48, 50, 68),
	ShellTransparency = 0.05,
	PanelTransparency = 0.1,
	GlassTransparency = 0.12,
	CornerWindow = 16,
	CornerPanel = 12,
	CornerControl = 8,
	CornerPill = 10,
	CornerRail = 10,
	SpaceOuter = 10,
	SpacePanel = 8,
	SpaceControl = 6,
}





function WyvernUI:CheckConfig(Target, Defaults)
	if typeof(Target) ~= "table" then return Target end
	for k, v in Defaults do
		if Target[k] == nil then
			Target[k] = typeof(v) == "function" and v() or v
		end
	end
	return Target
end

function WyvernUI:DefineTheme(Name, Config)
	self.Themes[Name] = Config or {}
end

function WyvernUI:IsMobileDevice()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function WyvernUI:CheckImportState() end

local function parentGui()
	local screen = CoreGui:FindFirstChild("WyvernSpyUI")
	if screen then return screen end
	screen = Instance.new("ScreenGui")
	screen.Name = "WyvernSpyUI"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 120
	pcall(function() screen.Parent = CoreGui end)
	if not screen.Parent then
		screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return screen
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or (C.CornerControl or 8))
	c.Parent = parent
	return c
end

local function pad(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 4)
	p.PaddingRight = UDim.new(0, r or l or 4)
	p.PaddingTop = UDim.new(0, t or l or 4)
	p.PaddingBottom = UDim.new(0, b or t or l or 4)
	p.Parent = parent
	return p
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or C.Border
	s.Thickness = thickness or 1
	s.Transparency = 0.42
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local Element = {}

local function wrap(inst, className, extra)
	local self = {
		Instance = inst,
		Class = className or "Element",
		Enabled = true,
		ActiveTab = nil,
		_selected = false,
	}
	if extra then
		for k, v in extra do self[k] = v end
	end
	return setmetatable(self, Element)
end

function Element:__index(key)
	local method = rawget(Element, key)
	if method ~= nil then return method end
	local inst = rawget(self, "Instance")
	if inst then
		local ok, val = pcall(function() return inst[key] end)
		if ok and typeof(val) ~= "nil" and typeof(val) ~= "function" and typeof(val) ~= "Instance" then
			return val
		end
	end
	return function(this, config)
		return Element._create(this, key, config or {})
	end
end

function Element:_host()
	
	local override = rawget(self, "_hostOverride")
	if override then return override end
	local inst = self.Instance
	if not inst then return nil end
	local content = inst:FindFirstChild("Content")
	if content then return content end
	return inst
end

function Element:_create(class, config)
	config = config or {}
	local host = self:_host()
	if not host then
		warn("[Wyvern UI] no host for", class)
		return wrap(Instance.new("Frame"), class)
	end

	local function order(gui)
		if config.LayoutOrder then gui.LayoutOrder = config.LayoutOrder end
	end

	
	if class == "List" or class == "Canvas" then
		local scroll = config.Scroll or class == "Canvas"
		local frame
		if scroll then
			frame = Instance.new("ScrollingFrame")
			frame.ScrollBarThickness = 6
			frame.ScrollBarImageColor3 = Color3.fromRGB(70, 74, 88)
			frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			frame.CanvasSize = UDim2.new()
			frame.BackgroundColor3 = C.BgDark
			frame.BackgroundTransparency = 0
			frame.BorderSizePixel = 0
			frame.ClipsDescendants = true
		else
			frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
		end
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 1, 0)
		frame.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		frame.Parent = host
		order(frame)
		if config.BackgroundTransparency ~= nil then
			frame.BackgroundTransparency = config.BackgroundTransparency
		end
		corner(frame, C.CornerPanel or 10)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = config.FillDirection or Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, config.UiPadding or 2)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		pcall(function()
			if config.HorizontalFlex then layout.HorizontalFlex = config.HorizontalFlex end
			if config.VerticalFlex then layout.VerticalFlex = config.VerticalFlex end
		end)
		pad(frame, config.UiPadding or 4)
		return wrap(frame, class)
	end

	
	if class == "Table" then
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = C.BgDark
		frame.BackgroundTransparency = config.Border and 0 or 1
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.ClipsDescendants = true
		frame.Parent = host
		order(frame)
		corner(frame, C.CornerPanel or 10)
		if config.Border then stroke(frame, C.Border, 1) end
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 0)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		pad(frame, 2)
		return wrap(frame, "Table", {
			_maxColumns = config.MaxColumns or 3,
			_rowAlt = config.RowBackground,
			_rowIndex = 0,
		})
	end

	
	if class == "Row" or class == "HeaderRow" or class == "NextRow" then
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 0, 26)
		frame.AutomaticSize = Enum.AutomaticSize.None
			frame.ClipsDescendants = true
		if class == "HeaderRow" then
			frame.BackgroundColor3 = Color3.fromRGB(32, 40, 58)
			frame.BackgroundTransparency = 0
		end
		
		if self.Class == "Table" and self._rowAlt then
			self._rowIndex = (self._rowIndex or 0) + 1
			if self._rowIndex % 2 == 0 then
				frame.BackgroundColor3 = C.RowAlt
				frame.BackgroundTransparency = 0
			else
				frame.BackgroundTransparency = 1
			end
		else
			frame.BackgroundTransparency = 1
		end
		frame.Parent = host
		order(frame)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = frame
		pad(frame, 4, 4, 3, 3)
		return wrap(frame, "Row")
	end

	
	if class == "NextColumn" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(0.5, -4, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		order(frame)
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 2)
		layout.Parent = frame
		pcall(function()
			local flex = Instance.new("UIFlexItem")
			flex.FlexMode = Enum.UIFlexMode.Fill
			flex.Parent = frame
		end)
		return wrap(frame, "Column")
	end

	
	if class == "Label" then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0, 0, 0, 20)
		label.AutomaticSize = Enum.AutomaticSize.XY
		label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextColor3 = config.TextColor3 or C.Text
		label.TextSize = 13
		label.Font = Enum.Font.BuilderSans
		label.TextWrapped = config.TextWrapped == true
		label.RichText = config.RichText or false
		label.Text = tostring(config.Text or "")
		label.Parent = host
		order(label)
		applyFont(label)
		return wrap(label, "Label")
	end

	
	if class == "BulletText" then
		local lines = {}
		for _, row in (config.Rows or {}) do
			table.insert(lines, "•  " .. tostring(row))
		end
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextColor3 = C.TextDim
		label.TextSize = 12
		label.Font = Enum.Font.BuilderSans
		label.TextWrapped = true
		label.Text = table.concat(lines, "\n")
		label.Parent = host
		order(label)
		return wrap(label, "BulletText")
	end

	
	if class == "Separator" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, config.Text and 22 or 10)
		frame.Parent = host
		order(frame)
		if config.Text then
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 1, 0)
			t.Text = "— " .. tostring(config.Text) .. " —"
			t.TextColor3 = C.Accent
			t.TextSize = 12
			t.Font = Enum.Font.BuilderSansBold
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = frame
		else
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.BackgroundColor3 = C.Border
			line.BorderSizePixel = 0
			line.Parent = frame
		end
		return wrap(frame, "Separator")
	end

	
	if class == "Button" then
		local btn = Instance.new("TextButton")
		local sz = config.Size
		
		if sz and sz.X.Scale >= 1 and sz.X.Offset == 0 then
			sz = UDim2.new(0, 120, 0, sz.Y.Offset > 0 and sz.Y.Offset or 26)
		end
		btn.Size = sz or UDim2.new(0, 96, 0, 22)
		btn.AutomaticSize = Enum.AutomaticSize.None
		btn.BackgroundColor3 = C.Btn
		btn.BackgroundTransparency = 0.05
		btn.TextColor3 = C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.BuilderSansMedium
		btn.Text = tostring(config.Text or config.Label or "Button")
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = host
		order(btn)
		corner(btn, C.CornerControl or 8)
		pcall(function() btn.Style = Enum.ButtonStyle.Custom end)
		applyFont(btn, "medium")
		
		if config.FlexFill then
			pcall(function()
				local flex = Instance.new("UIFlexItem")
				flex.FlexMode = Enum.UIFlexMode.Fill
				flex.Parent = btn
			end)
		end
		local el = wrap(btn, "Button")
		btn.MouseEnter:Connect(function()
			tween(btn, TWEEN_FAST, { BackgroundColor3 = C.BtnHover })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, TWEEN_FAST, { BackgroundColor3 = C.Btn })
		end)
		if config.Callback then
			btn.MouseButton1Click:Connect(function()
				pcall(config.Callback, el)
			end)
		end
		function el:Remove() btn:Destroy() end
		return el
	end

	
	if class == "Selectable" then
		local btn = Instance.new("TextButton")
		local rowH = 22
		pcall(function()
			if WyvernUI:IsMobileDevice() then rowH = 30 end
		end)
		btn.Size = config.Size or UDim2.new(1, -4, 0, rowH)
		btn.BackgroundColor3 = C.BgDark
		btn.BackgroundTransparency = 1
		btn.TextColor3 = config.TextColor3 or C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.BuilderSansMedium
		btn.Text = tostring(config.Text or "")
		btn.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = tostring(config.Text or "")
		btn.Parent = host
		pcall(function()
			btn.Style = Enum.ButtonStyle.Custom
		end)
		order(btn)
		pad(btn, 6, 4, 0, 0)
		applyFont(btn, "medium")
		local el = wrap(btn, "Selectable")
		el._btn = btn
		el._alive = true
		function el:SetSelected(v)
			if not el._alive then return end
			el._selected = not not v
			if el._selected then
				btn.BackgroundTransparency = 0
				btn.BackgroundColor3 = C.SelectActive or C.AccentSoft
			else
				btn.BackgroundTransparency = 1
			end
		end
		function el:Remove()
			el._alive = false
			pcall(function() btn:Destroy() end)
		end
		btn.MouseEnter:Connect(function()
			if not el._alive or el._selected then return end
			btn.BackgroundTransparency = 0.55
			btn.BackgroundColor3 = C.Select
		end)
		btn.MouseLeave:Connect(function()
			if not el._selected then
				btn.BackgroundTransparency = 1
			end
		end)
		if config.Callback then
			btn.MouseButton1Click:Connect(function()
				pcall(config.Callback, el)
			end)
		end
		return el
	end

	
	if class == "Checkbox" then
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(0, 0, 0, 22)
		holder.AutomaticSize = Enum.AutomaticSize.X
		holder.Parent = host
		order(holder)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 6)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = holder

		local box = Instance.new("TextButton")
		box.Size = UDim2.fromOffset(16, 16)
		box.BackgroundColor3 = C.Input
		box.Text = ""
		box.TextColor3 = Color3.fromRGB(235, 235, 240)
		box.TextSize = 12
		box.Font = Enum.Font.GothamBold
		box.BorderSizePixel = 0
		box.AutoButtonColor = false
		box.Parent = holder
		pcall(function() box.Style = Enum.ButtonStyle.Custom end)
		corner(box, C.CornerControl or 8)
		stroke(box, Color3.fromRGB(55, 58, 68), 1)

		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.new(0, 0, 0, 18)
		lab.AutomaticSize = Enum.AutomaticSize.X
		lab.Text = tostring(config.Label or config.Text or "")
		lab.TextColor3 = C.Text
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Font = Enum.Font.BuilderSans
		lab.TextSize = 13
		lab.Parent = holder

		local state = not not config.Value
		local function paint()
			if state then
				box.BackgroundColor3 = C.Check
				box.BackgroundTransparency = 0
				box.Text = "✓"
			else
				box.BackgroundColor3 = C.Input
				box.BackgroundTransparency = 0
				box.Text = ""
			end
		end
		paint()

		local el = wrap(holder, "Checkbox")
		local function set(v)
			state = not not v
			paint()
			if config.Callback then pcall(config.Callback, state) end
		end
		box.MouseButton1Click:Connect(function() set(not state) end)
		lab.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				set(not state)
			end
		end)
		function el:Toggle() set(not state) end
		return el
	end

	
	if class == "CodeEditor" or class == "Console" then
		local colors = config.Colors or {}
		local function col3(c, fallback)
			if typeof(c) == "Color3" then
				return string.format("rgb(%d,%d,%d)", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
			end
			return fallback
		end
		local COL = {
			text = col3(colors.Text, "rgb(204,204,204)"),
			keyword = col3(colors.Keyword or colors.Function or colors.Local, "rgb(248,109,124)"),
			string = col3(colors.String, "rgb(172,240,148)"),
			comment = col3(colors.Comment, "rgb(102,102,102)"),
			number = col3(colors.Number or colors.Nil or colors.Bool, "rgb(255,198,0)"),
			builtin = col3(colors.BuiltIn, "rgb(132,214,247)"),
			method = col3(colors.LocalMethod or colors.FunctionName, "rgb(253,251,172)"),
			property = col3(colors.LocalProperty, "rgb(97,161,241)"),
			op = col3(colors.Operator or colors.Bracket, "rgb(200,200,210)"),
		}
		local KEYWORDS = {
			["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
			["end"]=true,["false"]=true,["for"]=true,["function"]=true,["goto"]=true,
			["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,
			["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,
			["until"]=true,["while"]=true,["continue"]=true,["export"]=true,["type"]=true,
		}
		local BUILTINS = {
			["game"]=true,["workspace"]=true,["script"]=true,["Color3"]=true,["Vector3"]=true,
			["Vector2"]=true,["CFrame"]=true,["UDim2"]=true,["UDim"]=true,["Instance"]=true,
			["Enum"]=true,["task"]=true,["wait"]=true,["print"]=true,["warn"]=true,
			["error"]=true,["typeof"]=true,["type"]=true,["pairs"]=true,["ipairs"]=true,
			["next"]=true,["pcall"]=true,["xpcall"]=true,["unpack"]=true,["select"]=true,
			["tonumber"]=true,["tostring"]=true,["setmetatable"]=true,["getmetatable"]=true,
			["require"]=true,["tick"]=true,["time"]=true,["SharedTable"]=true,
			["FireServer"]=true,["InvokeServer"]=true,["OnClientEvent"]=true,["OnClientInvoke"]=true,
			["GetService"]=true,["FindFirstChild"]=true,["WaitForChild"]=true,
		}

		local function escapeRich(s)
			return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
		end

		local function highlight(src)
			src = tostring(src or "")
			local out = {}
			local i = 1
			local n = #src
			while i <= n do
				local ch = src:sub(i, i)
				
				if src:sub(i, i + 3) == "--[[" then
					local j = src:find("%]%]", i + 4) or n
					if src:sub(j, j + 1) == "]]" then j = j + 1 end
					table.insert(out, '<font color="' .. COL.comment .. '">' .. escapeRich(src:sub(i, j)) .. "</font>")
					i = j + 1
				
				elseif src:sub(i, i + 1) == "--" then
					local j = src:find("\n", i) or (n + 1)
					table.insert(out, '<font color="' .. COL.comment .. '">' .. escapeRich(src:sub(i, j - 1)) .. "</font>")
					i = j
				
				elseif ch == '"' or ch == "'" then
					local q = ch
					local j = i + 1
					while j <= n do
						local c = src:sub(j, j)
						if c == "\\" then
							j += 2
						elseif c == q then
							break
						else
							j += 1
						end
					end
					table.insert(out, '<font color="' .. COL.string .. '">' .. escapeRich(src:sub(i, j)) .. "</font>")
					i = j + 1
				
				elseif src:sub(i, i + 1) == "[[" then
					local j = src:find("%]%]", i + 2) or n
					if src:sub(j, j + 1) == "]]" then j = j + 1 end
					table.insert(out, '<font color="' .. COL.string .. '">' .. escapeRich(src:sub(i, j)) .. "</font>")
					i = j + 1
				
				elseif ch:match("%d") then
					local j = i
					while j <= n and src:sub(j, j):match("[%d%.xXa-fA-F]") do
						j += 1
					end
					table.insert(out, '<font color="' .. COL.number .. '">' .. escapeRich(src:sub(i, j - 1)) .. "</font>")
					i = j
				
				elseif ch:match("[%a_]") then
					local j = i
					while j <= n and src:sub(j, j):match("[%w_]") do
						j += 1
					end
					local word = src:sub(i, j - 1)
					local color = COL.text
					if KEYWORDS[word] then
						color = COL.keyword
					elseif BUILTINS[word] then
						color = COL.builtin
					end
					table.insert(out, '<font color="' .. color .. '">' .. escapeRich(word) .. "</font>")
					i = j
				else
					table.insert(out, '<font color="' .. COL.op .. '">' .. escapeRich(ch) .. "</font>")
					i += 1
				end
			end
			return table.concat(out)
		end

		local scroll = Instance.new("ScrollingFrame")
		if config.Fill then
			scroll.Size = UDim2.new(1, 0, 1, -40)
			scroll.AutomaticSize = Enum.AutomaticSize.None
		else
			scroll.Size = config.Size or UDim2.new(1, 0, 0, 160)
		end
		scroll.BackgroundColor3 = (typeof(colors.Background) == "Color3" and colors.Background) or C.BgDark
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 8
		scroll.ScrollBarImageColor3 = Color3.fromRGB(70, 74, 88)
		scroll.ScrollingDirection = Enum.ScrollingDirection.XY
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = host
		order(scroll)
		corner(scroll, C.CornerPanel or 10)
		stroke(scroll, C.Border, 1)
		pad(scroll, 8, 8, 6, 6)
		if config.Fill then
			pcall(function()
				local flex = Instance.new("UIFlexItem")
				flex.FlexMode = Enum.UIFlexMode.Fill
				flex.Parent = scroll
			end)
		end

		
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(0, 0, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.XY
		row.Parent = scroll
		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.Padding = UDim.new(0, 6)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = row

		local gutter = Instance.new("Frame")
		gutter.Name = "Gutter"
		gutter.BackgroundColor3 = C.Gutter
		gutter.BorderSizePixel = 0
		gutter.Size = UDim2.new(0, 42, 0, 0)
		gutter.AutomaticSize = Enum.AutomaticSize.Y
		gutter.Parent = row

		local lineBox = Instance.new("TextLabel")
		lineBox.Name = "LineNumbers"
		lineBox.BackgroundTransparency = 1
		lineBox.Size = UDim2.new(1, -6, 0, 0)
		lineBox.AutomaticSize = Enum.AutomaticSize.Y
		lineBox.TextXAlignment = Enum.TextXAlignment.Right
		lineBox.TextYAlignment = Enum.TextYAlignment.Top
		lineBox.TextColor3 = C.LineNum
		lineBox.TextSize = config.FontSize or 14
		lineBox.Font = Enum.Font.RobotoMono
		applyFont(lineBox, "code")
		lineBox.Text = "1"
		lineBox.Parent = gutter

		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(0, 1, 1, 0)
		sep.Position = UDim2.new(1, -1, 0, 0)
		sep.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		sep.BorderSizePixel = 0
		sep.Parent = gutter

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0, 0, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.XY
		box.BackgroundTransparency = 1
		box.TextColor3 = (typeof(colors.Text) == "Color3" and colors.Text) or Color3.fromRGB(200, 210, 220)
		box.PlaceholderColor3 = C.TextDim
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.TextSize = config.FontSize or 14
		box.Font = Enum.Font.RobotoMono
		applyFont(box, "code")
		box.ClearTextOnFocus = false
		box.MultiLine = true
		box.TextWrapped = false 
		box.RichText = false
		box.Text = config.Text or ""
		box.TextEditable = (config.Editable ~= false) and not config.ReadOnly
		box.Parent = row

		local function updateLineNumbers(src)
			local text = tostring(src or "")
			local count = 1
			for i = 1, #text do
				if string.byte(text, i) == 10 then
					count += 1
				end
			end
			if #text == 0 then count = 1 end
			local buf = table.create(count)
			for i = 1, count do
				buf[i] = tostring(i)
			end
			lineBox.Text = table.concat(buf, string.char(10))
		end

		local plainText = config.Text or ""
		local focused = false
		updateLineNumbers(plainText)

		local function showHighlight()
			if focused then return end
			local ok = pcall(function()
				box.RichText = true
				box.Text = highlight(plainText)
			end)
			if not ok then
				box.RichText = false
				box.Text = plainText
			end
			updateLineNumbers(plainText)
		end

		local function showPlain()
			box.RichText = false
			box.Text = plainText
			updateLineNumbers(plainText)
		end

		box.Focused:Connect(function()
			focused = true
			showPlain()
		end)
		box.FocusLost:Connect(function()
			plainText = box.Text
			focused = false
			showHighlight()
		end)
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if focused then
				plainText = box.Text
				updateLineNumbers(plainText)
			end
		end)

		
		task.defer(showHighlight)

		local el = wrap(scroll, class)
		el.Enabled = config.Enabled ~= false
		el._box = box
		el._lines = {}
		el._plain = function() return plainText end

		function el:GetText()
			if focused then return box.Text end
			return plainText
		end
		function el:GetValue()
			return self:GetText()
		end
		function el:SetText(t)
			plainText = tostring(t or "")
			if focused then
				box.RichText = false
				box.Text = plainText
			else
				showHighlight()
			end
			el._lines = {}
		end
		function el:Clear()
			self:SetText("")
			el._lines = {}
		end
		function el:SetWrapped(on)
			el._wrapped = on and true or false
			box.TextWrapped = el._wrapped
		end
		function el:HighlightLine(lineNum)
			lineNum = tonumber(lineNum) or 1
			local lines = {}
			for s in (plainText .. "\n"):gmatch("(.-)\n") do
				table.insert(lines, s)
			end
			if lineNum < 1 then lineNum = 1 end
			if lineNum > #lines then lineNum = #lines end
			
			self:SetText(plainText)
			pcall(function()
				box:CaptureFocus()
			end)
			el._highlightLine = lineNum
		end
		function el:AppendText(...)
			if not el.Enabled then return end
			local parts = {...}
			for i = 1, #parts do parts[i] = tostring(parts[i]) end
			local line = table.concat(parts, " ")
			if plainText ~= "" and not plainText:match("\n$") then
				plainText ..= "\n"
			end
			plainText ..= line
			local maxL = config.MaxLines or 500
			local lines = {}
			for s in (plainText .. "\n"):gmatch("(.-)\n") do
				table.insert(lines, s)
			end
			while #lines > maxL do table.remove(lines, 1) end
			plainText = table.concat(lines, "\n")
			if focused then
				box.Text = plainText
			else
				showHighlight()
			end
		end
		return el
	end

	if class == "TreeNode" then
		local root = Instance.new("Frame")
		root.Name = "TreeNode"
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.Size = UDim2.new(1, -2, 0, 0)
		root.AutomaticSize = Enum.AutomaticSize.Y
		root.ClipsDescendants = false
		root.Parent = host
		order(root)

		local rowH = 26
		pcall(function()
			if WyvernUI:IsMobileDevice() then rowH = 32 end
		end)

		local open = false
		local title = tostring(config.Title or config.Text or "Node")
		local countVal = tonumber(config.Count) or 0
		local iconImage = config.IconImage or "rbxassetid://110803789420086"

		local headerBtn = Instance.new("TextButton")
		headerBtn.Name = "Header"
		headerBtn.Size = UDim2.new(1, 0, 0, rowH)
		headerBtn.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
		headerBtn.BackgroundTransparency = 0.2
		headerBtn.BorderSizePixel = 0
		headerBtn.AutoButtonColor = false
		headerBtn.Text = ""
		headerBtn.ZIndex = 2
		headerBtn.Parent = root
		corner(headerBtn, 6)
		pcall(function() headerBtn.Style = Enum.ButtonStyle.Custom end)

		local caret = Instance.new("TextLabel")
		caret.Name = "Caret"
		caret.Size = UDim2.fromOffset(16, rowH)
		caret.Position = UDim2.fromOffset(2, 0)
		caret.BackgroundTransparency = 1
		caret.Text = ">"
		caret.TextColor3 = C.TextDim
		caret.TextSize = 12
		caret.Font = Enum.Font.GothamBold
		caret.ZIndex = 3
		caret.Parent = headerBtn

		-- Cobalt-style class icon (real image, not text)
		local icon = Instance.new("ImageLabel")
		icon.Name = "TypeIcon"
		icon.Size = UDim2.fromOffset(18, 18)
		icon.Position = UDim2.new(0, 18, 0.5, -9)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = iconImage
		icon.ZIndex = 3
		icon.Parent = headerBtn

		local header = Instance.new("TextLabel")
		header.Name = "Title"
		header.Size = UDim2.new(1, -78, 1, 0)
		header.Position = UDim2.fromOffset(40, 0)
		header.BackgroundTransparency = 1
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.TextTruncate = Enum.TextTruncate.AtEnd
		header.Font = Enum.Font.BuilderSansMedium
		header.TextSize = 13
		header.TextColor3 = C.Text
		header.Text = title
		header.ZIndex = 3
		header.Parent = headerBtn
		applyFont(header, "medium")

		local countBg = Instance.new("Frame")
		countBg.Name = "CountBadge"
		countBg.AnchorPoint = Vector2.new(1, 0.5)
		countBg.Position = UDim2.new(1, -6, 0.5, 0)
		countBg.Size = UDim2.fromOffset(22, 18)
		countBg.BackgroundColor3 = Color3.fromRGB(48, 50, 58)
		countBg.BorderSizePixel = 0
		countBg.ZIndex = 3
		countBg.Parent = headerBtn
		corner(countBg, 4)
		local countLbl = Instance.new("TextLabel")
		countLbl.Name = "Count"
		countLbl.Size = UDim2.fromScale(1, 1)
		countLbl.BackgroundTransparency = 1
		countLbl.Text = tostring(countVal)
		countLbl.TextColor3 = Color3.fromRGB(180, 182, 190)
		countLbl.TextSize = 11
		countLbl.Font = Enum.Font.GothamMedium
		countLbl.ZIndex = 4
		countLbl.Parent = countBg

		local body = Instance.new("Frame")
		body.Name = "Content"
		body.BackgroundTransparency = 1
		body.BorderSizePixel = 0
		body.Position = UDim2.fromOffset(8, rowH + 2)
		body.Size = UDim2.new(1, -10, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Visible = false
		body.Parent = root
		local bl = Instance.new("UIListLayout")
		bl.Padding = UDim.new(0, 2)
		bl.SortOrder = Enum.SortOrder.LayoutOrder
		bl.Parent = body

		local function refresh()
			header.Text = title
			caret.Text = open and "v" or ">"
			headerBtn.BackgroundTransparency = open and 0.05 or 0.2
			body.Visible = open
			countLbl.Text = tostring(countVal)
			local digits = #tostring(countVal)
			countBg.Size = UDim2.fromOffset(math.max(22, 10 + digits * 7), 18)
		end
		refresh()

		headerBtn.MouseButton1Click:Connect(function()
			open = not open
			refresh()
		end)

		local el = wrap(root, "TreeNode")
		el._title = title
		el._header = header
		el._hostOverride = body
		el._open = function() return open end
		function el:_host() return body end
		function el:SetTitle(t)
			title = tostring(t or "")
			el._title = title
			refresh()
		end
		function el:SetCount(n)
			countVal = tonumber(n) or 0
			refresh()
		end
		function el:SetIconImage(img)
			if img then
				iconImage = img
				icon.Image = img
			end
		end
		function el:Remove()
			pcall(function() root:Destroy() end)
		end
		return el
	end

	
	if class == "TabSelector" then
		local root = Instance.new("Frame")
		root.BackgroundTransparency = 1
		root.Size = config.Size or UDim2.new(1, 0, 1, 0)
		root.Parent = host
		order(root)

		-- Top segmented pill navigation (reference layout philosophy)
		local tabBar = Instance.new("Frame")
		tabBar.Name = "PillNav"
		tabBar.Size = UDim2.new(1, 0, 0, 36)
		tabBar.BackgroundColor3 = C.BgGlass or C.BgDark
		tabBar.BackgroundTransparency = C.GlassTransparency or 0.12
		tabBar.BorderSizePixel = 0
		tabBar.Parent = root
		corner(tabBar, C.CornerPanel or 10)
		stroke(tabBar, C.Border, 1)
		local tl = Instance.new("UIListLayout")
		tl.FillDirection = Enum.FillDirection.Horizontal
		tl.Padding = UDim.new(0, 6)
		tl.VerticalAlignment = Enum.VerticalAlignment.Center
		tl.HorizontalAlignment = Enum.HorizontalAlignment.Left
		tl.Parent = tabBar
		pad(tabBar, 8, 8, 5, 5)

		local body = Instance.new("Frame")
		body.Name = "Body"
		body.Position = UDim2.fromOffset(0, 42)
		body.Size = UDim2.new(1, 0, 1, -42)
		body.BackgroundColor3 = C.Panel or C.BgDark
		body.BackgroundTransparency = C.PanelTransparency or 0.1
		body.BorderSizePixel = 0
		body.ClipsDescendants = true
		body.Parent = root
		corner(body, C.CornerPanel or 10)
		stroke(body, C.Border, 1)

		local el = wrap(root, "TabSelector")
		el._tabs = {}
		el.ActiveTab = nil
		el._tabBar = tabBar

		function el:CreateTab(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Tab"
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(math.clamp(#name * 8 + 28, 72, 160), 26)
			btn.BackgroundColor3 = C.TabIdle
			btn.Text = name
			btn.TextColor3 = C.TabTextIdle or C.TextDim
			btn.TextSize = 13
			btn.Font = Enum.Font.BuilderSansMedium
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent = tabBar
			corner(btn, C.CornerPill or 9)

			local page = Instance.new("ScrollingFrame")
			page.Name = "TabPage"
			page.Size = UDim2.new(1, -12, 1, -12)
			page.Position = UDim2.fromOffset(6, 6)
			page.BackgroundTransparency = 1
			page.BorderSizePixel = 0
			page.Visible = false
			page.ClipsDescendants = true
			page.ScrollBarThickness = 4
			page.ScrollBarImageColor3 = C.Border
			page.ScrollingDirection = Enum.ScrollingDirection.Y
			page.CanvasSize = UDim2.new(0, 0, 0, 0)
			page.AutomaticCanvasSize = Enum.AutomaticSize.Y
			page.Parent = body
			local pl = Instance.new("UIListLayout")
			pl.Padding = UDim.new(0, 8)
			pl.SortOrder = Enum.SortOrder.LayoutOrder
			pl.FillDirection = Enum.FillDirection.Vertical
			pl.Parent = page
			local pp = Instance.new("UIPadding")
			pp.PaddingTop = UDim.new(0, 6)
			pp.PaddingBottom = UDim.new(0, 14)
			pp.PaddingLeft = UDim.new(0, 6)
			pp.PaddingRight = UDim.new(0, 8)
			pp.Parent = page

			local tabEl = wrap(page, "Tab")
			tabEl._button = btn
			tabEl._name = name

			local function activate()
				for _, t in el._tabs do
					if t._button then
						t._button.BackgroundColor3 = C.TabIdle
						t._button.TextColor3 = C.TabTextIdle or C.TextDim
					end
					if t.Instance then t.Instance.Visible = false end
				end
				page.Visible = true
				btn.BackgroundColor3 = C.TabActive
				btn.TextColor3 = C.TabTextActive or Color3.fromRGB(28, 30, 40)
				el.ActiveTab = tabEl
			end
			btn.MouseButton1Click:Connect(activate)
			btn.MouseEnter:Connect(function()
				if el.ActiveTab ~= tabEl then
					btn.BackgroundColor3 = C.Select or C.BtnHover
				end
			end)
			btn.MouseLeave:Connect(function()
				if el.ActiveTab ~= tabEl then
					btn.BackgroundColor3 = C.TabIdle
				end
			end)
			if cfg.Focused or #el._tabs == 0 then
				task.defer(activate)
			end

			function tabEl:Remove()
				pcall(function() btn:Destroy() end)
				pcall(function() page:Destroy() end)
				for i, t in el._tabs do
					if t == tabEl then
						table.remove(el._tabs, i)
						break
					end
				end
				if el.ActiveTab == tabEl then
					el.ActiveTab = el._tabs[1]
					if el.ActiveTab then
						el.ActiveTab.Instance.Visible = true
						if el.ActiveTab._button then
							el.ActiveTab._button.BackgroundColor3 = C.TabActive
							el.ActiveTab._button.TextColor3 = C.TabTextActive or Color3.fromRGB(28, 30, 40)
						end
					end
				end
			end

			table.insert(el._tabs, tabEl)
			return tabEl
		end

		return el
	end


	if class == "InputText" then
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = config.Size or UDim2.new(1, 0, 0, 28)
		holder.BorderSizePixel = 0
		holder.Parent = host
		order(holder)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 1, 0)
		box.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
		box.BorderSizePixel = 0
		box.Text = tostring(config.Value or config.Text or "")
		box.PlaceholderText = config.Placeholder or "Search…"
		box.PlaceholderColor3 = Color3.fromRGB(120, 122, 132)
		box.TextColor3 = C.Text
		box.TextSize = 13
		box.Font = Enum.Font.BuilderSans
		box.ClearTextOnFocus = false
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.Parent = holder
		pcall(function() applyFont(box, "regular") end)
		corner(box, 6)
		stroke(box, Color3.fromRGB(55, 58, 68), 1)
		local ip = Instance.new("UIPadding")
		ip.PaddingLeft = UDim.new(0, 8)
		ip.PaddingRight = UDim.new(0, 8)
		ip.Parent = box
		if config.Callback then
			box:GetPropertyChangedSignal("Text"):Connect(function()
				pcall(config.Callback, box, box.Text)
			end)
		end
		return wrap(holder, "InputText")
	end

	if class == "InputInt" then
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, 0, 0, 24)
		holder.Parent = host
		order(holder)
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.new(0.55, 0, 1, 0)
		lab.Text = tostring(config.Label or config.Text or "")
		lab.TextColor3 = C.Text
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Font = Enum.Font.BuilderSans
		lab.TextSize = 12
		lab.Parent = holder
		pcall(function() applyFont(lab) end)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.4, 0, 0, 20)
		box.Position = UDim2.new(0.58, 0, 0, 2)
		box.BackgroundColor3 = C.CheckOff or C.Input
		box.TextColor3 = C.Text
		box.Text = tostring(config.Value or 0)
		box.Font = Enum.Font.BuilderSans
		box.TextSize = 12
		box.ClearTextOnFocus = false
		box.BorderSizePixel = 0
		box.Parent = holder
		corner(box, 3)
		pcall(function() applyFont(box) end)
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n == nil then
				box.Text = tostring(config.Value or 0)
				return
			end
			n = math.floor(n)
			box.Text = tostring(n)
			if config.Callback then
				pcall(config.Callback, n)
			end
		end)
		return wrap(holder, "InputInt")
	end

	
	if class == "Keybind" then
		return self:_create("Button", {
			Text = config.Label or config.Text or "Key",
			Callback = config.Callback,
			Size = UDim2.new(0, 56, 0, 22),
		})
	end

	if class == "Expand" then return self end

	if class == "ClearChildElements" then
		for _, c in host:GetChildren() do
			if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
				c:Destroy()
			end
		end
		return self
	end

	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 18)
	f.Parent = host
	return wrap(f, class)
end

for _, name in {
	"List", "Canvas", "Table", "Row", "NextRow", "NextColumn", "HeaderRow",
	"Label", "Button", "Selectable", "Checkbox", "InputText", "InputInt", "Separator", "CodeEditor",
	"Console", "BulletText", "Keybind", "TreeNode", "TabSelector",
} do
	Element[name] = function(self, config)
		return self:_create(name, config or {})
	end
end

function Element:Expand() return self end
function Element:ClearChildElements()
	return self:_create("ClearChildElements", {})
end
function Element:Center()
	local inst = self.Instance
	if not inst or not inst:IsA("GuiObject") then
		return self
	end
	pcall(function()
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local sz = inst.AbsoluteSize
		if sz.X < 2 or sz.Y < 2 then
			sz = Vector2.new(
				inst.Size.X.Offset > 0 and inst.Size.X.Offset or 560,
				inst.Size.Y.Offset > 0 and inst.Size.Y.Offset or 400
			)
		end
		inst.AnchorPoint = Vector2.new(0.5, 0.5)
		inst.Position = UDim2.fromOffset(
			math.floor(vs.X / 2),
			math.floor(vs.Y / 2)
		)
	end)
	return self
end
function Element:SetVisible(v) self.Instance.Visible = not not v end
function Element:SetTitle(t)
	local title = self.Instance:FindFirstChild("Title", true)
	if title and title:IsA("TextLabel") then title.Text = tostring(t) end
end
function Element:SetTheme() return self end
function Element:Close() self.Instance.Visible = false end
function Element:ClosePopup()
	local inst = self.Instance
	local p = inst.Parent
	if p and p.Name == "ModalDim" then p:Destroy() else inst.Visible = false end
end
function Element:Remove() self.Instance:Destroy() end

function Element:PopupModal(config)
	config = config or {}
	local screen = parentGui()
	local dim = Instance.new("Frame")
	dim.Name = "ModalDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.55
	dim.BorderSizePixel = 0
	dim.ZIndex = 50
	dim.Parent = screen

	local modal = Instance.new("Frame")
	modal.Size = UDim2.fromOffset(400, 190)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = C.Bg
	modal.ZIndex = 51
	modal.Parent = dim
	corner(modal, 8)
	stroke(modal, C.Border, 1)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 28)
	title.Position = UDim2.fromOffset(12, 8)
	title.BackgroundTransparency = 1
	title.Text = config.Title or "Wyvern Spy"
	title.TextColor3 = C.Text
	title.Font = Enum.Font.BuilderSansBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 52
	title.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(24, 22)
	closeBtn.Position = UDim2.new(1, -30, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 60)
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Color3.fromRGB(255, 210, 210)
	closeBtn.Font = Enum.Font.BuilderSansBold
	closeBtn.TextSize = 16
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 53
	closeBtn.Parent = modal
	corner(closeBtn, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(12, 40)
	content.Size = UDim2.new(1, -24, 1, -52)
	content.BackgroundTransparency = 1
	content.ZIndex = 52
	content.Parent = modal
	Instance.new("UIListLayout", content).Padding = UDim.new(0, 8)

	local el = wrap(modal, "Modal")
	local function close()
		dim:Destroy()
	end
	closeBtn.MouseButton1Click:Connect(close)
	
	dim.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local pos = input.Position
			local abs = modal.AbsolutePosition
			local size = modal.AbsoluteSize
			if pos.X < abs.X or pos.Y < abs.Y or pos.X > abs.X + size.X or pos.Y > abs.Y + size.Y then
				close()
			end
		end
	end)
	function el:ClosePopup() close() end
	function el:Close() close() end
	return el
end

function Element:PopupCanvas(config)
	config = config or {}
	local screen = parentGui()

	
	local catcher = Instance.new("TextButton")
	catcher.Name = "MenuCatcher"
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.ZIndex = 60
	catcher.Parent = screen

	local menu = Instance.new("Frame")
	menu.Name = "PopupMenu"
	menu.Size = UDim2.fromOffset(math.min(config.MaxSizeX or 220, 280), 0)
	menu.AutomaticSize = Enum.AutomaticSize.Y
	menu.BackgroundColor3 = C.Bg
	menu.BorderSizePixel = 0
	menu.ZIndex = 61
	menu.Parent = screen
	corner(menu, 6)
	stroke(menu, C.Border, 1)
	pad(menu, 4, 4, 4, 4)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = menu

	
	local rel = config.RelativeTo
	task.defer(function()
		if typeof(rel) == "Instance" and rel:IsA("GuiObject") then
			local abs = rel.AbsolutePosition
			local sz = rel.AbsoluteSize
			menu.Position = UDim2.fromOffset(abs.X, abs.Y + sz.Y + 4)
		elseif typeof(rel) == "table" and rel.Instance and rel.Instance:IsA("GuiObject") then
			local abs = rel.Instance.AbsolutePosition
			local sz = rel.Instance.AbsoluteSize
			menu.Position = UDim2.fromOffset(abs.X, abs.Y + sz.Y + 4)
		else
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
			menu.Position = UDim2.fromOffset(vp.X / 2 - 100, vp.Y / 2 - 40)
		end
	end)

	local el = wrap(menu, "PopupMenu")
	function el:_host() return menu end

	local function close()
		catcher:Destroy()
		menu:Destroy()
	end
	catcher.MouseButton1Click:Connect(close)

	
	local oldCreate = el._create
	function el:Selectable(cfg)
		cfg = cfg or {}
		local userCb = cfg.Callback
		cfg.Callback = function(...)
			close()
			if userCb then
				pcall(userCb, ...)
			end
		end
		cfg.Size = cfg.Size or UDim2.new(1, -4, 0, 24)
		return Element._create(self, "Selectable", cfg)
	end

	function el:ClosePopup() close() end
	function el:Close() close() end
	function el:Button(cfg)
		cfg = cfg or {}
		local userCb = cfg.Callback
		cfg.Callback = function(...)
			close()
			if userCb then pcall(userCb, ...) end
		end
		return Element._create(self, "Button", cfg)
	end

	return el
end

function WyvernUI:ApplyTheme(colors)
	mergeTheme(C, colors)
	-- keep aliases used by older widget code
	if C.Panel and not colors.Panel then
		-- ok
	end
	if colors and colors.Bg then
		C.Bg = colors.Bg
	end
	return C
end

function WyvernUI:GetColors()
	return C
end

function WyvernUI:Window(config)
	config = config or {}
	local screen = parentGui()
	local size = config.Size
	if not size then
		if self:IsMobileDevice() then
			local cam = workspace.CurrentCamera
			local vs = cam and cam.ViewportSize or Vector2.new(800, 600)
			size = UDim2.fromOffset(math.floor(vs.X * 0.94), math.floor(vs.Y * 0.72))
		else
			size = UDim2.fromOffset(820, 520)
		end
	end
	local minimized = false
	local ignoreDrag = false
	local fullSize = size
	-- normalize to offset so minimize/restore works
	if typeof(size) == "UDim2" and size.X.Offset == 0 and size.X.Scale > 0 then
		pcall(function()
			local vs = workspace.CurrentCamera.ViewportSize
			fullSize = UDim2.fromOffset(math.floor(vs.X * size.X.Scale), math.floor(vs.Y * size.Y.Scale))
			size = fullSize
		end)
	end

	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	if config.Centered then
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
	else
		frame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.12, 0)
	end
	frame.BackgroundColor3 = C.Bg
	frame.BackgroundTransparency = C.ShellTransparency or 0.05
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = false 
	frame.Parent = screen
	corner(frame, C.CornerWindow or 16)
	do
		local s = stroke(frame, C.Border, 1)
		if s then s.Transparency = 0.35 end
		-- soft highlight top edge
		local hi = Instance.new("Frame")
		hi.Name = "GlassHighlight"
		hi.Size = UDim2.new(1, -24, 0, 1)
		hi.Position = UDim2.fromOffset(12, 1)
		hi.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hi.BackgroundTransparency = 0.88
		hi.BorderSizePixel = 0
		hi.ZIndex = 3
		hi.Parent = frame
	end
	pcall(function()
		local depth = Instance.new("Frame")
		depth.Name = "Depth"
		depth.Size = UDim2.new(1, 10, 1, 10)
		depth.Position = UDim2.fromOffset(-5, -3)
		depth.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		depth.BackgroundTransparency = 0.7
		depth.BorderSizePixel = 0
		depth.ZIndex = 0
		depth.Parent = frame
		corner(depth, (C.CornerWindow or 16) + 2)
		frame.ZIndex = 1
	end)
	frame.ClipsDescendants = true
	frame.AutomaticSize = Enum.AutomaticSize.None

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = C.Title
	titleBar.BackgroundTransparency = 0.08
	titleBar.BorderSizePixel = 0
	titleBar.Active = true
	titleBar.Parent = frame
	corner(titleBar, C.CornerWindow or 14)
	
	local titleMask = Instance.new("Frame")
	titleMask.Size = UDim2.new(1, 0, 0, 12)
	titleMask.Position = UDim2.new(0, 0, 1, -12)
	titleMask.BackgroundColor3 = C.Title
	titleMask.BorderSizePixel = 0
	titleMask.Parent = titleBar

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.fromOffset(30, 30)
	logo.Position = UDim2.fromOffset(10, 5)
	logo.BackgroundTransparency = 1
	logo.BorderSizePixel = 0
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Parent = titleBar
	local logoAsset = config.LogoAsset or WyvernUI.LogoAsset
	if logoAsset and logoAsset ~= "" then
		logo.Image = logoAsset
	end

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -130, 1, 0)
	title.Position = UDim2.fromOffset(46, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title or self.DefaultTitle
	title.TextColor3 = C.Text
	title.Font = Enum.Font.BuilderSansMedium
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
	applyFont(title, "medium")

	
	do
		local UIS = game:GetService("UserInputService")
		local dragging = false
		local dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if ignoreDrag then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				-- don't start drag from control buttons
				local p = input.Position
				local abs = titleBar.AbsolutePosition
				local asz = titleBar.AbsoluteSize
				if p.X > abs.X + asz.X - 90 then
					return
				end
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
			end
		end)
		titleBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - dragStart
				frame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	local statusChip = Instance.new("TextButton")
	statusChip.Name = "StatusChip"
	statusChip.Size = UDim2.fromOffset(0, 22)
	statusChip.AutomaticSize = Enum.AutomaticSize.X
	statusChip.Position = UDim2.new(1, -200, 0.5, -11)
	statusChip.BackgroundColor3 = Color3.fromRGB(48, 22, 26)
	statusChip.BackgroundTransparency = 1
	statusChip.Text = ""
	statusChip.TextColor3 = Color3.fromRGB(255, 160, 165)
	statusChip.TextSize = 11
	statusChip.Font = Enum.Font.BuilderSansMedium
	statusChip.Visible = false
	statusChip.AutoButtonColor = true
	statusChip.BorderSizePixel = 0
	statusChip.Parent = titleBar
	corner(statusChip, 6)
	local scPad = Instance.new("UIPadding")
	scPad.PaddingLeft = UDim.new(0, 10)
	scPad.PaddingRight = UDim.new(0, 10)
	scPad.Parent = statusChip
	local scCorner = Instance.new("UICorner")
	scCorner.CornerRadius = UDim.new(0, 6)
	scCorner.Parent = statusChip

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(34, 26)
	minBtn.Position = UDim2.new(1, -82, 0, 8)
	minBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
	minBtn.BackgroundTransparency = 0.35
	minBtn.Text = "─"
	minBtn.TextColor3 = Color3.fromRGB(210, 212, 220)
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 16
	minBtn.BorderSizePixel = 0
	minBtn.AutoButtonColor = false
	minBtn.Parent = titleBar
	corner(minBtn, 6)
	minBtn.MouseEnter:Connect(function()
		minBtn.BackgroundTransparency = 0.05
		minBtn.BackgroundColor3 = Color3.fromRGB(55, 58, 70)
	end)
	minBtn.MouseLeave:Connect(function()
		minBtn.BackgroundTransparency = 0.35
		minBtn.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
	end)

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(36, 28)
	close.Position = UDim2.new(1, -42, 0, 6)
	close.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
	close.BackgroundTransparency = 0.35
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(230, 200, 200)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.BorderSizePixel = 0
	close.AutoButtonColor = false
	close.Parent = titleBar
	corner(close, 6)
	close.MouseEnter:Connect(function()
		close.BackgroundTransparency = 0
		close.BackgroundColor3 = Color3.fromRGB(180, 55, 65)
		close.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
	close.MouseLeave:Connect(function()
		close.BackgroundTransparency = 0.35
		close.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
		close.TextColor3 = Color3.fromRGB(230, 200, 200)
	end)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(0, 40)
	content.Size = UDim2.new(1, 0, 1, -40)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Active = false
	content.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
	pcall(function()
		layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
		layout.VerticalFlex = Enum.UIFlexAlignment.Fill
	end)
	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 8)
	contentPad.PaddingRight = UDim.new(0, 8)
	contentPad.PaddingTop = UDim.new(0, 6)
	contentPad.PaddingBottom = UDim.new(0, 6)
	contentPad.Parent = content

	local win = wrap(frame, "Window")
	function win:_host() return content end
	win._hostOverride = content

		local function animateSize(targetSize, duration)
		duration = duration or 0.22
		local ok = pcall(function()
			local TS = game:GetService("TweenService")
			local tw = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TS:Create(frame, tw, { Size = targetSize }):Play()
		end)
		if not ok then
			frame.Size = targetSize
		end
		-- always hard-set at end so size is correct even if tween is ignored
		task.delay(duration + 0.02, function()
			pcall(function() frame.Size = targetSize end)
		end)
	end

	local function setMinimized(v)
		minimized = not not v
		local abs = frame.AbsoluteSize
		local curW = math.max(abs.X, 180)
		local curH = math.max(abs.Y, 40)
		local isMobile = false
		pcall(function() isMobile = WyvernUI:IsMobileDevice() end)

		if minimized then
			if curH > 44 then
				fullSize = UDim2.fromOffset(curW, curH)
			end
			minBtn.Text = "□"
			minBtn.Size = UDim2.fromOffset(26, 22)
			minBtn.Position = UDim2.new(1, -60, 0.5, -11)
			close.Size = UDim2.fromOffset(26, 22)
			close.Position = UDim2.new(1, -30, 0.5, -11)
			close.TextSize = 14
			minBtn.TextSize = 12
			content.Visible = false
			content.Size = UDim2.new(1, 0, 0, 0)
			if grab then grab.Visible = false end
			if titleMask then titleMask.Visible = false end
			titleBar.Size = UDim2.new(1, 0, 1, 0)

			local barH = isMobile and 34 or 40
			local barW = isMobile and math.clamp(math.floor(curW * 0.5), 150, 260) or math.clamp(curW, 220, 480)
			animateSize(UDim2.fromOffset(barW, barH), 0.22)
		else
			minBtn.Text = "─"
			minBtn.Size = UDim2.fromOffset(36, 28)
			minBtn.Position = UDim2.new(1, -84, 0, 6)
			close.Size = UDim2.fromOffset(36, 28)
			close.Position = UDim2.new(1, -42, 0, 6)
			close.TextSize = 18
			minBtn.TextSize = 16
			if titleMask then titleMask.Visible = true end
			titleBar.Size = UDim2.new(1, 0, 0, 40)
			content.Visible = true
			content.Size = UDim2.new(1, 0, 1, -40)
			if grab then grab.Visible = true end
			local target = fullSize
			if typeof(target) ~= "UDim2" or (target.X.Offset < 100 and target.Y.Offset < 100) then
				if isMobile then
					local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
					target = UDim2.fromOffset(math.floor(vs.X * 0.94), math.floor(vs.Y * 0.72))
				else
					target = UDim2.fromOffset(820, 520)
				end
				fullSize = target
			end
			animateSize(target, 0.22)
		end
	end

local function bindBtn(btn, fn)
		btn.ZIndex = 10
		btn.Active = true
		btn.AutoButtonColor = true
		btn.MouseButton1Click:Connect(fn)
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				ignoreDrag = true
			end
		end)
		btn.InputEnded:Connect(function()
			ignoreDrag = false
		end)
	end

	bindBtn(minBtn, function()
		setMinimized(not minimized)
	end)
	bindBtn(close, function()
		pcall(function()
			frame.Visible = false
			-- destroy non-main windows so they don't linger invisible
			if config.DestroyOnClose or config.Title and tostring(config.Title):find("Editing:") then
				frame:Destroy()
			end
		end)
	end)

	
	local grab = Instance.new("TextButton")
	grab.Name = "ResizeGrab"
	grab.Size = UDim2.fromOffset(16, 16)
	grab.Position = UDim2.new(1, -16, 1, -16)
	grab.BackgroundColor3 = C.Border
	grab.BackgroundTransparency = 0.3
	grab.Text = ""
	grab.BorderSizePixel = 0
	grab.ZIndex = 5
	grab.Parent = frame
	corner(grab, 3)
	local dragging = false
	local startPos, startSize
	grab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = input.Position
			startSize = frame.AbsoluteSize
		end
	end)
	grab.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			fullSize = frame.Size
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or minimized then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - startPos
			local nx = math.clamp(startSize.X + delta.X, 420, 1200)
			local ny = math.clamp(startSize.Y + delta.Y, 280, 900)
			frame.Size = UDim2.fromOffset(nx, ny)
			fullSize = frame.Size
		end
	end)

	function win:SetVisible(v)
		frame.Visible = not not v
	end
	function win:Center()
		pcall(function()
			local cam = workspace.CurrentCamera
			local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromOffset(math.floor(vs.X / 2), math.floor(vs.Y / 2))
		end)
		return self
	end
	function win:Close()
		pcall(function()
			frame.Visible = false
			frame:Destroy()
		end)
	end
	function win:Minimize()
		setMinimized(true)
	end
	function win:Restore()
		setMinimized(false)
	end


	-- Boot open animation
	do
		local finalSize = frame.Size
		local finalPos = frame.Position
		if config.Centered then
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			pcall(function()
				local cam = workspace.CurrentCamera
				local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
				finalPos = UDim2.fromOffset(math.floor(vs.X / 2), math.floor(vs.Y / 2))
				frame.Position = finalPos
			end)
		end
		local startSize = UDim2.fromOffset(
			math.max(80, math.floor((finalSize.X.Offset > 0 and finalSize.X.Offset or 820) * 0.7)),
			math.max(60, math.floor((finalSize.Y.Offset > 0 and finalSize.Y.Offset or 520) * 0.7))
		)
		frame.Size = startSize
		frame.Position = UDim2.new(
			finalPos.X.Scale,
			finalPos.X.Offset + math.floor(((finalSize.X.Offset > 0 and finalSize.X.Offset or 820) - startSize.X.Offset) / 2),
			finalPos.Y.Scale,
			finalPos.Y.Offset + 40
		)
		frame.BackgroundTransparency = 0.55
		task.spawn(function()
			pcall(function()
				local TS = game:GetService("TweenService")
				local tw = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				TS:Create(frame, tw, {
					Size = finalSize,
					Position = finalPos,
					BackgroundTransparency = 0,
				}):Play()
			end)
			task.wait(0.4)
			pcall(function()
				frame.Size = finalSize
				frame.Position = finalPos
				frame.BackgroundTransparency = 0
			end)
		end)
	end

	table.insert(self.Windows, win)
	return win
end

return WyvernUI
