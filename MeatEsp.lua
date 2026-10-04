local Players,RunService,Workspace,UIS=game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace"),game:GetService("UserInputService")
local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")

local old=PG:FindFirstChild("MeatESP_GUI")
if old then old:Destroy() end

local gui=Instance.new("ScreenGui")
gui.Name="MeatESP_GUI"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=PG

local function new(class,props,parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end

local function corner(o,r)
    new("UICorner",{CornerRadius=UDim.new(0,r)},o)
end

local main=new("Frame",{
    Size=UDim2.fromOffset(365,210),
    Position=UDim2.new(.5,-182,.5,-105),
    BackgroundColor3=Color3.fromRGB(10,10,13),
    BorderSizePixel=0
},gui)

corner(main,8)

new("UIStroke",{
    Color=Color3.fromRGB(255,45,45),
    Transparency=.3,
    Thickness=1
},main)

local top=new("Frame",{
    Size=UDim2.new(1,0,0,34),
    BackgroundColor3=Color3.fromRGB(16,16,20),
    BorderSizePixel=0
},main)

corner(top,8)

local title=new("TextLabel",{
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(11,0),
    Size=UDim2.new(1,-80,1,0),
    Font=Enum.Font.GothamBold,
    Text="MEAT  ESP",
    TextSize=14,
    TextColor3=Color3.fromRGB(255,55,55),
    TextXAlignment=Enum.TextXAlignment.Left
},top)

local sub=new("TextLabel",{
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(90,0),
    Size=UDim2.fromOffset(80,34),
    Font=Enum.Font.GothamMedium,
    Text="PREMIUM",
    TextSize=8,
    TextColor3=Color3.fromRGB(115,115,125),
    TextXAlignment=Enum.TextXAlignment.Left
},top)

local minimize=new("TextButton",{
    Size=UDim2.fromOffset(23,23),
    Position=UDim2.new(1,-52,0,5),
    BackgroundColor3=Color3.fromRGB(35,35,40),
    Text="—",
    TextSize=14,
    Font=Enum.Font.GothamBold,
    TextColor3=Color3.new(1,1,1),
    BorderSizePixel=0
},top)

corner(minimize,4)

local close=new("TextButton",{
    Size=UDim2.fromOffset(23,23),
    Position=UDim2.new(1,-26,0,5),
    BackgroundColor3=Color3.fromRGB(130,28,28),
    Text="×",
    TextSize=15,
    Font=Enum.Font.GothamBold,
    TextColor3=Color3.new(1,1,1),
    BorderSizePixel=0
},top)

corner(close,4)

local list=new("ScrollingFrame",{
    Size=UDim2.fromOffset(145,157),
    Position=UDim2.fromOffset(8,43),
    BackgroundColor3=Color3.fromRGB(16,16,20),
    BorderSizePixel=0,
    ScrollBarThickness=2,
    CanvasSize=UDim2.new()
},main)

corner(list,5)

local listTitle=new("TextLabel",{
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(7,0),
    Size=UDim2.new(1,-14,0,25),
    Font=Enum.Font.GothamBold,
    Text="MEAT LIST",
    TextSize=9,
    TextColor3=Color3.fromRGB(155,155,165),
    TextXAlignment=Enum.TextXAlignment.Left
},list)

local layout=new("UIListLayout",{
    Padding=UDim.new(0,2),
    SortOrder=Enum.SortOrder.LayoutOrder
},list)

local selected
local minimized=false
local meatEnabled=true
local playerEnabled=true
local speedEnabled=false
local walkSpeed=50
local meatESP={}
local playerESP={}

local function char()
    local c=LP.Character
    if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")
    local r=c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health>0 then return c,h,r end
end

local function part(o)
    return o:IsA("BasePart") and o or o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true))
end

local function hasName(o,...)
    local n=o.Name:lower()
    for _,x in ipairs({...}) do
        if n:find(x,1,true) then return true end
    end
end

local isMeat=function(o)
    return hasName(o,"meat","thịt","flesh","food")
end

local isWater=function(o)
    return hasName(o,"water","ocean","sea","lake","river","pond")
end

local function meatCreate(o)
    if meatESP[o] then return end

    local p=part(o)
    if not p then return end

    local f=new("Folder",{Name="MeatESP"},o)

    local box=new("Highlight",{
        Name="Box",
        Adornee=o,
        FillColor=Color3.fromRGB(255,0,0),
        OutlineColor=Color3.fromRGB(255,35,35),
        FillTransparency=.88,
        OutlineTransparency=0,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled=meatEnabled
    },f)

    local bb=new("BillboardGui",{
        Name="Info",
        Adornee=p,
        Size=UDim2.fromOffset(90,38),
        StudsOffset=Vector3.new(0,2.3,0),
        AlwaysOnTop=true,
        MaxDistance=2500,
        Enabled=meatEnabled
    },f)

    local name=new("TextLabel",{
        BackgroundTransparency=1,
        Size=UDim2.fromScale(1,.6),
        Font=Enum.Font.GothamBold,
        Text="THỊT",
        TextSize=12,
        TextColor3=Color3.fromRGB(255,45,45),
        TextStrokeColor3=Color3.new(),
        TextStrokeTransparency=.2
    },bb)

    local dist=new("TextLabel",{
        BackgroundTransparency=1,
        Position=UDim2.fromScale(0,.58),
        Size=UDim2.fromScale(1,.42),
        Font=Enum.Font.GothamMedium,
        TextSize=9,
        TextColor3=Color3.new(1,1,1),
        TextStrokeColor3=Color3.new(),
        TextStrokeTransparency=.25
    },bb)

    meatESP[o]={
        folder=f,
        part=p,
        box=box,
        billboard=bb,
        name=name,
        dist=dist
    }
end

local function meatRemove(o)
    local d=meatESP[o]

    if d then
        if d.folder then d.folder:Destroy() end
        meatESP[o]=nil

        if selected and selected.obj==o then
            selected=nil
        end
    end
end

local function scanMeat()
    for _,o in ipairs(Workspace:GetDescendants()) do
        if (o:IsA("BasePart") or o:IsA("Model")) and isMeat(o) then
            meatCreate(o)
        end
    end
end

local function playerCreate(plr)
    if plr==LP or playerESP[plr] then return end

    local c=plr.Character
    if not c then return end

    local r=c:FindFirstChild("HumanoidRootPart")
    local h=c:FindFirstChildOfClass("Humanoid")

    if not r or not h then return end

    local f=new("Folder",{Name="PlayerESP"},gui)

    local box=new("Highlight",{
        Name="PlayerBox",
        Adornee=c,
        FillColor=Color3.fromRGB(0,170,255),
        OutlineColor=Color3.fromRGB(0,220,255),
        FillTransparency=.88,
        OutlineTransparency=0,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled=playerEnabled
    },f)

    local bb=new("BillboardGui",{
        Name="PlayerInfo",
        Adornee=r,
        Size=UDim2.fromOffset(120,38),
        StudsOffset=Vector3.new(0,3,0),
        AlwaysOnTop=true,
        MaxDistance=2500,
        Enabled=playerEnabled
    },f)

    local name=new("TextLabel",{
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,.55,0),
        Font=Enum.Font.GothamBold,
        Text=plr.DisplayName,
        TextSize=11,
        TextColor3=Color3.fromRGB(0,210,255),
        TextStrokeColor3=Color3.new(),
        TextStrokeTransparency=.2
    },bb)

    local dist=new("TextLabel",{
        BackgroundTransparency=1,
        Position=UDim2.fromScale(0,.55),
        Size=UDim2.new(1,0,.45,0),
        Font=Enum.Font.GothamMedium,
        TextSize=9,
        TextColor3=Color3.new(1,1,1),
        TextStrokeColor3=Color3.new(),
        TextStrokeTransparency=.25
    },bb)

    playerESP[plr]={
        folder=f,
        box=box,
        billboard=bb,
        name=name,
        dist=dist
    }
end

local function playerRemove(plr)
    local d=playerESP[plr]

    if d then
        if d.folder then d.folder:Destroy() end
        playerESP[plr]=nil
    end
end

local function playerScan()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            playerCreate(p)
        end
    end
end

local function button(text,x,y,w,color)
    local b=new("TextButton",{
        Size=UDim2.fromOffset(w,29),
        Position=UDim2.fromOffset(x,y),
        BackgroundColor3=color,
        BorderSizePixel=0,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=Color3.new(1,1,1),
        Text=text,
        AutoButtonColor=false
    },main)

    corner(b,4)
    return b
end

local tele=button("TELE",164,43,58,Color3.fromRGB(170,35,35))
local water=button("NƯỚC",226,43,58,Color3.fromRGB(35,80,145))
local playerBtn=button("PLAYER: ON",288,43,69,Color3.fromRGB(20,105,145))

local speedBtn=button("SPEED: OFF",164,78,92,Color3.fromRGB(45,45,50))
local meatBtn=button("MEAT: ON",260,78,97,Color3.fromRGB(145,30,30))

local speedBox=new("TextBox",{
    Size=UDim2.fromOffset(92,29),
    Position=UDim2.fromOffset(164,113),
    BackgroundColor3=Color3.fromRGB(25,25,30),
    BorderSizePixel=0,
    Font=Enum.Font.GothamBold,
    TextSize=10,
    TextColor3=Color3.new(1,1,1),
    PlaceholderText="Speed",
    Text="50",
    ClearTextOnFocus=false
},main)

corner(speedBox,4)

local speedInfo=new("TextLabel",{
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(260,113),
    Size=UDim2.fromOffset(97,29),
    Font=Enum.Font.GothamMedium,
    TextSize=9,
    TextColor3=Color3.fromRGB(145,145,155),
    Text="SPEED 16–250",
    TextXAlignment=Enum.TextXAlignment.Center
},main)

local status=new("TextLabel",{
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(164,148),
    Size=UDim2.fromOffset(193,20),
    Font=Enum.Font.GothamMedium,
    TextSize=8,
    Text="MEAT ESP  •  PLAYER ESP  •  TELEPORT",
    TextColor3=Color3.fromRGB(90,90,100),
    TextXAlignment=Enum.TextXAlignment.Center
},main)

local function toggleESP(map,state,btn,onText,color)
    for _,d in pairs(map) do
        d.box.Enabled=state
        d.billboard.Enabled=state
    end

    btn.Text=state and onText or onText:gsub("ON","OFF")
    btn.BackgroundColor3=state and color or Color3.fromRGB(45,45,50)
end

meatBtn.MouseButton1Click:Connect(function()
    meatEnabled=not meatEnabled
    toggleESP(meatESP,meatEnabled,meatBtn,"MEAT: ON",Color3.fromRGB(145,30,30))
end)

playerBtn.MouseButton1Click:Connect(function()
    playerEnabled=not playerEnabled
    toggleESP(playerESP,playerEnabled,playerBtn,"PLAYER: ON",Color3.fromRGB(20,105,145))
end)

speedBox.FocusLost:Connect(function()
    local n=tonumber(speedBox.Text)

    walkSpeed=n and math.clamp(math.floor(n),16,250) or walkSpeed
    speedBox.Text=tostring(walkSpeed)
end)

speedBtn.MouseButton1Click:Connect(function()
    speedEnabled=not speedEnabled

    speedBtn.Text=speedEnabled and "SPEED: ON" or "SPEED: OFF"

    speedBtn.BackgroundColor3=
        speedEnabled and Color3.fromRGB(145,30,30)
        or Color3.fromRGB(45,45,50)

    local _,h=char()

    if h then
        h.WalkSpeed=speedEnabled and walkSpeed or 16
    end
end)

local function teleport(pos)
    local c,h,r=char()
    if not c then return end

    c:PivotTo(CFrame.new(pos+Vector3.new(0,5,0)))

    r.AssemblyLinearVelocity=Vector3.zero
    r.AssemblyAngularVelocity=Vector3.zero
end

local function nearestWater()
    local _,_,r=char()
    if not r then return end

    local target
    local dist=math.huge

    for _,o in ipairs(Workspace:GetDescendants()) do
        if (o:IsA("BasePart") or o:IsA("Model")) and isWater(o) then
            local p=part(o)

            if p and p:IsDescendantOf(Workspace) then
                local d=(p.Position-r.Position).Magnitude

                if d<dist then
                    target,dist=p,d
                end
            end
        end
    end

    return target
end

tele.MouseButton1Click:Connect(function()
    if selected and selected.part and selected.part.Parent then
        teleport(selected.part.Position)
    else
        selected=nil
    end
end)

water.MouseButton1Click:Connect(function()
    local p=nearestWater()
    if p then
        teleport(p.Position)
    end
end)

local function refreshList()
    for _,c in ipairs(list:GetChildren()) do
        if c:IsA("TextButton") then
            c:Destroy()
        end
    end

    local arr={}
    local _,_,r=char()

    for o,d in pairs(meatESP) do
        if o.Parent and d.part and d.part.Parent then
            arr[#arr+1]={
                obj=o,
                part=d.part
            }
        end
    end

    table.sort(arr,function(a,b)
        if not r then
            return tostring(a.obj)<tostring(b.obj)
        end

        return (a.part.Position-r.Position).Magnitude<
               (b.part.Position-r.Position).Magnitude
    end)

    for i,d in ipairs(arr) do
        local b=new("TextButton",{
            Size=UDim2.new(1,-10,0,22),
            BackgroundColor3=Color3.fromRGB(27,27,32),
            BorderSizePixel=0,
            AutoButtonColor=false,
            Font=Enum.Font.GothamMedium,
            TextSize=9,
            TextColor3=Color3.fromRGB(225,225,230),
            Text="THỊT  #"..i
        },list)

        corner(b,3)

        b.MouseButton1Click:Connect(function()
            selected=d

            for _,x in ipairs(list:GetChildren()) do
                if x:IsA("TextButton") then
                    x.BackgroundColor3=Color3.fromRGB(27,27,32)
                end
            end

            b.BackgroundColor3=Color3.fromRGB(125,25,25)
        end)
    end

    list.CanvasSize=UDim2.fromOffset(
        0,
        math.max(0,#arr*24)
    )
end

RunService.Heartbeat:Connect(function()
    local _,h=char()

    if speedEnabled and h then
        h.WalkSpeed=walkSpeed
    end
end)

RunService.RenderStepped:Connect(function()
    local _,_,r=char()

    for o,d in pairs(meatESP) do
        if not o.Parent or not d.part or not d.part.Parent then
            meatRemove(o)
        elseif r then
            local dist=(r.Position-d.part.Position).Magnitude

            d.dist.Text=math.floor(dist).."m"
            d.name.TextSize=math.clamp(12+dist*.03,12,25)
            d.dist.TextSize=math.clamp(8+dist*.01,8,13)
        end
    end

    if r then
        for p,d in pairs(playerESP) do
            local c=p.Character
            local pr=c and c:FindFirstChild("HumanoidRootPart")
            local h=c and c:FindFirstChildOfClass("Humanoid")

            if not p.Parent or not c or not pr or not h then
                playerRemove(p)
            else
                d.box.Adornee=c
                d.billboard.Adornee=pr

                local dist=(r.Position-pr.Position).Magnitude

                d.name.Text=p.DisplayName
                d.dist.Text=math.floor(dist).."m"
                d.name.TextSize=math.clamp(11+dist*.018,11,18)
                d.dist.TextSize=math.clamp(8+dist*.008,8,13)
            end
        end
    end
end)

Workspace.DescendantAdded:Connect(function(o)
    if (o:IsA("BasePart") or o:IsA("Model")) and isMeat(o) then
        task.defer(function()
            if o.Parent then
                meatCreate(o)
            end
        end)
    end
end)

Workspace.DescendantRemoving:Connect(function(o)
    if meatESP[o] then
        meatRemove(o)
    end
end)

local function setupPlayer(p)
    if p==LP then return end

    p.CharacterAdded:Connect(function()
        task.wait(.5)

        if playerEnabled then
            playerCreate(p)
        end
    end)

    if p.Character and playerEnabled then
        playerCreate(p)
    end
end

for _,p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(playerRemove)

local dragging=false
local dragStart
local startPos

top.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then

        dragging=true
        dragStart=i.Position
        startPos=main.Position
    end
end)

UIS.InputChanged:Connect(function(i)
    if not dragging then return end

    if i.UserInputType~=Enum.UserInputType.MouseMovement and
       i.UserInputType~=Enum.UserInputType.Touch then
        return
    end

    local d=i.Position-dragStart

    main.Position=UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset+d.X,
        startPos.Y.Scale,
        startPos.Y.Offset+d.Y
    )
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or
       i.UserInputType==Enum.UserInputType.Touch then
        dragging=false
    end
end)

minimize.MouseButton1Click:Connect(function()
    minimized=not minimized

    for _,o in ipairs({
        list,tele,water,playerBtn,
        speedBtn,meatBtn,speedBox,
        speedInfo,status
    }) do
        o.Visible=not minimized
    end

    main.Size=minimized
        and UDim2.fromOffset(365,34)
        or UDim2.fromOffset(365,210)

    minimize.Text=minimized and "+" or "—"
end)

close.MouseButton1Click:Connect(function()
    for o in pairs(meatESP) do
        meatRemove(o)
    end

    for p in pairs(playerESP) do
        playerRemove(p)
    end

    gui:Destroy()
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)

    if speedEnabled then
        local _,h=char()

        if h then
            h.WalkSpeed=walkSpeed
        end
    end
end)

scanMeat()
playerScan()
refreshList()

task.spawn(function()
    while gui.Parent do
        scanMeat()
        playerScan()
        refreshList()
        task.wait(2)
    end
end)
