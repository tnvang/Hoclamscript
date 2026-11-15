local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ROBOT_HEIGHT = 25
local ROBOT_WIDTH = 10.7
local S = 19 / 12
local L = 3.8
local CAMY = 4 * S + 6
local V3 = Vector3.new
local SND = "rbxasset://sounds/"
local SIDES = {{"A", 1}, {"B", -1}}

local CUSTOM_IDS = {
	roar = {},
	scream = {},
	laugh = {},
	ghost = {},
}

local function pool(list, voice)
	local out = {}
	if voice then
		for _, id in ipairs(CUSTOM_IDS[voice]) do
			out[#out + 1] = id
		end
	end
	for _, name in ipairs(list) do
		out[#out + 1] = SND .. name
	end
	return out
end

local SOUNDS = {
	stepA = {pool = pool({"action_jump_land.mp3", "impact_water.mp3"}), volume = 3.4, speed = 0.26, fx = {dist = 0.4, reverb = true}},
	stepB = {pool = pool({"metal.mp3", "kerplunk.wav", "bass.wav", "action_footsteps_plastic.mp3"}), volume = 2.2, speed = 0.45, fx = {reverb = true}},
	grind = {pool = pool({"action_footsteps_plastic.mp3", "metal.mp3"}), volume = 1.2, speed = 0.2, loop = true, fx = {dist = 0.5}},
	jump = {pool = pool({"action_jump.mp3"}), volume = 2.6, speed = 0.34, fx = {dist = 0.4, reverb = true}},
	landA = {pool = pool({"action_jump_land.mp3"}), volume = 4.2, speed = 0.2, fx = {dist = 0.5, reverb = true}},
	landB = {pool = pool({"glassbreak.wav", "metal.mp3", "kerplunk.wav"}), volume = 1.6, speed = 0.45, fx = {reverb = true}},
	roarA = {pool = pool({"Rocket whoosh 01.wav", "action_falling.mp3", "impact_water.mp3", "bass.wav"}, "roar"), volume = 5, speed = 0.5, oct = 0.5, fx = {dist = 0.85, reverb = true, tremolo = true}},
	roarB = {pool = pool({"swordslash.wav", "unsheath.wav", "action_swim.mp3"}), volume = 4.5, speed = 0.3, oct = 0.5, fx = {dist = 0.8, reverb = true}},
	roarC = {pool = pool({"bass.wav", "action_swim.mp3", "impact_water.mp3", "action_falling.mp3"}), volume = 4, speed = 0.25, oct = 0.6, fx = {dist = 0.9, flange = true, reverb = true}},
	screamA = {pool = pool({"action_falling.mp3", "action_swim.mp3", "Rocket whoosh 01.wav"}, "scream"), volume = 4, speed = 1.1, oct = 1.9, fx = {dist = 0.9, flange = true, reverb = true}},
	screamB = {pool = pool({"glassbreak.wav", "swordslash.wav", "unsheath.wav"}), volume = 4, speed = 1.3, oct = 1.7, fx = {dist = 0.85, tremolo = true, reverb = true}},
	screamC = {pool = pool({"swordslash.wav", "action_falling.mp3", "action_swim.mp3"}), volume = 3.5, speed = 0.9, oct = 1.4, fx = {dist = 0.7, chorus = true, reverb = true}},
	ghostA = {pool = pool({"action_falling.mp3", "action_swim.mp3", "Rocket whoosh 01.wav"}, "ghost"), volume = 4, speed = 1.5, oct = 1.6, fx = {flange = true, chorus = true, echo = true, reverb = true}},
	ghostB = {pool = pool({"swordslash.wav", "unsheath.wav", "action_swim.mp3"}), volume = 3.6, speed = 0.7, oct = 1.2, fx = {tremolo = true, flange = true, echo = true, reverb = true}},
	ghostC = {pool = pool({"glassbreak.wav", "action_falling.mp3", "bass.wav"}), volume = 3, speed = 0.55, oct = 0.7, fx = {dist = 0.6, chorus = true, reverb = true}},
	laughA = {pool = pool({"action_jump.mp3", "kerplunk.wav", "splat.wav", "snap.wav"}, "laugh"), volume = 4, speed = 0.6, oct = 0.6, fx = {dist = 0.6, chorus = true, echo = true}},
	laughB = {pool = pool({"splat.wav", "clickfast.wav", "action_get_up.mp3", "snap.wav"}), volume = 3.5, speed = 1, oct = 1.4, fx = {dist = 0.5, tremolo = true, echo = true}},
	wlaughA = {pool = pool({"splat.wav", "kerplunk.wav", "action_jump.mp3", "snap.wav"}, "laugh"), volume = 4, speed = 0.5, oct = 0.55, fx = {dist = 0.7, chorus = true, echo = true}},
	wlaughB = {pool = pool({"clickfast.wav", "snap.wav", "action_get_up.mp3"}), volume = 3.5, speed = 1.3, oct = 1.7, fx = {dist = 0.5, flange = true, tremolo = true, echo = true}},
	slurp = {pool = pool({"splat.wav", "kerplunk.wav", "impact_water.mp3"}), volume = 3.5, speed = 0.45, fx = {reverb = true}},
	morphA = {pool = pool({"action_get_up.mp3"}), volume = 3.5, speed = 0.25, fx = {dist = 0.5, reverb = true}},
	morphB = {pool = pool({"glassbreak.wav", "metal.mp3", "kerplunk.wav"}), volume = 2.6, speed = 0.3, fx = {reverb = true, flange = true}},
}

local GROUPS = {
	step = {"stepA", "stepB"},
	grind = {"grind"},
	jump = {"jump"},
	land = {"landA", "landB"},
	roar = {"roarA", "roarB", "roarC"},
	scream = {"screamA", "screamB", "screamC"},
	ghost = {"ghostA", "ghostB", "ghostC"},
	laugh = {"laughA", "laughB"},
	wlaugh = {"wlaughA", "wlaughB"},
	slurp = {"slurp"},
	morph = {"morphA", "morphB"},
}

local boost = {speed = 16, jump = 50, speedOn = false, jumpOn = false}
local state = {on = false}
local setRobot, doRoar, doScream, doGhost, doLaugh, doFold, shutdown

local function make(class, props, parent)
	local inst = Instance.new(class)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local old = playerGui:FindFirstChild("RobotKinhDiGui")
if old then
	old:Destroy()
end

local gui = make("ScreenGui", {
	Name = "RobotKinhDiGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local flash = make("Frame", {
	Name = "Flash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(120, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 0,
}, gui)

local function doFlash(color, alpha)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = alpha
	TweenService:Create(flash, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
end

local FULL = UDim2.fromOffset(224, 238)
local MINI = UDim2.fromOffset(224, 30)

local main = make("Frame", {
	Name = "Main",
	Size = FULL,
	Position = UDim2.fromOffset(24, 110),
	BackgroundColor3 = Color3.fromRGB(16, 16, 20),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
make("UIStroke", {Color = Color3.fromRGB(200, 40, 40), Thickness = 1.5}, main)

local bar = make("Frame", {
	Name = "Bar",
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(46, 10, 14),
	BorderSizePixel = 0,
	Active = true,
}, main)

make("TextLabel", {
	Size = UDim2.new(1, -64, 1, 0),
	Position = UDim2.fromOffset(10, 0),
	BackgroundTransparency = 1,
	Text = "ROBOT KINH DỊ",
	Font = Enum.Font.SourceSansBold,
	TextSize = 17,
	TextColor3 = Color3.fromRGB(255, 90, 90),
	TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local function button(parent, props)
	props.Font = Enum.Font.SourceSansBold
	props.TextColor3 = Color3.fromRGB(255, 255, 255)
	props.BorderSizePixel = 0
	local b = make("TextButton", props, parent)
	make("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
	return b
end

local btnMin = button(bar, {
	Size = UDim2.fromOffset(24, 22),
	Position = UDim2.new(1, -56, 0, 4),
	BackgroundColor3 = Color3.fromRGB(60, 60, 70),
	Text = "—",
	TextSize = 16,
})

local btnClose = button(bar, {
	Size = UDim2.fromOffset(24, 22),
	Position = UDim2.new(1, -28, 0, 4),
	BackgroundColor3 = Color3.fromRGB(170, 30, 30),
	Text = "X",
	TextSize = 15,
})

local body = make("Frame", {
	Name = "Body",
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.fromOffset(0, 30),
	BackgroundTransparency = 1,
}, main)

make("TextLabel", {
	Size = UDim2.fromOffset(100, 24),
	Position = UDim2.fromOffset(12, 6),
	BackgroundTransparency = 1,
	Text = "Biến hình",
	Font = Enum.Font.SourceSansBold,
	TextSize = 17,
	TextColor3 = Color3.fromRGB(235, 235, 235),
	TextXAlignment = Enum.TextXAlignment.Left,
}, body)

local switch = make("TextButton", {
	Size = UDim2.fromOffset(46, 24),
	Position = UDim2.new(1, -58, 0, 6),
	BackgroundColor3 = Color3.fromRGB(70, 70, 78),
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
}, body)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, switch)

local knob = make("Frame", {
	Size = UDim2.fromOffset(20, 20),
	Position = UDim2.fromOffset(2, 2),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
}, switch)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

local function newRow(y)
	local f = make("Frame", {
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, y),
		BackgroundTransparency = 1,
	}, body)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, f)
	return f
end

local function rowButton(parent, text, color, order, count)
	return button(parent, {
		Size = UDim2.new(1 / count, -4 * (count - 1) / count, 1, 0),
		BackgroundColor3 = color,
		Text = text,
		TextSize = 14,
		LayoutOrder = order,
	})
end

local row1 = newRow(38)
local row2 = newRow(72)

local btnRoar = rowButton(row1, "GẦM", Color3.fromRGB(120, 20, 24), 1, 3)
local btnScream = rowButton(row1, "HÉT", Color3.fromRGB(96, 22, 96), 2, 3)
local btnLaugh = rowButton(row1, "CƯỜI", Color3.fromRGB(30, 96, 54), 3, 3)
local btnGhost = rowButton(row2, "HÉT MA", Color3.fromRGB(40, 64, 120), 1, 2)
local btnFold = rowButton(row2, "GẬP NGƯỜI", Color3.fromRGB(130, 56, 12), 2, 2)

local defaultInfo = ("Cao %d · Ngang %.1f"):format(ROBOT_HEIGHT, ROBOT_WIDTH)
local info = make("TextLabel", {
	Size = UDim2.new(1, -24, 0, 16),
	Position = UDim2.fromOffset(12, 190),
	BackgroundTransparency = 1,
	Text = defaultInfo,
	Font = Enum.Font.SourceSans,
	TextSize = 14,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(160, 160, 170),
}, body)
make("UITextSizeConstraint", {MaxTextSize = 14}, info)

local hintId = 0
local function hint(text, dur)
	hintId = hintId + 1
	local id = hintId
	info.Text = text
	task.delay(dur or 1.8, function()
		if hintId == id and info.Parent then
			info.Text = defaultInfo
		end
	end)
end

local function setSwitch(on)
	TweenService:Create(knob, TweenInfo.new(0.15), {
		Position = on and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2),
	}):Play()
	TweenService:Create(switch, TweenInfo.new(0.15), {
		BackgroundColor3 = on and Color3.fromRGB(200, 40, 40) or Color3.fromRGB(70, 70, 78),
	}):Play()
end

local sliderFn, sliderInput

local function makeSlider(y, name, default, color, onChange)
	local label = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(12, y),
		BackgroundTransparency = 1,
		Text = name .. ": " .. default,
		Font = Enum.Font.SourceSansBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(220, 220, 228),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, body)
	local track = make("TextButton", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, y + 18),
		BackgroundColor3 = Color3.fromRGB(44, 44, 52),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, body)
	make("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
	local f0 = (default - 1) / 299
	local fill = make("Frame", {
		Size = UDim2.new(f0, 0, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, track)
	make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
	local thumb = make("Frame", {
		Size = UDim2.fromOffset(18, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(f0, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, track)
	make("UICorner", {CornerRadius = UDim.new(1, 0)}, thumb)
	local function setValue(v)
		v = math.clamp(math.floor(v + 0.5), 1, 300)
		local f = (v - 1) / 299
		fill.Size = UDim2.new(f, 0, 1, 0)
		thumb.Position = UDim2.new(f, 0, 0.5, 0)
		label.Text = name .. ": " .. v
		onChange(v)
	end
	local function fromX(x)
		local w = math.max(track.AbsoluteSize.X, 1)
		setValue(1 + math.clamp((x - track.AbsolutePosition.X) / w, 0, 1) * 299)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderFn = fromX
			sliderInput = input
			fromX(input.Position.X)
		end
	end)
end

makeSlider(108, "Tốc độ chạy", boost.speed, Color3.fromRGB(230, 120, 30), function(v)
	boost.speed = v
	boost.speedOn = true
end)

makeSlider(148, "Sức bật", boost.jump, Color3.fromRGB(60, 140, 230), function(v)
	boost.jump = v
	boost.jumpOn = true
end)

local sliderConn = UserInputService.InputChanged:Connect(function(input)
	if sliderFn and (input == sliderInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
		sliderFn(input.Position.X)
	end
end)

local sliderEndConn = UserInputService.InputEnded:Connect(function(input)
	if sliderInput and (input == sliderInput or (input.UserInputType == Enum.UserInputType.MouseButton1 and sliderInput.UserInputType == Enum.UserInputType.MouseButton1)) then
		sliderFn = nil
		sliderInput = nil
	end
end)

local collapsed = false
btnMin.Activated:Connect(function()
	collapsed = not collapsed
	btnMin.Text = collapsed and "+" or "—"
	body.Visible = not collapsed
	TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = collapsed and MINI or FULL,
	}):Play()
end)

switch.Activated:Connect(function()
	setRobot(not state.on)
end)

btnRoar.Activated:Connect(function()
	doRoar()
end)

btnScream.Activated:Connect(function()
	doScream()
end)

btnLaugh.Activated:Connect(function()
	doLaugh()
end)

btnGhost.Activated:Connect(function()
	doGhost()
end)

btnFold.Activated:Connect(function()
	doFold()
end)

btnClose.Activated:Connect(function()
	shutdown()
end)

local dragging = false
local dragStart, startPos, dragInput

bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

bar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

local dragConn = UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		local screen = gui.AbsoluteSize
		local x = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, screen.X - main.AbsoluteSize.X))
		local y = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, screen.Y - main.AbsoluteSize.Y))
		main.Position = UDim2.fromOffset(x, y)
	end
end)
local PI = math.pi
local MAT = Enum.Material
local BLOCK, BALL, CYL = Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder

local ORDER = {
	"Hips", "Spine", "Chest", "Neck", "Head", "Jaw", "Tg1", "Tg2",
	"MJ", "Tn1", "Tn2", "Tn3", "Tn4", "Tn5", "Tn6",
	"ShA", "UA", "FA", "HA", "FgA", "TpA", "ThA",
	"ShB", "UB", "FB", "HB", "FgB", "TpB", "ThB",
	"LA", "KA", "FtA", "ToA", "LB", "KB", "FtB", "ToB",
	"Mound", "Vine1", "Vine2", "Vine3",
}

local PARENT = {
	Hips = "ROOT", Spine = "Hips", Chest = "Spine", Neck = "Chest", Head = "Neck", Jaw = "Head",
	Tg1 = "Jaw", Tg2 = "Tg1",
	MJ = "Spine", Tn1 = "Spine", Tn2 = "Tn1", Tn3 = "Tn2", Tn4 = "Tn3", Tn5 = "Tn4", Tn6 = "Tn5",
	ShA = "Chest", UA = "ShA", FA = "UA", HA = "FA", FgA = "HA", TpA = "FgA", ThA = "HA",
	ShB = "Chest", UB = "ShB", FB = "UB", HB = "FB", FgB = "HB", TpB = "FgB", ThB = "HB",
	LA = "Hips", KA = "LA", FtA = "KA", ToA = "FtA",
	LB = "Hips", KB = "LB", FtB = "KB", ToB = "FtB",
	Mound = "Chest", Vine1 = "Mound", Vine2 = "Vine1", Vine3 = "Vine2",
}

local PIVOT = {
	Hips = V3(0, 5.4, 0), Spine = V3(0, 6.2, 0), Chest = V3(0, 7.3, 0),
	Neck = V3(0, 9.7, -0.5), Head = V3(0, 10.2, -0.8), Jaw = V3(0, 9.7, -1.2),
	Tg1 = V3(0, 9.85, -2.1), Tg2 = V3(0, 9, -2.15),
	MJ = V3(0, 6.15, -1.4),
	Tn1 = V3(0, 6.55, -1.45), Tn2 = V3(0, 6.55, -3.05), Tn3 = V3(0, 6.55, -4.65),
	Tn4 = V3(0, 6.55, -6.25), Tn5 = V3(0, 6.55, -7.85), Tn6 = V3(0, 6.55, -9.45),
	ShA = V3(1.9, 9.5, 0), ShB = V3(-1.9, 9.5, 0),
	Mound = V3(-2.4, 9.2, 0.3), Vine1 = V3(-3, 8.6, 0.9), Vine2 = V3(-3.1, 7.2, 1), Vine3 = V3(-3.2, 5.8, 1.1),
	UA = V3(2.5, 13.2, 0), FA = V3(2.7, 8.6, -0.1), HA = V3(2.8, 4.4, -0.45),
	FgA = V3(2.8, 3.7, -1.25), TpA = V3(2.8, 2.4, -1.25), ThA = V3(3.3, 4, -0.8),
	UB = V3(-2.5, 13.2, 0), FB = V3(-2.7, 8.6, -0.1), HB = V3(-2.8, 4.4, -0.45),
	FgB = V3(-2.8, 3.7, -1.25), TpB = V3(-2.8, 2.4, -1.25), ThB = V3(-3.3, 4, -0.8),
	LA = V3(1.5, 9, 0), KA = V3(1.6, 4.7, 0), FtA = V3(1.6, 0.8, -0.2), ToA = V3(1.6, 0.4, -1.2),
	LB = V3(-1.7, 9, 0), KB = V3(-1.8, 4.7, 0), FtB = V3(-1.8, 0.8, -0.2), ToB = V3(-1.8, 0.4, -1.2),
}

local SHIFT = {}
for _, n in ipairs({
	"Hips", "Spine", "Chest", "Neck", "Head", "Jaw", "Tg1", "Tg2",
	"MJ", "Tn1", "Tn2", "Tn3", "Tn4", "Tn5", "Tn6",
	"ShA", "ShB", "Mound", "Vine1", "Vine2", "Vine3",
}) do
	SHIFT[n] = L
	PIVOT[n] = PIVOT[n] + V3(0, L, 0)
end

local C = {
	stone = Color3.fromRGB(104, 100, 108),
	dark = Color3.fromRGB(56, 52, 60),
	light = Color3.fromRGB(150, 146, 152),
	steel = Color3.fromRGB(86, 90, 100),
	black = Color3.fromRGB(10, 10, 12),
	white = Color3.fromRGB(240, 240, 235),
	bone = Color3.fromRGB(205, 198, 178),
	blood = Color3.fromRGB(110, 12, 16),
	leaf = Color3.fromRGB(30, 78, 36),
	leaf2 = Color3.fromRGB(20, 54, 26),
	sclera = Color3.fromRGB(228, 214, 190),
	vein = Color3.fromRGB(150, 20, 28),
	lid = Color3.fromRGB(62, 26, 28),
	tongue = Color3.fromRGB(150, 30, 45),
}

local R = nil

local FALLBACK = {
	SND .. "action_jump_land.mp3",
	SND .. "action_jump.mp3",
	SND .. "action_get_up.mp3",
	SND .. "action_footsteps_plastic.mp3",
}
local AVAILABLE = {}
local RESOLVED = {}
local OWN = {}
local soundsReady = false

local function probe(id)
	local s = Instance.new("Sound")
	s.Volume = 0
	s.SoundId = id
	s.Parent = SoundService
	pcall(function()
		ContentProvider:PreloadAsync({s})
	end)
	local t0 = os.clock()
	while not s.IsLoaded and os.clock() - t0 < 2.5 do
		task.wait(0.05)
	end
	AVAILABLE[id] = s.IsLoaded
	s:Destroy()
end

task.spawn(function()
	local seen, list = {}, {}
	local function collect(id)
		if not seen[id] then
			seen[id] = true
			list[#list + 1] = id
		end
	end
	for _, cfg in pairs(SOUNDS) do
		for _, id in ipairs(cfg.pool) do
			collect(id)
		end
	end
	for _, id in ipairs(FALLBACK) do
		collect(id)
	end
	local pending = #list
	for _, id in ipairs(list) do
		task.spawn(function()
			probe(id)
			pending = pending - 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
	for name, cfg in pairs(SOUNDS) do
		local pick
		for _, id in ipairs(cfg.pool) do
			if AVAILABLE[id] then
				pick = id
				OWN[name] = true
				break
			end
		end
		if not pick then
			for _, id in ipairs(FALLBACK) do
				if AVAILABLE[id] then
					pick = id
					break
				end
			end
		end
		RESOLVED[name] = pick
	end
	soundsReady = true
	local function count(group)
		local n = 0
		for _, name in ipairs(GROUPS[group]) do
			if OWN[name] then
				n = n + 1
			end
		end
		return n
	end
	hint(("Âm thanh: Gầm %d · Hét %d · Cười %d · Ma %d"):format(count("roar"), count("scream"), count("laugh"), count("ghost")), 6)
end)

local function waitSounds()
	local t0 = os.clock()
	while not soundsReady and os.clock() - t0 < 6 do
		task.wait(0.1)
	end
end

local function addFx(s, class, props)
	local e = Instance.new(class)
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Parent = s
end

local function newSound(name, parent)
	local cfg = SOUNDS[name]
	local s = Instance.new("Sound")
	s.Name = "RK_" .. name
	s.SoundId = RESOLVED[name] or ""
	s.Volume = cfg.volume
	s.PlaybackSpeed = cfg.speed
	s.Looped = cfg.loop == true
	s.RollOffMinDistance = 40
	s.RollOffMaxDistance = 260
	local fx = cfg.fx or {}
	if cfg.oct then
		addFx(s, "PitchShiftSoundEffect", {Octave = cfg.oct})
	end
	if fx.dist then
		addFx(s, "DistortionSoundEffect", {Level = fx.dist})
	end
	if fx.tremolo then
		addFx(s, "TremoloSoundEffect", {Depth = 0.8, Duty = 0.5, Frequency = 9})
	end
	if fx.flange then
		addFx(s, "FlangeSoundEffect", {Depth = 0.8, Mix = 0.7, Rate = 3})
	end
	if fx.chorus then
		addFx(s, "ChorusSoundEffect", {Depth = 0.9, Mix = 0.8, Rate = 6})
	end
	if fx.echo then
		addFx(s, "EchoSoundEffect", {Delay = 0.16, Feedback = 0.4, DryLevel = 0, WetLevel = -4})
	end
	if fx.reverb then
		addFx(s, "ReverbSoundEffect", {DecayTime = 3, Density = 1, Diffusion = 1, DryLevel = 0, WetLevel = -5})
	end
	s.Parent = parent
	return s
end

local function playSound(r, group, volMul, jitter)
	local list = GROUPS[group]
	if not list then
		return
	end
	for _, name in ipairs(list) do
		local s = r.sounds[name]
		if s and s.Parent then
			local cfg = SOUNDS[name]
			s.Volume = cfg.volume * (volMul or 1)
			s.PlaybackSpeed = cfg.speed * (jitter or 1)
			s.TimePosition = 0
			s:Play()
		end
	end
end

local function oneShot(parent, group, speedMul)
	for _, name in ipairs(GROUPS[group]) do
		local s = newSound(name, parent)
		s.PlaybackSpeed = SOUNDS[name].speed * speedMul
		s:Play()
		Debris:AddItem(s, 6)
	end
end

local function dust(hrp, g, count)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = V3(1, 1, 1)
	anchor.CFrame = CFrame.new(hrp.Position - V3(0, g, 0))
	anchor.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(150, 140, 130))
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(6, 18)
	e.SpreadAngle = Vector2.new(80, 80)
	e.Rate = 0
	e.Parent = anchor
	e:Emit(count or 30)
	Debris:AddItem(anchor, 3)
end

local function hidePart(r, d)
	if r.model and d:IsDescendantOf(r.model) then
		return
	end
	if d:IsA("BasePart") or d:IsA("Decal") then
		if d.Transparency < 1 and not d:FindFirstAncestorOfClass("Tool") then
			r.hidden[#r.hidden + 1] = {d, d.Transparency}
			d.Transparency = 1
		end
	end
end

local model, bones, pivot, rng, laughPart
local eyes, lights, emitters = {}, {}, {}
local tongueParts = {}

local function add(bone, shape, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size * S
	p.Color = color
	p.Material = mat or MAT.Slate
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	local w = Instance.new("Weld")
	w.Part0 = bones[bone]
	w.Part1 = p
	local pos = cf.Position + V3(0, SHIFT[bone] or 0, 0)
	w.C0 = pivot[bone]:Inverse() * (CFrame.new(pos * S) * cf.Rotation)
	w.Parent = p
	p.Parent = model
	return p, w
end

local function box(bone, x, y, z, cf, color, mat)
	return add(bone, BLOCK, V3(x, y, z), cf, color, mat)
end

local function ball(bone, d, cf, color, mat)
	return add(bone, BALL, V3(d, d, d), cf, color, mat)
end

local function col(bone, len, dia, cf, color, mat)
	return add(bone, CYL, V3(len, dia, dia), cf * CFrame.Angles(0, 0, PI / 2), color, mat)
end

local function claw(bone, cf, h, w, curve, color, segs, tipc)
	segs = segs or 5
	local seg = h / segs
	local cur = cf
	for i = 1, segs do
		local ww = w * (1 - (i - 1) / segs * 0.85)
		local c = (i == segs and tipc) and tipc or color
		box(bone, ww, seg + 0.04, ww, cur * CFrame.new(0, seg / 2, 0), c, MAT.Slate)
		cur = cur * CFrame.new(0, seg, 0) * CFrame.Angles(curve, 0, 0)
	end
end

local function aim(pos, dir)
	local d = dir.Unit
	local up = math.abs(d.Y) > 0.95 and V3(1, 0, 0) or V3(0, 1, 0)
	return CFrame.lookAt(pos, pos + d, up) * CFrame.Angles(-PI / 2, 0, 0)
end

local function spike(bone, pos, dir, len, w, color)
	claw(bone, aim(pos, dir), len, w, 0, color, 3, C.blood)
end

local function crack(bone, pos, len, ang)
	box(bone, 0.07, len, 0.05, CFrame.new(pos) * CFrame.Angles(0, 0, ang), Color3.fromRGB(255, 40, 20), MAT.Neon)
end

local function rocks(bone, cx, cy, cz, rx, ry, rz, count, minS, maxS)
	for i = 1, count do
		local s = rng:NextNumber(minS, maxS)
		local px = cx + rng:NextNumber(-1, 1) * rx
		local py = cy + rng:NextNumber(-1, 1) * ry
		local pz = cz + rng:NextNumber(-1, 1) * rz
		local color = (i % 3 == 0) and C.dark or ((i % 3 == 1) and C.stone or C.light)
		box(bone, s, s * rng:NextNumber(0.6, 1.3), s * rng:NextNumber(0.7, 1.2),
			CFrame.new(px, py, pz) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)),
			color, (i % 2 == 0) and MAT.Slate or MAT.Concrete)
	end
end

local function smiley(bone, pos, d)
	local cf = CFrame.new(pos)
	ball(bone, d, cf, C.black, MAT.SmoothPlastic)
	for _, sx in ipairs({-1, 1}) do
		ball(bone, d * 0.17, cf * CFrame.new(sx * d * 0.2, d * 0.14, -d * 0.44), C.white, MAT.Neon)
	end
	for i = -2, 2 do
		ball(bone, d * 0.1, cf * CFrame.new(i * d * 0.12, d * (-0.24 + 0.05 * i * i), -d * 0.45), C.white, MAT.Neon)
	end
end

local function sun(bone, pos, d)
	local cf = CFrame.new(pos)
	add(bone, CYL, V3(d * 0.05, d * 0.5, d * 0.5), cf * CFrame.Angles(0, PI / 2, 0), C.black, MAT.SmoothPlastic)
	for k = 0, 7 do
		box(bone, d * 0.1, d * 0.42, d * 0.05,
			cf * CFrame.Angles(0, 0, math.rad(k * 45)) * CFrame.new(0, d * 0.42, 0), C.black, MAT.SmoothPlastic)
	end
end

local function truss(bone, cx, cy, cz, w, h, d, levels, color)
	local t = 0.13
	local seg = h / levels
	for _, sx in ipairs({-1, 1}) do
		for _, sz in ipairs({-1, 1}) do
			box(bone, t, h, t, CFrame.new(cx + sx * w / 2, cy, cz + sz * d / 2), color, MAT.Metal)
		end
	end
	for i = 0, levels do
		local y = cy - h / 2 + i * seg
		box(bone, w, t, t, CFrame.new(cx, y, cz - d / 2), color, MAT.Metal)
		box(bone, w, t, t, CFrame.new(cx, y, cz + d / 2), color, MAT.Metal)
		box(bone, t, t, d, CFrame.new(cx - w / 2, y, cz), color, MAT.Metal)
		box(bone, t, t, d, CFrame.new(cx + w / 2, y, cz), color, MAT.Metal)
	end
	local aw = math.atan(w / seg)
	local ad = math.atan(d / seg)
	local lw = math.sqrt(seg * seg + w * w)
	local ld = math.sqrt(seg * seg + d * d)
	for i = 1, levels do
		local y = cy - h / 2 + (i - 0.5) * seg
		local sg = (i % 2 == 0) and 1 or -1
		box(bone, t, lw, t, CFrame.new(cx, y, cz - d / 2) * CFrame.Angles(0, 0, aw * sg), color, MAT.Metal)
		box(bone, t, lw, t, CFrame.new(cx, y, cz + d / 2) * CFrame.Angles(0, 0, -aw * sg), color, MAT.Metal)
		box(bone, t, ld, t, CFrame.new(cx - w / 2, y, cz) * CFrame.Angles(ad * sg, 0, 0), color, MAT.Metal)
		box(bone, t, ld, t, CFrame.new(cx + w / 2, y, cz) * CFrame.Angles(-ad * sg, 0, 0), color, MAT.Metal)
	end
end

local function vineLine(bone, a, b, t)
	local d = b - a
	local len = d.Magnitude
	if len > 0.02 then
		local up = math.abs(d.Unit.Y) > 0.95 and V3(1, 0, 0) or V3(0, 1, 0)
		box(bone, t, t, len + 0.05, CFrame.lookAt((a + b) / 2, b, up), C.leaf2, MAT.Grass)
	end
end

local function helix(bone, cx, cz, y0, y1, r, turns, n)
	local prev
	for i = 0, n do
		local a = i / n
		local th = a * turns * 2 * PI
		local p = V3(cx + math.cos(th) * r, y0 + (y1 - y0) * a, cz + math.sin(th) * r)
		if prev then
			vineLine(bone, prev, p, 0.13)
		end
		prev = p
	end
end

local function emitter(bone, props)
	local e = Instance.new("ParticleEmitter")
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Parent = bones[bone]
	emitters[#emitters + 1] = e
	return e
end
local RED = Color3.fromRGB(255, 35, 25)
local AMB = Color3.fromRGB(255, 150, 30)
local YEL = Color3.fromRGB(255, 225, 70)
local PALE = Color3.fromRGB(210, 225, 255)
local GRN = Color3.fromRGB(120, 255, 80)

local function eye(bone, pos, d, iris, withLight, fz, slit, tilt)
	local f = fz or -1
	local cf = CFrame.new(pos)
	box(bone, d * 1.7, d * 1.5, d * 0.6, cf * CFrame.new(0, 0, -f * d * 0.22), C.black, MAT.SmoothPlastic)
	ball(bone, d, cf, C.sclera, MAT.SmoothPlastic)
	for i = 1, (d > 0.4) and 5 or 3 do
		local t = rng:NextNumber(0.85, 1.15)
		local a = rng:NextNumber(0, 2 * PI)
		local dir = V3(math.sin(t) * math.cos(a), math.sin(t) * math.sin(a), f * math.cos(t))
		local tan = V3(math.cos(t) * math.cos(a), math.cos(t) * math.sin(a), -f * math.sin(t))
		local c = pos + dir * (d * 0.505)
		box(bone, d * 0.045, d * 0.045, d * 0.34, CFrame.lookAt(c, c + tan), C.vein, MAT.SmoothPlastic)
	end
	local ir, irW = ball(bone, d * 0.6, cf * CFrame.new(0, 0, f * d * 0.33), iris, MAT.Neon)
	local ir2, ir2W = ball(bone, d * 0.42, cf * CFrame.new(0, 0, f * d * 0.43), iris:Lerp(C.black, 0.55), MAT.SmoothPlastic)
	local pupil, pupW
	if slit then
		pupil, pupW = box(bone, d * 0.1, d * 0.5, d * 0.1, cf * CFrame.new(0, 0, f * d * 0.64), C.black, MAT.SmoothPlastic)
	else
		pupil, pupW = ball(bone, d * 0.3, cf * CFrame.new(0, 0, f * d * 0.58), C.black, MAT.SmoothPlastic)
	end
	local hl, hlW = ball(bone, d * 0.13, cf * CFrame.new(d * 0.13, d * 0.13, f * d * 0.69), C.white, MAT.Neon)
	local up, upW = box(bone, d * 1.25, d * 0.5, d * 0.5, cf * CFrame.new(0, d * 0.62, f * d * 0.5) * CFrame.Angles(0, 0, tilt or 0), C.lid, MAT.SmoothPlastic)
	local lo, loW = box(bone, d * 1.25, d * 0.42, d * 0.5, cf * CFrame.new(0, -d * 0.6, f * d * 0.5), C.lid, MAT.SmoothPlastic)
	eyes[#eyes + 1] = {
		iris = ir, pupil = pupil, base = iris, slit = slit, d = d * S,
		moves = {{irW, irW.C0}, {ir2W, ir2W.C0}, {pupW, pupW.C0}, {hlW, hlW.C0}},
		upW = upW, upC0 = upW.C0, loW = loW, loC0 = loW.C0,
		phase = rng:NextNumber(0, 6.28), blink = rng:NextNumber(1, 5), closed = 0, lid = 0.1,
		lookT = rng:NextNumber(0, 2), tx = 0, ty = 0, lx = 0, ly = 0, dil = 1,
	}
	if withLight then
		local l = Instance.new("PointLight")
		l.Color = iris
		l.Range = 16
		l.Brightness = 1.5
		l.Parent = ir
		lights[#lights + 1] = l
	end
	return ir
end

local function runeRing(bone, pos, d)
	local cf = CFrame.new(pos)
	local glow = Color3.fromRGB(255, 40, 25)
	for k = 0, 9 do
		local a = k * PI / 5
		box(bone, d * 0.12, d * 0.3, 0.06,
			cf * CFrame.new(math.cos(a) * d * 0.5, math.sin(a) * d * 0.5, 0) * CFrame.Angles(0, 0, a), glow, MAT.Neon)
	end
	ball(bone, d * 0.16, cf * CFrame.new(0, 0, -0.02), glow, MAT.Neon)
end

local function buildMouth()
	box("Spine", 2.5, 1.35, 0.15, CFrame.new(0, 6.62, -1.24), C.black, MAT.SmoothPlastic)
	box("Spine", 2.3, 1.1, 0.1, CFrame.new(0, 6.62, -1.3), C.blood, MAT.SmoothPlastic)
	for _, sx in ipairs({-0.7, 0, 0.7}) do
		ball("Spine", 0.17, CFrame.new(sx, 6.62, -1.4), RED, MAT.Neon)
	end
	box("Spine", 2.8, 0.4, 0.5, CFrame.new(0, 7.15, -1.42), C.dark)
	for i = -4, 4 do
		spike("Spine", V3(i * 0.3, 6.98, -1.72), V3(0, -1, 0), 0.5 + ((i % 2 == 0) and 0.25 or 0), 0.2, C.bone)
	end
	box("MJ", 2.8, 0.85, 0.45, CFrame.new(0, 6.6, -1.45), C.dark)
	for i = -4, 4 do
		spike("MJ", V3(i * 0.3 + 0.15, 7.0, -1.72), V3(0, 1, 0), 0.45 + ((i % 2 ~= 0) and 0.25 or 0), 0.2, C.bone)
	end
	for _, sx in ipairs({-1, 1}) do
		spike("MJ", V3(sx * 1.45, 6.9, -1.6), V3(sx * 0.3, 1, -0.5), 0.9, 0.3, C.bone)
	end
	local TL = 1.6
	for i = 1, 6 do
		local B = "Tn" .. i
		local zc = -1.45 - (i - 1) * TL - TL / 2
		local w = 0.95 - i * 0.07
		local parts = {}
		parts[#parts + 1] = box(B, w, 0.28, TL + 0.06, CFrame.new(0, 6.55, zc), C.tongue, MAT.SmoothPlastic)
		parts[#parts + 1] = box(B, w * 0.22, 0.32, TL, CFrame.new(0, 6.57, zc), Color3.fromRGB(200, 80, 95), MAT.SmoothPlastic)
		for j = 1, 2 do
			parts[#parts + 1] = ball(B, 0.2, CFrame.new((j == 1 and -1 or 1) * w * 0.28, 6.7, zc + (j - 1.5) * 0.5), Color3.fromRGB(215, 120, 130), MAT.SmoothPlastic)
		end
		if i == 6 then
			for _, sx in ipairs({-1, 1}) do
				parts[#parts + 1] = box(B, 0.22, 0.26, 1.1, CFrame.new(sx * 0.2, 6.55, zc - TL / 2 - 0.45) * CFrame.Angles(0, sx * 0.25, 0), C.tongue, MAT.SmoothPlastic)
			end
		end
		for _, p in ipairs(parts) do
			p.Transparency = 1
		end
		tongueParts[i] = parts
	end
end

local function buildTorso()
	box("Hips", 3.8, 1.4, 2.6, CFrame.new(0, 5.3, 0), C.light)
	box("Hips", 4.2, 0.6, 2.9, CFrame.new(0, 5.95, 0), C.dark)
	rocks("Hips", 0, 5.3, 0, 1.9, 0.6, 1.3, 8, 0.4, 0.9)
	truss("Hips", -1.9, 5, -1.55, 1, 1.1, 1, 2, C.steel)
	truss("Hips", 1.1, 4.5, -1.7, 0.9, 1, 0.9, 2, C.steel)
	for i = -2, 2 do
		box("Hips", 0.6, 1.3 + math.abs(i) * 0.2, 0.12,
			CFrame.new(i * 0.75, 4.35, -1.4) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.25, 0.25)), C.blood, MAT.Fabric)
	end
	ball("Hips", 1.7, CFrame.new(1.5, 5.2, 0), C.dark)
	ball("Hips", 1.7, CFrame.new(-1.7, 5.2, 0), C.dark)
	for i = -2, 2 do
		spike("Hips", V3(i * 0.8, 5.7, 1.35), V3(0, -0.15, 1), 1.6, 0.32, C.bone)
	end
	crack("Hips", V3(0.9, 5.4, -1.33), 0.8, 0.5)
	crack("Hips", V3(-1.2, 5.5, -1.33), 0.6, -0.4)

	box("Spine", 3.2, 1.4, 2.4, CFrame.new(0, 6.65, 0), C.dark)
	for _, sx in ipairs({-1, 1}) do
		for i = 0, 3 do
			spike("Spine", V3(sx * 1.55, 6.25 + i * 0.35, -0.6), V3(sx * 0.6, 0.15, -1), 1.5, 0.2, C.bone)
		end
		spike("Spine", V3(sx * 1.3, 6.8, 0.9), V3(sx, 0.3, 0.7), 1.3, 0.35, C.bone)
	end
	spike("Spine", V3(0, 6.9, 1.1), V3(0, 0.4, 1), 1.6, 0.45, C.bone)
	rocks("Spine", 0, 6.6, 0, 1.4, 0.5, 0.6, 5, 0.3, 0.6)

	box("Chest", 4, 2.8, 2.9, CFrame.new(0, 8.1, 0), C.stone)
	box("Chest", 4.8, 1.1, 3.2, CFrame.new(0, 9.3, 0), C.dark)
	box("Chest", 2.4, 1.9, 1.9, CFrame.new(0, 9.4, 1.5), C.stone)
	rocks("Chest", 0, 8.1, 0, 2.1, 1.4, 0.7, 12, 0.5, 0.9)
	rocks("Chest", 0, 10.2, 1.5, 1, 0.3, 0.6, 5, 0.4, 0.8)
	sun("Chest", V3(-0.8, 7.6, -1.5), 1.8)
	smiley("Chest", V3(1.1, 7.4, -1.75), 1)
	eye("Chest", V3(0.2, 8.75, -1.75), 0.75, RED, false, -1, true, 0)
	runeRing("Chest", V3(1.6, 8.8, -1.5), 0.8)
	runeRing("Chest", V3(-1.5, 8.8, -1.5), 0.8)
	for i = 1, 3 do
		box("Chest", 0.18, 0.9 + i * 0.3, 0.08, CFrame.new(-1.2 + i * 0.7, 7.1, -1.5), C.blood, MAT.SmoothPlastic)
	end
	crack("Chest", V3(1.8, 8.0, -1.5), 1, 0.4)
	crack("Chest", V3(-1.7, 8.2, -1.5), 0.9, -0.5)
	crack("Chest", V3(-1.4, 6.9, -1.5), 0.7, 0.3)
	for i = -2, 2 do
		spike("Chest", V3(i * 0.5, 10.35, 1.2), V3(i * 0.15, 1, 0.5), 1.3 + (2 - math.abs(i)) * 0.35, 0.36, C.bone)
	end
	col("Chest", 2.4, 0.9, CFrame.new(-0.9, 10.9, -0.5), C.light)
	box("Chest", 1.3, 0.25, 1.3, CFrame.new(-0.9, 12.1, -0.5), C.stone)
	box("Chest", 1.2, 0.25, 1.2, CFrame.new(-0.9, 9.7, -0.5), C.stone)
	ball("Chest", 1.4, CFrame.new(0, 9.7, -0.5), C.dark)
	ball("Chest", 1.7, CFrame.new(2.5, 9.4, 0), C.dark)
	ball("Chest", 1.7, CFrame.new(-2.5, 9.4, 0), C.dark)

	local mound = {
		{2.6, -2.2, 9.4, 0.5}, {2.2, -2.6, 10.6, 0.7}, {2, -1.7, 10.9, 0.9}, {2.2, -2.8, 8.4, 0.3},
		{1.8, -1.8, 8.6, 1.2}, {1.6, -3, 10, -0.2}, {1.8, -1.3, 10, 1.2}, {1.4, -2.4, 11.2, 0.4},
	}
	for i, m in ipairs(mound) do
		ball("Mound", m[1], CFrame.new(m[2], m[3], m[4]), (i % 2 == 0) and C.leaf or C.leaf2, MAT.Grass)
	end
	local flowers = {
		{0.9, -1.9, 11.45, 0.8, Color3.fromRGB(210, 20, 30)},
		{0.7, -1, 10.1, -0.6, Color3.fromRGB(40, 70, 220)},
		{0.6, -3.3, 10.4, -0.5, Color3.fromRGB(150, 70, 210)},
		{0.5, -2.9, 11.1, -0.1, Color3.fromRGB(245, 140, 40)},
		{1, -1.8, 9.2, -0.9, Color3.fromRGB(245, 245, 235)},
		{0.6, -3.4, 8.9, -0.3, Color3.fromRGB(235, 90, 160)},
		{0.5, -1.2, 11, 0.6, Color3.fromRGB(250, 220, 60)},
		{0.6, -2.6, 8, 0.9, Color3.fromRGB(190, 40, 60)},
		{0.5, -3, 9.7, 0.9, Color3.fromRGB(120, 90, 230)},
	}
	for _, fl in ipairs(flowers) do
		ball("Mound", fl[1], CFrame.new(fl[2], fl[3], fl[4]), fl[5], MAT.SmoothPlastic)
		ball("Mound", fl[1] * 0.35, CFrame.new(fl[2], fl[3] + fl[1] * 0.1, fl[4] - fl[1] * 0.4), Color3.fromRGB(250, 210, 50), MAT.SmoothPlastic)
	end
	local prev
	for i = 0, 9 do
		local a = 0.15 + i * 0.3
		local p = V3(-2 + math.cos(a), 10.9 + math.sin(a), 0.4)
		if prev then
			vineLine("Mound", prev, p, 0.12)
		end
		prev = p
	end
	local vineSpec = {{"Vine1", 8.6, 7.2}, {"Vine2", 7.2, 5.8}, {"Vine3", 5.8, 4.3}}
	for k, v in ipairs(vineSpec) do
		local x = -3 - (k - 1) * 0.1
		local z = 0.9 + (k - 1) * 0.1
		vineLine(v[1], V3(x, v[2], z), V3(x - 0.05, v[3], z + 0.05), 0.22)
		ball(v[1], 0.55, CFrame.new(x + 0.2, (v[2] + v[3]) / 2, z), C.leaf, MAT.Grass)
		ball(v[1], 0.45, CFrame.new(x - 0.2, v[3] + 0.2, z + 0.1), C.leaf2, MAT.Grass)
	end
	ball("Vine3", 0.7, CFrame.new(-3.3, 4.2, 1.2), Color3.fromRGB(210, 20, 30), MAT.SmoothPlastic)
	ball("Vine2", 0.55, CFrame.new(-3.3, 6.5, 1.1), Color3.fromRGB(150, 70, 210), MAT.SmoothPlastic)
end

local function buildBackEyes()
	local list = {
		{"Chest", -0.7, 9.8, 2.5, 0.6, RED, true, true},
		{"Chest", 0.6, 9.9, 2.5, 0.65, AMB, false, true},
		{"Chest", 0, 8.85, 2.5, 0.85, RED, true, true},
		{"Chest", -0.85, 8.9, 2.5, 0.5, YEL, false, false},
		{"Chest", 0.85, 8.9, 2.5, 0.5, PALE, false, false},
		{"Chest", 0.9, 8, 1.5, 0.5, AMB, false, true},
		{"Chest", -0.9, 8, 1.5, 0.5, RED, false, true},
		{"Chest", 1.7, 8.2, 1.5, 0.6, RED, false, false},
		{"Chest", 1.6, 7.2, 1.5, 0.55, YEL, false, true},
		{"Chest", -1.6, 7.2, 1.5, 0.55, GRN, false, true},
		{"Chest", 0, 7.3, 1.5, 0.8, RED, true, true},
		{"Spine", -0.8, 6.5, 1.25, 0.5, PALE, false, false},
		{"Spine", 0.8, 6.6, 1.25, 0.5, AMB, false, true},
	}
	for _, e in ipairs(list) do
		eye(e[1], V3(e[2], e[3], e[4]), e[5], e[6], e[7], 1, e[8], 0)
	end
end

local function buildHead()
	col("Neck", 1.2, 1, CFrame.new(0, 9.9, -0.5), C.dark)
	for _, sx in ipairs({-1, 1}) do
		box("Neck", 0.2, 1.2, 0.2, CFrame.new(sx * 0.5, 9.9, -0.95) * CFrame.Angles(0, 0, sx * 0.1), C.blood, MAT.SmoothPlastic)
	end
	box("Head", 2.3, 1.8, 2.2, CFrame.new(0, 10.6, -1), C.stone)
	box("Head", 2.5, 0.35, 0.8, CFrame.new(0, 11.5, -1.95), C.dark)
	box("Head", 0.3, 0.7, 0.3, CFrame.new(0, 10.3, -2.15), C.dark)
	eye("Head", V3(-0.65, 10.8, -2.1), 0.62, RED, true, -1, true, -0.3)
	eye("Head", V3(0.65, 10.8, -2.1), 0.62, RED, true, -1, true, 0.3)
	laughPart = eye("Head", V3(0, 11.2, -2.12), 0.42, YEL, true, -1, false, 0)
	eye("Head", V3(-0.92, 10.2, -2.12), 0.36, AMB, false, -1, true, -0.2)
	eye("Head", V3(0.92, 10.2, -2.12), 0.36, AMB, false, -1, true, 0.2)
	for _, sx in ipairs({-1, 1}) do
		box("Head", 0.1, 0.9, 0.05, CFrame.new(sx * 0.65, 10, -2.14), C.blood, MAT.SmoothPlastic)
	end
	for _, x in ipairs({-0.9, -0.54, -0.18, 0.18, 0.54, 0.9}) do
		local long = math.abs(x) > 0.8
		box("Head", 0.2, long and 0.8 or 0.45, 0.2, CFrame.new(x, long and 9.4 or 9.55, -2.1), C.bone, MAT.SmoothPlastic)
	end
	for _, sx in ipairs({-1, 1}) do
		spike("Head", V3(sx * 0.95, 9.75, -2.12), V3(0, -1, -0.1), 1.1, 0.22, C.bone)
	end
	rocks("Head", 0, 10.6, -1, 1.3, 0.8, 0.8, 6, 0.4, 0.7)
	claw("Head", CFrame.new(-0.8, 11.5, -0.7) * CFrame.Angles(0, 0, 0.55), 2.4, 0.55, -0.16, C.bone, 7, C.blood)
	claw("Head", CFrame.new(0.8, 11.5, -0.7) * CFrame.Angles(0, 0, -0.55), 2.4, 0.55, -0.16, C.bone, 7, C.blood)
	spike("Head", V3(-0.2, 11.5, -0.9), V3(-0.1, 1, 0), 1.2, 0.4, C.bone)
	spike("Head", V3(0.3, 11.5, -0.4), V3(0.1, 1, 0.2), 1.4, 0.4, C.bone)
	spike("Head", V3(-1.05, 11.2, -0.3), V3(-0.8, 1, 0), 1.2, 0.4, C.bone)
	spike("Head", V3(1.05, 11.2, -0.3), V3(0.8, 1, 0), 1.1, 0.4, C.bone)
	for i = -1, 1 do
		box("Head", 0.06, 1.6, 0.06, CFrame.new(i * 0.6, 10.3, 0.3) * CFrame.Angles(0.1, 0, i * 0.1), C.black, MAT.Fabric)
	end

	box("Jaw", 1.9, 0.5, 1.7, CFrame.new(0, 9.45, -1.3), C.dark)
	box("Jaw", 1.4, 0.15, 1.2, CFrame.new(0, 9.72, -1.3), C.blood, MAT.SmoothPlastic)
	for i = -2, 2 do
		local long = math.abs(i) == 2
		box("Jaw", 0.2, long and 1 or 0.5, 0.2, CFrame.new(i * 0.36, long and 10.1 or 9.95, -2.1), C.bone, MAT.SmoothPlastic)
	end
	for _, sx in ipairs({-1, 1}) do
		spike("Jaw", V3(sx * 0.8, 9.6, -2.1), V3(sx * 0.2, 1, -0.2), 1.5, 0.25, C.bone)
	end
	box("Jaw", 1, 0.15, 1, CFrame.new(0, 9.8, -1.5), Color3.fromRGB(170, 40, 50), MAT.SmoothPlastic)
	for i = -1, 1 do
		box("Jaw", 0.08, 0.9 + math.abs(i) * 0.3, 0.08, CFrame.new(i * 0.5, 9, -2.1), C.blood, MAT.SmoothPlastic)
	end

	box("Tg1", 0.5, 0.9, 0.14, CFrame.new(0, 9.4, -2.13), C.tongue, MAT.SmoothPlastic)
	box("Tg2", 0.46, 0.8, 0.12, CFrame.new(0, 8.6, -2.17), C.tongue, MAT.SmoothPlastic)
	box("Tg2", 0.16, 0.4, 0.1, CFrame.new(0, 8.05, -2.17), C.tongue, MAT.SmoothPlastic)
end

local function buildFx()
	local smoke = "rbxasset://textures/particles/smoke_main.dds"
	local spark = "rbxasset://textures/particles/sparkles_main.dds"
	emitter("Head", {
		Texture = spark,
		Color = ColorSequence.new(Color3.fromRGB(255, 50, 30)),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(1.5, 3),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = V3(0, 5, 0),
		LightEmission = 1,
		Rate = 14,
	})
	emitter("Chest", {
		Texture = smoke,
		Color = ColorSequence.new(Color3.fromRGB(18, 8, 10)),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 14)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = V3(0, 1, 0),
		Rate = 7,
	})
	emitter("Mound", {
		Texture = smoke,
		Color = ColorSequence.new(Color3.fromRGB(170, 200, 255)),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 6)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)}),
		Lifetime = NumberRange.new(2.5, 4),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = V3(0, 4, 0),
		LightEmission = 0.5,
		Rate = 5,
	})
	emitter("Jaw", {
		Texture = smoke,
		Color = ColorSequence.new(C.blood),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.25)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.3)}),
		Lifetime = NumberRange.new(1.2, 1.6),
		Speed = NumberRange.new(0, 2),
		SpreadAngle = Vector2.new(12, 12),
		Acceleration = V3(0, -45, 0),
		Rate = 6,
	})
	for _, f in ipairs({"FtA", "FtB"}) do
		emitter(f, {
			Texture = smoke,
			Color = ColorSequence.new(Color3.fromRGB(110, 20, 20)),
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 7)}),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1)}),
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = V3(0, 2, 0),
			Rate = 6,
		})
	end
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 40, 30)
	l.Range = 40
	l.Brightness = 1
	l.Parent = bones.Chest
	lights[#lights + 1] = l
	return emitter("Tn6", {
		Texture = smoke,
		Color = ColorSequence.new(C.blood),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.3)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.4)}),
		Lifetime = NumberRange.new(1, 1.5),
		Speed = NumberRange.new(0, 2),
		SpreadAngle = Vector2.new(20, 20),
		Acceleration = V3(0, -50, 0),
		Rate = 0,
	})
end
local function buildHand(k, s)
	local H, Fg, Tp, Th = "H" .. k, "Fg" .. k, "Tp" .. k, "Th" .. k
	local x0 = 2.8 * s
	box(H, 1.3, 0.7, 1.5, CFrame.new(x0, 4.05, -0.6), (s > 0) and C.stone or C.dark)
	rocks(H, x0, 4.05, -0.6, 0.5, 0.2, 0.5, 4, 0.3, 0.5)
	for i = -1, 1 do
		spike(H, V3(x0 + i * 0.4, 4.3, -0.1), V3(0, 0.6, 1), 0.9, 0.25, C.bone)
	end
	local lens = {1.0, 1.4, 1.5, 1.1}
	for i = 1, 4 do
		local x = x0 + (i - 2.5) * 0.32
		ball(Fg, 0.3, CFrame.new(x, 3.7, -1.25), C.dark)
		box(Fg, 0.2, 1.3, 0.2, CFrame.new(x, 3.05, -1.25), C.light)
		spike(Fg, V3(x, 3.3, -1.15), V3(0, 0.8, 0.8), 0.6, 0.14, C.bone)
		ball(Tp, 0.26, CFrame.new(x, 2.4, -1.25), C.dark)
		box(Tp, 0.17, 1.3, 0.17, CFrame.new(x, 1.75, -1.28), C.stone)
		spike(Tp, V3(x, 2.0, -1.2), V3(0, 0.8, 0.8), 0.5, 0.12, C.bone)
		claw(Tp, CFrame.new(x, 1.1, -1.28) * CFrame.Angles(PI, 0, 0), lens[i], 0.16, -0.5, C.bone, 5, C.blood)
	end
	ball(Th, 0.4, CFrame.new(x0 + 0.5 * s, 4, -0.8), C.dark)
	claw(Th, aim(V3(x0 + 0.5 * s, 4, -0.8), V3(s * 0.7, -0.6, -0.3)), 1.5, 0.26, 0.3, C.bone, 4, C.blood)
end

local function buildArmA()
	ball("ShA", 1.7, CFrame.new(2.5, 9.4, 0), C.dark)
	col("ShA", 0.5, 2.8, CFrame.new(2.55, 10, 0) * CFrame.Angles(0, 0, -0.2), C.stone)
	spike("ShA", V3(2.9, 10.2, 0), V3(0.5, 1, 0), 1.6, 0.45, C.bone)
	spike("ShA", V3(2.3, 10.2, 0.3), V3(-0.2, 1, 0.5), 1.3, 0.4, C.bone)
	spike("ShA", V3(2.6, 10.2, -0.4), V3(0.3, 1, -0.5), 1.2, 0.35, C.bone)

	col("UA", 4.6, 1.3, CFrame.new(2.6, 10.9, 0), C.stone)
	col("UA", 0.35, 1.7, CFrame.new(2.6, 13.1, 0), C.light)
	col("UA", 0.35, 1.7, CFrame.new(2.6, 8.9, 0), C.light)
	ball("UA", 1.4, CFrame.new(2.7, 8.6, -0.1), C.dark)
	smiley("UA", V3(2.35, 12.7, -0.7), 0.5)
	smiley("UA", V3(2.85, 12.7, -0.7), 0.5)
	sun("UA", V3(2.35, 12.1, -0.62), 0.45)
	sun("UA", V3(2.85, 12.1, -0.62), 0.45)
	eye("UA", V3(2.6, 10.9, -0.75), 0.6, RED, false, -1, true, 0)
	runeRing("UA", V3(2.6, 9.8, -0.75), 0.7)
	spike("UA", V3(3.3, 9.0, 0.2), V3(1, 0.2, 0.6), 1.2, 0.35, C.bone)
	spike("UA", V3(3.2, 10.2, 0.3), V3(1, 0.1, 0.7), 1, 0.3, C.bone)

	box("FA", 1.1, 4, 1.1, CFrame.new(2.75, 6.4, -0.3), C.dark)
	rocks("FA", 2.75, 6.4, -0.3, 0.55, 1.9, 0.55, 10, 0.35, 0.7)
	col("FA", 3.6, 0.22, CFrame.new(3.25, 6.4, -0.4), C.black, MAT.Metal)
	spike("FA", V3(3.3, 7.4, -0.2), V3(1, 0.9, 0.4), 1.1, 0.3, C.bone)
	spike("FA", V3(3.2, 5.4, -0.2), V3(1, 0.8, 0.5), 1, 0.28, C.bone)
	spike("FA", V3(2.75, 8.2, 0.3), V3(0, 0.5, 1), 1.6, 0.4, C.bone)
	crack("FA", V3(2.75, 6.2, -0.86), 1.2, 0.2)
	ball("FA", 1, CFrame.new(2.8, 4.4, -0.45), C.dark)
	buildHand("A", 1)
end

local function buildArmB()
	ball("ShB", 1.7, CFrame.new(-2.5, 9.4, 0), C.dark)
	box("ShB", 1.6, 1, 1.6, CFrame.new(-2.5, 9.5, 0), C.dark)
	spike("ShB", V3(-2.9, 10, 0), V3(-0.5, 1, 0), 1.5, 0.4, C.bone)
	spike("ShB", V3(-2.2, 10, 0.3), V3(0.2, 1, 0.5), 1.2, 0.35, C.bone)

	truss("UB", -2.55, 10.9, -0.1, 1, 4.4, 0.9, 5, C.steel)
	helix("UB", -2.55, -0.1, 8.8, 13, 0.75, 3.5, 20)
	ball("UB", 1.4, CFrame.new(-2.7, 8.6, -0.1), C.leaf2, MAT.Grass)
	eye("UB", V3(-2.5, 13.8, -0.95), 0.6, RED, false, -1, true, 0)
	runeRing("UB", V3(-2.55, 9.6, -0.65), 0.7)

	truss("FB", -2.7, 6.4, -0.3, 0.9, 4, 0.8, 5, C.steel)
	helix("FB", -2.7, -0.3, 4.5, 8.4, 0.65, 3, 18)
	spike("FB", V3(-3.2, 7.4, -0.2), V3(-1, 0.9, 0.4), 1.1, 0.3, C.bone)
	spike("FB", V3(-2.7, 8.2, 0.3), V3(0, 0.5, 1), 1.6, 0.4, C.bone)
	ball("FB", 1, CFrame.new(-2.8, 4.4, -0.45), C.dark)
	buildHand("B", -1)
end

local function buildFoot(k, x0, s)
	local F, T = "Ft" .. k, "To" .. k
	local glow = Color3.fromRGB(255, 40, 20)
	ball(F, 1.3, CFrame.new(x0, 0.8, -0.2), C.dark)
	box(F, 2.3, 0.75, 2.1, CFrame.new(x0, 0.4, 0), C.dark)
	box(F, 1.9, 0.5, 1.5, CFrame.new(x0, 0.75, -0.5) * CFrame.Angles(0.15, 0, s * 0.05), C.stone)
	rocks(F, x0, 0.5, -0.2, 1, 0.3, 0.9, 6, 0.3, 0.6)
	for i = 1, 3 do
		box(F, 0.07, 0.06, 0.9, CFrame.new(x0 + (i - 2) * 0.55, 1, -0.55) * CFrame.Angles(0, (i - 2) * 0.4, 0), glow, MAT.Neon)
	end
	spike(F, V3(x0 + 0.8 * s, 0.45, 0.8), V3(0.6 * s, 0.35, 1), 1.3, 0.4, C.bone)
	spike(F, V3(x0 + 1.1 * s, 0.9, -0.2), V3(s, 0.8, 0.3), 1.4, 0.4, C.bone)
	eye(F, V3(x0, 1.15, -1), 0.45, RED, false, -1, true, 0)
	box(T, 2.2, 0.45, 0.9, CFrame.new(x0, 0.28, -1.5), C.stone)
	local lens = {1.6, 2.1, 1.9, 1.4}
	for i = 1, 4 do
		local tx = x0 + (i - 2.5) * 0.52
		ball(T, 0.5, CFrame.new(tx, 0.3, -1.25), C.dark)
		box(T, 0.42, 0.38, 0.8, CFrame.new(tx, 0.27, -2), C.light)
		claw(T, CFrame.new(tx, 0.27, -2.4) * CFrame.Angles(-PI / 2 - 0.15, 0, 0), lens[i], 0.34, 0.28, C.bone, 5, C.blood)
		if i == 1 or i == 4 then
			spike(T, V3(tx, 0.5, -1.9), V3(0, 1, 1.2), 0.9, 0.2, C.bone)
		end
	end
end

local function buildLegs()
	col("LA", 4.2, 1.5, CFrame.new(1.5, 6.85, 0), C.stone)
	col("LA", 0.3, 1.85, CFrame.new(1.5, 8.9, 0), C.light)
	col("LA", 0.3, 1.85, CFrame.new(1.5, 6.85, 0), C.light)
	col("LA", 0.3, 1.85, CFrame.new(1.5, 4.85, 0), C.light)
	ball("LA", 1.7, CFrame.new(1.6, 4.7, 0), C.dark)
	spike("LA", V3(2.2, 7.4, 0.3), V3(1, 0.5, 0.4), 1.5, 0.4, C.bone)
	spike("LA", V3(2.1, 5.6, 0.2), V3(1, 0.4, 0.5), 1.2, 0.35, C.bone)
	runeRing("LA", V3(1.5, 7.6, -0.8), 0.9)
	crack("LA", V3(1.9, 6.4, -0.76), 1.1, 0.15)
	truss("KA", 1.6, 3, -0.1, 1.4, 3.4, 1.4, 4, C.steel)
	ball("KA", 1.8, CFrame.new(1.6, 4.5, -0.3), C.dark)
	col("KA", 1, 1.25, CFrame.new(1.6, 1, 0), C.stone)
	spike("KA", V3(1.6, 3.2, 0.75), V3(0, 0.4, 1), 1.4, 0.35, C.bone)
	spike("KA", V3(2.3, 3.8, 0), V3(1, 0.4, 0), 1.2, 0.3, C.bone)
	eye("KA", V3(1.6, 3.6, -0.95), 0.5, RED, false, -1, true, 0)
	ball("KA", 1, CFrame.new(1.6, 0.8, -0.2), C.dark)

	box("LB", 1.9, 4.2, 1.9, CFrame.new(-1.75, 6.85, 0) * CFrame.Angles(0, math.rad(10), math.rad(6)), C.dark)
	rocks("LB", -1.75, 6.85, 0, 1, 2, 1, 12, 0.4, 0.9)
	spike("LB", V3(-2.6, 7.4, 0), V3(-1, 0.6, 0), 1.5, 0.4, C.bone)
	spike("LB", V3(-2.6, 5.6, 0.1), V3(-1, 0.4, 0.3), 1.2, 0.35, C.bone)
	helix("LB", -1.75, 0, 4.9, 8.8, 1.1, 3, 18)
	ball("LB", 1.7, CFrame.new(-1.8, 4.7, 0), C.stone)
	runeRing("LB", V3(-1.75, 7.4, -1.03), 0.9)
	box("KB", 2, 3.2, 2, CFrame.new(-1.85, 3, -0.1) * CFrame.Angles(0, math.rad(15), math.rad(-8)), C.stone)
	box("KB", 1.4, 1.6, 1.4, CFrame.new(-1.6, 3.4, -0.4) * CFrame.Angles(math.rad(10), math.rad(-20), math.rad(12)), C.dark)
	rocks("KB", -1.9, 3, -0.1, 1.1, 1.5, 1.1, 12, 0.4, 0.9)
	spike("KB", V3(-3, 3.6, 0.1), V3(-1, 0.6, 0.2), 1.4, 0.4, C.bone)
	spike("KB", V3(-1.8, 2.6, 0.95), V3(0, 0.4, 1), 1.4, 0.35, C.bone)
	eye("KB", V3(-1.8, 3.8, -1.25), 0.5, RED, false, -1, true, 0)
	col("KB", 1, 1.3, CFrame.new(-1.8, 1, 0), C.dark)
	ball("KB", 1, CFrame.new(-1.8, 0.8, -0.2), C.dark)

	buildFoot("A", 1.6, 1)
	buildFoot("B", -1.8, -1)
end
local K, Z = {}, {}
local function setKZ(list, k, z)
	for _, n in ipairs(list) do
		K[n] = k
		Z[n] = z
	end
end
setKZ({"Hips"}, 90, 0.9)
setKZ({"Spine", "Chest"}, 65, 0.7)
setKZ({"Neck"}, 45, 0.6)
setKZ({"Head"}, 38, 0.55)
setKZ({"Jaw"}, 150, 0.5)
setKZ({"Tg1"}, 28, 0.3)
setKZ({"Tg2"}, 22, 0.25)
setKZ({"MJ"}, 120, 0.55)
setKZ({"Tn1", "Tn2", "Tn3", "Tn4", "Tn5", "Tn6"}, 26, 0.22)
setKZ({"ShA", "ShB"}, 42, 0.7)
setKZ({"UA", "UB"}, 36, 0.55)
setKZ({"FA", "FB"}, 34, 0.5)
setKZ({"HA", "HB"}, 44, 0.45)
setKZ({"FgA", "FgB"}, 60, 0.4)
setKZ({"TpA", "TpB"}, 70, 0.38)
setKZ({"ThA", "ThB"}, 55, 0.45)
setKZ({"LA", "LB"}, 110, 0.9)
setKZ({"KA", "KB"}, 100, 0.8)
setKZ({"FtA", "FtB"}, 120, 0.8)
setKZ({"ToA", "ToB"}, 90, 0.6)
setKZ({"Mound"}, 20, 0.35)
setKZ({"Vine1", "Vine2", "Vine3"}, 12, 0.25)

local DAMP = {}
for n, k in pairs(K) do
	DAMP[n] = 2 * Z[n] * math.sqrt(k)
end

local function fpart(folder, root, shape, size, off, color, mat)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = mat or MAT.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = p
	w.C0 = off
	w.Parent = p
	p.Parent = folder
	return p
end

local function froot(folder)
	local p = Instance.new("Part")
	p.Size = V3(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = folder
	return p
end

local function floatEye(folder, d, iris)
	local root = froot(folder)
	fpart(folder, root, BALL, V3(d, d, d), CFrame.new(), C.sclera)
	fpart(folder, root, BALL, V3(d * 0.6, d * 0.6, d * 0.6), CFrame.new(0, 0, -d * 0.33), iris, MAT.Neon)
	fpart(folder, root, BLOCK, V3(d * 0.1, d * 0.5, d * 0.1), CFrame.new(0, 0, -d * 0.62), C.black)
	for i = 1, 6 do
		local a = i * 1.05
		fpart(folder, root, BLOCK, V3(d * 0.04, d * 0.04, d * 0.4),
			CFrame.new(math.cos(a) * d * 0.38, math.sin(a) * d * 0.38, -d * 0.32) * CFrame.Angles(math.sin(a) * 0.9, math.cos(a) * 0.9, 0), C.vein)
	end
	return root
end

local function floatSkull(folder, d)
	local root = froot(folder)
	fpart(folder, root, BALL, V3(d, d, d), CFrame.new(), C.bone)
	fpart(folder, root, BLOCK, V3(d * 0.62, d * 0.22, d * 0.5), CFrame.new(0, -d * 0.5, -d * 0.12), C.bone)
	for _, sx in ipairs({-1, 1}) do
		fpart(folder, root, BALL, V3(d * 0.26, d * 0.26, d * 0.26), CFrame.new(sx * d * 0.2, d * 0.05, -d * 0.4), C.black)
		fpart(folder, root, BALL, V3(d * 0.1, d * 0.1, d * 0.1), CFrame.new(sx * d * 0.2, d * 0.05, -d * 0.5), RED, MAT.Neon)
	end
	fpart(folder, root, BLOCK, V3(d * 0.1, d * 0.14, d * 0.1), CFrame.new(0, -d * 0.18, -d * 0.48), C.black)
	for i = -2, 2 do
		fpart(folder, root, BLOCK, V3(d * 0.07, d * 0.12, d * 0.05), CFrame.new(i * d * 0.1, -d * 0.4, -d * 0.38), C.white)
	end
	return root
end

local function floatShard(folder, len)
	local root = froot(folder)
	fpart(folder, root, BLOCK, V3(len * 0.14, len, len * 0.14), CFrame.new(), C.bone, MAT.Slate)
	fpart(folder, root, BLOCK, V3(len * 0.16, len * 0.22, len * 0.16), CFrame.new(0, len * 0.4, 0), C.blood)
	return root
end

local function floatSmiley(folder, d)
	local root = froot(folder)
	fpart(folder, root, BALL, V3(d, d, d), CFrame.new(), C.black)
	for _, sx in ipairs({-1, 1}) do
		fpart(folder, root, BALL, V3(d * 0.17, d * 0.17, d * 0.17), CFrame.new(sx * d * 0.2, d * 0.14, -d * 0.44), C.white, MAT.Neon)
	end
	for i = -2, 2 do
		fpart(folder, root, BALL, V3(d * 0.1, d * 0.1, d * 0.1), CFrame.new(i * d * 0.12, d * (-0.24 + 0.05 * i * i), -d * 0.45), C.white, MAT.Neon)
	end
	return root
end

local function floatSun(folder, d)
	local root = froot(folder)
	fpart(folder, root, CYL, V3(d * 0.08, d * 0.9, d * 0.9), CFrame.Angles(0, PI / 2, 0), C.black)
	for k = 0, 7 do
		fpart(folder, root, BLOCK, V3(d * 0.14, d * 0.42, d * 0.08),
			CFrame.Angles(0, 0, math.rad(k * 45)) * CFrame.new(0, d * 0.65, 0), C.black)
	end
	return root
end

local function buildSigil(folder)
	local root = froot(folder)
	local D = 32
	local disc = fpart(folder, root, CYL, V3(0.12, D, D), CFrame.Angles(0, 0, PI / 2), Color3.fromRGB(150, 10, 14), MAT.Neon)
	disc.Transparency = 0.62
	local ring = fpart(folder, root, CYL, V3(0.14, D * 0.86, D * 0.86), CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, PI / 2), C.black)
	ring.Transparency = 0.4
	for k = 0, 5 do
		local bar = fpart(folder, root, BLOCK, V3(D * 0.8, 0.1, 0.35), CFrame.new(0, 0.08, 0) * CFrame.Angles(0, k * PI / 6, 0), Color3.fromRGB(255, 40, 25), MAT.Neon)
		bar.Transparency = 0.3
	end
	local inner = fpart(folder, root, CYL, V3(0.16, D * 0.4, D * 0.4), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, PI / 2), Color3.fromRGB(190, 15, 20), MAT.Neon)
	inner.Transparency = 0.5
	local core = fpart(folder, root, CYL, V3(0.18, D * 0.32, D * 0.32), CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, PI / 2), C.black)
	core.Transparency = 0.35
	return root
end

local function fxBuild()
	local folder = Instance.new("Model")
	folder.Name = "RK_Floaters"
	local list = {}
	local function reg(root, kind, rad, h, spd, ph, bob)
		list[#list + 1] = {root = root, kind = kind, rad = rad, h = h, spd = spd, ph = ph, bob = bob}
	end
	local irises = {RED, AMB, YEL, PALE, GRN, RED}
	for i = 1, 6 do
		reg(floatEye(folder, 2 + (i % 3) * 0.7, irises[i]), "eye", 10 + (i % 3) * 2.5, 5 + i * 4,
			(i % 2 == 0 and 1 or -1) * (0.28 + i * 0.04), i * 1.1, 1.4)
	end
	for i = 1, 4 do
		reg(floatSkull(folder, 2.4 + (i % 2) * 0.6), "skull", 13 + i, 8 + i * 4.5,
			(i % 2 == 0 and -1 or 1) * (0.22 + i * 0.03), i * 1.7, 1.8)
	end
	for i = 1, 9 do
		reg(floatShard(folder, 3 + (i % 3) * 1.2), "shard", 8 + (i % 4) * 2, 3 + i * 3,
			(i % 2 == 0 and 1 or -1) * (0.5 + (i % 3) * 0.12), i * 0.7, 1.2)
	end
	for i = 1, 3 do
		reg(floatSmiley(folder, 2.4), "glyph", 15 + i, 6 + i * 7, 0.2 * (i % 2 == 0 and 1 or -1) + 0.1, i * 2.1, 2)
	end
	for i = 1, 2 do
		reg(floatSun(folder, 2.6), "glyph", 12 + i * 3, 12 + i * 9, -0.18 * i, i * 3, 2)
	end
	local sigil = buildSigil(folder)
	folder.Parent = workspace
	return {folder = folder, list = list, sigil = sigil}
end

local function fxUpdate(r, t, fear)
	local base = r.hrp.Position - V3(0, r.g, 0)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or (base + V3(0, 10, -20))
	for _, f in ipairs(r.fx.list) do
		local a = t * f.spd * (1 + fear * 0.8) + f.ph
		local rad = f.rad * (1 + fear * 0.12)
		local pos = base + V3(math.cos(a) * rad, f.h + math.sin(t * 0.9 + f.ph * 2) * f.bob, math.sin(a) * rad)
		if f.kind == "shard" then
			f.root.CFrame = CFrame.new(pos) * CFrame.Angles(t * 0.7 + f.ph, t * 1.1 + f.ph * 2, t * 0.5)
		else
			f.root.CFrame = CFrame.lookAt(pos, camPos)
		end
	end
	r.fx.sigil.CFram
local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function updateRobot(r, dt)
	local hrp, hum = r.hrp, r.hum
	if not hrp.Parent or not hum.Parent or hum.Health <= 0 then
		return
	end
	dt = math.min(dt, 1 / 30)
	local vel = hrp.AssemblyLinearVelocity
	local flat = V3(vel.X, 0, vel.Z)
	local speed = flat.Magnitude
	local aspeed = math.min(speed, 36)
	local air = hum.FloorMaterial == Enum.Material.Air
	r.t = r.t + dt
	local t = r.t
	local amp = math.clamp(aspeed / 14, 0, 1.2)
	local walking = (not air) and speed > 1.2
	if walking then
		r.phase = r.phase + dt * (2 + aspeed * 0.12)
	end
	local sw, cw = math.sin(r.phase), math.cos(r.phase)
	local sw2 = math.sin(r.phase - 0.8)
	local sw3 = math.sin(r.phase - 1.6)
	local sign = sw >= 0 and 1 or -1
	if walking and sign ~= r.lastSign then
		playSound(r, "step", 0.6 + amp * 0.6, 0.85 + math.random() * 0.3)
		dust(hrp, r.g, 6)
		r.shake = math.max(r.shake, 0.06 + amp * 0.12)
	end
	r.lastSign = sign

	local grind = r.sounds.grind
	if walking then
		grind.Volume = SOUNDS.grind.volume * math.clamp(amp, 0.25, 1)
		if not grind.Playing then
			grind:Play()
		end
	elseif grind.Playing then
		grind:Stop()
	end

	local airBefore = r.airT
	r.airT = air and (r.airT + dt) or 0
	if air then
		if not r.air then
			r.air = true
			r.minVy = 0
			if vel.Y > 8 then
				playSound(r, "jump", 1, 0.95 + math.random() * 0.1)
			end
		end
		r.minVy = math.min(r.minVy, vel.Y)
	elseif r.air then
		r.air = false
		if airBefore > 0.18 then
			local fall = math.clamp(-r.minVy / 50, 0, 1)
			r.squat = 0.35 + fall * 0.65
			r.shake = math.max(r.shake, 0.2 + fall * 0.8)
			playSound(r, "land", 0.5 + fall, 1)
			dust(hrp, r.g, 20 + math.floor(fall * 40))
		end
	end

	local lv = hrp.CFrame:VectorToObjectSpace(flat)
	local accel = math.clamp((-lv.Z - r.vf) * 3, -40, 40)
	r.vf = r.vf + (-lv.Z - r.vf) * (1 - math.exp(-dt * 3))
	r.acc = r.acc + (accel - r.acc) * (1 - math.exp(-dt * 6))
	r.turn = r.turn + (hrp.AssemblyAngularVelocity.Y - r.turn) * (1 - math.exp(-dt * 6))
	local turn = math.clamp(r.turn, -4, 4)
	local lean = math.clamp(r.vf / 14, -1, 1.2) * 0.12
	local push = math.clamp(-r.acc * 0.006, -0.3, 0.3)

	local fold = r.fold
	local fb, fm, fext = 0, 0, 0
	if fold then
		fold.t = fold.t + dt
		local ft = fold.t
		fb = smooth(ft / 0.9) - smooth((ft - 6.2) / 0.8)
		fm = smooth((ft - 0.8) / 0.6) - smooth((ft - 6) / 0.5)
		fext = math.clamp((ft - 1.4) / 0.9, 0, 1) - math.clamp((ft - 5.4) / 0.9, 0, 1)
		if ft > 2 and ft < 5.5 then
			r.laugh = math.max(r.laugh, 1)
		end
		if ft > 7.1 then
			r.fold = nil
		end
	end

	r.laughCd = r.laughCd - dt
	if r.laughCd <= 0 then
		r.laughCd = 9 + math.random() * 14
		doLaugh()
	end
	r.screamCd = r.screamCd - dt
	if r.screamCd <= 0 then
		r.screamCd = 25 + math.random() * 25
		if not r.fold then
			doScream()
		end
	end
	r.ghostCd = r.ghostCd - dt
	if r.ghostCd <= 0 then
		r.ghostCd = 35 + math.random() * 30
		if not r.fold then
			doGhost()
		end
	end
	r.spasmCd = r.spasmCd - dt
	if r.spasmCd <= 0 then
		r.spasmCd = 2.5 + math.random() * 4
		r.spasm = 0.35
	end

	local roarB = math.sin(math.clamp(r.roar / 1.4, 0, 1) * PI)
	local screamB = math.sin(math.clamp(r.scream / 1.6, 0, 1) * PI)
	local ghostB = math.sin(math.clamp(r.ghost / 2.2, 0, 1) * PI)
	local laughB = math.clamp(r.laugh, 0, 1)
	local sp = r.spasm > 0 and 1 or 0
	r.roar = math.max(0, r.roar - dt)
	r.scream = math.max(0, r.scream - dt)
	r.ghost = math.max(0, r.ghost - dt)
	r.laugh = math.max(0, r.laugh - dt)
	r.spasm = math.max(0, r.spasm - dt)

	local sq = r.squat
	r.squat = math.max(0, sq - dt * 2.2)
	local br = math.sin(t * 1.5)
	local nz1 = math.noise(t * 0.35, 1.7)
	local nz2 = math.noise(t * 0.5, 4.3)
	local tg = {}
	for _, n in ipairs(ORDER) do
		tg[n] = V3(0, 0, 0)
	end
	local hipY = 0

	if air then
		local up = vel.Y > 0
		tg.Spine = V3(-0.1, 0, 0)
		tg.Chest = V3(-0.1, 0, 0)
		tg.Neck = V3(0.1, 0, 0)
		tg.Head = V3(0.1, 0, 0)
		tg.Jaw = V3(-0.6, 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			tg["Sh" .. k] = V3(-0.3, 0, d * 0.25)
			tg["U" .. k] = V3(up and 2 or 1.2, 0, d * (up and 0.4 or 1))
			tg["F" .. k] = V3(0.5, 0, 0)
			tg["H" .. k] = V3(0.3, 0, 0)
			tg["Fg" .. k] = V3(-0.5, 0, 0)
			tg["Tp" .. k] = V3(-0.4, 0, 0)
			tg["Th" .. k] = V3(0, 0, d * 0.5)
			tg["L" .. k] = V3(d == 1 and 0.6 or -0.2, 0, d * 0.03)
			tg["K" .. k] = V3(d == 1 and -0.9 or -0.6, 0, 0)
			tg["Ft" .. k] = V3(0.4, 0, 0)
			tg["To" .. k] = V3(-0.35, 0, 0)
		end
	else
		hipY = -1.1 * amp * sw * sw - 2.4 * sq
		tg.Hips = V3(0, sw * 0.12 * amp, sw * 0.07 * amp + math.sin(t * 0.7) * 0.02)
		tg.Spine = V3(-0.16 + br * 0.02 - sq * 0.12 - lean, -sw * 0.12 * amp + nz1 * 0.05, -sw * 0.05 * amp)
		tg.Chest = V3(-0.22 + br * 0.03 - sq * 0.1 - lean * 0.8, -sw2 * 0.12 * amp + nz2 * 0.06, sw2 * 0.04 * amp)
		tg.Neck = V3(0.14 + br * 0.02 + sq * 0.2 + lean * 0.6, nz1 * 0.5, nz2 * 0.12)
		tg.Head = V3(0.12 + nz2 * 0.3, nz2 * 0.9 + sw3 * 0.06 * amp, math.sin(t * 0.45) * 0.08)
		tg.Jaw = V3(-0.14 - (0.5 + 0.5 * math.sin(t * 2.1)) * 0.08 - amp * 0.05 * math.abs(sw), 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			local s1, s2, s3 = d * sw, d * sw2, d * sw3
			local n1 = math.noise(t * 0.45 + d, 11.3)
			local n2 = math.noise(t * 0.6 + d, 23.7)
			local n3 = math.noise(t * 0.8 + d * 2, 37.1)
			tg["Sh" .. k] = V3(br * 0.05 + n1 * 0.12 + sq * 0.1, 0, d * (0.04 + n2 * 0.06))
			tg["U" .. k] = V3(0.22 - s1 * 0.3 * amp + br * 0.03 + n1 * 0.12 + push, n2 * 0.15, d * (0.1 + math.abs(turn) * 0.05 + math.sin(t * 0.9 + d) * 0.03))
			tg["F" .. k] = V3(0.22 + math.max(0, -s2) * 0.3 * amp + br * 0.03 + n2 * 0.12, d * n3 * 0.25, 0)
			tg["H" .. k] = V3(0.12 + s3 * 0.2 * amp + n3 * 0.35, d * n1 * 0.2, d * n2 * 0.25)
			tg["Fg" .. k] = V3(0.35 + math.sin(t * 5.1 + d * 2) * 0.1 + math.noise(t * 2, 9.37 + d * 5.1) * 0.5, 0, 0)
			tg["Tp" .. k] = V3(0.3 + math.sin(t * 6.3 + d) * 0.12 + math.noise(t * 2.4, 31.4 + d * 3.1) * 0.5, 0, 0)
			tg["Th" .. k] = V3(math.noise(t * 1.5, 41.3 + d) * 0.4, 0, d * (0.2 + math.sin(t * 3 + d) * 0.1))
			local c1 = d * cw
			tg["L" .. k] = V3(s1 * 0.45 * amp + 0.9 * sq, 0, d * 0.03)
			tg["K" .. k] = V3(-math.max(0, c1) * 0.9 * amp - 1.6 * sq, 0, 0)
			tg["Ft" .. k] = V3(-(tg["L" .. k].X + tg["K" .. k].X) * 0.85 + 0.05, 0, 0)
			tg["To" .. k] = V3(s1 * 0.35 * amp - 0.08 + math.noise(t * 1.4, 51.3 + d) * 0.3 * (1 - math.min(amp, 1)), 0, 0)
		end
	end

	local vs = math.clamp(r.vf / 14, -1, 1.2)
	tg.Mound = V3(-0.1 * vs + math.sin(t * 1.2) * 0.03, 0, math.sin(t * 0.9) * 0.03)
	for k = 1, 3 do
		tg["Vine" .. k] = V3(-0.3 * vs - 0.06 + math.sin(t * 1.4 + k * 0.9) * 0.1, 0, math.sin(t * 1.1 + k) * 0.08)
	end
	for i = 1, 6 do
		local f = 0.4 + i * 0.15
		local w = 1 + laughB
		tg["Tn" .. i] = V3(-0.1 + math.sin(t * 6 + i * 0.8) * 0.25 * f * w, math.sin(t * 4.3 + i * 1.1) * 0.2 * f * w, 0)
	end

	if roarB > 0 then
		tg.Spine = tg.Spine + V3(0.25 * roarB, 0, 0)
		tg.Chest = tg.Chest + V3(0.45 * roarB, 0, 0)
		tg.Neck = tg.Neck + V3(0.25 * roarB, 0, 0)
		tg.Head = tg.Head + V3(0.55 * roarB, 0, 0)
		tg.Jaw = tg.Jaw + V3(-0.95 * roarB, 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			tg["U" .. k] = tg["U" .. k] + V3(roarB, 0, d * 0.55 * roarB)
			tg["F" .. k] = tg["F" .. k] + V3(0.4 * roarB, 0, 0)
			tg["Fg" .. k] = tg["Fg" .. k] + V3(-0.5 * roarB, 0, 0)
		end
	end

	if screamB > 0 then
		local jit = math.random() - 0.5
		tg.Spine = tg.Spine + V3(0.2 * screamB, 0, 0)
		tg.Chest = tg.Chest + V3(0.3 * screamB, 0, 0)
		tg.Head = tg.Head + V3(0.7 * screamB, jit * 0.6 * screamB, jit * 0.3 * screamB)
		tg.Jaw = tg.Jaw + V3(-1.1 * screamB, 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			tg["U" .. k] = tg["U" .. k] + V3(1.8 * screamB, 0, d * 0.3 * screamB)
			tg["F" .. k] = tg["F" .. k] + V3(1.1 * screamB, 0, 0)
			tg["Fg" .. k] = tg["Fg" .. k] + V3(-0.8 * screamB, 0, 0)
			tg["Tp" .. k] = tg["Tp" .. k] + V3(-0.6 * screamB, 0, 0)
		end
	end

	if ghostB > 0 then
		local wob = math.sin(t * 14) * 0.15
		tg.Spine = tg.Spine + V3(0.3 * ghostB, 0, 0)
		tg.Chest = tg.Chest + V3(0.35 * ghostB, 0, 0)
		tg.Neck = tg.Neck + V3(0.4 * ghostB, 0, 0)
		tg.Head = tg.Head + V3(0.7 * ghostB, wob * ghostB, wob * ghostB)
		tg.Jaw = tg.Jaw + V3(-1.2 * ghostB, 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			tg["U" .. k] = tg["U" .. k] + V3(0.3 * ghostB, 0, d * 1.2 * ghostB)
			tg["F" .. k] = tg["F" .. k] + V3(0.5 * ghostB, 0, 0)
			tg["Fg" .. k] = tg["Fg" .. k] + V3(-0.7 * ghostB, 0, 0)
			tg["Tp" .. k] = tg["Tp" .. k] + V3(-0.7 * ghostB, 0, 0)
		end
	end

	if laughB > 0 then
		local lw = math.sin(t * 26)
		tg.Chest = tg.Chest + V3(lw * 0.07 * laughB, 0, 0)
		tg.Neck = tg.Neck + V3(0.15 * laughB, 0, 0)
		tg.Head = tg.Head + V3((0.35 + lw * 0.2) * laughB, 0, 0)
		tg.Jaw = tg.Jaw + V3(-(0.35 + 0.3 * lw) * laughB, 0, 0)
		tg.UA = tg.UA + V3(math.sin(t * 13) * 0.25 * laughB, 0, 0.25 * laughB)
		tg.UB = tg.UB + V3(math.sin(t * 13 + PI) * 0.25 * laughB, 0, -0.25 * laughB)
	end

	if fb > 0.001 then
		tg.Spine = tg.Spine + V3(-1.15 * fb, 0, 0)
		tg.Chest = tg.Chest + V3(-0.55 * fb, 0, 0)
		tg.Neck = tg.Neck + V3(0.9 * fb, 0, 0)
		tg.Head = tg.Head + V3(0.6 * fb, 0, 0)
		for _, p in ipairs(SIDES) do
			local k, d = p[1], p[2]
			tg["U" .. k] = tg["U" .. k] + V3(1.7 * fb, 0, d * 0.15 * fb)
			tg["F" .. k] = tg["F" .. k] + V3(-0.2 * fb, 0, 0)
		end
		tg.MJ = V3(-1.2 * fm, 0, 0)
		tg.Jaw = tg.Jaw + V3(-0.8 * fm, 0, 0)
		if fext > 0.5 then
			tg.Chest = tg.Chest + V3(math.sin(t * 34) * 0.1, 0, 0)
			tg.Head = tg.Head + V3(math.sin(t * 26) * 0.3, math.sin(t * 19) * 0.4, math.sin(t * 23) * 0.2)
			tg.Jaw = tg.Jaw + V3(-0.5 - 0.3 * math.sin(t * 30), 0, 0)
			tg.UA = tg.UA + V3(math.sin(t * 9) * 0.25, 0, 0)
			tg.UB = tg.UB + V3(math.sin(t * 9 + 2) * 0.25, 0, 0)
		end
	end

	if sp > 0 then
		local jx, jy = math.random() - 0.5, math.random() - 0.5
		local jz = math.random() - 0.5
		tg.Neck = tg.Neck + V3(jx * 0.3, jy * 0.6, jz * 0.2)
		tg.Head = tg.Head + V3(jx * 0.6, jy * 1.2, jz * 0.4)
		tg.UA = tg.UA + V3(jx * 0.2, 0, 0)
		tg.UB = tg.UB + V3(jy * 0.2, 0, 0)
		tg.FgA = tg.FgA + V3(jx * 1.2, 0, 0)
		tg.FgB = tg.FgB + V3(jy * 1.2, 0, 0)
		tg.TpA = tg.TpA + V3(jy * 1.2, 0, 0)
		tg.TpB = tg.TpB + V3(jx * 1.2, 0, 0)
	end

	local jawOpen = -tg.Jaw.X
	tg.Tg1 = V3(0.1 + math.sin(t * 2.3) * 0.12 + jawOpen * 0.15 + push, 0, math.sin(t * 1.7) * 0.1)
	tg.Tg2 = V3(0.18 + math.sin(t * 3.1 + 1) * 0.2 + push, 0, math.sin(t * 2.2 + 2) * 0.15)

	local a0 = 1 - math.exp(-dt * 14)
	r.hipY = r.hipY + (hipY - r.hipY) * a0
	for _, n in ipairs(ORDER) do
		local c, v = r.cur[n], r.vel[n]
		v = v + ((tg[n] - c) * K[n] - v * DAMP[n]) * dt
		c = c + v * dt
		r.vel[n], r.cur[n] = v, c
		local off = (n == "Hips") and CFrame.new(0, r.hipY * S, 0) or CFrame.new()
		r.welds[n].C0 = r.rest[n] * off * CFrame.Angles(c.X, c.Y, c.Z)
	end

	local count = fold and math.ceil(fext * 6 - 0.001) or 0
	if count < 0 then
		count = 0
	end
	for i = 1, 6 do
		local show = i <= count
		if r.tvis[i] ~= show then
			r.tvis[i] = show
			for _, p in ipairs(r.tongue[i]) do
				p.Transparency = show and 0 or 1
			end
		end
	end
	if r.drip then
		local want = (count >= 6) and 28 or 0
		if r.drip.Rate ~= want then
			r.drip.Rate = want
		end
	end

	local fear = math.max(roarB, screamB, laughB, ghostB, fb * 0.6)
	fxUpdate(r, t, fear)

	local ka = 1 - math.exp(-dt * 12)
	local la = 1 - math.exp(-dt * 28)
	for _, e in ipairs(r.eyes) do
		local pulse = 0.5 + 0.5 * math.sin(t * (2 + fear * 9) + e.phase)
		e.iris.Color = e.base:Lerp(C.black, 0.4 * (1 - pulse))
		e.blink = e.blink - dt
		if e.blink <= 0 then
			e.blink = 1.5 + math.random() * 4.5
			e.closed = 0.14
		end
		e.closed = math.max(0, e.closed - dt)
		local target = e.closed > 0 and 1 or (0.12 - 0.4 * fear + sp * 0.1)
		e.lid = e.lid + (target - e.lid) * la
		e.lookT = e.lookT - dt
		if e.lookT <= 0 then
			e.lookT = 0.4 + math.random() * 2
			if math.random() < 0.35 then
				e.tx, e.ty = 0, 0
			else
				e.tx, e.ty = math.random() * 2 - 1, math.random() * 2 - 1
			end
		end
		if fear > 0.3 then
			e.tx, e.ty = math.sin(t * 20 + e.phase), math.cos(t * 17 + e.phase)
		end
		e.lx = e.lx + (e.tx - e.lx) * ka
		e.ly = e.ly + (e.ty - e.ly) * ka
		local off = CFrame.new(e.lx * e.d * 0.1, e.ly * e.d * 0.08, 0)
		for _, m in ipairs(e.moves) do
			m[1].C0 = m[2] * off
		end
		e.upW.C0 = e.upC0 * CFrame.new(0, -e.d * 0.42 * e.lid, 0)
		e.loW.C0 = e.loC0 * CFrame.new(0, e.d * 0.38 * e.lid, 0)
		local dil = 1 + fear * 0.7 + math.sin(t * 3 + e.phase) * 0.08
		if math.abs(dil - e.dil) > 0.03 then
			e.dil = dil
			if e.slit then
				e.pupil.Size = V3(e.d * 0.1 * dil, e.d * 0.5, e.d * 0.1)
			else
				local sz = e.d * 0.3 * dil
				e.pupil.Size = V3(sz, sz, sz)
			end
		end
	end
	for i, l in ipairs(r.lights) do
		l.Brightness = (1.2 + fear * 3) * (0.7 + 0.3 * math.sin(t * 3 + i))
	end

	if r.shake > 0.003 then
		hum.CameraOffset = V3((math.random() - 0.5) * r.shake, CAMY + (math.random() - 0.5) * r.shake, 0)
		r.shake = r.shake * math.max(0, 1 - dt * 7)
	else
		r.shake = 0
		hum.CameraOffset = V3(0, CAMY, 0)
	end
ende = CFrame.new(base + V3(0, 0.15, 0)) * CFrame.Angles(0, t * 0.5, 0)
end
local function buildRobot(hrp, g)
	model = Instance.new("Model")
	model.Name = "RidKidRobot"
	bones, pivot, eyes, lights, emitters, laughPart = {}, {}, {}, {}, {}, nil
	tongueParts = {}
	rng = Random.new(77)
	local welds, rest = {}, {}
	for _, n in ipairs(ORDER) do
		pivot[n] = CFrame.new(PIVOT[n] * S)
	end
	for _, n in ipairs(ORDER) do
		local b = Instance.new("Part")
		b.Name = n
		b.Size = V3(0.2, 0.2, 0.2)
		b.Transparency = 1
		b.CanCollide = false
		b.CanQuery = false
		b.CanTouch = false
		b.Massless = true
		local w = Instance.new("Weld")
		local pn = PARENT[n]
		if pn == "ROOT" then
			w.Part0 = hrp
			w.C0 = CFrame.new(0, -g, 0) * pivot[n]
		else
			w.Part0 = bones[pn]
			w.C0 = pivot[pn]:Inverse() * pivot[n]
		end
		w.Part1 = b
		w.Parent = b
		b.Parent = model
		bones[n], welds[n], rest[n] = b, w, w.C0
	end
	buildTorso()
	buildMouth()
	buildBackEyes()
	buildHead()
	buildArmA()
	buildArmB()
	buildLegs()
	local drip = buildFx()
	return {model = model, welds = welds, rest = rest, eyes = eyes, lights = lights, laughPart = laughPart, tongue = tongueParts, drip = drip}
end

doRoar = function()
	local r = R
	if not r then
		hint("Hãy bật biến hình trước")
		return
	end
	playSound(r, "roar", 1, 0.95 + math.random() * 0.1)
	r.roar = 1.4
	r.shake = math.max(r.shake, 0.7)
	dust(r.hrp, r.g, 30)
	doFlash(Color3.fromRGB(120, 0, 0), 0.9)
end

doScream = function()
	local r = R
	if not r then
		hint("Hãy bật biến hình trước")
		return
	end
	playSound(r, "scream", 1, 0.9 + math.random() * 0.2)
	r.scream = 1.6
	r.shake = math.max(r.shake, 0.5)
	doFlash(Color3.fromRGB(150, 0, 20), 0.85)
end

doGhost = function()
	local r = R
	if not r then
		hint("Hãy bật biến hình trước")
		return
	end
	playSound(r, "ghost", 1, 0.9 + math.random() * 0.2)
	r.ghost = 2.2
	r.shake = math.max(r.shake, 0.4)
	doFlash(Color3.fromRGB(160, 180, 255), 0.88)
end

doLaugh = function()
	local r = R
	if not r then
		hint("Hãy bật biến hình trước")
		return
	end
	if r.laughing then
		return
	end
	r.laughing = true
	local n = math.random(6, 9)
	r.laugh = n * 0.34 + 0.5
	r.shake = math.max(r.shake, 0.25)
	task.spawn(function()
		for i = 1, n do
			if R ~= r then
				break
			end
			local name = (i % 2 == 1) and "laughA" or "laughB"
			local s = r.sounds[name]
			if s and s.Parent then
				s.Volume = SOUNDS[name].volume
				s.PlaybackSpeed = SOUNDS[name].speed * (0.85 + math.random() * 0.4)
				s.TimePosition = 0
				s:Play()
			end
			task.wait(0.26 + math.random() * 0.1)
		end
		task.wait(0.4)
		r.laughing = false
	end)
end

doFold = function()
	local r = R
	if not r then
		hint("Hãy bật biến hình trước")
		return
	end
	if r.fold or r.laughing then
		return
	end
	r.fold = {t = 0}
	r.laughing = true
	task.spawn(function()
		local function alive()
			return R == r and r.fold ~= nil
		end
		task.wait(0.8)
		if alive() then
			playSound(r, "ghost", 0.8, 0.8 + math.random() * 0.15)
			doFlash(Color3.fromRGB(140, 0, 0), 0.8)
			r.shake = math.max(r.shake, 0.6)
		end
		task.wait(0.7)
		if alive() then
			playSound(r, "slurp", 1, 1)
		end
		task.wait(0.5)
		local n = 0
		while alive() and r.fold.t < 5.4 do
			n = n + 1
			local name = (n % 2 == 1) and "wlaughA" or "wlaughB"
			local s = r.sounds[name]
			if s and s.Parent then
				s.Volume = SOUNDS[name].volume
				s.PlaybackSpeed = SOUNDS[name].speed * (0.6 + math.random() * 1.2)
				s.TimePosition = 0
				s:Play()
			end
			if n % 4 == 0 then
				playSound(r, "ghost", 0.5, 1.2 + math.random() * 0.4)
			end
			task.wait(0.14 + math.random() * 0.14)
		end
		r.laughing = false
	end)
end

local function releaseRobot(r)
	for _, c in ipairs(r.conns) do
		c:Disconnect()
	end
	r.conns = {}
	for _, rec in ipairs(r.hidden) do
		if rec[1].Parent then
			rec[1].Transparency = rec[2]
		end
	end
	for _, rec in ipairs(r.muted) do
		if rec[1].Parent then
			rec[1].Volume = rec[2]
		end
	end
	for _, s in pairs(r.sounds) do
		s:Destroy()
	end
	if r.fx and r.fx.folder then
		r.fx.folder:Destroy()
	end
	player.CameraMinZoomDistance = r.camMin
	if r.hum.Parent then
		r.hum.CameraOffset = r.camOffset
	end
end

local function stopRobot()
	local r = R
	if not r then
		return
	end
	R = nil
	if r.hrp.Parent then
		oneShot(r.hrp, "morph", 1.8)
		dust(r.hrp, r.g, 60)
	end
	releaseRobot(r)
	r.model:Destroy()
end

local function collapse(r)
	if R ~= r then
		return
	end
	R = nil
	for _, c in ipairs(r.conns) do
		c:Disconnect()
	end
	r.conns = {}
	if r.fx and r.fx.folder then
		r.fx.folder:Destroy()
	end
	for _, d in ipairs(r.model:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d.Enabled = false
		end
	end
	for _, w in pairs(r.welds) do
		w:Destroy()
	end
	for _, d in ipairs(r.model:GetChildren()) do
		if d:IsA("BasePart") then
			d.Massless = false
			if d.Transparency < 1 then
				d.CanCollide = true
			end
		end
	end
	for _, d in ipairs(r.model:GetChildren()) do
		if d:IsA("BasePart") and d.Transparency >= 1 and d.Size.X < 0.5 then
			d.AssemblyLinearVelocity = V3((math.random() - 0.5) * 24, math.random() * 14, (math.random() - 0.5) * 24)
		end
	end
	if r.sounds.grind then
		r.sounds.grind:Stop()
	end
	playSound(r, "roar", 1.2, 0.9)
	player.CameraMinZoomDistance = r.camMin
	Debris:AddItem(r.model, 8)
end

local function startRobot(char)
	waitSounds()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not char.Parent or not hum or not hrp or hum.Health <= 0 then
		return false
	end
	local g
	if hum.RigType == Enum.HumanoidRigType.R15 then
		g = hum.HipHeight + hrp.Size.Y / 2
	else
		g = 3 + hum.HipHeight
	end
	local r = {
		char = char, hum = hum, hrp = hrp, g = g, t = 0, phase = 0, lastSign = 1, shake = 0, squat = 0,
		air = false, airT = 0, minVy = 0, hipY = 0, roar = 0, scream = 0, ghost = 0, laugh = 0, laughing = false,
		spasm = 0, spasmCd = 3, laughCd = 8, screamCd = 22, ghostCd = 40, vf = 0, acc = 0, turn = 0,
		fold = nil, tvis = {},
		cur = {}, vel = {}, hidden = {}, conns = {}, sounds = {}, muted = {},
	}
	for _, n in ipairs(ORDER) do
		r.cur[n] = V3(0, 0, 0)
		r.vel[n] = V3(0, 0, 0)
	end
	for _, d in ipairs(char:GetDescendants()) do
		hidePart(r, d)
	end
	local built = buildRobot(hrp, g)
	r.model, r.welds, r.rest = built.model, built.welds, built.rest
	r.eyes, r.lights = built.eyes, built.lights
	r.tongue, r.drip = built.tongue, built.drip
	built.model.Parent = char
	r.fx = fxBuild()
	r.conns[#r.conns + 1] = char.DescendantAdded:Connect(function(d)
		hidePart(r, d)
	end)
	for name in pairs(SOUNDS) do
		local parent = (name:find("laugh") and built.laughPart) or hrp
		r.sounds[name] = newSound(name, parent)
	end
	for _, name in ipairs({"Running", "Jumping", "Landing", "GettingUp"}) do
		local s = hrp:FindFirstChild(name)
		if s and s:IsA("Sound") then
			r.muted[#r.muted + 1] = {s, s.Volume}
			s.Volume = 0
		end
	end
	r.camMin = player.CameraMinZoomDistance
	r.camOffset = hum.CameraOffset
	player.CameraMinZoomDistance = math.max(r.camMin, 20 * S)
	hum.CameraOffset = V3(0, CAMY, 0)
	r.conns[#r.conns + 1] = RunService.RenderStepped:Connect(function(dt)
		updateRobot(r, dt)
	end)
	r.conns[#r.conns + 1] = hum.Died:Connect(function()
		collapse(r)
	end)
	R = r
	playSound(r, "morph", 1, 1)
	dust(hrp, g, 60)
	r.shake = 0.5
	task.delay(0.45, function()
		if R == r then
			playSound(r, "roar", 1, 1)
			r.roar = 1.4
			r.shake = 0.7
		end
	end)
	task.delay(1.8, function()
		if R == r then
			doLaugh()
		end
	end)
	return true
end

setRobot = function(on)
	if on then
		if R or state.starting then
			return
		end
		state.starting = true
		local char = player.Character
		local ok = char and startRobot(char)
		state.starting = false
		if ok then
			state.on = true
			setSwitch(true)
		else
			state.on = false
			setSwitch(false)
			hint("Chưa sẵn sàng, thử lại")
		end
	else
		state.on = false
		setSwitch(false)
		stopRobot()
	end
end

local charConn = player.CharacterAdded:Connect(function(char)
	if not state.on then
		return
	end
	char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait(0.6)
	if state.on and player.Character == char and not R then
		startRobot(char)
	end
end)

local boostConn = RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if boost.speedOn then
		if not boost.origSpeed then
			boost.origSpeed = hum.WalkSpeed
		end
		if hum.WalkSpeed ~= boost.speed then
			hum.WalkSpeed = boost.speed
		end
	end
	if boost.jumpOn then
		if boost.origJump == nil then
			boost.origJump = hum.JumpPower
			boost.origUse = hum.UseJumpPower
		end
		if not hum.UseJumpPower then
			hum.UseJumpPower = true
		end
		if hum.JumpPower ~= boost.jump then
			hum.JumpPower = boost.jump
		end
	end
end)

shutdown = function()
	state.on = false
	boostConn:Disconnect()
	charConn:Disconnect()
	dragConn:Disconnect()
	sliderConn:Disconnect()
	sliderEndConn:Disconnect()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if boost.origSpeed then
			hum.WalkSpeed = boost.origSpeed
		end
		if boost.origJump ~= nil then
			hum.UseJumpPower = boost.origUse
			hum.JumpPower = boost.origJump
		end
	end
	stopRobot()
	gui:Destroy()
end
