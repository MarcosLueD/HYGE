--------------------------------------------------------------------------------
-- HUD DE SPECTATE (fora da janela, funciona com o painel fechado)
--------------------------------------------------------------------------------
do
    local hud = Instance.new("Frame")
    hud.Name = "SpectateHud"
    hud.AnchorPoint = Vector2.new(0.5, 1)
    hud.Position = UDim2.new(0.5, 0, 1, -24)
    hud.Size = UDim2.new(0, 470, 0, 92)
    hud.BackgroundColor3 = THEME.Card
    hud.BackgroundTransparency = 0.05
    hud.BorderSizePixel = 0
    hud.Visible = false
    hud.Parent = Gui
    Paint(hud, "BackgroundColor3", "Card")
    Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", hud)
    st.Transparency = 0.4
    Paint(st, "Color", "Accent")

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -110, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.TextColor3 = THEME.Accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = hud
    Paint(label, "TextColor3", "Accent")

    local prev = CreateButton(hud, "<", "Accent", 22)
    prev.Size = UDim2.new(0, 26, 0, 22)
    prev.Position = UDim2.new(1, -102, 0, 8)
    local nxt = CreateButton(hud, ">", "Accent", 22)
    nxt.Size = UDim2.new(0, 26, 0, 22)
    nxt.Position = UDim2.new(1, -72, 0, 8)
    local stop = CreateButton(hud, "SAIR", "Danger", 22)
    stop.Size = UDim2.new(0, 44, 0, 22)
    stop.Position = UDim2.new(1, -58, 0, 8)
    nxt.Position = UDim2.new(1, -134, 0, 8)
    prev.Position = UDim2.new(1, -164, 0, 8)

    local input = CreateInput(hud, "Mensagem privada", 32)
    input.Name = "Input"
    input.Size = UDim2.new(1, -128, 0, 32)
    input.Position = UDim2.new(0, 14, 0, 44)

    local send = CreateButton(hud, "ENVIAR", "Accent", 32)
    send.Size = UDim2.new(0, 100, 0, 32)
    send.Position = UDim2.new(1, -114, 0, 44)

    local function sendMsg()
        local msg = input.Text
        if msg == "" or not State.SpectateTarget then return end
        if Remotes.Whisper then
            Remotes.Whisper:FireServer(State.SpectateTarget.UserId, msg)
            Log("Você -> " .. State.SpectateTarget.Name .. ": " .. msg, "ok")
        else
            Log("Remote AdminWhisper ausente", "error")
        end
        input.Text = ""
    end

    send.MouseButton1Click:Connect(sendMsg)
    input.FocusLost:Connect(function(enter) if enter then sendMsg() end end)
    prev.MouseButton1Click:Connect(function() CycleSpectate(-1) end)
    nxt.MouseButton1Click:Connect(function() CycleSpectate(1) end)
    stop.MouseButton1Click:Connect(StopSpectate)

    SpectateHud = hud
end
