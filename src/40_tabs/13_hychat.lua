--------------------------------------------------------------------------------
-- v8.1 — CHAT HYGE (Chat › HYGE)
-- Conversa entre quem usa o HYGE: sala "Este servidor" (mesmo JobId) e sala
-- "Global" (todos os servidores). Dois clientes Roblox não falam direto um
-- com o outro, então as mensagens passam por um relay HTTP — o servidor
-- pequeno em server/chat-relay (Node, sem dependências; veja o README).
-- Sem relay configurado (CONFIG.ChatRelay ou o campo da aba) o chat fica
-- desligado e diz isso; nenhuma mensagem é inventada.
--
-- Precisa do HTTP do executor: request() para enviar; para só ler, também
-- serve game:HttpGet. Nomes vêm do próprio cliente e o relay NÃO os verifica.
-- Texto recebido é sempre escapado antes de ir para a tela (RichText).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("HyChat")
        if SET.ChatRelay == nil then SET.ChatRelay = "" end
        if SET.ChatOn == nil then SET.ChatOn = true end
        if SET.ChatToasts == nil then SET.ChatToasts = true end

        local CH = {
            Room = "server", Seq = 0, Boot = nil, Busy = false, Loaded = false,
            Msgs = { server = {}, global = {} }, Here = {}, Online = 0,
            Last = -math.huge, Err = nil, Max = 80,
        }
        V8.HyChat = CH
        local Enc = function(s) return V8.Net.Encode(s) end

        CH.Url = function()
            local u = tostring((SET.ChatRelay ~= "" and SET.ChatRelay) or CONFIG.ChatRelay or "")
            u = u:gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+$", "")
            if u ~= "" and not u:match("^https?://") then u = "https://" .. u end
            return u
        end
        CH.Job = function() return game.JobId ~= "" and game.JobId or "studio" end
        CH.Tag = function() return (V8.Play and V8.Play.Line()) or "" end

        local function Esc(s)
            return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
                :gsub("\"", "&quot;"):gsub("'", "&apos;"))
        end
        local function Hex(c)
            return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5),
                math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
        end

        ----------------------------------------------------------------------------
        -- CONVERSA
        ----------------------------------------------------------------------------
        local talk = CreateCard(tab, "CONVERSA", 1)

        local pills = Grid(talk, 2, 30)
        pills.LayoutOrder = 1
        local pillBtns = {}

        local status = SubLabel(talk, "", 2)

        local inRow = Instance.new("Frame")
        inRow.Size = UDim2.new(1, 0, 0, 34)
        inRow.BackgroundTransparency = 1
        inRow.LayoutOrder = 3
        inRow.Parent = talk

        local box = CreateInput(inRow, "Mensagem para os usuários HYGE...", 34)
        box.Size = UDim2.new(1, -100, 0, 34)

        local send = CreateButton(inRow, "ENVIAR", "Accent", 34)
        send.AnchorPoint = Vector2.new(1, 0)
        send.Position = UDim2.new(1, 0, 0, 0)
        send.Size = UDim2.new(0, 92, 0, 34)

        local feed = Instance.new("Frame")
        feed.Size = UDim2.new(1, 0, 0, 0)
        feed.AutomaticSize = Enum.AutomaticSize.Y
        feed.BackgroundTransparency = 1
        feed.LayoutOrder = 4
        feed.Parent = talk
        do
            local l = Instance.new("UIListLayout", feed)
            l.Padding = UDim.new(0, 4)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        local empty = SubLabel(talk, "", 5)

        local function PaintPills()
            for room, b in pairs(pillBtns) do
                local on = (room == CH.Room)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        CH.AddLine = function(m)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, 0)
            l.AutomaticSize = Enum.AutomaticSize.Y
            l.BackgroundTransparency = 1
            l.RichText = true
            local mine = (m.uid == LocalPlayer.UserId)
            local who = (m.tag ~= "" and ("[" .. m.tag .. "] ") or "") .. m.name
            l.Text = "<font color=\"" .. Hex(THEME.Dim) .. "\">" .. os.date("%H:%M", m.t)
                .. "</font>  <b><font color=\"" .. Hex(mine and THEME.Accent2 or THEME.Accent)
                .. "\">" .. Esc(who) .. "</font></b>:  " .. Esc(m.text)
            l.TextColor3 = THEME.Text
            l.Font = Enum.Font.Gotham
            l.TextSize = 12
            l.TextWrapped = true
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.LayoutOrder = -(m.seq or 0)   -- mais nova em cima
            l.Parent = feed
            -- guarda só as últimas CH.Max linhas na tela
            local lines = {}
            for _, c in ipairs(feed:GetChildren()) do
                if c:IsA("TextLabel") then table.insert(lines, c) end
            end
            if #lines > CH.Max then
                table.sort(lines, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
                for i = 1, #lines - CH.Max do lines[i]:Destroy() end
            end
            empty.Visible = false
        end

        CH.RenderFeed = function()
            for _, c in ipairs(feed:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end
            local msgs = CH.Msgs[CH.Room]
            for _, m in ipairs(msgs) do CH.AddLine(m) end
            empty.Visible = (#msgs == 0)
            empty.Text = (CH.Url() == "") and ""
                or (CH.Room == "server" and "Ninguém escreveu neste servidor ainda."
                    or "Nenhuma mensagem global ainda.")
        end

        CH.RenderStatus = function()
            local url = CH.Url()
            if url == "" then
                status.Text = "Desligado: nenhum servidor de chat configurado. Cole o endereço "
                    .. "do relay em Conexão, abaixo (o relay está em server/chat-relay — README)."
                status.TextColor3 = THEME.Warning
                return
            end
            if SET.ChatOn == false then
                status.Text = "Pausado (Conexão › Conectar ao chat HYGE)."
                status.TextColor3 = THEME.Dim
                return
            end
            if CH.Err then
                status.Text = "Sem conexão com o relay: " .. CH.Err .. " — tentando de novo."
                status.TextColor3 = THEME.Danger
                return
            end
            if not CH.Loaded then
                status.Text = "Conectando em " .. url .. "..."
                status.TextColor3 = THEME.Dim
                return
            end
            local names = {}
            for _, u in ipairs(CH.Here) do
                if type(u) == "table" and tonumber(u.uid) ~= LocalPlayer.UserId then
                    table.insert(names, tostring(u.name or "?"):sub(1, 40))
                end
            end
            status.Text = "Conectado  ·  " .. (#names + 1) .. " com HYGE neste servidor"
                .. (#names > 0 and (" (" .. table.concat(names, ", ") .. " e você)") or " (só você)")
                .. "  ·  " .. CH.Online .. " no total"
                .. (V8.Net.CanPost() and "" or "  ·  seu executor só LÊ (sem request())")
            status.TextColor3 = THEME.Success
        end

        ----------------------------------------------------------------------------
        -- rede
        ----------------------------------------------------------------------------
        CH.Poll = function()
            if CH.Busy then return end
            local url = CH.Url()
            if url == "" or SET.ChatOn == false then return end
            CH.Busy = true
            CH.Last = os.clock()
            task.spawn(function()
                local q = "/v1/poll?job=" .. Enc(CH.Job()) .. "&after=" .. CH.Seq
                    .. "&uid=" .. LocalPlayer.UserId .. "&name=" .. Enc(LocalPlayer.DisplayName)
                    .. "&tag=" .. Enc(CH.Tag()) .. "&place=" .. game.PlaceId
                    .. ((CONFIG.ChatKey or "") ~= "" and ("&key=" .. Enc(CONFIG.ChatKey)) or "")
                local data, err = V8.Net.Json("GET", url .. q)
                CH.Busy = false
                if not data or data.ok ~= true then
                    local why = err or tostring(data and data.error or "resposta inválida")
                    if CH.Err ~= why then Log("Chat HYGE: " .. why, "warn") end
                    CH.Err = why
                    pcall(CH.RenderStatus)
                    return
                end
                if CH.Err then Log("Chat HYGE: conectado de novo", "ok") end
                CH.Err = nil

                -- relay reiniciou: a numeração recomeça, então a lista também
                if data.boot ~= nil and CH.Boot ~= nil and data.boot ~= CH.Boot then
                    CH.Boot = data.boot
                    CH.Seq = 0
                    CH.Msgs.server, CH.Msgs.global = {}, {}
                    pcall(CH.RenderFeed)
                    CH.Last = -math.huge   -- busca o histórico no próximo segundo
                    return
                end
                CH.Boot = data.boot

                local fresh
                for _, m in ipairs(type(data.messages) == "table" and data.messages or {}) do
                    local seq = tonumber(m.seq)
                    if seq and seq > CH.Seq then
                        CH.Seq = seq
                        local room = (m.room == "global") and "global" or "server"
                        local msg = {
                            seq = seq, room = room, uid = tonumber(m.uid),
                            name = tostring(m.name or "?"):sub(1, 40),
                            tag = tostring(m.tag or ""):sub(1, 40),
                            text = tostring(m.text or ""):sub(1, 200),
                            t = tonumber(m.t) or os.time(),
                        }
                        local list = CH.Msgs[room]
                        table.insert(list, msg)
                        while #list > CH.Max do table.remove(list, 1) end
                        if room == CH.Room then pcall(CH.AddLine, msg) end
                        if msg.uid ~= LocalPlayer.UserId then fresh = msg end
                    end
                end
                CH.Here = type(data.here) == "table" and data.here or {}
                CH.Online = tonumber(data.online) or 0

                -- aviso de mensagem nova (não no histórico da primeira leitura)
                local viewing = V8.IsOpen and V8.IsOpen() and State.ActiveTab == "HyChat"
                if fresh and CH.Loaded and SET.ChatToasts and not viewing then
                    Toast("HYGE " .. (fresh.room == "global" and "global" or "servidor")
                        .. " · " .. fresh.name .. ": " .. fresh.text, nil, 4)
                end
                CH.Loaded = true
                pcall(CH.RenderStatus)
                if #CH.Msgs[CH.Room] == 0 then pcall(CH.RenderFeed) end
            end)
        end

        CH.Send = function()
            local text = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then
                Toast("Escreva a mensagem primeiro", "warn", 1.6)
                return
            end
            local url = CH.Url()
            if url == "" then
                Toast("Configure o servidor do chat em Conexão", "warn", 3)
                return
            end
            if not V8.Net.CanPost() then
                Log("Chat HYGE: este executor não expõe request() — dá para ler, não "
                    .. "para enviar", "error")
                Toast("Executor sem request(): não dá para enviar", "error", 3)
                return
            end
            if #text > 200 then text = text:sub(1, 200) end
            box.Text = ""
            local room = CH.Room
            task.spawn(function()
                local data, err = V8.Net.Json("POST", url .. "/v1/send", {
                    key = CONFIG.ChatKey or "", uid = LocalPlayer.UserId,
                    name = LocalPlayer.DisplayName, tag = CH.Tag(), job = CH.Job(),
                    place = game.PlaceId, room = room, text = text,
                })
                if not data or data.ok ~= true then
                    local why = err or tostring(data and data.error or "resposta inválida")
                    Log("Chat HYGE: mensagem NÃO enviada — " .. why, "error")
                    Toast("Mensagem não enviada", "error", 3)
                    return
                end
                -- a própria mensagem volta pelo poll: é a confirmação real
                CH.Last = -math.huge
            end)
        end

        send.MouseButton1Click:Connect(CH.Send)
        box.FocusLost:Connect(function(enter) if enter then CH.Send() end end)

        for i, r in ipairs({ { "server", "ESTE SERVIDOR" }, { "global", "GLOBAL" } }) do
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = THEME.Btn
            b.Text = r[2]
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = pills
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
            pillBtns[r[1]] = b
            b.MouseButton1Click:Connect(function()
                CH.Room = r[1]
                PaintPills()
                CH.RenderFeed()
            end)
        end

        ----------------------------------------------------------------------------
        -- CONEXÃO
        ----------------------------------------------------------------------------
        local conn = CreateCard(tab, "CONEXÃO", 2)
        SubLabel(conn, "Endereço do relay (server/chat-relay). Suas mensagens, seu "
            .. "UserId e seu nome passam por esse servidor — use um em que você confia. "
            .. "O relay não verifica nomes: qualquer um pode digitar qualquer nome.", -1)

        local urlBox = CreateInput(conn, "https://seu-relay.exemplo.com", 32)
        urlBox.LayoutOrder = 1
        urlBox.Font = Enum.Font.Code
        urlBox.TextSize = 12
        urlBox.Text = CH.Url()

        local g = Grid(conn, 2, 30)
        g.LayoutOrder = 2
        local save = CreateButton(g, "SALVAR E CONECTAR", "Success", 30)
        save.LayoutOrder = 1
        local test = CreateButton(g, "TESTAR AGORA", "Accent", 30)
        test.LayoutOrder = 2

        save.MouseButton1Click:Connect(function()
            SET.ChatRelay = urlBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            urlBox.Text = CH.Url()
            CH.Seq, CH.Boot, CH.Loaded, CH.Err = 0, nil, false, nil
            CH.Msgs.server, CH.Msgs.global = {}, {}
            CH.RenderFeed()
            CH.RenderStatus()
            if CH.Url() == "" then
                Log("Chat HYGE desligado (sem endereço)", "action")
            else
                Log("Chat HYGE: relay = " .. CH.Url(), "ok")
                CH.Poll()
            end
        end)
        test.MouseButton1Click:Connect(function()
            CH.Last = -math.huge
            CH.Poll()
        end)

        CheckRow(conn, "Conectar ao chat HYGE", "Desligado, o painel não consulta o relay",
            function() return SET.ChatOn ~= false end,
            function(v)
                SET.ChatOn = v and true or false
                CH.RenderStatus()
                if v then CH.Poll() end
            end, 3)
        CheckRow(conn, "Avisar mensagem nova", "Toast quando chega mensagem com a aba fechada",
            function() return SET.ChatToasts ~= false end,
            function(v) SET.ChatToasts = v and true or false end, 4)

        ----------------------------------------------------------------------------
        -- ritmo: 2 s com a aba aberta, 6 s fechada, 15 s se o relay falhou
        ----------------------------------------------------------------------------
        V8.Job(1, function()
            if CH.Url() == "" or SET.ChatOn == false then return end
            local viewing = V8.IsOpen and V8.IsOpen() and State.ActiveTab == "HyChat"
            local every = CH.Err and 15 or (viewing and 2 or 6)
            if os.clock() - CH.Last >= every then CH.Poll() end
        end)
        OnTabOpen("HyChat", function()
            pcall(CH.RenderStatus)
            CH.Last = math.min(CH.Last, os.clock() - 1.5)   -- abre e já busca
        end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function()
            PaintPills()
            pcall(CH.RenderFeed)    -- RichText não entra no registry: redesenha
            pcall(CH.RenderStatus)
            -- config importada/carregada pode trazer outro endereço
            if not urlBox:IsFocused() then urlBox.Text = CH.Url() end
        end)

        PaintPills()
        CH.RenderFeed()
        CH.RenderStatus()
    end
    Build()
end
