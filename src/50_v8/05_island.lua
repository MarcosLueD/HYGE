--------------------------------------------------------------------------------
-- v8.0 — ILHA NO TOPO DA TELA
-- Pílula fixa no alto, centralizada: logo, hora, FPS e ping — à vista mesmo
-- com o painel fechado. Clicar abre/fecha o painel.
-- Sem loop próprio: o Every(0.5) do scheduler já chama SetChips(fps, ping, ...)
-- e a ilha pega carona nele. Some durante o drone (a bússola do HUD fica ali).
-- Ajustes › Ilha no topo liga/desliga (vai junto na config em disco).
-- v9.3: pílula de vidro com borda e brilho neon (V8.Hud), separadores entre
-- os blocos, ping + barrinhas de qualidade da conexão e a moldura atrás da
-- barra do Roblox (canto superior esquerdo).
-- Tudo em V8.Island: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    V8.Island = {}
    local I = V8.Island
    if SET.Island == nil then SET.Island = true end
    if SET.TopbarFrame == nil then SET.TopbarFrame = true end

    local U = V8.Hud
    local C = U and U.C

    local pill = Instance.new("TextButton")
    pill.Name = "Island"
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 8)
    pill.Size = UDim2.new(0, 0, 0, 36)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Visible = SET.Island ~= false
    pill.ZIndex = 20
    pill.Parent = Gui
    I.Pill = pill   -- v9.0: o sino das notificações mora aqui (50_v8/11_notify.lua)
    local stroke, halo
    if U then
        stroke = U.Glass(pill, U.PILL)
        halo = U.Halo(pill)
    else
        pill.BackgroundColor3 = THEME.Sidebar
        pill.BackgroundTransparency = 0.02
        Paint(pill, "BackgroundColor3", "Sidebar")
        Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
        stroke = Instance.new("UIStroke", pill)
        stroke.Transparency = 0.2
        Paint(stroke, "Color", "Line")
    end
    do
        -- pontas em meio círculo: um respiro maior nas laterais
        local p = Instance.new("UIPadding", pill)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 12)
        local l = Instance.new("UIListLayout", pill)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 12)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- logo: a mesma caixa "H" da marca (ou a imagem de CONFIG.LogoId)
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 24, 0, 24)
    logo.BackgroundColor3 = THEME.Accent
    logo.BorderSizePixel = 0
    logo.LayoutOrder = 1
    logo.ZIndex = 21
    logo.Parent = pill
    Paint(logo, "BackgroundColor3", "Accent")
    Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 7)
    if CONFIG.LogoId ~= "" then
        logo.BackgroundTransparency = 1
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = CONFIG.LogoId
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 22
        img.Parent = logo
    else
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, 0, 1, 0)
        h.BackgroundTransparency = 1
        h.Text = "H"
        h.TextColor3 = THEME.Main
        h.Font = Enum.Font.GothamBlack
        h.TextSize = 13
        h.ZIndex = 22
        h.Parent = logo
        Paint(h, "TextColor3", "Main")
    end

    -- v9.3: separador fino entre os blocos (o sino também usa: 11_notify)
    I.Sep = function(order)
        local s = Instance.new("Frame")
        s.Name = "Sep"
        s.Size = UDim2.new(0, 1, 0, 16)
        s.BackgroundColor3 = C and C.Sep or THEME.Line
        s.BackgroundTransparency = C and C.SepT or 0
        s.BorderSizePixel = 0
        s.LayoutOrder = order
        s.ZIndex = 21
        s.Parent = pill
        if not C then Paint(s, "BackgroundColor3", "Line") end
        return s
    end

    local function Txt(parent, order, size, hudKey, themeKey)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0, 0, 0, 18)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundTransparency = 1
        t.Text = "—"
        t.Font = Enum.Font.GothamBold
        t.TextSize = size
        t.LayoutOrder = order
        t.ZIndex = 21
        t.Parent = parent
        if C then t.TextColor3 = C[hudKey] else Paint(t, "TextColor3", themeKey) end
        return t
    end
    I.Sep(2)
    local clock = Txt(pill, 3, 14, "Text", "Text")
    I.Sep(4)
    local fps = Txt(pill, 5, 13, "Text", "Text")
    I.Sep(6)

    -- v9.3: conexão = o ping em ms + 4 barrinhas (qualidade pelo ping)
    local conn = Instance.new("Frame")
    conn.Name = "Connection"
    conn.Size = UDim2.new(0, 0, 0, 18)
    conn.AutomaticSize = Enum.AutomaticSize.X
    conn.BackgroundTransparency = 1
    conn.LayoutOrder = 7
    conn.ZIndex = 21
    conn.Parent = pill
    do
        local l = Instance.new("UIListLayout", conn)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    local ping = Txt(conn, 1, 13, "Dim", "Dim")
    local signal = Instance.new("Frame")
    signal.Name = "Signal"
    signal.Size = UDim2.new(0, 15, 0, 13)
    signal.BackgroundTransparency = 1
    signal.LayoutOrder = 2
    signal.ZIndex = 21
    signal.Parent = conn
    local bars = {}
    for i = 1, 4 do
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0, 1)
        b.Position = UDim2.new(0, (i - 1) * 4, 1, 0)
        b.Size = UDim2.new(0, 3, 0, 1 + i * 3)
        b.BackgroundColor3 = C and C.Icon or THEME.Text
        b.BackgroundTransparency = 0.8
        b.BorderSizePixel = 0
        b.ZIndex = 22
        b.Parent = signal
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 1)
        bars[i] = b
    end

    I.Update = function(f, p)
        pill.Visible = (SET.Island ~= false) and not IsOn("drone")
        pcall(I.FitTopbar)
        if not pill.Visible then return end
        clock.Text = os.date("%H:%M")
        fps.Text = "FPS " .. tostring(f or "—")
        ping.Text = tostring(p or "—") .. " ms"
        if type(f) == "number" then
            if U then
                fps.TextColor3 = C[U.FpsKey(f)]
            else
                fps.TextColor3 = (f >= 50 and THEME.Text) or (f >= 30 and THEME.Warning)
                    or THEME.Danger
            end
        end
        -- ping e barrinhas acesas na cor da qualidade (verde, amarelo,
        -- vermelho; cinza sem medida)
        if U then
            local n, key = U.Quality(p)
            local lit = C[key] or C.Dim
            for i, b in ipairs(bars) do
                b.BackgroundColor3 = (i <= n) and lit or C.Icon
                b.BackgroundTransparency = (i <= n) and 0 or 0.8
            end
            ping.TextColor3 = lit
        end
    end

    -- v9.3: borda e brilho acendem de leve no hover (é clicável: abre/fecha
    -- o painel)
    pill.MouseEnter:Connect(function()
        if U then U.Lit(stroke, halo, true) end
    end)
    pill.MouseLeave:Connect(function()
        if U then U.Lit(stroke, halo, false) end
    end)
    pill.MouseButton1Click:Connect(function()
        if V8.SetOpen and V8.IsOpen then V8.SetOpen(not V8.IsOpen()) end
    end)

    ----------------------------------------------------------------------------
    -- v9.3: MOLDURA DA BARRA DO ROBLOX (canto superior esquerdo)
    -- O botão do Roblox, o menu, o chat e o microfone são da interface do
    -- próprio Roblox (CoreGui): o painel não mexe neles — nem nos ícones, nem
    -- no espaçamento. Mudar a UI do Roblox por script quebra a cada atualização
    -- dele (e num LocalScript do jogo nem é possível). O que dá para fazer sem
    -- risco é uma moldura ATRÁS deles, no mesmo vidro das outras barras.
    -- Ela mora numa ScreenGui própria no PlayerGui, que fica sempre ABAIXO da
    -- interface do Roblox — nunca cobre um botão dele, mesmo com o painel em
    -- gethui/CoreGui — e com DisplayOrder baixo, abaixo da interface do jogo.
    -- A área vem do GuiService.TopbarInset (onde os botões do Roblox
    -- terminam). Sem essa propriedade, ou com a barra do Roblox desligada pelo
    -- jogo, a moldura não aparece. Ajustes › Ilha no topo liga/desliga.
    ----------------------------------------------------------------------------
    local tbFrame
    if U and PlayerGui then
        local tbGui = Instance.new("ScreenGui")
        tbGui.Name = "HYGE_TopbarFrame"
        tbGui.IgnoreGuiInset = true
        tbGui.ResetOnSpawn = false
        tbGui.DisplayOrder = -10
        Track(tbGui)   -- o Unload destrói
        tbFrame = Instance.new("Frame")
        tbFrame.Name = "Frame"
        tbFrame.Visible = false
        tbFrame.Parent = tbGui
        U.Glass(tbFrame, U.PILL)
        U.Halo(tbFrame)
        tbGui.Parent = PlayerGui
    end
    I.TB_MARGIN = 4   -- folga da moldura em volta dos botões do Roblox
    I.FitTopbar = function()
        if not tbFrame then return end
        local ok, r = pcall(function() return GuiService.TopbarInset end)
        local m = I.TB_MARGIN
        local show = SET.TopbarFrame ~= false and ok and typeof(r) == "Rect"
            and r.Min.X >= 40 and r.Max.Y >= 24
        if show then
            local h = math.floor(r.Max.Y - 2 * m)
            tbFrame.Position = UDim2.new(0, m, 0, m)
            tbFrame.Size = UDim2.new(0, math.floor(r.Min.X - 2 * m), 0, h)
        end
        tbFrame.Visible = show
    end
    -- os botões do Roblox mudam de tamanho (menu expandido, chat ligado...)
    pcall(function()
        Conn.TopbarFit = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
            pcall(I.FitTopbar)
        end)
    end)

    -- carona no Every(0.5) do scheduler (ele chama SetChips a cada meio segundo)
    do
        local base = SetChips
        SetChips = function(f, p, ...)
            if base then base(f, p, ...) end
            pcall(I.Update, f, p)
        end
    end

    -- Ajustes
    do
        local card = CreateCard(Tabs.Settings, "ILHA NO TOPO", 9)
        CheckRow(card, "Mostrar a ilha",
            "Hora, FPS, conexão e ping no alto da tela; clique abre/fecha o painel",
            function() return SET.Island ~= false end,
            function(v)
                SET.Island = v and true or false
                pcall(I.Update, State.Fps, nil)
            end, 1)
        if tbFrame then
            CheckRow(card, "Moldura na barra do Roblox",
                "Vidro atrás do botão do Roblox, menu, chat e microfone (os botões continuam os do Roblox)",
                function() return SET.TopbarFrame ~= false end,
                function(v)
                    SET.TopbarFrame = v and true or false
                    pcall(I.FitTopbar)
                end, 2)
        end
    end

    pcall(I.Update, State.Fps, nil)
end
