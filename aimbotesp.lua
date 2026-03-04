
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local aimbotEnabled = false
local fovRadius     = 120        
local SMOOTHNESS_SCALE   = 0.97
local LEGIT_SMOOTHNESS_PERCENT = 0.70
local HEALTH_BAR_OFFSET  = 10   
local LOADING_DURATION   = 5    

local smoothness    = 1 - (0.15 * SMOOTHNESS_SCALE) 
local function clampLerpAlpha(value)
    return math.clamp(value, 0.05, 0.98)
end

local lockedTarget  = nil        
local visibleOnly   = false
local aimPartMode   = "Head"
local legitMode     = false

local espEnabled    = false
local chamsEnabled  = false
local nameEnabled   = false
local healthEnabled = false

local espObjects = {}   

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "AimbotESPMenu"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
local guiParent = (rawget(_G, "gethui") and gethui()) or game:GetService("CoreGui")
ScreenGui.Parent          = guiParent

local COL_BG          = Color3.fromRGB(7,   8,   12)
local COL_PANEL       = Color3.fromRGB(14,  16,  22)
local COL_PANEL_ALT   = Color3.fromRGB(20,  23,  31)
local COL_ACCENT      = Color3.fromRGB(226, 51,  69)
local COL_DIM         = Color3.fromRGB(164, 172, 190)
local COL_TOGON       = Color3.fromRGB(226, 51,  69)
local COL_TOGOFF      = Color3.fromRGB(59,  63,  76)
local COL_SLIDER      = Color3.fromRGB(226, 51,  69)
local COL_BORDER      = Color3.fromRGB(41,  46,  58)
local COL_TAB_ACTIVE  = Color3.fromRGB(30,  34,  46)
local COL_TEXT_MAIN   = Color3.fromRGB(240, 244, 255)

local MainFrame = Instance.new("Frame")
MainFrame.Name            = "MainFrame"
MainFrame.Size            = UDim2.new(0, 640, 0, 400)
MainFrame.Position        = UDim2.new(0.5, -320, 0.5, -200)
MainFrame.BackgroundColor3 = COL_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active          = true
MainFrame.Draggable       = true
MainFrame.Visible         = false    
MainFrame.Parent          = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = COL_BORDER
MainStroke.Transparency = 0.35
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size              = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3  = COL_PANEL
TitleBar.BorderSizePixel   = 0
TitleBar.Parent            = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFill = Instance.new("Frame")
TitleFill.Size             = UDim2.new(1, 0, 0, 14)
TitleFill.Position         = UDim2.new(0, 0, 1, -14)
TitleFill.BackgroundColor3 = COL_PANEL
TitleFill.BorderSizePixel  = 0
TitleFill.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, -120, 0, 24)
TitleLabel.Position          = UDim2.new(0, 16, 0, 8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text              = "IshKeb Universal Menu"
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextSize          = 17
TitleLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Parent            = TitleBar

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size              = UDim2.new(1, -120, 0, 18)
SubtitleLabel.Position          = UDim2.new(0, 16, 0, 29)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text              = "Aimbot + ESP  •  Insert to toggle"
SubtitleLabel.Font              = Enum.Font.GothamBold
SubtitleLabel.TextSize          = 11
SubtitleLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
SubtitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
SubtitleLabel.Parent            = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
CloseBtn.Position          = UDim2.new(1, -38, 0, 12)
CloseBtn.BackgroundColor3  = COL_PANEL_ALT
CloseBtn.Text              = "✕"
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 13
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local KeyHint = Instance.new("TextLabel")
KeyHint.Size                   = UDim2.new(1, 0, 0, 16)
KeyHint.Position               = UDim2.new(0, 0, 1, -20)
KeyHint.BackgroundTransparency = 1
KeyHint.Text                   = "Press INSERT to toggle menu"
KeyHint.Font                   = Enum.Font.GothamBold
KeyHint.TextSize               = 11
KeyHint.TextColor3             = Color3.fromRGB(255, 255, 255)
KeyHint.TextXAlignment         = Enum.TextXAlignment.Center
KeyHint.Parent                 = MainFrame

local thumbContent, thumbReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
local userBadge = Instance.new("Frame")
userBadge.Size                   = UDim2.new(0, 230, 0, 44)
userBadge.Position               = UDim2.new(0, 12, 1, -52)
userBadge.BackgroundTransparency = 1
userBadge.ZIndex                 = 8
userBadge.Parent                 = MainFrame

local userBadgeBG = Instance.new("Frame")
userBadgeBG.Size                   = UDim2.new(1, 0, 1, 0)
userBadgeBG.BackgroundColor3       = COL_PANEL
userBadgeBG.BackgroundTransparency = 0.18
userBadgeBG.BorderSizePixel        = 0
userBadgeBG.ZIndex                 = 8
userBadgeBG.Parent                 = userBadge

local userBadgeCorner = Instance.new("UICorner")
userBadgeCorner.CornerRadius = UDim.new(0, 10)
userBadgeCorner.Parent = userBadgeBG

local userBadgeStroke = Instance.new("UIStroke")
userBadgeStroke.Thickness = 1
userBadgeStroke.Color = COL_BORDER
userBadgeStroke.Transparency = 0.15
userBadgeStroke.Parent = userBadgeBG

local userAvatar = Instance.new("ImageLabel")
userAvatar.Size                   = UDim2.new(0, 36, 0, 36)
userAvatar.Position               = UDim2.new(0, 5, 0.5, -18)
userAvatar.BackgroundColor3       = COL_PANEL_ALT
userAvatar.BorderSizePixel        = 0
userAvatar.ZIndex                 = 9
userAvatar.Image                  = thumbReady and thumbContent or ""
userAvatar.Parent                 = userBadge

local userAvatarCorner = Instance.new("UICorner")
userAvatarCorner.CornerRadius = UDim.new(1, 0)
userAvatarCorner.Parent = userAvatar

local userAvatarStroke = Instance.new("UIStroke")
userAvatarStroke.Thickness = 1
userAvatarStroke.Color = COL_BORDER
userAvatarStroke.Transparency = 0.2
userAvatarStroke.Parent = userAvatar

local userWelcome = Instance.new("TextLabel")
userWelcome.Size                   = UDim2.new(1, -46, 1, 0)
userWelcome.Position               = UDim2.new(0, 50, 0, 0)
userWelcome.BackgroundTransparency = 1
userWelcome.ZIndex                 = 9
userWelcome.Text                   = "Welcome " .. LocalPlayer.Name .. "!"
userWelcome.Font                   = Enum.Font.GothamBold
userWelcome.TextSize               = 13
userWelcome.TextColor3             = Color3.fromRGB(255, 255, 255)
userWelcome.TextXAlignment         = Enum.TextXAlignment.Left
userWelcome.Parent                 = userBadge

local LoadFrame = Instance.new("Frame")
LoadFrame.Size             = UDim2.new(1, 0, 1, 0)
LoadFrame.BackgroundColor3 = COL_BG
LoadFrame.BorderSizePixel  = 0
LoadFrame.ZIndex           = 20
LoadFrame.Parent           = ScreenGui

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size                   = UDim2.new(1, 0, 0, 40)
LoadTitle.Position               = UDim2.new(0, 0, 0.38, 0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text                   = "IshKeb Menu"
LoadTitle.Font                   = Enum.Font.GothamBold
LoadTitle.TextSize               = 22
LoadTitle.TextColor3             = Color3.fromRGB(255, 255, 255)
LoadTitle.TextXAlignment         = Enum.TextXAlignment.Center
LoadTitle.ZIndex                 = 21
LoadTitle.Parent                 = LoadFrame

local LoadSub = Instance.new("TextLabel")
LoadSub.Size                   = UDim2.new(1, 0, 0, 22)
LoadSub.Position               = UDim2.new(0, 0, 0.38, 44)
LoadSub.BackgroundTransparency = 1
LoadSub.Text                   = "Developer: IshKeb"
LoadSub.Font                   = Enum.Font.GothamBold
LoadSub.TextSize               = 12
LoadSub.TextColor3             = Color3.fromRGB(255, 255, 255)
LoadSub.TextXAlignment         = Enum.TextXAlignment.Center
LoadSub.ZIndex                 = 21
LoadSub.Parent                 = LoadFrame

local ProgressBG = Instance.new("Frame")
ProgressBG.Size             = UDim2.new(0, 360, 0, 8)
ProgressBG.Position         = UDim2.new(0.5, -180, 0.58, 0)
ProgressBG.BackgroundColor3 = COL_TOGOFF
ProgressBG.BorderSizePixel  = 0
ProgressBG.ZIndex           = 21
ProgressBG.Parent           = LoadFrame

local ProgressBGCorner = Instance.new("UICorner")
ProgressBGCorner.CornerRadius = UDim.new(1, 0)
ProgressBGCorner.Parent = ProgressBG

local ProgressFill = Instance.new("Frame")
ProgressFill.Size             = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = COL_ACCENT
ProgressFill.BorderSizePixel  = 0
ProgressFill.ZIndex           = 22
ProgressFill.Parent           = ProgressBG

local ProgressFillCorner = Instance.new("UICorner")
ProgressFillCorner.CornerRadius = UDim.new(1, 0)
ProgressFillCorner.Parent = ProgressFill

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size                   = UDim2.new(1, 0, 0, 18)
LoadStatus.Position               = UDim2.new(0, 0, 0.58, 14)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text                   = "Initializing..."
LoadStatus.Font                   = Enum.Font.GothamBold
LoadStatus.TextSize               = 11
LoadStatus.TextColor3             = Color3.fromRGB(255, 255, 255)
LoadStatus.TextXAlignment         = Enum.TextXAlignment.Center
LoadStatus.ZIndex                 = 21
LoadStatus.Parent                 = LoadFrame

local BodyFrame = Instance.new("Frame")
BodyFrame.Size             = UDim2.new(1, 0, 1, -52)
BodyFrame.Position         = UDim2.new(0, 0, 0, 52)
BodyFrame.BackgroundTransparency = 1
BodyFrame.Parent           = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0, 170, 1, -10)
Sidebar.Position         = UDim2.new(0, 8, 0, 6)
Sidebar.BackgroundColor3 = COL_PANEL
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = BodyFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = COL_BORDER
SidebarStroke.Transparency = 0.25
SidebarStroke.Parent = Sidebar

local SidebarHeader = Instance.new("TextLabel")
SidebarHeader.Size                   = UDim2.new(1, -20, 0, 24)
SidebarHeader.Position               = UDim2.new(0, 10, 0, 10)
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.Text                   = "Modules"
SidebarHeader.Font                   = Enum.Font.GothamBold
SidebarHeader.TextSize               = 14
SidebarHeader.TextColor3             = Color3.fromRGB(255, 255, 255)
SidebarHeader.TextXAlignment         = Enum.TextXAlignment.Left
SidebarHeader.Parent                 = Sidebar

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -20, 1, -54)
TabBar.Position         = UDim2.new(0, 10, 0, 40)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel  = 0
TabBar.Parent           = Sidebar

local TabList = Instance.new("UIListLayout")
TabList.FillDirection  = Enum.FillDirection.Vertical
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabList.SortOrder      = Enum.SortOrder.LayoutOrder
TabList.Padding        = UDim.new(0, 8)
TabList.Parent         = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size             = UDim2.new(1, -194, 1, -10)
ContentArea.Position         = UDim2.new(0, 186, 0, 6)
ContentArea.BackgroundColor3 = COL_PANEL
ContentArea.BorderSizePixel  = 0
ContentArea.Parent           = BodyFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = ContentArea

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = COL_BORDER
ContentStroke.Transparency = 0.25
ContentStroke.Parent = ContentArea

local tabPanels = {}
local tabButtons = {}
local activeTab = nil

local function switchTab(name)
    if activeTab then
        tabPanels[activeTab].Visible     = false
        tabButtons[activeTab].TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButtons[activeTab].BackgroundColor3 = COL_PANEL_ALT
    end
    activeTab = name
    tabPanels[name].Visible     = true
    tabButtons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButtons[name].BackgroundColor3 = COL_TAB_ACTIVE
end

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size              = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3  = COL_PANEL_ALT
    btn.BorderSizePixel   = 0
    btn.Text              = name
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 12
    btn.TextColor3        = Color3.fromRGB(255, 255, 255)
    btn.LayoutOrder       = order
    btn.Parent            = TabBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local panel = Instance.new("ScrollingFrame")
    panel.Size               = UDim2.new(1, 0, 1, 0)
    panel.Position           = UDim2.new(0, 0, 0, 0)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel    = 0
    panel.ScrollBarThickness = 4
    panel.ScrollBarImageColor3 = COL_DIM
    panel.Visible            = false
    panel.Parent             = ContentArea

    local padding = Instance.new("UIPadding")
    padding.PaddingTop    = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft   = UDim.new(0, 12)
    padding.PaddingRight  = UDim.new(0, 12)
    padding.Parent        = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding         = UDim.new(0, 6)
    layout.SortOrder       = Enum.SortOrder.LayoutOrder
    layout.Parent          = panel

    tabPanels[name]  = panel
    tabButtons[name] = btn

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        panel.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    return panel
end

local function makeLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 12
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.LayoutOrder            = order
    lbl.Parent                 = parent
    return lbl
end

local function makeToggle(parent, labelText, order, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = COL_PANEL
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -60, 1, 0)
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 13
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local togBG = Instance.new("Frame")
    togBG.Size             = UDim2.new(0, 40, 0, 20)
    togBG.Position         = UDim2.new(1, -50, 0.5, -10)
    togBG.BackgroundColor3 = COL_TOGOFF
    togBG.BorderSizePixel  = 0
    togBG.Parent           = row

    local togBGCorner = Instance.new("UICorner")
    togBGCorner.CornerRadius = UDim.new(1, 0)
    togBGCorner.Parent = togBG

    local togKnob = Instance.new("Frame")
    togKnob.Size             = UDim2.new(0, 16, 0, 16)
    togKnob.Position         = UDim2.new(0, 2, 0.5, -8)
    togKnob.BackgroundColor3 = COL_ACCENT
    togKnob.BorderSizePixel  = 0
    togKnob.Parent           = togBG

    local togKnobCorner = Instance.new("UICorner")
    togKnobCorner.CornerRadius = UDim.new(1, 0)
    togKnobCorner.Parent = togKnob

    local state = false
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.Parent                 = row

    local function setState(nextState, fireCallback)
        state = nextState
        togBG.BackgroundColor3 = state and COL_TOGON or COL_TOGOFF
        togKnob.Position       = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        togKnob.BackgroundColor3 = state and COL_BG or COL_ACCENT
        if fireCallback and callback then callback(state) end
    end

    btn.MouseButton1Click:Connect(function()
        setState(not state, true)
    end)

    return {
        row = row,
        setState = setState,
        getState = function() return state end,
    }
end

local function makeSlider(parent, labelText, order, minVal, maxVal, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3 = COL_PANEL
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(0.75, 0, 0, 22)
    lbl.Position               = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = labelText
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 13
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local valLabel = Instance.new("TextLabel")
    valLabel.Size                   = UDim2.new(0.25, -10, 0, 22)
    valLabel.Position               = UDim2.new(0.75, 0, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text                   = tostring(defaultVal)
    valLabel.Font                   = Enum.Font.GothamBold
    valLabel.TextSize               = 12
    valLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
    valLabel.TextXAlignment         = Enum.TextXAlignment.Right
    valLabel.Parent                 = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -20, 0, 4)
    track.Position         = UDim2.new(0, 10, 0, 34)
    track.BackgroundColor3 = COL_TOGOFF
    track.BorderSizePixel  = 0
    track.Parent           = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = COL_SLIDER
    fill.BorderSizePixel  = 0
    fill.Parent           = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.BackgroundColor3 = COL_ACCENT
    knob.BorderSizePixel  = 0
    knob.Parent           = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false
    local trackBtn = Instance.new("TextButton")
    trackBtn.Size                   = UDim2.new(1, 0, 0, 20)
    trackBtn.Position               = UDim2.new(0, 0, 0.5, -10)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text                   = ""
    trackBtn.Parent                 = track

    local function updateFromX(absX)
        local trackAbs  = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local t = math.clamp((absX - trackAbs) / trackSize, 0, 1)
        local value
        if math.type and math.type(minVal) == "integer" then
            value = math.floor(minVal + t * (maxVal - minVal) + 0.5)
        else
            value = math.floor((minVal + t * (maxVal - minVal)) * 100 + 0.5) / 100
        end
        fill.Size     = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, 0, 0.5, 0)
        valLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    trackBtn.MouseButton1Down:Connect(function(x, _y)
        dragging = true
        updateFromX(x)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return row
end

local aimbotPanel  = createTab("Aimbot",  1)
local visualsPanel = createTab("Visuals", 2)
local partPanel    = createTab("Part selection", 3)
local notesPanel   = createTab("Notes",   4)

makeToggle(aimbotPanel, "Enable Aimbot", 1, function(val)
    aimbotEnabled = val
    if not val then lockedTarget = nil end
end)

makeSlider(aimbotPanel, "FOV Circle Size", 2, 20, 400, fovRadius, function(val)
    fovRadius = val
end)

makeSlider(aimbotPanel, "Aim Smoothness", 3, -1.00, 1.00, 0.15, function(val)
    smoothness = 1 - (val * SMOOTHNESS_SCALE)
end)

makeToggle(aimbotPanel, "Visible Only", 4, function(val)
    visibleOnly = val
    if not val then lockedTarget = nil end
end)

makeToggle(aimbotPanel, "Legit mode", 5, function(val)
    legitMode = val
    lockedTarget = nil
end)

makeLabel(aimbotPanel, "Hold M2 (Right-Click) to aim.", 6)

makeToggle(visualsPanel, "Name ESP",       1, function(val) nameEnabled   = val end)
makeToggle(visualsPanel, "Health Bar ESP", 2, function(val) healthEnabled = val end)
makeToggle(visualsPanel, "Chams ESP",      3, function(val) chamsEnabled  = val end)

local partModes = {
    "Head",
    "Torso",
    "Left Leg",
    "Right Leg",
    "Left Foot",
    "Right Foot",
    "Closest to Crosshair",
}
local partToggles = {}
for idx, modeName in ipairs(partModes) do
    partToggles[modeName] = makeToggle(partPanel, modeName, idx, function(val)
        if not val then
            partToggles[modeName].setState(true, false)
            return
        end
        aimPartMode = modeName
        lockedTarget = nil
        for otherName, toggle in pairs(partToggles) do
            if otherName ~= modeName and toggle.getState() then
                toggle.setState(false, false)
            end
        end
    end)
end
partToggles["Head"].setState(true, true)

local function makeNote(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize          = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 13
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextWrapped            = true
    lbl.LayoutOrder            = order
    lbl.Parent                 = parent
    return lbl
end

makeNote(notesPanel, "Developer: IshKeb", 1)
makeNote(notesPanel, "Note: this script should work for most games.", 2)
makeNote(notesPanel, "Toggle key is Insert", 3)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Thickness = 1.5
fovCircle.Color     = COL_ACCENT
fovCircle.Filled    = false
fovCircle.NumSides  = 64
fovCircle.Radius    = fovRadius

local function newDrawing(type_, props)
    local d = Drawing.new(type_)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function removeESPForPlayer(player)
    local obj = espObjects[player]
    if not obj then return end
    pcall(function() obj.nameTag:Remove() end)
    pcall(function() obj.healthBG:Remove() end)
    pcall(function() obj.healthBar:Remove() end)
    if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
    espObjects[player] = nil
end

local function getCharacterParts(character)
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not (root and head and humanoid) then return nil end
    return root, head, humanoid
end

local function setupESPForPlayer(player)
    if espObjects[player] then return end

    local hl = Instance.new("Highlight")
    hl.FillColor            = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor         = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency     = 0.4
    hl.OutlineTransparency  = 0
    hl.DepthMode            = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled              = false
    hl.Adornee              = player.Character
    hl.Parent               = workspace

    espObjects[player] = {
        nameTag   = newDrawing("Text",   {Visible=false, Size=16, Color=Color3.fromRGB(255,255,255), Center=true, Outline=true, Font=3}),
        healthBG  = newDrawing("Square", {Visible=false, Thickness=0, Color=Color3.fromRGB(0,0,0),   Filled=true}),
        healthBar = newDrawing("Square", {Visible=false, Thickness=0, Color=Color3.fromRGB(0,200,0), Filled=true}),
        highlight = hl,
    }
end

local function applyChams(player)
    local obj = espObjects[player]
    if not obj or not obj.highlight then return end
    obj.highlight.Adornee = player.Character
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    setupESPForPlayer(player)

    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)
        local obj = espObjects[player]
        if obj and obj.highlight then
            obj.highlight.Adornee = character
        end
    end)

    if player.Character then
        applyChams(player)
    end
end

local function onPlayerRemoving(player)
    removeESPForPlayer(player)
end

for _, p in pairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

local function getMousePos()
    return UserInputService:GetMouseLocation()
end

local function worldToScreen(pos)
    local vp, inView = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), inView, vp.Z
end

local function isTargetVisible(targetPart, character)
    if not targetPart or not character then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local ignore = {Camera}
    if LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    params.FilterDescendantsInstances = ignore
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = workspace:Raycast(origin, direction, params)
    return (not result) or result.Instance:IsDescendantOf(character)
end

local function getCharacterTargetParts(character, mode)
    if not character then return {} end
    local partMap = {
        ["Head"] = {"Head"},
        ["Torso"] = {"UpperTorso", "Torso", "HumanoidRootPart"},
        ["Left Leg"] = {"LeftLowerLeg", "LeftUpperLeg", "Left Leg"},
        ["Right Leg"] = {"RightLowerLeg", "RightUpperLeg", "Right Leg"},
        ["Left Foot"] = {"LeftFoot"},
        ["Right Foot"] = {"RightFoot"},
    }

    local names = partMap[mode]
    if names then
        for _, name in ipairs(names) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                return {part}
            end
        end
        return {}
    end

    local closestParts = {}
    for _, partName in ipairs({"Head", "UpperTorso", "Torso", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "Left Leg", "Right Leg"}) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            table.insert(closestParts, part)
        end
    end
    return closestParts
end

local function getClosestTargetPart(radius)
    local mousePos  = getMousePos()
    local bestDist  = math.huge
    local bestPart  = nil
    local searchRadius = radius or fovRadius
    local targetMode = legitMode and "Closest to Crosshair" or aimPartMode

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        for _, targetPart in ipairs(getCharacterTargetParts(character, targetMode)) do
            local screenPos, inView = worldToScreen(targetPart.Position)
            if not inView then continue end
            if visibleOnly and not isTargetVisible(targetPart, character) then continue end

            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist <= searchRadius and dist < bestDist then
                bestDist = dist
                bestPart = targetPart
            end
        end
    end

    return bestPart
end

local m2Held = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        m2Held = true
        return
    end
    if gpe then return end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        m2Held      = false
        lockedTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    local mousePos = getMousePos()

    fovCircle.Visible = aimbotEnabled
    fovCircle.Radius  = fovRadius
    fovCircle.Position = mousePos

    if aimbotEnabled and m2Held then
        if not lockedTarget then
            lockedTarget = getClosestTargetPart()
        end

        if lockedTarget then
            local humanoid = lockedTarget.Parent and
                             lockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 or not lockedTarget.Parent.Parent then
                lockedTarget = nil
            else
                if visibleOnly and not isTargetVisible(lockedTarget, lockedTarget.Parent) then
                    lockedTarget = nil
                else
                    local screenPos, inView = worldToScreen(lockedTarget.Position)
                    if inView then
                        local current  = mousePos
                        local target   = Vector2.new(screenPos.X, screenPos.Y)
                        local currentSmoothness = legitMode
                            and clampLerpAlpha(1 - (LEGIT_SMOOTHNESS_PERCENT * SMOOTHNESS_SCALE))
                            or clampLerpAlpha(smoothness)
                        local newPos   = current:Lerp(target, currentSmoothness)
                        local delta = newPos - current
                        if mousemoverel then
                            local moveX = math.round(delta.X)
                            local moveY = math.round(delta.Y)
                            if moveX == 0 and math.abs(delta.X) >= 0.1 then
                                moveX = delta.X > 0 and 1 or -1
                            end
                            if moveY == 0 and math.abs(delta.Y) >= 0.1 then
                                moveY = delta.Y > 0 and 1 or -1
                            end
                            mousemoverel(moveX, moveY)
                        end
                    end
                end
            end
        end
    elseif not m2Held then
        lockedTarget = nil
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local obj = espObjects[player]
        if not obj then continue end

        local character = player.Character
        local root, head, humanoid = getCharacterParts(character)

        local visible = (root ~= nil and head ~= nil)

        if nameEnabled and visible then
            local sp, inView = worldToScreen(head.Position + Vector3.new(0, 0.7, 0))
            obj.nameTag.Visible   = inView
            obj.nameTag.Position  = sp
            obj.nameTag.Text      = player.Name
        else
            obj.nameTag.Visible = false
        end

        local topSP, topInView
        local botSP, botInView
        if visible then
            topSP, topInView = worldToScreen(head.Position + Vector3.new(0, 0.7, 0))
            botSP, botInView = worldToScreen(root.Position - Vector3.new(0, 2.5, 0))
        end

        local barVisible = visible and topInView and botInView
        if barVisible and healthEnabled then
            local height = math.abs(topSP.Y - botSP.Y)
            local hp    = humanoid.Health
            local maxHp = humanoid.MaxHealth
            local ratio = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
            local barW  = 4
            local bx    = topSP.X - HEALTH_BAR_OFFSET
            local by    = topSP.Y

            obj.healthBG.Visible  = true
            obj.healthBG.Position = Vector2.new(bx, by)
            obj.healthBG.Size     = Vector2.new(barW, height)

            obj.healthBar.Visible  = true
            obj.healthBar.Position = Vector2.new(bx, by + height * (1 - ratio))
            obj.healthBar.Size     = Vector2.new(barW, height * ratio)

            local g = math.floor(200 * ratio)
            local r = math.floor(200 * (1 - ratio))
            obj.healthBar.Color = Color3.fromRGB(r, g, 0)
        else
            obj.healthBG.Visible  = false
            obj.healthBar.Visible = false
        end

        if obj.highlight then
            obj.highlight.Adornee = character
            obj.highlight.Enabled = chamsEnabled and visible and (character ~= nil)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

task.spawn(function()
    local messages = {
        "Initializing...",
        "Loading modules...",
        "Esp Modules Installed...",
        "Workspace injection complete...",
        "Almost ready...",
        "Prepping ByfronBypass",
        "Done!",
    }
    local phases = {
        {target = 0.18, speed = 0.55},
        {target = 0.30, speed = 0.10, pause = 0.09},
        {target = 0.58, speed = 0.75},
        {target = 0.66, speed = 0.18, pause = 0.06},
        {target = 0.90, speed = 0.85},
        {target = 1.00, speed = 0.45, pause = 0.12},
    }

    local fill = 0
    local totalDuration = LOADING_DURATION
    local phaseWeight = 0
    for _, phase in ipairs(phases) do
        phaseWeight = phaseWeight + ((phase.target - fill) / phase.speed)
        fill = phase.target
    end
    local timeScale = totalDuration / phaseWeight

    fill = 0
    for _, phase in ipairs(phases) do
        while fill < phase.target do
            local dt = RunService.RenderStepped:Wait()
            fill = math.min(phase.target, fill + (dt / timeScale) * phase.speed)
            ProgressFill.Size = UDim2.new(fill, 0, 1, 0)
            local idx = math.clamp(math.floor(fill * #messages) + 1, 1, #messages)
            LoadStatus.Text = messages[idx]
        end
        if phase.pause then
            task.wait(phase.pause)
        end
    end

    ProgressFill.Size = UDim2.new(1, 0, 1, 0)
    LoadStatus.Text = "Done!"
    task.wait(0.35)

    LoadFrame:Destroy()
    switchTab("Aimbot")
    MainFrame.Visible = true
end)
