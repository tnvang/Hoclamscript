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
    Version = "V3.0",
    SampleInterval = 0.15,
    CombatInterval = 0.25,
    UIInterval = 0.5,
    ScanInterval = 4,
    EvidenceLife = 45,
    MaxDetails = 18,
    SpawnGrace = 3,
    SeatGrace = 2,
    SpeedFloor = 32,
    SpeedMultiplier = 1.35,
    SpeedWindow = 0.6,
    SpeedStreak = 4,
    FlingSpeed = 220,
    FlingNear = 14,
    TeleportLimit = 70,
    TeleportElapsed = 0.6,
    AirGap = 3.5,
    FlightDuration = 3,
    HoverVelocity = 3,
    JumpMargin = 2.5,
    AirJumpRatio = 0.55,
    AirJumpWindow = 8,
    AirJumpCount = 3,
    SpinLimit = 25,
    TurnLimit = 9,
    UndergroundMargin = 30,
    UndergroundTime = 2,
    FloorSamples = 20,
    AttributionRadius = 60,
    AuraRadius = 30,
    AuraTargets = 3,
    AuraWindow = 0.8,
    FarmWindow = 25,
    FarmKills = 6,
    ReachSlack = 10,
    ReachHandle = 12,
    ReachOffset = 14,
    BodyPartLimit = 8,
    WalkSpeedLimit = 80,
    JumpPowerLimit = 150,
    HipHeightLimit = 10,
    HackThreshold = 20,
    HackNameMin = 5,
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
    LastError = nil
}

local Floor = {Y = nil, Samples = 0}
local Data = {}
local Rows = {}
local Connections = {}
local RingSize = 256
local DamageRing = {}
local Tracked = setmetatable({}, {__mode = "k"})

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

local HackRules = {
    {"TELEPORT", "Teleport (dịch chuyển)"},
    {"SPEED", "Speed Hack (tăng tốc)"},
    {"PROP_WALKSPEED", "Speed Hack (tăng tốc)"},
    {"FLING", "Fling (hất người chơi)"},
    {"SPIN", "Spin / Fling (xoay tốc độ cao)"},
    {"FLY", "Fly Hack (bay)"},
    {"INFJUMP", "Infinite Jump (nhảy vô hạn)"},
    {"PROP_JUMP", "Super Jump (nhảy cao)"},
    {"PROP_HIPHEIGHT", "HipHeight (nâng người)"},
    {"UNDERGROUND", "Underground (chui xuống đất)"},
    {"VOID_WALK", "Underground (đi dưới map)"},
    {"NOCLIP", "Noclip (xuyên tường)"},
    {"KILLAURA", "Kill Aura"},
    {"AUTOFARM", "Auto Farm"},
    {"REACH", "Reach (tầm đánh dài)"},
    {"HITBOX", "Hitbox Expander"},
    {"PROP_GODMODE", "God Mode (bất tử)"},
    {"ESP", "ESP / Wallhack"},
    {"MOVER", "Script di chuyển (BodyMover)"},
    {"NAME", "Đối tượng hack đáng ngờ"}
}

local function HackOf(id)
    for _, rule in ipairs(HackRules) do
        if string.sub(id, 1, #rule[1]) == rule[1] then
            return rule[2]
        end
    end

    return "Hành vi bất thường"
end

local function NewData()
    return {
        Score = 0,
        Peak = 0,
        Status = "CHƯA QUÉT",
        Busy = false,
        LastScan = 0,
        Samples = 0,
        Evidence = {},
        Details = {},
        Hacks = {},
        HackLog = {},
        Streak = {},
        History = {},
        Kills = {},
        AirJumps = {},
        LastPos = nil,
        LastTime = nil,
        LastLook = nil,
        LastVy = 0,
        PrevAir = false,
        AirCount = 0,
        AirStart = nil,
        AirStartY = 0,
        AirMaxY = 0,
        UnderStart = nil,
        Grace = 0,
        Speed = 0,
        Gap = 0,
        Spin = 0,
        AuraStamp = 0,
        KillStamp = 0
    }
end

local function GetData(player)
    if not Data[player] then
        Data[player] = NewData()
    end

    return Data[player]
end

local function ResetMotion(data)
    data.LastPos = nil
    data.LastTime = nil
    data.LastLook = nil
    data.LastVy = 0
    data.PrevAir = false
    data.AirCount = 0
    data.AirStart = nil
    data.UnderStart = nil
    data.History = {}
    data.Streak = {}
end

local function Recompute(data)
    local now = os.clock()
    local total = 0
    local groups = 0
    local list = {}

    for id, evidence in pairs(data.Evidence) do
        if now - evidence.Time > Config.EvidenceLife then
            data.Evidence[id] = nil
        else
            local value = evidence.Weight * math.min(evidence.Count, evidence.Need) / evidence.Need
            total += value
            groups += 1

            table.insert(list, {
                Id = id,
                Text = evidence.Detail,
                Count = evidence.Count,
                Total = evidence.Total,
                Weight = evidence.Weight,
                Value = value,
                Hack = HackOf(id)
            })
        end
    end

    if groups > 1 then
        total += math.min((groups - 1) * 6, 18)
    end

    data.Score = math.clamp(math.floor(total + 0.5), 0, 100)
    data.Peak = math.max(data.Peak, data.Score)

    table.sort(list, function(a, b)
        if a.Value == b.Value then
            return a.Id < b.Id
        end

        return a.Value > b.Value
    end)

    local hacks = {}
    local seen = {}

    for _, entry in ipairs(list) do
        if entry.Value >= Config.HackNameMin and not seen[entry.Hack] then
            seen[entry.Hack] = true
            table.insert(hacks, entry.Hack)
        end
    end

    data.Hacks = hacks

    if data.Score >= Config.HackThreshold then
        for _, name in ipairs(hacks) do
            data.HackLog[name] = true
        end

        data.Status = "CÓ SỬ DỤNG HACK"
    elseif data.Peak >= Config.HackThreshold then
        data.Status = "TỪNG BỊ PHÁT HIỆN"
    elseif data.Samples == 0 and data.LastScan == 0 then
        data.Status = "CHƯA QUÉT"
    else
        data.Status = "BÌNH THƯỜNG"
    end

    while #list > Config.MaxDetails do
        table.remove(list)
    end

    data.Details = list
end

local function ListHacks(data)
    if data.Score >= Config.HackThreshold then
        return data.Hacks
    end

    local names = {}

    if data.Peak >= Config.HackThreshold then
        for name in pairs(data.HackLog) do
            table.insert(names, name)
        end

        table.sort(names)
    end

    return names
end

local function AddEvidence(player, id, weight, need, detail)
    local data = GetData(player)
    local now = os.clock()
    local evidence = data.Evidence[id]

    if evidence then
        evidence.Count += 1
        evidence.Total += 1
        evidence.Time = now
        evidence.Detail = detail
        evidence.Weight = weight
    else
        data.Evidence[id] = {
            Weight = weight,
            Need = need,
            Count = 1,
            Total = 1,
            Time = now,
            Detail = detail
        }
    end

    Recompute(data)
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
    if Tracked[humanoid] ~= nil or not humanoid.Parent then
        return
    end

    Tracked[humanoid] = humanoid.Health

    local connection
    connection = humanoid.HealthChanged:Connect(function(health)
        if State.Destroyed then
            connection:Disconnect()
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
    end)

    humanoid.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Tracked[humanoid] = nil
            connection:Disconnect()
        end
    end)
end

local function TrackExisting()
    task.spawn(function()
        local count = 0

        for _, instance in ipairs(Workspace:GetDescendants()) do
            count += 1

            if count % 400 == 0 then
                task.wait()
            end

            if instance:IsA("Humanoid") then
                TrackHumanoid(instance)
            end
        end
    end)

    Track(Workspace.DescendantAdded:Connect(function(instance)
        if instance:IsA("Humanoid") then
            task.defer(TrackHumanoid, instance)
        end
    end))
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

    if #actors == 0 then
        return
    end

    local groups = {}

    for index = 1, RingSize do
        local event = DamageRing[index]

        if event and now - event.Time <= Config.FarmWindow then
            if event.Attacker == nil then
                local best = nil
                local bestDistance = Config.AttributionRadius
                local crowd = 0

                for _, actor in ipairs(actors) do
                    if actor.Humanoid ~= event.Humanoid then
                        local distance = (actor.Root.Position - event.Position).Magnitude

                        if distance <= Config.AttributionRadius then
                            crowd += 1

                            if distance <= bestDistance then
                                best = actor
                                bestDistance = distance
                            end
                        end
                    end
                end

                event.Attacker = best and best.Player or false
                event.Distance = bestDistance
                event.Crowd = crowd
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

                    if tool and handle and handle:IsA("BasePart") and IsMelee(tool) and event.Crowd == 1 then
                        local handleSize = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
                        local limit = handleSize + Config.ReachSlack + 4
                        local distance = (event.Position - actor.Root.Position).Magnitude

                        if distance > limit then
                            AddEvidence(
                                attacker,
                                "REACH_DAMAGE",
                                40,
                                2,
                                "Gây sát thương ở " .. FormatNumber(distance) .. " studs với '" .. tool.Name .. "', tầm hợp lệ khoảng " .. FormatNumber(limit)
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

            if count >= Config.AuraTargets and (behind >= 2 or unarmed or count >= 5) then
                local note = ""

                if behind > 0 then
                    note = note .. ", " .. behind .. " mục tiêu ở sau lưng"
                end

                if unarmed then
                    note = note .. ", không cầm vũ khí"
                end

                AddEvidence(
                    player,
                    "KILLAURA",
                    45,
                    3,
                    count .. " mục tiêu cùng nhận sát thương trong " .. FormatNumber(Config.AuraWindow) .. "s" .. note
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

                if #data.Kills >= Config.FarmKills then
                    local extra = data.Evidence.TELEPORT and ", kèm dịch chuyển liên tục" or ""

                    AddEvidence(
                        player,
                        "AUTOFARM",
                        data.Evidence.TELEPORT and 45 or 35,
                        2,
                        "Hạ " .. #data.Kills .. " mục tiêu trong " .. Config.FarmWindow .. "s" .. extra
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

    local data = GetData(player)

    local function OnCharacter()
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
    return math.max(Config.SpeedFloor, humanoid.WalkSpeed * Config.SpeedMultiplier + 4)
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
    if not part:IsA("BasePart") then
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

    return best
end

local function TrackLocalFloor()
    local character, humanoid, root = GetParts(LocalPlayer)

    if not character or humanoid.Health <= 0 or humanoid.SeatPart then
        return
    end

    local gap, hit = GroundGap(humanoid, root, 8)

    if gap and gap <= Config.AirGap and hit and hit.Instance.Anchored then
        Floor.Samples += 1

        if not Floor.Y or hit.Position.Y < Floor.Y then
            Floor.Y = hit.Position.Y
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

    if elapsed > 1.5 then
        ResetMotion(data)
        last = nil
        elapsed = 0
    end

    data.LastPos = position
    data.LastTime = now
    data.Samples += 1

    local state = humanoid:GetState()
    local seated = humanoid.SeatPart ~= nil or humanoid.Sit

    if seated then
        data.Grace = math.max(data.Grace, now + Config.SeatGrace)
    end

    local grace = now < data.Grace
    local exempt = ExemptStates[state] == true or seated

    table.insert(data.History, {Time = now, Position = position})

    while #data.History > 1 and now - data.History[1].Time > Config.SpeedWindow + 0.4 do
        table.remove(data.History, 1)
    end

    local velocity = root.AssemblyLinearVelocity
    local angular = root.AssemblyAngularVelocity
    local jumpLimit = math.max(MaxJump(humanoid), 7)
    local look = root.CFrame.LookVector

    if last and elapsed > 0 and elapsed <= Config.TeleportElapsed and not grace then
        local distance = (position - last).Magnitude
        local expected = velocity.Magnitude * elapsed

        if distance > Config.TeleportLimit and distance > expected * 3 + 20 then
            AddEvidence(
                player,
                "TELEPORT",
                45,
                2,
                "Tọa độ nhảy " .. FormatNumber(distance) .. " studs trong " .. FormatNumber(elapsed * 1000) .. "ms, không đi qua khoảng giữa"
            )

            data.History = {{Time = now, Position = position}}
            data.Streak = {}
            data.AirStart = nil
            data.AirCount = 0
            data.PrevAir = false
            data.LastVy = 0
            data.LastLook = look
            return
        end
    end

    local windowVy = 0
    local currentVy = 0

    if last and elapsed > 0 then
        currentVy = (position.Y - last.Y) / elapsed
        windowVy = currentVy
    end

    local speed = 0
    local oldest = nil

    for _, entry in ipairs(data.History) do
        if now - entry.Time <= Config.SpeedWindow then
            oldest = entry
            break
        end
    end

    if oldest then
        local span = now - oldest.Time

        if span >= 0.3 then
            local dx = position.X - oldest.Position.X
            local dz = position.Z - oldest.Position.Z
            speed = math.sqrt(dx * dx + dz * dz) / span
            windowVy = (position.Y - oldest.Position.Y) / span
        end
    end

    data.Speed = speed

    local allowed = AllowedSpeed(humanoid)

    if Streak(data, "speed", speed > allowed and not grace and not exempt) >= Config.SpeedStreak then
        AddEvidence(
            player,
            "SPEED",
            38,
            4,
            "Tốc độ thực tế " .. FormatNumber(speed) .. " studs/s, giới hạn " .. FormatNumber(allowed) .. " (WalkSpeed hiển thị " .. FormatNumber(humanoid.WalkSpeed) .. ")"
        )
    end

    if Streak(data, "fling_speed", speed > Config.FlingSpeed and not grace) >= 2 then
        AddEvidence(player, "FLING_SPEED", 45, 2, "Bị hất hoặc lao đi với tốc độ " .. FormatNumber(speed) .. " studs/s")
    end

    local gap, hit = GroundGap(humanoid, root, 400)
    data.Gap = gap or -1

    local airborne = gap == nil or gap > Config.AirGap
    local wasAir = data.PrevAir
    data.PrevAir = airborne
    data.AirCount = airborne and (data.AirCount + 1) or 0

    if not airborne and hit and hit.Instance.Anchored and not seated and not grace then
        Floor.Samples += 1

        if not Floor.Y or hit.Position.Y < Floor.Y then
            Floor.Y = hit.Position.Y
        end
    end

    if airborne and not exempt and not grace then
        if not data.AirStart then
            data.AirStart = now
            data.AirStartY = position.Y
            data.AirMaxY = position.Y
        end

        data.AirMaxY = math.max(data.AirMaxY, position.Y)

        local airTime = now - data.AirStart
        local gain = data.AirMaxY - data.AirStartY
        local hover = Streak(data, "hover", airTime >= Config.FlightDuration and math.abs(windowVy) <= Config.HoverVelocity)

        if hover >= 3 then
            AddEvidence(
                player,
                "FLY_HOVER",
                42,
                3,
                "Lơ lửng " .. FormatNumber(airTime) .. "s, cách đất " .. (gap and FormatNumber(gap) or "rất xa") .. " studs, vận tốc dọc " .. FormatNumber(windowVy)
            )
        end

        local rise = Streak(data, "altitude", airTime >= 1 and gain > jumpLimit * Config.JumpMargin + 4 and windowVy > -8)

        if rise >= 3 then
            AddEvidence(
                player,
                "FLY_ALTITUDE",
                40,
                4,
                "Lên cao " .. FormatNumber(gain) .. " studs khi trên không, tầm nhảy tối đa " .. FormatNumber(jumpLimit)
            )
        end
    else
        data.AirStart = nil
        data.Streak.hover = 0
        data.Streak.altitude = 0
    end

    local airJump = false

    if last and elapsed > 0 and airborne and wasAir and data.AirCount >= 3 and not exempt and not grace then
        local kick = currentVy - data.LastVy + Workspace.Gravity * elapsed

        if kick > JumpVelocity(humanoid) * Config.AirJumpRatio and currentVy > 5 then
            airJump = true
        end
    end

    data.LastVy = currentVy

    if airJump then
        table.insert(data.AirJumps, now)
    end

    while #data.AirJumps > 0 and now - data.AirJumps[1] > Config.AirJumpWindow do
        table.remove(data.AirJumps, 1)
    end

    if airJump and #data.AirJumps >= Config.AirJumpCount then
        AddEvidence(
            player,
            "INFJUMP",
            42,
            2,
            "Bật nhảy " .. #data.AirJumps .. " lần khi đang trên không trong " .. Config.AirJumpWindow .. "s"
        )
    end

    local turn = 0

    if data.LastLook and elapsed > 0 then
        local dot = math.clamp(look:Dot(data.LastLook), -1, 1)
        turn = math.acos(dot) / elapsed
    end

    data.LastLook = look

    local spinValue = angular.Magnitude
    data.Spin = math.max(spinValue, turn)

    local calm = not grace and not seated
    local spinProp = Streak(data, "spin_prop", spinValue > Config.SpinLimit and calm)
    local spinTurn = Streak(data, "spin_turn", turn > Config.TurnLimit and calm)

    if spinProp >= 2 or spinTurn >= 6 then
        AddEvidence(
            player,
            "SPIN",
            40,
            3,
            "Xoay liên tục, vận tốc góc " .. FormatNumber(spinValue) .. " rad/s, tốc độ quay đo được " .. FormatNumber(turn) .. " rad/s"
        )

        local near = NearestOther(player, position, Config.FlingNear)

        if near then
            AddEvidence(player, "FLING_NEAR", 50, 2, "Xoay tốc độ cao sát người chơi " .. near.Name)
        end
    end

    local belowFloor = (Floor.Samples >= Config.FloorSamples and Floor.Y ~= nil and position.Y < Floor.Y - Config.UndergroundMargin)
        or position.Y < Workspace.FallenPartsDestroyHeight + 15

    if belowFloor and not exempt and not grace and windowVy > -40 then
        data.UnderStart = data.UnderStart or now
    else
        data.UnderStart = nil
    end

    if data.UnderStart and now - data.UnderStart >= Config.UndergroundTime then
        AddEvidence(
            player,
            "UNDERGROUND",
            45,
            3,
            "Ở dưới mặt sàn thấp nhất của map (Y " .. FormatNumber(position.Y) .. ") nhưng vẫn sống"
        )
    end

    if airborne and gap == nil and data.AirStart and now - data.AirStart >= Config.UndergroundTime
        and math.abs(windowVy) <= Config.HoverVelocity * 2 and not exempt and not grace then

        local ceiling = Workspace:Raycast(position, Vector3.new(0, 500, 0), GroundParams)

        if ceiling and ceiling.Instance.CanCollide and ceiling.Instance.Anchored then
            AddEvidence(
                player,
                "VOID_WALK",
                42,
                3,
                "Di chuyển trong khoảng trống dưới map, phía trên có vật thể cách " .. FormatNumber(ceiling.Distance) .. " studs"
            )
        end
    end

    if not seated and not grace and not exempt then
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

        if Streak(data, "noclip_inside", inside ~= nil) >= 3 and inside then
            AddEvidence(
                player,
                "NOCLIP_INSIDE",
                45,
                3,
                "Tâm nhân vật nằm trong vật thể đặc: " .. inside.Name
            )
        end

        if last and elapsed > 0 and elapsed <= Config.TeleportElapsed then
            local delta = position - last
            local distance = delta.Magnitude

            if distance > 0.8 and distance < 30 then
                local result = Workspace:Raycast(last, delta, GroundParams)

                if result and IsSolid(result.Instance, root) then
                    AddEvidence(
                        player,
                        "NOCLIP_PATH",
                        42,
                        2,
                        "Đi xuyên qua '" .. result.Instance.Name .. "' khi di chuyển " .. FormatNumber(distance) .. " studs"
                    )
                end
            end
        end
    end
end
local ESPClasses = {
    Highlight = true,
    BillboardGui = true,
    SelectionBox = true,
    SelectionSphere = true,
    BoxHandleAdornment = true,
    SphereHandleAdornment = true,
    CylinderHandleAdornment = true,
    ConeHandleAdornment = true,
    LineHandleAdornment = true,
    WireframeHandleAdornment = true
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

local FlagWords = {
    "esp", "chams", "wallhack", "tracer", "boxesp", "nameesp", "xray",
    "aimbot", "killaura", "noclip", "speedhack", "flyhack", "fly",
    "exploit", "cheat", "hack", "aura"
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
    local character, humanoid = GetParts(player)

    if not character then
        return
    end

    if humanoid.WalkSpeed > Config.WalkSpeedLimit then
        AddEvidence(player, "PROP_WALKSPEED", 30, 1, "WalkSpeed bất thường: " .. FormatNumber(humanoid.WalkSpeed))
    end

    if humanoid.UseJumpPower then
        if humanoid.JumpPower > Config.JumpPowerLimit then
            AddEvidence(player, "PROP_JUMPPOWER", 30, 1, "JumpPower bất thường: " .. FormatNumber(humanoid.JumpPower))
        end
    elseif humanoid.JumpHeight > Config.JumpPowerLimit / 5 then
        AddEvidence(player, "PROP_JUMPHEIGHT", 30, 1, "JumpHeight bất thường: " .. FormatNumber(humanoid.JumpHeight))
    end

    if humanoid.HipHeight > Config.HipHeightLimit then
        AddEvidence(player, "PROP_HIPHEIGHT", 30, 1, "HipHeight bất thường: " .. FormatNumber(humanoid.HipHeight))
    end

    if humanoid.MaxHealth > 1000000 or humanoid.Health > 1000000 then
        AddEvidence(player, "PROP_GODMODE", 20, 1, "Máu cực lớn: " .. FormatNumber(humanoid.MaxHealth))
    end

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and not IsAllowed(part, character) then
            local size = math.max(part.Size.X, part.Size.Y, part.Size.Z)

            if size > Config.BodyPartLimit then
                AddEvidence(
                    player,
                    "HITBOX_" .. part.Name,
                    38,
                    1,
                    "Bộ phận '" .. part.Name .. "' có kích thước bất thường: " .. FormatNumber(size) .. " studs"
                )
            end
        end
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

    local handle = tool:FindFirstChild("Handle")

    if handle and handle:IsA("BasePart") then
        local size = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)

        if size > Config.ReachHandle then
            AddEvidence(
                player,
                "REACH_HANDLE",
                40,
                1,
                "Cán '" .. tool.Name .. "' dài bất thường: " .. FormatNumber(size) .. " studs"
            )
        end

        local offset = (handle.Position - root.Position).Magnitude

        if offset > Config.ReachOffset then
            AddEvidence(
                player,
                "REACH_OFFSET",
                40,
                2,
                "Vũ khí '" .. tool.Name .. "' cách thân " .. FormatNumber(offset) .. " studs"
            )
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
                AddEvidence(
                    player,
                    "REACH_HITBOX",
                    38,
                    1,
                    "Vùng '" .. part.Name .. "' của '" .. tool.Name .. "' quá lớn: " .. FormatNumber(size) .. " studs"
                )
                break
            end
        end
    end
end

local function ScanObjects(player)
    local character = player.Character

    if not character then
        return
    end

    local checked = 0
    local seen = {}

    for _, instance in ipairs(character:GetDescendants()) do
        checked += 1

        if checked % 120 == 0 then
            task.wait()
        end

        if instance.Parent and not IsAllowed(instance, character) then
            local class = instance.ClassName
            local word = NameFlagged(instance.Name)
            local id = nil
            local weight = 0
            local detail = nil

            if ESPClasses[class] then
                local onTop = false

                pcall(function()
                    onTop = instance.AlwaysOnTop == true
                end)

                if instance:IsA("Highlight") then
                    onTop = instance.DepthMode == Enum.HighlightDepthMode.AlwaysOnTop
                end

                if word then
                    id = "ESP_" .. instance.Name
                    weight = 28
                    detail = "Đối tượng '" .. instance.Name .. "' (" .. class .. ") mang đặc điểm ESP"
                elseif onTop and class ~= "BillboardGui" then
                    id = "ESP_ONTOP_" .. class
                    weight = 10
                    detail = "Đối tượng " .. class .. " hiển thị xuyên vật thể"
                end
            elseif MoverClasses[class] then
                id = "MOVER_" .. class
                weight = word and 35 or 15
                detail = "Có " .. class .. " '" .. instance.Name .. "' gắn vào nhân vật"
            elseif word then
                id = "NAME_" .. instance.Name
                weight = 20
                detail = "Đối tượng tên đáng ngờ: " .. instance.Name
            end

            if id and not seen[id] then
                seen[id] = true
                AddEvidence(player, id, weight, 1, detail)
            end
        end
    end
end

local function ScanPlayer(player, progress)
    if player == LocalPlayer or player.Parent ~= Players then
        return false
    end

    local data = GetData(player)

    if data.Busy then
        return false
    end

    data.Busy = true

    local ok = pcall(function()
        if progress then
            progress("Đang kiểm tra nhân vật...")
        end

        ScanHumanoid(player)
        ScanTools(player)

        if progress then
            progress("Đang kiểm tra vật thể...")
        end

        ScanObjects(player)
    end)

    data.Busy = false
    data.LastScan = os.clock()
    Recompute(data)

    return ok
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
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

UI.Main = Create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0.94, 0, 0.9, 0),
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
    Text = Config.Version .. "  •  GIÁM SÁT PHẦN MỀM HACK THỜI GIAN THỰC",
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
UI.SuspiciousCount = Stat(2, "ĐANG DÙNG HACK: 0", Config.Colors.Red)
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
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Đang chờ quét...",
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
    local data = GetData(player)
    local active = data.Score >= Config.HackThreshold
    local hacks = ListHacks(data)

    details.Info.Text = "Tốc độ: " .. FormatNumber(data.Speed) .. " studs/s  |  Cách đất: " .. FormatNumber(data.Gap)
        .. "  |  Xoay: " .. FormatNumber(data.Spin) .. " rad/s  |  Mẫu: " .. data.Samples
        .. "  |  Quét cuối: " .. math.floor(os.clock() - data.LastScan) .. "s trước"

    local lines = {}

    table.insert(lines, {
        Text = "Điểm nghi vấn: " .. data.Score .. "%  |  " .. data.Status .. "  |  Cao nhất: " .. data.Peak .. "%",
        Color = GetColor(data.Score),
        Size = 12
    })

    if #hacks > 0 then
        table.insert(lines, {
            Text = (active and "ĐANG SỬ DỤNG HACK: " or "ĐÃ TỪNG PHÁT HIỆN HACK: ") .. table.concat(hacks, "  •  "),
            Color = active and Config.Colors.Red or Config.Colors.Orange,
            Size = 12
        })
    else
        table.insert(lines, {Text = "Chưa phát hiện phần mềm hack.", Color = Config.Colors.Green, Size = 11})
    end

    for _, evidence in ipairs(data.Details) do
        table.insert(lines, {
            Text = "[" .. evidence.Hack .. "] " .. evidence.Text .. " | Lặp lại: " .. evidence.Count .. " (tổng " .. evidence.Total .. ")",
            Color = GetColor(evidence.Weight * 2),
            Size = 10
        })
    end

    table.insert(lines, {
        Text = "Lưu ý: đây là dữ liệu quan sát từ client, cần đối chiếu với cơ chế của game trước khi kết luận.",
        Color = Config.Colors.Gray,
        Size = 10
    })

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
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.fromOffset(12, 25),
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
        Size = UDim2.new(1, -20, 1, -62),
        Position = UDim2.fromOffset(10, 54),
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
        Text = "0%",
        TextColor3 = Config.Colors.Green,
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

    detail.MouseButton1Click:Connect(function()
        ShowDetails(player)
    end)

    observe.MouseButton1Click:Connect(function()
        Spectate(player)
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

    local data = GetData(player)
    local score = data.Score
    local active = score >= Config.HackThreshold
    local color = GetColor(score)
    local hacks = ListHacks(data)

    ui.Name.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
    ui.Status.Text = data.Status
    ui.Status.TextColor3 = (active or data.Peak >= Config.HackThreshold) and color or Config.Colors.Gray
    ui.Percent.Text = score .. "%"
    ui.Percent.TextColor3 = color

    if #hacks > 0 then
        ui.Tags.Text = (active and "Đang dùng: " or "Từng dùng: ") .. table.concat(hacks, "  •  ")
        ui.Tags.TextColor3 = active and Config.Colors.Red or Config.Colors.Orange
    else
        ui.Tags.Text = "Không phát hiện phần mềm hack"
        ui.Tags.TextColor3 = Config.Colors.Gray
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

            local data = GetData(player)
            Recompute(data)

            if data.Score >= Config.HackThreshold then
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
    UI.SuspiciousCount.Text = "ĐANG DÙNG HACK: " .. hackers
    UI.SuspiciousCount.TextColor3 = hackers > 0 and Config.Colors.Red or Config.Colors.Gray
    UI.Empty.Visible = total == 0
end
local function SetProgress(percent, message)
    TweenService:Create(UI.ProgressFill, TweenInfo.new(0.15), {
        Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
    }):Play()

    UI.ProgressText.Text = message or ""
end

local function ScanAll()
    if State.Scanning or State.Destroyed then
        return
    end

    State.Scanning = true
    State.Generation += 1

    local generation = State.Generation
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(targets, player)
        end
    end

    local total = #targets

    if total == 0 then
        State.Scanning = false
        UI.ScanState.Text = "KHÔNG CÓ NGƯỜI CHƠI"
        UI.ScanState.TextColor3 = Config.Colors.Gray
        SetProgress(100, "Không tìm thấy người chơi khác.")
        return
    end

    UI.ScanState.Text = "ĐANG TRA..."
    UI.ScanState.TextColor3 = Config.Colors.Yellow
    UI.ScanLabel.Text = "◌  ĐANG TRA..."

    local completed = 0

    for index, player in ipairs(targets) do
        if State.Destroyed or generation ~= State.Generation then
            break
        end

        if player.Parent == Players then
            RefreshFilters()
            SetProgress((index - 1) / total * 100, "Đang quét " .. player.Name .. "...")

            ScanPlayer(player, function(message)
                UI.ProgressText.Text = player.Name .. " | " .. message
            end)
        end

        completed += 1
        SetProgress(completed / total * 100, "Hoàn thành " .. completed .. "/" .. total)
        Safe(RefreshPlayers)
        task.wait(0.05)
    end

    if not State.Destroyed and generation == State.Generation then
        UI.ScanState.Text = "HOÀN TẤT"
        UI.ScanState.TextColor3 = Config.Colors.Green
        SetProgress(100, "Quét hoàn tất | " .. completed .. " người chơi")
        Safe(RefreshPlayers)
    end

    if not State.Destroyed then
        UI.ScanLabel.Text = "◉  TRA NGAY"
    end

    State.Scanning = false
end

local function SelfTest()
    if State.Destroyed then
        return
    end

    local tests = {}

    local function Check(name, condition)
        table.insert(tests, {Name = name, Ok = condition == true})
    end

    local dummy = {}

    Check("Quét chuyển động", type(ScanMotion) == "function")
    Check("Quét đối tượng", type(ScanPlayer) == "function")
    Check("Phân tích chiến đấu", type(AnalyzeCombat) == "function")

    AddEvidence(dummy, "SELFTEST", 60, 1, "test")
    Check("Bộ chấm điểm", GetData(dummy).Score >= 50)
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
    for key in pairs(Data) do
        Data[key] = nil
    end

    for index = 1, RingSize do
        DamageRing[index] = nil
    end

    Floor.Y = nil
    Floor.Samples = 0

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
    task.spawn(ScanAll)
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
    GetData(player)
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
    local lastCombat = 0

    while not State.Destroyed do
        local now = os.clock()

        Safe(RefreshFilters)
        Safe(TrackLocalFloor)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                Safe(ScanMotion, player)
            end
        end

        if now - lastCombat >= Config.CombatInterval then
            lastCombat = now
            Safe(AnalyzeCombat)
        end

        task.wait(Config.SampleInterval)
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

task.spawn(function()
    task.wait(2)

    while not State.Destroyed do
        if not State.Scanning then
            task.spawn(ScanAll)
        end

        task.wait(Config.ScanInterval)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    WatchPlayer(player)
end

Safe(TrackExisting)
Safe(RefreshFilters)
Safe(RefreshPlayers)
Safe(SelfTest)

print(Config.Title .. " " .. Config.Version .. " READY")
