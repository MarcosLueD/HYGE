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
    -- v9.2: INTEGRAÇÃO COM O SERVIDOR
    -- O painel é client-side. Tudo que muda o jogo para os outros é PEDIDO ao
    -- script de servidor (server/), que valida e responde. Aqui: se ele está
    -- instalado, o seu cargo lá e o que cada ação precisa.
    ----------------------------------------------------------------------------
    local rc = CreateCard(tab, "INTEGRAÇÃO COM O SERVIDOR", 2)
    SubLabel(rc, "Ações que mexem em outros jogadores são pedidas ao script de servidor do "
        .. "HYGE por RemoteEvents, e ele decide: confere o seu cargo, a permissão da ação, o "
        .. "alvo, os argumentos e o limite de uso. O que aparece aqui é só o que o servidor "
        .. "informou — cada pedido é conferido de novo lá.", -1)
    local resumo = SubLabel(rc, "", 0)

    local acts2 = Grid(rc, 2, 30)
    acts2.LayoutOrder = 1
    local recheck = CreateButton(acts2, "RECONFERIR SERVIDOR", "Accent", 30)
    recheck.LayoutOrder = 1
    recheck.MouseButton1Click:Connect(function()
        V8.Srv.Refresh()
        Log("Servidor: " .. (V8.Srv.Summary()), "action")
    end)
    local myId = CreateButton(acts2, "COPIAR MEU USERID", "Accent2", 30)
    myId.LayoutOrder = 2
    myId.MouseButton1Click:Connect(function()
        Copy(tostring(LocalPlayer.UserId), "Seu UserId (para o CONFIG.AdminIds do servidor)")
    end)

    -- v8.0: lê o catálogo único (V8.RemoteInfo) — os 13 Remotes, por grupo
    local rGrid = Grid(rc, 1, 22)
    rGrid.LayoutOrder = 2
    local rows = {}
    local lastGroup
    for i, item in ipairs(V8.RemoteInfo) do
        local group = item[4]
        if group ~= lastGroup then
            lastGroup = group
            local g = Instance.new("TextLabel")
            g.Size = UDim2.new(1, 0, 0, 22)
            g.BackgroundTransparency = 1
            g.Text = "  " .. group:upper() .. "  ·  SERVIDOR"
            g.TextColor3 = THEME.Accent
            g.Font = Enum.Font.GothamBold
            g.TextSize = 10
            g.TextXAlignment = Enum.TextXAlignment.Left
            g.TextYAlignment = Enum.TextYAlignment.Bottom
            g.LayoutOrder = i * 2 - 1
            g.Parent = rGrid
            Paint(g, "TextColor3", "Accent")
        end
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.TextColor3 = THEME.Dim
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.LayoutOrder = i * 2
        l.Parent = rGrid
        rows[i] = l
    end

    -- [LIBERADA] o servidor confirmou que o seu cargo pode · [SEM PERMISSÃO]
    -- · [NÃO É ADMIN] · [AUSENTE] o Remote não existe · [ENCONTRADO] existe,
    -- sem confirmação. (Rótulos fixos: string.upper não conhece acento.)
    local TAGS = {
        ["sem servidor"]  = { "[AUSENTE]       ", "Dim" },
        ["não é admin"]   = { "[NÃO É ADMIN]   ", "Danger" },
        ["sem permissão"] = { "[SEM PERMISSÃO] ", "Warning" },
    }
    local function Render()
        local txt, color = V8.Srv.Summary()
        resumo.Text = "Servidor: " .. txt
        resumo.TextColor3 = THEME[color] or THEME.Dim
        for i, item in ipairs(V8.RemoteInfo) do
            local key, remoteName, what = item[1], item[2], item[3]
            local short = V8.Srv.Short(key)
            local tag, c
            if short then
                local t = TAGS[short] or TAGS["sem permissão"]
                tag, c = t[1], t[2]
            elseif V8.Srv.State == "ok" then tag, c = "[LIBERADA]      ", "Success"
            else tag, c = "[ENCONTRADO]    ", "Text" end
            rows[i].Text = "  " .. tag .. " " .. remoteName .. "   —   " .. what
            rows[i].TextColor3 = THEME[c] or THEME.Dim
        end
    end
    V8.Srv.OnChange(Render)
    Render()

    ----------------------------------------------------------------------------
    -- v9.2: O QUE FUNCIONA ONDE
    ----------------------------------------------------------------------------
    local where = CreateCard(tab, "O QUE FUNCIONA ONDE", 3)
    local lw = SubLabel(where, "LOCAL — roda no seu cliente, em qualquer jogo, sem instalar nada:\n"
        .. "  Fly, Noclip, God, Invisível, WalkSpeed/JumpPower, Anti-Fall, Anti-Gravidade, "
        .. "Walk on Walls, Ctrl+clique TP, waypoints, ESP, Freecam, Drone, Spectate, Fullbright, "
        .. "Chat Spy, emotes e pacotes de animação, Teleportar até (sem o servidor), falar no chat, "
        .. "Fake Kick/Ban (só na sua tela) e todas as Configurações.\n"
        .. "  (O que muda o SEU personagem os outros veem; ESP, Freecam, Fullbright e efeitos, só você.)", 1)
    lw.TextColor3 = THEME.Accent2
    local sw = SubLabel(where, "SERVIDOR — exige server/HYGE_AdminServer.server.lua instalado no "
        .. "Roblox Studio deste jogo:\n"
        .. "  Kick, Bring, Freeze/Unfreeze, Ir até (pelo servidor), Anúncio, Mensagem privada, "
        .. "Fling, Spin, Trip, Launch, Force Sit, Scale e Balloon.\n"
        .. "  Sem o servidor esses botões mostram (sem servidor) e explicam o motivo — nada é "
        .. "simulado na sua tela.", 2)
    sw.TextColor3 = THEME.Warning

    ----------------------------------------------------------------------------
    -- v9.2: INSTALAR NO SEU JOGO (o passo a passo completo: docs/SERVIDOR.md)
    ----------------------------------------------------------------------------
    local inst = CreateCard(tab, "INSTALAR NO SEU JOGO (ROBLOX STUDIO)", 4)
    SubLabel(inst, "1. ServerScriptService › Script (comum) › cole server/HYGE_AdminServer.server.lua.\n"
        .. "2. StarterPlayer › StarterPlayerScripts › LocalScript › cole "
        .. "server/HYGE_AdminClient.client.lua (mostra anúncios e privados para todos).\n"
        .. "3. No topo do script de servidor: o seu UserId (" .. LocalPlayer.UserId .. ") em "
        .. "CONFIG.AdminIds; moderadores em CONFIG.ModIds; o que cada cargo pode em "
        .. "CONFIG.Permissions.\n"
        .. "4. Game Settings › Security: nada a ligar (RemoteEvents não precisam de HTTP).\n"
        .. "5. Opcional: o painel no próprio jogo — LocalScript HYGE_Panel em ServerStorage com o "
        .. "main.lua; o servidor entrega só para quem tem cargo. NUNCA ponha o main.lua em "
        .. "StarterPlayerScripts: todo jogador receberia o painel.\n"
        .. "6. Publique e teste (Test › Clients and Servers). Passo a passo: docs/SERVIDOR.md.", 1)

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
