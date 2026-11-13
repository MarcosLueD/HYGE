--------------------------------------------------------------------------------
-- FÁBRICA DE UI v7
-- Tiles de estatística, sliders com campo numérico + reset, switches genéricos
-- (não ligados ao registry), avatar, chips, confirmação e botões com gate de
-- Remote. Tudo em cima do CreateCard/CreateButton que já existiam.
--------------------------------------------------------------------------------

-- Tween que respeita a opção "animações" em Settings
local function Anim(inst, dur, props)
    if not SET.Animations then
        for k, v in pairs(props) do inst[k] = v end
        return
    end
    TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out), props):Play()
end

local function SubLabel(parent, text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 15)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = THEME.Dim
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 50
    l.Parent = parent
    Paint(l, "TextColor3", "Dim")
    return l
end

-- Tile de estatística: rótulo pequeno em cima, valor grande embaixo
local function StatTile(parent, label, value, order, colorKey)
    local box = Instance.new("Frame")
    box.Name = "Tile"
    box.BackgroundColor3 = THEME.Btn
    box.BorderSizePixel = 0
    box.LayoutOrder = order or 1
    box.Parent = parent
    Paint(box, "BackgroundColor3", "Btn")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local st = Instance.new("UIStroke", box)
    st.Transparency = 0.85
    Paint(st, "Color", "Line")

    local cap = Instance.new("TextLabel")
    cap.Size = UDim2.new(1, -16, 0, 12)
    cap.Position = UDim2.new(0, 8, 0, 7)
    cap.BackgroundTransparency = 1
    cap.Text = label
    cap.TextColor3 = THEME.Dim
    cap.Font = Enum.Font.GothamBold
    cap.TextSize = 9
    cap.TextXAlignment = Enum.TextXAlignment.Left
    cap.Parent = box
    Paint(cap, "TextColor3", "Dim")

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -16, 0, 20)
    val.Position = UDim2.new(0, 8, 0, 21)
    val.BackgroundTransparency = 1
    val.Text = tostring(value)
    val.TextColor3 = THEME[colorKey or "Text"]
    val.Font = Enum.Font.GothamBold
    val.TextSize = 15
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = box
    Paint(val, "TextColor3", colorKey or "Text")
    return val, box
end

-- Slider + campo numérico + reset, todos sincronizados.
-- o = { label, min, max, def, suffix, apply(v), order }
-- devolve setValue(v) para sincronizar de fora (comandos, scroll, presets)
local function SliderRow(parent, o)
    local minV, maxV = o.min, o.max
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundTransparency = 1
    row.LayoutOrder = o.order or 10
    row.Parent = parent
    V8.Cell(row, 10)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -112, 0, 18)
    name.BackgroundTransparency = 1
    name.Text = o.label
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    -- v8.0: valor solto à direita (dá para digitar) + "R" redondo para resetar
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0)
    box.Position = UDim2.new(1, 0, 0, -1)
    box.Size = UDim2.new(0, 58, 0, 20)
    box.BackgroundColor3 = THEME.Btn
    box.BackgroundTransparency = 1
    box.Text = tostring(o.def)
    box.TextColor3 = THEME.Text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Right
    box.ClearTextOnFocus = false
    box.Parent = row
    Paint(box, "TextColor3", "Text")

    local reset = Instance.new("TextButton")
    reset.AnchorPoint = Vector2.new(1, 0)
    reset.Position = UDim2.new(1, -66, 0, -1)
    reset.Size = UDim2.new(0, 20, 0, 20)
    reset.BackgroundColor3 = THEME.Btn
    reset.Text = "R"
    reset.TextColor3 = THEME.Dim
    reset.Font = Enum.Font.GothamBold
    reset.TextSize = 10
    reset.AutoButtonColor = false
    reset.Parent = row
    Paint(reset, "BackgroundColor3", "Btn")
    Paint(reset, "TextColor3", "Dim")
    Instance.new("UICorner", reset).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 30)
    bar.BackgroundColor3 = THEME.Track
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = row
    Paint(bar, "BackgroundColor3", "Track")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local pct0 = (o.def - minV) / (maxV - minV)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Paint(fill, "BackgroundColor3", "Accent")
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct0, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local current = o.def
    local function render(v)
        local pct = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -7, 0.5, -7)
        box.Text = tostring(v) .. (o.suffix or "")
    end

    local function apply(v, silent)
        if type(v) ~= "number" then return current end
        v = math.clamp(math.floor(v + 0.5), minV, maxV)   -- limites sempre válidos
        current = v
        render(v)
        if not silent and o.apply then
            local ok, err = pcall(o.apply, v)
            if not ok then Log(o.label .. ": " .. tostring(err), "error") end
        end
        return v
    end

    box.FocusLost:Connect(function()
        local v = tonumber((box.Text:gsub("[^%-%d%.]", "")))
        if v then
            apply(v)
        else
            render(current)   -- valor inválido: volta pro atual
            Toast("Valor inválido em " .. o.label, "warn", 1.6)
        end
    end)

    reset.MouseButton1Click:Connect(function()
        apply(o.def)
        Log(o.label .. " resetado (" .. o.def .. ")", "action")
    end)
    reset.MouseEnter:Connect(function() Anim(reset, 0.12, { TextColor3 = THEME.Accent }) end)
    reset.MouseLeave:Connect(function() Anim(reset, 0.12, { TextColor3 = THEME.Dim }) end)

    local moveConn, endConn
    bar.MouseButton1Down:Connect(function()
        local function fromInput(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)
                / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            apply(minV + rel * (maxV - minV))
        end
        Anim(knob, 0.1, { Size = UDim2.new(0, 18, 0, 18) })
        if moveConn then moveConn:Disconnect() end
        if endConn then endConn:Disconnect() end
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                fromInput(input)
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if moveConn then moveConn:Disconnect() moveConn = nil end
                if endConn then endConn:Disconnect() endConn = nil end
                Anim(knob, 0.1, { Size = UDim2.new(0, 14, 0, 14) })
            end
        end)
    end)

    render(o.def)
    return apply
end

-- Switch genérico (settings, opções de ESP): usa get/set em vez do registry
local function CheckRow(parent, labelText, description, get, set, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, description and 56 or 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 10
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -66, 0, 18)
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
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -66, 0, 14)
        d.Position = UDim2.new(0, 0, 0, 24)
        d.BackgroundTransparency = 1
        d.Text = description
        d.TextColor3 = THEME.Dim
        d.Font = Enum.Font.GothamMedium
        d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextTruncate = Enum.TextTruncate.AtEnd
        d.Parent = row
        Paint(d, "TextColor3", "Dim")
    end

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.new(0, 40, 0, 21)
    track.BackgroundColor3 = THEME.Track
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.Position = UDim2.new(0, 3, 0.5, -7.5)
    knob.BackgroundColor3 = THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- v8.0: mesmo esquema do SwitchRow (bolinha escura no ligado)
    local function render()
        local on = not not get()
        Anim(track, 0.15, { BackgroundColor3 = on and THEME.Accent or THEME.Track })
        Anim(knob, 0.15, {
            Position = on and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5),
            BackgroundColor3 = on and THEME.Main or THEME.Text })
    end

    track.MouseButton1Click:Connect(function()
        local ok, err = pcall(set, not get())
        if not ok then Log(labelText .. ": " .. tostring(err), "error") end
        render()
    end)

    render()
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, render)
    return render, row
end

--------------------------------------------------------------------------------
-- CONFIRMAÇÃO (para ações destrutivas)
--------------------------------------------------------------------------------
local Confirm
do
    local overlay = Instance.new("Frame")
    overlay.Name = "Confirm"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.45
    overlay.Visible = false
    overlay.ZIndex = 60
    overlay.Parent = Gui

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.Size = UDim2.new(0, 360, 0, 148)
    box.BackgroundColor3 = THEME.Card
    box.BorderSizePixel = 0
    box.ZIndex = 61
    box.Parent = overlay
    Paint(box, "BackgroundColor3", "Card")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
    local bst = Instance.new("UIStroke", box)
    bst.Transparency = 0.3
    Paint(bst, "Color", "Danger")

    local head = Instance.new("TextLabel")
    head.Size = UDim2.new(1, -28, 0, 20)
    head.Position = UDim2.new(0, 14, 0, 14)
    head.BackgroundTransparency = 1
    head.Text = "CONFIRMAR AÇÃO"
    head.TextColor3 = THEME.Danger
    head.Font = Enum.Font.GothamBold
    head.TextSize = 13
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.ZIndex = 62
    head.Parent = box
    Paint(head, "TextColor3", "Danger")

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -28, 0, 54)
    msg.Position = UDim2.new(0, 14, 0, 38)
    msg.BackgroundTransparency = 1
    msg.Text = ""
    msg.TextColor3 = THEME.Text
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 13
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.ZIndex = 62
    msg.Parent = box
    Paint(msg, "TextColor3", "Text")

    local yes = CreateButton(box, "CONFIRMAR", "Danger", 32)
    yes.Size = UDim2.new(0, 150, 0, 32)
    yes.Position = UDim2.new(1, -164, 1, -46)
    yes.ZIndex = 62

    local no = CreateButton(box, "CANCELAR", "Accent", 32)
    no.Size = UDim2.new(0, 120, 0, 32)
    no.Position = UDim2.new(0, 14, 1, -46)
    no.ZIndex = 62

    local pending

    local function close()
        overlay.Visible = false
        pending = nil
    end

    yes.MouseButton1Click:Connect(function()
        local fn = pending
        close()
        if fn then
            local ok, err = pcall(fn)
            if not ok then Log("ação: " .. tostring(err), "error") end
        end
    end)
    no.MouseButton1Click:Connect(close)

    -- Confirm(texto, fn): pede confirmação só se a opção estiver ligada
    Confirm = function(text, fn)
        if not SET.Confirm then
            local ok, err = pcall(fn)
            if not ok then Log("ação: " .. tostring(err), "error") end
            return
        end
        msg.Text = text
        pending = fn
        overlay.Visible = true
    end
end

--------------------------------------------------------------------------------
-- BOTÃO DE AÇÃO COM GATE DE REMOTE
-- remoteKey = chave em Remotes. Sem o remote o botão fica indisponível,
-- explica o motivo e registra no log — nunca finge que executou.
--------------------------------------------------------------------------------
local function ActionBtn(parent, text, colorKey, remoteKey, fn, confirmText)
    local available = (remoteKey == nil) or (Remotes[remoteKey] ~= nil)
    local b = CreateButton(parent, text, available and colorKey or "Line", 32)

    if not available then
        b.TextColor3 = THEME.Dim
        b.BackgroundTransparency = 0.45
        b.Text = text .. " (servidor)"
        Paint(b, "TextColor3", "Dim")
    end

    b.MouseButton1Click:Connect(function()
        if not available then
            Log(text .. ": precisa do RemoteEvent " .. tostring(remoteKey)
                .. " no ReplicatedStorage (função server-side)", "warn")
            Toast(text .. " depende de um Remote no servidor", "warn", 3)
            return
        end
        if confirmText then
            Confirm(confirmText, fn)
        else
            local ok, err = pcall(fn)
            if not ok then Log(text .. ": " .. tostring(err), "error") end
        end
    end)
    return b, available
end

-- Avatar (headshot) por UserId — usa rbxthumb, não baixa nada duas vezes
local function Avatar(parent, userId, size)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, size, 0, size)
    img.BackgroundColor3 = THEME.Track
    img.BorderSizePixel = 0
    img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=48&h=48"
    img.Parent = parent
    Paint(img, "BackgroundColor3", "Track")
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 8)
    return img
end

local function TagChip(parent, text, colorKey)
    local c = Instance.new("TextLabel")
    c.AutomaticSize = Enum.AutomaticSize.X
    c.Size = UDim2.new(0, 0, 0, 18)
    c.BackgroundColor3 = THEME[colorKey or "Btn"]
    c.BackgroundTransparency = 0.7
    c.Text = "  " .. text .. "  "
    c.TextColor3 = THEME[colorKey or "Dim"]
    c.Font = Enum.Font.GothamBold
    c.TextSize = 10
    c.Parent = parent
    Paint(c, "TextColor3", colorKey or "Dim")
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 5)
    return c
end

