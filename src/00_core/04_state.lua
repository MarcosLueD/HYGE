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

