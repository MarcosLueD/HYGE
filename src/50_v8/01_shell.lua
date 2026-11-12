--------------------------------------------------------------------------------
-- v8.0 — SHELL (layout novo, estilo do mockup)
-- NAO recria a janela: reconfigura as instancias que o engine ja criou.
--   * janela mais larga e baixa (800x500)
--   * TopBar limpa: "Welcome home, <nome>" + selo de verificado + relogio,
--     minimizar/fechar discretos no canto
--   * dock de icones no rodape como navegacao padrao (sidebar segue no codigo)
--   * console vira painel recolhivel (o icone </> do dock abre e fecha)
-- Tudo em V8.Shell: zero locais novos no chunk principal.
-- Entra DEPOIS de 00_dock.lua e ANTES de 02_situations.lua no build.
--------------------------------------------------------------------------------
do
    V8.Shell = {}
    local H = V8.Shell

    H.W = 800           -- largura da janela
    H.Hgt = 500         -- altura da janela
    H.TopH = 62         -- altura da TopBar (usada tambem no minimizado)
    H.ConsoleH = 168    -- altura do console quando aberto
    H.ConsoleOpen = false
    H.Blue = Color3.fromRGB(0, 175, 255)   -- azul do selo de verificado

    ----------------------------------------------------------------------------
    -- 1. JANELA
    ----------------------------------------------------------------------------
    Window.Size = UDim2.new(0, H.W, 0, H.Hgt)
    Window.Position = UDim2.new(0.5, -H.W * 0.5, 0.5, -H.Hgt * 0.5)
    do
        local c = Window:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    ----------------------------------------------------------------------------
    -- 2. TOPBAR: esconde logo/titulo/versao/Stat (nao destroi — o scheduler
    --    ainda escreve em Stat.Text quando SetChips nao existe)
    ----------------------------------------------------------------------------
    TopBar.Size = UDim2.new(1, 0, 0, H.TopH)
    do
        local c = TopBar:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    for _, c in ipairs(TopBar:GetChildren()) do
        local keep = (c == CloseBtn) or (c == MinBtn) or (c.Name == "StatChips")
        -- o "topFix" (tapa o canto arredondado de baixo) tem essa medida exata
        if c:IsA("Frame") and c.Size == UDim2.new(1, 0, 0, 16) then keep = true end
        if not keep and (c:IsA("TextLabel") or c:IsA("Frame")
            or c:IsA("ImageLabel")) then
            c.Visible = false
        end
    end

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

    ---------------------------------------------------- "Welcome home, <nome>"
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

    ------------------------------------------------------------------ relogio
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

    -- chamado pelo Every(1) que ja existe em 90_runtime/04_scheduler.lua (nenhum loop novo)
    H.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
    end
    H.Tick()

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
    do
        local chips = TopBar:FindFirstChild("StatChips")
        if chips then
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
    end

    ----------------------------------------------------------------------------
    -- 3. SIDEBAR (segue existindo, so acompanha a TopBar mais alta)
    ----------------------------------------------------------------------------
    Sidebar.Size = UDim2.new(0, 164, 1, -H.TopH)
    Sidebar.Position = UDim2.new(0, 0, 0, H.TopH)

    ----------------------------------------------------------------------------
    -- 4. GEOMETRIA: uma funcao unica manda no Content e no console
    ----------------------------------------------------------------------------
    H.Layout = function()
        local dockOn = (SET.Dock == true)
        local top = H.TopH + 10
        local bottom = dockOn and 74 or 16          -- espaco reservado ao dock
        local open = (H.ConsoleOpen == true) and (not State.Minimized)
        local cons = open and (H.ConsoleH + 10) or 0
        local left = dockOn and 14 or 172
        local wOff = dockOn and -28 or -186

        ConsoleFrame.Visible = open
        ConsoleFrame.Size = UDim2.new(1, wOff, 0, H.ConsoleH)
        ConsoleFrame.Position = UDim2.new(0, left, 1, -(bottom + H.ConsoleH))

        Content.Position = UDim2.new(0, left, 0, top)
        Content.Size = UDim2.new(1, wOff, 1, -(top + bottom + cons))
    end

    H.ToggleConsole = function(force)
        local want = force
        if want == nil then want = not H.ConsoleOpen end
        H.ConsoleOpen = want and true or false
        H.Layout()
        if V8.Dock and V8.Dock.Sync then pcall(V8.Dock.Sync, State.ActiveTab) end
    end

    ----------------------------------------------------------------------------
    -- 5. ajustes no dashboard da Home: o card "Welcome home" sai (subiu pra
    --    TopBar) e o nome sob o avatar ganha o mesmo selo azul
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
    else
        H.Layout()
    end
    H.Layout()

    ----------------------------------------------------------------------------
    -- 7. paleta padrao do shell novo: azul escuro quase preto (nao roxo).
    --    Se houver config salva em disco, o BootStep "Config" roda depois e
    --    o tema salvo ganha — isto e so o padrao de quem nunca salvou.
    ----------------------------------------------------------------------------
    if ApplyTheme and PALETTES[CONFIG.DefaultTheme] then
        SET.Theme = SET.Theme or CONFIG.DefaultTheme
        pcall(ApplyTheme, SET.Theme)
    end
end
