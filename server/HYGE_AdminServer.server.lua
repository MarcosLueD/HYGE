--[[
================================================================================
    HYGE ADMIN — SERVIDOR (v9.1)

    Onde colocar:  ServerScriptService  >  Script (comum, não LocalScript)
    Par dele:      server/HYGE_AdminClient.client.lua em StarterPlayerScripts

    O que faz:
      * cria os 13 RemoteEvents que o painel procura em ReplicatedStorage
        (AdminKick, AdminPull, AdminFreeze, ... — o painel lê na hora em que
        carrega, então este script precisa rodar antes: é o normal no Studio)
      * VALIDA TUDO AQUI. O painel no cliente só pede; quem decide se é admin,
        se o alvo existe e se o texto pode ser mostrado é este script. Nunca
        confie no cliente — qualquer um pode chamar um RemoteEvent.
      * filtra anúncio e mensagem privada pelo TextService (regra do Roblox
        para texto digitado que outra pessoa vai ler). Se o filtro falhar,
        a mensagem NÃO é enviada.
      * devolve confirmação real para o painel do admin ("✓ Kick: Fulano"),
        que aparece no console do painel.

    v9.1 (auditoria):
      * cada RemoteEvent tem os argumentos validados (tipo, faixa, lista de
        valores aceitos). Argumento errado = recusado, nada acontece.
      * UserId do alvo precisa ser um inteiro de alguém NO servidor
      * limite por ação (CONFIG.Cooldowns): kick, anúncio etc. têm o seu
      * tudo vai para o registro: ações aceitas E recusas (quem, o quê, por
        quê). Output do servidor + shared.HYGE_AUDIT (últimas 200 entradas)
      * texto: tamanho conferido antes de processar, corte sem quebrar
        caractere UTF-8, e mensagem que o filtro censurou inteira não é enviada

    Testes: tests/server.test.js (Roblox imitado, roda com npm test) e o
    roteiro para o Studio em docs/TESTES.md (Test › Clients and Servers).
    Só funciona em jogo seu (ou do seu grupo) — é um script de servidor.
================================================================================
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService       = game:GetService("TextService")

--------------------------------------------------------------------------------
-- CONFIGURAÇÃO
--------------------------------------------------------------------------------
local CONFIG = {
    -- UserIds com permissão. Use os mesmos do CONFIG.AdminIds do painel.
    AdminIds = {
        -- 123456789,
    },
    OwnerIsAdmin  = true,   -- dono do jogo (conta pessoal) é admin automaticamente
    GroupId       = 0,      -- opcional: libera membros deste grupo...
    GroupMinRank  = 255,    -- ...com rank >= este valor (255 = dono do grupo)

    ProtectAdmins = true,   -- admin não pode kickar/trollar outro admin
    Cooldown      = 0.25,   -- segundos entre ações iguais do mesmo admin (padrão)
    Cooldowns     = {       -- v9.1: por ação (o que não está aqui usa Cooldown)
        AdminKick     = 1,
        AdminAnnounce = 5,
        AdminWhisper  = 1,
        AdminScale    = 1,
        AdminFling    = 1,
        AdminLaunch   = 1,
    },
    MaxText       = 200,    -- limite de caracteres de anúncio/mensagem/motivo
    AuditSize     = 200,    -- quantas entradas o registro guarda

    FlingPower    = 160,
    LaunchPower   = 220,
    SpinSpeed     = 20,     -- rad/s
    BalloonSpeed  = 6,      -- studs/s para cima
    BalloonMax    = 20,     -- segundos: o balão se desliga sozinho
    TripTime      = 2,      -- segundos no chão
    Scale = { tiny = 0.5, normal = 1, giant = 2.5 },
}

--------------------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------------------
local NAMES = {
    "AdminKick", "AdminPull", "AdminFreeze", "AdminTeleport",
    "AdminAnnounce", "AdminWhisper",
    "AdminFling", "AdminSpin", "AdminTrip", "AdminLaunch",
    "AdminSit", "AdminScale", "AdminBalloon",
}

local R = {}
for _, name in ipairs(NAMES) do
    local r = ReplicatedStorage:FindFirstChild(name)
    if r and not r:IsA("RemoteEvent") then
        warn("[HYGE] ReplicatedStorage." .. name .. " existe mas não é RemoteEvent — ignorado")
        r = nil
    elseif not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = ReplicatedStorage
    end
    R[name] = r
end

--------------------------------------------------------------------------------
-- REGISTRO (auditoria): aceitas e recusas, no Output e em shared.HYGE_AUDIT
--------------------------------------------------------------------------------
local AuditLog = {}
shared.HYGE_AUDIT = AuditLog
local refusedWarn = {}   -- [Player] = { [motivo] = os.clock() } — sem spam no Output

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

-- recusa: sempre no registro; no Output no máximo 1x a cada 10 s por motivo
local function Refuse(player, remoteName, reason)
    Record({ ok = false, by = player.UserId, name = player.Name, action = remoteName, reason = reason })
    local now = os.clock()
    local seen = refusedWarn[player] or {}
    refusedWarn[player] = seen
    if not seen[reason] or now - seen[reason] > 10 then
        seen[reason] = now
        warn(("[HYGE] RECUSADO %s (%d) %s: %s"):format(player.Name, player.UserId, remoteName, reason))
    end
end

--------------------------------------------------------------------------------
-- QUEM É ADMIN (calculado no servidor, com cache por jogador)
--------------------------------------------------------------------------------
local adminCache = {}   -- [Player] = true/false
local lastAction = {}   -- [Player] = { [remote] = os.clock() da última ação }

local function ComputeAdmin(player)
    for _, id in ipairs(CONFIG.AdminIds) do
        if player.UserId == id then return true end
    end
    if CONFIG.OwnerIsAdmin and game.CreatorType == Enum.CreatorType.User
        and game.CreatorId == player.UserId and player.UserId > 0 then
        return true
    end
    if CONFIG.GroupId and CONFIG.GroupId > 0 then
        -- falhou a consulta (Roblox fora do ar) = NÃO é admin
        local ok, rank = pcall(function() return player:GetRankInGroup(CONFIG.GroupId) end)
        if ok and type(rank) == "number" and rank >= CONFIG.GroupMinRank then return true end
    end
    return false
end

local function IsAdmin(player)
    if adminCache[player] == nil then adminCache[player] = ComputeAdmin(player) end
    return adminCache[player]
end

Players.PlayerAdded:Connect(function(p) adminCache[p] = ComputeAdmin(p) end)
Players.PlayerRemoving:Connect(function(p)
    adminCache[p] = nil
    lastAction[p] = nil
    refusedWarn[p] = nil
end)

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

-- devolve para o painel do admin (o painel escuta AdminWhisper)
local function Notify(admin, text)
    if R.AdminWhisper and admin and admin.Parent then
        R.AdminWhisper:FireClient(admin, "HYGE", text)
    end
end

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
    if not root then return false end
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
-- VALIDAÇÃO DE ARGUMENTOS (v9.1). Cada validador devolve ok, valor limpo.
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
--   opts.protect = alvo admin é recusado (se CONFIG.ProtectAdmins)
--   opts.args    = validadores dos argumentos seguintes (na ordem)
-- Ordem: admin? -> limite da ação -> alvo -> argumentos -> ação. Qualquer
-- "não" para tudo, vai para o registro e (se for admin) avisa o painel.
--------------------------------------------------------------------------------
local function Handle(remoteName, opts, fn)
    local remote = R[remoteName]
    if not remote then return end
    local validators = opts.args or {}
    local cooldown = CONFIG.Cooldowns[remoteName] or CONFIG.Cooldown

    remote.OnServerEvent:Connect(function(player, ...)
        if not IsAdmin(player) then
            Refuse(player, remoteName, "não é admin")
            return
        end

        local now = os.clock()
        local mine = lastAction[player] or {}
        lastAction[player] = mine
        if mine[remoteName] and now - mine[remoteName] < cooldown then
            Refuse(player, remoteName, "limite da ação (" .. cooldown .. "s)")
            Notify(player, ("✗ %s: espere %.1fs"):format(remoteName, cooldown - (now - mine[remoteName])))
            return
        end
        mine[remoteName] = now   -- conta a tentativa (pedido inválido também gasta)

        local args = table.pack(...)
        local i = 1
        local target
        if opts.target then
            target = Target(args[1])
            if not target then
                Refuse(player, remoteName, "alvo inválido ou fora do servidor")
                Notify(player, "✗ " .. remoteName .. ": jogador não está no servidor")
                return
            end
            if opts.protect and CONFIG.ProtectAdmins and target ~= player and IsAdmin(target) then
                Refuse(player, remoteName, "alvo é admin")
                Notify(player, "✗ " .. remoteName .. ": " .. target.Name .. " também é admin")
                return
            end
            i = 2
        end

        local clean = {}
        for n, check in ipairs(validators) do
            local ok, v = check(args[i + n - 1])
            if not ok then
                Refuse(player, remoteName, "argumento " .. n .. " inválido")
                Notify(player, "✗ " .. remoteName .. ": argumento inválido")
                return
            end
            clean[n] = v
        end

        local ok, err = pcall(fn, player, target, table.unpack(clean, 1, #validators))
        if not ok then
            Refuse(player, remoteName, "falhou: " .. tostring(err))
            Notify(player, "✗ " .. remoteName .. ": " .. tostring(err))
        end
    end)
end

--------------------------------------------------------------------------------
-- MODERAÇÃO
--------------------------------------------------------------------------------
Handle("AdminKick", { target = true, protect = true, args = { Arg.optText } }, function(admin, target, reason)
    local text = reason or "Removido por um admin"
    text = FilterFor(text, admin.UserId, target) or "Removido por um admin"
    if FullyCensored(text) then text = "Removido por um admin" end
    Audit(admin, "kick", target)
    Notify(admin, "✓ Kick: " .. target.Name)
    target:Kick(text)
end)

Handle("AdminPull", { target = true }, function(admin, target)
    local mine = Root(admin)
    if not mine or not target.Character then error("sem personagem", 0) end
    target.Character:PivotTo(mine.CFrame * CFrame.new(0, 0, -4))
    Audit(admin, "bring", target)
    Notify(admin, "✓ Bring: " .. target.Name)
end)

Handle("AdminTeleport", { target = true }, function(admin, target)
    local theirs = Root(target)
    if not theirs or not admin.Character then error("sem personagem", 0) end
    admin.Character:PivotTo(theirs.CFrame * CFrame.new(0, 0, 4))
    Audit(admin, "goto", target)
    Notify(admin, "✓ Goto: " .. target.Name)
end)

Handle("AdminFreeze", { target = true, protect = true, args = { Arg.optBool } }, function(admin, target, on)
    if on == nil then on = true end
    local root = Root(target)
    if not root then error("alvo sem personagem", 0) end
    root.Anchored = on
    Audit(admin, on and "freeze" or "unfreeze", target)
    Notify(admin, (on and "✓ Freeze: " or "✓ Unfreeze: ") .. target.Name)
end)

--------------------------------------------------------------------------------
-- COMUNICAÇÃO (sempre filtrada)
--------------------------------------------------------------------------------
Handle("AdminAnnounce", { args = { Arg.text } }, function(admin, _, text)
    local safe = FilterFor(text, admin.UserId, nil)
    if not safe then error("o filtro do Roblox não respondeu — nada foi enviado", 0) end
    if FullyCensored(safe) then error("o filtro do Roblox bloqueou a mensagem — nada foi enviado", 0) end
    Audit(admin, "announce", nil, safe)
    R.AdminAnnounce:FireAllClients(admin.Name, safe)
end)

Handle("AdminWhisper", { target = true, args = { Arg.text } }, function(admin, target, text)
    local safe = FilterFor(text, admin.UserId, target)
    if not safe then error("o filtro do Roblox não respondeu — nada foi enviado", 0) end
    if FullyCensored(safe) then error("o filtro do Roblox bloqueou a mensagem — nada foi enviado", 0) end
    Audit(admin, "whisper", target)
    R.AdminWhisper:FireClient(target, admin.Name, safe)
    Notify(admin, "✓ Mensagem entregue para " .. target.Name)
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
    Audit(admin, "fling", target)
    Notify(admin, "✓ Fling: " .. target.Name)
end)

Handle("AdminLaunch", { target = true, protect = true }, function(admin, target)
    WithServerPhysics(target, 1.5, function(root)
        root.AssemblyLinearVelocity = Vector3.new(0, CONFIG.LaunchPower, 0)
    end)
    Audit(admin, "launch", target)
    Notify(admin, "✓ Launch: " .. target.Name)
end)

Handle("AdminTrip", { target = true, protect = true }, function(admin, target)
    local h = Hum(target)
    if not h then error("alvo sem personagem", 0) end
    h.PlatformStand = true
    WithServerPhysics(target, CONFIG.TripTime, function(root)
        root.AssemblyAngularVelocity = root.CFrame.RightVector * 8
    end)
    task.delay(CONFIG.TripTime, function()
        if h.Parent then h.PlatformStand = false end
    end)
    Audit(admin, "trip", target)
    Notify(admin, "✓ Trip: " .. target.Name)
end)

Handle("AdminSit", { target = true, protect = true }, function(admin, target)
    local h = Hum(target)
    if not h then error("alvo sem personagem", 0) end
    h.Sit = true
    Audit(admin, "sit", target)
    Notify(admin, "✓ Sit: " .. target.Name)
end)

Handle("AdminScale", { target = true, protect = true, args = { Arg.oneOf(CONFIG.Scale) } }, function(admin, target, mode)
    local factor = CONFIG.Scale[mode]
    if not target.Character then error("alvo sem personagem", 0) end
    target.Character:ScaleTo(factor)
    Audit(admin, "scale", target, mode)
    Notify(admin, "✓ Scale " .. mode .. ": " .. target.Name)
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
    if not root then error("alvo sem personagem", 0) end
    ClearConstraint(root, "HYGE_Spin")
    if on ~= false then
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
    Audit(admin, on ~= false and "spin on" or "spin off", target)
    Notify(admin, (on ~= false and "✓ Spin ON: " or "✓ Spin OFF: ") .. target.Name)
end)

Handle("AdminBalloon", { target = true, protect = true, args = { Arg.optBool } }, function(admin, target, on)
    local root = Root(target)
    if not root then error("alvo sem personagem", 0) end
    ClearConstraint(root, "HYGE_Balloon")
    if on ~= false then
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
                Notify(admin, "Balloon de " .. target.Name .. " desligou sozinho ("
                    .. CONFIG.BalloonMax .. "s)")
            end
        end)
    end
    Audit(admin, on ~= false and "balloon on" or "balloon off", target)
    Notify(admin, (on ~= false and "✓ Balloon ON: " or "✓ Balloon OFF: ") .. target.Name)
end)

print(("[HYGE] servidor pronto — %d Remotes, %d admin(s) por UserId%s")
    :format(#NAMES, #CONFIG.AdminIds,
        CONFIG.GroupId > 0 and (", grupo " .. CONFIG.GroupId .. " rank >= " .. CONFIG.GroupMinRank) or ""))
