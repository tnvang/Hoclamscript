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

local playerPage = newPage()
local visualPage = newPage()
local miscPage = newPage()
local settingsPage = newPage()
local optimizePage = newPage()
local ridKidPage = newPage()

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
			if onBegin then
				onBegin(startPos)
			end
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End and activeInput == input then
					dragging = false
					if onEnd then
						onEnd(lastDelta.Magnitude)
					end
				end
			end)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and input == activeInput) then
			local pos = p2(input)
			lastDelta = pos - startPos
			onDrag(lastDelta, pos)
		end
	end)
end

local function clampPosition(x, y)
	local v = viewport()
	local w = fullSize.X * userScale
	x = math.clamp(x, -w + 80, v.X - 80)
	y = math.clamp(y, 0, v.Y - CONFIG.Topbar * userScale)
	return x, y
end

local dragOrigin = Vector2.zero
makeDraggable(topbar, function()
	dragOrigin = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
end, function(delta)
	local x, y = clampPosition(dragOrigin.X + delta.X, dragOrigin.Y + delta.Y)
	main.Position = UDim2.fromOffset(x, y)
end, function()
	winPos = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
end)

local function createCard(parent, order, title)
	local holder = new("Frame", {
		Name = title or "Card",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = order,
	}, parent)
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)

	if title then
		new("TextLabel", {
			BackgroundTransparency = 1,
			Text = string.upper(title),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 14),
			LayoutOrder = 0,
		}, holder)
	end

	local card = new("Frame", {
		BackgroundColor3 = THEME.White,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
	}, holder)
	corner(card, 12)
	new("UIStroke", { Color = THEME.White, Transparency = 0.9, Thickness = 1 }, card)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, card)
	new("UIListLayout", {
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)
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
	new("UIStroke", { Color = THEME.Accent, Thickness = 2, Transparency = 0.2 }, knob)

	local function setValue(v, silent)
		v = math.clamp(math.floor(v + 0.5), min, max)
		local ratio = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = v .. suffix
		if not silent then
			callback(v)
		end
		return v
	end

	local function fromX(x)
		local w = track.AbsoluteSize.X
		if w <= 0 then
			return
		end
		local ratio = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
		setValue(min + ratio * (max - min))
	end

	makeDraggable(holder, function(pos)
		fromX(pos.X)
	end, function(_, pos)
		fromX(pos.X)
	end)

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
		tween(btn, {
			BackgroundColor3 = state and THEME.Accent or THEME.White,
			BackgroundTransparency = state and 0.1 or 0.85,
		})
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

if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
	local detection = Instance.new("Decal")
	detection.Name = "juisdfj0i32i0eidsuf0iok"
	detection.Parent = ReplicatedStorage
end

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
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)

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

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p)
	if env.selectedPlayer == p then
		env.selectedPlayer = nil
		playerButton.Text = "Chọn người chơi ▾"
	end
	refreshPlayers()
end)

createSlider(ridKidCard, 3, "Bán kính Orbit", 3, 12, 5, "", function(v)
	env.orbitRadius = v
end)
createSlider(ridKidCard, 4, "Vòng/giây", 1, 8, 2, "", function(v)
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
	if active then
		return
	end
	local root = getRoot(player)
	local targetRoot = getRoot(env.selectedPlayer)

	if not env.selectedPlayer or not env.selectedPlayer.Parent or not root or not targetRoot then
		return
	end

	actionToken += 1
	local token = actionToken
	local originalCFrame = root.CFrame
	local originalCharacter = player.Character
	local target = env.selectedPlayer
	local radius = env.orbitRadius or 5
	local spin = env.orbitSpin or 2
	local duration = 1.5
	local startTime = os.clock()

	active = true
	root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -radius)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	task.spawn(function()
		while os.clock() - startTime < duration do
			if actionToken ~= token then
				return
			end
			if player.Character ~= originalCharacter then
				active = false
				return
			end
			root = getRoot(player)
			targetRoot = getRoot(target)
			if not root or not targetRoot then
				active = false
				return
			end

			local elapsed = os.clock() - startTime
			local angle = elapsed * spin * math.pi * 2
			local wobble = math.sin(elapsed * 18) * 0.65
			local offset = Vector3.new(math.cos(angle) * radius, wobble, math.sin(angle) * radius)
			local position = targetRoot.Position + offset

			root.CFrame = CFrame.lookAt(position, targetRoot.Position)
			RunService.Heartbeat:Wait()
		end

		if actionToken ~= token then
			return
		end
		root = getRoot(player)
		if root and player.Character == originalCharacter then
			root.CFrame = originalCFrame
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		active = false
	end)
end)

stopButton.MouseButton1Click:Connect(function()
	actionToken += 1
	active = false
end)

createToggle(ridKidCard, 7, "Touch Fling", false, function(on)
	hiddenfling = on
end)

createToggle(ridKidCard, 8, "Anti Fling", false, function(on)
	if on then
		if not antiFlingActive then
			antiFlingActive = true
			for _, p in ipairs(Players:GetPlayers()) do
				others[p] = { parts = {}, set = {}, flagged = -1000 }
			end
		end
	else
		if antiFlingActive then
			antiFlingActive = false
			table.clear(others)
		end
	end
end)

task.spawn(function()
	local hrp, c, vel, movel = nil, nil, nil, 0.1
	while true do
		RunService.Heartbeat:Wait()
		if hiddenfling then
			while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
				RunService.Heartbeat:Wait()
				c = player.Character
				hrp = c and c:FindFirstChild("HumanoidRootPart")
			end

			if hiddenfling and hrp then
				vel = hrp.Velocity
				hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
				RunService.RenderStepped:Wait()
				if c and c.Parent and hrp and hrp.Parent then
					hrp.Velocity = vel
				end
				RunService.Stepped:Wait()
				if c and c.Parent and hrp and hrp.Parent then
					hrp.Velocity = vel + Vector3.new(0, movel, 0)
					movel = movel * -1
				end
			end
		end
	end
end)
-- Player Page
local playerCard = createCard(playerPage, 1, "Character Stats")
createSlider(playerCard, 1, "WalkSpeed", 16, 150, 16, "", function(v)
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
	end
end)
createSlider(playerCard, 2, "JumpPower", 50, 300, 50, "", function(v)
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").JumpPower = v
	end
end)

-- Visuals Page
local visualCard = createCard(visualPage, 1, "ESP & Rendering")
createToggle(visualCard, 1, "Fullbright", false, function(on)
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

-- Misc Page
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
	b.MouseEnter:Connect(function()
		tween(b, { BackgroundTransparency = 0.8 })
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundTransparency = 0.9 })
	end)
	b.Activated:Connect(callback)
	return b
end

addButton(miscCard, 1, "Rejoin Server", function()
	local ts = game:GetService("TeleportService")
	ts:Teleport(game.PlaceId, player)
end)

addButton(miscCard, 2, "Copy Discord Link", function()
	if setclipboard then
		setclipboard("https://discord.gg/9BW4PvXaJr")
	end
end)

-- Settings Page
local appearance = createCard(settingsPage, 1, "Appearance")
createSlider(appearance, 1, "Glass transparency", 5, 90, 42, "%", function(v)
	main.BackgroundTransparency = v / 100
end)
createSlider(appearance, 2, "Scale", 70, 150, 100, "%", function(v)
	userScale = v / 100
	uiScale.Scale = userScale
end)

local options = createCard(settingsPage, 2, "Options")
createToggle(options, 1, "Glow border", true, function(on)
	stroke.Enabled = on
end)
createToggle(options, 2, "Glass shine", true, function(on)
	shine.Visible = on
end)
createToggle(options, 3, "Show FPS", true, function(on)
	fpsPill.Visible = on
end)
-- Optimize Page
local optimizeCard = createCard(optimizePage, 1, "Optimization & Performance")
local meowEnabled = false
local generation = 0
local saved = {}
local detached = {}
local processed = setmetatable({}, {__mode = "k"})
local optimizeConnections = {}
local scanConnection
local originalQuality

local function remember(object, property, value)
	local properties = saved[object]
	if not properties then
		properties = {}
		saved[object] = properties
	end
	if properties[property] == nil then
		local ok, original = pcall(function()
			return object[property]
		end)
		if not ok then
			return
		end
		properties[property] = original
	end
	pcall(function()
		object[property] = value
	end)
end

local function isCharacter(object)
	local current = object
	while current and current ~= Workspace do
		if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function disconnectOptimizeConns()
	for _, connection in ipairs(optimizeConnections) do
		connection:Disconnect()
	end
	table.clear(optimizeConnections)
	if scanConnection then
		scanConnection:Disconnect()
		scanConnection = nil
	end
end

local function detach(object)
	if detached[object] or not object.Parent then
		return
	end
	detached[object] = object.Parent
	pcall(function()
		object.Parent = nil
	end)
end

local function optimizeObject(object)
	if not meowEnabled or processed[object] then
		return
	end
	if isCharacter(object) then
		return
	end
	processed[object] = true

	if object:IsA("Sky") then
		detach(object)
		return
	end
	if object:IsA("Atmosphere") then
		remember(object, "Density", 0)
		remember(object, "Haze", 0)
		remember(object, "Glare", 0)
		return
	end
	if object:IsA("Clouds") then
		remember(object, "Enabled", false)
		remember(object, "Cover", 0)
		remember(object, "Density", 0)
		return
	end
	if object:IsA("PostEffect") then
		remember(object, "Enabled", false)
		return
	end
	if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
		remember(object, "Enabled", false)
		return
	end
	if object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
		remember(object, "Enabled", false)
		remember(object, "Shadows", false)
		return
	end
	if object:IsA("Decal") or object:IsA("Texture") then
		remember(object, "Transparency", 1)
		return
	end
	if object:IsA("SurfaceAppearance") then
		detach(object)
		return
	end
	if object:IsA("BasePart") then
		remember(object, "CastShadow", false)
		remember(object, "Reflectance", 0)
		remember(object, "Material", Enum.Material.SmoothPlastic)
		return
	end
end

local function restoreAll()
	disconnectOptimizeConns()
	for object, properties in pairs(saved) do
		for property, original in pairs(properties) do
			pcall(function()
				object[property] = original
			end)
		end
	end
	for object, parent in pairs(detached) do
		pcall(function()
			if object.Parent == nil and parent and parent.Parent ~= nil then
				object.Parent = parent
			end
		end)
	end
	if originalQuality then
		pcall(function()
			Lighting.Technology = originalQuality
		end)
		originalQuality = nil
	end
	table.clear(saved)
	table.clear(detached)
	processed = setmetatable({}, {__mode = "k"})
end

createToggle(optimizeCard, 1, "Extreme Fix Lag", false, function(on)
	meowEnabled = on
	if on then
		generation += 1
		local token = generation
		saved = {}
		detached = {}
		processed = setmetatable({}, {__mode = "k"})
		pcall(function()
			originalQuality = Lighting.Technology
		end)
		remember(Lighting, "GlobalShadows", false)
		remember(Lighting, "EnvironmentDiffuseScale", 0)
		remember(Lighting, "EnvironmentSpecularScale", 0)
		remember(Lighting, "FogEnd", 1000000)

		local terrain = Workspace.Terrain
		remember(terrain, "Decoration", false)
		remember(terrain, "WaterWaveSize", 0)
		remember(terrain, "WaterWaveSpeed", 0)
		remember(terrain, "WaterReflectance", 0)

		scanConnection = Workspace.DescendantAdded:Connect(function(object)
			if meowEnabled and generation == token then
				optimizeObject(object)
			end
		end)

		table.insert(optimizeConnections, Lighting.DescendantAdded:Connect(function(object)
			if meowEnabled and generation == token then
				optimizeObject(object)
			end
		end))

		local objects = Workspace:GetDescendants()
		for _, object in ipairs(Lighting:GetDescendants()) do
			objects[#objects + 1] = object
		end

		local total = #objects
		local index = 1

		task.spawn(function()
			while index <= total do
				if not meowEnabled or generation ~= token then
					return
				end
				local batchStart = os.clock()
				local count = 0
				while index <= total and count < 200 do
					optimizeObject(objects[index])
					index += 1
					count += 1
					if os.clock() - batchStart >= 0.008 then
						break
					end
				end
				task.wait()
			end
		end)
	else
		generation += 1
		restoreAll()
	end
end)

env.__GlassUIOptimizerCleanup = function()
	if meowEnabled then
		meowEnabled = false
		generation += 1
		restoreAll()
	end
	disconnectOptimizeConns()
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
