--------------------------------------------------------------------------------
-- v8.0 — DOCK (navegação principal)
-- Barra solta no rodapé da TELA, visível mesmo com o painel fechado (é ela que
-- abre o painel; a bolinha "H" só aparece no modo sidebar). 7 seções:
--   Início · Personagem · Shop · Scripts · Jogadores · Configurações · Chat
-- O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel.
-- Navegação dentro da seção (as duas posicionadas pelo V8.Shell):
--   * sub-abas em pílula no topo da janela (Início, Personagem, Jogadores)
--   * Scripts usa uma segunda barra de ícones logo acima do dock
--     (Console, Emotes) — igual às imagens de referência
-- O título grande da janela (V8.Shell.SetTitle) acompanha a seção ativa.
-- A sidebar continua existindo: SET.Dock escolhe dock OU sidebar (Ajustes).
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS das abas (40_tabs) no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    K.BOTTOM, K.H = 14, 56      -- distância do rodapé da tela e altura do dock
    K.SUB_H, K.GAP = 50, 10     -- barra de sub-ícones (Scripts) e respiro

    -- tabs: { aba interna, nome, ícone (só usado na barra de sub-ícones) }
    K.Sections = {
        { id = "inicio",  icon = "home",     label = "Início",
          tabs = { { "Home", "Painel" }, { "Server", "Servidor" } } },
        { id = "char",    icon = "user",     label = "Personagem",
          tabs = { { "Movement", "Movimento" }, { "Visuals", "Visual" } } },
        { id = "shop",    icon = "bag",      label = "Shop",
          tabs = { { "Shop", "Shop" } } },
        { id = "scripts", icon = "terminal", label = "Scripts", subdock = true,
          tabs = { { "Scripts", "Console", "terminal" }, { "Emotes", "Emotes", "smile" } } },
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
    K.SubWasOn = false -- a barra de sub-ícones estava visível? (o shell usa)
    for _, s in ipairs(K.Sections) do
        K.ById[s.id] = s
        for _, t in ipairs(s.tabs) do K.TabSection[t[1]] = s end
    end

    local function IsOpenNow() return V8.IsOpen and V8.IsOpen() or false end

    -- moldura padrão das duas barras (dock e sub-ícones)
    local function BarFrame(name, height, radius)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 1)
        f.Size = UDim2.new(0, 0, 0, height)
        f.AutomaticSize = Enum.AutomaticSize.X
        f.BackgroundColor3 = THEME.Sidebar
        f.BackgroundTransparency = 0.02
        f.BorderSizePixel = 0
        f.Visible = false
        f.ZIndex = 20
        f.Parent = Gui
        Paint(f, "BackgroundColor3", "Sidebar")
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, radius)
        local st = Instance.new("UIStroke", f)
        st.Transparency = 0.2
        Paint(st, "Color", "Line")
        local l = Instance.new("UIListLayout", f)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.SortOrder = Enum.SortOrder.LayoutOrder
        return f, l
    end

    -- nome no hover (o ícone ativo do dock já mostra o nome ao lado)
    local function Tip(parent)
        local t = Instance.new("TextLabel")
        t.AnchorPoint = Vector2.new(0.5, 1)
        t.Position = UDim2.new(0.5, 0, 0, -8)
        t.Size = UDim2.new(0, 0, 0, 22)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundColor3 = THEME.Card
        t.Text = ""
        t.TextColor3 = THEME.Text
        t.Font = Enum.Font.GothamBold
        t.TextSize = 11
        t.Visible = false
        t.ZIndex = 22
        t.Parent = parent
        Paint(t, "BackgroundColor3", "Card")
        Paint(t, "TextColor3", "Text")
        Instance.new("UICorner", t).CornerRadius = UDim.new(0, 7)
        local p = Instance.new("UIPadding", t)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)
        return t
    end

    ----------------------------------------------------------------------------
    -- o dock (filho da ScreenGui, não da janela)
    ----------------------------------------------------------------------------
    local bar, barLayout = BarFrame("Dock", K.H, 18)
    bar.Position = UDim2.new(0.5, 0, 1, -K.BOTTOM)
    barLayout.Padding = UDim.new(0, 2)
    do
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
    end
    K.Bar = function() return bar end
    local tip = Tip(bar)

    -- os 7 botões: ícone sozinho; o ativo ganha o nome ao lado (sem fundo)
    for i, s in ipairs(K.Sections) do
        local b = Instance.new("TextButton")
        b.Name = s.id
        b.Size = UDim2.new(0, 44, 0, 44)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 20
        b.Parent = bar
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
        lbl.TextSize = 14
        lbl.Visible = false
        lbl.LayoutOrder = 2
        lbl.ZIndex = 20
        lbl.Parent = b
        Paint(lbl, "TextColor3", "Text")

        K.Btns[s.id] = { button = b, icon = ico, label = lbl }

        b.MouseEnter:Connect(function()
            if lbl.Visible then return end   -- ativo: nome já está à vista
            tip.Text = s.label
            tip.Visible = true
            IconTint(ico, THEME.Text)
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if not lbl.Visible then IconTint(ico, THEME.Dim) end
        end)
        b.MouseButton1Click:Connect(function()
            tip.Visible = false
            K.Open(s.id, true)
        end)
    end

    ----------------------------------------------------------------------------
    -- barra de sub-ícones (seção com subdock = true): uma por seção, logo
    -- acima do dock. Ativo = quadradinho claro com o ícone escuro.
    ----------------------------------------------------------------------------
    for _, s in ipairs(K.Sections) do
        if s.subdock then
            local f, l = BarFrame("SubDock_" .. s.id, K.SUB_H, 16)
            f.Position = UDim2.new(0.5, 0, 1, -(K.BOTTOM + K.H + K.GAP))
            l.Padding = UDim.new(0, 6)
            do
                local p = Instance.new("UIPadding", f)
                p.PaddingLeft = UDim.new(0, 5)
                p.PaddingRight = UDim.new(0, 5)
            end
            local subTip = Tip(f)
            s.sub, s.subBtns = f, {}

            for i, t in ipairs(s.tabs) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 40, 0, 40)
                b.BackgroundColor3 = THEME.Accent
                b.BackgroundTransparency = 1
                b.Text = ""
                b.AutoButtonColor = false
                b.LayoutOrder = i
                b.ZIndex = 20
                b.Parent = f
                Paint(b, "BackgroundColor3", "Accent")
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 11)

                local ico = Icon(b, t[3] or "dot", THEME.Dim, 20, 1)
                ico.AnchorPoint = Vector2.new(0.5, 0.5)
                ico.Position = UDim2.new(0.5, 0, 0.5, 0)
                ico.ZIndex = 21

                local u = { button = b, icon = ico, tab = t[1] }
                s.subBtns[i] = u

                b.MouseEnter:Connect(function()
                    subTip.Text = t[2]
                    subTip.Visible = true
                    if u.tab ~= State.ActiveTab then IconTint(ico, THEME.Text) end
                end)
                b.MouseLeave:Connect(function()
                    subTip.Visible = false
                    if u.tab ~= State.ActiveTab then IconTint(ico, THEME.Dim) end
                end)
                b.MouseButton1Click:Connect(function()
                    subTip.Visible = false
                    ShowTab(u.tab)
                end)
            end
        end
    end

    ----------------------------------------------------------------------------
    -- sub-abas em pílula no topo da janela (largura toda, divididas por igual)
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
        sb.Size = UDim2.new(0.5, -3, 1, 0)
        sb.BackgroundColor3 = THEME.Btn
        sb.Text = ""
        sb.TextColor3 = THEME.Text
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 12
        sb.AutoButtonColor = false
        sb.LayoutOrder = i
        sb.Visible = false
        sb.Parent = seg
        Paint(sb, "BackgroundColor3", "Btn")
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 10)
        local u = { btn = sb, tab = nil }
        segBtns[i] = u
        sb.MouseButton1Click:Connect(function()
            if u.tab then ShowTab(u.tab) end
        end)
    end

    K.SegShown = function()
        local s = K.Current
        return s ~= nil and not s.subdock and #s.tabs > 1
    end

    K.SubShown = function()
        local s = K.Current
        return s ~= nil and s.subdock == true and SET.Dock == true
            and IsOpenNow() and not State.Minimized
    end

    K.RenderSeg = function()
        local s = K.Current
        local n = K.SegShown() and #s.tabs or 0
        local gap = (n > 1) and math.ceil(6 * (n - 1) / n) or 0
        for i, u in ipairs(segBtns) do
            local t = (n > 1) and s.tabs[i]
            if t then
                local on = (t[1] == State.ActiveTab)
                u.tab = t[1]
                u.btn.Text = t[2]
                u.btn.Visible = true
                u.btn.Size = UDim2.new(1 / n, -gap, 1, 0)
                u.btn.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                u.btn.TextColor3 = on and THEME.Main or THEME.Text
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

    K.RenderSub = function()
        local subOn = false
        for _, s in ipairs(K.Sections) do
            if s.sub then
                local show = (K.Current == s) and K.SubShown()
                s.sub.Visible = show
                if show then
                    subOn = true
                    for _, u in ipairs(s.subBtns) do
                        local on = (u.tab == State.ActiveTab)
                        u.button.BackgroundTransparency = on and 0 or 1
                        IconTint(u.icon, on and THEME.Main or THEME.Dim)
                    end
                end
            end
        end
        -- a janela "em casa" sobe/desce para não cobrir a barra de sub-ícones.
        -- Só com o painel aberto: fechando, ela não "desce" enquanto some (e
        -- reabrindo na mesma seção, nada se mexe)
        if IsOpenNow() and subOn ~= K.SubWasOn then
            K.SubWasOn = subOn
            if V8.Shell and V8.Shell.Reflow then pcall(V8.Shell.Reflow) end
        end
    end

    -- título da janela: seção com sub-ícones mostra a sub-aba ("Emotes");
    -- as outras mostram o nome da seção ("Personagem")
    K.TitleFor = function(s, active)
        if not s then return tostring(active or "") end
        if s.subdock then
            for _, t in ipairs(s.tabs) do
                if t[1] == active then return t[2] end
            end
        end
        return s.label
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
            IconTint(u.icon, on and THEME.Text or THEME.Dim)
        end
        K.RenderSeg()
        K.RenderSub()
        if V8.Shell and V8.Shell.SetTitle then
            pcall(V8.Shell.SetTitle, K.TitleFor(s, active))
        end
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
    -- comandos) mantém o dock, as sub-abas e o título em dia
    do
        local base = ShowTab
        ShowTab = function(name)
            base(name)
            pcall(K.Sync, name)
        end
    end

    -- troca de tema: ícones (IconTint) e switches não ficam no registry
    -- Painted — repinta tudo que se desenha à mão
    do
        local baseTheme = ApplyTheme
        if baseTheme then
            ApplyTheme = function(name)
                local r = baseTheme(name)
                pcall(K.Sync, State.ActiveTab)
                if V8.Renders then
                    for _, render in ipairs(V8.Renders) do pcall(render) end
                end
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
        SubLabel(nav, "O dock no rodapé da tela é o padrão da v8: 7 ícones, sempre "
            .. "visível, e é ele que abre o painel. Desligue para voltar à sidebar "
            .. "dentro da janela larga (com a bolinha H para abrir).", 0)

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
