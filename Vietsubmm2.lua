local discordUrl = "https://discord.gg/9BW4PvXaJr"
local ruzHubUrl = "https://raw.githubusercontent.com/Main-Scripts-Ready-V9/Ruz-Hub/refs/heads/main/Mm2.lua"
local yarhmUrl = "https://raw.githubusercontent.com/xn7-ui/MM2/refs/heads/main/Mm2.script"

local translations = {
    ["Kill closest player as murderer"] = "Chém đứa gần nhất (Sát nhân)",
    ["Murderer kill aura"] = "Tự chém người xung quanh",
    ["Kill EVERYONE as murderer"] = "Chém sạch cả phòng",
    ["Hold everyone hostage"] = "Giữ tất cả làm con tin",
    ["Ignore knife throws (doesn't work)"] = "Bỏ qua dao bay (Đang lỗi)",
    ["God mode (Very, VERY UNSTABLE)"] = "Chế độ Bất tử (Dễ văng game)",
    ["Fling Murderer"] = "Hất văng Sát nhân",
    ["Fling Sheriff"] = "Hất văng Cảnh sát",
    ["Copy murderer username"] = "Coppy tên Sát nhân",
    ["Copy sheriff username"] = "Coppy tên Cảnh sát",
    ["Teleport to dropped gun"] = "Biến tới chỗ súng rơi",
    ["Automatically get gun on drop"] = "Tự nhặt súng khi rơi",
    ["Experimental dropped gun take"] = "Thử nghiệm nhặt súng rơi",
    ["Detectables"] = "Tính năng dễ bị phát hiện",
    ["Instakill murderer as sheriff"] = "Bắn chết Sát nhân ngay",
    ["Spawn knife throw near player"] = "Tạo dao ném sát người chơi",
    ["Send Sheriff and Murderer names into chat"] = "Chat tên Cảnh sát & Sát nhân",
    ["Teleport to map"] = "Biến vào map",
    ["Teleport to lobby"] = "Biến về sảnh",
    ["Shoot position offset"] = "Độ lệch vị trí bắn",
    ["Offset-to-ping multiplier"] = "Chỉnh lệch theo ping",
    ["Round timer"] = "Đồng hồ đếm giờ",
    ["Shoot murderer"] = "Bắn Sát nhân",
    ["Knife throw to closest"] = "Phi dao vào đứa gần nhất",
    ["Auto knife throw"] = "Tự động phi dao",
    ["Delayed shoot murderer"] = "Bắn Sát nhân (Delay)",
    ["Players"] = "Người chơi",
    ["Traps"] = "Bẫy",
    ["Dropped Gun"] = "Súng rơi",
    ["Hide my own ESP"] = "Ẩn định vị bản thân",
    ["Hide YARHM"] = "Ẩn YARHM",
    ["FPS Boost"] = "Tăng FPS / Giảm lag",
    ["Reclip"] = "Bật lại va chạm",
    ["Noclip"] = "Đi xuyên tường",
    ["Other"] = "Khác",
    ["Get ping"] = "Xem Ping",
    ["Open developer console (debugging)"] = "Mở bảng console",
    ["Theme"] = "Giao diện",
    ["Theme code"] = "Mã giao diện",
    ["Apply"] = "Áp dụng",
    ["Reload theme"] = "Tải lại giao diện",
    ["Delete theme from save"] = "Xóa giao diện đã lưu",
    ["Fly"] = "Bay",
    ["OP Fly"] = "Bay siêu mượt",
    ["Fly speed"] = "Tốc độ bay",
    ["Jumping"] = "Nhảy",
    ["Infinite jump"] = "Nhảy vô hạn",
    ["Limit infinite jump to 2 jumps only"] = "Giới hạn nhảy 2 lần",
    ["Hitbox mod"] = "Chỉnh Hitbox",
    ["Hitbox expander"] = "Mở rộng Hitbox",
    ["Expand everyone's hitbox"] = "Bật Hitbox tất cả người chơi",
    ["Loop hitbox expansion"] = "Lặp lại mở rộng Hitbox",
    ["Aggressive hitbox expansion (all parts)"] = "Mở rộng Hitbox toàn thân",
    ["Speed and view"] = "Tốc độ & Tầm nhìn",
    ["Walkspeed"] = "Tốc độ chạy",
    ["Set speed"] = "Đặt tốc độ",
    ["Increase walkspeed"] = "Tăng tốc độ",
    ["Decrease walkspeed"] = "Giảm tốc độ",
    ["Walkspeed increment (How big each increase/decrease is)"] = "Mức độ tăng/giảm",
    ["Set"] = "Cài đặt",
    ["FOV change"] = "Đổi FOV",
    ["Set FOV"] = "Đặt FOV",
    ["Loop walkspeed and FOV"] = "Khóa tốc độ & FOV",
    ["Teleports"] = "Dịch chuyển",
    ["Enter player's name"] = "Nhập tên người chơi",
    ["Teleport"] = "Dịch chuyển",
    ["Spectate players"] = "Xem người chơi",
    ["Aim locking"] = "Khóa tâm",
    ["Target player"] = "Chọn mục tiêu",
    ["Set target"] = "Khóa mục tiêu",
    ["Aim lock"] = "Bật khóa tâm",
    ["Unaim lock"] = "Tắt khóa tâm",
    ["Target fling player"] = "Hất văng người chọn",
    ["Anti-fling"] = "Chống hất văng",
    ["Miscellaneous"] = "Linh tinh",
    ["Anti AFK detection"] = "Chống văng khi treo máy",
    ["Player"] = "Nhân vật",
    ["Visual"] = "Hiệu ứng",
    ["ESP"] = "Định vị (ESP)",
    ["Combat"] = "Chiến đấu",
    ["Skills"] = "Kỹ năng",
    ["Utilities"] = "Tiện ích",
    ["Config"] = "Cài đặt",
    ["UI Settings"] = "Cài đặt menu",
    ["Hide Key"] = "Nút ẩn/hiện menu",
    ["UI Size"] = "Cỡ menu",
    ["Notifications"] = "Thông báo",
    ["Config Manager"] = "Quản lý cấu hình",
    ["Select Config"] = "Chọn cấu hình",
    ["Run Config"] = "Chạy cấu hình",
    ["Config Name"] = "Tên cấu hình",
    ["Set New Config"] = "Lưu cấu hình mới",
    ["Auto Load Config"] = "Tự bật cấu hình",
    ["Run"] = "Chạy",
    ["Save"] = "Lưu",
    ["Attach"] = "Cài phím",
    ["None"] = "Chưa chọn",
    ["Bomb"] = "Bom",
    ["Free Gold Bomb"] = "Bom vàng miễn phí",
    ["Bomb Jump"] = "Tập nhảy bằng bom",
    ["Gold Bomb Jump"] = "Nhảy bằng bom vàng",
    ["Fireflies"] = "Đom đốm",
    ["Fireflies Jump Helper"] = "Hỗ trợ nhảy đom đốm",
    ["Grab Gun"] = "Nhặt súng",
    ["Auto Grab Gun"] = "Tự động nhặt súng",
    ["Keybind"] = "Gán phím",
    ["Fling Murderer 1 Time"] = "Hất văng Sát nhân 1 lần",
    ["Fling Sheriff 1 Time"] = "Hất văng Cảnh sát 1 lần",
    ["Anti Fling"] = "Chống hất (fling)",
    ["Wallhop"] = "Nhảy tường",
    ["Auto Wallhop"] = "Tự động nhảy tường",
    ["Silent Aim"] = "Tự ngắm ẩn (Silent Aim)",
    ["Silent Aim Enabled"] = "Bật ngắm",
    ["Silent Aim Method"] = "Kiểu ngắm",
    ["FOV Visible"] = "Hiện vòng FOV",
    ["FOV Color"] = "Màu vòng FOV",
    ["FOV Size"] = "Kích thước vòng FOV",
    ["Screen Buttons"] = "Nút trên màn hình",
    ["Prediction"] = "Đón đầu hướng đi",
    ["Murderer"] = "Sát nhân",
    ["Hold Everyone As Hostage"] = "Bắt làm con tin",
    ["Hitbox Expander"] = "Phóng to Hitbox",
    ["Hitbox Actived"] = "Bật Hitbox",
    ["Load Shoot / Throw Button"] = "Hiện nút Bắn / Ném",
    ["Shoot Style"] = "Kiểu bắn",
    ["Camlock"] = "Khóa camera",
    ["Load Camlock Button"] = "Hiện nút khóa camera",
    ["Self ESP"] = "Soi bản thân",
    ["Style"] = "Kiểu hiển thị",
    ["Highlight"] = "Tô màu nổi bật",
    ["Corner Box"] = "Khung góc",
    ["Skeleton"] = "Hiện khung xương",
    ["Items"] = "Vật phẩm",
    ["Dropped Gun ESP"] = "Soi súng rơi",
    ["Walk Speed"] = "Tốc độ chạy",
    ["Walk Speed Enabled"] = "Bật chỉnh tốc độ",
    ["Jump Power"] = "Lực nhảy",
    ["Jump Power Enabled"] = "Bật chỉnh lực nhảy",
    ["NoClip Enabled"] = "Bật đi xuyên tường",
    ["Load NoClip Button"] = "Hiện nút xuyên tường",
    ["Infinite Jump Enabled"] = "Bật nhảy vô hạn",
    ["Fly Enabled"] = "Bật bay",
    ["Fly Speed"] = "Tốc độ bay",
    ["Load Fly Button"] = "Hiện nút bay",
    ["Camera"] = "Góc nhìn",
    ["FOV Enabled"] = "Bật chỉnh FOV",
    ["Field of View"] = "Tầm nhìn (FOV)",
    ["Crosshair"] = "Tâm bắn",
    ["Custom Crosshair"] = "Tâm bắn tùy chỉnh",
    ["Select Crosshair"] = "Chọn kiểu tâm",
    ["Crosshair Size"] = "Cỡ tâm bắn",
    ["Crosshair Spin"] = "Xoay tâm bắn",
    ["Spin Speed"] = "Tốc độ xoay tâm",
    ["Custom Texture ID"] = "ID ảnh nền tùy chỉnh",
    ["Custom Skybox"] = "Bầu trời tùy chỉnh",
    ["Select Skybox"] = "Chọn kiểu bầu trời",
    ["VFX Aura"] = "Hào quang hiệu ứng",
    ["Aura Enabled"] = "Bật hào quang",
    ["Aura Type"] = "Loại hào quang",
    ["Reset Aura Color"] = "Đặt lại màu hào quang",
    ["Aura Color"] = "Màu hào quang",
    ["Refresh Aura"] = "Làm mới hào quang",
    ["Gun Visuals"] = "Hiệu ứng súng",
    ["Beam Color Changer"] = "Đổi màu đường đạn",
    ["Beam Color"] = "Màu đường đạn",
    ["Reset Beam Color"] = "Đặt lại màu đường đạn",
    ["Beam Width"] = "Độ rộng đường đạn",
    ["Beam VFX"] = "Hiệu ứng đường đạn",
    ["Beam VFX Preset"] = "Mẫu đường đạn",
    ["Knife Visuals"] = "Hiệu ứng dao",
    ["Two-Handed Knife"] = "Cầm dao 2 tay",
    ["Two-Handed Gun"] = "Cầm súng 2 tay",
    ["Custom Shoot Sound"] = "Âm thanh bắn tùy chỉnh",
    ["Shoot Sound Preset"] = "Mẫu tiếng bắn",
    ["Old Gun Equip Sound"] = "Tiếng rút súng cũ",
    ["No Reload Animation"] = "Tắt dáng nạp đạn",
    ["Environment"] = "Cảnh quan",
    ["Stretch Screen"] = "Kéo giãn màn hình",
    ["Stretch Amount"] = "Mức độ kéo giãn",
    ["ESP Enabled"] = "Bật soi vị trí (ESP)",
    ["Roles"] = "Phe",
    ["Murderer ESP"] = "đvị Sát nhân",
    ["Sheriff ESP"] = "đvị Cảnh sát",
    ["Innocent ESP"] = "định vị"
}

local function runVietsubEngine()
    local coreContainer = (gethui and gethui()) or game:GetService("CoreGui")
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local function processText(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if translations[obj.Text] then
                obj.Text = translations[obj.Text]
            end
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                if translations[obj.Text] then
                    obj.Text = translations[obj.Text]
                end
            end)
        end
    end

    local function scanAndTranslate(container)
        for _, obj in ipairs(container:GetDescendants()) do
            processText(obj)
        end
        container.DescendantAdded:Connect(function(obj)
            task.wait(0.05)
            processText(obj)
        end)
    end

    scanAndTranslate(coreContainer)
    scanAndTranslate(playerGui)
end

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TvanVietsubHubPremium"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

local function makeCornerText(text, xAlign, yAlign)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(0, 230, 255)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0.6

    if xAlign == "Left" then
        lbl.Position = UDim2.new(0, 10, yAlign == "Top" and 0 or 1, yAlign == "Top" and 10 or -28)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    else
        lbl.Position = UDim2.new(1, -190, yAlign == "Top" and 0 or 1, yAlign == "Top" and 10 or -28)
        lbl.TextXAlignment = Enum.TextXAlignment.Right
    end

    lbl.Parent = screenGui
end

makeCornerText("Tác giả Vietsub Tvàn", "Left", "Top")
makeCornerText("Học làm script", "Right", "Top")
makeCornerText("Học làm script", "Left", "Bottom")
makeCornerText("Tác giả Vietsub Tvàn", "Right", "Bottom")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 310)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -155)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Transparency = 0.3
stroke.Parent = mainFrame

local headerBar = Instance.new("Frame")
headerBar.Size = UDim2.new(1, 0, 0, 42)
headerBar.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
headerBar.BorderSizePixel = 0
headerBar.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = headerBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "TVÀN PREMIUM HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = headerBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0.9, 0, 0, 32)
tabContainer.Position = UDim2.new(0.05, 0, 0.17, 0)
tabContainer.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
tabContainer.Parent = mainFrame

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = tabContainer

local tabRuz = Instance.new("TextButton")
tabRuz.Size = UDim2.new(0.48, 0, 0.84, 0)
tabRuz.Position = UDim2.new(0.01, 0, 0.08, 0)
tabRuz.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
tabRuz.Text = "RuzHub"
tabRuz.TextColor3 = Color3.fromRGB(255, 255, 255)
tabRuz.TextSize = 11
tabRuz.Font = Enum.Font.GothamBold
tabRuz.Parent = tabContainer

local tabRuzCorner = Instance.new("UICorner")
tabRuzCorner.CornerRadius = UDim.new(0, 6)
tabRuzCorner.Parent = tabRuz

local tabYarhm = Instance.new("TextButton")
tabYarhm.Size = UDim2.new(0.48, 0, 0.84, 0)
tabYarhm.Position = UDim2.new(0.51, 0, 0.08, 0)
tabYarhm.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
tabYarhm.Text = "YARHM"
tabYarhm.TextColor3 = Color3.fromRGB(150, 150, 170)
tabYarhm.TextSize = 11
tabYarhm.Font = Enum.Font.GothamBold
tabYarhm.Parent = tabContainer

local tabYarhmCorner = Instance.new("UICorner")
tabYarhmCorner.CornerRadius = UDim.new(0, 6)
tabYarhmCorner.Parent = tabYarhm

local contentRuz = Instance.new("Frame")
contentRuz.Size = UDim2.new(0.9, 0, 0.38, 0)
contentRuz.Position = UDim2.new(0.05, 0, 0.30, 0)
contentRuz.BackgroundTransparency = 1
contentRuz.Visible = true
contentRuz.Parent = mainFrame

local contentYarhm = Instance.new("Frame")
contentYarhm.Size = UDim2.new(0.9, 0, 0.38, 0)
contentYarhm.Position = UDim2.new(0.05, 0, 0.30, 0)
contentYarhm.BackgroundTransparency = 1
contentYarhm.Visible = false
contentYarhm.Parent = mainFrame

local function createStyledBtn(parent, text, pos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

createStyledBtn(contentRuz, "⚡ CHẠY RUZHUB No key(VIETSUB)", UDim2.new(0, 0, 0, 5), Color3.fromRGB(0, 150, 255), function()
    loadstring(game:HttpGet(ruzHubUrl))()
    task.wait(1)
    runVietsubEngine()
    mainFrame.Visible = false
end)

createStyledBtn(contentRuz, "🌐 CHẠY RUZHUB (TIẾNG ANH)", UDim2.new(0, 0, 0, 50), Color3.fromRGB(35, 38, 52), function()
    loadstring(game:HttpGet(ruzHubUrl))()
    mainFrame.Visible = false
end)

createStyledBtn(contentYarhm, "⚡ CHẠY YARHM No key (VIETSUB)", UDim2.new(0, 0, 0, 5), Color3.fromRGB(140, 60, 255), function()
    loadstring(game:HttpGet(yarhmUrl))()
    task.wait(1)
    runVietsubEngine()
    mainFrame.Visible = false
end)

createStyledBtn(contentYarhm, "🌐 CHẠY YARHM (TIẾNG ANH)", UDim2.new(0, 0, 0, 50), Color3.fromRGB(35, 38, 52), function()
    loadstring(game:HttpGet(yarhmUrl))()
    mainFrame.Visible = false
end)

local function createBottomBtn(text, pos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 34)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = mainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

createBottomBtn("💬 VÀO SERVER DISCORD", UDim2.new(0.05, 0, 0.70, 0), Color3.fromRGB(88, 101, 242), function()
    if setclipboard then
        setclipboard(discordUrl)
    end
    if request then
        request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["Origin"] = "https://discord.com"},
            Body = game:GetService("HttpService"):JSONEncode({cmd = "INVITE_BROWSER", args = {code = "9BW4PvXaJr"}, nonce = game:GetService("HttpService"):GenerateGUID(false)})
        })
    end
end)

createBottomBtn("📋 COPY LINK DISCORD", UDim2.new(0.05, 0, 0.83, 0), Color3.fromRGB(35, 160, 100), function()
    if setclipboard then
        setclipboard(discordUrl)
    end
end)

tabRuz.MouseButton1Click:Connect(function()
    contentRuz.Visible = true
    contentYarhm.Visible = false
    tabRuz.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    tabRuz.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabYarhm.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    tabYarhm.TextColor3 = Color3.fromRGB(150, 150, 170)
end)

tabYarhm.MouseButton1Click:Connect(function()
    contentRuz.Visible = false
    contentYarhm.Visible = true
    tabYarhm.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
    tabYarhm.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabRuz.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    tabRuz.TextColor3 = Color3.fromRGB(150, 150, 170)
end)
