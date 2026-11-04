if _G.HuyPremiumCleanup then
	pcall(_G.HuyPremiumCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local rad = math.rad
local TAU = math.pi * 2
local V3 = Vector3.new
local ZERO = Vector3.zero

local state = {mode = nil, cape = false}
local settings = {speed = 1}
local rig = {joints = {}, bases = {}}
local capeData = nil
local fx = nil
local alpha = 0
local clock = 0
local phase = 0
local spin = 0
local conns = {}
local warned = false
local refreshUI = function() end

local JOINT_KEYS = {
	Root = "root",
	RootJoint = "root",
	Waist = "waist",
	Neck = "neck",
	RightShoulder = "rs",
	["Right Shoulder"] = "rs",
	LeftShoulder = "ls",
	["Left Shoulder"] = "ls",
	RightElbow = "re",
	LeftElbow = "le",
}

local function rotAt(base, rx, ry, rz)
	return CFrame.new(base.Position) * CFrame.Angles(rx, ry, rz) * (base - base.Position)
end

local function pivotRot(base, pivot, rx, ry, rz)
	return CFrame.new(pivot) * CFrame.Angles(rx, ry, rz) * CFrame.new(-pivot) * base
end

local function yawOf(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function collect(char)
	local newRig = {joints = {}, bases = {}, char = char, rest = false}
	newRig.hum = char:FindFirstChildOfClass("Humanoid")
	newRig.hrp = char:FindFirstChild("HumanoidRootPart")
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") then
			local key = JOINT_KEYS[d.Name]
			if key and not newRig.joints[key] and (key ~= "root" or d.Part0 == newRig.hrp) then
				newRig.joints[key] = d
				newRig.bases[key] = d.C0
			end
		end
	end
	rig = newRig
end

local function restoreRig()
	for key, m in pairs(rig.joints) do
		local b = rig.bases[key]
		if m and m.Parent and b then
			m.C0 = b
		end
	end
end

local function safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok and not warned then
		warned = true
		warn("Huy Premium loi: " .. tostring(err))
	end
end
local CAPE_SEGS = 8
local CAPE_H = 0.4

local function destroyCape()
	if capeData and capeData.folder then
		pcall(function()
			capeData.folder:Destroy()
		end)
	end
	capeData = nil
end

local function newPart(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(a, b, c0)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = b
	w.C0 = c0
	w.Parent = b
	return w
end

local function buildCape(char)
	destroyCape()
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not (torso and torso:IsA("BasePart")) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "HuyCape"
	folder.Parent = char

	local crimson = Color3.fromRGB(150, 10, 48)
	local deep = Color3.fromRGB(86, 6, 34)
	local gold = Color3.fromRGB(255, 205, 90)
	local tw = torso.Size.X

	local mantle = newPart("Mantle", V3(tw + 0.7, 0.42, 0.62), deep, Enum.Material.Fabric, folder)
	weld(torso, mantle, CFrame.new(0, torso.Size.Y / 2 - 0.02, torso.Size.Z / 2 + 0.12))
	local mantleTrim = newPart("MantleTrim", V3(tw + 0.74, 0.08, 0.66), gold, Enum.Material.Metal, folder)
	weld(mantle, mantleTrim, CFrame.new(0, 0.21, 0))

	local segs = {}
	local parts = {}
	local prev = torso
	local lastWidth = 2
	for i = 1, CAPE_SEGS do
		local width = 1.9 + (i - 1) * 0.14
		local t = (i - 1) / (CAPE_SEGS - 1)
		local p = newPart("Cape" .. i, V3(width, CAPE_H, 0.1), crimson:Lerp(deep, t), Enum.Material.Fabric, folder)
		local m = Instance.new("Motor6D")
		m.Name = "CapeJoint" .. i
		m.Part0 = prev
		if i == 1 then
			m.C0 = CFrame.new(0, torso.Size.Y / 2 - 0.12, torso.Size.Z / 2 + 0.14)
		else
			m.C0 = CFrame.new(0, -CAPE_H / 2, 0.012)
		end
		m.C1 = CFrame.new(0, CAPE_H / 2, 0)
		m.Part1 = p
		m.Parent = p
		for _, side in ipairs({-1, 1}) do
			local trim = newPart("Trim", V3(0.07, CAPE_H, 0.13), gold, Enum.Material.Metal, folder)
			weld(p, trim, CFrame.new(side * width / 2, 0, 0))
		end
		segs[i] = {motor = m, base = m.C0, p = 0, pv = 0, r = 0, rv = 0}
		parts[i] = p
		lastWidth = width
		prev = p
	end

	local patch = newPart("Patch", V3(1.3, 0.78, 0.05), Color3.fromRGB(34, 4, 16), Enum.Material.SmoothPlastic, folder)
	weld(parts[3], patch, CFrame.new(0, -CAPE_H / 2, 0.075))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 100
	sg.LightInfluence = 0
	sg.Parent = patch
	local border = Instance.new("Frame")
	border.BackgroundTransparency = 1
	border.Size = UDim2.fromScale(1, 1)
	border.Parent = sg
	local bs = Instance.new("UIStroke")
	bs.Color = gold
	bs.Thickness = 3
	bs.Parent = border
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.fromScale(1, 1)
	tl.Text = "HUY"
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = gold
	tl.Parent = border
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = tl

	local hem = newPart("Hem", V3(lastWidth, 0.12, 0.15), gold, Enum.Material.Metal, folder)
	weld(parts[CAPE_SEGS], hem, CFrame.new(0, -CAPE_H / 2 - 0.04, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(0.5, 1.6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.28, 0)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 225, 130))
	pe.Parent = hem

	capeData = {
		folder = folder,
		segs = segs,
		emitter = pe,
		yaw = rig.hrp and yawOf(rig.hrp.CFrame) or 0,
		turn = 0,
	}
end

local function animateCape(dt)
	if not capeData then
		return
	end
	local hrp = rig.hrp
	if not (hrp and hrp.Parent) then
		return
	end
	local vel = hrp.AssemblyLinearVelocity
	local cf = hrp.CFrame
	local fwd = math.clamp(vel:Dot(cf.LookVector) / 20, -1, 1.3)
	local side = math.clamp(vel:Dot(cf.RightVector) / 20, -1, 1)
	local vy = vel.Y
	local fall = math.clamp(-vy / 45, 0, 1)
	local rise = math.clamp(vy / 55, 0, 1)
	local yaw = yawOf(cf)
	local dyaw = (yaw - capeData.yaw + math.pi) % TAU - math.pi
	capeData.yaw = yaw
	local turnRaw = math.clamp(dyaw / math.max(dt, 1 / 240), -6, 6)
	capeData.turn = capeData.turn + (turnRaw - capeData.turn) * math.min(1, dt * 8)
	local sp = math.max(fwd, 0)
	local step = math.clamp(dt, 0, 1 / 20)
	for i, seg in ipairs(capeData.segs) do
		local k = 190 - i * 12
		local c = 2 * math.sqrt(k) * 0.45
		local wind = -(rad(1.6) + rad(4.2) * sp + rad(4.5) * fall) + rad(1) * rise + rad(1.5) * math.max(-fwd, 0)
		local ripple = math.sin(clock * 8.5 - i * 0.9) * (rad(0.8) + rad(2.2) * sp + rad(2) * fall)
		local idle = math.sin(clock * 1.7 - i * 0.55) * rad(1.2)
		local pt = wind + ripple + idle
		local rt = -side * rad(5) * (0.5 + i * 0.12) + capeData.turn * rad(0.5) * (0.4 + i * 0.1) + math.sin(clock * 3.1 - i * 0.7) * rad(1 + 2 * sp)
		seg.pv = seg.pv + ((pt - seg.p) * k - seg.pv * c) * step
		seg.p = math.clamp(seg.p + seg.pv * step, -rad(24), rad(2.5))
		seg.rv = seg.rv + ((rt - seg.r) * k - seg.rv * c) * step
		seg.r = math.clamp(seg.r + seg.rv * step, -rad(18), rad(18))
		seg.motor.C0 = seg.base * CFrame.Angles(seg.p, 0, seg.r)
	end
	capeData.emitter.Rate = math.floor(sp * 26 + fall * 20)
end
local builders = {}
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local STAR_TEX = "rbxasset://textures/particles/sparkles_main.dds"

local function track(inst)
	if fx then
		fx.objs[#fx.objs + 1] = inst
	end
	return inst
end

local function destroyFx()
	if fx then
		for _, o in ipairs(fx.objs) do
			pcall(function()
				o:Destroy()
			end)
		end
	end
	fx = nil
end

local function seq(...)
	local cs = {...}
	local k = {}
	for i, c in ipairs(cs) do
		k[i] = ColorSequenceKeypoint.new((i - 1) / math.max(#cs - 1, 1), c)
	end
	return ColorSequence.new(k)
end

local function findPart(char, names)
	for _, n in ipairs(names) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

local function ghostOn(base, offset, parent)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.CFrame = base.CFrame * CFrame.new(offset)
	p.Parent = parent
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	return p
end

local function attach(part, offset)
	local a = Instance.new("Attachment")
	a.Position = offset or Vector3.new(0, 0, 0)
	a.Parent = part
	track(a)
	return a
end

local function trail(part, c0, c1, life, w, p0, p1)
	local t = Instance.new("Trail")
	t.Attachment0 = attach(part, p0 or Vector3.new(0, 0.5, 0))
	t.Attachment1 = attach(part, p1 or Vector3.new(0, -0.5, 0))
	t.Color = ColorSequence.new(c0, c1)
	t.Transparency = NumberSequence.new(0.05, 1)
	t.Lifetime = life or 0.6
	t.LightEmission = 1
	t.LightInfluence = 0
	t.WidthScale = NumberSequence.new(w or 1, 0)
	t.MinLength = 0.02
	t.FaceCamera = true
	t.Enabled = false
	t.Parent = part
	fx.trails[#fx.trails + 1] = t
	track(t)
	return t
end

local function emitter(part, o)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = o.tex or STAR_TEX
	pe.Color = o.color
	pe.LightEmission = 1
	pe.LightInfluence = 0
	pe.Rate = o.rate or 20
	pe.Lifetime = NumberRange.new(o.l0 or 0.5, o.l1 or 1)
	pe.Speed = NumberRange.new(o.s0 or 1, o.s1 or 3)
	pe.SpreadAngle = o.spread or Vector2.new(180, 180)
	pe.Size = o.size or NumberSequence.new(0.4, 0)
	pe.Transparency = NumberSequence.new(0, 1)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-120, 120)
	pe.Acceleration = o.acc or Vector3.new(0, 0, 0)
	if o.sphere then
		pe.Shape = Enum.ParticleEmitterShape.Sphere
		pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	end
	pe.Enabled = false
	pe.Parent = part
	fx.emitters[#fx.emitters + 1] = pe
	track(pe)
	return pe
end

local function light(part, color, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 0
	l.Shadows = false
	l.Parent = part
	track(l)
	return l
end

local function beam(a0, a1, parent, c0, c1)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = seq(c0, c1)
	b.LightEmission = 1
	b.LightInfluence = 0
	b.FaceCamera = true
	b.Segments = 16
	b.Width0 = 0.4
	b.Width1 = 0.1
	b.Enabled = false
	b.Parent = parent
	track(b)
	return b
end

builders.void = function(char, folder)
	local head = char:FindFirstChild("Head")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	local hand = findPart(char, {"RightHand", "Right Arm"})
	if not (head and torso) then
		return
	end
	local purple = Color3.fromRGB(170, 60, 255)
	local pink = Color3.fromRGB(255, 110, 200)
	local orange = Color3.fromRGB(255, 140, 40)
	local white = Color3.fromRGB(255, 255, 255)

	local p = ghostOn(head, Vector3.new(0, 2.0, 0), folder)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(3.6, 3.6)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Adornee = p
	bb.Parent = p

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(0, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = bb

	local function circle(scale, bg, bgT)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(scale, scale)
		f.BackgroundColor3 = bg
		f.BackgroundTransparency = bgT
		f.BorderSizePixel = 0
		f.Parent = holder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		return f
	end

	local function ringStroke(f, th, ...)
		local s = Instance.new("UIStroke")
		s.Thickness = th
		s.Color = white
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = f
		local g = Instance.new("UIGradient")
		g.Color = seq(...)
		g.Parent = s
		return g
	end

	local glow = circle(1.35, purple, 0.6)
	local core = circle(0.8, Color3.new(0, 0, 0), 0)
	local g1 = ringStroke(core, 6, purple, white, purple, pink, purple)
	local ring2 = circle(1.02, Color3.new(0, 0, 0), 1)
	local g2 = ringStroke(ring2, 2, pink, purple, pink)

	local function sigil()
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(0.34, 0.34)
		f.BackgroundTransparency = 1
		f.Parent = holder
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = purple
		s.Parent = f
		return f
	end
	local sg1 = sigil()
	local sg2 = sigil()

	local lt = light(p, purple, 14)
	emitter(p, {color = seq(purple, pink), rate = 40, s0 = 4, s1 = 8, spread = Vector2.new(6, 6), l0 = 0.6, l1 = 1.1, size = NumberSequence.new(0.55, 0), acc = Vector3.new(0, 5, 0)})
	emitter(p, {color = seq(white, purple), rate = 25, s0 = 1, s1 = 3, l0 = 0.5, l1 = 0.9, size = NumberSequence.new(0.3, 0)})

	trail(torso, purple, pink, 0.9, 1.5, Vector3.new(0, 0.9, 0.6), Vector3.new(0, -0.4, 0.6))
	if hand then
		trail(hand, orange, pink, 0.7, 1.2, Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0))
	end

	fx.update = function(dt, a)
		holder.Size = UDim2.fromScale(a, a)
		g1.Rotation = (clock * 220) % 360
		g2.Rotation = (-clock * 140) % 360
		sg1.Rotation = (clock * 70) % 360
		sg2.Rotation = (-clock * 70) % 360
		glow.BackgroundTransparency = 0.6 + math.sin(clock * 6) * 0.12
		lt.Brightness = 3 * a
	end
end

builders.phoenix = function(char, folder)
	local torso = findPart(char, {"UpperTorso", "Torso"})
	if not torso then
		return
	end
	local fire = seq(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 130, 20), Color3.fromRGB(180, 20, 10))
	local hands = {
		findPart(char, {"RightHand", "Right Arm"}),
		findPart(char, {"LeftHand", "Left Arm"}),
	}
	local uppers = {
		findPart(char, {"RightUpperArm", "Right Arm"}),
		findPart(char, {"LeftUpperArm", "Left Arm"}),
	}
	local seen = {}
	for _, h in ipairs(hands) do
		if h and not seen[h] then
			seen[h] = true
			trail(h, Color3.fromRGB(255, 210, 90), Color3.fromRGB(200, 30, 10), 0.8, 1.6)
			emitter(h, {tex = FIRE_TEX, color = fire, rate = 40, s0 = 1, s1 = 3, l0 = 0.4, l1 = 0.8, size = NumberSequence.new(1.3, 0), acc = Vector3.new(0, 6, 0)})
		end
	end
	for _, u in ipairs(uppers) do
		if u and not seen[u] then
			seen[u] = true
			emitter(u, {tex = FIRE_TEX, color = fire, rate = 30, s0 = 1, s1 = 3, l0 = 0.4, l1 = 0.8, size = NumberSequence.new(1.5, 0), acc = Vector3.new(0, 6, 0)})
		end
	end
	emitter(torso, {color = seq(Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 90, 20)), rate = 25, s0 = 2, s1 = 5, l0 = 0.6, l1 = 1.2, size = NumberSequence.new(0.35, 0), acc = Vector3.new(0, 4, 0)})
	local lt = light(torso, Color3.fromRGB(255, 140, 40), 16)
	fx.update = function(dt, a)
		lt.Brightness = (2.5 + math.sin(clock * 18) * 0.8) * a
	end
end
builders.galaxy = function(char, folder)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	if not (hrp and torso) then
		return
	end
	local orbs = {}
	for i = 1, 8 do
		local o = Instance.new("Part")
		o.Shape = Enum.PartType.Ball
		o.Size = Vector3.new(0.5, 0.5, 0.5)
		o.Material = Enum.Material.Neon
		o.Anchored = true
		o.CanCollide = false
		o.CanTouch = false
		o.CanQuery = false
		o.CastShadow = false
		o.Transparency = 1
		o.CFrame = hrp.CFrame
		o.Parent = folder
		local t = trail(o, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0.8, 1, Vector3.new(0, 0.25, 0), Vector3.new(0, -0.25, 0))
		orbs[i] = {part = o, trail = t}
	end
	emitter(torso, {color = seq(Color3.fromRGB(120, 220, 255), Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 120, 220)), rate = 45, s0 = 0.5, s1 = 2, l0 = 1, l1 = 1.6, size = NumberSequence.new(0.4, 0), sphere = true})
	local lt = light(torso, Color3.new(1, 1, 1), 16)
	fx.update = function(dt, a)
		local base = hrp.Position + Vector3.new(0, 0.4, 0)
		for i, d in ipairs(orbs) do
			local outer = i % 2 == 0
			local ang = clock * (outer and -2.4 or 3.4) + i * 0.8
			local r = outer and 4 or 3
			local tilt = outer and math.rad(55) or math.rad(-25)
			local cf = CFrame.new(base) * CFrame.Angles(0, 0, tilt) * CFrame.new(math.cos(ang) * r, 0, math.sin(ang) * r)
			d.part.Position = cf.Position
			local h = (clock * 0.2 + i / 8) % 1
			local c1 = Color3.fromHSV(h, 0.75, 1)
			d.part.Color = c1
			d.part.Transparency = 1 - a
			d.trail.Color = ColorSequence.new(c1, Color3.fromHSV((h + 0.18) % 1, 0.9, 1))
		end
		lt.Color = Color3.fromHSV((clock * 0.2) % 1, 0.7, 1)
		lt.Brightness = 2.5 * a
	end
end

builders.thunder = function(char, folder)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	local rh = findPart(char, {"RightHand", "Right Arm"})
	local lh = findPart(char, {"LeftHand", "Left Arm"})
	if not (hrp and torso and rh and lh) then
		return
	end
	local cyan = Color3.fromRGB(110, 200, 255)
	local white = Color3.fromRGB(240, 252, 255)
	local blue = Color3.fromRGB(50, 120, 255)

	local sky = ghostOn(hrp, Vector3.new(0.5, 10, 0), folder)
	local gnd = ghostOn(hrp, Vector3.new(-3, -2.5, 0), folder)
	local aSky = attach(sky, Vector3.new(0, 0, 0))
	local aGnd = attach(gnd, Vector3.new(0, 0, 0))
	local aR = attach(rh, Vector3.new(0, -0.2, 0))
	local aL = attach(lh, Vector3.new(0, -0.2, 0))

	local beams = {
		beam(aR, aSky, sky, white, cyan),
		beam(aR, aSky, sky, cyan, blue),
		beam(aR, aSky, sky, white, blue),
		beam(aL, aGnd, gnd, white, cyan),
		beam(aL, aGnd, gnd, cyan, blue),
	}

	emitter(torso, {color = seq(white, cyan, blue), rate = 40, s0 = 6, s1 = 12, l0 = 0.25, l1 = 0.5, size = NumberSequence.new(0.35, 0)})
	emitter(rh, {color = seq(white, cyan), rate = 30, s0 = 4, s1 = 9, l0 = 0.2, l1 = 0.45, size = NumberSequence.new(0.4, 0)})
	trail(torso, cyan, blue, 0.5, 1.2, Vector3.new(0, 0.9, 0.6), Vector3.new(0, -0.4, 0.6))
	local lt = light(torso, cyan, 18)

	local acc = 0
	fx.update = function(dt, a)
		local on = a > 0.25
		acc = acc + dt
		if acc >= 0.05 then
			acc = 0
			for _, b in ipairs(beams) do
				b.CurveSize0 = (math.random() - 0.5) * 9
				b.CurveSize1 = (math.random() - 0.5) * 9
				b.Width0 = 0.2 + math.random() * 0.45
				b.Enabled = on and math.random() > 0.15
			end
		end
		lt.Brightness = on and (math.random() * 6) or 0
	end
end

local function buildFx(mode)
	destroyFx()
	local char = rig.char
	if not (mode and char and builders[mode]) then
		return
	end
	fx = {objs = {}, emitters = {}, trails = {}, on = nil, update = nil}
	local folder = Instance.new("Folder")
	folder.Name = "HuyFx"
	folder.Parent = char
	track(folder)
	local ok, err = pcall(builders[mode], char, folder)
	if not ok then
		warn("Huy FX loi: " .. tostring(err))
	end
end

local function animateFx(dt)
	if not fx then
		return
	end
	local on = alpha > 0.25
	if fx.on ~= on then
		fx.on = on
		for _, e in ipairs(fx.emitters) do
			e.Enabled = on
		end
		for _, t in ipairs(fx.trails) do
			t.Enabled = on
		end
	end
	if fx.update then
		fx.update(dt, alpha)
	end
end
local emotes = {}
local KEYS = {"off", "root", "waist", "neck", "rs", "ls", "re", "le"}
local smooth = {}

local function elbow(d)
	return V3(rad(d), 0, 0)
end

local function resetSmooth()
	for _, k in ipairs(KEYS) do
		smooth[k] = ZERO
	end
end

resetSmooth()

emotes.shake = function(p)
	local s = math.sin(p * 6)
	local c = math.cos(p * 6)
	return {
		off = V3(s * 0.4, math.abs(c) * 0.08, 0),
		root = V3(rad(-4), rad(14) * s, rad(-5) * s),
		waist = V3(0, -rad(11) * s, rad(6) * s),
		neck = V3(0, -rad(10) * s, -rad(4) * s),
		rs = V3(rad(34) * c, 0, rad(14)),
		ls = V3(-rad(34) * c, 0, -rad(14)),
		re = elbow(32 + 14 * s),
		le = elbow(32 - 14 * s),
	}
end

emotes.tilt = function(p)
	local s = math.sin(p * 3.6)
	local c = math.cos(p * 3.6)
	return {
		off = V3(s * 0.22, 0, 0),
		root = V3(0, rad(4) * c, rad(17) * s),
		waist = V3(0, 0, -rad(9) * s),
		neck = V3(0, rad(6) * c, -rad(8) * s),
		rs = V3(0, 0, rad(18 + 16 * s)),
		ls = V3(0, 0, -rad(18 - 16 * s)),
		re = elbow(14),
		le = elbow(14),
	}
end

emotes.ninja = function(p)
	local s = math.sin(p * 10)
	local c = math.cos(p * 10)
	local w = math.sin(p * 5)
	return {
		off = V3(0, math.abs(s) * 0.07 - 0.05, 0),
		root = V3(-rad(44), rad(5) * w, rad(3) * c),
		waist = V3(-rad(6), -rad(4) * w, 0),
		neck = V3(rad(40), 0, 0),
		rs = V3(-rad(78 + 6 * s), 0, rad(7)),
		ls = V3(-rad(78 - 6 * s), 0, -rad(7)),
		re = elbow(10),
		le = elbow(10),
	}
end

emotes.emote = function(p)
	local s = math.sin(p * 8)
	local c = math.cos(p * 8)
	local m = math.sin(p * 4)
	local u = 0.5 + 0.5 * m
	local v = 1 - u
	return {
		off = V3(m * 0.22, math.abs(s) * 0.26, 0),
		root = V3(-rad(5), rad(20) * m, rad(7) * s),
		waist = V3(rad(4) * math.abs(c), -rad(16) * m, -rad(5) * s),
		neck = V3(rad(6) * math.abs(s), rad(14) * m, rad(6) * c),
		rs = V3(rad(35 + 125 * u), 0, rad(10 + 26 * u)),
		ls = V3(rad(35 + 125 * v), 0, -rad(10 + 26 * v)),
		re = elbow(52 - 38 * u + 10 * s),
		le = elbow(52 - 38 * v - 10 * s),
	}
end

emotes.void = function(p)
	local s = math.sin(p * 3)
	local c = math.cos(p * 3)
	return {
		off = V3(0, 0.16 + 0.12 * s, 0),
		root = V3(-rad(30), rad(7) * s, rad(3) * c),
		waist = V3(-rad(6), 0, 0),
		neck = V3(rad(20), rad(8) * s, 0),
		rs = V3(rad(78 + 8 * s), 0, rad(8)),
		ls = V3(-rad(64 + 10 * c), 0, -rad(10)),
		re = elbow(22),
		le = elbow(14),
	}
end

emotes.phoenix = function(p)
	local f = math.sin(p * 7)
	local g = math.sin(p * 7 - 0.9)
	return {
		off = V3(0, 0.55 + 0.32 * f, 0),
		root = V3(-rad(12), 0, rad(4) * math.sin(p * 3.5)),
		waist = V3(rad(4) * f, 0, 0),
		neck = V3(rad(14), 0, 0),
		rs = V3(-rad(6), 0, rad(62 + 46 * f)),
		ls = V3(-rad(6), 0, -rad(62 + 46 * f)),
		re = elbow(14 + 14 * g),
		le = elbow(14 + 14 * g),
	}
end

emotes.galaxy = function(p)
	local s = math.sin(p * 4)
	local w = math.sin(p * 3)
	return {
		off = V3(0, 0.34 + 0.2 * s, 0),
		root = V3(-rad(7), 0, 0),
		waist = V3(0, 0, 0),
		neck = V3(rad(12), 0, 0),
		rs = V3(0, 0, rad(86 + 6 * w)),
		ls = V3(0, 0, -rad(86 + 6 * w)),
		re = elbow(8),
		le = elbow(8),
	}
end

emotes.thunder = function(p)
	local s = math.sin(p * 12)
	local tr = math.sin(p * 31) * 0.5 + math.sin(p * 47) * 0.5
	return {
		off = V3(tr * 0.05, math.abs(s) * 0.1, 0),
		root = V3(-rad(18), rad(9) * s, rad(5) * math.sin(p * 6)),
		waist = V3(-rad(5), -rad(6) * s, 0),
		neck = V3(rad(26), rad(6) * tr, 0),
		rs = V3(rad(166 + 5 * tr), 0, rad(8)),
		ls = V3(-rad(52 + 16 * s), 0, -rad(14)),
		re = elbow(8),
		le = elbow(20 + 10 * s),
	}
end

local function setJoint(key, v)
	local m = rig.joints[key]
	local base = rig.bases[key]
	if m and m.Parent and base then
		m.C0 = rotAt(base, v.X, v.Y, v.Z)
	end
end

local function applyMotion(dt)
	local hum, hrp, b = rig.hum, rig.hrp, rig.bases
	local rootJoint = rig.joints.root
	if not (hum and hrp and hrp.Parent and rootJoint and rootJoint.Parent and b.root and hum.Health > 0) then
		return
	end
	local mode = state.mode
	local moving = hum.MoveDirection.Magnitude > 0.1 and not hum.Sit
	local target = (mode ~= nil and moving) and 1 or 0
	alpha = alpha + (target - alpha) * (1 - math.exp(-dt * 7))
	if alpha < 0.001 then
		alpha = 0
	elseif alpha > 0.999 then
		alpha = 1
	end
	local vel = hrp.AssemblyLinearVelocity
	local hv = V3(vel.X, 0, vel.Z).Magnitude
	local ratio = math.clamp(hv / math.max(hum.WalkSpeed, 1), 0.6, 1.4)
	phase = phase + dt * ratio * settings.speed
	local ease = alpha * alpha * (3 - 2 * alpha)
	local fn = emotes[mode]
	local pz = fn and fn(phase) or nil
	local k = 1 - math.exp(-dt * 16)
	local energy = 0
	for _, key in ipairs(KEYS) do
		local tv = ZERO
		if pz and pz[key] then
			tv = pz[key] * ease
		end
		local cv = smooth[key]:Lerp(tv, k)
		smooth[key] = cv
		energy = energy + cv.Magnitude
	end
	if mode == "galaxy" and moving then
		spin = (spin + dt * 9 * alpha) % TAU
	else
		local goal = spin > math.pi and TAU or 0
		spin = spin + (goal - spin) * (1 - math.exp(-dt * 6))
		if math.abs(goal - spin) < 0.003 then
			spin = 0
		end
	end
	if target == 0 and energy < 0.004 and spin == 0 then
		if not rig.rest then
			restoreRig()
			resetSmooth()
			rig.rest = true
		end
		return
	end
	rig.rest = false
	local feet = hum.RigType == Enum.HumanoidRigType.R15 and (hum.HipHeight + hrp.Size.Y / 2) or 3
	local pivot = b.root.Position + V3(0, -feet, 0)
	local ro = smooth.root
	rootJoint.C0 = CFrame.new(smooth.off) * pivotRot(b.root, pivot, ro.X, ro.Y + spin, ro.Z)
	setJoint("waist", smooth.waist)
	setJoint("neck", smooth.neck)
	setJoint("rs", smooth.rs)
	setJoint("ls", smooth.ls)
	setJoint("re", smooth.re)
	setJoint("le", smooth.le)
end

local function setMode(name, on)
	state.mode = on and name or nil
	buildFx(state.mode)
	refreshUI()
end

local function setCape(on)
	state.cape = on
	if on and rig.char then
		buildCape(rig.char)
	else
		destroyCape()
	end
	refreshUI()
end

local function onChar(char)
	alpha = 0
	spin = 0
	resetSmooth()
	destroyFx()
	capeData = nil
	rig = {joints = {}, bases = {}}
	local hum = char:WaitForChild("Humanoid", 10)
	char:WaitForChild("HumanoidRootPart", 10)
	if not hum then
		return
	end
	if hum.RigType == Enum.HumanoidRigType.R15 then
		char:WaitForChild("UpperTorso", 10)
		char:WaitForChild("LowerTorso", 10)
		char:WaitForChild("RightUpperArm", 10)
		char:WaitForChild("LeftUpperArm", 10)
		char:WaitForChild("RightLowerArm", 10)
		char:WaitForChild("LeftLowerArm", 10)
	else
		char:WaitForChild("Torso", 10)
		char:WaitForChild("Right Arm", 10)
		char:WaitForChild("Left Arm", 10)
	end
	task.wait(0.3)
	if player.Character ~= char or not char.Parent then
		return
	end
	collect(char)
	if state.mode then
		buildFx(state.mode)
	end
	if state.cape then
		buildCape(char)
	end
end

conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
	clock = clock + dt
	safe(applyMotion, dt)
	safe(animateCape, dt)
	safe(animateFx, dt)
end)

conns[#conns + 1] = player.CharacterAdded:Connect(onChar)
if player.Character then
	task.spawn(onChar, player.Character)
end
local GOLD = Color3.fromRGB(255, 205, 90)
local GOLD2 = Color3.fromRGB(255, 150, 50)
local BG1 = Color3.fromRGB(36, 24, 66)
local BG2 = Color3.fromRGB(8, 10, 22)
local PANEL = Color3.fromRGB(30, 34, 58)
local ACTIVE = Color3.fromRGB(62, 48, 42)
local OFF = Color3.fromRGB(70, 74, 100)
local TEXT = Color3.fromRGB(242, 242, 252)
local SUB = Color3.fromRGB(150, 156, 184)

local pg = player:WaitForChild("PlayerGui")
for _, n in ipairs({"HuyPremiumV1", "HuyPremiumV2"}) do
	local o = pg:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "HuyPremiumV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function stroke(parent, color, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = th
	s.Transparency = tr
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot or 0
	g.Parent = parent
	return g
end

local function label(parent, text, font, size, color, pos, sz, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Position = pos
	l.Size = sz
	l.Parent = parent
	return l
end

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.new(0.92, 0, 0.86, 0)
main.BackgroundColor3 = Color3.new(1, 1, 1)
main.BackgroundTransparency = 0.06
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 18)
gradient(main, BG1, BG2, 90)

local sizeC = Instance.new("UISizeConstraint")
sizeC.MinSize = Vector2.new(250, 220)
sizeC.MaxSize = Vector2.new(340, 500)
sizeC.Parent = main

local mainScale = Instance.new("UIScale")
mainScale.Scale = 0.86
mainScale.Parent = main

local mainStroke = stroke(main, Color3.new(1, 1, 1), 2, 0)
local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, GOLD),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(120, 70, 200)),
	ColorSequenceKeypoint.new(0.65, GOLD2),
	ColorSequenceKeypoint.new(1, GOLD),
})
strokeGrad.Parent = mainStroke

local glowTop = Instance.new("Frame")
glowTop.Size = UDim2.new(1, 0, 0, 100)
glowTop.BackgroundColor3 = GOLD
glowTop.BorderSizePixel = 0
glowTop.Parent = main
corner(glowTop, 18)
local glowGrad = Instance.new("UIGradient")
glowGrad.Rotation = 90
glowGrad.Transparency = NumberSequence.new(0.84, 1)
glowGrad.Parent = glowTop

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = main

local logo = Instance.new("Frame")
logo.Position = UDim2.fromOffset(12, 10)
logo.Size = UDim2.fromOffset(36, 36)
logo.BackgroundColor3 = Color3.new(1, 1, 1)
logo.BorderSizePixel = 0
logo.Parent = header
corner(logo, 18)
gradient(logo, GOLD, GOLD2, 45)
label(logo, "H", Enum.Font.GothamBlack, 20, BG2, UDim2.new(), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)

local title = label(header, "HUY PREMIUM", Enum.Font.GothamBlack, 18, Color3.new(1, 1, 1), UDim2.fromOffset(58, 8), UDim2.new(1, -150, 0, 22))
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 205)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 60)),
})
titleGrad.Parent = title
label(header, "Hành động khi di chuyển", Enum.Font.Gotham, 11, SUB, UDim2.fromOffset(58, 31), UDim2.new(1, -150, 0, 16))

local function headerButton(name, text, xOffset)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, xOffset, 0.5, 0)
	btn.Size = UDim2.fromOffset(30, 30)
	btn.BackgroundColor3 = PANEL
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = GOLD
	btn.AutoButtonColor = false
	btn.Parent = header
	corner(btn, 10)
	stroke(btn, GOLD, 1, 0.55)
	return btn
end

local closeBtn = headerButton("Close", "X", -10)
local minBtn = headerButton("Min", "—", -46)

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(12, 56)
divider.Size = UDim2.new(1, -24, 0, 1)
divider.BackgroundColor3 = GOLD
divider.BackgroundTransparency = 0.65
divider.BorderSizePixel = 0
divider.Parent = main

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Position = UDim2.fromOffset(10, 62)
list.Size = UDim2.new(1, -20, 1, -154)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = GOLD
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 2)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.Parent = list

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 90)
footer.BackgroundTransparency = 1
footer.Parent = main

local footLine = Instance.new("Frame")
footLine.Position = UDim2.fromOffset(12, 0)
footLine.Size = UDim2.new(1, -24, 0, 1)
footLine.BackgroundColor3 = GOLD
footLine.BackgroundTransparency = 0.75
footLine.BorderSizePixel = 0
footLine.Parent = footer

label(footer, "Tốc độ động tác", Enum.Font.GothamMedium, 12, TEXT, UDim2.fromOffset(16, 8), UDim2.new(0.6, 0, 0, 16))
local speedValue = label(footer, "100%", Enum.Font.GothamBold, 12, GOLD, UDim2.new(0.6, 0, 0, 8), UDim2.new(0.4, -16, 0, 16), Enum.TextXAlignment.Right)

local hit = Instance.new("TextButton")
hit.Position = UDim2.fromOffset(12, 28)
hit.Size = UDim2.new(1, -24, 0, 26)
hit.BackgroundTransparency = 1
hit.Text = ""
hit.AutoButtonColor = false
hit.Parent = footer

local bar = Instance.new("Frame")
bar.Position = UDim2.fromOffset(0, 9)
bar.Size = UDim2.new(1, 0, 0, 8)
bar.BackgroundColor3 = OFF
bar.BorderSizePixel = 0
bar.Parent = hit
corner(bar, 4)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0.5, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.Parent = bar
corner(fill, 4)
gradient(fill, GOLD2, GOLD, 0)

local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.fromScale(0.5, 0.5)
knob.Size = UDim2.fromOffset(18, 18)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.BorderSizePixel = 0
knob.Parent = bar
corner(knob, 9)
stroke(knob, GOLD, 2, 0)

local status = label(footer, "", Enum.Font.Gotham, 11, SUB, UDim2.fromOffset(16, 62), UDim2.new(1, -32, 0, 20))

local bubble = Instance.new("TextButton")
bubble.Name = "Bubble"
bubble.Size = UDim2.fromOffset(56, 56)
bubble.Position = UDim2.fromOffset(40, 120)
bubble.BackgroundColor3 = BG2
bubble.BackgroundTransparency = 0.08
bubble.Text = "H"
bubble.Font = Enum.Font.GothamBlack
bubble.TextSize = 28
bubble.TextColor3 = GOLD
bubble.AutoButtonColor = false
bubble.Visible = false
bubble.Parent = gui
corner(bubble, 28)
local bubbleStroke = stroke(bubble, Color3.new(1, 1, 1), 2.5, 0)
local bubbleGrad = Instance.new("UIGradient")
bubbleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, GOLD),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 80, 220)),
	ColorSequenceKeypoint.new(1, GOLD),
})
bubbleGrad.Parent = bubbleStroke
local items = {
	shake = {name = "Lắc Qua Lắc Lại", desc = "Lắc hông, vung tay nhịp nhàng"},
	tilt = {name = "Nghiêng Qua Nghiêng Lại", desc = "Đung đưa êm, đầu luôn thẳng"},
	ninja = {name = "Chạy Ninja", desc = "Cúi người, hai tay vuốt sau"},
	emote = {name = "Vũ Điệu Huy", desc = "Nhảy nhót, hai tay đổi nhịp"},
	void = {name = "Hố Đen Tím", desc = "Vầng hắc quang, lướt như gió"},
	phoenix = {name = "Phượng Hoàng Lửa", desc = "Sải cánh lửa, bay bổng"},
	galaxy = {name = "Thiên Hà Xoay", desc = "Xoay tròn, 8 vệ tinh bay quanh"},
	thunder = {name = "Thần Sấm", desc = "Gọi sét xanh, người giật điện"},
	cape = {name = "Áo Choàng Huy", desc = "Bay theo gió khi chạy, nhảy"},
}

local sections = {
	{name = "ĐỘNG TÁC KHI DI CHUYỂN", ids = {"shake", "tilt", "ninja", "emote"}},
	{name = "HIỆU ỨNG ĐẶC BIỆT", ids = {"void", "phoenix", "galaxy", "thunder"}},
	{name = "TRANG BỊ", ids = {"cape"}},
}

local rows = {}
local rowOrder = {}

local function makeRow(id, index, order)
	local item = items[id]
	local row = Instance.new("TextButton")
	row.Name = id
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -4, 0, 56)
	row.BackgroundColor3 = PANEL
	row.BackgroundTransparency = 0.25
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = list
	corner(row, 12)
	local rowStroke = stroke(row, OFF, 1, 0.45)
	local scale = Instance.new("UIScale")
	scale.Parent = row

	local badge = Instance.new("Frame")
	badge.Position = UDim2.fromOffset(10, 11)
	badge.Size = UDim2.fromOffset(34, 34)
	badge.BackgroundColor3 = OFF
	badge.BorderSizePixel = 0
	badge.Parent = row
	corner(badge, 10)
	local badgeText = label(badge, tostring(index), Enum.Font.GothamBlack, 16, TEXT, UDim2.new(), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)

	label(row, item.name, Enum.Font.GothamBold, 13, TEXT, UDim2.fromOffset(54, 9), UDim2.new(1, -118, 0, 20))
	label(row, item.desc, Enum.Font.Gotham, 11, SUB, UDim2.fromOffset(54, 30), UDim2.new(1, -118, 0, 16))

	local sw = Instance.new("Frame")
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -12, 0.5, 0)
	sw.Size = UDim2.fromOffset(46, 24)
	sw.BackgroundColor3 = OFF
	sw.BorderSizePixel = 0
	sw.Parent = row
	corner(sw, 12)

	local sk = Instance.new("Frame")
	sk.AnchorPoint = Vector2.new(0, 0.5)
	sk.Position = UDim2.new(0, 3, 0.5, 0)
	sk.Size = UDim2.fromOffset(18, 18)
	sk.BackgroundColor3 = Color3.new(1, 1, 1)
	sk.BorderSizePixel = 0
	sk.Parent = sw
	corner(sk, 9)

	rows[id] = {row = row, stroke = rowStroke, badge = badge, badgeText = badgeText, sw = sw, knob = sk, name = item.name}
	rowOrder[#rowOrder + 1] = id

	row.Activated:Connect(function()
		scale.Scale = 0.95
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		if id == "cape" then
			setCape(not state.cape)
		else
			setMode(id, state.mode ~= id)
		end
	end)
end

local order = 0
local index = 0
for _, sec in ipairs(sections) do
	order = order + 1
	local hd = Instance.new("Frame")
	hd.Name = "Section"
	hd.LayoutOrder = order
	hd.Size = UDim2.new(1, -4, 0, 22)
	hd.BackgroundTransparency = 1
	hd.Parent = list
	label(hd, sec.name, Enum.Font.GothamBold, 11, GOLD, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 16))
	local ln = Instance.new("Frame")
	ln.Position = UDim2.fromOffset(4, 19)
	ln.Size = UDim2.new(1, -8, 0, 1)
	ln.BackgroundColor3 = GOLD
	ln.BackgroundTransparency = 0.7
	ln.BorderSizePixel = 0
	ln.Parent = hd
	for _, id in ipairs(sec.ids) do
		order = order + 1
		index = index + 1
		makeRow(id, index, order)
	end
end

refreshUI = function()
	local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local names = {}
	for _, id in ipairs(rowOrder) do
		local r = rows[id]
		local on = (id == "cape" and state.cape) or state.mode == id
		TweenService:Create(r.knob, info, {Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}):Play()
		TweenService:Create(r.sw, info, {BackgroundColor3 = on and GOLD or OFF}):Play()
		TweenService:Create(r.stroke, info, {Color = on and GOLD or OFF, Transparency = on and 0.05 or 0.45}):Play()
		TweenService:Create(r.row, info, {BackgroundColor3 = on and ACTIVE or PANEL, BackgroundTransparency = on and 0.05 or 0.25}):Play()
		TweenService:Create(r.badge, info, {BackgroundColor3 = on and GOLD or OFF}):Play()
		TweenService:Create(r.badgeText, info, {TextColor3 = on and BG2 or TEXT}):Play()
		if on then
			names[#names + 1] = r.name
		end
	end
	if #names > 0 then
		status.Text = "Đang bật: " .. table.concat(names, " + ")
	else
		status.Text = "Chưa bật chức năng nào"
	end
end
refreshUI()

local SPEED_MIN = 0.5
local SPEED_MAX = 1.6

local function setSpeedAlpha(t)
	t = math.clamp(t, 0, 1)
	settings.speed = SPEED_MIN + (SPEED_MAX - SPEED_MIN) * t
	fill.Size = UDim2.fromScale(t, 1)
	knob.Position = UDim2.fromScale(t, 0.5)
	speedValue.Text = string.format("%d%%", math.floor(settings.speed * 100 + 0.5))
end
setSpeedAlpha((1 - SPEED_MIN) / (SPEED_MAX - SPEED_MIN))

local sliding = false

local function slideTo(x)
	local w = bar.AbsoluteSize.X
	if w > 0 then
		setSpeedAlpha((x - bar.AbsolutePosition.X) / w)
	end
end

hit.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		slideTo(input.Position.X)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				sliding = false
			end
		end)
	end
end)

conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
	if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		slideTo(input.Position.X)
	end
end)

local function makeDraggable(handle, target, onTap)
	local dragging = false
	local moved = false
	local startInput
	local startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			startInput = input.Position
			startPos = target.AbsolutePosition
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onTap then
						onTap()
					end
				end
			end)
		end
	end)
	conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			if d.Magnitude > 6 then
				moved = true
			end
			if moved then
				local vs = gui.AbsoluteSize
				local sz = target.AbsoluteSize
				local ap = target.AnchorPoint
				local x = math.clamp(startPos.X + d.X, 0, math.max(vs.X - sz.X, 0))
				local y = math.clamp(startPos.Y + d.Y, 0, math.max(vs.Y - sz.Y, 0))
				target.Position = UDim2.fromOffset(x + sz.X * ap.X, y + sz.Y * ap.Y)
			end
		end
	end)
end

local function collapse()
	local p = main.AbsolutePosition
	local vs = gui.AbsoluteSize
	bubble.Position = UDim2.fromOffset(math.clamp(p.X + 10, 0, math.max(vs.X - 56, 0)), math.clamp(p.Y + 10, 0, math.max(vs.Y - 56, 0)))
	main.Visible = false
	bubble.Visible = true
end

local function expand()
	main.Position = UDim2.fromScale(0.5, 0.5)
	mainScale.Scale = 0.86
	main.Visible = true
	bubble.Visible = false
	TweenService:Create(mainScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

minBtn.Activated:Connect(collapse)
makeDraggable(header, main)
makeDraggable(bubble, bubble, expand)

local armed = false
closeBtn.Activated:Connect(function()
	if armed then
		if _G.HuyPremiumCleanup then
			_G.HuyPremiumCleanup()
		end
		return
	end
	armed = true
	closeBtn.Text = "?"
	closeBtn.BackgroundColor3 = Color3.fromRGB(170, 40, 60)
	status.Text = "Bấm thêm lần nữa để tắt script"
	task.delay(2.2, function()
		if closeBtn.Parent then
			armed = false
			closeBtn.Text = "X"
			closeBtn.BackgroundColor3 = PANEL
			refreshUI()
		end
	end)
end)

conns[#conns + 1] = RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if main.Visible then
		titleGrad.Offset = Vector2.new(math.sin(t * 1.4) * 0.4, 0)
		strokeGrad.Rotation = (t * 45) % 360
	end
	if bubble.Visible then
		bubbleGrad.Rotation = (t * 90) % 360
		bubbleStroke.Transparency = 0.1 + 0.3 * (0.5 + 0.5 * math.sin(t * 3))
	end
end)

TweenService:Create(mainScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

_G.HuyPremiumCleanup = function()
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	pcall(restoreRig)
	destroyFx()
	destroyCape()
	gui:Destroy()
	_G.HuyPremiumCleanup = nil
end
