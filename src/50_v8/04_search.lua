--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — BUSCA GLOBAL (Ctrl+K)
-- Overlay único que pesquisa situações, funções, jogadores, waypoints e
-- comandos. Enter executa o item selecionado; ↑/↓ navegam; Esc fecha.
-- Nenhum loop novo: só uma conexão de teclado (Conn.SearchKeys).
--------------------------------------------------------------------------------
do
    V8.Search = {}
    local S = V8.Search

    CONFIG.SearchKey  = Enum.KeyCode.K
    CONFIG.SearchCtrl = true

    local ROWS = 8
    local items, sel = {}, 1

    ----------------------------------------------------------------------------
    -- UI
    ----------------------------------------------------------------------------
    local Overlay = Instance.new("Frame")
    Overlay.Name = "Search"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Visible = false
    Overlay.ZIndex = 50
    Overlay.Parent = Gui

    local dim = Instance.new("TextButton")   -- clique fora fecha
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundTransparency = 1
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.ZIndex = 50
    dim.Parent = Overlay

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0)
    box.Position = UDim2.new(0.5, 0, 0, 90)
    box.Size = UDim2.new(0, 560, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundColor3 = THEME.Card
    box.BorderSizePixel = 0
    box.ZIndex = 51
    box.Parent = Overlay
    Paint(box, "BackgroundColor3", "Card")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 13)
    local bst = Instance.new("UIStroke", box)
    bst.Transparency = 0.25
    Paint(bst, "Color", "Accent")

    local pad = Instance.new("UIPadding", box)
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local layout = Instance.new("UIListLayout", box)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local input = CreateInput(box, "buscar situação, função, jogador, waypoint, comando...", 36)
    input.LayoutOrder = 0
    input.ZIndex = 52
    input.TextSize = 14

    local hintTop = Instance.new("TextLabel")
    hintTop.Size = UDim2.new(1, 0, 0, 13)
    hintTop.BackgroundTransparency = 1
    hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha"
    hintTop.TextColor3 = THEME.Dim
    hintTop.Font = Enum.Font.Gotham
    hintTop.TextSize = 10
    hintTop.TextXAlignment = Enum.TextXAlignment.Left
    hintTop.LayoutOrder = 1
    hintTop.ZIndex = 52
    hintTop.Parent = box
    table.insert(Painted, { inst = hintTop, prop = "TextColor3", key = "Dim" })

    local rows = {}
    for i = 1, ROWS do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = 1 + i
        b.Visible = false
        b.ZIndex = 52
        b.Parent = box
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

        local kind = Instance.new("TextLabel")
        kind.Size = UDim2.new(0, 74, 1, 0)
        kind.Position = UDim2.new(0, 8, 0, 0)
        kind.BackgroundTransparency = 1
        kind.Text = ""
        kind.TextColor3 = THEME.Accent2
        kind.Font = Enum.Font.GothamBold
        kind.TextSize = 9
        kind.TextXAlignment = Enum.TextXAlignment.Left
        kind.ZIndex = 53
        kind.Parent = b
        table.insert(Painted, { inst = kind, prop = "TextColor3", key = "Accent2" })

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -230, 1, 0)
        label.Position = UDim2.new(0, 86, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = ""
        label.TextColor3 = THEME.Text
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 53
        label.Parent = b
        Paint(label, "TextColor3", "Text")

        local hint = Instance.new("TextLabel")
        hint.AnchorPoint = Vector2.new(1, 0)
        hint.Size = UDim2.new(0, 200, 1, 0)
        hint.Position = UDim2.new(1, -8, 0, 0)
        hint.BackgroundTransparency = 1
        hint.Text = ""
        hint.TextColor3 = THEME.Dim
        hint.Font = Enum.Font.Gotham
        hint.TextSize = 10
        hint.TextXAlignment = Enum.TextXAlignment.Right
        hint.TextTruncate = Enum.TextTruncate.AtEnd
        hint.ZIndex = 53
        hint.Parent = b
        table.insert(Painted, { inst = hint, prop = "TextColor3", key = "Dim" })

        rows[i] = { btn = b, kind = kind, label = label, hint = hint }
        b.MouseButton1Click:Connect(function()
            sel = i
            S.Run()
        end)
    end

    local empty = Instance.new("TextLabel")
    empty.Size = UDim2.new(1, 0, 0, 26)
    empty.BackgroundTransparency = 1
    empty.Text = "nada encontrado"
    empty.TextColor3 = THEME.Dim
    empty.Font = Enum.Font.Gotham
    empty.TextSize = 12
    empty.TextXAlignment = Enum.TextXAlignment.Left
    empty.LayoutOrder = 40
    empty.Visible = false
    empty.ZIndex = 52
    empty.Parent = box
    table.insert(Painted, { inst = empty, prop = "TextColor3", key = "Dim" })

    ----------------------------------------------------------------------------
    -- coleta dos resultados
    ----------------------------------------------------------------------------
    local function Collect(q)
        local out = {}
        local function add(kind, label, hint, run)
            local score
            local low = tostring(label):lower()
            if q == "" then
                score = 2
            elseif low:sub(1, #q) == q then
                score = 0
            elseif low:find(q, 1, true) then
                score = 1
            elseif kind:find(q, 1, true) then
                score = 3
            end
            if score then
                table.insert(out, { kind = kind, label = label, hint = hint or "",
                                    run = run, score = score, i = #out })
            end
        end

        if V8.Sit then
            for _, n in ipairs(V8.Sit.Order) do
                local d = V8.Sit.Defs[n]
                add("situação", n, (d and d.desc or "")
                    .. (V8.Sit.Keys[n] and ("   [" .. KeyName(V8.Sit.Keys[n]) .. "]") or ""),
                    function() V8.Sit.Apply(n) end)
            end
        end

        for _, id in ipairs(ToggleOrder) do
            local t = Toggles[id]
            add("função", t.label or id,
                (IsOn(id) and "ligado" or "desligado")
                .. (Keybinds[id] and ("   [" .. KeyName(Keybinds[id]) .. "]") or ""),
                function() Flip(id) end)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            local nm = p.Name
            add("jogador", nm, "selecionar e abrir Players", function()
                if SelectPlayer then SelectPlayer(p) end
                ShowTab("Players")
            end)
        end

        for idx, w in ipairs(State.Waypoints) do
            add("waypoint", w.name or ("WP " .. idx), "teleportar", function()
                local wp = State.Waypoints[idx]
                if wp then
                    TeleportTo(wp.cframe)
                    Log("TP -> " .. (wp.name or idx), "ok")
                end
            end)
        end

        if V8.CmdNames then
            for _, n in ipairs(V8.CmdNames) do
                local c = V8.Commands and V8.Commands[n]
                add("comando", n, c and c.usage or "", function()
                    if c and c.usage and c.usage:find("<") then
                        if V8.OpenCmdBar then V8.OpenCmdBar(n .. " ") end
                    elseif V8.RunCommand then
                        V8.RunCommand(n)
                    end
                end)
            end
        end

        table.sort(out, function(a, b)
            if a.score ~= b.score then return a.score < b.score end
            return a.i < b.i
        end)
        return out
    end

    local function Paint2(i)
        local r = rows[i]
        local active = (i == sel)
        r.btn.BackgroundTransparency = active and 0 or 1
        r.label.TextColor3 = active and THEME.Accent or THEME.Text
    end

    local function Render()
        for i = 1, ROWS do
            local it = items[i]
            local r = rows[i]
            if it then
                r.btn.Visible = true
                r.kind.Text = it.kind:upper()
                r.label.Text = it.label
                r.hint.Text = it.hint
                Paint2(i)
            else
                r.btn.Visible = false
            end
        end
        empty.Visible = (#items == 0)
        empty.Text = (#items == 0) and "nada encontrado" or ""
        if #items > ROWS then
            hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha   •   "
                .. #items .. " resultados (mostrando " .. ROWS .. ")"
        else
            hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha"
        end
    end

    local function Refresh()
        local q = (input.Text or ""):lower():gsub("^%s+", "")
        items = Collect(q)
        sel = 1
        Render()
    end

    local function Move(d)
        if #items == 0 then return end
        sel = sel + d
        local cap = math.min(#items, ROWS)
        if sel < 1 then sel = cap end
        if sel > cap then sel = 1 end
        for i = 1, ROWS do
            if rows[i].btn.Visible then Paint2(i) end
        end
    end

    ----------------------------------------------------------------------------
    -- abrir / fechar / executar
    ----------------------------------------------------------------------------
    S.Close = function()
        Overlay.Visible = false
        pcall(function() input:ReleaseFocus() end)
    end

    S.Open = function()
        Overlay.Visible = true
        input.Text = ""
        Refresh()
        pcall(function() input:CaptureFocus() end)
    end

    S.Run = function()
        local it = items[sel]
        if not it then
            S.Close()
            return
        end
        S.Close()
        local ok, err = pcall(it.run)
        if not ok then Log("busca: " .. tostring(err), "error") end
    end

    dim.MouseButton1Click:Connect(function() S.Close() end)

    input:GetPropertyChangedSignal("Text"):Connect(function()
        if Overlay.Visible then pcall(Refresh) end
    end)

    input.FocusLost:Connect(function(enter)
        if not Overlay.Visible then return end
        if enter then S.Run() end
    end)

    Conn.SearchKeys = UserInputService.InputBegan:Connect(function(input2)
        if not Overlay.Visible then return end
        if input2.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local kc = input2.KeyCode
        if kc == Enum.KeyCode.Escape then
            S.Close()
        elseif kc == Enum.KeyCode.Down then
            Move(1)
        elseif kc == Enum.KeyCode.Up then
            Move(-1)
        end
    end)

    -- chamado pelo handler global de teclas (90_runtime/03_input.lua)
    S.HandleKey = function(input3)
        if input3.KeyCode ~= CONFIG.SearchKey then return false end
        if CONFIG.SearchCtrl then
            local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if not ctrl then return false end
        end
        if Overlay.Visible then S.Close() else S.Open() end
        return true
    end

    ----------------------------------------------------------------------------
    -- UI de configuração (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "BUSCA GLOBAL", 7)
        SubLabel(card, "Abre um campo que pesquisa situações, funções, jogadores, "
            .. "waypoints e comandos. Padrão: Ctrl+K.", -1)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundTransparency = 1
        row.LayoutOrder = 1
        row.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -110, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "Tecla da busca"
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        Paint(lbl, "TextColor3", "Text")

        local btn = Instance.new("TextButton")
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
        btn.Size = UDim2.new(0, 96, 0, 26)
        btn.BackgroundColor3 = THEME.Btn
        btn.Text = KeyName(CONFIG.SearchKey)
        btn.TextColor3 = THEME.Accent2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = row
        Paint(btn, "BackgroundColor3", "Btn")
        Paint(btn, "TextColor3", "Accent2")
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local st = Instance.new("UIStroke", btn)
        st.Transparency = 0.6
        Paint(st, "Color", "Accent")

        btn.MouseButton1Click:Connect(function()
            Drop("SearchCapture")
            capturing = "search"
            btn.Text = "aperte..."
            Toast("Aperte a tecla da busca global", nil, 3)
            Conn.SearchCapture = UserInputService.InputBegan:Connect(function(input4)
                if capturing ~= "search" then return end
                if input4.UserInputType ~= Enum.UserInputType.Keyboard then return end
                local kc = input4.KeyCode
                if kc == Enum.KeyCode.Unknown then return end
                if kc == Enum.KeyCode.LeftControl or kc == Enum.KeyCode.RightControl then return end
                Drop("SearchCapture")
                capturing = nil
                if kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey then
                    Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                else
                    CONFIG.SearchKey = kc
                    Log("Busca global = "
                        .. (CONFIG.SearchCtrl and "Ctrl+" or "") .. KeyName(kc), "ok")
                end
                btn.Text = KeyName(CONFIG.SearchKey)
            end)
        end)

        CheckRow(card, "Exigir Ctrl junto", "Desligue para abrir com a tecla sozinha",
            function() return CONFIG.SearchCtrl end,
            function(v) CONFIG.SearchCtrl = v end, 2)

        local open = CreateButton(card, "ABRIR A BUSCA AGORA", "Accent", 32)
        open.LayoutOrder = 3
        open.MouseButton1Click:Connect(function() S.Open() end)
    end
end
