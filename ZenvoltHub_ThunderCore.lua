--[[
    ZENVOLT HUB // THUNDERCORE EDITION
    Standalone Roblox LocalScript UI
    Designed for Roblox Studio / your own experience.
    No external loader, no remote code execution, no exploit functions.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("ZenvoltThunderCore")
if old then old:Destroy() end

local C = {
    bg = Color3.fromRGB(7, 9, 17),
    panel = Color3.fromRGB(12, 16, 29),
    panel2 = Color3.fromRGB(17, 23, 40),
    panel3 = Color3.fromRGB(22, 31, 51),
    line = Color3.fromRGB(40, 55, 81),
    text = Color3.fromRGB(236, 244, 255),
    muted = Color3.fromRGB(130, 148, 176),
    cyan = Color3.fromRGB(54, 231, 255),
    blue = Color3.fromRGB(77, 119, 255),
    purple = Color3.fromRGB(166, 91, 255),
    green = Color3.fromRGB(70, 255, 174),
    red = Color3.fromRGB(255, 88, 120),
    yellow = Color3.fromRGB(255, 221, 92),
}

local gui = Instance.new("ScreenGui")
gui.Name = "ZenvoltThunderCore"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or C.line,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function gradient(parent, a, b, rotation)
    return make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(1, b)
        }),
        Rotation = rotation or 0
    }, parent)
end

local function tween(obj, duration, props, style, direction)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function label(parent, text, size, color, font, x, y, w, h)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C.text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.new(0, x or 0, 0, y or 0),
        Size = UDim2.new(0, w or 200, 0, h or 22),
        TextTruncate = Enum.TextTruncate.AtEnd
    }, parent)
end

local function addButtonFx(button, baseColor)
    button.AutoButtonColor = false
    local base = baseColor or C.panel3
    button.BackgroundColor3 = base
    button.MouseEnter:Connect(function()
        tween(button, 0.14, {BackgroundColor3 = C.panel3, BackgroundTransparency = 0})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.14, {BackgroundColor3 = base})
    end)
    button.MouseButton1Down:Connect(function()
        tween(button, 0.07, {Size = button.Size - UDim2.fromOffset(2, 2)})
    end)
    button.MouseButton1Up:Connect(function()
        tween(button, 0.12, {Size = button.Size + UDim2.fromOffset(2, 2)})
    end)
end

-- Background atmosphere
local background = make("Frame", {
    Name = "Atmosphere",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Parent = gui
})
gradient(background, Color3.fromRGB(8, 13, 28), Color3.fromRGB(20, 7, 34), 35)

local glowTop = make("Frame", {
    BackgroundColor3 = C.blue,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    Size = UDim2.new(0.7, 0, 0, 180),
    Position = UDim2.new(0.15, 0, -0.12, 0),
    Parent = background
})
corner(glowTop, 100)
local glowGrad = gradient(glowTop, C.cyan, C.purple, 0)

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 780, 0, 490),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = gui
})
corner(main, 16)
local mainStroke = stroke(main, C.cyan, 1.3, 0.08)
gradient(main, Color3.fromRGB(13, 19, 34), Color3.fromRGB(9, 11, 23), 135)

local scale = make("UIScale", {Scale = 1, Parent = main})
local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    local factor = math.min((v.X - 24) / 780, (v.Y - 24) / 490, 1)
    scale.Scale = math.clamp(factor, 0.58, 1)
end
updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Edge energy strip
local topLine = make("Frame", {
    Name = "EnergyLine",
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = C.cyan,
    BorderSizePixel = 0,
    Parent = main
})
gradient(topLine, C.cyan, C.purple, 0)

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = Color3.fromRGB(11, 16, 29),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Parent = main
})
local headerLine = make("Frame", {
    Position = UDim2.new(0, 18, 1, -1),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
    Parent = header
})

local logoWrap = make("Frame", {
    Position = UDim2.new(0, 20, 0, 13),
    Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = C.panel3,
    BorderSizePixel = 0,
    Parent = header
})
corner(logoWrap, 12)
local logoStroke = stroke(logoWrap, C.cyan, 1.2, 0.1)
gradient(logoWrap, Color3.fromRGB(21, 53, 77), Color3.fromRGB(43, 20, 76), 45)
label(logoWrap, "ϟ", 31, C.cyan, Enum.Font.GothamBlack, 0, -1, 42, 42).TextXAlignment = Enum.TextXAlignment.Center

label(header, "ZENVOLT", 20, C.text, Enum.Font.GothamBlack, 74, 10, 180, 26)
local sub = label(header, "T H U N D E R C O R E   /   U I   S Y S T E M", 8, C.muted, Enum.Font.GothamBold, 76, 36, 270, 16)

local livePill = make("Frame", {
    Position = UDim2.new(1, -202, 0, 22),
    Size = UDim2.fromOffset(83, 24),
    BackgroundColor3 = Color3.fromRGB(17, 43, 43),
    BorderSizePixel = 0,
    Parent = header
})
corner(livePill, 8)
local liveDot = make("Frame", {
    Position = UDim2.fromOffset(9, 9),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = C.green,
    BorderSizePixel = 0,
    Parent = livePill
})
corner(liveDot, 6)
label(livePill, "ONLINE", 9, C.green, Enum.Font.GothamBold, 22, 1, 55, 22)

local minimize = make("TextButton", {
    Position = UDim2.new(1, -104, 0, 19),
    Size = UDim2.fromOffset(30, 30),
    Text = "—",
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.muted,
    BackgroundColor3 = C.panel2,
    BorderSizePixel = 0,
    Parent = header
})
corner(minimize, 9)
local close = make("TextButton", {
    Position = UDim2.new(1, -65, 0, 19),
    Size = UDim2.fromOffset(30, 30),
    Text = "×",
    TextSize = 22,
    Font = Enum.Font.Gotham,
    TextColor3 = C.red,
    BackgroundColor3 = Color3.fromRGB(44, 22, 36),
    BorderSizePixel = 0,
    Parent = header
})
corner(close, 9)

-- Sidebar
local sidebar = make("Frame", {
    Position = UDim2.new(0, 14, 0, 82),
    Size = UDim2.new(0, 172, 1, -98),
    BackgroundColor3 = Color3.fromRGB(10, 14, 26),
    BorderSizePixel = 0,
    Parent = main
})
corner(sidebar, 13)
stroke(sidebar, C.line, 1, 0.35)
label(sidebar, "CONTROL CENTER", 9, C.muted, Enum.Font.GothamBold, 14, 12, 140, 18)

local navArea = make("Frame", {
    Position = UDim2.new(0, 8, 0, 39),
    Size = UDim2.new(1, -16, 0, 220),
    BackgroundTransparency = 1,
    Parent = sidebar
})
make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = navArea
})

local sideFooter = make("Frame", {
    Position = UDim2.new(0, 10, 1, -78),
    Size = UDim2.new(1, -20, 0, 64),
    BackgroundColor3 = C.panel2,
    BorderSizePixel = 0,
    Parent = sidebar
})
corner(sideFooter, 10)
stroke(sideFooter, C.line, 1, 0.45)
label(sideFooter, "BUILD", 8, C.muted, Enum.Font.GothamBold, 10, 7, 60, 13)
label(sideFooter, "THUNDERCORE", 11, C.cyan, Enum.Font.GothamBlack, 10, 22, 130, 17)
label(sideFooter, "v3.0  •  LOCAL UI", 8, C.muted, Enum.Font.Gotham, 10, 42, 130, 12)

-- Content shell
local content = make("Frame", {
    Position = UDim2.new(0, 200, 0, 82),
    Size = UDim2.new(1, -214, 1, -98),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = main
})

local pages = {}
local navButtons = {}
local currentPage = "Overview"
local floating -- forward declaration for callbacks created before the floating button
local toastLayer = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 50,
    Parent = gui
})

local function toast(titleText, bodyText, accent)
    local card = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 340, 0, 24),
        Size = UDim2.fromOffset(292, 72),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = toastLayer
    })
    corner(card, 12)
    stroke(card, accent or C.cyan, 1.2, 0.12).ZIndex = 52
    local stripe = make("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.new(0, 8, 0, 9),
        BackgroundColor3 = accent or C.cyan,
        BorderSizePixel = 0,
        ZIndex = 52,
        Parent = card
    })
    corner(stripe, 4)
    label(card, titleText, 12, C.text, Enum.Font.GothamBold, 20, 10, 250, 20).ZIndex = 52
    label(card, bodyText, 10, C.muted, Enum.Font.Gotham, 20, 34, 250, 23).ZIndex = 52
    tween(card, 0.35, {Position = UDim2.new(1, -18, 0, 24)}, Enum.EasingStyle.Back)
    task.delay(2.8, function()
        if card.Parent then
            tween(card, 0.25, {Position = UDim2.new(1, 340, 0, 24)})
            task.wait(0.3)
            card:Destroy()
        end
    end)
end

local function pageBase(name, titleText, subtitleText)
    local page = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.cyan,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = content
    })
    make("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    local head = make("Frame", {
        Size = UDim2.new(1, -4, 0, 57),
        BackgroundTransparency = 1,
        Parent = page,
        LayoutOrder = 1
    })
    label(head, titleText, 22, C.text, Enum.Font.GothamBlack, 1, 0, 400, 31)
    label(head, subtitleText, 10, C.muted, Enum.Font.Gotham, 2, 32, 430, 18)
    pages[name] = page
    return page
end

local function section(parent, titleText, hintText, height)
    local card = make("Frame", {
        Size = UDim2.new(1, -4, 0, height or 100),
        BackgroundColor3 = C.panel2,
        BorderSizePixel = 0,
        Parent = parent
    })
    corner(card, 12)
    stroke(card, C.line, 1, 0.35)
    label(card, titleText, 12, C.text, Enum.Font.GothamBold, 14, 10, 360, 20)
    if hintText then
        label(card, hintText, 9, C.muted, Enum.Font.Gotham, 14, 30, 420, 17)
    end
    return card
end

local function actionButton(parent, text, x, y, width, callback, accent)
    local b = make("TextButton", {
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.fromOffset(width, 30),
        Text = text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.text,
        BackgroundColor3 = C.panel3,
        BorderSizePixel = 0,
        Parent = parent
    })
    corner(b, 8)
    stroke(b, accent or C.line, 1, 0.2)
    addButtonFx(b, C.panel3)
    b.Activated:Connect(function()
        if callback then callback() end
    end)
    return b
end

local function statCard(parent, titleText, valueText, iconText, x, width)
    local card = make("Frame", {
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, width, 0, 76),
        BackgroundColor3 = C.panel2,
        BorderSizePixel = 0,
        Parent = parent
    })
    corner(card, 11)
    stroke(card, C.line, 1, 0.38)
    label(card, iconText, 17, C.cyan, Enum.Font.GothamBlack, 12, 10, 28, 24)
    label(card, titleText, 9, C.muted, Enum.Font.GothamBold, 43, 10, width - 52, 18)
    label(card, valueText, 16, C.text, Enum.Font.GothamBlack, 43, 30, width - 52, 28)
    return card
end

-- Overview
local overview = pageBase("Overview", "Command overview", "Your local control deck. Clean, fast, and ready.")
local hero = make("Frame", {
    Size = UDim2.new(1, -4, 0, 128),
    BackgroundColor3 = Color3.fromRGB(14, 27, 48),
    BorderSizePixel = 0,
    Parent = overview,
    LayoutOrder = 2
})
corner(hero, 14)
stroke(hero, C.cyan, 1, 0.25)
gradient(hero, Color3.fromRGB(17, 48, 69), Color3.fromRGB(35, 19, 64), 12)
label(hero, "THUNDERCORE // ACTIVE", 9, C.cyan, Enum.Font.GothamBlack, 17, 13, 240, 18)
label(hero, "Own the storm.", 25, C.text, Enum.Font.GothamBlack, 16, 34, 350, 34)
label(hero, "Zenvolt interface system • local client panel", 10, C.muted, Enum.Font.Gotham, 18, 73, 390, 20)
actionButton(hero, "SYSTEM STATUS  ↗", 17, 94, 126, function()
    toast("SYSTEM ONLINE", "Interface systems are responding.", C.green)
end, C.cyan)

local statRow = make("Frame", {
    Size = UDim2.new(1, -4, 0, 76),
    BackgroundTransparency = 1,
    Parent = overview,
    LayoutOrder = 3
})
local cardWidth = math.floor((content.AbsoluteSize.X - 12) / 3)
statCard(statRow, "PLAYERS", tostring(#Players:GetPlayers()), "◎", 0, 145)
statCard(statRow, "FPS", "--", "ϟ", 154, 145)
statCard(statRow, "PING", "--", "⌁", 308, 145)

local quick = section(overview, "Quick actions", "Small utilities for your own experience.", 98)
quick.LayoutOrder = 4
actionButton(quick, "REFRESH INFO", 14, 55, 112, function()
    toast("REFRESHED", "Player information updated.", C.cyan)
end, C.cyan)
actionButton(quick, "TOGGLE FX", 135, 55, 100, function()
    background.Visible = not background.Visible
    toast("ATMOSPHERE", background.Visible and "Background FX enabled." or "Background FX hidden.", C.purple)
end, C.purple)
actionButton(quick, "HIDE PANEL", 244, 55, 100, function()
    main.Visible = false
    floating.Visible = true
end, C.line)

-- Player page
local playerPage = pageBase("Player", "Player profile", "Client-side information and interface preferences.")
local profile = section(playerPage, "Current player", "Information is read locally from your client.", 142)
profile.LayoutOrder = 2
local avatar = make("ImageLabel", {
    Position = UDim2.new(0, 15, 0, 52),
    Size = UDim2.fromOffset(60, 60),
    BackgroundColor3 = C.panel3,
    BorderSizePixel = 0,
    Image = "",
    Parent = profile
})
corner(avatar, 12)
task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and avatar.Parent then avatar.Image = image end
end)
label(profile, LocalPlayer.DisplayName, 14, C.text, Enum.Font.GothamBold, 88, 54, 250, 22)
label(profile, "@" .. LocalPlayer.Name, 10, C.muted, Enum.Font.Gotham, 88, 77, 250, 18)
label(profile, "USER ID  " .. tostring(LocalPlayer.UserId), 9, C.cyan, Enum.Font.GothamBold, 88, 99, 240, 17)
actionButton(profile, "COPY USER ID", 88, 117, 112, function()
    toast("USER ID", tostring(LocalPlayer.UserId), C.cyan)
end)

local session = section(playerPage, "Session details", "Live values from the current client session.", 120)
session.LayoutOrder = 3
label(session, "Place ID", 10, C.muted, Enum.Font.Gotham, 15, 52, 80, 18)
label(session, tostring(game.PlaceId), 11, C.text, Enum.Font.GothamBold, 100, 52, 270, 18)
label(session, "Players in server", 10, C.muted, Enum.Font.Gotham, 15, 77, 120, 18)
local playerCount = label(session, tostring(#Players:GetPlayers()), 11, C.text, Enum.Font.GothamBold, 140, 77, 80, 18)
actionButton(session, "COPY PLACE ID", 15, 89, 118, function()
    toast("PLACE ID", tostring(game.PlaceId), C.cyan)
end)

-- Visuals page
local visuals = pageBase("Visuals", "Visual laboratory", "Tune the interface atmosphere without heavy scene effects.")
local fxCard = section(visuals, "Thunder effects", "Lightweight UI-only effects.", 132)
fxCard.LayoutOrder = 2

local function toggleRow(parent, titleText, descText, y, initial, callback)
    label(parent, titleText, 11, C.text, Enum.Font.GothamBold, 14, y, 230, 18)
    label(parent, descText, 9, C.muted, Enum.Font.Gotham, 14, y + 18, 260, 16)
    local toggle = make("TextButton", {
        Position = UDim2.new(1, -62, 0, y + 4),
        Size = UDim2.fromOffset(46, 23),
        BackgroundColor3 = initial and C.cyan or C.panel3,
        Text = "",
        BorderSizePixel = 0,
        Parent = parent
    })
    corner(toggle, 12)
    local knob = make("Frame", {
        Position = initial and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 0, 3),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = C.text,
        BorderSizePixel = 0,
        Parent = toggle
    })
    corner(knob, 12)
    local enabled = initial
    toggle.Activated:Connect(function()
        enabled = not enabled
        tween(toggle, 0.18, {BackgroundColor3 = enabled and C.cyan or C.panel3})
        tween(knob, 0.18, {Position = enabled and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 0, 3)})
        if callback then callback(enabled) end
    end)
    return function() return enabled end
end

local lightningEnabled = true
toggleRow(fxCard, "Lightning streaks", "Animated electric lines around the panel.", 51, true, function(v)
    lightningEnabled = v
end)
local rgbEnabled = true
toggleRow(fxCard, "RGB edge pulse", "Slow cyan / violet energy shift.", 92, true, function(v)
    rgbEnabled = v
end)

local colorCard = section(visuals, "Accent profile", "Select the hub's primary energy color.", 104)
colorCard.LayoutOrder = 3
local function setAccent(col, name)
    C.cyan = col
    mainStroke.Color = col
    logoStroke.Color = col
    topLine.BackgroundColor3 = col
    toast("ACCENT CHANGED", name .. " profile selected.", col)
end
actionButton(colorCard, "CYAN", 14, 57, 76, function() setAccent(Color3.fromRGB(54, 231, 255), "Cyan") end, C.cyan)
actionButton(colorCard, "VIOLET", 98, 57, 76, function() setAccent(Color3.fromRGB(177, 100, 255), "Violet") end, C.purple)
actionButton(colorCard, "ICE BLUE", 182, 57, 76, function() setAccent(Color3.fromRGB(102, 170, 255), "Ice blue") end, C.blue)

-- Script hub page: safe local registry, no arbitrary execution
local scriptsPage = pageBase("ScriptHub", "Script library", "A clean registry for tools you create or trust.")
local registry = section(scriptsPage, "Local script registry", "This panel does not download or execute unknown code.", 124)
registry.LayoutOrder = 2
label(registry, "Add your own approved modules here.", 10, C.text, Enum.Font.Gotham, 14, 54, 350, 18)
label(registry, "Use ModuleScripts in your own Roblox experience.", 9, C.muted, Enum.Font.Gotham, 14, 74, 350, 18)
actionButton(registry, "VIEW GUIDANCE", 14, 91, 120, function()
    toast("SCRIPT SAFETY", "Review source code before using it.", C.yellow)
end, C.yellow)

local modules = section(scriptsPage, "Suggested project modules", "Example ideas for your own game.", 132)
modules.LayoutOrder = 3
local moduleNames = {"Settings manager", "Player data panel", "Ability cooldown UI"}
for i, name in ipairs(moduleNames) do
    local y = 50 + (i - 1) * 25
    local dot = make("Frame", {
        Position = UDim2.new(0, 15, 0, y + 5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = (i == 1 and C.cyan or (i == 2 and C.purple or C.green)),
        BorderSizePixel = 0,
        Parent = modules
    })
    corner(dot, 6)
    label(modules, name, 10, C.text, Enum.Font.Gotham, 30, y, 260, 17)
    label(modules, "READY TO BUILD", 8, C.muted, Enum.Font.GothamBold, 270, y, 100, 17)
end

-- Settings page
local settingsPage = pageBase("Settings", "System settings", "Manage panel behavior and visual preferences.")
local behavior = section(settingsPage, "Interface behavior", "Changes apply immediately.", 132)
behavior.LayoutOrder = 2
local soundsEnabled = true
toggleRow(behavior, "Interface notifications", "Show small status toast messages.", 51, true, function(v)
    soundsEnabled = v
    toast("NOTIFICATIONS", v and "Notifications enabled." or "Notifications disabled.", C.cyan)
end)
local compact = false
toggleRow(behavior, "Compact layout", "Reduce spacing in the panel.", 92, false, function(v)
    compact = v
    toast("LAYOUT", v and "Compact mode selected." or "Standard mode selected.", C.purple)
end)

local resetCard = section(settingsPage, "Reset controls", "Return the interface to its default state.", 90)
resetCard.LayoutOrder = 3
actionButton(resetCard, "RESET UI", 14, 51, 100, function()
    lightningEnabled = true
    rgbEnabled = true
    background.Visible = true
    main.Visible = true
    floating.Visible = false
    toast("RESET COMPLETE", "Default interface restored.", C.green)
end, C.red)

-- Nav buttons
local navItems = {
    {name = "Overview", icon = "⌂", title = "Overview"},
    {name = "Player", icon = "◎", title = "Player"},
    {name = "Visuals", icon = "ϟ", title = "Visuals"},
    {name = "ScriptHub", icon = "▤", title = "Script Hub"},
    {name = "Settings", icon = "⚙", title = "Settings"},
}
local function showPage(name)
    currentPage = name
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end
    for pageName, b in pairs(navButtons) do
        local active = pageName == name
        b.BackgroundColor3 = active and Color3.fromRGB(20, 43, 61) or Color3.fromRGB(10, 14, 26)
        b.TextColor3 = active and C.cyan or C.muted
        local s = b:FindFirstChildOfClass("UIStroke")
        if s then
            s.Color = active and C.cyan or C.line
            s.Transparency = active and 0.18 or 0.85
        end
    end
end

for i, item in ipairs(navItems) do
    local b = make("TextButton", {
        Name = item.name,
        Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = Color3.fromRGB(10, 14, 26),
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = i,
        Parent = navArea
    })
    corner(b, 9)
    stroke(b, C.line, 1, 0.85)
    label(b, item.icon, 16, C.muted, Enum.Font.GothamBlack, 10, 2, 24, 31)
    label(b, item.title, 10, C.muted, Enum.Font.GothamBold, 39, 2, 100, 31)
    b.Activated:Connect(function()
        showPage(item.name)
        if soundsEnabled then toast("NAVIGATION", "Opened " .. item.title .. ".", C.cyan) end
    end)
    navButtons[item.name] = b
end
showPage("Overview")

-- Floating reopen button
floating = make("TextButton", {
    Name = "FloatingToggle",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -18, 0.5, 0),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = C.panel,
    Text = "ϟ",
    TextSize = 30,
    Font = Enum.Font.GothamBlack,
    TextColor3 = C.cyan,
    BorderSizePixel = 0,
    Visible = false,
    Parent = gui
})
corner(floating, 18)
stroke(floating, C.cyan, 1.5, 0.05)
gradient(floating, Color3.fromRGB(18, 47, 67), Color3.fromRGB(40, 18, 63), 45)
floating.Activated:Connect(function()
    main.Visible = true
    floating.Visible = false
    toast("ZENVOLT", "Thundercore interface restored.", C.cyan)
end)

minimize.Activated:Connect(function()
    main.Visible = false
    floating.Visible = true
end)
close.Activated:Connect(function()
    gui:Destroy()
end)

-- Drag window by the header
do
    local dragging = false
    local dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Decorative lightning paths, kept in a clipped layer around the top/right edge.
local lightningLayer = make("Frame", {
    Name = "LightningLayer",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ClipsDescendants = true,
    ZIndex = 10,
    Parent = main
})
local bolts = {}
local function makeBolt()
    local group = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(math.random(18, 92) / 100, 0, 0, math.random(5, 70)),
        Size = UDim2.fromOffset(math.random(30, 95), math.random(18, 46)),
        ZIndex = 10,
        Parent = lightningLayer
    })
    local points = {
        Vector2.new(0, math.random(2, 12)),
        Vector2.new(0.25, math.random(0, 20)),
        Vector2.new(0.48, math.random(8, 28)),
        Vector2.new(0.68, math.random(0, 20)),
        Vector2.new(1, math.random(6, 30))
    }
    for i = 1, #points - 1 do
        local a = points[i]
        local b = points[i + 1]
        local ax, ay = a.X * group.Size.X.Offset, a.Y
        local bx, by = b.X * group.Size.X.Offset, b.Y
        local dx, dy = bx - ax, by - ay
        local line = make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(ax, ay),
            Size = UDim2.fromOffset(math.sqrt(dx*dx + dy*dy), 2),
            Rotation = math.deg(math.atan2(dy, dx)),
            BackgroundColor3 = C.cyan,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.05,
            ZIndex = 10,
            Parent = group
        })
        line.BackgroundColor3 = (i % 2 == 0) and C.purple or C.cyan
        make("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.25)
            }),
            Parent = line
        })
    end
    group.Visible = false
    table.insert(bolts, group)
    return group
end
for i = 1, 8 do makeBolt() end

-- Soft shimmer on the top line
local phase = 0
local fpsFrames, fpsTime = 0, os.clock()
local lastFps = 0
RunService.RenderStepped:Connect(function(dt)
    if not gui.Parent then return end
    phase += dt
    fpsFrames += 1
    if os.clock() - fpsTime >= 1 then
        lastFps = fpsFrames
        fpsFrames = 0
        fpsTime = os.clock()
    end
    if rgbEnabled then
        local hue = (phase * 0.08) % 1
        local col = Color3.fromHSV(hue * 0.45 + 0.48, 0.72, 1)
        mainStroke.Color = col
        topLine.BackgroundColor3 = col
        logoStroke.Color = col
    end
    if overview and overview.Parent then
        local row = statRow
        if row and row.Parent then
            local fpsLabel = row:FindFirstChild("FPS")
            -- The labels are nested in cards; find the value by its text and update safely below.
            for _, descendant in ipairs(row:GetDescendants()) do
                if descendant:IsA("TextLabel") and descendant.Text == "--" then
                    descendant.Text = tostring(lastFps)
                    break
                end
            end
        end
    end
    for i, bolt in ipairs(bolts) do
        if lightningEnabled and main.Visible then
            if math.random() < 0.018 then
                bolt.Visible = true
                bolt.Position = UDim2.new(math.random(20, 94) / 100, 0, 0, math.random(5, 78))
                for _, line in ipairs(bolt:GetChildren()) do
                    if line:IsA("Frame") then
                        line.BackgroundColor3 = (math.random() > 0.5) and C.cyan or C.purple
                    end
                end
                task.delay(math.random(5, 12) / 100, function()
                    if bolt.Parent then bolt.Visible = false end
                end)
            end
        else
            bolt.Visible = false
        end
    end
end)

Players.PlayerAdded:Connect(function()
    if playerCount and playerCount.Parent then
        playerCount.Text = tostring(#Players:GetPlayers())
    end
end)
Players.PlayerRemoving:Connect(function()
    task.defer(function()
        if playerCount and playerCount.Parent then
            playerCount.Text = tostring(#Players:GetPlayers())
        end
    end)
end)

-- Keep the initial reveal cinematic but quick.
main.Position = UDim2.fromScale(0.5, 0.53)
main.BackgroundTransparency = 1
tween(main, 0.35, {Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0}, Enum.EasingStyle.Back)
toast("ZENVOLT HUB", "Thundercore edition initialized.", C.cyan)
