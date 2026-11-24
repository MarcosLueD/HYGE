--------------------------------------------------------------------------------
-- ABA HOME (dashboard)
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Home")

    ----------------------------------------------------------------------------
    -- VISÃO GERAL
    ----------------------------------------------------------------------------
    -- v8.1: MAPA ATUAL (0) e PERFIL (1) entram antes, em 01_home_server.lua
    local overview = CreateCard(tab, "VISÃO GERAL", 2)
    local grid = Grid(overview, 4, 48)
    Tiles = {}

    local function T(key, label, def, colorKey)
        local val = StatTile(grid, label, def, #Tiles + 1, colorKey)
        Tiles[key] = val
        return val
    end

    T("fps",     "FPS",       "—", "Success")
    T("ping",    "PING",      "—", "Accent2")
    T("players", "JOGADORES", "—")
    T("uptime",  "UPTIME",    "—")

    ----------------------------------------------------------------------------
    -- SEGUNDA FILEIRA: identificadores com botão de copiar
    ----------------------------------------------------------------------------
    local grid2 = Grid(overview, 2, 62)   -- v8.0: janela estreita (era 4)

    local function InfoCard(label, value, iconKind, iconColor, order, copyFn)
        local box = Instance.new("Frame")
        box.BackgroundColor3 = THEME.Btn
        box.BorderSizePixel = 0
        box.LayoutOrder = order
        box.Parent = grid2
        Paint(box, "BackgroundColor3", "Btn")
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
        local st = Instance.new("UIStroke", box)
        st.Transparency = 0.85
        Paint(st, "Color", "Line")

        local cap = Instance.new("TextLabel")
        cap.Size = UDim2.new(1, -34, 0, 12)
        cap.Position = UDim2.new(0, 9, 0, 8)
        cap.BackgroundTransparency = 1
        cap.Text = label
        cap.TextColor3 = THEME.Dim
        cap.Font = Enum.Font.GothamBold
        cap.TextSize = 9
        cap.TextXAlignment = Enum.TextXAlignment.Left
        cap.Parent = box
        Paint(cap, "TextColor3", "Dim")

        local ic = Icon(box, iconKind, iconColor, 15)
        ic.Position = UDim2.new(1, -24, 0, 8)

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(1, -42, 0, 32)
        val.Position = UDim2.new(0, 9, 0, 23)
        val.BackgroundTransparency = 1
        val.Text = tostring(value)
        val.TextColor3 = THEME.Text
        val.Font = Enum.Font.GothamBold
        val.TextSize = 14
        val.TextWrapped = true
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.TextYAlignment = Enum.TextYAlignment.Top
        val.Parent = box
        Paint(val, "TextColor3", "Text")

        if copyFn then
            local cb = Instance.new("TextButton")
            cb.AnchorPoint = Vector2.new(1, 1)
            cb.Position = UDim2.new(1, -7, 1, -7)
            cb.Size = UDim2.new(0, 22, 0, 22)
            cb.BackgroundTransparency = 1
            cb.Text = ""
            cb.AutoButtonColor = false
            cb.Parent = box
            Icon(cb, "copy", THEME.Dim, 14).Position = UDim2.new(0, 4, 0, 4)
            cb.MouseButton1Click:Connect(function()
                local text = copyFn()
                if setclipboard then
                    setclipboard(text)
                    Toast("Copiado: " .. text, "ok", 1.6)
                else
                    print("[HYGE] " .. text)
                    Toast("Executor sem setclipboard — jogado no output", "warn")
                end
            end)
        end
        return val
    end

    Tiles.place = InfoCard("PLACE ID", tostring(game.PlaceId), "box", THEME.Accent, 1,
        function() return tostring(game.PlaceId) end)
    Tiles.job = InfoCard("JOB ID", "—", "clip", THEME.Accent, 2,
        function() return (game.JobId ~= "" and game.JobId or "estúdio") end)
    Tiles.active = InfoCard("FUNÇÕES ON", "0", "bolt", THEME.Warning, 3)
    Tiles.remotes = InfoCard("REMOTES", "—", "wifi", THEME.Accent2, 4)

    ----------------------------------------------------------------------------
    -- QUICK ACTIONS (pílulas com switch real)
    ----------------------------------------------------------------------------
    local quick = CreateCard(tab, "AÇÕES RÁPIDAS", 3)
    -- v9.0: as ações rápidas são os FAVORITOS (estrela em qualquer função)
    SubLabel(quick, "Um clique liga/desliga. Toque na estrela ao lado de qualquer "
        .. "função (Personagem, Visual, Troll...) para fixar ou tirar daqui.", -1)

    local qGrid = Grid(quick, 2, 40)   -- v8.0: janela estreita (era 4)
    local quickBtns = {}

    -- v9.0: nome curto, ícone e cor de cada função (vale para qualquer
    -- toggle que virar favorito)
    V8.ToggleLook = {
        fly        = { "Fly", "bolt", "Accent2" },
        noclip     = { "Noclip", "ghost", "Accent" },
        esp        = { "ESP", "eye", "Success" },
        freecam    = { "Freecam", "cam", "Accent" },
        infjump    = { "Inf Jump", "up", "Accent2" },
        god        = { "God", "shield", "Success" },
        invisible  = { "Invisível", "circle", "Accent" },
        fullbright = { "Fullbright", "sun", "Warning" },
        wall       = { "Paredes", "box", "Accent" },
        chatspy    = { "Chat Spy", "clip", "Accent2" },
        antiafk    = { "Anti-AFK", "clock", "Success" },
        drone      = { "Drone", "wifi", "Accent" },
        antifall   = { "Anti-Fall", "shield", "Accent2" },
        antigrav   = { "Anti-Grav", "up", "Accent" },
        wallwalk   = { "Wall Walk", "mask", "Warning" },
        clicktp    = { "Clique TP", "link", "Accent2" },
    }

    local quickEmpty = SubLabel(quick, "Nenhuma função fixada. Toque na estrela de "
        .. "uma função para ela aparecer aqui.", 2)
    quickEmpty.Visible = false
    local quickSig = nil

    local function QuickPill(i, id)
        local look = V8.ToggleLook[id] or { Toggles[id].label or id, "dot", "Accent" }
        local label, kind, ck = look[1], look[2], look[3]

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundColor3 = THEME.Btn
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.Parent = qGrid
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
        local bs = Instance.new("UIStroke", b)
        bs.Transparency = 0.85
        Paint(bs, "Color", "Line")

        local ic = Icon(b, kind, THEME[ck], 16)
        ic.Position = UDim2.new(0, 10, 0.5, -8)

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -100, 1, 0)
        lb.Position = UDim2.new(0, 34, 0, 0)
        lb.BackgroundTransparency = 1
        lb.Text = label
        lb.TextColor3 = THEME.Text
        lb.Font = Enum.Font.GothamMedium
        lb.TextSize = 12
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.TextTruncate = Enum.TextTruncate.AtEnd
        lb.Parent = b
        Paint(lb, "TextColor3", "Text")

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -44, 0.5, 0)
        track.Size = UDim2.new(0, 32, 0, 17)
        track.BackgroundColor3 = THEME.Track
        track.BorderSizePixel = 0
        track.Parent = b
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = UDim2.new(0, 2, 0.5, 0)
        knob.Size = UDim2.new(0, 13, 0, 13)
        knob.BackgroundColor3 = THEME.Text
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = Instance.new("TextLabel")
        state.AnchorPoint = Vector2.new(1, 0.5)
        state.Position = UDim2.new(1, -8, 0.5, 0)
        state.Size = UDim2.new(0, 30, 0, 14)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = THEME.Dim
        state.Font = Enum.Font.GothamBold
        state.TextSize = 10
        state.TextXAlignment = Enum.TextXAlignment.Right
        state.Parent = b

        b.MouseButton1Click:Connect(function() Flip(id) end)
        quickBtns[id] = { track = track, knob = knob, state = state, icon = ic, key = ck }
    end

    -- monta (de novo) as pílulas a partir da lista de favoritos
    local function BuildQuick()
        local list = V8.Fav and V8.Fav.List() or {}
        quickSig = table.concat(list, " ")
        for _, c in ipairs(qGrid:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for k in pairs(quickBtns) do quickBtns[k] = nil end
        local shown = 0
        for _, id in ipairs(list) do
            if Toggles[id] then
                shown = shown + 1
                QuickPill(shown, id)
            end
        end
        quickEmpty.Visible = (shown == 0)
        if RefreshQuick then pcall(RefreshQuick) end
    end
    BuildQuick()
    if V8.Fav then V8.Fav.OnChange = BuildQuick end
    -- config/perfil carregado trocou a lista: remonta só se mudou
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, function()
        local list = V8.Fav and V8.Fav.List() or {}
        if table.concat(list, " ") ~= quickSig then BuildQuick() end
    end)

    ----------------------------------------------------------------------------
    -- DESLIGAR TUDO (centralizado)
    ----------------------------------------------------------------------------
    local offHolder = Instance.new("Frame")
    offHolder.Size = UDim2.new(1, 0, 0, 40)
    offHolder.BackgroundTransparency = 1
    offHolder.LayoutOrder = 90
    offHolder.Parent = quick

    local allOff = Instance.new("TextButton")
    allOff.AnchorPoint = Vector2.new(0.5, 0.5)
    allOff.Position = UDim2.new(0.5, 0, 0.5, 0)
    allOff.Size = UDim2.new(0, 300, 0, 34)
    allOff.BackgroundColor3 = THEME.Danger
    allOff.Text = "DESLIGAR TUDO"
    allOff.TextColor3 = Color3.fromRGB(255, 235, 235)
    allOff.Font = Enum.Font.GothamBold
    allOff.TextSize = 13
    allOff.AutoButtonColor = false
    allOff.Parent = offHolder
    Paint(allOff, "BackgroundColor3", "Danger")
    Instance.new("UICorner", allOff).CornerRadius = UDim.new(0, 9)
    Icon(allOff, "power", Color3.fromRGB(255, 235, 235), 16).Position =
        UDim2.new(0, 78, 0.5, -8)

    allOff.MouseEnter:Connect(function()
        Anim(allOff, 0.12, { BackgroundTransparency = 0.15 })
    end)
    allOff.MouseLeave:Connect(function()
        Anim(allOff, 0.12, { BackgroundTransparency = 0 })
    end)

    allOff.MouseButton1Click:Connect(function()
        local n = 0
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then
                SetToggle(id, false, true)
                n = n + 1
            end
        end
        if State.Spectating then StopSpectate() end
        Log("Desligar tudo: " .. n .. " função(ões) encerrada(s)", "action")
        Toast(n .. " função(ões) desligada(s)", "ok", 2)
        if RefreshQuick then RefreshQuick() end
        if RefreshStatus then RefreshStatus() end
    end)

    -- RefreshQuick: chamado pelo scheduler e pelo registry de toggles
    RefreshQuick = function()
        local active = 0
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then active = active + 1 end
        end
        for id, ref in pairs(quickBtns) do
            local on = IsOn(id)
            ref.state.Text = on and "ON" or "OFF"
            ref.state.TextColor3 = on and THEME.Success or THEME.Dim
            Anim(ref.track, 0.14, { BackgroundColor3 = on and THEME.Success or THEME.Track })
            Anim(ref.knob, 0.14, {
                Position = on and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                BackgroundColor3 = on and Color3.fromRGB(15, 22, 20) or THEME.Text,
            })
            IconTint(ref.icon, on and THEME[ref.key] or THEME.Dim)
        end
        if Tiles.active then Tiles.active.Text = tostring(active) end
    end

    ----------------------------------------------------------------------------
    -- ATALHOS (rodapé compacto)
    ----------------------------------------------------------------------------
    local info = CreateCard(tab, nil, 4)
    local keysLbl = SubLabel(info, "", 1)
    keysLbl.TextSize = 10

    -- v8.0: o rodapé lê os atalhos REAIS (antes era texto fixo F/N/E/C/G e
    -- mentia depois de remapear em Ajustes)
    local function ShortcutText()
        local parts = { "ATALHOS", "[" .. KeyName(CONFIG.PanelKey) .. "] painel",
            "[" .. KeyName(CONFIG.ConsoleKey) .. "] comandos" }
        if CONFIG.SearchKey then
            table.insert(parts, "[" .. (CONFIG.SearchCtrl and "Ctrl+" or "")
                .. KeyName(CONFIG.SearchKey) .. "] busca")
        end
        for _, id in ipairs(ToggleOrder) do
            if Keybinds[id] then
                table.insert(parts, "[" .. KeyName(Keybinds[id]) .. "] "
                    .. (Toggles[id].label or id))
            end
        end
        table.insert(parts, "remapeável em Ajustes")
        return table.concat(parts, "   ·   ")
    end
    keysLbl.Text = ShortcutText()

    OnTabOpen("Home", function()
        pcall(function() keysLbl.Text = ShortcutText() end)
        if RefreshQuick then RefreshQuick() end
        if Tiles.job then
            Tiles.job.Text = (game.JobId ~= "" and game.JobId or "estúdio")
        end
    end)
end
