local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

local UI_PARENT = game.CoreGui
pcall(function()
    if typeof(gethui) == "function" then
        local h = gethui()
        if h then UI_PARENT = h end
    end
end)

pcall(function()
    local old = UI_PARENT:FindFirstChild("SchizoUI")
    if old then old:Destroy() end
end)
pcall(function()
    local oldCC = Lighting:FindFirstChild("SchizoColorCorrection")
    if oldCC then oldCC:Destroy() end
    local oldBlur = Lighting:FindFirstChild("SchizoBlur")
    if oldBlur then oldBlur:Destroy() end
end)

local State = {
    enabled = false,
    intensity = 5,
    lastEventAt = tick(),
    currentDelay = 10,
    busy = false,
}

pcall(function()
    if typeof(readfile) == "function" then
        local ok, data = pcall(readfile, "schizo_state.json")
        if ok and data and data ~= "" then
            local ok2, d = pcall(HttpService.JSONDecode, HttpService, data)
            if ok2 and type(d) == "table" and d.intensity then
                State.intensity = math.clamp(tonumber(d.intensity) or 5, 1, 10)
            end
        end
    end
end)

local function saveState()
    pcall(function()
        if typeof(writefile) == "function" then
            writefile("schizo_state.json", HttpService:JSONEncode({ intensity = State.intensity }))
        end
    end)
end

local activeSounds = {}
local function playSound(id, volume, pitch, parent)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.5
    s.PlaybackSpeed = pitch or 1
    s.Parent = parent or SoundService
    table.insert(activeSounds, s)

    local cleaned = false
    local function clean()
        if cleaned then return end
        cleaned = true
        for i, v in ipairs(activeSounds) do
            if v == s then table.remove(activeSounds, i) break end
        end
        pcall(function() s:Destroy() end)
    end

    s.Ended:Connect(clean)
    task.delay(20, clean)
    pcall(function() s:Play() end)
    return s
end

local function stopAllSounds()
    for _, s in ipairs(activeSounds) do
        pcall(function() s:Stop() s:Destroy() end)
    end
    activeSounds = {}
end

local SND_CROWD  = "rbxassetid://6042053626"
local SND_CLICK  = "rbxassetid://131961136"
local SND_NOTIFY = "rbxassetid://9120386436"

local namePrefixes = {"User", "Guest", "Unknown", "Anon", "Null", "Void", "Silent", "Hidden", "Shadow", "Echo", "Whisper", "Static"}
local function randomName()
    return namePrefixes[math.random(1, #namePrefixes)] .. "_" .. math.random(100, 9999)
end

-- ============================================================
-- World color / lighting effects
-- ============================================================

local function makeColorCorrection()
    local cc = Lighting:FindFirstChild("SchizoColorCorrection")
    if cc then return cc end
    cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "SchizoColorCorrection"
    cc.Brightness = 0
    cc.Contrast = 0
    cc.Saturation = 0
    cc.TintColor = Color3.fromRGB(255, 255, 255)
    cc.Parent = Lighting
    return cc
end

local function makeBlur()
    local b = Lighting:FindFirstChild("SchizoBlur")
    if b then return b end
    b = Instance.new("BlurEffect")
    b.Name = "SchizoBlur"
    b.Size = 0
    b.Parent = Lighting
    return b
end

local colorActive = false
local function evColorShift()
    if colorActive then return end
    colorActive = true

    local cc = makeColorCorrection()

    local palettes = {
        { tint = Color3.fromRGB(170, 90, 255), sat = -0.4, con = 0.15, bri = -0.05 },
        { tint = Color3.fromRGB(255, 60, 80),  sat = -0.5, con = 0.2,  bri = -0.1 },
        { tint = Color3.fromRGB(80, 220, 140), sat = -0.35, con = 0.1, bri = -0.05 },
        { tint = Color3.fromRGB(80, 130, 255), sat = -0.45, con = 0.2, bri = -0.08 },
        { tint = Color3.fromRGB(255, 200, 100), sat = -0.6, con = 0.25, bri = -0.15 },
        { tint = Color3.fromRGB(200, 200, 200), sat = -1,   con = 0.3,  bri = -0.2 },
    }

    local p = palettes[math.random(1, #palettes)]

    local inInfo = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(cc, inInfo, {
        TintColor = p.tint,
        Saturation = p.sat,
        Contrast = p.con,
        Brightness = p.bri,
    }):Play()

    local holdTime = 2.5 + math.random() * 2.5
    task.wait(holdTime)

    local outInfo = TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    TweenService:Create(cc, outInfo, {
        TintColor = Color3.fromRGB(255, 255, 255),
        Saturation = 0,
        Contrast = 0,
        Brightness = 0,
    }):Play()

    task.wait(1.5)
    colorActive = false
end

local function evDesaturateFlash()
    local cc = makeColorCorrection()
    local origSat = cc.Saturation
    local origCon = cc.Contrast

    TweenService:Create(cc, TweenInfo.new(0.2), { Saturation = -0.9, Contrast = 0.4 }):Play()
    task.wait(0.35)
    TweenService:Create(cc, TweenInfo.new(0.9), { Saturation = origSat, Contrast = origCon }):Play()
    task.wait(1)
end

local function evBlurVision()
    local b = makeBlur()
    TweenService:Create(b, TweenInfo.new(0.4), { Size = 12 + math.random(0, 8) }):Play()
    task.wait(1.5 + math.random() * 1.5)
    TweenService:Create(b, TweenInfo.new(1.2), { Size = 0 }):Play()
    task.wait(1.3)
end

local function evDoubleVision()
    local cc = makeColorCorrection()
    local origCon = cc.Contrast
    local origBri = cc.Brightness
    TweenService:Create(cc, TweenInfo.new(0.3), { Contrast = -0.2, Brightness = 0.15 }):Play()
    task.wait(0.9)
    TweenService:Create(cc, TweenInfo.new(0.5), { Contrast = origCon, Brightness = origBri }):Play()
    task.wait(0.7)
end

-- ============================================================
-- Audio events
-- ============================================================

local function evWhisper()
    local s = playSound(SND_CROWD, 0.35, 0.35 + math.random() * 0.1)
    task.delay(3, function()
        if s then pcall(function() s:Stop() end) end
    end)
end

local function evBreathing()
    playSound(SND_CLICK, 0.45, 0.28)
    task.wait(0.65)
    playSound(SND_CLICK, 0.45, 0.31)
    task.wait(0.75)
    playSound(SND_CLICK, 0.45, 0.27)
end

local function evFootsteps()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = cam.CFrame * CFrame.new(0, 0, 5 + math.random(0, 4))
    anchor.Parent = Workspace

    for i = 1, 5 do
        playSound(SND_CLICK, 0.3, 0.85 + math.random() * 0.1, anchor)
        task.wait(0.32)
    end
    task.delay(2, function() pcall(function() anchor:Destroy() end) end)
end

local function evLaughter()
    playSound(SND_NOTIFY, 0.4, 0.42 + math.random() * 0.1)
    task.wait(0.5)
    playSound(SND_NOTIFY, 0.35, 0.38)
end

local function evNameCalled()
    playSound(SND_CROWD, 0.55, 0.5)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 280, 0, 32)
    lbl.Position = UDim2.new(0.5, -140, 0.72, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = LocalPlayer.DisplayName .. "..."
    lbl.TextColor3 = Color3.fromRGB(230, 200, 255)
    lbl.TextSize = 20
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 1
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextTransparency = 1
    lbl.ZIndex = 600
    lbl.Parent = ScreenGui
    corner(lbl, 6)

    TweenService:Create(lbl, TweenInfo.new(0.4), {
        BackgroundTransparency = 0.45,
        TextTransparency = 0,
        TextStrokeTransparency = 0,
    }):Play()
    task.wait(2)
    TweenService:Create(lbl, TweenInfo.new(0.7), {
        BackgroundTransparency = 1,
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    }):Play()
    task.wait(0.8)
    pcall(function() lbl:Destroy() end)
end

-- ============================================================
-- Camera events
-- ============================================================

local function evCameraShake()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local endTime = tick() + 0.5
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if tick() > endTime or not cam.Parent then
            if conn then conn:Disconnect() end
            return
        end
        local fade = (endTime - tick()) / 0.5
        local amp = 0.5 * fade
        cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
    end)
end

local fovActive = false
local function evFovPulse()
    if fovActive then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    fovActive = true
    local base = cam.FieldOfView
    TweenService:Create(cam, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { FieldOfView = base + 15 + math.random(0, 10) }):Play()
    task.wait(0.5)
    TweenService:Create(cam, TweenInfo.new(1.1, Enum.EasingStyle.Sine), { FieldOfView = base }):Play()
    task.wait(1.2)
    fovActive = false
end

local function evCameraRoll()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local startCF = cam.CFrame
    local rollAmount = (math.random() - 0.5) * 0.35
    local endTime = tick() + 1.8
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local t = 1 - ((endTime - tick()) / 1.8)
        if t >= 1 or not cam.Parent then
            if conn then conn:Disconnect() end
            return
        end
        local roll = rollAmount * math.sin(t * math.pi)
        cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, roll)
    end)
    task.wait(1.9)
end

-- ============================================================
-- Visual overlay events
-- ============================================================

local function evScreenTint()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = Color3.fromRGB(90, 0, 40)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = 500
    f.Parent = ScreenGui
    TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.75 }):Play()
    task.wait(0.5)
    TweenService:Create(f, TweenInfo.new(1, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    task.wait(1.1)
    pcall(function() f:Destroy() end)
end

local function evVignette()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = 500
    f.Parent = ScreenGui
    TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.45 }):Play()
    task.wait(0.7)
    TweenService:Create(f, TweenInfo.new(1, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    task.wait(1.1)
    pcall(function() f:Destroy() end)
end

-- ============================================================
-- World events
-- ============================================================

local function evSilhouette()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    local side = math.random(-1, 1)
    if side == 0 then side = 1 end
    anchor.CFrame = hrp.CFrame * CFrame.new(side * (15 + math.random(0, 15)), 2, -20 - math.random(0, 15))
    anchor.Parent = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 60, 0, 130)
    bb.AlwaysOnTop = false
    bb.Adornee = anchor
    bb.Parent = anchor

    local silhouette = Instance.new("Frame")
    silhouette.Size = UDim2.new(1, 0, 1, 0)
    silhouette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    silhouette.BackgroundTransparency = 1
    silhouette.BorderSizePixel = 0
    silhouette.Parent = bb
    corner(silhouette, 24)

    TweenService:Create(silhouette, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.1 }):Play()
    task.wait(1.5 + math.random() * 1.5)
    TweenService:Create(silhouette, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    task.wait(0.7)
    pcall(function() anchor:Destroy() end)
end

local function evFakePlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = hrp.CFrame * CFrame.new((math.random() - 0.5) * 40, 3, -25 - math.random(0, 20))
    anchor.Parent = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 140, 0, 24)
    bb.AlwaysOnTop = true
    bb.Adornee = anchor
    bb.Parent = anchor

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = randomName()
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextTransparency = 1
    lbl.Parent = bb

    TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { TextTransparency = 0 }):Play()
    task.wait(2 + math.random() * 2)
    TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { TextTransparency = 1 }):Play()
    task.wait(0.6)
    pcall(function() anchor:Destroy() end)
end

local function evFakeKill()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 62)
    f.Position = UDim2.new(0, 0, 0.25, 0)
    f.BackgroundColor3 = Color3.fromRGB(120, 20, 30)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = 600
    f.Parent = ScreenGui

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "You were killed by " .. randomName()
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 20
    lbl.Font = Enum.Font.GothamBold
    lbl.TextTransparency = 1
    lbl.Parent = f

    TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.15 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { TextTransparency = 0 }):Play()
    task.wait(2.2)
    TweenService:Create(f, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { TextTransparency = 1 }):Play()
    task.wait(0.9)
    pcall(function() f:Destroy() end)
end

local function evFakeHealthDrop()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 220, 0, 22)
    f.Position = UDim2.new(0.5, -110, 0, 60)
    f.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0
    f.ZIndex = 600
    f.Parent = ScreenGui
    corner(f, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, -4, 1, -4)
    fill.Position = UDim2.new(0, 2, 0, 2)
    fill.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    fill.BorderSizePixel = 0
    fill.Parent = f
    corner(fill, 3)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "❤ 100"
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.ZIndex = 601
    lbl.Parent = f

    TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Size = UDim2.new(0.12, 0, 1, -4) }):Play()
    task.wait(0.4)
    lbl.Text = "❤ 12"
    task.wait(1.4)
    TweenService:Create(f, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(fill, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.7, Enum.EasingStyle.Sine), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    task.wait(0.8)
    pcall(function() f:Destroy() end)
end

local chatMessages = {
    "who's there",
    "stop following me",
    "we see you",
    "you're not alone",
    "behind you",
    "did you hear that",
    "they're watching",
    "don't turn around",
    "you can't hide",
    "I'm right here",
    "look behind you",
    "we're waiting",
    "hello?",
    "are you there",
    "it's so cold",
    "come closer",
    "why did you do it",
}
local chatUsers = {"???", "Unknown", "System", "NULL", "you", "them", "him", "it", "Everyone"}

local function evFakeChat()
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 320, 0, 26)
    box.Position = UDim2.new(0, 12, 0.15, 0)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.ZIndex = 600
    box.Parent = ScreenGui
    corner(box, 4)

    local user = chatUsers[math.random(1, #chatUsers)]
    local msg = chatMessages[math.random(1, #chatMessages)]

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. user .. "]: " .. msg
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextStrokeTransparency = 1
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextTransparency = 1
    lbl.ZIndex = 601
    lbl.Parent = box

    TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.35 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
    task.wait(4)
    TweenService:Create(box, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    task.wait(0.9)
    pcall(function() box:Destroy() end)
end

-- ============================================================
-- Build UI
-- ============================================================

local buildOk, buildErr = pcall(function()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SchizoUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = UI_PARENT

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
    return c
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 200)
Main.Position = UDim2.new(0.5, -150, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(18, 12, 26)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
corner(Main, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 30)
Title.Position = UDim2.new(0, 14, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "Schizophrenia"
Title.TextColor3 = Color3.fromRGB(210, 160, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -36, 0, 9)
Close.BackgroundColor3 = Color3.fromRGB(180, 40, 70)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 15
Close.Font = Enum.Font.GothamBold
Close.Parent = Main
corner(Close, 6)

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -28, 0, 72)
Toggle.Position = UDim2.new(0, 14, 0, 48)
Toggle.BackgroundColor3 = Color3.fromRGB(38, 26, 52)
Toggle.Text = "Schizophrenia: OFF"
Toggle.TextColor3 = Color3.fromRGB(200, 150, 255)
Toggle.TextSize = 17
Toggle.Font = Enum.Font.GothamBold
Toggle.Parent = Main
corner(Toggle, 10)

local IntensityLabel = Instance.new("TextLabel")
IntensityLabel.Size = UDim2.new(1, -28, 0, 20)
IntensityLabel.Position = UDim2.new(0, 14, 0, 128)
IntensityLabel.BackgroundTransparency = 1
IntensityLabel.Text = "Intensity: " .. State.intensity
IntensityLabel.TextColor3 = Color3.fromRGB(180, 175, 195)
IntensityLabel.TextSize = 13
IntensityLabel.Font = Enum.Font.Gotham
IntensityLabel.TextXAlignment = Enum.TextXAlignment.Left
IntensityLabel.Parent = Main

local IntBar = Instance.new("TextButton")
IntBar.Size = UDim2.new(1, -28, 0, 20)
IntBar.Position = UDim2.new(0, 14, 0, 152)
IntBar.BackgroundColor3 = Color3.fromRGB(42, 32, 56)
IntBar.Text = ""
IntBar.AutoButtonColor = false
IntBar.Parent = Main
corner(IntBar, 10)

local IntFill = Instance.new("Frame")
IntFill.Size = UDim2.new((State.intensity - 1) / 9, 0, 1, 0)
IntFill.BackgroundColor3 = Color3.fromRGB(165, 100, 230)
IntFill.BorderSizePixel = 0
IntFill.Parent = IntBar
corner(IntFill, 10)

local function setIntensity(v)
    State.intensity = math.clamp(math.floor(v + 0.5), 1, 10)
    IntensityLabel.Text = "Intensity: " .. State.intensity
    IntFill.Size = UDim2.new((State.intensity - 1) / 9, 0, 1, 0)
    saveState()
end

local draggingInt = false
local function intFromX(x)
    local rel = math.clamp((x - IntBar.AbsolutePosition.X) / math.max(IntBar.AbsoluteSize.X, 1), 0, 1)
    setIntensity(1 + rel * 9)
end

IntBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingInt = true
        intFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingInt and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        intFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingInt = false
    end
end)

local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 52, 0, 52)
Icon.Position = UDim2.new(0, 120, 0, 120)
Icon.BackgroundColor3 = Color3.fromRGB(80, 40, 140)
Icon.Text = "👁"
Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
Icon.TextSize = 28
Icon.Font = Enum.Font.GothamBold
Icon.Visible = false
Icon.Parent = ScreenGui
corner(Icon, 26)

local function showMain(show)
    Main.Visible = show
    Icon.Visible = not show
end

Close.MouseButton1Click:Connect(function() showMain(false) end)
Icon.MouseButton1Click:Connect(function() showMain(true) end)

local draggingIcon = false
local dragStart, startPos
Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingIcon = true
        dragStart = input.Position
        startPos = Icon.Position
    end
end)
Icon.InputChanged:Connect(function(input)
    if draggingIcon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingIcon = false
    end
end)

local eventList = {
    { fn = evWhisper,         weight = 3 },
    { fn = evBreathing,       weight = 3 },
    { fn = evFootsteps,       weight = 2 },
    { fn = evLaughter,        weight = 2 },
    { fn = evNameCalled,      weight = 2 },
    { fn = evCameraShake,     weight = 2 },
    { fn = evFovPulse,        weight = 2 },
    { fn = evCameraRoll,      weight = 2 },
    { fn = evScreenTint,      weight = 2 },
    { fn = evVignette,        weight = 2 },
    { fn = evSilhouette,      weight = 3 },
    { fn = evFakePlayer,      weight = 2 },
    { fn = evFakeKill,        weight = 2 },
    { fn = evFakeHealthDrop,  weight = 2 },
    { fn = evFakeChat,        weight = 4 },
    { fn = evColorShift,      weight = 3 },
    { fn = evDesaturateFlash, weight = 2 },
    { fn = evBlurVision,      weight = 2 },
    { fn = evDoubleVision,    weight = 2 },
}

local function pickEvent()
    local total = 0
    for _, e in ipairs(eventList) do total = total + e.weight end
    local r = math.random() * total
    local acc = 0
    for _, e in ipairs(eventList) do
        acc = acc + e.weight
        if r <= acc then return e.fn end
    end
    return eventList[1].fn
end

task.spawn(function()
    State.currentDelay = 10
    while true do
        task.wait(0.5)
        if State.enabled and not State.busy then
            if tick() - State.lastEventAt >= State.currentDelay then
                State.busy = true
                State.lastEventAt = tick()
                local minSec = 15 - (State.intensity - 1) * 1.33
                local maxSec = 30 - (State.intensity - 1) * 2.55
                State.currentDelay = minSec + math.random() * (maxSec - minSec)
                task.spawn(function()
                    pcall(pickEvent())
                    task.wait(0.5)
                    State.busy = false
                end)
            end
        end
    end
end)

local function updateToggleVisual()
    if State.enabled then
        TweenService:Create(Toggle, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(130, 60, 200) }):Play()
        Toggle.Text = "Schizophrenia: ON"
    else
        TweenService:Create(Toggle, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(38, 26, 52) }):Play()
        Toggle.Text = "Schizophrenia: OFF"
    end
end

local function restoreLighting()
    local cc = Lighting:FindFirstChild("SchizoColorCorrection")
    if cc then
        TweenService:Create(cc, TweenInfo.new(0.8), {
            TintColor = Color3.fromRGB(255, 255, 255),
            Saturation = 0,
            Contrast = 0,
            Brightness = 0,
        }):Play()
        task.delay(1, function()
            if cc and cc.Parent then cc:Destroy() end
        end)
    end
    local b = Lighting:FindFirstChild("SchizoBlur")
    if b then
        TweenService:Create(b, TweenInfo.new(0.6), { Size = 0 }):Play()
        task.delay(0.8, function()
            if b and b.Parent then b:Destroy() end
        end)
    end
    colorActive = false
end

Toggle.MouseButton1Click:Connect(function()
    State.enabled = not State.enabled
    State.lastEventAt = tick()
    State.currentDelay = 2
    if not State.enabled then
        stopAllSounds()
        restoreLighting()
    else
        task.spawn(function()
            task.wait(1)
            pcall(evWhisper)
        end)
    end
    updateToggleVisual()
end)

updateToggleVisual()

end)

if not buildOk then
    warn("[Schizophrenia UI] Build error: " .. tostring(buildErr))
end

print("[Schizophrenia UI] Loaded.")
