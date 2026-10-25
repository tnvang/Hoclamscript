local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait()
	LocalPlayer = Players.LocalPlayer
end

if _G.RidKidHub_Cleanup then
	pcall(_G.RidKidHub_Cleanup)
	_G.RidKidHub_Cleanup = nil
end

local CONFIG = {
	Name = "RidKid Hub",
	Version = "v1.0",
	LogoId = "rbxassetid://130920436247899",
	ToggleKey = Enum.KeyCode.RightShift,
	Size = Vector2.new(580, 360),
}

local THEME = {
	Background = Color3.fromRGB(9, 8, 26),
	Panel = Color3.fromRGB(22, 18, 50),
	Accent = Color3.fromRGB(139, 92, 246),
	Accent2 = Color3.fromRGB(56, 189, 248),
	Accent3 = Color3.fromRGB(244, 114, 182),
	Text = Color3.fromRGB(240, 238, 255),
	SubText = Color3.fromRGB(160, 155, 205),
	Off = Color3.fromRGB(55, 50, 95),
	Danger = Color3.fromRGB(239, 68, 68),
	Good = Color3.fromRGB(77, 255, 145),
	Lime = Color3.fromRGB(216, 255, 92),
	Peri = Color3.fromRGB(128, 136, 255),
	Cyan = Color3.fromRGB(123, 255, 240),
	Orange = Color3.fromRGB(255, 130, 40),
	Pink = Color3.fromRGB(255, 61, 245),
	Lav = Color3.fromRGB(197, 139, 232),
	Red = Color3.fromRGB(224, 40, 20),
	Ink = Color3.fromRGB(10, 10, 14),
}

local WHITE = Color3.fromRGB(255, 255, 255)
local W, H = CONFIG.Size.X, CONFIG.Size.Y

local connections = {}

local function track(conn)
	connections[#connections + 1] = conn
	return conn
end

local function new(class, props)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = radius or UDim.new(0, 8), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function gradient(parent, colors, rotation)
	local keys = {}
	for i, c in ipairs(colors) do
		keys[i] = ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c)
	end
	return new("UIGradient", {
		Color = ColorSequence.new(keys),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

local function label(parent, props)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return new("TextLabel", base)
end

local function tween(obj, duration, props, style, direction)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local orders = setmetatable({}, { __mode = "k" })
local function nextOrder(page)
	orders[page] = (orders[page] or 0) + 1
	return orders[page]
end

local function resolveParent()
	local okHui, hui = pcall(function()
		return gethui()
	end)
	if okHui and typeof(hui) == "Instance" then
		return hui
	end
	local okCore, core = pcall(function()
		local c = game:GetService("CoreGui")
		local probe = Instance.new("Folder")
		probe.Parent = c
		probe:Destroy()
		return c
	end)
	if okCore and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function getBaseScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if vp.X < 100 or vp.Y < 100 then
		vp = Vector2.new(1280, 720)
	end
	return math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.5, 1)
end

local mode = "booting"
local setMode
local destroyUI

local Gui = new("ScreenGui", {
	Name = "RidKidHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
})

pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(Gui)
	end
end)

local parentTarget = resolveParent()
local oldGui = parentTarget:FindFirstChild("RidKidHub")
if oldGui then
	oldGui:Destroy()
end
Gui.Parent = parentTarget

local notificationsEnabled = true
local notifyCount = 0

local NotifyHolder = new("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.fromOffset(240, 300),
	BackgroundTransparency = 1,
	Parent = Gui,
})
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Parent = NotifyHolder,
})

local function notify(title, text, duration)
	if not notificationsEnabled then
		return
	end
	duration = duration or 2.2
	notifyCount = notifyCount + 1

	local wrapper = new("Frame", {
		Size = UDim2.fromOffset(240, 56),
		BackgroundTransparency = 1,
		LayoutOrder = notifyCount,
		Parent = NotifyHolder,
	})
	local card = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(1, 270, 0, 0),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Parent = wrapper,
	})
	corner(card, UDim.new(0, 10))
	local s = stroke(card, WHITE, 1.2, 0.1)
	gradient(s, { THEME.Accent, THEME.Accent2 }, 0)

	local bar = new("Frame", {
		Position = UDim2.new(0, 8, 0, 10),
		Size = UDim2.new(0, 3, 1, -20),
		BackgroundColor3 = THEME.Accent2,
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(bar, UDim.new(1, 0))

	label(card, {
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.new(1, -28, 0, 18),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(card, {
		Position = UDim2.fromOffset(20, 28),
		Size = UDim2.new(1, -28, 0, 18),
		Text = text,
		TextSize = 12,
		TextColor3 = THEME.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	tween(card, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(duration, function()
		if card.Parent then
			tween(card, 0.3, { Position = UDim2.new(1, 270, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.35, function()
			if wrapper and wrapper.Parent then
				wrapper:Destroy()
			end
		end)
	end)
end

local function makeDraggable(handle, target, onTap, onDrag)
	local dragging = false
	local activeInput = nil
	local dragStart = Vector2.new()
	local startPos = target.Position
	local startAbs = Vector2.new()
	local moved = false

	track(handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			moved = false
			activeInput = input
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = target.Position
			startAbs = target.AbsolutePosition
		end
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
			or (input.UserInputType == Enum.UserInputType.Touch and input == activeInput)
		if not isMove then
			return
		end

		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
		if not moved and delta.Magnitude < 4 then
			return
		end
		moved = true
		if onDrag then
			onDrag()
		end

		local dx, dy = delta.X, delta.Y
		local screen = Gui.AbsoluteSize
		if screen.X > 0 and screen.Y > 0 then
			local size = target.AbsoluteSize
			local margin = math.min(80, size.X * 0.5, size.Y * 0.5)
			local nx = math.clamp(startAbs.X + dx, margin - size.X, screen.X - margin)
			local ny = math.clamp(startAbs.Y + dy, 0, screen.Y - margin)
			dx = nx - startAbs.X
			dy = ny - startAbs.Y
		end

		target.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + dx,
			startPos.Y.Scale,
			startPos.Y.Offset + dy
		)
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if not dragging or not activeInput then
			return
		end
		local ended = (input == activeInput)
			or (
				activeInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		if ended then
			dragging = false
			if not moved and onTap then
				onTap()
			end
		end
	end))
end

local function createLogo(parent, size)
	local frame = new("Frame", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = parent,
	})
	corner(frame, UDim.new(1, 0))
	gradient(frame, { THEME.Accent, THEME.Accent2 }, 45)

	local fallback = label(frame, {
		Size = UDim2.fromScale(1, 1),
		Text = "R",
		Font = Enum.Font.GothamBlack,
		TextSize = math.floor(size * 0.55),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local img = new("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = CONFIG.LogoId,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 2,
		Parent = frame,
	})
	corner(img, UDim.new(1, 0))

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ img })
		end)
		task.wait(0.2)
		if img.Parent and img.IsLoaded then
			fallback.Visible = false
			frame.BackgroundTransparency = 1
		end
	end)

	return frame
end

local Holder = new("Frame", {
	Name = "Holder",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1,
	Parent = Gui,
})

local Main = new("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
	Active = true,
	ClipsDescendants = true,
	Parent = Holder,
})
local MainScale = new("UIScale", { Scale = 0.01, Parent = Main })
corner(Main, UDim.new(0, 14))

local bgGradient = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 6, 24)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 12, 54)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 16, 40)),
	}),
	Rotation = 90,
	Parent = Main,
})

local borderStroke = stroke(Main, WHITE, 1.6, 0)
local borderGradient = gradient(borderStroke, { THEME.Accent, THEME.Accent2, THEME.Accent3, THEME.Accent }, 0)

local Space
do
	local ok, cg = pcall(Instance.new, "CanvasGroup")
	Space = (ok and cg) or Instance.new("Frame")
	Space.Name = "Space"
	Space.Size = UDim2.fromScale(1, 1)
	Space.BackgroundTransparency = 1
	Space.BorderSizePixel = 0
	Space.ClipsDescendants = true
	Space.ZIndex = 1
	Space.Parent = Main
	corner(Space, UDim.new(0, 14))
end

local GlowLayer = new("Frame", {
	Name = "Glows",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = Space,
})
local StarLayer = new("Frame", {
	Name = "Stars",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = Space,
})

local rng = Random.new()

local glows = {}
local function createGlow(color, size, bx, by, phase)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(bx, by),
		BackgroundTransparency = 1,
		Parent = GlowLayer,
	})
	for i = 1, 8 do
		local s = 1 - (i - 1) * 0.115
		local layer = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(s, s),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.96,
			BorderSizePixel = 0,
			Parent = holder,
		})
		corner(layer, UDim.new(1, 0))
	end
	glows[#glows + 1] = { frame = holder, bx = bx, by = by, phase = phase }
end
createGlow(THEME.Accent, 320, 0.12, 0.2, 0)
createGlow(THEME.Accent2, 280, 0.9, 0.85, 2)
createGlow(THEME.Accent3, 220, 0.75, 0.08, 4)

local starColors = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(190, 215, 255),
	Color3.fromRGB(220, 195, 255),
	Color3.fromRGB(255, 232, 205),
}
local stars = {}
local STAR_COUNT = 75

for _ = 1, STAR_COUNT do
	local layer = rng:NextInteger(1, 3)
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(layer, layer),
		BackgroundColor3 = starColors[rng:NextInteger(1, #starColors)],
		BorderSizePixel = 0,
		Parent = StarLayer,
	})
	corner(frame, UDim.new(1, 0))
	stars[#stars + 1] = {
		frame = frame,
		x = rng:NextNumber(0, 1),
		y = rng:NextNumber(0, 1),
		speed = (0.01 + 0.02 * layer) * rng:NextNumber(0.8, 1.25),
		twinkle = rng:NextNumber(1, 3.5),
		phase = rng:NextNumber(0, 6.28),
		bright = 0.55 + layer * 0.15,
	}
end

local starSpeedMul = 1
local shootingEnabled = true
local shootTimer = 2

local function updateStars(dt, t)
	for _, s in ipairs(stars) do
		s.x = s.x - s.speed * starSpeedMul * dt
		s.y = s.y + s.speed * 0.25 * starSpeedMul * dt
		if s.x < -0.02 then
			s.x = 1.02
			s.y = rng:NextNumber(0, 1)
		end
		if s.y > 1.02 then
			s.y = -0.02
		end
		local tw = 0.5 + 0.5 * math.sin(t * s.twinkle + s.phase)
		local edge = math.clamp(math.min(s.x, 1 - s.x, s.y, 1 - s.y) / 0.05, 0, 1)
		local alpha = (0.25 + 0.75 * tw) * s.bright * edge
		s.frame.Position = UDim2.fromScale(s.x, s.y)
		s.frame.BackgroundTransparency = 1 - math.clamp(alpha, 0, 1)
	end
end

local function spawnShootingStar()
	local sx = rng:NextNumber(0.4, 1.0)
	local sy = rng:NextNumber(-0.05, 0.35)
	local star = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(95, 2),
		Position = UDim2.fromScale(sx, sy),
		Rotation = 155,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = StarLayer,
	})
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = star,
	})
	tween(star, 0.2, { BackgroundTransparency = 0 })
	tween(star, 1.1, { Position = UDim2.fromScale(sx - 0.6, sy + 0.45) }, Enum.EasingStyle.Linear)
	task.delay(0.7, function()
		if star.Parent then
			tween(star, 0.4, { BackgroundTransparency = 1 })
		end
	end)
	task.delay(1.2, function()
		if star.Parent then
			star:Destroy()
		end
	end)
end
local Content = new("Frame", {
	Name = "Content",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = Main,
})

local TopBar = new("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	Active = true,
	Parent = Content,
})

local Divider = new("Frame", {
	Position = UDim2.new(0, 12, 1, -1),
	Size = UDim2.new(1, -24, 0, 1),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
	Parent = TopBar,
})
new("UIGradient", {
	Color = ColorSequence.new(THEME.Accent, THEME.Accent2),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	}),
	Parent = Divider,
})

local TopLogo = createLogo(TopBar, 32)
TopLogo.Position = UDim2.fromOffset(14, 9)

local Title = label(TopBar, {
	Position = UDim2.fromOffset(54, 6),
	Size = UDim2.fromOffset(0, 22),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = CONFIG.Name,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
})
local titleGradient = gradient(Title, { WHITE, THEME.Accent2, THEME.Accent, THEME.Accent3 }, 0)

label(TopBar, {
	Position = UDim2.fromOffset(54, 27),
	Size = UDim2.fromOffset(220, 14),
	Text = "SPACE EDITION  |  " .. CONFIG.Version,
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = THEME.SubText,
})

local function barIcon(parent, rotation, width)
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, 2),
		Rotation = rotation,
		BackgroundColor3 = THEME.Text,
		BorderSizePixel = 0,
		Parent = parent,
	})
	corner(bar, UDim.new(1, 0))
	return bar
end

local function createTopButton(offsetRight, hoverColor, buildIcon, onClick)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -offsetRight, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.3,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = TopBar,
	})
	corner(btn, UDim.new(0, 8))
	stroke(btn, THEME.Accent, 1, 0.7)
	buildIcon(btn)
	track(btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0 })
	end))
	track(btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundColor3 = THEME.Panel, BackgroundTransparency = 0.3 })
	end))
	track(btn.MouseButton1Click:Connect(onClick))
	return btn
end

createTopButton(12, THEME.Danger, function(btn)
	barIcon(btn, 45, 14)
	barIcon(btn, -45, 14)
end, function()
	destroyUI()
end)

createTopButton(48, THEME.Accent, function(btn)
	barIcon(btn, 0, 12)
end, function()
	setMode("min")
end)

makeDraggable(TopBar, Holder)

local Sidebar = new("Frame", {
	Name = "Sidebar",
	Position = UDim2.fromOffset(12, 60),
	Size = UDim2.new(0, 128, 1, -72),
	BackgroundColor3 = THEME.Panel,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = Content,
})
corner(Sidebar, UDim.new(0, 12))
stroke(Sidebar, THEME.Accent, 1, 0.75)

local TabList = new("Frame", {
	Size = UDim2.new(1, 0, 1, -30),
	BackgroundTransparency = 1,
	Parent = Sidebar,
})
new("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	Parent = TabList,
})
new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = TabList,
})

label(Sidebar, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 0, 1, -6),
	Size = UDim2.new(1, 0, 0, 16),
	Text = "RidKid Hub " .. CONFIG.Version,
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = THEME.SubText,
	TextXAlignment = Enum.TextXAlignment.Center,
})

local Pages = new("Frame", {
	Name = "Pages",
	Position = UDim2.fromOffset(150, 60),
	Size = UDim2.new(1, -162, 1, -72),
	BackgroundTransparency = 1,
	Parent = Content,
})

local function createPage()
	local page = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = Pages,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	new("UIPadding", {
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 4),
		Parent = page,
	})
	return page
end

local tabs = {}
local currentTab = nil

local function selectTab(tab)
	if currentTab == tab then
		return
	end
	currentTab = tab
	for _, t in ipairs(tabs) do
		local active = (t == tab)
		t.page.Visible = active
		tween(t.button, 0.2, {
			BackgroundTransparency = active and 0.2 or 1,
			TextColor3 = active and WHITE or THEME.SubText,
		})
	end
end

local function createTab(name, page)
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Accent,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		LayoutOrder = #tabs + 1,
		Parent = TabList,
	})
	corner(btn, UDim.new(0, 8))
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = btn })

	local tab = { button = btn, page = page }
	tabs[#tabs + 1] = tab

	track(btn.MouseEnter:Connect(function()
		if currentTab ~= tab then
			tween(btn, 0.15, { BackgroundTransparency = 0.75 })
		end
	end))
	track(btn.MouseLeave:Connect(function()
		if currentTab ~= tab then
			tween(btn, 0.15, { BackgroundTransparency = 1 })
		end
	end))
	track(btn.MouseButton1Click:Connect(function()
		selectTab(tab)
	end))
	return tab
end

local function createSection(page, text)
	return label(page, {
		Size = UDim2.new(1, 0, 0, 20),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = THEME.Accent2,
		LayoutOrder = nextOrder(page),
	})
end

local function createInfo(page, name, value)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, UDim.new(0, 8))
	label(row, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.45, -12, 1, 0),
		Text = name,
		TextColor3 = THEME.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	return label(row, {
		Position = UDim2.new(0.45, 0, 0, 0),
		Size = UDim2.new(0.55, -12, 1, 0),
		Text = value,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

local function createNote(page, text, color)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, UDim.new(0, 10))
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = row,
	})
	return label(row, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = color or THEME.SubText,
		TextSize = 12,
	})
end

local function safeCall(name, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[RidKid Hub] " .. tostring(name) .. ": " .. tostring(err))
	end
end

local function createToggle(page, name, desc, default, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, UDim.new(0, 10))
	local rowStroke = stroke(row, THEME.Accent, 1, 0.8)

	label(row, {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -78, 0, 18),
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(row, {
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -78, 0, 14),
		Text = desc,
		TextSize = 11,
		TextColor3 = THEME.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local trackFrame = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = THEME.Off,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(trackFrame, UDim.new(1, 0))

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = trackFrame,
	})
	corner(knob, UDim.new(1, 0))

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})

	local state = default and true or false
	local function render(animate)
		local d = animate and 0.2 or 0
		tween(trackFrame, d, { BackgroundColor3 = state and THEME.Accent or THEME.Off })
		tween(knob, d, {
			Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		})
	end
	render(false)

	track(hit.MouseEnter:Connect(function()
		tween(row, 0.15, { BackgroundTransparency = 0.15 })
		tween(rowStroke, 0.15, { Transparency = 0.5 })
	end))
	track(hit.MouseLeave:Connect(function()
		tween(row, 0.15, { BackgroundTransparency = 0.35 })
		tween(rowStroke, 0.15, { Transparency = 0.8 })
	end))
	track(hit.MouseButton1Click:Connect(function()
		state = not state
		render(true)
		safeCall(name, callback, state)
	end))

	return {
		Set = function(v)
			state = v and true or false
			render(true)
		end,
		Get = function()
			return state
		end,
	}
end

local function buildButton(parent, text, color, callback, size, order)
	color = color or THEME.Accent
	local btn = new("TextButton", {
		Size = size,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = THEME.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	corner(btn, UDim.new(0, 10))
	stroke(btn, color, 1, 0.3)

	track(btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.3 })
	end))
	track(btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.55 })
	end))
	track(btn.MouseButton1Click:Connect(function()
		tween(btn, 0.08, { BackgroundTransparency = 0 })
		task.delay(0.1, function()
			if btn.Parent then
				tween(btn, 0.2, { BackgroundTransparency = 0.3 })
			end
		end)
		safeCall(text, callback)
	end))
	return btn
end

local function createButton(page, text, color, callback)
	return buildButton(page, text, color, callback, UDim2.new(1, 0, 0, 40), nextOrder(page))
end

local function createButtonRow(page, defs)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local n = #defs
	for i, d in ipairs(defs) do
		buildButton(row, d[1], d[2], d[3], UDim2.new(1 / n, -8 * (n - 1) / n, 1, 0), i)
	end
	return row
end

local function createSlider(page, name, min, max, default, callback)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Accent, 1, 0.8)

	label(row, {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -90, 0, 18),
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
	})
	local valueLabel = label(row, {
		Position = UDim2.new(1, -72, 0, 8),
		Size = UDim2.fromOffset(60, 18),
		Text = tostring(default),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = THEME.Accent2,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local bar = new("Frame", {
		Position = UDim2.new(0, 12, 0, 40),
		Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = THEME.Off,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(bar, UDim.new(1, 0))

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = bar,
	})
	corner(fill, UDim.new(1, 0))
	gradient(fill, { THEME.Accent, THEME.Accent2 }, 0)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = bar,
	})
	corner(knob, UDim.new(1, 0))
	stroke(knob, THEME.Accent, 2, 0)

	local hit = new("TextButton", {
		Position = UDim2.new(0, 6, 0, 30),
		Size = UDim2.new(1, -12, 0, 26),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})

	local function apply(ratio, fire)
		ratio = math.clamp(ratio, 0, 1)
		local value = math.floor(min + (max - min) * ratio + 0.5)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		if fire then
			safeCall(name, callback, value)
		end
	end
	apply((default - min) / (max - min), false)

	local function fromX(x)
		local width = math.max(bar.AbsoluteSize.X, 1)
		apply((x - bar.AbsolutePosition.X) / width, true)
	end

	local dragging = false
	track(hit.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			page.ScrollingEnabled = false
			fromX(input.Position.X)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromX(input.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			page.ScrollingEnabled = true
		end
	end))
end
local function createPortalSystem()
	local BIND = "RidKidPortal"
	local DEFAULT_PORTALS = 3
	local MAX_PORTALS = 30
	local BASE_SPEED = 16
	local TURN_SPEED = 1.8
	local PITCH_SPEED = 1.2
	local MOUSE_SENS = 0.004
	local TOUCH_TURN = 5.5
	local EYE_HEIGHT = 1.5
	local PLACE_DISTANCE = 9
	local ARRIVE_DISTANCE = 5
	local RING_R = 3.2
	local SEGMENTS = 20
	local ORB_COUNT = 3
	local CHIP_W = 34
	local CHIP_GAP = 4
	local CELL_W = 48
	local CELL_H = 30
	local PAD_W = CELL_W * 5
	local PAD_H = CELL_H * 5
	local SPEEDS = { 0.25, 0.5, 1, 2, 4, 8 }

	pcall(function()
		RunService:UnbindFromRenderStep("PortalController")
	end)
	pcall(function()
		RunService:UnbindFromRenderStep(BIND)
	end)
	do
		local oldFolder = workspace:FindFirstChild("ClientPortals")
		if oldFolder then
			oldFolder:Destroy()
		end
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local oldPad = pg and pg:FindFirstChild("PortalController")
		if oldPad then
			oldPad:Destroy()
		end
	end

	local api = {}
	local folder = new("Folder", { Name = "ClientPortals", Parent = workspace })
	local portals = {}
	local portalById = {}
	local strips = {}
	local nextId = 1
	local selectedId = nil
	local viewing = false
	local destroyed = false
	local padCollapsed = false
	local speedIndex = 3
	local held = {}
	local lookInput = nil
	local previousMouseBehavior = nil
	local lock = nil
	local controls = nil
	local hubWasOpen = false
	local viewToggle = nil
	local infoLabels = nil
	local posTimer = 0
	local pad = nil
	local selectPortal

	local function say(text)
		notify("Cổng dịch chuyển", text)
	end

	local function getCamera()
		return workspace.CurrentCamera
	end

	local function getHumanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function getRoot()
		local c = LocalPlayer.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") then
			return r
		end
		return nil
	end

	local function getPortal(id)
		if id then
			return portalById[id]
		end
		return nil
	end

	local function getIndex(id)
		for i, p in ipairs(portals) do
			if p.id == id then
				return i
			end
		end
		return nil
	end

	local function clampPosition(v)
		local minY = math.min(workspace.FallenPartsDestroyHeight + 100, 9000)
		return Vector3.new(
			math.clamp(v.X, -50000, 50000),
			math.clamp(v.Y, minY, 10000),
			math.clamp(v.Z, -50000, 50000)
		)
	end

	local function portalCFrame(p)
		return CFrame.new(p.position) * CFrame.Angles(0, p.yaw, 0)
	end

	local function applyPortal(p)
		p.model:PivotTo(portalCFrame(p))
	end

	local function newPart(parent, name, props)
		local base = {
			Name = name,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Material = Enum.Material.Neon,
			Parent = parent,
		}
		for k, v in pairs(props) do
			base[k] = v
		end
		return new("Part", base)
	end

	local function addChip(strip, p)
		local btn = new("TextButton", {
			Size = UDim2.fromOffset(CHIP_W, 26),
			LayoutOrder = p.id,
			BackgroundColor3 = THEME.Off,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = tostring(p.id),
			TextColor3 = p.color,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Parent = strip.frame,
		})
		corner(btn, UDim.new(0, 7))
		local s = stroke(btn, THEME.Ink, 1, 0.2)
		strip.chips[p.id] = { button = btn, stroke = s }
		track(btn.Activated:Connect(function()
			selectPortal(p.id)
		end))
	end

	local function createPortal()
		local id = nextId
		nextId = nextId + 1
		local color = Color3.fromHSV(((id - 1) * 0.137) % 1, 0.62, 1)
		local soft = color:Lerp(WHITE, 0.6)

		local model = new("Model", { Name = "Portal_" .. id })
		local root = newPart(model, "Root", {
			Size = Vector3.new(1, 1, 1),
			Transparency = 1,
			CFrame = CFrame.new(),
		})
		model.PrimaryPart = root

		local ring = {}
		for i = 1, SEGMENTS do
			local a = (i - 1) / SEGMENTS * math.pi * 2
			ring[i] = newPart(model, "Ring" .. i, {
				Size = Vector3.new(1.2, 0.55, 0.55),
				CFrame = CFrame.new(math.cos(a) * RING_R, math.sin(a) * RING_R, 0)
					* CFrame.Angles(0, 0, a + math.pi / 2),
				Color = color,
				Transparency = 0.45,
			})
		end

		local membrane = newPart(model, "Membrane", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.12, RING_R * 2 - 0.5, RING_R * 2 - 0.5),
			CFrame = CFrame.Angles(0, math.pi / 2, 0),
			Color = color,
			Material = Enum.Material.ForceField,
			Transparency = 0.6,
		})

		local halo = newPart(model, "Halo", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, RING_R * 2 + 2.6, RING_R * 2 + 2.6),
			CFrame = CFrame.new(0, 0, 0.35) * CFrame.Angles(0, math.pi / 2, 0),
			Color = color,
			Transparency = 0.93,
		})

		local fx = newPart(model, "Fx", {
			Size = Vector3.new(RING_R * 1.7, RING_R * 1.7, 0.6),
			Transparency = 1,
			CFrame = CFrame.new(),
		})
		local emitter = new("ParticleEmitter", {
			Color = ColorSequence.new(color, WHITE),
			LightEmission = 1,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(1, 1.8),
			Rate = 16,
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(30, 30),
			EmissionDirection = Enum.NormalId.Front,
			Parent = fx,
		})
		pcall(function()
			emitter.Shape = Enum.ParticleEmitterShape.Sphere
			emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		end)

		local light = new("PointLight", {
			Color = color,
			Brightness = 1,
			Range = 16,
			Parent = membrane,
		})

		local orbs = {}
		for i = 1, ORB_COUNT do
			orbs[i] = newPart(model, "Orb" .. i, {
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.5, 0.5, 0.5),
				Color = soft,
				CFrame = CFrame.new(),
			})
		end

		local gui = new("BillboardGui", {
			Name = "Tag",
			Size = UDim2.fromOffset(34, 20),
			StudsOffset = Vector3.new(0, RING_R + 1.8, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			MaxDistance = 400,
			Adornee = root,
			Parent = root,
		})
		local tag = new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Text = "#" .. id,
			TextColor3 = Color3.fromRGB(12, 12, 20),
			Font = Enum.Font.GothamBlack,
			TextSize = 13,
			Parent = gui,
		})
		corner(tag, UDim.new(0, 7))
		stroke(tag, WHITE, 1.2, 0.1)

		local p = {
			id = id,
			model = model,
			ring = ring,
			membrane = membrane,
			halo = halo,
			orbs = orbs,
			emitter = emitter,
			light = light,
			gui = gui,
			color = color,
			position = Vector3.zero,
			yaw = 0,
			pitch = 0,
			placed = false,
			hidden = false,
		}
		portals[#portals + 1] = p
		portalById[id] = p
		for _, strip in ipairs(strips) do
			addChip(strip, p)
		end
		return p
	end

	local function placePortal(p, position, yaw)
		p.position = clampPosition(position)
		p.yaw = yaw
		p.pitch = 0
		p.placed = true
		applyPortal(p)
		p.model.Parent = folder
	end

	local function frontOfCharacter()
		local root = getRoot()
		if not root then
			return nil, nil
		end
		local cf = root.CFrame
		local _, yaw = cf:ToEulerAnglesYXZ()
		local flat = CFrame.new(cf.Position) * CFrame.Angles(0, yaw, 0)
		return (flat * CFrame.new(0, 0, -PLACE_DISTANCE)).Position, yaw
	end

	local function freeSpot(position, yaw, ignore)
		local right = CFrame.Angles(0, yaw, 0).RightVector
		for attempt = 0, 12 do
			local candidate = position
			if attempt > 0 then
				local side = attempt % 2 == 1 and 1 or -1
				candidate = position + right * side * 5 * math.ceil(attempt / 2)
			end
			local blocked = false
			for _, other in ipairs(portals) do
				if other ~= ignore and other.placed and (other.position - candidate).Magnitude < 4 then
					blocked = true
					break
				end
			end
			if not blocked then
				return candidate
			end
		end
		return position
	end

	local function autoPlace(p)
		local position, yaw = frontOfCharacter()
		if not position then
			return false
		end
		placePortal(p, freeSpot(position, yaw, p), yaw)
		return true
	end

	local function refreshChips()
		for _, strip in ipairs(strips) do
			for _, p in ipairs(portals) do
				local chip = strip.chips[p.id]
				if chip then
					local sel = p.id == selectedId
					chip.button.BackgroundColor3 = p.placed and p.color or THEME.Off
					chip.button.TextColor3 = p.placed and THEME.Ink or p.color
					chip.stroke.Color = sel and WHITE or THEME.Ink
					chip.stroke.Thickness = sel and 2 or 1
					chip.stroke.Transparency = sel and 0 or 0.2
				end
			end
		end
	end

	local function scrollToSelected()
		local index = getIndex(selectedId)
		if not index then
			return
		end
		for _, strip in ipairs(strips) do
			local window = strip.frame.AbsoluteSize.X
			if window > 0 then
				local left = CHIP_GAP + (index - 1) * (CHIP_W + CHIP_GAP)
				local right = left + CHIP_W + CHIP_GAP
				local current = strip.frame.CanvasPosition.X
				if left < current then
					strip.frame.CanvasPosition = Vector2.new(math.max(0, left - CHIP_GAP), 0)
				elseif right > current + window then
					strip.frame.CanvasPosition = Vector2.new(math.max(0, right - window), 0)
				end
			end
		end
	end

	local function updateInfo()
		local p = getPortal(selectedId)
		if pad then
			pad.title.Text = p and ("Chỉnh cổng #" .. p.id) or "Chỉnh cổng"
			pad.title.BackgroundColor3 = p and p.color or THEME.Pink
			pad.speed.Text = "x" .. tostring(SPEEDS[speedIndex])
		end
		if infoLabels then
			if p then
				infoLabels.selected.Text = "#" .. p.id .. (p.placed and "  ·  đã đặt" or "  ·  chưa đặt")
				if p.placed then
					infoLabels.position.Text = math.floor(p.position.X + 0.5)
						.. ", "
						.. math.floor(p.position.Y + 0.5)
						.. ", "
						.. math.floor(p.position.Z + 0.5)
				else
					infoLabels.position.Text = "--"
				end
			else
				infoLabels.selected.Text = "Chưa có cổng"
				infoLabels.position.Text = "--"
			end
			infoLabels.speed.Text = "x" .. tostring(SPEEDS[speedIndex])
		end
	end

	local function refreshLook()
		for _, p in ipairs(portals) do
			local selected = p.id == selectedId
			local hidden = viewing and selected
			p.hidden = hidden
			local v = hidden and 1 or nil
			for _, seg in ipairs(p.ring) do
				seg.Transparency = v or (selected and 0.1 or 0.45)
			end
			p.membrane.Transparency = v or (selected and 0.45 or 0.7)
			p.halo.Transparency = v or (selected and 0.82 or 0.94)
			for _, orb in ipairs(p.orbs) do
				orb.Transparency = v or 0.05
			end
			p.emitter.Enabled = not hidden
			p.light.Enabled = not hidden
			p.light.Brightness = selected and 2 or 1
			p.gui.Enabled = not hidden
		end
	end

	local function clampPad()
		if not pad then
			return
		end
		local screen = Gui.AbsoluteSize
		if screen.X <= 0 or screen.Y <= 0 then
			return
		end
		local ap, sz = pad.frame.AbsolutePosition, pad.frame.AbsoluteSize
		local nx = math.clamp(ap.X, 0, math.max(0, screen.X - sz.X))
		local ny = math.clamp(ap.Y, 0, math.max(0, screen.Y - sz.Y))
		if math.abs(nx - ap.X) > 0.5 or math.abs(ny - ap.Y) > 0.5 then
			local pos = pad.frame.Position
			pad.frame.Position =
				UDim2.new(pos.X.Scale, pos.X.Offset + (nx - ap.X), pos.Y.Scale, pos.Y.Offset + (ny - ap.Y))
		end
	end

	local function lockCharacter(root, humanoid)
		lock = {
			root = root,
			anchored = root.Anchored,
			humanoid = humanoid,
			walkSpeed = humanoid.WalkSpeed,
		}
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid.WalkSpeed = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		root.Anchored = true
	end

	local function unlockCharacter()
		if not lock then
			return
		end
		local saved = lock
		lock = nil
		if saved.root.Parent then
			saved.root.Anchored = saved.anchored
		end
		if saved.humanoid.Parent then
			saved.humanoid.WalkSpeed = saved.walkSpeed
			saved.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end

	local function restoreCamera()
		local cam = getCamera()
		if not cam then
			return
		end
		cam.CameraType = Enum.CameraType.Custom
		local humanoid = getHumanoid()
		if humanoid then
			cam.CameraSubject = humanoid
		end
	end

	local function stopLook()
		lookInput = nil
		if previousMouseBehavior then
			UserInputService.MouseBehavior = previousMouseBehavior
			previousMouseBehavior = nil
		end
	end

	local function exitView()
		if not viewing then
			return
		end
		viewing = false
		table.clear(held)
		stopLook()
		unlockCharacter()
		restoreCamera()
		refreshLook()
		if pad then
			pad.frame.Visible = false
		end
		if viewToggle then
			viewToggle.Set(false)
		end
		updateInfo()
		if hubWasOpen then
			hubWasOpen = false
			if mode == "min" then
				setMode("open")
			end
		end
	end

	local function enterView()
		if viewing or destroyed then
			return false
		end
		local p = getPortal(selectedId)
		if not p then
			say("Chưa chọn cổng")
			return false
		end
		local humanoid = getHumanoid()
		local root = getRoot()
		if not humanoid or not root or humanoid.Health <= 0 then
			say("Nhân vật chưa sẵn sàng")
			return false
		end
		if humanoid.SeatPart then
			say("Hãy rời khỏi ghế trước")
			return false
		end
		if not p.placed and not autoPlace(p) then
			say("Nhân vật chưa sẵn sàng")
			return false
		end
		lockCharacter(root, humanoid)
		viewing = true
		table.clear(held)
		hubWasOpen = (mode == "open")
		if hubWasOpen then
			setMode("min")
		end
		refreshLook()
		refreshChips()
		if pad then
			pad.frame.Visible = true
		end
		if viewToggle then
			viewToggle.Set(true)
		end
		updateInfo()
		task.defer(scrollToSelected)
		task.defer(clampPad)
		return true
	end
	selectPortal = function(id)
		local p = getPortal(id)
		if not p then
			return
		end
		if viewing and not p.placed and not autoPlace(p) then
			say("Nhân vật chưa sẵn sàng")
			return
		end
		selectedId = id
		refreshLook()
		refreshChips()
		updateInfo()
		task.defer(scrollToSelected)
	end

	local function flash(color)
		local f = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = Gui,
		})
		tween(f, 0.5, { BackgroundTransparency = 1 })
		task.delay(0.55, function()
			if f.Parent then
				f:Destroy()
			end
		end)
	end

	function api.createStrip(parent)
		local frame = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = THEME.Accent,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = parent,
		})
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, CHIP_GAP),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = frame,
		})
		new("UIPadding", { PaddingLeft = UDim.new(0, CHIP_GAP), Parent = frame })
		local strip = { frame = frame, chips = {} }
		strips[#strips + 1] = strip
		for _, p in ipairs(portals) do
			addChip(strip, p)
		end
		refreshChips()
		return frame
	end

	function api.add()
		if #portals >= MAX_PORTALS then
			say("Tối đa " .. MAX_PORTALS .. " cổng")
			return
		end
		local p = createPortal()
		if viewing then
			refreshChips()
		else
			selectPortal(p.id)
		end
		say("Đã tạo cổng #" .. p.id)
	end

	function api.remove()
		local index = getIndex(selectedId)
		if not index then
			say("Không có cổng để xoá")
			return
		end
		local p = table.remove(portals, index)
		portalById[p.id] = nil
		for _, strip in ipairs(strips) do
			local chip = strip.chips[p.id]
			if chip then
				chip.button:Destroy()
				strip.chips[p.id] = nil
			end
		end
		p.model:Destroy()
		selectedId = nil
		local following = portals[math.min(index, #portals)]
		if following then
			selectPortal(following.id)
		else
			exitView()
			refreshChips()
			updateInfo()
		end
		say("Đã xoá cổng #" .. p.id)
	end

	function api.place()
		local p = getPortal(selectedId)
		if not p then
			say("Chưa chọn cổng")
			return
		end
		if not autoPlace(p) then
			say("Nhân vật chưa sẵn sàng")
			return
		end
		refreshLook()
		refreshChips()
		updateInfo()
		say("Đã đặt cổng #" .. p.id)
	end

	function api.teleport()
		local p = getPortal(selectedId)
		if not p then
			say("Chưa chọn cổng")
			return
		end
		if not p.placed then
			say("Cổng #" .. p.id .. " chưa đặt")
			return
		end
		local character = LocalPlayer.Character
		local humanoid = getHumanoid()
		local root = getRoot()
		if not character or not humanoid or not root or humanoid.Health <= 0 then
			say("Nhân vật chưa sẵn sàng")
			return
		end
		if humanoid.SeatPart then
			say("Hãy rời khỏi ghế trước")
			return
		end
		exitView()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		character:PivotTo(portalCFrame(p) * CFrame.new(0, 0, -ARRIVE_DISTANCE))
		flash(p.color)
		say("Đã tới cổng #" .. p.id)
	end

	function api.setView(on)
		if on then
			enterView()
		else
			exitView()
		end
		return viewing
	end

	function api.isViewing()
		return viewing
	end

	function api.setViewToggle(t)
		viewToggle = t
	end

	function api.bindInfo(labels)
		infoLabels = labels
		updateInfo()
	end

	local function readMove(p)
		if controls then
			local ok, vector = pcall(controls.GetMoveVector, controls)
			if ok and typeof(vector) == "Vector3" then
				return vector
			end
		end
		local humanoid = getHumanoid()
		if humanoid then
			return CFrame.Angles(0, p.yaw, 0):VectorToObjectSpace(humanoid.MoveDirection)
		end
		return Vector3.zero
	end

	local function step(dt)
		if destroyed or not viewing then
			return
		end
		local p = getPortal(selectedId)
		if not p or not p.placed then
			exitView()
			return
		end
		dt = math.min(dt, 0.1)

		for data, source in pairs(held) do
			if source.UserInputType == Enum.UserInputType.MouseButton1 then
				if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
					held[data] = nil
				end
			elseif
				source.UserInputState == Enum.UserInputState.End
				or source.UserInputState == Enum.UserInputState.Cancel
			then
				held[data] = nil
			end
		end

		local planar = Vector3.zero
		local vertical = 0
		local turn = 0
		local look = 0
		for data in pairs(held) do
			planar = planar + Vector3.new(data.move.X, 0, data.move.Z)
			vertical = vertical + data.move.Y
			turn = turn + data.turn
			look = look + data.look
		end

		local speed = BASE_SPEED * SPEEDS[speedIndex]
		if UserInputService:GetFocusedTextBox() == nil then
			local input = readMove(p)
			planar = planar + Vector3.new(input.X, 0, input.Z)
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then
				vertical = vertical + 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
				vertical = vertical - 1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				speed = speed * 2
			end
		end

		local changed = false
		if turn ~= 0 then
			p.yaw = (p.yaw + turn * TURN_SPEED * dt) % (2 * math.pi)
			changed = true
		end
		if look ~= 0 then
			p.pitch = math.clamp(p.pitch + look * PITCH_SPEED * dt, -1.45, 1.45)
		end

		if planar.Magnitude > 1 then
			planar = planar.Unit
		end
		local world = CFrame.Angles(0, p.yaw, 0):VectorToWorldSpace(planar)
		local move = world + Vector3.new(0, math.clamp(vertical, -1, 1), 0)
		if move.Magnitude > 0.001 then
			p.position = clampPosition(p.position + move * speed * dt)
			changed = true
		end
		if changed then
			applyPortal(p)
		end

		posTimer = posTimer + dt
		if posTimer >= 0.25 then
			posTimer = 0
			updateInfo()
		end

		local cam = getCamera()
		if cam then
			if cam.CameraType ~= Enum.CameraType.Scriptable then
				cam.CameraType = Enum.CameraType.Scriptable
			end
			cam.CFrame = CFrame.new(p.position + Vector3.new(0, EYE_HEIGHT, 0))
				* CFrame.Angles(0, p.yaw, 0)
				* CFrame.Angles(p.pitch, 0, 0)
		end
	end

	local function animate(t)
		for _, p in ipairs(portals) do
			if p.placed and not p.hidden then
				local base = portalCFrame(p)
				for i, orb in ipairs(p.orbs) do
					local a = t * (1.1 + i * 0.25) + i * 2.1
					local r = RING_R - 0.85 + math.sin(t * 1.4 + i) * 0.35
					orb.CFrame = base * CFrame.new(math.cos(a) * r, math.sin(a) * r, math.sin(a * 1.7) * 0.35)
				end
				local selected = p.id == selectedId
				p.membrane.Transparency = (selected and 0.42 or 0.68) + math.sin(t * 2.2 + p.id) * 0.08
				if selected then
					for i, seg in ipairs(p.ring) do
						seg.Transparency = 0.05 + (math.sin(t * 4 - i * 0.55) * 0.5 + 0.5) * 0.35
					end
				end
			end
		end
	end

	local function cell(parent, className, text, color, col, row, span)
		local obj = new(className, {
			Position = UDim2.fromOffset(col * CELL_W, row * CELL_H),
			Size = UDim2.fromOffset((span or 1) * CELL_W, CELL_H),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = THEME.Ink,
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			Parent = parent,
		})
		stroke(obj, THEME.Ink, 1, 0)
		new("UITextSizeConstraint", { MinTextSize = 7, MaxTextSize = 14, Parent = obj })
		new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = obj })
		return obj
	end

	local function buildPad()
		local frame = new("Frame", {
			Name = "AdjustPanel",
			Size = UDim2.fromOffset(PAD_W, PAD_H),
			Position = UDim2.new(1, -PAD_W - 12, 0, 72),
			BackgroundColor3 = THEME.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Active = true,
			Visible = false,
			ZIndex = 20,
			Parent = Gui,
		})
		corner(frame, UDim.new(0, 10))
		local border = stroke(frame, WHITE, 1.5, 0)
		gradient(border, { THEME.Accent, THEME.Accent2, THEME.Accent3 }, 0)

		local title = cell(frame, "TextButton", "Chỉnh cổng", THEME.Pink, 0, 0, 3)
		title.AutoButtonColor = false
		local collapse = cell(frame, "TextButton", "-", THEME.Lav, 3, 0)
		local exitBtn = cell(frame, "TextButton", "X", THEME.Red, 4, 0)

		local body = new("Frame", {
			Position = UDim2.fromOffset(0, CELL_H),
			Size = UDim2.fromOffset(PAD_W, CELL_H * 4),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		local stripHolder = new("Frame", {
			Size = UDim2.fromOffset(PAD_W, CELL_H),
			BackgroundColor3 = THEME.Panel,
			BorderSizePixel = 0,
			Parent = body,
		})
		api.createStrip(stripHolder)

		local defs = {
			{ "Xoay <", 0, 1, THEME.Lav, Vector3.zero, 1, 0 },
			{ "Tiến", 1, 1, THEME.Peri, Vector3.new(0, 0, -1), 0, 0 },
			{ "Xoay >", 2, 1, THEME.Lav, Vector3.zero, -1, 0 },
			{ "Lên", 3, 1, THEME.Good, Vector3.new(0, 1, 0), 0, 0 },
			{ "Ngẩng", 4, 1, THEME.Cyan, Vector3.zero, 0, 1 },
			{ "Trái", 0, 2, THEME.Peri, Vector3.new(-1, 0, 0), 0, 0 },
			{ "Lùi", 1, 2, THEME.Peri, Vector3.new(0, 0, 1), 0, 0 },
			{ "Phải", 2, 2, THEME.Peri, Vector3.new(1, 0, 0), 0, 0 },
			{ "Xuống", 3, 2, THEME.Lime, Vector3.new(0, -1, 0), 0, 0 },
			{ "Cúi", 4, 2, THEME.Cyan, Vector3.zero, 0, -1 },
		}
		for _, d in ipairs(defs) do
			local btn = cell(body, "TextButton", d[1], d[4], d[2], d[3])
			local data = { move = d[5], turn = d[6], look = d[7] }
			track(btn.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					held[data] = input
				end
			end))
		end

		local slower = cell(body, "TextButton", "Chậm", THEME.Cyan, 0, 3)
		local speedLabel = cell(body, "TextLabel", "x1", THEME.Orange, 1, 3)
		local faster = cell(body, "TextButton", "Nhanh", THEME.Peri, 2, 3)
		local done = cell(body, "TextButton", "Đặt xong", THEME.Good, 3, 3, 2)

		pad = { frame = frame, title = title, speed = speedLabel }

		makeDraggable(title, frame)

		track(collapse.Activated:Connect(function()
			padCollapsed = not padCollapsed
			table.clear(held)
			body.Visible = not padCollapsed
			collapse.Text = padCollapsed and "+" or "-"
			frame.Size = UDim2.fromOffset(PAD_W, padCollapsed and CELL_H or PAD_H)
			task.defer(clampPad)
		end))
		track(exitBtn.Activated:Connect(exitView))
		track(done.Activated:Connect(function()
			local p = getPortal(selectedId)
			exitView()
			if p then
				say("Đã chốt cổng #" .. p.id)
			end
		end))
		track(slower.Activated:Connect(function()
			speedIndex = math.max(1, speedIndex - 1)
			updateInfo()
		end))
		track(faster.Activated:Connect(function()
			speedIndex = math.min(#SPEEDS, speedIndex + 1)
			updateInfo()
		end))
	end

	local function bindCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and not destroyed then
			humanoid.Died:Connect(exitView)
			humanoid.Seated:Connect(function(active)
				if active then
					exitView()
				end
			end)
		end
	end

	track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or destroyed or not viewing or lookInput then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			lookInput = input
			if not previousMouseBehavior then
				previousMouseBehavior = UserInputService.MouseBehavior
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		elseif input.UserInputType == Enum.UserInputType.Touch then
			if input.Position.X > Gui.AbsoluteSize.X * 0.4 then
				lookInput = input
			end
		end
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if not lookInput or not viewing then
			return
		end
		local p = getPortal(selectedId)
		if not p then
			return
		end
		local dx
		local dy
		if lookInput.UserInputType == Enum.UserInputType.MouseButton2 then
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			dx = input.Delta.X * MOUSE_SENS
			dy = input.Delta.Y * MOUSE_SENS
		else
			if input ~= lookInput then
				return
			end
			local width = math.max(1, Gui.AbsoluteSize.X)
			dx = input.Delta.X / width * TOUCH_TURN
			dy = input.Delta.Y / width * TOUCH_TURN
		end
		p.yaw = (p.yaw - dx) % (2 * math.pi)
		p.pitch = math.clamp(p.pitch - dy, -1.45, 1.45)
		applyPortal(p)
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		for data, source in pairs(held) do
			if
				source == input
				or (
					source.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseButton1
				)
			then
				held[data] = nil
			end
		end
		if
			lookInput
			and (
				lookInput == input
				or (
					lookInput.UserInputType == Enum.UserInputType.MouseButton2
					and input.UserInputType == Enum.UserInputType.MouseButton2
				)
			)
		then
			stopLook()
		end
	end))

	track(UserInputService.WindowFocusReleased:Connect(function()
		table.clear(held)
		stopLook()
	end))

	track(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(clampPad)
	end))

	track(LocalPlayer.CharacterAdded:Connect(function(character)
		exitView()
		task.spawn(bindCharacter, character)
	end))
	track(LocalPlayer.CharacterRemoving:Connect(exitView))

	track(RunService.Heartbeat:Connect(function()
		if not destroyed then
			animate(os.clock())
		end
	end))

	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, step)

	function api.shutdown()
		if destroyed then
			return
		end
		hubWasOpen = false
		exitView()
		destroyed = true
		pcall(function()
			RunService:UnbindFromRenderStep(BIND)
		end)
		for _, p in ipairs(portals) do
			pcall(function()
				p.model:Destroy()
			end)
		end
		table.clear(portals)
		table.clear(portalById)
		table.clear(strips)
		folder:Destroy()
	end

	buildPad()

	for _ = 1, DEFAULT_PORTALS do
		createPortal()
	end
	selectPortal(portals[1].id)
	updateInfo()

	task.spawn(function()
		local scripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
		local module = scripts and scripts:WaitForChild("PlayerModule", 10)
		if not module then
			return
		end
		local ok, result = pcall(function()
			return require(module):GetControls()
		end)
		if ok and not destroyed then
			controls = result
		end
	end)

	if LocalPlayer.Character then
		task.spawn(bindCharacter, LocalPlayer.Character)
	end

	return api
end

local Portal = createPortalSystem()
local function copyText(text, name)
	local ok = pcall(function()
		local fn = setclipboard or toclipboard
		fn(text)
	end)
	if ok then
		notify("Đã sao chép", name, 2)
	else
		notify("Không sao chép được", "Executor chưa hỗ trợ clipboard", 3)
	end
end

local function createHero(page, title, subtitle)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(card, UDim.new(0, 12))
	gradient(card, { Color3.fromRGB(70, 40, 150), Color3.fromRGB(20, 60, 120) }, 20)
	stroke(card, THEME.Accent2, 1, 0.6)

	local logo = createLogo(card, 56)
	logo.Position = UDim2.fromOffset(14, 14)

	label(card, {
		Position = UDim2.fromOffset(82, 17),
		Size = UDim2.new(1, -92, 0, 22),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(card, {
		Position = UDim2.fromOffset(82, 42),
		Size = UDim2.new(1, -92, 0, 18),
		Text = subtitle,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(205, 200, 240),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	return card
end

local function createLinkCard(page, role, name, link, accent)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(page),
		Parent = page,
	})
	corner(row, UDim.new(0, 10))
	stroke(row, accent, 1, 0.6)

	label(row, {
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -104, 0, 14),
		Text = role,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = accent,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(row, {
		Position = UDim2.fromOffset(12, 22),
		Size = UDim2.new(1, -104, 0, 20),
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(row, {
		Position = UDim2.fromOffset(12, 43),
		Size = UDim2.new(1, -104, 0, 14),
		Text = link,
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(80, 30),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Text = "Sao chép",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = THEME.Text,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(btn, UDim.new(0, 8))
	stroke(btn, accent, 1, 0.3)
	track(btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.3 })
	end))
	track(btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.55 })
	end))
	track(btn.MouseButton1Click:Connect(function()
		copyText(link, name)
	end))
end

local HomePage = createPage()
local PortalPage = createPage()
local VisualPage = createPage()
local SettingsPage = createPage()
local AuthorPage = createPage()

local fpsLabel

do
	local name = LocalPlayer.DisplayName
	if not name or name == "" then
		name = LocalPlayer.Name
	end
	createHero(HomePage, "Xin chào, " .. name, "Khám phá vũ trụ cùng RidKid Hub.")

	createSection(HomePage, "THÔNG TIN")
	createInfo(HomePage, "Tên tài khoản", "@" .. LocalPlayer.Name)
	createInfo(HomePage, "Place ID", tostring(game.PlaceId))
	createInfo(HomePage, "Người chơi", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers))
	fpsLabel = createInfo(HomePage, "FPS", "--")
end

do
	createSection(PortalPage, "CHỌN CỔNG")
	local strip = new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(PortalPage),
		Parent = PortalPage,
	})
	corner(strip, UDim.new(0, 10))
	stroke(strip, THEME.Accent, 1, 0.8)
	Portal.createStrip(strip)

	createButtonRow(PortalPage, {
		{ "+ Tạo cổng", THEME.Good, Portal.add },
		{ "Xoá cổng", THEME.Danger, Portal.remove },
	})

	createSection(PortalPage, "HÀNH ĐỘNG")
	createButtonRow(PortalPage, {
		{ "Đặt cổng tại đây", THEME.Accent, Portal.place },
		{ "Dịch chuyển", THEME.Accent2, Portal.teleport },
	})

	createSection(PortalPage, "GÓC NHÌN")
	local viewToggle
	viewToggle = createToggle(PortalPage, "Nhìn từ cổng", "Nhân vật đứng im, camera nhập vào cổng", false, function(v)
		Portal.setView(v)
		viewToggle.Set(Portal.isViewing())
	end)
	Portal.setViewToggle(viewToggle)

	createSection(PortalPage, "TRẠNG THÁI")
	Portal.bindInfo({
		selected = createInfo(PortalPage, "Cổng đang chọn", "--"),
		position = createInfo(PortalPage, "Vị trí cổng", "--"),
		speed = createInfo(PortalPage, "Tốc độ dời cổng", "x1"),
	})

	createSection(PortalPage, "HƯỚNG DẪN")
	createNote(
		PortalPage,
		"Chọn số cổng rồi bấm Đặt cổng tại đây để đặt trước mặt nhân vật. Bật Nhìn từ cổng để đổi góc nhìn: nhân vật đứng im, hub thu nhỏ và bảng Chỉnh cổng hiện ra. Joystick hoặc WASD dời cổng, E/Q lên xuống, vuốt nửa phải màn hình (hoặc giữ chuột phải) để xoay. Dịch chuyển đưa nhân vật tới cổng đang chọn, không bị reset hay chết."
	)
end

do
	createSection(VisualPage, "HIỆU ỨNG VŨ TRỤ")
	createToggle(VisualPage, "Sao chuyển động", "Nền sao di chuyển", true, function(v)
		StarLayer.Visible = v
	end)
	createToggle(VisualPage, "Sao băng", "Sao băng xuất hiện ngẫu nhiên", true, function(v)
		shootingEnabled = v
	end)
	createToggle(VisualPage, "Tinh vân", "Đám mây màu mềm mại", true, function(v)
		GlowLayer.Visible = v
	end)
	createSlider(VisualPage, "Tốc độ sao", 0, 300, 100, function(v)
		starSpeedMul = v / 100
	end)
end

do
	createSection(SettingsPage, "GIAO DIỆN")
	createToggle(SettingsPage, "Thông báo", "Hiện thông báo nhỏ", true, function(v)
		notificationsEnabled = v
		if v then
			notify("Thông báo", "Đã bật")
		end
	end)

	local afkConn = nil
	track({
		Disconnect = function()
			if afkConn then
				afkConn:Disconnect()
				afkConn = nil
			end
		end,
	})
	createToggle(SettingsPage, "Chống AFK", "Không bị kick khi đứng yên", false, function(v)
		if v then
			if not afkConn then
				afkConn = LocalPlayer.Idled:Connect(function()
					pcall(function()
						local vu = game:GetService("VirtualUser")
						vu:CaptureController()
						vu:ClickButton2(Vector2.new())
					end)
				end)
			end
		elseif afkConn then
			afkConn:Disconnect()
			afkConn = nil
		end
		notify("Chống AFK", v and "Đã bật" or "Đã tắt")
	end)
	createInfo(SettingsPage, "Phím bật/tắt", CONFIG.ToggleKey.Name)

	createSection(SettingsPage, "CỬA SỔ")
end

do
	createHero(AuthorPage, "RidKid Hub", "Cảm ơn bạn đã dùng và ủng hộ!")

	createSection(AuthorPage, "ĐỘI NGŨ")
	createLinkCard(
		AuthorPage,
		"TÁC GIẢ CHÍNH",
		"@hoclamscript_roblox",
		"https://www.tiktok.com/@hoclamscript_roblox",
		THEME.Pink
	)
	createLinkCard(
		AuthorPage,
		"NGƯỜI PHỤ TRÁCH LÀM · CÔNG LỚN",
		"@viet69xhamter",
		"https://www.tiktok.com/@viet69xhamter",
		THEME.Accent2
	)
	createLinkCard(
		AuthorPage,
		"THƯ KÍ TỔNG",
		"Emi Fukada",
		"https://www.tiktok.com/@quocdaicofgi",
		THEME.Lav
	)

	createSection(AuthorPage, "CỘNG ĐỒNG")
	createLinkCard(AuthorPage, "SERVER DISCORD", "RidKid Hub", "https://discord.gg/Pfrxphu6M", THEME.Peri)

	createSection(AuthorPage, "LỜI CHÚC")
	createNote(
		AuthorPage,
		"Chúc bạn chơi game thật vui, mượt và không lag!\nChúc bạn luôn may mắn, gặp nhiều bạn tốt và đạt được mọi mục tiêu trong game lẫn ngoài đời.\nCảm ơn bạn đã tin dùng RidKid Hub. Nhớ ghé TikTok và Discord để ủng hộ tụi mình nhé!",
		THEME.Text
	)
end

createTab("Trang chủ", HomePage)
createTab("Cổng", PortalPage)
createTab("Hiệu ứng", VisualPage)
createTab("Cài đặt", SettingsPage)
createTab("Tác giả", AuthorPage)

local LogoHolder = new("Frame", {
	Name = "MinimizedLogo",
	Size = UDim2.fromOffset(60, 60),
	Position = UDim2.fromOffset(20, 100),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = Gui,
})

local Ripple = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(56, 56),
	BackgroundTransparency = 1,
	Parent = LogoHolder,
})
corner(Ripple, UDim.new(1, 0))
local RippleStroke = stroke(Ripple, THEME.Accent2, 2, 0.4)

local LogoInner = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(56, 56),
	BackgroundTransparency = 1,
	Parent = LogoHolder,
})
local LogoScale = new("UIScale", { Scale = 0.01, Parent = LogoInner })

local Ring = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 8, 30),
	BorderSizePixel = 0,
	Parent = LogoInner,
})
corner(Ring, UDim.new(1, 0))
local ringStroke = stroke(Ring, WHITE, 2.5, 0)
local ringGradient = gradient(ringStroke, { THEME.Accent, THEME.Accent2, THEME.Accent3, THEME.Accent }, 0)

local MiniLogo = createLogo(Ring, 46)
MiniLogo.AnchorPoint = Vector2.new(0.5, 0.5)
MiniLogo.Position = UDim2.fromScale(0.5, 0.5)

local LogoHit = new("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 5,
	Parent = LogoHolder,
})

local token = 0
local logoMoved = false

local function placeLogoNearMain()
	local ap = Main.AbsolutePosition
	local sz = Gui.AbsoluteSize
	local x = math.clamp(ap.X + 12, 0, math.max(sz.X - 70, 0))
	local y = math.clamp(ap.Y + 12, 0, math.max(sz.Y - 70, 0))
	LogoHolder.Position = UDim2.fromOffset(x, y)
end

function setMode(newMode)
	if mode == "closed" or mode == newMode then
		return
	end
	mode = newMode
	token = token + 1
	local my = token

	if newMode == "open" then
		Main.Visible = true
		tween(MainScale, 0.45, { Scale = getBaseScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(LogoScale, 0.2, { Scale = 0.01 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function()
			if token == my then
				LogoHolder.Visible = false
			end
		end)
	elseif newMode == "min" then
		if not logoMoved then
			placeLogoNearMain()
		end
		LogoHolder.Visible = true
		tween(MainScale, 0.28, { Scale = 0.01 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(LogoScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(0.3, function()
			if token == my then
				Main.Visible = false
			end
		end)
	elseif newMode == "hidden" then
		tween(MainScale, 0.28, { Scale = 0.01 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(LogoScale, 0.2, { Scale = 0.01 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.3, function()
			if token == my then
				Main.Visible = false
				LogoHolder.Visible = false
			end
		end)
	end
end

local function cleanup()
	pcall(Portal.shutdown)
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(connections)
	if Gui then
		Gui:Destroy()
	end
	if _G.RidKidHub_Cleanup == cleanup then
		_G.RidKidHub_Cleanup = nil
	end
end
_G.RidKidHub_Cleanup = cleanup

function destroyUI()
	if mode == "closed" then
		return
	end
	pcall(Portal.shutdown)
	mode = "closed"
	token = token + 1
	if Main.Visible then
		tween(MainScale, 0.3, { Scale = 0.01 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	end
	if LogoHolder.Visible then
		tween(LogoScale, 0.25, { Scale = 0.01 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(0.35, cleanup)
end

makeDraggable(LogoHit, LogoHolder, function()
	setMode("open")
end, function()
	logoMoved = true
end)

do
	createButtonRow(SettingsPage, {
		{
			"Đặt lại vị trí",
			THEME.Accent2,
			function()
				Holder.Position = UDim2.fromScale(0.5, 0.5)
				logoMoved = false
				LogoHolder.Position = UDim2.fromOffset(20, 100)
				notify("Giao diện", "Đã đặt lại vị trí")
			end,
		},
		{
			"Đóng Hub",
			THEME.Danger,
			function()
				destroyUI()
			end,
		},
	})
end

track(UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == CONFIG.ToggleKey then
		if mode == "open" then
			setMode("hidden")
		else
			setMode("open")
		end
	end
end))

local elapsed = 0
local fpsAcc, fpsFrames = 0, 0

track(RunService.Heartbeat:Connect(function(rawDt)
	local dt = math.min(rawDt, 0.1)
	elapsed = elapsed + dt

	fpsAcc = fpsAcc + rawDt
	fpsFrames = fpsFrames + 1
	if fpsAcc >= 0.5 then
		if fpsLabel and mode == "open" then
			fpsLabel.Text = tostring(math.floor(fpsFrames / fpsAcc + 0.5))
		end
		fpsAcc, fpsFrames = 0, 0
	end

	if mode == "open" then
		borderGradient.Rotation = (elapsed * 40) % 360
		titleGradient.Rotation = (elapsed * 45) % 360
		bgGradient.Rotation = 90 + math.sin(elapsed * 0.3) * 25

		if StarLayer.Visible then
			updateStars(dt, elapsed)
		end

		if GlowLayer.Visible then
			for _, g in ipairs(glows) do
				g.frame.Position = UDim2.fromScale(
					g.bx + math.sin(elapsed * 0.25 + g.phase) * 0.06,
					g.by + math.cos(elapsed * 0.2 + g.phase) * 0.08
				)
			end
		end

		if shootingEnabled and StarLayer.Visible then
			shootTimer = shootTimer - dt
			if shootTimer <= 0 then
				spawnShootingStar()
				shootTimer = rng:NextNumber(2.5, 6)
			end
		end
	elseif mode == "min" then
		ringGradient.Rotation = (elapsed * 120) % 360
		local p = (elapsed % 1.8) / 1.8
		local s = 56 + 38 * p
		Ripple.Size = UDim2.fromOffset(s, s)
		RippleStroke.Transparency = 0.35 + 0.65 * p
	end
end))

selectTab(tabs[1])
setMode("open")
notify(CONFIG.Name, "Đã tải thành công", 2.5)
