--------------------------------------------------------------------------------
-- FÁBRICA DE UI
--------------------------------------------------------------------------------
local Tabs, NavButtons = {}, {}
local ShowTab  -- forward

local function CreateTab(name)
    local f = Instance.new("ScrollingFrame")
    f.Name = name
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Visible = false
    f.ScrollBarThickness = 3
    f.ScrollingDirection = Enum.ScrollingDirection.Y
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.Parent = Content
    Paint(f, "ScrollBarImageColor3", "Accent")

    local layout = Instance.new("UIListLayout", f)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", f)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 10)

    Tabs[name] = f
    return f
end

local TabHooks = {}
local function OnTabOpen(name, fn)
    if not TabHooks[name] then TabHooks[name] = {} end
    table.insert(TabHooks[name], fn)
end

ShowTab = function(name)
    if not Tabs[name] then return end
    for n, t in pairs(Tabs) do
        if t.Visible and n ~= name then t.Visible = false end
    end
    local tab = Tabs[name]
    tab.Visible = true
    State.ActiveTab = name

    -- fade-in suave
    for _, d in ipairs(tab:GetDescendants()) do
        if d:IsA("Frame") and d.Name == "Card" then
            d.Position = UDim2.new(0, 0, 0, 6)
            TweenService:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                { Position = UDim2.new(0, 0, 0, 0) }):Play()
        end
    end

    for n, b in pairs(NavButtons) do
        local active = (n == name)
        TweenService:Create(b.button, TweenInfo.new(0.14), {
            BackgroundColor3 = active and THEME.Accent or THEME.Sidebar,
            BackgroundTransparency = active and 0.82 or 0,
        }):Play()
        if b.label then
            TweenService:Create(b.label, TweenInfo.new(0.14), {
                TextColor3 = active and THEME.Accent or THEME.Dim }):Play()
        end
        if b.stroke then
            b.stroke.Color = THEME.Accent
            TweenService:Create(b.stroke, TweenInfo.new(0.14), {
                Transparency = active and 0.35 or 1 }):Play()
        end
        if IconTint then IconTint(b.icon, active and THEME.Accent or THEME.Dim) end
        TweenService:Create(b.pill, TweenInfo.new(0.16), {
            Size = active and UDim2.new(0, 3, 0, 22) or UDim2.new(0, 3, 0, 0),
            BackgroundColor3 = THEME.Accent,
        }):Play()
    end

    if TabHooks[name] then
        for _, hook in ipairs(TabHooks[name]) do
            local ok, err = pcall(hook)
            if not ok then Log("hook " .. name .. ": " .. tostring(err), "error") end
        end
    end
end

local function AddNav(name, order)
    local NAV_ICON = {
        Home = "home", Movement = "user", Visuals = "eye", Players = "users",
        Moderation = "shield", Server = "server", Emotes = "smile", Settings = "gear",
        Shop = "bag", Scripts = "terminal", Chat = "chat",   -- v8.0
    }
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32)   -- v8.0: 11 abas precisam caber na sidebar
    b.BackgroundColor3 = THEME.Sidebar
    b.Text = ""
    b.AutoButtonColor = false
    b.LayoutOrder = order
    b.Parent = Sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)

    local navStroke = Instance.new("UIStroke", b)
    navStroke.Transparency = 1
    navStroke.Color = THEME.Accent

    local ic = Icon and Icon(b, NAV_ICON[name] or "dot", THEME.Dim, 17) or nil
    if ic then ic.Position = UDim2.new(0, 13, 0.5, -8) end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.new(0, 40, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.Dim
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = b

    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(0, 0.5)
    pill.Position = UDim2.new(0, 0, 0.5, 0)
    pill.Size = UDim2.new(0, 3, 0, 0)
    pill.BackgroundColor3 = THEME.Accent
    pill.BorderSizePixel = 0
    pill.Parent = b
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    b.MouseEnter:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(lbl, TweenInfo.new(0.12), { TextColor3 = THEME.Text }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(lbl, TweenInfo.new(0.12), { TextColor3 = THEME.Dim }):Play()
        end
    end)
    b.MouseButton1Click:Connect(function() ShowTab(name) end)

    NavButtons[name] = { button = b, pill = pill, icon = ic, label = lbl,
        stroke = navStroke }
end

-- v8.0: título de seção em caixa de frase ("MOVIMENTO E VELOCIDADE" vira
-- "Movimento e velocidade"), preservando siglas. string.lower não conhece
-- acento (UTF-8), então as maiúsculas acentuadas do português vão por tabela.
do
    local LOWER = { ["Á"] = "á", ["À"] = "à", ["Â"] = "â", ["Ã"] = "ã", ["É"] = "é",
        ["Ê"] = "ê", ["Í"] = "í", ["Ó"] = "ó", ["Ô"] = "ô", ["Õ"] = "õ", ["Ú"] = "ú",
        ["Ç"] = "ç" }
    local KEEP = { ESP = true, HUD = true, ID = true, FPS = true, AFK = true,
        JSON = true, HYGE = true, UI = true, TP = true }
    V8.Sentence = function(s)
        if type(s) ~= "string" or s == "" or s:upper() ~= s then return s end
        local out = s:lower():gsub("\195[\128-\159]", function(c) return LOWER[c] end)
        out = out:gsub("%a+", function(w)
            if KEEP[w:upper()] then return w:upper() end
        end)
        return (out:gsub("^%l", string.upper))
    end
end

-- v8.0: transforma um Frame em "cartão" (fundo, borda sutil, cantos, respiro
-- interno). As linhas (switch, slider, keybind) são cartões soltos.
V8.Cell = function(f, padV)
    f.BackgroundColor3 = THEME.Card
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    Paint(f, "BackgroundColor3", "Card")
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", f)
    st.Transparency = 0.25
    Paint(st, "Color", "Line")
    local p = Instance.new("UIPadding", f)
    p.PaddingLeft = UDim.new(0, 14)
    p.PaddingRight = UDim.new(0, 12)
    p.PaddingTop = UDim.new(0, padV or 0)
    p.PaddingBottom = UDim.new(0, padV or 0)
    return f
end

-- v8.0: o "card" virou SEÇÃO — título pequeno em cima e o conteúdo solto
-- embaixo (cada linha é seu próprio cartão). Antes era uma caixa com tudo dentro.
local function CreateCard(parent, title, order)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = parent

    local layout = Instance.new("UIListLayout", card)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    if title then
        local head = Instance.new("TextLabel")
        head.Size = UDim2.new(1, 0, 0, 18)
        head.BackgroundTransparency = 1
        head.Text = V8.Sentence(title)
        head.TextColor3 = THEME.Text
        head.Font = Enum.Font.GothamBold
        head.TextSize = 13
        head.TextXAlignment = Enum.TextXAlignment.Left
        head.LayoutOrder = -1
        head.Parent = card
        Paint(head, "TextColor3", "Text")
    end
    return card
end

local function CardTitleRef(card)
    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("TextLabel") and c.LayoutOrder == -1 then return c end
    end
end

local function Grid(parent, cols, cellHeight)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local g = Instance.new("UIGridLayout", holder)
    g.CellPadding = UDim2.new(0, 8, 0, 8)
    g.CellSize = UDim2.new(1 / cols, -8, 0, cellHeight or 34)
    g.SortOrder = Enum.SortOrder.LayoutOrder
    return holder
end

local function CreateButton(parent, text, colorKey, height)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, height or 34)
    b.BackgroundColor3 = THEME.Btn
    b.Text = text
    b.TextColor3 = THEME.Text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextWrapped = true   -- v8.0: na janela estreita, texto longo quebra em vez de vazar
    b.AutoButtonColor = false
    b.Parent = parent
    Paint(b, "BackgroundColor3", "Btn")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", b)
    stroke.Transparency = 0.8
    Paint(stroke, "Color", colorKey or "Accent")

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {
            BackgroundColor3 = THEME[colorKey or "Accent"], TextColor3 = Color3.new(0, 0, 0) }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.13), { Transparency = 0.2 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {
            BackgroundColor3 = THEME.Btn, TextColor3 = THEME.Text }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.13), { Transparency = 0.8 }):Play()
    end)
    return b
end

local function CreateInput(parent, placeholder, height)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, height or 34)
    box.BackgroundColor3 = THEME.Btn
    box.TextColor3 = THEME.Text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = THEME.Dim
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Text = ""
    box.Parent = parent
    Paint(box, "BackgroundColor3", "Btn")
    Paint(box, "TextColor3", "Text")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", box)
    stroke.Transparency = 0.85
    Paint(stroke, "Color", "Accent")
    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0.2 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0.85 }):Play()
    end)
    return box
end

local function Divider(parent)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = THEME.Line
    d.BorderSizePixel = 0
    d.Parent = parent
    Paint(d, "BackgroundColor3", "Line")
    return d
end

