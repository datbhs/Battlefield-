--[[
    ZENVOLT HUB | THUNDER EDITION
    Standalone Roblox LocalScript
    UI only: neon RGB, animated lightning, draggable window,
    floating toggle, player/server information, responsive tabs.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
if not Player then return end

local PlayerGui = Player:WaitForChild("PlayerGui")
local Previous = PlayerGui:FindFirstChild("ZenvoltHub")
if Previous then Previous:Destroy() end

local CONFIG = {
    RGBSpeed = 0.7,
    Neon = Color3.fromRGB(0, 235, 255),
    Background = Color3.fromRGB(10, 12, 19),
    Card = Color3.fromRGB(23, 28, 42),
    Text = Color3.fromRGB(235, 245, 255),
    Muted = Color3.fromRGB(135, 151, 173),
}

local RGBEnabled = true
local AnimationsEnabled = true
local Alive = true
local FPS = 0
local Frames = 0
local LastFPSUpdate = os.clock()
local Connections = {}
local TabButtons = {}
local PageBuilders = {}
local CurrentTab = "Home"
local SwitchTab

local function KeepConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function New(className, properties, parent)
    local obj = Instance.new(className)
    for key, value in pairs(properties or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 10)
    }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or CONFIG.Neon,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function Padding(parent, amount)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, amount),
        PaddingBottom = UDim.new(0, amount),
        PaddingLeft = UDim.new(0, amount),
        PaddingRight = UDim.new(0, amount),
    }, parent)
end

local function MakeLabel(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CONFIG.Text,
        Font = font or Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function MakeButton(parent, text, size, color)
    local baseColor = color or CONFIG.Card
    local button = New("TextButton", {
        AutoButtonColor = false,
        Text = text,
        Size = size or UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = baseColor,
        TextColor3 = CONFIG.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
    }, parent)

    Corner(button, 9)
    Stroke(button, CONFIG.Neon, 1, 0.72)

    KeepConnection(button.MouseEnter:Connect(function()
        if not Alive or not AnimationsEnabled then return end
        TweenService:Create(button, TweenInfo.new(0.13), {
            BackgroundColor3 = Color3.fromRGB(29, 48, 62)
        }):Play()
    end))

    KeepConnection(button.MouseLeave:Connect(function()
        if not Alive then return end
        TweenService:Create(button, TweenInfo.new(0.16), {
            BackgroundColor3 = baseColor
        }):Play()
    end))

    KeepConnection(button.Activated:Connect(function()
        if not Alive or not AnimationsEnabled then return end
        local originalSize = button.Size
        TweenService:Create(button, TweenInfo.new(0.07), {
            BackgroundColor3 = Color3.fromRGB(35, 70, 88)
        }):Play()
        task.delay(0.09, function()
            if button.Parent and Alive then
                TweenService:Create(button, TweenInfo.new(0.12), {
                    BackgroundColor3 = baseColor
                }):Play()
            end
        end)
    end))

    return button
end

local function MakeCard(parent, title, description, height)
    local card = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        Size = UDim2.new(1, 0, 0, height or 78),
    }, parent)
    Corner(card, 10)
    Stroke(card, Color3.fromRGB(45, 65, 85), 1, 0.35)

    local heading = MakeLabel(card, title, 13, CONFIG.Neon, Enum.Font.GothamBold)
    heading.Position = UDim2.fromOffset(12, 8)
    heading.Size = UDim2.new(1, -24, 0, 21)

    local desc = MakeLabel(card, description, 11, CONFIG.Muted)
    desc.Position = UDim2.fromOffset(12, 31)
    desc.Size = UDim2.new(1, -24, 1, -36)
    desc.TextYAlignment = Enum.TextYAlignment.Top

    return card
end

-- Main ScreenGui
local Screen = New("ScreenGui", {
    Name = "ZenvoltHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
}, PlayerGui)

local Main = New("Frame", {
    Name = "Main",
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    ClipsDescendants = true,
}, Screen)
Corner(Main, 14)

local MainStroke = Stroke(Main, CONFIG.Neon, 1.7, 0)
local MainGradient = New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 245, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 50, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 30, 160)),
    }),
    Rotation = 0,
}, MainStroke)

-- Lightning layers are clipped to the window
local ThunderFX = New("Frame", {
    Name = "ThunderFX",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Active = false,
    ClipsDescendants = true,
    ZIndex = 20,
}, Main)

local ThunderFlash = New("Frame", {
    Name = "ThunderFlash",
    BackgroundColor3 = Color3.fromRGB(130, 210, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    Active = false,
    ZIndex = 18,
}, Main)
Corner(ThunderFlash, 14)

-- Header
local Header = New("Frame", {
    Name = "Header",
    BackgroundColor3 = Color3.fromRGB(14, 18, 28),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 54),
    ZIndex = 30,
}, Main)
Corner(Header, 14)

New("Frame", {
    BackgroundColor3 = Header.BackgroundColor3,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    ZIndex = 30,
}, Header)

local Logo = New("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(17, 6),
    Size = UDim2.fromOffset(40, 40),
    Text = "ϟ",
    TextColor3 = CONFIG.Neon,
    Font = Enum.Font.GothamBlack,
    TextSize = 36,
    ZIndex = 31,
}, Header)

local Title = MakeLabel(Header, "ZENVOLT HUB", 17, CONFIG.Text, Enum.Font.GothamBlack)
Title.Position = UDim2.fromOffset(61, 6)
Title.Size = UDim2.new(0.65, -61, 0, 23)
Title.ZIndex = 31

local Subtitle = MakeLabel(Header, "THUNDER EDITION / LUAU", 9, CONFIG.Muted)
Subtitle.Position = UDim2.fromOffset(62, 29)
Subtitle.Size = UDim2.new(0.65, -62, 0, 15)
Subtitle.ZIndex = 31

local CloseButton = MakeButton(Header, "×", UDim2.fromOffset(35, 32), Color3.fromRGB(65, 25, 43))
CloseButton.AnchorPoint = Vector2.new(1, 0.5)
CloseButton.Position = UDim2.new(1, -12, 0.5, 0)
CloseButton.TextSize = 23
CloseButton.ZIndex = 32

-- Body and navigation
local Body = New("Frame", {
    Name = "Body",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 54),
    Size = UDim2.new(1, 0, 1, -54),
    ZIndex = 2,
}, Main)

local Sidebar = New("Frame", {
    Name = "Sidebar",
    BackgroundColor3 = Color3.fromRGB(13, 16, 25),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 145, 1, 0),
}, Body)
Corner(Sidebar, 12)
Padding(Sidebar, 10)

New("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local Content = New("Frame", {
    Name = "Content",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 155, 0, 0),
    Size = UDim2.new(1, -165, 1, 0),
    ClipsDescendants = true,
}, Body)

local ContentTitle = MakeLabel(Content, "OVERVIEW", 17, CONFIG.Text, Enum.Font.GothamBold)
ContentTitle.Position = UDim2.fromOffset(5, 8)
ContentTitle.Size = UDim2.new(1, -10, 0, 30)

local ContentSubtitle = MakeLabel(Content, "Welcome back to your control center.", 11, CONFIG.Muted)
ContentSubtitle.Position = UDim2.fromOffset(5, 36)
ContentSubtitle.Size = UDim2.new(1, -10, 0, 23)

local Page = New("ScrollingFrame", {
    Name = "Page",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 65),
    Size = UDim2.new(1, 0, 1, -70),
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CONFIG.Neon,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Content)
Padding(Page, 5)

local PageLayout = New("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Page)

local AvatarImage = ""
pcall(function()
    AvatarImage = Players:GetUserThumbnailAsync(
        Player.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local function ReadPing()
    local ping
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if typeof(ping) == "number" then
        return string.format("%.0f ms", ping)
    end
    return "N/A"
end

local function AddInfoCard(title, description, height)
    return MakeCard(Page, title, description, height)
end

local function ClearPage()
    for _, child in ipairs(Page:GetChildren()) do
        if child ~= PageLayout and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

-- Home
local function BuildHome()
    local profile = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        Size = UDim2.new(1, 0, 0, 105),
    }, Page)
    Corner(profile, 12)
    Stroke(profile, CONFIG.Neon, 1, 0.55)

    local avatar = New("ImageLabel", {
        BackgroundColor3 = CONFIG.Background,
        Image = AvatarImage,
        Size = UDim2.fromOffset(65, 65),
        Position = UDim2.fromOffset(12, 19),
    }, profile)
    Corner(avatar, 32)

    local name = MakeLabel(profile, Player.DisplayName, 15, CONFIG.Text, Enum.Font.GothamBold)
    name.Position = UDim2.fromOffset(88, 22)
    name.Size = UDim2.new(1, -100, 0, 24)

    local username = MakeLabel(profile, "@" .. Player.Name, 11, CONFIG.Neon)
    username.Position = UDim2.fromOffset(88, 47)
    username.Size = UDim2.new(1, -100, 0, 18)

    local uid = MakeLabel(profile, "USER ID: " .. Player.UserId, 10, CONFIG.Muted)
    uid.Position = UDim2.fromOffset(88, 68)
    uid.Size = UDim2.new(1, -100, 0, 17)

    local statsCard = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        Size = UDim2.new(1, 0, 0, 78),
    }, Page)
    Corner(statsCard, 10)
    Stroke(statsCard, CONFIG.Neon, 1, 0.65)

    local fpsLabel = MakeLabel(statsCard, "FPS: --", 13, CONFIG.Neon, Enum.Font.GothamBold)
    fpsLabel.Position = UDim2.fromOffset(12, 12)
    fpsLabel.Size = UDim2.new(0.5, -12, 0, 22)

    local pingLabel = MakeLabel(statsCard, "PING: --", 13, CONFIG.Neon, Enum.Font.GothamBold)
    pingLabel.Position = UDim2.new(0.5, 0, 0, 12)
    pingLabel.Size = UDim2.new(0.5, -10, 0, 22)

    local status = MakeLabel(statsCard, "LIVE CLIENT STATISTICS", 9, CONFIG.Muted)
    status.Position = UDim2.fromOffset(12, 43)
    status.Size = UDim2.new(1, -24, 0, 17)

    local server = New("Frame", {
        BackgroundColor3 = CONFIG.Card,
        Size = UDim2.new(1, 0, 0, 108),
    }, Page)
    Corner(server, 10)
    Stroke(server, Color3.fromRGB(45, 65, 85), 1, 0.35)

    local serverTitle = MakeLabel(server, "SERVER INFORMATION", 12, CONFIG.Text, Enum.Font.GothamBold)
    serverTitle.Position = UDim2.fromOffset(12, 8)
    serverTitle.Size = UDim2.new(1, -24, 0, 20)

    local placeLabel = MakeLabel(server, "PLACE ID: " .. tostring(game.PlaceId), 10, CONFIG.Muted)
    placeLabel.Position = UDim2.fromOffset(12, 34)
    placeLabel.Size = UDim2.new(1, -24, 0, 18)

    local jobLabel = MakeLabel(server, "JOB ID: " .. tostring(game.JobId), 10, CONFIG.Muted)
    jobLabel.Position = UDim2.fromOffset(12, 57)
    jobLabel.Size = UDim2.new(1, -24, 0, 36)

    KeepConnection(RunService.RenderStepped:Connect(function()
        if not Alive or not statsCard.Parent then return end
        fpsLabel.Text = "FPS: " .. tostring(FPS)
        pingLabel.Text = "PING: " .. ReadPing()
    end))
end

local function BuildPlayer()
    AddInfoCard("PLAYER PROFILE",
        "Name: " .. Player.Name ..
        "\nDisplay name: " .. Player.DisplayName ..
        "\nUserId: " .. tostring(Player.UserId), 88)
    AddInfoCard("CHARACTER",
        "This page displays your local player information. Add your own character tools here.", 78)
    local refresh = MakeButton(Page, "REFRESH PROFILE", UDim2.new(1, 0, 0, 38))
    KeepConnection(refresh.Activated:Connect(function()
        if Alive then SwitchTab("Player") end
    end))
end

local function BuildVisuals()
    AddInfoCard("VISUAL SETTINGS", "Customize the Hub's neon border and interface appearance.")
    local rgbButton = MakeButton(Page, "RGB BORDER: ON", UDim2.new(1, 0, 0, 38))
    KeepConnection(rgbButton.Activated:Connect(function()
        RGBEnabled = not RGBEnabled
        rgbButton.Text = "RGB BORDER: " .. (RGBEnabled and "ON" or "OFF")
    end))
    local animButton = MakeButton(Page, "UI ANIMATIONS: ON", UDim2.new(1, 0, 0, 38))
    KeepConnection(animButton.Activated:Connect(function()
        AnimationsEnabled = not AnimationsEnabled
        animButton.Text = "UI ANIMATIONS: " .. (AnimationsEnabled and "ON" or "OFF")
    end))
    AddInfoCard("PERFORMANCE", "Lightning effects are limited to the Hub window.")
end

local function BuildScriptHub()
    AddInfoCard("SCRIPT HUB", "Organize your own Roblox Studio tools and authorized scripts here.", 78)
    local info = MakeButton(Page, "SHOW ENVIRONMENT INFO", UDim2.new(1, 0, 0, 38))
    KeepConnection(info.Activated:Connect(function()
        ContentSubtitle.Text = "PlaceId: " .. tostring(game.PlaceId)
    end))
    AddInfoCard("EXTENSION POINT", "No remote code is downloaded or executed by this template.", 78)
end

local function BuildSettings()
    AddInfoCard("INTERFACE SETTINGS", "Change the appearance and motion of ZENVOLT HUB.")
    local rgb = MakeButton(Page, "TOGGLE RGB", UDim2.new(1, 0, 0, 38))
    KeepConnection(rgb.Activated:Connect(function()
        RGBEnabled = not RGBEnabled
        rgb.Text = "RGB: " .. (RGBEnabled and "ON" or "OFF")
    end))
    local motion = MakeButton(Page, "TOGGLE ANIMATIONS", UDim2.new(1, 0, 0, 38))
    KeepConnection(motion.Activated:Connect(function()
        AnimationsEnabled = not AnimationsEnabled
        motion.Text = "ANIMATIONS: " .. (AnimationsEnabled and "ON" or "OFF")
    end))
    local hide = MakeButton(Page, "HIDE HUB", UDim2.new(1, 0, 0, 38))
    KeepConnection(hide.Activated:Connect(function()
        Main.Visible = false
    end))
    AddInfoCard("ABOUT", "ZENVOLT HUB • THUNDER EDITION\nStandalone Luau interface.", 78)
end

PageBuilders = {
    Home = BuildHome,
    Player = BuildPlayer,
    Visuals = BuildVisuals,
    ["Script Hub"] = BuildScriptHub,
    Settings = BuildSettings,
}

local tabs = {
    {"Home", "⌂"},
    {"Player", "◉"},
    {"Visuals", "◈"},
    {"Script Hub", "ϟ"},
    {"Settings", "⚙"},
}

for index, data in ipairs(tabs) do
    local tabName, symbol = data[1], data[2]
    local button = MakeButton(Sidebar, symbol .. "    " .. tabName,
        UDim2.new(1, 0, 0, 37), Color3.fromRGB(17, 20, 31))
    button.LayoutOrder = index
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextSize = 12
    Padding(button, 9)
    TabButtons[tabName] = button

    KeepConnection(button.Activated:Connect(function()
        SwitchTab(tabName)
    end))
end

SwitchTab = function(tabName)
    if not Alive or not PageBuilders[tabName] then return end
    CurrentTab = tabName

    for name, button in pairs(TabButtons) do
        local selected = name == tabName
        button.BackgroundColor3 = selected
            and Color3.fromRGB(20, 50, 66)
            or Color3.fromRGB(17, 20, 31)
        button.TextColor3 = selected and CONFIG.Neon or CONFIG.Muted
    end

    ContentTitle.Text = string.upper(tabName)
    ContentSubtitle.Text = "ZENVOLT SYSTEM / " .. string.upper(tabName)
    ClearPage()
    PageBuilders[tabName]()
    Page.CanvasPosition = Vector2.zero
end

-- Floating lightning toggle
local Floating = New("TextButton", {
    Name = "FloatingToggle",
    AutoButtonColor = false,
    Text = "⚡",
    Font = Enum.Font.GothamBlack,
    TextSize = 28,
    TextColor3 = CONFIG.Neon,
    BackgroundColor3 = Color3.fromRGB(12, 17, 29),
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0, 20, 0.5, -27),
    ZIndex = 50,
}, Screen)
Corner(Floating, 28)

local FloatingStroke = Stroke(Floating, CONFIG.Neon, 2, 0)
New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 50, 255)),
    }),
    Rotation = 45,
}, FloatingStroke)

-- Drag helpers: support mouse and touch.
local function MakeDraggable(handle, target, allowTouch)
    local dragging = false
    local dragStart
    local startPosition
    local activeInput
    local endConnection

    KeepConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or (allowTouch and input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            activeInput = input

            if endConnection then endConnection:Disconnect() end
            endConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeInput = nil
                    if endConnection then
                        endConnection:Disconnect()
                        endConnection = nil
                    end
                end
            end)
        end
    end))

    KeepConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local mouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
        local touchMove = input.UserInputType == Enum.UserInputType.Touch and activeInput ~= nil
        if mouseMove or touchMove then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end))
end

MakeDraggable(Header, Main, true)
MakeDraggable(Floating, Floating, true)

KeepConnection(Floating.Activated:Connect(function()
    Main.Visible = not Main.Visible
end))

KeepConnection(CloseButton.Activated:Connect(function()
    Main.Visible = false
end))

-- Responsive layout
local function ApplyResponsiveSize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.max(280, math.min(720, viewport.X - 24))
    local height = math.max(300, math.min(460, viewport.Y - 50))
    Main.Size = UDim2.fromOffset(width, height)

    local small = viewport.X < 550
    Sidebar.Size = UDim2.new(0, small and 105 or 145, 1, 0)
    Content.Position = UDim2.new(0, small and 115 or 155, 0, 0)
    Content.Size = UDim2.new(1, small and -125 or -165, 1, 0)

    for tabName, button in pairs(TabButtons) do
        local labels = {
            Home = "⌂    Home",
            Player = "◉    Player",
            Visuals = "◈    Visuals",
            ["Script Hub"] = "ϟ    Script Hub",
            Settings = "⚙    Settings",
        }
        button.Text = small and tabName or labels[tabName]
        button.TextSize = small and 10 or 12
    end
end

if workspace.CurrentCamera then
    KeepConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyResponsiveSize))
end

-- Thunder geometry
local ThunderRandom = Random.new()
local ThunderBusy = false

local function ThunderSegment(a, b, thickness, color, alpha, z)
    local delta = b - a
    local line = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
        Size = UDim2.fromOffset(delta.Magnitude + thickness, thickness),
        Rotation = math.deg(math.atan2(delta.Y, delta.X)),
        BackgroundColor3 = color,
        BackgroundTransparency = alpha,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = z,
    }, ThunderFX)
    return line, alpha
end

local function ThunderPoints(a, b, steps, jitter)
    local points = {a}
    for i = 1, steps - 1 do
        local point = a:Lerp(b, i / steps)
        point += Vector2.new(
            ThunderRandom:NextNumber(-jitter, jitter),
            ThunderRandom:NextNumber(-jitter, jitter)
        )
        table.insert(points, point)
    end
    table.insert(points, b)
    return points
end

local function ThunderBolt(a, b, steps, jitter, scale, parts)
    local points = ThunderPoints(a, b, steps, jitter)
    for i = 1, #points - 1 do
        local p1, p2 = points[i], points[i + 1]

        local glow, glowAlpha = ThunderSegment(
            p1, p2, 8 * scale,
            Color3.fromRGB(30, 190, 255), 0.68, 21
        )
        table.insert(parts, {Object = glow, Alpha = glowAlpha})

        local core, coreAlpha = ThunderSegment(
            p1, p2, 2.2 * scale,
            Color3.fromRGB(255, 255, 255), 0.04, 22
        )
        table.insert(parts, {Object = core, Alpha = coreAlpha})
    end
    return points
end

local function CreateThunder(big)
    if not Alive or not Main.Visible or ThunderBusy then return end
    local width = ThunderFX.AbsoluteSize.X
    local height = ThunderFX.AbsoluteSize.Y
    if width < 100 or height < 100 then return end

    ThunderBusy = true
    local parts = {}
    local boltCount = big and 2 or 1

    for _ = 1, boltCount do
        local startX = ThunderRandom:NextNumber(width * 0.12, width * 0.88)
        local startPoint = Vector2.new(startX, -5)
        local endPoint = Vector2.new(
            math.clamp(startX + ThunderRandom:NextNumber(-90, 90), 5, width - 5),
            ThunderRandom:NextNumber(height * 0.50, height - 5)
        )

        local points = ThunderBolt(startPoint, endPoint, ThunderRandom:NextInteger(7, 11), 23, 1, parts)
        local branchCount = ThunderRandom:NextInteger(1, 2)

        for _ = 1, branchCount do
            local index = ThunderRandom:NextInteger(2, math.max(2, #points - 2))
            local origin = points[index]
            local side = ThunderRandom:NextNumber() < 0.5 and -1 or 1
            local branchEnd = origin + Vector2.new(
                side * ThunderRandom:NextNumber(25, 75),
                ThunderRandom:NextNumber(20, 65)
            )
            ThunderBolt(origin, branchEnd, 3, 11, 0.55, parts)
        end
    end

    ThunderFlash.BackgroundTransparency = big and 0.84 or 0.93

    task.spawn(function()
        task.wait(0.055)

        for _, part in ipairs(parts) do
            if part.Object.Parent then
                part.Object.BackgroundTransparency = 1
            end
        end
        ThunderFlash.BackgroundTransparency = 1

        task.wait(0.065)

        if Alive and Main.Parent and Main.Visible then
            for _, part in ipairs(parts) do
                if part.Object.Parent then
                    part.Object.BackgroundTransparency = part.Alpha
                end
            end
            ThunderFlash.BackgroundTransparency = big and 0.88 or 0.95
            task.wait(0.055)
        end

        ThunderFlash.BackgroundTransparency = 1

        for _, part in ipairs(parts) do
            if part.Object.Parent then
                TweenService:Create(part.Object, TweenInfo.new(0.32), {
                    BackgroundTransparency = 1
                }):Play()
            end
        end

        task.wait(0.36)
        for _, part in ipairs(parts) do
            if part.Object.Parent then part.Object:Destroy() end
        end
        ThunderBusy = false
    end)
end

-- Main animation loop
KeepConnection(RunService.RenderStepped:Connect(function()
    if not Alive then return end

    Frames += 1
    local now = os.clock()
    if now - LastFPSUpdate >= 1 then
        FPS = math.floor(Frames / (now - LastFPSUpdate) + 0.5)
        Frames = 0
        LastFPSUpdate = now
    end

    if RGBEnabled then
        local color = Color3.fromHSV((now * CONFIG.RGBSpeed) % 1, 0.9, 1)
        MainStroke.Color = color
        FloatingStroke.Color = color
        Logo.TextColor3 = color
    else
        MainStroke.Color = CONFIG.Neon
        FloatingStroke.Color = CONFIG.Neon
        Logo.TextColor3 = CONFIG.Neon
    end

    MainGradient.Rotation = (now * 90) % 360

    if AnimationsEnabled then
        local pulse = 0.7 + math.sin(now * 5) * 0.2
        FloatingStroke.Transparency = 1 - pulse
    else
        FloatingStroke.Transparency = 0
    end
end))

-- Random lightning strikes; instances are cleaned up after each flash.
task.spawn(function()
    while Alive do
        task.wait(ThunderRandom:NextNumber(1.8, 3.8))
        if Alive and Main.Parent and Main.Visible then
            CreateThunder(ThunderRandom:NextNumber() < 0.22)
        end
    end
end)

local function Cleanup()
    if not Alive then return end
    Alive = false
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    if Screen.Parent then Screen:Destroy() end
end

KeepConnection(Screen.Destroying:Connect(function()
    Alive = false
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
end))

ApplyResponsiveSize()
SwitchTab("Home")
print("[ZENVOLT HUB] THUNDER EDITION LOADED ⚡")
