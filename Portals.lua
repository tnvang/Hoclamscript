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
	local SEGMENTS = 24
	local INNER_SEGMENTS = 24
	local RUNE_COUNT = 10
	local ARMS = 3
	local ARM_ORBS = 6
	local CHIP_W = 34
	local CHIP_GAP = 4
	local CELL_W = 48
	local CELL_H = 30
	local PAD_W = CELL_W * 5
	local PAD_H = CELL_H * 5
	local SPEEDS = { 0.25, 0.5, 1, 2, 4, 8 }
	local FX = {
		Near = 30,
		Close = 6,
		Lod = 300,
		Hot = 120,
		Cross = RING_R + 1.4,
		Jump = 30,
		Cooldown = 0.8,
		Disc = RING_R * 2 - 0.5,
	}
	local FLAT = CFrame.Angles(0, math.pi / 2, 0)

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
	local teleporting = false
	local fovBase = nil
	local fovToken = 0
	local flashToken = 0
	local screenFx = nil
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

	local function clamp01(x)
		return math.clamp(x, 0, 1)
	end

	local function easeOut(x)
		local v = 1 - clamp01(x)
		return 1 - v * v * v
	end

	local function easeBack(x)
		local v = clamp01(x) - 1
		return 1 + 2.70158 * v * v * v + 1.70158 * v * v
	end

	local function veil(v, k)
		return 1 - (1 - math.clamp(v, 0, 1)) * k
	end

	local function getOverlay()
		if screenFx and screenFx.Parent then
			return screenFx
		end
		screenFx = new("Frame", {
			Name = "PortalFlash",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 50,
			Parent = Gui,
		})
		return screenFx
	end

	local function screenIn(color, strength, time)
		if destroyed then
			return
		end
		local f = getOverlay()
		flashToken = flashToken + 1
		f.BackgroundColor3 = color
		f.Visible = true
		tween(f, time, { BackgroundTransparency = 1 - strength })
	end

	local function screenOut(time)
		if destroyed or not screenFx then
			return
		end
		local f = screenFx
		flashToken = flashToken + 1
		local token = flashToken
		tween(f, time, { BackgroundTransparency = 1 })
		task.delay(time + 0.05, function()
			if token == flashToken and f.Parent then
				f.Visible = false
			end
		end)
	end
	local function flash(color, strength, fadeIn, fadeOut)
		screenIn(color, strength, fadeIn)
		local token = flashToken
		task.delay(fadeIn, function()
			if token == flashToken and not destroyed then
				screenOut(fadeOut)
			end
		end)
	end

	local function punchFov(amount, inTime, outTime)
		local cam = getCamera()
		if not cam or destroyed then
			return
		end
		fovToken = fovToken + 1
		local token = fovToken
		if not fovBase then
			fovBase = cam.FieldOfView
		end
		local base = fovBase
		tween(
			cam,
			inTime,
			{ FieldOfView = math.clamp(base + amount, 1, 120) },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		task.delay(inTime, function()
			if token ~= fovToken or destroyed then
				return
			end
			local c = getCamera()
			if c then
				tween(c, outTime, { FieldOfView = base }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			end
			task.delay(outTime + 0.05, function()
				if token == fovToken then
					fovBase = nil
					local c2 = getCamera()
					if c2 then
						c2.FieldOfView = base
					end
				end
			end)
		end)
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

		local segLen = 2 * RING_R * math.sin(math.pi / SEGMENTS) * 1.12
		local ring = {}
		for i = 1, SEGMENTS do
			local a = (i - 1) / SEGMENTS * math.pi * 2
			ring[i] = newPart(model, "Ring" .. i, {
				Size = Vector3.new(segLen, 0.5, 0.6),
				CFrame = CFrame.new(math.cos(a) * RING_R, math.sin(a) * RING_R, 0)
					* CFrame.Angles(0, 0, a + math.pi / 2),
				Color = color,
				Transparency = 0.45,
			})
		end

		local innerR = RING_R - 0.62
		local inner = {}
		for i = 1, INNER_SEGMENTS do
			local a = (i - 1) / INNER_SEGMENTS * math.pi * 2
			inner[i] = newPart(model, "Inner" .. i, {
				Size = Vector3.new(2 * innerR * math.sin(math.pi / INNER_SEGMENTS) * 0.9, 0.14, 0.14),
				CFrame = CFrame.new(math.cos(a) * innerR, math.sin(a) * innerR, 0)
					* CFrame.Angles(0, 0, a + math.pi / 2),
				Color = soft,
				Transparency = 0.6,
			})
		end

		local membrane = newPart(model, "Membrane", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.12, FX.Disc, FX.Disc),
			CFrame = FLAT,
			Color = color,
			Material = Enum.Material.ForceField,
			Transparency = 0.6,
		})

		local core = newPart(model, "Core", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, FX.Disc * 0.5, FX.Disc * 0.5),
			CFrame = FLAT,
			Color = soft,
			Transparency = 0.9,
		})

		local halo = newPart(model, "Halo", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.04, RING_R * 2 + 2.6, RING_R * 2 + 2.6),
			CFrame = CFrame.new(0, 0, 0.08) * FLAT,
			Color = color,
			Transparency = 0.93,
		})

		local ripples = {}
		for i = 1, 2 do
			ripples[i] = newPart(model, "Ripple" .. i, {
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.08, FX.Disc, FX.Disc),
				CFrame = FLAT,
				Color = color,
				Material = Enum.Material.ForceField,
				Transparency = 1,
			})
		end

		local runes = {}
		for i = 1, RUNE_COUNT do
			runes[i] = newPart(model, "Rune" .. i, {
				Size = Vector3.new(0.34, 0.34, 0.34),
				Color = soft,
				Transparency = 0.2,
				CFrame = CFrame.new(),
			})
		end

		local orbs = {}
		for i = 1, ARMS * ARM_ORBS do
			orbs[i] = newPart(model, "Orb" .. i, {
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.3, 0.3, 0.3),
				Color = soft,
				Transparency = 0.2,
				CFrame = CFrame.new(),
			})
		end

		local fx = newPart(model, "Fx", {
			Size = Vector3.new(RING_R * 1.7, RING_R * 1.7, 0.6),
			Transparency = 1,
			CFrame = CFrame.new(),
		})
		local ambient = new("ParticleEmitter", {
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
			Rate = 8,
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(30, 30),
			EmissionDirection = Enum.NormalId.Front,
			Parent = fx,
		})
		pcall(function()
			ambient.Shape = Enum.ParticleEmitterShape.Sphere
			ambient.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		end)
		local jet = newPart(model, "Jet", {
			Size = Vector3.new(RING_R * 2.2, RING_R * 2.2, RING_R * 2.2),
			Transparency = 1,
			CFrame = CFrame.new(),
		})
		local inflow = new("ParticleEmitter", {
			Color = ColorSequence.new(soft, color),
			LightEmission = 1,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.3, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.25, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.45, 0.7),
			Rate = 0,
			Speed = NumberRange.new(4, 7),
			SpreadAngle = Vector2.new(0, 0),
			Parent = jet,
		})
		local spark = new("ParticleEmitter", {
			Color = ColorSequence.new(WHITE, color),
			LightEmission = 1,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.6),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.6, 1.1),
			Rate = 0,
			Speed = NumberRange.new(10, 24),
			Drag = 3,
			SpreadAngle = Vector2.new(0, 0),
			Parent = jet,
		})
		pcall(function()
			inflow.Shape = Enum.ParticleEmitterShape.Sphere
			inflow.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			inflow.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		end)
		pcall(function()
			spark.Shape = Enum.ParticleEmitterShape.Sphere
			spark.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			spark.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		end)

		local light = new("PointLight", {
			Color = color,
			Brightness = 1,
			Range = 16,
			Parent = membrane,
		})

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
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
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
		local tagScale = new("UIScale", { Scale = 1, Parent = tag })

		local p = {
			id = id,
			model = model,
			ring = ring,
			inner = inner,
			runes = runes,
			orbs = orbs,
			ripples = ripples,
			rippleOn = { false, false },
			membrane = membrane,
			core = core,
			halo = halo,
			ambient = ambient,
			inflow = inflow,
			spark = spark,
			light = light,
			gui = gui,
			tagScale = tagScale,
			color = color,
			segLen = segLen,
			position = Vector3.zero,
			yaw = 0,
			pitch = 0,
			placed = false,
			hidden = false,
			hiddenApplied = false,
			energy = 0,
			force = 0,
			flare = 0,
			flareAge = 99,
			travel = -1,
			appear = 0,
			cool = 0,
			phase = 0,
			swirl = 0,
			acc = 0,
			mix = -1,
			thick = -1,
			last = nil,
		}
		portals[#portals + 1] = p
		portalById[id] = p
		for _, strip in ipairs(strips) do
			addChip(strip, p)
		end
		return p
	end

	local function startFlare(p, travel)
		p.flare = 1
		p.flareAge = 0
		p.travel = travel
	end

	local function placePortal(p, position, yaw)
		p.position = clampPosition(position)
		p.yaw = yaw
		p.pitch = 0
		p.placed = true
		p.appear = 0
		p.energy = 0
		p.last = nil
		applyPortal(p)
		p.model.Parent = folder
		startFlare(p, -1)
		p.spark:Emit(50)
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

	local function applyHidden(p)
		p.hiddenApplied = true
		for _, seg in ipairs(p.ring) do
			seg.Transparency = 1
		end
		for _, seg in ipairs(p.inner) do
			seg.Transparency = 1
		end
		for _, rune in ipairs(p.runes) do
			rune.Transparency = 1
		end
		for _, orb in ipairs(p.orbs) do
			orb.Transparency = 1
		end
		for i, r in ipairs(p.ripples) do
			r.Transparency = 1
			p.rippleOn[i] = false
		end
		p.membrane.Transparency = 1
		p.core.Transparency = 1
		p.halo.Transparency = 1
		p.ambient.Enabled = false
		p.inflow.Enabled = false
		p.light.Enabled = false
		p.gui.Enabled = false
	end

	local function applyShown(p)
		p.hiddenApplied = false
		p.ambient.Enabled = true
		p.inflow.Enabled = true
		p.light.Enabled = true
		p.gui.Enabled = true
	end

	local function refreshLook()
		for _, p in ipairs(portals) do
			p.hidden = viewing and p.id == selectedId
		end
	end

	local function dissolve(p)
		p.spark:Emit(40)
		p.ambient.Enabled = false
		p.inflow.Enabled = false
		p.light.Enabled = false
		p.gui.Enabled = false
		for _, d in ipairs(p.model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				tween(d, 0.35, { Transparency = 1 })
			end
		end
		task.delay(1.1, function()
			p.model:Destroy()
		end)
	end

	local function onPass(p, travel)
		p.cool = FX.Cooldown
		startFlare(p, travel)
		p.spark:Emit(60)
		flash(p.color:Lerp(WHITE, 0.35), 0.45, 0.06, 0.55)
		punchFov(14, 0.09, 0.5)
	end

	local function trackPortal(p, dt, rootPos)
		local rel = nil
		local target = 0
		if rootPos and not viewing then
			rel = portalCFrame(p):PointToObjectSpace(rootPos)
			target = clamp01((FX.Near - rel.Magnitude) / (FX.Near - FX.Close))
		end
		if p.force > target then
			target = p.force
		end
		local rate = target > p.energy and 6 or 2.2
		p.energy = p.energy + (target - p.energy) * (1 - math.exp(-dt * rate))
		if p.energy < 0.001 then
			p.energy = 0
		end
		if p.appear < 1 then
			p.appear = math.min(1, p.appear + dt / 0.85)
		end
		if p.flare > 0 then
			p.flareAge = p.flareAge + dt
			p.flare = math.max(0, 1 - p.flareAge / 1.2)
		end
		if p.cool > 0 then
			p.cool = p.cool - dt
		end
		local prev = p.last
		p.last = rel
		if rel and prev and p.cool <= 0 and p.appear > 0.5 and prev.Z ~= rel.Z and prev.Z * rel.Z <= 0 then
			if (rel - prev).Magnitude <= FX.Jump then
				local hit = prev:Lerp(rel, prev.Z / (prev.Z - rel.Z))
				if math.sqrt(hit.X * hit.X + hit.Y * hit.Y) <= FX.Cross then
					onPass(p, rel.Z < prev.Z and -1 or 1)
				end
			end
		end
	end

	local function drawPortal(p, t, step)
		local base = portalCFrame(p)
		local selected = p.id == selectedId
		local e = p.energy
		local f = p.flare * p.flare
		local grow = math.max(0.05, easeBack(p.appear))
		local k = clamp01(p.appear * 1.4)
		p.phase = p.phase + step * (0.5 + 2.2 * e + 7 * f)
		p.swirl = p.swirl + step * (0.55 + 1.6 * e + 3.2 * f)

		local mix = clamp01(e * 0.25 + f * 0.85)
		if math.abs(mix - p.mix) > 0.01 then
			p.mix = mix
			local c = p.color:Lerp(WHITE, mix)
			for _, seg in ipairs(p.ring) do
				seg.Color = c
			end
			p.membrane.Color = c
			p.halo.Color = c
			p.light.Color = c
			for _, r in ipairs(p.ripples) do
				r.Color = c
			end
		end

		local thick = 1 + 0.45 * f + 0.2 * e
		if math.abs(thick - p.thick) > 0.015 then
			p.thick = thick
			local size = Vector3.new(p.segLen, 0.5 * thick, 0.6 * thick)
			for _, seg in ipairs(p.ring) do
				seg.Size = size
			end
		end

		local baseT = (selected and 0.12 or 0.38) - 0.22 * e - 0.3 * f
		local chaseAmp = (0.18 + 0.3 * e) * (1 - f)
		local chaseSpeed = 3 + 5 * e + 8 * f
		for i, seg in ipairs(p.ring) do
			local wave = math.sin(t * chaseSpeed - i * 0.52) * 0.5 + 0.5
			seg.Transparency = veil(baseT + wave * chaseAmp, k)
		end
		local innerSpeed = 2.4 + 4 * e + 6 * f
		for i, seg in ipairs(p.inner) do
			local wave = math.sin(i * 0.7 - t * innerSpeed) * 0.5 + 0.5
			seg.Transparency = veil(math.max(0.02, 0.62 - 0.35 * wave - 0.25 * e - 0.2 * f), k)
		end

		local open = 0.8 + 0.2 * easeOut(e)
		local breathe = math.sin(t * 2.2 + p.id)
		local d = FX.Disc * open * (1 + breathe * 0.015 + 0.12 * f) * grow
		p.membrane.Size = Vector3.new(0.12, d, d)
		p.membrane.Transparency = veil((selected and 0.42 or 0.66) - 0.22 * e - 0.3 * f + breathe * 0.06, k)

		local cd = FX.Disc * (0.45 + 0.35 * e + 0.5 * f) * grow
		p.core.Size = Vector3.new(0.05, cd, cd)
		p.core.Transparency = veil(0.92 - 0.38 * e - 0.55 * f + math.sin(t * 3 + p.id) * 0.03, k)

		local hd = (RING_R * 2 + 2.6) * (1 + 0.25 * e + 0.5 * f) * grow
		p.halo.Size = Vector3.new(0.04, hd, hd)
		p.halo.Transparency = veil((selected and 0.84 or 0.94) - 0.1 * e - 0.25 * f, k)

		for i, r in ipairs(p.ripples) do
			local q = (p.flareAge - (i - 1) * 0.15) / 0.95
			if p.flare > 0 and q > 0 and q < 1 then
				local s = easeOut(q)
				local rd = FX.Disc * (0.7 + 2.4 * s)
				r.Size = Vector3.new(0.08, rd, rd)
				r.CFrame = base * CFrame.new(0, 0, p.travel * (s * 6 + (i - 1) * 0.8)) * FLAT
				r.Transparency = 0.3 + 0.7 * q
				p.rippleOn[i] = true
			elseif p.rippleOn[i] then
				r.Transparency = 1
				p.rippleOn[i] = false
			end
		end

		local runeCount = #p.runes
		local rr = (RING_R + 1 + 0.45 * e + f) * (0.4 + 0.6 * grow)
		local rs = 0.34 * (1 + 0.9 * f + 0.25 * e) * grow
		local runeT = veil(0.25 - 0.2 * e - 0.2 * f, k)
		for i, rune in ipairs(p.runes) do
			local a = p.phase * 0.35 + (i - 1) / runeCount * math.pi * 2
			rune.CFrame = base
				* CFrame.new(math.cos(a) * rr, math.sin(a) * rr, 0)
				* CFrame.Angles(p.phase, p.phase * 0.7 + i, a)
			rune.Size = Vector3.new(rs, rs, rs)
			rune.Transparency = runeT
		end

		local inR = (RING_R - 0.7) * (0.85 + 0.15 * open)
		local orbBoost = 1 + 0.6 * e + f
		for i, orb in ipairs(p.orbs) do
			local arm = (i - 1) % ARMS
			local idx = math.floor((i - 1) / ARMS)
			local s = (p.swirl * 0.22 + idx / ARM_ORBS) % 1
			local r = inR * (1 - s)
			local a = arm / ARMS * math.pi * 2 + s * 1.35 * math.pi * 2 + p.swirl * 0.8
			local w = math.sin(s * math.pi)
			local sz = (0.18 + 0.28 * w) * orbBoost * grow
			orb.CFrame = base * CFrame.new(math.cos(a) * r, math.sin(a) * r, math.sin(s * 9 + p.swirl + i) * 0.18)
			orb.Size = Vector3.new(sz, sz, sz)
			orb.Transparency = veil(0.55 - 0.5 * w - 0.2 * e, k)
		end

		p.light.Brightness = (selected and 1.8 or 1) + 2.2 * e + 6 * f
		p.light.Range = 14 + 12 * e + 12 * f
		p.ambient.Rate = 6 + 26 * e + 40 * f
		p.inflow.Rate = e > 0.02 and 70 * e * (1 - f) or 0
		p.tagScale.Scale = (0.9 + 0.3 * e + 0.35 * f) * math.min(1, grow)
		p.gui.StudsOffset = Vector3.new(0, RING_R + 1.8 + 0.35 * e + math.sin(t * 2 + p.id) * 0.1, 0)
	end

	local function fxStep(dt)
		dt = math.min(dt, 0.1)
		local t = os.clock()
		local root = getRoot()
		local rootPos = root and root.Position or nil
		local cam = getCamera()
		local camPos = cam and cam.CFrame.Position or rootPos
		for _, p in ipairs(portals) do
			if p.placed then
				trackPortal(p, dt, rootPos)
				if p.hidden then
					if not p.hiddenApplied then
						applyHidden(p)
					end
				else
					if p.hiddenApplied then
						applyShown(p)
					end
					local dist = camPos and (p.position - camPos).Magnitude or 0
					if dist <= FX.Lod then
						p.acc = p.acc + dt
						local interval = 0
						if p.energy <= 0.01 and p.flare <= 0 and p.appear >= 1 then
							interval = dist <= FX.Hot and 0.033 or 0.1
						end
						if p.acc >= interval then
							local step = p.acc
							p.acc = 0
							drawPortal(p, t, step)
						end
					end
				end
			end
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
		if teleporting then
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
		if p.placed and not destroyed then
			dissolve(p)
		else
			p.model:Destroy()
		end
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
		if teleporting then
			return
		end
		local humanoid = getHumanoid()
		local root = getRoot()
		if not LocalPlayer.Character or not humanoid or not root or humanoid.Health <= 0 then
			say("Nhân vật chưa sẵn sàng")
			return
		end
		if humanoid.SeatPart then
			say("Hãy rời khỏi ghế trước")
			return
		end
		exitView()
		teleporting = true
		local id = p.id
		p.force = 1
		screenIn(p.color:Lerp(WHITE, 0.2), 0.8, 0.28)
		punchFov(22, 0.3, 0.7)
		task.delay(0.3, function()
			p.force = 0
			local character = LocalPlayer.Character
			local hum = getHumanoid()
			local r = getRoot()
			if destroyed or getPortal(id) ~= p or not character or not hum or not r or hum.Health <= 0 or hum.SeatPart then
				teleporting = false
				screenOut(0.3)
				return
			end
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			character:PivotTo(portalCFrame(p) * CFrame.new(0, 0, -ARRIVE_DISTANCE))
			for _, other in ipairs(portals) do
				other.last = nil
			end
			p.cool = FX.Cooldown
			startFlare(p, -1)
			p.spark:Emit(80)
			screenOut(0.6)
			teleporting = false
			say("Đã tới cổng #" .. id)
		end)
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
		for _, p in ipairs(portals) do
			p.last = nil
		end
		task.spawn(bindCharacter, character)
	end))
	track(LocalPlayer.CharacterRemoving:Connect(exitView))

	track(RunService.Heartbeat:Connect(function(dt)
		if destroyed then
			return
		end
		fxStep(dt)
	end))

	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, step)

	function api.shutdown()
		if destroyed then
			return
		end
		hubWasOpen = false
		exitView()
		destroyed = true
		fovToken = fovToken + 1
		flashToken = flashToken + 1
		if fovBase then
			local cam = getCamera()
			if cam then
				cam.FieldOfView = fovBase
			end
			fovBase = nil
		end
		if screenFx then
			pcall(function()
				screenFx:Destroy()
			end)
			screenFx = nil
		end
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
