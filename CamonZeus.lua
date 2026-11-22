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

local Parts = {}

local Config = {
    Title = "TIẾT LỘ NGƯỜI SỬ DỤNG PHẦN MỀM GIAN LẬN",
    Version = "V7.0",
    SampleInterval = 0.1,
    CombatInterval = 0.2,
    UIInterval = 0.4,
    ScanDuration = 45,
    StaticPasses = 8,
    StaticNeed = 5,
    MinMoved = 50,
    HackThreshold = 20,
    MaxDetails = 40,
    SpawnGrace = 3,
    SeatGrace = 2,
    SoftStateGrace = 2.5,
    SpeedFloor = 26,
    SpeedMultiplier = 1.3,
    SpeedBonus = 3,
    SpeedWindow = 0.7,
    SpeedStreak = 3,
    SpeedNeed = 12,
    BaselineRatio = 1.1,
    BaselineCap = 90,
    PeerRatio = 0.9,
    PeerCount = 6,
    JumpPeerCount = 3,
    PeerBorderline = 1.35,
    FlingSpeed = 250,
    FlingNear = 20,
    SpinFlingNear = 14,
    TeleportLimit = 60,
    TeleportElapsed = 0.35,
    TeleportNeed = 3,
    AirGap = 4,
    FlightTime = 3,
    FlightNeed = 16,
    FlightFallSpeed = -12,
    HoverVelocity = 4,
    HoverTime = 2,
    AirJumpRatio = 0.5,
    AirJumpPerAir = 2,
    AirJumpNeed = 2,
    SuperJumpMargin = 1.8,
    SpinAngular = 22,
    SpinTurnSample = 1,
    SpinWindow = 10,
    SpinHits = 8,
    SpinNeed = 5,
    TiltDot = 0.5,
    TiltNeed = 80,
    JitterDistance = 4,
    JitterNeed = 16,
    UndergroundMargin = 25,
    UndergroundNeed = 20,
    FloorSamples = 30,
    NoclipInside = 3,
    NoclipNeed = 12,
    MeshNeed = 24,
    PathNeed = 6,
    AttributionRadius = 60,
    AuraRadius = 24,
    AuraTargets = 3,
    AuraWindow = 0.8,
    AuraNeed = 3,
    FarmWindow = 25,
    FarmKills = 8,
    KillBurstWindow = 6,
    KillBurst = 5,
    ReachSlack = 12,
    ReachNeed = 5,
    ReachHandle = 14,
    ReachOffset = 16,
    ClickWindow = 10,
    ClickHits = 8,
    ClickNeed = 5,
    ClickDamageWindow = 1.5,
    ClickDamageHits = 8,
    ToolWindow = 3,
    ToolSwitches = 10,
    ToolNeed = 3,
    BodyPartLimit = 8,
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
    Progress = 0,
    Spectating = nil,
    CameraSubject = nil,
    DamageCount = 0,
    DamageDirty = false,
    LastError = nil,
    Shadow = nil,
    StaticBusy = 0,
    SpecMode = "first",
    Hidden = {},
    OldFov = 70,
    WasVisible = nil
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
    SUPERJUMP = "Super Jump (nhảy cao bất thường)",
    INFJUMP = "Infinite Jump (nhảy vô hạn)",
    UNDERGROUND = "Underground (chui xuống đất)",
    NOCLIP = "Noclip (xuyên tường)",
    KILLAURA = "Kill Aura (đánh diện rộng)",
    AUTOKILL = "Auto Kill (tự động hạ người chơi)",
    AUTOFARM = "Auto Farm (tự động cày)",
    AUTOCLICK = "Auto Click (bấm đánh liên tục)",
    TOOLSPAM = "Tool Spam (đổi vũ khí liên tục)",
    TOOLMULTI = "Multi Tool (cầm nhiều vũ khí cùng lúc)",
    REACH = "Reach (tầm đánh dài)",
    HITBOX = "Hitbox Expander (nới rộng hitbox)"
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
        Moved = 0,
        Dirty = false,
        Skip = {Ride = 0, Platform = 0, Soft = 0, Grace = 0, State = 0},
        Evidence = {},
        Details = {},
        Known = {},
        Unknown = 0,
        Notes = {},
        Streak = {},
        History = {},
        Kills = {},
        PlayerKills = {},
        Teleports = {},
        HitTimes = {},
        ToolLast = nil,
        ToolSwitches = {},
        ClickHist = {},
        ClickPrev = {},
        SpinHist = {},
        AirJumps = 0,
        AirJumpLast = 0,
        AirJumpMax = 0,
        AirJumpFlag = false,
        AirFlag = false,
        GainMax = 0,
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
        SoftSince = nil,
        Speed = 0,
        PeakSpeed = 0,
        Allowed = 0,
        Gap = 0,
        Spin = 0,
        SpinUntil = 0,
        AuraBursts = 0,
        AuraStamp = 0,
        KillStamp = 0,
        PKillStamp = 0,
        MoverCheck = 0,
        MoverFound = false,
        MoverClass = nil,
        MoverSince = nil,
        WaterCheck = 0,
        InWater = false
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
    data.SpinHist = {}
    data.ClickHist = {}
    data.ClickPrev = {}
    data.SoftSince = nil
    data.MoverSince = nil
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
                if not seen[evidence.Name] and evidence.Weight >= 18 then
                    seen[evidence.Name] = true
                    table.insert(known, evidence.Name)
                end
            elseif evidence.Weight >= 18 then
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
    elseif (data.Moved or 0) < Config.MinMoved then
        data.Status = "CHƯA ĐỦ DỮ LIỆU - QUÉT LẠI"
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

    if #parts == 0 then
        return "Hack không xác định"
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

local PathParams = RaycastParams.new()
PathParams.FilterType = Enum.RaycastFilterType.Exclude
PathParams.IgnoreWater = true
PathParams.RespectCanCollide = true

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
    PathParams.FilterDescendantsInstances = list
    WallParams.FilterDescendantsInstances = list
end

Parts[1] = true
assert(Parts and Parts[1], "[CheatReveal] Thiếu PHẦN 1/13, hãy dán đủ theo thứ tự từ phần 1")

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
                    Nearest = nil,
                    Distance = 0,
                    Clear = false,
                    IsPlayer = false,
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

local function Trim(list, now, life)
    while #list > 0 and now - list[1] > life do
        table.remove(list, 1)
    end
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

    if #actors == 0 then
        return
    end

    local groups = {}
    local touched = {}

    for index = 1, RingSize do
        local event = DamageRing[index]

        if event and now - event.Time <= Config.FarmWindow then
            if event.Nearest == nil then
                local best = nil
                local bestDistance = Config.AttributionRadius + 1
                local second = math.huge

                for _, actor in ipairs(actors) do
                    if actor.Humanoid ~= event.Humanoid then
                        local distance = (actor.Root.Position - event.Position).Magnitude

                        if distance < bestDistance then
                            if best then
                                second = bestDistance
                            end

                            best = actor
                            bestDistance = distance
                        elseif distance < second then
                            second = distance
                        end
                    end
                end

                if best and bestDistance <= Config.AttributionRadius then
                    event.Nearest = best.Player
                    event.Distance = bestDistance
                    event.Clear = second > bestDistance * 1.4 + 6
                else
                    event.Nearest = false
                end

                local model = event.Humanoid.Parent
                event.IsPlayer = model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
            end

            local attacker = event.Nearest
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

                    if event.IsPlayer and event.Clear then
                        table.insert(data.PlayerKills, event.Time)
                    end
                end

                if not event.Checked then
                    event.Checked = true

                    local tool = actor.Tool

                    if event.Clear and tool and IsMelee(tool) then
                        table.insert(data.HitTimes, event.Time)
                        touched[attacker] = true

                        local handle = tool:FindFirstChild("Handle")

                        if handle and handle:IsA("BasePart") then
                            local handleSize = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
                            local limit = handleSize + Config.ReachSlack
                            local distance = (event.Position - actor.Root.Position).Magnitude

                            if distance > limit then
                                AddEvidence(
                                    attacker,
                                    "REACH_DAMAGE",
                                    45,
                                    Config.ReachNeed,
                                    "Gây sát thương ở cách " .. FormatNumber(distance) .. " studs với vũ khí cận chiến '" .. tool.Name .. "' (tầm hợp lệ khoảng " .. FormatNumber(limit) .. "); người này là người gần nạn nhân nhất và vượt trội so với người thứ hai nên không nhầm sang người khác"
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    for player in pairs(touched) do
        local data = GetData(player)
        Trim(data.HitTimes, now, Config.ClickDamageWindow)

        if #data.HitTimes >= Config.ClickDamageHits then
            AddEvidence(
                player,
                "AUTOCLICK",
                45,
                Config.ClickNeed,
                #data.HitTimes .. " lần gây sát thương cận chiến trong " .. FormatNumber(Config.ClickDamageWindow) .. "s, nhanh hơn tốc độ bấm của người thật"
            )
            data.HitTimes = {}
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

            if count >= Config.AuraTargets and (behind >= 2 or (unarmed and count >= 4) or count >= 5) then
                data.AuraBursts += 1

                AddEvidence(
                    player,
                    "KILLAURA",
                    45,
                    Config.AuraNeed,
                    count .. " mục tiêu cùng nhận sát thương trong " .. FormatNumber(Config.AuraWindow) .. "s quanh người này, " .. behind .. " mục tiêu ở sau lưng" .. (unarmed and ", không cầm vũ khí" or "") .. " (lần thứ " .. data.AuraBursts .. ")"
                )
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local data = GetData(player)

            Trim(data.Kills, now, Config.FarmWindow)
            Trim(data.PlayerKills, now, Config.KillBurstWindow)
            Trim(data.Teleports, now, 40)

            local newest = data.Kills[#data.Kills]

            if newest and newest > data.KillStamp then
                data.KillStamp = newest

                if #data.Kills >= Config.FarmKills and #data.Teleports >= 2 then
                    AddEvidence(
                        player,
                        "AUTOFARM",
                        55,
                        1,
                        "Hạ " .. #data.Kills .. " mục tiêu trong " .. Config.FarmWindow .. "s, kèm " .. #data.Teleports .. " lần dịch chuyển tức thời giữa các mục tiêu"
                    )
                end
            end

            local playerNewest = data.PlayerKills[#data.PlayerKills]

            if playerNewest and playerNewest > data.PKillStamp then
                data.PKillStamp = playerNewest

                if #data.PlayerKills >= Config.KillBurst then
                    AddEvidence(
                        player,
                        "AUTOKILL",
                        45,
                        2,
                        "Hạ " .. #data.PlayerKills .. " người chơi trong " .. Config.KillBurstWindow .. "s, mỗi lần đều xác định rõ người này là người gần nạn nhân nhất"
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
        data.ToolLast = nil
        data.ToolSwitches = {}
        data.Grace = os.clock() + Config.SpawnGrace
    end

    if player.Character then
        OnCharacter()
    end

    Track(player.CharacterAdded:Connect(OnCharacter))
end

Parts[2] = true
assert(Parts and Parts[2], "[CheatReveal] Thiếu PHẦN 2/13, hãy dán đủ theo thứ tự")

local HardStates = {
    [Enum.HumanoidStateType.Climbing] = true,
    [Enum.HumanoidStateType.Swimming] = true,
    [Enum.HumanoidStateType.Seated] = true,
    [Enum.HumanoidStateType.Dead] = true
}

local SoftStates = {
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.PlatformStanding] = true,
    [Enum.HumanoidStateType.Physics] = true,
    [Enum.HumanoidStateType.GettingUp] = true
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
    "glide", "glider", "parachute", "wing", "jetpack", "hover", "broom",
    "carpet", "heli", "rocket", "cloud", "balloon", "umbrella"
}

local ActionPriority = {
    [Enum.AnimationPriority.Action] = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true
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
        Baseline.LocalSpeed * Config.BaselineRatio
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

local function SolidKind(part, root)
    if not part:IsA("BasePart") or part:IsA("TrussPart") then
        return nil
    end

    if not part.CanCollide or not part.Anchored then
        return nil
    end

    if part:GetAttribute("ACAllowed") then
        return nil
    end

    if part:IsA("Terrain") then
        if Collides(root, part) then
            return "terrain"
        end

        return nil
    end

    if part.Size.Magnitude < 1.2 then
        return nil
    end

    if not Collides(root, part) then
        return nil
    end

    if part:IsA("MeshPart") or part:IsA("UnionOperation") then
        local fidelity = part.CollisionFidelity

        if fidelity == Enum.CollisionFidelity.Box or fidelity == Enum.CollisionFidelity.PreciseConvexDecomposition then
            return "part"
        end

        return "mesh"
    end

    return "part"
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
        return data.MoverFound, data.MoverClass
    end

    data.MoverCheck = now

    local found = false
    local class = nil

    for _, descendant in ipairs(character:GetDescendants()) do
        if MoverClasses[descendant.ClassName] then
            found = true
            class = descendant.ClassName
            break
        end
    end

    data.MoverFound = found
    data.MoverClass = class

    return found, class
end

local function HasAirTool(character)
    local tool = character:FindFirstChildOfClass("Tool")

    if not tool then
        return false
    end

    local lower = string.lower(tool.Name)

    for _, word in ipairs(AirToolWords) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end

    return false
end

local function InWater(data, position, now)
    if now - data.WaterCheck < 1 then
        return data.InWater
    end

    data.WaterCheck = now
    data.InWater = false

    pcall(function()
        local region = Region3.new(position - Vector3.new(3, 4, 3), position + Vector3.new(3, 2, 3)):ExpandToGrid(4)
        local materials = Workspace.Terrain:ReadVoxels(region, 4)

        for x = 1, #materials do
            for y = 1, #materials[x] do
                for z = 1, #materials[x][y] do
                    if materials[x][y][z] == Enum.Material.Water then
                        data.InWater = true
                        return
                    end
                end
            end
        end
    end)

    return data.InWater
end

local function LearnFloor(gap, hit, trusted)
    if not gap or gap > Config.AirGap or not hit or not hit.Instance.Anchored then
        return
    end

    local y = hit.Position.Y

    if not Floor.Y then
        Floor.Y = y
        Floor.Samples = 1
        return
    end

    Floor.Samples += 1

    if y < Floor.Y and (trusted or y >= Floor.Y - Config.UndergroundMargin) then
        Floor.Y = y
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

    LearnFloor(gap, hit, true)

    local grounded = gap ~= nil and gap <= Config.AirGap and hit ~= nil and hit.Instance.Anchored

    if seated or attached or HardStates[state] or SoftStates[state] or not grounded then
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
            Baseline.LocalSpeed = math.min(speed, Config.BaselineCap)
        else
            Baseline.LocalSpeed = math.max(speed, Baseline.LocalSpeed * 0.9995)
        end
    end
end

local function MonitorTool(player, data, character, humanoid, now)
    local tool = character:FindFirstChildOfClass("Tool")

    if tool ~= data.ToolLast then
        if data.ToolLast ~= nil or tool ~= nil then
            table.insert(data.ToolSwitches, now)
        end

        data.ToolLast = tool
    end

    Trim(data.ToolSwitches, now, Config.ToolWindow)

    if #data.ToolSwitches >= Config.ToolSwitches then
        AddEvidence(
            player,
            "TOOLSPAM",
            42,
            Config.ToolNeed,
            "Cầm và cất vũ khí " .. #data.ToolSwitches .. " lần trong " .. Config.ToolWindow .. "s (người bình thường hiếm khi đổi nhanh như vậy)"
        )
        data.ToolSwitches = {}
    end

    local hit = false

    if tool then
        local animator = humanoid:FindFirstChildOfClass("Animator")

        if animator then
            local ok, tracks = pcall(animator.GetPlayingAnimationTracks, animator)

            if ok then
                local seen = {}

                for _, track in ipairs(tracks) do
                    if ActionPriority[track.Priority] and not track.Looped then
                        seen[track] = true

                        local previous = data.ClickPrev[track]
                        local position = track.TimePosition

                        if previous == nil or position < previous - 0.005 then
                            hit = true
                        end

                        data.ClickPrev[track] = position
                    end
                end

                for track in pairs(data.ClickPrev) do
                    if not seen[track] then
                        data.ClickPrev[track] = nil
                    end
                end
            end
        end
    else
        data.ClickPrev = {}
    end

    table.insert(data.ClickHist, hit and 1 or 0)

    while #data.ClickHist > Config.ClickWindow do
        table.remove(data.ClickHist, 1)
    end

    if #data.ClickHist >= Config.ClickWindow then
        local total = 0

        for _, value in ipairs(data.ClickHist) do
            total += value
        end

        if total >= Config.ClickHits and tool then
            AddEvidence(
                player,
                "AUTOCLICK",
                45,
                Config.ClickNeed,
                "Phát lại hoạt ảnh đánh " .. total .. "/" .. Config.ClickWindow .. " lần đo liên tiếp (khoảng " .. FormatNumber(Config.ClickWindow * Config.SampleInterval) .. "s) khi đang cầm '" .. tool.Name .. "', nhanh hơn người thật"
            )
            data.ClickHist = {}
        end
    end
end

Parts[3] = true
assert(Parts and Parts[3], "[CheatReveal] Thiếu PHẦN 3/13, hãy dán đủ theo thứ tự")

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

    Safe(MonitorTool, player, data, character, humanoid, now)

    local state = humanoid:GetState()
    local seated = humanoid.SeatPart ~= nil or humanoid.Sit
    local attached = false
    local assemblyRoot = root.AssemblyRootPart

    if assemblyRoot and assemblyRoot ~= root and not assemblyRoot:IsDescendantOf(character) then
        attached = true
    end

    local hard = seated or attached or HardStates[state] == true
    local soft = SoftStates[state] == true or humanoid.PlatformStand

    if soft then
        data.SoftSince = data.SoftSince or now
    else
        data.SoftSince = nil
    end

    local softExempt = soft and (now - data.SoftSince) < Config.SoftStateGrace

    if seated or attached then
        data.Grace = math.max(data.Grace, now + Config.SeatGrace)
        data.Skip.Ride += 1
    elseif hard then
        data.Skip.State += 1
    elseif softExempt then
        data.Skip.Soft += 1
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
                    4,
                    "Người chơi " .. player.Name .. " bị hất đi " .. FormatNumber(instant) .. " studs/s khi đang xoay sát người này (" .. FormatNumber(spinnerDistance) .. " studs)",
                    2
                )
            end
        end
    end

    local grace = now < data.Grace
    local clean = not grace and not hard and not softExempt
    local gap = nil
    local hit = nil

    if not hard then
        gap, hit = GroundGap(humanoid, root, 400)
        data.Gap = gap or -1
    end

    if not clean then
        if grace and not hard and not softExempt then
            data.Skip.Grace += 1
        end

        data.History = {}
        data.Streak = {}
        data.AirStart = nil
        data.PrevClean = false
        data.LastDelta = nil
        data.LastVy = 0
        return
    end

    local platform = false

    if hit and gap and gap <= Config.AirGap then
        local part = hit.Instance

        if not part.Anchored or part.AssemblyLinearVelocity.Magnitude > 1.5 then
            platform = true
            data.Skip.Platform += 1
        end
    end

    data.Clean += 1
    LearnFloor(gap, hit, false)

    local jumpLimit = math.max(MaxJump(humanoid), 7)
    local currentVy = 0

    if last and prevClean and elapsed > 0 then
        currentVy = (position.Y - last.Y) / elapsed
    end

    if not platform and last and prevClean and elapsed > 0 and elapsed <= Config.TeleportElapsed then
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

    if span >= Config.SpeedWindow * 0.7 then
        local dx = position.X - first.Position.X
        local dz = position.Z - first.Position.Z
        speed = math.sqrt(dx * dx + dz * dz) / span
        windowVy = (position.Y - first.Position.Y) / span
    end

    data.Speed = speed

    if speed > 3 then
        data.Moved = (data.Moved or 0) + 1
    end

    if speed > data.PeakSpeed then
        data.PeakSpeed = speed
    end

    local allowed = AllowedSpeed(humanoid)
    data.Allowed = allowed

    local mover, moverClass = HasMover(data, character, now)

    if mover then
        data.MoverSince = data.MoverSince or now
    else
        data.MoverSince = nil
    end

    local moverNote = mover and ("; có vật đẩy " .. tostring(moverClass) .. " gắn trên nhân vật (có thể do game, nhưng cũng là cách script hack hay dùng)") or ""

    if data.MoverSince and now - data.MoverSince > 4 then
        AddEvidence(
            player,
            "ANOM_MOVER",
            12,
            20,
            "Vật đẩy " .. tostring(moverClass) .. " gắn liên tục trên nhân vật hơn 4 giây (dấu hiệu phụ)"
        )
    end

    if not platform and Streak(data, "speed", speed > allowed) >= Config.SpeedStreak then
        AddEvidence(
            player,
            "SPEED",
            45,
            Config.SpeedNeed,
            "Chạy ngang " .. FormatNumber(speed) .. " studs/s (trung bình " .. FormatNumber(span) .. "s), vượt mức cho phép " .. FormatNumber(allowed) .. " (WalkSpeed hiển thị " .. FormatNumber(humanoid.WalkSpeed) .. ", tốc độ hợp lệ đã học từ bạn " .. FormatNumber(Baseline.LocalSpeed) .. "); nhanh nhất " .. FormatNumber(data.PeakSpeed) .. " studs/s, vượt liên tục " .. data.Streak.speed .. " lần đo; không ngồi xe, không đứng trên nền di chuyển, không vừa hồi sinh" .. moverNote,
            speed > allowed * 1.8 and 2 or 1
        )
    end

    local airborne = gap == nil or gap > Config.AirGap

    if airborne then
        if not data.AirStart then
            data.AirStart = now
            data.AirStartY = position.Y
            data.AirMaxY = position.Y
            data.AirJumps = 0
            data.AirJumpLast = now
            data.AirJumpFlag = false
            data.AirFlag = false
        end

        data.AirMaxY = math.max(data.AirMaxY, position.Y)

        local airTime = now - data.AirStart
        local gain = data.AirMaxY - data.AirStartY

        if gain > data.GainMax then
            data.GainMax = gain
        end

        if not HasAirTool(character) and not (airTime >= 1.5 and InWater(data, position, now)) then
            local falling = windowVy < Config.FlightFallSpeed
            local fly = airTime >= Config.FlightTime and not falling
            local hover = Streak(data, "hover", airTime >= Config.HoverTime and math.abs(windowVy) <= Config.HoverVelocity) >= 4

            if fly or hover then
                AddEvidence(
                    player,
                    "FLY",
                    50,
                    Config.FlightNeed,
                    "Ở trên không liên tục " .. FormatNumber(airTime) .. "s, cách đất " .. (gap and FormatNumber(gap) or "rất xa") .. " studs, vận tốc dọc trung bình " .. FormatNumber(windowVy) .. " studs/s (nhảy hoặc rơi bình thường không thể giữ độ cao quá " .. FormatNumber(Config.FlightTime) .. "s), đã lên cao " .. FormatNumber(gain) .. " studs, tầm nhảy tối đa " .. FormatNumber(jumpLimit) .. "; không ngồi xe, không bơi, không cầm đồ bay của game" .. moverNote
                )
            end

            if gain > jumpLimit * Config.SuperJumpMargin + 3 and not data.AirFlag and airTime < Config.FlightTime then
                data.AirFlag = true

                AddEvidence(
                    player,
                    "SUPERJUMP",
                    45,
                    2,
                    "Nhảy lên cao " .. FormatNumber(gain) .. " studs trong một lần nhảy, tầm nhảy tối đa của nhân vật " .. FormatNumber(jumpLimit) .. " studs"
                )
            end
        end

        if last and prevClean and elapsed > 0 and now - data.AirJumpLast >= 0.3 and airTime >= 0.35 then
            local kick = currentVy - data.LastVy + Workspace.Gravity * elapsed

            if kick > JumpVelocity(humanoid) * Config.AirJumpRatio and currentVy > 12 then
                data.AirJumps += 1
                data.AirJumpLast = now
                data.AirJumpMax = math.max(data.AirJumpMax, data.AirJumps)

                if data.AirJumps >= Config.AirJumpPerAir and not data.AirJumpFlag then
                    data.AirJumpFlag = true

                    AddEvidence(
                        player,
                        "INFJUMP",
                        45,
                        Config.AirJumpNeed,
                        "Bật nhảy thêm " .. data.AirJumps .. " lần khi đang trên không (lực bật +" .. FormatNumber(kick) .. " studs/s so với rơi tự do)"
                    )
                end
            end
        end
    else
        data.AirStart = nil
        data.Streak.hover = 0
    end

    local angular = root.AssemblyAngularVelocity.Magnitude
    local turn = 0

    if lastLook and prevClean then
        local a = Vector3.new(look.X, 0, look.Z)
        local b = Vector3.new(lastLook.X, 0, lastLook.Z)

        if a.Magnitude > 0.2 and b.Magnitude > 0.2 then
            turn = math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1))
        end
    end

    data.Spin = math.max(angular, turn / math.max(elapsed, 0.05))

    table.insert(data.SpinHist, (turn > Config.SpinTurnSample or angular > Config.SpinAngular) and 1 or 0)

    while #data.SpinHist > Config.SpinWindow do
        table.remove(data.SpinHist, 1)
    end

    if #data.SpinHist >= Config.SpinWindow then
        local total = 0

        for _, value in ipairs(data.SpinHist) do
            total += value
        end

        if total >= Config.SpinHits then
            data.SpinUntil = now + 1.5
            data.SpinHist = {}

            AddEvidence(
                player,
                "SPIN",
                40,
                Config.SpinNeed,
                "Thân xoay liên tục: " .. total .. "/" .. Config.SpinWindow .. " lần đo liên tiếp có góc quay lớn (vận tốc góc " .. FormatNumber(angular) .. " rad/s), không ngồi xe, không bị hất"
            )

            local near, distance = NearestOther(player, position, Config.SpinFlingNear)

            if near then
                AddEvidence(
                    player,
                    "FLING",
                    50,
                    4,
                    "Xoay tốc độ cao sát người chơi " .. near.Name .. " (cách " .. FormatNumber(distance) .. " studs)"
                )
            end
        end
    end

    local upDot = root.CFrame.UpVector.Y

    if Streak(data, "tilt", upDot < Config.TiltDot) >= 1 then
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
                "Vị trí rung lắc đảo chiều liên tục (" .. FormatNumber(a) .. " rồi " .. FormatNumber(b) .. " studs mỗi lần đo theo hướng ngược nhau)"
            )
        end
    end

    data.LastDelta = delta

    local floorKnown = Floor.Y ~= nil and Floor.Samples >= Config.FloorSamples

    if floorKnown
        and gap == nil
        and position.Y < Floor.Y - Config.UndergroundMargin
        and position.Y > Workspace.FallenPartsDestroyHeight + 20
        and windowVy > -25 then

        AddEvidence(
            player,
            "UNDERGROUND",
            50,
            Config.UndergroundNeed,
            "Ở độ cao Y " .. FormatNumber(position.Y) .. ", thấp hơn mặt sàn thấp nhất đã đo (" .. FormatNumber(Floor.Y) .. ") tới " .. FormatNumber(Floor.Y - position.Y) .. " studs, bên dưới không có vật đỡ nhưng không rơi (vận tốc dọc " .. FormatNumber(windowVy) .. ")"
        )
    end

    Probe.CFrame = CFrame.new(position)

    local insidePart = nil
    local insideMesh = nil
    local ok, parts = pcall(Workspace.GetPartsInPart, Workspace, Probe, WallParams)

    if ok then
        for _, part in ipairs(parts) do
            local kind = SolidKind(part, root)

            if kind == "part" then
                insidePart = part
                break
            elseif kind == "mesh" and not insideMesh then
                insideMesh = part
            end
        end
    end

    if Streak(data, "inside", insidePart ~= nil) >= Config.NoclipInside and insidePart then
        AddEvidence(
            player,
            "NOCLIP_INSIDE",
            50,
            Config.NoclipNeed,
            "Tâm nhân vật nằm trong vật thể đặc '" .. insidePart.Name .. "' (cố định, va chạm bật, đúng nhóm va chạm) liên tục " .. data.Streak.inside .. " lần đo, vật lý bình thường không cho phép"
        )
    end

    if not insidePart and Streak(data, "insidemesh", insideMesh ~= nil) >= Config.NoclipInside and insideMesh then
        AddEvidence(
            player,
            "NOCLIP_MESH",
            45,
            Config.MeshNeed,
            "Tâm nhân vật nằm trong vật thể dạng mesh '" .. insideMesh.Name .. "' liên tục " .. data.Streak.insidemesh .. " lần đo (mesh kém chính xác hơn nên cần số lần xác nhận cao hơn)"
        )
    end

    if delta and elapsed <= 0.25 and not platform then
        local distance = delta.Magnitude

        if distance > 0.8 and distance < 20 then
            local result = Workspace:Raycast(last, delta, PathParams)

            if result and SolidKind(result.Instance, root) then
                AddEvidence(
                    player,
                    "NOCLIP_PATH",
                    40,
                    Config.PathNeed,
                    "Đi xuyên qua '" .. result.Instance.Name .. "' khi di chuyển " .. FormatNumber(distance) .. " studs trong " .. FormatNumber(elapsed * 1000) .. "ms mà không có đường đi vòng"
                )
            end
        end
    end

    data.LastVy = currentVy
    data.PrevClean = true
end

Parts[4] = true
assert(Parts and Parts[4], "[CheatReveal] Thiếu PHẦN 4/13, hãy dán đủ theo thứ tự")

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
            12,
            Config.StaticNeed,
            "Thuộc tính Humanoid bất thường: " .. table.concat(found, ", ") .. " (chỉ là dấu hiệu phụ, có thể do cơ chế game)"
        )
    end

    local large = {}
    local head = character:FindFirstChild("Head")
    local headSize = 0

    if head and head:IsA("BasePart") then
        headSize = math.max(head.Size.X, head.Size.Y, head.Size.Z)
    end

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and not IsAllowed(part, character) then
            local size = math.max(part.Size.X, part.Size.Y, part.Size.Z)
            local ratio = part == root and headSize > 0 and size > 5 and size > headSize * 3.2

            if size > Config.BodyPartLimit or ratio then
                table.insert(large, "'" .. part.Name .. "' " .. FormatNumber(size) .. " studs")
            end
        end
    end

    if #large > 0 then
        AddEvidence(
            player,
            "HITBOX_SIZE",
            38,
            Config.StaticNeed,
            "Bộ phận cơ thể lớn bất thường: " .. table.concat(large, ", ") .. " (giới hạn " .. Config.BodyPartLimit .. " studs, đầu " .. FormatNumber(headSize) .. " studs)"
        )
    end
end

local function ScanTools(player)
    local character, _, root = GetParts(player)

    if not character then
        return
    end

    local tools = 0

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            tools += 1
        end
    end

    if tools > 1 then
        AddEvidence(
            player,
            "TOOLMULTI",
            18,
            Config.StaticNeed,
            "Đang cầm cùng lúc " .. tools .. " vũ khí/công cụ (một số game cho phép nên chỉ là dấu hiệu phụ)"
        )
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
            "REACH_HANDLE",
            38,
            Config.StaticNeed,
            "Vũ khí kéo dài bất thường: " .. table.concat(found, "; ")
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
            20,
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

Parts[5] = true
assert(Parts and Parts[5], "[CheatReveal] Thiếu PHẦN 5/13, hãy dán đủ theo thứ tự")

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
    Text = Config.Version .. "  •  CHỈ QUÉT KHI BẠN BẤM  •  17 LOẠI HACK  •  QUÉT SÂU " .. Config.ScanDuration .. " GIÂY",
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
    Text = "Chưa quét. Bấm TRA NGAY để quét mọi người, hoặc TRA ở từng người (khoảng " .. Config.ScanDuration .. " giây).",
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
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 14, 0.5, 0),
    BackgroundColor3 = Config.Colors.Black,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "◉",
    TextColor3 = Config.Colors.Accent,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    Visible = false,
    ZIndex = 50
}, UI.Gui)

Corner(UI.Floating, 26)
Stroke(UI.Floating, Config.Colors.Accent, 0.15, 1.5)
Hover(UI.Floating, 0.15, 0)

Parts[6] = true
assert(Parts and Parts[6], "[CheatReveal] Thiếu PHẦN 6/13, hãy dán đủ theo thứ tự")

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

    details.Info.Text = "Tốc độ: " .. FormatNumber(data.Speed) .. " (đỉnh " .. FormatNumber(data.PeakSpeed)
        .. ")  |  Cho phép: " .. FormatNumber(data.Allowed) .. "  |  Chuẩn của bạn: " .. FormatNumber(Baseline.LocalSpeed)
        .. "  |  Mẫu: " .. data.Clean .. "/" .. data.Samples .. "  |  Đã chạy: " .. (data.Moved or 0)
        .. "  |  Bỏ qua: xe " .. data.Skip.Ride .. ", nền " .. data.Skip.Platform
        .. ", ngã " .. data.Skip.Soft .. ", leo/bơi " .. data.Skip.State .. ", hồi sinh " .. data.Skip.Grace

    if data.Scanning then
        Push("Đang quan sát người chơi này, kết quả và cơ sở kết luận sẽ hiện khi quét xong.", Config.Colors.Yellow, 11)
    elseif not data.Scanned then
        Push("Chưa quét người chơi này. Bấm TRA để bắt đầu.", Config.Colors.Gray, 11)
    else
        Push("Điểm nghi vấn: " .. data.Score .. "%  |  " .. data.Status, GetColor(data.Score), 12)

        if active then
            Push("ĐANG SỬ DỤNG HACK: " .. HackSummary(data), Config.Colors.Red, 12)
        elseif (data.Moved or 0) < Config.MinMoved then
            Push("Chưa đủ dữ liệu: người này chưa chạy đủ lâu trong lúc quét. Hãy quét lại khi họ đang di chuyển.", Config.Colors.Yellow, 11)
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
                elseif evidence.Weight >= 18 then
                    index += 1
                    Push(
                        "◇ Dấu hiệu bất thường #" .. index .. " (loại hack không xác định)\nCơ sở: " .. evidence.Text .. "\nMức xác nhận: " .. evidence.Count .. "/" .. evidence.Need .. " lần đo (đã đủ ngưỡng)",
                        Config.Colors.Yellow,
                        10
                    )
                else
                    Push(
                        "◇ Dấu hiệu phụ (tính thêm vào điểm)\nCơ sở: " .. evidence.Text .. "\nMức xác nhận: " .. evidence.Count .. "/" .. evidence.Need,
                        Config.Colors.Gray,
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

    local floating = State.Spectating ~= nil

    local panel = Create("Frame", {
        Name = "DetailsPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = floating and UDim2.new(0.7, 0, 0.6, 0) or UDim2.new(0.95, 0, 0.93, 0),
        Position = floating and UDim2.new(0.5, 0, 0.68, 0) or UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = floating and 55 or 20
    }, floating and UI.Gui or UI.Main)

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

    UI.Details = {Panel = panel, Info = info, List = list, Player = player, Signature = nil, Floating = floating}

    exit.MouseButton1Click:Connect(function()
        panel:Destroy()

        if UI.Details and UI.Details.Panel == panel then
            UI.Details = nil
        end
    end)

    RenderDetails()
end

Parts[7] = true
assert(Parts and Parts[7], "[CheatReveal] Thiếu PHẦN 7/13, hãy dán đủ theo thứ tự")

local Sim = {
    Panel = nil,
    Player = nil,
    Pos = nil,
    Conns = {},
    ShowOff = false,
    Collapsed = false,
    Stamp = nil,
    Ui = nil,
    Toggles = setmetatable({}, {__mode = "k"})
}

local RequestScan = nil
local StopSpectating = nil
local Spec = {Bar = nil}

function Spec.Hide(character)
    for _, child in ipairs(character:GetChildren()) do
        local part = nil

        if child.Name == "Head" and child:IsA("BasePart") then
            part = child
        elseif child:IsA("Accessory") then
            part = child:FindFirstChild("Handle")
        end

        if part and part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
            State.Hidden[part] = true
        end
    end
end

function Spec.Unhide()
    for part in pairs(State.Hidden) do
        if part.Parent then
            part.LocalTransparencyModifier = 0
        end

        State.Hidden[part] = nil
    end
end

function Spec.Apply()
    local player = State.Spectating
    local camera = Workspace.CurrentCamera

    if not player or not camera then
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        pcall(function()
            LocalPlayer.ReplicationFocus = root
        end)
    end

    if State.SpecMode == "third" and humanoid then
        Spec.Unhide()
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

function Spec.Step()
    local player = State.Spectating
    local camera = Workspace.CurrentCamera

    if not player or not camera or State.SpecMode ~= "first" then
        return
    end

    local character = player.Character
    local head = character and character:FindFirstChild("Head")

    if not head or not head:IsA("BasePart") then
        return
    end

    Spec.Hide(character)

    local target = head.CFrame * CFrame.new(0, 0.1, -0.7)

    if camera.CameraType ~= Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = target
    else
        camera.CFrame = camera.CFrame:Lerp(target, 0.5)
    end

    camera.FieldOfView = 80
end

function Spec.GetBar()
    if Spec.Bar then
        return Spec.Bar
    end

    local frame = Create("Frame", {
        Name = "SpectateBar",
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(360, 114),
        Position = UDim2.new(0.5, 0, 0, 8),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 60
    }, UI.Gui)

    Glass(frame, 14, true)

    local title = Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, frame)

    local info = Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.fromOffset(10, 25),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.Gray,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, frame)

    local view = Button(frame, {
        Size = UDim2.fromOffset(108, 26),
        Position = UDim2.fromOffset(10, 46),
        BackgroundColor3 = Config.Colors.Accent,
        BackgroundTransparency = 0.4,
        Text = "GÓC: THỨ NHẤT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 7)

    local previous = Button(frame, {
        Size = UDim2.fromOffset(40, 26),
        Position = UDim2.fromOffset(124, 46),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.35,
        Text = "◀",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, 7)

    local forward = Button(frame, {
        Size = UDim2.fromOffset(40, 26),
        Position = UDim2.fromOffset(170, 46),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.35,
        Text = "▶",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, 7)

    local stop = Button(frame, {
        Size = UDim2.fromOffset(134, 26),
        Position = UDim2.fromOffset(216, 46),
        BackgroundColor3 = Config.Colors.Red,
        BackgroundTransparency = 0.4,
        Text = "DỪNG XEM",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 7)

    local simButton = Button(frame, {
        Size = UDim2.fromOffset(108, 26),
        Position = UDim2.fromOffset(10, 78),
        BackgroundColor3 = Config.Colors.Red,
        BackgroundTransparency = 0.5,
        Text = "Check",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 7)

    local scanButton = Button(frame, {
        Size = UDim2.fromOffset(86, 26),
        Position = UDim2.fromOffset(124, 78),
        BackgroundColor3 = Config.Colors.Violet,
        BackgroundTransparency = 0.4,
        Text = "TRA",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 7)

    local detailButton = Button(frame, {
        Size = UDim2.fromOffset(134, 26),
        Position = UDim2.fromOffset(216, 78),
        BackgroundColor3 = Config.Colors.Accent,
        BackgroundTransparency = 0.5,
        Text = "CHI TIẾT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, 7)

    view.MouseButton1Click:Connect(function()
        State.SpecMode = State.SpecMode == "first" and "third" or "first"
        Spec.Unhide()
        view.Text = State.SpecMode == "first" and "GÓC: THỨ NHẤT" or "GÓC: THỨ BA"

        local camera = Workspace.CurrentCamera

        if camera and State.SpecMode == "third" then
            camera.CameraType = Enum.CameraType.Custom
            camera.FieldOfView = State.OldFov
        end

        Spec.Apply()
    end)

    previous.MouseButton1Click:Connect(function()
        Spec.Next(-1)
    end)

    forward.MouseButton1Click:Connect(function()
        Spec.Next(1)
    end)

    stop.MouseButton1Click:Connect(function()
        StopSpectating()
    end)

    simButton.MouseButton1Click:Connect(function()
        local target = State.Spectating

        if not target then
            return
        end

        if Sim.Panel and Sim.Player == target then
            Sim.Close()
        else
            Safe(Sim.Show, target)
        end
    end)

    scanButton.MouseButton1Click:Connect(function()
        local target = State.Spectating

        if target and target.Parent == Players and RequestScan then
            RequestScan({target}, true)
        end
    end)

    detailButton.MouseButton1Click:Connect(function()
        local target = State.Spectating

        if not target then
            return
        end

        local details = UI.Details

        if details and details.Player == target and details.Panel.Parent then
            details.Panel:Destroy()
            UI.Details = nil
        else
            Safe(ShowDetails, target)
        end
    end)

    Spec.Bar = {
        Frame = frame,
        Title = title,
        Info = info,
        View = view,
        Sim = simButton,
        Scan = scanButton,
        Detail = detailButton
    }

    return Spec.Bar
end

function Spec.Begin(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = Workspace.CurrentCamera

    if not humanoid or not camera then
        UI.ProgressText.Text = "Không thể quan sát " .. player.Name .. " (chưa có nhân vật)."
        return false
    end

    if not State.Spectating then
        State.CameraSubject = camera.CameraSubject
        State.OldFov = camera.FieldOfView
        State.WasVisible = UI.Main.Visible
        RunService:BindToRenderStep("CheatRevealSpectate", Enum.RenderPriority.Camera.Value + 1, Spec.Step)
    end

    Spec.Unhide()
    State.Spectating = player
    State.SpecMode = "first"

    local bar = Spec.GetBar()
    bar.Frame.Visible = true
    bar.View.Text = "GÓC: THỨ NHẤT"
    bar.Title.Text = "ĐANG QUAN SÁT: " .. player.DisplayName .. " (@" .. player.Name .. ")"

    camera.CameraType = Enum.CameraType.Scriptable
    Spec.Apply()

    UI.Main.Visible = false
    UI.Floating.Visible = true
    UI.ProgressText.Text = "ĐANG QUAN SÁT: " .. player.Name

    if Sim.Panel then
        Safe(Sim.Show, player)
    end

    if UI.Details and UI.Details.Panel.Parent then
        Safe(ShowDetails, player)
    end

    return true
end

function Spec.Next(step)
    local list = {}

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= LocalPlayer then
            table.insert(list, other)
        end
    end

    if #list == 0 then
        StopSpectating()
        return
    end

    table.sort(list, function(a, b)
        return a.Name < b.Name
    end)

    local index = table.find(list, State.Spectating) or 0
    local count = #list

    for _ = 1, count do
        index = (index - 1 + step) % count + 1

        if Spec.Begin(list[index]) then
            return
        end
    end
end

function Spec.Update()
    local player = State.Spectating

    if not player then
        return
    end

    if player.Parent ~= Players then
        StopSpectating()
        return
    end

    Spec.Apply()

    local bar = Spec.Bar

    if not bar then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local data = ViewData(player)
    local speed = 0

    if root and root:IsA("BasePart") then
        local velocity = root.AssemblyLinearVelocity
        speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    end

    local verdict = data.Scanned and data.Status or "CHƯA QUÉT"

    bar.Info.Text = "Tốc độ ngang: " .. FormatNumber(speed) .. " studs/s  |  " .. verdict .. "  |  Điểm: " .. data.Score .. "%"

    local simOpen = Sim.Panel ~= nil and Sim.Player == player
    local details = UI.Details
    local detailOpen = details ~= nil and details.Player == player and details.Panel.Parent ~= nil

    bar.Sim.Text = simOpen and "ĐÓNG QUAN SÁT" or "CHECK KĨ"
    bar.Detail.Text = detailOpen and "ĐÓNG CHI TIẾT" or "CHI TIẾT"
    bar.Scan.Text = State.Scanning and ("QUÉT " .. math.floor(State.Progress) .. "%") or "TRA"
end

StopSpectating = function()
    local was = State.Spectating ~= nil

    State.Spectating = nil
    State.SpecMode = "first"

    if not was then
        return
    end

    pcall(function()
        RunService:UnbindFromRenderStep("CheatRevealSpectate")
    end)

    Spec.Unhide()

    pcall(function()
        LocalPlayer.ReplicationFocus = nil
    end)

    if Spec.Bar then
        Spec.Bar.Frame.Visible = false
    end

    if UI.Details and UI.Details.Floating then
        UI.Details.Panel:Destroy()
        UI.Details = nil
    end

    local camera = Workspace.CurrentCamera

    if camera then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid or State.CameraSubject
        camera.FieldOfView = State.OldFov
    end

    if State.WasVisible ~= nil and not State.Destroyed then
        UI.Main.Visible = State.WasVisible
        UI.Floating.Visible = not State.WasVisible
    end

    State.WasVisible = nil
end

local function Spectate(player)
    if State.Spectating == player then
        StopSpectating()
        return
    end

    Spec.Begin(player)
end

Parts[8] = true
assert(Parts and Parts[8], "[CheatReveal] Thiếu PHẦN 8/13, hãy dán đủ theo thứ tự")

Sim.Features = {
    {"SPEED", "Speed Hack"},
    {"FLY", "Fly"},
    {"NOCLIP", "Noclip"},
    {"TELEPORT", "Teleport"},
    {"INFJUMP", "Infinite Jump"},
    {"SUPERJUMP", "Super Jump"},
    {"UNDERGROUND", "Underground"},
    {"KILLAURA", "Kill Aura"},
    {"AUTOKILL", "Auto Kill"},
    {"AUTOCLICK", "Auto Click"},
    {"REACH", "Reach"},
    {"HITBOX", "Hitbox Expander"},
    {"TOOLSPAM", "Tool Spam"},
    {"TOOLMULTI", "Multi Tool"},
    {"AUTOFARM", "Auto Farm"},
    {"SPIN", "Spin"},
    {"FLING", "Fling"}
}

function Sim.Close()
    for _, connection in ipairs(Sim.Conns) do
        connection:Disconnect()
    end

    table.clear(Sim.Conns)

    if Sim.Panel then
        Sim.Pos = {X = Sim.Panel.Position.X.Offset, Y = Sim.Panel.Position.Y.Offset}
        Sim.Panel:Destroy()
    end

    Sim.Panel = nil
    Sim.Player = nil
    Sim.Ui = nil
    Sim.Stamp = nil
end

function Sim.Clamp(panel, width, height)
    local area = UI.Gui.AbsoluteSize
    local x = math.clamp(panel.Position.X.Offset, 0, math.max(area.X - width, 0))
    local y = math.clamp(panel.Position.Y.Offset, 0, math.max(area.Y - height, 0))

    panel.Position = UDim2.fromOffset(x, y)
end

function Sim.Value(key, evidence, data)
    if string.sub(key, 1, 6) == "HIDDEN" then
        return evidence.Text, nil
    elseif key == "SPEED" then
        local limit = math.max(data.Allowed, 1)
        return "tốc độ " .. FormatNumber(data.PeakSpeed) .. " / cho phép " .. FormatNumber(data.Allowed), math.clamp(data.PeakSpeed / (limit * 3), 0.08, 1)
    elseif key == "FLY" or key == "SUPERJUMP" then
        return "độ cao " .. FormatNumber(data.GainMax) .. " studs", nil
    end

    return "xác nhận " .. evidence.Count .. "/" .. evidence.Need, nil
end

function Sim.Counts()
    local ui = Sim.Ui

    if not ui then
        return
    end

    local on = 0

    for _, record in ipairs(ui.Rows) do
        if record.On then
            on += 1
        end
    end

    ui.OnLabel.Text = "ĐANG BẬT (" .. on .. ")"
    ui.OffLabel.Text = "ĐANG TẮT (" .. (#ui.Rows - on) .. ")"
end

function Sim.MakeRow(parent, index, entry, player, data, delay, states)
    local detected = entry.Evidence ~= nil
    local value = nil
    local fraction = nil

    if detected then
        value, fraction = Sim.Value(entry.Key, entry.Evidence, data)
    end

    local initial = states[entry.Key]

    if initial == nil then
        initial = detected
    end

    local row = Create("TextButton", {
        Size = UDim2.new(1, -2, 0, 24),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, parent)

    Corner(row, 7)

    local stroke = Stroke(row, Color3.fromRGB(255, 255, 255), 0.92)

    local name = Create("TextLabel", {
        Size = UDim2.new(1, -52, 0, 24),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = entry.Label,
        TextColor3 = Config.Colors.Gray,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local subText = "@" .. player.Name .. "  •   CHÍNH XÁC"

    if detected then
        subText = "@" .. player.Name .. "  •  " .. value
    end

    local sub = Create("TextLabel", {
        Size = UDim2.new(1, -52, 0, 12),
        Position = UDim2.fromOffset(8, 19),
        BackgroundTransparency = 1,
        Text = subText,
        TextColor3 = detected and Config.Colors.Orange or Config.Colors.Accent,
        TextSize = 8,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false
    }, row)

    local barBack = Create("Frame", {
        Size = UDim2.new(1, -60, 0, 4),
        Position = UDim2.fromOffset(8, 36),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Visible = false
    }, row)

    Corner(barBack, 3)

    local fill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Config.Colors.Red,
        BorderSizePixel = 0
    }, barBack)

    Corner(fill, 3)

    local track = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 4),
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = Color3.fromRGB(70, 74, 90),
        BorderSizePixel = 0
    }, row)

    Corner(track, 8)

    local knob = Create("Frame", {
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, track)

    Corner(knob, 6)

    local record = {On = false, Row = row}

    local function Apply(state, wait)
        record.On = state
        states[entry.Key] = state

        local height = 24

        if state then
            height = (detected and fraction) and 46 or 34
        end

        row.Size = UDim2.new(1, -2, 0, height)
        row.LayoutOrder = state and index or 500 + index
        row.BackgroundTransparency = state and 0.35 or 0.7
        row.Visible = state or Sim.ShowOff

        stroke.Color = state and (detected and Config.Colors.Red or Config.Colors.Accent) or Color3.fromRGB(255, 255, 255)
        stroke.Transparency = state and 0.3 or 0.92

        name.TextColor3 = state and Config.Colors.White or Config.Colors.Gray
        name.Size = UDim2.new(1, -52, 0, state and 16 or 24)
        name.Position = UDim2.fromOffset(8, state and 3 or 0)

        sub.Visible = state
        track.Position = UDim2.new(1, -8, 0, state and 8 or 4)

        local showBar = state and detected and fraction ~= nil

        barBack.Visible = showBar
        fill.Size = UDim2.new(0, 0, 1, 0)

        if showBar then
            task.delay(wait or 0, function()
                if fill.Parent then
                    TweenService:Create(
                        fill,
                        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = UDim2.new(fraction, 0, 1, 0)}
                    ):Play()
                end
            end)
        end
    end

    local function Knob(state, wait)
        local goalPosition = state and UDim2.fromOffset(16, 2) or UDim2.fromOffset(2, 2)
        local goalColor = state and Config.Colors.Green or Color3.fromRGB(70, 74, 90)

        task.delay(wait or 0, function()
            if knob.Parent then
                local info = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                TweenService:Create(knob, info, {Position = goalPosition}):Play()
                TweenService:Create(track, info, {BackgroundColor3 = goalColor}):Play()
            end
        end)
    end

    Apply(initial, delay)

    if initial then
        Knob(true, delay)
    end

    row.MouseButton1Click:Connect(function()
        Apply(not record.On, 0)
        Knob(record.On, 0)
        Sim.Counts()
    end)

    return record
end

function Sim.Show(player)
    Sim.Close()

    local data = ViewData(player)

    Sim.Stamp = tostring(data.Scanned) .. tostring(data.Scanning) .. tostring(data.LastScan)

    local states = Sim.Toggles[player]

    if not states or states.Stamp ~= data.LastScan then
        states = {Stamp = data.LastScan}
        Sim.Toggles[player] = states
    end

    local active = {}
    local hidden = {}
    local activeCount = 0

    if data.Scanned then
        for _, evidence in ipairs(data.Details) do
            if evidence.Confirmed and evidence.Weight >= 18 then
                local key = string.match(evidence.Id, "^%u+")

                if KnownHacks[key] then
                    local current = active[key]

                    if not current then
                        activeCount += 1
                    end

                    if not current or evidence.Count > current.Count then
                        active[key] = evidence
                    end
                else
                    table.insert(hidden, evidence)
                end
            end
        end

        if activeCount + #hidden == 0 and data.Score >= Config.HackThreshold then
            table.insert(hidden, {Text = "nhiều dấu hiệu phụ cộng dồn vượt " .. Config.HackThreshold .. "%", Count = 1, Need = 1})
        end
    end

    local entries = {}

    for _, feature in ipairs(Sim.Features) do
        if active[feature[1]] then
            table.insert(entries, {Key = feature[1], Label = feature[2], Evidence = active[feature[1]]})
        end
    end

    for index, evidence in ipairs(hidden) do
        table.insert(entries, {Key = "HIDDEN" .. index, Label = "Chức năng ẩn #" .. index, Evidence = evidence})
    end

    for _, feature in ipairs(Sim.Features) do
        if not active[feature[1]] then
            table.insert(entries, {Key = feature[1], Label = feature[2], Evidence = nil})
        end
    end

    local total = activeCount + #hidden
    local area = UI.Gui.AbsoluteSize
    local width = math.min(270, math.max(area.X - 16, 200))
    local maxHeight = math.min(300, math.max(area.Y - 16, 140))
    local height = 120
    local startX = math.max((area.X - width) / 2, 8)
    local startY = math.max((area.Y - maxHeight) / 2, 8)

    if State.Spectating then
        startX = math.max(area.X - width - 8, 8)
        startY = 126
    end

    if Sim.Pos then
        startX = Sim.Pos.X
        startY = Sim.Pos.Y
    end

    local panel = Create("Frame", {
        Name = "SimPanel",
        Size = UDim2.fromOffset(width, Sim.Collapsed and 38 or height),
        Position = UDim2.fromOffset(startX, startY),
        BackgroundColor3 = Config.Colors.Black,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 70
    }, UI.Gui)

    Glass(panel, 14, true)
    Sim.Clamp(panel, width, Sim.Collapsed and 38 or height)

    Sim.Panel = panel
    Sim.Player = player

    local header = Create("Frame", {
        Name = "SimHeader",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, panel)

    local avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(7, 6),
        BackgroundColor3 = Config.Colors.Glass,
        Image = "",
        BorderSizePixel = 0
    }, header)

    Corner(avatar, 13)

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

    local title = Create("TextLabel", {
        Size = UDim2.new(1, -106, 0, 14),
        Position = UDim2.fromOffset(40, 4),
        BackgroundTransparency = 1,
        Text = "SCRIPT HUB  •  LOẠI BỎ",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, header)

    Create("UIGradient", {
        Color = ColorSequence.new(Config.Colors.Violet, Config.Colors.Accent)
    }, title)

    Create("TextLabel", {
        Size = UDim2.new(1, -106, 0, 12),
        Position = UDim2.fromOffset(40, 19),
        BackgroundTransparency = 1,
        Text = "@" .. player.Name,
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, header)

    local collapse = Create("TextButton", {
        Size = UDim2.fromOffset(24, 22),
        Position = UDim2.new(1, -58, 0, 8),
        BackgroundColor3 = Config.Colors.Glass2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = Sim.Collapsed and "+" or "—",
        TextColor3 = Config.Colors.White,
        TextSize = 13,
        Font = Enum.Font.GothamBold
    }, header)

    Corner(collapse, 6)
    Stroke(collapse, Color3.fromRGB(255, 255, 255), 0.8)

    local close = Create("TextButton", {
        Size = UDim2.fromOffset(24, 22),
        Position = UDim2.new(1, -30, 0, 8),
        BackgroundColor3 = Config.Colors.Red,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "X",
        TextColor3 = Config.Colors.White,
        TextSize = 11,
        Font = Enum.Font.GothamBold
    }, header)

    Corner(close, 6)
    Stroke(close, Color3.fromRGB(255, 255, 255), 0.8)

    local list = Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -62),
        Position = UDim2.fromOffset(6, 40),
        BackgroundColor3 = Config.Colors.Glass,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Colors.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = not Sim.Collapsed
    }, panel)

    Corner(list, 9)

    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    }, list)

    local note = Create("TextLabel", {
        Size = UDim2.new(1, -12, 0, 14),
        Position = UDim2.new(0, 6, 1, -18),
        BackgroundTransparency = 1,
        Text = "Bật/tắt chỉ là Check, không ảnh hưởng người chơi.",
        TextColor3 = Config.Colors.Gray,
        TextSize = 8,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = not Sim.Collapsed
    }, panel)

    local statusText = "PHÁT HIỆN " .. total .. " HACK NGHIÊM TRỌNG"
    local statusColor = Config.Colors.Red

    if data.Scanning then
        statusText = "ĐANG QUÉT, CHỜ KẾT QUẢ..."
        statusColor = Config.Colors.Yellow
    elseif not data.Scanned then
        statusText = "CHƯA QUÉT (BẤM TRA), VẪN BẬT/TẮT THỬ ĐƯỢC"
        statusColor = Config.Colors.Gray
    elseif total == 0 then
        statusText = "KHÔNG CÓ HACK NÀO ĐƯỢC XÁC NHẬN"
        statusColor = Config.Colors.Green
    end

    Create("TextLabel", {
        LayoutOrder = 1,
        Size = UDim2.new(1, -2, 0, 16),
        BackgroundTransparency = 1,
        Text = statusText,
        TextColor3 = statusColor,
        TextSize = 9,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, list)

    local onHeader = Create("Frame", {
        LayoutOrder = 5,
        Size = UDim2.new(1, -2, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, list)

    local onLabel = Create("TextLabel", {
        Size = UDim2.new(1, -62, 1, 0),
        BackgroundTransparency = 1,
        Text = "ĐANG BẬT (0)",
        TextColor3 = Config.Colors.Red,
        TextSize = 10,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left
    }, onHeader)

    local reset = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(58, 16),
        Position = UDim2.new(1, -2, 0.5, 0),
        BackgroundColor3 = Config.Colors.Violet,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "ĐẶT LẠI",
        TextColor3 = Config.Colors.White,
        TextSize = 8,
        Font = Enum.Font.GothamBold
    }, onHeader)

    Corner(reset, 6)

    local offHeader = Create("Frame", {
        LayoutOrder = 500,
        Size = UDim2.new(1, -2, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, list)

    local offLabel = Create("TextLabel", {
        Size = UDim2.new(1, -62, 1, 0),
        BackgroundTransparency = 1,
        Text = "ĐANG TẮT (0)",
        TextColor3 = Config.Colors.Gray,
        TextSize = 10,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left
    }, offHeader)

    local offToggle = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(50, 16),
        Position = UDim2.new(1, -2, 0.5, 0),
        BackgroundColor3 = Config.Colors.Accent,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = Sim.ShowOff and "ẨN" or "HIỆN",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, offHeader)

    Corner(offToggle, 6)

    local ui = {Rows = {}, OnLabel = onLabel, OffLabel = offLabel}
    Sim.Ui = ui

    local delay = 0.2

    for index, entry in ipairs(entries) do
        local record = Sim.MakeRow(list, 10 + index, entry, player, data, delay, states)
        table.insert(ui.Rows, record)

        if record.On then
            delay += 0.12
        end
    end

    Sim.Counts()

    offToggle.MouseButton1Click:Connect(function()
        Sim.ShowOff = not Sim.ShowOff
        offToggle.Text = Sim.ShowOff and "ẨN" or "HIỆN"

        for _, record in ipairs(ui.Rows) do
            record.Row.Visible = record.On or Sim.ShowOff
        end
    end)

    reset.MouseButton1Click:Connect(function()
        Sim.Toggles[player] = nil
        Sim.Show(player)
    end)

    local function Fit()
        if not panel.Parent then
            return
        end

        height = math.clamp(40 + layout.AbsoluteContentSize.Y + 10 + 22, 110, maxHeight)

        if not Sim.Collapsed then
            panel.Size = UDim2.fromOffset(width, height)
            Sim.Clamp(panel, width, height)
        end
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Fit)
    task.defer(Fit)

    collapse.MouseButton1Click:Connect(function()
        Sim.Collapsed = not Sim.Collapsed
        list.Visible = not Sim.Collapsed
        note.Visible = not Sim.Collapsed
        collapse.Text = Sim.Collapsed and "+" or "—"

        local current = Sim.Collapsed and 38 or height
        panel.Size = UDim2.fromOffset(width, current)
        Sim.Clamp(panel, width, current)
    end)

    close.MouseButton1Click:Connect(Sim.Close)

    local dragging = false
    local dragStart = nil
    local origin = nil
    local dragInput = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            origin = panel.Position

            if input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    table.insert(Sim.Conns, UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not panel.Parent then
            return
        end

        local delta = input.Position - dragStart
        local current = Sim.Collapsed and 38 or height

        panel.Position = UDim2.fromOffset(origin.X.Offset + delta.X, origin.Y.Offset + delta.Y)
        Sim.Clamp(panel, width, current)
    end))
end

function Sim.Refresh()
    local player = Sim.Player

    if not Sim.Panel or not player then
        return
    end

    if player.Parent ~= Players then
        Sim.Close()
        return
    end

    local data = ViewData(player)
    local stamp = tostring(data.Scanned) .. tostring(data.Scanning) .. tostring(data.LastScan)

    if Sim.Stamp ~= stamp then
        Sim.Show(player)
    end
end

Parts[9] = true
assert(Parts and Parts[9], "[CheatReveal] Thiếu PHẦN 9/13, hãy dán đủ theo thứ tự")

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

    local sim = Button(row, {
        Size = UDim2.fromOffset(84, 22),
        Position = UDim2.fromOffset(280, 85),
        BackgroundColor3 = Config.Colors.Red,
        BackgroundTransparency = 0.45,
        Text = "CHECK KĨ",
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

    sim.MouseButton1Click:Connect(function()
        Sim.Show(player)
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
            ui.Tags.Text = "Phát hiện " .. math.max(1, #data.Known + data.Unknown) .. " chức năng hack. Bấm Check để xem bảng của " .. player.Name
            ui.Tags.TextColor3 = Config.Colors.Red
        elseif (data.Moved or 0) < Config.MinMoved then
            ui.Tags.Text = "Người này chưa chạy đủ lâu trong lúc quét. Hãy quét lại khi họ đang di chuyển."
            ui.Tags.TextColor3 = Config.Colors.Yellow
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

Parts[10] = true
assert(Parts and Parts[10], "[CheatReveal] Thiếu PHẦN 10/13, hãy dán đủ theo thứ tự")

local function SetProgress(percent, message)
    State.Progress = math.clamp(percent, 0, 100)

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

local function CountPeers(pool, player, test)
    local count = 0

    for other, otherData in pairs(pool) do
        if other ~= player and test(otherData) then
            count += 1
        end
    end

    return count
end

local function Drop(data, id, note)
    data.Evidence[id] = nil
    table.insert(data.Notes, note)
end

local function Note(data, note)
    table.insert(data.Notes, note)
end

local function ApplyPeerRules(targets, pool)
    for _, player in ipairs(targets) do
        local data = Data[player]

        if data then
            local speed = data.Evidence.SPEED

            if speed and speed.Count >= speed.Need then
                local peak = data.PeakSpeed
                local peers = CountPeers(pool, player, function(other)
                    return other.PeakSpeed >= peak * Config.PeerRatio
                end)
                local movers = 0

                for _, other in pairs(pool) do
                    if (other.Moved or 0) >= Config.MinMoved then
                        movers += 1
                    end
                end

                if peers >= Config.PeerCount and peers >= movers * 0.4 then
                    if peak <= data.Allowed * Config.PeerBorderline then
                        Drop(data, "SPEED", "Đã loại bỏ kết luận Speed Hack: có " .. peers .. " người chơi khác cũng đạt tốc độ tương tự (≥ " .. FormatNumber(peak * Config.PeerRatio) .. " studs/s) và tốc độ chỉ vượt ngưỡng ít, nhiều khả năng là nút chạy nhanh của game.")
                    else
                        Note(data, "Có " .. peers .. " người chơi khác cũng nhanh tương tự, nhưng tốc độ người này vượt hẳn ngưỡng nên vẫn giữ kết luận Speed Hack.")
                    end
                end
            end

            local jump = data.Evidence.INFJUMP

            if jump and jump.Count >= jump.Need then
                local peers = CountPeers(pool, player, function(other)
                    return other.AirJumpMax >= 2
                end)

                if peers >= Config.JumpPeerCount then
                    Drop(data, "INFJUMP", "Đã loại bỏ kết luận Infinite Jump: có " .. peers .. " người chơi khác cũng nhảy nhiều lần trên không, nhiều khả năng là cơ chế game.")
                end
            end

            local superJump = data.Evidence.SUPERJUMP

            if superJump and superJump.Count >= superJump.Need then
                local gain = data.GainMax
                local peers = CountPeers(pool, player, function(other)
                    return other.GainMax >= gain * 0.9
                end)

                if peers >= Config.JumpPeerCount then
                    Drop(data, "SUPERJUMP", "Đã loại bỏ kết luận Super Jump: có " .. peers .. " người chơi khác cũng nhảy cao tương tự, nhiều khả năng là bệ nhảy hoặc cơ chế game.")
                end
            end

            local aura = data.Evidence.KILLAURA

            if aura and aura.Count >= aura.Need then
                local peers = CountPeers(pool, player, function(other)
                    return other.AuraBursts >= 1
                end)

                if peers >= 2 then
                    Drop(data, "KILLAURA", "Đã loại bỏ kết luận Kill Aura: có " .. peers .. " người chơi khác cũng gây sát thương diện rộng, nhiều khả năng là kỹ năng của game.")
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

        if passes < Config.StaticPasses and elapsed >= passes * (duration - 3) / Config.StaticPasses then
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

        local phase = "Giai đoạn 1: đo chuyển động"

        if elapsed >= duration * 0.7 then
            phase = "Giai đoạn 3: đối chiếu và loại trừ nhầm lẫn"
        elseif elapsed >= duration * 0.35 then
            phase = "Giai đoạn 2: kiểm tra chiến đấu, vũ khí, vật thể"
        end

        SetProgress(
            elapsed / duration * 100,
            phase .. " | " .. math.floor(elapsed) .. "/" .. duration .. "s | để người chơi hoạt động bình thường"
        )

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

    if single and not cancelled and targets[1] then
        local result = Data[targets[1]]

        if result and result.Scanned and result.Score >= Config.HackThreshold
            and not (Sim.Panel and Sim.Player == targets[1]) then
            Safe(Sim.Show, targets[1])
        end
    end
end

RequestScan = function(targets, single)
    task.spawn(RunSession, targets, single)
end

Parts[11] = true
assert(Parts and Parts[11], "[CheatReveal] Thiếu PHẦN 11/13, hãy dán đủ theo thứ tự")

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
    Check("Theo dõi vũ khí", type(MonitorTool) == "function")
    Check("Quan sát góc nhìn", type(Spec.Begin) == "function" and type(Spec.Step) == "function")
    Check("Bảng mô phỏng", type(Sim.Show) == "function" and type(Sim.MakeRow) == "function")
    Check("Chi tiết", type(ShowDetails) == "function" and type(RenderDetails) == "function")

    AddEvidence(dummy, "SELFTEST", 60, 1, "test")
    local testData = GetData(dummy)
    Recompute(testData)
    Check("Bộ chấm điểm", testData.Score >= Config.HackThreshold)
    Check("Hack không xác định", testData.Unknown == 1 and string.find(HackSummary(testData), "không xác định", 1, true) ~= nil)
    Data[dummy] = nil

    Check("Giao diện", UI.Gui.Parent ~= nil and UI.List.Parent == UI.Body)
    Check("Logo thu gọn", UI.Floating.Parent == UI.Gui)
    Check("Camera", Workspace.CurrentCamera ~= nil)
    Check("Probe", Probe.Parent ~= nil)
    Check("Âm thanh", SoundService ~= nil)

    Check("Raycast", (pcall(function()
        return Workspace:Raycast(Vector3.new(0, 500, 0), Vector3.new(0, -1, 0), GroundParams)
    end)))

    Check("Raycast xuyên tường", (pcall(function()
        return Workspace:Raycast(Vector3.new(0, 500, 0), Vector3.new(0, -1, 0), PathParams)
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
    Sim.Toggles = setmetatable({}, {__mode = "k"})

    Sim.Close()
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
    Sim.Close()

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

local FloatDragging = false
local FloatMoved = false
local FloatStart = nil
local FloatOrigin = nil
local FloatInput = nil

local function ClampFloating()
    local area = UI.Gui.AbsoluteSize
    local position = UI.Floating.AbsolutePosition - UI.Gui.AbsolutePosition
    local size = UI.Floating.AbsoluteSize
    local x = math.clamp(position.X, 0, math.max(area.X - size.X, 0))
    local y = math.clamp(position.Y, 0, math.max(area.Y - size.Y, 0))

    if x ~= position.X or y ~= position.Y then
        local current = UI.Floating.Position

        UI.Floating.Position = UDim2.new(
            current.X.Scale,
            current.X.Offset + (x - position.X),
            current.Y.Scale,
            current.Y.Offset + (y - position.Y)
        )
    end
end

Track(UI.Floating.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        FloatDragging = true
        FloatMoved = false
        FloatStart = input.Position
        FloatOrigin = UI.Floating.Position
        FloatInput = input

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                FloatDragging = false
            end
        end)
    end
end))

Track(UI.Floating.MouseButton1Click:Connect(function()
    if FloatMoved then
        FloatMoved = false
        return
    end

    if State.Spectating then
        StopSpectating()
        return
    end

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

    if Sim.Panel and Sim.Player == player then
        Sim.Close()
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

Parts[12] = true
assert(Parts and Parts[12], "[CheatReveal] Thiếu PHẦN 12/13, hãy dán đủ theo thứ tự")

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

    if FloatDragging and FloatStart then
        local valid = input.UserInputType == Enum.UserInputType.MouseMovement
            or (input.UserInputType == Enum.UserInputType.Touch and input == FloatInput)

        if valid then
            local delta = input.Position - FloatStart

            if FloatMoved or delta.Magnitude > 6 then
                FloatMoved = true

                UI.Floating.Position = UDim2.new(
                    FloatOrigin.X.Scale,
                    FloatOrigin.X.Offset + delta.X,
                    FloatOrigin.Y.Scale,
                    FloatOrigin.Y.Offset + delta.Y
                )

                ClampFloating()
            end
        end
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
            Safe(Spec.Update)
        end

        Safe(Sim.Refresh)

        task.wait(Config.UIInterval)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    WatchPlayer(player)
end

Safe(RefreshFilters)
Safe(RefreshPlayers)

Parts[13] = true

print(Config.Title .. " " .. Config.Version .. " READY (13/13 phần)")
