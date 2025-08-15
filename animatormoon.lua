if _G.MoonAnimCore then return end
_G.MoonAnimCore = true

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local Dummy = workspace:FindFirstChild("Dummy") or workspace:FindFirstChild("MoonAnimatorDummy")
if not Dummy or not Dummy:FindFirstChild("Head") then
    warn("Dummy não encontrado ou incompleto.")
    return
end

local partsToRecord = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
local rootPartName = Dummy:FindFirstChild("HumanoidRootPart") and "HumanoidRootPart" or "RootPart"

local defaultPose = {}
for _, partName in pairs(partsToRecord) do
    local part = Dummy:FindFirstChild(partName)
    if part then
        defaultPose[partName] = part.CFrame
    end
end
local defaultRootCFrame = nil
if rootPartName then
    local rootPart = Dummy:FindFirstChild(rootPartName)
    if rootPart then
        defaultRootCFrame = rootPart.CFrame
        rootPart.Transparency = 1
        rootPart.CastShadow = false
    end
end

local animationData = {}

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MoonAnimatorTimeline"
gui.Parent = playerGui
gui.ResetOnSpawn = false
gui.Enabled = true

local orangeBtnColor = Color3.fromRGB(255, 140, 0)
local darkBtnColor = Color3.fromRGB(60, 40, 10)
local greyBtnColor = Color3.fromRGB(90, 90, 90)

-- Base GUI Frame (menor vertical e mais largo horizontal)
local uiBase = Instance.new("Frame", gui)
uiBase.Size = UDim2.new(0, 460, 0, 200)
uiBase.Position = UDim2.new(0, 20, 0.5, -100)
uiBase.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
uiBase.BorderSizePixel = 0
Instance.new("UICorner", uiBase)

local uiTitle = Instance.new("TextLabel", uiBase)
uiTitle.Size = UDim2.new(1, -10, 0, 25)
uiTitle.Position = UDim2.new(0, 5, 0, 3)
uiTitle.Text = "🌙 Moon Animator Lite v3.5"
uiTitle.TextColor3 = orangeBtnColor
uiTitle.Font = Enum.Font.GothamBold
uiTitle.TextSize = 16
uiTitle.BackgroundTransparency = 1
uiTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Função para criar botões comuns
local function createButton(parent, name, xPos, yPos, width, height, text, color)
    local btn = Instance.new("TextButton", parent)
    btn.Name = name
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(20, 20, 20)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = math.min(15, height - 6)
    btn.Text = text
    Instance.new("UICorner", btn)
    return btn
end

-- Linha 1: 5 botões, 88 largura, 28 altura, espaçamento 6px
local btnWidth, btnHeight, btnGap = 88, 28, 6
local btnY1 = 33
local addBtn = createButton(uiBase, "addKey", 10 + (btnWidth + btnGap) * 0, btnY1, btnWidth, btnHeight, "➕ Add Keyframe", orangeBtnColor)
local playBtn = createButton(uiBase, "play", 10 + (btnWidth + btnGap) * 1, btnY1, btnWidth, btnHeight, "▶️ Play", orangeBtnColor)
local loopBtn = createButton(uiBase, "loop", 10 + (btnWidth + btnGap) * 2, btnY1, btnWidth, btnHeight, "🔁 Loop: OFF", greyBtnColor)
local resetBtn = createButton(uiBase, "reset", 10 + (btnWidth + btnGap) * 3, btnY1, btnWidth, btnHeight, "♻️ Reset Pose", orangeBtnColor)
local clearBtn = createButton(uiBase, "clear", 10 + (btnWidth + btnGap) * 4, btnY1, btnWidth, btnHeight, "🧼 Clear Keys", orangeBtnColor)

-- Linha 2: Velocidade e Slots Toggle, largura 140, altura 28
local btnWidth2 = 140
local btnY2 = 68
local speedDownBtn = createButton(uiBase, "speedDown", 10, btnY2, 65, btnHeight, "🐢 Speed -", orangeBtnColor)
local speedUpBtn = createButton(uiBase, "speedUp", 10 + 65 + 10, btnY2, 65, btnHeight, "⚡ Speed +", orangeBtnColor)
local slotsToggleBtn = createButton(uiBase, "slotsToggle", 10 + 140 + 20, btnY2, 140, btnHeight, "📁 Slots", orangeBtnColor)

-- Linha 3: Input + Save/Load buttons
local inputName = Instance.new("TextBox", uiBase)
inputName.Size = UDim2.new(0, 210, 0, 28)
inputName.Position = UDim2.new(0, 10, 0, 105)
inputName.PlaceholderText = "Colar StdLtAssetID aqui"
inputName.ClearTextOnFocus = false
inputName.Text = ""
inputName.BackgroundColor3 = orangeBtnColor
inputName.TextColor3 = Color3.fromRGB(20, 20, 20)
inputName.Font = Enum.Font.GothamBold
inputName.TextSize = 15
Instance.new("UICorner", inputName)

local saveBtn = createButton(uiBase, "saveAnim", 230, 105, 100, 28, "💾 Save", orangeBtnColor)
local loadBtn = createButton(uiBase, "loadAnim", 340, 105, 100, 28, "📂 Load", orangeBtnColor)

-- Linha 4: Export Buttons
local exportPosBtn = createButton(uiBase, "exportPos", 10, 145, 140, 28, "📤 Export (Pos)", orangeBtnColor)
local exportIdBtn = createButton(uiBase, "exportId", 10 + 140 + 10, 145, 140, 28, "📤 Export (ID)", orangeBtnColor)

-- Linha 5: Timeline frame horizontal e progress bar
local timelineFrame = Instance.new("Frame", uiBase)
timelineFrame.Size = UDim2.new(1, -20, 0, 28)
timelineFrame.Position = UDim2.new(0, 10, 0, 180)
timelineFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
timelineFrame.BorderSizePixel = 0
Instance.new("UICorner", timelineFrame)

local progressBar = Instance.new("Frame", timelineFrame)
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.Position = UDim2.new(0, 0, 0, 0)
progressBar.BackgroundColor3 = orangeBtnColor
progressBar.BorderSizePixel = 0
Instance.new("UICorner", progressBar)

local keyframeButtons = {}

local timelineTime = 0
local timeStep = 0.5

local playing = false
local playStartTime = 0
local playDuration = 0
local loopEnabled = false

local playbackSpeed = 1

-- GUI dos slots menor e horizontal abaixo da base
local slotsGui = Instance.new("Frame", gui)
slotsGui.Size = UDim2.new(0, 460, 0, 70)
slotsGui.Position = UDim2.new(0, 20, 0.5, 110)
slotsGui.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
slotsGui.BorderSizePixel = 0
slotsGui.Visible = false
Instance.new("UICorner", slotsGui)

local slotsTitle = Instance.new("TextLabel", slotsGui)
slotsTitle.Size = UDim2.new(1, -20, 0, 25)
slotsTitle.Position = UDim2.new(0, 10, 0, 8)
slotsTitle.BackgroundTransparency = 1
slotsTitle.Text = "💾 Slots de Animação"
slotsTitle.Font = Enum.Font.GothamBold
slotsTitle.TextSize = 20
slotsTitle.TextColor3 = orangeBtnColor
slotsTitle.TextXAlignment = Enum.TextXAlignment.Center

local slots = {}
local slotCount = 5
local slotWidth = 60
local slotHeight = 40
local slotPadding = 10
local startX = 15
local startY = 35

for i = 1, slotCount do
    local slotFrame = Instance.new("Frame", slotsGui)
    slotFrame.Size = UDim2.new(0, slotWidth, 0, slotHeight + 25)
    slotFrame.Position = UDim2.new(0, startX + (slotWidth + slotPadding) * (i-1), 0, startY)
    slotFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    slotFrame.BorderSizePixel = 0
    Instance.new("UICorner", slotFrame)

    local slotBtn = Instance.new("TextButton", slotFrame)
    slotBtn.Size = UDim2.new(1, 0, 0, slotHeight)
    slotBtn.Position = UDim2.new(0, 0, 0, 0)
    slotBtn.BackgroundColor3 = orangeBtnColor
    slotBtn.Text = "Slot " .. i
    slotBtn.Font = Enum.Font.GothamBold
    slotBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    slotBtn.TextSize = 16
    Instance.new("UICorner", slotBtn)

    local saveSlotBtn = Instance.new("TextButton", slotFrame)
    saveSlotBtn.Size = UDim2.new(0.5, -2, 0, 25)
    saveSlotBtn.Position = UDim2.new(0, 0, 0, slotHeight)
    saveSlotBtn.BackgroundColor3 = orangeBtnColor
    saveSlotBtn.Text = "Salvar"
    saveSlotBtn.Font = Enum.Font.GothamBold
    saveSlotBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    saveSlotBtn.TextSize = 14
    Instance.new("UICorner", saveSlotBtn)

    local loadSlotBtn = Instance.new("TextButton", slotFrame)
    loadSlotBtn.Size = UDim2.new(0.5, -2, 0, 25)
    loadSlotBtn.Position = UDim2.new(0.5, 2, 0, slotHeight)
    loadSlotBtn.BackgroundColor3 = orangeBtnColor
    loadSlotBtn.Text = "Abrir"
    loadSlotBtn.Font = Enum.Font.GothamBold
    loadSlotBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    loadSlotBtn.TextSize = 14
    Instance.new("UICorner", loadSlotBtn)

    slots[i] = {
        slotBtn = slotBtn,
        saveBtn = saveSlotBtn,
        loadBtn = loadSlotBtn
    }
end

-- Funções e lógica abaixo seguem igual (copiar as funções de antes)

local function refreshTimeline()
    for _, btn in pairs(keyframeButtons) do
        btn:Destroy()
    end
    keyframeButtons = {}

    local keys = {}
    for t in pairs(animationData) do table.insert(keys, t) end
    table.sort(keys)

    for i, t in ipairs(keys) do
        local btn = Instance.new("TextButton", timelineFrame)
        btn.Size = UDim2.new(0, 12, 0, 24)
        btn.Position = UDim2.new(0, (t / (keys[#keys] or 1)) * (timelineFrame.AbsoluteSize.X - 12), 0, 2)
        btn.BackgroundColor3 = orangeBtnColor
        btn.Text = "⌾"
        btn.TextColor3 = Color3.fromRGB(20, 20, 20)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn)

        btn.MouseButton1Click:Connect(function()
            timelineTime = t
            local keyframe = animationData[t]
            if keyframe then
                local rootPart = Dummy:FindFirstChild(rootPartName)
                if rootPart then
                    rootPart.CFrame = keyframe.Root
                end
                for partName, cfLocal in pairs(keyframe.Parts) do
                    local part = Dummy:FindFirstChild(partName)
                    if part and cfLocal then
                        part.CFrame = keyframe.Root * cfLocal
                    end
                end
            end
        end)

        table.insert(keyframeButtons, btn)
    end
end

local function updateProgressBar(t)
    if playDuration > 0 then
        local percent = math.clamp(t / playDuration, 0, 1)
        progressBar:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
    else
        progressBar.Size = UDim2.new(0, 0, 1, 0)
    end
end

local function slerp(c0, c1, alpha)
    local pos = c0.Position:Lerp(c1.Position, alpha)
    local rot0 = c0 - c0.Position
    local rot1 = c1 - c1.Position
    local rot = rot0:lerp(rot1, alpha)
    return CFrame.new(pos) * rot
end

playBtn.MouseButton1Click:Connect(function()
    if not next(animationData) then return end

    playing = true
    playStartTime = tick()

    local keys = {}
    for time in pairs(animationData) do table.insert(keys, time) end
    table.sort(keys)
    playDuration = keys[#keys] or 0

    RS:BindToRenderStep("PlayAnimation", 201, function()
        if not playing then
            RS:UnbindFromRenderStep("PlayAnimation")
            updateProgressBar(0)
            return
        end

        local elapsed = (tick() - playStartTime) * playbackSpeed

        if loopEnabled and elapsed > playDuration then
            playStartTime = tick()
            elapsed = 0
        end

        updateProgressBar(elapsed)

        local before, after = nil, nil
        for i = 1, #keys - 1 do
            if elapsed >= keys[i] and elapsed <= keys[i+1] then
                before = keys[i]
                after = keys[i+1]
                break
            end
        end

        local rootPart = Dummy:FindFirstChild(rootPartName)
        if before and after and rootPart then
            local alpha = (elapsed - before) / (after - before)
            local beforeFrame = animationData[before]
            local afterFrame = animationData[after]

            local rootCFrame = slerp(beforeFrame.Root, afterFrame.Root, alpha)
            rootPart.CFrame = rootCFrame

            for partName, cfLocal in pairs(beforeFrame.Parts) do
                local part = Dummy:FindFirstChild(partName)
                local afterCfLocal = afterFrame.Parts[partName]
                if part and cfLocal and afterCfLocal then
                    local lerpedLocal = cfLocal:lerp(afterCfLocal, alpha)
                    part.CFrame = rootCFrame * lerpedLocal
                end
            end
        elseif elapsed > keys[#keys] then
            if not loopEnabled then
                playing = false
                RS:UnbindFromRenderStep("PlayAnimation")
                updateProgressBar(0)
            end
        end
    end)
end)

loopBtn.MouseButton1Click:Connect(function()
    loopEnabled = not loopEnabled
    loopBtn.Text = "🔁 Loop: " .. (loopEnabled and "ON" or "OFF")
    loopBtn.BackgroundColor3 = loopEnabled and orangeBtnColor or greyBtnColor
end)

addBtn.MouseButton1Click:Connect(function()
    local rootPart = Dummy:FindFirstChild(rootPartName)
    if not rootPart then return end

    local keyframe = {Root = rootPart.CFrame, Parts = {}}
    for _, partName in pairs(partsToRecord) do
        local part = Dummy:FindFirstChild(partName)
        if part then
            keyframe.Parts[partName] = rootPart.CFrame:ToObjectSpace(part.CFrame)
        end
    end
    animationData[timelineTime] = keyframe
    timelineTime += timeStep
    refreshTimeline()
end)

resetBtn.MouseButton1Click:Connect(function()
    local rootPart = Dummy:FindFirstChild(rootPartName)
    if rootPart and defaultRootCFrame then
        rootPart.CFrame = defaultRootCFrame
    end
    for partName, cf in pairs(defaultPose) do
        local part = Dummy:FindFirstChild(partName)
        if part then
            part.CFrame = cf
        end
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    animationData = {}
    timelineTime = 0
    refreshTimeline()
end)

local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % 2^32
    end
    return tostring(hash)
end

local function saveToSlot(slot)
    local success, json = pcall(function()
        return HttpService:JSONEncode(animationData)
    end)
    if not success then return end
    LocalPlayer:SetAttribute("StdLtSlot_"..slot, json)
end

local function loadFromSlot(slot)
    local json = LocalPlayer:GetAttribute("StdLtSlot_"..slot)
    if not json then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if success and data then
        animationData = data
        timelineTime = 0
        refreshTimeline()
    end
end

for i = 1, slotCount do
    local s = slots[i]
    s.saveBtn.MouseButton1Click:Connect(function()
        saveToSlot(i)
    end)
    s.loadBtn.MouseButton1Click:Connect(function()
        loadFromSlot(i)
    end)
end

slotsToggleBtn.MouseButton1Click:Connect(function()
    slotsGui.Visible = not slotsGui.Visible
end)

saveBtn.MouseButton1Click:Connect(function()
    local success, json = pcall(function()
        return HttpService:JSONEncode(animationData)
    end)
    if not success then return end
    local id = simpleHash(json)
    LocalPlayer:SetAttribute("StdLtAssetID_"..id, json)
    inputName.Text = "StdLtAssetID:"..id
end)

loadBtn.MouseButton1Click:Connect(function()
    local text = inputName.Text
    local id = text:match("^StdLtAssetID:(%d+)$")
    if id then
        local json = LocalPlayer:GetAttribute("StdLtAssetID_"..id)
        if not json then return end
        local success, data = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if success and data then
            animationData = data
            timelineTime = 0
            refreshTimeline()
        end
    end
end)

exportPosBtn.MouseButton1Click:Connect(function()
    local success, json = pcall(function()
        return HttpService:JSONEncode(animationData)
    end)
    if success then
        inputName.Text = json
    end
end)

local exportStorage = {}

local function generateRandomId()
    local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = ""
    for i = 1, 6 do
        id = id .. charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    return id
end

exportIdBtn.MouseButton1Click:Connect(function()
    local success, json = pcall(function()
        return HttpService:JSONEncode(animationData)
    end)
    if not success then return end
    local id = generateRandomId()
    exportStorage[id] = json
    inputName.Text = "StdLt:AssetID//" .. id
end)

local function importByCustomId(code)
    local id = code:match("^StdLt:AssetID//(%w+)$")
    if not id then return nil end
    local json = exportStorage[id]
    if not json then return nil end
    local success, data = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if success then
        return data
    else
        return nil
    end
end

inputName.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    local txt = inputName.Text
    if txt:sub(1, 12) == "StdLt:AssetID" then
        local data = importByCustomId(txt)
        if data then
            animationData = data
            timelineTime = 0
            refreshTimeline()
        end
    end
end)

-- Velocidade
local minSpeed, maxSpeed = 0.1, 5
speedDownBtn.MouseButton1Click:Connect(function()
    playbackSpeed = math.clamp(playbackSpeed - 0.1, minSpeed, maxSpeed)
    print(string.format("[🐢] Velocidade: %.1fx", playbackSpeed))
end)

speedUpBtn.MouseButton1Click:Connect(function()
    playbackSpeed = math.clamp(playbackSpeed + 0.1, minSpeed, maxSpeed)
    print(string.format("[⚡] Velocidade: %.1fx", playbackSpeed))
end)

-- Toggle arrastável preto com lua laranja
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0, 30, 0, 30)
toggleBtn.Position = UDim2.new(0, 20, 0.5, -150)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.Text = "🌙"
toggleBtn.TextColor3 = orangeBtnColor
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextScaled = true
toggleBtn.BorderSizePixel = 0
Instance.new("UICorner", toggleBtn)

local draggingToggle = false
local dragInputToggle
local dragStartToggle
local startPosToggle

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingToggle = true
        dragStartToggle = input.Position
        startPosToggle = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingToggle = false
            end
        end)
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInputToggle = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInputToggle and draggingToggle then
        local delta = input.Position - dragStartToggle
        toggleBtn.Position = UDim2.new(
            startPosToggle.X.Scale,
            math.clamp(startPosToggle.X.Offset + delta.X, 0, gui.AbsoluteSize.X - toggleBtn.AbsoluteSize.X),
            startPosToggle.Y.Scale,
            math.clamp(startPosToggle.Y.Offset + delta.Y, 0, gui.AbsoluteSize.Y - toggleBtn.AbsoluteSize.Y)
        )
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    uiBase.Visible = not uiBase.Visible
end)

print("🌙 Moon Animator Lite v3.5 GUI compacto e horizontal carregado!")
