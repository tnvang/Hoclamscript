local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local NguoiChoi = Players.LocalPlayer
local MaGame = game.PlaceId
local MaServer = game.JobId

local TuDongItNguoi = false
local DangHop = false
local ChanServer = {[MaServer] = true}

local TikTok = "hoclamScript_roblox"
local Discord = "https://discord.gg/9BW4PvXaJr"

local CuaSo = Rayfield:CreateWindow({
    Name = "RidKid Hub",
    Icon = 0,
    LoadingTitle = "RIDKID HUB",
    LoadingSubtitle = "Công cụ đổi server",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = false
    }
})

local Gui = Instance.new("ScreenGui")
Gui.Name = "DiscordGoc"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = CoreGui

local function TaoChu(vitri)
    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(0, 150, 0, 22)
    Text.Position = vitri
    Text.BackgroundTransparency = 1
    Text.Text = "Hãy vào server Discord tui"
    Text.TextSize = 11
    Text.Font = Enum.Font.GothamMedium
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextStrokeTransparency = 0.6
    Text.TextXAlignment = Enum.TextXAlignment.Center
    Text.Parent = Gui
end

TaoChu(UDim2.new(0, 4, 0, 4))
TaoChu(UDim2.new(1, -154, 0, 4))
TaoChu(UDim2.new(0, 4, 1, -26))
TaoChu(UDim2.new(1, -154, 1, -26))

local function ThongBao(noiDung)
    Rayfield:Notify({
        Title = "RidKid Hub",
        Content = noiDung,
        Duration = 3
    })
end

local function LayServer(boQua)
    boQua = boQua or ""

    local urls = {
        ("https://games.roproxy.com/v1/games/%s/servers/0?sortOrder=Asc&limit=100&cursor=%s"):format(MaGame, boQua),
        ("https://games.roblox.com/v1/games/%s/servers/0?sortOrder=Asc&limit=100&cursor=%s"):format(MaGame, boQua)
    }

    for _, url in ipairs(urls) do
        local ok, ketQua = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and ketQua then
            local thanhCong, duLieu = pcall(function()
                return HttpService:JSONDecode(ketQua)
            end)

            if thanhCong and duLieu and duLieu.data then
                return duLieu.data, duLieu.nextPageCursor
            end
        end
    end

    return nil
end

local function VaoServer(maServer)
    if not maServer or maServer == "" then
        ThongBao("Mã server không hợp lệ!")
        return false
    end

    if maServer == MaServer then
        ThongBao("Bạn đang ở server này!")
        return false
    end

    ChanServer[maServer] = true

    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            MaGame,
            maServer,
            NguoiChoi
        )
    end)

    if ok then
        ThongBao("Đang chuyển server...")
        return true
    end

    ThongBao("Không thể chuyển server!")
    return false
end

local function TimServerItNguoi()
    local boQua = ""

    for _ = 1, 3 do
        local danhSach, trangTiep = LayServer(boQua)

        if not danhSach then
            task.wait(1)
        else
            local ketQua = {}

            for _, server in ipairs(danhSach) do
                if server.id ~= MaServer
                    and not ChanServer[server.id]
                    and server.playing >= 1
                    and server.playing <= 3
                    and server.playing < server.maxPlayers then

                    table.insert(ketQua, server)
                end
            end

            table.sort(ketQua, function(a, b)
                return a.playing < b.playing
            end)

            if #ketQua > 0 then
                return ketQua[1]
            end

            if not trangTiep or trangTiep == "" then
                break
            end

            boQua = trangTiep
        end
    end

    return nil
end

local function TimServerDongNguoi()
    local danhSach = LayServer("")

    if not danhSach then
        return nil
    end

    local ketQua = {}

    for _, server in ipairs(danhSach) do
        if server.id ~= MaServer
            and not ChanServer[server.id]
            and server.playing < server.maxPlayers then

            table.insert(ketQua, server)
        end
    end

    table.sort(ketQua, function(a, b)
        return a.playing > b.playing
    end)

    return ketQua[1]
end

local function HopItNguoi()
    if DangHop then
        return
    end

    DangHop = true

    local server = TimServerItNguoi()

    if server then
        ThongBao("Đã tìm thấy server " .. server.playing .. " người!")
        VaoServer(server.id)
    else
        ThongBao("Không tìm thấy server 1-3 người!")
    end

    DangHop = false
end

local function HopDongNguoi()
    if DangHop then
        return
    end

    DangHop = true
    ThongBao("Đang tìm server đông người...")

    local server = TimServerDongNguoi()

    if server then
        ThongBao("Đã tìm thấy server " .. server.playing .. " người!")
        VaoServer(server.id)
    else
        ThongBao("Không tìm thấy server phù hợp!")
    end

    DangHop = false
end

local function TuDongTimServer()
    if DangHop then
        return
    end

    DangHop = true

    while TuDongItNguoi do
        local server = TimServerItNguoi()

        if not TuDongItNguoi then
            break
        end

        if server then
            ThongBao("Đã tìm thấy server " .. server.playing .. " người!")
            VaoServer(server.id)
            break
        end

        ThongBao("Không tìm thấy, đang thử lại...")
        task.wait(4)
    end

    DangHop = false
end

local TabDoiServer = CuaSo:CreateTab("Đổi Server", 4483362458)

TabDoiServer:CreateSection("TỰ ĐỘNG ĐỔI SERVER")

TabDoiServer:CreateToggle({
    Name = "Tự động tìm server 1-3 người",
    CurrentValue = false,
    Callback = function(giaTri)
        TuDongItNguoi = giaTri

        if giaTri then
            task.spawn(TuDongTimServer)
        end
    end
})

TabDoiServer:CreateParagraph({
    Title = "Hướng dẫn",
    Content = "Bật chức năng này để tự động tìm server có từ 1 đến 3 người. Hệ thống sẽ bỏ qua server hiện tại và server đã thử."
})

TabDoiServer:CreateSection("ĐỔI SERVER THỦ CÔNG")

TabDoiServer:CreateButton({
    Name = "Hop vào server ít người",
    Callback = function()
        task.spawn(HopItNguoi)
    end
})

TabDoiServer:CreateParagraph({
    Title = "Server ít người",
    Content = "Nhấn nút trên để tìm server có từ 1 đến 3 người."
})

TabDoiServer:CreateButton({
    Name = "Hop vào server đông người",
    Callback = function()
        task.spawn(HopDongNguoi)
    end
})

TabDoiServer:CreateParagraph({
    Title = "Server đông người",
    Content = "Nhấn nút trên để tìm server còn chỗ và có nhiều người chơi nhất trong danh sách được tải."
})

TabDoiServer:CreateSection("SERVER HIỆN TẠI")

TabDoiServer:CreateParagraph({
    Title = "Thông tin",
    Content = "Mã server: " .. string.sub(MaServer, 1, 12) ..
        "...\nNgười chơi: " ..
        #Players:GetPlayers() ..
        "/" ..
        Players.MaxPlayers
})

local TabDanhSach = CuaSo:CreateTab("Danh Sách Server", 4483362458)

TabDanhSach:CreateSection("VÀO SERVER BẰNG MÃ")

local MaServerNhap = ""

TabDanhSach:CreateInput({
    Name = "Mã Server / JobId",
    PlaceholderText = "Nhập mã server...",
    RemoveTextAfterFocusLost = false,
    Callback = function(giaTri)
        MaServerNhap = giaTri
    end
})

TabDanhSach:CreateButton({
    Name = "Vào server bằng mã",
    Callback = function()
        local ma = MaServerNhap:match("^%s*(.-)%s*$")

        if ma == "" then
            ThongBao("Vui lòng nhập mã server!")
            return
        end

        VaoServer(ma)
    end
})

TabDanhSach:CreateSection("DANH SÁCH SERVER")

TabDanhSach:CreateParagraph({
    Title = "Cách cập nhật",
    Content = "Nhấn nút 'Cập nhật danh sách server' để tải lại danh sách server mới. Nhấn vào một server để tham gia."
})

TabDanhSach:CreateButton({
    Name = "Cập nhật danh sách server",
    Callback = function()
        local danhSach = LayServer("")

        if not danhSach then
            ThongBao("Không thể tải danh sách server!")
            return
        end

        table.sort(danhSach, function(a, b)
            return a.playing < b.playing
        end)

        for _, server in ipairs(danhSach) do
            local ma = server.id

            TabDanhSach:CreateButton({
                Name = string.format(
                    "[%d/%d] %s",
                    server.playing,
                    server.maxPlayers,
                    string.sub(ma, 1, 8)
                ),
                Callback = function()
                    VaoServer(ma)
                end
            })

            TabDanhSach:CreateButton({
                Name = "Sao chép mã " .. string.sub(ma, 1, 8),
                Callback = function()
                    if setclipboard then
                        local ok = pcall(function()
                            setclipboard(ma)
                        end)

                        if ok then
                            ThongBao("Đã sao chép mã server!")
                        else
                            ThongBao("Không thể sao chép!")
                        end
                    else
                        ThongBao("Trình chạy không hỗ trợ sao chép!")
                    end
                end
            })
        end

        ThongBao("Đã cập nhật danh sách server!")
    end
})

local TabTacGia = CuaSo:CreateTab("Tác Giả", 4483362458)

TabTacGia:CreateSection("RIDKID HUB")

TabTacGia:CreateParagraph({
    Title = "Học làm script",
    Content = "Chia sẻ script, kiến thức Roblox và hỗ trợ lập trình."
})

TabTacGia:CreateSection("TIKTOK")

TabTacGia:CreateParagraph({
    Title = "ID TikTok",
    Content = "hoclamScript_roblox"
})

TabTacGia:CreateButton({
    Name = "Sao chép ID TikTok",
    Callback = function()
        if setclipboard then
            local ok = pcall(function()
                setclipboard(TikTok)
            end)

            if ok then
                ThongBao("Đã sao chép ID TikTok!")
            else
                ThongBao("Không thể sao chép!")
            end
        else
            ThongBao("Trình chạy không hỗ trợ sao chép!")
        end
    end
})

TabTacGia:CreateSection("DISCORD")

TabTacGia:CreateParagraph({
    Title = "Máy chủ Discord",
    Content = "Tham gia Discord để nhận hỗ trợ, chia sẻ script và trò chuyện."
})

TabTacGia:CreateButton({
    Name = "Sao chép liên kết Discord",
    Callback = function()
        if setclipboard then
            local ok = pcall(function()
                setclipboard(Discord)
            end)

            if ok then
                ThongBao("Đã sao chép liên kết Discord!")
            else
                ThongBao("Không thể sao chép!")
            end
        else
            ThongBao("Trình chạy không hỗ trợ sao chép!")
        end
    end
})

TabTacGia:CreateSection("THÔNG TIN")

TabTacGia:CreateParagraph({
    Title = "Tên giao diện",
    Content = "RidKid Hub"
})

Rayfield:Notify({
    Title = "RidKid Hub",
    Content = "Menu đã tải thành công!",
    Duration = 4
})
