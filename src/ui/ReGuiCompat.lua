--[[
	ReGuiCompat v2 – visual style closer to Dear-ReGui / Sigma Spy screenshot
	Pure Instances only (executor Real safe)
]]

local ReGui = {
	Version = "compat-2.0",
	DefaultTitle = "Sigma Spy",
	Themes = {},
	Windows = {},
	Initialised = true,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Colors matched to typical Sigma Spy / ImGui dark blue
local C = {
	Bg = Color3.fromRGB(28, 32, 44),
	Bg2 = Color3.fromRGB(22, 25, 36),
	Title = Color3.fromRGB(36, 42, 58),
	Border = Color3.fromRGB(55, 65, 90),
	Text = Color3.fromRGB(210, 214, 230),
	TextDim = Color3.fromRGB(140, 148, 170),
	Accent = Color3.fromRGB(70, 110, 180),
	Btn = Color3.fromRGB(48, 56, 78),
	BtnHover = Color3.fromRGB(60, 72, 100),
	Select = Color3.fromRGB(45, 70, 120),
	SelectActive = Color3.fromRGB(55, 95, 160),
	Input = Color3.fromRGB(18, 20, 30),
	Green = Color3.fromRGB(100, 220, 140),
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

local function pad(parent, px)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px or 4)
	p.PaddingRight = UDim.new(0, px or 4)
	p.PaddingTop = UDim.new(0, px or 4)
	p.PaddingBottom = UDim.new(0, px or 4)
	p.Parent = parent
	return p
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
		for k, v in extra do
			self[k] = v
		end
	end
	return setmetatable(self, Element)
end

function Element:__index(key)
	local method = rawget(Element, key)
	if method ~= nil then return method end
	local inst = rawget(self, "Instance")
	if inst then
		local ok, val = pcall(function() return inst[key] end)
		if ok and typeof(val) ~= "Instance" then
			-- allow reading properties; for GuiObject Text etc
			if typeof(val) ~= "function" then
				return val
			end
		end
		-- property write via creating setter is hard; methods only
	end
	-- dynamic: Parent:SomeClass(config)
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

	local function setLayoutOrder(gui)
		if config.LayoutOrder then
			gui.LayoutOrder = config.LayoutOrder
		end
	end

	if class == "List" or class == "Canvas" then
		local isScroll = config.Scroll or class == "Canvas"
		local frame
		if isScroll then
			frame = Instance.new("ScrollingFrame")
			frame.ScrollBarThickness = 3
			frame.ScrollBarImageColor3 = C.Border
			frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			frame.CanvasSize = UDim2.new()
			frame.BackgroundColor3 = C.Bg2
		else
			frame = Instance.new("Frame")
			frame.BackgroundTransparency = 1
		end
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 1, 0)
		frame.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		frame.Parent = host
		setLayoutOrder(frame)
		if config.BackgroundTransparency then
			frame.BackgroundTransparency = config.BackgroundTransparency
		elseif isScroll then
			frame.BackgroundTransparency = 0
		end
		corner(frame, 4)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = config.FillDirection or Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, config.UiPadding or 3)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		pcall(function()
			if config.HorizontalFlex then layout.HorizontalFlex = config.HorizontalFlex end
			if config.VerticalFlex then layout.VerticalFlex = config.VerticalFlex end
		end)
		if config.UiPadding then pad(frame, config.UiPadding) end
		return wrap(frame, class)
	end

	if class == "Table" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = config.Size or UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		setLayoutOrder(frame)
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 3)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		return wrap(frame, "Table", { _maxColumns = config.MaxColumns or 3 })
	end

	if class == "Row" or class == "HeaderRow" or class == "NextRow" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		setLayoutOrder(frame)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = frame
		return wrap(frame, "Row")
	end

	if class == "NextColumn" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.Parent = host
		setLayoutOrder(frame)
		Instance.new("UIListLayout", frame).Padding = UDim.new(0, 2)
		return wrap(frame, "Column")
	end

	if class == "Label" then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextColor3 = config.TextColor3 or C.Text
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextWrapped = config.TextWrapped ~= false
		label.RichText = config.RichText or false
		label.Text = tostring(config.Text or "")
		label.Parent = host
		setLayoutOrder(label)
		return wrap(label, "Label")
	end

	if class == "BulletText" then
		local lines = {}
		for _, row in (config.Rows or {}) do
			table.insert(lines, "• " .. tostring(row))
		end
		return self:_create("Label", {
			Text = table.concat(lines, "\n"),
			TextWrapped = true,
		})
	end

	if class == "Separator" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, config.Text and 22 or 8)
		frame.Parent = host
		setLayoutOrder(frame)
		if config.Text then
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 1, 0)
			t.Text = tostring(config.Text)
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

	if class == "Button" then
		local btn = Instance.new("TextButton")
		btn.Size = config.Size or UDim2.new(0, 88, 0, 24)
		btn.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		btn.BackgroundColor3 = C.Btn
		btn.TextColor3 = C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.Gotham
		btn.Text = tostring(config.Text or config.Label or "Button")
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Parent = host
		setLayoutOrder(btn)
		corner(btn, 4)
		local el = wrap(btn, "Button")
		if config.Callback then
			btn.MouseButton1Click:Connect(function()
				pcall(config.Callback, el)
			end)
		end
		function el:Remove()
			btn:Destroy()
		end
		return el
	end

	if class == "Selectable" then
		local btn = Instance.new("TextButton")
		btn.Size = config.Size or UDim2.new(1, -4, 0, 18)
		btn.BackgroundColor3 = C.Bg2
		btn.BackgroundTransparency = 0.3
		btn.TextColor3 = config.TextColor3 or C.Text
		btn.TextSize = 12
		btn.Font = Enum.Font.Code
		btn.Text = tostring(config.Text or "")
		btn.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = host
		setLayoutOrder(btn)
		pad(btn, 4)
		corner(btn, 2)
		local el = wrap(btn, "Selectable")
		el._btn = btn
		function el:SetSelected(v)
			el._selected = v and true or false
			btn.BackgroundColor3 = el._selected and C.SelectActive or C.Bg2
			btn.BackgroundTransparency = el._selected and 0 or 0.3
		end
		function el:Remove()
			btn:Destroy()
		end
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
		holder.Size = UDim2.new(1, 0, 0, 22)
		holder.Parent = host
		setLayoutOrder(holder)
		local box = Instance.new("TextButton")
		box.Size = UDim2.fromOffset(18, 18)
		box.BackgroundColor3 = C.Input
		box.Text = config.Value and "✓" or ""
		box.TextColor3 = C.Green
		box.TextSize = 12
		box.Font = Enum.Font.GothamBold
		box.BorderSizePixel = 0
		box.Parent = holder
		corner(box, 3)
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Position = UDim2.fromOffset(24, 0)
		lab.Size = UDim2.new(1, -24, 1, 0)
		lab.Text = tostring(config.Label or config.Text or "")
		lab.TextColor3 = C.Text
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Font = Enum.Font.Gotham
		lab.TextSize = 12
		lab.Parent = holder
		local state = config.Value and true or false
		local el = wrap(holder, "Checkbox")
		local function set(v)
			state = not not v
			box.Text = state and "✓" or ""
			if config.Callback then pcall(config.Callback, state) end
		end
		box.MouseButton1Click:Connect(function() set(not state) end)
		function el:Toggle() set(not state) end
		return el
	end

	if class == "CodeEditor" or class == "Console" then
		local scroll = Instance.new("ScrollingFrame")
		-- Fill leaves room for button rows below (no need to scroll to see buttons)
		if config.Fill then
			scroll.Size = UDim2.new(1, 0, 1, -36)
		else
			scroll.Size = config.Size or UDim2.new(1, 0, 0, 180)
		end
		scroll.BackgroundColor3 = C.Input
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 5
		scroll.ScrollBarImageColor3 = C.Border
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = host
		setLayoutOrder(scroll)
		corner(scroll, 4)
		pad(scroll, 6)
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
		box.TextColor3 = Color3.fromRGB(180, 220, 190)
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

	if class == "TreeNode" then
		local root = Instance.new("Frame")
		root.BackgroundTransparency = 1
		root.Size = UDim2.new(1, 0, 0, 0)
		root.AutomaticSize = Enum.AutomaticSize.Y
		root.Parent = host
		setLayoutOrder(root)

		local header = Instance.new("TextButton")
		header.Size = UDim2.new(1, 0, 0, 20)
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
			header.Text = (open and "▼ " or "▶ ") .. title
		end
		refresh()

		local body = Instance.new("Frame")
		body.Name = "Content"
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromOffset(10, 20)
		body.Size = UDim2.new(1, -10, 0, 0)
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
		-- children go into body
		function el:_host()
			return body
		end
		function el:Remove()
			root:Destroy()
		end
		return el
	end

	if class == "TabSelector" then
		local root = Instance.new("Frame")
		root.BackgroundTransparency = 1
		root.Size = config.Size or UDim2.new(1, 0, 1, 0)
		root.Parent = host
		setLayoutOrder(root)

		local tabBar = Instance.new("Frame")
		tabBar.Size = UDim2.new(1, 0, 0, 26)
		tabBar.BackgroundColor3 = C.Title
		tabBar.BorderSizePixel = 0
		tabBar.Parent = root
		local tl = Instance.new("UIListLayout")
		tl.FillDirection = Enum.FillDirection.Horizontal
		tl.Padding = UDim.new(0, 2)
		tl.Parent = tabBar
		pad(tabBar, 2)

		local body = Instance.new("Frame")
		body.Name = "Body"
		body.Position = UDim2.fromOffset(0, 28)
		body.Size = UDim2.new(1, 0, 1, -28)
		body.BackgroundColor3 = C.Bg2
		body.BorderSizePixel = 0
		body.Parent = root
		corner(body, 4)

		local el = wrap(root, "TabSelector")
		el._tabs = {}
		el.ActiveTab = nil

		function el:CreateTab(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Tab"
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(math.max(64, #name * 7 + 16), 22)
			btn.BackgroundColor3 = C.Btn
			btn.Text = name
			btn.TextColor3 = C.Text
			btn.TextSize = 12
			btn.Font = Enum.Font.Gotham
			btn.BorderSizePixel = 0
			btn.Parent = tabBar
			corner(btn, 3)

			-- Fixed page: children can use Fill without hiding bottom buttons
			local page = Instance.new("Frame")
			page.Size = UDim2.new(1, -8, 1, -8)
			page.Position = UDim2.fromOffset(4, 4)
			page.BackgroundTransparency = 1
			page.Visible = false
			page.Parent = body
			local pl = Instance.new("UIListLayout")
			pl.Padding = UDim.new(0, 4)
			pl.SortOrder = Enum.SortOrder.LayoutOrder
			pl.FillDirection = Enum.FillDirection.Vertical
			pl.Parent = page
			pcall(function()
				pl.VerticalFlex = Enum.UIFlexAlignment.Fill
			end)
			pad(page, 4)

			local tabEl = wrap(page, "Tab")
			tabEl._name = name
			tabEl._button = btn
			table.insert(el._tabs, tabEl)

			local function activate()
				for _, t in el._tabs do
					t.Instance.Visible = false
					if t._button then t._button.BackgroundColor3 = C.Btn end
				end
				page.Visible = true
				btn.BackgroundColor3 = C.SelectActive
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
						el.ActiveTab._button.BackgroundColor3 = C.SelectActive
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
			Size = UDim2.new(0, 70, 0, 22),
		})
	end

	if class == "Expand" then
		return self
	end

	if class == "ClearChildElements" then
		for _, c in host:GetChildren() do
			if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner")) then
				c:Destroy()
			end
		end
		return self
	end

	if class == "PopupModal" or class == "PopupCanvas" then
		return self:PopupModal(config)
	end

	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 20)
	f.Parent = host
	return wrap(f, class)
end

-- explicit methods
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
function Element:SetVisible(v)
	self.Instance.Visible = not not v
end
function Element:SetTitle(t)
	local title = self.Instance:FindFirstChild("Title", true)
	if title and title:IsA("TextLabel") then
		title.Text = tostring(t)
	end
end
function Element:SetTheme() return self end
function Element:Close()
	self.Instance.Visible = false
end
function Element:ClosePopup()
	local inst = self.Instance
	local p = inst.Parent
	if p and p.Name == "ModalDim" then
		p:Destroy()
	else
		inst.Visible = false
	end
end
function Element:Remove()
	self.Instance:Destroy()
end
function Element:PopupModal(config)
	config = config or {}
	local screen = parentGui()
	local dim = Instance.new("Frame")
	dim.Name = "ModalDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.5
	dim.BorderSizePixel = 0
	dim.Parent = screen
	local modal = Instance.new("Frame")
	modal.Size = UDim2.fromOffset(380, 180)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = C.Bg
	modal.Parent = dim
	corner(modal, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Border
	stroke.Parent = modal
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(10, 6)
	title.BackgroundTransparency = 1
	title.Text = config.Title or "Sigma Spy"
	title.TextColor3 = C.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = modal
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(10, 38)
	content.Size = UDim2.new(1, -20, 1, -48)
	content.BackgroundTransparency = 1
	content.Parent = modal
	Instance.new("UIListLayout", content).Padding = UDim.new(0, 6)
	return wrap(modal, "Modal")
end
function Element:PopupCanvas(config)
	return self:PopupModal(config)
end

function ReGui:Window(config)
	config = config or {}
	local screen = parentGui()
	local size = config.Size or UDim2.fromOffset(700, 440)

	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.15, 0)
	frame.BackgroundColor3 = C.Bg
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen
	corner(frame, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Border
	stroke.Thickness = 1
	stroke.Parent = frame

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = C.Title
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title or self.DefaultTitle
	title.TextColor3 = C.Text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(26, 22)
	close.Position = UDim2.new(1, -30, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(90, 45, 55)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 210, 210)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.BorderSizePixel = 0
	close.Parent = titleBar
	corner(close, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(6, 34)
	content.Size = UDim2.new(1, -12, 1, -40)
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
	function win:_host()
		return content
	end
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)
	table.insert(self.Windows, win)
	return win
end

return ReGui
