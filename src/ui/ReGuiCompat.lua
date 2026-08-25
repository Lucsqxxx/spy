--[[
	ReGuiCompat v3 – closer to original Sigma Spy / Dear-ReGui look
	Reference: dark navy, left remote list, Editor/Options/Remote tabs
]]

local ReGui = {
	Version = "compat-3.0",
	DefaultTitle = "Sigma Spy",
	Themes = {},
	Windows = {},
	Initialised = true,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Palette from screenshots
local C = {
	Bg = Color3.fromRGB(30, 34, 46),
	BgDark = Color3.fromRGB(22, 25, 35),
	Title = Color3.fromRGB(38, 44, 60),
	Border = Color3.fromRGB(58, 68, 92),
	Text = Color3.fromRGB(205, 210, 225),
	TextDim = Color3.fromRGB(130, 140, 165),
	Accent = Color3.fromRGB(80, 130, 200),
	Btn = Color3.fromRGB(50, 70, 110),
	BtnHover = Color3.fromRGB(65, 90, 140),
	Select = Color3.fromRGB(40, 70, 120),
	SelectActive = Color3.fromRGB(55, 100, 170),
	Input = Color3.fromRGB(16, 18, 26),
	Check = Color3.fromRGB(70, 140, 220),
	Green = Color3.fromRGB(90, 210, 130),
	TabActive = Color3.fromRGB(45, 75, 130),
	TabIdle = Color3.fromRGB(35, 40, 55),
	RowAlt = Color3.fromRGB(26, 30, 42),
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
		frame.Size = config.Size or UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
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
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.Parent = host
		order(frame)
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 2)
		layout.Parent = frame
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
		btn.Size = config.Size or UDim2.new(0, 100, 0, 26)
		btn.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		btn.BackgroundColor3 = C.Btn
		btn.TextColor3 = C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamMedium
		btn.Text = tostring(config.Text or config.Label or "Button")
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Parent = host
		order(btn)
		corner(btn, 4)
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
		local scroll = Instance.new("ScrollingFrame")
		if config.Fill then
			scroll.Size = UDim2.new(1, 0, 1, -32)
		else
			scroll.Size = config.Size or UDim2.new(1, 0, 0, 160)
		end
		scroll.BackgroundColor3 = C.Input
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 5
		scroll.ScrollBarImageColor3 = C.Border
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -4, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundTransparency = 1
		box.TextColor3 = Color3.fromRGB(175, 220, 185)
		box.PlaceholderColor3 = C.TextDim
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.TextSize = config.FontSize or 13
		box.Font = Enum.Font.Code
		box.ClearTextOnFocus = false
		box.MultiLine = true
		box.TextWrapped = true
		box.Text = config.Text or ""
		box.TextEditable = (config.Editable ~= false) and not config.ReadOnly
		box.Parent = scroll
		local el = wrap(scroll, class)
		el.Enabled = config.Enabled ~= false
		el._box = box
		el._lines = {}
		function el:GetText() return box.Text end
		function el:GetValue() return box.Text end
		function el:SetText(t)
			box.Text = tostring(t or "")
			el._lines = {}
		end
		function el:Clear()
			box.Text = ""
			el._lines = {}
		end
		function el:AppendText(...)
			if not el.Enabled then return end
			local parts = {...}
			for i = 1, #parts do parts[i] = tostring(parts[i]) end
			table.insert(el._lines, table.concat(parts, " "))
			local maxL = config.MaxLines or 200
			while #el._lines > maxL do table.remove(el._lines, 1) end
			box.Text = table.concat(el._lines, "\n")
		end
		return el
	end

	-------------------------------------------------------------------- TreeNode
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
			page.Parent = body
			local pl = Instance.new("UIListLayout")
			pl.Padding = UDim.new(0, 5)
			pl.SortOrder = Enum.SortOrder.LayoutOrder
			pl.FillDirection = Enum.FillDirection.Vertical
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
	dim.Parent = screen
	local modal = Instance.new("Frame")
	modal.Size = UDim2.fromOffset(400, 190)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = C.Bg
	modal.Parent = dim
	corner(modal, 8)
	stroke(modal, C.Border, 1)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(12, 8)
	title.BackgroundTransparency = 1
	title.Text = config.Title or "Sigma Spy"
	title.TextColor3 = C.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = modal
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(12, 40)
	content.Size = UDim2.new(1, -24, 1, -52)
	content.BackgroundTransparency = 1
	content.Parent = modal
	Instance.new("UIListLayout", content).Padding = UDim.new(0, 8)
	return wrap(modal, "Modal")
end
function Element:PopupCanvas(config) return self:PopupModal(config) end

function ReGui:Window(config)
	config = config or {}
	local screen = parentGui()
	local size = config.Size or UDim2.fromOffset(720, 460)

	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.12, 0)
	frame.BackgroundColor3 = C.Bg
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen
	corner(frame, 6)
	stroke(frame, C.Border, 1)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 28)
	titleBar.BackgroundColor3 = C.Title
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	-- orange accent dot like original
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.fromOffset(10, 10)
	dot.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
	dot.BorderSizePixel = 0
	dot.Parent = titleBar
	corner(dot, 4)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.fromOffset(24, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title or self.DefaultTitle
	title.TextColor3 = C.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(24, 20)
	close.Position = UDim2.new(1, -28, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(100, 50, 60)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 210, 210)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.BorderSizePixel = 0
	close.Parent = titleBar
	corner(close, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(6, 32)
	content.Size = UDim2.new(1, -12, 1, -38)
	content.BackgroundTransparency = 1
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
	close.MouseButton1Click:Connect(function() frame.Visible = false end)
	table.insert(self.Windows, win)
	return win
end

return ReGui
