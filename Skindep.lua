local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Effects, Enabled, HiddenParts = {}, {}, {}
local HiddenAccessories, AccessoryStates = {}, {}
local OriginalColors, AccessoryColors, OriginalClothes = {}, {}, {}
local RainbowConnection, CurrentStyle, VietnamStar
local Destroyed = false

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "VN | HIỆU ỨNG",
    LoadingTitle = "Học Làm Script",
    LoadingSubtitle = "Hệ thống ngoại hình nhân vật",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false
})

local TabEffects = Window:CreateTab("Hiệu ứng", "sparkles")
local TabBody = Window:CreateTab("Cơ thể", "user-round")
local TabAccessories = Window:CreateTab("Phụ kiện", "shirt")
local TabAppearance = Window:CreateTab("Ngoại hình", "palette")
local TabSettings = Window:CreateTab("Cài đặt", "settings")
local TabAuthor = Window:CreateTab("Tác giả", "users")

local function Character()
    return Player.Character
end

local function Root()
    local C = Character()
    return C and C:FindFirstChild("HumanoidRootPart")
end

local function AddEffect(Name, Object)
    Effects[Name] = Effects[Name] or {}
    table.insert(Effects[Name], Object)
end

local function StopEffect(Name)
    if Name == "Rainbow" and RainbowConnection then
        RainbowConnection:Disconnect()
        RainbowConnection = nil
    end

    for _, Object in ipairs(Effects[Name] or {}) do
        pcall(function()
            Object:Destroy()
        end)
    end

    Effects[Name] = {}
    Enabled[Name] = false
end

local function ToggleEffect(Name, Value, Callback)
    StopEffect(Name)
    if Value and not Destroyed then
        Enabled[Name] = true
        local Success, Error = pcall(Callback)
        if not Success then
            StopEffect(Name)
            warn("TVANDZ Effect Error:", Name, Error)
        end
    end
end

local function CreateObject(Name, Class, Parent, Properties)
    if not Parent then return end

    local Object = Instance.new(Class)
    Object.Name = "VN_" .. Name

    for Key, Value in pairs(Properties or {}) do
        Object[Key] = Value
    end

    Object.Parent = Parent
    AddEffect(Name, Object)
    return Object
end

local function CreateHighlight()
    local C = Character()
    if C then
        CreateObject("Highlight", "Highlight", C, {
            FillColor = Color3.fromRGB(255, 190, 40),
            OutlineColor = Color3.new(1, 1, 1),
            FillTransparency = 0.55,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        })
    end
end

local function CreateFire()
    CreateObject("Fire", "Fire", Root(), {
        Color = Color3.fromRGB(255, 170, 40),
        SecondaryColor = Color3.fromRGB(255, 60, 10),
        Size = 3,
        Heat = 5
    })
end

local function CreateShoulderFire()
    local C = Character()
    if not C then return end

    local Names = {
        "LeftUpperArm", "RightUpperArm",
        "Left Arm", "Right Arm"
    }

    local HasUpper = C:FindFirstChild("LeftUpperArm")
        or C:FindFirstChild("RightUpperArm")

    for _, Name in ipairs(Names) do
        local Part = C:FindFirstChild(Name)
        if Part and Part:IsA("BasePart") then
            if Name == "LeftUpperArm" or Name == "RightUpperArm"
                or not HasUpper then
                local Attachment = Instance.new("Attachment")
                Attachment.Name = "TVANDZ_ShoulderAttachment"
                Attachment.Position = Vector3.new(0, Part.Size.Y * 0.35, 0)
                Attachment.Parent = Part
                AddEffect("ShoulderFire", Attachment)

                local Fire = Instance.new("Fire")
                Fire.Name = "TVANDZ_ShoulderFire"
                Fire.Color = Color3.fromRGB(255, 170, 35)
                Fire.SecondaryColor = Color3.fromRGB(255, 45, 10)
                Fire.Size = 2.5
                Fire.Heat = 6
                Fire.Parent = Part
                AddEffect("ShoulderFire", Fire)
            end
        end
    end
end

local function CreateSparkles()
    CreateObject("Sparkles", "Sparkles", Root(), {
        SparkleColor = Color3.fromRGB(255, 220, 80)
    })
end

local function CreateTrail()
    local R = Root()
    if not R then return end

    local A0 = Instance.new("Attachment")
    A0.Position = Vector3.new(0, 1, 0)
    A0.Parent = R
    AddEffect("Trail", A0)

    local A1 = Instance.new("Attachment")
    A1.Position = Vector3.new(0, -1, 0)
    A1.Parent = R
    AddEffect("Trail", A1)

    CreateObject("Trail", "Trail", R, {
        Attachment0 = A0,
        Attachment1 = A1,
        Lifetime = 0.5,
        MinLength = 0.1,
        FaceCamera = true,
        LightEmission = 1,
        Color = ColorSequence.new(
            Color3.fromRGB(255, 220, 50),
            Color3.fromRGB(255, 80, 20)
        )
    })
end

local function CreateRainbow()
    local C = Character()
    if not C then return end

    local H = Instance.new("Highlight")
    H.Name = "VN_Rainbow"
    H.FillTransparency = 0.45
    H.Parent = C
    AddEffect("Rainbow", H)

    local Hue = 0
    RainbowConnection = RunService.Heartbeat:Connect(function(Delta)
        if not Enabled.Rainbow or not H.Parent then
            return
        end

        Hue = (Hue + Delta * 0.25) % 1
        H.FillColor = Color3.fromHSV(Hue, 1, 1)
        H.OutlineColor = H.FillColor
    end)
end

local function CreateForceField()
    local C = Character()
    if C then
        CreateObject("ForceField", "ForceField", C, {
            Visible = true
        })
    end
end

local function CreateSmoke()
    CreateObject("Smoke", "Smoke", Root(), {
        Color = Color3.fromRGB(170, 190, 220),
        Opacity = 0.35,
        RiseVelocity = 5,
        Size = 5
    })
end

local function CreateAura()
    CreateObject("NeonAura", "PointLight", Root(), {
        Color = Color3.fromRGB(60, 190, 255),
        Brightness = 2,
        Range = 14,
        Shadows = false
    })
end

local function CreateEnergy()
    local R = Root()
    if not R then return end

    local A = Instance.new("Attachment")
    A.Name = "TVANDZ_Energy"
    A.Parent = R
    AddEffect("EnergyAura", A)

    local E = Instance.new("ParticleEmitter")
    E.Name = "TVANDZ_EnergyParticles"
    E.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    E.Color = ColorSequence.new(
        Color3.fromRGB(60, 190, 255),
        Color3.fromRGB(170, 80, 255)
    )
    E.LightEmission = 1
    E.Rate = 18
    E.Lifetime = NumberRange.new(0.7, 1.5)
    E.Speed = NumberRange.new(1, 3)
    E.SpreadAngle = Vector2.new(180, 180)
    E.Rotation = NumberRange.new(0, 360)
    E.RotSpeed = NumberRange.new(-90, 90)
    E.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 0)
    })
    E.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    E.Parent = A
end

local function CreateSelectionBox()
    local C, R = Character(), Root()
    if not C or not R then return end

    CreateObject("SelectionBox", "SelectionBox", R, {
        Adornee = C,
        Color3 = Color3.fromRGB(255, 200, 45),
        LineThickness = 0.04,
        SurfaceTransparency = 1
    })
end

local function CreateVietnamText()
    local C = Character()
    local Head = C and C:FindFirstChild("Head")
    if not Head then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "VN_VietnamText"
    Billboard.Size = UDim2.fromOffset(240, 55)
    Billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    Billboard.AlwaysOnTop = true
    Billboard.LightInfluence = 0
    Billboard.Adornee = Head

    local Label = Instance.new("TextLabel")
    Label.Name = "VietnamText"
    Label.Size = UDim2.fromScale(1, 1)
    Label.BackgroundTransparency = 1
    Label.Text = "TÔI YÊU VIỆT NAM"
    Label.TextColor3 = Color3.fromRGB(255, 215, 45)
    Label.TextStrokeColor3 = Color3.fromRGB(160, 0, 0)
    Label.TextStrokeTransparency = 0.15
    Label.TextScaled = true
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Billboard

    Billboard.Parent = Head
    AddEffect("VietnamText", Billboard)
end

local EffectList = {
    {"Rainbow", "Dải cầu vồng", CreateRainbow},
    {"Fire", "Lửa toàn thân", CreateFire},
    {"ShoulderFire", "Lửa trên hai vai", CreateShoulderFire},
    {"Sparkles", "Ánh sáng lấp lánh", CreateSparkles},
    {"Highlight", "Viền phát sáng", CreateHighlight},
    {"Trail", "Vệt sáng chuyển động", CreateTrail},
    {"ForceField", "Lớp bảo vệ", CreateForceField},
    {"Smoke", "Hiệu ứng khói", CreateSmoke},
    {"NeonAura", "Hào quang xanh", CreateAura},
    {"EnergyAura", "Hào quang năng lượng", CreateEnergy},
    {"SelectionBox", "Khung nhân vật", CreateSelectionBox},
    {"VietnamText", "Tôi yêu Việt Nam", CreateVietnamText}
}

TabEffects:CreateSection("Hiệu ứng nhân vật")

for _, Data in ipairs(EffectList) do
    local Name, Label, Callback = unpack(Data)

    TabEffects:CreateToggle({
        Name = Label,
        CurrentValue = false,
        Flag = "Effect_" .. Name,
        Callback = function(Value)
            ToggleEffect(Name, Value, Callback)
        end
    })
end

local BodyParts = {
    Head = {"Head"},
    Torso = {"UpperTorso", "LowerTorso", "Torso"},
    LeftArm = {"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm"},
    RightArm = {"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm"},
    LeftLeg = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg"},
    RightLeg = {"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}
}

local function HideBody(Name, Hide)
    local C = Character()
    if not C then return end

    for _, PartName in ipairs(BodyParts[Name] or {}) do
        local Part = C:FindFirstChild(PartName)

        if Part and Part:IsA("BasePart") then
            if Hide then
                if HiddenParts[Part] == nil then
                    HiddenParts[Part] = Part.LocalTransparencyModifier
                end
                Part.LocalTransparencyModifier = 1
            elseif HiddenParts[Part] ~= nil then
                Part.LocalTransparencyModifier = HiddenParts[Part]
                HiddenParts[Part] = nil
            end
        end
    end
end

local function RestoreBody()
    for Part, Value in pairs(HiddenParts) do
        if Part and Part.Parent then
            Part.LocalTransparencyModifier = Value
        end
    end
    table.clear(HiddenParts)
end

TabBody:CreateSection("Chỉnh sửa cơ thể")

for _, Data in ipairs({
    {"Head", "Ẩn đầu"},
    {"Torso", "Ẩn thân"},
    {"LeftArm", "Ẩn tay trái"},
    {"RightArm", "Ẩn tay phải"},
    {"LeftLeg", "Ẩn chân trái"},
    {"RightLeg", "Ẩn chân phải"}
}) do
    local Name, Label = unpack(Data)

    TabBody:CreateToggle({
        Name = Label,
        CurrentValue = false,
        Flag = "Body_" .. Name,
        Callback = function(Value)
            HideBody(Name, Value)
        end
    })
end

TabBody:CreateButton({
    Name = "Ẩn toàn bộ cơ thể",
    Callback = function()
        for Name in pairs(BodyParts) do
            HideBody(Name, true)
        end
    end
})

TabBody:CreateButton({
    Name = "Khôi phục cơ thể",
    Callback = RestoreBody
})

local AccessoryTypes = {
    {"Hair", "Tóc", Enum.AccessoryType.Hair},
    {"Hat", "Mũ", Enum.AccessoryType.Hat},
    {"Face", "Phụ kiện mặt", Enum.AccessoryType.Face},
    {"Neck", "Phụ kiện cổ", Enum.AccessoryType.Neck},
    {"Shoulder", "Phụ kiện vai", Enum.AccessoryType.Shoulder},
    {"Front", "Phụ kiện trước", Enum.AccessoryType.Front},
    {"Back", "Phụ kiện sau", Enum.AccessoryType.Back},
    {"Waist", "Phụ kiện eo", Enum.AccessoryType.Waist},
    {"Eyebrow", "Lông mày", Enum.AccessoryType.Eyebrow},
    {"Eyelash", "Lông mi", Enum.AccessoryType.Eyelash}
}

local function RestoreAccessories()
    for Part, Data in pairs(HiddenAccessories) do
        if Part and Part.Parent then
            pcall(function()
                if Data.Type == "Part" then
                    Part.LocalTransparencyModifier = Data.Value
                else
                    Part.Transparency = Data.Value
                end
            end)
        end
    end
    table.clear(HiddenAccessories)
end

local function HideAccessory(Accessory)
    for _, Part in ipairs(Accessory:GetDescendants()) do
        if Part:IsA("BasePart") then
            if HiddenAccessories[Part] == nil then
                HiddenAccessories[Part] = {
                    Type = "Part",
                    Value = Part.LocalTransparencyModifier
                }
            end
            Part.LocalTransparencyModifier = 1
        elseif Part:IsA("Decal") or Part:IsA("Texture") then
            if HiddenAccessories[Part] == nil then
                HiddenAccessories[Part] = {
                    Type = "Image",
                    Value = Part.Transparency
                }
            end
            Part.Transparency = 1
        end
    end
end

local function UpdateAccessories()
    RestoreAccessories()

    local C = Character()
    if not C then return end

    for _, Accessory in ipairs(C:GetChildren()) do
        if Accessory:IsA("Accessory") then
            if AccessoryStates.All then
                HideAccessory(Accessory)
            else
                for _, Data in ipairs(AccessoryTypes) do
                    if AccessoryStates[Data[1]]
                        and Accessory.AccessoryType == Data[3] then
                        HideAccessory(Accessory)
                        break
                    end
                end
            end
        end
    end
end

TabAccessories:CreateSection("Chỉnh sửa phụ kiện")

for _, Data in ipairs(AccessoryTypes) do
    local Name, Label = unpack(Data)

    TabAccessories:CreateToggle({
        Name = "Ẩn " .. Label,
        CurrentValue = false,
        Flag = "Accessory_" .. Name,
        Callback = function(Value)
            AccessoryStates[Name] = Value
            UpdateAccessories()
        end
    })
end

TabAccessories:CreateToggle({
    Name = "Ẩn tất cả phụ kiện",
    CurrentValue = false,
    Flag = "Accessory_All",
    Callback = function(Value)
        AccessoryStates.All = Value
        UpdateAccessories()
    end
})

TabAccessories:CreateButton({
    Name = "Khôi phục phụ kiện",
    Callback = function()
        table.clear(AccessoryStates)
        RestoreAccessories()
    end
})

local function SaveAppearance()
    local C = Character()
    if not C then return end

    table.clear(OriginalColors)
    table.clear(AccessoryColors)
    table.clear(OriginalClothes)

    for _, Part in ipairs(C:GetDescendants()) do
        if Part:IsA("BasePart") then
            if Part:FindFirstAncestorWhichIsA("Accessory") then
                AccessoryColors[Part] = Part.Color
            else
                OriginalColors[Part] = Part.Color
            end
        elseif Part:IsA("Shirt") then
            OriginalClothes[Part] = {"Shirt", Part.ShirtTemplate}
        elseif Part:IsA("Pants") then
            OriginalClothes[Part] = {"Pants", Part.PantsTemplate}
        elseif Part:IsA("ShirtGraphic") then
            OriginalClothes[Part] = {"Graphic", Part.Graphic}
        end
    end
end

local function RemoveStar()
    if VietnamStar then
        pcall(function()
            VietnamStar:Destroy()
        end)
        VietnamStar = nil
    end
end

local function RestoreAppearance()
    RemoveStar()

    for Part, Color in pairs(OriginalColors) do
        if Part and Part.Parent then
            pcall(function()
                Part.Color = Color
            end)
        end
    end

    for Part, Color in pairs(AccessoryColors) do
        if Part and Part.Parent then
            pcall(function()
                Part.Color = Color
            end)
        end
    end

    for Part, Data in pairs(OriginalClothes) do
        if Part and Part.Parent then
            pcall(function()
                if Data[1] == "Shirt" then
                    Part.ShirtTemplate = Data[2]
                elseif Data[1] == "Pants" then
                    Part.PantsTemplate = Data[2]
                else
                    Part.Graphic = Data[2]
                end
            end)
        end
    end

    CurrentStyle = nil
end

local function PrepareAppearance()
    if CurrentStyle then
        RestoreAppearance()
    end

    local C = Character()
    if not C then return end

    SaveAppearance()
    return C
end

local function RemoveClothes(C)
    for _, Part in ipairs(C:GetDescendants()) do
        if Part:IsA("Shirt") then
            Part.ShirtTemplate = ""
        elseif Part:IsA("Pants") then
            Part.PantsTemplate = ""
        elseif Part:IsA("ShirtGraphic") then
            Part.Graphic = ""
        end
    end
end

local function CreateVietnamStar(C)
    local Torso = C:FindFirstChild("UpperTorso")
        or C:FindFirstChild("Torso")
        or C:FindFirstChild("LowerTorso")

    if not Torso then return end

    local Gui = Instance.new("SurfaceGui")
    Gui.Name = "VN_VietnamStar"
    Gui.Face = Enum.NormalId.Front
    Gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    Gui.PixelsPerStud = 100
    Gui.AlwaysOnTop = true
    Gui.Parent = Torso

    local Star = Instance.new("TextLabel")
    Star.Name = "Star"
    Star.Size = UDim2.fromScale(1, 1)
    Star.BackgroundTransparency = 1
    Star.Text = "★"
    Star.TextColor3 = Color3.fromRGB(255, 220, 30)
    Star.TextScaled = true
    Star.Font = Enum.Font.GothamBold
    Star.Parent = Gui

    VietnamStar = Gui
end

local function ChangeAppearance(Style)
    local C = PrepareAppearance()
    if not C then return end

    CurrentStyle = Style
    RemoveClothes(C)
    RemoveStar()

    local Skin = Color3.fromRGB(234, 193, 157)
    local Hair = Color3.fromRGB(125, 70, 48)
    local Gray = Color3.fromRGB(180, 180, 180)
    local Yellow = Color3.fromRGB(245, 205, 48)
    local Blue = Color3.fromRGB(13, 105, 172)
    local Green = Color3.fromRGB(75, 151, 75)
    local Red = Color3.fromRGB(218, 37, 29)

    for _, Part in ipairs(C:GetDescendants()) do
        if Part:IsA("BasePart") then
            local Name = Part.Name
            local Accessory = Part:FindFirstAncestorWhichIsA("Accessory")

            if Style == "Bacon" then
                if Accessory then
                    if Accessory.AccessoryType == Enum.AccessoryType.Hair then
                        Part.Color = Hair
                    end
                elseif Name == "Head" or Name:find("Arm")
                    or Name:find("Hand") or Name:find("Leg")
                    or Name:find("Foot") then
                    Part.Color = Skin
                elseif Name == "Torso" or Name == "UpperTorso"
                    or Name == "LowerTorso" then
                    Part.Color = Gray
                end

            elseif Style == "Noob" then
                if not Accessory then
                    if Name == "Head" or Name:find("Arm")
                        or Name:find("Hand") then
                        Part.Color = Yellow
                    elseif Name == "Torso" or Name == "UpperTorso"
                        or Name == "LowerTorso" then
                        Part.Color = Blue
                    elseif Name:find("Leg") or Name:find("Foot") then
                        Part.Color = Green
                    end
                end

            elseif Style == "Vietnam" then
                if not Accessory then
                    Part.Color = Red
                end
            end
        end
    end

    if Style == "Vietnam" then
        CreateVietnamStar(C)
    end
end

TabAppearance:CreateSection("Biến đổi ngoại hình")

TabAppearance:CreateButton({
    Name = "Biến thành Bacon",
    Callback = function()
        ChangeAppearance("Bacon")
    end
})

TabAp
pearance:CreateButton({
    Name = "Biến thành Noob",
    Callback = function()
        ChangeAppearance("Noob")
    end
})

TabAppearance:CreateButton({
    Name = "Biến thành lá cờ Việt Nam",
    Callback = function()
        ChangeAppearance("Vietnam")
    end
})

TabAppearance:CreateButton({
    Name = "Khôi phục ngoại hình ban đầu",
    Callback = RestoreAppearance
})

local function StopAllEffects()
    local Names = {}

    for Name in pairs(Effects) do
        table.insert(Names, Name)
    end

    for _, Name in ipairs(Names) do
        StopEffect(Name)
    end

    if RainbowConnection then
        RainbowConnection:Disconnect()
        RainbowConnection = nil
    end
end

local function RestoreAll()
    StopAllEffects()
    RestoreBody()
    table.clear(AccessoryStates)
    RestoreAccessories()
    RestoreAppearance()
end

TabSettings:CreateSection("Quản lý hệ thống")

TabSettings:CreateButton({
    Name = "Tắt tất cả hiệu ứng",
    Callback = StopAllEffects
})

TabSettings:CreateButton({
    Name = "Khôi phục cơ thể",
    Callback = RestoreBody
})

TabSettings:CreateButton({
    Name = "Khôi phục phụ kiện",
    Callback = function()
        table.clear(AccessoryStates)
        RestoreAccessories()
    end
})

TabSettings:CreateButton({
    Name = "Khôi phục toàn bộ ngoại hình",
    Callback = RestoreAll
})

TabSettings:CreateButton({
    Name = "Xóa giao diện",
    Callback = function()
        if Destroyed then return end
        Destroyed = true

        RestoreAll()

        pcall(function()
            Rayfield:Destroy()
        end)
    end
})

TabSettings:CreateParagraph({
    Title = "TVÀN DZ | HIỆU ỨNG",
    Content = "Script chỉnh sửa ngoại hình và hiệu ứng hiển thị phía máy khách."
})

TabAuthor:CreateSection("Thông tin tác giả")

TabAuthor:CreateParagraph({
    Title = "TVÀN DZ",
    Content = "Tác giả by: Tvàn cte phô mai que và học làm script"
})

TabAuthor:CreateParagraph({
    Title = "TikTok",
    Content = "hoclamscript_roblox"
})

TabAuthor:CreateButton({
    Name = "Copy ID TikTok",
    Callback = function()
        if typeof(setclipboard) == "function" then
            pcall(setclipboard, "hoclamscript_roblox")
        end
    end
})

TabAuthor:CreateParagraph({
    Title = "Discord",
    Content = "Tham gia máy chủ Discord của tác giả"
})

TabAuthor:CreateButton({
    Name = "Copy Link Discord",
    Callback = function()
        if typeof(setclipboard) == "function" then
            pcall(setclipboard, "https://discord.gg/9BW4PvXaJr")
        end
    end
})

TabAuthor:CreateButton({
    Name = "Copy tên tác giả",
    Callback = function()
        if typeof(setclipboard) == "function" then
            pcall(setclipboard, "Tvàn cte phô mai que và học làm script")
        end
    end
})

TabAuthor:CreateButton({
    Name = "Copy toàn bộ thông tin",
    Callback = function()
        if typeof(setclipboard) == "function" then
            pcall(setclipboard,
                "Tác giả: Tvàn cte phô mai que và học làm script\n"
                .. "TikTok: hoclamscript_roblox\n"
                .. "Discord: https://discord.gg/9BW4PvXaJr"
            )
        end
    end
})
