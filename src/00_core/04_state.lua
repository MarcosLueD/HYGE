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

