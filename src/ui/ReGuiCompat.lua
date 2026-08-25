--[[
	ReGuiCompat v3 – closer to original Sigma Spy / Dear-ReGui look
	Reference: dark navy, left remote list, Editor/Options/Remote tabs
]]

local ReGui = {
	Version = "compat-3.1",
	DefaultTitle = "Sigma Spy",
	Themes = {},
	Windows = {},
	Initialised = true,
	DefaultFont = Font.fromEnum(Enum.Font.Code),
	DefaultTextSize = 13,
}

function ReGui:SetFont(fontFace, textSize)
	if fontFace then
		self.DefaultFont = fontFace
	end
	if textSize then
		self.DefaultTextSize = textSize
	end
end

local function applyFont(gui)
	pcall(function()
		gui.FontFace = ReGui.DefaultFont
	end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Palette from screenshots
local C = {
	-- Matched to original Sigma Spy / ImGui screenshot
	Bg = Color3.fromRGB(24, 28, 38),
	BgDark = Color3.fromRGB(18, 20, 28),
	Title = Color3.fromRGB(45, 85, 145),      -- blue title bar
	TitleBot = Color3.fromRGB(35, 65, 115),
	Border = Color3.fromRGB(50, 70, 110),
	Text = Color3.fromRGB(220, 225, 235),
	TextDim = Color3.fromRGB(130, 140, 160),
	Accent = Color3.fromRGB(90, 150, 220),
	Btn = Color3.fromRGB(40, 70, 120),
	BtnHover = Color3.fromRGB(55, 95, 160),
	Select = Color3.fromRGB(35, 65, 110),
	SelectActive = Color3.fromRGB(50, 100, 170),
	Input = Color3.fromRGB(14, 16, 22),
	Check = Color3.fromRGB(70, 140, 220),
	Green = Color3.fromRGB(80, 220, 120),
	TabActive = Color3.fromRGB(50, 95, 160),
	TabIdle = Color3.fromRGB(32, 40, 55),
	RowAlt = Color3.fromRGB(22, 26, 36),
	LineNum = Color3.fromRGB(90, 100, 120),
}

function ReGui:CheckConfig(Target, Defaults)
	if typeof(Target) ~= "table" then return Target end
	for k, v in Defaults do
		if Target[k] == nil then
			Target[k] = typeof(v) == "function" and v() or v
		end
	end
	return Target
end

function ReGui:DefineTheme(Name, Config)
	self.Themes[Name] = Config or {}
end

function ReGui:IsMobileDevice()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function ReGui:CheckImportState() end

local function parentGui()
	local screen = CoreGui:FindFirstChild("SigmaSpyUI")
	if screen then return screen end
	screen = Instance.new("ScreenGui")
	screen.Name = "SigmaSpyUI"
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
	c.CornerRadius = UDim.new(0, r or 4)
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
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- ============== Element ==============
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
	local inst = self.Instance
	local content = inst:FindFirstChild("Content")
	if content then return content end
	return inst
end

function Element:_create(class, config)
	config = config or {}
	local host = self:_host()

	local function order(gui)
		if config.LayoutOrder then gui.LayoutOrder = config.LayoutOrder end
	end

	-------------------------------------------------------------------- List / Canvas
	if class == "List" or class == "Canvas" then
		local scroll = config.Scroll or class == "Canvas"
		local frame
		if scroll then
			frame = Instance.new("ScrollingFrame")
			frame.ScrollBarThickness = 3
			frame.ScrollBarImageColor3 = C.Border
			frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			frame.CanvasSize = UDim2.new()
			frame.BackgroundColor3 = C.BgDark
			frame.BackgroundTransparency = 0
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
		corner(frame, 4)
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

	-------------------------------------------------------------------- Table
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
		corner(frame, 4)
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

	-------------------------------------------------------------------- Row
	if class == "Row" or class == "HeaderRow" or class == "NextRow" then
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 0, 28)
		frame.AutomaticSize = Enum.AutomaticSize.None
		frame.ClipsDescendants = true
		-- alternating row bg for tables
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

	-------------------------------------------------------------------- Column
	if class == "NextColumn" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(0, 140, 0, 0)
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

	-------------------------------------------------------------------- Label
	if class == "Label" then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0, 0, 0, 18)
		label.AutomaticSize = Enum.AutomaticSize.XY
		label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextColor3 = config.TextColor3 or C.Text
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextWrapped = config.TextWrapped == true
		label.RichText = config.RichText or false
		label.Text = tostring(config.Text or "")
		label.Parent = host
		order(label)
		applyFont(label)
		return wrap(label, "Label")
	end

	-------------------------------------------------------------------- BulletText
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
		label.Font = Enum.Font.Gotham
		label.TextWrapped = true
		label.Text = table.concat(lines, "\n")
		label.Parent = host
		order(label)
		return wrap(label, "BulletText")
	end

	-------------------------------------------------------------------- Separator
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
			t.Font = Enum.Font.GothamBold
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

	-------------------------------------------------------------------- Button
	if class == "Button" then
		local btn = Instance.new("TextButton")
		local sz = config.Size
		-- Prevent UDim2.new(1,0,*) from blowing past the window in horizontal rows
		if sz and sz.X.Scale >= 1 and sz.X.Offset == 0 then
			sz = UDim2.new(0, 120, 0, sz.Y.Offset > 0 and sz.Y.Offset or 26)
		end
		btn.Size = sz or UDim2.new(0, 100, 0, 26)
		btn.AutomaticSize = Enum.AutomaticSize.None
		btn.BackgroundColor3 = C.Btn
		btn.TextColor3 = C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamMedium
		btn.Text = tostring(config.Text or config.Label or "Button")
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Parent = host
		order(btn)
		corner(btn, 4)
		applyFont(btn)
		-- Equal-width flex in horizontal rows when requested
		if config.FlexFill then
			pcall(function()
				local flex = Instance.new("UIFlexItem")
				flex.FlexMode = Enum.UIFlexMode.Fill
				flex.Parent = btn
			end)
		end
		local el = wrap(btn, "Button")
		if config.Callback then
			btn.MouseButton1Click:Connect(function()
				pcall(config.Callback, el)
			end)
		end
		function el:Remove() btn:Destroy() end
		return el
	end

	-------------------------------------------------------------------- Selectable (remote list items)
	if class == "Selectable" then
		local btn = Instance.new("TextButton")
		btn.Size = config.Size or UDim2.new(1, -2, 0, 18)
		btn.BackgroundColor3 = C.BgDark
		btn.BackgroundTransparency = 1
		btn.TextColor3 = config.TextColor3 or C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.Code
		btn.Text = tostring(config.Text or "")
		btn.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = host
		order(btn)
		pad(btn, 6, 4, 0, 0)
		applyFont(btn)
		local el = wrap(btn, "Selectable")
		el._btn = btn
		function el:SetSelected(v)
			el._selected = not not v
			if el._selected then
				btn.BackgroundTransparency = 0
				btn.BackgroundColor3 = C.SelectActive
			else
				btn.BackgroundTransparency = 1
			end
		end
		function el:Remove() btn:Destroy() end
		btn.MouseEnter:Connect(function()
			if not el._selected then
				btn.BackgroundTransparency = 0.5
				btn.BackgroundColor3 = C.Select
			end
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

	-------------------------------------------------------------------- Checkbox (screenshot style)
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
		box.TextColor3 = Color3.new(1, 1, 1)
		box.TextSize = 12
		box.Font = Enum.Font.GothamBold
		box.BorderSizePixel = 0
		box.AutoButtonColor = false
		box.Parent = holder
		corner(box, 3)
		stroke(box, C.Border, 1)

		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.new(0, 0, 0, 18)
		lab.AutomaticSize = Enum.AutomaticSize.X
		lab.Text = tostring(config.Label or config.Text or "")
		lab.TextColor3 = C.Text
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Font = Enum.Font.Gotham
		lab.TextSize = 13
		lab.Parent = holder

		local state = not not config.Value
		local function paint()
			if state then
				box.BackgroundColor3 = C.Check
				box.Text = "✓"
			else
				box.BackgroundColor3 = C.Input
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

	-------------------------------------------------------------------- CodeEditor / Console
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
				-- long comment --[[ ]]
				if src:sub(i, i + 3) == "--[[" then
					local j = src:find("%]%]", i + 4) or n
					if src:sub(j, j + 1) == "]]" then j = j + 1 end
					table.insert(out, '<font color="' .. COL.comment .. '">' .. escapeRich(src:sub(i, j)) .. "</font>")
					i = j + 1
				-- line comment
				elseif src:sub(i, i + 1) == "--" then
					local j = src:find("\n", i) or (n + 1)
					table.insert(out, '<font color="' .. COL.comment .. '">' .. escapeRich(src:sub(i, j - 1)) .. "</font>")
					i = j
				-- strings
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
				-- long string [[ ]]
				elseif src:sub(i, i + 1) == "[[" then
					local j = src:find("%]%]", i + 2) or n
					if src:sub(j, j + 1) == "]]" then j = j + 1 end
					table.insert(out, '<font color="' .. COL.string .. '">' .. escapeRich(src:sub(i, j)) .. "</font>")
					i = j + 1
				-- number
				elseif ch:match("%d") then
					local j = i
					while j <= n and src:sub(j, j):match("[%d%.xXa-fA-F]") do
						j += 1
					end
					table.insert(out, '<font color="' .. COL.number .. '">' .. escapeRich(src:sub(i, j - 1)) .. "</font>")
					i = j
				-- identifier / keyword
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
			scroll.Size = UDim2.new(1, 0, 1, -34)
			scroll.AutomaticSize = Enum.AutomaticSize.None
		else
			scroll.Size = config.Size or UDim2.new(1, 0, 0, 160)
		end
		scroll.BackgroundColor3 = (typeof(colors.Background) == "Color3" and colors.Background) or C.Input
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 6
		scroll.ScrollBarImageColor3 = C.Border
		scroll.ScrollingDirection = Enum.ScrollingDirection.XY
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = host
		order(scroll)
		corner(scroll, 4)
		stroke(scroll, C.Border, 1)
		pad(scroll, 8, 8, 6, 6)
		if config.Fill then
			pcall(function()
				local flex = Instance.new("UIFlexItem")
				flex.FlexMode = Enum.UIFlexMode.Fill
				flex.Parent = scroll
			end)
		end

		-- Line number gutter + editor row
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

		local lineBox = Instance.new("TextLabel")
		lineBox.Name = "LineNumbers"
		lineBox.BackgroundTransparency = 1
		lineBox.Size = UDim2.new(0, 36, 0, 0)
		lineBox.AutomaticSize = Enum.AutomaticSize.Y
		lineBox.TextXAlignment = Enum.TextXAlignment.Right
		lineBox.TextYAlignment = Enum.TextYAlignment.Top
		lineBox.TextColor3 = C.LineNum
		lineBox.TextSize = config.FontSize or 13
		lineBox.Font = Enum.Font.Code
		applyFont(lineBox)
		lineBox.Text = "1"
		lineBox.Parent = row

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0, 0, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.XY
		box.BackgroundTransparency = 1
		box.TextColor3 = (typeof(colors.Text) == "Color3" and colors.Text) or Color3.fromRGB(200, 210, 220)
		box.PlaceholderColor3 = C.TextDim
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.TextSize = config.FontSize or 13
		box.Font = Enum.Font.Code
		applyFont(box)
		box.ClearTextOnFocus = false
		box.MultiLine = true
		box.TextWrapped = false -- allow horizontal scroll
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

		-- initial highlight
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
		root.BackgroundTransparency = 1
		root.Size = UDim2.new(1, 0, 0, 0)
		root.AutomaticSize = Enum.AutomaticSize.Y
		root.Parent = host
		order(root)

		local header = Instance.new("TextButton")
		header.Size = UDim2.new(1, 0, 0, 18)
		header.BackgroundTransparency = 1
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Font = Enum.Font.GothamBold
		header.TextSize = 12
		header.TextColor3 = C.Text
		header.AutoButtonColor = false
		header.Parent = root

		local open = true
		local title = tostring(config.Title or config.Text or "Node")
		local function refresh()
			header.Text = (open and "▼  " or "▶  ") .. title
		end
		refresh()

		local body = Instance.new("Frame")
		body.Name = "Content"
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromOffset(8, 18)
		body.Size = UDim2.new(1, -8, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.Visible = open
		body.Parent = root
		local bl = Instance.new("UIListLayout")
		bl.Padding = UDim.new(0, 1)
		bl.SortOrder = Enum.SortOrder.LayoutOrder
		bl.Parent = body

		header.MouseButton1Click:Connect(function()
			open = not open
			body.Visible = open
			refresh()
		end)

		local el = wrap(root, "TreeNode")
		function el:_host() return body end
		function el:Remove() root:Destroy() end
		return el
	end

	-------------------------------------------------------------------- TabSelector
	if class == "TabSelector" then
		local root = Instance.new("Frame")
		root.BackgroundTransparency = 1
		root.Size = config.Size or UDim2.new(1, 0, 1, 0)
		root.Parent = host
		order(root)

		local tabBar = Instance.new("Frame")
		tabBar.Size = UDim2.new(1, 0, 0, 26)
		tabBar.BackgroundColor3 = C.BgDark
		tabBar.BorderSizePixel = 0
		tabBar.Parent = root
		corner(tabBar, 4)
		local tl = Instance.new("UIListLayout")
		tl.FillDirection = Enum.FillDirection.Horizontal
		tl.Padding = UDim.new(0, 2)
		tl.VerticalAlignment = Enum.VerticalAlignment.Center
		tl.Parent = tabBar
		pad(tabBar, 4, 4, 2, 2)

		local body = Instance.new("Frame")
		body.Name = "Body"
		body.Position = UDim2.fromOffset(0, 28)
		body.Size = UDim2.new(1, 0, 1, -28)
		body.BackgroundColor3 = C.BgDark
		body.BorderSizePixel = 0
		body.ClipsDescendants = true
		body.Parent = root
		corner(body, 4)
		stroke(body, C.Border, 1)

		local el = wrap(root, "TabSelector")
		el._tabs = {}
		el.ActiveTab = nil

		function el:CreateTab(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Tab"
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(math.clamp(#name * 7 + 18, 56, 200), 22)
			btn.BackgroundColor3 = C.TabIdle
			btn.Text = name
			btn.TextColor3 = C.Text
			btn.TextSize = 12
			btn.Font = Enum.Font.Gotham
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			btn.Parent = tabBar
			corner(btn, 3)

			local page = Instance.new("Frame")
			page.Size = UDim2.new(1, -10, 1, -10)
			page.Position = UDim2.fromOffset(5, 5)
			page.BackgroundTransparency = 1
			page.Visible = false
			page.ClipsDescendants = true
			page.Parent = body
			local pl = Instance.new("UIListLayout")
			pl.Padding = UDim.new(0, 5)
			pl.SortOrder = Enum.SortOrder.LayoutOrder
			pl.FillDirection = Enum.FillDirection.Vertical
			pl.VerticalAlignment = Enum.VerticalAlignment.Top
			pl.Parent = page
			pcall(function()
				pl.VerticalFlex = Enum.UIFlexAlignment.Fill
			end)

			local tabEl = wrap(page, "Tab")
			tabEl._name = name
			tabEl._button = btn
			table.insert(el._tabs, tabEl)

			local function activate()
				for _, t in el._tabs do
					t.Instance.Visible = false
					if t._button then t._button.BackgroundColor3 = C.TabIdle end
				end
				page.Visible = true
				btn.BackgroundColor3 = C.TabActive
				el.ActiveTab = tabEl
			end
			btn.MouseButton1Click:Connect(activate)
			if cfg.Focused or #el._tabs == 1 then activate() end

			function tabEl:Remove()
				btn:Destroy()
				page:Destroy()
			end
			return tabEl
		end

		function el:RemoveTab(tab)
			if not tab then return end
			for i, t in el._tabs do
				if t == tab or (tab.Instance and t.Instance == tab.Instance) then
					table.remove(el._tabs, i)
					break
				end
			end
			pcall(function() tab:Remove() end)
			if el.ActiveTab == tab then
				el.ActiveTab = el._tabs[1]
				if el.ActiveTab then
					el.ActiveTab.Instance.Visible = true
					if el.ActiveTab._button then
						el.ActiveTab._button.BackgroundColor3 = C.TabActive
					end
				end
			end
		end

		function el:CompareTabs(a, b)
			return a == b or (a and b and a.Instance == b.Instance)
		end

		return el
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
	"Label", "Button", "Selectable", "Checkbox", "Separator", "CodeEditor",
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
	if inst:IsA("GuiObject") then
		inst.AnchorPoint = Vector2.new(0.5, 0.5)
		inst.Position = UDim2.fromScale(0.5, 0.5)
	end
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
	title.Text = config.Title or "Sigma Spy"
	title.TextColor3 = C.Text
	title.Font = Enum.Font.GothamBold
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
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 53
	closeBtn.Parent = modal
	corner(closeBtn, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
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
	-- click dim background to close
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

-- Context menu for Script / Build buttons (closes on pick or outside click)
function Element:PopupCanvas(config)
	config = config or {}
	local screen = parentGui()

	-- full-screen invisible catcher
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

	-- position near RelativeTo button if provided
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

	-- wrap Selectable to auto-close after click
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

function ReGui:Window(config)
	config = config or {}
	local screen = parentGui()
	local size = config.Size or UDim2.fromOffset(760, 480)
	local minimized = false
	local fullSize = size

	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.1, 0)
	frame.BackgroundColor3 = C.Bg
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen
	corner(frame, 4)
	stroke(frame, C.Border, 1)

	-- Blue title bar (screenshot style)
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 26)
	titleBar.BackgroundColor3 = C.Title
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	-- minimize (collapse) arrow on left
	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(22, 20)
	minBtn.Position = UDim2.fromOffset(4, 3)
	minBtn.BackgroundTransparency = 1
	minBtn.Text = "▼"
	minBtn.TextColor3 = C.Text
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 12
	minBtn.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Position = UDim2.fromOffset(28, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title or self.DefaultTitle
	title.TextColor3 = Color3.fromRGB(235, 240, 250)
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(24, 20)
	close.Position = UDim2.new(1, -28, 0, 3)
	close.BackgroundColor3 = Color3.fromRGB(180, 60, 70)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 230, 230)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.BorderSizePixel = 0
	close.Parent = titleBar
	corner(close, 3)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(6, 30)
	content.Size = UDim2.new(1, -12, 1, -36)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content
	pcall(function()
		layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
		layout.VerticalFlex = Enum.UIFlexAlignment.Fill
	end)

	local win = wrap(frame, "Window")
	function win:_host() return content end

	local function setMinimized(v)
		minimized = v
		content.Visible = not minimized
		if minimized then
			minBtn.Text = "▶"
			frame.Size = UDim2.fromOffset(fullSize.X.Offset, 26)
		else
			minBtn.Text = "▼"
			frame.Size = fullSize
		end
	end

	minBtn.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	function win:SetVisible(v)
		frame.Visible = not not v
	end
	function win:Minimize()
		setMinimized(true)
	end
	function win:Restore()
		setMinimized(false)
	end

	table.insert(self.Windows, win)
	return win
end

return ReGui
