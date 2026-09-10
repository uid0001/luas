local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

-- Default Theme Palette (iOS 18 Dark Modern)
Library.Theme = {
    Background = Color3.fromRGB(20, 20, 24),
    Sidebar = Color3.fromRGB(15, 15, 18),
    CardBg = Color3.fromRGB(28, 28, 34),
    CardBorder = Color3.fromRGB(48, 48, 56),
    SidebarBorder = Color3.fromRGB(36, 36, 44),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(160, 160, 175),
    Accent = Color3.fromRGB(10, 132, 255), -- Default iOS Blue
    AccentGreen = Color3.fromRGB(52, 199, 89),
    AccentRed = Color3.fromRGB(255, 69, 58),
    AccentOrange = Color3.fromRGB(255, 159, 10),
    AccentPurple = Color3.fromRGB(175, 82, 222),
    AccentPink = Color3.fromRGB(255, 55, 95),
    AccentCyan = Color3.fromRGB(100, 210, 255),
    HoverLight = Color3.fromRGB(38, 38, 48),
    SwitchOff = Color3.fromRGB(58, 58, 64),
    SwitchKnob = Color3.fromRGB(255, 255, 255),
    DropdownBg = Color3.fromRGB(30, 30, 36)
}

Library.AccentColors = {
    {Name = "Blue", NameRu = "Синий", Color = Color3.fromRGB(10, 132, 255)},
    {Name = "Purple", NameRu = "Фиолетовый", Color = Color3.fromRGB(175, 82, 222)},
    {Name = "Green", NameRu = "Зеленый", Color = Color3.fromRGB(48, 209, 88)},
    {Name = "Orange", NameRu = "Оранжевый", Color = Color3.fromRGB(255, 159, 10)},
    {Name = "Pink", NameRu = "Розовый", Color = Color3.fromRGB(255, 55, 95)},
    {Name = "Red", NameRu = "Красный", Color = Color3.fromRGB(255, 69, 58)},
    {Name = "Cyan", NameRu = "Бирюзовый", Color = Color3.fromRGB(100, 210, 255)}
}

-- Tween presets
local TweenFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TweenSpring = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ===================================================
-- Lucide Icons System (WindUI Compatible)
-- Supports loading from GitHub raw, readfile("icons.lua"), or preloaded table
-- ===================================================
Library.Icons = {}
Library.IconsLoaded = false
Library.IconsUrl = "https://raw.githubusercontent.com/Footagesus/Icons/46d30c19ba7bc601d6ec794a48dc3a89568b1eec/lucide/dist/Icons.lua"

function Library:LoadIcons(customSource)
    if Library.IconsLoaded and next(Library.Icons) ~= nil then
        return Library.Icons
    end

    local loaded = false

    -- 1. If custom table is passed directly
    if type(customSource) == "table" then
        Library.Icons = customSource
        Library.IconsLoaded = true
        return Library.Icons
    end

    -- 2. Try loading via readfile / loadfile (local file fallback, e.g. "icons.lua")
    pcall(function()
        if readfile and isfile and isfile("icons.lua") then
            local chunk = loadstring(readfile("icons.lua"))
            if chunk then
                local res = chunk()
                if type(res) == "table" then
                    Library.Icons = res
                    Library.IconsLoaded = true
                    loaded = true
                end
            end
        end
    end)

    if loaded then return Library.Icons end

    -- 3. Load dynamically from GitHub raw via game:HttpGet / request
    pcall(function()
        local url = (type(customSource) == "string" and customSource) or Library.IconsUrl
        local content = nil
        if game and game.HttpGet then
            content = game:HttpGet(url)
        elseif request then
            local response = request({Url = url, Method = "GET"})
            content = response and response.Body
        elseif syn and syn.request then
            local response = syn.request({Url = url, Method = "GET"})
            content = response and response.Body
        elseif http_request then
            local response = http_request({Url = url, Method = "GET"})
            content = response and response.Body
        end

        if content and #content > 0 then
            local fn = loadstring(content)
            if fn then
                local iconMap = fn()
                if type(iconMap) == "table" then
                    Library.Icons = iconMap
                    Library.IconsLoaded = true
                    loaded = true
                end
            end
        end
    end)

    return Library.Icons
end

-- Resolve an icon input into a valid rbxassetid url:
-- Handles "lucide:name", "name", "rbxassetid://12345", or raw numbers.
-- If no icon specified, returns nil / "" (no forced default!).
function Library:GetIcon(iconInput)
    if not iconInput then return "" end
    if type(iconInput) == "number" then
        return "rbxassetid://" .. tostring(iconInput)
    end
    if type(iconInput) ~= "string" or iconInput == "" then
        return ""
    end

    -- Direct Roblox asset URL or path
    if iconInput:sub(1, 13) == "rbxassetid://" or iconInput:sub(1, 11) == "roblox.com/" or iconInput:find("://") then
        return iconInput
    end

    -- Strip "lucide:" prefix if present (WindUI syntax compatibility)
    local cleanName = iconInput
    if cleanName:sub(1, 7) == "lucide:" then
        cleanName = cleanName:sub(8)
    end
    cleanName = string.lower(cleanName:gsub("^%s+", ""):gsub("%s+$", ""))

    -- Auto-load icons map if empty
    if not Library.IconsLoaded or next(Library.Icons) == nil then
        Library:LoadIcons()
    end

    -- Lookup in Lucide icon map
    if Library.Icons and Library.Icons[cleanName] then
        return Library.Icons[cleanName]
    end

    -- Fallback: if string is all digits
    if tonumber(cleanName) then
        return "rbxassetid://" .. cleanName
    end

    return ""
end

function Library:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "iOS 18 Menu"
    local menuKey = config.Keybind or Enum.KeyCode.RightControl
    local initialAccent = config.Accent or Library.Theme.Accent
    local windowSize = config.Size or UDim2.new(0, 560, 0, 370)

    local currentAccent = initialAccent
    local accentListeners = {}

    local function RegisterAccentListener(cb)
        table.insert(accentListeners, cb)
        pcall(cb, currentAccent)
    end

    local function SetAccent(newColor)
        currentAccent = newColor
        Library.Theme.Accent = newColor
        for _, cb in ipairs(accentListeners) do
            pcall(cb, currentAccent)
        end
    end

    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "iOS18_Window_" .. tostring(math.random(10000, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Container Frame
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = windowSize
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Library.Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 0
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 20)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Library.Theme.CardBorder
    MainStroke.Thickness = 1.2
    MainStroke.Transparency = 0.3
    MainStroke.Parent = MainFrame

    -- Menu Dimensions & Resizing
    local MIN_WIDTH, MAX_WIDTH = 460, 900
    local MIN_HEIGHT, MAX_HEIGHT = 320, 650
    local currentWidth = math.clamp(windowSize.X.Offset, MIN_WIDTH, MAX_WIDTH)
    local currentHeight = math.clamp(windowSize.Y.Offset, MIN_HEIGHT, MAX_HEIGHT)

    -- Initial entrance animation state (compact -> full with fade)
    local isMenuOpen = true
    local isMenuAnimating = false
    MainFrame.Size = UDim2.new(0, math.max(MIN_WIDTH - 40, currentWidth - 40), 0, math.max(MIN_HEIGHT - 40, currentHeight - 40))
    MainFrame.GroupTransparency = 1
    MainStroke.Transparency = 1

    local entranceTween = TweenService:Create(MainFrame, TweenSmooth, {
        Size = UDim2.new(0, currentWidth, 0, currentHeight),
        GroupTransparency = 0
    })
    local entranceStrokeTween = TweenService:Create(MainStroke, TweenSmooth, {
        Transparency = 0.3
    })
    entranceTween:Play()
    entranceStrokeTween:Play()

    -- Global cleanup tracking
    local Connections = {}

    -- Resizing & Dragging implementation
    local isResizing = false
    local resizeStartMouse, resizeStartSize, resizeStartPos
    local isDragging = false
    local dragStart, startPos

    table.insert(Connections, MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not isResizing then
            -- Check if click is on bottom-right resize area or interactive element
            local mousePos = input.Position
            local framePos = MainFrame.AbsolutePosition
            local frameSize = MainFrame.AbsoluteSize
            -- Ignore drag if clicking near bottom right resize corner (30x30 region)
            if mousePos.X >= (framePos.X + frameSize.X - 30) and mousePos.Y >= (framePos.Y + frameSize.Y - 30) then
                return
            end

            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            local endedConn
            endedConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                    if endedConn then endedConn:Disconnect() end
                end
            end)
            table.insert(Connections, endedConn)
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if isDragging and not isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                math.round(startPos.X.Offset + delta.X),
                startPos.Y.Scale,
                math.round(startPos.Y.Offset + delta.Y)
            )
        elseif isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStartMouse
            local targetW = math.clamp(resizeStartSize.X + delta.X, MIN_WIDTH, MAX_WIDTH)
            local targetH = math.clamp(resizeStartSize.Y + delta.Y, MIN_HEIGHT, MAX_HEIGHT)

            local actualDeltaW = targetW - resizeStartSize.X
            local actualDeltaH = targetH - resizeStartSize.Y

            currentWidth = math.round(targetW)
            currentHeight = math.round(targetH)

            MainFrame.Size = UDim2.new(0, currentWidth, 0, currentHeight)
            MainFrame.Position = UDim2.new(
                resizeStartPos.X.Scale,
                math.round(resizeStartPos.X.Offset + (actualDeltaW * 0.5)),
                resizeStartPos.Y.Scale,
                math.round(resizeStartPos.Y.Offset + (actualDeltaH * 0.5))
            )
        end
    end))

    -- iOS 18 Corner Resize Grip (Bottom-Right)
    local ResizeGripBtn = Instance.new("TextButton")
    ResizeGripBtn.Name = "ResizeGrip"
    ResizeGripBtn.Size = UDim2.new(0, 24, 0, 24)
    ResizeGripBtn.AnchorPoint = Vector2.new(1, 1)
    ResizeGripBtn.Position = UDim2.new(1, -2, 1, -2)
    ResizeGripBtn.BackgroundTransparency = 1
    ResizeGripBtn.AutoButtonColor = false
    ResizeGripBtn.Text = ""
    ResizeGripBtn.ZIndex = 120
    ResizeGripBtn.Parent = MainFrame

    local GripPill1 = Instance.new("Frame")
    GripPill1.Name = "GripPill1"
    GripPill1.Size = UDim2.new(0, 11, 0, 2.5)
    GripPill1.AnchorPoint = Vector2.new(1, 1)
    GripPill1.Position = UDim2.new(1, -6, 1, -6)
    GripPill1.Rotation = -45
    GripPill1.BackgroundColor3 = Color3.fromRGB(100, 100, 115)
    GripPill1.BorderSizePixel = 0
    GripPill1.ZIndex = 121
    GripPill1.Parent = ResizeGripBtn

    local GripCorner1 = Instance.new("UICorner")
    GripCorner1.CornerRadius = UDim.new(1, 0)
    GripCorner1.Parent = GripPill1

    local GripPill2 = Instance.new("Frame")
    GripPill2.Name = "GripPill2"
    GripPill2.Size = UDim2.new(0, 6, 0, 2.5)
    GripPill2.AnchorPoint = Vector2.new(1, 1)
    GripPill2.Position = UDim2.new(1, -11, 1, -11)
    GripPill2.Rotation = -45
    GripPill2.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
    GripPill2.BorderSizePixel = 0
    GripPill2.ZIndex = 121
    GripPill2.Parent = ResizeGripBtn

    local GripCorner2 = Instance.new("UICorner")
    GripCorner2.CornerRadius = UDim.new(1, 0)
    GripCorner2.Parent = GripPill2

    local function SetGripVisualState(isHover, isActive)
        local targetColor = isActive and currentAccent 
            or (isHover and Color3.fromRGB(220, 220, 235) or Color3.fromRGB(100, 100, 115))
        local targetColor2 = isActive and currentAccent 
            or (isHover and Color3.fromRGB(180, 180, 200) or Color3.fromRGB(80, 80, 95))
        local targetSize1 = isActive and UDim2.new(0, 13, 0, 3) 
            or (isHover and UDim2.new(0, 12, 0, 2.5) or UDim2.new(0, 11, 0, 2.5))
        local targetSize2 = isActive and UDim2.new(0, 8, 0, 3) 
            or (isHover and UDim2.new(0, 7, 0, 2.5) or UDim2.new(0, 6, 0, 2.5))

        TweenService:Create(GripPill1, TweenFast, {BackgroundColor3 = targetColor, Size = targetSize1}):Play()
        TweenService:Create(GripPill2, TweenFast, {BackgroundColor3 = targetColor2, Size = targetSize2}):Play()
    end

    ResizeGripBtn.MouseEnter:Connect(function()
        if not isResizing then SetGripVisualState(true, false) end
    end)
    ResizeGripBtn.MouseLeave:Connect(function()
        if not isResizing then SetGripVisualState(false, false) end
    end)

    table.insert(Connections, ResizeGripBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = true
            isDragging = false
            resizeStartMouse = input.Position
            resizeStartSize = Vector2.new(MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y)
            resizeStartPos = MainFrame.Position
            SetGripVisualState(true, true)

            local endConn
            endConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    isResizing = false
                    if endConn then endConn:Disconnect() end
                    SetGripVisualState(false, false)
                    if config.OnResize then
                        pcall(config.OnResize, currentWidth, currentHeight)
                    end
                end
            end)
            table.insert(Connections, endConn)
        end
    end))

    RegisterAccentListener(function(newColor)
        if isResizing then
            TweenService:Create(GripPill1, TweenFast, {BackgroundColor3 = newColor}):Play()
            TweenService:Create(GripPill2, TweenFast, {BackgroundColor3 = newColor}):Play()
        end
    end)

    -- Left Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Library.Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 20)
    SidebarCorner.Parent = Sidebar

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = Library.Theme.SidebarBorder
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.Parent = Sidebar

    -- Sidebar Header: Image Logo (if config.Logo provided) or Text Title
    if config.Logo then
        local AppLogo = Instance.new("ImageLabel")
        AppLogo.Name = "AppLogo"
        AppLogo.Image = config.Logo
        AppLogo.ImageColor3 = (config.TintLogo ~= false) and currentAccent or Color3.fromRGB(255, 255, 255)
        AppLogo.BackgroundTransparency = 1
        AppLogo.AnchorPoint = Vector2.new(0.5, 0.5)
        AppLogo.Position = UDim2.new(0.5, 0, 0, 28)
        AppLogo.Size = config.LogoSize or UDim2.new(0, 110, 0, 32)
        AppLogo.ScaleType = Enum.ScaleType.Fit
        AppLogo.Parent = Sidebar

        if config.TintLogo ~= false then
            RegisterAccentListener(function(newColor)
                TweenService:Create(AppLogo, TweenFast, {ImageColor3 = newColor}):Play()
            end)
        end
    else
        local AppTitle = Instance.new("TextLabel")
        AppTitle.Text = windowTitle
        AppTitle.Font = Enum.Font.GothamBold
        AppTitle.TextSize = 17
        AppTitle.TextColor3 = Library.Theme.TextPrimary
        AppTitle.TextXAlignment = Enum.TextXAlignment.Left
        AppTitle.BackgroundTransparency = 1
        AppTitle.Position = UDim2.new(0, 18, 0, 16)
        AppTitle.Size = UDim2.new(1, -36, 0, 26)
        AppTitle.Parent = Sidebar
    end

    -- Tab buttons container
    local TabButtonsLayout = Instance.new("ScrollingFrame")
    TabButtonsLayout.Size = UDim2.new(1, -16, 1, -66)
    TabButtonsLayout.Position = UDim2.new(0, 8, 0, 56)
    TabButtonsLayout.BackgroundTransparency = 1
    TabButtonsLayout.ScrollBarThickness = 0
    TabButtonsLayout.BorderSizePixel = 0
    TabButtonsLayout.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabButtonsLayout.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabButtonsLayout.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabButtonsLayout

    -- Right Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -160, 1, 0)
    ContentArea.Position = UDim2.new(0, 160, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = false
    ContentArea.Parent = MainFrame

    -- Modal Overlay (for confirmation dialogs)
    local ModalOverlay = Instance.new("Frame")
    ModalOverlay.Name = "ModalOverlay"
    ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
    ModalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ModalOverlay.BackgroundTransparency = 1
    ModalOverlay.BorderSizePixel = 0
    ModalOverlay.Visible = false
    ModalOverlay.ZIndex = 150
    ModalOverlay.Parent = MainFrame

    local ModalCorner = Instance.new("UICorner")
    ModalCorner.CornerRadius = UDim.new(0, 20)
    ModalCorner.Parent = ModalOverlay

    local DialogCard = Instance.new("Frame")
    DialogCard.Name = "DialogCard"
    DialogCard.Size = UDim2.new(0, 320, 0, 160)
    DialogCard.AnchorPoint = Vector2.new(0.5, 0.5)
    DialogCard.Position = UDim2.new(0.5, 0, 0.5, 0)
    DialogCard.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    DialogCard.BorderSizePixel = 0
    DialogCard.ZIndex = 151
    DialogCard.Parent = ModalOverlay

    local DialogCorner = Instance.new("UICorner")
    DialogCorner.CornerRadius = UDim.new(0, 16)
    DialogCorner.Parent = DialogCard

    local DialogStroke = Instance.new("UIStroke")
    DialogStroke.Color = Library.Theme.AccentRed
    DialogStroke.Thickness = 1.2
    DialogStroke.Transparency = 0.3
    DialogStroke.Parent = DialogCard

    local DialogTitle = Instance.new("TextLabel")
    DialogTitle.Name = "DialogTitle"
    DialogTitle.Font = Enum.Font.GothamBold
    DialogTitle.TextSize = 13
    DialogTitle.TextColor3 = Library.Theme.AccentRed
    DialogTitle.TextXAlignment = Enum.TextXAlignment.Center
    DialogTitle.BackgroundTransparency = 1
    DialogTitle.Position = UDim2.new(0, 16, 0, 14)
    DialogTitle.Size = UDim2.new(1, -32, 0, 18)
    DialogTitle.ZIndex = 152
    DialogTitle.Parent = DialogCard

    local DialogPrompt = Instance.new("TextLabel")
    DialogPrompt.Name = "DialogPrompt"
    DialogPrompt.Font = Enum.Font.GothamMedium
    DialogPrompt.TextSize = 13
    DialogPrompt.TextColor3 = Library.Theme.TextPrimary
    DialogPrompt.TextXAlignment = Enum.TextXAlignment.Center
    DialogPrompt.TextWrapped = true
    DialogPrompt.BackgroundTransparency = 1
    DialogPrompt.Position = UDim2.new(0, 18, 0, 38)
    DialogPrompt.Size = UDim2.new(1, -36, 0, 48)
    DialogPrompt.ZIndex = 152
    DialogPrompt.Parent = DialogCard

    local DialogBtnContainer = Instance.new("Frame")
    DialogBtnContainer.Name = "DialogBtnContainer"
    DialogBtnContainer.BackgroundTransparency = 1
    DialogBtnContainer.Position = UDim2.new(0, 16, 1, -44)
    DialogBtnContainer.Size = UDim2.new(1, -32, 0, 32)
    DialogBtnContainer.ZIndex = 152
    DialogBtnContainer.Parent = DialogCard

    local DialogBtnLayout = Instance.new("UIListLayout")
    DialogBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    DialogBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    DialogBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    DialogBtnLayout.Padding = UDim.new(0, 10)
    DialogBtnLayout.Parent = DialogBtnContainer

    local DialogNoBtn = Instance.new("TextButton")
    DialogNoBtn.Name = "DialogNoBtn"
    DialogNoBtn.Size = UDim2.new(0.5, -5, 1, 0)
    DialogNoBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
    DialogNoBtn.AutoButtonColor = false
    DialogNoBtn.Text = "Cancel"
    DialogNoBtn.Font = Enum.Font.GothamMedium
    DialogNoBtn.TextSize = 13
    DialogNoBtn.TextColor3 = Library.Theme.TextSecondary
    DialogNoBtn.ZIndex = 153
    DialogNoBtn.Parent = DialogBtnContainer

    local DialogNoCorner = Instance.new("UICorner")
    DialogNoCorner.CornerRadius = UDim.new(0, 8)
    DialogNoCorner.Parent = DialogNoBtn

    local DialogYesBtn = Instance.new("TextButton")
    DialogYesBtn.Name = "DialogYesBtn"
    DialogYesBtn.Size = UDim2.new(0.5, -5, 1, 0)
    DialogYesBtn.BackgroundColor3 = Library.Theme.AccentRed
    DialogYesBtn.AutoButtonColor = false
    DialogYesBtn.Text = "Confirm"
    DialogYesBtn.Font = Enum.Font.GothamBold
    DialogYesBtn.TextSize = 13
    DialogYesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DialogYesBtn.ZIndex = 153
    DialogYesBtn.Parent = DialogBtnContainer

    local DialogYesCorner = Instance.new("UICorner")
    DialogYesCorner.CornerRadius = UDim.new(0, 8)
    DialogYesCorner.Parent = DialogYesBtn

    local pendingModalCallback = nil
    local function CloseModal()
        pendingModalCallback = nil
        TweenService:Create(DialogCard, TweenFast, {Size = UDim2.new(0, 260, 0, 130)}):Play()
        local t = TweenService:Create(ModalOverlay, TweenFast, {BackgroundTransparency = 1})
        t:Play()
        t.Completed:Connect(function()
            ModalOverlay.Visible = false
        end)
    end

    DialogNoBtn.MouseButton1Click:Connect(CloseModal)
    DialogYesBtn.MouseButton1Click:Connect(function()
        local cb = pendingModalCallback
        CloseModal()
        if cb then pcall(cb) end
    end)

    local function OpenConfirmModal(...)
        local args = {...}
        local title, prompt, onConfirm, cancelText, confirmText
        if typeof(args[1]) == "table" and (args[1] == Window or args[1].ScreenGui ~= nil) then
            title = args[2]
            prompt = args[3]
            onConfirm = args[4]
            cancelText = args[5]
            confirmText = args[6]
        else
            title = args[1]
            prompt = args[2]
            onConfirm = args[3]
            cancelText = args[4]
            confirmText = args[5]
        end

        pendingModalCallback = onConfirm
        DialogTitle.Text = tostring(title or "CONFIRMATION")
        DialogPrompt.Text = tostring(prompt or "Are you sure you want to proceed?")
        DialogNoBtn.Text = tostring(cancelText or "Cancel")
        DialogYesBtn.Text = tostring(confirmText or "Confirm")
        ModalOverlay.BackgroundTransparency = 1
        ModalOverlay.Visible = true
        DialogCard.Size = UDim2.new(0, 260, 0, 130)
        TweenService:Create(ModalOverlay, TweenFast, {BackgroundTransparency = 0.55}):Play()
        TweenService:Create(DialogCard, TweenSpring, {Size = UDim2.new(0, 320, 0, 160)}):Play()
    end

    -- Notification Overlay (iOS Dynamic Banner at Top Center)
    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.Size = UDim2.new(0, 320, 1, 0)
    NotificationContainer.Position = UDim2.new(0.5, 0, 0, 16)
    NotificationContainer.AnchorPoint = Vector2.new(0.5, 0)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.ZIndex = 300
    NotificationContainer.Parent = ScreenGui

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotifLayout.Padding = UDim.new(0, 8)
    NotifLayout.Parent = NotificationContainer

    local function Notify(...)
        local args = {...}
        local notifConfig = args[1]
        if typeof(notifConfig) == "table" and (notifConfig == Window or notifConfig.ScreenGui ~= nil) then
            notifConfig = args[2]
        end
        notifConfig = notifConfig or {}
        local title = notifConfig.Title or "Notification"
        local message = notifConfig.Message or notifConfig.Text or ""
        local duration = notifConfig.Duration or 3
        local iconAsset = Library:GetIcon(notifConfig.Icon)
        local hasIcon = (iconAsset ~= nil and iconAsset ~= "")
        local notifColor = notifConfig.Color or currentAccent

        local Card = Instance.new("CanvasGroup")
        Card.Name = "NotifCard"
        Card.Size = UDim2.new(1, 0, 0, 52)
        Card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        Card.BorderSizePixel = 0
        Card.GroupTransparency = 1
        Card.Position = UDim2.new(0, 0, 0, -20)
        Card.ZIndex = 301
        Card.Parent = NotificationContainer

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 14)
        CardCorner.Parent = Card

        local CardStroke = Instance.new("UIStroke")
        CardStroke.Color = notifColor
        CardStroke.Thickness = 1.2
        CardStroke.Transparency = 0.4
        CardStroke.Parent = Card

        if hasIcon then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Name = "NotifIcon"
            IconImg.Size = UDim2.new(0, 22, 0, 22)
            IconImg.Position = UDim2.new(0, 14, 0.5, 0)
            IconImg.AnchorPoint = Vector2.new(0, 0.5)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = iconAsset
            IconImg.ImageColor3 = notifColor
            IconImg.ZIndex = 302
            IconImg.Parent = Card
        end

        local textStartX = hasIcon and 46 or 16
        local textWidthOffset = hasIcon and -56 or -26

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Name = "NotifTitle"
        TitleLbl.Text = title
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 13
        TitleLbl.TextColor3 = notifColor
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Position = UDim2.new(0, textStartX, 0, 8)
        TitleLbl.Size = UDim2.new(1, textWidthOffset, 0, 16)
        TitleLbl.ZIndex = 302
        TitleLbl.Parent = Card

        local MsgLbl = Instance.new("TextLabel")
        MsgLbl.Name = "NotifMsg"
        MsgLbl.Text = message
        MsgLbl.Font = Enum.Font.GothamMedium
        MsgLbl.TextSize = 11.5
        MsgLbl.TextColor3 = Library.Theme.TextSecondary
        MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
        MsgLbl.BackgroundTransparency = 1
        MsgLbl.Position = UDim2.new(0, textStartX, 0, 26)
        MsgLbl.Size = UDim2.new(1, textWidthOffset, 0, 18)
        MsgLbl.ZIndex = 302
        MsgLbl.Parent = Card

        -- Slide down and fade in
        TweenService:Create(Card, TweenSpring, {GroupTransparency = 0}):Play()
        TweenService:Create(CardStroke, TweenFast, {Transparency = 0.3}):Play()

        task.delay(duration, function()
            if Card and Card.Parent then
                local fadeOut = TweenService:Create(Card, TweenFast, {
                    GroupTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0)
                })
                fadeOut:Play()
                fadeOut.Completed:Connect(function()
                    pcall(function() Card:Destroy() end)
                end)
            end
        end)
    end

    -- Tab management
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentArea = ContentArea,
        Pages = {},
        TabButtons = {},
        CurrentTab = nil,
        Connections = Connections,
        RegisterAccentListener = RegisterAccentListener,
        SetAccent = SetAccent,
        GetAccent = function() return currentAccent end,
        SetKeybind = function(self, newKey) menuKey = newKey end,
        GetKeybind = function(self) return menuKey end,
        OpenConfirmModal = OpenConfirmModal,
        Notify = Notify
    }

    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == menuKey then
            Window:Toggle()
        end
    end))

    function Window:SwitchTab(tabName)
        if self.CurrentTab == tabName then return end
        self.CurrentTab = tabName

        for name, btn in pairs(self.TabButtons) do
            local isSelected = (name == tabName)
            local targetBg = isSelected and Library.Theme.CardBg or Color3.fromRGB(0, 0, 0)
            local targetTrans = isSelected and 0 or 1
            local targetText = isSelected and currentAccent or Library.Theme.TextSecondary
            local targetIconColor = isSelected and currentAccent or Library.Theme.TextSecondary

            TweenService:Create(btn.Frame, TweenFast, {BackgroundTransparency = targetTrans, BackgroundColor3 = targetBg}):Play()
            TweenService:Create(btn.Label, TweenFast, {TextColor3 = targetText}):Play()
            if btn.Icon then
                TweenService:Create(btn.Icon, TweenFast, {ImageColor3 = targetIconColor}):Play()
            end
            if btn.Stroke then
                TweenService:Create(btn.Stroke, TweenFast, {Transparency = isSelected and 0.5 or 1}):Play()
            end
        end

        for name, page in pairs(self.Pages) do
            if name == tabName then
                page.Visible = true
                page.Position = UDim2.new(0, 12, 0, 0)
                TweenService:Create(page, TweenSmooth, {Position = UDim2.new(0, 0, 0, 0)}):Play()
            else
                page.Visible = false
            end
        end
    end

    function Window:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        local rawIcon = tabConfig.Icon
        local iconAssetId = Library:GetIcon(rawIcon)
        local hasIcon = (iconAssetId ~= nil and iconAssetId ~= "")
        local order = tabConfig.Order or (#TabButtonsLayout:GetChildren())

        -- Tab Button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = tabName .. "TabBtn"
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Library.Theme.CardBg
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.LayoutOrder = order
        TabBtn.Parent = TabButtonsLayout

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 10)
        Corner.Parent = TabBtn

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Library.Theme.CardBorder
        Stroke.Thickness = 1
        Stroke.Transparency = 1
        Stroke.Parent = TabBtn

        local TabIcon = nil
        if hasIcon then
            TabIcon = Instance.new("ImageLabel")
            TabIcon.Name = "TabIcon"
            TabIcon.Image = iconAssetId
            TabIcon.Size = UDim2.new(0, 17, 0, 17)
            TabIcon.Position = UDim2.new(0, 12, 0.5, 0)
            TabIcon.AnchorPoint = Vector2.new(0, 0.5)
            TabIcon.BackgroundTransparency = 1
            TabIcon.ImageColor3 = Library.Theme.TextSecondary
            TabIcon.Parent = TabBtn
        end

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TabLabel"
        TabLabel.Text = tabName
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Library.Theme.TextSecondary
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.BackgroundTransparency = 1
        TabLabel.Position = UDim2.new(0, hasIcon and 37 or 14, 0, 0)
        TabLabel.Size = UDim2.new(1, hasIcon and -45 or -22, 1, 0)
        TabLabel.Parent = TabBtn

        self.TabButtons[tabName] = {
            Frame = TabBtn,
            Label = TabLabel,
            Icon = TabIcon,
            Stroke = Stroke
        }

        TabBtn.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)

        TabBtn.MouseEnter:Connect(function()
            if self.CurrentTab ~= tabName then
                TweenService:Create(TabBtn, TweenFast, {BackgroundTransparency = 0.5, BackgroundColor3 = Library.Theme.HoverLight}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self.CurrentTab ~= tabName then
                TweenService:Create(TabBtn, TweenFast, {BackgroundTransparency = 1}):Play()
            end
        end)

        RegisterAccentListener(function(newColor)
            if self.CurrentTab == tabName then
                TweenService:Create(TabLabel, TweenFast, {TextColor3 = newColor}):Play()
                if TabIcon then
                    TweenService:Create(TabIcon, TweenFast, {ImageColor3 = newColor}):Play()
                end
            end
        end)

        -- Content Page
        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.Position = UDim2.new(0, 0, 0, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.BorderSizePixel = 0
        Page.ClipsDescendants = false
        Page.Visible = false
        Page.Parent = ContentArea

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 18)
        PagePadding.PaddingLeft = UDim.new(0, 18)
        PagePadding.PaddingRight = UDim.new(0, 18)
        PagePadding.PaddingBottom = UDim.new(0, 18)
        PagePadding.Parent = Page

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        self.Pages[tabName] = Page

        if not self.CurrentTab then
            self:SwitchTab(tabName)
        end

        local Tab = {
            Window = self,
            Page = Page,
            ZCounter = 30
        }

        -- Helper to create Base Row Card
        local function CreateBaseRow(title, desc, zIndex, height)
            local Row = Instance.new("TextButton")
            Row.Name = "RowCard"
            Row.Size = UDim2.new(1, 0, 0, height or 52)
            Row.BackgroundColor3 = Library.Theme.CardBg
            Row.BorderSizePixel = 0
            Row.AutoButtonColor = false
            Row.Text = ""
            Row.ClipsDescendants = false
            Row.ZIndex = zIndex or 1
            Row.Parent = Page

            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 12)
            RowCorner.Parent = Row

            local RowStroke = Instance.new("UIStroke")
            RowStroke.Color = Library.Theme.CardBorder
            RowStroke.Thickness = 1
            RowStroke.Transparency = 0.6
            RowStroke.Parent = Row

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Text = title or ""
            TitleLabel.Font = Enum.Font.GothamMedium
            TitleLabel.TextSize = 13.5
            TitleLabel.TextColor3 = Library.Theme.TextPrimary
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Position = UDim2.new(0, 16, 0, desc and 8 or 0)
            TitleLabel.Size = UDim2.new(1, -80, desc and 0.42 or 1, 0)
            TitleLabel.ZIndex = Row.ZIndex
            TitleLabel.Parent = Row

            if desc then
                local SubLabel = Instance.new("TextLabel")
                SubLabel.Text = desc
                SubLabel.Font = Enum.Font.Gotham
                SubLabel.TextSize = 11
                SubLabel.TextColor3 = Library.Theme.TextSecondary
                SubLabel.TextXAlignment = Enum.TextXAlignment.Left
                SubLabel.BackgroundTransparency = 1
                SubLabel.Position = UDim2.new(0, 16, 0, 27)
                SubLabel.Size = UDim2.new(1, -80, 0.36, 0)
                SubLabel.ZIndex = Row.ZIndex
                SubLabel.Parent = Row
            end

            Row.MouseEnter:Connect(function()
                TweenService:Create(Row, TweenFast, {BackgroundColor3 = Library.Theme.HoverLight}):Play()
                TweenService:Create(RowStroke, TweenFast, {Transparency = 0.2}):Play()
            end)
            Row.MouseLeave:Connect(function()
                TweenService:Create(Row, TweenFast, {BackgroundColor3 = Library.Theme.CardBg}):Play()
                TweenService:Create(RowStroke, TweenFast, {Transparency = 0.6}):Play()
            end)

            return Row, RowStroke, TitleLabel
        end

        -- Component: Toggle
        function Tab:AddToggle(toggleConfig)
            local title = toggleConfig.Title or "Toggle"
            local desc = toggleConfig.Desc
            local defaultState = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local row = CreateBaseRow(title, desc, 1)

            local Track = Instance.new("TextButton")
            Track.Name = "ToggleTrack"
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.Size = UDim2.new(0, 48, 0, 26)
            Track.AnchorPoint = Vector2.new(1, 0.5)
            Track.Position = UDim2.new(1, -16, 0.5, 0)
            Track.BackgroundColor3 = defaultState and currentAccent or Library.Theme.SwitchOff
            Track.BorderSizePixel = 0
            Track.Parent = row

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Knob = Instance.new("Frame")
            Knob.Name = "Knob"
            Knob.Size = UDim2.new(0, 20, 0, 20)
            Knob.AnchorPoint = Vector2.new(0, 0.5)
            Knob.Position = defaultState and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            Knob.BackgroundColor3 = Library.Theme.SwitchKnob
            Knob.BorderSizePixel = 0
            Knob.Parent = Track

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob

            local isEnabled = defaultState

            local function SetState(state, doCallback)
                isEnabled = state
                local targetColor = isEnabled and currentAccent or Library.Theme.SwitchOff
                local targetPos = isEnabled and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)

                TweenService:Create(Track, TweenFast, {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Knob, TweenSpring, {Position = targetPos}):Play()

                if doCallback ~= false then
                    pcall(callback, isEnabled)
                end
            end

            RegisterAccentListener(function(newColor)
                if isEnabled then
                    TweenService:Create(Track, TweenFast, {BackgroundColor3 = newColor}):Play()
                end
            end)

            Track.MouseButton1Click:Connect(function() SetState(not isEnabled) end)
            row.MouseButton1Click:Connect(function() SetState(not isEnabled) end)

            return {
                Set = SetState,
                Get = function() return isEnabled end,
                Row = row
            }
        end

        -- Component: Slider
        function Tab:AddSlider(sliderConfig)
            local title = sliderConfig.Title or "Slider"
            local desc = sliderConfig.Desc
            local minVal = sliderConfig.Min or 0
            local maxVal = sliderConfig.Max or 100
            local defaultVal = math.clamp(sliderConfig.Default or minVal, minVal, maxVal)
            local callback = sliderConfig.Callback or function() end

            local row = CreateBaseRow(title, desc, 1, 60)

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Name = "ValueLabel"
            ValueLabel.Text = tostring(defaultVal)
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextColor3 = currentAccent
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(1, -66, 0, 10)
            ValueLabel.Size = UDim2.new(0, 50, 0, 18)
            ValueLabel.Parent = row

            local SliderTrack = Instance.new("Frame")
            SliderTrack.Name = "SliderTrack"
            SliderTrack.Size = UDim2.new(1, -32, 0, 6)
            SliderTrack.Position = UDim2.new(0, 16, 1, -16)
            SliderTrack.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
            SliderTrack.BorderSizePixel = 0
            SliderTrack.Parent = row

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = SliderTrack

            local FillTrack = Instance.new("Frame")
            FillTrack.Name = "FillTrack"
            local initialPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
            FillTrack.Size = UDim2.new(initialPct, 0, 1, 0)
            FillTrack.BackgroundColor3 = currentAccent
            FillTrack.BorderSizePixel = 0
            FillTrack.Parent = SliderTrack

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = FillTrack

            local SliderKnob = Instance.new("Frame")
            SliderKnob.Name = "SliderKnob"
            SliderKnob.Size = UDim2.new(0, 18, 0, 18)
            SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderKnob.Position = UDim2.new(initialPct, 0, 0.5, 0)
            SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderKnob.BorderSizePixel = 0
            SliderKnob.Parent = SliderTrack

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = SliderKnob

            RegisterAccentListener(function(newColor)
                TweenService:Create(ValueLabel, TweenFast, {TextColor3 = newColor}):Play()
                TweenService:Create(FillTrack, TweenFast, {BackgroundColor3 = newColor}):Play()
            end)

            local currentVal = defaultVal
            local isSliding = false

            local function UpdateSlider(mouseX)
                local trackPos = SliderTrack.AbsolutePosition.X
                local trackWidth = SliderTrack.AbsoluteSize.X
                local pct = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
                local val = math.floor(minVal + (pct * (maxVal - minVal)))
                currentVal = val

                ValueLabel.Text = tostring(val)
                TweenService:Create(FillTrack, TweenInfo.new(0.06, Enum.EasingStyle.Linear), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                TweenService:Create(SliderKnob, TweenInfo.new(0.06, Enum.EasingStyle.Linear), {Position = UDim2.new(pct, 0, 0.5, 0)}):Play()

                pcall(callback, val)
            end

            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isSliding = true
                    TweenService:Create(SliderKnob, TweenFast, {Size = UDim2.new(0, 22, 0, 22)}):Play()
                    UpdateSlider(input.Position.X)
                end
            end)

            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input.Position.X)
                end
            end))

            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if isSliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    isSliding = false
                    TweenService:Create(SliderKnob, TweenFast, {Size = UDim2.new(0, 18, 0, 18)}):Play()
                end
            end))

            local function SetValue(val)
                currentVal = math.clamp(val, minVal, maxVal)
                local pct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
                ValueLabel.Text = tostring(currentVal)
                TweenService:Create(FillTrack, TweenFast, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                TweenService:Create(SliderKnob, TweenSpring, {Position = UDim2.new(pct, 0, 0.5, 0)}):Play()
                pcall(callback, currentVal)
            end

            return {
                Set = SetValue,
                Get = function() return currentVal end,
                Row = row
            }
        end

        -- Component: Button
        function Tab:AddButton(btnConfig)
            local title = btnConfig.Title or "Button"
            local desc = btnConfig.Desc
            local buttonText = btnConfig.ButtonText or "Click"
            local callback = btnConfig.Callback or function() end

            local row = CreateBaseRow(title, desc, 1)

            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Name = "ActionBtn"
            ActionBtn.Size = UDim2.new(0, 96, 0, 28)
            ActionBtn.AnchorPoint = Vector2.new(1, 0.5)
            ActionBtn.Position = UDim2.new(1, -16, 0.5, 0)
            ActionBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            ActionBtn.AutoButtonColor = false
            ActionBtn.Text = ""
            ActionBtn.Parent = row

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 8)
            Corner.Parent = ActionBtn

            local Stroke = Instance.new("UIStroke")
            Stroke.Color = Library.Theme.CardBorder
            Stroke.Thickness = 1
            Stroke.Transparency = 0.4
            Stroke.Parent = ActionBtn

            local Label = Instance.new("TextLabel")
            Label.Name = "BtnText"
            Label.Text = buttonText
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextColor3 = currentAccent
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.Parent = ActionBtn

            RegisterAccentListener(function(newColor)
                TweenService:Create(Label, TweenFast, {TextColor3 = newColor}):Play()
            end)

            ActionBtn.MouseEnter:Connect(function()
                TweenService:Create(ActionBtn, TweenFast, {BackgroundColor3 = Color3.fromRGB(46, 46, 56)}):Play()
            end)
            ActionBtn.MouseLeave:Connect(function()
                TweenService:Create(ActionBtn, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
            end)

            ActionBtn.MouseButton1Click:Connect(function()
                TweenService:Create(ActionBtn, TweenFast, {Size = UDim2.new(0, 92, 0, 26)}):Play()
                task.delay(0.08, function()
                    TweenService:Create(ActionBtn, TweenSpring, {Size = UDim2.new(0, 96, 0, 28)}):Play()
                end)
                pcall(callback)
            end)

            return {
                Row = row,
                Button = ActionBtn
            }
        end

        -- Component: Dropdown / Combo Box
        function Tab:AddDropdown(dropdownConfig)
            local title = dropdownConfig.Title or "Dropdown"
            local desc = dropdownConfig.Desc
            local options = dropdownConfig.Options or {}
            local defaultOption = dropdownConfig.Default or options[1] or "None"
            local callback = dropdownConfig.Callback or function() end

            Tab.ZCounter = Tab.ZCounter - 1
            local zIndex = Tab.ZCounter

            local row = CreateBaseRow(title, desc, zIndex)

            local ComboContainer = Instance.new("Frame")
            ComboContainer.Name = "ComboContainer"
            ComboContainer.Size = UDim2.new(0, 130, 0, 30)
            ComboContainer.AnchorPoint = Vector2.new(1, 0.5)
            ComboContainer.Position = UDim2.new(1, -16, 0.5, 0)
            ComboContainer.BackgroundTransparency = 1
            ComboContainer.ClipsDescendants = false
            ComboContainer.ZIndex = zIndex + 2
            ComboContainer.Parent = row

            local ComboMain = Instance.new("TextButton")
            ComboMain.Name = "ComboMain"
            ComboMain.Size = UDim2.new(1, 0, 1, 0)
            ComboMain.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            ComboMain.AutoButtonColor = false
            ComboMain.Text = ""
            ComboMain.ZIndex = zIndex + 3
            ComboMain.Parent = ComboContainer

            local ComboCorner = Instance.new("UICorner")
            ComboCorner.CornerRadius = UDim.new(0, 8)
            ComboCorner.Parent = ComboMain

            local ComboStroke = Instance.new("UIStroke")
            ComboStroke.Color = Library.Theme.CardBorder
            ComboStroke.Thickness = 1
            ComboStroke.Transparency = 0.4
            ComboStroke.Parent = ComboMain

            local CurrentLabel = Instance.new("TextLabel")
            CurrentLabel.Name = "CurrentLabel"
            CurrentLabel.Text = tostring(defaultOption)
            CurrentLabel.Font = Enum.Font.GothamMedium
            CurrentLabel.TextSize = 12
            CurrentLabel.TextColor3 = Library.Theme.TextPrimary
            CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
            CurrentLabel.BackgroundTransparency = 1
            CurrentLabel.Position = UDim2.new(0, 12, 0, 0)
            CurrentLabel.Size = UDim2.new(1, -38, 1, 0)
            CurrentLabel.ZIndex = zIndex + 4
            CurrentLabel.Parent = ComboMain

            local Chevron = Instance.new("ImageLabel")
            Chevron.Name = "Chevron"
            local chevIcon = Library:GetIcon("chevron-down")
            Chevron.Image = (chevIcon ~= "") and chevIcon or "rbxassetid://7733717447"
            Chevron.ImageColor3 = Library.Theme.TextSecondary
            Chevron.BackgroundTransparency = 1
            Chevron.AnchorPoint = Vector2.new(0.5, 0.5)
            Chevron.Position = UDim2.new(1, -14, 0.5, 0)
            Chevron.Size = UDim2.new(0, 16, 0, 16)
            Chevron.ZIndex = zIndex + 4
            Chevron.Parent = ComboMain

            local DropdownList = Instance.new("ScrollingFrame")
            DropdownList.Name = "DropdownList"
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Position = UDim2.new(0, 0, 1, 6)
            DropdownList.BackgroundColor3 = Library.Theme.DropdownBg
            DropdownList.BorderSizePixel = 0
            DropdownList.ScrollBarThickness = 3
            DropdownList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
            DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
            DropdownList.Visible = false
            DropdownList.ClipsDescendants = true
            DropdownList.ZIndex = zIndex + 15
            DropdownList.Parent = ComboContainer

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 10)
            DropCorner.Parent = DropdownList

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Library.Theme.CardBorder
            DropStroke.Thickness = 1
            DropStroke.Transparency = 0.25
            DropStroke.Parent = DropdownList

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)
            DropLayout.Parent = DropdownList

            local DropPadding = Instance.new("UIPadding")
            DropPadding.PaddingTop = UDim.new(0, 4)
            DropPadding.PaddingBottom = UDim.new(0, 4)
            DropPadding.PaddingLeft = UDim.new(0, 4)
            DropPadding.PaddingRight = UDim.new(0, 4)
            DropPadding.Parent = DropdownList

            local isOpen = false
            local selectedVal = defaultOption
            local optionButtons = {}

            local function CloseDrop()
                if not isOpen then return end
                isOpen = false
                TweenService:Create(Chevron, TweenFast, {Rotation = 0}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
                local t = TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, 0)
                })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then DropdownList.Visible = false end
                end)
            end

            local function OpenDrop()
                if isOpen then return end
                isOpen = true
                DropdownList.Visible = true
                TweenService:Create(Chevron, TweenFast, {Rotation = 180}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(44, 44, 52)}):Play()
                local targetH = math.min(#options * 30 + 8, 160)
                TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, targetH)
                }):Play()
            end

            local function SelectOption(opt)
                selectedVal = opt
                CurrentLabel.Text = tostring(opt)
                for itemOpt, label in pairs(optionButtons) do
                    local isSel = (itemOpt == opt)
                    TweenService:Create(label, TweenFast, {TextColor3 = isSel and currentAccent or Library.Theme.TextPrimary}):Play()
                end
                CloseDrop()
                pcall(callback, opt)
            end

            local function RefreshOptions(newOptions)
                options = newOptions
                for _, child in ipairs(DropdownList:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                table.clear(optionButtons)

                for idx, optName in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Name = "Opt_" .. tostring(optName)
                    OptBtn.Size = UDim2.new(1, 0, 0, 28)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.AutoButtonColor = false
                    OptBtn.Text = ""
                    OptBtn.LayoutOrder = idx
                    OptBtn.ZIndex = zIndex + 16
                    OptBtn.Parent = DropdownList

                    local OptCorner = Instance.new("UICorner")
                    OptCorner.CornerRadius = UDim.new(0, 6)
                    OptCorner.Parent = OptBtn

                    local OptLabel = Instance.new("TextLabel")
                    OptLabel.Text = tostring(optName)
                    OptLabel.Font = Enum.Font.GothamMedium
                    OptLabel.TextSize = 12
                    OptLabel.TextColor3 = (optName == selectedVal) and currentAccent or Library.Theme.TextPrimary
                    OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                    OptLabel.BackgroundTransparency = 1
                    OptLabel.Position = UDim2.new(0, 10, 0, 0)
                    OptLabel.Size = UDim2.new(1, -20, 1, 0)
                    OptLabel.ZIndex = zIndex + 17
                    OptLabel.Parent = OptBtn

                    optionButtons[optName] = OptLabel

                    OptBtn.MouseEnter:Connect(function()
                        TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 0, BackgroundColor3 = Library.Theme.HoverLight}):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 1}):Play()
                    end)
                    OptBtn.MouseButton1Click:Connect(function()
                        SelectOption(optName)
                    end)
                    OptBtn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            SelectOption(optName)
                        end
                    end)
                end

                if isOpen then
                    local targetH = math.min(#options * 30 + 8, 160)
                    TweenService:Create(DropdownList, TweenFast, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
                end
            end

            RefreshOptions(options)

            ComboMain.MouseButton1Click:Connect(function()
                if isOpen then CloseDrop() else OpenDrop() end
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
                if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    task.defer(function()
                        if not isOpen then return end
                        local mousePos = UserInputService:GetMouseLocation()
                        local cPos = ComboContainer.AbsolutePosition
                        local cSize = ComboContainer.AbsoluteSize
                        local dPos = DropdownList.AbsolutePosition
                        local dSize = DropdownList.AbsoluteSize

                        local inCombo = (mousePos.X >= cPos.X and mousePos.X <= cPos.X + cSize.X and mousePos.Y >= cPos.Y and mousePos.Y <= cPos.Y + cSize.Y)
                        local inDrop = (mousePos.X >= dPos.X and mousePos.X <= dPos.X + dSize.X and mousePos.Y >= dPos.Y and mousePos.Y <= dPos.Y + dSize.Y)

                        if not inCombo and not inDrop then
                            CloseDrop()
                        end
                    end)
                end
            end))

            return {
                Select = SelectOption,
                Get = function() return selectedVal end,
                Refresh = RefreshOptions,
                Row = row
            }
        end

        -- Component: Accent Color Picker (iOS 18 Palette)
        function Tab:AddAccentPicker(accentConfig)
            local title = accentConfig.Title or "Accent Color"
            local desc = accentConfig.Desc
            local defaultColorName = accentConfig.Default or "Blue"
            local callback = accentConfig.Callback or function() end

            Tab.ZCounter = Tab.ZCounter - 1
            local zIndex = Tab.ZCounter

            local row = CreateBaseRow(title, desc, zIndex)

            local ComboContainer = Instance.new("Frame")
            ComboContainer.Name = "AccentPickerContainer"
            ComboContainer.Size = UDim2.new(0, 140, 0, 30)
            ComboContainer.AnchorPoint = Vector2.new(1, 0.5)
            ComboContainer.Position = UDim2.new(1, -16, 0.5, 0)
            ComboContainer.BackgroundTransparency = 1
            ComboContainer.ClipsDescendants = false
            ComboContainer.ZIndex = zIndex + 2
            ComboContainer.Parent = row

            local ComboMain = Instance.new("TextButton")
            ComboMain.Name = "ComboMain"
            ComboMain.Size = UDim2.new(1, 0, 1, 0)
            ComboMain.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            ComboMain.AutoButtonColor = false
            ComboMain.Text = ""
            ComboMain.ZIndex = zIndex + 3
            ComboMain.Parent = ComboContainer

            local ComboCorner = Instance.new("UICorner")
            ComboCorner.CornerRadius = UDim.new(0, 8)
            ComboCorner.Parent = ComboMain

            local ComboStroke = Instance.new("UIStroke")
            ComboStroke.Color = Library.Theme.CardBorder
            ComboStroke.Thickness = 1
            ComboStroke.Transparency = 0.4
            ComboStroke.Parent = ComboMain

            -- Preview dot for currently selected color
            local SelectedDot = Instance.new("Frame")
            SelectedDot.Name = "SelectedDot"
            SelectedDot.Size = UDim2.new(0, 10, 0, 10)
            SelectedDot.AnchorPoint = Vector2.new(0, 0.5)
            SelectedDot.Position = UDim2.new(0, 12, 0.5, 0)
            SelectedDot.BackgroundColor3 = currentAccent
            SelectedDot.BorderSizePixel = 0
            SelectedDot.ZIndex = zIndex + 4
            SelectedDot.Parent = ComboMain

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = SelectedDot

            local CurrentLabel = Instance.new("TextLabel")
            CurrentLabel.Name = "CurrentLabel"
            CurrentLabel.Text = tostring(defaultColorName)
            CurrentLabel.Font = Enum.Font.GothamMedium
            CurrentLabel.TextSize = 12
            CurrentLabel.TextColor3 = Library.Theme.TextPrimary
            CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
            CurrentLabel.BackgroundTransparency = 1
            CurrentLabel.Position = UDim2.new(0, 30, 0, 0)
            CurrentLabel.Size = UDim2.new(1, -56, 1, 0)
            CurrentLabel.ZIndex = zIndex + 4
            CurrentLabel.Parent = ComboMain

            local Chevron = Instance.new("ImageLabel")
            Chevron.Name = "Chevron"
            local chevIcon = Library:GetIcon("chevron-down")
            Chevron.Image = (chevIcon ~= "") and chevIcon or "rbxassetid://7733717447"
            Chevron.ImageColor3 = Library.Theme.TextSecondary
            Chevron.BackgroundTransparency = 1
            Chevron.AnchorPoint = Vector2.new(0.5, 0.5)
            Chevron.Position = UDim2.new(1, -14, 0.5, 0)
            Chevron.Size = UDim2.new(0, 16, 0, 16)
            Chevron.ZIndex = zIndex + 4
            Chevron.Parent = ComboMain

            local DropdownList = Instance.new("CanvasGroup")
            DropdownList.Name = "DropdownList"
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Position = UDim2.new(0, 0, 1, 6)
            DropdownList.BackgroundColor3 = Library.Theme.DropdownBg
            DropdownList.BorderSizePixel = 0
            DropdownList.GroupTransparency = 1
            DropdownList.Visible = false
            DropdownList.ZIndex = zIndex + 15
            DropdownList.Parent = ComboContainer

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 10)
            DropCorner.Parent = DropdownList

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Library.Theme.CardBorder
            DropStroke.Thickness = 1
            DropStroke.Transparency = 0.25
            DropStroke.Parent = DropdownList

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)
            DropLayout.Parent = DropdownList

            local DropPadding = Instance.new("UIPadding")
            DropPadding.PaddingTop = UDim.new(0, 4)
            DropPadding.PaddingBottom = UDim.new(0, 4)
            DropPadding.PaddingLeft = UDim.new(0, 4)
            DropPadding.PaddingRight = UDim.new(0, 4)
            DropPadding.Parent = DropdownList

            local isOpen = false
            local selectedColorName = defaultColorName
            local selectedColorVal = currentAccent
            local optionButtons = {}

            local function CloseDrop()
                if not isOpen then return end
                isOpen = false
                TweenService:Create(Chevron, TweenFast, {Rotation = 0}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
                local t = TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, 0),
                    GroupTransparency = 1
                })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then DropdownList.Visible = false end
                end)
            end

            local function OpenDrop()
                if isOpen then return end
                isOpen = true
                DropdownList.Visible = true
                TweenService:Create(Chevron, TweenFast, {Rotation = 180}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(44, 44, 52)}):Play()
                local targetH = math.min(#Library.AccentColors * 30 + 8, 220)
                TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, targetH),
                    GroupTransparency = 0
                }):Play()
            end

            local function SelectColor(colItem)
                selectedColorName = colItem.Name
                selectedColorVal = colItem.Color
                CurrentLabel.Text = colItem.Name
                SelectedDot.BackgroundColor3 = colItem.Color

                for name, item in pairs(optionButtons) do
                    local isSel = (name == colItem.Name)
                    TweenService:Create(item.Label, TweenFast, {TextColor3 = isSel and colItem.Color or Library.Theme.TextPrimary}):Play()
                end

                Window:SetAccent(colItem.Color)
                CloseDrop()
                pcall(callback, colItem.Color, colItem.Name)
            end

            for idx, colItem in ipairs(Library.AccentColors) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Name = "Opt_" .. colItem.Name
                OptBtn.Size = UDim2.new(1, 0, 0, 26)
                OptBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                OptBtn.BackgroundTransparency = 1
                OptBtn.AutoButtonColor = false
                OptBtn.Text = ""
                OptBtn.LayoutOrder = idx
                OptBtn.ZIndex = zIndex + 16
                OptBtn.Parent = DropdownList

                local OptCorner = Instance.new("UICorner")
                OptCorner.CornerRadius = UDim.new(0, 6)
                OptCorner.Parent = OptBtn

                local OptDot = Instance.new("Frame")
                OptDot.Name = "Dot"
                OptDot.Size = UDim2.new(0, 10, 0, 10)
                OptDot.AnchorPoint = Vector2.new(0, 0.5)
                OptDot.Position = UDim2.new(0, 10, 0.5, 0)
                OptDot.BackgroundColor3 = colItem.Color
                OptDot.BorderSizePixel = 0
                OptDot.ZIndex = zIndex + 17
                OptDot.Parent = OptBtn

                local ODCorner = Instance.new("UICorner")
                ODCorner.CornerRadius = UDim.new(1, 0)
                ODCorner.Parent = OptDot

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Text = colItem.Name
                OptLabel.Font = Enum.Font.GothamMedium
                OptLabel.TextSize = 12
                OptLabel.TextColor3 = (colItem.Name == defaultColorName) and colItem.Color or Library.Theme.TextPrimary
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.BackgroundTransparency = 1
                OptLabel.Position = UDim2.new(0, 28, 0, 0)
                OptLabel.Size = UDim2.new(1, -34, 1, 0)
                OptLabel.ZIndex = zIndex + 17
                OptLabel.Parent = OptBtn

                optionButtons[colItem.Name] = {Button = OptBtn, Label = OptLabel, Dot = OptDot}

                OptBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 0, BackgroundColor3 = Library.Theme.HoverLight}):Play()
                end)
                OptBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 1}):Play()
                end)

                OptBtn.MouseButton1Click:Connect(function()
                    SelectColor(colItem)
                end)
                OptBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        SelectColor(colItem)
                    end
                end)
            end

            ComboMain.MouseButton1Click:Connect(function()
                if isOpen then CloseDrop() else OpenDrop() end
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
                if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    task.defer(function()
                        if not isOpen then return end
                        local mousePos = UserInputService:GetMouseLocation()
                        local cPos = ComboContainer.AbsolutePosition
                        local cSize = ComboContainer.AbsoluteSize
                        local dPos = DropdownList.AbsolutePosition
                        local dSize = DropdownList.AbsoluteSize

                        local inCombo = (mousePos.X >= cPos.X and mousePos.X <= cPos.X + cSize.X and mousePos.Y >= cPos.Y and mousePos.Y <= cPos.Y + cSize.Y)
                        local inDrop = (mousePos.X >= dPos.X and mousePos.X <= dPos.X + dSize.X and mousePos.Y >= dPos.Y and mousePos.Y <= dPos.Y + dSize.Y)

                        if not inCombo and not inDrop then
                            CloseDrop()
                        end
                    end)
                end
            end))

            RegisterAccentListener(function(newColor)
                SelectedDot.BackgroundColor3 = newColor
            end)

            return {
                Select = function(self, colNameOrColor)
                    for _, c in ipairs(Library.AccentColors) do
                        if c.Name == colNameOrColor or c.Color == colNameOrColor then
                            SelectColor(c)
                            return
                        end
                    end
                end,
                Get = function()
                    return selectedColorVal, selectedColorName
                end,
                Row = row
            }
        end

        -- Component: Keybind Selector
        function Tab:AddKeybind(keybindConfig)
            local title = keybindConfig.Title or "Keybind"
            local desc = keybindConfig.Desc
            local defaultKey = keybindConfig.Default or Enum.KeyCode.E
            local callback = keybindConfig.Callback or function() end

            local row = CreateBaseRow(title, desc, 1)

            local KeybindBtn = Instance.new("TextButton")
            KeybindBtn.Name = "KeybindBtn"
            KeybindBtn.Size = UDim2.new(0, 110, 0, 30)
            KeybindBtn.AnchorPoint = Vector2.new(1, 0.5)
            KeybindBtn.Position = UDim2.new(1, -16, 0.5, 0)
            KeybindBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            KeybindBtn.AutoButtonColor = false
            KeybindBtn.Text = ""
            KeybindBtn.Parent = row

            local KeyCorner = Instance.new("UICorner")
            KeyCorner.CornerRadius = UDim.new(0, 8)
            KeyCorner.Parent = KeybindBtn

            local KeyStroke = Instance.new("UIStroke")
            KeyStroke.Color = Library.Theme.CardBorder
            KeyStroke.Thickness = 1
            KeyStroke.Transparency = 0.4
            KeyStroke.Parent = KeybindBtn

            local KeyLabel = Instance.new("TextLabel")
            KeyLabel.Name = "KeyText"
            KeyLabel.Text = defaultKey.Name
            KeyLabel.Font = Enum.Font.GothamMedium
            KeyLabel.TextSize = 13
            KeyLabel.TextColor3 = currentAccent
            KeyLabel.BackgroundTransparency = 1
            KeyLabel.Size = UDim2.new(1, 0, 1, 0)
            KeyLabel.Parent = KeybindBtn

            local DotsFrame = Instance.new("Frame")
            DotsFrame.Name = "DotsFrame"
            DotsFrame.Size = UDim2.new(1, 0, 1, 0)
            DotsFrame.BackgroundTransparency = 1
            DotsFrame.Visible = false
            DotsFrame.Parent = KeybindBtn

            local DotsLayout = Instance.new("UIListLayout")
            DotsLayout.FillDirection = Enum.FillDirection.Horizontal
            DotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            DotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            DotsLayout.Padding = UDim.new(0, 5)
            DotsLayout.Parent = DotsFrame

            local dots = {}
            for i = 1, 3 do
                local dot = Instance.new("Frame")
                dot.Name = "Dot" .. i
                dot.Size = UDim2.new(0, 5, 0, 5)
                dot.BackgroundColor3 = currentAccent
                dot.BorderSizePixel = 0
                dot.Parent = DotsFrame

                local dCorner = Instance.new("UICorner")
                dCorner.CornerRadius = UDim.new(1, 0)
                dCorner.Parent = dot
                table.insert(dots, dot)
            end

            RegisterAccentListener(function(newColor)
                TweenService:Create(KeyLabel, TweenFast, {TextColor3 = newColor}):Play()
                for _, dot in ipairs(dots) do
                    TweenService:Create(dot, TweenFast, {BackgroundColor3 = newColor}):Play()
                end
            end)

            local currentKey = defaultKey
            local listening = false
            local dotLoop = nil

            local function StartAnimation()
                listening = true
                KeyLabel.Visible = false
                DotsFrame.Visible = true

                TweenService:Create(KeybindBtn, TweenFast, {BackgroundColor3 = Color3.fromRGB(45, 45, 56)}):Play()
                TweenService:Create(KeyStroke, TweenFast, {Color = currentAccent, Transparency = 0.1}):Play()

                if dotLoop then dotLoop:Disconnect() end
                local tickCount = 0
                dotLoop = RunService.RenderStepped:Connect(function(dt)
                    tickCount = tickCount + dt * 6
                    for i, dot in ipairs(dots) do
                        local wave = (math.sin(tickCount - (i * 0.8)) + 1) / 2
                        dot.BackgroundTransparency = 0.2 + (0.7 * (1 - wave))
                        local s = 4 + (wave * 2.5)
                        dot.Size = UDim2.new(0, s, 0, s)
                    end
                end)
            end

            local function StopAnimation(newKey)
                listening = false
                if dotLoop then
                    dotLoop:Disconnect()
                    dotLoop = nil
                end
                DotsFrame.Visible = false
                KeyLabel.Visible = true
                if newKey then
                    currentKey = newKey
                    KeyLabel.Text = newKey.Name
                    pcall(callback, newKey)
                else
                    KeyLabel.Text = currentKey.Name
                end

                TweenService:Create(KeybindBtn, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
                TweenService:Create(KeyStroke, TweenFast, {Color = Library.Theme.CardBorder, Transparency = 0.4}):Play()
            end

            KeybindBtn.MouseButton1Click:Connect(function()
                if not listening then StartAnimation() end
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        StopAnimation(input.KeyCode)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                        StopAnimation(nil)
                    end
                end
            end))

            return {
                Set = function(key) StopAnimation(key) end,
                Get = function() return currentKey end,
                Row = row
            }
        end

        -- Component: TextInput
        function Tab:AddTextInput(inputConfig)
            local title = inputConfig.Title or "Input"
            local desc = inputConfig.Desc
            local placeholder = inputConfig.Placeholder or "Type here..."
            local defaultVal = inputConfig.Default or ""
            local callback = inputConfig.Callback or function() end

            local row = CreateBaseRow(title, desc, 1)

            local InputContainer = Instance.new("Frame")
            InputContainer.Name = "InputContainer"
            InputContainer.Size = UDim2.new(0, 130, 0, 30)
            InputContainer.AnchorPoint = Vector2.new(1, 0.5)
            InputContainer.Position = UDim2.new(1, -16, 0.5, 0)
            InputContainer.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            InputContainer.BorderSizePixel = 0
            InputContainer.Parent = row

            local InCorner = Instance.new("UICorner")
            InCorner.CornerRadius = UDim.new(0, 8)
            InCorner.Parent = InputContainer

            local InStroke = Instance.new("UIStroke")
            InStroke.Color = Library.Theme.CardBorder
            InStroke.Thickness = 1
            InStroke.Transparency = 0.4
            InStroke.Parent = InputContainer

            local TextBox = Instance.new("TextBox")
            TextBox.Name = "Box"
            TextBox.Text = defaultVal
            TextBox.PlaceholderText = placeholder
            TextBox.PlaceholderColor3 = Library.Theme.TextSecondary
            TextBox.TextColor3 = Library.Theme.TextPrimary
            TextBox.Font = Enum.Font.GothamMedium
            TextBox.TextSize = 12
            TextBox.BackgroundTransparency = 1
            TextBox.Position = UDim2.new(0, 10, 0, 0)
            TextBox.Size = UDim2.new(1, -20, 1, 0)
            TextBox.ClearTextOnFocus = false
            TextBox.TextXAlignment = Enum.TextXAlignment.Left
            TextBox.Parent = InputContainer

            TextBox.Focused:Connect(function()
                TweenService:Create(InStroke, TweenFast, {Color = currentAccent, Transparency = 0.1}):Play()
            end)
            TextBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(InStroke, TweenFast, {Color = Library.Theme.CardBorder, Transparency = 0.4}):Play()
                pcall(callback, TextBox.Text, enterPressed)
            end)

            return {
                Set = function(t) TextBox.Text = tostring(t) end,
                Get = function() return TextBox.Text end,
                Row = row
            }
        end

        -- ==========================================
        -- Tab Component: CreateSearchBar
        -- ==========================================
        function Tab:CreateSearchBar(searchConfig)
            local placeholder = searchConfig.Placeholder or "Search..."
            local callback = searchConfig.Callback or function() end
            local layoutOrder = searchConfig.LayoutOrder or 1

            local SearchBarFrame = Instance.new("Frame")
            SearchBarFrame.Name = "SearchBarFrame"
            SearchBarFrame.Size = UDim2.new(1, 0, 0, 36)
            SearchBarFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
            SearchBarFrame.BorderSizePixel = 0
            SearchBarFrame.LayoutOrder = layoutOrder
            SearchBarFrame.Parent = Page

            local SearchCorner = Instance.new("UICorner")
            SearchCorner.CornerRadius = UDim.new(0, 10)
            SearchCorner.Parent = SearchBarFrame

            local SearchIcon = Instance.new("ImageLabel")
            SearchIcon.Name = "SearchIcon"
            SearchIcon.Size = UDim2.new(0, 16, 0, 16)
            SearchIcon.Position = UDim2.new(0, 12, 0.5, 0)
            SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
            SearchIcon.BackgroundTransparency = 1
            local sIcon = Library:GetIcon("search")
            SearchIcon.Image = (sIcon ~= "") and sIcon or "rbxassetid://10734943674"
            SearchIcon.ImageColor3 = Library.Theme.TextSecondary
            SearchIcon.Parent = SearchBarFrame

            local SearchInput = Instance.new("TextBox")
            SearchInput.Name = "SearchInput"
            SearchInput.Size = UDim2.new(1, -40, 1, 0)
            SearchInput.Position = UDim2.new(0, 34, 0, 0)
            SearchInput.BackgroundTransparency = 1
            SearchInput.Font = Enum.Font.GothamMedium
            SearchInput.TextSize = 12
            SearchInput.TextColor3 = Library.Theme.TextPrimary
            SearchInput.PlaceholderText = placeholder
            SearchInput.PlaceholderColor3 = Library.Theme.TextSecondary
            SearchInput.ClearTextOnFocus = false
            SearchInput.TextXAlignment = Enum.TextXAlignment.Left
            SearchInput.Text = ""
            SearchInput.Parent = SearchBarFrame

            SearchInput.Focused:Connect(function()
                TweenService:Create(SearchBarFrame, TweenFast, {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 38)
                }):Play()
                TweenService:Create(SearchIcon, TweenFast, {
                    ImageColor3 = currentAccent
                }):Play()
            end)

            SearchInput.FocusLost:Connect(function()
                TweenService:Create(SearchBarFrame, TweenFast, {
                    BackgroundColor3 = Color3.fromRGB(24, 24, 30)
                }):Play()
                TweenService:Create(SearchIcon, TweenFast, {
                    ImageColor3 = Library.Theme.TextSecondary
                }):Play()
            end)

            SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
                pcall(callback, SearchInput.Text)
            end)

            return {
                Get = function() return SearchInput.Text end,
                Set = function(newText) SearchInput.Text = tostring(newText or "") end,
                Clear = function() SearchInput.Text = "" end,
                Frame = SearchBarFrame,
                Box = SearchInput
            }
        end

        -- ==========================================
        -- Tab Component: AddMultiDropdown
        -- Multi-selection dropdown with toggle items & count label
        -- ==========================================
        function Tab:AddMultiDropdown(multiConfig)
            local title = multiConfig.Title or "Multi Dropdown"
            local desc = multiConfig.Desc
            local options = multiConfig.Options or {}
            local defaultSelected = multiConfig.Default or {}
            local callback = multiConfig.Callback or function() end

            Tab.ZCounter = Tab.ZCounter - 1
            local zIndex = Tab.ZCounter

            local row = CreateBaseRow(title, desc, zIndex)

            local selectedMap = {}
            for _, item in ipairs(defaultSelected) do
                selectedMap[item] = true
            end

            local ComboContainer = Instance.new("Frame")
            ComboContainer.Name = "MultiComboContainer"
            ComboContainer.Size = UDim2.new(0, 150, 0, 30)
            ComboContainer.AnchorPoint = Vector2.new(1, 0.5)
            ComboContainer.Position = UDim2.new(1, -16, 0.5, 0)
            ComboContainer.BackgroundTransparency = 1
            ComboContainer.ClipsDescendants = false
            ComboContainer.ZIndex = zIndex + 2
            ComboContainer.Parent = row

            local ComboMain = Instance.new("TextButton")
            ComboMain.Name = "ComboMain"
            ComboMain.Size = UDim2.new(1, 0, 1, 0)
            ComboMain.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            ComboMain.AutoButtonColor = false
            ComboMain.Text = ""
            ComboMain.ZIndex = zIndex + 3
            ComboMain.Parent = ComboContainer

            local ComboCorner = Instance.new("UICorner")
            ComboCorner.CornerRadius = UDim.new(0, 8)
            ComboCorner.Parent = ComboMain

            local ComboStroke = Instance.new("UIStroke")
            ComboStroke.Color = Library.Theme.CardBorder
            ComboStroke.Thickness = 1
            ComboStroke.Transparency = 0.4
            ComboStroke.Parent = ComboMain

            local CurrentLabel = Instance.new("TextLabel")
            CurrentLabel.Name = "CurrentLabel"
            CurrentLabel.Font = Enum.Font.GothamMedium
            CurrentLabel.TextSize = 11.5
            CurrentLabel.TextColor3 = Library.Theme.TextPrimary
            CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
            CurrentLabel.BackgroundTransparency = 1
            CurrentLabel.Position = UDim2.new(0, 10, 0, 0)
            CurrentLabel.Size = UDim2.new(1, -34, 1, 0)
            CurrentLabel.ZIndex = zIndex + 4
            CurrentLabel.Parent = ComboMain

            local Chevron = Instance.new("ImageLabel")
            Chevron.Name = "Chevron"
            local chevIcon = Library:GetIcon("chevron-down")
            Chevron.Image = (chevIcon ~= "") and chevIcon or "rbxassetid://7733717447"
            Chevron.ImageColor3 = Library.Theme.TextSecondary
            Chevron.BackgroundTransparency = 1
            Chevron.AnchorPoint = Vector2.new(0.5, 0.5)
            Chevron.Position = UDim2.new(1, -12, 0.5, 0)
            Chevron.Size = UDim2.new(0, 14, 0, 14)
            Chevron.ZIndex = zIndex + 4
            Chevron.Parent = ComboMain

            local DropdownList = Instance.new("CanvasGroup")
            DropdownList.Name = "DropdownList"
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Position = UDim2.new(0, 0, 1, 6)
            DropdownList.BackgroundColor3 = Library.Theme.DropdownBg
            DropdownList.BorderSizePixel = 0
            DropdownList.GroupTransparency = 1
            DropdownList.Visible = false
            DropdownList.ZIndex = zIndex + 15
            DropdownList.Parent = ComboContainer

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 10)
            DropCorner.Parent = DropdownList

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Library.Theme.CardBorder
            DropStroke.Thickness = 1
            DropStroke.Transparency = 0.25
            DropStroke.Parent = DropdownList

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Name = "Scroll"
            Scroll.Size = UDim2.new(1, 0, 1, 0)
            Scroll.BackgroundTransparency = 1
            Scroll.BorderSizePixel = 0
            Scroll.ScrollBarThickness = 3
            Scroll.ScrollBarImageColor3 = Library.Theme.CardBorder
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Scroll.ZIndex = zIndex + 16
            Scroll.Parent = DropdownList

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)
            DropLayout.Parent = Scroll

            local DropPadding = Instance.new("UIPadding")
            DropPadding.PaddingTop = UDim.new(0, 4)
            DropPadding.PaddingBottom = UDim.new(0, 4)
            DropPadding.PaddingLeft = UDim.new(0, 4)
            DropPadding.PaddingRight = UDim.new(0, 4)
            DropPadding.Parent = Scroll

            local isOpen = false
            local itemWidgets = {}

            local function UpdateCountLabel()
                local count = 0
                for _, sel in pairs(selectedMap) do
                    if sel then count = count + 1 end
                end
                if count == 0 then
                    CurrentLabel.Text = "0 Selected"
                    CurrentLabel.TextColor3 = Library.Theme.TextSecondary
                else
                    CurrentLabel.Text = count .. " Selected"
                    CurrentLabel.TextColor3 = currentAccent
                end
            end

            local function CloseDrop()
                if not isOpen then return end
                isOpen = false
                TweenService:Create(Chevron, TweenFast, {Rotation = 0}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
                local t = TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, 0),
                    GroupTransparency = 1
                })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then DropdownList.Visible = false end
                end)
            end

            local function OpenDrop()
                if isOpen then return end
                isOpen = true
                DropdownList.Visible = true
                TweenService:Create(Chevron, TweenFast, {Rotation = 180}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(44, 44, 52)}):Play()
                local visibleCount = math.min(#options, 6)
                local targetH = (visibleCount * 30) + 8
                TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, targetH),
                    GroupTransparency = 0
                }):Play()
            end

            local function RefreshOptions(newOptions)
                options = newOptions
                for _, child in ipairs(Scroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                table.clear(itemWidgets)

                for idx, optName in ipairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Name = "Opt_" .. tostring(optName)
                    OptBtn.Size = UDim2.new(1, 0, 0, 26)
                    OptBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.AutoButtonColor = false
                    OptBtn.Text = ""
                    OptBtn.LayoutOrder = idx
                    OptBtn.ZIndex = zIndex + 17
                    OptBtn.Parent = Scroll

                    local OptCorner = Instance.new("UICorner")
                    OptCorner.CornerRadius = UDim.new(0, 6)
                    OptCorner.Parent = OptBtn

                    local OptLabel = Instance.new("TextLabel")
                    OptLabel.Text = tostring(optName)
                    OptLabel.Font = Enum.Font.GothamMedium
                    OptLabel.TextSize = 12
                    OptLabel.TextColor3 = (selectedMap[optName] == true) and currentAccent or Library.Theme.TextPrimary
                    OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                    OptLabel.BackgroundTransparency = 1
                    OptLabel.Position = UDim2.new(0, 10, 0, 0)
                    OptLabel.Size = UDim2.new(1, -20, 1, 0)
                    OptLabel.ZIndex = zIndex + 18
                    OptLabel.Parent = OptBtn

                    itemWidgets[optName] = {Btn = OptBtn, Label = OptLabel}

                    OptBtn.MouseEnter:Connect(function()
                        TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 0, BackgroundColor3 = Library.Theme.HoverLight}):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        TweenService:Create(OptBtn, TweenFast, {BackgroundTransparency = 1}):Play()
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        selectedMap[optName] = not selectedMap[optName]
                        local isSel = selectedMap[optName] == true
                        TweenService:Create(OptLabel, TweenFast, {
                            TextColor3 = isSel and currentAccent or Library.Theme.TextPrimary
                        }):Play()
                        UpdateCountLabel()
                        local selectedList = {}
                        for k, v in pairs(selectedMap) do
                            if v then table.insert(selectedList, k) end
                        end
                        pcall(callback, selectedList, optName, isSel)
                    end)
                end
                UpdateCountLabel()
            end

            RefreshOptions(options)

            RegisterAccentListener(function(newColor)
                UpdateCountLabel()
                for optName, data in pairs(itemWidgets) do
                    if selectedMap[optName] == true then
                        TweenService:Create(data.Label, TweenFast, {TextColor3 = newColor}):Play()
                    end
                end
            end)

            ComboMain.MouseButton1Click:Connect(function()
                if isOpen then CloseDrop() else OpenDrop() end
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
                if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = ComboContainer.AbsolutePosition
                    local size = ComboContainer.AbsoluteSize
                    local dropH = DropdownList.AbsoluteSize.Y
                    if mousePos.X < pos.X or mousePos.X > pos.X + size.X or mousePos.Y < pos.Y or mousePos.Y > pos.Y + dropH + 10 then
                        CloseDrop()
                    end
                end
            end))

            return {
                Get = function()
                    local list = {}
                    for k, v in pairs(selectedMap) do
                        if v then table.insert(list, k) end
                    end
                    return list
                end,
                Set = function(newSelectedList)
                    table.clear(selectedMap)
                    for _, k in ipairs(newSelectedList or {}) do
                        selectedMap[k] = true
                    end
                    for optName, data in pairs(itemWidgets) do
                        local isSel = (selectedMap[optName] == true)
                        data.Label.TextColor3 = isSel and currentAccent or Library.Theme.TextPrimary
                    end
                    UpdateCountLabel()
                end,
                Refresh = RefreshOptions,
                Row = row
            }
        end

        -- ==========================================
        -- Tab Component: AddAccentPicker
        -- iOS 18 Color Palette picker with live preview dot and dynamic retinting
        -- ==========================================
        function Tab:AddAccentPicker(pickerConfig)
            pickerConfig = pickerConfig or {}
            local title = pickerConfig.Title or "Accent Color"
            local desc = pickerConfig.Desc or "Change menu theme highlight color"
            local defaultColorName = pickerConfig.Default or "Blue"
            local callback = pickerConfig.Callback or function() end

            Tab.ZCounter = Tab.ZCounter - 1
            local zIndex = Tab.ZCounter

            local row = CreateBaseRow(title, desc, zIndex)

            local ComboContainer = Instance.new("Frame")
            ComboContainer.Name = "AccentComboContainer"
            ComboContainer.Size = UDim2.new(0, 130, 0, 30)
            ComboContainer.AnchorPoint = Vector2.new(1, 0.5)
            ComboContainer.Position = UDim2.new(1, -16, 0.5, 0)
            ComboContainer.BackgroundTransparency = 1
            ComboContainer.ClipsDescendants = false
            ComboContainer.ZIndex = zIndex + 2
            ComboContainer.Parent = row

            local ComboMain = Instance.new("TextButton")
            ComboMain.Name = "ComboMain"
            ComboMain.Size = UDim2.new(1, 0, 1, 0)
            ComboMain.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            ComboMain.AutoButtonColor = false
            ComboMain.Text = ""
            ComboMain.ZIndex = zIndex + 3
            ComboMain.Parent = ComboContainer

            local ComboCorner = Instance.new("UICorner")
            ComboCorner.CornerRadius = UDim.new(0, 8)
            ComboCorner.Parent = ComboMain

            local ComboStroke = Instance.new("UIStroke")
            ComboStroke.Color = Library.Theme.CardBorder
            ComboStroke.Thickness = 1
            ComboStroke.Transparency = 0.4
            ComboStroke.Parent = ComboMain

            local ColorDotPreview = Instance.new("Frame")
            ColorDotPreview.Name = "ColorDotPreview"
            ColorDotPreview.Size = UDim2.new(0, 10, 0, 10)
            ColorDotPreview.AnchorPoint = Vector2.new(0, 0.5)
            ColorDotPreview.Position = UDim2.new(0, 10, 0.5, 0)
            ColorDotPreview.BackgroundColor3 = currentAccent
            ColorDotPreview.BorderSizePixel = 0
            ColorDotPreview.ZIndex = zIndex + 4
            ColorDotPreview.Parent = ComboMain

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = ColorDotPreview

            local CurrentLabel = Instance.new("TextLabel")
            CurrentLabel.Name = "CurrentLabel"
            CurrentLabel.Text = defaultColorName
            CurrentLabel.Font = Enum.Font.GothamMedium
            CurrentLabel.TextSize = 12
            CurrentLabel.TextColor3 = Library.Theme.TextPrimary
            CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
            CurrentLabel.BackgroundTransparency = 1
            CurrentLabel.Position = UDim2.new(0, 26, 0, 0)
            CurrentLabel.Size = UDim2.new(1, -52, 1, 0)
            CurrentLabel.ZIndex = zIndex + 4
            CurrentLabel.Parent = ComboMain

            local Chevron = Instance.new("ImageLabel")
            Chevron.Name = "Chevron"
            Chevron.Image = Library:GetIcon("chevron-down")
            Chevron.ImageColor3 = Library.Theme.TextSecondary
            Chevron.BackgroundTransparency = 1
            Chevron.AnchorPoint = Vector2.new(0.5, 0.5)
            Chevron.Position = UDim2.new(1, -14, 0.5, 0)
            Chevron.Size = UDim2.new(0, 16, 0, 16)
            Chevron.ZIndex = zIndex + 4
            Chevron.Parent = ComboMain

            local DropdownList = Instance.new("CanvasGroup")
            DropdownList.Name = "DropdownList"
            DropdownList.Size = UDim2.new(1, 0, 0, 0)
            DropdownList.Position = UDim2.new(0, 0, 1, 6)
            DropdownList.BackgroundColor3 = Library.Theme.DropdownBg
            DropdownList.BorderSizePixel = 0
            DropdownList.GroupTransparency = 1
            DropdownList.Visible = false
            DropdownList.ZIndex = zIndex + 15
            DropdownList.Parent = ComboContainer

            local DropCorner = Instance.new("UICorner")
            DropCorner.CornerRadius = UDim.new(0, 10)
            DropCorner.Parent = DropdownList

            local DropStroke = Instance.new("UIStroke")
            DropStroke.Color = Library.Theme.CardBorder
            DropStroke.Thickness = 1
            DropStroke.Transparency = 0.25
            DropStroke.Parent = DropdownList

            local DropLayout = Instance.new("UIListLayout")
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            DropLayout.Padding = UDim.new(0, 2)
            DropLayout.Parent = DropdownList

            local DropPadding = Instance.new("UIPadding")
            DropPadding.PaddingTop = UDim.new(0, 4)
            DropPadding.PaddingBottom = UDim.new(0, 4)
            DropPadding.PaddingLeft = UDim.new(0, 4)
            DropPadding.PaddingRight = UDim.new(0, 4)
            DropPadding.Parent = DropdownList

            local isOpen = false
            local selectedColorName = defaultColorName
            local optionLabels = {}

            local function CloseDrop()
                if not isOpen then return end
                isOpen = false
                TweenService:Create(Chevron, TweenFast, {Rotation = 0}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(36, 36, 44)}):Play()
                local t = TweenService:Create(DropdownList, TweenFast, {
                    Size = UDim2.new(1, 0, 0, 0),
                    GroupTransparency = 1
                })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then DropdownList.Visible = false end
                end)
            end

            local function OpenDrop()
                if isOpen then return end
                isOpen = true
                DropdownList.Visible = true
                TweenService:Create(Chevron, TweenFast, {Rotation = 180}):Play()
                TweenService:Create(ComboMain, TweenFast, {BackgroundColor3 = Color3.fromRGB(46, 46, 56)}):Play()
                local totalHeight = (#Library.AccentColors * 28) + 8
                TweenService:Create(DropdownList, TweenSpring, {
                    Size = UDim2.new(1, 0, 0, totalHeight),
                    GroupTransparency = 0
                }):Play()
            end

            local function SelectColor(colorItem)
                selectedColorName = colorItem.Name
                CurrentLabel.Text = colorItem.Name
                TweenService:Create(ColorDotPreview, TweenFast, {BackgroundColor3 = colorItem.Color}):Play()
                for _, opt in ipairs(optionLabels) do
                    local isSel = (opt.Item.Name == selectedColorName)
                    TweenService:Create(opt.Label, TweenFast, {
                        TextColor3 = isSel and colorItem.Color or Library.Theme.TextPrimary
                    }):Play()
                end
                CloseDrop()
                SetAccent(colorItem.Color)
                pcall(callback, colorItem.Color, colorItem.Name)
            end

            for idx, colorItem in ipairs(Library.AccentColors) do
                local OptionBtn = Instance.new("TextButton")
                OptionBtn.Name = colorItem.Name .. "Option"
                OptionBtn.Size = UDim2.new(1, 0, 0, 26)
                OptionBtn.BackgroundColor3 = Library.Theme.HoverLight
                OptionBtn.BackgroundTransparency = 1
                OptionBtn.AutoButtonColor = false
                OptionBtn.Text = ""
                OptionBtn.LayoutOrder = idx
                OptionBtn.ZIndex = zIndex + 16
                OptionBtn.Parent = DropdownList

                local OptCorner = Instance.new("UICorner")
                OptCorner.CornerRadius = UDim.new(0, 6)
                OptCorner.Parent = OptionBtn

                local OptDot = Instance.new("Frame")
                OptDot.Size = UDim2.new(0, 8, 0, 8)
                OptDot.AnchorPoint = Vector2.new(0, 0.5)
                OptDot.Position = UDim2.new(0, 8, 0.5, 0)
                OptDot.BackgroundColor3 = colorItem.Color
                OptDot.BorderSizePixel = 0
                OptDot.ZIndex = zIndex + 17
                OptDot.Parent = OptionBtn

                local DotC = Instance.new("UICorner")
                DotC.CornerRadius = UDim.new(1, 0)
                DotC.Parent = OptDot

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Text = colorItem.Name
                OptLabel.Font = Enum.Font.GothamMedium
                OptLabel.TextSize = 12
                OptLabel.TextColor3 = (colorItem.Name == selectedColorName) and currentAccent or Library.Theme.TextPrimary
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.BackgroundTransparency = 1
                OptLabel.Position = UDim2.new(0, 24, 0, 0)
                OptLabel.Size = UDim2.new(1, -32, 1, 0)
                OptLabel.ZIndex = zIndex + 17
                OptLabel.Parent = OptionBtn

                table.insert(optionLabels, {Label = OptLabel, Item = colorItem})

                OptionBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptionBtn, TweenFast, {BackgroundTransparency = 0}):Play()
                end)
                OptionBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptionBtn, TweenFast, {BackgroundTransparency = 1}):Play()
                end)
                OptionBtn.MouseButton1Click:Connect(function()
                    SelectColor(colorItem)
                end)
            end

            RegisterAccentListener(function(newColor)
                TweenService:Create(ColorDotPreview, TweenFast, {BackgroundColor3 = newColor}):Play()
            end)

            ComboMain.MouseButton1Click:Connect(function()
                if isOpen then CloseDrop() else OpenDrop() end
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
                if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = UserInputService:GetMouseLocation()
                    local pos = ComboContainer.AbsolutePosition
                    local size = ComboContainer.AbsoluteSize
                    local dropH = DropdownList.AbsoluteSize.Y
                    if mousePos.X < pos.X or mousePos.X > pos.X + size.X or mousePos.Y < pos.Y or mousePos.Y > pos.Y + dropH + 10 then
                        CloseDrop()
                    end
                end
            end))

            return {
                Select = function(colorNameOrColor)
                    for _, cItem in ipairs(Library.AccentColors) do
                        if cItem.Name == colorNameOrColor or cItem.Color == colorNameOrColor then
                            SelectColor(cItem)
                            break
                        end
                    end
                end,
                Get = function() return currentAccent, selectedColorName end,
                Row = row
            }
        end

        -- ==========================================
        -- Tab Component: AddWarningBanner
        -- Attention banner / callout card (Red/Yellow/Orange)
        -- ==========================================
        function Tab:AddWarningBanner(bannerConfig)
            bannerConfig = bannerConfig or {}
            local title = bannerConfig.Title or "WARNING"
            local desc = bannerConfig.Desc or ""
            local bannerColor = bannerConfig.Color or Library.Theme.AccentRed
            local iconAsset = Library:GetIcon(bannerConfig.Icon)
            local hasIcon = (iconAsset ~= nil and iconAsset ~= "")
            local layoutOrder = bannerConfig.LayoutOrder or 0

            local Card = Instance.new("Frame")
            Card.Name = "WarningBanner"
            Card.Size = UDim2.new(1, 0, 0, 64)
            Card.BackgroundColor3 = Color3.fromRGB(38, 22, 24)
            Card.BorderSizePixel = 0
            Card.LayoutOrder = layoutOrder
            Card.Parent = Page

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 12)
            Corner.Parent = Card

            local Stroke = Instance.new("UIStroke")
            Stroke.Color = bannerColor
            Stroke.Thickness = 1
            Stroke.Transparency = 0.5
            Stroke.Parent = Card

            if hasIcon then
                local IconImg = Instance.new("ImageLabel")
                IconImg.Name = "BannerIcon"
                IconImg.Image = iconAsset
                IconImg.ImageColor3 = bannerColor
                IconImg.BackgroundTransparency = 1
                IconImg.Position = UDim2.new(0, 14, 0.5, 0)
                IconImg.AnchorPoint = Vector2.new(0, 0.5)
                IconImg.Size = UDim2.new(0, 22, 0, 22)
                IconImg.Parent = Card
            end

            local startX = hasIcon and 44 or 16
            local widthOffset = hasIcon and -54 or -26

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Name = "BannerTitle"
            TitleLabel.Text = title
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.TextSize = 12.5
            TitleLabel.TextColor3 = bannerColor
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Position = UDim2.new(0, startX, 0, 9)
            TitleLabel.Size = UDim2.new(1, widthOffset, 0, 16)
            TitleLabel.Parent = Card

            local DescLabel = Instance.new("TextLabel")
            DescLabel.Name = "BannerDesc"
            DescLabel.Text = desc
            DescLabel.Font = Enum.Font.Gotham
            DescLabel.TextSize = 11
            DescLabel.TextColor3 = Library.Theme.TextSecondary
            DescLabel.TextXAlignment = Enum.TextXAlignment.Left
            DescLabel.TextWrapped = true
            DescLabel.BackgroundTransparency = 1
            DescLabel.Position = UDim2.new(0, startX, 0, 27)
            DescLabel.Size = UDim2.new(1, widthOffset, 0, 30)
            DescLabel.Parent = Card

            return {
                SetTitle = function(t) TitleLabel.Text = t end,
                SetDesc = function(d) DescLabel.Text = d end,
                Card = Card
            }
        end

        -- ==========================================
        -- Tab Component: AddGrid
        -- Grid layout container for slots / item cards
        -- ==========================================
        function Tab:AddGrid(gridConfig)
            gridConfig = gridConfig or {}
            local cellSize = gridConfig.CellSize or UDim2.new(0, 64, 0, 64)
            local cellPadding = gridConfig.CellPadding or UDim2.new(0, 9, 0, 9)
            local layoutOrder = gridConfig.LayoutOrder or 2

            local Container = Instance.new("Frame")
            Container.Name = "GridContainer"
            Container.Size = UDim2.new(1, 0, 0, 0)
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.BackgroundTransparency = 1
            Container.BorderSizePixel = 0
            Container.LayoutOrder = layoutOrder
            Container.Parent = Page

            local Layout = Instance.new("UIGridLayout")
            Layout.CellSize = cellSize
            Layout.CellPadding = cellPadding
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = Container

            local slots = {}

            local function AddSlot(slotConfig)
                local name = slotConfig.Name or "Item"
                local image = slotConfig.Image or ""
                local color = slotConfig.Color or Color3.fromRGB(255, 255, 255)
                local order = slotConfig.Order or (#slots + 1)
                local onHover = slotConfig.OnHover
                local onClick = slotConfig.OnClick

                local SlotBtn = Instance.new("TextButton")
                SlotBtn.Name = "Slot_" .. tostring(name)
                SlotBtn.Size = cellSize
                SlotBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
                SlotBtn.AutoButtonColor = false
                SlotBtn.Text = ""
                SlotBtn.LayoutOrder = order
                SlotBtn.Parent = Container

                local SlotCorner = Instance.new("UICorner")
                SlotCorner.CornerRadius = UDim.new(0, 10)
                SlotCorner.Parent = SlotBtn

                local SlotStroke = Instance.new("UIStroke")
                SlotStroke.Color = Library.Theme.CardBorder
                SlotStroke.Thickness = 1
                SlotStroke.Transparency = 0.4
                SlotStroke.Parent = SlotBtn

                local IconImg = Instance.new("ImageLabel")
                IconImg.Name = "SlotIcon"
                IconImg.Image = Library:GetIcon(image)
                IconImg.ImageColor3 = color
                IconImg.BackgroundTransparency = 1
                IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
                IconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
                IconImg.Size = UDim2.new(0.85, 0, 0.85, 0)
                IconImg.Parent = SlotBtn

                local defaultBadgeIcon = Library:GetIcon("x")
                if defaultBadgeIcon == "" then defaultBadgeIcon = "rbxassetid://10747384394" end

                local Badge = Instance.new("ImageLabel")
                Badge.Name = "SlotBadge"
                Badge.Image = defaultBadgeIcon
                Badge.ImageColor3 = Library.Theme.AccentRed
                Badge.BackgroundTransparency = 1
                Badge.AnchorPoint = Vector2.new(0.5, 0.5)
                Badge.Position = UDim2.new(0.5, 0, 0.5, 0)
                Badge.Size = UDim2.new(0.9, 0, 0.9, 0)
                Badge.Visible = false
                Badge.Parent = SlotBtn

                SlotBtn.MouseEnter:Connect(function()
                    TweenService:Create(SlotBtn, TweenFast, {BackgroundColor3 = Library.Theme.HoverLight}):Play()
                    if onHover then pcall(onHover, true, SlotBtn) end
                end)
                SlotBtn.MouseLeave:Connect(function()
                    TweenService:Create(SlotBtn, TweenFast, {BackgroundColor3 = Color3.fromRGB(24, 24, 28)}):Play()
                    if onHover then pcall(onHover, false, SlotBtn) end
                end)
                SlotBtn.MouseButton1Click:Connect(function()
                    TweenService:Create(SlotBtn, TweenFast, {Size = UDim2.new(0, cellSize.X.Offset - 6, 0, cellSize.Y.Offset - 6)}):Play()
                    task.delay(0.08, function()
                        TweenService:Create(SlotBtn, TweenSpring, {Size = cellSize}):Play()
                    end)
                    if onClick then pcall(onClick, SlotBtn) end
                end)

                local slotObj = {
                    Button = SlotBtn,
                    Icon = IconImg,
                    Badge = Badge,
                    Stroke = SlotStroke,
                    Name = name,
                    SetBadge = function(visible, badgeColor, customBadgeIcon)
                        Badge.Visible = visible
                        if badgeColor then Badge.ImageColor3 = badgeColor end
                        if customBadgeIcon then
                            local resolvedBadge = Library:GetIcon(customBadgeIcon)
                            if resolvedBadge ~= "" then Badge.Image = resolvedBadge end
                        end
                        TweenService:Create(SlotStroke, TweenFast, {
                            Color = visible and (badgeColor or Library.Theme.AccentRed) or Library.Theme.CardBorder,
                            Transparency = visible and 0.2 or 0.4
                        }):Play()
                    end
                }
                table.insert(slots, slotObj)
                return slotObj
            end

            return {
                Container = Container,
                AddSlot = AddSlot,
                Filter = function(searchText)
                    local query = string.lower(searchText or "")
                    for _, s in ipairs(slots) do
                        if query == "" or string.find(string.lower(s.Name), query, 1, true) then
                            s.Button.Visible = true
                        else
                            s.Button.Visible = false
                        end
                    end
                end,
                Clear = function()
                    for _, s in ipairs(slots) do
                        s.Button:Destroy()
                    end
                    table.clear(slots)
                end
            }
        end

        return Tab
    end

    -- Toggle Menu Open/Close with Smooth Animations
    function Window:Toggle(forceState)
        local targetState = (forceState ~= nil) and forceState or not isMenuOpen
        if isMenuAnimating and (targetState == isMenuOpen) then return end

        local compactSize = UDim2.new(0, math.max(MIN_WIDTH - 40, currentWidth - 40), 0, math.max(MIN_HEIGHT - 40, currentHeight - 40))
        local fullSize = UDim2.new(0, currentWidth, 0, currentHeight)

        if targetState then
            isMenuOpen = true
            MainFrame.Visible = true
            MainFrame.GroupTransparency = 1
            MainFrame.Size = compactSize
            MainStroke.Transparency = 1
            isMenuAnimating = true

            local openTween = TweenService:Create(MainFrame, TweenSmooth, {
                Size = fullSize,
                GroupTransparency = 0
            })
            local strokeTween = TweenService:Create(MainStroke, TweenSmooth, {
                Transparency = 0.3
            })
            openTween:Play()
            strokeTween:Play()
            openTween.Completed:Connect(function()
                isMenuAnimating = false
            end)
        else
            isMenuAnimating = true
            local closeTween = TweenService:Create(MainFrame, TweenSmooth, {
                Size = compactSize,
                GroupTransparency = 1
            })
            local strokeTween = TweenService:Create(MainStroke, TweenSmooth, {
                Transparency = 1
            })
            closeTween:Play()
            strokeTween:Play()
            closeTween.Completed:Connect(function()
                if not isMenuOpen then
                    MainFrame.Visible = false
                end
                isMenuAnimating = false
            end)
            isMenuOpen = false
        end
    end

    function Window:IsOpen()
        return isMenuOpen
    end

    -- Unload & Destroy Method
    function Window:Unload()
        for _, conn in ipairs(self.Connections) do
            pcall(function()
                if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                    conn:Disconnect()
                end
            end)
        end
        table.clear(self.Connections)

        if config.UnloadCallback then
            pcall(config.UnloadCallback)
        end

        pcall(function()
            local fadeTween = TweenService:Create(MainFrame, TweenSmooth, {
                Size = UDim2.new(0, math.max(MIN_WIDTH - 40, currentWidth - 40), 0, math.max(MIN_HEIGHT - 40, currentHeight - 40)),
                GroupTransparency = 1
            })
            local strokeTween = TweenService:Create(MainStroke, TweenSmooth, {
                Transparency = 1
            })
            fadeTween:Play()
            strokeTween:Play()
            fadeTween.Completed:Connect(function()
                pcall(function() ScreenGui:Destroy() end)
            end)
        end)
        task.delay(0.5, function()
            if ScreenGui and ScreenGui.Parent then
                pcall(function() ScreenGui:Destroy() end)
            end
        end)
    end

    return Window
end

return Library
