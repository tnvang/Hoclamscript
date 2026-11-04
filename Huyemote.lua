if _G.HuyPremiumCleanup then
	pcall(_G.HuyPremiumCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local state = {mode = nil, cape = false}
local rig = {joints = {}, bases = {}}
local capeData = nil
local fx = nil
local alpha = 0
local clock = 0
local spin = 0
local conns = {}
local FX = {}
local refreshUI = function() end

local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local STAR_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local JOINT_KEYS = {
	Root = "root",
	RootJoint = "root",
	RightShoulder = "rs",
	["Right Shoulder"] = "rs",
	LeftShoulder = "ls",
	["Left Shoulder"] = "ls",
}

local function pivotRot(base, pivot, rot)
	return CFrame.new(pivot) * rot * CFrame.new(-pivot) * base
end

local function collect(char)
	local newRig = {joints = {}, bases = {}, char = char}
	newRig.hum = char:FindFirstChildOfClass("Humanoid")
	newRig.hrp = char:FindFirstChild("HumanoidRootPart")
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") then
			local key = JOINT_KEYS[d.Name]
			if key and not newRig.joints[key] then
				newRig.joints[key] = d
				newRig.bases[key] = d.C0
			end
		end
	end
	rig = newRig
end

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
	t.Transparency = NumberSequence.new(0.1, 1)
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
	pe.LightEmission = o.emit or 1
	pe.LightInfluence = 0
	pe.Rate = o.rate or 20
	pe.Lifetime = NumberRange.new(o.l0 or 0.5, o.l1 or 1)
	pe.Speed = NumberRange.new(o.s0 or 1, o.s1 or 3)
	pe.SpreadAngle = o.spread or Vector2.new(180, 180)
	pe.Size = o.size or NumberSequence.new(0.4, 0)
	pe.Transparency = o.tr or NumberSequence.new(0, 1)
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
	b.Segments = 1
	b.Width0 = 0.4
	b.Width1 = 0.4
	b.Enabled = false
	b.Parent = parent
	track(b)
	return b
end

local function makeBolt(parent, a0, a1, n, outerW, innerW, cOuter, cInner)
	local pts = {a0}
	for _ = 1, n - 1 do
		pts[#pts + 1] = attach(parent, Vector3.new(0, 0, 0))
	end
	pts[#pts + 1] = a1
	local beams = {}
	for k = 1, n do
		local o = beam(pts[k], pts[k + 1], parent, cOuter, cOuter)
		o.Width0 = outerW
		o.Width1 = outerW
		o.Transparency = NumberSequence.new(0.45)
		local i = beam(pts[k], pts[k + 1], parent, cInner, cInner)
		i.Width0 = innerW
		i.Width1 = innerW
		beams[#beams + 1] = o
		beams[#beams + 1] = i
	end
	local offs = {}
	for k = 1, n - 1 do
		offs[k] = {0, 0}
	end
	local bolt = {}
	function bolt.roll(amp)
		for k = 1, n - 1 do
			offs[k][1] = (math.random() - 0.5) * 2 * amp
			offs[k][2] = (math.random() - 0.5) * 2 * amp
		end
	end
	function bolt.step(on)
		local p0 = a0.WorldPosition
		local p1 = a1.WorldPosition
		local d = p1 - p0
		local len = d.Magnitude
		if len > 0.05 then
			local dir = d / len
			local ref = math.abs(dir.Y) > 0.9 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
			local rt = dir:Cross(ref).Unit
			local up = dir:Cross(rt)
			for k = 1, n - 1 do
				local t = k / n
				local env = math.sin(math.pi * t)
				pts[k + 1].WorldPosition = p0 + d * t + rt * (offs[k][1] * env) + up * (offs[k][2] * env)
			end
		end
		for _, b in ipairs(beams) do
			b.Enabled = on
		end
	end
	bolt.roll(1)
	return bolt
end

local function circleOn(parent, scale, color, transp)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(scale, scale)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transp
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	return f
end

local function ringStroke(frame, th, ...)
	local s = Instance.new("UIStroke")
	s.Thickness = th
	s.Color = Color3.new(1, 1, 1)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = frame
	local g = Instance.new("UIGradient")
	g.Color = seq(...)
	g.Parent = s
	return g
end

local function solid(parent, size, cf, color, material)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function weldTo(base, part)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = part
	w.Parent = part
	return w
end

local function destroyCape()
	if capeData and capeData.folder then
		pcall(function()
			capeData.folder:Destroy()
		end)
	end
	capeData = nil
end

local function buildCape(char)
	destroyCape()
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "HuyCape"
	folder.Parent = char

	local ty = torso.Size.Y
	local tz = torso.Size.Z
	local gold = Color3.fromRGB(255, 205, 90)
	local ruby = Color3.fromRGB(255, 40, 70)

	for _, sx in ipairs({-1, 1}) do
		local pad = solid(folder, Vector3.new(1.05, 0.16, 1.15), torso.CFrame * CFrame.new(sx * 1.28, ty / 2 + 0.02, 0), gold, Enum.Material.Metal)
		weldTo(torso, pad)
		local gem = solid(folder, Vector3.new(0.3, 0.3, 0.3), torso.CFrame * CFrame.new(sx * 1.28, ty / 2 + 0.17, 0), ruby, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		weldTo(torso, gem)
	end
	local collar = solid(folder, Vector3.new(1.9, 0.18, 0.3), torso.CFrame * CFrame.new(0, ty / 2 - 0.06, tz / 2 + 0.05), gold, Enum.Material.Metal)
	weldTo(torso, collar)
	local chain = solid(folder, Vector3.new(1.3, 0.08, 0.08), torso.CFrame * CFrame.new(0, ty / 2 - 0.28, -(tz / 2 + 0.05)), gold, Enum.Material.Metal)
	weldTo(torso, chain)
	local clasp = solid(folder, Vector3.new(0.34, 0.34, 0.34), torso.CFrame * CFrame.new(0, ty / 2 - 0.28, -(tz / 2 + 0.1)), ruby, Enum.Material.Neon)
	clasp.Shape = Enum.PartType.Ball
	weldTo(torso, clasp)

	local rows = 7
	local hs = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.16}
	local function widthFor(s, i)
		if s == 2 then
			return 0.92 + (i - 1) * 0.04
		end
		return 0.54 + (i - 1) * 0.06
	end
	local function dist(i)
		return (widthFor(2, i) + widthFor(1, i)) / 2
	end

	local function edge(parent, rightSide, px, color, tr)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(rightSide and 1 or 0, 0)
		f.Position = UDim2.new(rightSide and 1 or 0, 0, 0, 0)
		f.Size = UDim2.new(0, px, 1, 0)
		f.BackgroundColor3 = color
		f.BackgroundTransparency = tr
		f.BorderSizePixel = 0
		f.Parent = parent
		return f
	end

	local strips = {}
	local trails = {}
	for s = 1, 3 do
		local sign = s - 2
		local strip = {}
		local prev = torso
		for i = 1, rows do
			local w = widthFor(s, i)
			local h = hs[i]
			local hem = i == rows
			local t = (i - 1) / (rows - 1)
			local p = Instance.new("Part")
			p.Name = "Cape" .. s .. "_" .. i
			p.Size = Vector3.new(w, h, 0.1)
			p.Material = hem and Enum.Material.Metal or Enum.Material.Fabric
			if hem then
				p.Color = gold
			else
				p.Color = Color3.fromRGB(168 - 88 * t, 16 - 8 * t, 44 - 16 * t)
			end
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Massless = true
			p.Parent = folder

			local m = Instance.new("Motor6D")
			m.Part0 = prev
			if i == 1 then
				m.C0 = CFrame.new(sign * dist(1), ty / 2 - 0.12, tz / 2 + 0.1)
			else
				m.C0 = CFrame.new(sign * (dist(i) - dist(i - 1)), -hs[i - 1] / 2, 0.012)
			end
			m.C1 = CFrame.new(0, h / 2, 0)
			m.Part1 = p
			m.Parent = p

			if not hem then
				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Back
				sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
				sg.CanvasSize = Vector2.new(w * 100, h * 100)
				sg.LightInfluence = 0
				sg.Parent = p
				edge(sg, false, 3, Color3.new(0, 0, 0), 0.55)
				edge(sg, true, 3, Color3.new(1, 1, 1), 0.85)
				if s == 1 then
					edge(sg, false, 7, gold, 0)
				elseif s == 3 then
					edge(sg, true, 7, gold, 0)
				end
				if s == 2 and i == 3 then
					local ring = Instance.new("Frame")
					ring.AnchorPoint = Vector2.new(0.5, 0.5)
					ring.Position = UDim2.fromScale(0.5, 0.5)
					ring.Size = UDim2.fromOffset(44, 44)
					ring.BackgroundColor3 = Color3.fromRGB(90, 6, 26)
					ring.BorderSizePixel = 0
					ring.Parent = sg
					local rc = Instance.new("UICorner")
					rc.CornerRadius = UDim.new(0.5, 0)
					rc.Parent = ring
					local rs = Instance.new("UIStroke")
					rs.Color = gold
					rs.Thickness = 3
					rs.Parent = ring
					local tx = Instance.new("TextLabel")
					tx.BackgroundTransparency = 1
					tx.Size = UDim2.fromScale(1, 1)
					tx.Text = "H"
					tx.Font = Enum.Font.GothamBlack
					tx.TextScaled = true
					tx.TextColor3 = gold
					tx.Parent = ring
					local tp = Instance.new("UIPadding")
					tp.PaddingTop = UDim.new(0, 8)
					tp.PaddingBottom = UDim.new(0, 8)
					tp.Parent = tx
				end
			else
				local pe = Instance.new("ParticleEmitter")
				pe.Texture = STAR_TEX
				pe.Rate = s == 2 and 10 or 5
				pe.Lifetime = NumberRange.new(0.6, 1.1)
				pe.Speed = NumberRange.new(0.4, 1.4)
				pe.SpreadAngle = Vector2.new(180, 180)
				pe.Size = NumberSequence.new(0.28, 0)
				pe.LightEmission = 1
				pe.LightInfluence = 0
				pe.Color = ColorSequence.new(Color3.fromRGB(255, 232, 150), Color3.fromRGB(255, 170, 60))
				pe.Parent = p
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(-w / 2, 0, 0)
				a0.Parent = p
				local a1 = Instance.new("Attachment")
				a1.Position = Vector3.new(w / 2, 0, 0)
				a1.Parent = p
				local tr = Instance.new("Trail")
				tr.Attachment0 = a0
				tr.Attachment1 = a1
				tr.Color = ColorSequence.new(Color3.fromRGB(255, 225, 130), Color3.fromRGB(255, 140, 50))
				tr.Transparency = NumberSequence.new(0.55, 1)
				tr.Lifetime = 0.45
				tr.LightEmission = 1
				tr.LightInfluence = 0
				tr.MinLength = 0.05
				tr.FaceCamera = false
				tr.Enabled = false
				tr.Parent = p
				trails[#trails + 1] = tr
			end

			strip[i] = {motor = m, base = m.C0}
			prev = p
		end
		strips[s] = strip
	end
	capeData = {folder = folder, strips = strips, trails = trails, sf = 0, side = 0, lift = 0, turn = 0, on = false}
end

local function animateCape(dt)
	local cd = capeData
	if not cd then
		return
	end
	local hrp = rig.hrp
	if not hrp or not hrp.Parent then
		return
	end
	local vel = hrp.AssemblyLinearVelocity
	local k = math.min(1, dt * 7)
	cd.sf = cd.sf + (math.clamp(vel:Dot(hrp.CFrame.LookVector) / 18, -0.4, 1.2) - cd.sf) * k
	cd.side = cd.side + (math.clamp(vel:Dot(hrp.CFrame.RightVector) / 18, -1, 1) - cd.side) * k
	cd.lift = cd.lift + (math.clamp(vel.Y / 45, -0.7, 0.7) - cd.lift) * k
	cd.turn = cd.turn + (math.clamp(hrp.AssemblyAngularVelocity.Y, -6, 6) - cd.turn) * k
	local sf = cd.sf
	local sp = math.max(sf, 0)
	local idle = math.sin(clock * 1.6)
	for s, strip in ipairs(cd.strips) do
		local ph = s * 0.85
		for i, seg in ipairs(strip) do
			local flare = -(math.rad(2.2) + math.rad(7.5) * sf) + cd.lift * math.rad(3)
			local wave = math.sin(clock * 6 - i * 0.75 - ph) * (math.rad(1.4) + math.rad(5) * sp)
			local roll = math.sin(clock * 2.3 - i * 0.55 + ph) * math.rad(2.2) * (0.5 + sp) + (cd.turn * math.rad(1.3) - cd.side * math.rad(3.5)) * (i / 4) + idle * math.rad(0.6) * (s - 2)
			seg.motor.C0 = seg.base * CFrame.Angles(flare + wave, 0, roll)
		end
	end
	local on = sp > 0.4
	if cd.on ~= on then
		cd.on = on
		for _, t in ipairs(cd.trails) do
			t.Enabled = on
		end
	end
end
FX.void = function(char, folder)
	local head = char:FindFirstChild("Head")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	local rh = findPart(char, {"RightHand", "Right Arm"})
	local lh = findPart(char, {"LeftHand", "Left Arm"})
	local rf = findPart(char, {"RightFoot", "Right Leg"})
	local lf = findPart(char, {"LeftFoot", "Left Leg"})
	if not (head and torso) then
		return
	end
	local purple = Color3.fromRGB(165, 55, 255)
	local violet = Color3.fromRGB(90, 20, 190)
	local pink = Color3.fromRGB(255, 105, 205)
	local orange = Color3.fromRGB(255, 140, 40)
	local white = Color3.fromRGB(255, 255, 255)

	local halo = ghostOn(head, Vector3.new(0, 1.75, 0), folder)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(2.7, 2.7)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Adornee = halo
	bb.Parent = halo

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(0, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = bb

	local glow3 = circleOn(holder, 2.1, violet, 0.9)
	local glow2 = circleOn(holder, 1.7, purple, 0.78)
	local glow1 = circleOn(holder, 1.3, pink, 0.62)
	local core = circleOn(holder, 0.84, Color3.fromRGB(4, 0, 10), 0)
	local gRing = ringStroke(core, 6, purple, white, pink, white, purple)
	local ring2 = circleOn(holder, 1.02, white, 1)
	local gRing2 = ringStroke(ring2, 2, pink, purple, pink)

	local petals = {}
	for i = 1, 8 do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromScale(0.1, 0.3)
		f.BackgroundColor3 = Color3.fromRGB(70, 10, 120)
		f.BorderSizePixel = 0
		f.Parent = holder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		petals[i] = f
	end
	local dots = {}
	for i = 1, 6 do
		dots[i] = circleOn(holder, 0.07, white, 0)
	end

	local lt = light(halo, purple, 14)
	emitter(halo, {color = seq(purple, pink), rate = 38, s0 = 4, s1 = 8, spread = Vector2.new(6, 6), l0 = 0.6, l1 = 1.1, size = NumberSequence.new(0.55, 0), acc = Vector3.new(0, 5, 0)})
	emitter(halo, {color = seq(white, purple), rate = 22, s0 = 1, s1 = 3, l0 = 0.5, l1 = 0.9, size = NumberSequence.new(0.3, 0)})

	local top = ghostOn(head, Vector3.new(0, 10, 0), folder)
	local aH = attach(halo, Vector3.new(0, 0, 0))
	local aT = attach(top, Vector3.new(0, 0, 0))
	local bolt = makeBolt(top, aH, aT, 7, 0.55, 0.16, purple, white)

	trail(torso, purple, pink, 0.9, 1.5, Vector3.new(-0.6, 0.9, 0.6), Vector3.new(-0.6, -0.4, 0.6))
	trail(torso, orange, pink, 0.9, 1.5, Vector3.new(0.6, 0.9, 0.6), Vector3.new(0.6, -0.4, 0.6))
	if rh then
		trail(rh, orange, purple, 0.7, 1.3, Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0))
	end
	if lh then
		trail(lh, purple, pink, 0.7, 1.3, Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0))
	end
	for _, ft in ipairs({rf, lf}) do
		if ft then
			emitter(ft, {tex = SMOKE_TEX, color = seq(violet, purple), rate = 16, s0 = 0.5, s1 = 1.5, l0 = 0.5, l1 = 1, size = NumberSequence.new(1, 2.4), tr = NumberSequence.new(0.55, 1), emit = 0.6, acc = Vector3.new(0, 1.5, 0)})
		end
	end

	local acc = 0
	fx.update = function(dt, a)
		local on = a > 0.25
		holder.Size = UDim2.fromScale(a, a)
		gRing.Rotation = (clock * 240) % 360
		gRing2.Rotation = (-clock * 150) % 360
		glow1.BackgroundTransparency = 0.62 + math.sin(clock * 6) * 0.1
		glow2.BackgroundTransparency = 0.78 + math.sin(clock * 4.5 + 1) * 0.07
		for i, f in ipairs(petals) do
			local ang = clock * 0.9 + (i - 1) * math.pi / 4
			f.Position = UDim2.fromScale(0.5 + math.cos(ang) * 0.19, 0.5 + math.sin(ang) * 0.19)
			f.Rotation = math.deg(ang) + 90
		end
		for i, d in ipairs(dots) do
			local ang = -clock * 2.2 + (i - 1) * math.pi / 3
			d.Position = UDim2.fromScale(0.5 + math.cos(ang) * 0.58, 0.5 + math.sin(ang) * 0.58)
		end
		lt.Brightness = 3.2 * a
		acc = acc + dt
		if acc >= 0.06 then
			acc = 0
			bolt.roll(0.9)
		end
		bolt.step(on and math.random() > 0.08)
	end
end

FX.phoenix = function(char, folder)
	local torso = findPart(char, {"UpperTorso", "Torso"})
	if not torso then
		return
	end
	local goldC = Color3.fromRGB(255, 220, 100)
	local orangeC = Color3.fromRGB(255, 120, 30)
	local redC = Color3.fromRGB(225, 35, 30)
	local fire = seq(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 130, 20), Color3.fromRGB(180, 20, 10))
	local lens = {2.0, 2.8, 3.5, 4.0, 4.4, 4.1, 3.6, 3.0, 2.3}
	local count = #lens
	local wings = {}
	local feathers = {}

	local function makeWing(sign)
		local root = Instance.new("Part")
		root.Name = "WingRoot"
		root.Size = Vector3.new(0.3, 0.3, 0.3)
		root.Transparency = 1
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
		root.CastShadow = false
		root.Massless = true
		root.Parent = folder
		local base = CFrame.new(sign * 0.55, torso.Size.Y / 2 - 0.35, torso.Size.Z / 2 + 0.25) * CFrame.Angles(0, -sign * math.rad(28), 0)
		local m = Instance.new("Motor6D")
		m.Part0 = torso
		m.Part1 = root
		m.C0 = base
		m.Parent = root

		for layer = 1, 2 do
			for i = 1, count do
				local theta = math.rad(-20 + (i - 1) * 12)
				local phi = sign > 0 and (theta - math.pi / 2) or (math.pi / 2 - theta)
				local len = lens[i] * (layer == 1 and 1 or 0.55)
				local t = (i - 1) / (count - 1)
				local col
				if layer == 1 then
					if t < 0.5 then
						col = goldC:Lerp(orangeC, t * 2)
					else
						col = orangeC:Lerp(redC, (t - 0.5) * 2)
					end
				else
					col = Color3.fromRGB(255, 245, 190):Lerp(goldC, t)
				end
				local f = Instance.new("Part")
				f.Name = "Feather"
				f.Size = Vector3.new(layer == 1 and 0.4 or 0.34, len, 0.05)
				f.Material = Enum.Material.Neon
				f.Color = col
				f.CanCollide = false
				f.CanTouch = false
				f.CanQuery = false
				f.CastShadow = false
				f.Massless = true
				f.Transparency = 1
				f.Parent = folder
				local fm = Instance.new("Motor6D")
				fm.Part0 = root
				fm.Part1 = f
				fm.C0 = CFrame.new(0, 0, (layer == 1 and 0 or 0.04) + i * 0.005) * CFrame.Angles(0, 0, phi)
				fm.C1 = CFrame.new(0, -len / 2, 0)
				fm.Parent = f
				feathers[#feathers + 1] = f
				if layer == 1 and i >= 4 and i <= 6 then
					trail(f, goldC, redC, 0.5, 1.2, Vector3.new(0, len / 2, 0), Vector3.new(0, len / 2 - 0.9, 0))
					emitter(f, {tex = FIRE_TEX, color = fire, rate = 16, s0 = 0.5, s1 = 2, l0 = 0.35, l1 = 0.7, size = NumberSequence.new(0.9, 0), acc = Vector3.new(0, 4, 0)})
				end
			end
		end
		wings[#wings + 1] = {motor = m, base = base, sign = sign}
	end
	makeWing(1)
	makeWing(-1)

	emitter(torso, {color = seq(Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 90, 20)), rate = 24, s0 = 2, s1 = 5, l0 = 0.6, l1 = 1.2, size = NumberSequence.new(0.35, 0), acc = Vector3.new(0, 4, 0)})
	for _, nm in ipairs({{"RightFoot", "Right Leg"}, {"LeftFoot", "Left Leg"}}) do
		local ft = findPart(char, nm)
		if ft then
			emitter(ft, {tex = FIRE_TEX, color = fire, rate = 14, s0 = 0.5, s1 = 1.5, l0 = 0.3, l1 = 0.6, size = NumberSequence.new(0.8, 0), acc = Vector3.new(0, 3, 0)})
		end
	end
	local lt = light(torso, Color3.fromRGB(255, 140, 40), 18)

	fx.update = function(dt, a)
		local f = math.sin(clock * 8.5)
		local tr = 1 - a
		for _, w in ipairs(wings) do
			w.motor.C0 = w.base * CFrame.Angles(0, 0, w.sign * (math.rad(18) + math.rad(34) * f) * a)
		end
		for _, p in ipairs(feathers) do
			p.Transparency = tr
		end
		lt.Brightness = (2.6 + math.sin(clock * 18) * 0.8) * a
	end
end

FX.galaxy = function(char, folder)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and torso and hum) then
		return
	end
	local white = Color3.new(1, 1, 1)
	local cyan = Color3.fromRGB(110, 220, 255)
	local violet = Color3.fromRGB(170, 100, 255)
	local pink = Color3.fromRGB(255, 120, 220)

	local orbs = {}
	for i = 1, 10 do
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
		local t = trail(o, white, white, 1, 1, Vector3.new(0, 0.25, 0), Vector3.new(0, -0.25, 0))
		orbs[i] = {part = o, trail = t, orbit = (i - 1) % 3 + 1}
	end
	local radii = {2.6, 3.4, 4.2}
	local tilts = {math.rad(-20), math.rad(55), math.rad(88)}
	local speeds = {3.4, -2.6, 2.0}

	local disc = Instance.new("Part")
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanTouch = false
	disc.CanQuery = false
	disc.CastShadow = false
	disc.Transparency = 1
	disc.Size = Vector3.new(7, 0.05, 7)
	disc.CFrame = hrp.CFrame
	disc.Parent = folder
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(512, 512)
	sg.LightInfluence = 0
	sg.AlwaysOnTop = false
	sg.Adornee = disc
	sg.Parent = disc
	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = sg
	local discGlow = circleOn(root, 0.96, violet, 0.82)
	local ringA = circleOn(root, 0.96, white, 1)
	local gA = ringStroke(ringA, 6, cyan, violet, pink, violet, cyan)
	local ringB = circleOn(root, 0.78, white, 1)
	local gB = ringStroke(ringB, 3, pink, cyan, pink)
	local ringC = circleOn(root, 0.34, white, 1)
	local gC = ringStroke(ringC, 3, white, violet, white)
	local squares = {}
	for i = 1, 2 do
		local sq = Instance.new("Frame")
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Position = UDim2.fromScale(0.5, 0.5)
		sq.Size = UDim2.fromScale(0.6, 0.6)
		sq.BackgroundTransparency = 1
		sq.Parent = root
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = i == 1 and cyan or pink
		st.Parent = sq
		squares[i] = sq
	end
	local runes = {}
	for i = 1, 12 do
		runes[i] = circleOn(root, 0.035, white, 0)
	end

	emitter(torso, {color = seq(cyan, violet, pink), rate = 45, s0 = 0.5, s1 = 2, l0 = 1, l1 = 1.6, size = NumberSequence.new(0.4, 0), sphere = true})
	local lt = light(torso, white, 16)

	fx.update = function(dt, a)
		local base = hrp.Position + Vector3.new(0, 0.4, 0)
		for i, d in ipairs(orbs) do
			local o = d.orbit
			local ang = clock * speeds[o] + i * 0.9
			local r = radii[o]
			local cf = CFrame.new(base) * CFrame.Angles(0, clock * 0.4 * o, tilts[o]) * CFrame.new(math.cos(ang) * r, 0, math.sin(ang) * r)
			d.part.Position = cf.Position
			local h = (clock * 0.2 + i / 10) % 1
			local c1 = Color3.fromHSV(h, 0.75, 1)
			d.part.Color = c1
			d.part.Transparency = 1 - a
			d.trail.Color = ColorSequence.new(c1, Color3.fromHSV((h + 0.18) % 1, 0.9, 1))
		end
		local feet = hum.RigType == Enum.HumanoidRigType.R15 and (hum.HipHeight + hrp.Size.Y / 2) or 3
		local gp = hrp.Position - Vector3.new(0, feet - 0.08, 0)
		local sz = math.max(7 * a, 0.01)
		disc.Size = Vector3.new(sz, 0.05, sz)
		disc.CFrame = CFrame.new(gp)
		gA.Rotation = (clock * 90) % 360
		gB.Rotation = (-clock * 130) % 360
		gC.Rotation = (clock * 200) % 360
		squares[1].Rotation = (clock * 40) % 360
		squares[2].Rotation = (clock * 40 + 45) % 360
		for i, r in ipairs(runes) do
			local ang = clock * 0.8 + (i - 1) * math.pi / 6
			r.Position = UDim2.fromScale(0.5 + math.cos(ang) * 0.44, 0.5 + math.sin(ang) * 0.44)
		end
		discGlow.BackgroundTransparency = 0.82 + math.sin(clock * 3) * 0.06
		lt.Color = Color3.fromHSV((clock * 0.2) % 1, 0.7, 1)
		lt.Brightness = 2.5 * a
	end
end

FX.thunder = function(char, folder)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = findPart(char, {"UpperTorso", "Torso"})
	local rh = findPart(char, {"RightHand", "Right Arm"})
	local lh = findPart(char, {"LeftHand", "Left Arm"})
	local rf = findPart(char, {"RightFoot", "Right Leg"})
	local lf = findPart(char, {"LeftFoot", "Left Leg"})
	if not (hrp and torso and rh and lh) then
		return
	end
	local cyan = Color3.fromRGB(110, 200, 255)
	local white = Color3.fromRGB(240, 252, 255)
	local blue = Color3.fromRGB(50, 120, 255)

	local sky = ghostOn(hrp, Vector3.new(0.5, 11, 0), folder)
	local gnd = ghostOn(hrp, Vector3.new(-3, -2.5, 0), folder)
	local aSky = attach(sky, Vector3.new(0, 0, 0))
	local aGnd = attach(gnd, Vector3.new(0, 0, 0))
	local aR = attach(rh, Vector3.new(0, -0.2, 0))
	local aL = attach(lh, Vector3.new(0, -0.2, 0))
	local aT = attach(torso, Vector3.new(0, 0, 0))

	local bolts = {
		{bolt = makeBolt(sky, aR, aSky, 8, 0.6, 0.2, blue, white), amp = 1.1},
		{bolt = makeBolt(sky, aR, aSky, 8, 0.4, 0.12, cyan, white), amp = 1.5},
		{bolt = makeBolt(gnd, aL, aGnd, 5, 0.36, 0.12, blue, white), amp = 0.8},
	}
	for _, ft in ipairs({rf, lf}) do
		if ft then
			local aF = attach(ft, Vector3.new(0, 0, 0))
			bolts[#bolts + 1] = {bolt = makeBolt(sky, aT, aF, 4, 0.22, 0.08, cyan, white), amp = 0.6}
		end
	end

	emitter(torso, {color = seq(white, cyan, blue), rate = 40, s0 = 6, s1 = 12, l0 = 0.25, l1 = 0.5, size = NumberSequence.new(0.35, 0)})
	emitter(rh, {color = seq(white, cyan), rate = 30, s0 = 4, s1 = 9, l0 = 0.2, l1 = 0.45, size = NumberSequence.new(0.4, 0)})
	emitter(lh, {color = seq(white, cyan), rate = 20, s0 = 3, s1 = 7, l0 = 0.2, l1 = 0.4, size = NumberSequence.new(0.3, 0)})
	trail(torso, cyan, blue, 0.5, 1.2, Vector3.new(0, 0.9, 0.6), Vector3.new(0, -0.4, 0.6))
	local lt = light(torso, cyan, 18)

	local acc = 0
	fx.update = function(dt, a)
		local on = a > 0.25
		acc = acc + dt
		if acc >= 0.05 then
			acc = 0
			for _, b in ipairs(bolts) do
				b.bolt.roll(b.amp)
			end
		end
		for _, b in ipairs(bolts) do
			b.bolt.step(on and math.random() > 0.12)
		end
		lt.Brightness = on and (math.random() * 6) or 0
	end
end

local function buildFx(mode)
	destroyFx()
	local char = rig.char
	if not (mode and char and FX[mode]) then
		return
	end
	fx = {objs = {}, emitters = {}, trails = {}, on = nil, update = nil}
	local folder = Instance.new("Folder")
	folder.Name = "HuyFx"
	folder.Parent = char
	track(folder)
	local ok, err = pcall(FX[mode], char, folder)
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
local function applyMotion(dt)
	local hum, hrp, j, b = rig.hum, rig.hrp, rig.joints, rig.bases
	if not (hum and hrp and j.root and j.root.Parent and hum.Health > 0) then
		alpha = 0
		return
	end
	local moving = hum.MoveDirection.Magnitude > 0.1
	local target = (state.mode ~= nil and moving) and 1 or 0
	alpha = alpha + (target - alpha) * math.min(1, dt * 10)
	local a = alpha
	local feet = hum.RigType == Enum.HumanoidRigType.R15 and (hum.HipHeight + hrp.Size.Y / 2) or 3
	local pivot = b.root.Position + Vector3.new(0, -feet, 0)
	local rootC = b.root
	local rsC = b.rs
	local lsC = b.ls
	local mode = state.mode

	if mode == "shake" then
		local s = math.sin(clock * 12)
		rootC = CFrame.new(s * 0.5 * a, 0, 0) * pivotRot(b.root, pivot, CFrame.Angles(0, math.rad(16) * s * a, 0))
	elseif mode == "tilt" then
		local s = math.sin(clock * 7)
		rootC = pivotRot(b.root, pivot, CFrame.Angles(0, 0, math.rad(20) * s * a))
	elseif mode == "ninja" then
		local flutter = math.sin(clock * 16) * 5
		rootC = pivotRot(b.root, pivot, CFrame.Angles(-math.rad(48) * a, 0, 0))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(-math.rad(85 + flutter) * a, 0, 0))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(-math.rad(85 - flutter) * a, 0, 0))
		end
	elseif mode == "emote" then
		local s = math.sin(clock * 9)
		local bob = math.abs(s) * 0.3 * a
		rootC = CFrame.new(0, bob, 0) * pivotRot(b.root, pivot, CFrame.Angles(0, math.rad(20) * math.sin(clock * 4.5) * a, math.rad(5) * s * a))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(math.rad(135 + 35 * s) * a, 0, math.rad(18) * a))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(math.rad(135 - 35 * s) * a, 0, -math.rad(18) * a))
		end
	elseif mode == "void" then
		local s = math.sin(clock * 10)
		local c = math.cos(clock * 10)
		rootC = CFrame.new(0, math.abs(s) * 0.18 * a, 0) * pivotRot(b.root, pivot, CFrame.Angles(-math.rad(34) * a, math.rad(7) * s * a, math.rad(4) * c * a))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(-math.rad(75 + 20 * s) * a, 0, math.rad(10) * a))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(math.rad(20 + 25 * c) * a, 0, -math.rad(12) * a))
		end
	elseif mode == "phoenix" then
		local f = math.sin(clock * 8.5)
		rootC = CFrame.new(0, (0.45 + 0.35 * f) * a, 0) * pivotRot(b.root, pivot, CFrame.Angles(-math.rad(14) * a, 0, 0))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(math.rad(-15) * a, 0, math.rad(70 + 35 * f) * a))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(math.rad(-15) * a, 0, -math.rad(70 + 35 * f) * a))
		end
	elseif mode == "galaxy" then
		spin = (spin + dt * 11 * a) % (math.pi * 2)
		local ang = spin * a
		rootC = CFrame.new(0, (0.3 + math.sin(clock * 4) * 0.25) * a, 0) * pivotRot(b.root, pivot, CFrame.Angles(-math.rad(8) * a, ang, 0))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(0, 0, math.rad(88 + 8 * math.sin(clock * 3)) * a))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(0, 0, -math.rad(88 + 8 * math.sin(clock * 3)) * a))
		end
	elseif mode == "thunder" then
		local s = math.sin(clock * 14)
		local jit = a * 0.12
		rootC = CFrame.new((math.random() - 0.5) * jit, (math.random() - 0.5) * jit + math.abs(s) * 0.12 * a, 0) * pivotRot(b.root, pivot, CFrame.Angles(-math.rad(22) * a, math.rad(10) * s * a, math.rad(6) * math.sin(clock * 7) * a))
		if b.rs then
			rsC = pivotRot(b.rs, b.rs.Position, CFrame.Angles(math.rad(172 + (math.random() - 0.5) * 8) * a, 0, math.rad(6) * a))
		end
		if b.ls then
			lsC = pivotRot(b.ls, b.ls.Position, CFrame.Angles(-math.rad(65 + 25 * s) * a, 0, -math.rad(10) * a))
		end
	end

	j.root.C0 = rootC
	if j.rs then
		j.rs.C0 = rsC
	end
	if j.ls then
		j.ls.C0 = lsC
	end
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
	capeData = nil
	destroyFx()
	rig = {joints = {}, bases = {}}
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	if hum.RigType == Enum.HumanoidRigType.R15 then
		char:WaitForChild("UpperTorso")
		char:WaitForChild("LowerTorso")
		char:WaitForChild("RightUpperArm")
		char:WaitForChild("LeftUpperArm")
	else
		char:WaitForChild("Torso")
		char:WaitForChild("Right Arm")
		char:WaitForChild("Left Arm")
	end
	task.wait(0.3)
	collect(char)
	if state.mode then
		buildFx(state.mode)
	end
	if state.cape then
		buildCape(char)
	end
end

local warned = {}
local function safe(name, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok and not warned[name] then
		warned[name] = true
		warn("Huy " .. name .. " loi: " .. tostring(err))
	end
end

conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt)
	clock = clock + dt
	safe("motion", applyMotion, dt)
	safe("cape", animateCape, dt)
	safe("fx", animateFx, dt)
end)

conns[#conns + 1] = player.CharacterAdded:Connect(onChar)
if player.Character then
	task.spawn(onChar, player.Character)
end
