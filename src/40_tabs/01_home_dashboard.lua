--------------------------------------------------------------------------------
-- v8.0 — DASHBOARD DA HOME (header + relogio, tira de status, card do jogador
-- com chat rapido e Friend Activity). Tudo pendurado em V8.Dash: zero locais
-- novos no chunk principal. Entra DEPOIS de 40_tabs/00_home.lua no build.
--------------------------------------------------------------------------------
do
    V8.Dash = {}
    local D = V8.Dash
    local home = Tabs.Home
    if not home then return end

    ----------------------------------------------------------------------------
    -- 1. HEADER: "Welcome home, <nome>" + relogio
    ----------------------------------------------------------------------------
    local head = Instance.new("Frame")
    head.Name = "Card"
    head.Size = UDim2.new(1, 0, 0, 62)
    head.BackgroundColor3 = THEME.Card
    head.BackgroundTransparency = 0.25
    head.BorderSizePixel = 0
    head.LayoutOrder = -3
    head.Parent = home
    Paint(head, "BackgroundColor3", "Card")
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 12)
    D.Head = head   -- o shell esconde este card (o welcome subiu pra TopBar)

    do  -- gradiente diagonal (o look azul do mockup)
        local g = Instance.new("UIGradient", head)
        g.Rotation = 25
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.5),
        })
    end

    local welcome = Instance.new("TextLabel")
    welcome.Size = UDim2.new(1, -160, 0, 24)
    welcome.Position = UDim2.new(0, 16, 0, 11)
    welcome.BackgroundTransparency = 1
    welcome.Text = "Welcome home, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
    welcome.TextColor3 = THEME.Text
    welcome.Font = Enum.Font.GothamBold
    welcome.TextSize = 19
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.TextTruncate = Enum.TextTruncate.AtEnd
    welcome.Parent = head
    Paint(welcome, "TextColor3", "Text")

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -160, 0, 14)
    sub.Position = UDim2.new(0, 16, 0, 35)
    sub.BackgroundTransparency = 1
    sub.Text = "HYGE " .. CONFIG.Version
    sub.TextColor3 = THEME.Dim
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = head
    Paint(sub, "TextColor3", "Dim")

    local clockIco = Icon(head, "clock", THEME.Dim, 16, 1)
    clockIco.Position = UDim2.new(1, -104, 0.5, -8)

    local clockLbl = Instance.new("TextLabel")
    clockLbl.Size = UDim2.new(0, 78, 0, 22)
    clockLbl.Position = UDim2.new(1, -84, 0.5, -11)
    clockLbl.BackgroundTransparency = 1
    clockLbl.Text = "--:--"
    clockLbl.TextColor3 = THEME.Text
    clockLbl.Font = Enum.Font.GothamBold
    clockLbl.TextSize = 16
    clockLbl.TextXAlignment = Enum.TextXAlignment.Right
    clockLbl.Parent = head
    Paint(clockLbl, "TextColor3", "Text")

    ----------------------------------------------------------------------------
    -- 2. TIRA DE STATUS: 3 colunas clicaveis (igual ao mockup)
    ----------------------------------------------------------------------------
    -- a tira nao e mais um card unico: sao 3 cards arredondados separados
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1, 0, 0, 72)
    strip.BackgroundTransparency = 1
    strip.LayoutOrder = -2
    strip.Parent = home

    D.Slots = { "fly", "noclip", "esp" }   -- o que cada card mostra
    -- icone por toggle (o card sempre mostra o icone do que ele controla)
    D.SlotIcons = {
        fly = "bolt", noclip = "ghost", esp = "eye", god = "shield",
        invisible = "circle", infjump = "up", wall = "box", chatspy = "clip",
        fullbright = "sun", antiafk = "clock", freecam = "cam", drone = "wifi",
    }
    local slotUI = {}

    for i = 1, 3 do
        local col = Instance.new("TextButton")
        col.Name = "Card"
        col.Size = UDim2.new(1 / 3, -8, 1, 0)
        col.Position = UDim2.new((i - 1) / 3, (i - 1) * 4, 0, 0)
        col.BackgroundColor3 = THEME.Card
        col.BorderSizePixel = 0
        col.Text = ""
        col.AutoButtonColor = false
        col.Parent = strip
        Paint(col, "BackgroundColor3", "Card")
        Instance.new("UICorner", col).CornerRadius = UDim.new(0, 12)
        local colStroke = Instance.new("UIStroke", col)
        colStroke.Transparency = 0.6
        Paint(colStroke, "Color", "Line")

        -- caixinha do icone
        local pad = Instance.new("Frame")
        pad.Size = UDim2.new(0, 34, 0, 34)
        pad.Position = UDim2.new(0, 12, 0.5, -17)
        pad.BackgroundColor3 = THEME.Btn
        pad.BorderSizePixel = 0
        pad.Parent = col
        Paint(pad, "BackgroundColor3", "Btn")
        Instance.new("UICorner", pad).CornerRadius = UDim.new(0, 10)

        local ico = Icon(pad, "dot", THEME.Dim, 18, 1)
        ico.AnchorPoint = Vector2.new(0.5, 0.5)
        ico.Position = UDim2.new(0.5, 0, 0.5, 0)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -60, 0, 20)
        name.Position = UDim2.new(0, 54, 0, 16)
        name.BackgroundTransparency = 1
        name.Text = "—"
        name.TextColor3 = THEME.Text
        name.Font = Enum.Font.GothamBold
        name.TextSize = 15
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = col
        Paint(name, "TextColor3", "Text")

        local state = Instance.new("TextLabel")
        state.Size = UDim2.new(1, -60, 0, 14)
        state.Position = UDim2.new(0, 54, 0, 38)
        state.BackgroundTransparency = 1
        state.Text = "Off"
        state.TextColor3 = THEME.Dim
        state.Font = Enum.Font.GothamMedium
        state.TextSize = 12
        state.TextXAlignment = Enum.TextXAlignment.Left
        state.Parent = col
        Paint(state, "TextColor3", "Dim")

        col.MouseEnter:Connect(function() colStroke.Transparency = 0.25 end)
        col.MouseLeave:Connect(function() colStroke.Transparency = 0.6 end)
        col.MouseButton1Click:Connect(function()
            local id = D.Slots[i]
            if id and Toggles[id] then
                Flip(id)
                pcall(D.Tick)
            else
                Log("Card " .. i .. " não tem um toggle válido "
                    .. "(ajuste em Ajustes › Navegação)", "warn")
            end
        end)

        slotUI[i] = { name = name, state = state, icon = ico,
                      pad = pad, stroke = colStroke, card = col }
    end

    ----------------------------------------------------------------------------
    -- troca o que os 3 cards controlam. Aceita "fly noclip esp" ou tabela.
    ----------------------------------------------------------------------------
    D.SetSlots = function(spec, silent)
        local list = {}
        if type(spec) == "table" then
            for i = 1, 3 do list[i] = spec[i] end
        elseif type(spec) == "string" then
            for w in spec:gmatch("[%w_]+") do
                if #list < 3 then list[#list + 1] = w:lower() end
            end
        end
        local bad = {}
        for i = 1, 3 do
            local id = list[i]
            if id and Toggles[id] then
                D.Slots[i] = id
            elseif id then
                bad[#bad + 1] = id
            end
        end
        pcall(D.Tick)
        if not silent then
            if #bad > 0 then
                Log("Ignorei toggle inexistente: " .. table.concat(bad, ", "), "warn")
            end
            Log("Cards de status: " .. table.concat(D.Slots, " "), "ok")
        end
        return table.concat(D.Slots, " ")
    end

    ----------------------------------------------------------------------------
    -- 3. LINHA DE BAIXO: card do jogador  |  Friend Activity
    ----------------------------------------------------------------------------
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 250)
    row.BackgroundTransparency = 1
    row.LayoutOrder = -1
    row.Parent = home

    local function Panel(xScale, xOff, wScale, wOff)
        local p = Instance.new("Frame")
        p.Name = "Card"
        p.Size = UDim2.new(wScale, wOff, 1, 0)
        p.Position = UDim2.new(xScale, xOff, 0, 0)
        p.BackgroundColor3 = THEME.Card
        p.BorderSizePixel = 0
        p.Parent = row
        Paint(p, "BackgroundColor3", "Card")
        Instance.new("UICorner", p).CornerRadius = UDim.new(0, 12)
        local st = Instance.new("UIStroke", p)
        st.Transparency = 0.6
        Paint(st, "Color", "Line")
        return p
    end

    local me = Panel(0, 0, 0.46, -6)
    local fr = Panel(0.46, 6, 0.54, -6)

    ---------------------------------------------------------------- card do eu
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 112, 0, 112)
    ring.Position = UDim2.new(0.5, -56, 0, 16)
    ring.BackgroundTransparency = 1
    ring.Parent = me
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    do
        local st = Instance.new("UIStroke", ring)
        st.Thickness = 2
        Paint(st, "Color", "Accent")
    end

    local face = Instance.new("ImageLabel")
    face.Size = UDim2.new(1, -10, 1, -10)
    face.Position = UDim2.new(0, 5, 0, 5)
    face.BackgroundColor3 = THEME.Track
    face.BorderSizePixel = 0
    face.Image = "rbxthumb://type=AvatarThumbnail&id="
        .. tostring(LocalPlayer.UserId) .. "&w=420&h=420"
    face.Parent = ring
    Paint(face, "BackgroundColor3", "Track")
    Instance.new("UICorner", face).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(1, -20, 1, -26)
    dot.BackgroundColor3 = THEME.Success
    dot.BorderSizePixel = 0
    dot.Parent = ring
    Paint(dot, "BackgroundColor3", "Success")
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    do
        local st = Instance.new("UIStroke", dot)
        st.Thickness = 3
        Paint(st, "Color", "Card")
    end

    -- nome + selo de verificado (o selo e desenhado pelo shell, que carrega
    -- depois: aqui fica so a linha que o abriga)
    local nameRow = Instance.new("Frame")
    nameRow.Name = "NameRow"
    nameRow.Size = UDim2.new(1, -20, 0, 22)
    nameRow.Position = UDim2.new(0, 10, 0, 136)
    nameRow.BackgroundTransparency = 1
    nameRow.Parent = me
    do
        local l = Instance.new("UIListLayout", nameRow)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    D.NameRow = nameRow

    local myName = Instance.new("TextLabel")
    myName.AutomaticSize = Enum.AutomaticSize.X
    myName.Size = UDim2.new(0, 0, 0, 20)
    myName.BackgroundTransparency = 1
    myName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    myName.TextColor3 = THEME.Text
    myName.Font = Enum.Font.GothamBold
    myName.TextSize = 16
    myName.LayoutOrder = 1
    myName.Parent = nameRow
    Paint(myName, "TextColor3", "Text")

    local myTag = Instance.new("TextLabel")
    myTag.Size = UDim2.new(1, -20, 0, 14)
    myTag.Position = UDim2.new(0, 10, 0, 159)
    myTag.BackgroundTransparency = 1
    myTag.Text = "@" .. LocalPlayer.Name
    myTag.TextColor3 = THEME.Dim
    myTag.Font = Enum.Font.GothamMedium
    myTag.TextSize = 12
    myTag.TextXAlignment = Enum.TextXAlignment.Center
    myTag.Parent = me
    Paint(myTag, "TextColor3", "Dim")

    ------------------------------------------------------------ chat rapido
    local chatBox = Instance.new("Frame")
    chatBox.Size = UDim2.new(1, -24, 0, 40)
    chatBox.Position = UDim2.new(0, 12, 1, -52)
    chatBox.BackgroundColor3 = THEME.Btn
    chatBox.BorderSizePixel = 0
    chatBox.Parent = me
    Paint(chatBox, "BackgroundColor3", "Btn")
    Instance.new("UICorner", chatBox).CornerRadius = UDim.new(0, 10)
    do
        local st = Instance.new("UIStroke", chatBox)
        st.Transparency = 0.7
        Paint(st, "Color", "Line")
    end

    local chatIco = Icon(chatBox, "smile", THEME.Dim, 16, 1)
    chatIco.Position = UDim2.new(0, 12, 0.5, -8)

    local chatInput = Instance.new("TextBox")
    chatInput.Size = UDim2.new(1, -46, 1, 0)
    chatInput.Position = UDim2.new(0, 38, 0, 0)
    chatInput.BackgroundTransparency = 1
    chatInput.Text = ""
    chatInput.PlaceholderText = "Chat..."
    chatInput.TextColor3 = THEME.Text
    chatInput.PlaceholderColor3 = THEME.Dim
    chatInput.Font = Enum.Font.GothamMedium
    chatInput.TextSize = 13
    chatInput.TextXAlignment = Enum.TextXAlignment.Left
    chatInput.ClearTextOnFocus = false
    chatInput.Parent = chatBox
    Paint(chatInput, "TextColor3", "Text")
    Paint(chatInput, "PlaceholderColor3", "Dim")

    -- manda no chat DO JOGO pelo seu proprio player. Cobre os dois sistemas.
    D.Say = function(msg)
        if type(msg) ~= "string" or msg:gsub("%s", "") == "" then return false end
        local sent = false

        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                local ch = tcs:FindFirstChild("TextChannels")
                ch = ch and ch:FindFirstChild("RBXGeneral")
                if ch then
                    ch:SendAsync(msg)
                    sent = true
                end
            end
        end)

        if not sent then
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local say = ev and ev:FindFirstChild("SayMessageRequest")
                if say then
                    say:FireServer(msg, "All")
                    sent = true
                end
            end)
        end

        if sent then
            Log("Chat: " .. msg, "action")
        else
            Log("Não achei o sistema de chat deste jogo — nada foi enviado", "error")
            Toast("Chat indisponível neste jogo", "error", 4)
        end
        return sent
    end

    chatInput.FocusLost:Connect(function(enter)
        local msg = chatInput.Text
        chatInput.Text = ""
        if enter then D.Say(msg) end
    end)

    -------------------------------------------------------- Friend Activity
    local frHead = Instance.new("TextLabel")
    frHead.Size = UDim2.new(1, -100, 0, 20)
    frHead.Position = UDim2.new(0, 14, 0, 12)
    frHead.BackgroundTransparency = 1
    frHead.Text = "Friend Activity"
    frHead.TextColor3 = THEME.Text
    frHead.Font = Enum.Font.GothamBold
    frHead.TextSize = 14
    frHead.TextXAlignment = Enum.TextXAlignment.Left
    frHead.Parent = fr
    Paint(frHead, "TextColor3", "Text")

    local frBtn = CreateButton(fr, "ATUALIZAR", "Accent", 22)
    frBtn.Size = UDim2.new(0, 84, 0, 22)
    frBtn.Position = UDim2.new(1, -98, 0, 11)
    frBtn.TextSize = 10

    local frList = Instance.new("ScrollingFrame")
    frList.Size = UDim2.new(1, -20, 1, -50)
    frList.Position = UDim2.new(0, 10, 0, 40)
    frList.BackgroundTransparency = 1
    frList.BorderSizePixel = 0
    frList.ScrollBarThickness = 3
    frList.CanvasSize = UDim2.new(0, 0, 0, 0)
    frList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frList.Parent = fr
    Paint(frList, "ScrollBarImageColor3", "Accent")
    do
        local l = Instance.new("UIListLayout", frList)
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local frEmpty = Instance.new("TextLabel")
    frEmpty.Size = UDim2.new(1, 0, 0, 40)
    frEmpty.BackgroundTransparency = 1
    frEmpty.Text = "Clique em ATUALIZAR"
    frEmpty.TextColor3 = THEME.Dim
    frEmpty.Font = Enum.Font.GothamMedium
    frEmpty.TextSize = 12
    frEmpty.TextWrapped = true
    frEmpty.LayoutOrder = 999
    frEmpty.Parent = frList
    Paint(frEmpty, "TextColor3", "Dim")

    D.Friends = function(silent)
        for _, c in ipairs(frList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local ok, list = pcall(function() return LocalPlayer:GetFriendsOnline(12) end)
        if not ok or type(list) ~= "table" then
            frEmpty.Text = "Seu executor não deixou ler a lista de amigos"
            frEmpty.Visible = true
            if not silent then Log("GetFriendsOnline falhou neste executor", "warn") end
            return
        end
        if #list == 0 then
            frEmpty.Text = "Nenhum amigo online agora"
            frEmpty.Visible = true
            if not silent then Log("Nenhum amigo online", "info") end
            return
        end
        frEmpty.Visible = false

        for i, f in ipairs(list) do
            local rowf = Instance.new("Frame")
            rowf.Size = UDim2.new(1, -6, 0, 46)
            rowf.BackgroundColor3 = THEME.Btn
            rowf.BorderSizePixel = 0
            rowf.LayoutOrder = i
            rowf.Parent = frList
            Paint(rowf, "BackgroundColor3", "Btn")
            Instance.new("UICorner", rowf).CornerRadius = UDim.new(0, 9)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 34, 0, 34)
            thumb.Position = UDim2.new(0, 6, 0, 6)
            thumb.BackgroundColor3 = THEME.Track
            thumb.BorderSizePixel = 0
            thumb.Parent = rowf
            Paint(thumb, "BackgroundColor3", "Track")
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 7)
            if f.PlaceId then
                thumb.Image = "rbxthumb://type=GameIcon&id="
                    .. tostring(f.PlaceId) .. "&w=150&h=150"
            else
                thumb.Image = "rbxthumb://type=AvatarHeadShot&id="
                    .. tostring(f.VisitorId) .. "&w=48&h=48"
            end

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -136, 0, 16)
            nm.Position = UDim2.new(0, 46, 0, 7)
            nm.BackgroundTransparency = 1
            nm.Text = tostring(f.DisplayName or f.UserName or "?")
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = rowf
            Paint(nm, "TextColor3", "Text")

            local loc = Instance.new("TextLabel")
            loc.Size = UDim2.new(1, -136, 0, 13)
            loc.Position = UDim2.new(0, 46, 0, 24)
            loc.BackgroundTransparency = 1
            loc.Text = tostring(f.LastLocation or "Online")
            loc.TextColor3 = THEME.Dim
            loc.Font = Enum.Font.GothamMedium
            loc.TextSize = 11
            loc.TextXAlignment = Enum.TextXAlignment.Left
            loc.TextTruncate = Enum.TextTruncate.AtEnd
            loc.Parent = rowf
            Paint(loc, "TextColor3", "Dim")

            if f.PlaceId and f.GameId then
                local join = CreateButton(rowf, "ENTRAR", "Success", 24)
                join.Size = UDim2.new(0, 74, 0, 24)
                join.Position = UDim2.new(1, -82, 0.5, -12)
                join.TextSize = 10
                join.MouseButton1Click:Connect(function()
                    Confirm("Teleportar para o servidor de "
                        .. tostring(f.DisplayName or f.UserName) .. "?", function()
                        Log("Teleportando para o jogo de "
                            .. tostring(f.UserName), "action")
                        local okT, errT = pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                f.PlaceId, f.GameId, LocalPlayer)
                        end)
                        if not okT then
                            Log("Teleporte recusado: " .. tostring(errT), "error")
                        end
                    end)
                end)
            end
        end

        if not silent then Log(#list .. " amigo(s) online", "ok") end
    end

    frBtn.MouseButton1Click:Connect(function() D.Friends() end)

    ----------------------------------------------------------------------------
    -- 4. TICK (relogio + tira de status) — chamado pelo Every(1) de 90_runtime/04_scheduler.lua
    ----------------------------------------------------------------------------
    D.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
        for i = 1, 3 do
            local id = D.Slots[i]
            local ui = slotUI[i]
            if ui then
                if id and Toggles[id] then
                    local on = IsOn(id)
                    ui.name.Text = (Toggles[id].label or id)
                    ui.state.Text = on and "On" or "Off"
                    ui.state.TextColor3 = on and THEME.Success or THEME.Dim
                    ui.name.TextColor3 = on and THEME.Text or THEME.Dim
                    -- icone do toggle: aceso no Accent, apagado no Dim
                    if ui.iconKind ~= (D.SlotIcons[id] or "dot") then
                        ui.iconKind = D.SlotIcons[id] or "dot"
                        ui.icon:Destroy()
                        ui.icon = Icon(ui.pad, ui.iconKind, THEME.Dim, 18, 1)
                        ui.icon.AnchorPoint = Vector2.new(0.5, 0.5)
                        ui.icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                    IconTint(ui.icon, on and THEME.Accent or THEME.Dim)
                    ui.pad.BackgroundTransparency = on and 0 or 0.45
                else
                    ui.name.Text = "—"
                    ui.state.Text = ""
                    IconTint(ui.icon, THEME.Dim)
                end
            end
        end
    end

    -- abrir a Home ja atualiza a tira (o registry acumula: o hook de 00_home.lua
    -- continua rodando tambem)
    OnTabOpen("Home", function() pcall(D.Tick) end)

    pcall(D.Tick)
end
