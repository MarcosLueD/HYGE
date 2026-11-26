--[[
================================================================================
    HYGE ADMIN — SERVIDOR (v9.2)

    Onde colocar:  ServerScriptService  >  Script (comum, não LocalScript)
    Par dele:      server/HYGE_AdminClient.client.lua em StarterPlayerScripts
    Passo a passo: docs/SERVIDOR.md

    O que faz:
      * cria os 13 RemoteEvents de AÇÃO que o painel procura em
        ReplicatedStorage (AdminKick, AdminPull, AdminFreeze, ...) e, desde a
        v9.2, mais dois:
          HYGE_Status (RemoteFunction) — o painel pergunta "qual é o meu cargo
                       e quais ações eu posso usar?" e mostra isso na tela
          HYGE_Result (RemoteEvent)    — a resposta de cada pedido (aceito ou
                       recusado, e por quê) volta só para quem pediu
      * VALIDA TUDO AQUI. O painel no cliente só pede; quem decide se a pessoa
        tem cargo, se a ação é permitida para esse cargo, se o alvo existe, se
        os argumentos estão certos e se não passou do limite é este script.
        Nunca confie no cliente — qualquer um pode chamar um RemoteEvent, com
        os argumentos que quiser. O HYGE_Status também é só informativo: cada
        pedido é conferido de novo, do zero.
      * filtra anúncio, mensagem privada e motivo do kick pelo TextService
        (regra do Roblox para texto digitado que outra pessoa vai ler). Se o
        filtro falhar, a mensagem NÃO é enviada.
      * registra ações aceitas E recusadas (quem, o quê, por quê): Output do
        servidor + shared.HYGE_AUDIT (últimas CONFIG.AuditSize entradas)

    v9.2 (integração com o painel):
      * cargos: 1 moderador, 2 admin, 3 dono; cada ação tem um nível mínimo
        (CONFIG.Permissions). Com ProtectAdmins, ninguém age sobre alguém do
        mesmo cargo ou acima (o dono age sobre admins; admin não age em admin)
      * limite geral por jogador (CONFIG.RateLimit), além do limite por ação
      * argumento a mais = recusado (o pedido tem de ter exatamente o formato)
      * erro inesperado não vai para o cliente (ele recebe só "erro interno");
        o detalhe fica no Output do servidor
      * recusa repetida não enche o registro: vira uma entrada com contador
      * opcional: entrega o painel (LocalScript em ServerStorage) só para quem
        tem cargo — quem não tem nunca recebe o código (CONFIG.PanelScript)

    Testes: tests/server.test.js (Roblox imitado, roda com npm test) e o
    roteiro para o Studio em docs/TESTES.md (Test › Clients and Servers).
    Só funciona em jogo seu (ou do seu grupo) — é um script de servidor.
================================================================================
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local TextService       = game:GetService("TextService")

local VERSION = "9.2"

--------------------------------------------------------------------------------
-- CONFIGURAÇÃO
--------------------------------------------------------------------------------
local CONFIG = {
    -- CARGOS. No Studio os jogadores de teste têm UserId negativo (-1, -2...):
    -- para testar, coloque o deles aqui (docs/SERVIDOR.md, "Testar no Studio").
    AdminIds = {            -- cargo 2 (admin). Os mesmos do CONFIG.AdminIds do painel.
        -- 123456789,
    },
    ModIds = {              -- cargo 1 (moderador)
        -- 987654321,
    },
    OwnerIsAdmin  = true,   -- dono do jogo (conta pessoal) = cargo 3 (dono)
    GroupId       = 0,      -- opcional: cargos pelo grupo...
    GroupMinRank  = 255,    -- ...rank >= este = admin (255 = dono do grupo)
    GroupModRank  = 0,      -- ...rank >= este = moderador (0 = desligado)

    -- cargo mínimo de cada ação: 1 moderador, 2 admin, 3 só o dono.
    -- Ação que não estiver aqui pede cargo 2.
    Permissions = {
        AdminKick     = 1,
        AdminFreeze   = 1,
        AdminPull     = 1,
        AdminTeleport = 1,
        AdminWhisper  = 1,
        AdminAnnounce = 2,
        AdminFling    = 2,
        AdminSpin     = 2,
        AdminTrip     = 2,
        AdminLaunch   = 2,
        AdminSit      = 2,
        AdminScale    = 2,
        AdminBalloon  = 2,
    },

    ProtectAdmins = true,   -- ninguém age sobre alguém do MESMO cargo ou acima
    Cooldown      = 0.25,   -- segundos entre ações iguais do mesmo jogador (padrão)
    Cooldowns     = {       -- por ação (o que não está aqui usa Cooldown)
        AdminKick     = 1,
        AdminAnnounce = 5,
        AdminWhisper  = 1,
        AdminScale    = 1,
        AdminFling    = 1,
        AdminLaunch   = 1,
    },
    -- v9.2: limite geral por jogador, somando TODOS os Remotes do HYGE
    -- (inclusive HYGE_Status). Passou: recusado sem resposta até a janela virar.
    RateLimit     = { Max = 30, Window = 10 },
    MaxText       = 200,    -- limite de caracteres de anúncio/mensagem/motivo
    AuditSize     = 200,    -- quantas entradas o registro guarda

    -- v9.2: entrega do painel. Um LocalScript com este nome em ServerStorage
    -- (cole o main.lua nele) é copiado para o PlayerGui de quem tiver cargo >=
    -- PanelMinLevel ao entrar. ServerStorage não chega nos clientes: quem não
    -- tem cargo nunca recebe o painel. Sem o LocalScript, nada acontece.
    PanelScript   = "HYGE_Panel",
    PanelMinLevel = 1,

    FlingPower    = 160,
    LaunchPower   = 220,
    SpinSpeed     = 20,     -- rad/s
    BalloonSpeed  = 6,      -- studs/s para cima
    BalloonMax    = 20,     -- segundos: o balão se desliga sozinho
    TripTime      = 2,      -- segundos no chão
    Scale = { tiny = 0.5, normal = 1, giant = 2.5 },
}

local ROLE = { [0] = "jogador", [1] = "moderador", [2] = "admin", [3] = "dono" }

--------------------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------------------
-- ações (o painel conhece estes nomes: src/00_core/04_state.lua, V8.RemoteInfo)
local NAMES = {
    "AdminKick", "AdminPull", "AdminFreeze", "AdminTeleport",
    "AdminAnnounce", "AdminWhisper",
    "AdminFling", "AdminSpin", "AdminTrip", "AdminLaunch",
    "AdminSit", "AdminScale", "AdminBalloon",
}
-- nome curto de cada uma nas respostas para o painel
local LABEL = {
    AdminKick = "Kick", AdminPull = "Bring", AdminFreeze = "Freeze",
    AdminTeleport = "Ir até", AdminAnnounce = "Anúncio", AdminWhisper = "Privado",
    AdminFling = "Fling", AdminSpin = "Spin", AdminTrip = "Trip",
    AdminLaunch = "Launch", AdminSit = "Sit", AdminScale = "Scale",
    AdminBalloon = "Balloon",
}

-- acha ou cria; o que tiver o nome certo e a classe errada é ignorado
local function Ensure(name, class)
    local r = ReplicatedStorage:FindFirstChild(name)
    if r and not r:IsA(class) then
        warn("[HYGE] ReplicatedStorage." .. name .. " existe mas não é " .. class .. " — ignorado")
        return nil
    end
    if not r then
        r = Instance.new(class)
        r.Name = name
        r.Parent = ReplicatedStorage
    end
    return r
end

local R = {}
for _, name in ipairs(NAMES) do R[name] = Ensure(name, "RemoteEvent") end
local Result = Ensure("HYGE_Result", "RemoteEvent")
local Status = Ensure("HYGE_Status", "RemoteFunction")

-- cargo mínimo de uma ação (valor inválido no CONFIG = só o dono, e avisa)
local function Need(remoteName)
    local lv = CONFIG.Permissions[remoteName]
    if lv == nil then return 2 end
    if type(lv) ~= "number" or lv ~= math.floor(lv) or lv < 1 or lv > 3 then return 3 end
    return lv
end
for name, lv in pairs(CONFIG.Permissions) do
    if not LABEL[name] then
        warn("[HYGE] CONFIG.Permissions." .. tostring(name) .. ": ação desconhecida (ignorada)")
    elseif Need(name) == 3 and lv ~= 3 then
        warn("[HYGE] CONFIG.Permissions." .. name .. " = " .. tostring(lv)
            .. " é inválido (use 1, 2 ou 3) — ficou só para o dono")
    end
end

--------------------------------------------------------------------------------
-- REGISTRO (auditoria): aceitas e recusas, no Output e em shared.HYGE_AUDIT
-- O que entra: quem (UserId e nome), a ação, o alvo (UserId), o motivo da
-- recusa e a hora. O que NÃO entra: o texto de mensagens privadas, o motivo
-- do kick e os argumentos que o cliente mandou (só "argumento 2 inválido").
-- O texto de um anúncio entra (já filtrado: todo mundo viu).
--------------------------------------------------------------------------------
local AuditLog = {}
shared.HYGE_AUDIT = AuditLog
local recent = {}   -- [Player] = { [ação|motivo] = { entry =, seen = os.clock() } }

local function Record(entry)
    entry.time = os.time()
    table.insert(AuditLog, entry)
    while #AuditLog > CONFIG.AuditSize do table.remove(AuditLog, 1) end
end

local function Audit(admin, action, target, extra)
    Record({ ok = true, by = admin.UserId, name = admin.Name, action = action,
             target = target and target.UserId or nil, extra = extra })
    print(("[HYGE] %s -> %s%s%s"):format(admin.Name, action,
        target and (" " .. target.Name) or "", extra and (" " .. extra) or ""))
end

-- Recusa: sempre conta. A mesma recusa (jogador + ação + motivo) repetida com
-- menos de 10 s de intervalo só aumenta o contador da entrada que já existe —
-- quem fica martelando um Remote não empurra o resto do registro para fora,
-- e o Output recebe um aviso só.
local function Refuse(player, action, reason)
    local now = os.clock()
    local mine = recent[player] or {}
    recent[player] = mine
    local key = action .. "|" .. reason
    local r = mine[key]
    if r and now - r.seen < 10 then
        r.seen = now
        r.entry.count = r.entry.count + 1
        r.entry.last = os.time()
        return
    end
    local entry = { ok = false, by = player.UserId, name = player.Name, action = action,
                    reason = reason, count = 1 }
    Record(entry)
    mine[key] = { entry = entry, seen = now }
    warn(("[HYGE] RECUSADO %s (%d) %s: %s"):format(player.Name, player.UserId, action, reason))
end

--------------------------------------------------------------------------------
-- CARGO (calculado no servidor, com cache por jogador)
--------------------------------------------------------------------------------
local levelCache = {}   -- [Player] = 0..3
local lastAction = {}   -- [Player] = { [remote] = os.clock() da última ação }
local buckets    = {}   -- [Player] = { t0 = os.clock(), n = pedidos na janela }

local function ComputeLevel(player)
    if CONFIG.OwnerIsAdmin and game.CreatorType == Enum.CreatorType.User
        and game.CreatorId == player.UserId and player.UserId > 0 then
        return 3
    end
    for _, id in ipairs(CONFIG.AdminIds) do
        if player.UserId == id then return 2 end
    end
    local level = 0
    for _, id in ipairs(CONFIG.ModIds or {}) do
        if player.UserId == id then level = 1 break end
    end
    if CONFIG.GroupId and CONFIG.GroupId > 0 then
        -- falhou a consulta (Roblox fora do ar) = não ganha cargo pelo grupo
        local ok, rank = pcall(function() return player:GetRankInGroup(CONFIG.GroupId) end)
        if ok and type(rank) == "number" then
            if rank >= CONFIG.GroupMinRank then return 2 end
            if (CONFIG.GroupModRank or 0) > 0 and rank >= CONFIG.GroupModRank then level = 1 end
        end
    end
    return level
end

local function Level(player)
    if levelCache[player] == nil then levelCache[player] = ComputeLevel(player) end
    return levelCache[player]
end

-- limite geral. Devolve: bloqueado?, acabou de estourar agora?
-- Estourou: fica bloqueado até passar uma janela inteira SEM pedidos —
-- continuar martelando mantém o bloqueio (e o registro não cresce: são sempre
-- as mesmas recusas, com contador).
local function Flooding(player)
    local now, win = os.clock(), CONFIG.RateLimit.Window
    local b = buckets[player]
    if b and b.mute and now < b.mute then
        b.mute = now + win
        return true, false
    end
    if not b or now - b.t0 >= win then
        b = { t0 = now, n = 0 }
        buckets[player] = b
    end
    b.n = b.n + 1
    if b.n > CONFIG.RateLimit.Max then
        b.mute = now + win
        return true, true
    end
    return false, false
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function Root(p)
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Hum(p)
    local c = p and p.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- resposta para o painel de quem pediu (só ele recebe)
local function Reply(player, remoteName, ok, message, code, target, state)
    if Result and player and player.Parent then
        Result:FireClient(player, {
            action = remoteName, ok = ok, message = message, code = code,
            target = target and target.UserId or nil, state = state,
        })
    end
end

-- erro "esperado" (o admin pode ler); qualquer outro vira "erro interno"
local function Fail(message) error({ hyge = message }, 0) end

-- UserId: número inteiro de alguém que está NESTE servidor (quem garante é o
-- GetPlayerByUserId; no Studio os jogadores de teste têm UserId negativo)
local function Target(userId)
    if type(userId) ~= "number" or userId ~= userId or userId == 0
        or userId ~= math.floor(userId) or math.abs(userId) > 2^53 then
        return nil
    end
    return Players:GetPlayerByUserId(userId)
end

-- texto do cliente: string UTF-8 válida, sem caracteres de controle, até
-- CONFIG.MaxText caracteres (cortado sem partir caractere). nil = inválido
local function CleanText(s)
    if type(s) ~= "string" then return nil end
    if #s > CONFIG.MaxText * 4 then return nil end      -- nem processa lixo enorme
    if utf8.len(s) == nil then return nil end           -- bytes que não são texto
    s = s:gsub("%c", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    local cut = utf8.offset(s, CONFIG.MaxText + 1)
    if cut then s = s:sub(1, cut - 1) end
    return s
end

-- filtro obrigatório do Roblox. Falhou = nil (e NÃO se envia nada)
local function FilterFor(text, fromUserId, toPlayer)
    local ok, out = pcall(function()
        local ctx = toPlayer and Enum.TextFilterContext.PrivateChat
            or Enum.TextFilterContext.PublicChat
        local res = TextService:FilterStringAsync(text, fromUserId, ctx)
        if toPlayer then return res:GetNonChatStringForUserAsync(toPlayer.UserId) end
        return res:GetNonChatStringForBroadcastAsync()
    end)
    if ok and type(out) == "string" then return out end
    return nil
end

-- o filtro trocou TUDO por #: não manda "#####" para ninguém
local function FullyCensored(s)
    return s:gsub("[#%s]", "") == ""
end

-- o servidor assume a física do alvo por um instante (velocidade aplicada
-- no servidor só vale se o servidor for o dono da montagem) e devolve depois
local function WithServerPhysics(target, seconds, fn)
    local root = Root(target)
    if not root then Fail("alvo sem personagem") end
    pcall(function() root:SetNetworkOwner(nil) end)
    local ok, err = pcall(fn, root)
    task.delay(seconds, function()
        if root.Parent and target.Parent then
            pcall(function() root:SetNetworkOwner(target) end)
        end
    end)
    if not ok then error(err, 0) end
    return true
end

--------------------------------------------------------------------------------
-- VALIDAÇÃO DE ARGUMENTOS. Cada validador devolve ok, valor limpo.
--------------------------------------------------------------------------------
local Arg = {}
Arg.text = function(v)             -- texto obrigatório
    local s = CleanText(v)
    return s ~= nil, s
end
Arg.optText = function(v)          -- texto opcional (nil ou só espaços = sem texto)
    if v == nil then return true, nil end
    if type(v) ~= "string" then return false end
    if #v <= CONFIG.MaxText * 4 and v:match("^%s*$") then return true, nil end
    local s = CleanText(v)
    return s ~= nil, s
end
Arg.optBool = function(v)          -- liga/desliga (nil = padrão de cada ação)
    return v == nil or type(v) == "boolean", v
end
Arg.oneOf = function(set)          -- um dos valores da tabela (chave)
    return function(v)
        return type(v) == "string" and set[v] ~= nil, v
    end
end

--------------------------------------------------------------------------------
-- PORTEIRO: toda chamada passa por aqui
--   opts.target  = o 1º argumento é UserId de um jogador alvo
--   opts.noSelf  = o alvo não pode ser quem pediu
--   opts.protect = alvo de cargo igual ou maior é recusado (CONFIG.ProtectAdmins)
--   opts.args    = validadores dos argumentos seguintes (na ordem)
-- Ordem: limite geral -> tem cargo? -> cargo permite a ação? -> limite da ação
-- -> formato (nº de argumentos) -> alvo -> argumentos -> ação.
-- Qualquer "não" para tudo e vai para o registro. Quem tem cargo recebe o
-- motivo no painel (HYGE_Result); quem não tem não recebe resposta nenhuma.
--
-- fn(admin, alvo, args...) devolve: ação para o registro, mensagem para o
-- painel, estado (liga/desliga) e um extra para o registro.
--------------------------------------------------------------------------------
local function Handle(remoteName, opts, fn)
    local remote = R[remoteName]
    if not remote then return end
    local validators = opts.args or {}
    local expected = (opts.target and 1 or 0) + #validators
    local cooldown = CONFIG.Cooldowns[remoteName] or CONFIG.Cooldown
    local need = Need(remoteName)
    local label = LABEL[remoteName] or remoteName

    remote.OnServerEvent:Connect(function(player, ...)
        local flood, first = Flooding(player)
        if flood then
            Refuse(player, remoteName, "excesso de pedidos")
            -- staff fica sabendo uma vez; quem não tem cargo nunca recebe nada
            if first and Level(player) >= 1 then
                Reply(player, remoteName, false, ("muitos pedidos seguidos — espere %d s sem pedir nada")
                    :format(CONFIG.RateLimit.Window), "rate")
            end
            return
        end

        local level = Level(player)
        if level < 1 then
            Refuse(player, remoteName, "não é admin")
            return
        end
        if level < need then
            Refuse(player, remoteName, "sem permissão (cargo " .. ROLE[level] .. ")")
            Reply(player, remoteName, false, label .. ": o seu cargo (" .. ROLE[level]
                .. ") não pode usar esta ação", "perm")
            return
        end

        local now = os.clock()
        local mine = lastAction[player] or {}
        lastAction[player] = mine
        if mine[remoteName] and now - mine[remoteName] < cooldown then
            Refuse(player, remoteName, "limite da ação (" .. cooldown .. "s)")
            Reply(player, remoteName, false, ("%s: espere %.1fs"):format(label,
                cooldown - (now - mine[remoteName])), "cooldown")
            return
        end
        mine[remoteName] = now   -- conta a tentativa (pedido inválido também gasta)

        local args = table.pack(...)
        local n = args.n
        while n > 0 and args[n] == nil do n = n - 1 end   -- nil no fim não conta
        if n > expected then
            Refuse(player, remoteName, "argumentos demais (" .. n .. ", esperado " .. expected .. ")")
            Reply(player, remoteName, false, label .. ": pedido com argumentos a mais", "args")
            return
        end

        local i = 1
        local target
        if opts.target then
            target = Target(args[1])
            if not target then
                Refuse(player, remoteName, "alvo inválido ou fora do servidor")
                Reply(player, remoteName, false, label .. ": jogador não está no servidor", "target")
                return
            end
            if opts.noSelf and target == player then
                Refuse(player, remoteName, "alvo é quem pediu")
                Reply(player, remoteName, false, label .. ": não vale em você mesmo", "target")
                return
            end
            if opts.protect and CONFIG.ProtectAdmins and target ~= player and Level(target) >= level then
                Refuse(player, remoteName, "alvo protegido (cargo " .. ROLE[Level(target)] .. ")")
                Reply(player, remoteName, false, label .. ": " .. target.Name .. " tem cargo igual "
                    .. "ou maior que o seu (" .. ROLE[Level(target)] .. ")", "protected", target)
                return
            end
            i = 2
        end

        local clean = {}
        for k, check in ipairs(validators) do
            local ok, v = check(args[i + k - 1])
            if not ok then
                Refuse(player, remoteName, "argumento " .. k .. " inválido")
                Reply(player, remoteName, false, label .. ": argumento inválido", "args", target)
                return
            end
            clean[k] = v
        end

        local ok, action, message, state, extra = pcall(fn, player, target, table.unpack(clean, 1, #validators))
        if ok then
            Audit(player, action, target, extra)
            Reply(player, remoteName, true, message, "ok", target, state)
        elseif type(action) == "table" and type(action.hyge) == "string" then
            Refuse(player, remoteName, "falhou: " .. action.hyge)
            Reply(player, remoteName, false, label .. ": " .. action.hyge, "failed", target)
        else
            -- o detalhe (linha, nome de objeto...) fica só no Output do servidor
            Refuse(player, remoteName, "erro interno")
            warn("[HYGE] erro interno em " .. remoteName .. ": " .. tostring(action))
            Reply(player, remoteName, false, label .. ": erro interno no servidor (detalhe no "
                .. "Output do servidor)", "internal", target)
        end
    end)
end

--------------------------------------------------------------------------------
-- STATUS (v9.2): o painel pergunta o cargo e as ações liberadas. Só informa —
-- cada pedido de ação passa pelo porteiro de novo. Quem não tem cargo recebe
-- só a versão e o cargo 0 (nem a lista de ações, nem os limites).
--------------------------------------------------------------------------------
if Status then
    Status.OnServerInvoke = function(player)
        if Flooding(player) then
            Refuse(player, "HYGE_Status", "excesso de pedidos")
            return nil
        end
        local level = Level(player)
        local out = { hyge = VERSION, level = level, role = ROLE[level] }
        if level >= 1 then
            out.actions, out.cooldowns = {}, {}
            for _, name in ipairs(NAMES) do
                if R[name] and level >= Need(name) then
                    out.actions[name] = true
                    out.cooldowns[name] = CONFIG.Cooldowns[name] or CONFIG.Cooldown
                end
            end
            out.maxText = CONFIG.MaxText
        end
        return out
    end
end

--------------------------------------------------------------------------------
-- MODERAÇÃO
--------------------------------------------------------------------------------
Handle("AdminKick", { target = true, noSelf = true, protect = true, args = { Arg.optText } },
    function(admin, target, reason)
        local text = reason or "Removido por um admin"
        text = FilterFor(text, admin.UserId, target) or "Removido por um admin"
        if FullyCensored(text) then text = "Removido por um admin" end
        target:Kick(text)
        return "kick", "Kick: " .. target.Name
    end)

Handle("AdminPull", { target = true, noSelf = true }, function(admin, target)
    local mine = Root(admin)
    if not mine then Fail("você está sem personagem") end
    if not target.Character then Fail("alvo sem personagem") end
    target.Character:PivotTo(mine.CFrame * CFrame.new(0, 0, -4))
    return "bring", "Bring: " .. target.Name
end)

Handle("AdminTeleport", { target = true, noSelf = true }, function(admin, target)
    local theirs = Root(target)
    if not theirs then Fail("alvo sem personagem") end
    if not admin.Character then Fail("você está sem personagem") end
    admin.Character:PivotTo(theirs.CFrame * CFrame.new(0, 0, 4))
    return "goto", "Ir até: " .. target.Name
end)

Handle("AdminFreeze", { target = true, protect = true, args = { Arg.optBool } }, function(admin, target, on)
    if on == nil then on = true end
    local root = Root(target)
    if not root then Fail("alvo sem personagem") end
    root.Anchored = on
    return on and "freeze" or "unfreeze", (on and "Freeze: " or "Unfreeze: ") .. target.Name, on
end)

--------------------------------------------------------------------------------
-- COMUNICAÇÃO (sempre filtrada)
--------------------------------------------------------------------------------
Handle("AdminAnnounce", { args = { Arg.text } }, function(admin, _, text)
    local safe = FilterFor(text, admin.UserId, nil)
    if not safe then Fail("o filtro do Roblox não respondeu — nada foi enviado") end
    if FullyCensored(safe) then Fail("o filtro do Roblox bloqueou a mensagem — nada foi enviado") end
    R.AdminAnnounce:FireAllClients(admin.Name, safe)
    return "announce", "Anúncio enviado para todos", nil, safe
end)

Handle("AdminWhisper", { target = true, args = { Arg.text } }, function(admin, target, text)
    local safe = FilterFor(text, admin.UserId, target)
    if not safe then Fail("o filtro do Roblox não respondeu — nada foi enviado") end
    if FullyCensored(safe) then Fail("o filtro do Roblox bloqueou a mensagem — nada foi enviado") end
    R.AdminWhisper:FireClient(target, admin.Name, safe)
    return "whisper", "Mensagem entregue para " .. target.Name
end)

--------------------------------------------------------------------------------
-- TROLL
--------------------------------------------------------------------------------
Handle("AdminFling", { target = true, protect = true }, function(admin, target)
    WithServerPhysics(target, 1.5, function(root)
        local a = math.random() * math.pi * 2
        root.AssemblyLinearVelocity = Vector3.new(math.cos(a), 0.45, math.sin(a)) * CONFIG.FlingPower
        root.AssemblyAngularVelocity = Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30))
    end)
    return "fling", "Fling: " .. target.Name
end)

Handle("AdminLaunch", { target = true, protect = true }, function(admin, target)
    WithServerPhysics(target, 1.5, function(root)
        root.AssemblyLinearVelocity = Vector3.new(0, CONFIG.LaunchPower, 0)
    end)
    return "launch", "Launch: " .. target.Name
end)

Handle("AdminTrip", { target = true, protect = true }, function(admin, target)
    local h = Hum(target)
    if not h then Fail("alvo sem personagem") end
    h.PlatformStand = true
    WithServerPhysics(target, CONFIG.TripTime, function(root)
        root.AssemblyAngularVelocity = root.CFrame.RightVector * 8
    end)
    task.delay(CONFIG.TripTime, function()
        if h.Parent then h.PlatformStand = false end
    end)
    return "trip", "Trip: " .. target.Name
end)

Handle("AdminSit", { target = true, protect = true }, function(admin, target)
    local h = Hum(target)
    if not h then Fail("alvo sem personagem") end
    h.Sit = true
    return "sit", "Sit: " .. target.Name
end)

Handle("AdminScale", { target = true, protect = true, args = { Arg.oneOf(CONFIG.Scale) } }, function(admin, target, mode)
    local factor = CONFIG.Scale[mode]
    if not target.Character then Fail("alvo sem personagem") end
    target.Character:ScaleTo(factor)
    return "scale", "Scale " .. mode .. ": " .. target.Name, nil, mode
end)

-- Spin e Balloon: constraints criadas no servidor replicam para o cliente
-- dono do personagem, que simula com elas (não precisa trocar o dono da física)
local function ClearConstraint(root, name)
    for _, n in ipairs({ name, name .. "_Att" }) do
        local o = root:FindFirstChild(n)
        if o then o:Destroy() end
    end
end

Handle("AdminSpin", { target = true, protect = true, args = { Arg.optBool } }, function(admin, target, on)
    local root = Root(target)
    if not root then Fail("alvo sem personagem") end
    ClearConstraint(root, "HYGE_Spin")
    on = on ~= false
    if on then
        local att = Instance.new("Attachment")
        att.Name = "HYGE_Spin_Att"
        att.Parent = root
        local av = Instance.new("AngularVelocity")
        av.Name = "HYGE_Spin"
        av.Attachment0 = att
        av.RelativeTo = Enum.ActuatorRelativeTo.World
        av.MaxTorque = math.huge
        av.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
        av.Parent = root
    end
    return on and "spin on" or "spin off", (on and "Spin ON: " or "Spin OFF: ") .. target.Name, on
end)

Handle("AdminBalloon", { target = true, protect = true, args = { Arg.optBool } }, function(admin, target, on)
    local root = Root(target)
    if not root then Fail("alvo sem personagem") end
    ClearConstraint(root, "HYGE_Balloon")
    on = on ~= false
    if on then
        local att = Instance.new("Attachment")
        att.Name = "HYGE_Balloon_Att"
        att.Parent = root
        local lv = Instance.new("LinearVelocity")
        lv.Name = "HYGE_Balloon"
        lv.Attachment0 = att
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
        lv.LineDirection = Vector3.yAxis
        lv.LineVelocity = CONFIG.BalloonSpeed
        lv.MaxForce = root.AssemblyMass * workspace.Gravity * 3
        lv.Parent = root
        -- desliga sozinho: ninguém fica flutuando para sempre fora do mapa
        task.delay(CONFIG.BalloonMax, function()
            if lv.Parent then
                ClearConstraint(root, "HYGE_Balloon")
                Reply(admin, "AdminBalloon", true, "Balloon de " .. target.Name
                    .. " desligou sozinho (" .. CONFIG.BalloonMax .. "s)", "ok", target, false)
            end
        end)
    end
    return on and "balloon on" or "balloon off", (on and "Balloon ON: " or "Balloon OFF: ") .. target.Name, on
end)

--------------------------------------------------------------------------------
-- ENTRADA / SAÍDA (cargo calculado na entrada; painel entregue só para staff)
--------------------------------------------------------------------------------
local function GivePanel(player)
    if (CONFIG.PanelScript or "") == "" or Level(player) < (CONFIG.PanelMinLevel or 1) then return end
    local src = ServerStorage:FindFirstChild(CONFIG.PanelScript)
    if not src then return end
    if not src:IsA("LocalScript") then
        warn("[HYGE] ServerStorage." .. CONFIG.PanelScript .. " não é LocalScript — painel não entregue")
        return
    end
    local gui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 15)
    if not gui or not player.Parent or gui:FindFirstChild("HYGE_PanelHost") then return end
    -- ResetOnSpawn = false: o painel não reinicia a cada respawn
    local host = Instance.new("ScreenGui")
    host.Name = "HYGE_PanelHost"
    host.ResetOnSpawn = false
    src:Clone().Parent = host
    host.Parent = gui
    Audit(player, "panel", nil, ROLE[Level(player)])
end

local function OnJoin(player)
    levelCache[player] = ComputeLevel(player)
    local ok, err = pcall(GivePanel, player)
    if not ok then warn("[HYGE] não deu para entregar o painel a " .. player.Name .. ": " .. tostring(err)) end
end

Players.PlayerAdded:Connect(OnJoin)
-- quem já estava no servidor quando o script começou (raro: o Studio roda os
-- scripts de servidor antes de os jogadores entrarem)
for _, p in ipairs(Players:GetPlayers()) do
    if levelCache[p] == nil then task.spawn(OnJoin, p) end
end
Players.PlayerRemoving:Connect(function(p)
    levelCache[p] = nil
    lastAction[p] = nil
    buckets[p] = nil
    recent[p] = nil
end)

print(("[HYGE] servidor %s pronto — %d Remotes de ação, %d admin(s) e %d moderador(es) por UserId%s")
    :format(VERSION, #NAMES, #CONFIG.AdminIds, #(CONFIG.ModIds or {}),
        CONFIG.GroupId > 0 and (", grupo " .. CONFIG.GroupId .. " rank >= " .. CONFIG.GroupMinRank) or ""))
