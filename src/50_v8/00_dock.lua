--------------------------------------------------------------------------------
-- v8.0 — DOCK DE ICONES (navegacao principal, estilo mockup)
-- Barra flutuante no rodape da janela: 7 icones + um oitavo "mais" que abre
-- um menuzinho com as abas restantes. A sidebar NAO foi removida: SET.Dock
-- escolhe qual das duas aparece (card NAVEGACAO nas Settings).
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS de 40_tabs/08_settings.lua no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    ----------------------------------------------------------------------------
    -- os 7 do mockup + o "mais". "tab" abre aba, "fn" roda acao.
    -- as acoes olham V8.* na hora do clique (esses modulos vem depois no cat).
    ----------------------------------------------------------------------------
    K.Items = {
        { id = "Home",     icon = "home",   label = "Home",           tab = "Home" },
        { id = "Console",  icon = "code",   label = "Console",
          fn = function()
              if V8.Shell and V8.Shell.ToggleConsole then V8.Shell.ToggleConsole()
              elseif V8.OpenCmdBar then V8.OpenCmdBar() end
          end },
        { id = "Players",  icon = "users",  label = "Jogadores",      tab = "Players" },
        { id = "Emotes",   icon = "music",  label = "Emotes",         tab = "Emotes" },
        { id = "Search",   icon = "search", label = "Busca (Ctrl+K)",
          fn = function()
              if V8.Search then V8.Search.Open() end
          end },
        { id = "Settings", icon = "gear",   label = "Ajustes",        tab = "Settings" },
        { id = "Cloud",    icon = "cloud",  label = "Salvar config",
          fn = function()
              if V8.Cfg then V8.Cfg.Save() end
          end },
        { id = "More",     icon = "dots",   label = "Mais abas",
          fn = function() K.ToggleMore() end },
    }

    -- o que sobrou vai pro menu do "mais"
    K.MoreTabs = { "Movement", "Visuals", "Moderation", "Server" }
    K.MoreLabels = {
        Movement = "Movimento", Visuals = "Visual",
        Moderation = "Moderação", Server = "Servidor",
    }

    K.Btns = {}     -- por id
    K.ByTab = {}    -- por nome de aba (usado no Sync)

    ----------------------------------------------------------------------------
    -- a barra: filha da Window, entao acompanha o arrasto do painel de graca
    ----------------------------------------------------------------------------
    local bar = Instance.new("Frame")
    bar.Name = "Dock"
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.Position = UDim2.new(0.5, 0, 1, -10)
    bar.Size = UDim2.new(0, 0, 0, 52)
    bar.AutomaticSize = Enum.AutomaticSize.X
    bar.BackgroundColor3 = THEME.Sidebar
    bar.BackgroundTransparency = 0.06
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.ZIndex = 8
    bar.Parent = Window
    Paint(bar, "BackgroundColor3", "Sidebar")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 16)
    do
        local st = Instance.new("UIStroke", bar)
        st.Transparency = 0.55
        Paint(st, "Color", "Line")
    end

    do
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingTop = UDim.new(0, 6)
        local l = Instance.new("UIListLayout", bar)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.VerticalAlignment = Enum.VerticalAlignment.Center
    end

    -- nome aparece em cima do dock no hover
    local tip = Instance.new("TextLabel")
    tip.AnchorPoint = Vector2.new(0.5, 1)
    tip.Position = UDim2.new(0.5, 0, 0, -6)
    tip.Size = UDim2.new(0, 0, 0, 20)
    tip.AutomaticSize = Enum.AutomaticSize.X
    tip.BackgroundColor3 = THEME.Card
    tip.Text = ""
    tip.TextColor3 = THEME.Text
    tip.Font = Enum.Font.GothamBold
    tip.TextSize = 11
    tip.Visible = false
    tip.ZIndex = 10
    tip.Parent = bar
    Paint(tip, "BackgroundColor3", "Card")
    Paint(tip, "TextColor3", "Text")
    Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 6)
    do
        local p = Instance.new("UIPadding", tip)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)
    end

    ----------------------------------------------------------------------------
    -- menu do "mais": abas que nao couberam nos 7 icones
    ----------------------------------------------------------------------------
    local more = Instance.new("Frame")
    more.Name = "DockMore"
    more.AnchorPoint = Vector2.new(1, 1)
    more.Position = UDim2.new(1, -4, 0, -10)
    more.Size = UDim2.new(0, 168, 0, 0)
    more.AutomaticSize = Enum.AutomaticSize.Y
    more.BackgroundColor3 = THEME.Card
    more.BorderSizePixel = 0
    more.Visible = false
    more.ZIndex = 11
    more.Parent = bar
    Paint(more, "BackgroundColor3", "Card")
    Instance.new("UICorner", more).CornerRadius = UDim.new(0, 12)
    do
        local st = Instance.new("UIStroke", more)
        st.Transparency = 0.45
        Paint(st, "Color", "Line")
        local p = Instance.new("UIPadding", more)
        p.PaddingTop = UDim.new(0, 6)
        p.PaddingBottom = UDim.new(0, 6)
        p.PaddingLeft = UDim.new(0, 6)
        p.PaddingRight = UDim.new(0, 6)
        local l = Instance.new("UIListLayout", more)
        l.Padding = UDim.new(0, 3)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- acesso a barra para quem esta fora deste bloco (SetMinimized, shell)
    K.Bar = function() return bar end

    K.ToggleMore = function(force)
        local want = force
        if want == nil then want = not more.Visible end
        more.Visible = want and true or false
    end

    for i, tabName in ipairs(K.MoreTabs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 11
        b.Parent = more
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

        local mi = Icon(b, ({ Movement = "run", Visuals = "eye",
            Moderation = "shield", Server = "server" })[tabName] or "dot",
            THEME.Dim, 16, 1)
        mi.Position = UDim2.new(0, 8, 0.5, -8)
        mi.ZIndex = 11

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -34, 1, 0)
        t.Position = UDim2.new(0, 32, 0, 0)
        t.BackgroundTransparency = 1
        t.Text = K.MoreLabels[tabName] or tabName
        t.TextColor3 = THEME.Text
        t.Font = Enum.Font.GothamMedium
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 11
        t.Parent = b
        Paint(t, "TextColor3", "Text")

        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.15 end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
        b.MouseButton1Click:Connect(function()
            K.ToggleMore(false)
            ShowTab(tabName)
        end)

        K.ByTab[tabName] = { more = true, icon = mi, text = t }
    end

    ----------------------------------------------------------------------------
    -- os 8 botoes da barra
    ----------------------------------------------------------------------------
    for i, item in ipairs(K.Items) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 46, 0, 40)
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 8
        b.Parent = bar
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 11)

        local ico = Icon(b, item.icon or "dot", THEME.Dim, 20, 1)
        ico.AnchorPoint = Vector2.new(0.5, 0.5)
        ico.Position = UDim2.new(0.5, 0, 0.5, 0)
        ico.ZIndex = 8

        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(0.5, 1)
        pill.Position = UDim2.new(0.5, 0, 1, -3)
        pill.Size = UDim2.new(0, 0, 0, 3)
        pill.BackgroundColor3 = THEME.Accent
        pill.BorderSizePixel = 0
        pill.ZIndex = 8
        pill.Parent = b
        Paint(pill, "BackgroundColor3", "Accent")
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

        local entry = { button = b, icon = ico, pill = pill, item = item }
        K.Btns[item.id] = entry
        if item.tab then K.ByTab[item.tab] = entry end

        b.MouseEnter:Connect(function()
            tip.Text = item.label or item.id
            tip.Visible = true
            if State.ActiveTab ~= item.tab then
                TweenService:Create(b, TweenInfo.new(0.12),
                    { BackgroundTransparency = 0.2 }):Play()
                IconTint(ico, THEME.Text)
            end
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if State.ActiveTab ~= item.tab then
                TweenService:Create(b, TweenInfo.new(0.12),
                    { BackgroundTransparency = 1 }):Play()
                IconTint(ico, THEME.Dim)
            end
        end)
        b.MouseButton1Click:Connect(function()
            if item.id ~= "More" then K.ToggleMore(false) end
            if item.tab then
                ShowTab(item.tab)
            elseif item.fn then
                pcall(item.fn)
            end
        end)
    end

    ----------------------------------------------------------------------------
    -- realce da aba ativa (inclusive quando ela mora no menu "mais")
    ----------------------------------------------------------------------------
    K.Sync = function(active)
        for _, item in ipairs(K.Items) do
            local u = K.Btns[item.id]
            if u then
                local on = (item.tab ~= nil and item.tab == active)
                if item.id == "Console" and V8.Shell
                    and V8.Shell.ConsoleOpen == true then on = true end
                TweenService:Create(u.button, TweenInfo.new(0.14), {
                    BackgroundTransparency = on and 0 or 1,
                }):Play()
                TweenService:Create(u.pill, TweenInfo.new(0.16), {
                    Size = on and UDim2.new(0, 18, 0, 3) or UDim2.new(0, 0, 0, 3),
                }):Play()
                IconTint(u.icon, on and THEME.Accent or THEME.Dim)
            end
        end

        -- aba escondida no "mais": acende o botao de tres pontinhos
        local hidden = false
        for _, n in ipairs(K.MoreTabs) do
            if n == active then hidden = true end
            local m = K.ByTab[n]
            if m and m.more then
                IconTint(m.icon, n == active and THEME.Accent or THEME.Dim)
                m.text.TextColor3 = n == active and THEME.Accent or THEME.Text
            end
        end
        local dots = K.Btns.More
        if dots then
            IconTint(dots.icon, hidden and THEME.Accent or THEME.Dim)
            dots.pill.Size = hidden and UDim2.new(0, 18, 0, 3)
                or UDim2.new(0, 0, 0, 3)
        end
    end

    -- embrulha o ShowTab que ja existe (mesmo truque do ApplyTheme no persist)
    do
        local base = ShowTab
        ShowTab = function(name)
            base(name)
            pcall(K.Sync, name)
        end
    end

    ----------------------------------------------------------------------------
    -- liga / desliga: sidebar OU dock, nunca as duas
    -- a geometria do Content fica com V8.Shell quando ele existe
    ----------------------------------------------------------------------------
    K.Apply = function(on)
        SET.Dock = on and true or false
        bar.Visible = SET.Dock
        Sidebar.Visible = not SET.Dock
        if not SET.Dock then K.ToggleMore(false) end
        if V8.Shell and V8.Shell.Layout then
            pcall(V8.Shell.Layout)
        elseif SET.Dock then
            Content.Size = UDim2.new(1, -24, 1, -180)
            Content.Position = UDim2.new(0, 12, 0, 64)
        else
            Content.Size = UDim2.new(1, -184, 1, -180)
            Content.Position = UDim2.new(0, 172, 0, 64)
        end
        pcall(K.Sync, State.ActiveTab)
    end

    ----------------------------------------------------------------------------
    -- card nas Settings
    ----------------------------------------------------------------------------
    do
        local nav = CreateCard(Tabs.Settings, "NAVEGAÇÃO", 8)
        SubLabel(nav, "O dock de ícones no rodapé é o padrão da v8: 7 atalhos "
            .. "mais o botão de três pontinhos com as abas restantes. Desligue "
            .. "para voltar à sidebar de sempre — as duas dão acesso às 8 abas.", 0)

        local render = CheckRow(nav, "Usar dock de ícones",
            "Esconde a sidebar e mostra a barra de ícones no rodapé do painel",
            function() return SET.Dock == true end,
            function(v) K.Apply(v) end, 1)
        K.Render = render

        ------------------------------------------------------------------------
        -- os 3 cards de status da Home sao configuraveis
        ------------------------------------------------------------------------
        if V8.Dash and V8.Dash.SetSlots then
            SubLabel(nav, "Cards de status da Home: escreva os três toggles "
                .. "separados por espaço (padrão: fly noclip esp). Vale qualquer "
                .. "id da lista: fly, noclip, infjump, god, invisible, wall, esp, "
                .. "chatspy, fullbright, antiafk, freecam, drone.", 2)

            local box = CreateInput(nav, "fly noclip esp", 32)
            box.LayoutOrder = 3
            box.Text = table.concat(V8.Dash.Slots, " ")
            box.FocusLost:Connect(function(enter)
                if not enter then
                    box.Text = table.concat(V8.Dash.Slots, " ")
                    return
                end
                SET.Slots = V8.Dash.SetSlots(box.Text)
                box.Text = SET.Slots
            end)
            K.SlotBox = box
        end
    end

    K.Apply(SET.Dock)
end
