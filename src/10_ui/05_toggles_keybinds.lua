--------------------------------------------------------------------------------
-- REGISTRY DE TOGGLES  (estado + UI + keybind + log em um só lugar)
--------------------------------------------------------------------------------
local Toggles, ToggleOrder = {}, {}

local function DefineToggle(def)
    def.state = false
    def.listeners = {}
    Toggles[def.id] = def
    table.insert(ToggleOrder, def.id)
    return def
end

local function IsOn(id)
    local t = Toggles[id]
    return t and t.state or false
end

local RefreshStatus  -- forward

local function SetToggle(id, on, silent)
    local t = Toggles[id]
    if not t then return end
    on = not not on
    if t.state == on then return end

    local fn = on and t.enable or t.disable
    local ok, err = pcall(fn)
    if not ok then
        Log(t.label .. " falhou: " .. tostring(err), "error")
        Toast(t.label .. " falhou", "error")
        return
    end

    t.state = on
    for _, l in ipairs(t.listeners) do pcall(l, on) end
    if not silent then
        Log(t.label .. ": " .. (on and "ON" or "OFF"), on and "ok" or nil)
        Toast(t.label .. (on and "  ativado" or "  desativado"), on and "ok" or "warn", 1.6)
    end
    if RefreshStatus then RefreshStatus() end
end

local function Flip(id) SetToggle(id, not IsOn(id)) end

-- Switch animado
local function SwitchRow(parent, id, labelText, description)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, description and 56 or 44)
    row.BackgroundTransparency = 1
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cada linha é um cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -70, 0, 18)
    name.Position = UDim2.new(0, 0, 0, description and 4 or 8)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -70, 0, 14)
        desc.Position = UDim2.new(0, 0, 0, 24)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.TextColor3 = THEME.Dim
        desc.Font = Enum.Font.GothamMedium
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.Parent = row
        Paint(desc, "TextColor3", "Dim")
    end

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.new(0, 46, 0, 24)
    track.BackgroundColor3 = THEME.Track
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- v8.0: ligado = trilho no destaque + bolinha escura; desligado = trilho
    -- escuro + bolinha clara (com destaque branco, bolinha branca sumia)
    local function render(on)
        TweenService:Create(track, TweenInfo.new(0.16), {
            BackgroundColor3 = on and THEME.Accent or THEME.Track }):Play()
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and THEME.Main or THEME.Text }):Play()
    end

    track.MouseButton1Click:Connect(function() Flip(id) end)
    if Toggles[id] then
        table.insert(Toggles[id].listeners, render)
        render(Toggles[id].state)
        -- troca de tema repinta também os switches (V8.Renders roda no ApplyTheme)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() render(Toggles[id].state) end)
    end
    return row, render
end

--------------------------------------------------------------------------------
-- KEYBINDS
--------------------------------------------------------------------------------
local Keybinds = {}      -- [toggleId] = KeyCode
local KeybindLabels = {}
local capturing, captureConn = nil, nil

local function StopCapture()
    if captureConn then captureConn:Disconnect() captureConn = nil end
    if capturing and KeybindLabels[capturing] then
        KeybindLabels[capturing].Text = KeyName(Keybinds[capturing])
    end
    capturing = nil
end

local function KeybindRow(parent, id, labelText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -110, 1, 0)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.new(0, 96, 0, 28)
    btn.BackgroundColor3 = THEME.Btn
    btn.Text = KeyName(Keybinds[id])
    btn.TextColor3 = THEME.Accent2
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = row
    Paint(btn, "BackgroundColor3", "Btn")
    Paint(btn, "TextColor3", "Accent2")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Transparency = 0.6
    Paint(stroke, "Color", "Accent")

    KeybindLabels[id] = btn

    btn.MouseButton1Click:Connect(function()
        if capturing == id then StopCapture() return end
        StopCapture()
        capturing = id
        btn.Text = "aperte..."
        Toast("Aperte uma tecla para " .. labelText .. " (Backspace remove)", nil, 3)

        captureConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if capturing ~= id then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Unknown then return end

            if kc == Enum.KeyCode.Backspace then
                Keybinds[id] = nil
                Log("Keybind removido: " .. labelText)
                StopCapture()
                return
            end
            -- v8.0: console e busca (sem Ctrl) também são teclas do painel —
            -- o handler global trata essas antes dos toggles, então o atalho
            -- nunca dispararia
            if kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey
                or (kc == CONFIG.SearchKey and not CONFIG.SearchCtrl) then
                Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                return
            end
            -- conflito: avisa em vez de apagar em silencio
            for otherId, otherKc in pairs(Keybinds) do
                if otherKc == kc and otherId ~= id then
                    Keybinds[otherId] = nil
                    if KeybindLabels[otherId] then KeybindLabels[otherId].Text = "—" end
                    local other = Toggles[otherId] and Toggles[otherId].label or otherId
                    Log("[" .. KeyName(kc) .. "] estava em '" .. other
                        .. "' — esse atalho ficou sem tecla", "warn")
                    Toast("'" .. other .. "' perdeu o atalho [" .. KeyName(kc) .. "]", "warn")
                end
            end
            -- v8.0: situações também disputam teclas (e ganham no handler global)
            if V8.Sit and V8.Sit.Keys then
                for sitName, sitKc in pairs(V8.Sit.Keys) do
                    if sitKc == kc then
                        V8.Sit.Keys[sitName] = nil
                        Log("[" .. KeyName(kc) .. "] estava na situação '" .. sitName
                            .. "' — ela ficou sem tecla", "warn")
                        Toast("Situação '" .. sitName .. "' perdeu o atalho", "warn")
                    end
                end
                pcall(V8.Sit.Render)
            end
            Keybinds[id] = kc
            Log("Keybind " .. labelText .. " = " .. KeyName(kc), "ok")
            StopCapture()
        end)
    end)
    return row
end

