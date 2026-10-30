local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ITEM_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso",
	"LeftArm", "RightArm", "LeftLeg", "RightLeg",
	"IdleAnimation", "WalkAnimation", "RunAnimation", "JumpAnimation",
	"FallAnimation", "ClimbAnimation", "SwimAnimation",
}
local COLOR_PROPS = {
	"HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor",
}
local SCALE_PROPS = {
	"HeightScale", "WidthScale", "DepthScale", "HeadScale", "BodyTypeScale", "ProportionScale",
}
local ID_LABELS = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso",
	"LeftArm", "RightArm", "LeftLeg", "RightLeg",
}

local saved = nil
local busy = false
local autoApply = true
local collapsed = false
local connections = {}

local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function short(err)
	return string.sub(tostring(err), 1, 90)
end

local function capture(humanoid)
	local desc = humanoid:GetAppliedDescription()
	local data = { Items = {}, Colors = {}, Scales = {}, Accessories = {} }
	for _, p in ipairs(ITEM_PROPS) do
		data.Items[p] = desc[p]
	end
	for _, p in ipairs(COLOR_PROPS) do
		data.Colors[p] = desc[p]
	end
	for _, p in ipairs(SCALE_PROPS) do
		data.Scales[p] = desc[p]
	end
	for _, a in ipairs(desc:GetAccessories(true)) do
		table.insert(data.Accessories, {
			AssetId = a.AssetId,
			AccessoryType = a.AccessoryType,
			Order = a.Order,
			Puffiness = a.Puffiness,
			IsLayered = a.IsLayered,
		})
	end
	return data
end

local function build(data)
	local desc = Instance.new("HumanoidDescription")
	for k, v in pairs(data.Items) do
		desc[k] = v
	end
	for k, v in pairs(data.Colors) do
		desc[k] = v
	end
	for k, v in pairs(data.Scales) do
		desc[k] = v
	end
	desc:SetAccessories(data.Accessories, true)
	return desc
end

local function apply(humanoid, data)
	local desc = build(data)
	local ok, err = pcall(function()
		humanoid:ApplyDescription(desc)
	end)
	if ok then
		return true
	end
	local ok2 = pcall(function()
		humanoid:ApplyDescriptionReset(desc)
	end)
	if ok2 then
		return true
	end
	return false, err
end

local function idsText(data)
	local lines = {}
	for _, p in ipairs(ID_LABELS) do
		local id = data.Items[p]
		if id and id ~= 0 then
			table.insert(lines, p .. ": " .. id)
		end
	end
	for _, a in ipairs(data.Accessories) do
		table.insert(lines, a.AccessoryType.Name .. ": " .. a.AssetId)
	end
	return table.concat(lines, "\n")
end

local gui = Instance.new("ScreenGui")
gui.Name = "SkinGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(1, -200, 0.5, -150)
frame.Size = UDim2.fromOffset(190, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.ClipsDescendants = true
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local frameLayout = Instance.new("UIListLayout", frame)
frameLayout.SortOrder = Enum.SortOrder.LayoutOrder

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
titleBar.BorderSizePixel = 0
titleBar.LayoutOrder = 1
titleBar.Parent = frame

local dragArea = Instance.new("TextLabel")
dragArea.Size = UDim2.new(1, -72, 1, 0)
dragArea.BackgroundTransparency = 1
dragArea.Text = "  👕 Skin"
dragArea.Font = Enum.Font.GothamBold
dragArea.TextSize = 15
dragArea.TextColor3 = Color3.new(1, 1, 1)
dragArea.TextXAlignment = Enum.TextXAlignment.Left
dragArea.Parent = titleBar

local collapseBtn = Instance.new("TextButton")
collapseBtn.AnchorPoint = Vector2.new(1, 0.5)
collapseBtn.Position = UDim2.new(1, -38, 0.5, 0)
collapseBtn.Size = UDim2.fromOffset(30, 26)
collapseBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
collapseBtn.Text = "–"
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 18
collapseBtn.TextColor3 = Color3.new(1, 1, 1)
collapseBtn.Parent = titleBar
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -4, 0.5, 0)
closeBtn.Size = UDim2.fromOffset(30, 26)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 0, 0)
content.AutomaticSize = Enum.AutomaticSize.Y
content.BackgroundTransparency = 1
content.LayoutOrder = 2
content.Parent = frame

local pad = Instance.new("UIPadding", content)
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeButton(text, color, order, height)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, height or 44)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.LayoutOrder = order
	b.Parent = content
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local saveBtn = makeButton("💾 Lưu skin", Color3.fromRGB(40, 150, 70), 1)
local loadBtn = makeButton("👕 Mang lại skin", Color3.fromRGB(50, 110, 200), 2)
local autoBtn = makeButton("", Color3.fromRGB(40, 150, 70), 3, 36)
autoBtn.TextSize = 14

local function refreshAutoBtn()
	if autoApply then
		autoBtn.Text = "🔄 Tự động: BẬT"
		autoBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
	else
		autoBtn.Text = "🔄 Tự động: TẮT"
		autoBtn.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
	end
end
refreshAutoBtn()

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 38)
status.BackgroundTransparency = 1
status.Text = ""
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(230, 230, 230)
status.LayoutOrder = 4
status.Parent = content

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, 0, 0, 100)
box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Code
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextWrapped = true
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = false
box.Text = ""
box.PlaceholderText = "Id asset sẽ hiện ở đây"
box.LayoutOrder = 5
box.Parent = content
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local function loadSkin(humanoid, isAuto)
	busy = true
	status.Text = isAuto and "Đang tự mặc skin..." or "Đang mặc..."
	local ok, err = apply(humanoid, saved)
	if ok then
		box.Text = idsText(saved)
		status.Text = isAuto and "Đã tự mặc skin!" or "Đã mang lại skin!"
	else
		status.Text = "Mặc skin thất bại: " .. short(err)
	end
	busy = false
end

saveBtn.Activated:Connect(function()
	if busy then
		return
	end
	local hum = getHumanoid()
	if not hum then
		status.Text = "Chưa có nhân vật"
		return
	end
	busy = true
	local ok, result = pcall(capture, hum)
	if ok then
		saved = result
		box.Text = idsText(result)
		status.Text = "Đã lưu skin!"
	else
		status.Text = "Không lấy được id: " .. short(result)
	end
	busy = false
end)

loadBtn.Activated:Connect(function()
	if busy then
		return
	end
	if not saved then
		status.Text = "Chưa có skin nào được lưu"
		return
	end
	local hum = getHumanoid()
	if not hum then
		status.Text = "Chưa có nhân vật"
		return
	end
	loadSkin(hum, false)
end)

autoBtn.Activated:Connect(function()
	autoApply = not autoApply
	refreshAutoBtn()
	status.Text = autoApply and "Đã bật tự động mặc skin" or "Đã tắt tự động mặc skin"
end)

collapseBtn.Activated:Connect(function()
	collapsed = not collapsed
	content.Visible = not collapsed
	collapseBtn.Text = collapsed and "+" or "–"
end)

closeBtn.Activated:Connect(function()
	autoApply = false
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	gui:Destroy()
end)

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

dragArea.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.AbsolutePosition
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

dragArea.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if not dragging or input ~= dragInput then
		return
	end
	local delta = input.Position - dragStart
	local screen = gui.AbsoluteSize
	local x = math.clamp(startPos.X + delta.X, 0, math.max(0, screen.X - frame.AbsoluteSize.X))
	local y = math.clamp(startPos.Y + delta.Y, 0, math.max(0, screen.Y - 34))
	frame.Position = UDim2.fromOffset(x, y)
end))

local function onCharacter(char)
	if not autoApply or not saved then
		return
	end
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end
	local startTime = os.clock()
	while not player:HasAppearanceLoaded() and os.clock() - startTime < 10 do
		task.wait(0.2)
	end
	task.wait(0.5)
	if not autoApply or not saved or player.Character ~= char then
		return
	end
	while busy do
		task.wait(0.2)
	end
	loadSkin(hum, true)
end

table.insert(connections, player.CharacterAdded:Connect(onCharacter))

task.spawn(function()
	local thanks = Instance.new("TextLabel")
	thanks.AnchorPoint = Vector2.new(0.5, 0.5)
	thanks.Position = UDim2.fromScale(0.5, 0.5)
	thanks.Size = UDim2.fromOffset(340, 60)
	thanks.BackgroundTransparency = 1
	thanks.Text = "Cảm ơn bạn nhiều ❤️"
	thanks.Font = Enum.Font.GothamBold
	thanks.TextSize = 32
	thanks.TextColor3 = Color3.new(1, 1, 1)
	thanks.TextTransparency = 1
	thanks.TextStrokeColor3 = Color3.new(0, 0, 0)
	thanks.TextStrokeTransparency = 1
	thanks.Parent = gui

	local fadeIn = TweenService:Create(thanks, TweenInfo.new(0.6), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.4,
	})
	fadeIn:Play()
	fadeIn.Completed:Wait()
	task.wait(1.5)

	local fadeOut = TweenService:Create(thanks, TweenInfo.new(0.6), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fadeOut:Play()
	fadeOut.Completed:Wait()
	thanks:Destroy()

	frame.Visible = true
end)
