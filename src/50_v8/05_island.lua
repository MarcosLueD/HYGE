--------------------------------------------------------------------------------
-- v8.0 — ILHA NO TOPO DA TELA
-- Pílula fixa no alto, centralizada: logo, hora, FPS e ping — à vista mesmo
-- com o painel fechado. Clicar abre/fecha o painel.
-- Sem loop próprio: o Every(0.5) do scheduler já chama SetChips(fps, ping, ...)
-- e a ilha pega carona nele. Some durante o drone (a bússola do HUD fica ali).
-- Ajustes › Ilha no topo liga/desliga (vai junto na config em disco).
-- Tudo em V8.Island: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    V8.Island = {}
    local I = V8.Island
    if SET.Island == nil then SET.Island = true end

    local pill = Instance.new("TextButton")
    pill.Name = "Island"
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 8)
    pill.Size = UDim2.new(0, 0, 0, 34)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = THEME.Sidebar
    pill.BackgroundTransparency = 0.02
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Visible = SET.Island ~= false
    pill.ZIndex = 20
    pill.Parent = Gui
    Paint(pill, "BackgroundColor3", "Sidebar")
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
    do
        local st = Instance.new("UIStroke", pill)
        st.Transparency = 0.2
        Paint(st, "Color", "Line")
        local p = Instance.new("UIPadding", pill)
        p.PaddingLeft = UDim.new(0, 6)
        p.PaddingRight = UDim.new(0, 14)
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

    local function Txt(order, size, key)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0, 0, 0, 18)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundTransparency = 1
        t.Text = "—"
        t.TextColor3 = THEME[key]
        t.Font = Enum.Font.GothamBold
        t.TextSize = size
        t.LayoutOrder = order
        t.ZIndex = 21
        t.Parent = pill
        Paint(t, "TextColor3", key)
        return t
    end
    local clock = Txt(2, 13, "Text")
    local fps = Txt(3, 12, "Text")
    local ping = Txt(4, 12, "Dim")

    I.Update = function(f, p)
        pill.Visible = (SET.Island ~= false) and not IsOn("drone")
        if not pill.Visible then return end
        clock.Text = os.date("%H:%M")
        fps.Text = "FPS " .. tostring(f or "—")
        ping.Text = tostring(p or "—") .. " ms"
        if type(f) == "number" then
            fps.TextColor3 = (f >= 50 and THEME.Text) or (f >= 30 and THEME.Warning)
                or THEME.Danger
        end
    end

    pill.MouseButton1Click:Connect(function()
        if V8.SetOpen and V8.IsOpen then V8.SetOpen(not V8.IsOpen()) end
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
            "Hora, FPS e ping no alto da tela; clique abre/fecha o painel",
            function() return SET.Island ~= false end,
            function(v)
                SET.Island = v and true or false
                pcall(I.Update, State.Fps, nil)
            end, 1)
    end

    pcall(I.Update, State.Fps, nil)
end
