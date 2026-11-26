--------------------------------------------------------------------------------
-- ABA SETTINGS
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Settings")

    ----------------------------------------------------------------------------
    -- KEYBINDS
    ----------------------------------------------------------------------------
    local keyCard = CreateCard(tab, "KEYBINDS", 1)
    SubLabel(keyCard, "Clique no botão e aperte a tecla. Backspace remove. "
        .. "Se a tecla já estiver em uso, o painel avisa qual função perdeu o atalho.", -1)

    Keybinds.fly     = Enum.KeyCode.F
    Keybinds.noclip  = Enum.KeyCode.N
    Keybinds.esp     = Enum.KeyCode.E
    Keybinds.freecam = Enum.KeyCode.C
    Keybinds.drone   = Enum.KeyCode.G

    for i, id in ipairs(ToggleOrder) do
        KeybindRow(keyCard, id, Toggles[id].label).LayoutOrder = i
    end

    -- v8.1: a tecla que abre/fecha o painel também é remapeável (vai na config)
    do
        local function PanelKeyRow()
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.LayoutOrder = 0
            row.Parent = keyCard
            V8.Cell(row, 5)

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -110, 1, 0)
            name.BackgroundTransparency = 1
            name.Text = "Abrir/fechar o painel"
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
            btn.Text = KeyName(CONFIG.PanelKey)
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
            V8.PanelKeyLabel = btn

            btn.MouseButton1Click:Connect(function()
                StopCapture()   -- encerra outra captura em andamento
                Drop("PanelCapture")
                capturing = "panel"
                btn.Text = "aperte..."
                Toast("Aperte a nova tecla do painel", nil, 3)
                Conn.PanelCapture = UserInputService.InputBegan:Connect(function(input)
                    if capturing ~= "panel" then
                        Drop("PanelCapture")
                        btn.Text = KeyName(CONFIG.PanelKey)
                        return
                    end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    local kc = input.KeyCode
                    if kc == Enum.KeyCode.Unknown then return end
                    Drop("PanelCapture")
                    -- solta a captura só depois deste evento: senão o handler
                    -- global vê a tecla nova e já abre/fecha o painel
                    task.defer(function()
                        if capturing == "panel" then capturing = nil end
                    end)
                    local clash
                    if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace
                        or kc == Enum.KeyCode.Return then
                        clash = "uso do Roblox"
                    elseif kc == CONFIG.ConsoleKey then
                        clash = "barra de comandos"
                    elseif kc == CONFIG.SearchKey and not CONFIG.SearchCtrl then
                        clash = "busca global"
                    end
                    for tid, k in pairs(Keybinds) do
                        if k == kc then clash = Toggles[tid] and Toggles[tid].label or tid end
                    end
                    if clash then
                        Toast("[" .. KeyName(kc) .. "] já é de " .. clash .. " — nada mudou", "warn", 3)
                    else
                        CONFIG.PanelKey = kc
                        Log("Tecla do painel = " .. KeyName(kc), "ok")
                        -- v9.0: a tecla do painel ganha de tudo: macro nela some
                        if V8.Macro and V8.Macro.Release then pcall(V8.Macro.Release, kc) end
                    end
                    btn.Text = KeyName(CONFIG.PanelKey)
                end)
            end)
        end
        PanelKeyRow()
    end

    local kBtns = Grid(keyCard, 2, 30)
    kBtns.LayoutOrder = 80

    local clearKeys = CreateButton(kBtns, "REMOVER TODOS", "Danger", 30)
    clearKeys.LayoutOrder = 1
    clearKeys.MouseButton1Click:Connect(function()
        Confirm("Remover todos os atalhos de teclado?", function()
            for id in pairs(Keybinds) do
                Keybinds[id] = nil
                if KeybindLabels[id] then KeybindLabels[id].Text = "—" end
            end
            Log("Todos os keybinds removidos", "action")
        end)
    end)

    local resetKeys = CreateButton(kBtns, "VOLTAR AO PADRÃO", "Success", 30)
    resetKeys.LayoutOrder = 2
    local function ResetKeys()
        for id in pairs(Keybinds) do Keybinds[id] = nil end
        Keybinds.fly     = Enum.KeyCode.F
        Keybinds.noclip  = Enum.KeyCode.N
        Keybinds.esp     = Enum.KeyCode.E
        Keybinds.freecam = Enum.KeyCode.C
        Keybinds.drone   = Enum.KeyCode.G
        for id, lbl in pairs(KeybindLabels) do lbl.Text = KeyName(Keybinds[id]) end
        CONFIG.PanelKey = Enum.KeyCode.B   -- v8.1: a tecla do painel também volta
        if V8.PanelKeyLabel then V8.PanelKeyLabel.Text = KeyName(CONFIG.PanelKey) end
        Log("Keybinds restaurados (painel B · F/N/E/C/G)", "ok")
    end
    resetKeys.MouseButton1Click:Connect(ResetKeys)

    ----------------------------------------------------------------------------
    -- APARÊNCIA
    ----------------------------------------------------------------------------
    local look = CreateCard(tab, "APARÊNCIA", 2)

    ApplyTheme = function(paletteName)
        local p = PALETTES[paletteName]
        if not p then return end
        for k, v in pairs(p) do THEME[k] = v end
        for i = #Painted, 1, -1 do
            local entry = Painted[i]
            if entry.inst.Parent or entry.inst == Gui then
                local ok = pcall(function() entry.inst[entry.prop] = THEME[entry.key] end)
                if not ok then table.remove(Painted, i) end
            else
                table.remove(Painted, i)
            end
        end
        if RefreshStatus then RefreshStatus() end
        if RefreshQuick then RefreshQuick() end
        -- v8.0: as linhas do log saíram do registry; redesenha com as cores novas
        if RenderLog then pcall(RenderLog, nil) end
        -- v9.0: a prévia ao vivo da cor personalizada reaplica o tema várias
        -- vezes seguidas; nessas o log fica quieto
        if not V8.QuietTheme then Log("Tema: " .. paletteName, "ok") end
    end

    local themeGrid = Grid(look, 3, 32)
    themeGrid.LayoutOrder = 1
    -- v9.0: 9 temas (Rosa, Laranja e Meia-noite novos); a cor personalizada
    -- tem cartão próprio (50_v8/12_colors.lua)
    for i, n in ipairs(THEME_ORDER) do
        local b = CreateButton(themeGrid, "   " .. n:upper(), "Accent", 32)
        b.LayoutOrder = i
        local sw = Instance.new("Frame")
        sw.Size = UDim2.new(0, 8, 0, 8)
        sw.Position = UDim2.new(0, 8, 0.5, -4)
        sw.BackgroundColor3 = PALETTES[n].Accent
        sw.BorderSizePixel = 0
        sw.Parent = b
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        b.MouseButton1Click:Connect(function() ApplyTheme(n) end)
    end

    local scaleSet = SliderRow(look, {
        label = "Tamanho da GUI", min = 70, max = 130, def = 100, suffix = "%", order = 2,
        apply = function(v)
            CONFIG.UiScale = v / 100
            WindowScale.Scale = CONFIG.UiScale
        end,
    })

    local alphaSet = SliderRow(look, {
        label = "Transparência da janela", min = 0, max = 60, def = 0, suffix = "%", order = 3,
        apply = function(v)
            SET.Transparency = v / 100
            Window.BackgroundTransparency = SET.Transparency
            Sidebar.BackgroundTransparency = SET.Transparency
            ConsoleFrame.BackgroundTransparency = SET.Transparency
        end,
    })

    local compactRender
    local function ApplyCompact(on)
        SET.Compact = on
        -- v8: com o shell novo quem manda na geometria e o V8.Shell.Layout
        if V8.Shell and V8.Shell.Layout then
            if on then V8.Shell.ConsoleOpen = false end
            pcall(V8.Shell.Layout)
            return
        end
        ConsoleFrame.Visible = (not on) and (not State.Minimized)
        Content.Size = on and UDim2.new(1, -184, 1, -84) or UDim2.new(1, -184, 1, -214)
    end
    -- v8.0: a aba Scripts esconde esta linha (o console saiu da janela)
    compactRender, V8.CompactRow = CheckRow(look, "Modo compacto",
        "Esconde o console e dá mais espaço para as abas",
        function() return SET.Compact end,
        function(v) ApplyCompact(v) end, 4)

    CheckRow(look, "Animações", "Desligue se o jogo estiver pesado",
        function() return SET.Animations end,
        function(v) SET.Animations = v end, 5)

    ----------------------------------------------------------------------------
    -- COMPORTAMENTO
    ----------------------------------------------------------------------------
    local beh = CreateCard(tab, "COMPORTAMENTO", 3)

    CheckRow(beh, "Confirmar ações destrutivas", "Pede confirmação em kick, freeze, limpar...",
        function() return SET.Confirm end,
        function(v) SET.Confirm = v end, 1)

    CheckRow(beh, "Toasts", "Avisos flutuantes no canto da tela",
        function() return SET.Toasts end,
        function(v) SET.Toasts = v end, 2)

    CheckRow(beh, "Registrar no console", "Desligado, só os erros continuam aparecendo no log",
        function() return SET.ShowLogs end,
        function(v) SET.ShowLogs = v end, 3)

    CheckRow(beh, "ESP automático no respawn", "Reconstrói o ESP quando alguém renasce",
        function() return SET.EspAuto end,
        function(v) SET.EspAuto = v end, 4)

    -- v9.0.1: o Shift do Roblox prendia o mouse no centro (Shift Lock) — e o
    -- Fly usa o Shift para acelerar. Quem aplica é o V8.ShiftLock (03_input).
    CheckRow(beh, "Bloquear Shift Lock do Roblox", "O Shift não prende mais o mouse no centro da tela",
        function() return SET.NoShiftLock ~= false end,
        function(v)
            SET.NoShiftLock = v
            if V8.ShiftLock then V8.ShiftLock.Sync() end
        end, 5)

    local maxLogSet = SliderRow(beh, {
        label = "Linhas guardadas no log", min = 20, max = 300, def = SET.MaxLog, order = 6,
        apply = function(v)
            SET.MaxLog = v
            CONFIG.MaxLog = v
        end,
    })

    ----------------------------------------------------------------------------
    -- PRESETS
    ----------------------------------------------------------------------------
    local pre = CreateCard(tab, "PRESETS", 4)
    SubLabel(pre, "Presets mexem só nas funções e nos valores — seus keybinds ficam intactos.", -1)

    local PRESETS = {
        Default  = { fly = false, noclip = false, esp = false, fullbright = false,
                     infjump = false, god = false, invisible = false, wall = false,
                     chatspy = false, antiafk = true, freecam = false, drone = false,
                     antifall = false, antigrav = false, wallwalk = false },
        Admin    = { esp = true, fullbright = true, antiafk = true, chatspy = true,
                     noclip = false, fly = false, drone = false, freecam = false },
        Visual   = { esp = true, fullbright = true, wall = true, chatspy = false,
                     fly = false, noclip = false, drone = false, freecam = false },
        Movement = { fly = true, noclip = true, infjump = true, esp = false,
                     fullbright = false, drone = false, freecam = false,
                     antifall = true, wallwalk = false },
        Minimal  = { antiafk = true, fly = false, noclip = false, esp = false,
                     fullbright = false, infjump = false, god = false,
                     invisible = false, wall = false, chatspy = false,
                     freecam = false, drone = false, antifall = false,
                     antigrav = false, wallwalk = false },
    }

    ApplyPreset = function(name)
        local p = PRESETS[name]
        if not p then
            Log("Preset desconhecido: " .. tostring(name), "warn")
            return false
        end
        local changed = 0
        for id, want in pairs(p) do
            if Toggles[id] and IsOn(id) ~= want then
                SetToggle(id, want, true)
                changed = changed + 1
            end
        end
        if name == "Movement" then
            if WalkSlider then WalkSlider(60) end
            if FlySlider then FlySlider(90) end
        elseif name == "Default" or name == "Minimal" then
            if WalkSlider then WalkSlider(16) end
            if JumpSlider then JumpSlider(50) end
            if FlySlider then FlySlider(50) end
        end
        Log("Preset " .. name .. " aplicado (" .. changed .. " mudança(s))", "action")
        Toast("Preset " .. name, "ok", 2)
        if RefreshQuick then RefreshQuick() end
        if RefreshStatus then RefreshStatus() end
        return true
    end

    local preGrid = Grid(pre, 3, 32)   -- v8.0: janela estreita (era 5)
    for i, n in ipairs({ "Default", "Admin", "Visual", "Movement", "Minimal" }) do
        local b = CreateButton(preGrid, n:upper(), "Accent", 32)
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function() ApplyPreset(n) end)
    end

    ----------------------------------------------------------------------------
    -- SISTEMA
    ----------------------------------------------------------------------------
    -- v8.2: 12 = Celular e toque, 13 = Atualização (50_v8); Sistema e Sobre no fim
    local sys = CreateCard(tab, "SISTEMA", 20)
    local sysGrid = Grid(sys, 2, 32)   -- v8.0: janela estreita (era 4)

    local reload = CreateButton(sysGrid, "RECARREGAR DADOS", "Accent", 32)
    reload.LayoutOrder = 1
    reload.MouseButton1Click:Connect(function()
        if RefreshStatus then RefreshStatus() end
        if RebuildPlayerRows then RebuildPlayerRows() end
        if UpdateServerInfo then UpdateServerInfo() end
        Log("Dados recarregados", "ok")
    end)

    local restore = CreateButton(sysGrid, "RESTAURAR PADRÕES", "Warning", 32)
    restore.LayoutOrder = 2
    restore.MouseButton1Click:Connect(function()
        Confirm("Voltar aparência, comportamento, velocidades e keybinds ao padrão?", function()
            -- v8.0: uma única implementação (V8.UI.restore, logo abaixo)
            if V8.UI and V8.UI.restore then V8.UI.restore() end
            Log("Configurações restauradas", "action")
        end)
    end)

    -- v8.0: janela arrastada para fora da tela tinha que recarregar o script
    local center = CreateButton(sysGrid, "CENTRALIZAR JANELA", "Accent", 32)
    center.LayoutOrder = 3
    center.MouseButton1Click:Connect(function()
        if V8.Win then V8.Win.Center() end
    end)

    local unload = CreateButton(sysGrid, "DESCARREGAR PAINEL", "Danger", 32)
    unload.LayoutOrder = 4
    unload.MouseButton1Click:Connect(function()
        Confirm("Descarregar o HYGE? Tudo é desfeito e a GUI é removida.", function()
            if Unload then Unload() end
        end)
    end)

    ----------------------------------------------------------------------------
    -- SOBRE
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- V8.0: expõe os setters desta aba para a persistência (V8.Cfg) usar
    ----------------------------------------------------------------------------
    V8.UI = {
        scale   = scaleSet,
        alpha   = alphaSet,
        maxlog  = maxLogSet,
        compact = ApplyCompact,
        compactRender = compactRender,
        resetkeys = ResetKeys,
        restore = function()
            SET.Animations = true
            SET.Toasts = true
            SET.ShowLogs = true
            SET.Confirm = true
            SET.EspAuto = true
            SET.NoShiftLock = true
            SET.MaxLog = 60
            CONFIG.MaxLog = 60
            ApplyCompact(false)
            if compactRender then compactRender() end
            -- v8.0: volta para o tema padrão da v8 (era "Roxo" fixo, mas o
            -- shell novo nasce em CONFIG.DefaultTheme)
            ApplyTheme(CONFIG.DefaultTheme)
            scaleSet(100)
            alphaSet(0)
            maxLogSet(60, true)
            ResetKeys()
            ApplyPreset("Default")
            if V8.Renders then
                for _, r in ipairs(V8.Renders) do pcall(r) end
            end
            if V8.Win then V8.Win.Center() end
        end,
    }

    local about = CreateCard(tab, "SOBRE", 21)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    -- v9.2: o estado do servidor muda depois do boot (a resposta do HYGE_Status)
    local function AboutText()
        local _, _, missing = V8.RemoteStatus()
        txt.Text = "HYGE Admin Panel " .. CONFIG.Version
            .. "\nPainel client-side. A interface e as funções LOCAIS rodam na SUA máquina; "
            .. "o que mexe em outros jogadores é pedido ao script de servidor, que decide."
            .. "\n\nVocê: " .. LocalPlayer.Name .. " (UserId " .. LocalPlayer.UserId .. ")"
            .. "\nCONFIG.AdminIds do painel só decide quem ABRE o painel. Quem pode agir "
            .. "nos outros é o CONFIG.AdminIds do script de servidor."
            .. "\n\nServidor: " .. (V8.Srv.Summary())
            .. (#missing == 0 and ""
                or ("\nRemotes ausentes: " .. table.concat(missing, ", ") .. "\nAs ações que "
                    .. "dependem deles ficam indisponíveis (com o motivo), nunca são simuladas. "
                    .. "Instalação: Início › Servidor (ou docs/SERVIDOR.md)."))
    end
    AboutText()
    V8.Srv.OnChange(AboutText)
    txt.TextColor3 = THEME.Dim
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = about
    Paint(txt, "TextColor3", "Dim")

    -- v9.0: reabre o cartão de novidades (50_v8/15_news.lua)
    local news = CreateButton(about, "VER NOVIDADES DA " .. CONFIG.Version:upper(), "Accent", 32)
    news.LayoutOrder = 2
    news.MouseButton1Click:Connect(function()
        if V8.News then V8.News.Show(false) end
    end)
end
