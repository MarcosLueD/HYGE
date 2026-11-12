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

    local function MakeRow(p)
        local row = Instance.new("Frame")
        row.Name = "Row_" .. p.UserId
        row.Size = UDim2.new(1, 0, 0, 56)
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

        local dn = Instance.new("TextLabel")
        dn.Size = UDim2.new(1, -300, 0, 17)
        dn.Position = UDim2.new(0, 56, 0, 9)
        dn.BackgroundTransparency = 1
        dn.Text = p.DisplayName .. (p == LocalPlayer and "   (você)" or "")
        dn.TextColor3 = THEME.Text
        dn.Font = Enum.Font.GothamBold
        dn.TextSize = 13
        dn.TextXAlignment = Enum.TextXAlignment.Left
        dn.TextTruncate = Enum.TextTruncate.AtEnd
        dn.Parent = row
        Paint(dn, "TextColor3", "Text")

        local un = Instance.new("TextLabel")
        un.Size = UDim2.new(1, -300, 0, 14)
        un.Position = UDim2.new(0, 56, 0, 27)
        un.BackgroundTransparency = 1
        un.Text = "@" .. p.Name
        un.TextColor3 = THEME.Dim
        un.Font = Enum.Font.Code
        un.TextSize = 11
        un.TextXAlignment = Enum.TextXAlignment.Left
        un.Parent = row
        Paint(un, "TextColor3", "Dim")

        local meta = Instance.new("TextLabel")
        meta.AnchorPoint = Vector2.new(1, 0)
        meta.Size = UDim2.new(0, 240, 0, 14)
        meta.Position = UDim2.new(1, -150, 0, 41)
        meta.BackgroundTransparency = 1
        meta.Text = ""
        meta.TextColor3 = THEME.Dim
        meta.Font = Enum.Font.Code
        meta.TextSize = 10
        meta.TextXAlignment = Enum.TextXAlignment.Right
        meta.Parent = row
        Paint(meta, "TextColor3", "Dim")

        local hp = Instance.new("TextLabel")
        hp.AnchorPoint = Vector2.new(1, 0)
        hp.Size = UDim2.new(0, 240, 0, 16)
        hp.Position = UDim2.new(1, -150, 0, 10)
        hp.BackgroundTransparency = 1
        hp.Text = ""
        hp.TextColor3 = THEME.Success
        hp.Font = Enum.Font.Code
        hp.TextSize = 11
        hp.TextXAlignment = Enum.TextXAlignment.Right
        hp.Parent = row
        Paint(hp, "TextColor3", "Success")

        local sel = CreateButton(row, "SELECIONAR", "Accent", 24)
        sel.Size = UDim2.new(0, 88, 0, 24)
        sel.Position = UDim2.new(1, -140, 0, 8)
        sel.MouseButton1Click:Connect(function() SelectPlayer(p) end)

        local tp = CreateButton(row, "TP", "Success", 24)
        tp.Size = UDim2.new(0, 40, 0, 24)
        tp.Position = UDim2.new(1, -140, 0, 34)
        tp.MouseButton1Click:Connect(function() Goto(p) end)

        local spec = CreateButton(row, "SPECTATE", "Accent2", 24)
        spec.Size = UDim2.new(0, 44, 0, 24)
        spec.Position = UDim2.new(1, -96, 0, 34)
        spec.Text = "OLHAR"
        spec.MouseButton1Click:Connect(function()
            if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
        end)

        if p == LocalPlayer then
            tp.Visible = false
            spec.Visible = false
        end

        local entry = { frame = row, player = p, meta = meta, hp = hp,
            stroke = stroke, select = sel }
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
                    e.hp.Text = math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth) .. " HP"
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
                e.meta.Text = "ping " .. ping .. "  ·  " .. dist .. "  ·  " .. team
                    .. "  ·  " .. Elapsed(State.JoinTimes[p.UserId]
                        and (os.clock() - State.JoinTimes[p.UserId]) or nil)

                local isSel = (State.SelectedPlayer == p)
                e.stroke.Transparency = isSel and 0.15 or 1
                e.select.Text = isSel and "SELECIONADO" or "SELECIONAR"
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
