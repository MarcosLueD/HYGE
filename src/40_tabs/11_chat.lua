--------------------------------------------------------------------------------
-- v8.0 — ABA CHAT (balão do dock)
-- Feed do chat DESTE servidor + enviar no chat do jogo + privado pelo Remote.
-- Mostra só o que o seu cliente já recebe do Roblox: nenhuma mensagem é
-- inventada e não existe chat entre servidores (exigiria um servidor próprio).
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Chat")
    V8.Chat = { Max = 80, Count = 0 }
    local CH = V8.Chat

    ----------------------------------------------------------------------------
    -- ENVIAR
    ----------------------------------------------------------------------------
    local send = CreateCard(tab, "ENVIAR", 1)
    SubLabel(send, "ENVIAR NO CHAT fala pelo seu personagem, como se você tivesse "
        .. "digitado. PRIVADO vai para o jogador selecionado em Jogadores e "
        .. "precisa do Remote AdminWhisper (script de server/).", -1)

    local box = CreateInput(send, "Mensagem...", 34)
    box.LayoutOrder = 1

    local function Take()
        local text = box.Text
        if text:match("^%s*$") then
            Toast("Escreva a mensagem primeiro", "warn", 1.6)
            return nil
        end
        return text
    end

    local function SayPublic()
        local text = Take()
        if not text then return end
        if V8.Dash and V8.Dash.Say and V8.Dash.Say(text) then box.Text = "" end
    end

    local g = Grid(send, 2, 32)
    g.LayoutOrder = 2

    local pub = CreateButton(g, "ENVIAR NO CHAT", "Accent", 32)
    pub.LayoutOrder = 1
    pub.MouseButton1Click:Connect(SayPublic)
    box.FocusLost:Connect(function(enter)
        if enter then SayPublic() end
    end)

    local priv = ActionBtn(g, "PRIVADO P/ SELECIONADO", "Accent2", "Whisper", function()
        local p = RequireSelected()
        if not p then return end
        local text = Take()
        if not text then return end
        Remotes.Whisper:FireServer(p.UserId, text)
        Log("Você -> " .. p.Name .. ": " .. text, "ok")
        box.Text = ""
    end)
    priv.LayoutOrder = 2

    ----------------------------------------------------------------------------
    -- FEED (mais nova em cima, guarda as últimas CH.Max)
    ----------------------------------------------------------------------------
    local feed = CreateCard(tab, "CHAT DO SERVIDOR", 2)
    local status = SubLabel(feed, "", 0)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.LayoutOrder = 1
    list.Parent = feed
    do
        local l = Instance.new("UIListLayout", list)
        l.Padding = UDim.new(0, 3)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local lines, seq, mode = {}, 0, "?"

    CH.Add = function(name, text, isMe)
        seq = seq + 1
        CH.Count = CH.Count + 1
        local key = isMe and "Accent2" or "Text"
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.BackgroundTransparency = 1
        l.RichText = false
        l.Text = os.date("%H:%M") .. "   " .. tostring(name) .. ":  " .. tostring(text)
        l.TextColor3 = THEME[key]
        l.Font = Enum.Font.Gotham
        l.TextSize = 12
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = -seq
        l.Parent = list
        Paint(l, "TextColor3", key)
        table.insert(lines, l)
        while #lines > CH.Max do
            local old = table.remove(lines, 1)
            if old then old:Destroy() end
        end
        status.Text = CH.Count .. " mensagem(ns) desde que o painel abriu   ·   " .. mode
    end

    -- escuta UM sistema só (mesma regra do Chat Spy: nunca linha duplicada)
    local modern = false
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
        Conn.ChatFeed = tcs.MessageReceived:Connect(function(msg)
            local src = msg.TextSource
            if not src then return end   -- mensagem de sistema
            local p = Players:GetPlayerByUserId(src.UserId)
            pcall(CH.Add, p and p.DisplayName or src.Name, msg.Text,
                src.UserId == LocalPlayer.UserId)
        end)
        modern = true
    end)
    if modern then
        mode = "chat novo (TextChatService)"
    else
        local ok = pcall(function()
            Conn.ChatFeed = Players.PlayerChatted:Connect(function(_, player, message)
                pcall(CH.Add, player.DisplayName, message, player == LocalPlayer)
            end)
        end)
        mode = ok and "chat legado" or "não consegui ler o chat deste jogo"
    end
    status.Text = "Nenhuma mensagem ainda   ·   " .. mode
end
