-- HYGE GUI - Versão FINAL com Anti-AFK Melhorado + todos os toggles funcionando

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Espera personagem carregar
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
LocalPlayer.Character:WaitForChild("HumanoidRootPart", 10)

-- Estados
local espEnabled = false
local flyEnabled = false
local noclipEnabled = false
local silentEnabled = false
local wallEnabled = false
local speedEnabled = false

local flyBV, flyBG, flyConn
local wallhackConnection
local WALL_TRANSPARENCY = 0.75

local DEFAULT_WALKSPEED = 16
local currentSpeed = 60

-- Anti-AFK Melhorado (pula + anda um pouco a cada 4 minutos)
spawn(function()
    while true do
        task.wait(240)  -- 4 minutos
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = LocalPlayer.Character.Humanoid
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- Simula pulo
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            
            -- Simula pequeno movimento (evita detecção de AFK em alguns jogos)
            hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-1,1), 0, math.random(-1,1))
        end
    end
end)

-- Rejoin Server
local function rejoinServer()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("Rejoining...")  -- evita kick por vazio
        return
    end
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- UI Toggle Keybind (INSERT abre/fecha)
local guiVisible = true
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        guiVisible = not guiVisible
        screenGui.Enabled = guiVisible
    end
end)

-- Cria GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HYGE"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", screenGui)
frame.Position = UDim2.new(0.5, -200, 0.5, -240)
frame.Size = UDim2.new(0, 400, 0, 520)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -80, 0, 50)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "HYGE"
title.TextColor3 = Color3.fromRGB(200, 0, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 42
title.TextStrokeTransparency = 0.75
title.TextStrokeColor3 = Color3.fromRGB(120, 0, 200)

local uiStroke = Instance.new("UIStroke", title)
uiStroke.Color = Color3.fromRGB(180, 100, 255)
uiStroke.Thickness = 2.8
uiStroke.Transparency = 0.35

local titleGradient = Instance.new("UIGradient", title)
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))
}
titleGradient.Rotation = 45

-- Botões Fechar / Minimizar
local closeButton = Instance.new("TextButton", frame)
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -46, 0, 12)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 22
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 10)
closeButton.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local minButton = Instance.new("TextButton", frame)
minButton.Size = UDim2.new(0, 36, 0, 36)
minButton.Position = UDim2.new(1, -92, 0, 12)
minButton.BackgroundColor3 = Color3.fromRGB(100, 0, 180)
minButton.Text = "-"
minButton.TextColor3 = Color3.new(1,1,1)
minButton.Font = Enum.Font.GothamBold
minButton.TextSize = 26
Instance.new("UICorner", minButton).CornerRadius = UDim.new(0, 10)

local minimized = false
minButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    frame.Size = minimized and UDim2.new(0, 400, 0, 60) or UDim2.new(0, 400, 0, 520)
    minButton.Text = minimized and "+" or "-"
end)

-- Sistema de arrastar (funcionando 100%)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Função para criar botão
local function createButton(text, x, y, width)
    local btn = Instance.new("TextButton", frame)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.Size = UDim2.new(0, width, 0, 42)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
    btn.TextColor3 = Color3.fromRGB(220, 100, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 0, 120)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 0, 60)}):Play()
    end)
    
    return btn
end

-- Botões
local espBtn    = createButton("ESP: OFF",       15,  80, 180)
local flyBtn    = createButton("Fly: OFF",      205,  80, 180)
local noclipBtn = createButton("NoClip: OFF",    15, 135, 180)
local silentBtn = createButton("Silent Aim: OFF",205, 135, 180)
local wallBtn   = createButton("Wall: OFF",      15, 190, 180)
local speedBtn  = createButton("Speed: OFF ("..currentSpeed..")", 205, 190, 180)

-- Função toggle visual
local function updateToggle(btn, state)
    if state then
        btn.Text = btn.Text:gsub("OFF", "ON")
        btn.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
    else
        btn.Text = btn.Text:gsub("ON", "OFF")
        btn.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
    end
end

-- Atualiza texto do Speed
local function updateSpeedText()
    speedBtn.Text = (speedEnabled and "Speed: ON (" or "Speed: OFF (") .. currentSpeed .. ")"
end

-- ESP (apenas contorno)
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    updateToggle(espBtn, espEnabled)
    
    if espEnabled then
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer and plr.Character then
                local hl = plr.Character:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
                hl.Parent = plr.Character
                hl.FillTransparency = 1
                hl.OutlineColor = Color3.fromRGB(200, 0, 255)
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
        end
    else
        for _, plr in Players:GetPlayers() do
            if plr.Character then
                local hl = plr.Character:FindFirstChildOfClass("Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- Fly
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    updateToggle(flyBtn, flyEnabled)
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if flyEnabled then
        flyBV = Instance.new("BodyVelocity", hrp)
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = Vector3.new()
        
        flyBG = Instance.new("BodyGyro", hrp)
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.CFrame = hrp.CFrame
        
        local speed = 60
        
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local moveDir = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end
            
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            flyBV.Velocity = moveDir * speed
            flyBG.CFrame = Camera.CFrame
        end)
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        if flyConn then flyConn:Disconnect() flyConn = nil end
    end
end)

-- NoClip
noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    updateToggle(noclipBtn, noclipEnabled)
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in LocalPlayer.Character:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Silent Aim
silentBtn.MouseButton1Click:Connect(function()
    silentEnabled = not silentEnabled
    updateToggle(silentBtn, silentEnabled)
end)

local function getClosestTarget()
    local mousePos = UIS:GetMouseLocation()
    local closest, minDist = nil, 180
    
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, visible = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr.Character.HumanoidRootPart
                end
            end
        end
    end
    return closest
end

UIS.InputBegan:Connect(function(input)
    if silentEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not UIS:GetFocusedTextBox() then
        local target = getClosestTarget()
        if target then
            LocalPlayer:GetMouse().Hit = target.CFrame
        end
    end
end)

-- Wallhack
local function applyWallhack()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
            if not obj:IsDescendantOf(LocalPlayer.Character) and 
               not (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")) then
                if not obj:GetAttribute("OriginalTransparency") then
                    obj:SetAttribute("OriginalTransparency", obj.Transparency)
                end
                obj.Transparency = WALL_TRANSPARENCY
            end
        end
    end
end

local function restoreWallhack()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
            local original = obj:GetAttribute("OriginalTransparency")
            if original then
                obj.Transparency = original
                obj:SetAttribute("OriginalTransparency", nil)
            end
        end
    end
end

wallBtn.MouseButton1Click:Connect(function()
    wallEnabled = not wallEnabled
    updateToggle(wallBtn, wallEnabled)
    
    if wallEnabled then
        applyWallhack()
        if not wallhackConnection then
            wallhackConnection = Workspace.DescendantAdded:Connect(function(obj)
                if wallEnabled and (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
                    if not obj:IsDescendantOf(LocalPlayer.Character) and 
                       not (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")) then
                        if not obj:GetAttribute("OriginalTransparency") then
                            obj:SetAttribute("OriginalTransparency", obj.Transparency)
                        end
                        obj.Transparency = WALL_TRANSPARENCY
                    end
                end
            end)
        end
    else
        restoreWallhack()
        if wallhackConnection then
            wallhackConnection:Disconnect()
            wallhackConnection = nil
        end
    end
end)

-- Speed com slider
speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    updateToggle(speedBtn, speedEnabled)
    updateSpeedText()
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local humanoid = char.Humanoid
    
    if speedEnabled then
        humanoid.WalkSpeed = currentSpeed
        print("Speed ativado: " .. currentSpeed)
    else
        humanoid.WalkSpeed = DEFAULT_WALKSPEED
        print("Speed desativado")
    end
end)

-- Slider para ajustar velocidade
local sliderFrame = Instance.new("Frame", frame)
sliderFrame.Position = UDim2.new(0, 15, 0, 240)
sliderFrame.Size = UDim2.new(0, 370, 0, 40)
sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
sliderFrame.BorderSizePixel = 0
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 20)

local sliderFill = Instance.new("Frame", sliderFrame)
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)  -- inicia em 50%
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 20)

local sliderLabel = Instance.new("TextLabel", sliderFrame)
sliderLabel.Size = UDim2.new(1, 0, 1, 0)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Velocidade: " .. currentSpeed
sliderLabel.TextColor3 = Color3.new(1,1,1)
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextSize = 18

local draggingSlider = false
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
    end
end)

sliderFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

RunService.RenderStepped:Connect(function()
    if draggingSlider then
        local mouseX = UIS:GetMouseLocation().X
        local frameAbsPos = sliderFrame.AbsolutePosition.X
        local frameWidth = sliderFrame.AbsoluteSize.X
        
        local relative = math.clamp((mouseX - frameAbsPos) / frameWidth, 0, 1)
        sliderFill.Size = UDim2.new(relative, 0, 1, 0)
        
        currentSpeed = math.floor(16 + (300 - 16) * relative)
        sliderLabel.Text = "Velocidade: " .. currentSpeed
        
        if speedEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = currentSpeed
            end
        end
        
        updateSpeedText()
    end
end)

-- Adicione botões para Rejoin e Infinite Yield (como no script anterior)
local rejoinBtn = createButton("Rejoin Server", 15, 440, 180)
rejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

local iyBtn = createButton("Infinite Yield", 205, 440, 180)
iyBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

print("HYGE carregado com Anti-AFK melhorado e todas as funções!")
