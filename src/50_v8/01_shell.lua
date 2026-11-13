--------------------------------------------------------------------------------
-- v8.0 — SHELL (layout novo)
-- NAO recria a janela: reconfigura as instancias que o engine ja criou.
-- Dois modos, escolhidos por SET.Dock (Ajustes › Navegação):
--   * DOCK (padrao): janela "em pe" de 460x520, estilo cartao — titulo grande
--     da secao a esquerda e o selo "HYGE" a direita. Sem fechar/minimizar: o
--     dock (clicar de novo no icone ativo) e a tecla do painel fecham. A janela
--     nasce logo acima do dock (e sobe quando a barra de sub-icones aparece).
--   * SIDEBAR: janela larga de 800x500 com "Welcome home", relogio, chips de
--     FPS/ping e os botoes de fechar/minimizar.
-- Tudo em V8.Shell: zero locais novos no chunk principal.
-- Entra DEPOIS de 00_dock.lua e ANTES de 02_situations.lua no build.
--------------------------------------------------------------------------------
do
    V8.Shell = {}
    local H = V8.Shell

    H.DockW, H.DockH, H.DockTop = 460, 520, 54   -- modo dock
    H.SideW, H.SideH, H.SideTop = 800, 500, 62   -- modo sidebar
    H.W, H.Hgt, H.TopH = H.DockW, H.DockH, H.DockTop
    H.ConsoleH = 168    -- compat: o console mora na aba Scripts
    H.ConsoleOpen = false
    H.Blue = Color3.fromRGB(0, 175, 255)   -- azul do selo de verificado
    H.SideBits = {}     -- pecas do cabecalho que so existem no modo sidebar

    H.IsDock = function() return SET.Dock ~= false end

    ----------------------------------------------------------------------------
    -- 1. TOPBAR: esconde logo/titulo/versao/Stat do motor antigo (nao destroi —
    --    o scheduler ainda escreve em Stat.Text quando SetChips nao existe)
    ----------------------------------------------------------------------------
    for _, c in ipairs(TopBar:GetChildren()) do
        -- o "topFix" (tapa o canto arredondado de baixo) tem essa medida exata
        local isFix = c:IsA("Frame") and c.Size == UDim2.new(1, 0, 0, 16)
        if isFix then H.TopFix = c end
        if c.Name == "StatChips" then H.Chips = c end
        local keep = (c == CloseBtn) or (c == MinBtn) or (c.Name == "StatChips") or isFix
        if not keep and (c:IsA("TextLabel") or c:IsA("Frame")
            or c:IsA("ImageLabel")) then
            c.Visible = false
        end
    end
    do
        local c = TopBar:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    -- borda da janela: linha sutil (o brilho no destaque some no tema claro)
    pcall(function()
        for _, e in ipairs(Painted) do
            if e.inst == winStroke and e.prop == "Color" then e.key = "Line" end
        end
        winStroke.Color = THEME.Line
        winStroke.Transparency = 0.15
        winStroke.Thickness = 1
    end)

    -------------------------------------------------- selo azul de verificado
    -- circulo azul + serrilha (quadrado girado) + check branco
    H.Badge = function(parent, size, order)
        local b = Instance.new("Frame")
        b.Name = "Verified"
        b.Size = UDim2.new(0, size, 0, size)
        b.BackgroundColor3 = H.Blue
        b.BorderSizePixel = 0
        b.LayoutOrder = order or 2
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)

        local star = Instance.new("Frame")
        star.AnchorPoint = Vector2.new(0.5, 0.5)
        star.Position = UDim2.new(0.5, 0, 0.5, 0)
        star.Size = UDim2.new(0.78, 0, 0.78, 0)
        star.Rotation = 45
        star.BackgroundColor3 = H.Blue
        star.BorderSizePixel = 0
        star.ZIndex = 2
        star.Parent = b
        Instance.new("UICorner", star).CornerRadius =
            UDim.new(0, math.max(2, math.floor(size * 0.14)))

        local ck = Icon(b, "check", Color3.new(1, 1, 1),
            math.max(8, math.floor(size * 0.64)), 1)
        ck.AnchorPoint = Vector2.new(0.5, 0.5)
        ck.Position = UDim2.new(0.5, 0, 0.5, 0)
        ck.ZIndex = 3
        return b
    end

    ----------------------------------------------------------------------------
    -- 2a. CABECALHO DO MODO SIDEBAR: "Welcome home, <nome>" + relogio
    ----------------------------------------------------------------------------
    local head = Instance.new("Frame")
    head.Name = "Welcome"
    head.Position = UDim2.new(0, 20, 0, 10)
    head.Size = UDim2.new(0, 0, 0, 26)
    head.AutomaticSize = Enum.AutomaticSize.X
    head.BackgroundTransparency = 1
    head.Parent = TopBar
    do
        local l = Instance.new("UIListLayout", head)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 7)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local hi = Instance.new("TextLabel")
    hi.AutomaticSize = Enum.AutomaticSize.X
    hi.Size = UDim2.new(0, 0, 0, 24)
    hi.BackgroundTransparency = 1
    hi.Text = "Welcome home, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
    hi.TextColor3 = Color3.new(1, 1, 1)    -- branco puro de proposito
    hi.Font = Enum.Font.GothamBold
    hi.TextSize = 20
    hi.TextXAlignment = Enum.TextXAlignment.Left
    hi.LayoutOrder = 1
    hi.Parent = head
    H.Badge(head, 18, 2)

    local sub = Instance.new("TextLabel")
    sub.Name = "WelcomeSub"
    sub.Position = UDim2.new(0, 21, 0, 37)
    sub.Size = UDim2.new(0, 320, 0, 14)
    sub.BackgroundTransparency = 1
    sub.Text = "HYGE " .. CONFIG.Version .. "  ·  painel pronto"
    sub.TextColor3 = THEME.Dim
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = TopBar
    Paint(sub, "TextColor3", "Dim")

    local clock = Instance.new("Frame")
    clock.Name = "Clock"
    clock.AnchorPoint = Vector2.new(1, 0.5)
    clock.Position = UDim2.new(1, -84, 0, 21)
    clock.Size = UDim2.new(0, 0, 0, 22)
    clock.AutomaticSize = Enum.AutomaticSize.X
    clock.BackgroundTransparency = 1
    clock.Parent = TopBar
    do
        local l = Instance.new("UIListLayout", clock)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    Icon(clock, "clock", THEME.Dim, 15, 1)

    local clockLbl = Instance.new("TextLabel")
    clockLbl.AutomaticSize = Enum.AutomaticSize.X
    clockLbl.Size = UDim2.new(0, 0, 0, 20)
    clockLbl.BackgroundTransparency = 1
    clockLbl.Text = "--:--"
    clockLbl.TextColor3 = THEME.Text
    clockLbl.Font = Enum.Font.GothamBold
    clockLbl.TextSize = 15
    clockLbl.LayoutOrder = 2
    clockLbl.Parent = clock
    Paint(clockLbl, "TextColor3", "Text")

    H.SideBits = { head, sub, clock }

    --------------------------------------------- minimizar / fechar discretos
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -40, 0, 8)
    CloseBtn.TextSize = 13
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -70, 0, 8)
    MinBtn.TextSize = 13
    do
        local c = CloseBtn:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 9) end
        c = MinBtn:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 9) end
        CloseBtn.BackgroundTransparency = 0.45
        MinBtn.BackgroundTransparency = 0.45
    end

    ------------------------------- chips de FPS/ping na segunda linha, a direita
    if H.Chips then
        local chips = H.Chips
        chips.AnchorPoint = Vector2.new(1, 0.5)
        chips.Position = UDim2.new(1, -16, 0, 45)
        chips.Size = UDim2.new(0, 430, 0, 20)
        local lay = chips:FindFirstChildOfClass("UIListLayout")
        if lay then lay.Padding = UDim.new(0, 14) end
        -- o chip 4 e o nome do jogo (texto longo): sai da barra limpa,
        -- a informacao continua na aba Servidor
        for _, c in ipairs(chips:GetChildren()) do
            if c:IsA("Frame") and c.LayoutOrder == 4 then c.Visible = false end
        end
    end

    ----------------------------------------------------------------------------
    -- 2b. CABECALHO DO MODO DOCK: titulo grande da secao + selo "HYGE"
    ----------------------------------------------------------------------------
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Position = UDim2.new(0, 20, 0, 4)
    title.Size = UDim2.new(1, -120, 1, -4)
    title.BackgroundTransparency = 1
    title.Text = "Início"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = TopBar
    Paint(title, "TextColor3", "Text")
    H.TitleLbl = title

    local pill = Instance.new("TextLabel")
    pill.Name = "Brand"
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -16, 0.5, 2)
    pill.Size = UDim2.new(0, 0, 0, 24)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = THEME.Text
    pill.Text = "HYGE"
    pill.TextColor3 = THEME.Main
    pill.Font = Enum.Font.GothamBold
    pill.TextSize = 12
    pill.Parent = TopBar
    Paint(pill, "BackgroundColor3", "Text")
    Paint(pill, "TextColor3", "Main")
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    do
        local p = Instance.new("UIPadding", pill)
        p.PaddingLeft = UDim.new(0, 12)
        p.PaddingRight = UDim.new(0, 12)
    end
    H.Pill = pill

    -- "Jogadores" ganha a contagem ao lado, como na referencia ("Players 70")
    H.TitleBase = "Início"
    H.TitleText = function()
        local t = H.TitleBase or ""
        if V8.Dock and V8.Dock.Current and V8.Dock.Current.id == "players" then
            t = t .. "   " .. #Players:GetPlayers()
        end
        return t
    end
    H.SetTitle = function(text)
        H.TitleBase = tostring(text or "")
        title.Text = H.TitleText()
    end

    -- chamado pelo Every(1) que ja existe em 90_runtime/04_scheduler.lua
    -- (nenhum loop novo): relogio do modo sidebar + contagem de jogadores
    H.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
        pcall(function() title.Text = H.TitleText() end)
    end
    H.Tick()

    ----------------------------------------------------------------------------
    -- 3. POSICAO "DE CASA"
    --    dock: centralizada logo acima do dock (ou da barra de sub-icones)
    --    sidebar: no meio da tela. Usada tambem por 'center'.
    ----------------------------------------------------------------------------
    H.HomePos = function()
        local sc = CONFIG.UiScale or 1
        if H.IsDock() then
            local vh = Gui.AbsoluteSize.Y
            if vh < 100 then vh = Camera.ViewportSize.Y end
            local gap = 82                                  -- dock + respiro
            if V8.Dock and V8.Dock.SubWasOn then gap = gap + 60 end
            return UDim2.new(0.5, -H.W * sc * 0.5, 0,
                math.max(8, math.floor(vh - H.Hgt * sc - gap)))
        end
        return UDim2.new(0.5, -H.W * sc * 0.5, 0.5, -H.Hgt * sc * 0.5)
    end

    -- volta para casa (com animacao) — so se o usuario nunca arrastou a janela
    H.Reflow = function()
        if SET.WinPos ~= nil then return end
        Anim(Window, 0.2, { Position = H.HomePos() })
    end

    -- resolucao mudou: a janela "em casa" acompanha
    Conn.ShellFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if SET.WinPos == nil then pcall(function() Window.Position = H.HomePos() end) end
    end)

    ----------------------------------------------------------------------------
    -- 4. MODO (tamanho da janela + cabecalho) e GEOMETRIA do Content
    ----------------------------------------------------------------------------
    H.ApplyMode = function()
        local dock = H.IsDock()
        H.W = dock and H.DockW or H.SideW
        H.Hgt = dock and H.DockH or H.SideH
        H.TopH = dock and H.DockTop or H.SideTop

        -- no dock nao existe botao de restaurar: nunca fica minimizado
        if dock and State.Minimized then
            State.Minimized = false
            Content.Visible = true
            MinBtn.Text = "—"
        end

        TopBar.Size = UDim2.new(1, 0, 0, H.TopH)
        TopBar.BackgroundTransparency = dock and 1 or 0
        if H.TopFix then H.TopFix.Visible = not dock end
        for _, o in ipairs(H.SideBits) do o.Visible = not dock end
        if H.Chips then H.Chips.Visible = not dock end
        CloseBtn.Visible = not dock
        MinBtn.Visible = not dock
        title.Visible = dock
        pill.Visible = dock

        Sidebar.Size = UDim2.new(0, 164, 1, -H.TopH)
        Sidebar.Position = UDim2.new(0, 0, 0, H.TopH)

        local c = Window:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, dock and 22 or 18) end
        Window.Size = UDim2.new(0, H.W, 0, State.Minimized and H.TopH or H.Hgt)

        if H.LastMode ~= dock then
            H.LastMode = dock
            if SET.WinPos == nil then Window.Position = H.HomePos() end
        end
    end

    -- uma funcao unica manda na janela, no Content e nas sub-abas.
    -- O dock mora fora da janela: nada e reservado no rodape.
    H.Layout = function()
        H.ApplyMode()
        local dockOn = H.IsDock()
        local left = dockOn and 14 or 172
        local wOff = dockOn and -28 or -186
        local top = dockOn and H.TopH or (H.TopH + 10)
        local bottom = 14

        -- sub-abas em pilula da secao ativa (ex.: Personagem › Movimento | Visual)
        local seg = V8.Dock and V8.Dock.Seg
        if seg then
            local show = dockOn and V8.Dock.SegShown() and not State.Minimized
            seg.Visible = show
            seg.Position = UDim2.new(0, left, 0, top)
            seg.Size = UDim2.new(1, wOff, 0, 32)
            if show then top = top + 42 end
        end

        Content.Position = UDim2.new(0, left, 0, top)
        Content.Size = UDim2.new(1, wOff, 1, -(top + bottom))
    end

    -- compatibilidade: quem pedia "abrir o console" agora abre a aba Scripts
    H.ToggleConsole = function()
        if V8.Dock and V8.Dock.Open then V8.Dock.Open("scripts", true) end
    end

    ----------------------------------------------------------------------------
    -- 5. ajustes no dashboard da Home: o card "Welcome home" sai e o nome sob
    --    o avatar ganha o selo azul
    ----------------------------------------------------------------------------
    if V8.Dash then
        if V8.Dash.Head then V8.Dash.Head.Visible = false end
        if V8.Dash.NameRow then H.Badge(V8.Dash.NameRow, 15, 2) end
    end

    ----------------------------------------------------------------------------
    -- 6. dock como padrao (a sidebar continua a um clique nas Settings)
    ----------------------------------------------------------------------------
    if SET.Dock == nil then SET.Dock = true end
    if V8.Dock and V8.Dock.Apply then
        pcall(V8.Dock.Apply, SET.Dock == true)
    end
    H.Layout()
    if SET.WinPos == nil then Window.Position = H.HomePos() end

    ----------------------------------------------------------------------------
    -- 7. paleta padrao (CONFIG.DefaultTheme = Grafite). Se houver config salva
    --    em disco, o BootStep "Config" roda depois e o tema salvo ganha.
    ----------------------------------------------------------------------------
    if ApplyTheme and PALETTES[CONFIG.DefaultTheme] then
        SET.Theme = SET.Theme or CONFIG.DefaultTheme
        pcall(ApplyTheme, SET.Theme)
    end
end
