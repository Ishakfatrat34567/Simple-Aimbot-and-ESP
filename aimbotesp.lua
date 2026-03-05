
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StatsService      = game:GetService("Stats")
local HttpService       = game:GetService("HttpService")
local Camera            = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local aimbotEnabled = false
local fovRadius     = 120        
local SMOOTHNESS_SCALE   = 0.97
local LEGIT_SMOOTHNESS_PERCENT = 0.70
local HEALTH_BAR_OFFSET  = 10   
local LOADING_DURATION   = 5    

local TOGGLE_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local smoothness    = 1 - (0.15 * SMOOTHNESS_SCALE) 
local hardLockOn    = false
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
local skeletonEnabled = false
local tracersEnabled = false

local espObjects = {}   
local spectatingPlayer = nil

local function getPlayerDisplayName(player)
    return (player and (player.DisplayName or player.Name)) or "Unknown"
end

local function getCurrentCamera()
    return workspace.CurrentCamera
end

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

local fovColor = COL_ACCENT
local espColor = Color3.fromRGB(255, 255, 255)

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

local firstCloseNotificationShown = false
local function showCustomNotification(message, visibleDuration)
    local notify = Instance.new("Frame")
    notify.Size = UDim2.new(0, 290, 0, 58)
    notify.AnchorPoint = Vector2.new(1, 1)
    notify.Position = UDim2.new(1, 320, 1, -18)
    notify.BackgroundColor3 = COL_PANEL
    notify.BorderSizePixel = 0
    notify.ZIndex = 40
    notify.Parent = ScreenGui

    local notifyCorner = Instance.new("UICorner")
    notifyCorner.CornerRadius = UDim.new(0, 10)
    notifyCorner.Parent = notify

    local notifyStroke = Instance.new("UIStroke")
    notifyStroke.Thickness = 1
    notifyStroke.Color = COL_BORDER
    notifyStroke.Transparency = 0.1
    notifyStroke.Parent = notify

    local notifyText = Instance.new("TextLabel")
    notifyText.Size = UDim2.new(1, -20, 1, 0)
    notifyText.Position = UDim2.new(0, 10, 0, 0)
    notifyText.BackgroundTransparency = 1
    notifyText.Text = message
    notifyText.Font = Enum.Font.GothamBold
    notifyText.TextSize = 14
    notifyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifyText.TextXAlignment = Enum.TextXAlignment.Left
    notifyText.ZIndex = 41
    notifyText.Parent = notify

    local tweenIn = TweenService:Create(notify, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -18, 1, -18)
    })
    local tweenOut = TweenService:Create(notify, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 320, 1, -18)
    })

    tweenIn:Play()
    tweenIn.Completed:Wait()
    task.wait(visibleDuration or 5)
    tweenOut:Play()
    tweenOut.Completed:Wait()
    notify:Destroy()
end

local function showFirstCloseNotification()
    showCustomNotification("Press Insert to open the menu!", 5)
end

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
LoadTitle.Text                   = "Installing Modules..."
LoadTitle.Font                   = Enum.Font.GothamBold
LoadTitle.TextSize               = 30
LoadTitle.TextColor3             = Color3.fromRGB(255, 255, 255)
LoadTitle.TextXAlignment         = Enum.TextXAlignment.Center
LoadTitle.ZIndex                 = 21
LoadTitle.Parent                 = LoadFrame

local LoadSub = Instance.new("TextLabel")
LoadSub.Size                   = UDim2.new(1, 0, 0, 22)
LoadSub.Position               = UDim2.new(0, 0, 0.38, 44)
LoadSub.BackgroundTransparency = 1
LoadSub.Text                   = ""
LoadSub.Font                   = Enum.Font.GothamBold
LoadSub.TextSize               = 16
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
LoadStatus.Text                   = "Installing Modules..."
LoadStatus.Font                   = Enum.Font.GothamBold
LoadStatus.TextSize               = 15
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

    local bgTween
    local knobTween

    local function setState(nextState, fireCallback)
        state = nextState

        if bgTween then bgTween:Cancel() end
        if knobTween then knobTween:Cancel() end

        bgTween = TweenService:Create(togBG, TOGGLE_TWEEN_INFO, {
            BackgroundColor3 = state and COL_TOGON or COL_TOGOFF,
        })
        knobTween = TweenService:Create(togKnob, TOGGLE_TWEEN_INFO, {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = state and COL_BG or COL_ACCENT,
        })

        bgTween:Play()
        knobTween:Play()

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

    local currentValue = defaultVal

    local function setValue(value, fireCallback)
        local clamped = math.clamp(value, minVal, maxVal)
        local t = (clamped - minVal) / (maxVal - minVal)
        local finalValue
        if math.type and math.type(minVal) == "integer" then
            finalValue = math.floor(clamped + 0.5)
        else
            finalValue = math.floor(clamped * 100 + 0.5) / 100
        end
        currentValue = finalValue
        fill.Size     = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, 0, 0.5, 0)
        valLabel.Text = tostring(finalValue)
        if fireCallback and callback then callback(finalValue) end
    end

    local function updateFromX(absX)
        local trackAbs  = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local t = math.clamp((absX - trackAbs) / trackSize, 0, 1)
        local rawValue = minVal + t * (maxVal - minVal)
        setValue(rawValue, true)
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

    return {
        row = row,
        setValue = setValue,
        getValue = function() return currentValue end,
    }
end

local function makeColorPicker(parent, title, order, onColor)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 58)
    row.BackgroundColor3 = COL_PANEL
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -10, 0, 20)
    lbl.Position               = UDim2.new(0, 10, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = title
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 12
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Parent                 = row

    local colors = {
        Color3.fromRGB(226, 51, 69),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(70, 170, 255),
        Color3.fromRGB(110, 255, 160),
        Color3.fromRGB(255, 222, 89),
        Color3.fromRGB(196, 140, 255),
        Color3.fromRGB(255, 145, 77),
        Color3.fromRGB(255, 95, 145),
    }

    local xOffset = 10
    for _, color in ipairs(colors) do
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size             = UDim2.new(0, 18, 0, 18)
        colorBtn.Position         = UDim2.new(0, xOffset, 0, 30)
        colorBtn.BackgroundColor3 = color
        colorBtn.BorderSizePixel  = 0
        colorBtn.Text             = ""
        colorBtn.Parent           = row

        local colorCorner = Instance.new("UICorner")
        colorCorner.CornerRadius = UDim.new(1, 0)
        colorCorner.Parent = colorBtn

        local colorStroke = Instance.new("UIStroke")
        colorStroke.Thickness = 1
        colorStroke.Color = Color3.fromRGB(255, 255, 255)
        colorStroke.Transparency = 0.2
        colorStroke.Parent = colorBtn

        colorBtn.MouseButton1Click:Connect(function()
            onColor(color)
        end)

        xOffset = xOffset + 24
    end

    return row
end

local homePanel     = createTab("Home", 1)
local aimbotPanel   = createTab("Aimbot",  2)
local visualsPanel  = createTab("Visuals", 3)
local partPanel     = createTab("Part selection", 4)
local notesPanel    = createTab("Notes",   5)
local spectatePanel = createTab("Spectate", 6)
local configsPanel  = createTab("Configs", 7)

local homeHeader = makeLabel(homePanel, "Home", 1)
homeHeader.TextSize = 15

local homeSubHeader = makeLabel(homePanel, "Session + Server Information", 2)
homeSubHeader.TextColor3 = COL_DIM

local function makeInfoRow(parent, title, order)
    local row = Instance.new("TextLabel")
    row.Size                   = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1
    row.Font                   = Enum.Font.GothamBold
    row.TextSize               = 12
    row.TextColor3             = Color3.fromRGB(255, 255, 255)
    row.TextXAlignment         = Enum.TextXAlignment.Left
    row.LayoutOrder            = order
    row.Text                   = title
    row.Parent                 = parent
    return row
end

local statsRows = {
    username = makeInfoRow(homePanel, "Username: " .. LocalPlayer.Name, 3),
    userId = makeInfoRow(homePanel, "User ID: " .. tostring(LocalPlayer.UserId), 4),
    accountAge = makeInfoRow(homePanel, "Account Age: " .. tostring(LocalPlayer.AccountAge) .. " days", 5),
    serverPlayers = makeInfoRow(homePanel, "Players: 0", 6),
    placeId = makeInfoRow(homePanel, "Place ID: " .. tostring(game.PlaceId), 7),
    jobId = makeInfoRow(homePanel, "Server ID: " .. string.sub(game.JobId ~= "" and game.JobId or "Private", 1, 18), 8),
    uptime = makeInfoRow(homePanel, "Session Uptime: 00:00", 9),
    memory = makeInfoRow(homePanel, "Client Memory: -- MB", 10),
}

local thumbContent, thumbReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
local userBadge = Instance.new("Frame")
userBadge.Size                   = UDim2.new(1, 0, 0, 58)
userBadge.BackgroundTransparency = 1
userBadge.LayoutOrder            = 99
userBadge.Parent                 = homePanel

local userBadgeBG = Instance.new("Frame")
userBadgeBG.Size                   = UDim2.new(1, 0, 1, 0)
userBadgeBG.BackgroundColor3       = COL_PANEL_ALT
userBadgeBG.BackgroundTransparency = 0.08
userBadgeBG.BorderSizePixel        = 0
userBadgeBG.Parent                 = userBadge

local userBadgeCorner = Instance.new("UICorner")
userBadgeCorner.CornerRadius = UDim.new(0, 10)
userBadgeCorner.Parent = userBadgeBG

local userBadgeStroke = Instance.new("UIStroke")
userBadgeStroke.Thickness = 1
userBadgeStroke.Color = COL_BORDER
userBadgeStroke.Transparency = 0.1
userBadgeStroke.Parent = userBadgeBG

local userAvatar = Instance.new("ImageLabel")
userAvatar.Size                   = UDim2.new(0, 46, 0, 46)
userAvatar.Position               = UDim2.new(0, 6, 0.5, -23)
userAvatar.BackgroundColor3       = COL_PANEL
userAvatar.BorderSizePixel        = 0
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
userWelcome.Size                   = UDim2.new(1, -64, 1, 0)
userWelcome.Position               = UDim2.new(0, 60, 0, 0)
userWelcome.BackgroundTransparency = 1
userWelcome.Text                   = "Welcome " .. LocalPlayer.Name .. "!"
userWelcome.Font                   = Enum.Font.GothamBold
userWelcome.TextSize               = 15
userWelcome.TextColor3             = Color3.fromRGB(255, 255, 255)
userWelcome.TextXAlignment         = Enum.TextXAlignment.Left
userWelcome.Parent                 = userBadge

local aimbotToggle = makeToggle(aimbotPanel, "Enable Aimbot", 1, function(val)
    aimbotEnabled = val
    if not val then lockedTarget = nil end
end)

local fovSlider = makeSlider(aimbotPanel, "FOV Circle Size", 2, 20, 400, fovRadius, function(val)
    fovRadius = val
end)

local smoothnessSlider = makeSlider(aimbotPanel, "Aim Smoothness", 3, 0, 100, 15, function(val)
    local smoothPercent = math.clamp(val / 100, 0, 1)
    hardLockOn = smoothPercent <= 0
    if hardLockOn then
        smoothness = 1
    else
        smoothness = 1 - (smoothPercent * SMOOTHNESS_SCALE)
    end
end)

local visibleToggle = makeToggle(aimbotPanel, "Visible Only", 4, function(val)
    visibleOnly = val
    if not val then lockedTarget = nil end
end)

local legitToggle = makeToggle(aimbotPanel, "Legit mode", 5, function(val)
    legitMode = val
    lockedTarget = nil
end)

local aimBindType = "UserInputType"
local aimBindValue = Enum.UserInputType.MouseButton2
local waitingForAimbotBind = false

local function getBindDisplayText()
    if aimBindType == "KeyCode" then
        return aimBindValue.Name
    end
    if aimBindValue == Enum.UserInputType.MouseButton1 then return "Mouse1" end
    if aimBindValue == Enum.UserInputType.MouseButton2 then return "Mouse2" end
    if aimBindValue == Enum.UserInputType.MouseButton3 then return "Mouse3" end
    return aimBindValue.Name
end

local function inputMatchesAimbotBind(input)
    if aimBindType == "KeyCode" then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == aimBindValue
    end
    return input.UserInputType == aimBindValue
end

local aimBindContainer = Instance.new("Frame")
aimBindContainer.Size = UDim2.new(1, 0, 0, 40)
aimBindContainer.BackgroundColor3 = COL_PANEL_ALT
aimBindContainer.BorderSizePixel = 0
aimBindContainer.LayoutOrder = 6
aimBindContainer.Parent = aimbotPanel

local aimBindContainerCorner = Instance.new("UICorner")
aimBindContainerCorner.CornerRadius = UDim.new(0, 8)
aimBindContainerCorner.Parent = aimBindContainer

local aimBindContainerStroke = Instance.new("UIStroke")
aimBindContainerStroke.Thickness = 1
aimBindContainerStroke.Color = COL_BORDER
aimBindContainerStroke.Transparency = 0.1
aimBindContainerStroke.Parent = aimBindContainer

local aimBindButton = Instance.new("TextButton")
aimBindButton.Size             = UDim2.new(1, -8, 1, -8)
aimBindButton.Position         = UDim2.new(0, 4, 0, 4)
aimBindButton.BackgroundColor3 = COL_PANEL
aimBindButton.BorderSizePixel  = 0
aimBindButton.Text             = "Rebind Aimbot Key: " .. getBindDisplayText()
aimBindButton.Font             = Enum.Font.GothamBold
aimBindButton.TextSize         = 12
aimBindButton.TextColor3       = Color3.fromRGB(255, 255, 255)
aimBindButton.Parent           = aimBindContainer

local aimBindCorner = Instance.new("UICorner")
aimBindCorner.CornerRadius = UDim.new(0, 6)
aimBindCorner.Parent = aimBindButton

local aimBindHint = makeLabel(aimbotPanel, "Hold Mouse2 to aim.", 7)

local function refreshBindText()
    local bindName = getBindDisplayText()
    aimBindButton.Text = "Rebind Aimbot Key: " .. bindName
    aimBindHint.Text = "Hold " .. bindName .. " to aim."
end

aimBindButton.MouseButton1Click:Connect(function()
    waitingForAimbotBind = true
    aimBindButton.Text = "Press any keyboard or mouse button..."
end)

makeColorPicker(aimbotPanel, "FOV Circle Color", 98, function(color)
    fovColor = color
end)

local nameToggle = makeToggle(visualsPanel, "Name ESP",       1, function(val) nameEnabled   = val end)
local healthToggle = makeToggle(visualsPanel, "Health Bar ESP", 2, function(val) healthEnabled = val end)
local chamsToggle = makeToggle(visualsPanel, "Chams ESP",      3, function(val) chamsEnabled  = val end)
local skeletonToggle = makeToggle(visualsPanel, "Skeleton ESP",   4, function(val) skeletonEnabled = val end)
local tracersToggle = makeToggle(visualsPanel, "Tracers ESP",    5, function(val) tracersEnabled = val end)
makeColorPicker(visualsPanel, "ESP Color", 98, function(color)
    espColor = color
end)

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

makeLabel(spectatePanel, "Spectate", 1)

local spectateStatus = makeLabel(spectatePanel, "Not spectating", 2)
spectateStatus.TextColor3 = COL_DIM

local stopSpectateFrame = Instance.new("Frame")
stopSpectateFrame.Size = UDim2.new(1, 0, 0, 40)
stopSpectateFrame.BackgroundColor3 = COL_PANEL_ALT
stopSpectateFrame.BorderSizePixel = 0
stopSpectateFrame.LayoutOrder = 3
stopSpectateFrame.Parent = spectatePanel

local stopSpectateFrameCorner = Instance.new("UICorner")
stopSpectateFrameCorner.CornerRadius = UDim.new(0, 8)
stopSpectateFrameCorner.Parent = stopSpectateFrame

local stopSpectateFrameStroke = Instance.new("UIStroke")
stopSpectateFrameStroke.Thickness = 1
stopSpectateFrameStroke.Color = COL_BORDER
stopSpectateFrameStroke.Transparency = 0.1
stopSpectateFrameStroke.Parent = stopSpectateFrame

local stopSpectateBtn = Instance.new("TextButton")
stopSpectateBtn.Size = UDim2.new(1, -8, 1, -8)
stopSpectateBtn.Position = UDim2.new(0, 4, 0, 4)
stopSpectateBtn.BackgroundColor3 = COL_PANEL
stopSpectateBtn.BorderSizePixel = 0
stopSpectateBtn.Text = "Stop Spectating"
stopSpectateBtn.Font = Enum.Font.GothamBold
stopSpectateBtn.TextSize = 12
stopSpectateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopSpectateBtn.Parent = stopSpectateFrame

local stopSpectateCorner = Instance.new("UICorner")
stopSpectateCorner.CornerRadius = UDim.new(0, 6)
stopSpectateCorner.Parent = stopSpectateBtn

local spectateList = Instance.new("ScrollingFrame")
spectateList.Size = UDim2.new(1, 0, 0, 220)
spectateList.BackgroundColor3 = COL_PANEL
spectateList.BorderSizePixel = 0
spectateList.LayoutOrder = 4
spectateList.AutomaticCanvasSize = Enum.AutomaticSize.None
spectateList.CanvasSize = UDim2.new(0, 0, 0, 0)
spectateList.ScrollBarThickness = 4
spectateList.Parent = spectatePanel

local spectateListCorner = Instance.new("UICorner")
spectateListCorner.CornerRadius = UDim.new(0, 8)
spectateListCorner.Parent = spectateList

local spectateListStroke = Instance.new("UIStroke")
spectateListStroke.Thickness = 1
spectateListStroke.Color = COL_BORDER
spectateListStroke.Transparency = 0.1
spectateListStroke.Parent = spectateList

local spectateListLayout = Instance.new("UIListLayout")
spectateListLayout.Padding = UDim.new(0, 4)
spectateListLayout.SortOrder = Enum.SortOrder.LayoutOrder
spectateListLayout.Parent = spectateList

local function stopSpectating()
    spectatingPlayer = nil
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local cam = getCurrentCamera()
    if hum and cam then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end
    spectateStatus.Text = "Not spectating"
end

local function spectatePlayer(player)
    if not player or player == LocalPlayer then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        task.spawn(showCustomNotification, "Player is not ready to spectate.", 5)
        return
    end
    local cam = getCurrentCamera()
    if not cam then
        task.spawn(showCustomNotification, "Camera is not ready yet.", 5)
        return
    end
    spectatingPlayer = player
    cam.CameraType = Enum.CameraType.Custom
    cam.CameraSubject = humanoid
    spectateStatus.Text = "Spectating: " .. getPlayerDisplayName(player)
end

local function rebuildSpectateList()
    for _, child in ipairs(spectateList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(candidates, player)
        end
    end

    table.sort(candidates, function(a, b)
        return string.lower(getPlayerDisplayName(a)) < string.lower(getPlayerDisplayName(b))
    end)

    for idx, player in ipairs(candidates) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -8, 0, 28)
        row.Position = UDim2.new(0, 4, 0, 0)
        row.BackgroundColor3 = COL_PANEL_ALT
        row.BorderSizePixel = 0
        row.LayoutOrder = idx
        row.Text = getPlayerDisplayName(player)
        row.Font = Enum.Font.GothamBold
        row.TextSize = 12
        row.TextColor3 = Color3.fromRGB(255, 255, 255)
        row.Parent = spectateList

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row

        row.MouseButton1Click:Connect(function()
            spectatePlayer(player)
        end)
    end

    spectateList.CanvasSize = UDim2.new(0, 0, 0, math.max(0, #candidates * 32 + 6))
end

stopSpectateBtn.MouseButton1Click:Connect(stopSpectating)
rebuildSpectateList()

local savedConfigs = {}
local selectedConfigName = nil

local CONFIGS_FILE = "IshKeb_Configs.json"
local function colorToTable(c)
    return {r = c.R, g = c.G, b = c.B}
end

local function tableToColor(t, fallback)
    if type(t) ~= "table" then return fallback end
    if type(t.r) ~= "number" or type(t.g) ~= "number" or type(t.b) ~= "number" then return fallback end
    return Color3.new(math.clamp(t.r, 0, 1), math.clamp(t.g, 0, 1), math.clamp(t.b, 0, 1))
end

local function serializeConfig(config)
    return {
        aimbotEnabled = config.aimbotEnabled,
        fovRadius = config.fovRadius,
        smoothnessValue = config.smoothnessValue,
        visibleOnly = config.visibleOnly,
        legitMode = config.legitMode,
        nameEnabled = config.nameEnabled,
        healthEnabled = config.healthEnabled,
        chamsEnabled = config.chamsEnabled,
        skeletonEnabled = config.skeletonEnabled,
        tracersEnabled = config.tracersEnabled,
        aimPartMode = config.aimPartMode,
        fovColor = colorToTable(config.fovColor),
        espColor = colorToTable(config.espColor),
        aimBindType = config.aimBindType,
        aimBindValueName = config.aimBindValue and config.aimBindValue.Name or "MouseButton2",
    }
end

local function deserializeConfig(config)
    if type(config) ~= "table" then return nil end
    local bindType = config.aimBindType == "KeyCode" and "KeyCode" or "UserInputType"
    local bindEnum = bindType == "KeyCode" and Enum.KeyCode[config.aimBindValueName or "Unknown"] or Enum.UserInputType[config.aimBindValueName or "MouseButton2"]
    if not bindEnum then
        bindType = "UserInputType"
        bindEnum = Enum.UserInputType.MouseButton2
    end

    return {
        aimbotEnabled = config.aimbotEnabled == true,
        fovRadius = tonumber(config.fovRadius) or fovRadius,
        smoothnessValue = tonumber(config.smoothnessValue) or 15,
        visibleOnly = config.visibleOnly == true,
        legitMode = config.legitMode == true,
        nameEnabled = config.nameEnabled == true,
        healthEnabled = config.healthEnabled == true,
        chamsEnabled = config.chamsEnabled == true,
        skeletonEnabled = config.skeletonEnabled == true,
        tracersEnabled = config.tracersEnabled == true,
        aimPartMode = type(config.aimPartMode) == "string" and config.aimPartMode or aimPartMode,
        fovColor = tableToColor(config.fovColor, fovColor),
        espColor = tableToColor(config.espColor, espColor),
        aimBindType = bindType,
        aimBindValue = bindEnum,
    }
end

local function saveConfigsToDisk()
    if not writefile then return end
    local serializable = {}
    for name, config in pairs(savedConfigs) do
        serializable[name] = serializeConfig(config)
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, serializable)
    if ok then
        pcall(writefile, CONFIGS_FILE, encoded)
    end
end

local function loadConfigsFromDisk()
    if not readfile or not isfile or not isfile(CONFIGS_FILE) then return end
    local okRead, contents = pcall(readfile, CONFIGS_FILE)
    if not okRead then return end
    local okDecode, parsed = pcall(HttpService.JSONDecode, HttpService, contents)
    if not okDecode or type(parsed) ~= "table" then return end
    for name, config in pairs(parsed) do
        local loaded = deserializeConfig(config)
        if loaded and type(name) == "string" and name ~= "" then
            savedConfigs[name] = loaded
        end
    end
end

makeLabel(configsPanel, "Configs", 1)

local configNameFrame = Instance.new("Frame")
configNameFrame.Size = UDim2.new(1, 0, 0, 40)
configNameFrame.BackgroundColor3 = COL_PANEL_ALT
configNameFrame.BorderSizePixel = 0
configNameFrame.LayoutOrder = 2
configNameFrame.Parent = configsPanel

local configNameFrameCorner = Instance.new("UICorner")
configNameFrameCorner.CornerRadius = UDim.new(0, 8)
configNameFrameCorner.Parent = configNameFrame

local configNameFrameStroke = Instance.new("UIStroke")
configNameFrameStroke.Thickness = 1
configNameFrameStroke.Color = COL_BORDER
configNameFrameStroke.Transparency = 0.1
configNameFrameStroke.Parent = configNameFrame

local configNameBox = Instance.new("TextBox")
configNameBox.Size = UDim2.new(1, -8, 1, -8)
configNameBox.Position = UDim2.new(0, 4, 0, 4)
configNameBox.BackgroundColor3 = COL_PANEL
configNameBox.BorderSizePixel = 0
configNameBox.PlaceholderText = "Config name (required)"
configNameBox.Text = ""
configNameBox.ClearTextOnFocus = false
configNameBox.Font = Enum.Font.GothamBold
configNameBox.TextSize = 12
configNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
configNameBox.PlaceholderColor3 = COL_DIM
configNameBox.Parent = configNameFrame

local configNameCorner = Instance.new("UICorner")
configNameCorner.CornerRadius = UDim.new(0, 6)
configNameCorner.Parent = configNameBox

local configDropdownFrame = Instance.new("Frame")
configDropdownFrame.Size = UDim2.new(1, 0, 0, 40)
configDropdownFrame.BackgroundColor3 = COL_PANEL_ALT
configDropdownFrame.BorderSizePixel = 0
configDropdownFrame.LayoutOrder = 3
configDropdownFrame.Parent = configsPanel

local configDropdownFrameCorner = Instance.new("UICorner")
configDropdownFrameCorner.CornerRadius = UDim.new(0, 8)
configDropdownFrameCorner.Parent = configDropdownFrame

local configDropdownFrameStroke = Instance.new("UIStroke")
configDropdownFrameStroke.Thickness = 1
configDropdownFrameStroke.Color = COL_BORDER
configDropdownFrameStroke.Transparency = 0.1
configDropdownFrameStroke.Parent = configDropdownFrame

local configDropdown = Instance.new("Frame")
configDropdown.Size = UDim2.new(1, -8, 1, -8)
configDropdown.Position = UDim2.new(0, 4, 0, 4)
configDropdown.BackgroundColor3 = COL_PANEL
configDropdown.BorderSizePixel = 0
configDropdown.Parent = configDropdownFrame

local configDropdownCorner = Instance.new("UICorner")
configDropdownCorner.CornerRadius = UDim.new(0, 6)
configDropdownCorner.Parent = configDropdown

local configDropdownButton = Instance.new("TextButton")
configDropdownButton.Size = UDim2.new(1, -36, 1, 0)
configDropdownButton.Position = UDim2.new(0, 10, 0, 0)
configDropdownButton.BackgroundTransparency = 1
configDropdownButton.Text = "Open Stored Configs"
configDropdownButton.Font = Enum.Font.GothamBold
configDropdownButton.TextSize = 12
configDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
configDropdownButton.TextXAlignment = Enum.TextXAlignment.Left
configDropdownButton.Parent = configDropdown

local configDropdownArrow = Instance.new("ImageLabel")
configDropdownArrow.Size = UDim2.new(0, 18, 0, 18)
configDropdownArrow.AnchorPoint = Vector2.new(1, 0.5)
configDropdownArrow.Position = UDim2.new(1, -10, 0.5, 0)
configDropdownArrow.BackgroundTransparency = 1
configDropdownArrow.Image = "rbxassetid://124463564041369"
configDropdownArrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
configDropdownArrow.Parent = configDropdown

local configListFrame = Instance.new("Frame")
configListFrame.Size = UDim2.new(1, 0, 0, 0)
configListFrame.BackgroundColor3 = COL_PANEL_ALT
configListFrame.BorderSizePixel = 0
configListFrame.LayoutOrder = 4
configListFrame.Visible = false
configListFrame.Parent = configsPanel

local configListCorner = Instance.new("UICorner")
configListCorner.CornerRadius = UDim.new(0, 6)
configListCorner.Parent = configListFrame

local configListLayout = Instance.new("UIListLayout")
configListLayout.Padding = UDim.new(0, 4)
configListLayout.SortOrder = Enum.SortOrder.LayoutOrder
configListLayout.Parent = configListFrame

local saveConfigFrame = Instance.new("Frame")
saveConfigFrame.Size = UDim2.new(1, 0, 0, 40)
saveConfigFrame.BackgroundColor3 = COL_PANEL_ALT
saveConfigFrame.BorderSizePixel = 0
saveConfigFrame.LayoutOrder = 5
saveConfigFrame.Parent = configsPanel

local saveConfigFrameCorner = Instance.new("UICorner")
saveConfigFrameCorner.CornerRadius = UDim.new(0, 8)
saveConfigFrameCorner.Parent = saveConfigFrame

local saveConfigFrameStroke = Instance.new("UIStroke")
saveConfigFrameStroke.Thickness = 1
saveConfigFrameStroke.Color = COL_BORDER
saveConfigFrameStroke.Transparency = 0.1
saveConfigFrameStroke.Parent = saveConfigFrame

local saveConfigBtn = Instance.new("TextButton")
saveConfigBtn.Size = UDim2.new(1, -8, 1, -8)
saveConfigBtn.Position = UDim2.new(0, 4, 0, 4)
saveConfigBtn.BackgroundColor3 = COL_PANEL
saveConfigBtn.BorderSizePixel = 0
saveConfigBtn.Text = "Save Config"
saveConfigBtn.Font = Enum.Font.GothamBold
saveConfigBtn.TextSize = 12
saveConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveConfigBtn.Parent = saveConfigFrame

local saveConfigCorner = Instance.new("UICorner")
saveConfigCorner.CornerRadius = UDim.new(0, 6)
saveConfigCorner.Parent = saveConfigBtn

local loadConfigFrame = Instance.new("Frame")
loadConfigFrame.Size = UDim2.new(1, 0, 0, 40)
loadConfigFrame.BackgroundColor3 = COL_PANEL_ALT
loadConfigFrame.BorderSizePixel = 0
loadConfigFrame.LayoutOrder = 6
loadConfigFrame.Parent = configsPanel

local loadConfigFrameCorner = Instance.new("UICorner")
loadConfigFrameCorner.CornerRadius = UDim.new(0, 8)
loadConfigFrameCorner.Parent = loadConfigFrame

local loadConfigFrameStroke = Instance.new("UIStroke")
loadConfigFrameStroke.Thickness = 1
loadConfigFrameStroke.Color = COL_BORDER
loadConfigFrameStroke.Transparency = 0.1
loadConfigFrameStroke.Parent = loadConfigFrame

local loadConfigBtn = Instance.new("TextButton")
loadConfigBtn.Size = UDim2.new(1, -8, 1, -8)
loadConfigBtn.Position = UDim2.new(0, 4, 0, 4)
loadConfigBtn.BackgroundColor3 = COL_PANEL
loadConfigBtn.BorderSizePixel = 0
loadConfigBtn.Text = "Load Config"
loadConfigBtn.Font = Enum.Font.GothamBold
loadConfigBtn.TextSize = 12
loadConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadConfigBtn.Parent = loadConfigFrame

local loadConfigCorner = Instance.new("UICorner")
loadConfigCorner.CornerRadius = UDim.new(0, 6)
loadConfigCorner.Parent = loadConfigBtn

local deleteLastConfigFrame = Instance.new("Frame")
deleteLastConfigFrame.Size = UDim2.new(1, 0, 0, 40)
deleteLastConfigFrame.BackgroundColor3 = COL_PANEL_ALT
deleteLastConfigFrame.BorderSizePixel = 0
deleteLastConfigFrame.LayoutOrder = 7
deleteLastConfigFrame.Parent = configsPanel

local deleteLastConfigFrameCorner = Instance.new("UICorner")
deleteLastConfigFrameCorner.CornerRadius = UDim.new(0, 8)
deleteLastConfigFrameCorner.Parent = deleteLastConfigFrame

local deleteLastConfigFrameStroke = Instance.new("UIStroke")
deleteLastConfigFrameStroke.Thickness = 1
deleteLastConfigFrameStroke.Color = COL_BORDER
deleteLastConfigFrameStroke.Transparency = 0.1
deleteLastConfigFrameStroke.Parent = deleteLastConfigFrame

local deleteLastConfigBtn = Instance.new("TextButton")
deleteLastConfigBtn.Size = UDim2.new(1, -8, 1, -8)
deleteLastConfigBtn.Position = UDim2.new(0, 4, 0, 4)
deleteLastConfigBtn.BackgroundColor3 = COL_PANEL
deleteLastConfigBtn.BorderSizePixel = 0
deleteLastConfigBtn.Text = "Delete Last Config"
deleteLastConfigBtn.Font = Enum.Font.GothamBold
deleteLastConfigBtn.TextSize = 12
deleteLastConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteLastConfigBtn.Parent = deleteLastConfigFrame

local deleteLastConfigCorner = Instance.new("UICorner")
deleteLastConfigCorner.CornerRadius = UDim.new(0, 6)
deleteLastConfigCorner.Parent = deleteLastConfigBtn

local deleteAllConfigsFrame = Instance.new("Frame")
deleteAllConfigsFrame.Size = UDim2.new(1, 0, 0, 40)
deleteAllConfigsFrame.BackgroundColor3 = COL_PANEL_ALT
deleteAllConfigsFrame.BorderSizePixel = 0
deleteAllConfigsFrame.LayoutOrder = 8
deleteAllConfigsFrame.Parent = configsPanel

local deleteAllConfigsFrameCorner = Instance.new("UICorner")
deleteAllConfigsFrameCorner.CornerRadius = UDim.new(0, 8)
deleteAllConfigsFrameCorner.Parent = deleteAllConfigsFrame

local deleteAllConfigsFrameStroke = Instance.new("UIStroke")
deleteAllConfigsFrameStroke.Thickness = 1
deleteAllConfigsFrameStroke.Color = COL_BORDER
deleteAllConfigsFrameStroke.Transparency = 0.1
deleteAllConfigsFrameStroke.Parent = deleteAllConfigsFrame

local deleteAllConfigsBtn = Instance.new("TextButton")
deleteAllConfigsBtn.Size = UDim2.new(1, -8, 1, -8)
deleteAllConfigsBtn.Position = UDim2.new(0, 4, 0, 4)
deleteAllConfigsBtn.BackgroundColor3 = COL_PANEL
deleteAllConfigsBtn.BorderSizePixel = 0
deleteAllConfigsBtn.Text = "Delete All Configs"
deleteAllConfigsBtn.Font = Enum.Font.GothamBold
deleteAllConfigsBtn.TextSize = 12
deleteAllConfigsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteAllConfigsBtn.Parent = deleteAllConfigsFrame

local deleteAllConfigsCorner = Instance.new("UICorner")
deleteAllConfigsCorner.CornerRadius = UDim.new(0, 6)
deleteAllConfigsCorner.Parent = deleteAllConfigsBtn

local function getConfigSnapshot()
    return {
        aimbotEnabled = aimbotEnabled,
        fovRadius = fovRadius,
        smoothnessValue = smoothnessSlider.getValue(),
        visibleOnly = visibleOnly,
        legitMode = legitMode,
        nameEnabled = nameEnabled,
        healthEnabled = healthEnabled,
        chamsEnabled = chamsEnabled,
        skeletonEnabled = skeletonEnabled,
        tracersEnabled = tracersEnabled,
        aimPartMode = aimPartMode,
        fovColor = fovColor,
        espColor = espColor,
        aimBindType = aimBindType,
        aimBindValue = aimBindValue,
    }
end

local function applyConfig(config)
    if not config then return end
    aimbotToggle.setState(config.aimbotEnabled, true)
    fovSlider.setValue(config.fovRadius, true)
    smoothnessSlider.setValue(config.smoothnessValue, true)
    visibleToggle.setState(config.visibleOnly, true)
    legitToggle.setState(config.legitMode, true)

    nameToggle.setState(config.nameEnabled, true)
    healthToggle.setState(config.healthEnabled, true)
    chamsToggle.setState(config.chamsEnabled, true)
    skeletonToggle.setState(config.skeletonEnabled, true)
    tracersToggle.setState(config.tracersEnabled, true)

    fovColor = config.fovColor
    espColor = config.espColor

    if partToggles[config.aimPartMode] then
        partToggles[config.aimPartMode].setState(true, true)
    end

    if config.aimBindType and config.aimBindValue then
        aimBindType = config.aimBindType
        aimBindValue = config.aimBindValue
        refreshBindText()
    end
end

local function getSortedConfigNames()
    local names = {}
    for name, _ in pairs(savedConfigs) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function rebuildConfigList()
    for _, child in ipairs(configListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local names = getSortedConfigNames()

    if #names == 0 then
        selectedConfigName = nil
    else
        if not selectedConfigName or not savedConfigs[selectedConfigName] then
            selectedConfigName = names[1]
        end
    end

    for idx, name in ipairs(names) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, -8, 0, 28)
        option.Position = UDim2.new(0, 4, 0, 0)
        option.BackgroundColor3 = COL_PANEL
        option.BorderSizePixel = 0
        option.LayoutOrder = idx
        option.Text = name
        option.Font = Enum.Font.GothamBold
        option.TextSize = 12
        option.TextColor3 = Color3.fromRGB(255, 255, 255)
        option.Parent = configListFrame

        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 6)
        optionCorner.Parent = option

        option.MouseButton1Click:Connect(function()
            selectedConfigName = name
            configListFrame.Visible = false
            configListFrame.Size = UDim2.new(1, 0, 0, 0)
        end)
    end

    configListFrame.Size = configListFrame.Visible and UDim2.new(1, 0, 0, math.max(0, #names * 32 + 6)) or UDim2.new(1, 0, 0, 0)
end

configDropdownButton.MouseButton1Click:Connect(function()
    if next(savedConfigs) == nil then
        task.spawn(showCustomNotification, "No configs detected, Make one to open.", 5)
        return
    end
    configListFrame.Visible = not configListFrame.Visible
    rebuildConfigList()
end)

saveConfigBtn.MouseButton1Click:Connect(function()
    local name = string.gsub(configNameBox.Text, "^%s*(.-)%s*$", "%1")
    if name == "" then
        task.spawn(showCustomNotification, "Config name is required.", 5)
        return
    end
    savedConfigs[name] = getConfigSnapshot()
    selectedConfigName = name
    configNameBox.Text = name
    saveConfigsToDisk()
    rebuildConfigList()
end)

loadConfigBtn.MouseButton1Click:Connect(function()
    if not selectedConfigName then return end
    applyConfig(savedConfigs[selectedConfigName])
end)

deleteLastConfigBtn.MouseButton1Click:Connect(function()
    local names = getSortedConfigNames()
    local lastName = names[#names]
    if not lastName then return end
    savedConfigs[lastName] = nil
    if selectedConfigName == lastName then
        selectedConfigName = nil
    end
    saveConfigsToDisk()
    rebuildConfigList()
end)

deleteAllConfigsBtn.MouseButton1Click:Connect(function()
    savedConfigs = {}
    selectedConfigName = nil
    saveConfigsToDisk()
    rebuildConfigList()
end)

loadConfigsFromDisk()
rebuildConfigList()

local scriptStart = os.clock()
local function formatClock(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function updateHomeStats()
    local currentPlayers = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers
    statsRows.serverPlayers.Text = string.format("Players: %d/%d", currentPlayers, maxPlayers)
    statsRows.uptime.Text = "Session Uptime: " .. formatClock(os.clock() - scriptStart)

    local memoryMb = math.floor(collectgarbage("count") / 1024)
    local totalMemory = StatsService:GetTotalMemoryUsageMb()
    statsRows.memory.Text = string.format("Client Memory: %d MB (Total %.0f MB)", memoryMb, totalMemory)
end

Players.PlayerAdded:Connect(updateHomeStats)
Players.PlayerRemoving:Connect(updateHomeStats)
Players.PlayerAdded:Connect(rebuildSpectateList)
Players.PlayerRemoving:Connect(function(player)
    if spectatingPlayer == player then
        stopSpectating()
    end
    rebuildSpectateList()
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Thickness = 1.5
fovCircle.Color     = fovColor
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
    pcall(function() obj.tracer:Remove() end)
    if obj.skeletonLines then
        for _, line in ipairs(obj.skeletonLines) do
            pcall(function() line:Remove() end)
        end
    end
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
        tracer    = newDrawing("Line",   {Visible=false, Thickness=1.5, Color=espColor}),
        skeletonLines = {
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
            newDrawing("Line", {Visible=false, Thickness=1.5, Color=espColor}),
        },
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

local function getPart(character, names)
    for _, name in ipairs(names) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function getSkeletonSegments(character)
    local head = getPart(character, {"Head"})
    local neck = getPart(character, {"UpperTorso", "Torso"})
    local root = getPart(character, {"HumanoidRootPart", "LowerTorso", "Torso"})
    local lArm = getPart(character, {"LeftHand", "LeftLowerArm", "LeftUpperArm", "Left Arm"})
    local rArm = getPart(character, {"RightHand", "RightLowerArm", "RightUpperArm", "Right Arm"})
    local lLeg = getPart(character, {"LeftFoot", "LeftLowerLeg", "LeftUpperLeg", "Left Leg"})
    local rLeg = getPart(character, {"RightFoot", "RightLowerLeg", "RightUpperLeg", "Right Leg"})

    if not (head and neck and root) then
        return nil
    end

    return {
        {head, neck},
        {neck, root},
        {neck, lArm},
        {neck, rArm},
        {root, lLeg},
        {root, rLeg},
    }
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
    if waitingForAimbotBind then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            aimBindType = "KeyCode"
            aimBindValue = input.KeyCode
            waitingForAimbotBind = false
            refreshBindText()
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            aimBindType = "UserInputType"
            aimBindValue = input.UserInputType
            waitingForAimbotBind = false
            refreshBindText()
            return
        end
    end

    if inputMatchesAimbotBind(input) then
        m2Held = true
        return
    end
    if gpe then return end
end)

UserInputService.InputEnded:Connect(function(input)
    if inputMatchesAimbotBind(input) then
        m2Held      = false
        lockedTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    updateHomeStats()
    if spectatingPlayer then
        local character = spectatingPlayer.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local cam = getCurrentCamera()
        if hum and hum.Health > 0 and cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
        else
            stopSpectating()
        end
    end
    local mousePos = getMousePos()

    fovCircle.Visible = aimbotEnabled
    fovCircle.Radius  = fovRadius
    fovCircle.Position = mousePos
    fovCircle.Color = fovColor

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
                            or (hardLockOn and 1 or clampLerpAlpha(smoothness))
                        local newPos   = currentSmoothness >= 1 and target or current:Lerp(target, currentSmoothness)
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
            obj.nameTag.Color     = espColor
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
            local width  = math.max(24, height * 0.6)
            local hp    = humanoid.Health
            local maxHp = humanoid.MaxHealth
            local ratio = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
            local barW  = 4
            local bx    = (topSP.X - (width * 0.5)) - HEALTH_BAR_OFFSET
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

        if obj.tracer then
            if tracersEnabled and visible then
                local tracerOrigin = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y - 2)
                obj.tracer.Visible = true
                obj.tracer.From = tracerOrigin
                local rootSp, rootIn = worldToScreen(root.Position)
                obj.tracer.Visible = rootIn
                obj.tracer.To = rootSp
                obj.tracer.Color = espColor
            else
                obj.tracer.Visible = false
            end
        end

        if obj.skeletonLines then
            if skeletonEnabled and visible then
                local segments = getSkeletonSegments(character)
                if segments then
                    for i, line in ipairs(obj.skeletonLines) do
                        local seg = segments[i]
                        if seg and seg[1] and seg[2] then
                            local a, aIn = worldToScreen(seg[1].Position)
                            local b, bIn = worldToScreen(seg[2].Position)
                            line.Visible = aIn and bIn
                            line.From = a
                            line.To = b
                            line.Color = espColor
                        else
                            line.Visible = false
                        end
                    end
                else
                    for _, line in ipairs(obj.skeletonLines) do
                        line.Visible = false
                    end
                end
            else
                for _, line in ipairs(obj.skeletonLines) do
                    line.Visible = false
                end
            end
        end

        if obj.highlight then
            obj.highlight.Adornee = character
            obj.highlight.FillColor = espColor
            obj.highlight.Enabled = chamsEnabled and visible and (character ~= nil)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        local wasVisible = MainFrame.Visible
        MainFrame.Visible = not MainFrame.Visible
        if wasVisible and not firstCloseNotificationShown then
            firstCloseNotificationShown = true
            task.spawn(showFirstCloseNotification)
        end
    end
end)

local funFacts = {
    "Bananas are berries, but strawberries are not.",
    "Octopuses have three hearts.",
    "A day on Venus is longer than a year on Venus.",
    "Honey never spoils if sealed properly.",
    "Wombat poop is cube-shaped.",
    "Sharks existed before trees.",
    "Some turtles can breathe through their butts.",
    "The Eiffel Tower can grow taller in summer heat.",
    "There are more possible chess games than atoms in the observable universe.",
    "Koalas have fingerprints very similar to humans.",
}

local function pickRandomFunFact()
    return funFacts[math.random(1, #funFacts)]
end

task.spawn(function()
    math.randomseed(tick() * 1000 + LocalPlayer.UserId)
    LoadTitle.Text = "Installing Modules..."
    LoadStatus.Text = "Installing Modules..."
    LoadSub.Text = "Fun fact: " .. pickRandomFunFact()

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
            LoadStatus.Text = "Installing Modules..."
        end
        if phase.pause then
            LoadSub.Text = "Fun fact: " .. pickRandomFunFact()
            task.wait(phase.pause)
        end
    end

    ProgressFill.Size = UDim2.new(1, 0, 1, 0)
    LoadStatus.Text = "Installing Modules..."
    task.wait(0.35)

    LoadFrame:Destroy()
    switchTab("Home")
    MainFrame.Visible = true
end)
