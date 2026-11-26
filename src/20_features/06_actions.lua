--------------------------------------------------------------------------------
-- AÇÕES DE MODERAÇÃO
--------------------------------------------------------------------------------
local function RequireSelected()
    if not State.SelectedPlayer or not State.SelectedPlayer.Parent then
        Toast("Selecione um jogador em Jogadores › Lista", "warn")
        Log("Nenhum jogador selecionado", "warn")
        return nil
    end
    return State.SelectedPlayer
end

local function TeleportTo(cframe)
    local root = Root()
    if not root then Toast("Sem personagem", "warn") return end
    root.CFrame = cframe
end

-- liga/desliga (Spin/Balloon) por UserId do alvo. v9.2: só muda quando o
-- SERVIDOR confirma (HYGE_Result) — antes mudava no clique, mesmo recusado
local TrollState = { Spin = {}, Balloon = {} }

-- [srv:begin] (tests/bridge.test.js roda este bloco)
--------------------------------------------------------------------------------
-- v9.2: PONTE COM O SERVIDOR (server/HYGE_AdminServer.server.lua)
-- O painel nunca decide nada que vale para os outros jogadores: ele PEDE pelo
-- RemoteEvent e o servidor valida (cargo, permissão, alvo, argumentos,
-- limite) e responde pelo HYGE_Result. Aqui fica:
--   * Scan: acha os Remotes de novo (o servidor pode criá-los depois do painel)
--   * Hello: pergunta ao servidor (HYGE_Status) o seu cargo e as ações
--     liberadas — só para MOSTRAR; o servidor confere cada pedido de novo
--   * Can/Send: explica por que uma ação não pode ir (sem servidor, sem cargo,
--     sem permissão) em vez de fingir que foi
--   * a resposta do servidor vai para o console/toast e para os botões
-- Estados: "none" (nenhum Remote: servidor não instalado), "legacy" (Remotes
-- sem HYGE_Status: servidor v9.1 ou de outro sistema — os pedidos vão, mas
-- sem confirmação estruturada), "checking", "noresponse", "ok".
--------------------------------------------------------------------------------
do
    V8.Srv = { State = "none", Info = nil, Pending = {}, Hooks = {}, Watch = {} }
    local S = V8.Srv
    local TIMEOUT, HELLO_TIMEOUT = 6, 8

    -- { chave, nome no ReplicatedStorage, o que faz, grupo } (catálogo único)
    S.Entry = function(key)
        for _, r in ipairs(V8.RemoteInfo) do
            if r[1] == key then return r end
        end
        return nil
    end

    -- quem quer saber quando o estado muda (botões, etiquetas, aba Servidor)
    S.OnChange = function(fn) table.insert(S.Watch, fn) end
    S.Changed = function()
        for _, fn in ipairs(S.Watch) do pcall(fn) end
    end

    ----------------------------------------------------------------------------
    -- mensagens do servidor para todo mundo / para você (antes em 05_events)
    ----------------------------------------------------------------------------
    local function OnWhisper(fromName, message)
        fromName, message = tostring(fromName), tostring(message)
        if fromName == "HYGE" then
            -- servidor v9.1: a confirmação das ações vinha por aqui
            Log("[SERVIDOR] " .. message, message:find("✗", 1, true) and "error" or "ok")
            return
        end
        Log("[ADMIN " .. fromName .. "] " .. message, "action")
        Toast("ADMIN " .. fromName .. ": " .. message, nil, 6)
    end
    -- o anúncio volta para todos (já filtrado pelo Roblox): é a confirmação real
    local function OnAnnounce(fromName, message)
        Log("[ANÚNCIO " .. tostring(fromName) .. "] " .. tostring(message), "action")
    end

    -- resposta de um pedido seu (só você recebe)
    S.OnResult = function(r)
        if type(r) ~= "table" or type(r.action) ~= "string" or type(r.message) ~= "string" then return end
        S.Pending[r.action] = nil
        local text = (r.ok == true and "✓ " or "✗ ") .. r.message:sub(1, 300)
        Log("[SERVIDOR] " .. text, r.ok == true and "ok" or "error")
        Toast(text, r.ok == true and "ok" or "warn", r.ok == true and 2 or 3.5)
        if r.ok == true and type(r.target) == "number" and type(r.state) == "boolean" then
            if r.action == "AdminSpin" then TrollState.Spin[r.target] = r.state
            elseif r.action == "AdminBalloon" then TrollState.Balloon[r.target] = r.state end
        end
        for _, fn in ipairs(S.Hooks) do pcall(fn, r) end
    end

    -- (re)liga a escuta de um Remote só quando ele mudou; Conn[nome] é o que o
    -- Unload desconecta
    local hooked = {}
    local function Hook(name, remote, signal, fn)
        if hooked[name] == remote then return end
        hooked[name] = remote
        if remote then
            Conn[name] = remote[signal]:Connect(fn)
        else
            Conn[name] = nil
        end
    end

    ----------------------------------------------------------------------------
    -- Scan: Remotes de novo + estado
    ----------------------------------------------------------------------------
    S.Scan = function()
        local have = 0
        for _, r in ipairs(V8.RemoteInfo) do
            local o = ReplicatedStorage:FindFirstChild(r[2])
            Remotes[r[1]] = (o and o:IsA("RemoteEvent")) and o or nil
            if Remotes[r[1]] then have = have + 1 end
        end
        local st = ReplicatedStorage:FindFirstChild("HYGE_Status")
        S.StatusFn = (st and st:IsA("RemoteFunction")) and st or nil
        local res = ReplicatedStorage:FindFirstChild("HYGE_Result")
        Hook("SrvResult", (res and res:IsA("RemoteEvent")) and res or nil, "OnClientEvent", S.OnResult)
        Hook("Whisper", Remotes.Whisper, "OnClientEvent", OnWhisper)
        Hook("Announce", Remotes.Announce, "OnClientEvent", OnAnnounce)

        if S.StatusFn then
            if S.State ~= "ok" and S.State ~= "noresponse" then S.State = "checking" end
        elseif have > 0 then
            S.State, S.Info = "legacy", nil
        else
            S.State, S.Info = "none", nil
        end
        return have
    end

    -- resposta do HYGE_Status, conferida campo a campo (nada de confiar no formato)
    S.Clean = function(r)
        if type(r) ~= "table" or type(r.hyge) ~= "string" or type(r.level) ~= "number"
            or r.level ~= r.level then
            return nil
        end
        local info = {
            hyge = r.hyge:sub(1, 16),
            level = math.max(0, math.min(3, math.floor(r.level))),
            role = type(r.role) == "string" and r.role:sub(1, 24) or "?",
            actions = {}, cooldowns = {},
            maxText = type(r.maxText) == "number" and r.maxText or nil,
        }
        if type(r.actions) == "table" then
            for k, v in pairs(r.actions) do
                if type(k) == "string" and v == true then info.actions[k] = true end
            end
        end
        if type(r.cooldowns) == "table" then
            for k, v in pairs(r.cooldowns) do
                if type(k) == "string" and type(v) == "number" then info.cooldowns[k] = v end
            end
        end
        return info
    end

    -- Hello: pergunta o cargo. Usa o task do Roblox direto (não o contado em
    -- V8.Tasks): se o servidor nunca responder, isso não pode deixar o Unload
    -- em "SOBROU"; resposta que chegar depois do Unload é ignorada.
    S.Hello = function()
        local fn = S.StatusFn
        if not fn then return false end
        if S.State == "checking" and S.Asked and os.clock() - S.Asked < 2 then return false end
        S.Asked = os.clock()
        S.State, S.Why = "checking", nil
        S.Seq = (S.Seq or 0) + 1
        local seq = S.Seq
        V8.RawTask.spawn(function()
            local ok, r = pcall(function() return fn:InvokeServer() end)
            if V8.Unloaded or seq ~= S.Seq then return end
            local info = ok and S.Clean(r) or nil
            S.Info = info
            S.State = info and "ok" or "noresponse"
            S.Why = (not ok) and tostring(r) or ((not info) and "resposta inválida ou limite de pedidos" or nil)
            if info then
                Log("Servidor HYGE " .. info.hyge .. ": seu cargo é " .. info.role, info.level > 0 and "ok" or "warn")
            end
            S.Changed()
        end)
        return true
    end

    S.Refresh = function()
        S.Scan()
        S.Hello()
        S.Changed()
    end

    ----------------------------------------------------------------------------
    -- Can / Send
    ----------------------------------------------------------------------------
    -- ok, motivo (frase para o jogador), estado
    S.Can = function(key)
        local e = S.Entry(key)
        local name = e and e[2] or tostring(key)
        if not Remotes[key] then
            return false, "precisa do script de servidor do HYGE, que não está instalado neste jogo "
                .. "(falta ReplicatedStorage." .. name .. "). Instale server/HYGE_AdminServer.server.lua "
                .. "em ServerScriptService pelo Roblox Studio (Início › Servidor › Instalação)", "none"
        end
        local I = S.State == "ok" and S.Info or nil
        if I and I.level < 1 then
            return false, "o servidor deste jogo não reconhece você como admin: coloque o seu UserId ("
                .. tostring(LocalPlayer.UserId) .. ") em CONFIG.AdminIds do script de servidor", "ok"
        end
        if I and not I.actions[name] then
            return false, "o seu cargo no servidor (" .. I.role .. ") não tem permissão para esta ação "
                .. "(CONFIG.Permissions do script de servidor)", "ok"
        end
        return true, nil, S.State
    end

    -- motivo curto para o botão; nil = disponível
    S.Short = function(key)
        local ok, _, state = S.Can(key)
        if ok then return nil end
        if state == "none" then return "sem servidor" end
        if S.Info and S.Info.level < 1 then return "não é admin" end
        return "sem permissão"
    end

    -- Pede ao servidor. label = o que aparece no console ("Kick: Fulano").
    -- Devolve: o pedido saiu?, estado. O resultado vem depois (HYGE_Result).
    S.Send = function(key, label, ...)
        local ok, why, state = S.Can(key)
        if not ok then
            Log(label .. " — não enviado: " .. why, "warn")
            Toast(label .. ": " .. (S.Short(key) or "indisponível"), "warn", 3)
            return false, state
        end
        local remote = Remotes[key]
        local sent, err = pcall(remote.FireServer, remote, ...)
        if not sent then
            Log(label .. " — falhou ao enviar: " .. tostring(err), "error")
            return false, state
        end
        if state == "legacy" then
            Log(label .. " — pedido enviado (servidor sem resposta estruturada: confira no jogo)", "warn")
        else
            S.Pending[remote.Name] = { at = os.clock(), label = label }
            Log(label .. " — pedido enviado; aguardando o servidor", "action")
        end
        return true, state
    end

    -- uma linha sobre o servidor (aba Servidor, Sobre, Diagnóstico, comando)
    -- devolve texto, cor do tema
    S.Summary = function()
        local have, total = V8.RemoteStatus()
        if S.State == "none" then
            return "não instalado neste jogo (0/" .. total .. " Remotes)", "Dim"
        elseif S.State == "legacy" then
            return "Remotes " .. have .. "/" .. total .. " sem o HYGE_Status (servidor v9.1 ou de outro "
                .. "sistema): o servidor valida, mas o painel não sabe o seu cargo", "Warning"
        elseif S.State == "checking" then
            return "conferindo o servidor...", "Dim"
        elseif S.State == "noresponse" or not S.Info then
            return "HYGE_Status sem resposta (" .. tostring(S.Why or "?") .. ") — os pedidos vão e "
                .. "o servidor decide", "Warning"
        end
        local I = S.Info
        if I.level < 1 then
            return "HYGE " .. I.hyge .. " instalado, mas o servidor NÃO reconhece você como admin", "Danger"
        end
        local n = 0
        for _ in pairs(I.actions) do n = n + 1 end
        return "HYGE " .. I.hyge .. " instalado · seu cargo: " .. I.role .. " · " .. n .. "/" .. total
            .. " ações liberadas", "Success"
    end

    -- pedido sem resposta e HYGE_Status que não respondeu
    V8.Job(1, function()
        local now = os.clock()
        if S.State == "checking" and S.Asked and now - S.Asked > HELLO_TIMEOUT then
            S.State, S.Why = "noresponse", "nada em " .. HELLO_TIMEOUT .. " s"
            S.Changed()
        end
        for name, p in pairs(S.Pending) do
            if now - p.at > TIMEOUT then
                S.Pending[name] = nil
                Log(p.label .. " — o servidor não respondeu em " .. TIMEOUT .. " s (script parado ou "
                    .. "com erro? veja o Output do servidor)", "warn")
            end
        end
    end)

    S.Scan()
end
-- [srv:end]

--------------------------------------------------------------------------------
-- Cada ação abaixo só PEDE (V8.Srv.Send). Sem o servidor, ela diz o motivo e
-- não faz nada — nada é simulado na sua tela como se tivesse funcionado.
--------------------------------------------------------------------------------

-- Ir até o jogador: com o servidor HYGE (e permissão), quem move é o servidor
-- (fica no registro e respeita o jogo); sem ele, move só o SEU personagem —
-- isso funciona em qualquer jogo, porque o seu cliente controla o seu corpo
local function Goto(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then Toast("Alvo sem personagem", "warn") return end
    if V8.Srv.Can("Teleport") then
        V8.Srv.Send("Teleport", "Ir até " .. player.Name, player.UserId)
        return
    end
    TeleportTo(root.CFrame * CFrame.new(0, 0, 4))
    Log("Goto (local: só o seu personagem) -> " .. player.Name, "ok")
end

-- v9.2: sem o servidor não existe mais o "bring local" (movia o alvo só na
-- sua tela e o servidor desfazia: parecia que tinha funcionado)
local function Bring(player)
    return V8.Srv.Send("Pull", "Bring: " .. player.Name, player.UserId)
end

-- v9.2: também não mexe mais no personagem do alvo no seu cliente
local function FreezePlayer(player, freeze)
    return V8.Srv.Send("Freeze", (freeze and "Freeze: " or "Unfreeze: ") .. player.Name,
        player.UserId, freeze == true)
end

local function KickPlayer(player, reason)
    return V8.Srv.Send("Kick", "Kick: " .. player.Name, player.UserId, reason)
end

--------------------------------------------------------------------------------
-- AÇÕES DE TROLL (v8.0) — 100% dependentes de servidor, cliente só pede.
--------------------------------------------------------------------------------
local function FlingPlayer(player)
    return V8.Srv.Send("Fling", "Fling: " .. player.Name, player.UserId)
end

-- liga/desliga: o botão segue a confirmação do servidor. Servidor v9.1 não
-- confirma — aí o botão segue o pedido, como antes
local function SpinPlayer(player, on)
    local sent, state = V8.Srv.Send("Spin", (on and "Spin ON: " or "Spin OFF: ") .. player.Name,
        player.UserId, on == true)
    if sent and state == "legacy" then TrollState.Spin[player.UserId] = on end
    return sent
end

local function TripPlayer(player)
    return V8.Srv.Send("Trip", "Trip: " .. player.Name, player.UserId)
end

local function LaunchPlayer(player)
    return V8.Srv.Send("Launch", "Launch: " .. player.Name, player.UserId)
end

local function SitPlayer(player)
    return V8.Srv.Send("Sit", "Force Sit: " .. player.Name, player.UserId)
end

local function ScalePlayer(player, mode)
    return V8.Srv.Send("Scale", "Scale (" .. mode .. "): " .. player.Name, player.UserId, mode)
end

local function BalloonPlayer(player, on)
    local sent, state = V8.Srv.Send("Balloon", (on and "Balloon ON: " or "Balloon OFF: ") .. player.Name,
        player.UserId, on == true)
    if sent and state == "legacy" then TrollState.Balloon[player.UserId] = on end
    return sent
end

-- 100% LOCAL de propósito (e dito na tela): o alvo e o servidor não veem nada
local function FakeMessage(player, kind)
    local texts = {
        kick = "[SISTEMA] " .. player.Name .. " foi expulso do servidor.",
        ban  = "[SISTEMA] " .. player.Name .. " foi banido permanentemente.",
    }
    local msg = texts[kind] or texts.kick
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = msg, Color = THEME.Danger, Font = Enum.Font.GothamBold })
    end)
    Log("Fake message exibida SÓ na sua tela — o alvo e o servidor não veem nada: "
        .. msg, "warn")
    Toast("Fake message é 100% local", "warn", 3)
end

-- v9.2: sem o servidor o anúncio não aparece mais "só no seu chat" como se
-- tivesse ido para todos — o painel diz que precisa do servidor
local function Announce(msg)
    return V8.Srv.Send("Announce", "Anúncio", msg)
end

-- v9.2: mensagem privada num lugar só (Moderação, Chat e HUD do Spectate
-- faziam cada um o seu FireServer)
V8.Srv.Whisper = function(player, text)
    local cut = utf8.offset(text, 58)   -- corta sem partir acento
    local short = (cut and cut <= #text) and (text:sub(1, cut - 1) .. "...") or text
    return V8.Srv.Send("Whisper", "Privado para " .. player.Name .. ": " .. short, player.UserId, text)
end

local function Copy(text, what)
    if setclipboard then
        setclipboard(text)
        Log(what .. " copiado: " .. text, "ok")
        Toast(what .. " copiado", "ok", 1.5)
    else
        Log(what .. ": " .. text)
    end
end
