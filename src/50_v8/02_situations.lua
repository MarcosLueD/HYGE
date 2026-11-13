--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — SISTEMA DE SITUAÇÕES
-- Um clique troca o modo de operação inteiro: liga o que pertence à situação
-- e DESLIGA o que não pertence. Cards no Dashboard + keybind por situação.
-- Tudo dentro de um do..end (locais liberados no fim, por causa do limite
-- de ~200 slots do Luau).
--------------------------------------------------------------------------------
do
    V8.Sit = {}
    local S = V8.Sit

    S.Current = nil
    S.Keys    = {}   -- [nome] = KeyCode
    S.Order   = { "Moderação", "Caça", "Observação", "Movimento", "Stealth", "Limpeza" }

    -- on   = toggles que a situação liga (o resto é desligado)
    -- esp  = campos de EspOpts sobrescritos
    -- walk / fly / jump = velocidades aplicadas pelos sliders reais
    -- tab  = aba aberta ao aplicar
    S.Defs = {
        ["Moderação"] = {
            icon = "shield", desc = "vigiar a sala", key = Enum.KeyCode.KeypadOne,
            on   = { esp = true, fullbright = true, chatspy = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = false, Allies = true, Enemies = true },
            tab  = "Players",
        },
        ["Caça"] = {
            icon = "eye", desc = "só inimigos", key = Enum.KeyCode.KeypadTwo,
            on   = { esp = true, fly = true, noclip = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = true, Allies = false, Enemies = true },
            fly  = 90,
            tab  = "Visuals",
        },
        ["Observação"] = {
            icon = "cam", desc = "freecam + spectate", key = Enum.KeyCode.KeypadThree,
            on   = { freecam = true, esp = true, chatspy = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = false,
                     HealthBar = false, Tracers = false, Allies = true, Enemies = true },
            tab  = "Players",
            hint = "Selecione um jogador e use ASSISTIR (ou 'spec <nome>').",
        },
        ["Movimento"] = {
            icon = "run", desc = "atravessar o mapa", key = Enum.KeyCode.KeypadFour,
            on   = { fly = true, noclip = true, infjump = true, antiafk = true },
            walk = 80, fly = 120, jump = 100,
            tab  = "Movement",
        },
        ["Stealth"] = {
            icon = "ghost", desc = "sumir da tela", key = Enum.KeyCode.KeypadFive,
            on   = { invisible = true, wall = true, esp = true, antiafk = true },
            esp  = { Highlight = true, Name = false, Distance = false, Health = false,
                     HealthBar = false, Tracers = false, Allies = true, Enemies = true },
            tab  = "Visuals",
        },
        ["Limpeza"] = {
            icon = "trash", desc = "desligar tudo", key = Enum.KeyCode.KeypadSix,
            on   = {},
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = false, Allies = true, Enemies = true,
                     MaxDist = 1000, TeamColors = false },
            walk = 16, fly = 50, jump = 50,
            clean = true,
        },
    }

    for n, d in pairs(S.Defs) do S.Keys[n] = d.key end

    local cards = {}    -- [nome] = { bar = Frame, name = TextLabel, key = TextLabel }
    local keyBtns = {}  -- [nome] = TextButton (aba Settings)
    local header                                     -- label "SITUAÇÃO ATIVA: ..."

    ----------------------------------------------------------------------------
    -- render do estado ativo (cards + header + rótulos de tecla)
    ----------------------------------------------------------------------------
    S.Render = function()
        for n, c in pairs(cards) do
            local active = (S.Current == n)
            c.bar.Visible = active
            c.name.TextColor3 = active and THEME.Accent or THEME.Text
            c.key.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—"
        end
        for n, b in pairs(keyBtns) do
            if b.Text ~= "aperte..." then b.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—" end
        end
        if header then
            header.Text = "SITUAÇÃO ATIVA:  " .. (S.Current and S.Current:upper() or "NENHUMA")
            header.TextColor3 = S.Current and THEME.Accent or THEME.Dim
        end
    end

    ----------------------------------------------------------------------------
    -- aplica uma situação
    ----------------------------------------------------------------------------
    S.Apply = function(name, silent)
        local d = S.Defs[name]
        if not d then
            Log("Situação desconhecida: " .. tostring(name), "warn")
            return false
        end

        local changed = 0
        for _, id in ipairs(ToggleOrder) do
            local want = (d.on[id] == true)
            if IsOn(id) ~= want then
                local ok = pcall(SetToggle, id, want, true)
                if ok then changed = changed + 1 end
            end
        end

        if d.esp then
            for k, v in pairs(d.esp) do EspOpts[k] = v end
        end
        if d.walk and WalkSlider then pcall(WalkSlider, d.walk) end
        if d.fly  and FlySlider  then pcall(FlySlider, d.fly) end
        if d.jump and JumpSlider then pcall(JumpSlider, d.jump) end

        if d.clean then
            pcall(StopSpectate)
            pcall(function() Emote.Stop(true) end)
        end

        S.Current = name
        if d.tab then pcall(ShowTab, d.tab) end
        if RefreshQuick then pcall(RefreshQuick) end
        if RefreshStatus then pcall(RefreshStatus) end
        pcall(S.Render)

        if not silent then
            Log("Situação " .. name .. " aplicada (" .. changed .. " mudança(s))", "action")
            if d.hint then Log(d.hint) end
            Toast("Situação: " .. name, d.clean and "warn" or "ok", 2.5)
        end
        return true
    end

    -- aceita nome parcial / sem acento certo ("mod", "caca", "stealth")
    S.Find = function(q)
        if not q or q == "" then return nil end
        q = tostring(q):lower()
        for _, n in ipairs(S.Order) do
            local low = n:lower()
            if low == q then return n end
        end
        for _, n in ipairs(S.Order) do
            if n:lower():sub(1, #q) == q then return n end
        end
        for _, n in ipairs(S.Order) do
            if n:lower():find(q, 1, true) then return n end
        end
        return nil
    end

    ----------------------------------------------------------------------------
    -- teclas (chamado pelo handler global de 90_runtime/03_input.lua)
    ----------------------------------------------------------------------------
    S.HandleKey = function(input)
        for n, kc in pairs(S.Keys) do
            if kc == input.KeyCode then
                S.Apply(n)
                return true
            end
        end
        return false
    end

    ----------------------------------------------------------------------------
    -- CARDS NO DASHBOARD (aba Home, no topo)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Home"], "SITUAÇÕES", 0)
        SubLabel(card, "Um clique troca o modo de operação: liga o que pertence à "
            .. "situação e desliga o resto. As teclas ficam na aba Settings.", -1)

        header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, 0, 0, 14)
        header.BackgroundTransparency = 1
        header.Text = "SITUAÇÃO ATIVA:  NENHUMA"
        header.TextColor3 = THEME.Dim
        header.Font = Enum.Font.GothamBold
        header.TextSize = 10
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = 0
        header.Parent = card
        table.insert(Painted, { inst = header, prop = "TextColor3", key = "Dim" })

        local grid = Grid(card, 2, 54)   -- v8.0: janela estreita (era 3)
        grid.LayoutOrder = 1

        for i, n in ipairs(S.Order) do
            local d = S.Defs[n]
            local b = CreateButton(grid, "", d.clean and "Danger" or "Accent", 54)
            b.LayoutOrder = i

            local ic = Icon(b, d.icon, d.clean and THEME.Danger or THEME.Accent, 16)
            ic.Position = UDim2.new(0, 10, 0, 9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -76, 0, 15)
            nm.Position = UDim2.new(0, 33, 0, 9)
            nm.BackgroundTransparency = 1
            nm.Text = n:upper()
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = b

            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -44, 0, 12)
            ds.Position = UDim2.new(0, 33, 0, 26)
            ds.BackgroundTransparency = 1
            ds.Text = d.desc
            ds.TextColor3 = THEME.Dim
            ds.Font = Enum.Font.Gotham
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.Parent = b
            table.insert(Painted, { inst = ds, prop = "TextColor3", key = "Dim" })

            local kl = Instance.new("TextLabel")
            kl.AnchorPoint = Vector2.new(1, 0)
            kl.Size = UDim2.new(0, 60, 0, 13)
            kl.Position = UDim2.new(1, -8, 0, 9)
            kl.BackgroundTransparency = 1
            kl.Text = d.key and KeyName(d.key) or "—"
            kl.TextColor3 = THEME.Accent2
            kl.Font = Enum.Font.Code
            kl.TextSize = 10
            kl.TextXAlignment = Enum.TextXAlignment.Right
            kl.Parent = b
            table.insert(Painted, { inst = kl, prop = "TextColor3", key = "Accent2" })

            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 1)
            bar.Position = UDim2.new(0.5, 0, 1, -4)
            bar.Size = UDim2.new(1, -16, 0, 3)
            bar.BackgroundColor3 = THEME.Accent
            bar.BorderSizePixel = 0
            bar.Visible = false
            bar.Parent = b
            Paint(bar, "BackgroundColor3", "Accent")
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            cards[n] = { bar = bar, name = nm, key = kl }
            b.MouseButton1Click:Connect(function() S.Apply(n) end)
        end
    end

    ----------------------------------------------------------------------------
    -- ATALHOS DAS SITUAÇÕES (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "ATALHOS DAS SITUAÇÕES", 5)
        SubLabel(card, "Padrão: teclado numérico 1 a 6. Clique e aperte a tecla; "
            .. "Backspace remove. Conflitos com funções são desfeitos automaticamente.", -1)

        for i, n in ipairs(S.Order) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i
            row.Parent = card

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -110, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Situação " .. n
            lbl.TextColor3 = THEME.Text
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = row
            Paint(lbl, "TextColor3", "Text")

            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.new(1, 0, 0.5, 0)
            btn.Size = UDim2.new(0, 96, 0, 26)
            btn.BackgroundColor3 = THEME.Btn
            btn.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—"
            btn.TextColor3 = THEME.Accent2
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            btn.AutoButtonColor = false
            btn.Parent = row
            Paint(btn, "BackgroundColor3", "Btn")
            Paint(btn, "TextColor3", "Accent2")
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
            local st = Instance.new("UIStroke", btn)
            st.Transparency = 0.6
            Paint(st, "Color", "Accent")

            keyBtns[n] = btn

            btn.MouseButton1Click:Connect(function()
                Drop("SitCapture")
                capturing = "sit:" .. n
                btn.Text = "aperte..."
                Toast("Aperte a tecla da situação " .. n .. " (Backspace remove)", nil, 3)

                Conn.SitCapture = UserInputService.InputBegan:Connect(function(input)
                    if capturing ~= ("sit:" .. n) then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    local kc = input.KeyCode
                    if kc == Enum.KeyCode.Unknown then return end

                    Drop("SitCapture")
                    capturing = nil

                    if kc == Enum.KeyCode.Backspace then
                        S.Keys[n] = nil
                        Log("Atalho da situação " .. n .. " removido")
                    elseif kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey then
                        Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                    else
                        for id, other in pairs(Keybinds) do
                            if other == kc then
                                Keybinds[id] = nil
                                if KeybindLabels[id] then KeybindLabels[id].Text = "—" end
                                Log("Tecla " .. KeyName(kc) .. " tirada de '" .. id .. "'", "warn")
                            end
                        end
                        for other, okc in pairs(S.Keys) do
                            if okc == kc and other ~= n then S.Keys[other] = nil end
                        end
                        S.Keys[n] = kc
                        Log("Situação " .. n .. " = " .. KeyName(kc), "ok")
                    end
                    pcall(S.Render)
                end)
            end)
        end
    end

    S.Render()
end
