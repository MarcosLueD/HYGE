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

    for _, id in ipairs(ToggleOrder) do
        KeybindRow(keyCard, id, Toggles[id].label)
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
        Log("Keybinds restaurados (F/N/E/C/G)", "ok")
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
        Log("Tema: " .. paletteName, "ok")
    end

    local themeGrid = Grid(look, 4, 32)
    themeGrid.LayoutOrder = 1
    for i, n in ipairs({ "Roxo", "Ciano", "Verde", "Vermelho", "Azul" }) do
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
        label = "Escala da interface", min = 70, max = 130, def = 100, suffix = "%", order = 2,
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

    local maxLogSet = SliderRow(beh, {
        label = "Linhas guardadas no log", min = 20, max = 300, def = SET.MaxLog, order = 5,
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
                     chatspy = false, antiafk = true, freecam = false, drone = false },
        Admin    = { esp = true, fullbright = true, antiafk = true, chatspy = true,
                     noclip = false, fly = false, drone = false, freecam = false },
        Visual   = { esp = true, fullbright = true, wall = true, chatspy = false,
                     fly = false, noclip = false, drone = false, freecam = false },
        Movement = { fly = true, noclip = true, infjump = true, esp = false,
                     fullbright = false, drone = false, freecam = false },
        Minimal  = { antiafk = true, fly = false, noclip = false, esp = false,
                     fullbright = false, infjump = false, god = false,
                     invisible = false, wall = false, chatspy = false,
                     freecam = false, drone = false },
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

    local preGrid = Grid(pre, 5, 32)
    for i, n in ipairs({ "Default", "Admin", "Visual", "Movement", "Minimal" }) do
        local b = CreateButton(preGrid, n:upper(), "Accent", 32)
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function() ApplyPreset(n) end)
    end

    ----------------------------------------------------------------------------
    -- SISTEMA
    ----------------------------------------------------------------------------
    local sys = CreateCard(tab, "SISTEMA", 10)
    local sysGrid = Grid(sys, 4, 32)

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

    local about = CreateCard(tab, "SOBRE", 11)
    local _, _, missing = V8.RemoteStatus()

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.Text = "HYGE Admin Panel " .. CONFIG.Version
        .. "\nPainel client-side. Tudo que aparece aqui roda na SUA máquina."
        .. "\n\nAdmin: " .. LocalPlayer.Name .. " (UserId " .. LocalPlayer.UserId .. ")"
        .. "\nEdite CONFIG.AdminIds no topo do script para liberar outros admins."
        .. "\n\nRemotes ausentes: "
        .. (#missing == 0 and "nenhum — tudo pronto"
            or (table.concat(missing, ", ") .. "\nAs ações que dependem deles ficam "
                .. "indisponíveis (com aviso), nunca são simuladas. O script de "
                .. "servidor que cria e valida todos eles está em server/ (README)."))
    txt.TextColor3 = THEME.Dim
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = about
    Paint(txt, "TextColor3", "Dim")
end
