--------------------------------------------------------------------------------
-- v8.1 — INÍCIO: MAPA ATUAL + PERFIL
-- Mapa: nome do jogo, Place ID, Job ID e jogadores, com os botões rápidos
-- REJOIN (volta para este servidor), TROCAR SERVIDOR (outro servidor público
-- com vaga) e DISCORD (copia CONFIG.Discord).
-- Perfil: tempo de jogo (V8.Play, o mesmo que vira ponto na Playtime Shop),
-- sessão, pontos e idade da conta; o rank/título/ícone equipados aparecem
-- também no cartão do avatar.
-- Entra DEPOIS de 01_home_dashboard.lua (usa V8.Dash). Zero locais novos.
--------------------------------------------------------------------------------
do
    local function Build()
        local home = Tabs.Home
        local P = V8.Play
        V8.Hop = { busy = false }
        local H = V8.Hop

        ----------------------------------------------------------------------------
        -- ações
        ----------------------------------------------------------------------------
        H.Rejoin = function()
            if game.JobId == "" then
                Toast("Rejoin não funciona no Studio", "warn", 2)
                return
            end
            Log("Rejoin: voltando para este servidor...", "action")
            Toast("Reconectando...", nil, 3)
            local ok, err = pcall(function()
                if #Players:GetPlayers() <= 1 then
                    -- sozinho, este servidor fecha quando você sai: vai para um novo
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
            if not ok then
                Log("Rejoin falhou: " .. tostring(err), "error")
                Toast("Rejoin falhou", "error")
            end
        end

        -- lista pública de servidores (API do Roblox, pelo HTTP do executor).
        -- Sem HTTP: Teleport comum — o Roblox escolhe e pode cair no mesmo.
        H.Hop = function()
            if H.busy then
                Toast("Já estou procurando um servidor...", "warn", 2)
                return
            end
            if game.JobId == "" then
                Toast("Trocar de servidor não funciona no Studio", "warn", 2)
                return
            end
            H.busy = true
            Toast("Procurando outro servidor...", nil, 3)
            task.spawn(function()
                local base = "https://games.roblox.com/v1/games/" .. game.PlaceId
                    .. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"
                local pool, cursor, lastErr = {}, nil, nil
                for _ = 1, 3 do
                    local url = base .. (cursor and ("&cursor=" .. V8.Net.Encode(cursor)) or "")
                    local data, err = V8.Net.Json("GET", url)
                    if not data then
                        lastErr = err
                        break
                    end
                    for _, s in ipairs(type(data.data) == "table" and data.data or {}) do
                        local playing, maxp = tonumber(s.playing), tonumber(s.maxPlayers)
                        if type(s.id) == "string" and s.id ~= game.JobId
                            and playing and maxp and playing < maxp then
                            table.insert(pool, s)
                        end
                    end
                    cursor = data.nextPageCursor
                    if #pool >= 8 or type(cursor) ~= "string" then break end
                end
                local ok, err = pcall(function()
                    if #pool > 0 then
                        local s = pool[math.random(1, #pool)]
                        Log("Trocando de servidor (" .. tostring(s.playing) .. "/"
                            .. tostring(s.maxPlayers) .. " jogadores)", "action")
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    else
                        Log("Sem lista de servidores (" .. tostring(lastErr or "nenhum outro com vaga")
                            .. ") — o Roblox escolhe o servidor e pode ser este mesmo", "warn")
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end
                end)
                if not ok then
                    Log("Troca de servidor falhou: " .. tostring(err), "error")
                    Toast("Troca de servidor falhou", "error")
                    H.busy = false
                    return
                end
                task.delay(10, function() H.busy = false end)
            end)
        end

        H.Discord = function()
            local link = tostring(CONFIG.Discord or "")
            if link == "" then
                Log("Nenhum convite do Discord configurado: preencha CONFIG.Discord "
                    .. "no topo do script", "warn")
                Toast("Sem link do Discord (CONFIG.Discord)", "warn", 3)
                return
            end
            Copy(link, "Link do Discord")
        end

        Conn.TpFail = TeleportService.TeleportInitFailed:Connect(function(player, _, msg)
            if player ~= LocalPlayer then return end
            H.busy = false
            Log("Teleporte recusado pelo Roblox: " .. tostring(msg), "error")
            Toast("Teleporte falhou", "error", 3)
        end)

        ----------------------------------------------------------------------------
        -- card MAPA ATUAL
        ----------------------------------------------------------------------------
        local map = CreateCard(home, "MAPA ATUAL", 0)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 66)
        row.LayoutOrder = 1
        row.Parent = map
        V8.Cell(row, 0)

        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(0, 46, 0, 46)
        thumb.Position = UDim2.new(0, 0, 0.5, -23)
        thumb.BackgroundColor3 = THEME.Track
        thumb.BorderSizePixel = 0
        thumb.Image = "rbxthumb://type=Asset&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
        thumb.Parent = row
        Paint(thumb, "BackgroundColor3", "Track")
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 10)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -58, 0, 20)
        nameLbl.Position = UDim2.new(0, 58, 0, 9)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = "Carregando o nome do jogo..."
        nameLbl.TextColor3 = THEME.Text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 15
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row
        Paint(nameLbl, "TextColor3", "Text")

        local idLbl = Instance.new("TextLabel")
        idLbl.Size = UDim2.new(1, -58, 0, 14)
        idLbl.Position = UDim2.new(0, 58, 0, 30)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = ""
        idLbl.TextColor3 = THEME.Dim
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 11
        idLbl.TextXAlignment = Enum.TextXAlignment.Left
        idLbl.TextTruncate = Enum.TextTruncate.AtEnd
        idLbl.Parent = row
        Paint(idLbl, "TextColor3", "Dim")

        local countLbl = Instance.new("TextLabel")
        countLbl.Size = UDim2.new(1, -58, 0, 14)
        countLbl.Position = UDim2.new(0, 58, 0, 45)
        countLbl.BackgroundTransparency = 1
        countLbl.Text = ""
        countLbl.TextColor3 = THEME.Accent2
        countLbl.Font = Enum.Font.GothamBold
        countLbl.TextSize = 11
        countLbl.TextXAlignment = Enum.TextXAlignment.Left
        countLbl.Parent = row
        Paint(countLbl, "TextColor3", "Accent2")

        task.spawn(function()
            local ok, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            if ok and type(info) == "table" and info.Name then
                nameLbl.Text = tostring(info.Name)
            else
                nameLbl.Text = "Jogo " .. tostring(game.PlaceId)
            end
        end)

        local btns = Grid(map, 3, 34)
        btns.LayoutOrder = 2

        local bRejoin = CreateButton(btns, "REJOIN", "Warning", 34)
        bRejoin.LayoutOrder = 1
        bRejoin.MouseButton1Click:Connect(function()
            Confirm("Sair e voltar para ESTE mesmo servidor?", H.Rejoin)
        end)

        local bHop = CreateButton(btns, "TROCAR SERVIDOR", "Accent", 34)
        bHop.LayoutOrder = 2
        bHop.MouseButton1Click:Connect(function()
            Confirm("Sair deste servidor e entrar em outro do mesmo jogo?", H.Hop)
        end)

        local bDisc = CreateButton(btns, "DISCORD", "Accent2", 34)
        bDisc.LayoutOrder = 3
        bDisc.MouseButton1Click:Connect(H.Discord)

        ----------------------------------------------------------------------------
        -- card PERFIL
        ----------------------------------------------------------------------------
        local prof = CreateCard(home, "PERFIL", 1)
        local tiles = Grid(prof, 2, 48)
        tiles.LayoutOrder = 1
        local T = {}
        T.total   = StatTile(tiles, "TEMPO DE JOGO (HYGE)", "—", 1, "Accent2")
        T.session = StatTile(tiles, "ESTA SESSÃO", "—", 2)
        T.points  = StatTile(tiles, "PONTOS DA LOJA", "—", 3, "Success")
        T.age     = StatTile(tiles, "IDADE DA CONTA", "—", 4)

        local equipLbl = SubLabel(prof, "", 2)

        ----------------------------------------------- rank/título no avatar
        local me = V8.Dash and V8.Dash.NameRow and V8.Dash.NameRow.Parent
        local line
        if me then
            line = Instance.new("TextLabel")
            line.Size = UDim2.new(1, -20, 0, 14)
            line.Position = UDim2.new(0, 10, 0, 176)
            line.BackgroundTransparency = 1
            line.Text = ""
            line.TextColor3 = THEME.Accent2
            line.Font = Enum.Font.GothamBold
            line.TextSize = 11
            line.TextTruncate = Enum.TextTruncate.AtEnd
            line.Parent = me
            Paint(line, "TextColor3", "Accent2")
        end
        local icon   -- ícone comprado, ao lado do nome

        local function Profile()
            local eq = P.Line()
            local rank = P.Equipped("rank")
            if line then
                line.Text = (eq ~= "" and (eq .. "  ·  ") or "") .. P.Fmt(P.Total) .. " jogadas"
                line.TextColor3 = (rank and rank.color) or THEME.Accent2
            end
            local ic = P.Equipped("icon")
            if icon then icon:Destroy() icon = nil end
            if ic and V8.Dash and V8.Dash.NameRow then
                icon = Icon(V8.Dash.NameRow, ic.icon, (rank and rank.color) or THEME.Accent, 16, 0)
            end
            equipLbl.Text = (eq ~= "" and ("Equipado: " .. eq .. ".  ") or "Nada equipado.  ")
                .. "Rank, ícone e título se compram com tempo de jogo na Playtime Shop."
        end

        local function Tick()
            T.total.Text = P.Fmt(P.Total)
            T.session.Text = P.Fmt(P.Session())
            T.points.Text = tostring(P.Points())
            T.age.Text = tostring(LocalPlayer.AccountAge or 0) .. " dias"
            idLbl.Text = "Place " .. tostring(game.PlaceId) .. "   ·   Job "
                .. (game.JobId ~= "" and game.JobId or "estúdio")
            countLbl.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " jogadores no servidor"
            if line then
                local eq = P.Line()
                line.Text = (eq ~= "" and (eq .. "  ·  ") or "") .. P.Fmt(P.Total) .. " jogadas"
            end
        end

        P.OnChange(function() pcall(Profile) pcall(Tick) end)
        V8.TabTick.Home = Tick
        OnTabOpen("Home", function() pcall(Tick) end)
        pcall(Profile)
        pcall(Tick)
    end
    Build()
end
