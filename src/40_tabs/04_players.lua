--------------------------------------------------------------------------------
-- ABA PLAYERS
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Players")

    local head = CreateCard(tab, "JOGADORES", 1)
    local search = CreateInput(head, "Buscar por username ou display name...", 32)
    search.LayoutOrder = 1

    local countLbl = SubLabel(head, "", 2)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.LayoutOrder = 3
    list.Parent = head
    local listLayout = Instance.new("UIListLayout", list)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    PlayerRows = {}          -- [userId] = { frame=, player=, ... }
    local filter = ""

    local function Elapsed(sec)
        if not sec then return "—" end
        local m = math.floor(sec / 60)
        if m < 1 then return math.floor(sec) .. "s" end
        if m < 60 then return m .. "min" end
        return math.floor(m / 60) .. "h" .. (m % 60) .. "min"
    end

    local function Passes(p)
        if filter == "" then return true end
        return (p.Name:lower():find(filter, 1, true) ~= nil)
            or (p.DisplayName:lower():find(filter, 1, true) ~= nil)
    end

    -- v8.1: ESP de UM jogador. Marcar alguém liga o ESP (se estava desligado)
    -- só nos marcados; desmarcar o último devolve o ESP como estava.
    V8.EspPick = { auto = false }
    V8.EspPick.Flip = function(p)
        local pick = EspOpts.Pick
        if pick[p.UserId] then pick[p.UserId] = nil else pick[p.UserId] = true end
        local any = next(pick) ~= nil
        if any and not IsOn("esp") then
            SetToggle("esp", true, true)
            V8.EspPick.auto = true
        elseif not any and V8.EspPick.auto then
            V8.EspPick.auto = false
            SetToggle("esp", false, true)
        end
        Log((pick[p.UserId] and "ESP em " or "ESP removido de ") .. p.Name
            .. (any and "" or " — ESP volta a mostrar todos"), "action")
        if RefreshStatus then RefreshStatus() end
    end
    -- desligar o ESP por qualquer caminho limpa as marcações
    if Toggles.esp then
        table.insert(Toggles.esp.listeners, function(on)
            if on then return end
            for k in pairs(EspOpts.Pick) do EspOpts.Pick[k] = nil end
            V8.EspPick.auto = false
        end)
    end

    local function MakeRow(p)
        local row = Instance.new("Frame")
        row.Name = "Row_" .. p.UserId
        row.Size = UDim2.new(1, 0, 0, 62)
        row.BackgroundColor3 = THEME.Btn
        row.BorderSizePixel = 0
        row.Parent = list
        Paint(row, "BackgroundColor3", "Btn")
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", row)
        stroke.Transparency = 1
        Paint(stroke, "Color", "Accent")

        local av = Avatar(row, p.UserId, 40)
        av.Position = UDim2.new(0, 8, 0.5, -20)

        -- v8.1: 3 linhas à esquerda, 4 botões (2x2) à direita
        local function Line(y, h, font, size, key)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -206, 0, h)
            l.Position = UDim2.new(0, 56, 0, y)
            l.BackgroundTransparency = 1
            l.Text = ""
            l.TextColor3 = THEME[key]
            l.Font = font
            l.TextSize = size
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.Parent = row
            Paint(l, "TextColor3", key)
            return l
        end
        local dn = Line(7, 17, Enum.Font.GothamBold, 13, "Text")
        dn.Text = p.DisplayName .. (p == LocalPlayer and "   (você)" or "")
        local un = Line(24, 14, Enum.Font.Code, 11, "Dim")
        un.Text = "@" .. p.Name
        local hp = Line(40, 14, Enum.Font.Code, 10, "Success")
        hp.Size = UDim2.new(0, 72, 0, 14)
        local meta = Line(40, 14, Enum.Font.Code, 10, "Dim")
        meta.Position = UDim2.new(0, 132, 0, 40)
        meta.Size = UDim2.new(1, -282, 0, 14)

        local function Btn(text, key, x, y)
            local b = CreateButton(row, text, key, 24)
            b.Size = UDim2.new(0, 64, 0, 24)
            b.Position = UDim2.new(1, x, 0, y)
            b.TextSize = 11
            return b
        end
        local sel = Btn("ALVO", "Accent", -138, 6)
        sel.MouseButton1Click:Connect(function() SelectPlayer(p) end)

        local esp = Btn("ESP", "Success", -70, 6)
        esp.MouseButton1Click:Connect(function()
            V8.EspPick.Flip(p)
            UpdatePlayerRows()
        end)

        local tp = Btn("TP", "Success", -138, 33)
        tp.MouseButton1Click:Connect(function() Goto(p) end)

        local spec = Btn("SPEC", "Accent2", -70, 33)
        spec.MouseButton1Click:Connect(function()
            if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
            UpdatePlayerRows()
        end)

        if p == LocalPlayer then
            tp.Visible = false
            spec.Visible = false
            esp.Visible = false
        end

        local entry = { frame = row, player = p, meta = meta, hp = hp,
            stroke = stroke, select = sel, esp = esp, spec = spec }
        PlayerRows[p.UserId] = entry
        return entry
    end

    RebuildPlayerRows = function()
        -- remove linhas de quem saiu
        for id, e in pairs(PlayerRows) do
            if not e.player or not e.player.Parent then
                if e.frame then e.frame:Destroy() end
                PlayerRows[id] = nil
            end
        end
        -- cria linhas de quem chegou
        local shown, total = 0, 0
        for _, p in ipairs(Players:GetPlayers()) do
            total = total + 1
            local e = PlayerRows[p.UserId]
            if not e then e = MakeRow(p) end
            local pass = Passes(p)
            e.frame.Visible = pass
            if pass then
                shown = shown + 1
                e.frame.LayoutOrder = (p == LocalPlayer) and 0 or shown
            end
        end
        countLbl.Text = shown .. " de " .. total .. " jogador(es)"
            .. (filter ~= "" and "  ·  filtro: \"" .. filter .. "\"" or "")
    end

    UpdatePlayerRows = function()
        local myRoot = Root()
        for id, e in pairs(PlayerRows) do
            local p = e.player
            if not p or not p.Parent then
                if e.frame then e.frame:Destroy() end
                PlayerRows[id] = nil
            elseif e.frame.Visible then
                local char = p.Character
                local h = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if h then
                    local pct = h.MaxHealth > 0 and (h.Health / h.MaxHealth) or 0
                    e.hp.Text = math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth) .. " HP"
                    e.hp.TextColor3 = pct > 0.5 and THEME.Success
                        or (pct > 0.25 and THEME.Warning or THEME.Danger)
                else
                    e.hp.Text = "sem personagem"
                    e.hp.TextColor3 = THEME.Dim
                end

                local dist = "—"
                if myRoot and root then
                    dist = math.floor((myRoot.Position - root.Position).Magnitude) .. "m"
                end

                -- ping: o client só consegue ler o SEU ping. Dos outros não existe
                -- API client-side, então mostra "—" em vez de inventar número.
                local ping = "—"
                if p == LocalPlayer then
                    local ok, v = pcall(function()
                        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    if ok and v then ping = math.floor(v) .. "ms" end
                end

                local team = p.Team and p.Team.Name or "sem equipe"
                e.meta.Text = (p == LocalPlayer and ("ping " .. ping .. " · ") or "")
                    .. dist .. " · " .. team .. " · " .. Elapsed(State.JoinTimes[p.UserId]
                        and (os.clock() - State.JoinTimes[p.UserId]) or nil)

                local isSel = (State.SelectedPlayer == p)
                e.stroke.Transparency = isSel and 0.15 or 1
                e.select.Text = isSel and "É O ALVO" or "ALVO"
                e.esp.Text = EspOpts.Pick[p.UserId] and "ESP ON" or "ESP"
                e.spec.Text = (State.SpectateTarget == p) and "PARAR" or "SPEC"
            end
        end
    end

    SelectPlayer = function(p)
        if not p or not p.Parent then
            Toast("Jogador não está mais no servidor", "warn")
            return
        end
        State.SelectedPlayer = p
        Log("Selecionado: " .. p.Name .. " (" .. p.DisplayName .. ")", "action")
        if UpdateSelectedInfo then UpdateSelectedInfo() end
        UpdatePlayerRows()
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        filter = search.Text:lower()
        RebuildPlayerRows()
    end)

    OnTabOpen("Players", function()
        RebuildPlayerRows()
        UpdatePlayerRows()
    end)

    RebuildPlayerRows()
end
