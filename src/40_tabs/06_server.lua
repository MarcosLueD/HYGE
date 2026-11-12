--------------------------------------------------------------------------------
-- ABA SERVER
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Server")
    serverStart = os.time()

    local card = CreateCard(tab, "SERVIDOR", 1)
    local grid = Grid(card, 3, 48)
    local S = {}

    local function T(key, label, def, colorKey)
        S[key] = StatTile(grid, label, def, #grid:GetChildren(), colorKey)
    end

    T("place",   "PLACE ID",   tostring(game.PlaceId))
    T("job",     "JOB ID",     "—")
    T("players", "JOGADORES",  "—")
    T("max",     "MAX PLAYERS", tostring(Players.MaxPlayers))
    T("fps",     "FPS",        "—", "Success")
    T("ping",    "SEU PING",   "—", "Accent2")
    T("mem",     "MEMÓRIA",    "—", "Warning")
    T("uptime",  "SESSÃO",     "—")
    T("name",    "SEU NOME",   LocalPlayer.Name)

    local acts = Grid(card, 3, 32)
    acts.LayoutOrder = 5

    local cJob = CreateButton(acts, "COPIAR JOB ID", "Accent", 32)
    cJob.LayoutOrder = 1
    cJob.MouseButton1Click:Connect(function()
        if game.JobId == "" then
            Toast("Sem JobId (rodando no Studio)", "warn", 2)
            return
        end
        Copy(game.JobId, "JobId")
    end)

    local rejoin = CreateButton(acts, "REJOIN", "Warning", 32)
    rejoin.LayoutOrder = 2
    rejoin.MouseButton1Click:Connect(function()
        Confirm("Sair e voltar para ESTE mesmo servidor?", function()
            if game.JobId == "" then
                Toast("Rejoin não funciona no Studio", "warn", 2)
                return
            end
            Log("Rejoin solicitado", "action")
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
            if not ok then
                Log("Rejoin falhou: " .. tostring(err), "error")
                Toast("Rejoin falhou", "error")
            end
        end)
    end)

    local refresh = CreateButton(acts, "ATUALIZAR", "Success", 32)
    refresh.LayoutOrder = 3
    refresh.MouseButton1Click:Connect(function()
        UpdateServerInfo()
        Log("Dados do servidor atualizados", "ok")
    end)

    ----------------------------------------------------------------------------
    -- REMOTES
    ----------------------------------------------------------------------------
    local rc = CreateCard(tab, "REMOTES (FUNÇÕES SERVER-SIDE)", 2)
    SubLabel(rc, "O painel é client-side. Tudo que muda o jogo para os outros "
        .. "precisa de um RemoteEvent em ReplicatedStorage COM validação de admin "
        .. "no servidor. Sem o Remote a ação fica indisponível.", -1)

    -- v8.0: lê o catálogo único (V8.RemoteInfo) — os 13 Remotes, por grupo
    do
        local have, total = V8.RemoteStatus()
        local resumo = SubLabel(rc, have .. " de " .. total .. " Remotes encontrados"
            .. (have < total and "  ·  o script pronto está em server/ (veja o README)" or ""), 0)
        resumo.TextColor3 = (have == total) and THEME.Success or THEME.Warning
    end

    local rGrid = Grid(rc, 1, 22)
    rGrid.LayoutOrder = 1
    local lastGroup
    for i, item in ipairs(V8.RemoteInfo) do
        local key, remoteName, what, group = item[1], item[2], item[3], item[4]
        if group ~= lastGroup then
            lastGroup = group
            local g = Instance.new("TextLabel")
            g.Size = UDim2.new(1, 0, 0, 22)
            g.BackgroundTransparency = 1
            g.Text = "  " .. group:upper()
            g.TextColor3 = THEME.Accent
            g.Font = Enum.Font.GothamBold
            g.TextSize = 10
            g.TextXAlignment = Enum.TextXAlignment.Left
            g.TextYAlignment = Enum.TextYAlignment.Bottom
            g.LayoutOrder = i * 2 - 1
            g.Parent = rGrid
            Paint(g, "TextColor3", "Accent")
        end
        local found = Remotes[key] ~= nil
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.Text = (found and "  [OK]      " or "  [AUSENTE] ") .. remoteName
            .. "   —   " .. what
        l.TextColor3 = found and THEME.Success or THEME.Dim
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = i * 2
        l.Parent = rGrid
        Paint(l, "TextColor3", found and "Success" or "Dim")
    end

    ----------------------------------------------------------------------------
    UpdateServerInfo = function()
        S.job.Text = game.JobId ~= "" and (game.JobId:sub(1, 10) .. "…") or "estúdio"
        S.players.Text = tostring(#Players:GetPlayers())
        S.max.Text = tostring(Players.MaxPlayers)
        S.fps.Text = tostring(State.Fps)
        S.ping.Text = math.floor(LocalPlayer:GetNetworkPing() * 2000) .. "ms"

        local ok, mb = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
        S.mem.Text = ok and (math.floor(mb) .. " MB") or "—"

        local secs = os.time() - (serverStart or os.time())
        S.uptime.Text = math.floor(secs / 60) .. "min " .. (secs % 60) .. "s"
        S.name.Text = LocalPlayer.Name
    end

    OnTabOpen("Server", UpdateServerInfo)
    UpdateServerInfo()
end
