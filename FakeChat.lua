local LANG, askAgain, T

do
	local http0 = game:GetService("HttpService")
	local plr0 = game:GetService("Players").LocalPlayer
	local data
	if type(readfile) == "function" and type(isfile) == "function" then
		pcall(function()
			if isfile("GlassChat_Settings.json") then
				data = http0:JSONDecode(readfile("GlassChat_Settings.json"))
			end
		end)
	end
	askAgain = true
	if type(data) == "table" then
		if data.lang == "vi" or data.lang == "en" then
			LANG = data.lang
		end
		if data.askLang == false then
			askAgain = false
		end
	end

	if not LANG or askAgain then
		local chosen
		local dontAsk = false

		local function mk(class, props, parent)
			local o = Instance.new(class)
			for k, v in pairs(props) do
				o[k] = v
			end
			o.Parent = parent
			return o
		end

		local sg = mk("ScreenGui", {Name = "RidKidLang", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000}, nil)
		local okp = pcall(function()
			sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		end)
		if not okp or not sg.Parent then
			sg.Parent = plr0:WaitForChild("PlayerGui")
		end

		local frame = mk("Frame", {Size = UDim2.new(0, 330, 0, 232), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, ClipsDescendants = true}, sg)
		mk("UICorner", {CornerRadius = UDim.new(0, 18)}, frame)
		mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(184, 132, 38), Color3.fromRGB(34, 22, 8)), Rotation = 90}, frame)
		mk("UIStroke", {Color = Color3.fromRGB(255, 214, 120), Thickness = 1.6, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, frame)

		mk("TextLabel", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 14), BackgroundTransparency = 1, Text = "RidKid Hub", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 24}, frame)
		mk("TextLabel", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 48), BackgroundTransparency = 1, Text = "Chọn ngôn ngữ  •  Choose your language", TextColor3 = Color3.fromRGB(255, 240, 210), Font = Enum.Font.Gotham, TextSize = 13}, frame)

		for i, info in ipairs({{"vi", "Tiếng Việt"}, {"en", "English"}}) do
			local b = mk("TextButton", {Size = UDim2.new(0, 140, 0, 48), Position = UDim2.new(0, 20 + (i - 1) * 150, 0, 86), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.78, Text = info[2], TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 17, BorderSizePixel = 0}, frame)
			mk("UICorner", {CornerRadius = UDim.new(0, 12)}, b)
			mk("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
			b.Activated:Connect(function()
				chosen = info[1]
			end)
		end

		local askBtn = mk("TextButton", {Size = UDim2.new(1, -40, 0, 28), Position = UDim2.new(0, 20, 0, 148), BackgroundTransparency = 1, Text = "[  ]  Không hỏi lại  •  Don't ask again", TextColor3 = Color3.fromRGB(255, 240, 210), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, frame)
		askBtn.Activated:Connect(function()
			dontAsk = not dontAsk
			askBtn.Text = (dontAsk and "[x]  " or "[  ]  ") .. "Không hỏi lại  •  Don't ask again"
		end)

		mk("TextLabel", {Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 196), BackgroundTransparency = 1, Text = "Học Làm Script x Tvàn", TextColor3 = Color3.fromRGB(255, 214, 120), Font = Enum.Font.GothamMedium, TextSize = 12}, frame)

		repeat
			task.wait()
		until chosen

		LANG = chosen
		askAgain = not dontAsk
		sg:Destroy()
	end
end

LANG = LANG or "vi"
T = function(vi, en)
	if LANG == "en" then
		return en
	end
	return vi
end
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer
local sharedT = (typeof(shared) == "table") and shared or {}

local PRESETS = {"FF1744","FF3B3B","FF6B6B","FF8A00","FFB300","FFD400","C6FF00","7CFF3B","00E676","00C853","1DE9B6","00E5FF","40C4FF","3B82FF","2962FF","304FFE","7B3BFF","9C27B0","D13BFF","E040FB","FF3BA7","FF80AB","FFC0CB","FFFFFF","B0B0B0","8D6E63","FFE0B2"}
local LIGHTS = {"FFE296", "FFF4C2", "FFB84D", "FF8A5C", "FF9EC7", "C9A8FF", "9ED8FF", "A6FFE0", "FFFFFF"}
local TAGS = {"", "admin", "roblox", "Rid", "9999robux", "Banana", "VIP", "Owner", "Mod", "Pro", "Legend", "King", "Ninja", "Rich", "Dev", "Master", "Boss", "Elite", "Sigma", "Alpha", "Hacker", "Gamer", "Demon", "Angel", "Hero", "Wolf"}
local BADGES = {"👑", "🔥", "⚡", "💎", "⭐", "🚀", "🏆", "💀", "😎", "🎯", "🌟", "👾"}
local DEFAULT_QUICK = {"Xin chào mọi người!", "Cho mình chơi cùng với", "Cảm ơn bạn nhé", "GG, chơi hay quá"}
local FILE = "GlassChat_Settings.json"
local CLARITY = {0.2, 0.32, 0.44, 0.56}
local ICON = "rbxassetid://130920436247899"
local GAME_TIMES = {{"Bình minh", 6}, {"Sáng", 9}, {"Trưa", 12}, {"Chiều", 16}, {"Hoàng hôn", 18}, {"Đêm", 0}, {"Giữ nguyên", -1}}

local FACES = {
	{"", "Mặc định"}, {"Arcade", "Arcade"}, {"Fantasy", "Fantasy"}, {"Cartoon", "Cartoon"},
	{"SciFi", "SciFi"}, {"Code", "Code"}, {"Antique", "Antique"}, {"Bangers", "Bangers"},
	{"Creepster", "Creepster"}, {"FredokaOne", "Fredoka"}, {"LuckiestGuy", "Luckiest"}, {"PermanentMarker", "Marker"},
	{"Michroma", "Michroma"}, {"IndieFlower", "Indie"}, {"SpecialElite", "Elite"}, {"Fondamento", "Fonda"},
}

local SMALLCAPS = {"ᴀ", "ʙ", "ᴄ", "ᴅ", "ᴇ", "ꜰ", "ɢ", "ʜ", "ɪ", "ᴊ", "ᴋ", "ʟ", "ᴍ", "ɴ", "ᴏ", "ᴘ", "ǫ", "ʀ", "ꜱ", "ᴛ", "ᴜ", "ᴠ", "ᴡ", "x", "ʏ", "ᴢ"}
local UNI = {
	{name = "Thường"},
	{name = "Đậm", up = 0x1D5D4, lo = 0x1D5EE, dg = 0x1D7EC},
	{name = "Nghiêng", up = 0x1D608, lo = 0x1D622},
	{name = "Đậm nghiêng", up = 0x1D63C, lo = 0x1D656},
	{name = "Viết tay", up = 0x1D4D0, lo = 0x1D4EA},
	{name = "Gô-tích", up = 0x1D56C, lo = 0x1D586},
	{name = "Máy chữ", up = 0x1D670, lo = 0x1D68A, dg = 0x1D7F6},
	{name = "Rộng", up = 0xFF21, lo = 0xFF41, dg = 0xFF10},
	{name = "Tròn", up = 0x24B6, lo = 0x24D0},
	{name = "Chữ nhỏ", small = true},
}

local state = {
	tag = "admin",
	tagColor = "FF3B3B",
	chatColor = "rainbow",
	edit = "tagColor",
	bold = false,
	italic = false,
	under = false,
	strike = false,
	caps = false,
	outline = false,
	mark = false,
	face = "",
	uni = 1,
	sendTag = true,
	badge = "👑",
	channel = "RBXGeneral",
	tab = 1,
	theme = 1,
	skyTop = "B88426",
	skyBottom = "221608",
	skyAuto = false,
	light = "auto",
	fxRays = true,
	fxSweep = true,
	fxMotes = true,
	fxClouds = true,
	clarity = 3,
	gameOn = false,
	gSky = "FFB04A",
	gLight = "auto",
	gStrength = 2,
	gFog = 0,
	gBloom = 0,
	gRays = 0,
	gTime = -1,
	gLock = false,
}
local quick = table.clone(DEFAULT_QUICK)
local rgb = {255, 59, 59}
local hsv = {0, 0.77, 1}
local conns = {}
local spin = {}
local accentObjs = {}
local activeCache = {}

if sharedT.GlassChatConns then
	for _, c in ipairs(sharedT.GlassChatConns) do
		pcall(function()
			c:Disconnect()
		end)
	end
end
sharedT.GlassChatConns = conns

local function seq3(a, b, c)
	return ColorSequence.new({ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b), ColorSequenceKeypoint.new(1, c)})
end

local THEMES = {
	{name = "Nắng Vàng", accent = Color3.fromRGB(245, 168, 24), border = seq3(Color3.fromRGB(255, 246, 176), Color3.fromRGB(255, 190, 40), Color3.fromRGB(255, 120, 30))},
	{name = "Tím", accent = Color3.fromRGB(124, 108, 255), border = seq3(Color3.fromRGB(255, 120, 200), Color3.fromRGB(124, 108, 255), Color3.fromRGB(80, 220, 255))},
	{name = "Đỏ", accent = Color3.fromRGB(255, 64, 90), border = seq3(Color3.fromRGB(255, 160, 130), Color3.fromRGB(255, 64, 90), Color3.fromRGB(190, 40, 140))},
	{name = "Xanh", accent = Color3.fromRGB(0, 170, 255), border = seq3(Color3.fromRGB(120, 255, 230), Color3.fromRGB(0, 170, 255), Color3.fromRGB(70, 100, 255))},
}

local SKIES = {
	{name = "Nắng vàng", top = "B88426", bottom = "221608"},
	{name = "Bình minh", top = "E8845A", bottom = "2A1840"},
	{name = "Trưa xanh", top = "3A8FD8", bottom = "0E2A4A"},
	{name = "Hoàng hôn", top = "E85D3A", bottom = "3A1030"},
	{name = "Đêm sao", top = "2A2F6B", bottom = "07091C"},
	{name = "Hoa anh đào", top = "D86B9A", bottom = "2C1230"},
	{name = "Ngọc bích", top = "2FB5A0", bottom = "082A2A"},
	{name = "Băng giá", top = "7FB6D9", bottom = "1B2A3C"},
}
for _, s in ipairs(SKIES) do
	s.top3 = Color3.fromHex(s.top)
	s.bottom3 = Color3.fromHex(s.bottom)
end

local TONES = {
	{"Đỏ", "FF3B3B"}, {"Cam", "FF8A00"}, {"Vàng", "FFD400"}, {"Chanh", "7CFF3B"},
	{"Lục", "00C853"}, {"Ngọc", "1DE9B6"}, {"Lơ", "00E5FF"}, {"Xanh", "3B82FF"},
	{"Chàm", "304FFE"}, {"Tím", "9C27B0"}, {"Hồng", "FF3BA7"}, {"Bạc", "B0B0B0"},
}
for _, t in ipairs(TONES) do
	local base = Color3.fromHex(t[2])
	t.top = base:Lerp(Color3.new(0, 0, 0), 0.12):ToHex():upper()
	t.bottom = base:Lerp(Color3.new(0, 0, 0), 0.78):ToHex():upper()
end

local STYLES = {
	{name = "Vua Vàng", tag = "King", tagColor = "FFB300", chatColor = "FFD400", bold = true, italic = false, badge = "👑", theme = 1},
	{name = "Hacker", tag = "Hacker", tagColor = "00E676", chatColor = "7CFF3B", bold = true, italic = false, badge = "👾", theme = 4},
	{name = "Quỷ Đỏ", tag = "Demon", tagColor = "FF1744", chatColor = "FF6B6B", bold = true, italic = false, badge = "🔥", theme = 3},
	{name = "Thiên Thần", tag = "Angel", tagColor = "FFC0CB", chatColor = "FFFFFF", bold = false, italic = true, badge = "🌟", theme = 2},
	{name = "Ninja Tím", tag = "Ninja", tagColor = "9C27B0", chatColor = "D13BFF", bold = true, italic = false, badge = "⚡", theme = 2},
	{name = "Cầu Vồng", tag = "VIP", tagColor = "rainbow", chatColor = "rainbow", bold = true, italic = false, badge = "auto", theme = 1},
}

local canSave = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

local function validHex(c)
	return type(c) == "string" and string.match(c, "^%x%x%x%x%x%x$") ~= nil
end

local function validColor(c)
	return c == "rainbow" or validHex(c)
end

local function inRange(v, a, b)
	return type(v) == "number" and v >= a and v <= b and v == math.floor(v)
end

local function clip(text, n)
	local ok, cut = pcall(utf8.offset, text, n + 1)
	if ok and cut then
		return string.sub(text, 1, cut - 1)
	end
	return text
end

if canSave then
	pcall(function()
		if not isfile(FILE) then return end
		local data = HttpService:JSONDecode(readfile(FILE))
		if type(data) ~= "table" then return end
		if type(data.tag) == "string" then
			local t = string.gsub(data.tag, "[<>&\"']", "")
			state.tag = clip(t, 16)
		end
		if validColor(data.tagColor) then state.tagColor = data.tagColor end
		if validColor(data.chatColor) then state.chatColor = data.chatColor end
		state.bold = data.bold == true
		state.italic = data.italic == true
		if type(data.sendTag) == "boolean" then state.sendTag = data.sendTag end
		if type(data.badge) == "string" and (data.badge == "" or data.badge == "auto" or table.find(BADGES, data.badge)) then
			state.badge = data.badge
		end
		if type(data.channel) == "string" and data.channel ~= "" then state.channel = data.channel end
		if data.ver == 2 and type(data.theme) == "number" and THEMES[data.theme] then state.theme = data.theme end
		if validHex(data.skyTop) then state.skyTop = data.skyTop end
		if validHex(data.skyBottom) then state.skyBottom = data.skyBottom end
		if type(data.skyAuto) == "boolean" then state.skyAuto = data.skyAuto end
		if data.light == "auto" or validColor(data.light) then state.light = data.light end
		for _, k in ipairs({"fxRays", "fxSweep", "fxMotes", "fxClouds", "under", "strike", "caps", "outline", "mark", "gameOn", "gLock"}) do
			if type(data[k]) == "boolean" then state[k] = data[k] end
		end
		if type(data.clarity) == "number" and CLARITY[data.clarity] then state.clarity = data.clarity end
		if type(data.uni) == "number" and UNI[data.uni] then state.uni = data.uni end
		if type(data.face) == "string" then
			for _, f in ipairs(FACES) do
				if f[1] == data.face then
					state.face = data.face
				end
			end
		end
		if validHex(data.gSky) then state.gSky = data.gSky end
		if data.gLight == "auto" or validHex(data.gLight) then state.gLight = data.gLight end
		if inRange(data.gStrength, 1, 3) then state.gStrength = data.gStrength end
		for _, k in ipairs({"gFog", "gBloom", "gRays"}) do
			if inRange(data[k], 0, 3) then state[k] = data[k] end
		end
		if type(data.gTime) == "number" and data.gTime >= -1 and data.gTime <= 24 then state.gTime = data.gTime end
		if type(data.quick) == "table" then
			local list = {}
			for _, m in ipairs(data.quick) do
				if type(m) == "string" and m ~= "" and #list < 12 then
					list[#list + 1] = clip(m, 120)
				end
			end
			quick = list
		end
	end)
end

local theme = THEMES[state.theme]

local function writeNow()
	if not canSave then return false end
	return pcall(function()
		writefile(FILE, HttpService:JSONEncode({ver = 2, tag = state.tag, tagColor = state.tagColor, chatColor = state.chatColor, bold = state.bold, italic = state.italic, under = state.under, strike = state.strike, caps = state.caps, outline = state.outline, mark = state.mark, face = state.face, uni = state.uni, sendTag = state.sendTag, badge = state.badge, channel = state.channel, theme = state.theme, quick = quick, skyTop = state.skyTop, skyBottom = state.skyBottom, skyAuto = state.skyAuto, light = state.light, fxRays = state.fxRays, fxSweep = state.fxSweep, fxMotes = state.fxMotes, fxClouds = state.fxClouds, clarity = state.clarity, gameOn = state.gameOn, gSky = state.gSky, gLight = state.gLight, gStrength = state.gStrength, gFog = state.gFog, gBloom = state.gBloom, gRays = state.gRays, gTime = state.gTime, gLock = state.gLock}))
	end)
end

local saveToken = 0
local function save()
	if not canSave then return end
	saveToken += 1
	local mine = saveToken
	task.delay(1, function()
		if mine == saveToken then
			writeNow()
		end
	end)
end
local function uniApply(text)
	local st = UNI[state.uni]
	if not st or not (st.up or st.small) then return text end
	local ok, res = pcall(function()
		local out = {}
		for _, cp in utf8.codes(text) do
			local ch = utf8.char(cp)
			if cp >= 65 and cp <= 90 then
				ch = st.small and SMALLCAPS[cp - 64] or utf8.char(st.up + cp - 65)
			elseif cp >= 97 and cp <= 122 then
				ch = st.small and SMALLCAPS[cp - 96] or utf8.char(st.lo + cp - 97)
			elseif cp >= 48 and cp <= 57 and st.dg then
				ch = utf8.char(st.dg + cp - 48)
			end
			out[#out + 1] = ch
		end
		return table.concat(out)
	end)
	return ok and res or text
end

local CHAR = "^" .. utf8.charpattern

local function paint(text, color, face)
	local fa = (face and face ~= "") and (' face="' .. face .. '"') or ""
	if color ~= "rainbow" then
		return string.format('<font color="#%s"%s>%s</font>', color, fa, text)
	end
	local out, i, k = {}, 1, 0
	while i <= #text do
		local piece = text:match("^&#?%w+;", i) or text:match(CHAR, i) or text:sub(i, i)
		i += #piece
		k += 1
		out[k] = string.format('<font color="#%s"%s>%s</font>', Color3.fromHSV((k * 0.07) % 1, 0.8, 1):ToHex(), fa, piece)
	end
	return table.concat(out)
end

local function chatPaint(text)
	local out = paint(text, state.chatColor, state.face)
	if state.mark then out = '<mark color="#000000" transparency="0.55">' .. out .. "</mark>" end
	if state.outline then out = '<stroke color="#000000" thickness="1" transparency="0.3">' .. out .. "</stroke>" end
	if state.strike then out = "<s>" .. out .. "</s>" end
	if state.under then out = "<u>" .. out .. "</u>" end
	if state.caps then out = "<uc>" .. out .. "</uc>" end
	if state.bold then out = "<b>" .. out .. "</b>" end
	if state.italic then out = "<i>" .. out .. "</i>" end
	return out
end

local function tagPrefix()
	if state.tag == "" then return "" end
	return paint("[" .. state.tag .. "]", state.tagColor) .. " "
end

local function isMine(msg)
	local src = msg.TextSource
	if src then
		return src.UserId == lp.UserId
	end
	local plain = string.gsub(msg.PrefixText, "<[^>]*>", "")
	plain = string.gsub(plain, "[%s:]+$", "")
	return plain == lp.DisplayName or plain == lp.Name
end

local function colorBadge(c)
	if c == "rainbow" then return "🌈" end
	local h, s, v = Color3.fromHex(c):ToHSV()
	h = h * 360
	if s < 0.18 or v < 0.2 then
		return v > 0.55 and "⚪" or "⚫"
	end
	if h < 20 or h >= 340 then return "🔴" end
	if h < 45 then return "🟠" end
	if h < 70 then return "🟡" end
	if h < 170 then return "🟢" end
	if h < 260 then return "🔵" end
	return "🟣"
end

local function badgeText()
	if state.badge == "" then return "" end
	if state.badge == "auto" then return colorBadge(state.tagColor) .. " " end
	return state.badge .. " "
end

local function plainPrefix()
	local p = badgeText()
	if state.sendTag and state.tag ~= "" then
		p = p .. "[" .. state.tag .. "] "
	end
	return p
end

local function autoHex()
	return Color3.fromHex(state.skyTop):Lerp(Color3.new(1, 1, 1), 0.6):ToHex():upper()
end

local cam = workspace.CurrentCamera
local viewW = cam and cam.ViewportSize.X or 800
local viewH = cam and cam.ViewportSize.Y or 400
local W = math.max(300, math.min(math.clamp(viewW - 100, 420, 620), viewW - 20))
local H = math.clamp(viewH - 30, 260, 380)
local SIDE = 100
local INNER = W - SIDE - 52
local FULL = UDim2.new(0, W, 0, H)

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function rounded(o, r)
	return make("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end

local function outline(o, t, th)
	return make("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = t, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end

local function glow(o, t, th)
	local s = outline(o, t, th)
	spin[#spin + 1] = make("UIGradient", {Color = theme.border}, s)
	return s
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

local function tweenTo(o, props, t)
	TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function setActive(b, on)
	if activeCache[b] == on then return end
	activeCache[b] = on
	tweenTo(b, {BackgroundColor3 = on and theme.accent or Color3.new(1, 1, 1), BackgroundTransparency = on and 0.25 or 0.88})
end

local function clearOld(p)
	if p then
		local o = p:FindFirstChild("GlassChatHub")
		if o then
			o:Destroy()
		end
	end
end
pcall(function()
	clearOld(gethui and gethui())
end)
pcall(function()
	clearOld(game:GetService("CoreGui"))
end)
pcall(function()
	clearOld(lp:FindFirstChildOfClass("PlayerGui"))
end)

local gui = make("ScreenGui", {Name = "GlassChatHub", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local ok = pcall(function()
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not ok or not gui.Parent then
	gui.Parent = lp:WaitForChild("PlayerGui")
end

local main = make("Frame", {Size = FULL, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = CLARITY[state.clarity], BorderSizePixel = 0, ClipsDescendants = true, Active = true}, gui)
rounded(main, 18)
glow(main, 0.3, 1.6)
local mainGrad = make("UIGradient", {Color = ColorSequence.new(Color3.fromHex(state.skyTop), Color3.fromHex(state.skyBottom)), Rotation = 90}, main)
local mainScale = make("UIScale", {Scale = 1}, main)

local bar = make("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 3}, main)
do
	local holder = make("Frame", {Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 12, 0, 6), BackgroundColor3 = Color3.fromRGB(18, 22, 38), BackgroundTransparency = 0.2, BorderSizePixel = 0}, bar)
	make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, holder)
	make("UIAspectRatioConstraint", {AspectRatio = 1}, holder)
	outline(holder, 0.6, 1)
	local img = make("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0}, holder)
	make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, img)
	make("TextLabel", {Size = UDim2.new(1, -120, 0, 18), Position = UDim2.new(0, 48, 0, 5), BackgroundTransparency = 1, Text = "Glass Chat", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, bar)
	make("TextLabel", {Size = UDim2.new(1, -120, 0, 12), Position = UDim2.new(0, 48, 0, 22), BackgroundTransparency = 1, Text = "Kính trời • Ánh sáng • Game", TextColor3 = Color3.fromRGB(235, 226, 200), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, bar)
end
make("Frame", {Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 40), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 3}, main)

local function topButton(text, x, color)
	local b = make("TextButton", {Size = UDim2.new(0, 22, 0, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 9), BackgroundColor3 = color, BackgroundTransparency = 0.1, Text = text, TextColor3 = Color3.fromRGB(50, 30, 30), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 4}, main)
	rounded(b, 11)
	return b
end
local minBtn = topButton("-", -42, Color3.fromRGB(255, 189, 68))
local closeBtn = topButton("×", -12, Color3.fromRGB(255, 95, 87))

local toast = make("TextLabel", {Name = "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -50), Size = UDim2.new(0, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(24, 18, 10), BackgroundTransparency = 0.2, Text = "", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 13, BorderSizePixel = 0, ZIndex = 20}, gui)
rounded(toast, 17)
glow(toast, 0.3, 1.5)
make("UIPadding", {PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18)}, toast)

local toastToken = 0
local function notify(text)
	toastToken += 1
	local mine = toastToken
	toast.Text = text
	tweenTo(toast, {Position = UDim2.new(0.5, 0, 0, 62)}, 0.25)
	task.delay(1.8, function()
		if mine == toastToken then
			tweenTo(toast, {Position = UDim2.new(0.5, 0, 0, -50)}, 0.25)
		end
	end)
end
local refresh, loadColor, activeSlider, applyTheme
local svBox, svKnob, hueKnob, chanBtn, othersPreview, buildQuick
local colorStroke, tagBtns, targetBtns, sliderUI, toggles = {}, {}, {}, {}, {}
local tabBtns, themeStroke, skyStroke, lightStroke, clarityBtns = {}, {}, {}, {}, {}
local badgeBtns, toneStroke, fontBtns, uniBtns = {}, {}, {}, {}
local gToneStroke, gLightStroke, gStrBtns, gTimeBtns, levelBtns = {}, {}, {}, {}, {}

local side = make("ScrollingFrame", {Size = UDim2.new(0, SIDE, 1, -54), Position = UDim2.new(0, 10, 0, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3}, main)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, side)
make("Frame", {Size = UDim2.new(0, 1, 1, -62), Position = UDim2.new(0, SIDE + 14, 0, 50), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 3}, main)

local content = make("Frame", {Size = UDim2.new(1, -(SIDE + 28), 1, -54), Position = UDim2.new(0, SIDE + 20, 0, 46), BackgroundTransparency = 1, ZIndex = 3}, main)
local preview = make("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, RichText = true, TextWrapped = true, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, content)
rounded(preview, 8)
outline(preview, 0.85, 1)

local pages = {}
local function newPage()
	local p = make("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(0, 0, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.new(1, 1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false}, content)
	make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, p)
	make("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, p)
	pages[#pages + 1] = p
	return p
end
local colorPage, tagPage, sendPage, skyPage, fontPage, gamePage, themePage = newPage(), newPage(), newPage(), newPage(), newPage(), newPage(), newPage()

local function lockScroll(on)
	for _, p in ipairs(pages) do
		p.ScrollingEnabled = on
	end
end

for i, name in ipairs({"Màu sắc", "Tiller", "Gửi tin", "Nền kính", "Chữ", "Game", "Cài đặt"}) do
	local b = make("TextButton", {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, Text = name, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, side)
	rounded(b, 8)
	tabBtns[i] = b
	b.Activated:Connect(function()
		state.tab = i
		refresh()
	end)
end

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function header(parent, text)
	local row = make("Frame", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, parent)
	local dot = make("Frame", {Size = UDim2.new(0, 3, 0, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = theme.accent, BorderSizePixel = 0}, row)
	rounded(dot, 2)
	accentObjs[#accentObjs + 1] = dot
	make("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(255, 244, 220), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
end

local function card(page, title)
	local f = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93, BorderSizePixel = 0, LayoutOrder = nextOrder()}, page)
	rounded(f, 10)
	outline(f, 0.88, 1)
	make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, f)
	make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	if title then
		header(f, title)
	end
	return f
end

local function grid(parent, minW, ch, n, fixed)
	local cols = math.max(1, math.floor((INNER + 6) / (minW + 6)))
	local cw = fixed and minW or math.floor((INNER - 6 * (cols - 1)) / cols)
	local rows = math.max(1, math.ceil(n / cols))
	local f = make("Frame", {Size = UDim2.new(1, 0, 0, rows * ch + (rows - 1) * 6), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, parent)
	make("UIGridLayout", {CellSize = UDim2.new(0, cw, 0, ch), CellPadding = UDim2.new(0, 6, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	return f
end

local function pill(text, parent, ord)
	local b = make("TextButton", {Text = text, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = ord or 0}, parent)
	rounded(b, 8)
	return b
end

local function textBox(placeholder, size, parent, ord)
	local t = make("TextBox", {Size = size, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Color3.fromRGB(200, 200, 210), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord or 0}, parent)
	rounded(t, 8)
	make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, t)
	return t
end

local pickers = {}

local function makePicker(parent, opts)
	local ph, ps, pv = 0, 1, 1
	local suppress = false

	local box = make("TextButton", {Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = Color3.new(1, 0, 0), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder()}, parent)
	rounded(box, 8)
	local wl = make("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, box)
	rounded(wl, 8)
	make("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wl)
	local bl = make("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, box)
	rounded(bl, 8)
	make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, bl)
	local knob = make("Frame", {Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, box)
	rounded(knob, 8)
	outline(knob, 0, 2)

	local huebar = make("TextButton", {Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder()}, parent)
	rounded(huebar, 9)
	local hkeys = {}
	for i = 0, 6 do
		hkeys[#hkeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))
	end
	make("UIGradient", {Color = ColorSequence.new(hkeys)}, huebar)
	local hknob = make("Frame", {Size = UDim2.new(0, 8, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, huebar)
	rounded(hknob, 4)

	local hexBox = textBox("Gõ mã màu, ví dụ FF3B3B", UDim2.new(1, 0, 0, 28), parent, nextOrder())

	local obj = {}

	function obj.sync()
		if not suppress then
			local hex = opts.get()
			if hex then
				local col = Color3.fromHex(hex)
				local nh, ns, nv = col:ToHSV()
				if ns > 0.02 and nv > 0.02 then
					ph = nh
				end
				ps = ns
				pv = nv
			end
		end
		box.BackgroundColor3 = Color3.fromHSV(ph, 1, 1)
		knob.Position = UDim2.new(ps, 0, 1 - pv, 0)
		knob.BackgroundColor3 = Color3.fromHSV(ph, ps, pv)
		hknob.Position = UDim2.new(ph, 0, 0.5, 0)
	end

	local function apply()
		suppress = true
		opts.set(Color3.fromHSV(ph, ps, pv):ToHex():upper())
		suppress = false
	end

	local function moveBox(x, y)
		ps = math.clamp((x - box.AbsolutePosition.X) / math.max(box.AbsoluteSize.X, 1), 0, 1)
		pv = 1 - math.clamp((y - box.AbsolutePosition.Y) / math.max(box.AbsoluteSize.Y, 1), 0, 1)
		apply()
	end

	local function moveHueBar(x)
		ph = math.clamp((x - huebar.AbsolutePosition.X) / math.max(huebar.AbsoluteSize.X, 1), 0, 0.999)
		apply()
	end

	box.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = moveBox
			lockScroll(false)
			moveBox(input.Position.X, input.Position.Y)
		end
	end)

	huebar.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = moveHueBar
			lockScroll(false)
			moveHueBar(input.Position.X)
		end
	end)

	hexBox.FocusLost:Connect(function()
		local t = string.gsub(hexBox.Text, "[#%s]", "")
		if validHex(t) then
			local up = string.upper(t)
			hexBox.Text = ""
			opts.set(up)
			notify("Đã áp dụng màu #" .. up)
		elseif t ~= "" then
			notify("Mã màu gồm 6 ký tự 0-9, A-F")
		end
	end)

	pickers[#pickers + 1] = obj
	return obj
end

local function afterEdit()
	if state.edit == "skyTop" or state.edit == "skyBottom" then
		state.skyAuto = false
	end
end

local function goEdit(key)
	state.edit = key
	state.tab = 1
	loadColor()
	refresh()
end

local function applyStyle(st)
	state.tag = st.tag
	state.tagColor = st.tagColor
	state.chatColor = st.chatColor
	state.bold = st.bold
	state.italic = st.italic
	state.badge = st.badge
	state.edit = "tagColor"
	loadColor()
	applyTheme(st.theme)
	notify("Phong cách: " .. st.name)
end
local sunStep, forceLook, applyFx

do
	local SUN_X, SUN_Y = 24, -6
	local beamAngles = {-12, -26, -40, -54, -68, -82}
	local beamWidths = {22, 12, 30, 16, 24, 12}
	local moteX = {0.12, 0.28, 0.45, 0.6, 0.75, 0.88, 0.35, 0.68}
	local moteS = {0.03, 0.045, 0.025, 0.05, 0.035, 0.04, 0.055, 0.03}
	local moteO = {0.1, 0.5, 0.8, 0.3, 0.65, 0.2, 0.9, 0.45}
	local moteZ = {4, 3, 5, 3, 4, 3, 5, 4}
	local starX = {0.08, 0.2, 0.33, 0.47, 0.6, 0.72, 0.85, 0.93, 0.15, 0.4, 0.55, 0.78, 0.26, 0.66}
	local starY = {0.06, 0.14, 0.05, 0.12, 0.07, 0.16, 0.09, 0.22, 0.3, 0.26, 0.34, 0.28, 0.42, 0.38}
	local cloudY = {0.12, 0.3, 0.52}
	local cloudS = {0.012, 0.02, 0.008}
	local cloudO = {0.1, 0.55, 0.85}
	local cloudW = {150, 200, 120}
	local cloudH = {32, 40, 26}
	local beams, glows, motes, stars, clouds = {}, {}, {}, {}, {}
	local white = Color3.new(1, 1, 1)

	local sunLayer = make("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1}, main)
	rounded(sunLayer, 18)

	local horizon = make("Frame", {Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.new(0, 0, 0.55, 0), BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 1}, sunLayer)
	make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0.74)}, horizon)

	for i = 1, #cloudY do
		local c = make("Frame", {Size = UDim2.new(0, cloudW[i], 0, cloudH[i]), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, cloudY[i], 0), BackgroundColor3 = white, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 2}, sunLayer)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, c)
		clouds[i] = c
	end

	for i = 1, #starX do
		local s = make("Frame", {Size = UDim2.new(0, 2 + (i % 2), 0, 2 + (i % 2)), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(starX[i], 0, starY[i], 0), BackgroundColor3 = white, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, sunLayer)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, s)
		stars[i] = s
	end

	for i, ang in ipairs(beamAngles) do
		local beam = make("Frame", {Size = UDim2.new(0, beamWidths[i], 0, 760), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, SUN_X, 0, SUN_Y), Rotation = ang, BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 3}, sunLayer)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, beam)
		make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.6, 0.9), NumberSequenceKeypoint.new(1, 1)})}, beam)
		beams[i] = beam
	end

	local glowGroup = make("Frame", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, SUN_X, 0, SUN_Y), BackgroundTransparency = 1, ZIndex = 3}, sunLayer)
	local glowScale = make("UIScale", {Scale = 1}, glowGroup)
	for i, info in ipairs({{190, 0.92}, {140, 0.86}, {96, 0.78}, {58, 0.6}}) do
		local c = make("Frame", {Size = UDim2.new(0, info[1], 0, info[1]), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = white, BackgroundTransparency = info[2], BorderSizePixel = 0, ZIndex = 3}, glowGroup)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, c)
		glows[i] = c
	end

	local sweep = make("Frame", {Size = UDim2.new(0, 110, 1.8, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.4, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = Color3.fromRGB(255, 244, 214), BorderSizePixel = 0, Visible = false, ZIndex = 4}, sunLayer)
	make("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.84), NumberSequenceKeypoint.new(1, 1)})}, sweep)

	for i = 1, #moteX do
		local m = make("Frame", {Size = UDim2.new(0, moteZ[i], 0, moteZ[i]), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 5}, sunLayer)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, m)
		motes[i] = m
	end

	local sheen = make("Frame", {Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 2}, main)
	rounded(sheen, 18)
	make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0.84, 1)}, sheen)

	local shine = make("Frame", {Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 1), BackgroundColor3 = white, BorderSizePixel = 0, ZIndex = 2}, main)
	make("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)})}, shine)

	local curTop, curBottom, curLight = Color3.new(), Color3.new(), Color3.new()
	local night, lastTick, sweepOn, starsLit, fxSig = 0, -1, false, false, ""

	local function skyNow(t)
		if state.skyAuto then
			local n = #SKIES
			local k = math.floor(t / 10)
			local a = SKIES[k % n + 1]
			local b = SKIES[(k + 1) % n + 1]
			local f = (t % 10) / 10
			f = f * f * (3 - 2 * f)
			return a.top3:Lerp(b.top3, f), a.bottom3:Lerp(b.bottom3, f)
		end
		return Color3.fromHex(state.skyTop), Color3.fromHex(state.skyBottom)
	end

	local function lightNow(t, top)
		if state.light == "rainbow" then
			return Color3.fromHSV((t * 0.06) % 1, 0.5, 1)
		elseif state.light == "auto" then
			return top:Lerp(white, 0.6)
		end
		return Color3.fromHex(state.light)
	end

	local function recolorLight(c)
		for _, b in ipairs(beams) do
			b.BackgroundColor3 = c
		end
		for _, g in ipairs(glows) do
			g.BackgroundColor3 = c
		end
		for _, m in ipairs(motes) do
			m.BackgroundColor3 = c
		end
		horizon.BackgroundColor3 = c
		sheen.BackgroundColor3 = c
	end

	applyFx = function()
		local sig = (state.fxRays and "1" or "0") .. (state.fxSweep and "1" or "0") .. (state.fxMotes and "1" or "0") .. (state.fxClouds and "1" or "0")
		if sig == fxSig then return end
		fxSig = sig
		for _, b in ipairs(beams) do
			b.Visible = state.fxRays
		end
		glowGroup.Visible = state.fxRays
		if not state.fxSweep then
			sweepOn = false
			sweep.Visible = false
		end
		for _, m in ipairs(motes) do
			m.Visible = state.fxMotes
		end
		for _, s in ipairs(stars) do
			s.Visible = state.fxMotes
		end
		for _, c in ipairs(clouds) do
			c.Visible = state.fxClouds
		end
	end

	sunStep = function(t)
		local step = math.floor(t * 15)
		if step ~= lastTick then
			lastTick = step
			local top, bottom = skyNow(t)
			if top ~= curTop or bottom ~= curBottom then
				curTop = top
				curBottom = bottom
				mainGrad.Color = ColorSequence.new(top, bottom)
			end
			local lc = lightNow(t, top)
			if lc ~= curLight then
				curLight = lc
				recolorLight(lc)
			end
			local lum = (0.299 * (top.R + bottom.R) + 0.587 * (top.G + bottom.G) + 0.114 * (top.B + bottom.B)) / 2
			night = math.clamp((0.28 - lum) / 0.15, 0, 1)
		end
		if state.fxRays then
			for i, b in ipairs(beams) do
				b.Rotation = beamAngles[i] + math.sin(t * 0.5 + i * 1.3) * 3
			end
			glowScale.Scale = 1 + math.sin(t * 1.1) * 0.06
		end
		if state.fxSweep then
			local phase = (t % 8) / 8
			if phase < 0.25 then
				sweep.Position = UDim2.new(-0.3 + (phase / 0.25) * 1.6, 0, 0.5, 0)
				if not sweepOn then
					sweepOn = true
					sweep.Visible = true
				end
			elseif sweepOn then
				sweepOn = false
				sweep.Visible = false
			end
		end
		if state.fxMotes then
			for i, m in ipairs(motes) do
				local y = 1 - ((t * moteS[i] + moteO[i]) % 1)
				m.Position = UDim2.new(moteX[i] + math.sin(t * 0.8 + i) * 0.02, 0, y, 0)
				m.BackgroundTransparency = 0.55 + math.sin(t * 2 + i * 1.7) * 0.3
			end
			if night > 0 or starsLit then
				starsLit = night > 0
				for i, s in ipairs(stars) do
					local a = night * (0.45 + 0.4 * math.sin(t * 1.6 + i * 2.1))
					s.BackgroundTransparency = 1 - math.clamp(a, 0, 1)
				end
			end
		end
		if state.fxClouds then
			for i, c in ipairs(clouds) do
				local x = ((t * cloudS[i] + cloudO[i]) % 1.6) - 0.3
				c.Position = UDim2.new(x, 0, cloudY[i], 0)
			end
		end
	end

	forceLook = function()
		lastTick = -1
		sunStep(os.clock())
	end
end
do
	local vipCard = card(colorPage, "Phong cách VIP (1 chạm)")
	local vipGrid = grid(vipCard, 120, 40, #STYLES)
	for i, st in ipairs(STYLES) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, vipGrid)
		rounded(b, 10)
		local c1 = st.tagColor == "rainbow" and Color3.fromRGB(255, 120, 200) or Color3.fromHex(st.tagColor)
		local c2 = st.chatColor == "rainbow" and Color3.fromRGB(80, 220, 255) or Color3.fromHex(st.chatColor)
		make("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = 20}, b)
		make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = st.name, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0.35}, b)
		b.Activated:Connect(function()
			applyStyle(st)
		end)
	end

	local targetCard = card(colorPage, "Đang chỉnh màu cho")
	local targetGrid = grid(targetCard, 80, 28, 5)
	for i, info in ipairs({{"tagColor", "Tiller"}, {"chatColor", "Chat"}, {"light", "Ánh sáng"}, {"skyTop", "Trời trên"}, {"skyBottom", "Trời dưới"}}) do
		local b = pill(info[2], targetGrid, i)
		b.TextSize = 12
		targetBtns[info[1]] = b
		b.Activated:Connect(function()
			state.edit = info[1]
			loadColor()
			refresh()
		end)
	end
end

do
	local tagCard = card(tagPage, "Chọn tiller")
	local tagGrid = grid(tagCard, 80, 28, #TAGS)
	for i, name in ipairs(TAGS) do
		local b = pill(name == "" and "Không" or name, tagGrid, i)
		tagBtns[name] = b
		b.Activated:Connect(function()
			state.tag = name
			notify(name == "" and "Đã tắt tiller" or ("Tiller: " .. name))
			refresh()
		end)
	end

	local customCard = card(tagPage, "Tiller tự đặt")
	local tagBox = textBox("Gõ tiller rồi bấm Enter", UDim2.new(1, 0, 0, 28), customCard, nextOrder())
	tagBox.FocusLost:Connect(function()
		local t = string.gsub(tagBox.Text, "[<>&\"']", "")
		t = string.gsub(t, "^%s+", "")
		t = string.gsub(t, "%s+$", "")
		t = clip(t, 16)
		if t ~= "" then
			state.tag = t
			tagBox.Text = ""
			notify("Tiller: " .. t)
			refresh()
		end
	end)
end

do
	local boardCard = card(colorPage, "Bảng màu")
	svBox = make("TextButton", {Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromHSV(hsv[1], 1, 1), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder()}, boardCard)
	rounded(svBox, 8)
	local white = make("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, svBox)
	rounded(white, 8)
	make("UIGradient", {Transparency = NumberSequence.new(0, 1)}, white)
	local black = make("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
	rounded(black, 8)
	make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, black)
	svKnob = make("Frame", {Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, svBox)
	rounded(svKnob, 8)
	outline(svKnob, 0, 2)

	local hueBar = make("TextButton", {Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder()}, boardCard)
	rounded(hueBar, 9)
	local hk = {}
	for i = 0, 6 do
		hk[#hk + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))
	end
	make("UIGradient", {Color = ColorSequence.new(hk)}, hueBar)
	hueKnob = make("Frame", {Size = UDim2.new(0, 8, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, hueBar)
	rounded(hueKnob, 4)

	local function pickColor()
		state[state.edit] = Color3.fromHSV(hsv[1], hsv[2], hsv[3]):ToHex():upper()
		afterEdit()
		loadColor(true)
		refresh()
	end

	local function moveSV(x, y)
		hsv[2] = math.clamp((x - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
		hsv[3] = 1 - math.clamp((y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
		pickColor()
	end

	local function moveHue(x)
		hsv[1] = math.clamp((x - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
		pickColor()
	end

	svBox.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = moveSV
			lockScroll(false)
			moveSV(input.Position.X, input.Position.Y)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if isPress(input) then
			activeSlider = moveHue
			lockScroll(false)
			moveHue(input.Position.X)
		end
	end)

	local presetCard = card(colorPage, "Màu có sẵn")
	local palette = grid(presetCard, 30, 30, #PRESETS + 1, true)
	for i, hex in ipairs(PRESETS) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.fromHex(hex), BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, palette)
		rounded(b, 8)
		colorStroke[hex] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state[state.edit] = hex
			afterEdit()
			loadColor()
			refresh()
		end)
	end

	local rb = make("TextButton", {Text = "", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = #PRESETS + 1}, palette)
	rounded(rb, 8)
	local keys = {}
	for i = 0, 5 do
		keys[#keys + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 5, 0.8, 1))
	end
	make("UIGradient", {Color = ColorSequence.new(keys), Rotation = 45}, rb)
	colorStroke.rainbow = outline(rb, 1, 2)
	rb.Activated:Connect(function()
		if state.edit == "skyTop" or state.edit == "skyBottom" then
			notify("Màu trời không dùng cầu vồng")
			return
		end
		state[state.edit] = "rainbow"
		refresh()
	end)

	local rgbCard = card(colorPage, "Tinh chỉnh RGB")
	local function sliderRow(index, letter, tint)
		local row = make("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, rgbCard)
		make("TextLabel", {Size = UDim2.new(0, 16, 1, 0), BackgroundTransparency = 1, Text = letter, TextColor3 = tint, Font = Enum.Font.GothamBold, TextSize = 13}, row)
		local hit = make("TextButton", {Size = UDim2.new(1, -66, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, row)
		local track = make("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0}, hit)
		rounded(track, 3)
		local fill = make("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = tint, BorderSizePixel = 0}, track)
		rounded(fill, 3)
		local knob = make("Frame", {Size = UDim2.new(0, 16, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
		rounded(knob, 8)
		local value = make("TextLabel", {Size = UDim2.new(0, 36, 1, 0), Position = UDim2.new(1, -36, 0, 0), BackgroundTransparency = 1, Text = "0", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 13}, row)

		sliderUI[index] = function(v)
			local a = v / 255
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
			value.Text = tostring(v)
		end

		local function setFromX(x)
			local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			rgb[index] = math.floor(a * 255 + 0.5)
			state[state.edit] = string.format("%02X%02X%02X", rgb[1], rgb[2], rgb[3])
			afterEdit()
			loadColor()
			refresh()
		end

		hit.InputBegan:Connect(function(input)
			if isPress(input) then
				activeSlider = setFromX
				lockScroll(false)
				setFromX(input.Position.X)
			end
		end)
	end
	sliderRow(1, "R", Color3.fromRGB(255, 90, 90))
	sliderRow(2, "G", Color3.fromRGB(90, 255, 120))
	sliderRow(3, "B", Color3.fromRGB(90, 150, 255))
end
do
	local fmtCard = card(fontPage, "Hiệu ứng chữ (hiện trên máy bạn)")
	local fmtGrid = grid(fmtCard, 90, 28, 7)
	for i, info in ipairs({{"bold", "Đậm"}, {"italic", "Nghiêng"}, {"under", "Gạch chân"}, {"strike", "Gạch ngang"}, {"caps", "Viết hoa"}, {"outline", "Viền chữ"}, {"mark", "Tô nền"}}) do
		local b = pill(info[2], fmtGrid, i)
		b.TextSize = 12
		toggles[info[1]] = b
		b.Activated:Connect(function()
			state[info[1]] = not state[info[1]]
			notify((state[info[1]] and "Bật " or "Tắt ") .. info[2])
			refresh()
		end)
	end

	local faceCard = card(fontPage, "Phông chữ (hiện trên máy bạn)")
	local faceGrid = grid(faceCard, 90, 28, #FACES)
	for i, f in ipairs(FACES) do
		local b = pill(f[2], faceGrid, i)
		b.TextSize = 12
		b.TextTruncate = Enum.TextTruncate.AtEnd
		if f[1] ~= "" then
			pcall(function()
				b.Font = Enum.Font[f[1]]
			end)
		end
		fontBtns[i] = b
		b.Activated:Connect(function()
			state.face = f[1]
			notify("Phông: " .. f[2])
			refresh()
		end)
	end

	local uniCard = card(fontPage, "Kiểu chữ đặc biệt (người khác thấy)")
	local uniGrid = grid(uniCard, 100, 28, #UNI)
	for i, u in ipairs(UNI) do
		local b = pill(u.name, uniGrid, i)
		b.TextSize = 12
		uniBtns[i] = b
		b.Activated:Connect(function()
			state.uni = i
			notify("Kiểu chữ: " .. u.name)
			refresh()
		end)
	end
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = "Chỉ áp dụng cho tin gửi từ ô Gửi tin hoặc tin mẫu. Chữ có dấu tiếng Việt giữ nguyên. Nếu thấy ô vuông thì chọn lại Thường.", TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, uniCard)
end

do
	local sendCard = card(sendPage, "Gửi tin (người khác có thể thấy)")
	local sendRow = make("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, sendCard)
	local sendBox = textBox("Gõ tin nhắn...", UDim2.new(1, -66, 1, 0), sendRow)
	local sendBtn = make("TextButton", {Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -60, 0, 0), BackgroundColor3 = Color3.fromRGB(80, 200, 120), BackgroundTransparency = 0.3, Text = "Gửi", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false}, sendRow)
	rounded(sendBtn, 8)

	local sendGrid = grid(sendCard, 120, 28, 2)
	local tagToggle = pill("Kèm tiller", sendGrid, 1)
	toggles.sendTag = tagToggle
	tagToggle.Activated:Connect(function()
		state.sendTag = not state.sendTag
		notify((state.sendTag and "Bật" or "Tắt") .. " kèm tiller")
		refresh()
	end)

	chanBtn = pill("Kênh", sendGrid, 2)
	chanBtn.TextSize = 12
	chanBtn.TextTruncate = Enum.TextTruncate.AtEnd
	chanBtn.Activated:Connect(function()
		local folder = TextChatService:FindFirstChild("TextChannels")
		if not folder then return end
		local names = {}
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("TextChannel") then
				names[#names + 1] = c.Name
			end
		end
		table.sort(names)
		if #names == 0 then return end
		local idx = table.find(names, state.channel) or 0
		state.channel = names[idx % #names + 1]
		notify("Kênh: " .. state.channel)
		refresh()
	end)

	local function deliver(text)
		local folder = TextChatService:FindFirstChild("TextChannels")
		local ch = folder and folder:FindFirstChild(state.channel)
		if not ch then
			notify("Không thấy kênh này")
			return false
		end
		text = clip(plainPrefix() .. uniApply(text), 200)
		local sent = pcall(function()
			ch:SendAsync(text)
		end)
		notify(sent and "Đã gửi tin" or "Gửi thất bại")
		return sent
	end

	local function sendMessage()
		local text = string.gsub(sendBox.Text, "^%s+", "")
		text = string.gsub(text, "%s+$", "")
		if text == "" then return end
		if deliver(text) then
			sendBox.Text = ""
		end
	end

	sendBtn.Activated:Connect(sendMessage)
	sendBox.FocusLost:Connect(function(enter)
		if enter then
			sendMessage()
		end
	end)

	local badgeCard = card(sendPage, "Huy hiệu VIP (người khác thấy)")
	local badgeItems = {{"", "Không"}, {"auto", "Auto"}}
	for _, e in ipairs(BADGES) do
		badgeItems[#badgeItems + 1] = {e, e}
	end
	local badgeGrid = grid(badgeCard, 44, 32, #badgeItems, true)
	for i, item in ipairs(badgeItems) do
		local b = pill(item[2], badgeGrid, i)
		b.TextSize = (item[1] == "" or item[1] == "auto") and 12 or 18
		badgeBtns[item[1]] = b
		b.Activated:Connect(function()
			state.badge = item[1]
			notify(item[1] == "" and "Đã tắt huy hiệu" or ("Huy hiệu: " .. item[2]))
			refresh()
		end)
	end
	othersPreview = make("TextLabel", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, Text = "", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, LayoutOrder = nextOrder()}, badgeCard)
	rounded(othersPreview, 6)
	make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, othersPreview)

	local quickCard = card(sendPage, "Tin nhắn mẫu (chạm để gửi)")
	local quickList = make("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder()}, quickCard)
	make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, quickList)

	buildQuick = function()
		for _, c in ipairs(quickList:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		for i, msg in ipairs(quick) do
			local row = make("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = i}, quickList)
			local b = make("TextButton", {Size = UDim2.new(1, -34, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, Text = msg, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0, AutoButtonColor = false}, row)
			rounded(b, 8)
			make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, b)
			local x = make("TextButton", {Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(1, -28, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 95, 87), BackgroundTransparency = 0.45, Text = "×", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false}, row)
			rounded(x, 8)
			b.Activated:Connect(function()
				deliver(msg)
			end)
			x.Activated:Connect(function()
				table.remove(quick, i)
				buildQuick()
				save()
				notify("Đã xóa tin mẫu")
			end)
		end
	end

	local addRow = make("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, quickCard)
	local addBox = textBox("Thêm tin mẫu...", UDim2.new(1, -66, 1, 0), addRow)
	local addBtn = make("TextButton", {Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -60, 0, 0), BackgroundColor3 = theme.accent, BackgroundTransparency = 0.3, Text = "Thêm", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false}, addRow)
	rounded(addBtn, 8)
	accentObjs[#accentObjs + 1] = addBtn

	local function addQuick()
		local t = string.gsub(addBox.Text, "^%s+", "")
		t = string.gsub(t, "%s+$", "")
		t = clip(t, 120)
		if t == "" then return end
		if #quick >= 12 then
			notify("Tối đa 12 tin mẫu")
			return
		end
		quick[#quick + 1] = t
		addBox.Text = ""
		buildQuick()
		save()
		notify("Đã thêm tin mẫu")
	end

	addBtn.Activated:Connect(addQuick)
	addBox.FocusLost:Connect(function(enter)
		if enter then
			addQuick()
		end
	end)
	buildQuick()

	local tipCard = card(sendPage, "Mẹo")
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Text = "Gõ /hoclamscriptVip@ trong chat để mở lại bảng sau khi bấm ×. Chỉ tin gửi từ ô Gửi tin hoặc tin mẫu mới kèm huy hiệu, tiller và kiểu chữ đặc biệt cho người khác thấy. Màu chữ chỉ hiện trên máy bạn.", TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, tipCard)
end
do
	local freeSky = card(skyPage, "Chọn màu nền kính tự do (chạm là đổi ngay)")
	makePicker(freeSky, {
		get = function()
			return state.skyTop
		end,
		set = function(hex)
			state.skyTop = hex
			state.skyBottom = Color3.fromHex(hex):Lerp(Color3.new(0, 0, 0), 0.8):ToHex():upper()
			state.skyAuto = false
			refresh()
		end,
	})

	local freeLight = card(skyPage, "Chọn màu tia nắng tự do (chạm là đổi ngay)")
	makePicker(freeLight, {
		get = function()
			if state.light == "rainbow" then
				return nil
			elseif state.light == "auto" then
				return autoHex()
			end
			return state.light
		end,
		set = function(hex)
			state.light = hex
			refresh()
		end,
	})

	local toneCard = card(skyPage, "Tông màu nền kính (đỏ, xanh, tím...)")
	local toneGrid = grid(toneCard, 90, 28, #TONES)
	for i, t in ipairs(TONES) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.fromHex(t[2]), BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, toneGrid)
		rounded(b, 8)
		make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = t[1], TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0.4}, b)
		toneStroke[i] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state.skyTop = t.top
			state.skyBottom = t.bottom
			state.skyAuto = false
			notify("Nền kính: " .. t[1])
			refresh()
		end)
	end

	local skyCard = card(skyPage, "Nền kính có sẵn")
	local skyGrid = grid(skyCard, 130, 40, #SKIES)
	for i, sk in ipairs(SKIES) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.05, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, skyGrid)
		rounded(b, 10)
		make("UIGradient", {Color = ColorSequence.new(sk.top3, sk.bottom3), Rotation = 90}, b)
		make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = sk.name, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0.4}, b)
		skyStroke[i] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state.skyTop = sk.top
			state.skyBottom = sk.bottom
			state.skyAuto = false
			notify("Nền kính: " .. sk.name)
			refresh()
		end)
	end

	local skyCtl = grid(skyCard, 130, 28, 2)
	local autoSky = pill("Ngày & đêm", skyCtl, 1)
	toggles.skyAuto = autoSky
	autoSky.Activated:Connect(function()
		state.skyAuto = not state.skyAuto
		notify(state.skyAuto and "Nền kính tự đổi màu" or "Đã dừng đổi màu nền kính")
		refresh()
	end)
	local skyEdit = pill("Chỉnh bằng RGB", skyCtl, 2)
	skyEdit.Activated:Connect(function()
		goEdit("skyTop")
		notify("Đang chỉnh màu nền trên")
	end)

	local lightCard = card(skyPage, "Màu tia nắng")
	local lightGrid = grid(lightCard, 30, 30, #LIGHTS + 2, true)
	for i, hex in ipairs(LIGHTS) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.fromHex(hex), BackgroundTransparency = 0.05, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, lightGrid)
		rounded(b, 8)
		lightStroke[hex] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state.light = hex
			notify("Tia nắng đã đổi màu")
			refresh()
		end)
	end

	local la = make("TextButton", {Text = "A", BackgroundColor3 = Color3.fromRGB(40, 40, 60), BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = #LIGHTS + 1}, lightGrid)
	rounded(la, 8)
	lightStroke.auto = outline(la, 1, 2)
	la.Activated:Connect(function()
		state.light = "auto"
		notify("Tia nắng theo màu nền")
		refresh()
	end)

	local lr = make("TextButton", {Text = "", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = #LIGHTS + 2}, lightGrid)
	rounded(lr, 8)
	local lkeys = {}
	for i = 0, 5 do
		lkeys[#lkeys + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 5, 0.7, 1))
	end
	make("UIGradient", {Color = ColorSequence.new(lkeys), Rotation = 45}, lr)
	lightStroke.rainbow = outline(lr, 1, 2)
	lr.Activated:Connect(function()
		state.light = "rainbow"
		notify("Tia nắng đổi màu liên tục")
		refresh()
	end)

	local fxCard = card(skyPage, "Hiệu ứng ánh sáng của bảng")
	local fxGrid = grid(fxCard, 110, 28, 4)
	for i, info in ipairs({{"fxRays", "Tia sáng"}, {"fxSweep", "Vệt sáng"}, {"fxMotes", "Hạt & sao"}, {"fxClouds", "Mây trời"}}) do
		local b = pill(info[2], fxGrid, i)
		toggles[info[1]] = b
		b.Activated:Connect(function()
			state[info[1]] = not state[info[1]]
			notify((state[info[1]] and "Bật " or "Tắt ") .. info[2])
			refresh()
		end)
	end

	local clarityCard = card(skyPage, "Độ trong của kính")
	local clarityGrid = grid(clarityCard, 70, 28, 4)
	for i, name in ipairs({"Đục", "Vừa", "Trong", "Rất trong"}) do
		local b = pill(name, clarityGrid, i)
		b.TextSize = 12
		clarityBtns[i] = b
		b.Activated:Connect(function()
			state.clarity = i
			notify("Độ trong: " .. name)
			refresh()
		end)
	end
end

do
	applyTheme = function(i)
		state.theme = i
		theme = THEMES[i]
		for _, g in ipairs(spin) do
			g.Color = theme.border
		end
		for _, o in ipairs(accentObjs) do
			o.BackgroundColor3 = theme.accent
		end
		table.clear(activeCache)
		refresh()
	end

	local themeCard = card(themePage, "Màu viền và nút (chủ đề)")
	local themeGrid = grid(themeCard, 120, 46, #THEMES)
	for i, th in ipairs(THEMES) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, themeGrid)
		rounded(b, 10)
		make("UIGradient", {Color = th.border, Rotation = 20}, b)
		make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = th.name, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15, TextStrokeTransparency = 0.45}, b)
		themeStroke[i] = outline(b, 1, 2)
		b.Activated:Connect(function()
			applyTheme(i)
			notify("Chủ đề " .. th.name)
		end)
	end

	local saveCard = card(themePage, "Lưu cài đặt")
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = canSave and "Tự động lưu mọi cài đặt, kể cả màu và hiệu ứng game. Lần sau chạy lại sẽ giữ nguyên." or "Executor của bạn không hỗ trợ lưu file, nên cài đặt sẽ mất khi thoát game.", TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, saveCard)
	local saveGrid = grid(saveCard, 120, 28, 2)
	local saveBtn = pill("Lưu ngay", saveGrid, 1)
	local resetBtn = pill("Đặt lại tất cả", saveGrid, 2)

	saveBtn.Activated:Connect(function()
		if not canSave then
			notify("Không hỗ trợ lưu file")
			return
		end
		notify(writeNow() and "Đã lưu cài đặt" or "Lưu thất bại")
	end)

	resetBtn.Activated:Connect(function()
		state.tag = "admin"
		state.tagColor = "FF3B3B"
		state.chatColor = "rainbow"
		state.bold = false
		state.italic = false
		state.under = false
		state.strike = false
		state.caps = false
		state.outline = false
		state.mark = false
		state.face = ""
		state.uni = 1
		state.sendTag = true
		state.badge = "👑"
		state.channel = "RBXGeneral"
		state.edit = "tagColor"
		state.skyTop = SKIES[1].top
		state.skyBottom = SKIES[1].bottom
		state.skyAuto = false
		state.light = "auto"
		state.fxRays = true
		state.fxSweep = true
		state.fxMotes = true
		state.fxClouds = true
		state.clarity = 3
		state.gameOn = false
		state.gSky = "FFB04A"
		state.gLight = "auto"
		state.gStrength = 2
		state.gFog = 0
		state.gBloom = 0
		state.gRays = 0
		state.gTime = -1
		state.gLock = false
		quick = table.clone(DEFAULT_QUICK)
		buildQuick()
		loadColor()
		applyTheme(1)
		notify("Đã đặt lại mặc định")
	end)

	local noteCard = card(themePage, "Ghi chú")
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Text = "Chủ đề chỉ đổi màu viền sáng và các nút đang chọn. Nền kính và tia nắng của bảng nằm ở tab Nền kính. Ánh sáng thật trong game nằm ở tab Game.", TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, noteCard)
end
local gameApply

do
	local black, white = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
	local LKEYS = {"Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "FogColor", "FogStart", "FogEnd", "Brightness", "ClockTime", "ExposureCompensation"}
	local GSTR = {0.35, 0.65, 1}
	local FOGEND = {1800, 800, 350}
	local BLOOMI = {0.4, 0.9, 1.6}
	local BLOOMS = {20, 30, 44}
	local RAYI = {0.08, 0.18, 0.32}
	local RAYS = {0.5, 0.75, 1}

	local store = sharedT.GlassChatOrig
	if not store then
		store = {}
		for _, k in ipairs(LKEYS) do
			pcall(function()
				store[k] = Lighting[k]
			end)
		end
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a and a.Name ~= "GlassChatAtmos" then
			store.atmos = {Color = a.Color, Decay = a.Decay, Density = a.Density, Offset = a.Offset, Glare = a.Glare, Haze = a.Haze}
		end
		sharedT.GlassChatOrig = store
	end

	local function getAtmos()
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if not a then
			a = Instance.new("Atmosphere")
			a.Name = "GlassChatAtmos"
			a.Parent = Lighting
		end
		return a
	end

	local function fx(class)
		local name = "GlassChat" .. class
		local o = Lighting:FindFirstChild(name)
		if not o then
			o = Instance.new(class)
			o.Name = name
			o.Parent = Lighting
		end
		return o
	end

	local function restoreAll()
		for _, k in ipairs(LKEYS) do
			if store[k] ~= nil then
				pcall(function()
					Lighting[k] = store[k]
				end)
			end
		end
		pcall(function()
			local a = Lighting:FindFirstChildOfClass("Atmosphere")
			if a then
				if a.Name == "GlassChatAtmos" then
					a:Destroy()
				elseif store.atmos then
					for k, v in pairs(store.atmos) do
						a[k] = v
					end
				end
			end
		end)
		for _, class in ipairs({"ColorCorrectionEffect", "BloomEffect", "SunRaysEffect"}) do
			pcall(function()
				local o = Lighting:FindFirstChild("GlassChat" .. class)
				if o then
					o.Enabled = false
				end
			end)
		end
	end

	local wasOn = false
	gameApply = function()
		if not state.gameOn then
			if wasOn then
				wasOn = false
				restoreAll()
			end
			return
		end
		wasOn = true
		pcall(function()
			local s = GSTR[state.gStrength]
			local sky = Color3.fromHex(state.gSky)
			local lc = state.gLight == "auto" and sky:Lerp(white, 0.5) or Color3.fromHex(state.gLight)
			Lighting.ColorShift_Top = lc:Lerp(black, 1 - 0.8 * s)
			Lighting.ColorShift_Bottom = sky:Lerp(black, 1 - 0.5 * s)
			Lighting.Ambient = Color3.fromRGB(70, 70, 70):Lerp(lc, 0.35 * s)
			Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 110):Lerp(sky:Lerp(lc, 0.5), 0.6 * s)
			if state.gTime >= 0 then
				Lighting.ClockTime = state.gTime
			end
			if state.gFog > 0 then
				Lighting.FogColor = sky
				Lighting.FogStart = 0
				Lighting.FogEnd = FOGEND[state.gFog]
			elseif store.FogEnd ~= nil then
				Lighting.FogColor = store.FogColor
				Lighting.FogStart = store.FogStart
				Lighting.FogEnd = store.FogEnd
			end
			local a = getAtmos()
			a.Color = sky
			a.Decay = sky:Lerp(black, 0.35)
			a.Density = 0.2 + 0.25 * s
			a.Offset = 0.2
			a.Glare = 0.2 + 1.2 * s
			a.Haze = 0.8 + 2.2 * s
			local cc = fx("ColorCorrectionEffect")
			cc.Enabled = true
			cc.TintColor = white:Lerp(sky:Lerp(lc, 0.5), 0.4 * s)
			cc.Saturation = 0.1 * s
			cc.Contrast = 0.04 * s
			local bl = fx("BloomEffect")
			bl.Enabled = state.gBloom > 0
			if state.gBloom > 0 then
				bl.Intensity = BLOOMI[state.gBloom]
				bl.Size = BLOOMS[state.gBloom]
				bl.Threshold = 0.85
			end
			local sr = fx("SunRaysEffect")
			sr.Enabled = state.gRays > 0
			if state.gRays > 0 then
				sr.Intensity = RAYI[state.gRays]
				sr.Spread = RAYS[state.gRays]
			end
		end)
	end
end

do
	local function arm()
		if not state.gameOn then
			state.gameOn = true
			notify("Đã bật hiệu ứng game")
		end
	end

	local masterCard = card(gamePage, "Hiệu ứng ánh sáng trong game")
	local masterGrid = grid(masterCard, 130, 30, 2)
	local onBtn = pill("Bật hiệu ứng game", masterGrid, 1)
	toggles.gameOn = onBtn
	onBtn.Activated:Connect(function()
		state.gameOn = not state.gameOn
		notify(state.gameOn and "Đã bật hiệu ứng game" or "Đã khôi phục ánh sáng gốc")
		refresh()
	end)
	local restoreBtn = pill("Khôi phục gốc", masterGrid, 2)
	restoreBtn.Activated:Connect(function()
		state.gameOn = false
		state.gTime = -1
		state.gLock = false
		notify("Đã khôi phục ánh sáng gốc")
		refresh()
	end)
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Text = "Chỉ đổi trên máy bạn, người khác không thấy. Mỗi game có ánh sáng riêng nên mức đổi màu có thể khác nhau, vài game tự đặt lại ánh sáng liên tục.", TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, masterCard)

	local skyCard = card(gamePage, "Màu bầu trời (game)")
	makePicker(skyCard, {
		get = function()
			return state.gSky
		end,
		set = function(hex)
			state.gSky = hex
			arm()
			refresh()
		end,
	})
	local gtGrid = grid(skyCard, 90, 28, #TONES)
	for i, t in ipairs(TONES) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.fromHex(t[2]), BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, gtGrid)
		rounded(b, 8)
		make("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = t[1], TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, TextStrokeTransparency = 0.4}, b)
		gToneStroke[i] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state.gSky = t[2]
			arm()
			notify("Trời game: " .. t[1])
			refresh()
		end)
	end
	header(skyCard, "Cường độ")
	local strGrid = grid(skyCard, 90, 28, 3)
	for i, name in ipairs({"Nhẹ", "Vừa", "Mạnh"}) do
		local b = pill(name, strGrid, i)
		gStrBtns[i] = b
		b.Activated:Connect(function()
			state.gStrength = i
			arm()
			notify("Cường độ: " .. name)
			refresh()
		end)
	end

	local lightCard = card(gamePage, "Màu ánh sáng (game)")
	makePicker(lightCard, {
		get = function()
			if state.gLight == "auto" then
				return Color3.fromHex(state.gSky):Lerp(Color3.new(1, 1, 1), 0.5):ToHex():upper()
			end
			return state.gLight
		end,
		set = function(hex)
			state.gLight = hex
			arm()
			refresh()
		end,
	})
	local glGrid = grid(lightCard, 30, 30, #LIGHTS + 1, true)
	for i, hex in ipairs(LIGHTS) do
		local b = make("TextButton", {Text = "", BackgroundColor3 = Color3.fromHex(hex), BackgroundTransparency = 0.05, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i}, glGrid)
		rounded(b, 8)
		gLightStroke[hex] = outline(b, 1, 2)
		b.Activated:Connect(function()
			state.gLight = hex
			arm()
			notify("Ánh sáng game đã đổi màu")
			refresh()
		end)
	end
	local ga = make("TextButton", {Text = "A", BackgroundColor3 = Color3.fromRGB(40, 40, 60), BackgroundTransparency = 0.1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = #LIGHTS + 1}, glGrid)
	rounded(ga, 8)
	gLightStroke.auto = outline(ga, 1, 2)
	ga.Activated:Connect(function()
		state.gLight = "auto"
		arm()
		notify("Ánh sáng theo màu trời game")
		refresh()
	end)

	local timeCard = card(gamePage, "Giờ trong game (đổi sắc trời)")
	local timeGrid = grid(timeCard, 90, 28, #GAME_TIMES)
	for i, tm in ipairs(GAME_TIMES) do
		local b = pill(tm[1], timeGrid, i)
		b.TextSize = 12
		gTimeBtns[i] = b
		b.Activated:Connect(function()
			state.gTime = tm[2]
			if tm[2] >= 0 then
				arm()
			end
			notify("Giờ game: " .. tm[1])
			refresh()
		end)
	end
	local lockGrid = grid(timeCard, 130, 28, 1)
	local lockBtn = pill("Khóa giờ", lockGrid, 1)
	toggles.gLock = lockBtn
	lockBtn.Activated:Connect(function()
		state.gLock = not state.gLock
		notify(state.gLock and "Đã khóa giờ game" or "Đã mở khóa giờ")
		refresh()
	end)

	local fxCard = card(gamePage, "Hiệu ứng ánh sáng game")
	for _, info in ipairs({{"gBloom", "Bloom (tỏa sáng)"}, {"gRays", "Tia nắng (SunRays)"}, {"gFog", "Sương mù"}}) do
		header(fxCard, info[2])
		local lg = grid(fxCard, 70, 28, 4)
		levelBtns[info[1]] = {}
		for i, name in ipairs({"Tắt", "Nhẹ", "Vừa", "Mạnh"}) do
			local b = pill(name, lg, i)
			levelBtns[info[1]][i] = b
			b.Activated:Connect(function()
				state[info[1]] = i - 1
				if i > 1 then
					arm()
				end
				notify(info[2] .. ": " .. name)
				refresh()
			end)
		end
	end
end
local TRIGGER = "/hoclamscriptvip@"
local lastClarity = state.clarity
local lastGame = 0

loadColor = function(keep)
	local c = state[state.edit]
	if c == "rainbow" then return end
	if c == "auto" then c = autoHex() end
	local col = Color3.fromHex(c)
	rgb[1] = math.floor(col.R * 255 + 0.5)
	rgb[2] = math.floor(col.G * 255 + 0.5)
	rgb[3] = math.floor(col.B * 255 + 0.5)
	if keep then return end
	local h, s, v = col:ToHSV()
	if s > 0.02 and v > 0.02 then
		hsv[1] = h
	end
	hsv[2] = s
	hsv[3] = v
end

refresh = function()
	local cur = state[state.edit]
	for key, s in pairs(colorStroke) do
		s.Transparency = key == cur and 0 or 1
	end
	for i, s in ipairs(themeStroke) do
		s.Transparency = i == state.theme and 0 or 1
	end
	for i, s in ipairs(skyStroke) do
		local sk = SKIES[i]
		s.Transparency = (not state.skyAuto and state.skyTop == sk.top and state.skyBottom == sk.bottom) and 0 or 1
	end
	for i, s in ipairs(toneStroke) do
		local t = TONES[i]
		s.Transparency = (not state.skyAuto and state.skyTop == t.top and state.skyBottom == t.bottom) and 0 or 1
	end
	for key, s in pairs(lightStroke) do
		s.Transparency = key == state.light and 0 or 1
	end
	for i, s in ipairs(gToneStroke) do
		s.Transparency = TONES[i][2] == state.gSky and 0 or 1
	end
	for key, s in pairs(gLightStroke) do
		s.Transparency = key == state.gLight and 0 or 1
	end
	for key, b in pairs(tagBtns) do
		setActive(b, key == state.tag)
	end
	for key, b in pairs(badgeBtns) do
		setActive(b, key == state.badge)
	end
	for key, b in pairs(targetBtns) do
		setActive(b, key == state.edit)
	end
	for key, b in pairs(toggles) do
		setActive(b, state[key])
	end
	for i, b in ipairs(fontBtns) do
		setActive(b, FACES[i][1] == state.face)
	end
	for i, b in ipairs(uniBtns) do
		setActive(b, i == state.uni)
	end
	for i, b in ipairs(clarityBtns) do
		setActive(b, i == state.clarity)
	end
	for i, b in ipairs(gStrBtns) do
		setActive(b, i == state.gStrength)
	end
	for i, b in ipairs(gTimeBtns) do
		setActive(b, GAME_TIMES[i][2] == state.gTime)
	end
	for key, list in pairs(levelBtns) do
		for i, b in ipairs(list) do
			setActive(b, i - 1 == state[key])
		end
	end
	for i, b in ipairs(tabBtns) do
		setActive(b, i == state.tab)
	end
	for i, p in ipairs(pages) do
		p.Visible = i == state.tab
	end
	for i = 1, 3 do
		sliderUI[i](rgb[i])
	end
	svBox.BackgroundColor3 = Color3.fromHSV(hsv[1], 1, 1)
	svKnob.Position = UDim2.new(hsv[2], 0, 1 - hsv[3], 0)
	svKnob.BackgroundColor3 = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
	hueKnob.Position = UDim2.new(hsv[1], 0, 0.5, 0)
	for _, p in ipairs(pickers) do
		p.sync()
	end
	chanBtn.Text = "Kênh: " .. state.channel
	othersPreview.Text = "Người khác có thể thấy: " .. plainPrefix() .. uniApply("Xin chào!")
	preview.Text = tagPrefix() .. "Tên: " .. chatPaint("Xin chào mọi người!")
	if lastClarity ~= state.clarity then
		lastClarity = state.clarity
		tweenTo(main, {BackgroundTransparency = CLARITY[state.clarity]}, 0.2)
	end
	applyFx()
	forceLook()
	gameApply()
	save()
end

local BUBBLE = 54
local bubble = make("ImageButton", {Name = "Bubble", Size = UDim2.new(0, BUBBLE, 0, BUBBLE), Position = UDim2.new(0, 20, 0.5, -27), BackgroundColor3 = Color3.fromRGB(24, 18, 10), BackgroundTransparency = 0.2, AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Active = true}, gui)
make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, bubble)
make("UIAspectRatioConstraint", {AspectRatio = 1}, bubble)
local bubbleImg = make("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0}, bubble)
make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, bubbleImg)
glow(bubble, 0.2, 2)

local placed = false
local function hideMain()
	if not placed then
		local p = main.AbsolutePosition
		bubble.Position = UDim2.fromOffset(p.X, p.Y)
		placed = true
	end
	main.Visible = false
	bubble.Visible = true
end

local function openMain()
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	bubble.Visible = false
	mainScale.Scale = 0.9
	main.Visible = true
	tweenTo(mainScale, {Scale = 1}, 0.14)
end

pcall(function()
	local old = TextChatService:FindFirstChild("GlassChatCmd")
	if old then
		old:Destroy()
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "GlassChatCmd"
	cmd.PrimaryAlias = "/hoclamscriptVip@"
	cmd.SecondaryAlias = "/hoclamscriptvip@"
	cmd.Parent = TextChatService
	cmd.Triggered:Connect(function()
		openMain()
		notify("Đã mở Glass Chat")
	end)
end)

TextChatService.OnIncomingMessage = function(msg)
	local props = Instance.new("TextChatMessageProperties")
	pcall(function()
		if isMine(msg) then
			local text = msg.Text
			local pp = plainPrefix()
			local viaBox = false
			if pp ~= "" and string.sub(text, 1, #pp) == pp then
				text = string.sub(text, #pp + 1)
				viaBox = true
			end
			local clean = string.gsub(text, "^%s+", "")
			clean = string.gsub(clean, "%s+$", "")
			if string.lower(clean) == TRIGGER then
				task.defer(openMain)
			end
			props.PrefixText = (viaBox and badgeText() or "") .. tagPrefix() .. msg.PrefixText
			props.Text = chatPaint(text)
		end
	end)
	pcall(function()
		if isMine(msg) and msg.Translation ~= "" then
			props.Translation = chatPaint(msg.Translation)
		end
	end)
	return props
end

minBtn.Activated:Connect(hideMain)

closeBtn.Activated:Connect(function()
	main.Visible = false
	bubble.Visible = false
end)

local dragging, startInput, startPos
bar.InputBegan:Connect(function(input)
	if isPress(input) then
		dragging = true
		startInput = input.Position
		startPos = main.Position
	end
end)

local bDrag, bMoved, bStart, bPos
bubble.InputBegan:Connect(function(input)
	if isPress(input) then
		bDrag = true
		bMoved = false
		bStart = input.Position
		bPos = bubble.Position
	end
end)

conns[#conns + 1] = RunService.Heartbeat:Connect(function()
	local t = os.clock()
	if main.Visible then
		sunStep(t)
	end
	local r = (t * 40) % 360
	for _, g in ipairs(spin) do
		g.Rotation = r
	end
	if state.gameOn then
		if state.gLock and state.gTime >= 0 then
			pcall(function()
				Lighting.ClockTime = state.gTime
			end)
		end
		if t - lastGame > 0.3 then
			lastGame = t
			gameApply()
		end
	end
end)

conns[#conns + 1] = UIS.InputChanged:Connect(function(input)
	local t = input.UserInputType
	if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
	if activeSlider then
		activeSlider(input.Position.X, input.Position.Y)
	elseif dragging then
		local d = input.Position - startInput
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	elseif bDrag then
		local d = input.Position - bStart
		if d.Magnitude > 6 then
			bMoved = true
		end
		if bMoved then
			local s = gui.AbsoluteSize
			bubble.Position = UDim2.fromOffset(math.clamp(bPos.X.Offset + d.X, 0, s.X - BUBBLE), math.clamp(bPos.Y.Offset + d.Y, 0, s.Y - BUBBLE))
		end
	end
end)

conns[#conns + 1] = UIS.InputEnded:Connect(function(input)
	if not isPress(input) then return end
	activeSlider = nil
	dragging = false
	lockScroll(true)
	if bDrag then
		bDrag = false
		if not bMoved then
			openMain()
		end
	end
end)

state.tab = 1
loadColor()
refresh()
local saveLang = LANG

do
	local EN = {
		["Màu sắc"] = "Colors", ["Tiller"] = "Tag", ["Gửi tin"] = "Send", ["Nền kính"] = "Glass", ["Chữ"] = "Text", ["Cài đặt"] = "Settings",
		["Ánh sáng"] = "Light", ["Trời trên"] = "Sky top", ["Trời dưới"] = "Sky bottom", ["Đang chỉnh màu cho"] = "Editing color for",
		["Phong cách VIP (1 chạm)"] = "VIP styles (1 tap)", ["Vua Vàng"] = "Gold King", ["Quỷ Đỏ"] = "Red Demon", ["Thiên Thần"] = "Angel",
		["Ninja Tím"] = "Purple Ninja", ["Cầu Vồng"] = "Rainbow", ["Chọn tiller"] = "Choose tag", ["Không"] = "None",
		["Tiller tự đặt"] = "Custom tag", ["Gõ tiller rồi bấm Enter"] = "Type a tag, then press Enter",
		["Bảng màu"] = "Color board", ["Màu có sẵn"] = "Preset colors", ["Tinh chỉnh RGB"] = "RGB fine-tune",
		["Gõ mã màu, ví dụ FF3B3B"] = "Type a color code, e.g. FF3B3B",
		["Hiệu ứng chữ (hiện trên máy bạn)"] = "Text effects (only you see)", ["Phông chữ (hiện trên máy bạn)"] = "Fonts (only you see)",
		["Kiểu chữ đặc biệt (người khác thấy)"] = "Special text styles (others see)", ["Mặc định"] = "Default",
		["Đậm"] = "Bold", ["Nghiêng"] = "Italic", ["Gạch chân"] = "Underline", ["Gạch ngang"] = "Strike", ["Viết hoa"] = "Uppercase",
		["Viền chữ"] = "Outline", ["Tô nền"] = "Highlight", ["Thường"] = "Normal", ["Đậm nghiêng"] = "Bold italic", ["Viết tay"] = "Script",
		["Gô-tích"] = "Gothic", ["Máy chữ"] = "Mono", ["Rộng"] = "Wide", ["Tròn"] = "Circle", ["Chữ nhỏ"] = "Small caps",
		["Chỉ áp dụng cho tin gửi từ ô Gửi tin hoặc tin mẫu. Chữ có dấu tiếng Việt giữ nguyên. Nếu thấy ô vuông thì chọn lại Thường."] = "Only applies to messages sent from the Send box or quick messages. Vietnamese accented letters stay unchanged. If you see squares, switch back to Normal.",
		["Gửi tin (người khác sẽ thấy)"] = "Send message (others will see)", ["Gõ tin nhắn..."] = "Type a message...", ["Gửi"] = "Send",
		["Kèm tiller"] = "Attach tag", ["Kênh"] = "Channel", ["Huy hiệu VIP (người khác thấy)"] = "VIP badge (others see)",
		["Tin nhắn mẫu (chạm để gửi)"] = "Quick messages (tap to send)", ["Thêm tin mẫu..."] = "Add quick message...", ["Thêm"] = "Add", ["Mẹo"] = "Tips",
		["Gõ /hoclamscriptVip@ trong chat để mở lại bảng sau khi bấm ×. Chỉ tin gửi từ ô Gửi tin hoặc tin mẫu mới kèm huy hiệu, tiller và kiểu chữ đặc biệt cho người khác thấy. Màu chữ chỉ hiện trên máy bạn."] = "Type /hoclamscriptVip@ in chat to reopen the hub after pressing ×. Only messages sent from the Send box or quick messages carry the badge, tag and special text style for others to see. Text colors only show on your device.",
		["Chọn màu nền kính tự do (chạm là đổi ngay)"] = "Pick any glass color (applies instantly)",
		["Chọn màu tia nắng tự do (chạm là đổi ngay)"] = "Pick any light-ray color (applies instantly)",
		["Tông màu nền kính (đỏ, xanh, tím...)"] = "Glass color tones (red, blue, purple...)", ["Nền kính có sẵn"] = "Glass presets",
		["Ngày & đêm"] = "Day & night", ["Chỉnh bằng RGB"] = "Edit with RGB", ["Màu tia nắng"] = "Light-ray color",
		["Hiệu ứng ánh sáng của bảng"] = "Hub light effects", ["Tia sáng"] = "Rays", ["Vệt sáng"] = "Light sweep", ["Hạt & sao"] = "Sparkles & stars",
		["Mây trời"] = "Clouds", ["Độ trong của kính"] = "Glass clarity", ["Đục"] = "Opaque", ["Vừa"] = "Medium", ["Trong"] = "Clear", ["Rất trong"] = "Very clear",
		["Màu viền và nút (chủ đề)"] = "Border & button color (theme)", ["Nắng Vàng"] = "Sunny Gold", ["Lưu cài đặt"] = "Save settings",
		["Tự động lưu mọi cài đặt, kể cả màu và hiệu ứng game. Lần sau chạy lại sẽ giữ nguyên."] = "All settings, including colors and game effects, are saved automatically and restored next run.",
		["Executor của bạn không hỗ trợ lưu file, nên cài đặt sẽ mất khi thoát game."] = "Your executor can't save files, so settings are lost when you leave the game.",
		["Lưu ngay"] = "Save now", ["Đặt lại tất cả"] = "Reset all", ["Ghi chú"] = "Notes",
		["Chủ đề chỉ đổi màu viền sáng và các nút đang chọn. Nền kính và tia nắng của bảng nằm ở tab Nền kính. Ánh sáng thật trong game nằm ở tab Game."] = "Themes only change the glowing border and selected buttons. The hub's glass and light rays are in the Glass tab. Real in-game lighting is in the Game tab.",
		["Hiệu ứng ánh sáng trong game"] = "In-game lighting effects", ["Bật hiệu ứng game"] = "Enable game effects", ["Khôi phục gốc"] = "Restore original",
		["Chỉ đổi trên máy bạn, người khác không thấy. Mỗi game có ánh sáng riêng nên mức đổi màu có thể khác nhau, vài game tự đặt lại ánh sáng liên tục."] = "Only changes on your device; others can't see it. Each game has its own lighting, so results vary, and some games keep resetting the lighting.",
		["Màu bầu trời (game)"] = "Sky color (game)", ["Cường độ"] = "Strength", ["Nhẹ"] = "Light", ["Mạnh"] = "Strong",
		["Màu ánh sáng (game)"] = "Light color (game)", ["Giờ trong game (đổi sắc trời)"] = "Game time (changes sky tone)", ["Khóa giờ"] = "Lock time",
		["Hiệu ứng ánh sáng game"] = "Game light effects", ["Bloom (tỏa sáng)"] = "Bloom (glow)", ["Tia nắng (SunRays)"] = "Sun rays",
		["Sương mù"] = "Fog", ["Tắt"] = "Off",
		["Bình minh"] = "Dawn", ["Sáng"] = "Morning", ["Trưa"] = "Noon", ["Chiều"] = "Afternoon", ["Hoàng hôn"] = "Sunset", ["Đêm"] = "Night", ["Giữ nguyên"] = "Keep",
		["Đỏ"] = "Red", ["Cam"] = "Orange", ["Vàng"] = "Yellow", ["Chanh"] = "Lime", ["Lục"] = "Green", ["Ngọc"] = "Teal", ["Lơ"] = "Cyan",
		["Xanh"] = "Blue", ["Chàm"] = "Indigo", ["Tím"] = "Purple", ["Hồng"] = "Pink", ["Bạc"] = "Silver",
		["Nắng vàng"] = "Golden sun", ["Trưa xanh"] = "Blue noon", ["Đêm sao"] = "Starry night", ["Hoa anh đào"] = "Cherry blossom",
		["Ngọc bích"] = "Jade", ["Băng giá"] = "Frost",
		["Phông"] = "Font", ["Kiểu chữ"] = "Text style", ["Huy hiệu"] = "Badge", ["Phong cách"] = "Style", ["Độ trong"] = "Clarity",
		["Trời game"] = "Game sky", ["Giờ game"] = "Game time",
		["Đã mở RidKid Hub"] = "RidKid Hub opened", ["Mã màu gồm 6 ký tự 0-9, A-F"] = "Color code needs 6 characters 0-9, A-F",
		["Màu trời không dùng cầu vồng"] = "Sky color has no rainbow mode", ["Đã tắt tiller"] = "Tag turned off",
		["Bật kèm tiller"] = "Attach tag: on", ["Tắt kèm tiller"] = "Attach tag: off", ["Không thấy kênh này"] = "Channel not found",
		["Đã gửi tin"] = "Message sent", ["Gửi thất bại"] = "Send failed", ["Đã xóa tin mẫu"] = "Quick message removed",
		["Tối đa 12 tin mẫu"] = "Maximum 12 quick messages", ["Đã thêm tin mẫu"] = "Quick message added", ["Đã tắt huy hiệu"] = "Badge turned off",
		["Nền kính tự đổi màu"] = "Glass auto color on", ["Đã dừng đổi màu nền kính"] = "Glass auto color off",
		["Đang chỉnh màu nền trên"] = "Editing glass top color", ["Tia nắng đã đổi màu"] = "Light ray color changed",
		["Tia nắng theo màu nền"] = "Light follows glass color", ["Tia nắng đổi màu liên tục"] = "Light ray rainbow on",
		["Không hỗ trợ lưu file"] = "File saving not supported", ["Đã lưu cài đặt"] = "Settings saved", ["Lưu thất bại"] = "Save failed",
		["Đã đặt lại mặc định"] = "Reset to defaults", ["Đã bật hiệu ứng game"] = "Game effects on",
		["Đã khôi phục ánh sáng gốc"] = "Original lighting restored", ["Ánh sáng game đã đổi màu"] = "Game light color changed",
		["Ánh sáng theo màu trời game"] = "Light follows game sky", ["Đã khóa giờ game"] = "Game time locked", ["Đã mở khóa giờ"] = "Game time unlocked",
	}

	local PREFIX = {
		{"Bật ", "Enabled "},
		{"Tắt ", "Disabled "},
		{"Chủ đề ", "Theme "},
		{"Đã áp dụng màu ", "Applied color "},
	}

	local function TR(text)
		if LANG ~= "en" or type(text) ~= "string" then return text end
		local hit = EN[text]
		if hit then return hit end
		for _, p in ipairs(PREFIX) do
			if string.sub(text, 1, #p[1]) == p[1] then
				local rest = string.sub(text, #p[1] + 1)
				return p[2] .. (EN[rest] or rest)
			end
		end
		local l, r = string.match(text, "^(.-): (.+)$")
		if l then
			return (EN[l] or l) .. ": " .. (EN[r] or r)
		end
		return text
	end

	local function dynamicText()
		if LANG ~= "en" then return end
		chanBtn.Text = "Channel: " .. state.channel
		othersPreview.Text = "Others see: " .. plainPrefix() .. uniApply("Hello!")
		preview.Text = tagPrefix() .. "Name: " .. chatPaint("Hello everyone!")
	end

	for _, o in ipairs(gui:GetDescendants()) do
		if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
			if o.Text == "Glass Chat" then
				o.Text = "RidKid Hub"
			elseif o.Text == "Kính trời • Ánh sáng • Game" then
				o.Text = "Học Làm Script x Tvàn"
			elseif LANG == "en" then
				local t = EN[o.Text]
				if t then
					o.Text = t
				end
				if o:IsA("TextBox") then
					local p = EN[o.PlaceholderText]
					if p then
						o.PlaceholderText = p
					end
				end
			end
		end
	end

	local rawNotify = notify
	notify = function(text)
		if text == "Đã mở Glass Chat" then
			text = "Đã mở RidKid Hub"
		end
		rawNotify(TR(text))
	end

	local rawRefresh = refresh
	refresh = function()
		rawRefresh()
		dynamicText()
	end

	local rawWrite = writeNow
	writeNow = function()
		local okw = rawWrite()
		if canSave then
			pcall(function()
				local d = HttpService:JSONDecode(readfile(FILE))
				d.lang = saveLang
				d.askLang = askAgain
				writefile(FILE, HttpService:JSONEncode(d))
			end)
		end
		return okw
	end

	if LANG == "en" then
		local viQuick = {"Xin chào mọi người!", "Cho mình chơi cùng với", "Cảm ơn bạn nhé", "GG, chơi hay quá"}
		local enQuick = {"Hello everyone!", "Can I play with you?", "Thank you!", "GG, nicely played!"}
		local same = #quick == #viQuick
		if same then
			for i, v in ipairs(viQuick) do
				if quick[i] ~= v then
					same = false
				end
			end
		end
		for i, v in ipairs(enQuick) do
			DEFAULT_QUICK[i] = v
		end
		if same then
			quick = table.clone(DEFAULT_QUICK)
			buildQuick()
		end
	end
end
do
	local aboutPage = newPage()
	local idx = #pages
	local DISCORD = "https://discord.gg/Pfrxphu6M"
	local TIKTOK1 = "https://www.tiktok.com/@hoclamscript_roblox"
	local TIKTOK2 = "https://www.tiktok.com/@viet69xhamter"
	local white = Color3.new(1, 1, 1)

	local tabBtn = make("TextButton", {Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = white, BackgroundTransparency = 0.88, Text = T("Giới thiệu", "About"), TextColor3 = white, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = idx}, side)
	rounded(tabBtn, 8)
	tabBtns[idx] = tabBtn
	tabBtn.Activated:Connect(function()
		state.tab = idx
		refresh()
	end)

	local function note(parent, text, size)
		return make("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(235, 226, 205), Font = Enum.Font.Gotham, TextSize = size or 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder()}, parent)
	end

	local function copy(text)
		local fn = setclipboard or toclipboard
		if fn then
			local okc = pcall(fn, text)
			notify(okc and T("Đã sao chép", "Copied") or T("Sao chép thất bại", "Copy failed"))
		else
			notify(T("Không hỗ trợ sao chép, hãy giữ vào ô link để sao chép", "Copy not supported, hold the link box to copy"))
		end
	end

	local function linkRow(parent, url)
		local row = make("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, parent)
		local box = textBox(url, UDim2.new(1, -86, 1, 0), row)
		box.Text = url
		box.FocusLost:Connect(function()
			box.Text = url
		end)
		local b = make("TextButton", {Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -80, 0, 0), BackgroundColor3 = theme.accent, BackgroundTransparency = 0.3, Text = T("Sao chép", "Copy"), TextColor3 = white, Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0, AutoButtonColor = false}, row)
		rounded(b, 8)
		accentObjs[#accentObjs + 1] = b
		b.Activated:Connect(function()
			copy(url)
		end)
	end

	local authorCard = card(aboutPage, T("Tác giả", "Author"))
	make("TextLabel", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "Học Làm Script x Tvàn", TextColor3 = Color3.fromRGB(255, 226, 150), Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder()}, authorCard)
	note(authorCard, "RidKid Hub", 12)

	local introCard = card(aboutPage, T("Giới thiệu", "Introduction"))
	note(introCard, T("Script được tạo ra để phục vụ và giải trí cho người sử dụng. Có các chức năng tùy chỉnh giao diện, hiệu ứng bầu trời, ánh sáng, và tùy chỉnh kiểu chữ, màu sắc, tiller khi nhắn để tạo phong cách như một người sở hữu.", "This script was made to serve and entertain its users. It lets you customize the interface, sky and light effects, and your text style, colors and tag when chatting, to look like a game owner."))

	local dcCard = card(aboutPage, T("Discord hỗ trợ", "Discord support"))
	note(dcCard, T("Server của tôi: nếu bạn cần giúp đỡ, giúp tối ưu và sửa lỗi script của bạn. Ngoài ra tôi còn tặng code giao diện, chức năng khác...", "My server: get help, optimization and bug fixes for your scripts. I also share free UI code and other features..."))
	linkRow(dcCard, DISCORD)

	local ttCard = card(aboutPage, "TikTok")
	note(ttCard, T("Id TikTok mình đăng video:", "My TikTok, where I post videos:"))
	linkRow(ttCard, TIKTOK1)
	note(ttCard, T("Follow người cùng làm với mình nha:", "Please follow my partner too:"))
	linkRow(ttCard, TIKTOK2)

	local guideCard = card(aboutPage, T("Hướng dẫn nhanh", "Quick guide"))
	note(guideCard, T("• Màu sắc: chọn phong cách VIP 1 chạm, màu tiller, màu chữ chat, màu nền kính và màu tia nắng.", "• Colors: pick a 1-tap VIP style, tag color, chat text color, glass color and light-ray color."))
	note(guideCard, T("• Tiller: chọn danh hiệu hiện trước tên khi bạn nhắn tin, hoặc tự đặt.", "• Tag: choose the title shown before your name when chatting, or make your own."))
	note(guideCard, T("• Gửi tin: gửi tin kèm huy hiệu, tiller, kiểu chữ đặc biệt cho người khác thấy; có tin nhắn mẫu.", "• Send: send messages with a badge, tag and special text style that others can see; includes quick messages."))
	note(guideCard, T("• Nền kính: đổi bầu trời, ánh sáng, độ trong và hiệu ứng của chính bảng này.", "• Glass: change the sky, light, clarity and effects of this hub itself."))
	note(guideCard, T("• Chữ: bật hiệu ứng chữ (đậm, nghiêng, gạch...), đổi phông chữ, chọn kiểu chữ đặc biệt.", "• Text: turn on text effects (bold, italic, lines...), change the font, pick special text styles."))
	note(guideCard, T("• Game: đổi màu bầu trời, màu ánh sáng, giờ và hiệu ứng thật trong game (chỉ máy bạn thấy).", "• Game: change the real in-game sky color, light color, time and effects (only you see it)."))
	note(guideCard, T("• Cài đặt: đổi chủ đề viền, lưu hoặc đặt lại mọi thứ.", "• Settings: change the border theme, save or reset everything."))
	note(guideCard, T("• Mở lại bảng sau khi bấm ×: gõ /hoclamscriptVip@ trong chat.", "• Reopen the hub after pressing ×: type /hoclamscriptVip@ in chat."))

	local langCard = card(aboutPage, T("Ngôn ngữ", "Language"))
	local langGrid = grid(langCard, 120, 28, 3)
	local bVi = pill("Tiếng Việt", langGrid, 1)
	local bEn = pill("English", langGrid, 2)
	local bAsk = pill(T("Hỏi mỗi lần chạy", "Ask every run"), langGrid, 3)
	bAsk.TextSize = 12

	local function paintLang()
		setActive(bVi, saveLang == "vi")
		setActive(bEn, saveLang == "en")
		setActive(bAsk, askAgain)
	end

	bVi.Activated:Connect(function()
		saveLang = "vi"
		paintLang()
		save()
		notify(T("Sẽ áp dụng ở lần chạy sau", "Will apply on the next run"))
	end)
	bEn.Activated:Connect(function()
		saveLang = "en"
		paintLang()
		save()
		notify(T("Sẽ áp dụng ở lần chạy sau", "Will apply on the next run"))
	end)
	bAsk.Activated:Connect(function()
		askAgain = not askAgain
		paintLang()
		save()
		notify(askAgain and T("Sẽ hỏi ngôn ngữ mỗi lần chạy", "Will ask for language every run") or T("Sẽ không hỏi lại ngôn ngữ", "Won't ask for language again"))
	end)

	local prevRefresh = refresh
	refresh = function()
		prevRefresh()
		paintLang()
	end
end

refresh()
