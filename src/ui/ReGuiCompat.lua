--[[
	ReGuiCompat – pure Instance UI compatible with Sigma Spy’s Ui.lua
	No rbxassetid prefabs / LoadLocalAsset (works on executor "Real")
]]

local ReGui = {
	Version = "compat-1.0",
	DefaultTitle = "Sigma Spy",
	Themes = {},
	ActiveTheme = "DarkTheme",
	Windows = {},
	Initialised = true,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local function deepMerge(a, b)
	if typeof(b) ~= "table" then return a end
	for k, v in b do
		if typeof(v) == "table" and typeof(a[k]) == "table" then
			deepMerge(a[k], v)
		else
			a[k] = v
		end
	end
	return a
end

function ReGui:CheckConfig(Target, Defaults)
	if typeof(Target) ~= "table" then return Target end
	for k, v in Defaults do
		if Target[k] == nil then
			if typeof(v) == "function" then
				Target[k] = v()
			else
				Target[k] = v
			end
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

function ReGui:CheckImportState()
	-- no-op (no prefab asset)
end

local function parentGui()
	local ok, gui = pcall(function()
		return CoreGui
	end)
	if ok and gui then
		local screen = CoreGui:FindFirstChild("ReGuiCompatScreens")
		if not screen then
			screen = Instance.new("ScreenGui")
			screen.Name = "ReGuiCompatScreens"
			screen.ResetOnSpawn = false
			screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			screen.DisplayOrder = 100
			pcall(function()
				screen.Parent = CoreGui
			end)
			if not screen.Parent then
				screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
			end
		end
		return screen
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function applyProps(inst, props)
	if not props then return end
	for k, v in props do
		if k == "Parent" or k == "Callback" or k == "Text" then
			continue
		end
		pcall(function()
			inst[k] = v
		end)
	end
end

-- Element wrapper
local Element = {}
Element.__index = Element

local function wrap(inst, className)
	local self = setmetatable({
		Instance = inst,
		Class = className or inst.ClassName,
		_children = {},
		ActiveTab = nil,
		Enabled = true,
		_tabs = {},
		_tabButtons = {},
		_tabContent = {},
	}, Element)
	return self
end

function Element:__index(key)
	local fromMeta = rawget(Element, key)
	if fromMeta ~= nil then
		return fromMeta
	end
	local inst = rawget(self, "Instance")
	if inst then
		local ok, val = pcall(function()
			return inst[key]
		end)
		if ok then
			return val
		end
	end
	-- dynamic element constructors: Button, Label, etc.
	return function(this, config)
		config = config or {}
		return this:_create(key, config)
	end
end

function Element:_host()
	local inst = self.Instance
	if inst:IsA("ScrollingFrame") or inst:IsA("Frame") or inst:IsA("ScreenGui") then
		return inst
	end
	local content = inst:FindFirstChild("Content") or inst:FindFirstChild("ContentFrame")
	return content or inst
end

function Element:_create(class, config)
	config = config or {}
	local host = self:_host()

	if class == "List" or class == "Canvas" then
		local scroll = config.Scroll
		local frame
		if scroll then
			frame = Instance.new("ScrollingFrame")
			frame.ScrollBarThickness = 4
			frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		else
			frame = Instance.new("Frame")
		end
		frame.BackgroundTransparency = config.BackgroundTransparency or 1
		frame.BorderSizePixel = 0
		frame.Size = config.Size or UDim2.new(1, 0, 1, 0)
		frame.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		frame.Parent = host
		applyProps(frame, config)
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = config.FillDirection or Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, config.UiPadding or 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		if config.HorizontalFlex then
			pcall(function()
				layout.HorizontalFlex = config.HorizontalFlex
			end)
		end
		if config.VerticalFlex then
			pcall(function()
				layout.VerticalFlex = config.VerticalFlex
			end)
		end
		return wrap(frame, class)
	end

	if class == "Table" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = config.Size or UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		local grid = Instance.new("UIListLayout")
		grid.FillDirection = Enum.FillDirection.Vertical
		grid.Padding = UDim.new(0, 4)
		grid.Parent = frame
		local el = wrap(frame, "Table")
		el._maxColumns = config.MaxColumns or 3
		el._currentRow = nil
		return el
	end

	if class == "Row" or class == "HeaderRow" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = frame
		return wrap(frame, "Row")
	end

	if class == "NextRow" then
		return self:Row(config)
	end

	if class == "NextColumn" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(0, 120, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.Parent = host
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 2)
		layout.Parent = frame
		return wrap(frame, "Column")
	end

	if class == "Label" or class == "BulletText" then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextColor3 = Color3.fromRGB(210, 210, 220)
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextWrapped = config.TextWrapped ~= false
		if class == "BulletText" and config.Rows then
			local lines = {}
			for _, row in config.Rows do
				table.insert(lines, "• " .. tostring(row))
			end
			label.Text = table.concat(lines, "\n")
		else
			label.Text = config.Text or ""
		end
		label.Parent = host
		applyProps(label, config)
		return wrap(label, "Label")
	end

	if class == "Separator" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, 20)
		frame.Parent = host
		if config.Text then
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 1, 0)
			t.Text = tostring(config.Text)
			t.TextColor3 = Color3.fromRGB(140, 140, 160)
			t.TextSize = 12
			t.Font = Enum.Font.GothamBold
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = frame
		else
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			line.BorderSizePixel = 0
			line.Parent = frame
		end
		return wrap(frame, "Separator")
	end

	if class == "Button" or class == "Selectable" then
		local btn = Instance.new("TextButton")
		btn.Size = config.Size or UDim2.new(0, 90, 0, 24)
		btn.AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btn.TextColor3 = Color3.fromRGB(230, 230, 240)
		btn.TextSize = 13
		btn.Font = Enum.Font.Gotham
		btn.Text = config.Text or config.Label or "Button"
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Parent = host
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		applyProps(btn, config)
		local el = wrap(btn, class)
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

	if class == "Checkbox" then
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, 0, 0, 24)
		holder.Parent = host
		local box = Instance.new("TextButton")
		box.Size = UDim2.fromOffset(20, 20)
		box.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		box.Text = config.Value and "X" or ""
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.Parent = holder
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Position = UDim2.fromOffset(26, 0)
		lab.Size = UDim2.new(1, -26, 1, 0)
		lab.Text = config.Label or config.Text or ""
		lab.TextColor3 = Color3.fromRGB(210, 210, 220)
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.Font = Enum.Font.Gotham
		lab.TextSize = 13
		lab.Parent = holder
		local state = config.Value and true or false
		local el = wrap(holder, "Checkbox")
		local function set(v)
			state = v and true or false
			box.Text = state and "X" or ""
			if config.Callback then
				pcall(config.Callback, state)
			end
		end
		box.MouseButton1Click:Connect(function()
			set(not state)
		end)
		function el:Toggle()
			set(not state)
		end
		return el
	end

	if class == "CodeEditor" or class == "Console" then
		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = config.Size or UDim2.new(1, 0, 1, 0)
		scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 6
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = host
		Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 4)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -8, 0, 0)
		box.AutomaticSize = Enum.AutomaticSize.Y
		box.BackgroundTransparency = 1
		box.TextColor3 = Color3.fromRGB(200, 220, 200)
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.TextSize = config.FontSize or 13
		box.Font = Enum.Font.Code
		box.ClearTextOnFocus = false
		box.MultiLine = true
		box.TextWrapped = true
		box.Text = config.Text or ""
		box.TextEditable = config.Editable ~= false and not config.ReadOnly
		box.Parent = scroll
		local el = wrap(scroll, class)
		el.Enabled = config.Enabled ~= false
		el._box = box
		el._lines = {}
		function el:GetText()
			return box.Text
		end
		function el:GetValue()
			return box.Text
		end
		function el:Clear()
			box.Text = ""
			el._lines = {}
		end
		function el:AppendText(...)
			if not el.Enabled then
				return
			end
			local parts = { ... }
			for i = 1, #parts do
				parts[i] = tostring(parts[i])
			end
			local line = table.concat(parts, " ")
			table.insert(el._lines, line)
			local maxLines = config.MaxLines or 200
			while #el._lines > maxLines do
				table.remove(el._lines, 1)
			end
			box.Text = table.concat(el._lines, "\n")
		end
		return el
	end

	if class == "TabSelector" then
		local root = Instance.new("Frame")
		root.BackgroundTransparency = 1
		root.Size = config.Size or UDim2.new(1, 0, 1, 0)
		root.Parent = host
		local tabBar = Instance.new("Frame")
		tabBar.Size = UDim2.new(1, 0, 0, 28)
		tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		tabBar.BorderSizePixel = 0
		tabBar.Parent = root
		local tabLayout = Instance.new("UIListLayout")
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabLayout.Padding = UDim.new(0, 2)
		tabLayout.Parent = tabBar
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.Position = UDim2.fromOffset(0, 30)
		body.Size = UDim2.new(1, 0, 1, -30)
		body.BackgroundTransparency = 1
		body.Parent = root
		local el = wrap(root, "TabSelector")
		el._tabBar = tabBar
		el._body = body
		el._tabs = {}
		el.ActiveTab = nil

		function el:CreateTab(cfg)
			cfg = cfg or {}
			local name = cfg.Name or "Tab"
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(70, 26)
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			btn.Text = name
			btn.TextColor3 = Color3.fromRGB(220, 220, 230)
			btn.TextSize = 12
			btn.Font = Enum.Font.Gotham
			btn.BorderSizePixel = 0
			btn.Parent = tabBar
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

			local page = Instance.new("ScrollingFrame")
			page.Size = UDim2.new(1, 0, 1, 0)
			page.BackgroundTransparency = 1
			page.Visible = false
			page.ScrollBarThickness = 4
			page.AutomaticCanvasSize = Enum.AutomaticSize.Y
			page.CanvasSize = UDim2.new(0, 0, 0, 0)
			page.Parent = body
			local pageLayout = Instance.new("UIListLayout")
			pageLayout.Padding = UDim.new(0, 4)
			pageLayout.Parent = page

			local tabEl = wrap(page, "Tab")
			tabEl._name = name
			tabEl._button = btn
			table.insert(el._tabs, tabEl)

			local function activate()
				for _, t in el._tabs do
					t.Instance.Visible = false
					if t._button then
						t._button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
					end
				end
				page.Visible = true
				btn.BackgroundColor3 = Color3.fromRGB(70, 90, 140)
				el.ActiveTab = tabEl
			end
			btn.MouseButton1Click:Connect(activate)
			if #el._tabs == 1 then
				activate()
			end

			function tabEl:Remove()
				btn:Destroy()
				page:Destroy()
			end
			return tabEl
		end

		function el:RemoveTab(tab)
			if not tab then
				return
			end
			for i, t in el._tabs do
				if t == tab or (tab.Instance and t.Instance == tab.Instance) then
					table.remove(el._tabs, i)
					break
				end
			end
			pcall(function()
				tab:Remove()
			end)
			if el.ActiveTab == tab then
				el.ActiveTab = el._tabs[1]
				if el.ActiveTab then
					el.ActiveTab.Instance.Visible = true
				end
			end
		end

		function el:CompareTabs(a, b)
			return a == b or (a and b and a.Instance == b.Instance)
		end

		return el
	end

	if class == "TreeNode" then
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Parent = host
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 20)
		btn.BackgroundTransparency = 1
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Text = (config.Title or config.Text or "Node")
		btn.TextColor3 = Color3.fromRGB(200, 200, 210)
		btn.TextSize = 12
		btn.Font = Enum.Font.Gotham
		btn.Parent = frame
		local child = Instance.new("Frame")
		child.BackgroundTransparency = 1
		child.Position = UDim2.fromOffset(12, 20)
		child.Size = UDim2.new(1, -12, 0, 0)
		child.AutomaticSize = Enum.AutomaticSize.Y
		child.Visible = false
		child.Parent = frame
		Instance.new("UIListLayout", child)
		btn.MouseButton1Click:Connect(function()
			child.Visible = not child.Visible
		end)
		local el = wrap(child, "TreeNode")
		function el:Remove()
			frame:Destroy()
		end
		return el
	end

	if class == "Keybind" then
		return self:Button({
			Text = config.Label or config.Text or "Keybind",
			Callback = config.Callback,
		})
	end

	if class == "PopupModal" or class == "PopupCanvas" then
		return self:Label({ Text = config.Title or "Modal" })
	end

	if class == "Expand" then
		return self
	end

	if class == "ClearChildElements" then
		for _, c in host:GetChildren() do
			if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
				c:Destroy()
			end
		end
		return self
	end

	-- generic frame fallback
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 24)
	f.Parent = host
	return wrap(f, class)
end

-- Chain helpers used by Ui.lua
function Element:List(config)
	return self:_create("List", config)
end
function Element:Canvas(config)
	return self:_create("Canvas", config)
end
function Element:Table(config)
	return self:_create("Table", config)
end
function Element:Row(config)
	return self:_create("Row", config)
end
function Element:NextRow(config)
	return self:_create("NextRow", config)
end
function Element:NextColumn(config)
	return self:_create("NextColumn", config)
end
function Element:HeaderRow(config)
	return self:_create("HeaderRow", config)
end
function Element:Label(config)
	return self:_create("Label", config)
end
function Element:Button(config)
	return self:_create("Button", config)
end
function Element:Selectable(config)
	return self:_create("Selectable", config)
end
function Element:Checkbox(config)
	return self:_create("Checkbox", config)
end
function Element:Separator(config)
	return self:_create("Separator", config)
end
function Element:CodeEditor(config)
	return self:_create("CodeEditor", config)
end
function Element:Console(config)
	return self:_create("Console", config)
end
function Element:BulletText(config)
	return self:_create("BulletText", config)
end
function Element:Keybind(config)
	return self:_create("Keybind", config)
end
function Element:TreeNode(config)
	return self:_create("TreeNode", config)
end
function Element:TabSelector(config)
	return self:_create("TabSelector", config)
end
function Element:Expand()
	return self
end
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
	self.Instance.Visible = v and true or false
end
function Element:SetTitle(t)
	local title = self.Instance:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = tostring(t)
	end
end
function Element:SetTheme()
	return self
end
function Element:Close()
	self.Instance.Visible = false
end
function Element:ClosePopup()
	self:Close()
	local p = self.Instance.Parent
	if p and p.Name == "ModalDim" then
		p:Destroy()
	end
end
function Element:PopupModal(config)
	config = config or {}
	local screen = parentGui()
	local dim = Instance.new("Frame")
	dim.Name = "ModalDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = screen
	local modal = Instance.new("Frame")
	modal.Size = UDim2.fromOffset(360, 160)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	modal.Parent = dim
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 8)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(8, 4)
	title.BackgroundTransparency = 1
	title.Text = config.Title or "Modal"
	title.TextColor3 = Color3.fromRGB(230, 230, 240)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = modal
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(8, 36)
	content.Size = UDim2.new(1, -16, 1, -44)
	content.BackgroundTransparency = 1
	content.Parent = modal
	Instance.new("UIListLayout", content).Padding = UDim.new(0, 6)
	return wrap(modal, "Modal")
end
function Element:PopupCanvas(config)
	return self:PopupModal(config)
end
function Element:Remove()
	self.Instance:Destroy()
end

function ReGui:Window(config)
	config = config or {}
	local screen = parentGui()
	local size = config.Size or UDim2.fromOffset(640, 420)

	local frame = Instance.new("Frame")
	frame.Name = "Window"
	frame.Size = size
	frame.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.2, 0)
	frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", frame).Color = Color3.fromRGB(50, 50, 60)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 32)
	titleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.fromOffset(10, 0)
	title.BackgroundTransparency = 1
	title.Text = config.Title or self.DefaultTitle
	title.TextColor3 = Color3.fromRGB(230, 230, 240)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(28, 24)
	close.Position = UDim2.new(1, -32, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 200, 200)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 12
	close.Parent = titleBar
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.fromOffset(6, 36)
	content.Size = UDim2.new(1, -12, 1, -42)
	content.BackgroundTransparency = 1
	content.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.Parent = content

	local win = wrap(frame, "Window")
	-- route children into Content
	local oldHost = win._host
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
