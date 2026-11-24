--------------------------------------------------------------------------------
-- REMOTES (opcionais — o painel funciona sem eles, em modo local)
--------------------------------------------------------------------------------
local Remotes = {
    Pull     = ReplicatedStorage:FindFirstChild("AdminPull"),
    Whisper  = ReplicatedStorage:FindFirstChild("AdminWhisper"),
    Announce = ReplicatedStorage:FindFirstChild("AdminAnnounce"),
    Kick     = ReplicatedStorage:FindFirstChild("AdminKick"),
    Freeze   = ReplicatedStorage:FindFirstChild("AdminFreeze"),
    Teleport = ReplicatedStorage:FindFirstChild("AdminTeleport"),
    Fling    = ReplicatedStorage:FindFirstChild("AdminFling"),
    Spin     = ReplicatedStorage:FindFirstChild("AdminSpin"),
    Trip     = ReplicatedStorage:FindFirstChild("AdminTrip"),
    Launch   = ReplicatedStorage:FindFirstChild("AdminLaunch"),
    Sit      = ReplicatedStorage:FindFirstChild("AdminSit"),
    Scale    = ReplicatedStorage:FindFirstChild("AdminScale"),
    Balloon  = ReplicatedStorage:FindFirstChild("AdminBalloon"),
}

--------------------------------------------------------------------------------
-- ESTADO
--------------------------------------------------------------------------------
local State = {
    FlySpeed        = 50,
    WalkSpeed       = 16,
    JumpPower       = 50,
    WallAlpha       = 0.75,
    DroneSpeed      = 70,
    DroneSens       = 4,
    DroneSmooth     = 8,
    GravityPct      = 25,    -- v8.1: % da gravidade normal com Anti-Gravidade ligado
    SelectedPlayer  = nil,
    Spectating      = false,
    SpectateTarget  = nil,
    Waypoints       = {},
    Emotes          = {},
    JoinTimes       = {},
    Fps             = 60,
    ActiveTab       = "Home",
    Minimized       = false,

    -- preferencias do painel (aba Settings)
    Settings = {
        Animations   = true,
        Toasts       = true,
        ShowLogs     = true,
        MaxLog       = 60,
        Confirm      = true,
        Transparency = 0,
        Compact      = false,
        EspAuto      = true,
        NoShiftLock  = true,   -- v9.0.1: Shift não liga o Shift Lock do Roblox
    },
    CmdHistory = {},
}

local SET = State.Settings

local Conn        = {}   -- conexões nomeadas, fáceis de derrubar
local Bin         = {}   -- instâncias criadas fora da GUI (limpar no unload)
local NoclipParts = {}
local WallCache   = {}
local Esp         = {}   -- [userId] = { highlight=, billboard=, name=, dist=, healthBar=, tracer= }

local DroneSpeedSlider, WalkSlider, JumpSlider, FlySlider  -- forward: sliders
local RenderWaypoints, RebuildPlayerRows, UpdatePlayerRows  -- forward
local UpdateSelectedInfo, UpdateServerInfo, SelectPlayer, Unload  -- forward
local PlayerRows, Tiles, serverStart, ApplyPreset, RenderLog  -- forward
local RefreshQuick, ApplyTheme, ClearLog  -- forward
local Toast, Log, ConsoleFrame  -- forward: definidos nos blocos de toast/console
local Emote = { Speed = 1 }  -- animacoes: .Play / .Stop / .track / .id
local DroneHUD = {}  -- HUD do modo drone: .Create/.Show/.Hide/.Update/.Destroy
local Icon, IconTint, SetChips  -- forward: icones vetoriais + chips da topbar
local V8 = {}  -- v8.0: situacoes, config em disco, busca global

-- v8.1: módulos que carregam ANTES do scheduler (90_runtime/04_scheduler.lua)
-- registram trabalho periódico aqui; o scheduler roda tudo no mesmo Heartbeat
-- e depois troca V8.Job pelo Every dele. Nada de loop próprio por módulo.
V8.Jobs = {}
V8.Job = function(interval, fn) table.insert(V8.Jobs, { interval, fn }) end
-- v8.1: [aba] = fn — roda 1x/s só enquanto essa aba está visível
V8.TabTick = {}

-- v9.0: MÓDULOS ISOLADOS. O build embrulha cada módulo (que não declara
-- 'local' no topo) em V8.Mod(nome, linha inicial, linha final, fn): se ele
-- quebrar ao carregar, só ele falha e o boot conta qual foi e em que linha.
V8.BootT0 = os.clock()
V8.Mods = {}     -- { name, from, to, ms, ok, err }
V8.Errors = {}   -- últimos erros do log (Diagnóstico)
V8.Mod = function(name, from, to, fn)
    local t0 = os.clock()
    local ok, err = pcall(fn)
    local rec = { name = name, from = from, to = to, ok = ok,
                  ms = (os.clock() - t0) * 1000, err = (not ok) and tostring(err) or nil }
    table.insert(V8.Mods, rec)
    if not ok then
        rec.err = V8.Where(rec.err)
        warn("[HYGE] módulo " .. name .. " falhou ao carregar: " .. rec.err)
    end
end

-- "HYGE:1234: msg" -> "src/arquivo.lua:12: msg" (linha do main.lua -> do src/).
-- Usa o V8.SrcMap do fim do arquivo (todos os módulos) ou, durante o boot,
-- as faixas dos módulos que já carregaram.
V8.Where = function(msg)
    msg = tostring(msg)
    local function Map(line)
        for _, m in ipairs(V8.SrcMap or {}) do
            if line >= m[2] and line <= m[3] then return m[1] .. ":" .. (line - m[2] + 1) end
        end
        for _, m in ipairs(V8.Mods) do
            if m.from and line >= m.from and line <= m.to then
                return m.name .. ":" .. (line - m.from + 1)
            end
        end
    end
    local function Sub(n)
        local w = Map(tonumber(n))
        return w and (w .. ":") or nil   -- nil = deixa como estava
    end
    msg = msg:gsub('%[string "[^"]*"%]:(%d+):', Sub)
    -- só nomes de chunk ("HYGE" do loader, "...Script" do executor): um
    -- "velocidade:50:" qualquer no meio da mensagem não é linha de código
    msg = msg:gsub("([%w_%.]+):(%d+):", function(p, n)
        if p == "HYGE" or p:find("Script", 1, true) then return Sub(n) end
        return nil
    end)
    return msg
end

-- v9.0: compara texto sem acento e sem caixa ("Aparência" ~ "aparencia").
-- string.lower não conhece UTF-8: as letras acentuadas (2 bytes, 0xC3 ..)
-- são trocadas pela letra sem acento.
V8.Fold = function(s)
    s = tostring(s or ""):lower()
    return (s:gsub("\195[\128-\191]", function(c)
        local b = c:byte(2)
        if b >= 160 then b = b - 32 end   -- minúscula -> faixa da maiúscula
        if b >= 128 and b <= 133 then return "a" end
        if b == 135 then return "c" end
        if b >= 136 and b <= 139 then return "e" end
        if b >= 140 and b <= 143 then return "i" end
        if b == 145 then return "n" end
        if b >= 146 and b <= 150 then return "o" end
        if b >= 153 and b <= 156 then return "u" end
        return c
    end))
end

local function Track(inst) table.insert(Bin, inst) return inst end
local function Drop(name)
    if Conn[name] then Conn[name]:Disconnect() Conn[name] = nil end
end

-- [conns:begin] (tests/diag.test.js roda este bloco)
--------------------------------------------------------------------------------
-- v9.1: CONTABILIDADE DE CONEXÕES E TAREFAS (Configurações › Diagnóstico)
-- Conn continua igual para quem usa (Conn.Nome = sinal:Connect(...) / Drop),
-- mas por baixo cada conexão é contada — criadas, encerradas, ativas — e
-- anotada com a linha de onde veio (vira src/arquivo.lua no relatório).
-- Trocar Conn.Nome sem Drop agora DESCONECTA a antiga (antes ela ficava viva
-- para sempre, sem ninguém com a referência) e conta como "reaproveitada".
-- Para listar: V8.Conns.live (pairs(Conn) não enxerga nada: é um proxy).
--------------------------------------------------------------------------------
do
    local info = (type(debug) == "table" and type(debug.info) == "function") and debug.info or nil
    -- linhas da pilha de quem chamou (o relatório pula as deste arquivo)
    V8.CallSite = function()
        if not info then return nil end
        local out = {}
        for lv = 2, 7 do
            local ok, l = pcall(info, lv, "l")
            if ok and type(l) == "number" and l > 0 then table.insert(out, l) end
        end
        return out
    end

    V8.Conns = { live = {}, meta = {}, created = 0, closed = 0, replaced = 0, respawns = {} }
    local S = V8.Conns
    local function Close(c)
        local ok, alive = pcall(function() return c.Connected end)
        if ok and alive == false then return false end
        pcall(function() c:Disconnect() end)
        return true
    end
    setmetatable(Conn, {
        __index = S.live,
        __newindex = function(_, k, v)
            local old = S.live[k]
            if old ~= nil and old ~= v then
                -- ainda conectada e trocada por outra = era vazamento
                if Close(old) and v ~= nil then S.replaced = S.replaced + 1 end
                S.closed = S.closed + 1
            end
            S.live[k] = v
            if v == nil then
                S.meta[k] = nil
            elseif v ~= old then
                S.created = S.created + 1
                S.meta[k] = { lines = V8.CallSite(), at = os.clock() }
            end
        end,
    })
end

-- Tarefas: o task do painel é este (o global continua intacto para o resto
-- do jogo). delay/defer/spawn são contados; depois do Unload, tarefa que
-- ainda rodar é anotada em V8.Tasks.late (é algo que "ficou vivo").
V8.Tasks = { scheduled = 0, ran = 0, running = 0, late = {}, lateSeen = {} }
V8.RawTask = task
local task = setmetatable({}, { __index = task })
do
    local real, T = V8.RawTask, V8.Tasks
    local function Late(site)
        if not V8.Unloaded then return end
        local key = site and table.concat(site, ",") or "?"
        if T.lateSeen[key] then return end
        T.lateSeen[key] = true
        table.insert(T.late, site or {})
        local where = (site and site[1] and V8.SrcOf) and V8.SrcOf(site) or "?"
        warn("[HYGE] tarefa rodou depois do unload: " .. tostring(where))
    end
    -- delay/defer: conta ao agendar e ao rodar
    local function Wrap(fn)
        if type(fn) ~= "function" then return fn end
        local site = V8.CallSite()
        T.scheduled = T.scheduled + 1
        return function(...)
            T.ran = T.ran + 1
            Late(site)
            return fn(...)
        end
    end
    task.delay = function(t, fn, ...) return real.delay(t, Wrap(fn), ...) end
    task.defer = function(fn, ...) return real.defer(Wrap(fn), ...) end
    -- spawn: conta quantas estão rodando agora (as que esperam HTTP, wait...)
    task.spawn = function(fn, ...)
        if type(fn) ~= "function" then return real.spawn(fn, ...) end
        local site = V8.CallSite()
        T.scheduled = T.scheduled + 1
        return real.spawn(function(...)
            T.ran = T.ran + 1
            T.running = T.running + 1
            Late(site)
            local r = table.pack(pcall(fn, ...))
            T.running = T.running - 1
            if not r[1] then error(r[2], 0) end
            return table.unpack(r, 2, r.n)
        end, ...)
    end
end
V8.Pending = function() return V8.Tasks.scheduled - V8.Tasks.ran end
-- [conns:end]

-- linha do main.lua -> "src/arquivo.lua:linha" (aceita a lista do CallSite:
-- usa a primeira que não for deste arquivo)
V8.SrcOf = function(lines)
    if type(lines) == "number" then lines = { lines } end
    if type(lines) ~= "table" then return nil end
    local first
    for _, l in ipairs(lines) do
        for _, m in ipairs(V8.SrcMap or {}) do
            if l >= m[2] and l <= m[3] then
                local w = m[1] .. ":" .. (l - m[2] + 1)
                if m[1] ~= "src/00_core/04_state.lua" then return w end
                first = first or w
            end
        end
    end
    return first
end

-- v8.0: catálogo ÚNICO dos Remotes. Aba Server, Ajustes › Sobre, comando
-- 'server' e o tile da Home leem daqui (antes eram 4 listas diferentes e só 6
-- dos 13 Remotes apareciam). { chave em Remotes, nome no ReplicatedStorage,
-- o que faz, grupo }
V8.RemoteInfo = {
    { "Kick",     "AdminKick",     "Expulsar jogadores",            "Moderação" },
    { "Pull",     "AdminPull",     "Bring / trazer jogador",        "Moderação" },
    { "Freeze",   "AdminFreeze",   "Congelar / descongelar",        "Moderação" },
    { "Teleport", "AdminTeleport", "Ir até o jogador pelo servidor", "Moderação" },
    { "Announce", "AdminAnnounce", "Anúncio para o servidor",       "Comunicação" },
    { "Whisper",  "AdminWhisper",  "Mensagem privada",              "Comunicação" },
    { "Fling",    "AdminFling",    "Arremessar o alvo",             "Troll" },
    { "Spin",     "AdminSpin",     "Girar o alvo (liga/desliga)",   "Troll" },
    { "Trip",     "AdminTrip",     "Derrubar o alvo",               "Troll" },
    { "Launch",   "AdminLaunch",   "Lançar o alvo para cima",       "Troll" },
    { "Sit",      "AdminSit",      "Forçar o alvo a sentar",        "Troll" },
    { "Scale",    "AdminScale",    "Mudar o tamanho do alvo",       "Troll" },
    { "Balloon",  "AdminBalloon",  "Flutuar o alvo (liga/desliga)", "Troll" },
}

-- devolve: quantos existem, total, lista dos nomes ausentes
V8.RemoteStatus = function()
    local have, missing = 0, {}
    for _, r in ipairs(V8.RemoteInfo) do
        if Remotes[r[1]] then have = have + 1 else table.insert(missing, r[2]) end
    end
    return have, #V8.RemoteInfo, missing
end

-- true enquanto o jogador digita em qualquer TextBox (chat, barra de comandos,
-- campos do painel): fly/freecam/drone não devem andar com as letras digitadas
V8.Typing = function()
    local ok, box = pcall(function() return UserInputService:GetFocusedTextBox() end)
    return ok and box ~= nil
end

