local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local env = (getgenv and getgenv()) or _G

if env.__GlassUIOptimizerCleanup then
	pcall(env.__GlassUIOptimizerCleanup)
end

local CONFIG = {
	Title = "RidKid Hub",
	Subtitle = "Ultimate Integrated Script Hub",
	LogoId = "rbxassetid://130920436247899",
	LogoSize = 49,
	DefaultSize = Vector2.new(420, 420),
	MinSize = Vector2.new(320, 280),
	MaxSize = Vector2.new(700, 600),
	Topbar = 46,
	ToggleKey = Enum.KeyCode.RightShift,
}

local THEME = {
	Base = Color3.fromRGB(16, 20, 32),
	Accent = Color3.fromRGB(110, 165, 255),
	Accent2 = Color3.fromRGB(170, 135, 255),
	Text = Color3.fromRGB(240, 243, 250),
	SubText = Color3.fromRGB(165, 172, 192),
	Danger = Color3.fromRGB(255, 95, 95),
	Good = Color3.fromRGB(100, 230, 150),
	Warn = Color3.fromRGB(255, 205, 90),
	White = Color3.new(1, 1, 1),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SPRING = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function pill(parent)
	return new("UICorner", { CornerRadius = UDim.new(1, 0) }, parent)
end

local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or TWEEN_FAST, props)
	t:Play()
	return t
end

local function viewport()
	local cam = Workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function p2(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function glassStroke(parent, thickness)
	local s = new("UIStroke", {
		Color = THEME.White,
		Thickness = thickness or 1.2,
		Transparency = 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	new("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.82),
			NumberSequenceKeypoint.new(1, 0.55),
		}),
	}, s)
	return s
end
local old = playerGui:FindFirstChild("GlassUI")
if old then
	old:Destroy()
end

local gui = new("ScreenGui", {
	Name = "GlassUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 99999,
}, playerGui)

local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local fullSize = CONFIG.DefaultSize
local userScale = 1
local vp = viewport()
local winPos = Vector2.new(math.floor((vp.X - fullSize.X) / 2), math.floor((vp.Y - fullSize.Y) / 2))
local iconPos = Vector2.new(24, math.floor(vp.Y / 2))

local main = new("Frame", {
	Name = "Main",
	BackgroundColor3 = THEME.White,
	BackgroundTransparency = 0.42,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Size = UDim2.fromOffset(fullSize.X, fullSize.Y),
	Position = UDim2.fromOffset(winPos.X, winPos.Y),
}, gui)
corner(main, 16)

local uiScale = new("UIScale", { Scale = 1 }, main)

new("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(58, 68, 98), Color3.fromRGB(14, 17, 28)),
	Rotation = 60,
}, main)

local stroke = glassStroke(main, 1.3)

local shine = new("Frame", {
	Name = "Shine",
	BackgroundColor3 = THEME.White,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 110),
}, main)
corner(shine, 16)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, shine)

local topbar = new("Frame", {
	Name = "Topbar",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, CONFIG.Topbar),
}, main)

local logoSmall = new("ImageLabel", {
	BackgroundColor3 = THEME.White,
	BackgroundTransparency = 0.9,
	Image = CONFIG.LogoId,
	ScaleType = Enum.ScaleType.Crop,
	Position = UDim2.fromOffset(14, 11),
	Size = UDim2.fromOffset(24, 24),
}, topbar)
pill(logoSmall)

new("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Text = CONFIG.Title,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(46, 7),
	Size = UDim2.new(1, -130, 0, 18),
}, topbar)

new("TextLabel", {
	Name = "Subtitle",
	BackgroundTransparency = 1,
	Text = CONFIG.Subtitle,
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(46, 24),
	Size = UDim2.new(1, -130, 0, 14),
}, topbar)

new("Frame", {
	Name = "Divider",
	BackgroundColor3 = THEME.White,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 14, 0, CONFIG.Topbar - 1),
	Size = UDim2.new(1, -28, 0, 1),
}, main)

local btnHolder = new("Frame", {
	Name = "Buttons",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(58, 26),
}, topbar)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, btnHolder)

local function headerButton(text, order, hoverColor, hoverTransparency)
	local b = new("TextButton", {
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(26, 26),
		LayoutOrder = order,
	}, btnHolder)
	corner(b, 8)
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundColor3 = hoverColor, BackgroundTransparency = hoverTransparency })
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundColor3 = THEME.White, BackgroundTransparency = 0.9 })
	end)
	return b
end

local minBtn = headerButton("–", 1, THEME.White, 0.75)
local closeBtn = headerButton("×", 2, THEME.Danger, 0.15)
local content = new("Frame", {
	Name = "Content",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, CONFIG.Topbar),
	Size = UDim2.new(1, 0, 1, -CONFIG.Topbar),
}, main)

local PAGE_PADDING = 14

local function newPage()
	local page = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		Visible = false,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.White,
		ScrollBarImageTransparency = 0.6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, content)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, PAGE_PADDING),
		PaddingRight = UDim.new(0, PAGE_PADDING),
	}, page)
	new("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)
	return page
end

local ridKidPage = newPage()
local playerPage = newPage()
local visualPage = newPage()
local miscPage = newPage()
local settingsPage = newPage()
local optimizePage = newPage()

local tabBar = new("ScrollingFrame", {
	Name = "Tabs",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(PAGE_PADDING, 8),
	Size = UDim2.new(1, -100, 0, 32),
	CanvasSize = UDim2.new(),
	AutomaticSize = Enum.AutomaticSize.None,
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 0,
}, content)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local fpsPill = new("Frame", {
	Name = "FPSPill",
	BackgroundColor3 = THEME.White,
	BackgroundTransparency = 0.92,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -PAGE_PADDING, 0, 8),
	Size = UDim2.fromOffset(72, 32),
}, content)
corner(fpsPill, 10)

local fpsLabel = new("TextLabel", {
	Name = "FPS",
	BackgroundTransparency = 1,
	Text = "-- FPS",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.Accent,
	Size = UDim2.fromScale(1, 1),
}, fpsPill)

local tabs = {}
local function selectTab(name)
	for n, t in pairs(tabs) do
		local active = n == name
		t.page.Visible = active
		tween(t.button, {
			BackgroundTransparency = active and 0.7 or 1,
			TextColor3 = active and THEME.Text or THEME.SubText,
		})
	end
end

local function addTab(name, order, page, width)
	local b = new("TextButton", {
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = THEME.SubText,
		AutoButtonColor = false,
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(width, 24),
		LayoutOrder = order,
	}, tabBar)
	corner(b, 7)
	tabs[name] = { button = b, page = page }
	b.Activated:Connect(function()
		selectTab(name)
	end)
end

addTab("RidKid", 1, ridKidPage, 60)
addTab("Player", 2, playerPage, 64)
addTab("Visuals", 3, visualPage, 64)
addTab("Misc", 4, miscPage, 50)
addTab("Settings", 5, settingsPage, 70)
addTab("Optimize", 6, optimizePage, 74)
selectTab("RidKid")

local S = CONFIG.LogoSize
local icon = new("Frame", {
	Name = "CollapsedIcon",
	BackgroundColor3 = THEME.Base,
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(S, S),
	Position = UDim2.fromOffset(iconPos.X, iconPos.Y),
	Visible = false,
}, gui)
pill(icon)
glassStroke(icon, 1.5)
local iconScale = new("UIScale", { Scale = 1 }, icon)

local iconImg = new("ImageButton", {
	Name = "Logo",
	BackgroundTransparency = 1,
	Image = CONFIG.LogoId,
	ScaleType = Enum.ScaleType.Crop,
	AutoButtonColor = false,
	Size = UDim2.fromScale(1, 1),
}, icon)
pill(iconImg)

local isOpen = true
local anim = 0

local function iconTarget()
	local cx, cy = iconPos.X + S / 2, iconPos.Y + S / 2
	return UDim2.fromOffset(cx - fullSize.X * 0.025, cy - fullSize.Y * 0.025)
end

local function collapse()
	if not isOpen then return end
	isOpen = false
	anim += 1
	local my = anim
	winPos = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
	local info = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	tween(main, { Position = iconTarget() }, info)
	local t = tween(uiScale, { Scale = 0.05 }, info)
	t.Completed:Connect(function()
		if my ~= anim then return end
		main.Visible = false
		icon.Visible = true
		iconScale.Scale = 0.3
		tween(iconScale, { Scale = 1 }, TWEEN_SPRING)
	end)
end

local function open()
	if isOpen then return end
	isOpen = true
	anim += 1
	icon.Visible = false
	main.Visible = true
	uiScale.Scale = 0.05
	main.Position = iconTarget()
	local x, y = winPos.X, winPos.Y
	tween(main, { Position = UDim2.fromOffset(x, y) }, TWEEN_SPRING)
	tween(uiScale, { Scale = userScale }, TWEEN_SPRING)
end

minBtn.Activated:Connect(collapse)

closeBtn.Activated:Connect(function()
	if env.__GlassUIOptimizerCleanup then
		pcall(env.__GlassUIOptimizerCleanup)
	end
	gui:Destroy()
end)
local function makeDraggable(target, onBegin, onDrag, onEnd)
	local dragging = false
	local activeInput = nil
	local startPos = Vector2.zero
	local lastDelta = Vector2.zero

	target.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			activeInput = input
			startPos = p2(input)
			lastDelta = Vector2.zero
			if onBegin then onBegin(startPos) end
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End and activeInput == input then
					dragging = false
					if onEnd then onEnd(lastDelta.Magnitude) end
				end
			end)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not dragging then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and input == activeInput) then
			local pos = p2(input)
			lastDelta = pos - startPos
			onDrag(lastDelta, pos)
		end
	end)
end

local dragOrigin = Vector2.zero
makeDraggable(topbar, function()
	dragOrigin = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
end, function(delta)
	main.Position = UDim2.fromOffset(dragOrigin.X + delta.X, dragOrigin.Y + delta.Y)
end, function()
	winPos = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
end)

local iconOrigin = Vector2.zero
makeDraggable(iconImg, function()
	iconOrigin = iconPos
end, function(delta)
	local v = viewport()
	local x = math.clamp(iconOrigin.X + delta.X, 0, v.X - S)
	local y = math.clamp(iconOrigin.Y + delta.Y, 0, v.Y - S)
	iconPos = Vector2.new(x, y)
	icon.Position = UDim2.fromOffset(x, y)
end, function(moved)
	if moved < 6 then
		open()
	end
end)

local function createCard(parent, order, title)
	local holder = new("Frame", {
		Name = title or "Card",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = order,
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, holder)

	if title then
		new("TextLabel", {
			BackgroundTransparency = 1,
			Text = string.upper(title),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14),
		}, holder)
	end

	local card = new("Frame", {
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	}, holder)
	corner(card, 12)
	new("UIStroke", { Color = THEME.White, Transparency = 0.9, Thickness = 1 }, card)
	new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, card)
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	return card
end

local function createSlider(parent, order, label, min, max, default, suffix, callback)
	local holder = new("Frame", {
		Name = label,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = order,
	}, parent)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.65, 0, 0, 16),
	}, holder)

	local valueLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.65, 0),
		Size = UDim2.new(0.35, 0, 0, 16),
	}, holder)

	local track = new("Frame", {
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 6),
	}, holder)
	pill(track)

	local fill = new("Frame", {
		BackgroundColor3 = THEME.White,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
	}, track)
	pill(fill)
	new("UIGradient", { Color = ColorSequence.new(THEME.Accent, THEME.Accent2) }, fill)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.White,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
	}, track)
	pill(knob)

	local function setValue(v, silent)
		v = math.clamp(math.floor(v + 0.5), min, max)
		local ratio = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = tostring(v) .. suffix
		if not silent then callback(v) end
		return v
	end

	local function fromX(x)
		local w = track.AbsoluteSize.X
		if w <= 0 then return end
		local ratio = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
		setValue(min + ratio * (max - min))
	end

	makeDraggable(holder, function(pos) fromX(pos.X) end, function(_, pos) fromX(pos.X) end)
	callback(setValue(default, true))
	return holder
end

local function createToggle(parent, order, label, default, callback)
	local row = new("Frame", {
		Name = label,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
	}, parent)

	new("TextLabel", {
		BackgroundTransparency = 1,
		Text = label,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -50, 1, 0),
	}, row)

	local state = default
	local btn = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(40, 22),
		BackgroundColor3 = state and THEME.Accent or THEME.White,
		BackgroundTransparency = state and 0.1 or 0.85,
		BorderSizePixel = 0,
	}, row)
	pill(btn)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = THEME.White,
		BorderSizePixel = 0,
	}, btn)
	pill(knob)

	btn.Activated:Connect(function()
		state = not state
		tween(btn, { BackgroundColor3 = state and THEME.Accent or THEME.White, BackgroundTransparency = state and 0.1 or 0.85 })
		tween(knob, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
		callback(state)
	end)

	callback(state)
	return row
end

local ridKidCard = createCard(ridKidPage, 1, "Orbit 3D & Fling Control")

local hiddenfling = false
local flingPower = 10000
local antiFlingActive = false
local others = {}

local function getRoot(targetPlayer)
	local character = targetPlayer and targetPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local playerButton = new("TextButton", {
	Text = "Chọn người chơi ▾",
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	TextColor3 = THEME.Text,
	AutoButtonColor = false,
	BackgroundColor3 = THEME.White,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 32),
	LayoutOrder = 1,
}, ridKidCard)
corner(playerButton, 8)

local playerList = new("ScrollingFrame", {
	BackgroundTransparency = 0.1,
	BackgroundColor3 = THEME.Base,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 90),
	Visible = false,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 3,
	LayoutOrder = 2,
}, ridKidCard)
corner(playerList, 8)

local function refreshPlayers()
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local list = Players:GetPlayers()
	table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)

	local y = 0
	for _, p in ipairs(list) do
		if p ~= player then
			local b = new("TextButton", {
				Text = p.DisplayName .. " (@" .. p.Name .. ")",
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = THEME.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BackgroundColor3 = THEME.White,
				BackgroundTransparency = 0.92,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(4, y),
				Size = UDim2.new(1, -8, 0, 26),
			}, playerList)
			corner(b, 6)
			b.MouseButton1Click:Connect(function()
				env.selectedPlayer = p
				playerButton.Text = p.DisplayName .. " (@" .. p.Name .. ")"
				playerList.Visible = false
			end)
			y += 29
		end
	end
	playerList.CanvasSize = UDim2.fromOffset(0, y)
end

playerButton.MouseButton1Click:Connect(function()
	refreshPlayers()
	playerList.Visible = not playerList.Visible
end)

createSlider(ridKidCard, 3, "Bán kính Orbit", 1, 20, 5, "", function(v)
	env.orbitRadius = v
end)

createSlider(ridKidCard, 4, "Vòng/giây", 1, 999, 2, "", function(v)
	env.orbitSpin = v
end)

local actionToken = 0
local active = false

local startButton = new("TextButton", {
	Text = "TELE + XOAY 1.5 GIÂY",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.White,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(30, 115, 85),
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 34),
	LayoutOrder = 5,
}, ridKidCard)
corner(startButton, 8)

local stopButton = new("TextButton", {
	Text = "DỪNG",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.White,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(140, 65, 65),
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 34),
	LayoutOrder = 6,
}, ridKidCard)
corner(stopButton, 8)

startButton.MouseButton1Click:Connect(function()
	if active then return end
	local root = getRoot(player)
	local targetRoot = getRoot(env.selectedPlayer)
	if not env.selectedPlayer or not env.selectedPlayer.Parent or not root or not targetRoot then return end

	actionToken += 1
	local token = actionToken
	local originalCFrame = root.CFrame
	local originalCharacter = player.Character
	local target = env.selectedPlayer
	local radius = env.orbitRadius or 5
	local spin = env.orbitSpin or 2
	local startTime = os.clock()

	active = true
	task.spawn(function()
		while os.clock() - startTime < 1.5 do
			if actionToken ~= token or player.Character ~= originalCharacter then break end
			root = getRoot(player)
			targetRoot = getRoot(target)
			if not root or not targetRoot then break end

			local elapsed = os.clock() - startTime
			local angle = elapsed * spin * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			root.CFrame = CFrame.lookAt(targetRoot.Position + offset, targetRoot.Position)
			RunService.Heartbeat:Wait()
		end
		if root and player.Character == originalCharacter then
			root.CFrame = originalCFrame
		end
		active = false
	end)
end)

stopButton.MouseButton1Click:Connect(function()
	actionToken += 1
	active = false
end)

createSlider(ridKidCard, 7, "Touch Fling Power", 1000, 100000000000, 10000, "", function(v)
	flingPower = v
end)

createToggle(ridKidCard, 8, "Touch Fling", false, function(on)
	hiddenfling = on
end)

createToggle(ridKidCard, 9, "Anti Fling", false, function(on)
	antiFlingActive = on
end)

task.spawn(function()
	local hrp, c, vel = nil, nil, nil
	while true do
		RunService.Heartbeat:Wait()
		if hiddenfling then
			c = player.Character
			hrp = c and c:FindFirstChild("HumanoidRootPart")
			if hrp then
				vel = hrp.Velocity
				hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
				RunService.RenderStepped:Wait()
				if hrp and hrp.Parent then hrp.Velocity = vel end
			end
		end
	end
end)

task.spawn(function()
	while true do
		RunService.Heartbeat:Wait()
		if antiFlingActive then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.AssemblyLinearVelocity.Magnitude > 300 or hrp.AssemblyAngularVelocity.Magnitude > 300) then
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
		end
	end
end)
local playerCard = createCard(playerPage, 1, "Character Stats")

createSlider(playerCard, 1, "WalkSpeed (Tốc độ chạy)", 1, 1000, 16, "", function(v)
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
	end
end)

createSlider(playerCard, 2, "JumpPower (Độ nhảy cao)", 1, 1000, 50, "", function(v)
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
	end
end)

local visualCard = createCard(visualPage, 1, "ESP & Visual Highlights")

local espBoxEnabled = false
local espLineEnabled = false
local espObjects = {}

local function createESP(targetPlayer)
	if targetPlayer == player then return end
	local box = Drawing.new("Square")
	box.Thickness = 1.5
	box.Color = Color3.fromRGB(255, 50, 50)
	box.Filled = false
	box.Visible = false

	local line = Drawing.new("Line")
	line.Thickness = 1.5
	line.Color = Color3.fromRGB(50, 255, 100)
	line.Visible = false

	espObjects[targetPlayer] = { Box = box, Line = line }
end

local function removeESP(targetPlayer)
	if espObjects[targetPlayer] then
		pcall(function()
			espObjects[targetPlayer].Box:Remove()
			espObjects[targetPlayer].Line:Remove()
		end)
		espObjects[targetPlayer] = nil
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	createESP(p)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

connect(RunService.RenderStepped, function()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	for p, draw in pairs(espObjects) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			local hrp = p.Character.HumanoidRootPart
			local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

			if onScreen then
				if espBoxEnabled then
					local size = (camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y)
					draw.Box.Size = Vector2.new(math.abs(size * 0.6), math.abs(size))
					draw.Box.Position = Vector2.new(pos.X - draw.Box.Size.X / 2, pos.Y - draw.Box.Size.Y / 2)
					draw.Box.Visible = true
				else
					draw.Box.Visible = false
				end

				if espLineEnabled then
					draw.Line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
					draw.Line.To = Vector2.new(pos.X, pos.Y)
					draw.Line.Visible = true
				else
					draw.Line.Visible = false
				end
			else
				draw.Box.Visible = false
				draw.Line.Visible = false
			end
		else
			draw.Box.Visible = false
			draw.Line.Visible = false
		end
	end
end)

createToggle(visualCard, 1, "ESP Box", false, function(on)
	espBoxEnabled = on
end)

createToggle(visualCard, 2, "ESP Line", false, function(on)
	espLineEnabled = on
end)
createToggle(visualCard, 3, "Fullbright", false, function(on)
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
		Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
	end
end)

local miscCard = createCard(miscPage, 1, "Utilities")
local function addButton(parent, order, text, callback)
	local b = new("TextButton", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = THEME.Text,
		AutoButtonColor = false,
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = order,
	}, parent)
	corner(b, 8)
	b.Activated:Connect(callback)
	return b
end

addButton(miscCard, 1, "Rejoin Server", function()
	game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

addButton(miscCard, 2, "Copy Discord Link", function()
	if setclipboard then setclipboard("https://discord.gg/9BW4PvXaJr") end
end)

local appearance = createCard(settingsPage, 1, "Appearance")
createSlider(appearance, 1, "Glass transparency", 5, 90, 42, "%", function(v)
	main.BackgroundTransparency = v / 100
end)
createSlider(appearance, 2, "Scale", 70, 150, 100, "%", function(v)
	userScale = v / 100
	uiScale.Scale = userScale
end)
local optimizeCard = createCard(optimizePage, 1, "Optimization & Performance")

local fpsBoosterEnabled = false
local fpsOriginals = setmetatable({}, {__mode = "k"})

createToggle(optimizeCard, 1, "Tăng FPS (FPS Booster)", false, function(on)
	fpsBoosterEnabled = on
	if on then
		pcall(function() setfpscap(999) end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				fpsOriginals[v] = { CastShadow = v.CastShadow }
				v.CastShadow = false
			end
		end
	else
		pcall(function() setfpscap(60) end)
		for inst, props in pairs(fpsOriginals) do
			if inst and inst.Parent then
				inst.CastShadow = props.CastShadow
			end
		end
		table.clear(fpsOriginals)
	end
end)

local fixLag1Enabled = false
createToggle(optimizeCard, 2, "Fix Lag 1 (Low Quality)", false, function(on)
	fixLag1Enabled = on
	if on then
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			Lighting.GlobalShadows = false
		end)
	else
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			Lighting.GlobalShadows = true
		end)
	end
end)

local meowEnabled = false
local savedProps = {}

createToggle(optimizeCard, 3, "Fix Lag 2 (Meow Extreme Max)", false, function(on)
	meowEnabled = on
	if on then
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Decal") then
				savedProps[v] = v.Enabled or v.Transparency
				pcall(function() v.Enabled = false end)
				pcall(function() v.Transparency = 1 end)
			elseif v:IsA("BasePart") and not v:IsA("Terrain") then
				savedProps[v] = { Material = v.Material, Reflectance = v.Reflectance }
				v.Material = Enum.Material.SmoothPlastic
				v.Reflectance = 0
			end
		end
	else
		for inst, prop in pairs(savedProps) do
			if inst and inst.Parent then
				if type(prop) == "table" then
					inst.Material = prop.Material
					inst.Reflectance = prop.Reflectance
				else
					pcall(function() inst.Enabled = prop end)
					pcall(function() inst.Transparency = prop end)
				end
			end
		end
		table.clear(savedProps)
	end
end)

env.__GlassUIOptimizerCleanup = function()
	for _, draw in pairs(espObjects) do
		pcall(function()
			draw.Box:Remove()
			draw.Line:Remove()
		end)
	end
	table.clear(espObjects)
end

do
	local frames, elapsed = 0, 0
	connect(RunService.RenderStepped, function(dt)
		frames += 1
		elapsed += dt
		if elapsed >= 0.5 then
			local fps = math.floor(frames / elapsed + 0.5)
			fpsLabel.Text = fps .. " FPS"
			fpsLabel.TextColor3 = fps >= 50 and THEME.Good or (fps >= 30 and THEME.Warn or THEME.Danger)
			frames, elapsed = 0, 0
		end
	end)
end
