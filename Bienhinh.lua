local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local K = 160
local KM = 220
local KB = 200
local HC = 0.34
local HS = 0.26

local RED = Color3.fromRGB(186, 28, 34)
local RED_DARK = Color3.fromRGB(104, 10, 16)
local RED_GLOW = Color3.fromRGB(255, 58, 66)
local BLUE = Color3.fromRGB(32, 58, 130)
local BLUE_DARK = Color3.fromRGB(12, 26, 72)
local LEG = Color3.fromRGB(26, 48, 114)
local BLACK = Color3.fromRGB(10, 8, 10)
local WHITE = Color3.fromRGB(246, 248, 250)
local GREY = Color3.fromRGB(184, 190, 200)
local FACES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local FACES_TOP = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top }

local session = nil
local enabled = false
local runId = 0
local startAnim
local stopSession
local toggle
local W = nil

local function box(c, x, y, w, h, col, tr, rot)
	local r = math.rad(rot or 0)
	local ey = (math.abs(w * math.sin(r)) + math.abs(h * math.cos(r))) / 2
	if y + ey < c.y0 or y - ey > c.y1 then
		return nil
	end
	c.n += 1
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x / c.w, y / c.h)
	f.Size = UDim2.fromScale(w / c.w, h / c.h)
	f.BackgroundColor3 = col
	f.BackgroundTransparency = tr or 0
	f.BorderSizePixel = 0
	f.Rotation = rot or 0
	f.ZIndex = c.n
	f.Parent = c.root
	return f
end

local function ellipse(c, x, y, w, h, col, tr, rot)
	local f = box(c, x, y, w, h, col, tr, rot)
	if not f then
		return nil
	end
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0.5, 0)
	u.Parent = f
	return f
end

local function line(c, x1, y1, x2, y2, th, col, tr)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 0.01 then
		return nil
	end
	return box(c, (x1 + x2) / 2, (y1 + y2) / 2, len + th * 0.6, th, col or BLACK, tr, math.deg(math.atan2(dy, dx)))
end

local function half(c, x1, y1, x2, y2, ix, iy, col)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	local mx, my = (x1 + x2) / 2, (y1 + y2) / 2
	local nx, ny = -dy / len, dx / len
	if (ix - mx) * nx + (iy - my) * ny < 0 then
		nx, ny = -nx, -ny
	end
	local big = (c.w + c.h) * 3
	return box(c, mx + nx * big / 2, my + ny * big / 2, big * 2, big, col, 0, math.deg(math.atan2(dy, dx)))
end

local function gradient(f, c0, c1, rot)
	if not f then
		return
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot
	g.Parent = f
end

local function strip(c, x, y, w, h, col, tr)
	local f = box(c, x, y, w, h, col, 0)
	if not f then
		return
	end
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, tr),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
end

local function wline(c, x1, y1, x2, y2, th)
	if c.soft then
		line(c, x1, y1, x2, y2, th + 3.5, RED_DARK, 0.6)
	end
	line(c, x1, y1, x2, y2, th, BLACK, 0.04)
end

local function web(c, cx, cy, angles, radii, rmax, th, closed, sag)
	local n = #angles
	for i = 1, n do
		local a = angles[i]
		wline(c, cx, cy, cx + math.sin(a) * rmax, cy + math.cos(a) * rmax, th)
	end
	local pairsN = closed and n or n - 1
	for _, r in radii do
		for i = 1, pairsN do
			local a1 = angles[i]
			local a2 = angles[i + 1] or (angles[1] + math.pi * 2)
			local am = (a1 + a2) / 2
			local x1, y1 = cx + math.sin(a1) * r, cy + math.cos(a1) * r
			local x2, y2 = cx + math.sin(a2) * r, cy + math.cos(a2) * r
			local xm, ym = cx + math.sin(am) * r * (1 - sag), cy + math.cos(am) * r * (1 - sag)
			wline(c, x1, y1, xm, ym, th)
			wline(c, xm, ym, x2, y2, th)
		end
	end
end

local SPIDER_LEGS = {
	{ { 0.05, -0.21 }, { 0.20, -0.21 }, { 0.19, -0.49 } },
	{ { 0.06, -0.15 }, { 0.37, -0.08 }, { 0.26, -0.47 } },
	{ { 0.06, -0.08 }, { 0.35, 0.06 }, { 0.23, 0.38 } },
	{ { 0.07, 0.00 }, { 0.21, 0.17 }, { 0.12, 0.50 } },
}

local function spider(c, cx, cy, hgt, col)
	for _, leg in SPIDER_LEGS do
		for side = -1, 1, 2 do
			local x1, y1 = cx + side * leg[1][1] * hgt, cy + leg[1][2] * hgt
			local x2, y2 = cx + side * leg[2][1] * hgt, cy + leg[2][2] * hgt
			local x3, y3 = cx + side * leg[3][1] * hgt, cy + leg[3][2] * hgt
			line(c, x1, y1, x2, y2, hgt * 0.062, col)
			line(c, x2, y2, x3, y3, hgt * 0.04, col)
			ellipse(c, x2, y2, hgt * 0.055, hgt * 0.055, col)
		end
	end
	ellipse(c, cx, cy - hgt * 0.17, hgt * 0.15, hgt * 0.16, col)
	ellipse(c, cx, cy + hgt * 0.085, hgt * 0.2, hgt * 0.35, col)
	for side = -1, 1, 2 do
		line(c, cx + side * hgt * 0.035, cy - hgt * 0.24, cx + side * hgt * 0.06, cy - hgt * 0.31, hgt * 0.024, col)
	end
end

local function eye(c, x, y, ew, eh, rot)
	for _, d in { 11, -11 } do
		ellipse(c, x, y, ew * 1.2, eh * 1.26, RED_DARK, 0.55, rot + d)
	end
	for _, d in { 11, -11 } do
		ellipse(c, x, y, ew * 1.12, eh * 1.16, BLACK, 0, rot + d)
	end
	for _, d in { 11, -11 } do
		gradient(ellipse(c, x, y, ew, eh, WHITE, 0, rot + d), WHITE, GREY, 90)
	end
end

local function grid(c, y1, y2)
	local w = c.w
	local step = w * 0.13
	local y = y1 + step
	while y < y2 - step * 0.5 do
		wline(c, 0, y, w, y, 3.4)
		y += step
	end
	for i = 0, 4 do
		local x = w * i / 4
		wline(c, x, y1, x, y2, 3.4)
	end
end

local function belt(c, converge)
	local w, h = c.w, c.h
	local by = h * 0.865
	box(c, w / 2, (by + h + 20) / 2, w, h - by + 20, RED)
	for _, f in { 0.905, 0.945, 0.985 } do
		wline(c, 0, h * f, w, h * f, 3.4)
	end
	for i = 0, 10 do
		local x = w * i / 10
		local x2 = converge and (w / 2 + (x - w / 2) * 0.9) or x
		wline(c, x, by, x2, h, 3.4)
	end
	line(c, 0, by, w, by, 5.5, BLACK)
end

local function torsoFront(c, back)
	local w, h = c.w, c.h
	local angles = {}
	for i = -6, 6 do
		angles[#angles + 1] = i * 0.19
	end
	local radii = {}
	for _, r in { 0.14, 0.27, 0.42, 0.59, 0.78, 0.98 } do
		radii[#radii + 1] = r * w
	end
	web(c, w / 2, -h * 0.05, angles, radii, w * 1.6, 3.6, false, 0.075)
	half(c, 0, h * 0.2, w * 0.31, h * 0.9, w * 0.02, h * 0.6, BLUE)
	half(c, w, h * 0.2, w * 0.69, h * 0.9, w * 0.98, h * 0.6, BLUE)
	line(c, 0, h * 0.2, w * 0.31, h * 0.9, 11, RED_DARK, 0.5)
	line(c, w, h * 0.2, w * 0.69, h * 0.9, 11, RED_DARK, 0.5)
	line(c, 0, h * 0.2, w * 0.31, h * 0.9, 5, BLACK)
	line(c, w, h * 0.2, w * 0.69, h * 0.9, 5, BLACK)
	belt(c, true)
	if back then
		spider(c, w / 2, h * 0.4, h * 0.34, BLACK)
	else
		spider(c, w / 2, h * 0.43, h * 0.44, BLACK)
	end
end

local function torsoSide(c)
	local w, h = c.w, c.h
	local sh = h * 0.2
	web(c, w / 2, -h * 0.04, { -0.7, -0.35, 0, 0.35, 0.7 }, { 0.22 * w, 0.42 * w, 0.64 * w }, w, 3.4, false, 0.08)
	box(c, w / 2, (sh + h + 20) / 2, w, h - sh + 20, BLUE)
	line(c, 0, sh, w, sh, 5.5, BLACK)
	belt(c, false)
end

local function torsoPainter(c, face)
	if face == "Front" then
		torsoFront(c, false)
	elseif face == "Back" then
		torsoFront(c, true)
	else
		torsoSide(c)
	end
end

local function armPainter(c, face, info)
	local w, h = c.w, c.h
	local sh, be, hs = info.sh * h, info.be * h, info.hs * h
	for i = 0, 4 do
		wline(c, w / 2, -sh * 0.4, w * i / 4, sh, 3.4)
	end
	for _, f in { 0.4, 0.75 } do
		local y0 = sh * f
		local sg = sh * 0.12
		for i = 0, 7 do
			local xa = w * i / 8
			local xb = w * (i + 1) / 8
			local ya = y0 - ((i % 2 == 1) and sg or 0)
			local yb = y0 - (((i + 1) % 2 == 1) and sg or 0)
			wline(c, xa, ya, xb, yb, 3.4)
		end
	end
	if face ~= info.side then
		box(c, w / 2, (sh + be) / 2, w, be - sh, BLUE)
		line(c, 0, sh, w, sh, 5, BLACK)
		line(c, 0, be - 7, w, be - 7, 7, BLUE_DARK, 0.35)
		line(c, 0, be, w, be, 5, BLACK)
		if face == "Front" or face == "Back" then
			local x = (((face == "Front") == (info.side == "Right")) and 0) or w
			line(c, x, sh, x, be, 6, BLACK)
		end
	else
		grid(c, sh, be)
		line(c, 0, sh, 0, be, 6, BLACK)
		line(c, w, sh, w, be, 6, BLACK)
	end
	grid(c, be, hs)
	web(c, w / 2, hs, { -0.9, -0.6, -0.3, 0, 0.3, 0.6, 0.9 }, { 0.2 * w, 0.4 * w, 0.62 * w, 0.9 * w }, (h - hs) * 1.4, 3.4, false, 0.08)
	line(c, 0, hs, w, hs, 5, BLACK)
end

local function legPainter(c, face, info)
	local w, h = c.w, c.h
	local cy = info.cuff * h
	local ky = info.knee * h
	strip(c, w * 0.3, cy / 2, w * 0.22, cy, WHITE, 0.9)
	strip(c, w * 0.78, cy / 2, w * 0.18, cy, BLACK, 0.84)
	line(c, 0, ky, w, ky, 10, BLUE_DARK, 0.62)
	line(c, 0, ky + 5, w, ky + 5, 4, WHITE, 0.9)
	line(c, 0, cy - 10, w, cy - 10, 16, BLUE_DARK, 0.5)
	line(c, 0, cy - 2, w, cy - 2, 5, BLACK)
end

local function headPainter(c, face)
	local w, h = c.w, c.h
	if face == "Front" then
		c.soft = true
		local angles = {}
		for i = 0, 11 do
			angles[#angles + 1] = i * math.pi * 2 / 12
		end
		local radii = {}
		for _, r in { 0.11, 0.21, 0.33, 0.47, 0.64 } do
			radii[#radii + 1] = r * w
		end
		web(c, w / 2, h * 0.6, angles, radii, w, 3.8, true, 0.08)
		eye(c, w * 0.27, h * 0.47, w * 0.42, h * 0.27, 26)
		eye(c, w * 0.73, h * 0.47, w * 0.42, h * 0.27, -26)
	else
		local angles = {}
		for i = 0, 9 do
			angles[#angles + 1] = i * math.pi * 2 / 10
		end
		local radii = {}
		for _, r in { 0.16, 0.34, 0.54 } do
			radii[#radii + 1] = r * w
		end
		web(c, w / 2, h * 0.55, angles, radii, w, 3.6, true, 0.08)
	end
end

local function cuffPainter(c)
	local w, h = c.w, c.h
	for _, f in { 0.3, 0.58, 0.84 } do
		wline(c, 0, h * f, w, h * f, 3.4)
	end
	for i = 0, 6 do
		local x = w * i / 6
		wline(c, x, 0, x, h, 3.4)
	end
	line(c, 0, 1, w, 1, 7, BLACK)
end

local function shoePainter(c, face)
	local w, h = c.w, c.h
	if face == "Front" then
		for i = 0, 8 do
			local x = w * i / 8
			wline(c, x, 0, w / 2 + (x - w / 2) * 0.62, h, 3.4)
		end
		wline(c, 0, h * 0.5, w, h * 0.5, 3.4)
	elseif face == "Top" then
		for i = 0, 6 do
			local x = w * i / 6
			wline(c, x, 0, x, h, 3.4)
		end
		for _, f in { 0.3, 0.55, 0.8 } do
			wline(c, 0, h * f, w, h * f, 3.4)
		end
	else
		for i = 0, 8 do
			local x = w * i / 8
			wline(c, x, 0, x, h, 3.4)
		end
		wline(c, 0, h * 0.5, w, h * 0.5, 3.4)
	end
end

local function dialPainter(c)
	local w = c.w
	ellipse(c, w / 2, w / 2, w, w, BLACK, 0)
	ellipse(c, w / 2, w / 2, w * 0.9, w * 0.9, RED, 0)
	gradient(ellipse(c, w / 2, w / 2, w * 0.8, w * 0.8, RED_GLOW, 0), RED_GLOW, RED_DARK, 90)
	spider(c, w / 2, w * 0.52, w * 0.56, WHITE)
end

local function shade(g)
	local f = Instance.new("Frame")
	f.Name = "Shade"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.ZIndex = 100000
	local gr = Instance.new("UIGradient")
	gr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.66),
		NumberSequenceKeypoint.new(0.2, 0.93),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(0.8, 0.93),
		NumberSequenceKeypoint.new(1, 0.66),
	})
	gr.Parent = f
	f.Parent = g
end

local function faceGui(part, face, w, h, list)
	local g = Instance.new("SurfaceGui")
	g.Name = "SpiderSkinGui"
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	g.CanvasSize = Vector2.new(w, h)
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.LightInfluence = 1
	g.AlwaysOnTop = false
	g.ClipsDescendants = true
	g.Enabled = false
	g.Parent = part
	list[#list + 1] = g
	return g
end

local function newCtx(g, ratio, offset, w, h, y0, y1, round)
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, ratio)
	holder.Position = UDim2.fromScale(0, offset)
	if round then
		holder.ClipsDescendants = true
		local u = Instance.new("UICorner")
		u.CornerRadius = UDim.new(0.2, 0)
		u.Parent = holder
	end
	holder.Parent = g
	return { root = holder, w = w, h = h, n = 1, soft = false, y0 = y0, y1 = y1 }
end
local function faceDims(p, face)
	if face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		return p.Size.X, p.Size.Z
	elseif face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		return p.Size.X, p.Size.Y
	end
	return p.Size.Z, p.Size.Y
end

local function paintOne(s, part, faces, painter, k, info, list, round)
	for _, face in faces do
		local fw, fh = faceDims(part, face)
		local g = faceGui(part, face, fw * k, fh * k, list)
		local c = newCtx(g, 1, 0, fw * k, fh * k, -1e9, 1e9, round)
		painter(c, face.Name, info)
		shade(g)
		task.wait()
		if s.dead then
			return false
		end
	end
	return true
end

local function paintStack(s, parts, painter, info, list)
	local total = 0
	for _, p in parts do
		total += p.Size.Y
	end
	local off = 0
	for _, p in parts do
		for _, face in FACES do
			local fw = (face == Enum.NormalId.Front or face == Enum.NormalId.Back) and p.Size.X or p.Size.Z
			local g = faceGui(p, face, fw * K, p.Size.Y * K, list)
			local c = newCtx(g, total / p.Size.Y, -off / p.Size.Y, fw * K, total * K, off * K - 4, (off + p.Size.Y) * K + 4)
			painter(c, face.Name, info)
			shade(g)
		end
		off += p.Size.Y
		task.wait()
		if s.dead then
			return false
		end
	end
	return true
end

local function armInfo(list, side, r15)
	if r15 then
		local total = list[1].Size.Y + list[2].Size.Y + list[3].Size.Y
		return { side = side, sh = 0.12, be = math.clamp(list[1].Size.Y / total, 0.3, 0.6), hs = 1 - list[3].Size.Y / total }
	end
	return { side = side, sh = 0.15, be = 0.52, hs = 0.8 }
end

local function legInfo(list, r15)
	if r15 then
		local total = list[1].Size.Y + list[2].Size.Y
		return { knee = list[1].Size.Y / total, cuff = 1 - (HC - 0.05) / total }
	end
	return { knee = 0.5, cuff = 1 - (HC + HS) / list[1].Size.Y }
end

local function setProp(s, inst, prop, val)
	local ok, old = pcall(function()
		return inst[prop]
	end)
	if not ok then
		return
	end
	s.props[#s.props + 1] = { inst, prop, old }
	pcall(function()
		inst[prop] = val
	end)
end

local function stash(s, inst)
	s.stash[#s.stash + 1] = { inst, inst.Parent }
	inst.Parent = nil
end

local function hideLoose(s, c)
	if s.dead or not c.Parent then
		return
	end
	if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c:IsA("CharacterMesh") then
		stash(s, c)
	elseif c:IsA("Accessory") then
		task.spawn(function()
			c:WaitForChild("Handle", 3)
			if s.dead then
				return
			end
			for _, d in c:GetDescendants() do
				if d:IsA("BasePart") then
					setProp(s, d, "Transparency", 1)
				end
			end
		end)
	end
end

local function newPart(folder, anchor, size, offset, col, name, mat, shape, tr)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = col
	p.Material = mat or Enum.Material.Fabric
	p.Transparency = tr or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = anchor.CFrame * offset
	p.Parent = folder
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = p
	w.Parent = p
	return p
end

local function tintFor(g, p, col)
	g.apply[#g.apply + 1] = { p, "Color", col }
	g.apply[#g.apply + 1] = { p, "Material", Enum.Material.Fabric }
	g.apply[#g.apply + 1] = { p, "Transparency", 0 }
	if p:IsA("MeshPart") then
		g.apply[#g.apply + 1] = { p, "TextureID", "" }
	end
end

local function makeBoot(s, list, g)
	local shoe, cuff
	if s.r15 then
		local low, foot = list[2], list[3]
		shoe = newPart(s.folder, foot, foot.Size + Vector3.new(0.08, 0.06, 0.34), CFrame.new(0, 0, -0.17), RED, "SpiderShoe", nil, nil, 1)
		cuff = newPart(s.folder, low, Vector3.new(low.Size.X + 0.06, HC, low.Size.Z + 0.06), CFrame.new(0, -low.Size.Y / 2 + HC / 2 - 0.05, 0), RED, "SpiderCuff", nil, nil, 1)
	else
		local leg = list[1]
		local ly = leg.Size.Y
		shoe = newPart(s.folder, leg, Vector3.new(leg.Size.X + 0.08, HS, leg.Size.Z + 0.34), CFrame.new(0, -ly / 2 + HS / 2, -0.17), RED, "SpiderShoe", nil, nil, 1)
		cuff = newPart(s.folder, leg, Vector3.new(leg.Size.X + 0.06, HC, leg.Size.Z + 0.06), CFrame.new(0, -ly / 2 + HS + HC / 2, 0), RED, "SpiderCuff", nil, nil, 1)
	end
	g.apply[#g.apply + 1] = { shoe, "Transparency", 0 }
	g.apply[#g.apply + 1] = { cuff, "Transparency", 0 }
	if not paintOne(s, shoe, FACES_TOP, shoePainter, KB, nil, g.guis) then
		return
	end
	paintOne(s, cuff, FACES, cuffPainter, KB, nil, g.guis)
end

local function makeGroups(s)
	local P, r15 = s.parts, s.r15
	local groups = {}
	local function group(name, delay, pre, build)
		local g = { name = name, delay = delay, pre = pre, guis = {}, apply = {}, ready = false, build = build }
		groups[#groups + 1] = g
		return g
	end
	local function arm(name, delay, list, side)
		local pre = {}
		for _, p in list do
			pre[#pre + 1] = { p, RED }
		end
		group(name, delay, pre, function(g)
			for _, p in list do
				tintFor(g, p, RED)
			end
			paintStack(s, list, armPainter, armInfo(list, side, r15), g.guis)
		end)
	end
	local function leg(name, delay, list)
		local pre = {}
		for i, p in list do
			pre[#pre + 1] = { p, (r15 and i == 3) and RED or LEG }
		end
		group(name, delay, pre, function(g)
			for i, p in list do
				tintFor(g, p, (r15 and i == 3) and RED or LEG)
			end
			local stack = r15 and { list[1], list[2] } or list
			if not paintStack(s, stack, legPainter, legInfo(list, r15), g.guis) then
				return
			end
			makeBoot(s, list, g)
		end)
	end
	arm("armR", 0.1, P.armR, "Right")
	arm("armL", 0.3, P.armL, "Left")
	local tpre = {}
	for _, p in P.torso do
		tpre[#tpre + 1] = { p, RED }
	end
	group("torso", 0.6, tpre, function(g)
		for _, p in P.torso do
			tintFor(g, p, RED)
		end
		paintStack(s, P.torso, torsoPainter, {}, g.guis)
	end)
	leg("legR", 1.0, P.legR)
	leg("legL", 1.2, P.legL)
	local hg = group("head", 1.7, { { P.head, RED } }, function(g)
		tintFor(g, P.head, RED)
		local m = P.head.Size.Y
		if not P.head:IsA("MeshPart") then
			m = m * 1.25
		end
		m = math.clamp(m + 0.04, 1, 2.6)
		local plane = newPart(s.folder, P.head, Vector3.new(m, m, m), CFrame.new(), RED, "SpiderFace", nil, nil, 1)
		s.maskGuis = g.guis
		paintOne(s, plane, FACES_TOP, headPainter, KM, nil, g.guis, true)
	end)
	hg.head = true
	return groups
end

local function reveal(s, g)
	if s.dead then
		return
	end
	if not s.cleared then
		s.cleared = true
		for _, ch in s.char:GetChildren() do
			if ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") or ch:IsA("CharacterMesh") then
				stash(s, ch)
			end
		end
	end
	local flashed = {}
	for _, a in g.apply do
		setProp(s, a[1], a[2], a[3])
		if a[2] == "Color" then
			flashed[#flashed + 1] = a[1]
			for _, ch in a[1]:GetChildren() do
				if ch:IsA("SurfaceAppearance") or ch:IsA("Decal") or ch:IsA("Texture") then
					stash(s, ch)
				end
			end
		end
	end
	for _, gui in g.guis do
		gui.Enabled = true
	end
	if g.head then
		for _, ch in s.char:GetChildren() do
			hideLoose(s, ch)
		end
		s.loose = s.char.ChildAdded:Connect(function(ch)
			task.defer(hideLoose, s, ch)
		end)
	end
	for _, p in flashed do
		p.Material = Enum.Material.Neon
	end
	task.delay(0.14, function()
		if s.dead then
			return
		end
		for _, p in flashed do
			p.Material = Enum.Material.Fabric
		end
	end)
end

local function sfx(s, path, speed, vol)
	task.spawn(function()
		pcall(function()
			local snd = Instance.new("Sound")
			snd.SoundId = path
			snd.Volume = vol or 0.6
			snd.PlaybackSpeed = speed or 1
			snd.RollOffMaxDistance = 80
			snd.Parent = s.hrp
			snd:Play()
			task.delay(4, function()
				snd:Destroy()
			end)
		end)
	end)
end

local function fly(s, target, col, delay, dur, from, done)
	task.delay(delay, function()
		if s.dead then
			return
		end
		local size = target.Size + Vector3.new(0.08, 0.08, 0.08)
		local shell = Instance.new("Part")
		shell.Name = "SpiderPlate"
		shell.Anchored = true
		shell.CanCollide = false
		shell.CanQuery = false
		shell.CanTouch = false
		shell.CastShadow = false
		shell.Material = Enum.Material.Neon
		shell.Color = col
		shell.Transparency = 0.15
		shell.Size = size * 0.5
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, size.Y * 0.35, 0)
		a0.Parent = shell
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -size.Y * 0.35, 0)
		a1.Parent = shell
		local tr = Instance.new("Trail")
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Lifetime = 0.3
		tr.Color = ColorSequence.new(RED_GLOW, RED_DARK)
		tr.Transparency = NumberSequence.new(0.2, 1)
		tr.LightEmission = 0.6
		tr.Parent = shell
		local offset = from
		if not offset then
			offset = Vector3.new(math.random() - 0.5, math.random() * 0.6 + 0.1, math.random() - 0.5).Unit * (5 + math.random() * 4)
		end
		local startCF = (target.CFrame + offset) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		shell.CFrame = startCF
		shell.Parent = s.folder
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if s.dead or not shell.Parent or not target.Parent then
				conn:Disconnect()
				shell:Destroy()
				return
			end
			local u = math.clamp((os.clock() - t0) / dur, 0, 1)
			local e = 1 - (1 - u) ^ 3
			shell.Size = size * (0.5 + 0.5 * e)
			shell.CFrame = startCF:Lerp(target.CFrame, e)
			if u >= 1 then
				conn:Disconnect()
				shell:Destroy()
				done()
			end
		end)
	end)
end

local function burst(s)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = RED_GLOW
	p.Transparency = 0.4
	p.Size = Vector3.new(2, 2, 2)
	p.CFrame = s.hrp.CFrame
	p.Parent = s.folder
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if s.dead or not p.Parent then
			conn:Disconnect()
			return
		end
		local u = (os.clock() - t0) / 0.5
		if u >= 1 then
			conn:Disconnect()
			p:Destroy()
			return
		end
		local d = 2 + 12 * u
		p.Size = Vector3.new(d, d, d)
		p.Transparency = 0.4 + 0.6 * u
		p.CFrame = s.hrp.CFrame
	end)
end

local function finish(s)
	burst(s)
	sfx(s, "rbxasset://sounds/snap.mp3", 0.9, 0.8)
	sfx(s, "rbxasset://sounds/bass.wav", 1.4, 0.4)
	if W then
		W.flash = os.clock()
	end
	local ok, err = pcall(startAnim, s)
	if not ok then
		warn(err)
	end
end

local function runSuit(s)
	local groups = makeGroups(s)
	sfx(s, "rbxasset://sounds/switch.wav", 1.1, 0.7)
	if W then
		W.flash = os.clock()
	end
	local finished = 0
	for index, g in groups do
		g.pending = #g.pre
		task.delay(g.delay, function()
			if s.dead then
				return
			end
			task.spawn(function()
				local ok, err = pcall(g.build, g)
				if not ok then
					warn(err)
				end
				g.ready = true
			end)
			for j, e in g.pre do
				local from = g.head and Vector3.new(0, 9, 0) or nil
				fly(s, e[1], e[2], (j - 1) * 0.05, 0.75, from, function()
					g.pending -= 1
					if g.pending > 0 then
						return
					end
					task.spawn(function()
						while not g.ready and not s.dead do
							task.wait()
						end
						if s.dead then
							return
						end
						reveal(s, g)
						sfx(s, "rbxasset://sounds/electronicpingshort.wav", 0.9 + index * 0.1, 0.5)
						finished += 1
						if finished == #groups then
							finish(s)
						end
					end)
				end)
			end
		end)
	end
end

local function destroyWatch()
	local w = W
	W = nil
	if w then
		if w.conn then
			w.conn:Disconnect()
		end
		if w.folder then
			w.folder:Destroy()
		end
	end
end

local function makeWatch(char)
	destroyWatch()
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end
	local r15 = hum.RigType == Enum.HumanoidRigType.R15
	local arm = char:WaitForChild(r15 and "LeftLowerArm" or "Left Arm", 10)
	if not arm or not arm:IsA("BasePart") or player.Character ~= char then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SpiderWatch"
	folder.Parent = char
	local hx, hz = arm.Size.X / 2, arm.Size.Z / 2
	local y = r15 and (-arm.Size.Y / 2 + 0.22) or (-arm.Size.Y / 2 + 0.62)
	local n = Vector3.new(-1, 0, 1).Unit
	local corner = Vector3.new(-hx, y, hz)
	local rot = CFrame.Angles(0, math.pi / 4, 0)
	newPart(folder, arm, Vector3.new(hx * 2 + 0.08, 0.22, hz * 2 + 0.08), CFrame.new(0, y, 0), Color3.fromRGB(28, 22, 24), "Strap")
	local bezel = newPart(folder, arm, Vector3.new(0.14, 0.74, 0.74), CFrame.new(corner + n * 0.06) * rot, RED_GLOW, "Bezel", Enum.Material.Neon, Enum.PartType.Cylinder)
	local dial = newPart(folder, arm, Vector3.new(0.12, 0.58, 0.58), CFrame.new(corner + n * 0.115) * rot, BLACK, "Dial", Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	local list = {}
	local g = faceGui(dial, Enum.NormalId.Left, 256, 256, list)
	g.LightInfluence = 0
	g.Enabled = true
	dialPainter(newCtx(g, 1, 0, 256, 256, -1e9, 1e9, false))
	local light = Instance.new("PointLight")
	light.Color = RED_GLOW
	light.Range = 5
	light.Brightness = 0.6
	light.Parent = bezel
	local hint = Instance.new("BillboardGui")
	hint.Size = UDim2.fromOffset(130, 28)
	hint.StudsOffsetWorldSpace = Vector3.new(0, 1.3, 0)
	hint.AlwaysOnTop = true
	hint.Adornee = dial
	hint.Parent = dial
	local lb = Instance.new("TextLabel")
	lb.Size = UDim2.fromScale(1, 1)
	lb.BackgroundColor3 = Color3.fromRGB(20, 16, 18)
	lb.BackgroundTransparency = 0.35
	lb.BorderSizePixel = 0
	lb.Text = "Chạm vào đồng hồ"
	lb.TextColor3 = WHITE
	lb.TextSize = 14
	lb.Font = Enum.Font.GothamBold
	lb.Parent = hint
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0.3, 0)
	lc.Parent = lb
	local w = { folder = folder, dial = dial, hint = hint, on = enabled, flash = 0 }
	W = w
	w.conn = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local k = (math.sin(t * 3.2) + 1) / 2
		local f = math.clamp(1 - (t - w.flash) / 0.6, 0, 1)
		if w.on then
			bezel.Transparency = 0.5 - f * 0.5
			light.Brightness = 0.3 + f * 3
		else
			bezel.Transparency = 0.45 * (1 - k)
			light.Brightness = 0.4 + k * 1.1
		end
	end)
end

local function nearWatch(x, y)
	if not W or not W.dial or not W.dial.Parent then
		return false
	end
	local cam = Workspace.CurrentCamera
	if not cam then
		return false
	end
	local p = W.dial.Position
	for i = 1, 2 do
		local ray = i == 1 and cam:ScreenPointToRay(x, y) or cam:ViewportPointToRay(x, y)
		local t = (p - ray.Origin):Dot(ray.Direction)
		if t > 0 then
			local d = (ray.Origin + ray.Direction * t - p).Magnitude
			if d < 0.9 + t * 0.05 then
				return true
			end
		end
	end
	return false
end
local KEYS = { "lean", "twist", "sway", "hp", "hy", "aRx", "aRz", "aRe", "aLx", "aLz", "aLe", "lRx", "lRz", "lRk", "lLx", "lLz", "lLk", "fR", "fL" }

local function mk(t)
	for _, k in KEYS do
		if t[k] == nil then
			t[k] = 0
		end
	end
	return t
end

local function mix(a, b, w)
	local o = {}
	for _, k in KEYS do
		o[k] = a[k] + (b[k] - a[k]) * w
	end
	return o
end

local function damp(cur, vel, target, smooth, dt)
	local omega = 2 / smooth
	local x = omega * dt
	local e = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = cur - target
	local temp = (vel + omega * change) * dt
	local nv = (vel - omega * temp) * e
	return target + (change + temp) * e, nv
end

local function idlePose(t, lk)
	local br = math.sin(t * 1.7)
	local ws = math.sin(t * 0.37)
	return mk({
		lean = 0.03 + br * 0.006, twist = lk.y * 0.2, sway = ws * 0.018,
		hp = lk.p - 0.02, hy = lk.y,
		aRx = 0.03 + br * 0.012, aRz = 0.1 + br * 0.012, aRe = 0.16 + br * 0.02,
		aLx = 0.02 - br * 0.012, aLz = 0.1 + br * 0.012, aLe = 0.2 - br * 0.02,
		lRx = 0, lRz = 0.045 + ws * 0.01, lRk = 0.03,
		lLx = 0, lLz = 0.045 - ws * 0.01, lLk = 0.03,
	})
end

local function runPose(ph, k)
	local s, c = math.sin(ph), math.cos(ph)
	local sw = 0.8 * k
	return mk({
		lean = 0.05 + 0.2 * k, twist = -s * 0.15 * k, sway = c * 0.025 * k,
		hp = -0.06,
		aRx = -s * 0.85 * k - 0.1, aRz = 0.14, aRe = 0.55 + 0.5 * k + math.max(0, -s) * 0.3 * k,
		aLx = s * 0.85 * k - 0.1, aLz = 0.14, aLe = 0.55 + 0.5 * k + math.max(0, s) * 0.3 * k,
		lRx = s * sw + 0.12 * k, lRz = 0.05, lRk = 0.18 + math.max(0, c) * 1.25 * k + math.max(0, -s) * 0.12 * k,
		lLx = -s * sw + 0.12 * k, lLz = 0.05, lLk = 0.18 + math.max(0, -c) * 1.25 * k + math.max(0, s) * 0.12 * k,
		fR = math.max(0, -s) * 0.4 * k, fL = math.max(0, s) * 0.4 * k,
	})
end

local function airPose(vy, t)
	local r = math.clamp((vy + 3) / 20, 0, 1)
	local f = math.sin(t * 6) * 0.04
	local rise = mk({
		lean = 0.12, twist = 0.1, sway = 0.03, hp = -0.12,
		aRx = 2.2, aRz = 0.28, aRe = 0.25,
		aLx = -0.5, aLz = 0.95, aLe = 0.5,
		lRx = 1.15, lRz = 0.1, lRk = 1.5,
		lLx = -0.3, lLz = 0.22, lLk = 1.15,
		fR = 0.2, fL = 0.5,
	})
	local fall = mk({
		lean = 0.08, hp = -0.06,
		aRx = 0.7 + f, aRz = 1.05, aRe = 0.4,
		aLx = 0.7 - f, aLz = 1.05, aLe = 0.4,
		lRx = 0.5, lRz = 0.28, lRk = 0.9,
		lLx = 0.2, lLz = 0.28, lLk = 0.8,
		fR = 0.3, fL = 0.3,
	})
	return mix(fall, rise, r)
end

local function climbPose(ph)
	local s = math.sin(ph)
	return mk({
		lean = -0.04, sway = s * 0.08, hp = 0.3,
		aRx = 2.5 + s * 0.4, aRz = 0.4, aRe = 0.45 - s * 0.25,
		aLx = 2.5 - s * 0.4, aLz = 0.4, aLe = 0.45 + s * 0.25,
		lRx = 0.75 - s * 0.5, lRz = 0.45, lRk = 1.35 - s * 0.45,
		lLx = 0.75 + s * 0.5, lLz = 0.45, lLk = 1.35 + s * 0.45,
	})
end

local SIT = mk({
	lean = 0.04, aRx = 0.35, aRz = 0.12, aRe = 0.5, aLx = 0.35, aLz = 0.12, aLe = 0.5,
	lRx = 1.5, lRz = 0.06, lRk = 1.5, lLx = 1.5, lLz = 0.06, lLk = 1.5,
})

local LAND = mk({
	lean = 0.5, hp = -0.2,
	aRx = 0.6, aRz = 0.75, aRe = 0.5, aLx = 0.4, aLz = 0.8, aLe = 0.5,
	lRx = 1.2, lRz = 0.28, lRk = 2.0, lLx = 1.0, lLz = 0.3, lLk = 1.9,
	fR = 0.2, fL = 0.2,
})

local function setAnimate(an, off)
	local ok = pcall(function()
		an.Disabled = off
	end)
	if not ok then
		pcall(function()
			an.Enabled = not off
		end)
	end
end

local function restoreJoints(s)
	if s.base then
		for m, b in s.base do
			pcall(function()
				m.C0 = b
			end)
		end
	end
end

startAnim = function(s)
	if s.dead then
		return
	end
	local char, hum, hrp, r15, P = s.char, s.hum, s.hrp, s.r15, s.parts
	local function mot(name)
		local o = char:FindFirstChild(name, true)
		if o and o:IsA("Motor6D") then
			return o
		end
		return nil
	end
	local J = {}
	if r15 then
		J.root = mot("RootJoint")
		J.waist = mot("Waist")
		J.neck = mot("Neck")
		J.sR = mot("RightShoulder")
		J.sL = mot("LeftShoulder")
		J.eR = mot("RightElbow")
		J.eL = mot("LeftElbow")
		J.hR = mot("RightHip")
		J.hL = mot("LeftHip")
		J.kR = mot("RightKnee")
		J.kL = mot("LeftKnee")
		J.aR = mot("RightAnkle")
		J.aL = mot("LeftAnkle")
	else
		J.root = mot("RootJoint")
		J.neck = mot("Neck")
		J.sR = mot("Right Shoulder")
		J.sL = mot("Left Shoulder")
		J.hR = mot("Right Hip")
		J.hL = mot("Left Hip")
	end
	local base = {}
	for _, m in J do
		base[m] = m.C0
	end
	s.base = base
	local an = char:FindFirstChild("Animate")
	if an then
		s.animate = an
		local ok, old = pcall(function()
			return an.Disabled
		end)
		s.animOld = ok and old or false
		setAnimate(an, true)
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	local L1 = P.legR[1].Size.Y
	local L2 = r15 and P.legR[2].Size.Y or 0
	local cur = { drop = 0 }
	for _, k in KEYS do
		cur[k] = 0
	end
	local look = { y = 0, p = 0, vy = 0, vp = 0, ty = 0, tp = 0, nt = os.clock() + 1.5 }
	local phase, climb, landT, landI = 0, 0, 0, 0
	local wasAir, lastVy = false, 0
	local first = true

	local function put(m, rx, ry, rz, oy)
		if not m then
			return
		end
		local b = base[m]
		local p = b.Position
		m.C0 = CFrame.new(0, oy or 0, 0) * CFrame.new(p) * CFrame.Angles(rx, ry, rz) * CFrame.new(-p) * b
	end

	local function ext(lx, lz, lk)
		return (L1 * math.cos(lx) + L2 * math.cos(lx - lk)) * math.cos(lz)
	end

	s.died = hum.Died:Connect(function()
		restoreJoints(s)
		if s.conn then
			s.conn:Disconnect()
			s.conn = nil
		end
	end)

	s.conn = RunService.RenderStepped:Connect(function(dt)
		if s.dead then
			return
		end
		local ok, err = pcall(function()
			dt = math.min(dt, 0.1)
			if hum.Health <= 0 or not hrp.Parent then
				return
			end
			if animator then
				for _, tr in animator:GetPlayingAnimationTracks() do
					tr:Stop(0)
				end
			end
			local v = hrp.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			local st = hum:GetState()
			local air = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Swimming
			local clim = st == Enum.HumanoidStateType.Climbing
			local sit = st == Enum.HumanoidStateType.Seated or hum.Sit
			local t = os.clock()
			if air then
				lastVy = v.Y
			elseif wasAir then
				landI = math.clamp((-lastVy - 12) / 50, 0, 1)
				if landI > 0.05 then
					landT = 0.4
				end
			end
			wasAir = air
			landT = math.max(0, landT - dt)
			if not air then
				phase += dt * speed * 0.6
			end
			if clim then
				climb += dt * math.abs(v.Y) * 0.5
			end
			local still = not air and not clim and not sit and speed < 1
			if still then
				if t >= look.nt then
					if math.random() < 0.25 then
						look.ty, look.tp = 0, 0
					else
						local sd = (math.random() < 0.5) and -1 or 1
						look.ty = sd * (0.3 + math.random() * 0.7)
						look.tp = -0.04 + math.random() * 0.14
					end
					look.nt = t + 1.4 + math.random() * 2.6
				end
			else
				look.ty, look.tp = 0, 0
				look.nt = t + 1.2
			end
			look.y, look.vy = damp(look.y, look.vy, look.ty, 0.38, dt)
			look.p, look.vp = damp(look.p, look.vp, look.tp, 0.3, dt)
			local target
			if sit then
				target = SIT
			elseif clim then
				target = climbPose(climb)
			elseif air then
				target = airPose(v.Y, t)
			else
				local w = math.clamp((speed - 1) / 5, 0, 1)
				target = mix(idlePose(t, look), runPose(phase, math.clamp(speed / 16, 0.3, 1.4)), w)
				local lw = landI * math.clamp(landT / 0.4, 0, 1)
				if lw > 0.01 then
					target = mix(target, LAND, lw)
				end
			end
			if first then
				first = false
				for _, k in KEYS do
					cur[k] = target[k]
				end
			end
			local a = 1 - math.exp(-dt * (air and 9 or 14))
			for _, k in KEYS do
				cur[k] += (target[k] - cur[k]) * a
			end
			local ls = (r15 or sit) and 1 or 0.72
			local tdrop = 0
			if not air and not clim and not sit then
				local e1 = ext(cur.lRx * ls, cur.lRz, r15 and cur.lRk or 0)
				local e2 = ext(cur.lLx * ls, cur.lLz, r15 and cur.lLk or 0)
				tdrop = math.clamp(L1 + L2 - math.max(e1, e2), 0, 1.6)
			end
			cur.drop += (tdrop - cur.drop) * (1 - math.exp(-dt * 22))
			local lean, tw, sw = cur.lean, cur.twist, cur.sway
			if r15 then
				put(J.root, 0, 0, 0, -cur.drop)
				put(J.waist, -lean, tw, sw)
				put(J.neck, lean * 0.75 - cur.hp, cur.hy - tw * 0.8, -sw * 0.6)
				put(J.sR, cur.aRx + lean * 0.8, 0, cur.aRz)
				put(J.sL, cur.aLx + lean * 0.8, 0, -cur.aLz)
				put(J.eR, cur.aRe, 0, 0)
				put(J.eL, cur.aLe, 0, 0)
				put(J.hR, cur.lRx, 0, cur.lRz)
				put(J.hL, cur.lLx, 0, -cur.lLz)
				put(J.kR, -cur.lRk, 0, 0)
				put(J.kL, -cur.lLk, 0, 0)
				put(J.aR, cur.lRk - cur.lRx - cur.fR, 0, 0)
				put(J.aL, cur.lLk - cur.lLx - cur.fL, 0, 0)
			else
				put(J.root, -lean, tw, sw, -cur.drop)
				put(J.neck, lean * 0.75 - cur.hp, cur.hy - tw * 0.8, -sw * 0.6)
				put(J.sR, cur.aRx + cur.aRe * 0.4 + lean * 0.8, 0, cur.aRz)
				put(J.sL, cur.aLx + cur.aLe * 0.4 + lean * 0.8, 0, -cur.aLz)
				put(J.hR, cur.lRx * ls + lean * 0.9, -tw, cur.lRz)
				put(J.hL, cur.lLx * ls + lean * 0.9, -tw, -cur.lLz)
			end
			if s.maskGuis then
				local cam = Workspace.CurrentCamera
				if cam then
					local close = (cam.CFrame.Position - P.head.Position).Magnitude < 1.8
					if close ~= s.maskHidden then
						s.maskHidden = close
						for _, g in s.maskGuis do
							g.Enabled = not close
						end
					end
				end
			end
		end)
		if not ok then
			s.fails += 1
			if s.fails == 1 then
				warn(err)
			end
			if s.fails > 20 then
				restoreJoints(s)
				if s.conn then
					s.conn:Disconnect()
					s.conn = nil
				end
			end
		end
	end)
end

local function teardown(s)
	if s.dead then
		return
	end
	s.dead = true
	for _, key in { "conn", "died", "loose" } do
		if s[key] then
			pcall(function()
				s[key]:Disconnect()
			end)
		end
	end
	restoreJoints(s)
	if s.animate then
		pcall(function()
			s.animate.Disabled = s.animOld
		end)
	end
	if s.all then
		for _, p in s.all do
			pcall(function()
				for _, ch in p:GetChildren() do
					if ch.Name == "SpiderSkinGui" then
						ch:Destroy()
					end
				end
			end)
		end
	end
	if s.folder then
		pcall(function()
			s.folder:Destroy()
		end)
	end
	for i = #s.props, 1, -1 do
		local r = s.props[i]
		pcall(function()
			r[1][r[2]] = r[3]
		end)
	end
	for _, r in s.stash do
		pcall(function()
			if r[2] and r[2].Parent then
				r[1].Parent = r[2]
			end
		end)
	end
end

stopSession = function()
	runId += 1
	local s = session
	session = nil
	if s then
		teardown(s)
	end
end

local function collect(char, r15)
	local function get(names)
		local list = {}
		for i, n in names do
			local p = char:WaitForChild(n, 6)
			if not p or not p:IsA("BasePart") then
				return nil
			end
			list[i] = p
		end
		return list
	end
	local head = char:WaitForChild("Head", 6)
	if not head or not head:IsA("BasePart") then
		return nil
	end
	local P = { head = head }
	if r15 then
		P.torso = get({ "UpperTorso", "LowerTorso" })
		P.armR = get({ "RightUpperArm", "RightLowerArm", "RightHand" })
		P.armL = get({ "LeftUpperArm", "LeftLowerArm", "LeftHand" })
		P.legR = get({ "RightUpperLeg", "RightLowerLeg", "RightFoot" })
		P.legL = get({ "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" })
	else
		P.torso = get({ "Torso" })
		P.armR = get({ "Right Arm" })
		P.armL = get({ "Left Arm" })
		P.legR = get({ "Right Leg" })
		P.legL = get({ "Left Leg" })
	end
	for _, k in { "torso", "armR", "armL", "legR", "legL" } do
		if not P[k] then
			return nil
		end
	end
	return P
end

local function applySuit(char, id)
	local hum = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not hrp then
		return
	end
	local t0 = os.clock()
	while not player:HasAppearanceLoaded() and os.clock() - t0 < 4 do
		task.wait(0.1)
	end
	if id ~= runId or not enabled or player.Character ~= char or not char.Parent then
		return
	end
	local r15 = hum.RigType == Enum.HumanoidRigType.R15
	local parts = collect(char, r15)
	if not parts or id ~= runId or not enabled or player.Character ~= char then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SpiderSuitFx"
	folder.Parent = char
	local all = { parts.head }
	for _, key in { "torso", "armR", "armL", "legR", "legL" } do
		for _, p in parts[key] do
			all[#all + 1] = p
		end
	end
	local s = {
		char = char, hum = hum, hrp = hrp, r15 = r15, parts = parts, folder = folder, all = all,
		props = {}, stash = {}, dead = false, fails = 0, maskHidden = false, cleared = false,
	}
	session = s
	runSuit(s)
end

local function startFor(char)
	runId += 1
	local id = runId
	task.spawn(function()
		local ok, err = pcall(applySuit, char, id)
		if not ok then
			warn(err)
		end
	end)
end

local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("SpiderToggleGui")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpiderToggleGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local btn = Instance.new("TextButton")
btn.Name = "Toggle"
btn.Text = ""
btn.AutoButtonColor = false
btn.Size = UDim2.fromOffset(46, 46)
btn.Position = UDim2.new(0, 12, 0.5, -23)
btn.BackgroundColor3 = Color3.fromRGB(46, 48, 54)
btn.BorderSizePixel = 0
btn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = btn

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(110, 114, 122)
stroke.Parent = btn

local icon = Instance.new("Frame")
icon.BackgroundTransparency = 1
icon.Size = UDim2.fromScale(1, 1)
icon.Parent = btn
spider({ root = icon, w = 46, h = 46, n = 1, soft = false, y0 = -1e9, y1 = 1e9 }, 23, 23, 30, WHITE)

local function refresh()
	btn.BackgroundColor3 = enabled and RED or Color3.fromRGB(46, 48, 54)
	stroke.Color = enabled and WHITE or Color3.fromRGB(110, 114, 122)
end

local lastClick = 0

toggle = function()
	if os.clock() - lastClick < 0.8 then
		return
	end
	lastClick = os.clock()
	enabled = not enabled
	refresh()
	if W then
		W.on = enabled
		W.flash = os.clock()
		W.hint.Enabled = false
	end
	if enabled then
		if player.Character then
			startFor(player.Character)
		end
	else
		stopSession()
	end
end

btn.Activated:Connect(toggle)

UserInputService.TouchTapInWorld:Connect(function(pos, processed)
	if not processed and nearWatch(pos.X, pos.Y) then
		toggle()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and nearWatch(input.Position.X, input.Position.Y) then
		toggle()
	end
end)

player.CharacterAdded:Connect(function(char)
	stopSession()
	task.spawn(makeWatch, char)
	if enabled then
		startFor(char)
	end
end)

player.CharacterRemoving:Connect(function()
	stopSession()
	destroyWatch()
end)

if player.Character then
	task.spawn(makeWatch, player.Character)
end

refresh()
