--------------------------------------------------------------------------------
-- v8.0 — DOCK (navegação principal)
-- Barra solta no rodapé da TELA, visível mesmo com o painel fechado (é ela que
-- abre o painel; a bolinha "H" só aparece no modo sidebar). 8 seções:
--   Início · Personagem · Shop · Scripts · Emotes · Jogadores · Configurações · Chat
-- O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel.
-- Seção com mais de uma aba ganha sub-abas no topo da janela
-- (ex.: Personagem › Movimento | Visual) — posicionadas pelo V8.Shell.Layout.
-- A sidebar continua existindo: SET.Dock escolhe dock OU sidebar (Ajustes).
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS das abas (40_tabs) no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    -- { aba interna, nome na sub-aba }
    K.Sections = {
        { id = "inicio",  icon = "home",     label = "Início",
          tabs = { { "Home", "Painel" }, { "Server", "Servidor" } } },
        { id = "char",    icon = "user",     label = "Personagem",
          tabs = { { "Movement", "Movimento" }, { "Visuals", "Visual" } } },
        { id = "shop",    icon = "bag",      label = "Shop",
          tabs = { { "Shop", "Shop" } } },
        { id = "scripts", icon = "terminal", label = "Scripts",
          tabs = { { "Scripts", "Console" } } },
        { id = "emotes",  icon = "grid",     label = "Emotes",
          tabs = { { "Emotes", "Emotes" } } },
        { id = "players", icon = "users",    label = "Jogadores",
          tabs = { { "Players", "Lista" }, { "Moderation", "Moderação" } } },
        { id = "config",  icon = "gear",     label = "Configurações",
          tabs = { { "Settings", "Configurações" } } },
        { id = "chat",    icon = "chat",     label = "Chat",
          tabs = { { "Chat", "Chat" } } },
    }

    K.ById = {}        -- id -> seção
    K.TabSection = {}  -- aba interna -> seção
    K.LastTab = {}     -- id -> última sub-aba usada (volta nela ao reabrir)
    K.Btns = {}        -- id -> { button, icon, label }
    K.Current = nil    -- seção da aba ativa
    for _, s in ipairs(K.Sections) do
        K.ById[s.id] = s
        for _, t in ipairs(s.tabs) do K.TabSection[t[1]] = s end
    end

    local function IsOpenNow() return V8.IsOpen and V8.IsOpen() or false end

    ----------------------------------------------------------------------------
    -- a barra (filha da ScreenGui, não da janela)
    ----------------------------------------------------------------------------
    local bar = Instance.new("Frame")
    bar.Name = "Dock"
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.Position = UDim2.new(0.5, 0, 1, -14)
    bar.Size = UDim2.new(0, 0, 0, 56)
    bar.AutomaticSize = Enum.AutomaticSize.X
    bar.BackgroundColor3 = THEME.Sidebar
    bar.BackgroundTransparency = 0.04
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.ZIndex = 20
    bar.Parent = Gui
    Paint(bar, "BackgroundColor3", "Sidebar")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 18)
    do
        local st = Instance.new("UIStroke", bar)
        st.Transparency = 0.5
        Paint(st, "Color", "Line")
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        local l = Instance.new("UIListLayout", bar)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.VerticalAlignment = Enum.VerticalAlignment.Center
    end
    K.Bar = function() return bar end

    -- nome do ícone no hover (o ativo já mostra o nome ao lado)
    local tip = Instance.new("TextLabel")
    tip.AnchorPoint = Vector2.new(0.5, 1)
    tip.Position = UDim2.new(0.5, 0, 0, -8)
    tip.Size = UDim2.new(0, 0, 0, 22)
    tip.AutomaticSize = Enum.AutomaticSize.X
    tip.BackgroundColor3 = THEME.Card
    tip.Text = ""
    tip.TextColor3 = THEME.Text
    tip.Font = Enum.Font.GothamBold
    tip.TextSize = 11
    tip.Visible = false
    tip.ZIndex = 22
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
    -- os 8 botões: ícone sozinho; o ativo ganha fundo + nome ao lado
    ----------------------------------------------------------------------------
    for i, s in ipairs(K.Sections) do
        local b = Instance.new("TextButton")
        b.Name = s.id
        b.Size = UDim2.new(0, 44, 0, 42)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 20
        b.Parent = bar
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 13)
        do
            local p = Instance.new("UIPadding", b)
            p.PaddingLeft = UDim.new(0, 12)
            p.PaddingRight = UDim.new(0, 12)
            local l = Instance.new("UIListLayout", b)
            l.FillDirection = Enum.FillDirection.Horizontal
            l.VerticalAlignment = Enum.VerticalAlignment.Center
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local ico = Icon(b, s.icon, THEME.Dim, 20, 1)
        ico.ZIndex = 20

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 0, 0, 20)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text = s.label
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Visible = false
        lbl.LayoutOrder = 2
        lbl.ZIndex = 20
        lbl.Parent = b
        Paint(lbl, "TextColor3", "Text")

        local entry = { button = b, icon = ico, label = lbl }
        K.Btns[s.id] = entry

        b.MouseEnter:Connect(function()
            if lbl.Visible then return end   -- ativo: nome já está à vista
            tip.Text = s.label
            tip.Visible = true
            b.BackgroundTransparency = 0.55
            IconTint(ico, THEME.Text)
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if lbl.Visible then return end
            b.BackgroundTransparency = 1
            IconTint(ico, THEME.Dim)
        end)
        b.MouseButton1Click:Connect(function()
            tip.Visible = false
            K.Open(s.id, true)
        end)
    end

    ----------------------------------------------------------------------------
    -- sub-abas no topo da janela (só para seção com mais de uma aba)
    ----------------------------------------------------------------------------
    local seg = Instance.new("Frame")
    seg.Name = "SubTabs"
    seg.BackgroundTransparency = 1
    seg.Visible = false
    seg.Parent = Window
    do
        local l = Instance.new("UIListLayout", seg)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    K.Seg = seg

    local segBtns = {}
    for i = 1, 4 do
        local sb = Instance.new("TextButton")
        sb.Size = UDim2.new(0, 0, 1, 0)
        sb.AutomaticSize = Enum.AutomaticSize.X
        sb.BackgroundColor3 = THEME.Btn
        sb.BackgroundTransparency = 1
        sb.Text = ""
        sb.TextColor3 = THEME.Dim
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 12
        sb.AutoButtonColor = false
        sb.LayoutOrder = i
        sb.Visible = false
        sb.Parent = seg
        Paint(sb, "BackgroundColor3", "Btn")
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 9)
        do
            local p = Instance.new("UIPadding", sb)
            p.PaddingLeft = UDim.new(0, 16)
            p.PaddingRight = UDim.new(0, 16)
        end
        local u = { btn = sb, tab = nil }
        segBtns[i] = u
        sb.MouseButton1Click:Connect(function()
            if u.tab then ShowTab(u.tab) end
        end)
    end

    K.SegShown = function()
        return K.Current ~= nil and #K.Current.tabs > 1
    end

    K.RenderSeg = function()
        local s = K.Current
        for i, u in ipairs(segBtns) do
            local t = s and #s.tabs > 1 and s.tabs[i]
            if t then
                local on = (t[1] == State.ActiveTab)
                u.tab = t[1]
                u.btn.Text = t[2]
                u.btn.Visible = true
                u.btn.BackgroundTransparency = on and 0 or 1
                u.btn.TextColor3 = on and THEME.Accent or THEME.Dim
            else
                u.tab = nil
                u.btn.Visible = false
            end
        end
        -- mostrar/esconder a faixa muda a altura do Content: o shell recalcula
        local want = (SET.Dock == true) and K.SegShown() and not State.Minimized
        if want ~= seg.Visible and V8.Shell and V8.Shell.Layout then
            pcall(V8.Shell.Layout)
        end
    end

    ----------------------------------------------------------------------------
    -- realce: só com o painel aberto (fechado, nenhum ícone fica aceso)
    ----------------------------------------------------------------------------
    K.Sync = function(active)
        active = active or State.ActiveTab
        local s = K.TabSection[active]
        K.Current = s
        if s then K.LastTab[s.id] = active end
        local open = IsOpenNow()
        for id, u in pairs(K.Btns) do
            local on = open and s ~= nil and s.id == id
            u.label.Visible = on
            u.button.BackgroundTransparency = on and 0 or 1
            IconTint(u.icon, on and THEME.Accent or THEME.Dim)
        end
        K.RenderSeg()
    end

    -- abre a seção (na última sub-aba usada). toggle = clique no dock:
    -- clicar na seção que já está aberta fecha o painel
    K.Open = function(id, toggle)
        local s = K.ById[id]
        if not s then return end
        local open = IsOpenNow()
        if toggle and open and K.Current == s then
            if V8.SetOpen then V8.SetOpen(false) end
            return
        end
        ShowTab(K.LastTab[id] or s.tabs[1][1])
        if not open and V8.SetOpen then V8.SetOpen(true) end
    end

    -- embrulha o ShowTab que já existe: qualquer caminho (busca, situações,
    -- comandos) mantém o dock e as sub-abas em dia
    do
        local base = ShowTab
        ShowTab = function(name)
            base(name)
            pcall(K.Sync, name)
        end
    end

    -- troca de tema: os ícones do dock são pintados à mão (IconTint)
    do
        local baseTheme = ApplyTheme
        if baseTheme then
            ApplyTheme = function(name)
                local r = baseTheme(name)
                pcall(K.Sync, State.ActiveTab)
                return r
            end
        end
    end

    ----------------------------------------------------------------------------
    -- liga / desliga: dock OU sidebar (+ bolinha "H"), nunca os dois
    ----------------------------------------------------------------------------
    K.Apply = function(on)
        SET.Dock = on and true or false
        bar.Visible = SET.Dock
        Sidebar.Visible = (not SET.Dock) and not State.Minimized
        if V8.Orb then V8.Orb.Visible = (not SET.Dock) and not IsOpenNow() end
        -- o HUD do spectate também fica no centro do rodapé: sobe acima do dock
        if SpectateHud then
            SpectateHud.Position = UDim2.new(0.5, 0, 1, SET.Dock and -84 or -24)
        end
        if V8.Shell and V8.Shell.Layout then pcall(V8.Shell.Layout) end
        pcall(K.Sync, State.ActiveTab)
    end

    ----------------------------------------------------------------------------
    -- card nas Settings
    ----------------------------------------------------------------------------
    do
        local nav = CreateCard(Tabs.Settings, "NAVEGAÇÃO", 8)
        SubLabel(nav, "O dock no rodapé da tela é o padrão da v8: 8 ícones, sempre "
            .. "visível, e é ele que abre o painel. Desligue para voltar à sidebar "
            .. "dentro da janela (com a bolinha H para abrir).", 0)

        local render = CheckRow(nav, "Usar dock de ícones",
            "Desligado: sidebar dentro da janela + bolinha H",
            function() return SET.Dock == true end,
            function(v) K.Apply(v) end, 1)
        K.Render = render

        ------------------------------------------------------------------------
        -- os 3 cards de status da Home são configuráveis
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
