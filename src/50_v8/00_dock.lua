--------------------------------------------------------------------------------
-- v8.0 — DOCK (navegação principal)
-- Barra solta no rodapé da TELA, visível mesmo com o painel fechado (é ela que
-- abre o painel; a bolinha "H" só aparece no modo sidebar). v8.1: 8 seções:
--   Início · Personagem · Playtime Shop · Troll · Emotes · Jogadores ·
--   Configurações · Chat
-- O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel.
-- Navegação dentro da seção (as duas posicionadas pelo V8.Shell):
--   * sub-abas em pílula no topo da janela (Início, Personagem, Jogadores,
--     Configurações › Ajustes · Console, Chat › HYGE · Jogo)
--   * uma seção com subdock = true ganha uma segunda barra de ícones logo
--     acima do dock (nenhuma usa na v8.1; o mecanismo continua disponível)
-- O título grande da janela (V8.Shell.SetTitle) acompanha a seção ativa.
-- A sidebar continua existindo: SET.Dock escolhe dock OU sidebar (Ajustes).
-- v9.3: visual de vidro (V8.Hud, 30_kit/09_hud.lua), destaque animado na
-- seção ativa, balão do hover fora da fila de ícones e a alça de recolher.
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS das abas (40_tabs) no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    -- [dockgeo:begin] (tests/hud.test.js roda este bloco)
    K.BOTTOM, K.H = 14, 56      -- distância do rodapé da tela e altura do dock
    K.SUB_H, K.GAP = 50, 10     -- barra de sub-ícones (Scripts) e respiro
    -- v9.3: alça de recolher, logo acima do dock (área de clique; o desenho
    -- é menor e fica no meio dela)
    K.HANDLE_W, K.HANDLE_H, K.HANDLE_GAP = 60, 18, 1

    -- quanto do rodapé fica reservado para o dock + alça (a janela "em casa"
    -- nasce acima disso). Não muda com o dock recolhido: recolher não mexe na
    -- janela nem em nada do jogo.
    K.Reserve = function()
        return K.BOTTOM + K.H + K.HANDLE_GAP + K.HANDLE_H + 6
    end

    -- posições (offset Y a partir do rodapé, AnchorPoint embaixo) do dock e da
    -- alça. barH = altura real do dock na tela (já com a escala do celular).
    -- Recolhido: o dock inteiro fica ABAIXO da tela (nunca meio visível) e a
    -- alça desce para perto do rodapé.
    K.Targets = function(hidden, barH)
        barH = (type(barH) == "number" and barH > 0) and barH or K.H
        if hidden then
            return { bar = math.ceil(barH) + 8, handle = -6 }
        end
        return { bar = -K.BOTTOM, handle = -(K.BOTTOM + math.ceil(barH) + K.HANDLE_GAP) }
    end
    -- [dockgeo:end]

    local U = V8.Hud
    local C = U and U.C

    -- tabs: { aba interna, nome, ícone (só usado na barra de sub-ícones) }
    K.Sections = {
        { id = "inicio",  icon = "home",     label = "Início",
          tabs = { { "Home", "Painel" }, { "Server", "Servidor" } } },
        { id = "char",    icon = "user",     label = "Personagem",
          tabs = { { "Movement", "Movimento" }, { "Visuals", "Visual" } } },
        { id = "shop",    icon = "bag",      label = "Playtime Shop",
          tabs = { { "Shop", "Shop" } } },
        { id = "troll",   icon = "mask",     label = "Troll",
          tabs = { { "Troll", "Troll" } } },
        { id = "emotes",  icon = "smile",    label = "Emotes",
          tabs = { { "Emotes", "Emotes" } } },
        { id = "players", icon = "users",    label = "Jogadores",
          tabs = { { "Players", "Lista" }, { "Moderation", "Moderação" } } },
        { id = "config",  icon = "gear",     label = "Configurações",
          tabs = { { "Settings", "Ajustes" }, { "Scripts", "Console" } } },
        { id = "chat",    icon = "chat",     label = "Chat",
          tabs = { { "HyChat", "HYGE" }, { "Chat", "Jogo" } } },
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

    -- cores do HUD (V8.Hud); sem o módulo de estilo, as do tema, como antes
    local function Col(hudKey, themeKey)
        return (C and C[hudKey]) or THEME[themeKey]
    end

    -- moldura padrão das duas barras (dock e sub-ícones). v9.3: vidro escuro
    -- azulado com borda neon (V8.Hud.Glass); fixo, não segue o tema
    local function BarFrame(name, height, radius)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 1)
        f.Size = UDim2.new(0, 0, 0, height)
        f.AutomaticSize = Enum.AutomaticSize.X
        f.BorderSizePixel = 0
        f.Visible = false
        f.ZIndex = 20
        f.Parent = Gui
        if U then
            U.Glass(f, radius)
        else
            f.BackgroundColor3 = THEME.Sidebar
            f.BackgroundTransparency = 0.02
            Paint(f, "BackgroundColor3", "Sidebar")
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, radius)
            local st = Instance.new("UIStroke", f)
            st.Transparency = 0.2
            Paint(st, "Color", "Line")
        end
        local l = Instance.new("UIListLayout", f)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.SortOrder = Enum.SortOrder.LayoutOrder
        return f, l
    end

    -- nome no hover (o ícone ativo do dock já mostra o nome ao lado).
    -- v9.3: o balão mora na tela (Gui), não dentro da barra: a barra tem
    -- UIListLayout, que tratava o balão como mais um item da fila e empurrava
    -- os ícones para o lado no hover. Agora ele aparece acima do ícone.
    local function Tip()
        local t = Instance.new("TextLabel")
        t.Name = "DockTip"
        t.AnchorPoint = Vector2.new(0.5, 1)
        t.Size = UDim2.new(0, 0, 0, 24)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Text = ""
        t.Font = Enum.Font.GothamBold
        t.TextSize = 11
        t.Visible = false
        t.ZIndex = 40
        t.Parent = Gui
        if U then
            U.Glass(t, 8)
            t.TextColor3 = C.Text
        else
            t.BackgroundColor3 = THEME.Card
            t.TextColor3 = THEME.Text
            Paint(t, "BackgroundColor3", "Card")
            Paint(t, "TextColor3", "Text")
            Instance.new("UICorner", t).CornerRadius = UDim.new(0, 7)
        end
        local p = Instance.new("UIPadding", t)
        p.PaddingLeft = UDim.new(0, 9)
        p.PaddingRight = UDim.new(0, 9)
        return t
    end

    -- mostra o balão acima de um botão (posição real na tela, já com a escala)
    local function ShowTip(t, text, over, barFrame)
        t.Text = text
        local x = over.AbsolutePosition.X + over.AbsoluteSize.X * 0.5
        local y = barFrame.AbsolutePosition.Y - 8
        t.Position = UDim2.new(0, math.floor(x + 0.5), 0, math.floor(y))
        t.Visible = true
    end

    ----------------------------------------------------------------------------
    -- o dock (filho da ScreenGui, não da janela)
    ----------------------------------------------------------------------------
    local bar, barLayout = BarFrame("Dock", K.H, 20)
    bar.Position = UDim2.new(0.5, 0, 1, -K.BOTTOM)
    barLayout.Padding = UDim.new(0, 4)
    do
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
    end
    K.Bar = function() return bar end
    local tip = Tip()

    -- os 8 botões: ícone sozinho; o ativo ganha o nome ao lado e um destaque
    -- (fundo neon translúcido + borda) que entra/sai com um fade curto
    for i, s in ipairs(K.Sections) do
        local b = Instance.new("TextButton")
        b.Name = s.id
        b.Size = UDim2.new(0, 44, 0, 44)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = Col("Neon", "Accent")
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 20
        b.Parent = bar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 14)
        local ring = Instance.new("UIStroke", b)
        ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ring.Color = Col("Neon", "Accent")
        ring.Thickness = 1
        ring.Transparency = 1
        do
            local p = Instance.new("UIPadding", b)
            p.PaddingLeft = UDim.new(0, 12)
            p.PaddingRight = UDim.new(0, 12)
            local l = Instance.new("UIListLayout", b)
            l.FillDirection = Enum.FillDirection.Horizontal
            l.HorizontalAlignment = Enum.HorizontalAlignment.Center
            l.VerticalAlignment = Enum.VerticalAlignment.Center
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local ico = Icon(b, s.icon, Col("IconDim", "Dim"), 20, 1)
        ico.ZIndex = 20

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 0, 0, 20)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text = s.label
        lbl.TextColor3 = Col("Text", "Text")
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Visible = false
        lbl.LayoutOrder = 2
        lbl.ZIndex = 20
        lbl.Parent = b
        if not U then Paint(lbl, "TextColor3", "Text") end

        local u = { button = b, icon = ico, label = lbl, ring = ring, on = false }
        K.Btns[s.id] = u

        b.MouseEnter:Connect(function()
            if u.on then return end          -- ativo: nome já está à vista
            ShowTip(tip, s.label, b, bar)
            IconTint(ico, Col("Icon", "Text"))
            if U then U.Tween(b, 0.12, { BackgroundTransparency = 0.93 }) end
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if u.on then return end
            IconTint(ico, Col("IconDim", "Dim"))
            if U then U.Tween(b, 0.12, { BackgroundTransparency = 1 }) end
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
            f.Position = UDim2.new(0.5, 0, 1, -K.Reserve())   -- acima da alça (v9.3)
            l.Padding = UDim.new(0, 6)
            do
                local p = Instance.new("UIPadding", f)
                p.PaddingLeft = UDim.new(0, 5)
                p.PaddingRight = UDim.new(0, 5)
            end
            local subTip = Tip()
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
                    ShowTip(subTip, t[2], b, f)
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
            and IsOpenNow() and not State.Minimized and not K.Hidden
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
            local was = u.on
            u.on = on
            u.label.Visible = on
            IconTint(u.icon, on and Col("Icon", "Text") or Col("IconDim", "Dim"))
            -- v9.3: destaque da seção ativa. Só mexe quando muda: o Sync roda
            -- várias vezes seguidas (ShowTab + SetOpen no mesmo clique) e
            -- repintar no meio cortaria a animação
            if U and on ~= was then
                U.Tween(u.button, 0.18, { BackgroundTransparency = on and 0.82 or 1 })
                U.Tween(u.ring, 0.18, { Transparency = on and 0.45 or 1 })
                if on then
                    u.label.TextTransparency = 1
                    U.Tween(u.label, 0.22, { TextTransparency = 0 })
                end
            end
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
    -- v9.3: ALÇA DE RECOLHER O DOCK (três traços, centralizada logo acima dele)
    -- Clique: o dock desliza para baixo até sair inteiro da tela e só então
    -- some (nunca fica meio visível); a alça desce para o rodapé e continua lá
    -- para trazer o dock de volta. O estado vai para a config (SET.DockHidden).
    -- Recolher não fecha o painel nem mexe na janela ou em nada do jogo.
    ----------------------------------------------------------------------------
    local handle = Instance.new("TextButton")   -- área de clique (maior que o desenho)
    handle.Name = "DockHandle"
    handle.AnchorPoint = Vector2.new(0.5, 1)
    handle.Size = UDim2.new(0, K.HANDLE_W, 0, K.HANDLE_H)
    handle.BackgroundTransparency = 1
    handle.Text = ""
    handle.AutoButtonColor = false
    handle.Visible = false
    handle.ZIndex = 21
    handle.Parent = Gui
    K.Handle = function() return handle end

    local grip = Instance.new("Frame")
    grip.Name = "Grip"
    grip.AnchorPoint = Vector2.new(0.5, 0.5)
    grip.Position = UDim2.new(0.5, 0, 0.5, 0)
    grip.Size = UDim2.new(0, 42, 0, 14)
    grip.Active = false
    grip.ZIndex = 21
    grip.Parent = handle
    local gripStroke
    if U then
        gripStroke = U.Glass(grip, 7)
    else
        grip.BackgroundColor3 = THEME.Sidebar
        Paint(grip, "BackgroundColor3", "Sidebar")
        Instance.new("UICorner", grip).CornerRadius = UDim.new(0, 7)
    end
    local gripScale = Instance.new("UIScale", grip)
    local lines = {}
    do
        local l = Instance.new("UIListLayout", grip)
        l.FillDirection = Enum.FillDirection.Vertical
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 2)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        for i = 1, 3 do
            local ln = Instance.new("Frame")
            ln.Size = UDim2.new(0, 16, 0, 2)
            ln.BackgroundColor3 = Col("IconDim", "Dim")
            ln.BorderSizePixel = 0
            ln.LayoutOrder = i
            ln.ZIndex = 22
            ln.Parent = grip
            Instance.new("UICorner", ln).CornerRadius = UDim.new(1, 0)
            lines[i] = ln
        end
    end

    -- feedback: passar o mouse acende os traços em neon; apertar encolhe um pouco
    local hover, press = false, false
    local function GripLook()
        local lit = hover or press
        local c = lit and Col("Neon", "Accent") or Col("IconDim", "Dim")
        for _, ln in ipairs(lines) do
            if U then U.Tween(ln, 0.12, { BackgroundColor3 = c }) else ln.BackgroundColor3 = c end
        end
        if U then
            U.Tween(grip, 0.12, { BackgroundTransparency = lit and 0.08 or C.GlassT })
            if gripStroke then U.Tween(gripStroke, 0.12, { Transparency = lit and 0.2 or 0.55 }) end
            U.Tween(gripScale, 0.1, { Scale = press and 0.88 or (hover and 1.06 or 1) })
        end
    end
    handle.MouseEnter:Connect(function() hover = true GripLook() end)
    handle.MouseLeave:Connect(function() hover, press = false, false GripLook() end)
    handle.MouseButton1Down:Connect(function() press = true GripLook() end)
    handle.MouseButton1Up:Connect(function() press = false GripLook() end)

    -- o HUD do spectate também fica no centro do rodapé: acima do dock + alça
    -- (ou só da alça, com o dock recolhido)
    local function SpecPos()
        if not SpectateHud then return end
        local y = -24
        if SET.Dock == true then
            y = K.Hidden and -(6 + K.HANDLE_H + 8) or -(K.Reserve() + 2)
        end
        SpectateHud.Position = UDim2.new(0.5, 0, 1, y)
    end

    K.Hidden = SET.DockHidden == true
    local moveSeq = 0
    -- recolhe (true) / mostra (false). animate = false: na hora (boot, config
    -- carregada, troca de modo)
    K.SetHidden = function(on, animate)
        on = on == true
        K.Hidden = on
        SET.DockHidden = on
        moveSeq = moveSeq + 1
        local seq = moveSeq
        tip.Visible = false
        local dockOn = SET.Dock == true
        handle.Visible = dockOn
        if not dockOn then
            bar.Visible = false
        else
            local h = bar.AbsoluteSize.Y
            local t = K.Targets(on, h > 0 and h or nil)
            local barPos = UDim2.new(0.5, 0, 1, t.bar)
            local handlePos = UDim2.new(0.5, 0, 1, t.handle)
            if animate and SET.Animations then
                bar.Visible = true   -- subindo: entra de baixo, já fora da tela
                local info = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                local tw = TweenService:Create(bar, info, { Position = barPos })
                tw.Completed:Connect(function()
                    -- só o último pedido vale: dois cliques rápidos não deixam o
                    -- dock escondido no meio do caminho
                    if seq == moveSeq and K.Hidden then bar.Visible = false end
                end)
                tw:Play()
                TweenService:Create(handle, info, { Position = handlePos }):Play()
            else
                bar.Position = barPos
                handle.Position = handlePos
                bar.Visible = not on
            end
        end
        SpecPos()
        pcall(K.RenderSub)
    end

    handle.MouseButton1Click:Connect(function()
        press = false
        if not UserInputService.MouseEnabled then hover = false end   -- toque: sem "hover"
        GripLook()
        K.SetHidden(not K.Hidden, true)
    end)

    -- a altura real do dock muda com a escala do celular: a alça acompanha
    bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if K.Hidden or SET.Dock ~= true then return end
        handle.Position = UDim2.new(0.5, 0, 1, K.Targets(false, bar.AbsoluteSize.Y).handle)
    end)

    ----------------------------------------------------------------------------
    -- liga / desliga: dock OU sidebar (+ bolinha "H"), nunca os dois
    ----------------------------------------------------------------------------
    K.Apply = function(on)
        SET.Dock = on and true or false
        Sidebar.Visible = (not SET.Dock) and not State.Minimized
        if V8.Orb then V8.Orb.Visible = (not SET.Dock) and not IsOpenNow() end
        -- v9.3: dock + alça + HUD do spectate, respeitando o recolhido salvo
        K.SetHidden(SET.DockHidden == true, false)
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
            .. "dentro da janela larga (com a bolinha H para abrir). A alça de três "
            .. "traços logo acima do dock recolhe e traz o dock de volta.", 0)

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
                .. "chatspy, fullbright, antiafk, freecam, drone, antifall, antigrav, "
                .. "wallwalk.", 2)

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
