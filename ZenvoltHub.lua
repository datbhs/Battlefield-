--[[
    Zenvolt Hub  |  Thunder GUI cho Roblox (Luau)
    ------------------------------------------------------------------
    - Cửa sổ kéo thả bằng thanh tiêu đề (chuột + cảm ứng), tự kẹp trong màn hình
    - Nút nổi: chạm để mở/đóng, giữ và kéo để dời chỗ. PC: phím RightShift
    - Viền điện chạy vòng, tia sét ngẫu nhiên, flash + rung khi triệu hồi sét
    - Mini UI-lib: Tab, Section, Label, Button, Toggle, Slider, Dropdown, Textbox, Notify
    - Chạy lại script sẽ tự dọn bản cũ

    Thêm tab của bạn: tìm dòng ">>> THÊM TAB CỦA BẠN" gần cuối file.
]]

-- ==================== SERVICES ====================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")
local Stats              = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

-- Chạy lại script thì dọn bản cũ trước
local env = (getgenv and getgenv()) or _G
if env.ZenvoltHub and env.ZenvoltHub.Destroy then
    pcall(env.ZenvoltHub.Destroy)
end

-- ==================== THEME ====================
local Config = {
    Version   = "v1.0",
    ToggleKey = Enum.KeyCode.RightShift,
}

local Themes = {
    Thunder = { Color3.fromRGB(255, 214, 10), Color3.fromRGB(140, 92, 255) }, -- vàng sét + tím điện
    Storm   = { Color3.fromRGB(0, 208, 255),  Color3.fromRGB(64, 112, 255) }, -- xanh bão
    Plasma  = { Color3.fromRGB(255, 72, 196), Color3.fromRGB(128, 84, 255) }, -- hồng plasma
}

local C = {
    Bg      = Color3.fromRGB(9, 10, 26),    -- xanh mực (đáy cửa sổ)
    Bg2     = Color3.fromRGB(27, 20, 62),   -- tím bão (đỉnh cửa sổ)
    Card    = Color3.fromRGB(28, 27, 52),
    CardHi  = Color3.fromRGB(44, 42, 78),
    Text    = Color3.fromRGB(238, 238, 250),
    Sub     = Color3.fromRGB(150, 150, 186),
    White   = Color3.fromRGB(255, 255, 255),
    Accent  = Themes.Thunder[1],
    Accent2 = Themes.Thunder[2],
}

local BOLT = "\u{26A1}"

-- Mỗi thành phần đăng ký 1 hàm tô màu, đổi theme thì gọi lại tất cả
local themeListeners = {}

local function onTheme(fn)
    themeListeners[#themeListeners + 1] = fn
    fn()
end

local function setTheme(name)
    local t = Themes[name]
    if not t then return end
    C.Accent, C.Accent2 = t[1], t[2]
    for _, fn in ipairs(themeListeners) do
        pcall(fn)
    end
end

-- Dải màu "tia điện chạy quanh viền": nền tím, một vệt sáng vàng
local function arcSequence()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,    C.Accent2),
        ColorSequenceKeypoint.new(0.35, C.Accent2),
        ColorSequenceKeypoint.new(0.5,  C.Accent),
        ColorSequenceKeypoint.new(0.65, C.Accent2),
        ColorSequenceKeypoint.new(1,    C.Accent2),
    })
end

-- ==================== HELPERS ====================
local rng         = Random.new()
local alive       = true
local connections = {} -- chỉ lưu kết nối tới service (instance bị Destroy sẽ tự ngắt)
local Hub         = {}
env.ZenvoltHub    = Hub

local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    inst.Parent = parent
    return inst
end

local function tween(inst, time, goal, style, dir)
    local info = TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end

local function loopTween(inst, time, goal, style, reverses)
    local info = TweenInfo.new(time, style, Enum.EasingDirection.InOut, -1, reverses == true)
    TweenService:Create(inst, info, goal):Play()
end

local function corner(parent, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function label(parent, props)
    local p = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.fromScale(1, 1),
    }
    for k, v in pairs(props) do
        p[k] = v
    end
    return new("TextLabel", p, parent)
end

-- ==================== GUI GỐC ====================
local gui = new("ScreenGui", {
    Name = "ZenvoltHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)

do -- thử gethui -> CoreGui -> PlayerGui
    local mounts = {}
    if gethui then mounts[#mounts + 1] = gethui end
    mounts[#mounts + 1] = function() return CoreGui end
    mounts[#mounts + 1] = function() return LocalPlayer:WaitForChild("PlayerGui") end
    for _, getParent in ipairs(mounts) do
        local ok = pcall(function() gui.Parent = getParent() end)
        if ok and gui.Parent then break end
    end
end

function Hub.Destroy()
    if not alive then return end
    alive = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    gui:Destroy()
    if env.ZenvoltHub == Hub then env.ZenvoltHub = nil end
end

-- Kích thước cửa sổ co theo màn hình (điện thoại nằm ngang ~ 640x360)
local camera    = workspace.CurrentCamera
local viewport  = camera and camera.ViewportSize or Vector2.new(800, 600)
local W         = math.clamp(viewport.X - 40, 300, 540)
local H         = math.clamp(viewport.Y - 40, 220, 330)
local SIDEBAR_W = (W < 460) and 104 or 134
local TITLE_H   = 44

-- ==================== THÔNG BÁO ====================
local NotifyHolder = new("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(250, 400),
    BackgroundTransparency = 1,
    ZIndex = 50,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
}, NotifyHolder)

local function Notify(title, text, duration)
    if not alive then return end
    local wrap = new("Frame", { Size = UDim2.fromOffset(240, 60), BackgroundTransparency = 1 }, NotifyHolder)
    local toast = new("Frame", {
        Position = UDim2.fromOffset(270, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.Bg2,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
    }, wrap)
    corner(toast, 10)
    stroke(toast, C.Accent, 1.5, 0.25)
    local bar = new("Frame", {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(0, 3, 1, -16),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
    }, toast)
    corner(bar, 2)
    label(toast, {
        Text = title, Font = Enum.Font.GothamBold, TextColor3 = C.Accent,
        Position = UDim2.fromOffset(20, 7), Size = UDim2.new(1, -28, 0, 16),
    })
    label(toast, {
        Text = text, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(20, 24), Size = UDim2.new(1, -28, 0, 30),
    })
    tween(toast, 0.35, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
    task.delay(duration or 3, function()
        if not wrap.Parent then return end
        local t = tween(toast, 0.28, { Position = UDim2.fromOffset(270, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Wait()
        wrap:Destroy()
    end)
end

-- Gọi callback an toàn: lỗi của người dùng không làm sập GUI
local function safe(cb, ...)
    if type(cb) ~= "function" then return end
    local ok, err = pcall(cb, ...)
    if not ok then
        Notify("Callback error", tostring(err), 4)
    end
end

-- ==================== CỬA SỔ CHÍNH ====================
local Root = new("Frame", {
    Name = "Root",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(W, H),
    BackgroundTransparency = 1,
    Visible = false,
}, gui)
local RootScale = new("UIScale", {}, Root)

-- Quầng sáng phía sau
local Glow = new("Frame", {
    Name = "Glow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 4, 1, 4),
    BackgroundTransparency = 1,
    ZIndex = 1,
}, Root)
corner(Glow, 16)
local glowStroke = stroke(Glow, C.Accent2, 6, 0.84)
onTheme(function() glowStroke.Color = C.Accent2 end)

local Main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.White, -- màu thật do UIGradient bên dưới quyết định
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true, -- chặn chạm xuyên xuống game
    ZIndex = 2,
}, Root)
corner(Main, 12)
local bgGrad = new("UIGradient", { Rotation = 90 }, Main)
onTheme(function() bgGrad.Color = ColorSequence.new(C.Bg2, C.Bg) end)

-- Viền điện: vệt sáng chạy vòng quanh cửa sổ (điểm nhấn chính của giao diện)
local borderStroke = stroke(Main, C.White, 2, 0)
local borderGrad = new("UIGradient", {}, borderStroke)
onTheme(function() borderGrad.Color = arcSequence() end)
loopTween(borderGrad, 3, { Rotation = 360 }, Enum.EasingStyle.Linear, false)

-- Lớp tia sét nằm sau nội dung, lớp flash nằm trên cùng
local FX = new("Frame", {
    Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1,
}, Main)

local Flash = new("Frame", {
    Name = "Flash",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.Accent,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 10,
}, Main)
corner(Flash, 12)
onTheme(function() Flash.BackgroundColor3 = C.Accent end)

-- ==================== TIA SÉT ====================
local baseScale, fxEnabled, fxDelay = 1, true, 3.9
local isOpen, minimized = false, false

-- Mỗi đoạn tia là 1 Frame mảnh, xoay theo góc giữa 2 điểm
local function addSegment(a, b, thickness, color, transparency)
    local d = b - a
    return new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
        Size = UDim2.fromOffset(d.Magnitude + thickness, thickness),
        Rotation = math.deg(math.atan2(d.Y, d.X)),
        BackgroundColor3 = color,
        BackgroundTransparency = transparency,
        BorderSizePixel = 0,
    }, FX)
end

local function zigzag(a, b, steps, jitter)
    local pts = { a }
    for i = 1, steps - 1 do
        local p = a:Lerp(b, i / steps)
        pts[#pts + 1] = p + Vector2.new(
            rng:NextNumber(-jitter, jitter),
            rng:NextNumber(-jitter, jitter) * 0.35
        )
    end
    pts[#pts + 1] = b
    return pts
end

local function shake()
    task.spawn(function()
        for _ = 1, 6 do
            if not alive then return end
            Main.Position = UDim2.fromOffset(rng:NextInteger(-3, 3), rng:NextInteger(-3, 3))
            task.wait(0.03)
        end
        Main.Position = UDim2.fromOffset(0, 0)
    end)
end

local function strike(big)
    if not alive or not isOpen or minimized then return end

    local parts = {} -- { frame, độ trong suốt gốc }
    local function seg(a, b, thickness, color, transparency)
        parts[#parts + 1] = { addSegment(a, b, thickness, color, transparency), transparency }
    end
    local function bolt(from, to, steps, jitter, scale)
        local pts = zigzag(from, to, steps, jitter)
        for i = 1, #pts - 1 do
            seg(pts[i], pts[i + 1], 7 * scale, C.Accent, 0.65)   -- vầng sáng
            seg(pts[i], pts[i + 1], 2.2 * scale, C.White, 0.05)  -- lõi trắng
        end
        return pts
    end

    for _ = 1, big and 3 or 1 do
        local x = rng:NextNumber(0.1, 0.9) * W
        local from = Vector2.new(x, -8)
        local to = Vector2.new(x + rng:NextNumber(-70, 70), rng:NextNumber(0.5, 1) * H)
        local pts = bolt(from, to, rng:NextInteger(7, 11), 24, 1)
        for _ = 1, rng:NextInteger(1, 2) do -- nhánh rẽ
            local p = pts[rng:NextInteger(2, #pts - 2)]
            local side = (rng:NextNumber() < 0.5) and -1 or 1
            bolt(p, p + Vector2.new(side * rng:NextNumber(30, 80), rng:NextNumber(30, 70)), 3, 12, 0.6)
        end
    end

    local function setVisible(show)
        for _, p in ipairs(parts) do
            p[1].BackgroundTransparency = show and p[2] or 1
        end
    end

    -- Chớp 2 nhịp rồi tắt dần, giống sét thật
    Flash.BackgroundTransparency = big and 0.75 or 0.9
    task.spawn(function()
        task.wait(0.07)
        setVisible(false)
        Flash.BackgroundTransparency = 1
        task.wait(0.06)
        setVisible(true)
        Flash.BackgroundTransparency = big and 0.82 or 0.93
        task.wait(0.06)
        for _, p in ipairs(parts) do
            tween(p[1], 0.35, { BackgroundTransparency = 1 })
        end
        tween(Flash, 0.35, { BackgroundTransparency = 1 })
        task.wait(0.4)
        for _, p in ipairs(parts) do
            p[1]:Destroy()
        end
    end)

    if big then shake() end
end

-- ==================== MỞ / ĐÓNG / THU NHỎ ====================
local function setOpen(state)
    if state == isOpen then return end
    isOpen = state
    if state then
        Root.Visible = true
        RootScale.Scale = baseScale * 0.65
        tween(RootScale, 0.4, { Scale = baseScale }, Enum.EasingStyle.Back)
        Flash.BackgroundTransparency = 0.6
        tween(Flash, 0.6, { BackgroundTransparency = 1 })
        task.delay(0.12, strike, false)
    else
        tween(RootScale, 0.2, { Scale = baseScale * 0.65 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function()
            if not isOpen then Root.Visible = false end
        end)
    end
end

-- Thu nhỏ còn thanh tiêu đề; dời tâm để thanh tiêu đề đứng yên
local function setMinimized(state)
    if state == minimized then return end
    minimized = state
    local p = Root.Position
    local shift = (H - TITLE_H) * 0.5 * RootScale.Scale * (state and -1 or 1)
    tween(Root, 0.25, {
        Size = UDim2.fromOffset(W, state and TITLE_H or H),
        Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + shift),
    }, Enum.EasingStyle.Quint)
end

-- ==================== KÉO THẢ ====================
-- handle: vùng nắm kéo | target: thứ được di chuyển | onTap: gọi khi chạm mà không kéo
local function makeDraggable(handle, target, onTap)
    local dragging, moved = false, false
    local startInput, startPointer, startPos

    handle.InputBegan:Connect(function(input)
        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
        dragging, moved = true, false
        startInput, startPointer, startPos = input, input.Position, target.Position
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
                dragging = false
                if not moved and onTap then onTap() end
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= startInput then return end
        local delta = input.Position - startPointer
        if not moved and delta.Magnitude < 6 then return end -- ngưỡng phân biệt chạm và kéo
        moved = true

        -- Đổi sang pixel rồi kẹp trong màn hình
        local screen = target.Parent.AbsoluteSize
        local size, anchor = target.AbsoluteSize, target.AnchorPoint
        local x = startPos.X.Scale * screen.X + startPos.X.Offset + delta.X
        local y = startPos.Y.Scale * screen.Y + startPos.Y.Offset + delta.Y
        local minX, minY = size.X * anchor.X, size.Y * anchor.Y
        x = math.clamp(x, minX, math.max(minX, screen.X - size.X * (1 - anchor.X)))
        y = math.clamp(y, minY, math.max(minY, screen.Y - size.Y * (1 - anchor.Y)))
        target.Position = UDim2.fromOffset(x, y)
    end)
end

-- ==================== THANH TIÊU ĐỀ ====================
local Title = new("Frame", {
    Name = "Title",
    Size = UDim2.new(1, 0, 0, TITLE_H),
    BackgroundTransparency = 1,
    Active = true,
    ZIndex = 2,
}, Main)

label(Title, {
    Text = BOLT, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center,
    Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(34, TITLE_H),
})

local titleText = label(Title, {
    Text = "Zenvolt Hub", Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = C.White,
    Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -130, 1, 0),
})
local titleGrad = new("UIGradient", {}, titleText)
onTheme(function()
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    C.Accent),
        ColorSequenceKeypoint.new(0.55, C.White),
        ColorSequenceKeypoint.new(1,    C.Accent2),
    })
end)

local titleLine = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, 0),
    Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
}, Title)
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, titleLine)
onTheme(function() titleLine.BackgroundColor3 = C.Accent end)

-- Nút "thu nhỏ" và "đóng" vẽ bằng Frame nên không phụ thuộc font
local function iconButton(rightOffset, kind, onClick)
    local b = new("TextButton", {
        Text = "", AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, rightOffset, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = C.Card, BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }, Title)
    corner(b, 8)
    local function line(rotation, width)
        new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(width, 2), Rotation = rotation,
            BackgroundColor3 = C.Text, BorderSizePixel = 0,
        }, b)
    end
    if kind == "min" then
        line(0, 12)
    else
        line(45, 14)
        line(-45, 14)
    end
    local hover = (kind == "close") and Color3.fromRGB(232, 64, 84) or C.CardHi
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = hover, BackgroundTransparency = 0 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.Card, BackgroundTransparency = 0.35 }) end)
    b.MouseButton1Click:Connect(onClick)
    return b
end

iconButton(-10, "close", function() setOpen(false) end)
iconButton(-44, "min", function() setMinimized(not minimized) end)
makeDraggable(Title, Root)

-- ==================== SIDEBAR + PAGES ====================
local Sidebar = new("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(0, TITLE_H),
    Size = UDim2.new(0, SIDEBAR_W, 1, -TITLE_H),
    BackgroundTransparency = 1,
    ZIndex = 2,
}, Main)
local TabList = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -26),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Sidebar)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, TabList)
new("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, TabList)
label(Sidebar, {
    Text = Config.Version, TextSize = 11, TextColor3 = C.Sub,
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -8), Size = UDim2.new(1, -16, 0, 14),
})

local sideLine = new("Frame", {
    Position = UDim2.new(0, SIDEBAR_W, 0, TITLE_H + 10),
    Size = UDim2.new(0, 1, 1, -(TITLE_H + 20)),
    BackgroundColor3 = C.Accent2,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 2,
}, Main)
onTheme(function() sideLine.BackgroundColor3 = C.Accent2 end)

local Pages = new("Frame", {
    Name = "Pages",
    Position = UDim2.fromOffset(SIDEBAR_W + 1, TITLE_H),
    Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -TITLE_H),
    BackgroundTransparency = 1,
    ZIndex = 2,
}, Main)

-- ==================== TAB + COMPONENT ====================
local Tabs, ActiveTab = {}, nil

local function selectTab(tab)
    if ActiveTab == tab then return end
    if ActiveTab then
        ActiveTab.Page.Visible = false
        ActiveTab.SetActive(false)
    end
    ActiveTab = tab
    tab.Page.Visible = true
    tab.SetActive(true)
end

function Hub:AddTab(name)
    local tab, order, active = { Name = name }, 0, false

    local button = new("TextButton", {
        Name = name, Text = "", AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.Accent2, BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = #Tabs + 1,
    }, TabList)
    corner(button, 8)
    local marker = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(3, 16), BackgroundColor3 = C.Accent, BackgroundTransparency = 1, BorderSizePixel = 0,
    }, button)
    corner(marker, 2)
    local text = label(button, {
        Text = name, Font = Enum.Font.GothamBold, TextColor3 = C.Sub,
        Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -16, 1, 0),
    })

    local page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, Pages)
    new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
    }, page)

    function tab.SetActive(on)
        active = on
        tween(button, 0.18, { BackgroundTransparency = on and 0.72 or 1 })
        tween(marker, 0.18, { BackgroundTransparency = on and 0 or 1 })
        tween(text, 0.18, { TextColor3 = on and C.Accent or C.Sub })
    end
    onTheme(function()
        button.BackgroundColor3 = C.Accent2
        marker.BackgroundColor3 = C.Accent
        page.ScrollBarImageColor3 = C.Accent
        if active then text.TextColor3 = C.Accent end
    end)
    button.MouseButton1Click:Connect(function() selectTab(tab) end)

    tab.Page = page
    Tabs[#Tabs + 1] = tab
    if #Tabs == 1 then selectTab(tab) end

    -- Khung nền chung cho mọi phần tử
    local function makeCard(height)
        order = order + 1
        local f = new("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = C.Card, BackgroundTransparency = 0.25, BorderSizePixel = 0,
            LayoutOrder = order,
        }, page)
        corner(f, 8)
        stroke(f, C.White, 1, 0.92)
        return f
    end

    function tab:AddCard(height)
        return makeCard(height)
    end

    function tab:AddSection(textValue)
        order = order + 1
        local l = label(page, {
            Text = textValue, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Accent,
            Size = UDim2.new(1, 0, 0, 18), LayoutOrder = order,
        })
        onTheme(function() l.TextColor3 = C.Accent end)
        return l
    end

    function tab:AddLabel(textValue)
        local f = makeCard(32)
        local l = label(f, {
            Text = textValue, TextColor3 = C.Sub,
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
        })
        return { Set = function(_, t) l.Text = t end }
    end

    function tab:AddButton(cfg)
        local f = makeCard(38)
        local s = f:FindFirstChildOfClass("UIStroke")
        local b = new("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        }, f)
        label(b, { Text = cfg.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0) })
        local dot = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
            Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
        }, b)
        corner(dot, 4)
        onTheme(function() dot.BackgroundColor3 = C.Accent end)

        b.MouseEnter:Connect(function() tween(f, 0.12, { BackgroundColor3 = C.CardHi }) end)
        b.MouseLeave:Connect(function() tween(f, 0.12, { BackgroundColor3 = C.Card }) end)
        b.MouseButton1Down:Connect(function() tween(f, 0.06, { BackgroundColor3 = C.CardHi }) end)
        b.MouseButton1Click:Connect(function()
            -- Nháy viền + chấm tròn để xác nhận đã bấm
            s.Color = C.Accent
            s.Transparency = 0.1
            tween(s, 0.4, { Transparency = 0.92, Color = C.White })
            tween(f, 0.2, { BackgroundColor3 = C.Card })
            dot.Size = UDim2.fromOffset(15, 15)
            tween(dot, 0.3, { Size = UDim2.fromOffset(8, 8) })
            safe(cfg.Callback)
        end)
    end

    function tab:AddToggle(cfg)
        local value = cfg.Default == true
        local f = makeCard(38)
        label(f, { Text = cfg.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0) })
        local track = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(42, 22), BackgroundColor3 = C.CardHi, BorderSizePixel = 0,
        }, f)
        corner(track, 11)
        local knob = new("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.Sub, BorderSizePixel = 0,
        }, track)
        corner(knob, 8)
        local hit = new("TextButton", {
            Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        }, f)

        local function render(animate)
            local d = animate and 0.18 or 0
            tween(track, d, { BackgroundColor3 = value and C.Accent or C.CardHi })
            tween(knob, d, {
                Position = value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                BackgroundColor3 = value and C.Bg or C.Sub,
            })
        end
        local function setValue(v, silent)
            value = v and true or false
            render(true)
            if not silent then safe(cfg.Callback, value) end
        end
        hit.MouseButton1Click:Connect(function() setValue(not value) end)
        onTheme(function() render(false) end)

        local obj = {}
        function obj:Set(v) setValue(v, true) end
        function obj:Get() return value end
        return obj
    end

    function tab:AddSlider(cfg)
        local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
        local suffix = cfg.Suffix or ""
        local value = math.clamp(cfg.Default or min, min, max)

        local f = makeCard(54)
        label(f, { Text = cfg.Name, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -90, 0, 18) })
        local valueLabel = label(f, {
            Text = "", Font = Enum.Font.GothamBold, TextColor3 = C.Accent, TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(70, 18),
        })
        local bar = new("Frame", {
            Position = UDim2.new(0, 12, 1, -17), Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = C.CardHi, BorderSizePixel = 0,
        }, f)
        corner(bar, 3)
        local fill = new("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
        }, bar)
        corner(fill, 3)
        local knob = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.White, BorderSizePixel = 0,
        }, bar)
        corner(knob, 7)
        local knobStroke = stroke(knob, C.Accent, 2, 0)
        -- Vùng chạm rộng hơn thanh trượt để dễ bấm bằng ngón tay
        local hit = new("TextButton", {
            Text = "", BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -24),
        }, f)

        local function render()
            local a = (max > min) and (value - min) / (max - min) or 0
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.fromScale(a, 0.5)
            local shown = (inc < 1) and string.format("%.2f", value) or tostring(math.floor(value + 0.5))
            valueLabel.Text = shown .. suffix
        end
        local function setValue(v, silent)
            v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
            if v == value then return end
            value = v
            render()
            if not silent then safe(cfg.Callback, value) end
        end
        local function fromX(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            setValue(min + (max - min) * a)
        end

        local activeInput = nil
        hit.InputBegan:Connect(function(input)
            local kind = input.UserInputType
            if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end
            activeInput = input
            page.ScrollingEnabled = false -- khóa cuộn trang khi đang kéo thanh trượt
            tween(knob, 0.1, { Size = UDim2.fromOffset(18, 18) })
            fromX(input.Position.X)
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conn:Disconnect()
                    activeInput = nil
                    page.ScrollingEnabled = true
                    tween(knob, 0.1, { Size = UDim2.fromOffset(14, 14) })
                end
            end)
        end)
        connect(UserInputService.InputChanged, function(input)
            if not activeInput then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input == activeInput then
                fromX(input.Position.X)
            end
        end)

        onTheme(function()
            fill.BackgroundColor3 = C.Accent
            knobStroke.Color = C.Accent
            valueLabel.TextColor3 = C.Accent
        end)
        render()

        local obj = {}
        function obj:Set(v) setValue(v, true) end
        function obj:Get() return value end
        return obj
    end

    function tab:AddDropdown(cfg)
        local options = cfg.Options or {}
        local current = cfg.Default or options[1]
        local closedH, rowH = 38, 30
        local openH = closedH + #options * rowH + 6

        local f = makeCard(closedH)
        f.ClipsDescendants = true
        label(f, { Text = cfg.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, -12, 0, closedH) })
        local valueLabel = label(f, {
            Text = tostring(current), Font = Enum.Font.GothamBold, TextColor3 = C.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -32, 0, 0), Size = UDim2.new(0.5, -32, 0, closedH),
        })
        local arrow = label(f, {
            Text = ">", Font = Enum.Font.GothamBold, TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Center,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -17, 0, closedH / 2),
            Size = UDim2.fromOffset(18, 18), Rotation = 90,
        })
        local head = new("TextButton", {
            Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, closedH),
        }, f)
        local list = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, closedH), Size = UDim2.new(1, 0, 0, #options * rowH + 6),
        }, f)
        new("UIListLayout", {
            Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }, list)
        new("UIPadding", { PaddingTop = UDim.new(0, 2) }, list)

        local rows = {}
        local function paint()
            valueLabel.TextColor3 = C.Accent
            for _, r in ipairs(rows) do
                r[2].TextColor3 = (r[1] == current) and C.Accent or C.Text
            end
        end
        local function setValue(v, silent)
            current = v
            valueLabel.Text = tostring(v)
            paint()
            if not silent then safe(cfg.Callback, v) end
        end
        local open = false
        local function setExpanded(state)
            open = state
            tween(f, 0.2, { Size = UDim2.new(1, 0, 0, open and openH or closedH) })
            tween(arrow, 0.2, { Rotation = open and 270 or 90 })
        end

        for i, opt in ipairs(options) do
            local row = new("TextButton", {
                Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.Text,
                AutoButtonColor = false, Size = UDim2.new(1, -16, 0, rowH - 2),
                BackgroundColor3 = C.CardHi, BackgroundTransparency = 0.45, BorderSizePixel = 0,
                LayoutOrder = i,
            }, list)
            corner(row, 6)
            rows[i] = { opt, row }
            row.MouseButton1Click:Connect(function()
                setValue(opt)
                setExpanded(false)
            end)
        end
        head.MouseButton1Click:Connect(function() setExpanded(not open) end)
        onTheme(paint)

        local obj = {}
        function obj:Set(v) setValue(v, true) end
        function obj:Get() return current end
        return obj
    end

    function tab:AddTextbox(cfg)
        local f = makeCard(38)
        label(f, { Text = cfg.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, -12, 1, 0) })
        local box = new("TextBox", {
            Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "Type here",
            PlaceholderColor3 = C.Sub, TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 13,
            ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = C.CardHi, BackgroundTransparency = 0.3, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.6, -12, 0, 26),
        }, f)
        corner(box, 6)
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
        local s = stroke(box, C.Accent, 1.2, 1)
        onTheme(function() s.Color = C.Accent end)
        box.Focused:Connect(function() tween(s, 0.15, { Transparency = 0 }) end)
        box.FocusLost:Connect(function(enterPressed)
            tween(s, 0.15, { Transparency = 1 })
            safe(cfg.Callback, box.Text, enterPressed)
        end)
        return box
    end

    return tab
end

-- ==================== NÚT NỔI MỞ / ĐÓNG ====================
local TOGGLE_HOME = UDim2.new(0, 40, 0.5, 0)

local Toggle = new("TextButton", {
    Name = "Toggle",
    Text = BOLT,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.Accent, -- dự phòng nếu thiết bị không vẽ được emoji
    AutoButtonColor = false,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = TOGGLE_HOME,
    Size = UDim2.fromOffset(46, 46),
    BackgroundColor3 = C.Bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ZIndex = 30,
}, gui)
corner(Toggle, 23)
local toggleStroke = stroke(Toggle, C.White, 2, 0)
local toggleGrad = new("UIGradient", {}, toggleStroke)
onTheme(function()
    toggleGrad.Color = arcSequence()
    Toggle.TextColor3 = C.Accent
end)
loopTween(toggleGrad, 2.4, { Rotation = 360 }, Enum.EasingStyle.Linear, false)
makeDraggable(Toggle, Toggle, function() setOpen(not isOpen) end)

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        setOpen(not isOpen)
    end
end)

-- ==================== API CÔNG KHAI ====================
Hub.Notify   = Notify
Hub.SetOpen  = setOpen
Hub.Strike   = strike
Hub.SetTheme = setTheme

-- ==================== NỘI DUNG CÁC TAB ====================
-- Tab 1: thông tin người chơi + chỉ số trực tiếp (chỉ đọc, không can thiệp game)
local home = Hub:AddTab("Home")

home:AddSection("Player")
do
    local f = home:AddCard(64)
    local avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = C.CardHi, BorderSizePixel = 0,
    }, f)
    corner(avatar, 22)
    local avatarStroke = stroke(avatar, C.Accent, 2, 0)
    onTheme(function() avatarStroke.Color = C.Accent end)
    label(f, {
        Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 15,
        Position = UDim2.fromOffset(64, 12), Size = UDim2.new(1, -74, 0, 20),
    })
    label(f, {
        Text = "@" .. LocalPlayer.Name .. "  (ID " .. LocalPlayer.UserId .. ")", TextSize = 11, TextColor3 = C.Sub,
        Position = UDim2.fromOffset(64, 34), Size = UDim2.new(1, -74, 0, 16),
    })
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and alive then avatar.Image = img end
    end)
end

home:AddSection("Live stats")
local fpsText, pingText, playersText
do
    local f = home:AddCard(58)
    local function stat(index, caption)
        local value = label(f, {
            Text = "--", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = C.Accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new((index - 1) / 3, 0, 0, 8), Size = UDim2.new(1 / 3, 0, 0, 24),
        })
        label(f, {
            Text = caption, TextSize = 11, TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new((index - 1) / 3, 0, 0, 32), Size = UDim2.new(1 / 3, 0, 0, 16),
        })
        onTheme(function() value.TextColor3 = C.Accent end)
        return value
    end
    fpsText, pingText, playersText = stat(1, "FPS"), stat(2, "Ping (ms)"), stat(3, "Players")
end

home:AddSection("Server")
local gameLabel = home:AddLabel("Game: loading...")
home:AddLabel("Place " .. game.PlaceId .. "  |  Job " .. string.sub(game.JobId, 1, 8))
task.spawn(function()
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    gameLabel:Set("Game: " .. ((ok and info and info.Name) or game.Name))
end)

-- Cập nhật FPS / Ping / số người chơi mỗi 0.5 giây
do
    local frames, last = 0, os.clock()
    connect(RunService.RenderStepped, function() frames = frames + 1 end)
    task.spawn(function()
        while alive do
            task.wait(0.5)
            local now = os.clock()
            local fps = math.floor(frames / math.max(now - last, 0.001) + 0.5)
            frames, last = 0, now
            if isOpen then
                fpsText.Text = tostring(fps)
                local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                pingText.Text = ok and tostring(math.floor(ping + 0.5)) or "--"
                playersText.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            end
        end
    end)
end

-- Tab 2: mẫu các component để bạn copy dùng
local demo = Hub:AddTab("Components")

demo:AddSection("Buttons")
demo:AddButton({ Name = "Show a notification", Callback = function()
    Notify("Notification", "Buttons run any function you give them.", 3)
end })

demo:AddSection("Inputs")
demo:AddToggle({ Name = "Toggle", Default = false, Callback = function(on)
    Notify("Toggle", on and "Turned on" or "Turned off", 1.5)
end })
demo:AddSlider({ Name = "Slider", Min = 0, Max = 100, Default = 40 })
demo:AddDropdown({ Name = "Dropdown", Options = { "Alpha", "Beta", "Gamma" }, Default = "Alpha", Callback = function(v)
    Notify("Dropdown", "Selected " .. tostring(v), 1.5)
end })
demo:AddTextbox({ Name = "Textbox", Placeholder = "Type and press Enter", Callback = function(textValue, entered)
    if entered and textValue ~= "" then
        Notify("Textbox", "You typed: " .. textValue, 2)
    end
end })

-- Tab 3: giao diện + hiệu ứng sét
local settings = Hub:AddTab("Settings")

settings:AddSection("Appearance")
settings:AddDropdown({ Name = "Theme", Options = { "Thunder", "Storm", "Plasma" }, Default = "Thunder", Callback = setTheme })
settings:AddSlider({
    Name = "Window size", Min = 70, Max = 130, Default = 100, Increment = 5, Suffix = "%",
    Callback = function(v)
        baseScale = v / 100
        if isOpen then RootScale.Scale = baseScale end
    end,
})

settings:AddSection("Lightning")
settings:AddToggle({ Name = "Lightning storm", Default = true, Callback = function(on) fxEnabled = on end })
settings:AddSlider({
    Name = "Storm intensity", Min = 1, Max = 10, Default = 5,
    Callback = function(v) fxDelay = 7 - v * 0.62 end,
})
settings:AddButton({ Name = "Summon thunder", Callback = function() strike(true) end })

settings:AddSection("Window")
settings:AddButton({ Name = "Reset window position", Callback = function()
    if minimized then
        minimized = false
        Root.Size = UDim2.fromOffset(W, H)
    end
    Root.Position = UDim2.fromScale(0.5, 0.5)
    Toggle.Position = TOGGLE_HOME
end })
settings:AddButton({ Name = "Unload Zenvolt Hub", Callback = function()
    setOpen(false)
    task.delay(0.35, Hub.Destroy)
end })

-- >>> THÊM TAB CỦA BẠN Ở ĐÂY (dùng biến Hub) <<<
-- local mine = Hub:AddTab("My tab")
-- mine:AddSection("Hello")
-- mine:AddButton({ Name = "Say hi", Callback = function() Hub.Notify("Hi", "It works.", 2) end })

-- ==================== SÉT NGẪU NHIÊN + KHỞI ĐỘNG ====================
task.spawn(function()
    while alive do
        task.wait(rng:NextNumber(0.6, 1.4) * fxDelay)
        if fxEnabled then strike(false) end
    end
end)

setOpen(true)
Notify("Zenvolt Hub", "Loaded. Tap the " .. BOLT .. " button to open or close.", 4)

return Hub
