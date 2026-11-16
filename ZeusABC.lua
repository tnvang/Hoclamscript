local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    Title = "UNIVERSAL PLAYER SCANNER",
    Version = "V2.0",
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
    Colors = {
        Background = Color3.fromRGB(13, 16, 27),
        Panel = Color3.fromRGB(23, 28, 43),
        Secondary = Color3.fromRGB(32, 39, 57),
        Accent = Color3.fromRGB(75, 145, 255),
        Green = Color3.fromRGB(65, 205, 135),
        Yellow = Color3.fromRGB(245, 185, 70),
        Orange = Color3.fromRGB(245, 125, 65),
        Red = Color3.fromRGB(240, 70, 80),
        White = Color3.fromRGB(240, 244, 255),
        Gray = Color3.fromRGB(145, 155, 175)
    }
}

local Data = {}
local Rows = {}
local Connections = {}
local Scanning = false
local Destroyed = false
local ScanGeneration = 0
local Spectating = nil
local OriginalCameraSubject = nil
local Floor = {Y = nil, Samples = 0}
local RingSize = 256
local DamageRing = {}
local DamageCount = 0
local DamageDirty = false
local Tracked = setmetatable({}, {__mode = "k"})

local function Track(connection)
    table.insert(Connections, connection)
    return connection
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

local function Stroke(object, color, transparency)
    return Create("UIStroke", {
        Color = color or Config.Colors.Secondary,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

local function FormatNumber(value)
    return string.format("%.1f", value or 0)
end

local function GetTier(score)
    if score >= 80 then
        return "RẤT NGHI VẤN"
    elseif score >= 50 then
        return "ĐÁNG NGHI"
    elseif score >= 20 then
        return "CẦN THEO DÕI"
    end
    return "CHƯA CÓ DẤU HIỆU"
end

local function GetColor(score)
    if score >= 80 then
        return Config.Colors.Red
    elseif score >= 50 then
        return Config.Colors.Orange
    elseif score >= 20 then
        return Config.Colors.Yellow
    end
    return Config.Colors.Green
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

    for id, evidence in pairs(data.Evidence) do
        if now - evidence.Time > Config.EvidenceLife then
            data.Evidence[id] = nil
        else
            total += evidence.Weight * math.min(evidence.Count, evidence.Need) / evidence.Need
            groups += 1
        end
    end

    if groups > 1 then
        total += math.min((groups - 1) * 6, 18)
    end

    data.Score = math.clamp(math.floor(total + 0.5), 0, 100)
    data.Peak = math.max(data.Peak, data.Score)
    data.Status = GetTier(data.Score)

    local list = {}

    for id, evidence in pairs(data.Evidence) do
        table.insert(list, {
            Id = id,
            Text = evidence.Detail,
            Count = evidence.Count,
            Total = evidence.Total,
            Weight = evidence.Weight,
            Value = evidence.Weight * math.min(evidence.Count, evidence.Need) / evidence.Need
        })
    end

    table.sort(list, function(a, b)
        if a.Value == b.Value then
            return a.Id < b.Id
        end
        return a.Value > b.Value
    end)

    while #list > Config.MaxDetails do
        table.remove(list)
    end

    data.Details = list
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
        if Destroyed then
            connection:Disconnect()
            return
        end

        local previous = Tracked[humanoid]
        Tracked[humanoid] = health

        if previous and health < previous then
            local part = RootOf(humanoid)

            if part then
                DamageCount += 1
                DamageRing[DamageCount % RingSize + 1] = {
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
                DamageDirty = true
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
    if not DamageDirty then
        return
    end

    DamageDirty = false

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
local function AddLine(parent, text, color, size)
    local line = Create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Config.Colors.Secondary,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = color or Config.Colors.White,
        TextSize = size or 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 22
    }, parent)

    Corner(line, 6)

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

    details.Info.Text = "Tốc độ: " .. FormatNumber(data.Speed) .. " studs/s  |  Cách đất: " .. FormatNumber(data.Gap)
        .. "  |  Xoay: " .. FormatNumber(data.Spin) .. " rad/s  |  Mẫu: " .. data.Samples
        .. "  |  Quét cuối: " .. math.floor(os.clock() - data.LastScan) .. "s trước"

    local lines = {}

    table.insert(lines, {
        Text = "Điểm nghi vấn: " .. data.Score .. "%  |  Mức độ: " .. data.Status .. "  |  Cao nhất: " .. data.Peak .. "%",
        Color = GetColor(data.Score),
        Size = 12
    })

    if #data.Details == 0 then
        table.insert(lines, {Text = "Chưa ghi nhận dấu hiệu bất thường.", Color = Config.Colors.White, Size = 11})
    else
        for _, evidence in ipairs(data.Details) do
            table.insert(lines, {
                Text = "[" .. evidence.Id .. "] " .. evidence.Text .. " | Lặp lại: " .. evidence.Count .. " (tổng " .. evidence.Total .. ")",
                Color = GetColor(evidence.Weight * 2),
                Size = 10
            })
        end
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

    for _, line in ipairs(lines) do
        AddLine(details.List, line.Text, line.Color, line.Size)
    end
end

local function ShowDetails(player)
    if UI.Details and UI.Details.Panel.Parent then
        UI.Details.Panel:Destroy()
    end

    local panel = Create("Frame", {
        Name = "DetailsPanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0.94, 0, 0.92, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Config.Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20
    }, UI.Main)

    Corner(panel, 12)
    Stroke(panel, Config.Colors.Accent)

    Create("TextLabel", {
        Size = UDim2.new(1, -56, 0, 18),
        Position = UDim2.fromOffset(12, 6),
        BackgroundTransparency = 1,
        Text = "PHÂN TÍCH: " .. player.DisplayName .. " (@" .. player.Name .. ")",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21
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
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 21
    }, panel)

    local exit = Create("TextButton", {
        Size = UDim2.fromOffset(30, 28),
        Position = UDim2.new(1, -38, 0, 6),
        BackgroundColor3 = Config.Colors.Red,
        Text = "X",
        TextColor3 = Config.Colors.White,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        ZIndex = 21
    }, panel)

    Corner(exit, 7)

    local list = Create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -62),
        Position = UDim2.fromOffset(10, 54),
        BackgroundColor3 = Config.Colors.Panel,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 21
    }, panel)

    Corner(list, 8)

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
    Spectating = nil

    local camera = Workspace.CurrentCamera

    if camera then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        camera.CameraSubject = humanoid or OriginalCameraSubject
        camera.CameraType = Enum.CameraType.Custom
    end
end

local function Spectate(player)
    if Spectating == player then
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

    if not Spectating then
        OriginalCameraSubject = camera.CameraSubject
    end

    Spectating = player
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
        Size = UDim2.new(1, -4, 0, 92),
        BackgroundColor3 = Config.Colors.Secondary,
        BorderSizePixel = 0
    }, UI.List)

    Corner(row, 8)

    local avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Config.Colors.Panel,
        Image = "",
        BorderSizePixel = 0
    }, row)

    Corner(avatar, 20)

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
        Position = UDim2.fromOffset(56, 6),
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
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right
    }, row)

    local status = Create("TextLabel", {
        Size = UDim2.new(1, -66, 0, 14),
        Position = UDim2.fromOffset(56, 25),
        BackgroundTransparency = 1,
        Text = "CHƯA QUÉT",
        TextColor3 = Config.Colors.Gray,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local bar = Create("Frame", {
        Size = UDim2.new(1, -66, 0, 5),
        Position = UDim2.fromOffset(56, 42),
        BackgroundColor3 = Config.Colors.Panel,
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
        Size = UDim2.new(1, -66, 0, 14),
        Position = UDim2.fromOffset(56, 49),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Colors.Gray,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local detail = Create("TextButton", {
        Size = UDim2.fromOffset(64, 22),
        Position = UDim2.fromOffset(56, 66),
        BackgroundColor3 = Config.Colors.Accent,
        Text = "CHI TIẾT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, row)

    Corner(detail, 5)

    local observe = Create("TextButton", {
        Size = UDim2.fromOffset(74, 22),
        Position = UDim2.fromOffset(126, 66),
        BackgroundColor3 = Config.Colors.Panel,
        Text = "QUAN SÁT",
        TextColor3 = Config.Colors.White,
        TextSize = 9,
        Font = Enum.Font.GothamBold
    }, row)

    Corner(observe, 5)

    detail.MouseButton1Click:Connect(function()
        ShowDetails(player)
    end)

    observe.MouseButton1Click:Connect(function()
        Spectate(player)
    end)

    Rows[player] = {
        Row = row,
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
    local color = GetColor(score)

    ui.Name.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
    ui.Status.Text = data.Status
    ui.Status.TextColor3 = color
    ui.Percent.Text = score .. "%"
    ui.Percent.TextColor3 = color

    local tags = {}

    for index, evidence in ipairs(data.Details) do
        if index > 3 then
            break
        end

        table.insert(tags, string.match(evidence.Id, "^[^_]+") or evidence.Id)
    end

    ui.Tags.Text = #tags > 0 and table.concat(tags, "  ·  ") or "Không có dấu hiệu"

    if ui.LastScore ~= score then
        ui.LastScore = score

        TweenService:Create(ui.Fill, TweenInfo.new(0.25), {
            Size = UDim2.new(score / 100, 0, 1, 0),
            BackgroundColor3 = color
        }):Play()
    end

    ui.Row.LayoutOrder = -score
    ui.Observe.Text = Spectating == player and "DỪNG XEM" or "QUAN SÁT"
end

local function RefreshPlayers()
    local total = 0
    local suspicious = 0
    local keyword = string.lower(UI.Search.Text)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            total += 1

            local data = GetData(player)
            Recompute(data)

            if data.Score >= 50 then
                suspicious += 1
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
    UI.SuspiciousCount.Text = "NGHI VẤN: " .. suspicious
end
local function SetProgress(percent, message)
    TweenService:Create(UI.ProgressFill, TweenInfo.new(0.15), {
        Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
    }):Play()

    UI.ProgressText.Text = message or ""
end

local function ScanAll()
    if Scanning or Destroyed then
        return
    end

    Scanning = true
    ScanGeneration += 1

    local generation = ScanGeneration
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(targets, player)
        end
    end

    local total = #targets

    if total == 0 then
        Scanning = false
        UI.ScanState.Text = "KHÔNG CÓ NGƯỜI CHƠI"
        UI.ScanState.TextColor3 = Config.Colors.Gray
        SetProgress(100, "Không tìm thấy người chơi khác.")
        return
    end

    UI.ScanState.Text = "ĐANG QUÉT"
    UI.ScanState.TextColor3 = Config.Colors.Yellow

    local completed = 0

    for index, player in ipairs(targets) do
        if Destroyed or generation ~= ScanGeneration then
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
        RefreshPlayers()
        task.wait(0.05)
    end

    if not Destroyed and generation == ScanGeneration then
        UI.ScanState.Text = "HOÀN TẤT"
        UI.ScanState.TextColor3 = Config.Colors.Green
        SetProgress(100, "Quét hoàn tất | " .. completed .. " người chơi")
        RefreshPlayers()
    end

    Scanning = false
end

local function SelfTest()
    if Destroyed then
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

    RefreshPlayers()
    SetProgress(0, "Đã xóa dữ liệu quét.")
end

local function Shutdown()
    Destroyed = true
    ScanGeneration += 1
    StopSpectating()

    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end

    Probe:Destroy()
    UI.Gui:Destroy()
end

Track(UI.ScanButton.MouseButton1Click:Connect(function()
    task.spawn(ScanAll)
end))

Track(UI.TestButton.MouseButton1Click:Connect(SelfTest))
Track(UI.ResetButton.MouseButton1Click:Connect(ResetAll))

Track(UI.Search:GetPropertyChangedSignal("Text"):Connect(function()
    RefreshPlayers()
end))

Track(UI.Minimize.MouseButton1Click:Connect(function()
    UI.Main.Visible = false
    UI.Floating.Visible = true
end))

Track(UI.Floating.MouseButton1Click:Connect(function()
    UI.Main.Visible = true
    UI.Floating.Visible = false
end))

Track(UI.Close.MouseButton1Click:Connect(Shutdown))

Track(Players.PlayerAdded:Connect(function(player)
    GetData(player)
    WatchPlayer(player)

    task.delay(1, function()
        if not Destroyed and player.Parent == Players then
            RefreshPlayers()
        end
    end)
end))

Track(Players.PlayerRemoving:Connect(function(player)
    if Spectating == player then
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
        if not Destroyed then
            RefreshPlayers()
        end
    end)
end))

Track(LocalPlayer.CharacterAdded:Connect(function(character)
    StopSpectating()
    task.wait(0.5)
    OriginalCameraSubject = character:FindFirstChildOfClass("Humanoid")
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

task.spawn(function()
    local lastCombat = 0

    while not Destroyed do
        local now = os.clock()

        RefreshFilters()
        pcall(TrackLocalFloor)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(ScanMotion, player)
            end
        end

        if now - lastCombat >= Config.CombatInterval then
            lastCombat = now
            pcall(AnalyzeCombat)
        end

        task.wait(Config.SampleInterval)
    end
end)

task.spawn(function()
    while not Destroyed do
        pcall(RefreshPlayers)

        if UI.Details then
            pcall(RenderDetails)
        end

        if Spectating then
            if Spectating.Parent ~= Players then
                StopSpectating()
            else
                local character = Spectating.Character
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

    while not Destroyed do
        if not Scanning then
            task.spawn(ScanAll)
        end

        task.wait(Config.ScanInterval)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    WatchPlayer(player)
end

TrackExisting()
RefreshFilters()
RefreshPlayers()
SelfTest()

print(Config.Title .. " " .. Config.Version .. " READY")
