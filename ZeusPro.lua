local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    Title = "TIẾT LỘ NGƯỜI SỬ DỤNG PHẦN MỀM GIAN LẬN",
    Version = "V4.0",
    SampleInterval = 0.1,
    CombatInterval = 0.25,
    UIInterval = 0.4,
    ScanDuration = 16,
    StaticPasses = 4,
    StaticNeed = 3,
    HackThreshold = 20,
    MaxDetails = 30,
    SpawnGrace = 4,
    SeatGrace = 3,
    HitGrace = 2.5,
    SpeedFloor = 45,
    SpeedMultiplier = 1.6,
    SpeedBonus = 6,
    SpeedWindow = 1,
    SpeedStreak = 6,
    SpeedNeed = 15,
    PeerRatio = 0.85,
    PeerCount = 2,
    FlingSpeed = 250,
    FlingNear = 20,
    SpinFlingNear = 14,
    TeleportLimit = 70,
    TeleportElapsed = 0.35,
    TeleportNeed = 3,
    AirGap = 4,
    FlightTime = 4.5,
    FlightNeed = 10,
    FallSpeed = -6,
    AirJumpRatio = 0.55,
    AirJumpPerAir = 3,
    AirJumpNeed = 2,
    SpinTurn = 12,
    SpinNeed = 25,
    TiltDot = 0.5,
    TiltNeed = 50,
    JitterDistance = 4,
    JitterNeed = 10,
    UndergroundMargin = 25,
    UndergroundNeed = 20,
    FloorSamples = 40,
    NoclipInside = 5,
    NoclipNeed = 8,
    PathNeed = 5,
    AttributionRadius = 60,
    AuraRadius = 22,
    AuraTargets = 3,
    AuraWindow = 0.8,
    AuraNeed = 3,
    FarmWindow = 25,
    FarmKills = 8,
    ReachSlack = 14,
    ReachNeed = 4,
    ReachHandle = 14,
    ReachOffset = 16,
    RootSizeLimit = 12,
    WalkSpeedLimit = 100,
    JumpPowerLimit = 200,
    HipHeightLimit = 12,
    ScreamId = "",
    FallbackSoundId = "rbxasset://sounds/uuhhh.mp3",
    ScreamVolume = 10,
    ToggleKey = Enum.KeyCode.RightShift,
    Colors = {
        Black = Color3.fromRGB(8, 9, 13),
        Glass = Color3.fromRGB(24, 26, 36),
        Glass2 = Color3.fromRGB(38, 41, 54),
        Accent = Color3.fromRGB(110, 175, 255),
        Violet = Color3.fromRGB(150, 105, 255),
        Green = Color3.fromRGB(70, 220, 150),
        Yellow = Color3.fromRGB(250, 200, 80),
        Orange = Color3.fromRGB(255, 140, 70),
        Red = Color3.fromRGB(255, 75, 90),
        White = Color3.fromRGB(244, 247, 255),
        Gray = Color3.fromRGB(150, 158, 176)
    }
}

local State = {
    Scanning = false,
    Destroyed = false,
    Generation = 0,
    Spectating = nil,
    CameraSubject = nil,
    DamageCount = 0,
    DamageDirty = false,
    LastError = nil,
    Shadow = nil,
    StaticBusy = 0
}

local Floor = {Y = nil, Samples = 0}
local Baseline = {LocalSpeed = 0, History = {}}
local Data = {}
local Rows = {}
local Connections = {}
local SessionConnections = {}
local RingSize = 256
local DamageRing = {}
local Tracked = {}

local function Track(connection)
    table.insert(Connections, connection)
    return connection
end

local function Safe(callback, ...)
    local ok, err = pcall(callback, ...)

    if not ok and State.LastError ~= tostring(err) then
        State.LastError = tostring(err)
        warn("[CheatReveal] " .. State.LastError)
    end

    return ok
end

local function Create(class, properties, parent)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    if object:IsA("GuiButton") then
        object.Selectable = false
    end

    object.Parent = parent
    return object
end

local function Corner(object, radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, object)
end

local function Stroke(object, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or Config.Colors.Glass2,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, object)
end

local function FormatNumber(value)
    return string.format("%.1f", value or 0)
end

local function GetColor(score)
    if score >= 80 then
        return Config.Colors.Red
    elseif score >= 50 then
        return Config.Colors.Orange
    elseif score >= Config.HackThreshold then
        return Config.Colors.Yellow
    end

    return Config.Colors.Green
end

local KnownHacks = {
    TELEPORT = "Teleport (dịch chuyển)",
    SPEED = "Speed Hack (tăng tốc)",
    FLING = "Fling (hất người chơi)",
    SPIN = "Spin (xoay liên tục)",
    FLY = "Fly Hack (bay)",
    INFJUMP = "Infinite Jump (nhảy vô hạn)",
    UNDERGROUND = "Underground (chui xuống đất)",
    NOCLIP = "Noclip (xuyên tường)",
    KILLAURA = "Kill Aura (đánh diện rộng)",
    AUTOFARM = "Auto Farm (tự động cày)",
    REACH = "Reach (tầm đánh dài)"
}

local function NewData()
    return {
        Score = 0,
        Status = "CHƯA QUÉT",
        Scanned = false,
        Scanning = false,
        LastScan = 0,
        Samples = 0,
        Clean = 0,
        Dirty = false,
        Skip = {Ride = 0, Platform = 0, Grace = 0, State = 0, Mover = 0},
        Evidence = {},
        Details = {},
        Known = {},
        Unknown = 0,
        Notes = {},
        Streak = {},
        History = {},
        Kills = {},
        Teleports = {},
        AirJumps = 0,
        AirJumpLast = 0,
        AirJumpMax = 0,
        LastPos = nil,
        LastTime = nil,
        LastLook = nil,
        LastDelta = nil,
        LastVy = 0,
        PrevClean = false,
        AirStart = nil,
        AirStartY = 0,
        AirMaxY = 0,
        Grace = 0,
        Speed = 0,
        PeakSpeed = 0,
        Gap = 0,
        Spin = 0,
        SpinUntil = 0,
        AuraBursts = 0,
        AuraStamp = 0,
        KillStamp = 0,
        MoverCheck = 0,
        MoverFound = false
    }
end

local function GetData(player)
    local shadow = State.Shadow

    if shadow and shadow[player] then
        return shadow[player]
    end

    if not Data[player] then
        Data[player] = NewData()
    end

    return Data[player]
end

local function ViewData(player)
    if not Data[player] then
        Data[player] = NewData()
    end

    return Data[player]
end

local function ResetMotion(data)
    data.LastPos = nil
    data.LastTime = nil
    data.LastLook = nil
    data.LastDelta = nil
    data.LastVy = 0
    data.PrevClean = false
    data.AirStart = nil
    data.History = {}
    data.Streak = {}
end

local function Recompute(data)
    local total = 0
    local groups = 0
    local list = {}
    local known = {}
    local seen = {}
    local unknown = 0

    for id, evidence in pairs(data.Evidence) do
        local confirmed = evidence.Count >= evidence.Need

        table.insert(list, {
            Id = id,
            Name = evidence.Name,
            Known = evidence.Known,
            Text = evidence.Detail,
            Count = evidence.Count,
            Need = evidence.Need,
            Weight = evidence.Weight,
            Confirmed = confirmed
        })

        if confirmed then
            total += evidence.Weight
            groups += 1

            if evidence.Known then
                if not seen[evidence.Name] then
                    seen[evidence.Name] = true
                    table.insert(known, evidence.Name)
                end
            else
                unknown += 1
            end
        end
    end

    if groups > 1 then
        total += math.min((groups - 1) * 6, 18)
    end

    data.Score = math.clamp(math.floor(total + 0.5), 0, 100)

    table.sort(known)
    data.Known = known
    data.Unknown = unknown

    if data.Scanning then
        data.Status = "ĐANG TRA..."
    elseif not data.Scanned then
        data.Status = "CHƯA QUÉT"
    elseif data.Score >= Config.HackThreshold then
        data.Status = "CÓ SỬ DỤNG HACK"
    elseif data.Score > 0 then
        data.Status = "DẤU HIỆU NHẸ - CHƯA KẾT LUẬN"
    else
        data.Status = "BÌNH THƯỜNG"
    end

    table.sort(list, function(a, b)
        if a.Confirmed ~= b.Confirmed then
            return a.Confirmed
        end

        if a.Weight ~= b.Weight then
            return a.Weight > b.Weight
        end

        return a.Id < b.Id
    end)

    while #list > Config.MaxDetails do
        table.remove(list)
    end

    data.Details = list
end

local function HackSummary(data)
    local parts = {}

    for _, name in ipairs(data.Known) do
        table.insert(parts, name)
    end

    if data.Unknown > 0 then
        table.insert(parts, "Sử dụng " .. data.Unknown .. " loại hack không xác định")
    end

    return table.concat(parts, "  •  ")
end

local function AddEvidence(player, id, weight, need, detail, amount)
    local data = GetData(player)
    local add = amount or 1
    local evidence = data.Evidence[id]

    if evidence then
        evidence.Count += add
        evidence.Detail = detail
        evidence.Weight = weight
        evidence.Need = need
    else
        local name = KnownHacks[string.match(id, "^%u+")]

        data.Evidence[id] = {
            Name = name or "Hack không xác định",
            Known = name ~= nil,
            Weight = weight,
            Need = need,
            Count = add,
            Detail = detail
        }
    end

    data.Dirty = true
end

local function GetParts(player)
    local character = player.Character

    if not character or not character.Parent then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or not root:IsA("BasePart") then
        return nil
    end

    return character, humanoid, root
end

local GroundParams = RaycastParams.new()
GroundParams.FilterType = Enum.RaycastFilterType.Exclude
GroundParams.IgnoreWater = true

local WallParams = OverlapParams.new()
WallParams.FilterType = Enum.RaycastFilterType.Exclude
WallParams.MaxParts = 40

local Probe = Instance.new("Part")
Probe.Name = "ScannerProbe"
Probe.Size = Vector3.new(0.4, 0.4, 0.4)
Probe.Anchored = true
Probe.CanCollide = false
Probe.CanQuery = false
Probe.CanTouch = false
Probe.Transparency = 1
Probe.Parent = Workspace

local function RefreshFilters()
    local list = {Probe}

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(list, player.Character)
        end
    end

    GroundParams.FilterDescendantsInstances = list
    WallParams.FilterDescendantsInstances = list
end
local function RootOf(humanoid)
    local model = humanoid.Parent

    if not model then
        return nil
    end

    local part = model:FindFirstChild("HumanoidRootPart")

    if part and part:IsA("BasePart") then
        return part
    end

    if model:IsA("Model") and model.PrimaryPart then
        return model.PrimaryPart
    end

    return model:FindFirstChildWhichIsA("BasePart")
end

local function TrackHumanoid(humanoid)
    if not State.Scanning or Tracked[humanoid] ~= nil or not humanoid.Parent then
        return
    end

    Tracked[humanoid] = humanoid.Health

    table.insert(SessionConnections, humanoid.HealthChanged:Connect(function(health)
        if State.Destroyed or not State.Scanning then
            return
        end

        local previous = Tracked[humanoid]
        Tracked[humanoid] = health

        if previous and health < previous then
            local part = RootOf(humanoid)

            if part then
                State.DamageCount += 1
                DamageRing[State.DamageCount % RingSize + 1] = {
                    Time = os.clock(),
                    Humanoid = humanoid,
                    Position = part.Position,
                    Delta = previous - health,
                    Dead = health <= 0,
                    Attacker = nil,
                    Distance = 0,
                    Crowd = 0,
                    Counted = false,
                    Checked = false
                }
                State.DamageDirty = true
            end
        end
    end))

    table.insert(SessionConnections, humanoid.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Tracked[humanoid] = nil
        end
    end))
end

local function StartCombat()
    for index = 1, RingSize do
        DamageRing[index] = nil
    end

    State.DamageCount = 0
    State.DamageDirty = false

    for humanoid in pairs(Tracked) do
        Tracked[humanoid] = nil
    end

    task.spawn(function()
        local count = 0

        for _, instance in ipairs(Workspace:GetDescendants()) do
            if State.Destroyed or not State.Scanning then
                return
            end

            count += 1

            if count % 500 == 0 then
                task.wait()
            end

            if instance:IsA("Humanoid") then
                TrackHumanoid(instance)
            end
        end
    end)

    table.insert(SessionConnections, Workspace.DescendantAdded:Connect(function(instance)
        if instance:IsA("Humanoid") then
            task.defer(TrackHumanoid, instance)
        end
    end))
end

local function StopCombat()
    for _, connection in ipairs(SessionConnections) do
        connection:Disconnect()
    end

    table.clear(SessionConnections)

    for humanoid in pairs(Tracked) do
        Tracked[humanoid] = nil
    end
end

local MeleeWords = {
    "sword", "knife", "katana", "blade", "axe", "hammer", "bat",
    "dagger", "spear", "saber", "sabre", "scythe", "mace", "club"
}

local function IsMelee(tool)
    local lower = string.lower(tool.Name)

    for _, word in ipairs(MeleeWords) do
        if string.find(lower, "%f[%a]" .. word .. "s?%f[%A]") then
            return true
        end
    end

    return false
end

local function AnalyzeCombat()
    if not State.DamageDirty then
        return
    end

    State.DamageDirty = false

    local now = os.clock()
    local actors = {}
    local byPlayer = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local character, humanoid, root = GetParts(player)

        if character and humanoid.Health > 0 then
            local actor = {
                Player = player,
                Humanoid = humanoid,
                Root = root,
                Tool = character:FindFirstChildOfClass("Tool")
            }
            table.insert(actors, actor)
            byPlayer[player] = actor
        end
    end

    local damaged = {}

    for index = 1, RingSize do
        local event = DamageRing[index]

        if event and now - event.Time <= 1.5 then
            damaged[event.Humanoid] = true
        end
    end

    local groups = {}

    for index = 1, RingSize do
        local event = DamageRing[index]

        if event and now - event.Time <= Config.FarmWindow then
            if event.Attacker == nil then
                local candidates = 0
                local chosen = nil
                local chosenDistance = 0

                for _, actor in ipairs(actors) do
                    if actor.Humanoid ~= event.Humanoid and not damaged[actor.Humanoid] then
                        local distance = (actor.Root.Position - event.Position).Magnitude

                        if distance <= Config.AttributionRadius then
                            candidates += 1
                            chosen = actor
                            chosenDistance = distance
                        end
                    end
                end

                event.Crowd = candidates

                if candidates == 1 then
                    event.Attacker = chosen.Player
                    event.Distance = chosenDistance
                else
                    event.Attacker = false
                end
            end

            local attacker = event.Attacker
            local actor = attacker and byPlayer[attacker]

            if actor and attacker ~= LocalPlayer then
                local data = GetData(attacker)

                if now - event.Time <= Config.AuraWindow and event.Distance <= Config.AuraRadius then
                    local group = groups[attacker]

                    if not group then
                        group = {Targets = {}, Newest = 0}
                        groups[attacker] = group
                    end

                    group.Targets[event.Humanoid] = event
                    group.Newest = math.max(group.Newest, event.Time)
                end

                if event.Dead and not event.Counted then
                    event.Counted = true
                    table.insert(data.Kills, event.Time)
                end

                if not event.Checked then
                    event.Checked = true

                    local tool = actor.Tool
                    local handle = tool and tool:FindFirstChild("Handle")

                    if tool and handle and handle:IsA("BasePart") and IsMelee(tool) then
                        local handleSize = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
                        local limit = handleSize + Config.ReachSlack
                        local distance = (event.Position - actor.Root.Position).Magnitude

                        if distance > limit then
                            AddEvidence(
                                attacker,
                                "REACH_DAMAGE",
                                45,
                                Config.ReachNeed,
                                "Gây sát thương ở cách " .. FormatNumber(distance) .. " studs với vũ khí cận chiến '" .. tool.Name .. "' (tầm hợp lệ khoảng " .. FormatNumber(limit) .. "), đã loại trừ trường hợp có nhiều người chơi khác ở gần"
                            )
                        end
                    end
                end
            end
        end
    end

    for player, group in pairs(groups) do
        local actor = byPlayer[player]
        local data = GetData(player)

        if actor and group.Newest > data.AuraStamp then
            data.AuraStamp = group.Newest

            local count = 0
            local behind = 0
            local look = actor.Root.CFrame.LookVector

            for _, event in pairs(group.Targets) do
                count += 1

                local offset = event.Position - actor.Root.Position
                local flat = Vector3.new(offset.X, 0, offset.Z)

                if flat.Magnitude > 1 and look:Dot(flat.Unit) < -0.2 then
                    behind += 1
                end
            end

            local unarmed = actor.Tool == nil

            if count >= Config.AuraTargets and (behind >= 2 or (unarmed and count >= 4)) then
                data.AuraBursts += 1

                AddEvidence(
                    player,
                    "KILLAURA",
                    45,
                    Config.AuraNeed,
                    count .. " mục tiêu cùng nhận sát thương trong " .. FormatNumber(Config.AuraWindow) .. "s, " .. behind .. " mục tiêu ở sau lưng" .. (unarmed and ", không cầm vũ khí" or "") .. " (lần thứ " .. data.AuraBursts .. ")"
                )
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local data = GetData(player)

            while #data.Kills > 0 and now - data.Kills[1] > Config.FarmWindow do
                table.remove(data.Kills, 1)
            end

            local newest = data.Kills[#data.Kills]

            if newest and newest > data.KillStamp then
                data.KillStamp = newest

                if #data.Kills >= Config.FarmKills and #data.Teleports >= 2 then
                    AddEvidence(
                        player,
                        "AUTOFARM",
                        55,
                        1,
                        "Hạ " .. #data.Kills .. " mục tiêu trong " .. Config.FarmWindow .. "s, kèm " .. #data.Teleports .. " lần dịch chuyển tức thời"
                    )
                end
            end
        end
    end
end

local function WatchPlayer(player)
    if player == LocalPlayer then
        return
    end

    local function OnCharacter()
        local data = GetData(player)
        ResetMotion(data)
        data.Grace = os.clock() + Config.SpawnGrace
    end

    if player.Character then
        OnCharacter()
    end

    Track(player.CharacterAdded:Connect(OnCharacter))
end
local ExemptStates = {
    [Enum.HumanoidStateType.Climbing] = true,
    [Enum.HumanoidStateType.Swimming] = true,
    [Enum.HumanoidStateType.Seated] = true,
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.PlatformStanding] = true,
    [Enum.HumanoidStateType.Physics] = true,
    [Enum.HumanoidStateType.GettingUp] = true
}

local AirStates = {
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.Jumping] = true,
    [Enum.HumanoidStateType.Flying] = true
}

local MoverClasses = {
    BodyVelocity = true,
    BodyGyro = true,
    BodyPosition = true,
    BodyThrust = true,
    BodyForce = true,
    BodyAngularVelocity = true,
    RocketPropulsion = true,
    LinearVelocity = true,
    AngularVelocity = true,
    VectorForce = true,
    AlignPosition = true,
    AlignOrientation = true,
    LineForce = true,
    Torque = true
}

local AirToolWords = {
    "glide", "glider", "parachute", "wing", "jetpack", "fly", "flight",
    "hover", "broom", "carpet", "heli", "rocket", "cloud", "balloon", "umbrella"
}

local function JumpVelocity(humanoid)
    if humanoid.UseJumpPower then
        return humanoid.JumpPower
    end

    return math.sqrt(2 * Workspace.Gravity * humanoid.JumpHeight)
end

local function MaxJump(humanoid)
    local velocity = JumpVelocity(humanoid)
    return (velocity * velocity) / (2 * Workspace.Gravity)
end

local function AllowedSpeed(humanoid)
    return math.max(
        Config.SpeedFloor,
        humanoid.WalkSpeed * Config.SpeedMultiplier + Config.SpeedBonus,
        Baseline.LocalSpeed * 1.3
    )
end

local function Streak(data, key, condition)
    if condition then
        data.Streak[key] = (data.Streak[key] or 0) + 1
    else
        data.Streak[key] = 0
    end

    return data.Streak[key]
end

local function StandOffset(humanoid, root)
    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        return 3
    end

    return humanoid.HipHeight + root.Size.Y / 2
end

local function GroundGap(humanoid, root, maxDistance)
    local result = Workspace:Raycast(root.Position, Vector3.new(0, -maxDistance, 0), GroundParams)

    if not result then
        return nil, nil
    end

    return result.Distance - StandOffset(humanoid, root), result
end

local function Collides(root, part)
    local ok, result = pcall(function()
        return PhysicsService:CollisionGroupsAreCollidable(root.CollisionGroup, part.CollisionGroup)
    end)

    if ok then
        return result
    end

    return true
end

local function IsSolid(part, root)
    if not part:IsA("BasePart") or part:IsA("Terrain") or part:IsA("TrussPart") then
        return false
    end

    if not part.CanCollide or not part.Anchored then
        return false
    end

    if part.Size.Magnitude < 1.5 then
        return false
    end

    if part:GetAttribute("ACAllowed") then
        return false
    end

    if part:IsA("MeshPart") or part:IsA("UnionOperation") then
        if part.CollisionFidelity ~= Enum.CollisionFidelity.PreciseConvexDecomposition then
            return false
        end
    end

    return Collides(root, part)
end

local function NearestOther(player, position, radius)
    local best = nil
    local bestDistance = radius

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local _, _, otherRoot = GetParts(other)

            if otherRoot then
                local distance = (otherRoot.Position - position).Magnitude

                if distance <= bestDistance then
                    best = other
                    bestDistance = distance
                end
            end
        end
    end

    return best, bestDistance
end

local function HasMover(data, character, now)
    if now - data.MoverCheck < 1.5 then
        return data.MoverFound
    end

    data.MoverCheck = now

    local found = false

    for _, descendant in ipairs(character:GetDescendants()) do
        if MoverClasses[descendant.ClassName] then
            found = true
            break
        end
    end

    if not found then
        local tool = character:FindFirstChildOfClass("Tool")

        if tool then
            local lower = string.lower(tool.Name)

            for _, word in ipairs(AirToolWords) do
                if string.find(lower, word, 1, true) then
                    found = true
                    break
                end
            end
        end
    end

    data.MoverFound = found
    return found
end

local function LearnFloor(gap, hit)
    if gap and gap <= Config.AirGap and hit and hit.Instance.Anchored then
        Floor.Samples += 1

        if not Floor.Y or hit.Position.Y < Floor.Y then
            Floor.Y = hit.Position.Y
        end
    end
end

local function SampleLocal()
    local character, humanoid, root = GetParts(LocalPlayer)

    if not character or humanoid.Health <= 0 then
        Baseline.History = {}
        return
    end

    local now = os.clock()
    local state = humanoid:GetState()
    local seated = humanoid.SeatPart ~= nil or humanoid.Sit
    local attached = false
    local assemblyRoot = root.AssemblyRootPart

    if assemblyRoot and assemblyRoot ~= root and not assemblyRoot:IsDescendantOf(character) then
        attached = true
    end

    local gap, hit = GroundGap(humanoid, root, 8)

    LearnFloor(gap, hit)

    local grounded = gap ~= nil and gap <= Config.AirGap and hit ~= nil and hit.Instance.Anchored

    if seated or attached or ExemptStates[state] or not grounded then
        Baseline.History = {}
        return
    end

    table.insert(Baseline.History, {Time = now, Position = root.Position})

    while #Baseline.History > 1 and now - Baseline.History[1].Time > Config.SpeedWindow + 0.15 do
        table.remove(Baseline.History, 1)
    end

    local first = Baseline.History[1]
    local span = now - first.Time

    if span >= Config.SpeedWindow * 0.8 then
        local dx = root.Position.X - first.Position.X
        local dz = root.Position.Z - first.Position.Z
        local speed = math.sqrt(dx * dx + dz * dz) / span

        if speed > Baseline.LocalSpeed then
            Baseline.LocalSpeed = math.min(speed, 120)
        end
    end
end

local function ScanMotion(player)
    local data = GetData(player)
    local character, humanoid, root = GetParts(player)

    if not character or humanoid.Health <= 0 then
        ResetMotion(data)
        return
    end

    local now = os.clock()
    local position = root.Position
    local last = data.LastPos
    local elapsed = data.LastTime and (now - data.LastTime) or 0

    if elapsed > 1 then
        ResetMotion(data)
        last = nil
        elapsed = 0
    end

    local prevClean = data.PrevClean
    local lastLook = data.LastLook
    local lastDelta = data.LastDelta
    local look = root.CFrame.LookVector

    data.LastPos = position
    data.LastTime = now
    data.LastLook = look
    data.Samples += 1

    local state = humanoid:GetState()
    local seated = humanoid.SeatPart ~= nil or humanoid.Sit
    local attached = false
    local assemblyRoot = root.AssemblyRootPart

    if assemblyRoot and assemblyRoot ~= root and not assemblyRoot:IsDescendantOf(character) then
        attached = true
    end

    local exempt = ExemptStates[state] == true

    if seated or attached then
        data.Grace = math.max(data.Grace, now + Config.SeatGrace)
        data.Skip.Ride += 1
    elseif exempt then
        data.Grace = math.max(data.Grace, now + Config.HitGrace)
        data.Skip.State += 1
    end

    if last and elapsed > 0 and elapsed <= 0.3 and not seated and not attached then
        local instant = (position - last).Magnitude / elapsed

        if instant > Config.FlingSpeed then
            local spinner = nil
            local spinnerDistance = Config.FlingNear

            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other ~= LocalPlayer then
                    local otherData = GetData(other)

                    if otherData.SpinUntil > now then
                        local _, _, otherRoot = GetParts(other)

                        if otherRoot then
                            local distance = (otherRoot.Position - position).Magnitude

                            if distance <= spinnerDistance then
                                spinner = other
                                spinnerDistance = distance
                            end
                        end
                    end
                end
            end

            if spinner then
                AddEvidence(
                    spinner,
                    "FLING",
                    55,
                    6,
                    "Người chơi " .. player.Name .. " bị hất đi " .. FormatNumber(instant) .. " studs/s khi đang bị xoay sát (" .. FormatNumber(spinnerDistance) .. " studs)",
                    3
                )
            end
        end
    end

    local grace = now < data.Grace
    local clean = not grace and not exempt and not seated and not attached
    local gap = nil
    local hit = nil
    local platform = false

    if clean then
        gap, hit = GroundGap(humanoid, root, 400)
        data.Gap = gap or -1

        if hit and gap and gap <= Config.AirGap then
            local part = hit.Instance

            if not part.Anchored or part.AssemblyLinearVelocity.Magnitude > 1.5 then
                platform = true
                data.Grace = math.max(data.Grace, now + 1.5)
                data.Skip.Platform += 1
            end
        end
    elseif grace and not exempt and not seated and not attached then
        data.Skip.Grace += 1
    end

    if not clean or platform then
        data.History = {}
        data.Streak = {}
        data.AirStart = nil
        data.PrevClean = false
        data.LastDelta = nil
        data.LastVy = 0
        return
    end

    data.Clean += 1
    LearnFloor(gap, hit)

    local jumpLimit = math.max(MaxJump(humanoid), 7)
    local currentVy = 0

    if last and prevClean and elapsed > 0 then
        currentVy = (position.Y - last.Y) / elapsed
    end

    if last and prevClean and elapsed > 0 and elapsed <= Config.TeleportElapsed then
        local distance = (position - last).Magnitude
        local expected = data.Speed * elapsed

        if distance > Config.TeleportLimit and distance > expected * 3 + 25 then
            table.insert(data.Teleports, now)

            AddEvidence(
                player,
                "TELEPORT",
                50,
                Config.TeleportNeed,
                "Tọa độ nhảy " .. FormatNumber(distance) .. " studs trong " .. FormatNumber(elapsed * 1000) .. "ms mà không đi qua khoảng giữa; không ngồi xe, không vừa hồi sinh; đã xảy ra " .. #data.Teleports .. " lần"
            )

            data.History = {{Time = now, Position = position}}
            data.Streak = {}
            data.AirStart = nil
            data.LastDelta = nil
            data.LastVy = 0
            data.PrevClean = true
            return
        end
    end

    table.insert(data.History, {Time = now, Position = position})

    while #data.History > 1 and now - data.History[1].Time > Config.SpeedWindow + 0.15 do
        table.remove(data.History, 1)
    end

    local speed = 0
    local windowVy = currentVy
    local first = data.History[1]
    local span = now - first.Time

    if span >= Config.SpeedWindow * 0.8 then
        local dx = position.X - first.Position.X
        local dz = position.Z - first.Position.Z
        speed = math.sqrt(dx * dx + dz * dz) / span
        windowVy = (position.Y - first.Position.Y) / span
    end

    data.Speed = speed

    if speed > data.PeakSpeed then
        data.PeakSpeed = speed
    end

    local mover = HasMover(data, character, now)

    if mover then
        data.Skip.Mover += 1
    end

    local allowed = AllowedSpeed(humanoid)
    local fast = not mover and speed > allowed

    if Streak(data, "speed", fast) >= Config.SpeedStreak then
        AddEvidence(
            player,
            "SPEED",
            45,
            Config.SpeedNeed,
            "Chạy ngang mặt đất " .. FormatNumber(speed) .. " studs/s (trung bình 1 giây), vượt mức cho phép " .. FormatNumber(allowed) .. " (WalkSpeed hiển thị " .. FormatNumber(humanoid.WalkSpeed) .. ", tốc độ hợp lệ đã học từ bạn " .. FormatNumber(Baseline.LocalSpeed) .. "); nhanh nhất " .. FormatNumber(data.PeakSpeed) .. " studs/s, vượt liên tục " .. data.Streak.speed .. " lần đo; không ngồi xe, không đứng trên vật chuyển động, không có vật đẩy do game gắn vào"
        )
    end

    local airState = AirStates[state] == true
    local airborne = airState and (gap == nil or gap > Config.AirGap)

    if airborne then
        if not data.AirStart then
            data.AirStart = now
            data.AirStartY = position.Y
            data.AirMaxY = position.Y
            data.AirJumps = 0
            data.AirJumpLast = now
        end

        data.AirMaxY = math.max(data.AirMaxY, position.Y)

        local airTime = now - data.AirStart

        if not mover and airTime >= Config.FlightTime and windowVy > Config.FallSpeed then
            AddEvidence(
                player,
                "FLY",
                50,
                Config.FlightNeed,
                "Ở trên không liên tục " .. FormatNumber(airTime) .. "s, cách đất " .. (gap and FormatNumber(gap) or "rất xa") .. " studs, vận tốc dọc trung bình " .. FormatNumber(windowVy) .. " studs/s (nhảy hoặc rơi bình thường không thể kéo dài quá " .. FormatNumber(Config.FlightTime) .. "s mà không rơi), đã lên cao " .. FormatNumber(data.AirMaxY - data.AirStartY) .. " studs, tầm nhảy tối đa " .. FormatNumber(jumpLimit)
            )
        end

        if last and prevClean and elapsed > 0 and now - data.AirJumpLast >= 0.3 and airTime >= 0.35 then
            local kick = currentVy - data.LastVy + Workspace.Gravity * elapsed

            if kick > JumpVelocity(humanoid) * Config.AirJumpRatio and currentVy > 10 then
                data.AirJumps += 1
                data.AirJumpLast = now
                data.AirJumpMax = math.max(data.AirJumpMax, data.AirJumps)

                if data.AirJumps == Config.AirJumpPerAir then
                    AddEvidence(
                        player,
                        "INFJUMP",
                        45,
                        Config.AirJumpNeed,
                        "Bật nhảy thêm " .. data.AirJumps .. " lần liên tiếp khi đang trên không (lực bật +" .. FormatNumber(kick) .. " studs/s so với rơi tự do)"
                    )
                end
            end
        end
    else
        data.AirStart = nil
        data.Streak.fly = 0
    end

    local turn = 0

    if lastLook and prevClean and elapsed > 0 then
        local a = Vector3.new(look.X, 0, look.Z)
        local b = Vector3.new(lastLook.X, 0, lastLook.Z)

        if a.Magnitude > 0.2 and b.Magnitude > 0.2 then
            turn = math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)) / elapsed
        end
    end

    data.Spin = turn

    if not mover and Streak(data, "spin", turn > Config.SpinTurn) >= 5 then
        data.SpinUntil = now + 1.5

        AddEvidence(
            player,
            "SPIN",
            38,
            Config.SpinNeed,
            "Thân xoay liên tục " .. FormatNumber(turn) .. " rad/s (ngưỡng " .. Config.SpinTurn .. "), kéo dài " .. data.Streak.spin .. " lần đo, không ngồi xe, không bị hất"
        )

        local near, distance = NearestOther(player, position, Config.SpinFlingNear)

        if near then
            AddEvidence(
                player,
                "FLING",
                50,
                6,
                "Xoay " .. FormatNumber(turn) .. " rad/s sát người chơi " .. near.Name .. " (cách " .. FormatNumber(distance) .. " studs)"
            )
        end
    else
        if turn <= Config.SpinTurn then
            data.Streak.spin = 0
        end
    end

    local upDot = root.CFrame.UpVector.Y

    if Streak(data, "tilt", upDot < Config.TiltDot and not humanoid.PlatformStand and not mover) >= 1 then
        AddEvidence(
            player,
            "ANOM_ORIENT",
            22,
            Config.TiltNeed,
            "Thân nghiêng bất thường kéo dài (độ dốc dọc " .. FormatNumber(upDot) .. ", bình thường gần 1.0) trong khi không ngã, không ngồi, không bị đẩy"
        )
    end

    local delta = nil

    if last and prevClean then
        delta = position - last
    end

    if delta and lastDelta then
        local a = delta.Magnitude
        local b = lastDelta.Magnitude

        if a > Config.JitterDistance and b > Config.JitterDistance and delta:Dot(lastDelta) < -0.5 * a * b then
            AddEvidence(
                player,
                "ANOM_JITTER",
                25,
                Config.JitterNeed,
                "Vị trí rung lắc đảo chiều liên tục (" .. FormatNumber(a) .. " rồi " .. FormatNumber(b) .. " studs mỗi 0.1s theo hướng ngược nhau)"
            )
        end
    end

    data.LastDelta = delta

    local floorKnown = Floor.Y ~= nil and Floor.Samples >= Config.FloorSamples
    local under = floorKnown
        and airState
        and gap == nil
        and position.Y < Floor.Y - Config.UndergroundMargin
        and position.Y > Workspace.FallenPartsDestroyHeight + 20
        and windowVy > -15

    if Streak(data, "under", under) >= 5 then
        AddEvidence(
            player,
            "UNDERGROUND",
            50,
            Config.UndergroundNeed,
            "Ở độ cao Y " .. FormatNumber(position.Y) .. ", thấp hơn mặt sàn thấp nhất đã đo " .. FormatNumber(Floor.Y) .. " tới " .. FormatNumber(Floor.Y - position.Y) .. " studs, bên dưới không có vật đỡ nhưng không rơi (vận tốc dọc " .. FormatNumber(windowVy) .. ")"
        )
    end

    Probe.CFrame = CFrame.new(position)

    local inside = nil
    local ok, parts = pcall(Workspace.GetPartsInPart, Workspace, Probe, WallParams)

    if ok then
        for _, part in ipairs(parts) do
            if IsSolid(part, root) then
                inside = part
                break
            end
        end
    end

    if Streak(data, "inside", inside ~= nil) >= Config.NoclipInside and inside then
        AddEvidence(
            player,
            "NOCLIP_INSIDE",
            50,
            Config.NoclipNeed,
            "Tâm nhân vật nằm trong vật thể đặc '" .. inside.Name .. "' (cố định, va chạm bật, đúng nhóm va chạm) liên tục " .. data.Streak.inside .. " lần đo, vật lý thường không cho phép điều này"
        )
    end

    if delta and elapsed <= 0.25 then
        local distance = delta.Magnitude

        if distance > 1 and distance < 14 then
            local result = Workspace:Raycast(last, delta, GroundParams)

            if result and IsSolid(result.Instance, root) then
                AddEvidence(
                    player,
                    "NOCLIP_PATH",
                    40,
                    Config.PathNeed,
                    "Đi xuyên qua '" .. result.Instance.Name .. "' khi di chuyển " .. FormatNumber(distance) .. " studs trong " .. FormatNumber(elapsed * 1000) .. "ms"
                )
            end
        end
    end

    data.LastVy = currentVy
    data.PrevClean = true
end
local FlagWords = {
    "chams", "wallhack", "boxesp", "nameesp", "aimbot", "killaura",
    "noclip", "speedhack", "flyhack", "exploit", "cheat", "hack"
}

local function NameFlagged(name)
    local lower = string.lower(name)

    for _, word in ipairs(FlagWords) do
        if string.find(lower, "%f[%a]" .. word .. "%f[%A]") then
            return word
        end
    end

    return nil
end

local function IsAllowed(instance, character)
    local current = instance

    while current and current ~= character.Parent do
        if current:GetAttribute("ACAllowed") then
            return true
        end

        current = current.Parent
    end

    return false
end

local function ScanHumanoid(player)
    local character, humanoid, root = GetParts(player)

    if not character then
        return
    end

    local found = {}

    if humanoid.WalkSpeed > Config.WalkSpeedLimit then
        table.insert(found, "WalkSpeed " .. FormatNumber(humanoid.WalkSpeed))
    end

    if humanoid.UseJumpPower then
        if humanoid.JumpPower > Config.JumpPowerLimit then
            table.insert(found, "JumpPower " .. FormatNumber(humanoid.JumpPower))
        end
    elseif humanoid.JumpHeight > Config.JumpPowerLimit / 5 then
        table.insert(found, "JumpHeight " .. FormatNumber(humanoid.JumpHeight))
    end

    if humanoid.HipHeight > Config.HipHeightLimit then
        table.insert(found, "HipHeight " .. FormatNumber(humanoid.HipHeight))
    end

    if humanoid.MaxHealth > 1000000 or humanoid.Health > 1000000 then
        table.insert(found, "Máu " .. FormatNumber(humanoid.MaxHealth))
    end

    if #found > 0 then
        AddEvidence(
            player,
            "ANOM_PROP",
            8,
            Config.StaticNeed,
            "Thuộc tính Humanoid bất thường: " .. table.concat(found, ", ") .. " (chỉ là dấu hiệu phụ, có thể do cơ chế game)"
        )
    end

    local rootSize = math.max(root.Size.X, root.Size.Y, root.Size.Z)
    local head = character:FindFirstChild("Head")
    local headSize = 0

    if head and head:IsA("BasePart") then
        headSize = math.max(head.Size.X, head.Size.Y, head.Size.Z)
    end

    local abnormal = rootSize > Config.RootSizeLimit or (headSize > 0 and rootSize > 5 and rootSize > headSize * 3.2)

    if abnormal and not IsAllowed(root, character) then
        AddEvidence(
            player,
            "ANOM_SIZE",
            25,
            Config.StaticNeed,
            "Hộp va chạm thân (HumanoidRootPart) lớn " .. FormatNumber(rootSize) .. " studs, lớn bất thường so với đầu " .. FormatNumber(headSize) .. " studs"
        )
    end
end

local function ScanTools(player)
    local character, _, root = GetParts(player)

    if not character then
        return
    end

    local tool = character:FindFirstChildOfClass("Tool")

    if not tool or IsAllowed(tool, character) then
        return
    end

    local found = {}
    local handle = tool:FindFirstChild("Handle")

    if handle and handle:IsA("BasePart") then
        local size = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)

        if size > Config.ReachHandle then
            table.insert(found, "cán '" .. tool.Name .. "' dài " .. FormatNumber(size) .. " studs")
        end

        local offset = (handle.Position - root.Position).Magnitude

        if offset > Config.ReachOffset then
            table.insert(found, "vũ khí '" .. tool.Name .. "' cách thân " .. FormatNumber(offset) .. " studs")
        end
    end

    local checked = 0

    for _, part in ipairs(tool:GetDescendants()) do
        checked += 1

        if checked > 80 then
            break
        end

        if part:IsA("BasePart") and part ~= handle then
            local size = math.max(part.Size.X, part.Size.Y, part.Size.Z)

            if size > Config.ReachHandle * 1.5 then
                table.insert(found, "vùng '" .. part.Name .. "' của '" .. tool.Name .. "' rộng " .. FormatNumber(size) .. " studs")
                break
            end
        end
    end

    if #found > 0 then
        AddEvidence(
            player,
            "ANOM_TOOL",
            18,
            Config.StaticNeed,
            "Vũ khí bất thường: " .. table.concat(found, "; ")
        )
    end
end

local function ScanObjects(player)
    local character = player.Character

    if not character then
        return
    end

    local checked = 0
    local names = {}

    for _, instance in ipairs(character:GetDescendants()) do
        checked += 1

        if checked % 150 == 0 then
            task.wait()
        end

        if instance.Parent and not IsAllowed(instance, character) then
            local word = NameFlagged(instance.Name)

            if word and #names < 4 then
                table.insert(names, "'" .. instance.Name .. "' (" .. instance.ClassName .. ")")
            end
        end
    end

    if #names > 0 then
        AddEvidence(
            player,
            "ANOM_OBJ",
            10,
            Config.StaticNeed,
            "Đối tượng có tên đáng ngờ gắn trên nhân vật: " .. table.concat(names, ", ")
        )
    end
end

local function RunStatic(player)
    if player == LocalPlayer or player.Parent ~= Players then
        return
    end

    Safe(ScanHumanoid, player)
    Safe(ScanTools, player)
    Safe(ScanObjects, player)
end
local OldGui = PlayerGui:FindFirstChild("CheatRevealScanner")

if OldGui then
    OldGui:Destroy()
end

local OldLegacy = PlayerGui:FindFirstChild("UniversalPlayerScanner")

if OldLegacy then
    OldLegacy:Destroy()
end

local UI = {}

local function Glass(object, radius, strong)
    Corner(object, radius)

    Create("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(135, 140, 155)),
        Rotation = 90
    }, object)

    local stroke = Stroke(object, Color3.fromRGB(255, 255, 255), strong and 0.6 or 0.84)

    Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.7)
        }),
        Rotation = 90
    }, stroke)

    return object
end

local function Hover(button, normal, hover)
    Track(button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = hover}):Play()
    end))

    Track(button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = normal}):Play()
    end))
end

local function Button(parent, properties, radius)
    properties.AutoButtonColor = false
    properties.BorderSizePixel = 0

    local normal = properties.BackgroundTransparency or 0
    local button = Create("TextButton", properties, parent)

    Corner(button, radius or 8)
    Stroke(button, Color3.fromRGB(255, 255, 255), 0.8)
    Hover(button, normal, math.max(normal - 0.2, 0))

    return button
end

UI.Gui = Create("ScreenGui", {
    Name = "CheatRevealScanner",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

UI.Main = Create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0.94, 0, 0.92, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Config.Colors.Black,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, UI.Gui)

Glass(UI.Main, 18, true)

Create("UISizeConstraint", {
    MaxSize = Vector2.new(900, 560),
    MinSize = Vector2.new(300, 220)
}, UI.Main)

UI.Scale = Create("UIScale", {Scale = 1}, UI.Main)

UI.Sheen = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 0
}, UI.Main)

Create("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    }),
    Rotation = 90
}, UI.Sheen)

UI.Header = Create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundTransparency = 1,
    BorderSizePixel = 0
}, UI.Main)

UI.Title = Create("TextLabel", {
    Size = UDim2.new(1, -120, 0, 22),
    Position = UDim2.fromOffset(16, 6),
    BackgroundTransparency = 1,
    Text = Config.Title,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextScaled = true,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left
}, UI.Header)

Create("UITextSizeConstraint", {MaxTextSize = 16, MinTextSize = 8}, UI.Title)

Create("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Config.Colors.Accent)
}, UI.Title)

Create("TextLabel", {
    Size = UDim2.new(1, -120, 0, 14),
    Position = UDim2.fromOffset(16, 30),
    BackgroundTransparency = 1,
    Text = Config.Version .. "  •  CHỈ QUÉT KHI BẠN BẤM  •  ƯU TIÊN CHÍNH XÁC",
    TextColor3 = Config.Colors.Gray,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, UI.Header)

UI.Minimize = Button(UI.Header, {
    Size = UDim2.fromOffset(32, 28),
    Position = UDim2.new(1, -78, 0, 10),
    BackgroundColor3 = Config.Colors.Glass2,
    BackgroundTransparency = 0.3,
    Text = "—",
    TextColor3 = Config.Colors.White,
    TextSize = 15,
    Font = Enum.Font.GothamBold
}, 8)

UI.Close = Button(UI.Header, {
    Size = UDim2.fromOffset(32, 28),
    Position = UDim2.new(1, -42, 0, 10),
    BackgroundColor3 = Config.Colors.Red,
    BackgroundTransparency = 0.45,
    Text = "X",
    TextColor3 = Config.Colors.White,
    TextSize = 12,
    Font = Enum.Font.GothamBold
}, 8)

UI.Divider = Create("Frame", {
    Size = UDim2.new(1, -28, 0, 1),
    Position = UDim2.fromOffset(14, 52),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
}, UI.Main)

Create("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.55),
        NumberSequenceKeypoint.new(1, 1)
    })
}, UI.Divider)

UI.Body = Create("Frame", {
    Size = UDim2.new(1, -16, 1, -66),
    Position = UDim2.fromOffset(8, 58),
    BackgroundTransparency = 1
}, UI.Main)

UI.Side = Create("ScrollingFrame", {
    Size = UDim2.new(0.34, -4, 1, 0),
    BackgroundColor3 = Config.Colors.Glass,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Config.Colors.Accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, UI.Body)

Glass(UI.Side, 14, false)

Create("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, UI.Side)

Create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8)
}, UI.Side)

local function Stat(order, text, color)
    local card = Create("Frame", {
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0
    }, UI.Side)

    Corner(card, 8)
    Stroke(card, Color3.fromRGB(255, 255, 255), 0.88)

    return Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, card)
end

UI.PlayerCount = Stat(1, "NGƯỜI CHƠI: 0", Config.Colors.White)
UI.SuspiciousCount = Stat(2, "CÓ DÙNG HACK: 0", Config.Colors.Gray)
UI.ScanState = Stat(3, "SẴN SÀNG", Config.Colors.Green)

UI.ProgressBack = Create("Frame", {
    LayoutOrder = 4,
    Size = UDim2.new(1, 0, 0, 8),
    BackgroundColor3 = Config.Colors.Glass2,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0
}, UI.Side)

Corner(UI.ProgressBack, 5)

UI.ProgressFill = Create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Config.Colors.Accent,
    BorderSizePixel = 0
}, UI.ProgressBack)

Corner(UI.ProgressFill, 5)

Create("UIGradient", {
    Color = ColorSequence.new(Config.Colors.Accent, Config.Colors.Violet)
}, UI.ProgressFill)

UI.ProgressText = Create("TextLabel", {
    LayoutOrder = 5,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "Chưa quét. Bấm TRA NGAY để quét mọi người, hoặc TRA ở từng người (khoảng 16 giây).",
    TextColor3 = Config.Colors.Gray,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
}, UI.Side)

UI.Search = Create("TextBox", {
    LayoutOrder = 6,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Config.Colors.Glass2,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    PlaceholderText = "Tìm tên người chơi...",
    PlaceholderColor3 = Config.Colors.Gray,
    Text = "",
    TextColor3 = Config.Colors.White,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, UI.Side)

Corner(UI.Search, 8)
Stroke(UI.Search, Color3.fromRGB(255, 255, 255), 0.82)

UI.Scan = Create("TextButton", {
    Name = "ScanButton",
    LayoutOrder = 7,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    ClipsDescendants = true
}, UI.Side)

Corner(UI.Scan, 11)

UI.ScanGradient = Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Colors.Accent),
        ColorSequenceKeypoint.new(0.5, Config.Colors.Violet),
        ColorSequenceKeypoint.new(1, Config.Colors.Accent)
    }),
    Rotation = 0
}, UI.Scan)

UI.ScanStroke = Stroke(UI.Scan, Color3.fromRGB(255, 255, 255), 0.35, 1.5)
UI.ScanScale = Create("UIScale", {Scale = 1}, UI.Scan)

UI.Shimmer = Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0.22, 0, 2.4, 0),
    Position = UDim2.new(-0.4, 0, 0.5, 0),
    Rotation = 20,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.8,
    BorderSizePixel = 0,
    ZIndex = 2
}, UI.Scan)

UI.ScanLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "◉  TRA NGAY",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
    ZIndex = 3
}, UI.Scan)

UI.TestButton = Button(UI.Side, {
    LayoutOrder = 8,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Config.Colors.Green,
    BackgroundTransparency = 0.55,
    Text = "TỰ TEST",
    TextColor3 = Config.Colors.White,
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, 9)

UI.ResetButton = Button(UI.Side, {
    LayoutOrder = 9,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Config.Colors.Red,
    BackgroundTransparency = 0.6,
    Text = "XÓA DỮ LIỆU",
    TextColor3 = Config.Colors.White,
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, 9)

UI.List = Create("ScrollingFrame", {
    Name = "PlayerList",
    Size = UDim2.new(0.66, -4, 1, 0),
    Position = UDim2.new(0.34, 4, 0, 0),
    BackgroundColor3 = Config.Colors.Glass,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Config.Colors.Accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, UI.Body)

Glass(UI.List, 14, false)

Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, UI.List)

Create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8)
}, UI.List)

UI.Empty = Create("TextLabel", {
    LayoutOrder = 100000,
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Text = "Chưa có người chơi khác trong server.",
    TextColor3 = Config.Colors.Gray,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    Visible = false
}, UI.List)

UI.Floating = Create("TextButton", {
    Name = "ScannerIcon",
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(0, 14, 0.5, 0),
    BackgroundColor3 = Config.Colors.Black,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "◉",
    TextColor3 = Config.Colors.Accent,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    Visible = false
}, UI.Gui)

Corner(UI.Floating, 24)
Stroke(UI.Floating, Config.Colors.Accent, 0.2, 1.5)
Hover(UI.Floating, 0.2, 0)
local function PlayScream()
    local id = Config.ScreamId ~= "" and Config.ScreamId or Config.FallbackSoundId

    for _, speed in ipairs({1, 0.75}) do
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = id
            sound.Volume = Config.ScreamVolume
            sound.PlaybackSpeed = speed
            sound.Parent = SoundService
            sound:Play()
            Debris:AddItem(sound, 8)
        end)
    end
end

local function SetVisible(visible)
    if State.Destroyed then
        return
    end

    PlayScream()

    UI.Floating.Visible = not visible
    UI.Main.Visible = visible

    if visible then
        UI.Scale.Scale = 0.88

        TweenService:Create(
            UI.Scale,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end
end

local function Ripple()
    local circle = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 2
    }, UI.Scan)

    Corner(circle, 999)

    TweenService:Create(
        circle,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 1}
    ):Play()

    Debris:AddItem(circle, 0.6)
end

local function AddLine(parent, text, color, size, order)
    local line = Create("TextLabel", {
        LayoutOrder = order,
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = color,
        TextSize = size,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, parent)

    Corner(line, 8)
    Stroke(line, color, 0.75)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    }, line)

    return line
end

local function RenderDetails()
    local details = UI.Details

    if not details or not details.Panel.Parent then
        return
    end

    local player = details.Player
    local data = ViewData(player)
    local active = data.Scanned and data.Score >= Config.HackThreshold
    local lines = {}

    local function Push(text, color, size)
        table.insert(lines, {Text = text, Color = color, Size = size})
    end

    details.Info.Text = "Tốc độ gần nhất: " .. FormatNumber(data.Speed) .. "  |  Đỉnh: " .. FormatNumber(data.PeakSpeed)
        .. " studs/s  |  Mẫu hợp lệ: " .. data.Clean .. "/" .. data.Samples
        .. "  |  Bỏ qua: xe " .. data.Skip.Ride .. ", nền di chuyển " .. data.Skip.Platform
        .. ", trạng thái đặc biệt " .. data.Skip.State .. ", vừa hồi sinh " .. data.Skip.Grace
        .. ", vật đẩy của game " .. data.Skip.Mover

    if data.Scanning then
        Push("Đang quan sát người chơi này, kết quả và cơ sở kết luận sẽ hiện khi quét xong.", Config.Colors.Yellow, 11)
    elseif not data.Scanned then
        Push("Chưa quét người chơi này. Bấm TRA ở danh sách hoặc TRA NGAY để bắt đầu.", Config.Colors.Gray, 11)
    else
        Push("Điểm nghi vấn: " .. data.Score .. "%  |  " .. data.Status, GetColor(data.Score), 12)

        if active then
            Push("ĐANG SỬ DỤNG HACK: " .. HackSummary(data), Config.Colors.Red, 12)
        else
            Push("Chưa đủ cơ sở để kết luận người này dùng hack.", Config.Colors.Green, 11)
        end

        local index = 0

        for _, evidence in ipairs(data.Details) do
            if evidence.Confirmed then
                if evidence.Known then
                    Push(
                        "◆ " .. evidence.Name .. "\nCơ sở kết luận: " .. evidence.Text .. "\nMức xác nhận: " .. evidence.Count .. "/" .. evidence.Need .. " lần đo (đã đủ ngưỡng)",
                        GetColor(evidence.Weight * 2),
                        10
                    )
                else
                    index += 1
                    Push(
                        "◇ Dấu hiệu bất thường #" .. index .. " (loại hack không xác định)\nCơ sở: " .. evidence.Text .. "\nMức xác nhận: " .. evidence.Count .. "/" .. evidence.Need .. " lần đo (đã đủ ngưỡng)",
                        Config.Colors.Yellow,
                        10
                    )
                end
            end
        end

        for _, evidence in ipairs(data.Details) do
            if not evidence.Confirmed then
                Push(
                    "… Chưa đủ xác nhận (không tính điểm): " .. evidence.Name .. " (" .. evidence.Count .. "/" .. evidence.Need .. ")\n" .. evidence.Text,
                    Config.Colors.Gray,
                    9
                )
            end
        end

        for _, note in ipairs(data.Notes) do
            Push("ℹ " .. note, Config.Colors.Accent, 9)
        end
    end

    Push(
        "Lưu ý: đây là dữ liệu quan sát từ client, cần đối chiếu với cơ chế của game trước khi xử lý người chơi.",
        Config.Colors.Gray,
        10
    )

    local parts = {}

    for _, line in ipairs(lines) do
        table.insert(parts, line.Text)
    end

    local signature = table.concat(parts, "\n")

    if signature == details.Signature then
        return
    end

    details.Signature = signature

    for _, child in ipairs(details.List:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for index, line in ipairs(lines) do
        AddLine(details.List, line.Text, line.Color, line.Size, index)
    end
end

local function ShowDetails(player)
    if UI.Details and UI.Details.Panel.Parent then
        UI.Details.Panel:Destroy()
    end

    local panel = Create("Frame", {
        Name = "DetailsPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0.95, 0, 0.93, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20
    }, UI.Main)

    Glass(panel, 14, true)

    Create("TextLabel", {
        Size = UDim2.new(1, -56, 0, 18),
        Position = UDim2.fromOffset(12, 6),
        BackgroundTransparency = 1,
        Text = "PHÂN TÍCH: " .. player.DisplayName .. " (@" .. player.Name .. ")",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, panel)

    local info = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.fromOffset(12, 24),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.Gray,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, panel)

    local exit = Button(panel, {
        Size = UDim2.fromOffset(30, 28),
        Position = UDim2.new(1, -38, 0, 6),
        BackgroundColor3 = Config.Colors.Red,
        BackgroundTransparency = 0.4,
        Text = "X",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, 7)

    local list = Create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -64),
        Position = UDim2.fromOffset(10, 56),
        BackgroundColor3 = Config.Colors.Glass,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Colors.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, panel)

    Corner(list, 10)

    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6)
    }, list)

    UI.Details = {Panel = panel, Info = info, List = list, Player = player, Signature = nil}

    exit.MouseButton1Click:Connect(function()
        panel:Destroy()
        UI.Details = nil
    end)

    RenderDetails()
end

local function StopSpectating()
    State.Spectating = nil

    local camera = Workspace.CurrentCamera

    if camera then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        camera.CameraSubject = humanoid or State.CameraSubject
        camera.CameraType = Enum.CameraType.Custom
    end
end

local function Spectate(player)
    if State.Spectating == player then
        StopSpectating()
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = Workspace.CurrentCamera

    if not humanoid or not camera then
        UI.ProgressText.Text = "Không thể quan sát người chơi này."
        return
    end

    if not State.Spectating then
        State.CameraSubject = camera.CameraSubject
    end

    State.Spectating = player
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    UI.ProgressText.Text = "ĐANG QUAN SÁT: " .. player.Name
end

local RequestScan = nil

local function CreatePlayerRow(player)
    if Rows[player] then
        return Rows[player]
    end

    local row = Create("Frame", {
        Name = "Player_" .. player.UserId,
        Size = UDim2.new(1, -4, 0, 112),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0
    }, UI.List)

    Glass(row, 12, false)

    local avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(42, 42),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Config.Colors.Glass,
        Image = "",
        BorderSizePixel = 0
    }, row)

    Corner(avatar, 21)

    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)

        if ok and avatar.Parent then
            avatar.Image = image
        end
    end)

    local name = Create("TextLabel", {
        Size = UDim2.new(1, -150, 0, 18),
        Position = UDim2.fromOffset(58, 6),
        BackgroundTransparency = 1,
        Text = player.DisplayName,
        TextColor3 = Config.Colors.White,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local percent = Create("TextLabel", {
        Size = UDim2.fromOffset(80, 18),
        Position = UDim2.new(1, -88, 0, 6),
        BackgroundTransparency = 1,
        Text = "--",
        TextColor3 = Config.Colors.Gray,
        TextSize = 14,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Right
    }, row)

    local status = Create("TextLabel", {
        Size = UDim2.new(1, -68, 0, 14),
        Position = UDim2.fromOffset(58, 25),
        BackgroundTransparency = 1,
        Text = "CHƯA QUÉT",
        TextColor3 = Config.Colors.Gray,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local bar = Create("Frame", {
        Size = UDim2.new(1, -68, 0, 6),
        Position = UDim2.fromOffset(58, 43),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0
    }, row)

    Corner(bar, 5)

    local fill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Config.Colors.Green,
        BorderSizePixel = 0
    }, bar)

    Corner(fill, 5)

    local tags = Create("TextLabel", {
        Size = UDim2.new(1, -68, 0, 28),
        Position = UDim2.fromOffset(58, 53),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.Gray,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local detail = Button(row, {
        Size = UDim2.fromOffset(70, 22),
        Position = UDim2.fromOffset(58, 85),
        BackgroundColor3 = Config.Colors.Accent,
        BackgroundTransparency = 0.45,
        Text = "CHI TIẾT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 6)

    local observe = Button(row, {
        Size = UDim2.fromOffset(78, 22),
        Position = UDim2.fromOffset(134, 85),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.4,
        Text = "QUAN SÁT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 6)

    local scan = Button(row, {
        Size = UDim2.fromOffset(56, 22),
        Position = UDim2.fromOffset(218, 85),
        BackgroundColor3 = Config.Colors.Violet,
        BackgroundTransparency = 0.35,
        Text = "TRA",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 6)

    detail.MouseButton1Click:Connect(function()
        ShowDetails(player)
    end)

    observe.MouseButton1Click:Connect(function()
        Spectate(player)
    end)

    scan.MouseButton1Click:Connect(function()
        if RequestScan then
            RequestScan({player}, true)
        end
    end)

    Rows[player] = {
        Row = row,
        Stroke = row:FindFirstChildOfClass("UIStroke"),
        Name = name,
        Status = status,
        Percent = percent,
        Fill = fill,
        Tags = tags,
        Observe = observe,
        LastScore = -1
    }

    return Rows[player]
end

local function UpdatePlayerRow(player)
    local ui = Rows[player]

    if not ui then
        return
    end

    local data = ViewData(player)
    local score = data.Score
    local active = data.Scanned and score >= Config.HackThreshold
    local color = GetColor(score)

    ui.Name.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
    ui.Status.Text = data.Status

    if data.Scanning then
        ui.Status.TextColor3 = Config.Colors.Yellow
        ui.Percent.Text = "..."
        ui.Percent.TextColor3 = Config.Colors.Accent
        ui.Tags.Text = "Đang quan sát, kết luận sau khi quét xong..."
        ui.Tags.TextColor3 = Config.Colors.Gray
        score = 0
    elseif not data.Scanned then
        ui.Status.TextColor3 = Config.Colors.Gray
        ui.Percent.Text = "--"
        ui.Percent.TextColor3 = Config.Colors.Gray
        ui.Tags.Text = "Chưa quét. Bấm TRA để kiểm tra người này."
        ui.Tags.TextColor3 = Config.Colors.Gray
        score = 0
    else
        ui.Status.TextColor3 = active and color or Config.Colors.Gray
        ui.Percent.Text = score .. "%"
        ui.Percent.TextColor3 = color

        if active then
            ui.Tags.Text = "Đang dùng: " .. HackSummary(data)
            ui.Tags.TextColor3 = Config.Colors.Red
        else
            ui.Tags.Text = "Không phát hiện phần mềm hack"
            ui.Tags.TextColor3 = Config.Colors.Gray
        end
    end

    if ui.LastScore ~= score then
        ui.LastScore = score

        TweenService:Create(ui.Fill, TweenInfo.new(0.25), {
            Size = UDim2.new(score / 100, 0, 1, 0),
            BackgroundColor3 = color
        }):Play()

        if ui.Stroke then
            ui.Stroke.Color = active and color or Color3.fromRGB(255, 255, 255)
            ui.Stroke.Transparency = active and 0.35 or 0.84
        end
    end

    ui.Row.LayoutOrder = -score
    ui.Observe.Text = State.Spectating == player and "DỪNG XEM" or "QUAN SÁT"
end

local function RefreshPlayers()
    local total = 0
    local hackers = 0
    local keyword = string.lower(UI.Search.Text)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            total += 1

            local data = ViewData(player)
            Recompute(data)

            if data.Scanned and data.Score >= Config.HackThreshold then
                hackers += 1
            end

            local ui = CreatePlayerRow(player)
            UpdatePlayerRow(player)

            ui.Row.Visible = string.find(
                string.lower(player.Name .. " " .. player.DisplayName),
                keyword,
                1,
                true
            ) ~= nil
        end
    end

    UI.PlayerCount.Text = "NGƯỜI CHƠI: " .. total
    UI.SuspiciousCount.Text = "CÓ DÙNG HACK: " .. hackers
    UI.SuspiciousCount.TextColor3 = hackers > 0 and Config.Colors.Red or Config.Colors.Gray
    UI.Empty.Visible = total == 0
end
local function SetProgress(percent, message)
    TweenService:Create(UI.ProgressFill, TweenInfo.new(0.15), {
        Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
    }):Play()

    if message then
        UI.ProgressText.Text = message
    end
end

local function CollectTargets()
    local list = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player)
        end
    end

    return list
end

local function CountPeers(pool, player, field, threshold)
    local count = 0

    for other, otherData in pairs(pool) do
        if other ~= player and otherData[field] >= threshold then
            count += 1
        end
    end

    return count
end

local function Drop(data, id, note)
    data.Evidence[id] = nil
    table.insert(data.Notes, note)
end

local function ApplyPeerRules(targets, pool)
    for _, player in ipairs(targets) do
        local data = Data[player]

        if data then
            local speed = data.Evidence.SPEED

            if speed and speed.Count >= speed.Need then
                local peers = CountPeers(pool, player, "PeakSpeed", data.PeakSpeed * Config.PeerRatio)

                if peers >= Config.PeerCount then
                    Drop(data, "SPEED", "Đã loại bỏ kết luận Speed Hack: có " .. peers .. " người chơi khác cũng đạt tốc độ tương tự (≥ " .. FormatNumber(data.PeakSpeed * Config.PeerRatio) .. " studs/s), nhiều khả năng là nút tăng tốc hoặc cơ chế của game.")
                end
            end

            local jump = data.Evidence.INFJUMP

            if jump and jump.Count >= jump.Need then
                local peers = CountPeers(pool, player, "AirJumpMax", 3)

                if peers >= Config.PeerCount then
                    Drop(data, "INFJUMP", "Đã loại bỏ kết luận Infinite Jump: có " .. peers .. " người chơi khác cũng nhảy nhiều lần trên không, nhiều khả năng là cơ chế game.")
                end
            end

            local aura = data.Evidence.KILLAURA

            if aura and aura.Count >= aura.Need then
                local peers = CountPeers(pool, player, "AuraBursts", 1)

                if peers >= 1 then
                    Drop(data, "KILLAURA", "Đã loại bỏ kết luận Kill Aura: có người chơi khác cũng gây sát thương diện rộng, nhiều khả năng là kỹ năng của game.")
                end
            end
        end
    end
end

local function RunSession(targets, single)
    if State.Scanning or State.Destroyed then
        if not State.Destroyed then
            UI.ProgressText.Text = "Đang có phiên quét, vui lòng đợi xong."
        end

        return
    end

    if #targets == 0 then
        UI.ScanState.Text = "KHÔNG CÓ NGƯỜI CHƠI"
        UI.ScanState.TextColor3 = Config.Colors.Gray
        SetProgress(100, "Không tìm thấy người chơi khác.")
        return
    end

    State.Scanning = true
    State.Generation += 1

    local generation = State.Generation
    local targetSet = {}

    for _, player in ipairs(targets) do
        local previous = Data[player]
        local fresh = NewData()

        fresh.Grace = previous and previous.Grace or 0
        fresh.Scanning = true
        Data[player] = fresh
        targetSet[player] = true
    end

    State.Shadow = nil

    if single then
        State.Shadow = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not targetSet[player] then
                local shadow = NewData()
                local previous = Data[player]

                shadow.Grace = previous and previous.Grace or 0
                State.Shadow[player] = shadow
            end
        end
    end

    UI.ScanState.Text = single and "ĐANG TRA 1 NGƯỜI..." or "ĐANG TRA..."
    UI.ScanState.TextColor3 = Config.Colors.Yellow
    UI.ScanLabel.Text = "◌  ĐANG TRA..."

    local duration = Config.ScanDuration
    local passes = 0
    local started = os.clock()
    local lastCombat = 0
    local lastFilter = 0

    StartCombat()
    Safe(RefreshFilters)

    while not State.Destroyed and generation == State.Generation do
        local now = os.clock()
        local elapsed = now - started

        if elapsed >= duration then
            break
        end

        if now - lastFilter >= 0.5 then
            lastFilter = now
            Safe(RefreshFilters)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Parent == Players then
                Safe(ScanMotion, player)
            end
        end

        if now - lastCombat >= Config.CombatInterval then
            lastCombat = now
            Safe(AnalyzeCombat)
        end

        if passes < Config.StaticPasses and elapsed >= passes * (duration - 2) / Config.StaticPasses then
            passes += 1
            State.StaticBusy += 1

            task.spawn(function()
                for _, player in ipairs(targets) do
                    if player.Parent == Players then
                        RunStatic(player)
                    end
                end

                State.StaticBusy -= 1
            end)
        end

        SetProgress(elapsed / duration * 100, "Đang quan sát " .. math.floor(elapsed) .. "/" .. duration .. "s | hãy để người chơi di chuyển bình thường")
        task.wait(Config.SampleInterval)
    end

    StopCombat()

    local waited = 0

    while State.StaticBusy > 0 and waited < 4 do
        task.wait(0.1)
        waited += 0.1
    end

    local cancelled = State.Destroyed or generation ~= State.Generation
    local pool = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local poolData = (State.Shadow and State.Shadow[player]) or Data[player]

            if poolData then
                pool[player] = poolData
            end
        end
    end

    State.Shadow = nil

    if not cancelled then
        ApplyPeerRules(targets, pool)
    end

    local flagged = 0

    for _, player in ipairs(targets) do
        local data = Data[player]

        if data then
            data.Scanning = false

            if not cancelled then
                data.Scanned = true
                data.LastScan = os.clock()
            end

            Recompute(data)

            if data.Scanned and data.Score >= Config.HackThreshold then
                flagged += 1
            end
        end
    end

    State.Scanning = false

    if State.Destroyed then
        return
    end

    UI.ScanLabel.Text = "◉  TRA NGAY"

    if cancelled then
        UI.ScanState.Text = "ĐÃ HỦY"
        UI.ScanState.TextColor3 = Config.Colors.Gray
        SetProgress(0, "Phiên quét đã bị hủy.")
    else
        UI.ScanState.Text = "HOÀN TẤT"
        UI.ScanState.TextColor3 = Config.Colors.Green
        SetProgress(100, "Quét xong | " .. #targets .. " người | có dùng hack: " .. flagged)
    end

    Safe(RefreshPlayers)
end

RequestScan = function(targets, single)
    task.spawn(RunSession, targets, single)
end

local function SelfTest()
    if State.Destroyed or State.Scanning then
        return
    end

    local tests = {}

    local function Check(name, condition)
        table.insert(tests, {Name = name, Ok = condition == true})
    end

    local dummy = {}

    Check("Quét chuyển động", type(ScanMotion) == "function")
    Check("Quét thuộc tính", type(RunStatic) == "function")
    Check("Phân tích chiến đấu", type(AnalyzeCombat) == "function")

    AddEvidence(dummy, "SELFTEST", 60, 1, "test")
    local testData = GetData(dummy)
    Recompute(testData)
    Check("Bộ chấm điểm", testData.Score >= Config.HackThreshold)
    Data[dummy] = nil

    Check("Giao diện", UI.Gui.Parent ~= nil and UI.List.Parent == UI.Body)
    Check("Camera", Workspace.CurrentCamera ~= nil)
    Check("Probe", Probe.Parent ~= nil)
    Check("Âm thanh", SoundService ~= nil)

    Check("Raycast", (pcall(function()
        return Workspace:Raycast(Vector3.new(0, 500, 0), Vector3.new(0, -1, 0), GroundParams)
    end)))

    Check("Vùng chồng lấn", (pcall(function()
        return Workspace:GetPartsInPart(Probe, WallParams)
    end)))

    local passed = 0
    local failed = {}

    for _, test in ipairs(tests) do
        if test.Ok then
            passed += 1
        else
            table.insert(failed, test.Name)
        end
    end

    if passed == #tests then
        UI.ScanState.Text = "TEST ĐẠT"
        UI.ScanState.TextColor3 = Config.Colors.Green
        SetProgress(100, "Hệ thống: " .. passed .. "/" .. #tests .. " kiểm tra đạt")
    else
        UI.ScanState.Text = "TEST LỖI"
        UI.ScanState.TextColor3 = Config.Colors.Red
        SetProgress(passed / #tests * 100, "Lỗi: " .. table.concat(failed, ", "))
    end
end

local function ResetAll()
    State.Generation += 1

    for key in pairs(Data) do
        Data[key] = nil
    end

    for index = 1, RingSize do
        DamageRing[index] = nil
    end

    Floor.Y = nil
    Floor.Samples = 0
    Baseline.LocalSpeed = 0
    Baseline.History = {}

    Safe(RefreshPlayers)
    SetProgress(0, "Đã xóa dữ liệu quét.")
end

local function Shutdown()
    if State.Destroyed then
        return
    end

    PlayScream()

    State.Destroyed = true
    State.Generation += 1
    StopSpectating()
    StopCombat()

    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end

    Probe:Destroy()
    UI.Gui:Destroy()
end

local function Tween(object, time, properties)
    TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

Track(UI.Scan.MouseEnter:Connect(function()
    Tween(UI.ScanScale, 0.18, {Scale = 1.04})
end))

Track(UI.Scan.MouseLeave:Connect(function()
    Tween(UI.ScanScale, 0.18, {Scale = 1})
end))

Track(UI.Scan.MouseButton1Down:Connect(function()
    Tween(UI.ScanScale, 0.08, {Scale = 0.95})
    Ripple()
end))

Track(UI.Scan.MouseButton1Up:Connect(function()
    Tween(UI.ScanScale, 0.15, {Scale = 1.04})
end))

Track(UI.Scan.MouseButton1Click:Connect(function()
    RequestScan(CollectTargets(), false)
end))

Track(UI.TestButton.MouseButton1Click:Connect(function()
    Safe(SelfTest)
end))

Track(UI.ResetButton.MouseButton1Click:Connect(ResetAll))

Track(UI.Search:GetPropertyChangedSignal("Text"):Connect(function()
    Safe(RefreshPlayers)
end))

Track(UI.Minimize.MouseButton1Click:Connect(function()
    SetVisible(false)
end))

Track(UI.Floating.MouseButton1Click:Connect(function()
    SetVisible(true)
end))

Track(UI.Close.MouseButton1Click:Connect(Shutdown))

Track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or State.Destroyed then
        return
    end

    if input.KeyCode == Config.ToggleKey then
        SetVisible(not UI.Main.Visible)
    end
end))

Track(Players.PlayerAdded:Connect(function(player)
    ViewData(player)
    WatchPlayer(player)

    task.delay(1, function()
        if not State.Destroyed and player.Parent == Players then
            Safe(RefreshPlayers)
        end
    end)
end))

Track(Players.PlayerRemoving:Connect(function(player)
    if State.Spectating == player then
        StopSpectating()
    end

    if UI.Details and UI.Details.Player == player then
        UI.Details.Panel:Destroy()
        UI.Details = nil
    end

    if Rows[player] then
        Rows[player].Row:Destroy()
        Rows[player] = nil
    end

    Data[player] = nil

    task.defer(function()
        if not State.Destroyed then
            Safe(RefreshPlayers)
        end
    end)
end))

Track(LocalPlayer.CharacterAdded:Connect(function(character)
    StopSpectating()
    task.wait(0.5)
    State.CameraSubject = character:FindFirstChildOfClass("Humanoid")
end))

local Dragging = false
local DragStart = nil
local StartPosition = nil
local DragInput = nil

Track(UI.Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = UI.Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end))

Track(UI.Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end))

Track(UserInputService.InputChanged:Connect(function(input)
    if Dragging and input == DragInput then
        local delta = input.Position - DragStart

        UI.Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end))

local Angle = 0
local Clock = 0
local Sweep = 0

Track(RunService.RenderStepped:Connect(function(dt)
    if State.Destroyed or not UI.Main.Visible then
        return
    end

    local scanning = State.Scanning

    Angle = (Angle + dt * (scanning and 240 or 40)) % 360
    Clock += dt
    Sweep = (Sweep + dt * (scanning and 1.2 or 0.4)) % 1.8

    UI.ScanGradient.Rotation = Angle
    UI.ScanStroke.Transparency = 0.4 + 0.3 * math.sin(Clock * (scanning and 6 or 3))
    UI.Shimmer.Position = UDim2.new(Sweep - 0.4, 0, 0.5, 0)
end))

task.spawn(function()
    while not State.Destroyed do
        Safe(RefreshFilters)
        Safe(SampleLocal)
        task.wait(0.2)
    end
end)

task.spawn(function()
    while not State.Destroyed do
        Safe(RefreshPlayers)

        if UI.Details then
            Safe(RenderDetails)
        end

        if State.Spectating then
            if State.Spectating.Parent ~= Players then
                StopSpectating()
            else
                local character = State.Spectating.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local camera = Workspace.CurrentCamera

                if humanoid and camera and camera.CameraSubject ~= humanoid then
                    camera.CameraSubject = humanoid
                end
            end
        end

        task.wait(Config.UIInterval)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    WatchPlayer(player)
end

Safe(RefreshFilters)
Safe(RefreshPlayers)

print(Config.Title .. " " .. Config.Version .. " READY")
