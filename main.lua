-- =============================================================================
-- HYGE v8.0 — ARQUIVO GERADO, NÃO EDITE AQUI.
-- Fonte: src/   ·   gerar de novo: npm run build  (ou: node build.js)
-- build: 284b05284bb0
-- =============================================================================
--[[
================================================================================
    HYGE ADMIN PANEL v8.0
    Evolucao direta da v7.0 — nada foi reescrito do zero.

    O que a v8.0 trouxe:
      * Shell novo: janela 800x500, TopBar "Welcome home" com relogio e
        dock de icones no rodape (a sidebar continua a um clique em Ajustes)
      * Situacoes (Keypad 1-6): um clique troca o modo de operacao inteiro
      * Busca global (Ctrl+K): situacoes, funcoes, jogadores, waypoints, comandos
      * Config em disco (HYGE/config.json) + exportar/importar por clipboard,
        incluindo a posicao da janela
      * Dashboard da Home: cards de status configuraveis, chat rapido e
        Friend Activity
      * Acoes de servidor completas (kick, bring, freeze, announce, whisper,
        fling, spin, trip, launch, sit, scale, balloon) com script de servidor
        pronto em server/ — catalogo unico de Remotes no painel
      * Lista de jogadores e ESP acompanham entradas e saidas em tempo real
      * Freecam refeito (sem "roll", nao anda com o personagem, solta o mouse
        com o painel aberto, scroll muda a velocidade)
      * Teclas de movimento (WASD/E/Q...) nao disparam atalhos enquanto o
        freecam, o drone ou o fly estao usando essas teclas
      * Correcoes: "Registrar no console" agora funciona, log nao vaza memoria
        no registry de tema, conflitos de tecla com console/busca/situacoes,
        janela nao some fora da tela (botao/comando 'center')

    Continua valendo: registry unico de toggles, scheduler unico (1 Heartbeat),
    tudo em pcall, pose de superman procedural no Fly, modo Drone e R6/R15.

    Acoes de servidor SO funcionam com os RemoteEvents correspondentes e
    validacao no servidor (veja server/). Sem eles o botao fica indisponivel e
    o log explica o motivo — nada e simulado.

    Teclas padrao: [B] painel  [F] fly  [N] noclip  [E] esp  [C] freecam
                   [G] drone   [;] comandos  [Ctrl+K] busca  [Keypad 1-6] situacoes

    ESTE ARQUIVO E GERADO a partir de src/ (npm run build). Edite em src/.
================================================================================
]]

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local StarterGui         = game:GetService("StarterGui")
local Lighting           = game:GetService("Lighting")
local TeleportService    = game:GetService("TeleportService")
local Stats              = game:GetService("Stats")
local GuiService         = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--------------------------------------------------------------------------------
-- CONFIGURAÇÃO
--------------------------------------------------------------------------------
local CONFIG = {
    Version   = "v8.0",
    AdminIds  = { LocalPlayer.UserId },  -- << coloque os UserIds dos seus admins
    DefaultTheme = "Azul",               -- tema de quem nunca salvou config
    PanelKey  = Enum.KeyCode.B,
    ConsoleKey= Enum.KeyCode.Semicolon,
    UiScale   = 1,
    MaxLog    = 60,

    -- Logo: suba a imagem em create.roblox.com > Development Items > Decals,
    -- copie o ID e cole aqui como "rbxassetid://SEU_ID". Vazio = logo em texto.
    LogoId    = "",

    -- Pose de voo. Por padrão o painel monta a pose de superman na mão
    -- (dobra os ombros/quadris direto nas juntas), então não depende de
    -- nenhum ID de animação e funciona em R6 e R15.
    -- Se você tiver uma animação SUA publicada, cole o ID abaixo e ela
    -- passa a ser usada no lugar da pose manual.
    FlyAnimR6  = "",
    FlyAnimR15 = "",
    FlyAnimSpeed = 1,

    -- Pacote "Endless Aura Floating Pack" (bundle 4899847411546). Os IDs
    -- abaixo ficam guardados pra quando/se o dono do jogo (ou o grupo HYGE)
    -- republicar os assets — hoje o Roblox RECUSA carregar animação de
    -- terceiro (o próprio catálogo marca isPurchasable=false/isOffSale=true
    -- pra esses dois IDs) e a track carrega com Length 0, sem animar nada.
    -- Move = catalog 74203422263286 ("Fall Animation" do pacote)
    -- Idle = catalog 75638427965557 ("Idle Animation" do pacote)
    FlyAnimMove = "rbxassetid://74203422263286",
    FlyAnimIdle = "rbxassetid://75638427965557",
    -- true: usa a pose procedural abaixo (não depende de asset de terceiro).
    -- Se um dia os IDs acima carregarem de verdade, troque pra false.
    FlyUsePose  = true,

    -- Ângulos da pose manual (em graus). Mexa se quiser outro estilo.
    -- Pose "vertical flutuante" (parecida com o thumbnail do Endless Aura
    -- Floating Pack): corpo em pé, pernas dobradas/recolhidas pra cima.
    -- Sinal (+/-) é uma estimativa — não testamos em jogo real. Se alguma
    -- junta dobrar pro lado errado, inverta só o campo dela aqui.
    Pose = {
        ArmFront = -18,    -- braço direito quase colado ao corpo (eixo Z do ombro)
        ArmBack  = -14,    -- braço esquerdo quase colado ao corpo
        ArmOut   = 6,      -- afasta um pouco os braços do tronco (eixo X do ombro)
        Elbow    = 18,     -- dobra o cotovelo pra curva relaxada (só existe em R15)
        LegSpread = 4,     -- abertura leve das pernas
        HipLift  = -70,    -- levanta a coxa pra frente/cima (quadril, R6 e R15)
        KneeFold = 90,     -- dobra a canela sob a coxa (joelho, só existe em R15)
        Waist    = -4,     -- tronco quase ereto (não mais deitado)
        Neck     = -6,     -- cabeça olhando pra frente
        BodyTilt = -10,    -- corpo quase vertical (só inclina um pouco ao se mover)
    },
}

--------------------------------------------------------------------------------
-- TEMAS
--------------------------------------------------------------------------------
local PALETTES = {
    Roxo = {
        Main = Color3.fromRGB(14, 12, 18),   Sidebar = Color3.fromRGB(10, 8, 14),
        Card = Color3.fromRGB(22, 18, 28),   Console = Color3.fromRGB(8, 6, 12),
        Accent = Color3.fromRGB(168, 85, 255), Accent2 = Color3.fromRGB(190, 140, 255),
        Text = Color3.fromRGB(245, 245, 250), Dim = Color3.fromRGB(145, 135, 165),
        Danger = Color3.fromRGB(255, 60, 90), Success = Color3.fromRGB(120, 220, 160),
        Warning = Color3.fromRGB(255, 180, 50), Btn = Color3.fromRGB(28, 22, 38),
        BtnHover = Color3.fromRGB(38, 30, 52), Track = Color3.fromRGB(40, 32, 55),
        Line = Color3.fromRGB(50, 40, 70),
    },
    Ciano = {
        Main = Color3.fromRGB(10, 15, 19),   Sidebar = Color3.fromRGB(7, 11, 14),
        Card = Color3.fromRGB(16, 24, 30),   Console = Color3.fromRGB(6, 10, 13),
        Accent = Color3.fromRGB(60, 220, 235), Accent2 = Color3.fromRGB(150, 240, 250),
        Text = Color3.fromRGB(240, 250, 252), Dim = Color3.fromRGB(130, 155, 165),
        Danger = Color3.fromRGB(255, 70, 90), Success = Color3.fromRGB(110, 230, 160),
        Warning = Color3.fromRGB(255, 190, 60), Btn = Color3.fromRGB(20, 32, 40),
        BtnHover = Color3.fromRGB(28, 44, 54), Track = Color3.fromRGB(30, 48, 58),
        Line = Color3.fromRGB(38, 60, 72),
    },
    Verde = {
        Main = Color3.fromRGB(11, 17, 13),   Sidebar = Color3.fromRGB(8, 13, 10),
        Card = Color3.fromRGB(17, 27, 20),   Console = Color3.fromRGB(6, 11, 8),
        Accent = Color3.fromRGB(90, 230, 130), Accent2 = Color3.fromRGB(160, 245, 190),
        Text = Color3.fromRGB(242, 252, 245), Dim = Color3.fromRGB(135, 165, 145),
        Danger = Color3.fromRGB(255, 80, 95), Success = Color3.fromRGB(120, 235, 165),
        Warning = Color3.fromRGB(250, 200, 80), Btn = Color3.fromRGB(21, 34, 25),
        BtnHover = Color3.fromRGB(30, 48, 36), Track = Color3.fromRGB(32, 52, 38),
        Line = Color3.fromRGB(42, 66, 50),
    },
    Vermelho = {
        Main = Color3.fromRGB(19, 11, 13),   Sidebar = Color3.fromRGB(14, 8, 10),
        Card = Color3.fromRGB(29, 17, 20),   Console = Color3.fromRGB(12, 6, 8),
        Accent = Color3.fromRGB(255, 85, 105), Accent2 = Color3.fromRGB(255, 150, 165),
        Text = Color3.fromRGB(252, 244, 245), Dim = Color3.fromRGB(170, 140, 145),
        Danger = Color3.fromRGB(255, 70, 70), Success = Color3.fromRGB(120, 225, 160),
        Warning = Color3.fromRGB(255, 190, 70), Btn = Color3.fromRGB(38, 22, 26),
        BtnHover = Color3.fromRGB(52, 30, 35), Track = Color3.fromRGB(55, 32, 38),
        Line = Color3.fromRGB(70, 42, 48),
    },
    Azul = {
        Main = Color3.fromRGB(10, 16, 30),   Sidebar = Color3.fromRGB(7, 12, 24),
        Card = Color3.fromRGB(16, 25, 45),   Console = Color3.fromRGB(6, 10, 20),
        Accent = Color3.fromRGB(58, 130, 255), Accent2 = Color3.fromRGB(130, 180, 255),
        Text = Color3.fromRGB(240, 246, 255), Dim = Color3.fromRGB(135, 152, 185),
        Danger = Color3.fromRGB(255, 75, 95), Success = Color3.fromRGB(70, 220, 140),
        Warning = Color3.fromRGB(255, 190, 60), Btn = Color3.fromRGB(24, 36, 62),
        BtnHover = Color3.fromRGB(34, 50, 84), Track = Color3.fromRGB(30, 44, 74),
        Line = Color3.fromRGB(42, 60, 98),
    },
}

local THEME = {}
for k, v in pairs(PALETTES.Roxo) do THEME[k] = v end

-- Registry de pintura: permite trocar de tema em tempo real
local Painted = {}
local function Paint(inst, prop, key)
    inst[prop] = THEME[key]
    table.insert(Painted, { inst = inst, prop = prop, key = key })
    return inst
end

--------------------------------------------------------------------------------
-- CHECAGEM DE ADMIN
--------------------------------------------------------------------------------
local function IsAdmin(player)
    for _, id in ipairs(CONFIG.AdminIds) do
        if player.UserId == id then return true end
    end
    return false
end

if not IsAdmin(LocalPlayer) then
    warn("[HYGE " .. CONFIG.Version .. "] Acesso negado.")
    return
end

print("[HYGE] iniciando " .. CONFIG.Version .. "...")

-- Onde a GUI vai morar.
-- Executor: gethui() / CoreGui (não some no respawn e não depende do PlayerGui).
-- Studio / LocalScript normal: PlayerGui.
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    or LocalPlayer:WaitForChild("PlayerGui", 10)

local GuiParent
do
    local ok, hui = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
        return nil
    end)
    if ok and hui then
        GuiParent = hui
        print("[HYGE] GUI em: gethui()")
    end

    if not GuiParent then
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then
            local writable = pcall(function()
                local probe = Instance.new("Folder")
                probe.Parent = cg
                probe:Destroy()
            end)
            if writable then
                GuiParent = cg
                print("[HYGE] GUI em: CoreGui")
            end
        end
    end

    if not GuiParent then
        GuiParent = PlayerGui
        print("[HYGE] GUI em: PlayerGui")
    end
    if not GuiParent then
        error("[HYGE] não achei um lugar para colocar a GUI")
    end
end

-- Evita duas instâncias abertas ao mesmo tempo (em qualquer um dos parents)
for _, holder in ipairs({ GuiParent, PlayerGui }) do
    if holder then
        local prev = holder:FindFirstChild("HYGE_PANEL")
        if prev then prev:Destroy() end
    end
end

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

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function Char()      return LocalPlayer.Character end
local function Root()
    local c = Char()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function Hum()
    local c = Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function KeyName(kc)
    if not kc then return "—" end
    local n = tostring(kc):gsub("Enum.KeyCode.", "")
    local short = {
        LeftControl = "LCtrl", RightControl = "RCtrl",
        LeftShift = "LShift", RightShift = "RShift",
        LeftAlt = "LAlt", RightAlt = "RAlt",
        Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
        LeftBracket = "[", RightBracket = "]", Backquote = "`", Minus = "-", Equals = "=",
    }
    return short[n] or n
end

local function FindPlayer(query)
    if not query or query == "" then return nil end
    query = query:lower()
    if query == "me" then return LocalPlayer end
    local best, bestLen = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local a, b = p.Name:lower(), p.DisplayName:lower()
        if a == query or b == query then return p end
        local hit = a:find(query, 1, true) or b:find(query, 1, true)
        if hit and #a < bestLen then best, bestLen = p, #a end
    end
    return best
end

local function Comma(n) return tostring(n) end

--------------------------------------------------------------------------------
-- GUI RAIZ
--------------------------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "HYGE_PANEL"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = GuiParent

-- alguns executores exigem protect_gui pra UI não ser limpa
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(Gui) end
end)

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 920, 0, 600)
Window.Position = UDim2.new(0.5, -460, 0.5, -300)
Window.BackgroundColor3 = THEME.Main
Window.BorderSizePixel = 0
Window.Visible = false
Window.Parent = Gui
Paint(Window, "BackgroundColor3", "Main")
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 16)

local WindowScale = Instance.new("UIScale", Window)
WindowScale.Scale = CONFIG.UiScale

local winStroke = Instance.new("UIStroke", Window)
winStroke.Thickness = 1.4
winStroke.Transparency = 0.55
Paint(winStroke, "Color", "Accent")

local winShadow = Instance.new("ImageLabel")
winShadow.Name = "Shadow"
winShadow.AnchorPoint = Vector2.new(0.5, 0.5)
winShadow.Position = UDim2.new(0.5, 0, 0.5, 4)
winShadow.Size = UDim2.new(1, 56, 1, 56)
winShadow.BackgroundTransparency = 1
winShadow.Image = "rbxassetid://6014261993"
winShadow.ImageColor3 = Color3.new(0, 0, 0)
winShadow.ImageTransparency = 0.35
winShadow.ScaleType = Enum.ScaleType.Slice
winShadow.SliceCenter = Rect.new(49, 49, 450, 450)
winShadow.ZIndex = -1
winShadow.Parent = Window

--------------------------------------------------------------------------------
-- TOASTS  (ícone, categoria, barra de duração, fechar, limite de 4)
--------------------------------------------------------------------------------
do
local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "Toasts"
ToastHolder.AnchorPoint = Vector2.new(1, 0)
ToastHolder.Position = UDim2.new(1, -18, 0, 18)
ToastHolder.Size = UDim2.new(0, 310, 1, -36)
ToastHolder.BackgroundTransparency = 1
ToastHolder.Parent = Gui

local toastLayout = Instance.new("UIListLayout", ToastHolder)
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local ToastList = {}
local TOAST_META = {
    info   = { icon = "i", key = "Accent"  },
    ok     = { icon = "+", key = "Success" },
    warn   = { icon = "!", key = "Warning" },
    error  = { icon = "x", key = "Danger"  },
    action = { icon = ">", key = "Accent2" },
}

local function KillToast(card)
    for i = #ToastList, 1, -1 do
        if ToastList[i] == card then table.remove(ToastList, i) end
    end
    if not card or not card.Parent then return end
    local out = TweenInfo.new(0.16)
    for _, d in ipairs(card:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            TweenService:Create(d, out, { TextTransparency = 1 }):Play()
        elseif d:IsA("Frame") then
            TweenService:Create(d, out, { BackgroundTransparency = 1 }):Play()
        elseif d:IsA("UIStroke") then
            TweenService:Create(d, out, { Transparency = 1 }):Play()
        end
    end
    TweenService:Create(card, out, { BackgroundTransparency = 1 }):Play()
    task.delay(0.2, function() if card then card:Destroy() end end)
end

Toast = function(text, kind, duration)
    if not SET.Toasts then return end
    local meta = TOAST_META[kind or "info"] or TOAST_META.info
    duration = duration or 2.6

    -- limite de toasts simultâneos: derruba os mais antigos
    while #ToastList >= 4 do
        local old = table.remove(ToastList, 1)
        if old then KillToast(old) end
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = THEME.Card
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = ToastHolder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    table.insert(ToastList, card)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = THEME[meta.key]
    stroke.Transparency = 1

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 20, 0, 20)
    badge.Position = UDim2.new(0, 10, 0, 10)
    badge.BackgroundColor3 = THEME[meta.key]
    badge.BackgroundTransparency = 0.15
    badge.Text = meta.icon
    badge.TextColor3 = Color3.new(0, 0, 0)
    badge.Font = Enum.Font.GothamBlack
    badge.TextSize = 12
    badge.Parent = card
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, 38, 0, 10)
    label.Size = UDim2.new(1, -62, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -8, 0, 8)
    close.Size = UDim2.new(0, 18, 0, 18)
    close.BackgroundTransparency = 1
    close.Text = "x"
    close.TextColor3 = THEME.Dim
    close.TextTransparency = 1
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.AutoButtonColor = false
    close.Parent = card

    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0, 1)
    barBg.Position = UDim2.new(0, 10, 1, -6)
    barBg.Size = UDim2.new(1, -20, 0, 2)
    barBg.BackgroundColor3 = THEME.Track
    barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0
    barBg.Parent = card
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = THEME[meta.key]
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local pad = Instance.new("UIPadding", card)
    pad.PaddingBottom = UDim.new(0, 16)

    local t = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(card, t, { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(label, t, { TextTransparency = 0 }):Play()
    TweenService:Create(close, t, { TextTransparency = 0.3 }):Play()
    TweenService:Create(stroke, t, { Transparency = 0.4 }):Play()
    TweenService:Create(barBg, t, { BackgroundTransparency = 0.6 }):Play()
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 1, 0) }):Play()

    close.MouseButton1Click:Connect(function() KillToast(card) end)
    task.delay(duration, function() KillToast(card) end)
end
end

--------------------------------------------------------------------------------
-- CONSOLE / LOG  (categorias, filtro, limpar, copiar — incremental)
--------------------------------------------------------------------------------
do
ConsoleFrame = Instance.new("Frame")
ConsoleFrame.Name = "Console"
ConsoleFrame.Size = UDim2.new(1, -184, 0, 130)
ConsoleFrame.Position = UDim2.new(0, 172, 1, -142)
ConsoleFrame.BackgroundColor3 = THEME.Console
ConsoleFrame.BorderSizePixel = 0
ConsoleFrame.Parent = Window
Paint(ConsoleFrame, "BackgroundColor3", "Console")
Instance.new("UICorner", ConsoleFrame).CornerRadius = UDim.new(0, 10)

local consoleStroke = Instance.new("UIStroke", ConsoleFrame)
consoleStroke.Transparency = 0.75
Paint(consoleStroke, "Color", "Line")

local LogBar = Instance.new("Frame")
LogBar.Size = UDim2.new(1, -16, 0, 22)
LogBar.Position = UDim2.new(0, 8, 0, 6)
LogBar.BackgroundTransparency = 1
LogBar.Parent = ConsoleFrame

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -14, 1, -36)
LogScroll.Position = UDim2.new(0, 8, 0, 30)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 3
LogScroll.ScrollingDirection = Enum.ScrollingDirection.Y
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.Parent = ConsoleFrame
Paint(LogScroll, "ScrollBarImageColor3", "Accent")

local logLayout = Instance.new("UIListLayout", LogScroll)
logLayout.Padding = UDim.new(0, 1)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- categorias: chave interna -> { rótulo, cor do tema }
local LOG_CAT = {
    info   = { "INFO",  "Dim"     },
    ok     = { "OK",    "Success" },
    warn   = { "AVISO", "Warning" },
    error  = { "ERRO",  "Danger"  },
    action = { "AÇÃO",  "Accent2" },
}
local LOG_ORDER = { "info", "ok", "warn", "error", "action" }

local LogEntries, logLabels, logSeq = {}, {}, 0
local LogFilter = "all"
local logChips = {}

local function LogPasses(e) return LogFilter == "all" or LogFilter == e.cat end

local function MakeLogLine(e)
    local meta = LOG_CAT[e.cat] or LOG_CAT.info
    logSeq = logSeq + 1
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, -6, 0, 17)
    line.BackgroundTransparency = 1
    line.Text = string.format("[%s] %-5s  %s", e.time, meta[1], e.msg)
    line.TextColor3 = THEME[meta[2]]
    line.Font = Enum.Font.Code
    line.TextSize = 12
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.TextTruncate = Enum.TextTruncate.AtEnd
    line.LayoutOrder = logSeq
    line.Parent = LogScroll
    -- v8.0: linhas de log NÃO entram no registry de tema (cada Log() somava uma
    -- entrada que nunca saía — vazamento com Chat Spy ligado). O ApplyTheme
    -- redesenha o log inteiro com RenderLog(nil), que já usa as cores novas.
    table.insert(logLabels, line)
end

RenderLog = function(entry)
    if entry then
        if LogPasses(entry) then MakeLogLine(entry) end
    else
        for _, l in ipairs(logLabels) do if l then l:Destroy() end end
        logLabels = {}
        for _, e in ipairs(LogEntries) do
            if LogPasses(e) then MakeLogLine(e) end
        end
    end
    while #logLabels > SET.MaxLog do
        local first = table.remove(logLabels, 1)
        if first then first:Destroy() end
    end
    LogScroll.CanvasPosition = Vector2.new(0, math.max(0, LogScroll.AbsoluteCanvasSize.Y))
end

ClearLog = function()
    LogEntries = {}
    RenderLog(nil)
end

Log = function(msg, kind)
    kind = kind or "info"
    if not LOG_CAT[kind] then kind = "info" end
    -- v8.0: a opção "Registrar no console" existia mas nunca era lida.
    -- Desligada, só os ERROS continuam chegando no console.
    if SET.ShowLogs == false and kind ~= "error" then return end
    local entry = { time = os.date("%H:%M:%S"), cat = kind, msg = tostring(msg) }
    table.insert(LogEntries, entry)
    while #LogEntries > math.max(SET.MaxLog, 10) do table.remove(LogEntries, 1) end
    RenderLog(entry)
    print("[HYGE] " .. entry.msg)
end

-- chips de filtro + ações do console
do
    local function Chip(text, filter, order, colorKey)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 58, 0, 22)
        b.Position = UDim2.new(0, 46 + (order - 1) * 62, 0, 0)
        b.BackgroundColor3 = THEME[colorKey]
        b.BackgroundTransparency = 0.8
        b.Text = text
        b.TextColor3 = THEME[colorKey]
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = LogBar
        Paint(b, "BackgroundColor3", colorKey)
        Paint(b, "TextColor3", colorKey)
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local cs = Instance.new("UIStroke", b)
        cs.Color = THEME[colorKey]
        cs.Transparency = 1
        logChips[filter] = { btn = b, stroke = cs }
        b.MouseButton1Click:Connect(function()
            LogFilter = filter
            for f, chip in pairs(logChips) do
                local on = (f == filter)
                chip.btn.BackgroundTransparency = on and 0.45 or 0.85
                chip.stroke.Transparency = on and 0.3 or 1
            end
            RenderLog(nil)
        end)
        return b
    end

    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(0, 42, 0, 22)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "LOGS"
    logTitle.TextColor3 = THEME.Text
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextSize = 12
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = LogBar
    Paint(logTitle, "TextColor3", "Text")

    Chip("TUDO", "all", 1, "Text")
    for i, cat in ipairs(LOG_ORDER) do
        Chip(LOG_CAT[cat][1], cat, i + 1, LOG_CAT[cat][2])
    end
    logChips.all.btn.BackgroundTransparency = 0.45
    logChips.all.stroke.Transparency = 0.3

    local function MiniBtn(text, offset, colorKey, fn)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, 0)
        b.Position = UDim2.new(1, -offset, 0, 1)
        b.Size = UDim2.new(0, 66, 0, 22)
        b.BackgroundColor3 = THEME.Btn
        b.Text = "  " .. text
        b.TextColor3 = THEME[colorKey]
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = LogBar
        Paint(b, "BackgroundColor3", "Btn")
        Paint(b, "TextColor3", colorKey)
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        if Icon then
            local ic = Icon(b, (text == "LIMPAR") and "trash" or "copy", THEME[colorKey], 12)
            ic.Position = UDim2.new(0, 8, 0.5, -6)
            b.Text = "     " .. text
        end
        b.MouseButton1Click:Connect(fn)
        return b
    end

    MiniBtn("COPIAR", 72, "Accent", function()
        local out = {}
        for _, e in ipairs(LogEntries) do
            local meta = LOG_CAT[e.cat] or LOG_CAT.info
            table.insert(out, string.format("[%s] %s  %s", e.time, meta[1], e.msg))
        end
        local text = table.concat(out, "\n")
        if setclipboard then
            setclipboard(text)
            Toast("Log copiado (" .. #LogEntries .. " linhas)", "ok", 1.6)
        else
            print(text)
            Toast("Executor sem setclipboard — log jogado no output", "warn")
        end
    end)

    MiniBtn("LIMPAR", 2, "Warning", function() ClearLog() end)
end
end

--------------------------------------------------------------------------------
-- TOP BAR / SIDEBAR / CONTENT
--------------------------------------------------------------------------------
local TopBar, Stat, CloseBtn, MinBtn, Sidebar, Content  -- usados fora do bloco
do
TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 56)
TopBar.BackgroundColor3 = THEME.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = Window
Paint(TopBar, "BackgroundColor3", "Sidebar")
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 16)
topFix.Position = UDim2.new(0, 0, 1, -16)
topFix.BackgroundColor3 = THEME.Sidebar
topFix.BorderSizePixel = 0
topFix.Parent = TopBar
Paint(topFix, "BackgroundColor3", "Sidebar")

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 16, 0.5, -15)
Logo.BackgroundColor3 = THEME.Accent
Logo.BorderSizePixel = 0
Logo.Parent = TopBar
Paint(Logo, "BackgroundColor3", "Accent")
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 9)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "H"
logoText.TextColor3 = Color3.new(0, 0, 0)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 17
logoText.Parent = Logo

-- Com LogoId preenchido a caixa vira a imagem da marca (fundo some)
if CONFIG.LogoId ~= "" then
    Logo.BackgroundTransparency = 1
    logoText.Visible = false
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, 6, 1, 6)
    img.Position = UDim2.new(0, -3, 0, -3)
    img.BackgroundTransparency = 1
    img.Image = CONFIG.LogoId
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = Logo
end

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Position = UDim2.new(0, 56, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "HYGE"
Title.TextColor3 = THEME.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar
Paint(Title, "TextColor3", "Text")

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 60, 0, 18)
Version.Position = UDim2.new(0, 116, 0.5, -8)
Version.BackgroundColor3 = THEME.Btn
Version.Text = CONFIG.Version
Version.TextColor3 = THEME.Accent
Version.Font = Enum.Font.GothamBold
Version.TextSize = 11
Version.Size = UDim2.new(0, 40, 0, 18)
Version.Parent = TopBar
Paint(Version, "BackgroundColor3", "Btn")
Paint(Version, "TextColor3", "Accent")
Instance.new("UICorner", Version).CornerRadius = UDim.new(0, 5)

Stat = Instance.new("TextLabel")
Stat.Size = UDim2.new(0, 400, 1, 0)
Stat.Position = UDim2.new(1, -500, 0, 0)
Stat.BackgroundTransparency = 1
Stat.TextColor3 = THEME.Dim
Stat.Font = Enum.Font.Code
Stat.TextSize = 12
Stat.TextXAlignment = Enum.TextXAlignment.Right
Stat.Text = "..."
Stat.Parent = TopBar
Paint(Stat, "TextColor3", "Dim")

local function WindowButton(symbol, order, colorKey)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.Position = UDim2.new(1, -16 - (order * 36), 0.5, -15)
    b.BackgroundColor3 = THEME.Btn
    b.Text = symbol
    b.TextColor3 = THEME.Dim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.AutoButtonColor = false
    b.Parent = TopBar
    Paint(b, "BackgroundColor3", "Btn")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = THEME[colorKey or "Accent"], TextColor3 = Color3.new(0, 0, 0) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = THEME.Btn, TextColor3 = THEME.Dim }):Play()
    end)
    return b
end

CloseBtn = WindowButton("X", 1, "Danger")
MinBtn   = WindowButton("—", 2, "Accent")

--------------------------------------------------------------------------------
-- SIDEBAR
--------------------------------------------------------------------------------
Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 164, 1, -56)
Sidebar.Position = UDim2.new(0, 0, 0, 56)
Sidebar.BackgroundColor3 = THEME.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window
Paint(Sidebar, "BackgroundColor3", "Sidebar")

local sidePad = Instance.new("UIPadding", Sidebar)
sidePad.PaddingTop = UDim.new(0, 10)
sidePad.PaddingLeft = UDim.new(0, 10)
sidePad.PaddingRight = UDim.new(0, 10)

local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0, 3)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -184, 1, -214)
Content.Position = UDim2.new(0, 172, 0, 64)
Content.BackgroundTransparency = 1
Content.Parent = Window
end

--------------------------------------------------------------------------------
-- FÁBRICA DE UI
--------------------------------------------------------------------------------
local Tabs, NavButtons = {}, {}
local ShowTab  -- forward

local function CreateTab(name)
    local f = Instance.new("ScrollingFrame")
    f.Name = name
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Visible = false
    f.ScrollBarThickness = 3
    f.ScrollingDirection = Enum.ScrollingDirection.Y
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.Parent = Content
    Paint(f, "ScrollBarImageColor3", "Accent")

    local layout = Instance.new("UIListLayout", f)
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", f)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 10)

    Tabs[name] = f
    return f
end

local TabHooks = {}
local function OnTabOpen(name, fn)
    if not TabHooks[name] then TabHooks[name] = {} end
    table.insert(TabHooks[name], fn)
end

ShowTab = function(name)
    if not Tabs[name] then return end
    for n, t in pairs(Tabs) do
        if t.Visible and n ~= name then t.Visible = false end
    end
    local tab = Tabs[name]
    tab.Visible = true
    State.ActiveTab = name

    -- fade-in suave
    for _, d in ipairs(tab:GetDescendants()) do
        if d:IsA("Frame") and d.Name == "Card" then
            d.Position = UDim2.new(0, 0, 0, 6)
            TweenService:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
                { Position = UDim2.new(0, 0, 0, 0) }):Play()
        end
    end

    for n, b in pairs(NavButtons) do
        local active = (n == name)
        TweenService:Create(b.button, TweenInfo.new(0.14), {
            BackgroundColor3 = active and THEME.Accent or THEME.Sidebar,
            BackgroundTransparency = active and 0.82 or 0,
        }):Play()
        if b.label then
            TweenService:Create(b.label, TweenInfo.new(0.14), {
                TextColor3 = active and THEME.Accent or THEME.Dim }):Play()
        end
        if b.stroke then
            b.stroke.Color = THEME.Accent
            TweenService:Create(b.stroke, TweenInfo.new(0.14), {
                Transparency = active and 0.35 or 1 }):Play()
        end
        if IconTint then IconTint(b.icon, active and THEME.Accent or THEME.Dim) end
        TweenService:Create(b.pill, TweenInfo.new(0.16), {
            Size = active and UDim2.new(0, 3, 0, 22) or UDim2.new(0, 3, 0, 0),
            BackgroundColor3 = THEME.Accent,
        }):Play()
    end

    if TabHooks[name] then
        for _, hook in ipairs(TabHooks[name]) do
            local ok, err = pcall(hook)
            if not ok then Log("hook " .. name .. ": " .. tostring(err), "error") end
        end
    end
end

local function AddNav(name, order)
    local NAV_ICON = {
        Home = "home", Movement = "user", Visuals = "eye", Players = "users",
        Moderation = "shield", Server = "server", Emotes = "grid", Settings = "gear",
        Shop = "bag", Scripts = "terminal", Chat = "chat",   -- v8.0
    }
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 32)   -- v8.0: 11 abas precisam caber na sidebar
    b.BackgroundColor3 = THEME.Sidebar
    b.Text = ""
    b.AutoButtonColor = false
    b.LayoutOrder = order
    b.Parent = Sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)

    local navStroke = Instance.new("UIStroke", b)
    navStroke.Transparency = 1
    navStroke.Color = THEME.Accent

    local ic = Icon and Icon(b, NAV_ICON[name] or "dot", THEME.Dim, 17) or nil
    if ic then ic.Position = UDim2.new(0, 13, 0.5, -8) end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.new(0, 40, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.Dim
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = b

    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(0, 0.5)
    pill.Position = UDim2.new(0, 0, 0.5, 0)
    pill.Size = UDim2.new(0, 3, 0, 0)
    pill.BackgroundColor3 = THEME.Accent
    pill.BorderSizePixel = 0
    pill.Parent = b
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    b.MouseEnter:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(lbl, TweenInfo.new(0.12), { TextColor3 = THEME.Text }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(lbl, TweenInfo.new(0.12), { TextColor3 = THEME.Dim }):Play()
        end
    end)
    b.MouseButton1Click:Connect(function() ShowTab(name) end)

    NavButtons[name] = { button = b, pill = pill, icon = ic, label = lbl,
        stroke = navStroke }
end

local function CreateCard(parent, title, order)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = THEME.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = parent
    Paint(card, "BackgroundColor3", "Card")
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", card)
    stroke.Transparency = 0.5
    Paint(stroke, "Color", "Line")

    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)

    local layout = Instance.new("UIListLayout", card)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    if title then
        local head = Instance.new("TextLabel")
        head.Size = UDim2.new(1, 0, 0, 20)
        head.BackgroundTransparency = 1
        head.Text = title
        head.TextColor3 = THEME.Accent
        head.Font = Enum.Font.GothamBold
        head.TextSize = 13
        head.TextXAlignment = Enum.TextXAlignment.Left
        head.LayoutOrder = -1
        head.Parent = card
        Paint(head, "TextColor3", "Accent")
    end
    return card
end

local function CardTitleRef(card)
    for _, c in ipairs(card:GetChildren()) do
        if c:IsA("TextLabel") and c.LayoutOrder == -1 then return c end
    end
end

local function Grid(parent, cols, cellHeight)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local g = Instance.new("UIGridLayout", holder)
    g.CellPadding = UDim2.new(0, 8, 0, 8)
    g.CellSize = UDim2.new(1 / cols, -8, 0, cellHeight or 34)
    g.SortOrder = Enum.SortOrder.LayoutOrder
    return holder
end

local function CreateButton(parent, text, colorKey, height)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, height or 34)
    b.BackgroundColor3 = THEME.Btn
    b.Text = text
    b.TextColor3 = THEME.Text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Parent = parent
    Paint(b, "BackgroundColor3", "Btn")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke", b)
    stroke.Transparency = 0.8
    Paint(stroke, "Color", colorKey or "Accent")

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {
            BackgroundColor3 = THEME[colorKey or "Accent"], TextColor3 = Color3.new(0, 0, 0) }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.13), { Transparency = 0.2 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.13), {
            BackgroundColor3 = THEME.Btn, TextColor3 = THEME.Text }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.13), { Transparency = 0.8 }):Play()
    end)
    return b
end

local function CreateInput(parent, placeholder, height)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, height or 34)
    box.BackgroundColor3 = THEME.Btn
    box.TextColor3 = THEME.Text
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = THEME.Dim
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Text = ""
    box.Parent = parent
    Paint(box, "BackgroundColor3", "Btn")
    Paint(box, "TextColor3", "Text")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", box)
    stroke.Transparency = 0.85
    Paint(stroke, "Color", "Accent")
    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0.2 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0.85 }):Play()
    end)
    return box
end

local function Divider(parent)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = THEME.Line
    d.BorderSizePixel = 0
    d.Parent = parent
    Paint(d, "BackgroundColor3", "Line")
    return d
end

--------------------------------------------------------------------------------
-- REGISTRY DE TOGGLES  (estado + UI + keybind + log em um só lugar)
--------------------------------------------------------------------------------
local Toggles, ToggleOrder = {}, {}

local function DefineToggle(def)
    def.state = false
    def.listeners = {}
    Toggles[def.id] = def
    table.insert(ToggleOrder, def.id)
    return def
end

local function IsOn(id)
    local t = Toggles[id]
    return t and t.state or false
end

local RefreshStatus  -- forward

local function SetToggle(id, on, silent)
    local t = Toggles[id]
    if not t then return end
    on = not not on
    if t.state == on then return end

    local fn = on and t.enable or t.disable
    local ok, err = pcall(fn)
    if not ok then
        Log(t.label .. " falhou: " .. tostring(err), "error")
        Toast(t.label .. " falhou", "error")
        return
    end

    t.state = on
    for _, l in ipairs(t.listeners) do pcall(l, on) end
    if not silent then
        Log(t.label .. ": " .. (on and "ON" or "OFF"), on and "ok" or nil)
        Toast(t.label .. (on and "  ativado" or "  desativado"), on and "ok" or "warn", 1.6)
    end
    if RefreshStatus then RefreshStatus() end
end

local function Flip(id) SetToggle(id, not IsOn(id)) end

-- Switch animado
local function SwitchRow(parent, id, labelText, description)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, description and 46 or 36)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -70, 0, 18)
    name.Position = UDim2.new(0, 0, 0, description and 4 or 9)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamMedium
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -70, 0, 14)
        desc.Position = UDim2.new(0, 0, 0, 24)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.TextColor3 = THEME.Dim
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = row
        Paint(desc, "TextColor3", "Dim")
    end

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.new(0, 46, 0, 24)
    track.BackgroundColor3 = THEME.Track
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = THEME.Dim
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function render(on)
        TweenService:Create(track, TweenInfo.new(0.16), {
            BackgroundColor3 = on and THEME.Accent or THEME.Track }):Play()
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and Color3.new(1, 1, 1) or THEME.Dim }):Play()
    end

    track.MouseButton1Click:Connect(function() Flip(id) end)
    if Toggles[id] then
        table.insert(Toggles[id].listeners, render)
        render(Toggles[id].state)
    end
    return row, render
end

--------------------------------------------------------------------------------
-- KEYBINDS
--------------------------------------------------------------------------------
local Keybinds = {}      -- [toggleId] = KeyCode
local KeybindLabels = {}
local capturing, captureConn = nil, nil

local function StopCapture()
    if captureConn then captureConn:Disconnect() captureConn = nil end
    if capturing and KeybindLabels[capturing] then
        KeybindLabels[capturing].Text = KeyName(Keybinds[capturing])
    end
    capturing = nil
end

local function KeybindRow(parent, id, labelText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -110, 1, 0)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamMedium
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.new(0, 96, 0, 28)
    btn.BackgroundColor3 = THEME.Btn
    btn.Text = KeyName(Keybinds[id])
    btn.TextColor3 = THEME.Accent2
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = row
    Paint(btn, "BackgroundColor3", "Btn")
    Paint(btn, "TextColor3", "Accent2")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Transparency = 0.6
    Paint(stroke, "Color", "Accent")

    KeybindLabels[id] = btn

    btn.MouseButton1Click:Connect(function()
        if capturing == id then StopCapture() return end
        StopCapture()
        capturing = id
        btn.Text = "aperte..."
        Toast("Aperte uma tecla para " .. labelText .. " (Backspace remove)", nil, 3)

        captureConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if capturing ~= id then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Unknown then return end

            if kc == Enum.KeyCode.Backspace then
                Keybinds[id] = nil
                Log("Keybind removido: " .. labelText)
                StopCapture()
                return
            end
            -- v8.0: console e busca (sem Ctrl) também são teclas do painel —
            -- o handler global trata essas antes dos toggles, então o atalho
            -- nunca dispararia
            if kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey
                or (kc == CONFIG.SearchKey and not CONFIG.SearchCtrl) then
                Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                return
            end
            -- conflito: avisa em vez de apagar em silencio
            for otherId, otherKc in pairs(Keybinds) do
                if otherKc == kc and otherId ~= id then
                    Keybinds[otherId] = nil
                    if KeybindLabels[otherId] then KeybindLabels[otherId].Text = "—" end
                    local other = Toggles[otherId] and Toggles[otherId].label or otherId
                    Log("[" .. KeyName(kc) .. "] estava em '" .. other
                        .. "' — esse atalho ficou sem tecla", "warn")
                    Toast("'" .. other .. "' perdeu o atalho [" .. KeyName(kc) .. "]", "warn")
                end
            end
            -- v8.0: situações também disputam teclas (e ganham no handler global)
            if V8.Sit and V8.Sit.Keys then
                for sitName, sitKc in pairs(V8.Sit.Keys) do
                    if sitKc == kc then
                        V8.Sit.Keys[sitName] = nil
                        Log("[" .. KeyName(kc) .. "] estava na situação '" .. sitName
                            .. "' — ela ficou sem tecla", "warn")
                        Toast("Situação '" .. sitName .. "' perdeu o atalho", "warn")
                    end
                end
                pcall(V8.Sit.Render)
            end
            Keybinds[id] = kc
            Log("Keybind " .. labelText .. " = " .. KeyName(kc), "ok")
            StopCapture()
        end)
    end)
    return row
end

--------------------------------------------------------------------------------
-- FEATURES
--------------------------------------------------------------------------------

-- FLY -------------------------------------------------------------------------
local flyBv, flyBg, flyTrack

--------------------------------------------------------------------------------
-- POSE DE SUPERMAN (procedural, sem asset id)
-- Escreve direto no Transform das juntas depois que a animação padrão roda,
-- então vence o Animate do jogo sem precisar de animação publicada.
--------------------------------------------------------------------------------
local FlyPose = { active = false }
do
    local RENDER_NAME = "HYGE_FlyPose"

    local function rad(v) return math.rad(v or 0) end

    function FlyPose.Stop()
        if not FlyPose.active then return end
        FlyPose.active = false
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
    end

    function FlyPose.Start()
        FlyPose.Stop()
        local char = Char()
        local h = Hum()
        if not char or not h then return end

        local r6 = (h.RigType == Enum.HumanoidRigType.R6)
        local joints = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") or d:IsA("Motor") then
                joints[d.Name] = d
            end
        end

        local P = CONFIG.Pose
        local ok = pcall(function()
            RunService:BindToRenderStep(RENDER_NAME,
                Enum.RenderPriority.Character.Value + 1, function()
                    if r6 then
                        -- R6: sem cotovelo/joelho, só ombro (Z+X) e quadril (Z+X)
                        local rs = joints["Right Shoulder"]
                        local ls = joints["Left Shoulder"]
                        local rh = joints["Right Hip"]
                        local lh = joints["Left Hip"]
                        local nk = joints["Neck"]
                        if rs then rs.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(P.ArmFront)) end
                        if ls then ls.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(-P.ArmBack)) end
                        if rh then rh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(-P.LegSpread)) end
                        if lh then lh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(P.LegSpread)) end
                        if nk then nk.Transform = CFrame.Angles(rad(P.Neck), 0, 0) end
                    else
                        -- R15: ombro+cotovelo, quadril+joelho, cintura, pescoço
                        local rs = joints["RightShoulder"]
                        local ls = joints["LeftShoulder"]
                        local re = joints["RightElbow"]
                        local le = joints["LeftElbow"]
                        local rh = joints["RightHip"]
                        local lh = joints["LeftHip"]
                        local rk = joints["RightKnee"]
                        local lk = joints["LeftKnee"]
                        local wa = joints["Waist"]
                        local nk = joints["Neck"]
                        if rs then rs.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(P.ArmFront)) end
                        if ls then ls.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(-P.ArmBack)) end
                        if re then re.Transform = CFrame.Angles(rad(P.Elbow), 0, 0) end
                        if le then le.Transform = CFrame.Angles(rad(P.Elbow), 0, 0) end
                        if rh then rh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(-P.LegSpread)) end
                        if lh then lh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(P.LegSpread)) end
                        if rk then rk.Transform = CFrame.Angles(rad(P.KneeFold), 0, 0) end
                        if lk then lk.Transform = CFrame.Angles(rad(P.KneeFold), 0, 0) end
                        if wa then wa.Transform = CFrame.Angles(rad(P.Waist), 0, 0) end
                        if nk then nk.Transform = CFrame.Angles(rad(P.Neck), 0, 0) end
                    end
                end)
        end)
        FlyPose.active = ok
        if not ok then Log("Pose de voo falhou ao iniciar", "warn") end
    end
end

-- Pose de superman: carrega a animação de voo no Animator do personagem
local function StartFlyAnim()
    local h = Hum()
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = h
    end

    -- ID próprio (se o dono do jogo publicou um) tem prioridade; senão, o pacote
    local moveId = (h.RigType == Enum.HumanoidRigType.R6)
        and CONFIG.FlyAnimR6 or CONFIG.FlyAnimR15
    if not moveId or moveId == "" then moveId = CONFIG.FlyAnimMove end
    local idleId = CONFIG.FlyAnimIdle

    local function LoadTrack(id)
        if not id or id == "" then return nil end
        local obj = Instance.new("Animation")
        obj.AnimationId = id
        local ok, tr = pcall(function() return animator:LoadAnimation(obj) end)
        pcall(function() obj:Destroy() end)
        if not ok or not tr then return nil end
        pcall(function()
            tr.Priority = Enum.AnimationPriority.Action4
            tr.Looped = true
            tr:AdjustSpeed(CONFIG.FlyAnimSpeed or 1)
        end)
        return tr
    end

    flyTrack = LoadTrack(moveId)
    FlyPose.idleTrack = LoadTrack(idleId)
    if not flyTrack and FlyPose.idleTrack then
        flyTrack = FlyPose.idleTrack
        FlyPose.idleTrack = nil
    end

    if not flyTrack then
        -- sem ID configurado: nada de animação (ou a pose, se CONFIG.FlyUsePose)
        if CONFIG.FlyUsePose then FlyPose.Start() end
        return
    end

    FlyPose.muted = false
    pcall(function() flyTrack:Play(0.2) end)

    -- O Roblox só recusa asset de terceiro DEPOIS de carregar: track fica com
    -- Length 0 e nada anima. Se for o caso, volta pra pose procedural e avisa.
    task.delay(1.2, function()
        if not flyTrack then return end
        local len = 0
        pcall(function() len = flyTrack.Length end)
        if len > 0 then return end
        pcall(function() flyTrack:Stop(0) end)
        pcall(function() flyTrack:Destroy() end)
        flyTrack = nil
        if FlyPose.idleTrack then
            pcall(function() FlyPose.idleTrack:Stop(0) end)
            pcall(function() FlyPose.idleTrack:Destroy() end)
            FlyPose.idleTrack = nil
        end
        Log("O Roblox recusou a animação de voo (asset de terceiro: só carrega "
            .. "se o dono do jogo republicar).", "error")
        if CONFIG.FlyUsePose then FlyPose.Start() end
    end)
end

local function StopFlyAnim()
    FlyPose.Stop()
    FlyPose.muted = false
    if flyTrack then
        pcall(function() flyTrack:Stop(0.2) end)
        pcall(function() flyTrack:Destroy() end)
        flyTrack = nil
    end
    if FlyPose.idleTrack then
        pcall(function() FlyPose.idleTrack:Stop(0.2) end)
        pcall(function() FlyPose.idleTrack:Destroy() end)
        FlyPose.idleTrack = nil
    end
end

local function StopFly()
    Drop("Fly")
    Drop("FlyAnimKeep")
    StopFlyAnim()
    if flyBv then flyBv:Destroy() flyBv = nil end
    if flyBg then flyBg:Destroy() flyBg = nil end
    local h = Hum()
    if h then h.PlatformStand = false end
end

local function StartFly()
    local root = Root()
    local h = Hum()
    if not root or not h then error("sem personagem") end
    StopFly()

    flyBv = Instance.new("BodyVelocity")
    flyBv.Name = "HYGE_Fly"
    flyBv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBv.Velocity = Vector3.zero
    flyBv.Parent = root

    flyBg = Instance.new("BodyGyro")
    flyBg.Name = "HYGE_Gyro"
    flyBg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBg.P = 15000
    flyBg.D = 1000
    flyBg.CFrame = root.CFrame
    flyBg.Parent = root

    local vel = Vector3.zero
    Conn.Fly = RunService.RenderStepped:Connect(function()
        if not flyBv or not flyBv.Parent then return end
        local cam = Camera.CFrame
        local dir = Vector3.zero
        -- v8.0: digitando no chat/console o personagem não sai voando
        if not V8.Typing() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        end

        local speed = State.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2 end

        local target = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        vel = vel:Lerp(target, target.Magnitude > 0 and 0.18 or 0.1)
        flyBv.Velocity = vel

        local look = vel.Magnitude > 2 and vel.Unit or cam.LookVector
        local r = Root()
        if r and flyBg then
            local aim = CFrame.lookAt(r.Position, r.Position + look)
            if FlyPose.active then
                -- deita o corpo na direção do voo (pose de superman)
                aim = aim * CFrame.Angles(math.rad(CONFIG.Pose.BodyTilt or -90), 0, 0)
            end
            flyBg.CFrame = flyBg.CFrame:Lerp(aim, 0.15)
        end
        local h2 = Hum()
        if h2 then h2.PlatformStand = true end
    end)

    StartFlyAnim()
    -- PlatformStand / troca de state às vezes derruba a track: religa sozinho
    Conn.FlyAnimKeep = RunService.Heartbeat:Connect(function()
        if not flyTrack or FlyPose.muted then return end
        local idle = FlyPose.idleTrack
        if idle then
            -- parado no ar = flutuar; em deslocamento = animação de voo
            local moving = (flyBv and flyBv.Velocity.Magnitude > 6)
            local want = moving and flyTrack or idle
            local other = moving and idle or flyTrack
            if other.IsPlaying then pcall(function() other:Stop(0.25) end) end
            if not want.IsPlaying then pcall(function() want:Play(0.25) end) end
        elseif not flyTrack.IsPlaying then
            pcall(function() flyTrack:Play(0.15) end)
        end
    end)
end

DefineToggle({
    id = "fly", label = "Fly", desc = "WASD + Space/Ctrl, Shift = 2x",
    enable = StartFly, disable = StopFly,
})

-- NOCLIP ---------------------------------------------------------------------
local function CacheNoclipParts()
    NoclipParts = {}
    local c = Char()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(NoclipParts, p) end
    end
end

DefineToggle({
    id = "noclip", label = "Noclip", desc = "Atravessa paredes",
    enable = function()
        CacheNoclipParts()
        Conn.Noclip = RunService.Stepped:Connect(function()
            for i = #NoclipParts, 1, -1 do
                local p = NoclipParts[i]
                if not p.Parent then
                    table.remove(NoclipParts, i)
                elseif p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    end,
    disable = function()
        Drop("Noclip")
        for _, p in ipairs(NoclipParts) do
            if p.Parent and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
    end,
})

-- INFINITE JUMP --------------------------------------------------------------
DefineToggle({
    id = "infjump", label = "Infinite Jump", desc = "Pulo infinito",
    enable = function()
        Conn.InfJump = UserInputService.JumpRequest:Connect(function()
            local h = Hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end,
    disable = function() Drop("InfJump") end,
})

-- GOD MODE -------------------------------------------------------------------
local savedMaxHealth = 100
local function ApplyGod(h)
    if not h then return end
    savedMaxHealth = (h.MaxHealth ~= math.huge) and h.MaxHealth or savedMaxHealth
    h.MaxHealth = math.huge
    h.Health = math.huge
    Drop("God")
    Conn.God = h.HealthChanged:Connect(function()
        if IsOn("god") then h.Health = math.huge end
    end)
end

DefineToggle({
    id = "god", label = "God Mode", desc = "Vida infinita (client-side)",
    enable = function() ApplyGod(Hum()) end,
    disable = function()
        Drop("God")
        local h = Hum()
        if h then
            h.MaxHealth = savedMaxHealth
            h.Health = savedMaxHealth
        end
    end,
})

-- INVISIBLE ------------------------------------------------------------------
local function ApplyInvisible(on)
    local c = Char()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = on and 1 or 0
        elseif p:IsA("Decal") then
            p.Transparency = on and 1 or 0
        end
    end
end

DefineToggle({
    id = "invisible", label = "Invisível (local)", desc = "Some só na sua tela",
    enable = function() ApplyInvisible(true) end,
    disable = function() ApplyInvisible(false) end,
})

-- WALL TRANSPARENCY ----------------------------------------------------------
local function IsWorldPart(obj)
    if not obj:IsA("BasePart") then return false end
    if obj:IsDescendantOf(Camera) then return false end
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return false end
    return true
end

DefineToggle({
    id = "wall", label = "Wall Transparency", desc = "Paredes translúcidas (só pra você)",
    enable = function()
        WallCache = {}
        task.spawn(function()
            local count = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not IsOn("wall") then return end
                if IsWorldPart(obj) then
                    WallCache[obj] = true
                    obj.LocalTransparencyModifier = State.WallAlpha
                    count = count + 1
                    if count % 400 == 0 then task.wait() end   -- evita travar o frame
                end
            end
            Log("Wall Transparency: " .. count .. " partes", "ok")
        end)
        Conn.Wall = workspace.DescendantAdded:Connect(function(obj)
            if IsWorldPart(obj) then
                WallCache[obj] = true
                obj.LocalTransparencyModifier = State.WallAlpha
            end
        end)
    end,
    disable = function()
        Drop("Wall")
        for part in pairs(WallCache) do
            if part.Parent then part.LocalTransparencyModifier = 0 end
        end
        WallCache = {}
    end,
})

-- ESP ------------------------------------------------------------------------
local EspGui = Instance.new("Frame")
EspGui.Name = "EspLayer"
EspGui.Size = UDim2.new(1, 0, 1, 0)
EspGui.BackgroundTransparency = 1
EspGui.Visible = false
EspGui.Parent = Gui

local EspOpts = {
    Highlight  = true,
    Name       = true,
    UseDisplay = true,   -- DisplayName em vez de @username
    Distance   = true,
    Health     = true,
    HealthBar  = true,
    Tracers    = false,
    Allies     = true,   -- mesma equipe
    Enemies    = true,   -- equipe diferente
    MaxDist    = 1000,
    Rate       = 0.066,  -- segundos entre atualizações (15Hz)
    ColorKey   = "Accent",
    AllyKey    = "Success",
    TeamColors = false,  -- pinta pela cor da equipe
}

local function RemoveEsp(userId)
    local e = Esp[userId]
    if not e then return end
    if e.highlight then e.highlight:Destroy() end
    if e.billboard then e.billboard:Destroy() end
    if e.tracer then e.tracer:Destroy() end
    Esp[userId] = nil
end

local function ClearEsp()
    for id in pairs(Esp) do RemoveEsp(id) end
    Esp = {}
end

local function IsAlly(player)
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function EspColorFor(player)
    if EspOpts.TeamColors and player.Team then
        return player.TeamColor.Color
    end
    if IsAlly(player) then return THEME[EspOpts.AllyKey] or THEME.Success end
    return THEME[EspOpts.ColorKey] or THEME.Accent
end

local function BuildEsp(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    RemoveEsp(player.UserId)

    local hl = Instance.new("Highlight")
    hl.Name = "HYGE_ESP"
    hl.Adornee = char
    hl.FillTransparency = 0.85
    hl.OutlineTransparency = 0
    hl.FillColor = THEME.Accent
    hl.OutlineColor = THEME.Accent
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    local entry = { highlight = hl }

    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "HYGE_ESP_Tag"
        bb.Adornee = head
        bb.Size = UDim2.new(0, 150, 0, 46)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0, 16)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.DisplayName
        nameLbl.TextColor3 = THEME.Accent
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextStrokeTransparency = 0.35
        nameLbl.Parent = bb

        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0, 14)
        distLbl.Position = UDim2.new(0, 0, 0, 16)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = ""
        distLbl.TextColor3 = THEME.Accent2
        distLbl.Font = Enum.Font.Code
        distLbl.TextSize = 11
        distLbl.TextStrokeTransparency = 0.4
        distLbl.Parent = bb

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0, 70, 0, 4)
        hpBg.Position = UDim2.new(0.5, -35, 0, 34)
        hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = bb
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = THEME.Success
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

        entry.billboard = bb
        entry.name = nameLbl
        entry.dist = distLbl
        entry.hpBg = hpBg
        entry.hpFill = hpFill
    end

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 2, 0, 0)
    tracer.ZIndex = 0
    tracer.BackgroundColor3 = THEME.Accent
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.Parent = EspGui
    entry.tracer = tracer

    Esp[player.UserId] = entry
end

-- Converte um ponto do mundo para o espaço de tela DA GUI.
-- WorldToViewportPoint devolve coordenadas da viewport 3D, que começa ABAIXO da
-- topbar do Roblox. Como o painel usa IgnoreGuiInset = true, o (0,0) da GUI é o
-- topo real da tela: sem somar o inset a linha fica ~36px fora de lugar.
local espInsetY = 0
pcall(function()
    if Gui.IgnoreGuiInset then espInsetY = GuiService:GetGuiInset().Y end
end)

-- Desenha uma linha entre dois pontos de tela reaproveitando o Frame já criado.
-- Rotation no Roblox pivota no CENTRO do objeto (não no AnchorPoint), por isso a
-- barra é posicionada no PONTO MÉDIO do segmento com AnchorPoint (0.5, 0.5).
local function DrawLine(frame, x1, y1, x2, y2, color, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 2 then
        frame.Visible = false
        return
    end
    frame.Size = UDim2.new(0, thickness or 2, 0, len)
    frame.Position = UDim2.new(0, (x1 + x2) * 0.5, 0, (y1 + y2) * 0.5)
    -- barra nasce apontando para +Y (90° do eixo X): R = ângulo do vetor - 90
    frame.Rotation = math.deg(math.atan2(dy, dx)) - 90
    frame.BackgroundColor3 = color
    frame.Visible = true
end

-- Só a geometria das linhas. Roda a cada frame (barato: nada é criado aqui).
local function UpdateTracers()
    local screen = EspGui.AbsoluteSize
    if screen.X < 2 then screen = Camera.ViewportSize end
    local originX, originY = screen.X * 0.5, screen.Y

    for _, e in pairs(Esp) do
        local tracer = e.tracer
        if tracer then
            local root = e.root
            if not (EspOpts.Tracers and e.show and root and root.Parent) then
                tracer.Visible = false
            else
                local pos, _ = Camera:WorldToViewportPoint(root.Position)
                -- pos.Z > 0 = está na frente da câmera. Usar 'onScreen' aqui fazia
                -- a linha sumir sempre que o alvo saía das bordas da tela.
                if pos.Z > 0 then
                    DrawLine(tracer, originX, originY,
                        pos.X, pos.Y + espInsetY, e.col or THEME.Accent, 2)
                else
                    tracer.Visible = false
                end
            end
        end
    end
end

-- Atualiza o ESP reaproveitando os objetos já criados por BuildEsp.
-- Nada é recriado por frame: fora do filtro os objetos só ficam desligados.
local function UpdateEsp()
    local myRoot = Root()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local e = Esp[p.UserId]
            local char = p.Character
            if char and (not e or not e.highlight or not e.highlight.Parent) then
                BuildEsp(p)
                e = Esp[p.UserId]
            end

            if e and char then
                local root = char:FindFirstChild("HumanoidRootPart")
                    or char.PrimaryPart or char:FindFirstChild("Torso")
                    or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
                local h = char:FindFirstChildOfClass("Humanoid")

                -- guardado para o loop de tracers (que roda em outra taxa)
                e.root = root

                -- distância (usada no filtro e no texto)
                local dist
                if myRoot and root then
                    dist = (myRoot.Position - root.Position).Magnitude
                end

                -- filtros: equipe e distância
                local ally = IsAlly(p)
                local show = ally and EspOpts.Allies or ((not ally) and EspOpts.Enemies)
                if show and dist and EspOpts.MaxDist > 0 and dist > EspOpts.MaxDist then
                    show = false
                end
                if show and h and h.Health <= 0 then show = false end
                e.show = show

                if not show then
                    if e.highlight then e.highlight.Enabled = false end
                    if e.billboard then e.billboard.Enabled = false end
                    if e.tracer then e.tracer.Visible = false end
                else
                    local col = EspColorFor(p)
                    e.col = col

                    if e.highlight then
                        e.highlight.Enabled = EspOpts.Highlight
                        e.highlight.FillColor = col
                        e.highlight.OutlineColor = col
                    end

                    local anyTag = EspOpts.Name or EspOpts.Distance
                        or EspOpts.Health or EspOpts.HealthBar
                    if e.billboard then e.billboard.Enabled = anyTag end

                    if e.name then
                        e.name.Visible = EspOpts.Name
                        if EspOpts.Name then
                            e.name.Text = EspOpts.UseDisplay and p.DisplayName
                                or ("@" .. p.Name)
                            e.name.TextColor3 = col
                        end
                    end

                    if e.dist then
                        local wantsInfo = EspOpts.Distance or EspOpts.Health
                        e.dist.Visible = wantsInfo
                        if wantsInfo then
                            local parts = {}
                            if EspOpts.Distance and dist then
                                table.insert(parts, math.floor(dist) .. "m")
                            end
                            if EspOpts.Health and h then
                                table.insert(parts, math.floor(h.Health) .. " HP")
                            end
                            e.dist.Text = table.concat(parts, "  |  ")
                        end
                    end

                    if e.hpBg then
                        e.hpBg.Visible = EspOpts.HealthBar
                        if EspOpts.HealthBar and h and h.MaxHealth > 0 and e.hpFill then
                            local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
                            e.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                            e.hpFill.BackgroundColor3 = pct > 0.5 and THEME.Success
                                or (pct > 0.25 and THEME.Warning or THEME.Danger)
                        end
                    end
                end
            elseif e then
                e.show = false
                e.root = nil
                if e.tracer then e.tracer.Visible = false end
            end
        end
    end

    -- tracers acompanham a câmera imediatamente ao aplicar o filtro
    if EspOpts.Tracers then pcall(UpdateTracers) end
end

DefineToggle({
    id = "esp", label = "ESP", desc = "Contorno, nome, distância, vida e tracers",
    enable = function()
        EspGui.Visible = true
        for _, p in ipairs(Players:GetPlayers()) do BuildEsp(p) end
        local acc = 0
        Conn.Esp = RunService.RenderStepped:Connect(function(dt)
            -- pesado (filtros, textos, vida): na taxa configurada, 15Hz por padrão
            acc = acc + dt
            if acc >= (EspOpts.Rate or 0.066) then
                acc = 0
                local ok, err = pcall(UpdateEsp)
                if not ok then Log("ESP: " .. tostring(err), "error") end
            -- leve (só posição/rotação das linhas): todo frame, sem criar nada
            elseif EspOpts.Tracers then
                local ok, err = pcall(UpdateTracers)
                if not ok then Log("ESP tracer: " .. tostring(err), "error") end
            end
        end)
    end,
    disable = function()
        Drop("Esp")
        ClearEsp()
        EspGui.Visible = false
    end,
})

-- CHAT SPY -------------------------------------------------------------------
DefineToggle({
    id = "chatspy", label = "Chat Spy", desc = "Mostra o chat no console",
    enable = function()
        -- v8.0: jogos com TextChatService (o padrão atual do Roblox) não
        -- disparam o PlayerChatted antigo — sem isso o Chat Spy ficava mudo.
        -- Usa UM dos dois sistemas, nunca os dois (evita linha duplicada).
        local modern = false
        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
            Conn.ChatSpy = tcs.MessageReceived:Connect(function(msg)
                local src = msg.TextSource
                if not src or src.UserId == LocalPlayer.UserId then return end
                local p = Players:GetPlayerByUserId(src.UserId)
                Log("[CHAT] " .. (p and p.Name or tostring(src.Name)) .. ": "
                    .. tostring(msg.Text))
            end)
            modern = true
        end)
        if modern then return end
        Conn.ChatSpy = Players.PlayerChatted:Connect(function(_, player, message)
            if player ~= LocalPlayer then
                Log("[CHAT] " .. player.Name .. ": " .. message)
            end
        end)
    end,
    disable = function() Drop("ChatSpy") end,
})

-- FULLBRIGHT -----------------------------------------------------------------
local lightBackup
DefineToggle({
    id = "fullbright", label = "Fullbright", desc = "Remove escuridão e neblina",
    enable = function()
        lightBackup = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd,
            ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows,
        }
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end,
    disable = function()
        if not lightBackup then return end
        for k, v in pairs(lightBackup) do Lighting[k] = v end
    end,
})

-- ANTI-AFK -------------------------------------------------------------------
DefineToggle({
    id = "antiafk", label = "Anti-AFK", desc = "Evita kick por inatividade",
    enable = function()
        Conn.AntiAfk = LocalPlayer.Idled:Connect(function()
            local ok = pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            if not ok then
                local h = Hum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            Log("Anti-AFK: entrada simulada")
        end)
    end,
    disable = function() Drop("AntiAfk") end,
})

-- FREECAM --------------------------------------------------------------------
-- v8.0: refeito.
--   * yaw/pitch guardados separados (antes girava em cima do CFrame acumulado
--     e a câmera "rolava" de lado com o tempo)
--   * o personagem não anda junto (controles desligados pelo PlayerModule)
--   * painel aberto = mouse livre para clicar na UI (igual ao drone)
--   * scroll muda a velocidade; digitando, a câmera não se mexe
local camBackup = {}
DefineToggle({
    id = "freecam", label = "Freecam",
    desc = "Câmera livre (WASD + E/Q, scroll = velocidade)",
    enable = function()
        camBackup.type = Camera.CameraType
        camBackup.subject = Camera.CameraSubject
        Camera.CameraType = Enum.CameraType.Scriptable

        -- trava os controles do personagem (se o jogo usar o PlayerModule padrão)
        camBackup.controls = nil
        pcall(function()
            local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then
                local controls = require(pm):GetControls()
                controls:Disable()
                camBackup.controls = controls
            end
        end)

        local pos = Camera.CFrame.Position
        local look = Camera.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        local pitch = math.asin(math.clamp(look.Y, -1, 1))
        State.FreecamSpeed = State.FreecamSpeed or 60

        Conn.FreecamScroll = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel and not Window.Visible then
                State.FreecamSpeed = math.clamp(State.FreecamSpeed + input.Position.Z * 8, 5, 400)
            end
        end)

        Conn.Freecam = RunService.RenderStepped:Connect(function(dt)
            local uiOpen = Window.Visible
            UserInputService.MouseBehavior = uiOpen
                and Enum.MouseBehavior.Default
                or Enum.MouseBehavior.LockCenter

            if not uiOpen then
                local d = UserInputService:GetMouseDelta()
                yaw = yaw - math.rad(d.X * 0.25)
                pitch = math.clamp(pitch - math.rad(d.Y * 0.25), -1.45, 1.45)
            end
            local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

            local move = Vector3.zero
            if not V8.Typing() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.yAxis end
            end
            local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1
            if move.Magnitude > 0 then
                pos = pos + move.Unit * State.FreecamSpeed * mult * dt
            end
            Camera.CFrame = CFrame.new(pos) * rot
        end)
    end,
    disable = function()
        Drop("Freecam")
        Drop("FreecamScroll")
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if camBackup.controls then
            pcall(function() camBackup.controls:Enable() end)
            camBackup.controls = nil
        end
        Camera.CameraType = camBackup.type or Enum.CameraType.Custom
        Camera.CameraSubject = camBackup.subject or Hum()
    end,
})

-- DRONE ----------------------------------------------------------------------
-- Câmera livre estilo drone: o personagem fica 100% travado no lugar (ancorado),
-- a câmera voa com inércia suave. Scroll muda a velocidade, Shift acelera,
-- Ctrl freia. Com o painel aberto o mouse volta a funcionar pra clicar na UI.
local droneBackup = { anchored = {}, ws = 16, jp = 50, autorotate = true }
DefineToggle({
    id = "drone", label = "Modo Drone", desc = "Câmera voa, personagem fica parado (WASD + E/Q, scroll = velocidade)",
    enable = function()
        local char = Char()
        if not char then error("personagem não carregado") end

        -- congela o personagem
        droneBackup.anchored = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                droneBackup.anchored[part] = part.Anchored
                part.Anchored = true
            end
        end
        local h = Hum()
        if h then
            droneBackup.ws = h.WalkSpeed
            droneBackup.jp = h.JumpPower
            droneBackup.autorotate = h.AutoRotate
            h.WalkSpeed = 0
            h.JumpPower = 0
            h.AutoRotate = false
            h:ChangeState(Enum.HumanoidStateType.Physics)
        end

        -- câmera
        droneBackup.type = Camera.CameraType
        droneBackup.subject = Camera.CameraSubject
        droneBackup.fov = Camera.FieldOfView
        Camera.CameraType = Enum.CameraType.Scriptable
        if DroneHUD.Show then pcall(DroneHUD.Show) end

        local pos = Camera.CFrame.Position
        local look = Camera.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        local pitch = math.asin(math.clamp(look.Y, -1, 1))
        local vel = Vector3.zero

        Conn.DroneScroll = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel and not Window.Visible then
                State.DroneSpeed = math.clamp(State.DroneSpeed + input.Position.Z * 8, 5, 400)
                if DroneSpeedSlider then DroneSpeedSlider(State.DroneSpeed) end
            end
        end)

        Conn.Drone = RunService.RenderStepped:Connect(function(dt)
            local uiOpen = Window.Visible
            UserInputService.MouseBehavior = uiOpen
                and Enum.MouseBehavior.Default
                or Enum.MouseBehavior.LockCenter

            if not uiOpen then
                local d = UserInputService:GetMouseDelta()
                yaw = yaw - d.X * State.DroneSens * 0.003
                pitch = math.clamp(pitch - d.Y * State.DroneSens * 0.003, -1.45, 1.45)
            end

            local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

            local dir = Vector3.zero
            if not uiOpen and not V8.Typing() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.yAxis end
            end

            local mult = 1
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mult = 3 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mult = 0.25 end

            local target = Vector3.zero
            if dir.Magnitude > 0 then
                target = dir.Unit * State.DroneSpeed * mult
            end
            -- inércia (quanto menor o Smooth, mais "pesado" o drone)
            local a = math.clamp(dt * (State.DroneSmooth or 8), 0, 1)
            vel = vel:Lerp(target, a)
            pos = pos + vel * dt

            Camera.CFrame = CFrame.new(pos) * rot
            Camera.FieldOfView = droneBackup.fov + math.clamp(vel.Magnitude * 0.08, 0, 20)
            if DroneHUD.Update then pcall(DroneHUD.Update, dt, pos, vel, yaw, pitch) end
        end)
    end,
    disable = function()
        Drop("Drone")
        Drop("DroneScroll")
        if DroneHUD.Hide then pcall(DroneHUD.Hide) end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default

        for part, was in pairs(droneBackup.anchored) do
            if part and part.Parent then part.Anchored = was end
        end
        droneBackup.anchored = {}

        local h = Hum()
        if h then
            h.WalkSpeed = State.WalkSpeed or droneBackup.ws
            h.JumpPower = droneBackup.jp
            h.AutoRotate = droneBackup.autorotate
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Camera.FieldOfView = droneBackup.fov or 70
        Camera.CameraType = droneBackup.type or Enum.CameraType.Custom
        Camera.CameraSubject = droneBackup.subject or Hum()
    end,
})

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

local function Goto(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then Toast("Alvo sem personagem", "warn") return end
    TeleportTo(root.CFrame * CFrame.new(0, 0, 4))
    Log("Goto -> " .. player.Name, "ok")
end

local function Bring(player)
    if Remotes.Pull then
        Remotes.Pull:FireServer(player.UserId, "selected")
        Log("Bring (server) -> " .. player.Name, "ok")
        return
    end
    local myRoot, theirRoot = Root(), player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and theirRoot then
        theirRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
        Log("Bring (local) -> " .. player.Name, "warn")
    else
        Toast("Não foi possível trazer", "error")
    end
end

local function FreezePlayer(player, freeze)
    if Remotes.Freeze then Remotes.Freeze:FireServer(player.UserId, freeze) end
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local h = char:FindFirstChildOfClass("Humanoid")
        if root then root.Anchored = freeze end
        if h then
            h.PlatformStand = freeze
            h.WalkSpeed = freeze and 0 or 16
        end
    end
    Log((freeze and "Freeze: " or "Unfreeze: ") .. player.Name, "ok")
end

local function KickPlayer(player, reason)
    if Remotes.Kick then
        Remotes.Kick:FireServer(player.UserId, reason or "Removido por um admin")
        Log("Kick enviado: " .. player.Name, "ok")
    else
        Log("Remote AdminKick ausente — kick precisa do servidor", "error")
        Toast("Sem AdminKick no ReplicatedStorage", "error")
    end
end

--------------------------------------------------------------------------------
-- AÇÕES DE TROLL (v8.0) — 100% dependentes de servidor, cliente só pede.
-- Estado local (Spin/Balloon) é só o que o painel PEDIU, não confirmação real
-- de que o servidor aplicou — deixado claro no Log.
--------------------------------------------------------------------------------
local TrollState = { Spin = {}, Balloon = {} }

local function FlingPlayer(player)
    if not Remotes.Fling then
        Log("Remote AdminFling ausente — fling precisa do servidor", "error")
        Toast("Sem AdminFling no ReplicatedStorage", "error")
        return
    end
    Remotes.Fling:FireServer(player.UserId)
    Log("Fling enviado: " .. player.Name, "ok")
end

local function SpinPlayer(player, on)
    if not Remotes.Spin then
        Log("Remote AdminSpin ausente — spin precisa do servidor", "error")
        Toast("Sem AdminSpin no ReplicatedStorage", "error")
        return
    end
    Remotes.Spin:FireServer(player.UserId, on)
    TrollState.Spin[player.UserId] = on
    Log((on and "Spin ON pedido: " or "Spin OFF pedido: ") .. player.Name, "ok")
end

local function TripPlayer(player)
    if not Remotes.Trip then
        Log("Remote AdminTrip ausente — trip precisa do servidor", "error")
        Toast("Sem AdminTrip no ReplicatedStorage", "error")
        return
    end
    Remotes.Trip:FireServer(player.UserId)
    Log("Trip enviado: " .. player.Name, "ok")
end

local function LaunchPlayer(player)
    if not Remotes.Launch then
        Log("Remote AdminLaunch ausente — launch precisa do servidor", "error")
        Toast("Sem AdminLaunch no ReplicatedStorage", "error")
        return
    end
    Remotes.Launch:FireServer(player.UserId)
    Log("Launch enviado: " .. player.Name, "ok")
end

local function SitPlayer(player)
    if not Remotes.Sit then
        Log("Remote AdminSit ausente — force sit precisa do servidor", "error")
        Toast("Sem AdminSit no ReplicatedStorage", "error")
        return
    end
    Remotes.Sit:FireServer(player.UserId)
    Log("Force Sit enviado: " .. player.Name, "ok")
end

local function ScalePlayer(player, mode)
    if not Remotes.Scale then
        Log("Remote AdminScale ausente — mudar tamanho precisa do servidor", "error")
        Toast("Sem AdminScale no ReplicatedStorage", "error")
        return
    end
    Remotes.Scale:FireServer(player.UserId, mode)
    Log("Scale (" .. mode .. ") enviado: " .. player.Name, "ok")
end

local function BalloonPlayer(player, on)
    if not Remotes.Balloon then
        Log("Remote AdminBalloon ausente — balão precisa do servidor", "error")
        Toast("Sem AdminBalloon no ReplicatedStorage", "error")
        return
    end
    Remotes.Balloon:FireServer(player.UserId, on)
    TrollState.Balloon[player.UserId] = on
    Log((on and "Balloon ON pedido: " or "Balloon OFF pedido: ") .. player.Name, "ok")
end

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

local function Announce(msg)
    if Remotes.Announce then
        Remotes.Announce:FireServer(msg)
        Log("Anúncio enviado: " .. msg, "ok")
    else
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "[ADMIN] " .. msg, Color = THEME.Accent, Font = Enum.Font.GothamBold })
        end)
        Log("Anúncio local: " .. msg, "warn")
    end
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

-- SPECTATE -------------------------------------------------------------------
local SpectateHud
local StopSpectate, StartSpectate

StopSpectate = function()
    if not State.Spectating then return end
    State.Spectating = false
    State.SpectateTarget = nil
    Drop("SpectateEnd")
    Camera.CameraType = camBackup.type or Enum.CameraType.Custom
    Camera.CameraSubject = Hum()
    if SpectateHud then SpectateHud.Visible = false end
    if RefreshStatus then RefreshStatus() end
    Log("Spectate OFF")
end

StartSpectate = function(player)
    local char = player and player.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if not h then Toast("Alvo sem personagem", "warn") return end
    camBackup.type = camBackup.type or Camera.CameraType
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = h
    State.Spectating = true
    State.SpectateTarget = player
    Drop("SpectateEnd")
    Conn.SpectateEnd = player.CharacterRemoving:Connect(StopSpectate)
    if SpectateHud then
        SpectateHud.Visible = true
        SpectateHud.Label.Text = "Assistindo " .. player.DisplayName .. "  (@" .. player.Name .. ")"
        SpectateHud.Input.PlaceholderText = "Mensagem privada para " .. player.DisplayName
    end
    if RefreshStatus then RefreshStatus() end
    Log("Spectate: " .. player.Name, "ok")
end

local function CycleSpectate(dir)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    if #list == 0 then return end
    local idx = 1
    for i, p in ipairs(list) do
        if p == State.SpectateTarget then idx = i break end
    end
    idx = ((idx - 1 + dir) % #list) + 1
    StartSpectate(list[idx])
end

--------------------------------------------------------------------------------
-- HUD DE SPECTATE (fora da janela, funciona com o painel fechado)
--------------------------------------------------------------------------------
do
    local hud = Instance.new("Frame")
    hud.Name = "SpectateHud"
    hud.AnchorPoint = Vector2.new(0.5, 1)
    hud.Position = UDim2.new(0.5, 0, 1, -24)
    hud.Size = UDim2.new(0, 470, 0, 92)
    hud.BackgroundColor3 = THEME.Card
    hud.BackgroundTransparency = 0.05
    hud.BorderSizePixel = 0
    hud.Visible = false
    hud.Parent = Gui
    Paint(hud, "BackgroundColor3", "Card")
    Instance.new("UICorner", hud).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", hud)
    st.Transparency = 0.4
    Paint(st, "Color", "Accent")

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -110, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.TextColor3 = THEME.Accent
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = hud
    Paint(label, "TextColor3", "Accent")

    local prev = CreateButton(hud, "<", "Accent", 22)
    prev.Size = UDim2.new(0, 26, 0, 22)
    prev.Position = UDim2.new(1, -102, 0, 8)
    local nxt = CreateButton(hud, ">", "Accent", 22)
    nxt.Size = UDim2.new(0, 26, 0, 22)
    nxt.Position = UDim2.new(1, -72, 0, 8)
    local stop = CreateButton(hud, "SAIR", "Danger", 22)
    stop.Size = UDim2.new(0, 44, 0, 22)
    stop.Position = UDim2.new(1, -58, 0, 8)
    nxt.Position = UDim2.new(1, -134, 0, 8)
    prev.Position = UDim2.new(1, -164, 0, 8)

    local input = CreateInput(hud, "Mensagem privada", 32)
    input.Name = "Input"
    input.Size = UDim2.new(1, -128, 0, 32)
    input.Position = UDim2.new(0, 14, 0, 44)

    local send = CreateButton(hud, "ENVIAR", "Accent", 32)
    send.Size = UDim2.new(0, 100, 0, 32)
    send.Position = UDim2.new(1, -114, 0, 44)

    local function sendMsg()
        local msg = input.Text
        if msg == "" or not State.SpectateTarget then return end
        if Remotes.Whisper then
            Remotes.Whisper:FireServer(State.SpectateTarget.UserId, msg)
            Log("Você -> " .. State.SpectateTarget.Name .. ": " .. msg, "ok")
        else
            Log("Remote AdminWhisper ausente", "error")
        end
        input.Text = ""
    end

    send.MouseButton1Click:Connect(sendMsg)
    input.FocusLost:Connect(function(enter) if enter then sendMsg() end end)
    prev.MouseButton1Click:Connect(function() CycleSpectate(-1) end)
    nxt.MouseButton1Click:Connect(function() CycleSpectate(1) end)
    stop.MouseButton1Click:Connect(StopSpectate)

    SpectateHud = hud
end
--------------------------------------------------------------------------------
-- FÁBRICA DE UI v7
-- Tiles de estatística, sliders com campo numérico + reset, switches genéricos
-- (não ligados ao registry), avatar, chips, confirmação e botões com gate de
-- Remote. Tudo em cima do CreateCard/CreateButton que já existiam.
--------------------------------------------------------------------------------

-- Tween que respeita a opção "animações" em Settings
local function Anim(inst, dur, props)
    if not SET.Animations then
        for k, v in pairs(props) do inst[k] = v end
        return
    end
    TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out), props):Play()
end

local function SubLabel(parent, text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 15)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = THEME.Dim
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 50
    l.Parent = parent
    Paint(l, "TextColor3", "Dim")
    return l
end

-- Tile de estatística: rótulo pequeno em cima, valor grande embaixo
local function StatTile(parent, label, value, order, colorKey)
    local box = Instance.new("Frame")
    box.Name = "Tile"
    box.BackgroundColor3 = THEME.Btn
    box.BorderSizePixel = 0
    box.LayoutOrder = order or 1
    box.Parent = parent
    Paint(box, "BackgroundColor3", "Btn")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local st = Instance.new("UIStroke", box)
    st.Transparency = 0.85
    Paint(st, "Color", "Line")

    local cap = Instance.new("TextLabel")
    cap.Size = UDim2.new(1, -16, 0, 12)
    cap.Position = UDim2.new(0, 8, 0, 7)
    cap.BackgroundTransparency = 1
    cap.Text = label
    cap.TextColor3 = THEME.Dim
    cap.Font = Enum.Font.GothamBold
    cap.TextSize = 9
    cap.TextXAlignment = Enum.TextXAlignment.Left
    cap.Parent = box
    Paint(cap, "TextColor3", "Dim")

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -16, 0, 20)
    val.Position = UDim2.new(0, 8, 0, 21)
    val.BackgroundTransparency = 1
    val.Text = tostring(value)
    val.TextColor3 = THEME[colorKey or "Text"]
    val.Font = Enum.Font.GothamBold
    val.TextSize = 15
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = box
    Paint(val, "TextColor3", colorKey or "Text")
    return val, box
end

-- Slider + campo numérico + reset, todos sincronizados.
-- o = { label, min, max, def, suffix, apply(v), order }
-- devolve setValue(v) para sincronizar de fora (comandos, scroll, presets)
local function SliderRow(parent, o)
    local minV, maxV = o.min, o.max
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundTransparency = 1
    row.LayoutOrder = o.order or 10
    row.Parent = parent

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -112, 0, 16)
    name.BackgroundTransparency = 1
    name.Text = o.label
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamMedium
    name.TextSize = 12
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0)
    box.Position = UDim2.new(1, -48, 0, -1)
    box.Size = UDim2.new(0, 54, 0, 20)
    box.BackgroundColor3 = THEME.Btn
    box.Text = tostring(o.def)
    box.TextColor3 = THEME.Accent2
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = row
    Paint(box, "BackgroundColor3", "Btn")
    Paint(box, "TextColor3", "Accent2")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local reset = Instance.new("TextButton")
    reset.AnchorPoint = Vector2.new(1, 0)
    reset.Position = UDim2.new(1, 0, 0, -1)
    reset.Size = UDim2.new(0, 42, 0, 20)
    reset.BackgroundColor3 = THEME.Btn
    reset.Text = "RESET"
    reset.TextColor3 = THEME.Dim
    reset.Font = Enum.Font.GothamBold
    reset.TextSize = 9
    reset.AutoButtonColor = false
    reset.Parent = row
    Paint(reset, "BackgroundColor3", "Btn")
    Paint(reset, "TextColor3", "Dim")
    Instance.new("UICorner", reset).CornerRadius = UDim.new(0, 6)

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = THEME.Track
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = row
    Paint(bar, "BackgroundColor3", "Track")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local pct0 = (o.def - minV) / (maxV - minV)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Paint(fill, "BackgroundColor3", "Accent")
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct0, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local current = o.def
    local function render(v)
        local pct = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -7, 0.5, -7)
        box.Text = tostring(v) .. (o.suffix or "")
    end

    local function apply(v, silent)
        if type(v) ~= "number" then return current end
        v = math.clamp(math.floor(v + 0.5), minV, maxV)   -- limites sempre válidos
        current = v
        render(v)
        if not silent and o.apply then
            local ok, err = pcall(o.apply, v)
            if not ok then Log(o.label .. ": " .. tostring(err), "error") end
        end
        return v
    end

    box.FocusLost:Connect(function()
        local v = tonumber((box.Text:gsub("[^%-%d%.]", "")))
        if v then
            apply(v)
        else
            render(current)   -- valor inválido: volta pro atual
            Toast("Valor inválido em " .. o.label, "warn", 1.6)
        end
    end)

    reset.MouseButton1Click:Connect(function()
        apply(o.def)
        Log(o.label .. " resetado (" .. o.def .. ")", "action")
    end)
    reset.MouseEnter:Connect(function() Anim(reset, 0.12, { TextColor3 = THEME.Accent }) end)
    reset.MouseLeave:Connect(function() Anim(reset, 0.12, { TextColor3 = THEME.Dim }) end)

    local moveConn, endConn
    bar.MouseButton1Down:Connect(function()
        local function fromInput(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)
                / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            apply(minV + rel * (maxV - minV))
        end
        Anim(knob, 0.1, { Size = UDim2.new(0, 18, 0, 18) })
        if moveConn then moveConn:Disconnect() end
        if endConn then endConn:Disconnect() end
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                fromInput(input)
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if moveConn then moveConn:Disconnect() moveConn = nil end
                if endConn then endConn:Disconnect() endConn = nil end
                Anim(knob, 0.1, { Size = UDim2.new(0, 14, 0, 14) })
            end
        end)
    end)

    render(o.def)
    return apply
end

-- Switch genérico (settings, opções de ESP): usa get/set em vez do registry
local function CheckRow(parent, labelText, description, get, set, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, description and 44 or 34)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 10
    row.Parent = parent

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -66, 0, 17)
    name.Position = UDim2.new(0, 0, 0, description and 3 or 8)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamMedium
    name.TextSize = 12
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    if description then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -66, 0, 13)
        d.Position = UDim2.new(0, 0, 0, 22)
        d.BackgroundTransparency = 1
        d.Text = description
        d.TextColor3 = THEME.Dim
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = row
        Paint(d, "TextColor3", "Dim")
    end

    local track = Instance.new("TextButton")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.new(0, 40, 0, 21)
    track.BackgroundColor3 = THEME.Track
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.Position = UDim2.new(0, 3, 0.5, -7.5)
    knob.BackgroundColor3 = THEME.Dim
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function render()
        local on = not not get()
        Anim(track, 0.15, { BackgroundColor3 = on and THEME.Accent or THEME.Track })
        Anim(knob, 0.15, {
            Position = on and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5),
            BackgroundColor3 = on and Color3.new(1, 1, 1) or THEME.Dim })
    end

    track.MouseButton1Click:Connect(function()
        local ok, err = pcall(set, not get())
        if not ok then Log(labelText .. ": " .. tostring(err), "error") end
        render()
    end)

    render()
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, render)
    return render, row
end

--------------------------------------------------------------------------------
-- CONFIRMAÇÃO (para ações destrutivas)
--------------------------------------------------------------------------------
local Confirm
do
    local overlay = Instance.new("Frame")
    overlay.Name = "Confirm"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.45
    overlay.Visible = false
    overlay.ZIndex = 60
    overlay.Parent = Gui

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.Size = UDim2.new(0, 360, 0, 148)
    box.BackgroundColor3 = THEME.Card
    box.BorderSizePixel = 0
    box.ZIndex = 61
    box.Parent = overlay
    Paint(box, "BackgroundColor3", "Card")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
    local bst = Instance.new("UIStroke", box)
    bst.Transparency = 0.3
    Paint(bst, "Color", "Danger")

    local head = Instance.new("TextLabel")
    head.Size = UDim2.new(1, -28, 0, 20)
    head.Position = UDim2.new(0, 14, 0, 14)
    head.BackgroundTransparency = 1
    head.Text = "CONFIRMAR AÇÃO"
    head.TextColor3 = THEME.Danger
    head.Font = Enum.Font.GothamBold
    head.TextSize = 13
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.ZIndex = 62
    head.Parent = box
    Paint(head, "TextColor3", "Danger")

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -28, 0, 54)
    msg.Position = UDim2.new(0, 14, 0, 38)
    msg.BackgroundTransparency = 1
    msg.Text = ""
    msg.TextColor3 = THEME.Text
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 13
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.ZIndex = 62
    msg.Parent = box
    Paint(msg, "TextColor3", "Text")

    local yes = CreateButton(box, "CONFIRMAR", "Danger", 32)
    yes.Size = UDim2.new(0, 150, 0, 32)
    yes.Position = UDim2.new(1, -164, 1, -46)
    yes.ZIndex = 62

    local no = CreateButton(box, "CANCELAR", "Accent", 32)
    no.Size = UDim2.new(0, 120, 0, 32)
    no.Position = UDim2.new(0, 14, 1, -46)
    no.ZIndex = 62

    local pending

    local function close()
        overlay.Visible = false
        pending = nil
    end

    yes.MouseButton1Click:Connect(function()
        local fn = pending
        close()
        if fn then
            local ok, err = pcall(fn)
            if not ok then Log("ação: " .. tostring(err), "error") end
        end
    end)
    no.MouseButton1Click:Connect(close)

    -- Confirm(texto, fn): pede confirmação só se a opção estiver ligada
    Confirm = function(text, fn)
        if not SET.Confirm then
            local ok, err = pcall(fn)
            if not ok then Log("ação: " .. tostring(err), "error") end
            return
        end
        msg.Text = text
        pending = fn
        overlay.Visible = true
    end
end

--------------------------------------------------------------------------------
-- BOTÃO DE AÇÃO COM GATE DE REMOTE
-- remoteKey = chave em Remotes. Sem o remote o botão fica indisponível,
-- explica o motivo e registra no log — nunca finge que executou.
--------------------------------------------------------------------------------
local function ActionBtn(parent, text, colorKey, remoteKey, fn, confirmText)
    local available = (remoteKey == nil) or (Remotes[remoteKey] ~= nil)
    local b = CreateButton(parent, text, available and colorKey or "Line", 32)

    if not available then
        b.TextColor3 = THEME.Dim
        b.BackgroundTransparency = 0.45
        b.Text = text .. "  (servidor)"
        Paint(b, "TextColor3", "Dim")
    end

    b.MouseButton1Click:Connect(function()
        if not available then
            Log(text .. ": precisa do RemoteEvent " .. tostring(remoteKey)
                .. " no ReplicatedStorage (função server-side)", "warn")
            Toast(text .. " depende de um Remote no servidor", "warn", 3)
            return
        end
        if confirmText then
            Confirm(confirmText, fn)
        else
            local ok, err = pcall(fn)
            if not ok then Log(text .. ": " .. tostring(err), "error") end
        end
    end)
    return b, available
end

-- Avatar (headshot) por UserId — usa rbxthumb, não baixa nada duas vezes
local function Avatar(parent, userId, size)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, size, 0, size)
    img.BackgroundColor3 = THEME.Track
    img.BorderSizePixel = 0
    img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=48&h=48"
    img.Parent = parent
    Paint(img, "BackgroundColor3", "Track")
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 8)
    return img
end

local function TagChip(parent, text, colorKey)
    local c = Instance.new("TextLabel")
    c.AutomaticSize = Enum.AutomaticSize.X
    c.Size = UDim2.new(0, 0, 0, 18)
    c.BackgroundColor3 = THEME[colorKey or "Btn"]
    c.BackgroundTransparency = 0.7
    c.Text = "  " .. text .. "  "
    c.TextColor3 = THEME[colorKey or "Dim"]
    c.Font = Enum.Font.GothamBold
    c.TextSize = 10
    c.Parent = parent
    Paint(c, "TextColor3", colorKey or "Dim")
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 5)
    return c
end

--------------------------------------------------------------------------------
-- ÍCONES VETORIAIS
-- Sem asset: cada ícone é um punhado de Frames posicionados numa grade 24x24 e
-- escalados. shape = { x, y, w, h, rot, corner, outline }
--------------------------------------------------------------------------------
do
    local S = {
        home   = { {12,2,12,12,45,3}, {5,11,14,10,0,3} },
        run    = { {13,1,6,6,0,3}, {6,7,3,10,-25,2}, {12,9,3,11,20,2}, {3,12,9,3,15,2} },
        eye    = { {2,6,20,12,0,6,1}, {9,9,6,6,0,3} },
        users  = { {3,3,8,8,0,4}, {13,5,7,7,0,4}, {1,13,12,8,0,4}, {12,15,11,6,0,3} },
        shield = { {4,3,16,10,0,3}, {7,10,10,10,45,3} },
        server = { {3,4,18,5,0,2,1}, {3,11,18,5,0,2,1}, {3,18,18,4,0,2,1} },
        smile  = { {2,2,20,20,0,10,1}, {7,8,3,3,0,2}, {14,8,3,3,0,2}, {7,15,10,3,0,2} },
        gear   = { {4,4,16,16,0,8,1}, {10,1,4,5,0,1}, {10,18,4,5,0,1}, {1,10,5,4,0,1},
                   {18,10,5,4,0,1} },
        bolt   = { {8,2,4,12,18,1}, {12,10,4,12,18,1} },
        ghost  = { {6,6,12,12,45,2,1} },
        cam    = { {2,7,15,11,0,3,1}, {16,9,7,7,25,2} },
        up     = { {11,5,3,16,0,1}, {7,7,9,3,-45,1}, {13,7,9,3,45,1} },
        circle = { {3,3,18,18,0,9,1} },
        sun    = { {7,7,10,10,0,5}, {11,1,2,5,0,1}, {11,18,2,5,0,1}, {1,11,5,2,0,1},
                   {18,11,5,2,0,1} },
        signal = { {3,15,3,6,0,1}, {8,11,3,10,0,1}, {13,7,3,14,0,1}, {18,3,3,18,0,1} },
        box    = { {3,6,18,14,0,3,1}, {3,6,18,4,0,1} },
        clip   = { {5,3,14,18,0,3,1}, {9,1,6,4,0,1} },
        wifi   = { {3,7,18,18,0,9,1}, {7,11,10,10,0,5,1}, {10,17,4,4,0,2} },
        clock  = { {3,3,18,18,0,9,1}, {11,7,2,6,0,1}, {12,11,6,2,0,1} },
        copy   = { {2,2,13,13,0,3,1}, {9,9,13,13,0,3,1} },
        power  = { {3,6,18,16,0,9,1}, {11,1,2,10,0,1} },
        trash  = { {5,6,14,15,0,3,1}, {3,3,18,3,0,1} },
        dot    = { {8,8,8,8,0,4} },
        -- v8: ícones do shell novo (dock do mockup)
        code   = { {2,7,9,3,45,1}, {2,14,9,3,-45,1},
                   {13,7,9,3,-45,1}, {13,14,9,3,45,1} },
        music  = { {4,15,8,7,0,4}, {10,3,3,15,0,1}, {10,3,9,4,0,2} },
        cloud  = { {3,12,18,8,0,4}, {7,6,10,9,0,5}, {13,9,8,8,0,4} },
        mic    = { {9,2,6,11,0,3}, {5,10,14,8,0,4,1}, {11,17,2,4,0,1},
                   {8,21,8,2,0,1} },
        check  = { {4,12,9,3,45,1}, {9,7,13,3,-45,1} },
        dots   = { {2,10,4,4,0,2}, {10,10,4,4,0,2}, {18,10,4,4,0,2} },
        search = { {3,3,15,15,0,7,1}, {15,15,7,3,45,1} },
        -- v8.0: dock de 8 seções
        user     = { {8,2,8,8,0,4,1}, {4,13,16,9,0,6,1} },
        bag      = { {4,8,16,14,0,3,1}, {8,4,2,6,0,1}, {14,4,2,6,0,1}, {8,3,8,2,0,1} },
        terminal = { {2,4,20,16,0,3,1}, {5,8.5,6,2,35,1}, {5,11.5,6,2,-35,1},
                     {12,14,6,2,0,1} },
        grid     = { {3,3,8,8,0,2,1}, {13,3,8,8,0,2,1}, {3,13,8,8,0,2,1},
                     {13,13,8,8,0,2,1} },
        chat     = { {2,3,20,15,0,7,1}, {5,16,3,6,25,1} },
    }

    Icon = function(parent, kind, color, size, order)
        size = size or 18
        local k = size / 24
        local root = Instance.new("Frame")
        root.Name = "Icon"
        root.Size = UDim2.new(0, size, 0, size)
        root.BackgroundTransparency = 1
        root.LayoutOrder = order or 1
        root.Parent = parent
        for _, s in ipairs(S[kind] or S.dot) do
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.new(0, (s[1] + s[3] * 0.5) * k, 0, (s[2] + s[4] * 0.5) * k)
            f.Size = UDim2.new(0, s[3] * k, 0, s[4] * k)
            f.Rotation = s[5] or 0
            f.BorderSizePixel = 0
            f.BackgroundColor3 = color
            f.Parent = root
            if (s[6] or 0) > 0 then
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, math.max(1, s[6] * k))
            end
            if s[7] == 1 then
                f.BackgroundTransparency = 1
                local st = Instance.new("UIStroke", f)
                st.Thickness = math.max(1, 2 * k)
                st.Color = color
            end
        end
        return root
    end

    -- repinta um ícone inteiro (usado no estado ativo da sidebar)
    IconTint = function(root, color)
        if not root then return end
        for _, f in ipairs(root:GetChildren()) do
            if f:IsA("Frame") then
                f.BackgroundColor3 = color
                local st = f:FindFirstChildOfClass("UIStroke")
                if st then st.Color = color end
            end
        end
    end
end
--------------------------------------------------------------------------------
-- CHIPS DA TOP BAR
-- Substitui a linha de texto "FPS ... • PING ..." por chips com ícone.
-- Reaproveita o mesmo Every(0.5) que já existia (nenhum loop novo): o scheduler
-- chama SetChips() em vez de escrever em Stat.Text.
--------------------------------------------------------------------------------
do
    Stat.Visible = false

    local row = Instance.new("Frame")
    row.Name = "StatChips"
    row.AnchorPoint = Vector2.new(1, 0.5)
    row.Position = UDim2.new(1, -92, 0.5, 0)
    row.Size = UDim2.new(0, 620, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = TopBar

    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 18)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local L = {}

    local function Chip(kind, iconColor, order)
        local holder = Instance.new("Frame")
        holder.AutomaticSize = Enum.AutomaticSize.X
        holder.Size = UDim2.new(0, 0, 0, 24)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = order
        holder.Parent = row

        local h = Instance.new("UIListLayout", holder)
        h.FillDirection = Enum.FillDirection.Horizontal
        h.VerticalAlignment = Enum.VerticalAlignment.Center
        h.Padding = UDim.new(0, 7)
        h.SortOrder = Enum.SortOrder.LayoutOrder

        Icon(holder, kind, iconColor, 16, 1)

        local t = Instance.new("TextLabel")
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 0, 20)
        t.BackgroundTransparency = 1
        t.Text = "—"
        t.TextColor3 = THEME.Text
        t.Font = Enum.Font.GothamMedium
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.LayoutOrder = 2
        t.Parent = holder
        Paint(t, "TextColor3", "Text")
        return t
    end

    L.fps     = Chip("signal", THEME.Success, 1)
    L.ping    = Chip("signal", THEME.Accent2, 2)
    L.players = Chip("users",  THEME.Accent,  3)
    L.name    = Chip("clip",   THEME.Dim,     4)
    L.watch   = Chip("eye",    THEME.Warning, 5)
    L.watch.Parent.Visible = false

    -- chamado pelo scheduler existente
    SetChips = function(fps, ping, np, maxp, pname, watching)
        L.fps.Text = "FPS " .. fps
        L.fps.TextColor3 = (fps >= 50 and THEME.Text) or (fps >= 30 and THEME.Warning)
            or THEME.Danger
        L.ping.Text = "PING " .. ping .. "ms"
        L.players.Text = np .. "/" .. maxp .. " jogadores"
        L.name.Text = pname
        if watching then
            L.watch.Text = "ASSISTINDO " .. watching
            L.watch.Parent.Visible = true
        else
            L.watch.Parent.Visible = false
        end
    end
end
--------------------------------------------------------------------------------
-- DRONE HUD (overlay de câmera de drone)
--
-- Incremental: NÃO toca no movimento do drone. O toggle existente só chama
-- DroneHUD.Show() / DroneHUD.Update(...) / DroneHUD.Hide(), e o Update roda
-- DENTRO do RenderStepped que o drone já tem — nenhuma conexão nova.
--
-- Todos os valores vêm da câmera real (posição, velocidade integrada, yaw,
-- pitch, FOV) e da distância até o personagem. Nada é número decorativo.
--------------------------------------------------------------------------------
do
    local E = {}          -- todos os elementos, pra não estourar locais do chunk
    local built = false
    local recStart = 0
    local blinkT = 0
    local slowAcc = 0
    local originPos = nil -- posição do personagem quando o drone ligou

    local CY = Color3.fromRGB(90, 255, 210)   -- ciano-verde do HUD
    local WH = Color3.fromRGB(235, 245, 245)
    local RD = Color3.fromRGB(255, 70, 90)

    -- fábrica curta: mk("Frame", { ... }, parent)
    local function mk(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        o.Parent = parent
        return o
    end

    local function txt(parent, props)
        props.BackgroundTransparency = 1
        props.Font = props.Font or Enum.Font.Code
        props.TextSize = props.TextSize or 11
        props.TextColor3 = props.TextColor3 or CY
        props.RichText = false
        return mk("TextLabel", props, parent)
    end

    ----------------------------------------------------------------------------
    -- CREATE
    ----------------------------------------------------------------------------
    DroneHUD.Create = function()
        if built then return end

        -- CanvasGroup permite fade do HUD inteiro com um tween só.
        -- Se o executor não suportar, cai pra Frame (fade vira liga/desliga).
        local root
        local okCG = pcall(function()
            root = Instance.new("CanvasGroup")
            root.GroupTransparency = 1
        end)
        if not okCG or not root then
            root = Instance.new("Frame")
            E.noFade = true
        end
        root.Name = "DroneHUD"
        root.Size = UDim2.new(1, 0, 1, 0)
        root.BackgroundTransparency = 1
        root.BorderSizePixel = 0
        root.Visible = false
        root.ZIndex = 0            -- fica atrás da janela do painel
        root.Parent = Gui
        E.root = root

        ------------------------------------------------------------------ vinheta
        local vig = mk("Frame", {
            Name = "Vignette", Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
        }, root)
        for i, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
            local vertical = (i <= 2)
            local band = mk("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                Size = vertical and UDim2.new(1, 0, 0, 150) or UDim2.new(0, 190, 1, 0),
                Position = (side == "Top" and UDim2.new(0, 0, 0, 0))
                    or (side == "Bottom" and UDim2.new(0, 0, 1, -150))
                    or (side == "Left" and UDim2.new(0, 0, 0, 0))
                    or UDim2.new(1, -190, 0, 0),
            }, vig)
            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.55),
                NumberSequenceKeypoint.new(1, 1),
            })
            g.Rotation = (side == "Top" and 90) or (side == "Bottom" and 270)
                or (side == "Left" and 0) or 180
            g.Parent = band
        end

        ---------------------------------------------------------------- scanlines
        local scan = mk("Frame", {
            Name = "Scanlines", Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
        }, root)
        for i = 1, 90 do
            mk("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, i / 90, 0),
            }, scan)
        end

        ------------------------------------------------------- topo esquerdo
        local tl = mk("Frame", {
            Size = UDim2.new(0, 240, 0, 60), Position = UDim2.new(0, 26, 0, 22),
            BackgroundTransparency = 1, ZIndex = 5,
        }, root)

        E.online = txt(tl, {
            Text = "● DRONE ONLINE", TextSize = 13, Font = Enum.Font.GothamBold,
            Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left,
        })
        E.cam = txt(tl, {
            Text = "CAM 01   ·   LIVE", TextColor3 = WH, TextTransparency = 0.35,
            Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        E.rec = txt(tl, {
            Text = "● REC 00:00:00", TextColor3 = RD,
            Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 34),
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        --------------------------------------------------------- topo direito
        local tr = mk("Frame", {
            Size = UDim2.new(0, 210, 0, 118),
            Position = UDim2.new(1, -236, 0, 22),
            BackgroundTransparency = 1, ZIndex = 5,
        }, root)
        txt(tr, {
            Text = "DRONE CAM 01", Font = Enum.Font.GothamBold, TextSize = 12,
            Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Right,
        })
        mk("Frame", {
            BackgroundColor3 = CY, BackgroundTransparency = 0.65, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 17),
        }, tr)

        E.tech = {}
        for i, key in ipairs({ "ALTITUDE", "SPEED", "HEADING", "PITCH", "FOV", "SIGNAL" }) do
            E.tech[key] = txt(tr, {
                Text = key .. ": --",
                TextColor3 = WH, TextTransparency = 0.15,
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 0, 6 + i * 15),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        end

        ------------------------------------------------------- retículo central
        local ret = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 60, 0, 60), BackgroundTransparency = 1, ZIndex = 5,
        }, root)
        for i = 1, 4 do
            local horiz = (i <= 2)
            mk("Frame", {
                BackgroundColor3 = CY, BackgroundTransparency = 0.25, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = horiz and UDim2.new(0, 12, 0, 1) or UDim2.new(0, 1, 0, 12),
                Position = (i == 1 and UDim2.new(0.5, -16, 0.5, 0))
                    or (i == 2 and UDim2.new(0.5, 16, 0.5, 0))
                    or (i == 3 and UDim2.new(0.5, 0, 0.5, -16))
                    or UDim2.new(0.5, 0, 0.5, 16),
            }, ret)
        end
        mk("Frame", {
            BackgroundColor3 = CY, BackgroundTransparency = 0.1, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 2, 0, 2),
        }, ret)

        --------------------------------------------------------------- bússola
        local comp = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26),
            Size = UDim2.new(0, 320, 0, 18), BackgroundTransparency = 1,
            ClipsDescendants = true, ZIndex = 5,
        }, root)
        E.comp = comp
        E.marks = {}
        for i, name in ipairs({ "N", "NE", "E", "SE", "S", "SW", "W", "NW" }) do
            E.marks[i] = txt(comp, {
                Text = name, TextColor3 = WH, TextTransparency = 0.35,
                Font = Enum.Font.GothamMedium, TextSize = 11,
                AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 34, 0, 14),
                Position = UDim2.new(0.5, 0, 0, 2),
            })
            E.marks[i].Name = name
        end
        -- agulha: marca o centro exato da bússola
        mk("Frame", {
            BackgroundColor3 = CY, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0, 1, 0, 6),
        }, comp)

        ---------------------------------------------------- inferior esquerdo
        local bl = mk("Frame", {
            Size = UDim2.new(0, 220, 0, 96),
            Position = UDim2.new(0, 26, 1, -122),
            BackgroundTransparency = 1, ZIndex = 5,
        }, root)

        txt(bl, { Text = "ALT", TextTransparency = 0.3, TextSize = 10,
            Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left })
        E.alt = txt(bl, { Text = "0.0 m", TextColor3 = WH, TextSize = 17,
            Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 11), TextXAlignment = Enum.TextXAlignment.Left })

        txt(bl, { Text = "DIST", TextTransparency = 0.3, TextSize = 10,
            Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 34),
            TextXAlignment = Enum.TextXAlignment.Left })
        E.dist = txt(bl, { Text = "0.0 m", TextColor3 = WH, TextSize = 17,
            Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 45), TextXAlignment = Enum.TextXAlignment.Left })

        txt(bl, { Text = "SIGNAL", TextTransparency = 0.3, TextSize = 10,
            Size = UDim2.new(0, 50, 0, 12), Position = UDim2.new(0, 0, 0, 70),
            TextXAlignment = Enum.TextXAlignment.Left })
        E.bars = {}
        for i = 1, 8 do
            E.bars[i] = mk("Frame", {
                BackgroundColor3 = CY, BorderSizePixel = 0,
                Size = UDim2.new(0, 7, 0, 9),
                Position = UDim2.new(0, 46 + (i - 1) * 9, 0, 71),
            }, bl)
        end
        E.sigPct = txt(bl, { Text = "100%", TextSize = 10,
            Size = UDim2.new(0, 44, 0, 12), Position = UDim2.new(0, 124, 0, 70),
            TextXAlignment = Enum.TextXAlignment.Left })

        ----------------------------------------------------- inferior direito
        local br = mk("Frame", {
            Size = UDim2.new(0, 150, 0, 40),
            Position = UDim2.new(1, -176, 1, -80),
            BackgroundTransparency = 1, ZIndex = 5,
        }, root)
        txt(br, { Text = "SPD", TextTransparency = 0.3, TextSize = 10,
            Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Right })
        E.spd = txt(br, { Text = "0.0", TextColor3 = WH, TextSize = 19,
            Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0, 11), TextXAlignment = Enum.TextXAlignment.Right })

        --------------------------------------------------- controles (rodapé)
        E.ctrl = txt(root, {
            Text = "WASD  MOVE      E / Q  ALTITUDE      MOUSE  LOOK"
                .. "      SCROLL  SPEED      G  EXIT DRONE",
            TextColor3 = WH, TextTransparency = 0.45, TextSize = 11,
            AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22),
            Size = UDim2.new(0, 700, 0, 14), ZIndex = 5,
        })

        built = true
    end

    ----------------------------------------------------------------------------
    -- SHOW / HIDE (fade)
    ----------------------------------------------------------------------------
    local function Fade(to, hideAfter)
        if E.noFade then
            E.root.Visible = (to == 0)
            return
        end
        local tw = TweenService:Create(E.root,
            TweenInfo.new(0.28, Enum.EasingStyle.Quad), { GroupTransparency = to })
        if hideAfter then
            tw.Completed:Connect(function()
                if E.root then E.root.Visible = false end
            end)
        end
        tw:Play()
    end

    DroneHUD.Show = function()
        DroneHUD.Create()
        if not E.root then return end

        recStart = os.clock()
        blinkT = 0
        slowAcc = 1        -- força um refresh no primeiro frame
        originPos = nil
        pcall(function()
            local r = Root()
            if r then originPos = r.Position end
        end)

        -- o texto de controles usa o keybind REAL do drone
        local kc = Keybinds and Keybinds["drone"]
        local kn = kc and KeyName(kc) or "—"
        E.ctrl.Text = "WASD  MOVE      E / Q  ALTITUDE      MOUSE  LOOK"
            .. "      SCROLL  SPEED      " .. kn .. "  EXIT DRONE"
        -- v8.0: o dock solto ocupa o centro do rodapé — a linha sobe acima dele
        E.ctrl.Position = UDim2.new(0.5, 0, 1, (SET.Dock == true) and -84 or -22)

        E.root.Visible = true
        Fade(0, false)
    end

    DroneHUD.Hide = function()
        if not E.root then return end
        Fade(1, true)
    end

    DroneHUD.Destroy = function()
        if E.root then pcall(function() E.root:Destroy() end) end
        E.root = nil
        built = false
    end

    ----------------------------------------------------------------------------
    -- UPDATE — chamado pelo RenderStepped que o drone JÁ tem
    ----------------------------------------------------------------------------
    DroneHUD.Update = function(dt, pos, vel, yaw, pitch)
        if not built or not E.root or not E.root.Visible then return end

        -- heading real da câmera: 0° = -Z (norte), cresce no sentido horário
        local heading = (-math.deg(yaw)) % 360

        -- bússola: cada ponto cardeal a 34px por 45°, deslizando pelo heading
        for i = 1, 8 do
            local diff = ((i - 1) * 45 - heading + 180) % 360 - 180
            local m = E.marks[i]
            m.Position = UDim2.new(0.5, diff * 1.9, 0, 2)
            if math.abs(diff) < 22.5 then
                m.TextColor3 = CY
                m.TextTransparency = 0
                m.TextSize = 13
            else
                m.TextColor3 = WH
                m.TextTransparency = 0.55
                m.TextSize = 11
            end
        end

        -- pisca do "DRONE ONLINE" (suave, sem tween por frame)
        blinkT = blinkT + dt
        E.online.TextTransparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(blinkT * 3))

        -- textos pesados: ~10Hz, não a cada frame
        slowAcc = slowAcc + dt
        if slowAcc < 0.1 then return end
        slowAcc = 0

        local speed = vel.Magnitude
        local alt = pos.Y

        local dist = 0
        local ref = originPos
        local r = Root()
        if r then ref = r.Position end
        if ref then dist = (pos - ref).Magnitude end

        -- sinal: 100% até 250m, cai suave até 25% em 2500m (não pisca de longe)
        local sig = 100
        if dist > 250 then
            sig = 100 - (dist - 250) / 2250 * 75
        end
        sig = math.clamp(math.floor(sig + 0.5), 25, 100)

        local fov = math.floor(Camera.FieldOfView + 0.5)
        local pdeg = math.deg(pitch)

        E.alt.Text = string.format("%.1f m", alt)
        E.dist.Text = string.format("%.1f m", dist)
        E.spd.Text = string.format("%.1f", speed)
        E.sigPct.Text = sig .. "%"

        E.tech.ALTITUDE.Text = string.format("ALTITUDE: %06.1f m", alt)
        E.tech.SPEED.Text    = string.format("SPEED: %05.1f", speed)
        E.tech.HEADING.Text  = string.format("HEADING: %03d°", math.floor(heading + 0.5))
        E.tech.PITCH.Text    = string.format("PITCH: %+03d°", math.floor(pdeg + 0.5))
        E.tech.FOV.Text      = "FOV: " .. fov .. "°"
        E.tech.SIGNAL.Text   = "SIGNAL: " .. sig .. "%"

        local lit = math.clamp(math.ceil(sig / 12.5), 1, 8)
        for i = 1, 8 do
            E.bars[i].BackgroundTransparency = (i <= lit) and 0.1 or 0.8
        end

        local t = math.floor(os.clock() - recStart)
        E.rec.Text = string.format("● REC %02d:%02d:%02d",
            math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
    end
end
--------------------------------------------------------------------------------
-- ABA HOME (dashboard)
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Home")

    ----------------------------------------------------------------------------
    -- VISÃO GERAL
    ----------------------------------------------------------------------------
    local overview = CreateCard(tab, "VISÃO GERAL", 1)
    local grid = Grid(overview, 4, 48)
    Tiles = {}

    local function T(key, label, def, colorKey)
        local val = StatTile(grid, label, def, #Tiles + 1, colorKey)
        Tiles[key] = val
        return val
    end

    T("fps",     "FPS",       "—", "Success")
    T("ping",    "PING",      "—", "Accent2")
    T("players", "JOGADORES", "—")
    T("uptime",  "UPTIME",    "—")

    ----------------------------------------------------------------------------
    -- SEGUNDA FILEIRA: identificadores com botão de copiar
    ----------------------------------------------------------------------------
    local grid2 = Grid(overview, 4, 62)

    local function InfoCard(label, value, iconKind, iconColor, order, copyFn)
        local box = Instance.new("Frame")
        box.BackgroundColor3 = THEME.Btn
        box.BorderSizePixel = 0
        box.LayoutOrder = order
        box.Parent = grid2
        Paint(box, "BackgroundColor3", "Btn")
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
        local st = Instance.new("UIStroke", box)
        st.Transparency = 0.85
        Paint(st, "Color", "Line")

        local cap = Instance.new("TextLabel")
        cap.Size = UDim2.new(1, -34, 0, 12)
        cap.Position = UDim2.new(0, 9, 0, 8)
        cap.BackgroundTransparency = 1
        cap.Text = label
        cap.TextColor3 = THEME.Dim
        cap.Font = Enum.Font.GothamBold
        cap.TextSize = 9
        cap.TextXAlignment = Enum.TextXAlignment.Left
        cap.Parent = box
        Paint(cap, "TextColor3", "Dim")

        local ic = Icon(box, iconKind, iconColor, 15)
        ic.Position = UDim2.new(1, -24, 0, 8)

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(1, -42, 0, 32)
        val.Position = UDim2.new(0, 9, 0, 23)
        val.BackgroundTransparency = 1
        val.Text = tostring(value)
        val.TextColor3 = THEME.Text
        val.Font = Enum.Font.GothamBold
        val.TextSize = 14
        val.TextWrapped = true
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.TextYAlignment = Enum.TextYAlignment.Top
        val.Parent = box
        Paint(val, "TextColor3", "Text")

        if copyFn then
            local cb = Instance.new("TextButton")
            cb.AnchorPoint = Vector2.new(1, 1)
            cb.Position = UDim2.new(1, -7, 1, -7)
            cb.Size = UDim2.new(0, 22, 0, 22)
            cb.BackgroundTransparency = 1
            cb.Text = ""
            cb.AutoButtonColor = false
            cb.Parent = box
            Icon(cb, "copy", THEME.Dim, 14).Position = UDim2.new(0, 4, 0, 4)
            cb.MouseButton1Click:Connect(function()
                local text = copyFn()
                if setclipboard then
                    setclipboard(text)
                    Toast("Copiado: " .. text, "ok", 1.6)
                else
                    print("[HYGE] " .. text)
                    Toast("Executor sem setclipboard — jogado no output", "warn")
                end
            end)
        end
        return val
    end

    Tiles.place = InfoCard("PLACE ID", tostring(game.PlaceId), "box", THEME.Accent, 1,
        function() return tostring(game.PlaceId) end)
    Tiles.job = InfoCard("JOB ID", "—", "clip", THEME.Accent, 2,
        function() return (game.JobId ~= "" and game.JobId or "estúdio") end)
    Tiles.active = InfoCard("FUNÇÕES ON", "0", "bolt", THEME.Warning, 3)
    Tiles.remotes = InfoCard("REMOTES", "—", "wifi", THEME.Accent2, 4)

    ----------------------------------------------------------------------------
    -- QUICK ACTIONS (pílulas com switch real)
    ----------------------------------------------------------------------------
    local quick = CreateCard(tab, "AÇÕES RÁPIDAS", 2)
    SubLabel(quick, "Um clique liga/desliga. O switch mostra o estado real do toggle.", -1)

    local qGrid = Grid(quick, 4, 40)
    local quickBtns = {}

    local QUICK = {
        { "fly", "Fly", "bolt", "Accent2" },
        { "noclip", "Noclip", "ghost", "Accent" },
        { "esp", "ESP", "eye", "Success" },
        { "freecam", "Freecam", "cam", "Accent" },
        { "infjump", "Inf Jump", "up", "Accent2" },
        { "god", "God", "shield", "Success" },
        { "invisible", "Invisível", "circle", "Accent" },
        { "fullbright", "Fullbright", "sun", "Warning" },
    }

    for i, item in ipairs(QUICK) do
        local id, label, kind, ck = item[1], item[2], item[3], item[4]

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundColor3 = THEME.Btn
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.Parent = qGrid
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
        local bs = Instance.new("UIStroke", b)
        bs.Transparency = 0.85
        Paint(bs, "Color", "Line")

        local ic = Icon(b, kind, THEME[ck], 16)
        ic.Position = UDim2.new(0, 10, 0.5, -8)

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -100, 1, 0)
        lb.Position = UDim2.new(0, 34, 0, 0)
        lb.BackgroundTransparency = 1
        lb.Text = label
        lb.TextColor3 = THEME.Text
        lb.Font = Enum.Font.GothamMedium
        lb.TextSize = 12
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Parent = b
        Paint(lb, "TextColor3", "Text")

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, -44, 0.5, 0)
        track.Size = UDim2.new(0, 32, 0, 17)
        track.BackgroundColor3 = THEME.Track
        track.BorderSizePixel = 0
        track.Parent = b
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = UDim2.new(0, 2, 0.5, 0)
        knob.Size = UDim2.new(0, 13, 0, 13)
        knob.BackgroundColor3 = THEME.Text
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = Instance.new("TextLabel")
        state.AnchorPoint = Vector2.new(1, 0.5)
        state.Position = UDim2.new(1, -8, 0.5, 0)
        state.Size = UDim2.new(0, 30, 0, 14)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = THEME.Dim
        state.Font = Enum.Font.GothamBold
        state.TextSize = 10
        state.TextXAlignment = Enum.TextXAlignment.Right
        state.Parent = b

        b.MouseButton1Click:Connect(function() Flip(id) end)
        quickBtns[id] = { track = track, knob = knob, state = state, icon = ic, key = ck }
    end

    ----------------------------------------------------------------------------
    -- DESLIGAR TUDO (centralizado)
    ----------------------------------------------------------------------------
    local offHolder = Instance.new("Frame")
    offHolder.Size = UDim2.new(1, 0, 0, 40)
    offHolder.BackgroundTransparency = 1
    offHolder.LayoutOrder = 90
    offHolder.Parent = quick

    local allOff = Instance.new("TextButton")
    allOff.AnchorPoint = Vector2.new(0.5, 0.5)
    allOff.Position = UDim2.new(0.5, 0, 0.5, 0)
    allOff.Size = UDim2.new(0, 300, 0, 34)
    allOff.BackgroundColor3 = THEME.Danger
    allOff.Text = "DESLIGAR TUDO"
    allOff.TextColor3 = Color3.fromRGB(255, 235, 235)
    allOff.Font = Enum.Font.GothamBold
    allOff.TextSize = 13
    allOff.AutoButtonColor = false
    allOff.Parent = offHolder
    Paint(allOff, "BackgroundColor3", "Danger")
    Instance.new("UICorner", allOff).CornerRadius = UDim.new(0, 9)
    Icon(allOff, "power", Color3.fromRGB(255, 235, 235), 16).Position =
        UDim2.new(0, 78, 0.5, -8)

    allOff.MouseEnter:Connect(function()
        Anim(allOff, 0.12, { BackgroundTransparency = 0.15 })
    end)
    allOff.MouseLeave:Connect(function()
        Anim(allOff, 0.12, { BackgroundTransparency = 0 })
    end)

    allOff.MouseButton1Click:Connect(function()
        local n = 0
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then
                SetToggle(id, false, true)
                n = n + 1
            end
        end
        if State.Spectating then StopSpectate() end
        Log("Desligar tudo: " .. n .. " função(ões) encerrada(s)", "action")
        Toast(n .. " função(ões) desligada(s)", "ok", 2)
        if RefreshQuick then RefreshQuick() end
        if RefreshStatus then RefreshStatus() end
    end)

    -- RefreshQuick: chamado pelo scheduler e pelo registry de toggles
    RefreshQuick = function()
        local active = 0
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then active = active + 1 end
        end
        for id, ref in pairs(quickBtns) do
            local on = IsOn(id)
            ref.state.Text = on and "ON" or "OFF"
            ref.state.TextColor3 = on and THEME.Success or THEME.Dim
            Anim(ref.track, 0.14, { BackgroundColor3 = on and THEME.Success or THEME.Track })
            Anim(ref.knob, 0.14, {
                Position = on and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                BackgroundColor3 = on and Color3.fromRGB(15, 22, 20) or THEME.Text,
            })
            IconTint(ref.icon, on and THEME[ref.key] or THEME.Dim)
        end
        if Tiles.active then Tiles.active.Text = tostring(active) end
    end

    ----------------------------------------------------------------------------
    -- ATALHOS (rodapé compacto)
    ----------------------------------------------------------------------------
    local info = CreateCard(tab, nil, 3)
    local keysLbl = SubLabel(info, "", 1)
    keysLbl.TextSize = 10

    -- v8.0: o rodapé lê os atalhos REAIS (antes era texto fixo F/N/E/C/G e
    -- mentia depois de remapear em Ajustes)
    local function ShortcutText()
        local parts = { "ATALHOS", "[" .. KeyName(CONFIG.PanelKey) .. "] painel",
            "[" .. KeyName(CONFIG.ConsoleKey) .. "] comandos" }
        if CONFIG.SearchKey then
            table.insert(parts, "[" .. (CONFIG.SearchCtrl and "Ctrl+" or "")
                .. KeyName(CONFIG.SearchKey) .. "] busca")
        end
        for _, id in ipairs(ToggleOrder) do
            if Keybinds[id] then
                table.insert(parts, "[" .. KeyName(Keybinds[id]) .. "] "
                    .. (Toggles[id].label or id))
            end
        end
        table.insert(parts, "remapeável em Ajustes")
        return table.concat(parts, "   ·   ")
    end
    keysLbl.Text = ShortcutText()

    OnTabOpen("Home", function()
        pcall(function() keysLbl.Text = ShortcutText() end)
        if RefreshQuick then RefreshQuick() end
        if Tiles.job then
            Tiles.job.Text = (game.JobId ~= "" and game.JobId or "estúdio")
        end
    end)
end
--------------------------------------------------------------------------------
-- v8.0 — DASHBOARD DA HOME (header + relogio, tira de status, card do jogador
-- com chat rapido e Friend Activity). Tudo pendurado em V8.Dash: zero locais
-- novos no chunk principal. Entra DEPOIS de 40_tabs/00_home.lua no build.
--------------------------------------------------------------------------------
do
    V8.Dash = {}
    local D = V8.Dash
    local home = Tabs.Home
    if not home then return end

    ----------------------------------------------------------------------------
    -- 1. HEADER: "Welcome home, <nome>" + relogio
    ----------------------------------------------------------------------------
    local head = Instance.new("Frame")
    head.Name = "Card"
    head.Size = UDim2.new(1, 0, 0, 62)
    head.BackgroundColor3 = THEME.Card
    head.BackgroundTransparency = 0.25
    head.BorderSizePixel = 0
    head.LayoutOrder = -3
    head.Parent = home
    Paint(head, "BackgroundColor3", "Card")
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 12)
    D.Head = head   -- o shell esconde este card (o welcome subiu pra TopBar)

    do  -- gradiente diagonal (o look azul do mockup)
        local g = Instance.new("UIGradient", head)
        g.Rotation = 25
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.5),
        })
    end

    local welcome = Instance.new("TextLabel")
    welcome.Size = UDim2.new(1, -160, 0, 24)
    welcome.Position = UDim2.new(0, 16, 0, 11)
    welcome.BackgroundTransparency = 1
    welcome.Text = "Welcome home, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
    welcome.TextColor3 = THEME.Text
    welcome.Font = Enum.Font.GothamBold
    welcome.TextSize = 19
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.TextTruncate = Enum.TextTruncate.AtEnd
    welcome.Parent = head
    Paint(welcome, "TextColor3", "Text")

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -160, 0, 14)
    sub.Position = UDim2.new(0, 16, 0, 35)
    sub.BackgroundTransparency = 1
    sub.Text = "HYGE " .. CONFIG.Version
    sub.TextColor3 = THEME.Dim
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = head
    Paint(sub, "TextColor3", "Dim")

    local clockIco = Icon(head, "clock", THEME.Dim, 16, 1)
    clockIco.Position = UDim2.new(1, -104, 0.5, -8)

    local clockLbl = Instance.new("TextLabel")
    clockLbl.Size = UDim2.new(0, 78, 0, 22)
    clockLbl.Position = UDim2.new(1, -84, 0.5, -11)
    clockLbl.BackgroundTransparency = 1
    clockLbl.Text = "--:--"
    clockLbl.TextColor3 = THEME.Text
    clockLbl.Font = Enum.Font.GothamBold
    clockLbl.TextSize = 16
    clockLbl.TextXAlignment = Enum.TextXAlignment.Right
    clockLbl.Parent = head
    Paint(clockLbl, "TextColor3", "Text")

    ----------------------------------------------------------------------------
    -- 2. TIRA DE STATUS: 3 colunas clicaveis (igual ao mockup)
    ----------------------------------------------------------------------------
    -- a tira nao e mais um card unico: sao 3 cards arredondados separados
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1, 0, 0, 72)
    strip.BackgroundTransparency = 1
    strip.LayoutOrder = -2
    strip.Parent = home

    D.Slots = { "fly", "noclip", "esp" }   -- o que cada card mostra
    -- icone por toggle (o card sempre mostra o icone do que ele controla)
    D.SlotIcons = {
        fly = "bolt", noclip = "ghost", esp = "eye", god = "shield",
        invisible = "circle", infjump = "up", wall = "box", chatspy = "clip",
        fullbright = "sun", antiafk = "clock", freecam = "cam", drone = "wifi",
    }
    local slotUI = {}

    for i = 1, 3 do
        local col = Instance.new("TextButton")
        col.Name = "Card"
        col.Size = UDim2.new(1 / 3, -8, 1, 0)
        col.Position = UDim2.new((i - 1) / 3, (i - 1) * 4, 0, 0)
        col.BackgroundColor3 = THEME.Card
        col.BorderSizePixel = 0
        col.Text = ""
        col.AutoButtonColor = false
        col.Parent = strip
        Paint(col, "BackgroundColor3", "Card")
        Instance.new("UICorner", col).CornerRadius = UDim.new(0, 12)
        local colStroke = Instance.new("UIStroke", col)
        colStroke.Transparency = 0.6
        Paint(colStroke, "Color", "Line")

        -- caixinha do icone
        local pad = Instance.new("Frame")
        pad.Size = UDim2.new(0, 34, 0, 34)
        pad.Position = UDim2.new(0, 12, 0.5, -17)
        pad.BackgroundColor3 = THEME.Btn
        pad.BorderSizePixel = 0
        pad.Parent = col
        Paint(pad, "BackgroundColor3", "Btn")
        Instance.new("UICorner", pad).CornerRadius = UDim.new(0, 10)

        local ico = Icon(pad, "dot", THEME.Dim, 18, 1)
        ico.AnchorPoint = Vector2.new(0.5, 0.5)
        ico.Position = UDim2.new(0.5, 0, 0.5, 0)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -60, 0, 20)
        name.Position = UDim2.new(0, 54, 0, 16)
        name.BackgroundTransparency = 1
        name.Text = "—"
        name.TextColor3 = THEME.Text
        name.Font = Enum.Font.GothamBold
        name.TextSize = 15
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = col
        Paint(name, "TextColor3", "Text")

        local state = Instance.new("TextLabel")
        state.Size = UDim2.new(1, -60, 0, 14)
        state.Position = UDim2.new(0, 54, 0, 38)
        state.BackgroundTransparency = 1
        state.Text = "Off"
        state.TextColor3 = THEME.Dim
        state.Font = Enum.Font.GothamMedium
        state.TextSize = 12
        state.TextXAlignment = Enum.TextXAlignment.Left
        state.Parent = col
        Paint(state, "TextColor3", "Dim")

        col.MouseEnter:Connect(function() colStroke.Transparency = 0.25 end)
        col.MouseLeave:Connect(function() colStroke.Transparency = 0.6 end)
        col.MouseButton1Click:Connect(function()
            local id = D.Slots[i]
            if id and Toggles[id] then
                Flip(id)
                pcall(D.Tick)
            else
                Log("Card " .. i .. " não tem um toggle válido "
                    .. "(ajuste em Ajustes › Navegação)", "warn")
            end
        end)

        slotUI[i] = { name = name, state = state, icon = ico,
                      pad = pad, stroke = colStroke, card = col }
    end

    ----------------------------------------------------------------------------
    -- troca o que os 3 cards controlam. Aceita "fly noclip esp" ou tabela.
    ----------------------------------------------------------------------------
    D.SetSlots = function(spec, silent)
        local list = {}
        if type(spec) == "table" then
            for i = 1, 3 do list[i] = spec[i] end
        elseif type(spec) == "string" then
            for w in spec:gmatch("[%w_]+") do
                if #list < 3 then list[#list + 1] = w:lower() end
            end
        end
        local bad = {}
        for i = 1, 3 do
            local id = list[i]
            if id and Toggles[id] then
                D.Slots[i] = id
            elseif id then
                bad[#bad + 1] = id
            end
        end
        pcall(D.Tick)
        if not silent then
            if #bad > 0 then
                Log("Ignorei toggle inexistente: " .. table.concat(bad, ", "), "warn")
            end
            Log("Cards de status: " .. table.concat(D.Slots, " "), "ok")
        end
        return table.concat(D.Slots, " ")
    end

    ----------------------------------------------------------------------------
    -- 3. LINHA DE BAIXO: card do jogador  |  Friend Activity
    ----------------------------------------------------------------------------
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 250)
    row.BackgroundTransparency = 1
    row.LayoutOrder = -1
    row.Parent = home

    local function Panel(xScale, xOff, wScale, wOff)
        local p = Instance.new("Frame")
        p.Name = "Card"
        p.Size = UDim2.new(wScale, wOff, 1, 0)
        p.Position = UDim2.new(xScale, xOff, 0, 0)
        p.BackgroundColor3 = THEME.Card
        p.BorderSizePixel = 0
        p.Parent = row
        Paint(p, "BackgroundColor3", "Card")
        Instance.new("UICorner", p).CornerRadius = UDim.new(0, 12)
        local st = Instance.new("UIStroke", p)
        st.Transparency = 0.6
        Paint(st, "Color", "Line")
        return p
    end

    local me = Panel(0, 0, 0.46, -6)
    local fr = Panel(0.46, 6, 0.54, -6)

    ---------------------------------------------------------------- card do eu
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 112, 0, 112)
    ring.Position = UDim2.new(0.5, -56, 0, 16)
    ring.BackgroundTransparency = 1
    ring.Parent = me
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    do
        local st = Instance.new("UIStroke", ring)
        st.Thickness = 2
        Paint(st, "Color", "Accent")
    end

    local face = Instance.new("ImageLabel")
    face.Size = UDim2.new(1, -10, 1, -10)
    face.Position = UDim2.new(0, 5, 0, 5)
    face.BackgroundColor3 = THEME.Track
    face.BorderSizePixel = 0
    face.Image = "rbxthumb://type=AvatarThumbnail&id="
        .. tostring(LocalPlayer.UserId) .. "&w=420&h=420"
    face.Parent = ring
    Paint(face, "BackgroundColor3", "Track")
    Instance.new("UICorner", face).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(1, -20, 1, -26)
    dot.BackgroundColor3 = THEME.Success
    dot.BorderSizePixel = 0
    dot.Parent = ring
    Paint(dot, "BackgroundColor3", "Success")
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    do
        local st = Instance.new("UIStroke", dot)
        st.Thickness = 3
        Paint(st, "Color", "Card")
    end

    -- nome + selo de verificado (o selo e desenhado pelo shell, que carrega
    -- depois: aqui fica so a linha que o abriga)
    local nameRow = Instance.new("Frame")
    nameRow.Name = "NameRow"
    nameRow.Size = UDim2.new(1, -20, 0, 22)
    nameRow.Position = UDim2.new(0, 10, 0, 136)
    nameRow.BackgroundTransparency = 1
    nameRow.Parent = me
    do
        local l = Instance.new("UIListLayout", nameRow)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    D.NameRow = nameRow

    local myName = Instance.new("TextLabel")
    myName.AutomaticSize = Enum.AutomaticSize.X
    myName.Size = UDim2.new(0, 0, 0, 20)
    myName.BackgroundTransparency = 1
    myName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    myName.TextColor3 = THEME.Text
    myName.Font = Enum.Font.GothamBold
    myName.TextSize = 16
    myName.LayoutOrder = 1
    myName.Parent = nameRow
    Paint(myName, "TextColor3", "Text")

    local myTag = Instance.new("TextLabel")
    myTag.Size = UDim2.new(1, -20, 0, 14)
    myTag.Position = UDim2.new(0, 10, 0, 159)
    myTag.BackgroundTransparency = 1
    myTag.Text = "@" .. LocalPlayer.Name
    myTag.TextColor3 = THEME.Dim
    myTag.Font = Enum.Font.GothamMedium
    myTag.TextSize = 12
    myTag.TextXAlignment = Enum.TextXAlignment.Center
    myTag.Parent = me
    Paint(myTag, "TextColor3", "Dim")

    ------------------------------------------------------------ chat rapido
    local chatBox = Instance.new("Frame")
    chatBox.Size = UDim2.new(1, -24, 0, 40)
    chatBox.Position = UDim2.new(0, 12, 1, -52)
    chatBox.BackgroundColor3 = THEME.Btn
    chatBox.BorderSizePixel = 0
    chatBox.Parent = me
    Paint(chatBox, "BackgroundColor3", "Btn")
    Instance.new("UICorner", chatBox).CornerRadius = UDim.new(0, 10)
    do
        local st = Instance.new("UIStroke", chatBox)
        st.Transparency = 0.7
        Paint(st, "Color", "Line")
    end

    local chatIco = Icon(chatBox, "smile", THEME.Dim, 16, 1)
    chatIco.Position = UDim2.new(0, 12, 0.5, -8)

    local chatInput = Instance.new("TextBox")
    chatInput.Size = UDim2.new(1, -46, 1, 0)
    chatInput.Position = UDim2.new(0, 38, 0, 0)
    chatInput.BackgroundTransparency = 1
    chatInput.Text = ""
    chatInput.PlaceholderText = "Chat..."
    chatInput.TextColor3 = THEME.Text
    chatInput.PlaceholderColor3 = THEME.Dim
    chatInput.Font = Enum.Font.GothamMedium
    chatInput.TextSize = 13
    chatInput.TextXAlignment = Enum.TextXAlignment.Left
    chatInput.ClearTextOnFocus = false
    chatInput.Parent = chatBox
    Paint(chatInput, "TextColor3", "Text")
    Paint(chatInput, "PlaceholderColor3", "Dim")

    -- manda no chat DO JOGO pelo seu proprio player. Cobre os dois sistemas.
    D.Say = function(msg)
        if type(msg) ~= "string" or msg:gsub("%s", "") == "" then return false end
        local sent = false

        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                local ch = tcs:FindFirstChild("TextChannels")
                ch = ch and ch:FindFirstChild("RBXGeneral")
                if ch then
                    ch:SendAsync(msg)
                    sent = true
                end
            end
        end)

        if not sent then
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local say = ev and ev:FindFirstChild("SayMessageRequest")
                if say then
                    say:FireServer(msg, "All")
                    sent = true
                end
            end)
        end

        if sent then
            Log("Chat: " .. msg, "action")
        else
            Log("Não achei o sistema de chat deste jogo — nada foi enviado", "error")
            Toast("Chat indisponível neste jogo", "error", 4)
        end
        return sent
    end

    chatInput.FocusLost:Connect(function(enter)
        local msg = chatInput.Text
        chatInput.Text = ""
        if enter then D.Say(msg) end
    end)

    -------------------------------------------------------- Friend Activity
    local frHead = Instance.new("TextLabel")
    frHead.Size = UDim2.new(1, -100, 0, 20)
    frHead.Position = UDim2.new(0, 14, 0, 12)
    frHead.BackgroundTransparency = 1
    frHead.Text = "Friend Activity"
    frHead.TextColor3 = THEME.Text
    frHead.Font = Enum.Font.GothamBold
    frHead.TextSize = 14
    frHead.TextXAlignment = Enum.TextXAlignment.Left
    frHead.Parent = fr
    Paint(frHead, "TextColor3", "Text")

    local frBtn = CreateButton(fr, "ATUALIZAR", "Accent", 22)
    frBtn.Size = UDim2.new(0, 84, 0, 22)
    frBtn.Position = UDim2.new(1, -98, 0, 11)
    frBtn.TextSize = 10

    local frList = Instance.new("ScrollingFrame")
    frList.Size = UDim2.new(1, -20, 1, -50)
    frList.Position = UDim2.new(0, 10, 0, 40)
    frList.BackgroundTransparency = 1
    frList.BorderSizePixel = 0
    frList.ScrollBarThickness = 3
    frList.CanvasSize = UDim2.new(0, 0, 0, 0)
    frList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frList.Parent = fr
    Paint(frList, "ScrollBarImageColor3", "Accent")
    do
        local l = Instance.new("UIListLayout", frList)
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local frEmpty = Instance.new("TextLabel")
    frEmpty.Size = UDim2.new(1, 0, 0, 40)
    frEmpty.BackgroundTransparency = 1
    frEmpty.Text = "Clique em ATUALIZAR"
    frEmpty.TextColor3 = THEME.Dim
    frEmpty.Font = Enum.Font.GothamMedium
    frEmpty.TextSize = 12
    frEmpty.TextWrapped = true
    frEmpty.LayoutOrder = 999
    frEmpty.Parent = frList
    Paint(frEmpty, "TextColor3", "Dim")

    D.Friends = function(silent)
        for _, c in ipairs(frList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local ok, list = pcall(function() return LocalPlayer:GetFriendsOnline(12) end)
        if not ok or type(list) ~= "table" then
            frEmpty.Text = "Seu executor não deixou ler a lista de amigos"
            frEmpty.Visible = true
            if not silent then Log("GetFriendsOnline falhou neste executor", "warn") end
            return
        end
        if #list == 0 then
            frEmpty.Text = "Nenhum amigo online agora"
            frEmpty.Visible = true
            if not silent then Log("Nenhum amigo online", "info") end
            return
        end
        frEmpty.Visible = false

        for i, f in ipairs(list) do
            local rowf = Instance.new("Frame")
            rowf.Size = UDim2.new(1, -6, 0, 46)
            rowf.BackgroundColor3 = THEME.Btn
            rowf.BorderSizePixel = 0
            rowf.LayoutOrder = i
            rowf.Parent = frList
            Paint(rowf, "BackgroundColor3", "Btn")
            Instance.new("UICorner", rowf).CornerRadius = UDim.new(0, 9)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 34, 0, 34)
            thumb.Position = UDim2.new(0, 6, 0, 6)
            thumb.BackgroundColor3 = THEME.Track
            thumb.BorderSizePixel = 0
            thumb.Parent = rowf
            Paint(thumb, "BackgroundColor3", "Track")
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 7)
            if f.PlaceId then
                thumb.Image = "rbxthumb://type=GameIcon&id="
                    .. tostring(f.PlaceId) .. "&w=150&h=150"
            else
                thumb.Image = "rbxthumb://type=AvatarHeadShot&id="
                    .. tostring(f.VisitorId) .. "&w=48&h=48"
            end

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -136, 0, 16)
            nm.Position = UDim2.new(0, 46, 0, 7)
            nm.BackgroundTransparency = 1
            nm.Text = tostring(f.DisplayName or f.UserName or "?")
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = rowf
            Paint(nm, "TextColor3", "Text")

            local loc = Instance.new("TextLabel")
            loc.Size = UDim2.new(1, -136, 0, 13)
            loc.Position = UDim2.new(0, 46, 0, 24)
            loc.BackgroundTransparency = 1
            loc.Text = tostring(f.LastLocation or "Online")
            loc.TextColor3 = THEME.Dim
            loc.Font = Enum.Font.GothamMedium
            loc.TextSize = 11
            loc.TextXAlignment = Enum.TextXAlignment.Left
            loc.TextTruncate = Enum.TextTruncate.AtEnd
            loc.Parent = rowf
            Paint(loc, "TextColor3", "Dim")

            if f.PlaceId and f.GameId then
                local join = CreateButton(rowf, "ENTRAR", "Success", 24)
                join.Size = UDim2.new(0, 74, 0, 24)
                join.Position = UDim2.new(1, -82, 0.5, -12)
                join.TextSize = 10
                join.MouseButton1Click:Connect(function()
                    Confirm("Teleportar para o servidor de "
                        .. tostring(f.DisplayName or f.UserName) .. "?", function()
                        Log("Teleportando para o jogo de "
                            .. tostring(f.UserName), "action")
                        local okT, errT = pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                f.PlaceId, f.GameId, LocalPlayer)
                        end)
                        if not okT then
                            Log("Teleporte recusado: " .. tostring(errT), "error")
                        end
                    end)
                end)
            end
        end

        if not silent then Log(#list .. " amigo(s) online", "ok") end
    end

    frBtn.MouseButton1Click:Connect(function() D.Friends() end)

    ----------------------------------------------------------------------------
    -- 4. TICK (relogio + tira de status) — chamado pelo Every(1) de 90_runtime/04_scheduler.lua
    ----------------------------------------------------------------------------
    D.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
        for i = 1, 3 do
            local id = D.Slots[i]
            local ui = slotUI[i]
            if ui then
                if id and Toggles[id] then
                    local on = IsOn(id)
                    ui.name.Text = (Toggles[id].label or id)
                    ui.state.Text = on and "On" or "Off"
                    ui.state.TextColor3 = on and THEME.Success or THEME.Dim
                    ui.name.TextColor3 = on and THEME.Text or THEME.Dim
                    -- icone do toggle: aceso no Accent, apagado no Dim
                    if ui.iconKind ~= (D.SlotIcons[id] or "dot") then
                        ui.iconKind = D.SlotIcons[id] or "dot"
                        ui.icon:Destroy()
                        ui.icon = Icon(ui.pad, ui.iconKind, THEME.Dim, 18, 1)
                        ui.icon.AnchorPoint = Vector2.new(0.5, 0.5)
                        ui.icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                    end
                    IconTint(ui.icon, on and THEME.Accent or THEME.Dim)
                    ui.pad.BackgroundTransparency = on and 0 or 0.45
                else
                    ui.name.Text = "—"
                    ui.state.Text = ""
                    IconTint(ui.icon, THEME.Dim)
                end
            end
        end
    end

    -- abrir a Home ja atualiza a tira (o registry acumula: o hook de 00_home.lua
    -- continua rodando tambem)
    OnTabOpen("Home", function() pcall(D.Tick) end)

    pcall(D.Tick)
end
--------------------------------------------------------------------------------
-- ABA MOVEMENT
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Movement")

    ----------------------------------------------------------------------------
    -- TOGGLES
    ----------------------------------------------------------------------------
    local main = CreateCard(tab, "MOVIMENTO", 1)
    SwitchRow(main, "fly", "Fly", Toggles.fly.desc)
    SwitchRow(main, "noclip", "Noclip", Toggles.noclip.desc)
    SwitchRow(main, "infjump", "Infinite Jump", Toggles.infjump.desc)
    SwitchRow(main, "god", "God Mode", Toggles.god.desc)

    ----------------------------------------------------------------------------
    -- VELOCIDADES
    ----------------------------------------------------------------------------
    local speeds = CreateCard(tab, "VELOCIDADES", 2)
    SubLabel(speeds, "Arraste, digite o número ou use RESET. Vale também via comandos.", -1)

    FlySlider = SliderRow(speeds, {
        label = "Fly Speed", min = 10, max = 500, def = State.FlySpeed, order = 1,
        apply = function(v) State.FlySpeed = v end,
    })

    WalkSlider = SliderRow(speeds, {
        label = "WalkSpeed", min = 0, max = 400, def = State.WalkSpeed, order = 2,
        apply = function(v)
            State.WalkSpeed = v
            local h = Hum()
            if h then h.WalkSpeed = v end
        end,
    })

    JumpSlider = SliderRow(speeds, {
        label = "JumpPower", min = 0, max = 400, def = State.JumpPower, order = 3,
        apply = function(v)
            State.JumpPower = v
            local h = Hum()
            if h then
                if h.UseJumpPower ~= nil then h.UseJumpPower = true end
                h.JumpPower = v
            end
        end,
    })

    ----------------------------------------------------------------------------
    -- CÂMERA / DRONE
    ----------------------------------------------------------------------------
    local drone = CreateCard(tab, "CÂMERA E DRONE", 3)
    SwitchRow(drone, "freecam", "Freecam", Toggles.freecam.desc)
    SwitchRow(drone, "drone", "Modo Drone", Toggles.drone.desc)

    DroneSpeedSlider = SliderRow(drone, {
        label = "Drone Speed", min = 10, max = 400, def = State.DroneSpeed, order = 3,
        apply = function(v) State.DroneSpeed = v end,
    })

    SliderRow(drone, {
        label = "Drone Sensibilidade", min = 1, max = 12, def = State.DroneSens, order = 4,
        apply = function(v) State.DroneSens = v end,
    })

    SliderRow(drone, {
        label = "Drone Suavidade", min = 1, max = 20, def = State.DroneSmooth, order = 5,
        apply = function(v) State.DroneSmooth = v end,
    })

    SubLabel(drone, "No drone: WASD move, E/Q sobe/desce, scroll muda a velocidade. "
        .. "O personagem fica ancorado no lugar e volta ao normal ao desligar.", 6)

    ----------------------------------------------------------------------------
    -- TELEPORTE RÁPIDO
    ----------------------------------------------------------------------------
    local tp = CreateCard(tab, "TELEPORTE", 4)
    local tpGrid = Grid(tp, 3, 34)

    local up = CreateButton(tpGrid, "SUBIR 50", "Accent", 34)
    up.LayoutOrder = 1
    up.MouseButton1Click:Connect(function()
        local r = Root()
        if r then TeleportTo(r.CFrame * CFrame.new(0, 50, 0)) end
    end)

    local fwd = CreateButton(tpGrid, "FRENTE 30", "Accent", 34)
    fwd.LayoutOrder = 2
    fwd.MouseButton1Click:Connect(function()
        local r = Root()
        if r then TeleportTo(r.CFrame * CFrame.new(0, 0, -30)) end
    end)

    local toCam = CreateButton(tpGrid, "PARA A CÂMERA", "Accent", 34)
    toCam.LayoutOrder = 3
    toCam.MouseButton1Click:Connect(function()
        TeleportTo(Camera.CFrame * CFrame.new(0, 0, -6))
        Log("Teleporte para a câmera", "action")
    end)

    ----------------------------------------------------------------------------
    -- WAYPOINTS
    ----------------------------------------------------------------------------
    local wp = CreateCard(tab, "WAYPOINTS", 5)
    SubLabel(wp, "Salva a posição atual do personagem. Os waypoints vão junto na "
        .. "config em disco (Ajustes › Configuração em disco).", -1)

    local wpInput = CreateInput(wp, "Nome do waypoint", 32)
    wpInput.LayoutOrder = 1

    local wpBtns = Grid(wp, 2, 32)
    wpBtns.LayoutOrder = 2

    local saveBtn = CreateButton(wpBtns, "SALVAR AQUI", "Success", 32)
    saveBtn.LayoutOrder = 1
    local clearBtn = CreateButton(wpBtns, "LIMPAR TODOS", "Danger", 32)
    clearBtn.LayoutOrder = 2

    local wpList = Instance.new("Frame")
    wpList.Size = UDim2.new(1, 0, 0, 0)
    wpList.AutomaticSize = Enum.AutomaticSize.Y
    wpList.BackgroundTransparency = 1
    wpList.LayoutOrder = 3
    wpList.Parent = wp
    local wpLayout = Instance.new("UIListLayout", wpList)
    wpLayout.Padding = UDim.new(0, 5)
    wpLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local emptyLbl = SubLabel(wp, "Nenhum waypoint salvo.", 4)

    RenderWaypoints = function()
        for _, c in ipairs(wpList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        emptyLbl.Visible = (#State.Waypoints == 0)

        for i, w in ipairs(State.Waypoints) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = wpList
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local nameBox = Instance.new("TextBox")
            nameBox.Size = UDim2.new(1, -224, 1, 0)
            nameBox.Position = UDim2.new(0, 10, 0, 0)
            nameBox.BackgroundTransparency = 1
            nameBox.Text = w.name
            nameBox.TextColor3 = THEME.Text
            nameBox.Font = Enum.Font.GothamMedium
            nameBox.TextSize = 12
            nameBox.TextXAlignment = Enum.TextXAlignment.Left
            nameBox.ClearTextOnFocus = false
            nameBox.Parent = row
            Paint(nameBox, "TextColor3", "Text")
            nameBox.FocusLost:Connect(function()
                local t = nameBox.Text
                if t == "" then
                    nameBox.Text = w.name
                    return
                end
                Log("Waypoint renomeado: " .. w.name .. " -> " .. t, "action")
                w.name = t
            end)

            local pos = Instance.new("TextLabel")
            pos.AnchorPoint = Vector2.new(1, 0.5)
            pos.Position = UDim2.new(1, -150, 0.5, 0)
            pos.Size = UDim2.new(0, 130, 1, 0)
            pos.BackgroundTransparency = 1
            pos.Text = string.format("%d, %d, %d", w.cframe.X, w.cframe.Y, w.cframe.Z)
            pos.TextColor3 = THEME.Dim
            pos.Font = Enum.Font.Code
            pos.TextSize = 11
            pos.TextXAlignment = Enum.TextXAlignment.Right
            pos.Parent = row
            Paint(pos, "TextColor3", "Dim")

            local go = CreateButton(row, "TP", "Accent", 24)
            go.Size = UDim2.new(0, 56, 0, 24)
            go.Position = UDim2.new(1, -138, 0.5, -12)
            go.MouseButton1Click:Connect(function()
                TeleportTo(w.cframe)
                Log("TP -> " .. w.name, "action")
            end)

            local del = CreateButton(row, "EXCLUIR", "Danger", 24)
            del.Size = UDim2.new(0, 68, 0, 24)
            del.Position = UDim2.new(1, -76, 0.5, -12)
            del.MouseButton1Click:Connect(function()
                for k, item in ipairs(State.Waypoints) do
                    if item == w then
                        table.remove(State.Waypoints, k)
                        break
                    end
                end
                Log("Waypoint removido: " .. w.name, "action")
                RenderWaypoints()
            end)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        local r = Root()
        if not r then
            Toast("Sem personagem", "warn")
            return
        end
        local name = wpInput.Text
        if name == "" then name = "Waypoint " .. (#State.Waypoints + 1) end
        table.insert(State.Waypoints, { name = name, cframe = r.CFrame })
        wpInput.Text = ""
        Log("Waypoint salvo: " .. name, "action")
        Toast("Waypoint salvo", "ok", 1.5)
        RenderWaypoints()
    end)

    clearBtn.MouseButton1Click:Connect(function()
        if #State.Waypoints == 0 then return end
        Confirm("Apagar todos os " .. #State.Waypoints .. " waypoints?", function()
            State.Waypoints = {}
            Log("Waypoints limpos", "action")
            RenderWaypoints()
        end)
    end)

    RenderWaypoints()
end
--------------------------------------------------------------------------------
-- ABA VISUALS
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Visuals")

    ----------------------------------------------------------------------------
    -- TOGGLES GERAIS
    ----------------------------------------------------------------------------
    local main = CreateCard(tab, "VISUAL", 1)
    SwitchRow(main, "esp", "ESP", Toggles.esp.desc)
    SwitchRow(main, "fullbright", "Fullbright", Toggles.fullbright.desc)
    SwitchRow(main, "invisible", "Invisível (local)", Toggles.invisible.desc)
    SwitchRow(main, "wall", "Wall Transparency", Toggles.wall.desc)
    SwitchRow(main, "chatspy", "Chat Spy", Toggles.chatspy.desc)

    SliderRow(main, {
        label = "Transparência das paredes", min = 10, max = 100,
        def = math.floor(State.WallAlpha * 100), suffix = "%", order = 20,
        apply = function(v)
            State.WallAlpha = v / 100
            for part, _ in pairs(WallCache) do
                if part and part.Parent then part.LocalTransparencyModifier = State.WallAlpha end
            end
        end,
    })

    ----------------------------------------------------------------------------
    -- O QUE O ESP MOSTRA
    ----------------------------------------------------------------------------
    local esp = CreateCard(tab, "ESP — O QUE MOSTRAR", 2)
    SubLabel(esp, "Vale na hora: as mudanças aparecem no próximo quadro, sem religar o ESP.", -1)

    local function Opt(key, label, desc, order)
        CheckRow(esp, label, desc,
            function() return EspOpts[key] end,
            function(v) EspOpts[key] = v end, order)
    end

    Opt("Highlight",  "Contorno",        "Highlight em volta do personagem", 1)
    Opt("Name",       "Nome",            nil, 2)
    Opt("UseDisplay", "Usar DisplayName", "Desligado mostra @username", 3)
    Opt("Distance",   "Distância",       nil, 4)
    Opt("Health",     "Vida em número",  nil, 5)
    Opt("HealthBar",  "Barra de vida",   nil, 6)
    Opt("Tracers",    "Tracers",         "Linha da sua tela até o jogador (custa mais FPS)", 7)

    ----------------------------------------------------------------------------
    -- FILTROS
    ----------------------------------------------------------------------------
    local filt = CreateCard(tab, "ESP — FILTROS", 3)
    CheckRow(filt, "Mostrar aliados", "Jogadores da sua equipe",
        function() return EspOpts.Allies end,
        function(v) EspOpts.Allies = v end, 1)
    CheckRow(filt, "Mostrar inimigos", "Jogadores de outra equipe (ou sem equipe)",
        function() return EspOpts.Enemies end,
        function(v) EspOpts.Enemies = v end, 2)
    CheckRow(filt, "Cores por equipe", "Usa a TeamColor no lugar da cor do tema",
        function() return EspOpts.TeamColors end,
        function(v) EspOpts.TeamColors = v end, 3)

    SliderRow(filt, {
        label = "Distância máxima", min = 100, max = 5000, def = EspOpts.MaxDist,
        suffix = "m", order = 4,
        apply = function(v) EspOpts.MaxDist = v end,
    })

    SliderRow(filt, {
        label = "Taxa de atualização", min = 15, max = 60, def = 15, suffix = "Hz", order = 5,
        apply = function(v) EspOpts.Rate = 1 / v end,
    })

    SubLabel(filt, "Fora do filtro o ESP só desliga o objeto — nada é recriado por quadro.", 6)

    ----------------------------------------------------------------------------
    -- CORES
    ----------------------------------------------------------------------------
    local cores = CreateCard(tab, "ESP — CORES", 4)
    local cGrid = Grid(cores, 4, 32)
    local COLORS = { "Accent", "Success", "Warning", "Danger" }
    local NAMES  = { Accent = "TEMA", Success = "VERDE", Warning = "AMARELO", Danger = "VERMELHO" }

    for i, key in ipairs(COLORS) do
        local b = CreateButton(cGrid, NAMES[key], key, 32)
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function()
            EspOpts.ColorKey = key
            Log("Cor do ESP (inimigos): " .. NAMES[key], "action")
        end)
    end

    SubLabel(cores, "Aliados usam verde por padrão. Com 'Cores por equipe' ligado, "
        .. "a TeamColor tem prioridade.", 10)
end
--------------------------------------------------------------------------------
-- ABA PLAYERS
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Players")

    local head = CreateCard(tab, "JOGADORES", 1)
    local search = CreateInput(head, "Buscar por username ou display name...", 32)
    search.LayoutOrder = 1

    local countLbl = SubLabel(head, "", 2)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.LayoutOrder = 3
    list.Parent = head
    local listLayout = Instance.new("UIListLayout", list)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    PlayerRows = {}          -- [userId] = { frame=, player=, ... }
    local filter = ""

    local function Elapsed(sec)
        if not sec then return "—" end
        local m = math.floor(sec / 60)
        if m < 1 then return math.floor(sec) .. "s" end
        if m < 60 then return m .. "min" end
        return math.floor(m / 60) .. "h" .. (m % 60) .. "min"
    end

    local function Passes(p)
        if filter == "" then return true end
        return (p.Name:lower():find(filter, 1, true) ~= nil)
            or (p.DisplayName:lower():find(filter, 1, true) ~= nil)
    end

    local function MakeRow(p)
        local row = Instance.new("Frame")
        row.Name = "Row_" .. p.UserId
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = THEME.Btn
        row.BorderSizePixel = 0
        row.Parent = list
        Paint(row, "BackgroundColor3", "Btn")
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", row)
        stroke.Transparency = 1
        Paint(stroke, "Color", "Accent")

        local av = Avatar(row, p.UserId, 40)
        av.Position = UDim2.new(0, 8, 0.5, -20)

        local dn = Instance.new("TextLabel")
        dn.Size = UDim2.new(1, -300, 0, 17)
        dn.Position = UDim2.new(0, 56, 0, 9)
        dn.BackgroundTransparency = 1
        dn.Text = p.DisplayName .. (p == LocalPlayer and "   (você)" or "")
        dn.TextColor3 = THEME.Text
        dn.Font = Enum.Font.GothamBold
        dn.TextSize = 13
        dn.TextXAlignment = Enum.TextXAlignment.Left
        dn.TextTruncate = Enum.TextTruncate.AtEnd
        dn.Parent = row
        Paint(dn, "TextColor3", "Text")

        local un = Instance.new("TextLabel")
        un.Size = UDim2.new(1, -300, 0, 14)
        un.Position = UDim2.new(0, 56, 0, 27)
        un.BackgroundTransparency = 1
        un.Text = "@" .. p.Name
        un.TextColor3 = THEME.Dim
        un.Font = Enum.Font.Code
        un.TextSize = 11
        un.TextXAlignment = Enum.TextXAlignment.Left
        un.Parent = row
        Paint(un, "TextColor3", "Dim")

        local meta = Instance.new("TextLabel")
        meta.AnchorPoint = Vector2.new(1, 0)
        meta.Size = UDim2.new(0, 240, 0, 14)
        meta.Position = UDim2.new(1, -150, 0, 41)
        meta.BackgroundTransparency = 1
        meta.Text = ""
        meta.TextColor3 = THEME.Dim
        meta.Font = Enum.Font.Code
        meta.TextSize = 10
        meta.TextXAlignment = Enum.TextXAlignment.Right
        meta.Parent = row
        Paint(meta, "TextColor3", "Dim")

        local hp = Instance.new("TextLabel")
        hp.AnchorPoint = Vector2.new(1, 0)
        hp.Size = UDim2.new(0, 240, 0, 16)
        hp.Position = UDim2.new(1, -150, 0, 10)
        hp.BackgroundTransparency = 1
        hp.Text = ""
        hp.TextColor3 = THEME.Success
        hp.Font = Enum.Font.Code
        hp.TextSize = 11
        hp.TextXAlignment = Enum.TextXAlignment.Right
        hp.Parent = row
        Paint(hp, "TextColor3", "Success")

        local sel = CreateButton(row, "SELECIONAR", "Accent", 24)
        sel.Size = UDim2.new(0, 88, 0, 24)
        sel.Position = UDim2.new(1, -140, 0, 8)
        sel.MouseButton1Click:Connect(function() SelectPlayer(p) end)

        local tp = CreateButton(row, "TP", "Success", 24)
        tp.Size = UDim2.new(0, 40, 0, 24)
        tp.Position = UDim2.new(1, -140, 0, 34)
        tp.MouseButton1Click:Connect(function() Goto(p) end)

        local spec = CreateButton(row, "SPECTATE", "Accent2", 24)
        spec.Size = UDim2.new(0, 44, 0, 24)
        spec.Position = UDim2.new(1, -96, 0, 34)
        spec.Text = "OLHAR"
        spec.MouseButton1Click:Connect(function()
            if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
        end)

        if p == LocalPlayer then
            tp.Visible = false
            spec.Visible = false
        end

        local entry = { frame = row, player = p, meta = meta, hp = hp,
            stroke = stroke, select = sel }
        PlayerRows[p.UserId] = entry
        return entry
    end

    RebuildPlayerRows = function()
        -- remove linhas de quem saiu
        for id, e in pairs(PlayerRows) do
            if not e.player or not e.player.Parent then
                if e.frame then e.frame:Destroy() end
                PlayerRows[id] = nil
            end
        end
        -- cria linhas de quem chegou
        local shown, total = 0, 0
        for _, p in ipairs(Players:GetPlayers()) do
            total = total + 1
            local e = PlayerRows[p.UserId]
            if not e then e = MakeRow(p) end
            local pass = Passes(p)
            e.frame.Visible = pass
            if pass then
                shown = shown + 1
                e.frame.LayoutOrder = (p == LocalPlayer) and 0 or shown
            end
        end
        countLbl.Text = shown .. " de " .. total .. " jogador(es)"
            .. (filter ~= "" and "  ·  filtro: \"" .. filter .. "\"" or "")
    end

    UpdatePlayerRows = function()
        local myRoot = Root()
        for id, e in pairs(PlayerRows) do
            local p = e.player
            if not p or not p.Parent then
                if e.frame then e.frame:Destroy() end
                PlayerRows[id] = nil
            elseif e.frame.Visible then
                local char = p.Character
                local h = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if h then
                    local pct = h.MaxHealth > 0 and (h.Health / h.MaxHealth) or 0
                    e.hp.Text = math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth) .. " HP"
                    e.hp.TextColor3 = pct > 0.5 and THEME.Success
                        or (pct > 0.25 and THEME.Warning or THEME.Danger)
                else
                    e.hp.Text = "sem personagem"
                    e.hp.TextColor3 = THEME.Dim
                end

                local dist = "—"
                if myRoot and root then
                    dist = math.floor((myRoot.Position - root.Position).Magnitude) .. "m"
                end

                -- ping: o client só consegue ler o SEU ping. Dos outros não existe
                -- API client-side, então mostra "—" em vez de inventar número.
                local ping = "—"
                if p == LocalPlayer then
                    local ok, v = pcall(function()
                        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    if ok and v then ping = math.floor(v) .. "ms" end
                end

                local team = p.Team and p.Team.Name or "sem equipe"
                e.meta.Text = "ping " .. ping .. "  ·  " .. dist .. "  ·  " .. team
                    .. "  ·  " .. Elapsed(State.JoinTimes[p.UserId]
                        and (os.clock() - State.JoinTimes[p.UserId]) or nil)

                local isSel = (State.SelectedPlayer == p)
                e.stroke.Transparency = isSel and 0.15 or 1
                e.select.Text = isSel and "SELECIONADO" or "SELECIONAR"
            end
        end
    end

    SelectPlayer = function(p)
        if not p or not p.Parent then
            Toast("Jogador não está mais no servidor", "warn")
            return
        end
        State.SelectedPlayer = p
        Log("Selecionado: " .. p.Name .. " (" .. p.DisplayName .. ")", "action")
        if UpdateSelectedInfo then UpdateSelectedInfo() end
        UpdatePlayerRows()
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        filter = search.Text:lower()
        RebuildPlayerRows()
    end)

    OnTabOpen("Players", function()
        RebuildPlayerRows()
        UpdatePlayerRows()
    end)

    RebuildPlayerRows()
end
--------------------------------------------------------------------------------
-- ABA MODERATION
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Moderation")

    ----------------------------------------------------------------------------
    -- PAINEL DO SELECIONADO
    ----------------------------------------------------------------------------
    local sel = CreateCard(tab, "JOGADOR SELECIONADO", 1)

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 64)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = 1
    holder.Parent = sel

    local av = Avatar(holder, 1, 56)
    av.Position = UDim2.new(0, 0, 0, 4)

    local dn = Instance.new("TextLabel")
    dn.Size = UDim2.new(1, -76, 0, 20)
    dn.Position = UDim2.new(0, 68, 0, 4)
    dn.BackgroundTransparency = 1
    dn.Text = "Nenhum jogador selecionado"
    dn.TextColor3 = THEME.Text
    dn.Font = Enum.Font.GothamBold
    dn.TextSize = 15
    dn.TextXAlignment = Enum.TextXAlignment.Left
    dn.Parent = holder
    Paint(dn, "TextColor3", "Text")

    local un = Instance.new("TextLabel")
    un.Size = UDim2.new(1, -76, 0, 15)
    un.Position = UDim2.new(0, 68, 0, 25)
    un.BackgroundTransparency = 1
    un.Text = "selecione alguém em Jogadores › Lista"
    un.TextColor3 = THEME.Dim
    un.Font = Enum.Font.Code
    un.TextSize = 12
    un.TextXAlignment = Enum.TextXAlignment.Left
    un.Parent = holder
    Paint(un, "TextColor3", "Dim")

    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -76, 0, 15)
    stats.Position = UDim2.new(0, 68, 0, 43)
    stats.BackgroundTransparency = 1
    stats.Text = ""
    stats.TextColor3 = THEME.Accent2
    stats.Font = Enum.Font.Code
    stats.TextSize = 11
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = holder
    Paint(stats, "TextColor3", "Accent2")

    local idRow = Grid(sel, 2, 30)
    idRow.LayoutOrder = 2
    local copyId = CreateButton(idRow, "COPIAR USERID", "Accent", 30)
    copyId.LayoutOrder = 1
    local copyName = CreateButton(idRow, "COPIAR @USERNAME", "Accent", 30)
    copyName.LayoutOrder = 2

    copyId.MouseButton1Click:Connect(function()
        local p = RequireSelected()
        if p then Copy(tostring(p.UserId), "UserId") end
    end)
    copyName.MouseButton1Click:Connect(function()
        local p = RequireSelected()
        if p then Copy(p.Name, "Username") end
    end)

    UpdateSelectedInfo = function()
        local p = State.SelectedPlayer
        if not p or not p.Parent then
            dn.Text = "Nenhum jogador selecionado"
            un.Text = "selecione alguém em Jogadores › Lista"
            stats.Text = ""
            av.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48"
            return
        end
        av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
        dn.Text = p.DisplayName
        un.Text = "@" .. p.Name .. "   ·   UserId " .. p.UserId

        local char = p.Character
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local myRoot = Root()
        local hp = h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth) .. " HP")
            or "sem personagem"
        local dist = (myRoot and root)
            and (math.floor((myRoot.Position - root.Position).Magnitude) .. "m") or "—"
        stats.Text = hp .. "   ·   " .. dist .. "   ·   "
            .. (p.Team and p.Team.Name or "sem equipe") .. "   ·   ping —"
    end

    ----------------------------------------------------------------------------
    -- MOVIMENTAÇÃO
    ----------------------------------------------------------------------------
    local mov = CreateCard(tab, "MOVIMENTAÇÃO", 2)
    local movGrid = Grid(mov, 3, 32)

    ActionBtn(movGrid, "TELEPORTAR ATÉ", "Success", nil, function()
        local p = RequireSelected()
        if p then Goto(p) end
    end)

    ActionBtn(movGrid, "TRAZER (BRING)", "Warning", nil, function()
        local p = RequireSelected()
        if not p then return end
        if not Remotes.Pull then
            Log("Bring sem AdminPull: só a sua tela vai ver o alvo mudar de lugar "
                .. "(o servidor não replica). Crie o Remote pra valer de verdade.", "warn")
        end
        Bring(p)
    end)

    ActionBtn(movGrid, "SPECTATE", "Accent", nil, function()
        local p = RequireSelected()
        if not p then return end
        if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
    end)

    ----------------------------------------------------------------------------
    -- MODERAÇÃO (depende do servidor)
    ----------------------------------------------------------------------------
    local mod = CreateCard(tab, "MODERAÇÃO", 3)
    SubLabel(mod, "Estas ações mudam o jogo pra todo mundo, então SÓ funcionam com "
        .. "RemoteEvent + validação no servidor. Sem o Remote o botão fica "
        .. "indisponível — o painel não finge que executou.", -1)

    local modGrid = Grid(mod, 3, 32)

    ActionBtn(modGrid, "KICK", "Danger", "Kick", function()
        local p = RequireSelected()
        if p then KickPlayer(p, "Removido por um admin") end
    end, "Enviar KICK para o jogador selecionado? A decisão final é do servidor.")

    ActionBtn(modGrid, "FREEZE", "Warning", "Freeze", function()
        local p = RequireSelected()
        if p then FreezePlayer(p, true) end
    end, "Congelar o jogador selecionado?")

    ActionBtn(modGrid, "UNFREEZE", "Success", "Freeze", function()
        local p = RequireSelected()
        if p then FreezePlayer(p, false) end
    end)

    ----------------------------------------------------------------------------
    -- COMUNICAÇÃO
    ----------------------------------------------------------------------------
    local com = CreateCard(tab, "COMUNICAÇÃO", 4)

    local wIn = CreateInput(com, "Mensagem privada para o selecionado...", 32)
    wIn.LayoutOrder = 1
    ActionBtn(com, "ENVIAR PRIVADO", "Accent", "Whisper", function()
        local p = RequireSelected()
        if not p then return end
        if wIn.Text == "" then
            Toast("Escreva a mensagem primeiro", "warn", 1.6)
            return
        end
        Remotes.Whisper:FireServer(p.UserId, wIn.Text)
        Log("Você -> " .. p.Name .. ": " .. wIn.Text, "ok")
        wIn.Text = ""
    end).LayoutOrder = 2

    Divider(com).LayoutOrder = 3

    local aIn = CreateInput(com, "Anúncio para o servidor...", 32)
    aIn.LayoutOrder = 4
    local aBtn = ActionBtn(com, "ANUNCIAR", "Warning", nil, function()
        if aIn.Text == "" then
            Toast("Escreva o anúncio primeiro", "warn", 1.6)
            return
        end
        Announce(aIn.Text)
        aIn.Text = ""
    end, "Enviar este anúncio?")
    aBtn.LayoutOrder = 5

    if not Remotes.Announce then
        SubLabel(com, "Sem AdminAnnounce o anúncio aparece SÓ no seu chat (local). "
            .. "Pra chegar em todo mundo precisa do Remote no servidor.", 6)
    end

    ----------------------------------------------------------------------------
    -- TROLL (v8.0) — tudo aqui depende de Remote no servidor, exceto Fake Message
    ----------------------------------------------------------------------------
    local troll = CreateCard(tab, "TROLL", 5)
    SubLabel(troll, "Fling/Spin/Trip/Launch/Sit/Scale/Balloon só funcionam com "
        .. "RemoteEvent + validação no servidor. Sem o Remote o botão fica "
        .. "indisponível — nada aqui é fingido.", -1)

    local trollGrid = Grid(troll, 3, 32)

    ActionBtn(trollGrid, "FLING", "Danger", "Fling", function()
        local p = RequireSelected()
        if p then FlingPlayer(p) end
    end, "Aplicar Fling no jogador selecionado?")

    local spinBtn
    spinBtn = ActionBtn(trollGrid, "SPIN: OFF", "Warning", "Spin", function()
        local p = RequireSelected()
        if not p then return end
        local on = not TrollState.Spin[p.UserId]
        SpinPlayer(p, on)
        spinBtn.Text = on and "SPIN: ON" or "SPIN: OFF"
    end)

    ActionBtn(trollGrid, "TRIP", "Warning", "Trip", function()
        local p = RequireSelected()
        if p then TripPlayer(p) end
    end)

    ActionBtn(trollGrid, "LAUNCH", "Danger", "Launch", function()
        local p = RequireSelected()
        if p then LaunchPlayer(p) end
    end, "Lançar o jogador selecionado bem alto?")

    ActionBtn(trollGrid, "FORCE SIT", "Warning", "Sit", function()
        local p = RequireSelected()
        if p then SitPlayer(p) end
    end)

    local balloonBtn
    balloonBtn = ActionBtn(trollGrid, "BALLOON: OFF", "Accent", "Balloon", function()
        local p = RequireSelected()
        if not p then return end
        local on = not TrollState.Balloon[p.UserId]
        BalloonPlayer(p, on)
        balloonBtn.Text = on and "BALLOON: ON" or "BALLOON: OFF"
    end)

    ActionBtn(trollGrid, "TINY", "Accent", "Scale", function()
        local p = RequireSelected()
        if p then ScalePlayer(p, "tiny") end
    end, "Encolher o jogador selecionado?")

    ActionBtn(trollGrid, "NORMAL", "Success", "Scale", function()
        local p = RequireSelected()
        if p then ScalePlayer(p, "normal") end
    end)

    ActionBtn(trollGrid, "GIANT", "Accent", "Scale", function()
        local p = RequireSelected()
        if p then ScalePlayer(p, "giant") end
    end, "Deixar o jogador selecionado gigante?")

    Divider(troll).LayoutOrder = 10

    local fakeGrid = Grid(troll, 2, 32)
    fakeGrid.LayoutOrder = 11

    ActionBtn(fakeGrid, "FAKE KICK MSG", "Warning", nil, function()
        local p = RequireSelected()
        if p then FakeMessage(p, "kick") end
    end)

    ActionBtn(fakeGrid, "FAKE BAN MSG", "Danger", nil, function()
        local p = RequireSelected()
        if p then FakeMessage(p, "ban") end
    end)

    SubLabel(troll, "Fake Message só aparece na SUA tela — não afeta o alvo nem o "
        .. "servidor, é só uma piscada de sistema local.", 12)

    OnTabOpen("Moderation", UpdateSelectedInfo)
    UpdateSelectedInfo()
end
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
    -- REMOTES
    ----------------------------------------------------------------------------
    local rc = CreateCard(tab, "REMOTES (FUNÇÕES SERVER-SIDE)", 2)
    SubLabel(rc, "O painel é client-side. Tudo que muda o jogo para os outros "
        .. "precisa de um RemoteEvent em ReplicatedStorage COM validação de admin "
        .. "no servidor. Sem o Remote a ação fica indisponível.", -1)

    -- v8.0: lê o catálogo único (V8.RemoteInfo) — os 13 Remotes, por grupo
    do
        local have, total = V8.RemoteStatus()
        local resumo = SubLabel(rc, have .. " de " .. total .. " Remotes encontrados"
            .. (have < total and "  ·  o script pronto está em server/ (veja o README)" or ""), 0)
        resumo.TextColor3 = (have == total) and THEME.Success or THEME.Warning
    end

    local rGrid = Grid(rc, 1, 22)
    rGrid.LayoutOrder = 1
    local lastGroup
    for i, item in ipairs(V8.RemoteInfo) do
        local key, remoteName, what, group = item[1], item[2], item[3], item[4]
        if group ~= lastGroup then
            lastGroup = group
            local g = Instance.new("TextLabel")
            g.Size = UDim2.new(1, 0, 0, 22)
            g.BackgroundTransparency = 1
            g.Text = "  " .. group:upper()
            g.TextColor3 = THEME.Accent
            g.Font = Enum.Font.GothamBold
            g.TextSize = 10
            g.TextXAlignment = Enum.TextXAlignment.Left
            g.TextYAlignment = Enum.TextYAlignment.Bottom
            g.LayoutOrder = i * 2 - 1
            g.Parent = rGrid
            Paint(g, "TextColor3", "Accent")
        end
        local found = Remotes[key] ~= nil
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.Text = (found and "  [OK]      " or "  [AUSENTE] ") .. remoteName
            .. "   —   " .. what
        l.TextColor3 = found and THEME.Success or THEME.Dim
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = i * 2
        l.Parent = rGrid
        Paint(l, "TextColor3", found and "Success" or "Dim")
    end

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
--------------------------------------------------------------------------------
-- ABA EMOTES (animações por ID + favoritos)
--
-- Limitação do Roblox, não do painel: o Animator só carrega AnimationId cujo
-- asset pertença ao dono do jogo (você ou o grupo) ou à própria Roblox. ID de
-- animação de terceiro simplesmente não carrega — por isso o erro aparece no
-- log em vez de fingir que tocou.
--
-- Só mexe no SEU personagem. Forçar animação em outro jogador é server-side e
-- precisaria de Remote com validação, igual kick/freeze.
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Emotes")

    local currentBox      -- label de status "tocando agora"
    local favList, favEmpty, RenderFavs

    ----------------------------------------------------------------------------
    -- MOTOR
    ----------------------------------------------------------------------------

    -- Aceita "123456", "rbxassetid://123456" e a URL do catálogo.
    local function ParseId(raw)
        if not raw then return nil end
        local s = tostring(raw):gsub("%s+", "")
        if s == "" then return nil end
        local n = s:match("(%d%d%d%d+)")
        return n and tonumber(n) or nil
    end

    local function Animator()
        local h = Hum()
        if not h then return nil end
        local a = h:FindFirstChildOfClass("Animator")
        if not a then
            local ok = pcall(function()
                a = Instance.new("Animator")
                a.Parent = h
            end)
            if not ok then return nil end
        end
        return a
    end

    local function SetStatus(text, colorKey)
        if not currentBox then return end
        currentBox.Text = text
        currentBox.TextColor3 = THEME[colorKey or "Dim"]
    end

    Emote.Stop = function(quiet)
        if Emote.track then
            pcall(function() Emote.track:Stop(0.15) end)
            pcall(function() Emote.track:Destroy() end)
        end
        Emote.track = nil
        Emote.id = nil
        -- libera a animação do voo, se o fly estiver ligado
        pcall(function() if FlyPose then FlyPose.muted = false end end)
        SetStatus("Nada tocando.", "Dim")
        if not quiet then Log("Emote parado", "action") end
    end

    Emote.Play = function(raw, label)
        local id = ParseId(raw)
        if not id then
            Log("ID de animação inválido: " .. tostring(raw), "warn")
            Toast("ID inválido", "warn", 2)
            return false
        end

        local h = Hum()
        if not h then
            Toast("Sem personagem", "warn", 2)
            return false
        end

        local anim = Animator()
        if not anim then
            Log("Não consegui acessar o Animator do personagem", "error")
            return false
        end

        Emote.Stop(true)

        -- o emote vence a pose/animação do voo (as duas escrevem nas juntas)
        pcall(function() if FlyPose and FlyPose.active then FlyPose.Stop() end end)
        pcall(function()
            if FlyPose then FlyPose.muted = true end
            if flyTrack and flyTrack.IsPlaying then flyTrack:Stop(0.15) end
            if FlyPose and FlyPose.idleTrack and FlyPose.idleTrack.IsPlaying then
                FlyPose.idleTrack:Stop(0.15)
            end
        end)

        local obj = Instance.new("Animation")
        obj.AnimationId = "rbxassetid://" .. id
        local ok, track = pcall(function() return anim:LoadAnimation(obj) end)
        pcall(function() obj:Destroy() end)

        if not ok or not track then
            Log("Animação " .. id .. " não carregou. O asset precisa pertencer "
                .. "ao dono do jogo (ou à Roblox).", "error")
            Toast("Animação não carregou", "error", 3)
            return false
        end

        local ok2, err = pcall(function()
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            track:Play(0.15)
            track:AdjustSpeed(Emote.Speed or 1)
        end)
        if not ok2 then
            Log("Falha ao tocar a animação: " .. tostring(err), "error")
            pcall(function() track:Destroy() end)
            return false
        end

        Emote.track = track
        Emote.id = id
        SetStatus((label or ("ID " .. id)) .. "  •  em loop", "Success")
        Log("Emote tocando: " .. (label or tostring(id)), "action")
        return true
    end

    ----------------------------------------------------------------------------
    -- TOCAR POR ID
    ----------------------------------------------------------------------------
    local play = CreateCard(tab, "TOCAR ANIMAÇÃO", 1)

    SubLabel(play, "Cole o ID da animação (aceita rbxassetid:// ou a URL do "
        .. "catálogo). Toca em loop até você apertar PARAR.", 1)

    local idBox = CreateInput(play, "rbxassetid://0000000000", 34)
    idBox.LayoutOrder = 2

    local rowA = Instance.new("Frame")
    rowA.Size = UDim2.new(1, 0, 0, 34)
    rowA.BackgroundTransparency = 1
    rowA.LayoutOrder = 3
    rowA.Parent = play

    local playBtn = CreateButton(rowA, "TOCAR", "Accent", 34)
    playBtn.Size = UDim2.new(0.5, -4, 0, 34)

    local stopBtn = CreateButton(rowA, "PARAR", "Danger", 34)
    stopBtn.Size = UDim2.new(0.5, -4, 0, 34)
    stopBtn.Position = UDim2.new(0.5, 4, 0, 0)

    currentBox = SubLabel(play, "Nada tocando.", 4)

    SliderRow(play, {
        label = "Velocidade", min = 10, max = 300, def = 100, suffix = "%", order = 5,
        apply = function(v)
            Emote.Speed = v / 100
            if Emote.track then
                pcall(function() Emote.track:AdjustSpeed(Emote.Speed) end)
            end
        end,
    })

    playBtn.MouseButton1Click:Connect(function()
        Emote.Play(idBox.Text)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        Emote.Stop()
    end)
    idBox.FocusLost:Connect(function(enter)
        if enter then Emote.Play(idBox.Text) end
    end)

    ----------------------------------------------------------------------------
    -- FAVORITOS
    ----------------------------------------------------------------------------
    local fav = CreateCard(tab, "FAVORITOS", 2)

    SubLabel(fav, "Salve os IDs que você mais usa. O nome também funciona no "
        .. "comando: emote <nome>.", 1)

    local nameBox = CreateInput(fav, "nome do emote (ex: dance)", 34)
    nameBox.LayoutOrder = 2

    local addBtn = CreateButton(fav, "SALVAR O ID ACIMA NOS FAVORITOS", "Accent2", 34)
    addBtn.LayoutOrder = 3

    favList = Instance.new("Frame")
    favList.Size = UDim2.new(1, 0, 0, 0)
    favList.AutomaticSize = Enum.AutomaticSize.Y
    favList.BackgroundTransparency = 1
    favList.LayoutOrder = 4
    favList.Parent = fav
    local favLayout = Instance.new("UIListLayout", favList)
    favLayout.Padding = UDim.new(0, 5)
    favLayout.SortOrder = Enum.SortOrder.LayoutOrder

    favEmpty = SubLabel(fav, "Nenhum favorito salvo.", 5)

    RenderFavs = function()
        for _, c in ipairs(favList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        favEmpty.Visible = (#State.Emotes == 0)

        for i, e in ipairs(State.Emotes) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = favList
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local nb = Instance.new("TextBox")
            nb.Size = UDim2.new(1, -244, 1, 0)
            nb.Position = UDim2.new(0, 10, 0, 0)
            nb.BackgroundTransparency = 1
            nb.Text = e.name
            nb.TextColor3 = THEME.Text
            nb.Font = Enum.Font.GothamMedium
            nb.TextSize = 12
            nb.TextXAlignment = Enum.TextXAlignment.Left
            nb.ClearTextOnFocus = false
            nb.Parent = row
            Paint(nb, "TextColor3", "Text")
            nb.FocusLost:Connect(function()
                local t = nb.Text
                if t == "" then nb.Text = e.name return end
                Log("Emote renomeado: " .. e.name .. " -> " .. t, "action")
                e.name = t
            end)

            local idLbl = Instance.new("TextLabel")
            idLbl.AnchorPoint = Vector2.new(1, 0.5)
            idLbl.Position = UDim2.new(1, -150, 0.5, 0)
            idLbl.Size = UDim2.new(0, 150, 1, 0)
            idLbl.BackgroundTransparency = 1
            idLbl.Text = tostring(e.id)
            idLbl.TextColor3 = THEME.Dim
            idLbl.Font = Enum.Font.Code
            idLbl.TextSize = 11
            idLbl.TextXAlignment = Enum.TextXAlignment.Right
            idLbl.Parent = row
            Paint(idLbl, "TextColor3", "Dim")

            local go = CreateButton(row, "TOCAR", "Accent", 24)
            go.Size = UDim2.new(0, 62, 0, 24)
            go.Position = UDim2.new(1, -138, 0.5, -12)
            go.MouseButton1Click:Connect(function()
                Emote.Play(e.id, e.name)
            end)

            local del = CreateButton(row, "EXCLUIR", "Danger", 24)
            del.Size = UDim2.new(0, 68, 0, 24)
            del.Position = UDim2.new(1, -66, 0.5, -12)
            del.MouseButton1Click:Connect(function()
                for k, item in ipairs(State.Emotes) do
                    if item == e then
                        table.remove(State.Emotes, k)
                        break
                    end
                end
                Log("Emote removido: " .. e.name, "action")
                RenderFavs()
            end)
        end
    end

    addBtn.MouseButton1Click:Connect(function()
        local id = ParseId(idBox.Text)
        if not id then
            Toast("Cole um ID válido no campo acima", "warn", 2)
            return
        end
        local nm = nameBox.Text
        if nm == "" then nm = "Emote " .. (#State.Emotes + 1) end
        table.insert(State.Emotes, { name = nm, id = id })
        nameBox.Text = ""
        Log("Emote salvo: " .. nm .. " (" .. id .. ")", "ok")
        Toast("Emote salvo", "ok", 1.5)
        RenderFavs()
    end)

    local clearBtn = CreateButton(fav, "LIMPAR TODOS", "Line", 30)
    clearBtn.LayoutOrder = 6
    clearBtn.MouseButton1Click:Connect(function()
        Confirm("Apagar todos os " .. #State.Emotes .. " favoritos?", function()
            for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
            Log("Favoritos de emote limpos", "action")
            RenderFavs()
        end)
    end)

    RenderFavs()
    V8.RenderEmotes = RenderFavs  -- v8.0: 50_v8/03_persist.lua re-renderiza favoritos importados

    ----------------------------------------------------------------------------
    -- AVISO
    ----------------------------------------------------------------------------
    local info = CreateCard(tab, "COMO FUNCIONA", 3)
    SubLabel(info, "1. O Roblox só carrega animação cujo asset pertença ao dono "
        .. "do jogo (você/seu grupo) ou à própria Roblox. ID de terceiro falha "
        .. "e o erro aparece no console.", 1)
    SubLabel(info, "2. A animação roda no SEU personagem e replica normalmente "
        .. "para os outros jogadores — é você quem tem network ownership dele.", 2)
    SubLabel(info, "3. Forçar emote em outro jogador é server-side. Sem Remote "
        .. "com validação, o painel não faz e não finge que fez.", 3)
    SubLabel(info, "4. O emote continua durante o Fly: ao tocar, a pose de "
        .. "superman é desligada para não brigar pelas mesmas juntas.", 4)
    SubLabel(info, "5. Respawn derruba a animação (o personagem é outro). "
        .. "É só apertar TOCAR de novo.", 5)
end
--------------------------------------------------------------------------------
-- ABA SETTINGS
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Settings")

    ----------------------------------------------------------------------------
    -- KEYBINDS
    ----------------------------------------------------------------------------
    local keyCard = CreateCard(tab, "KEYBINDS", 1)
    SubLabel(keyCard, "Clique no botão e aperte a tecla. Backspace remove. "
        .. "Se a tecla já estiver em uso, o painel avisa qual função perdeu o atalho.", -1)

    Keybinds.fly     = Enum.KeyCode.F
    Keybinds.noclip  = Enum.KeyCode.N
    Keybinds.esp     = Enum.KeyCode.E
    Keybinds.freecam = Enum.KeyCode.C
    Keybinds.drone   = Enum.KeyCode.G

    for _, id in ipairs(ToggleOrder) do
        KeybindRow(keyCard, id, Toggles[id].label)
    end

    local kBtns = Grid(keyCard, 2, 30)
    kBtns.LayoutOrder = 80

    local clearKeys = CreateButton(kBtns, "REMOVER TODOS", "Danger", 30)
    clearKeys.LayoutOrder = 1
    clearKeys.MouseButton1Click:Connect(function()
        Confirm("Remover todos os atalhos de teclado?", function()
            for id in pairs(Keybinds) do
                Keybinds[id] = nil
                if KeybindLabels[id] then KeybindLabels[id].Text = "—" end
            end
            Log("Todos os keybinds removidos", "action")
        end)
    end)

    local resetKeys = CreateButton(kBtns, "VOLTAR AO PADRÃO", "Success", 30)
    resetKeys.LayoutOrder = 2
    local function ResetKeys()
        for id in pairs(Keybinds) do Keybinds[id] = nil end
        Keybinds.fly     = Enum.KeyCode.F
        Keybinds.noclip  = Enum.KeyCode.N
        Keybinds.esp     = Enum.KeyCode.E
        Keybinds.freecam = Enum.KeyCode.C
        Keybinds.drone   = Enum.KeyCode.G
        for id, lbl in pairs(KeybindLabels) do lbl.Text = KeyName(Keybinds[id]) end
        Log("Keybinds restaurados (F/N/E/C/G)", "ok")
    end
    resetKeys.MouseButton1Click:Connect(ResetKeys)

    ----------------------------------------------------------------------------
    -- APARÊNCIA
    ----------------------------------------------------------------------------
    local look = CreateCard(tab, "APARÊNCIA", 2)

    ApplyTheme = function(paletteName)
        local p = PALETTES[paletteName]
        if not p then return end
        for k, v in pairs(p) do THEME[k] = v end
        for i = #Painted, 1, -1 do
            local entry = Painted[i]
            if entry.inst.Parent or entry.inst == Gui then
                local ok = pcall(function() entry.inst[entry.prop] = THEME[entry.key] end)
                if not ok then table.remove(Painted, i) end
            else
                table.remove(Painted, i)
            end
        end
        if RefreshStatus then RefreshStatus() end
        if RefreshQuick then RefreshQuick() end
        -- v8.0: as linhas do log saíram do registry; redesenha com as cores novas
        if RenderLog then pcall(RenderLog, nil) end
        Log("Tema: " .. paletteName, "ok")
    end

    local themeGrid = Grid(look, 4, 32)
    themeGrid.LayoutOrder = 1
    for i, n in ipairs({ "Roxo", "Ciano", "Verde", "Vermelho", "Azul" }) do
        local b = CreateButton(themeGrid, "   " .. n:upper(), "Accent", 32)
        b.LayoutOrder = i
        local sw = Instance.new("Frame")
        sw.Size = UDim2.new(0, 8, 0, 8)
        sw.Position = UDim2.new(0, 8, 0.5, -4)
        sw.BackgroundColor3 = PALETTES[n].Accent
        sw.BorderSizePixel = 0
        sw.Parent = b
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        b.MouseButton1Click:Connect(function() ApplyTheme(n) end)
    end

    local scaleSet = SliderRow(look, {
        label = "Escala da interface", min = 70, max = 130, def = 100, suffix = "%", order = 2,
        apply = function(v)
            CONFIG.UiScale = v / 100
            WindowScale.Scale = CONFIG.UiScale
        end,
    })

    local alphaSet = SliderRow(look, {
        label = "Transparência da janela", min = 0, max = 60, def = 0, suffix = "%", order = 3,
        apply = function(v)
            SET.Transparency = v / 100
            Window.BackgroundTransparency = SET.Transparency
            Sidebar.BackgroundTransparency = SET.Transparency
            ConsoleFrame.BackgroundTransparency = SET.Transparency
        end,
    })

    local compactRender
    local function ApplyCompact(on)
        SET.Compact = on
        -- v8: com o shell novo quem manda na geometria e o V8.Shell.Layout
        if V8.Shell and V8.Shell.Layout then
            if on then V8.Shell.ConsoleOpen = false end
            pcall(V8.Shell.Layout)
            return
        end
        ConsoleFrame.Visible = (not on) and (not State.Minimized)
        Content.Size = on and UDim2.new(1, -184, 1, -84) or UDim2.new(1, -184, 1, -214)
    end
    -- v8.0: a aba Scripts esconde esta linha (o console saiu da janela)
    compactRender, V8.CompactRow = CheckRow(look, "Modo compacto",
        "Esconde o console e dá mais espaço para as abas",
        function() return SET.Compact end,
        function(v) ApplyCompact(v) end, 4)

    CheckRow(look, "Animações", "Desligue se o jogo estiver pesado",
        function() return SET.Animations end,
        function(v) SET.Animations = v end, 5)

    ----------------------------------------------------------------------------
    -- COMPORTAMENTO
    ----------------------------------------------------------------------------
    local beh = CreateCard(tab, "COMPORTAMENTO", 3)

    CheckRow(beh, "Confirmar ações destrutivas", "Pede confirmação em kick, freeze, limpar...",
        function() return SET.Confirm end,
        function(v) SET.Confirm = v end, 1)

    CheckRow(beh, "Toasts", "Avisos flutuantes no canto da tela",
        function() return SET.Toasts end,
        function(v) SET.Toasts = v end, 2)

    CheckRow(beh, "Registrar no console", "Desligado, só os erros continuam aparecendo no log",
        function() return SET.ShowLogs end,
        function(v) SET.ShowLogs = v end, 3)

    CheckRow(beh, "ESP automático no respawn", "Reconstrói o ESP quando alguém renasce",
        function() return SET.EspAuto end,
        function(v) SET.EspAuto = v end, 4)

    local maxLogSet = SliderRow(beh, {
        label = "Linhas guardadas no log", min = 20, max = 300, def = SET.MaxLog, order = 5,
        apply = function(v)
            SET.MaxLog = v
            CONFIG.MaxLog = v
        end,
    })

    ----------------------------------------------------------------------------
    -- PRESETS
    ----------------------------------------------------------------------------
    local pre = CreateCard(tab, "PRESETS", 4)
    SubLabel(pre, "Presets mexem só nas funções e nos valores — seus keybinds ficam intactos.", -1)

    local PRESETS = {
        Default  = { fly = false, noclip = false, esp = false, fullbright = false,
                     infjump = false, god = false, invisible = false, wall = false,
                     chatspy = false, antiafk = true, freecam = false, drone = false },
        Admin    = { esp = true, fullbright = true, antiafk = true, chatspy = true,
                     noclip = false, fly = false, drone = false, freecam = false },
        Visual   = { esp = true, fullbright = true, wall = true, chatspy = false,
                     fly = false, noclip = false, drone = false, freecam = false },
        Movement = { fly = true, noclip = true, infjump = true, esp = false,
                     fullbright = false, drone = false, freecam = false },
        Minimal  = { antiafk = true, fly = false, noclip = false, esp = false,
                     fullbright = false, infjump = false, god = false,
                     invisible = false, wall = false, chatspy = false,
                     freecam = false, drone = false },
    }

    ApplyPreset = function(name)
        local p = PRESETS[name]
        if not p then
            Log("Preset desconhecido: " .. tostring(name), "warn")
            return false
        end
        local changed = 0
        for id, want in pairs(p) do
            if Toggles[id] and IsOn(id) ~= want then
                SetToggle(id, want, true)
                changed = changed + 1
            end
        end
        if name == "Movement" then
            if WalkSlider then WalkSlider(60) end
            if FlySlider then FlySlider(90) end
        elseif name == "Default" or name == "Minimal" then
            if WalkSlider then WalkSlider(16) end
            if JumpSlider then JumpSlider(50) end
            if FlySlider then FlySlider(50) end
        end
        Log("Preset " .. name .. " aplicado (" .. changed .. " mudança(s))", "action")
        Toast("Preset " .. name, "ok", 2)
        if RefreshQuick then RefreshQuick() end
        if RefreshStatus then RefreshStatus() end
        return true
    end

    local preGrid = Grid(pre, 5, 32)
    for i, n in ipairs({ "Default", "Admin", "Visual", "Movement", "Minimal" }) do
        local b = CreateButton(preGrid, n:upper(), "Accent", 32)
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function() ApplyPreset(n) end)
    end

    ----------------------------------------------------------------------------
    -- SISTEMA
    ----------------------------------------------------------------------------
    local sys = CreateCard(tab, "SISTEMA", 10)
    local sysGrid = Grid(sys, 4, 32)

    local reload = CreateButton(sysGrid, "RECARREGAR DADOS", "Accent", 32)
    reload.LayoutOrder = 1
    reload.MouseButton1Click:Connect(function()
        if RefreshStatus then RefreshStatus() end
        if RebuildPlayerRows then RebuildPlayerRows() end
        if UpdateServerInfo then UpdateServerInfo() end
        Log("Dados recarregados", "ok")
    end)

    local restore = CreateButton(sysGrid, "RESTAURAR PADRÕES", "Warning", 32)
    restore.LayoutOrder = 2
    restore.MouseButton1Click:Connect(function()
        Confirm("Voltar aparência, comportamento, velocidades e keybinds ao padrão?", function()
            -- v8.0: uma única implementação (V8.UI.restore, logo abaixo)
            if V8.UI and V8.UI.restore then V8.UI.restore() end
            Log("Configurações restauradas", "action")
        end)
    end)

    -- v8.0: janela arrastada para fora da tela tinha que recarregar o script
    local center = CreateButton(sysGrid, "CENTRALIZAR JANELA", "Accent", 32)
    center.LayoutOrder = 3
    center.MouseButton1Click:Connect(function()
        if V8.Win then V8.Win.Center() end
    end)

    local unload = CreateButton(sysGrid, "DESCARREGAR PAINEL", "Danger", 32)
    unload.LayoutOrder = 4
    unload.MouseButton1Click:Connect(function()
        Confirm("Descarregar o HYGE? Tudo é desfeito e a GUI é removida.", function()
            if Unload then Unload() end
        end)
    end)

    ----------------------------------------------------------------------------
    -- SOBRE
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- V8.0: expõe os setters desta aba para a persistência (V8.Cfg) usar
    ----------------------------------------------------------------------------
    V8.UI = {
        scale   = scaleSet,
        alpha   = alphaSet,
        maxlog  = maxLogSet,
        compact = ApplyCompact,
        compactRender = compactRender,
        resetkeys = ResetKeys,
        restore = function()
            SET.Animations = true
            SET.Toasts = true
            SET.ShowLogs = true
            SET.Confirm = true
            SET.EspAuto = true
            SET.MaxLog = 60
            CONFIG.MaxLog = 60
            ApplyCompact(false)
            if compactRender then compactRender() end
            -- v8.0: volta para o tema padrão da v8 (era "Roxo" fixo, mas o
            -- shell novo nasce em CONFIG.DefaultTheme)
            ApplyTheme(CONFIG.DefaultTheme)
            scaleSet(100)
            alphaSet(0)
            maxLogSet(60, true)
            ResetKeys()
            ApplyPreset("Default")
            if V8.Renders then
                for _, r in ipairs(V8.Renders) do pcall(r) end
            end
            if V8.Win then V8.Win.Center() end
        end,
    }

    local about = CreateCard(tab, "SOBRE", 11)
    local _, _, missing = V8.RemoteStatus()

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.Text = "HYGE Admin Panel " .. CONFIG.Version
        .. "\nPainel client-side. Tudo que aparece aqui roda na SUA máquina."
        .. "\n\nAdmin: " .. LocalPlayer.Name .. " (UserId " .. LocalPlayer.UserId .. ")"
        .. "\nEdite CONFIG.AdminIds no topo do script para liberar outros admins."
        .. "\n\nRemotes ausentes: "
        .. (#missing == 0 and "nenhum — tudo pronto"
            or (table.concat(missing, ", ") .. "\nAs ações que dependem deles ficam "
                .. "indisponíveis (com aviso), nunca são simuladas. O script de "
                .. "servidor que cria e valida todos eles está em server/ (README)."))
    txt.TextColor3 = THEME.Dim
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 12
    txt.TextWrapped = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = about
    Paint(txt, "TextColor3", "Dim")
end
--------------------------------------------------------------------------------
-- v8.0 — ABA SHOP (ícone de sacola do dock)
-- Ainda não existe loja no HYGE: a aba só avisa. Nada aqui é clicável nem
-- finge vender/desbloquear alguma coisa.
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Shop")
    local card = CreateCard(tab, "SHOP", 1)

    local big = Instance.new("TextLabel")
    big.Size = UDim2.new(1, 0, 0, 34)
    big.BackgroundTransparency = 1
    big.Text = "Em breve"
    big.TextColor3 = THEME.Text
    big.Font = Enum.Font.GothamBold
    big.TextSize = 24
    big.TextXAlignment = Enum.TextXAlignment.Left
    big.LayoutOrder = 1
    big.Parent = card
    Paint(big, "TextColor3", "Text")

    SubLabel(card, "A loja ainda não existe no HYGE. Quando ela entrar, os itens "
        .. "aparecem aqui — por enquanto não há nada para comprar ou desbloquear.", 2)
end
--------------------------------------------------------------------------------
-- v8.0 — ABA SCRIPTS (ícone de terminal do dock)
-- O console de log sai do rodapé da janela e passa a morar aqui, ocupando a
-- aba inteira, com uma linha de comando embaixo (Enter executa, ↑/↓ histórico).
-- A barra flutuante do ";" continua existindo (com autocomplete no Tab).
-- Não é um ScrollingFrame como as outras abas: o console já rola sozinho.
--------------------------------------------------------------------------------
do
    local view = Instance.new("Frame")
    view.Name = "Scripts"
    view.Size = UDim2.new(1, 0, 1, 0)
    view.BackgroundTransparency = 1
    view.Visible = false
    view.Parent = Content
    Tabs.Scripts = view
    V8.ScriptsTab = view

    -- o console (criado em 10_ui/02_console.lua) muda de casa
    ConsoleFrame.Parent = view
    ConsoleFrame.Position = UDim2.new(0, 0, 0, 0)
    ConsoleFrame.Size = UDim2.new(1, 0, 1, -48)
    ConsoleFrame.Visible = true

    local box = CreateInput(view, "comando   ·   Enter executa   ·   ↑/↓ histórico   ·   help lista tudo", 38)
    box.Position = UDim2.new(0, 0, 1, -38)
    box.Size = UDim2.new(1, -112, 0, 38)
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    do
        local p = Instance.new("UIPadding", box)
        p.PaddingLeft = UDim.new(0, 12)
        p.PaddingRight = UDim.new(0, 12)
    end

    local run = CreateButton(view, "EXECUTAR", "Accent", 38)
    run.Position = UDim2.new(1, -104, 1, -38)
    run.Size = UDim2.new(0, 104, 0, 38)

    local histPos = 0
    local function Go()
        local text = box.Text
        box.Text = ""
        histPos = 0
        if text:match("^%s*$") then return end
        if V8.RunCommand then
            V8.RunCommand(text)
        else
            Log("Os comandos ainda não carregaram", "warn")
        end
    end

    box.FocusLost:Connect(function(enter)
        if enter then Go() end
    end)
    run.MouseButton1Click:Connect(Go)

    -- ↑/↓ percorrem o mesmo histórico da barra do ";" (State.CmdHistory)
    Conn.ScriptsHistory = UserInputService.InputBegan:Connect(function(input)
        if not box:IsFocused() then return end
        local hist = State.CmdHistory
        if #hist == 0 then return end
        if input.KeyCode == Enum.KeyCode.Up then
            histPos = math.min(histPos + 1, #hist)
        elseif input.KeyCode == Enum.KeyCode.Down then
            histPos = math.max(histPos - 1, 0)
        else
            return
        end
        box.Text = (histPos == 0) and "" or (hist[#hist - histPos + 1] or "")
        box.CursorPosition = #box.Text + 1
    end)

    -- "Modo compacto" só escondia o console do rodapé, que não existe mais
    if V8.CompactRow then V8.CompactRow.Visible = false end
end
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
--------------------------------------------------------------------------------
-- v8.0 — DOCK (navegação principal)
-- Barra solta no rodapé da TELA, visível mesmo com o painel fechado (é ela que
-- abre o painel; a bolinha "H" só aparece no modo sidebar). 8 seções:
--   Início · Personagem · Shop · Scripts · Emotes · Jogadores · Configurações · Chat
-- O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel.
-- Seção com mais de uma aba ganha sub-abas no topo da janela
-- (ex.: Personagem › Movimento | Visual) — posicionadas pelo V8.Shell.Layout.
-- A sidebar continua existindo: SET.Dock escolhe dock OU sidebar (Ajustes).
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS das abas (40_tabs) no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    -- { aba interna, nome na sub-aba }
    K.Sections = {
        { id = "inicio",  icon = "home",     label = "Início",
          tabs = { { "Home", "Painel" }, { "Server", "Servidor" } } },
        { id = "char",    icon = "user",     label = "Personagem",
          tabs = { { "Movement", "Movimento" }, { "Visuals", "Visual" } } },
        { id = "shop",    icon = "bag",      label = "Shop",
          tabs = { { "Shop", "Shop" } } },
        { id = "scripts", icon = "terminal", label = "Scripts",
          tabs = { { "Scripts", "Console" } } },
        { id = "emotes",  icon = "grid",     label = "Emotes",
          tabs = { { "Emotes", "Emotes" } } },
        { id = "players", icon = "users",    label = "Jogadores",
          tabs = { { "Players", "Lista" }, { "Moderation", "Moderação" } } },
        { id = "config",  icon = "gear",     label = "Configurações",
          tabs = { { "Settings", "Configurações" } } },
        { id = "chat",    icon = "chat",     label = "Chat",
          tabs = { { "Chat", "Chat" } } },
    }

    K.ById = {}        -- id -> seção
    K.TabSection = {}  -- aba interna -> seção
    K.LastTab = {}     -- id -> última sub-aba usada (volta nela ao reabrir)
    K.Btns = {}        -- id -> { button, icon, label }
    K.Current = nil    -- seção da aba ativa
    for _, s in ipairs(K.Sections) do
        K.ById[s.id] = s
        for _, t in ipairs(s.tabs) do K.TabSection[t[1]] = s end
    end

    local function IsOpenNow() return V8.IsOpen and V8.IsOpen() or false end

    ----------------------------------------------------------------------------
    -- a barra (filha da ScreenGui, não da janela)
    ----------------------------------------------------------------------------
    local bar = Instance.new("Frame")
    bar.Name = "Dock"
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.Position = UDim2.new(0.5, 0, 1, -14)
    bar.Size = UDim2.new(0, 0, 0, 56)
    bar.AutomaticSize = Enum.AutomaticSize.X
    bar.BackgroundColor3 = THEME.Sidebar
    bar.BackgroundTransparency = 0.04
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.ZIndex = 20
    bar.Parent = Gui
    Paint(bar, "BackgroundColor3", "Sidebar")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 18)
    do
        local st = Instance.new("UIStroke", bar)
        st.Transparency = 0.5
        Paint(st, "Color", "Line")
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        local l = Instance.new("UIListLayout", bar)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.VerticalAlignment = Enum.VerticalAlignment.Center
    end
    K.Bar = function() return bar end

    -- nome do ícone no hover (o ativo já mostra o nome ao lado)
    local tip = Instance.new("TextLabel")
    tip.AnchorPoint = Vector2.new(0.5, 1)
    tip.Position = UDim2.new(0.5, 0, 0, -8)
    tip.Size = UDim2.new(0, 0, 0, 22)
    tip.AutomaticSize = Enum.AutomaticSize.X
    tip.BackgroundColor3 = THEME.Card
    tip.Text = ""
    tip.TextColor3 = THEME.Text
    tip.Font = Enum.Font.GothamBold
    tip.TextSize = 11
    tip.Visible = false
    tip.ZIndex = 22
    tip.Parent = bar
    Paint(tip, "BackgroundColor3", "Card")
    Paint(tip, "TextColor3", "Text")
    Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 6)
    do
        local p = Instance.new("UIPadding", tip)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)
    end

    ----------------------------------------------------------------------------
    -- os 8 botões: ícone sozinho; o ativo ganha fundo + nome ao lado
    ----------------------------------------------------------------------------
    for i, s in ipairs(K.Sections) do
        local b = Instance.new("TextButton")
        b.Name = s.id
        b.Size = UDim2.new(0, 44, 0, 42)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 20
        b.Parent = bar
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 13)
        do
            local p = Instance.new("UIPadding", b)
            p.PaddingLeft = UDim.new(0, 12)
            p.PaddingRight = UDim.new(0, 12)
            local l = Instance.new("UIListLayout", b)
            l.FillDirection = Enum.FillDirection.Horizontal
            l.VerticalAlignment = Enum.VerticalAlignment.Center
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local ico = Icon(b, s.icon, THEME.Dim, 20, 1)
        ico.ZIndex = 20

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 0, 0, 20)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.BackgroundTransparency = 1
        lbl.Text = s.label
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Visible = false
        lbl.LayoutOrder = 2
        lbl.ZIndex = 20
        lbl.Parent = b
        Paint(lbl, "TextColor3", "Text")

        local entry = { button = b, icon = ico, label = lbl }
        K.Btns[s.id] = entry

        b.MouseEnter:Connect(function()
            if lbl.Visible then return end   -- ativo: nome já está à vista
            tip.Text = s.label
            tip.Visible = true
            b.BackgroundTransparency = 0.55
            IconTint(ico, THEME.Text)
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if lbl.Visible then return end
            b.BackgroundTransparency = 1
            IconTint(ico, THEME.Dim)
        end)
        b.MouseButton1Click:Connect(function()
            tip.Visible = false
            K.Open(s.id, true)
        end)
    end

    ----------------------------------------------------------------------------
    -- sub-abas no topo da janela (só para seção com mais de uma aba)
    ----------------------------------------------------------------------------
    local seg = Instance.new("Frame")
    seg.Name = "SubTabs"
    seg.BackgroundTransparency = 1
    seg.Visible = false
    seg.Parent = Window
    do
        local l = Instance.new("UIListLayout", seg)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    K.Seg = seg

    local segBtns = {}
    for i = 1, 4 do
        local sb = Instance.new("TextButton")
        sb.Size = UDim2.new(0, 0, 1, 0)
        sb.AutomaticSize = Enum.AutomaticSize.X
        sb.BackgroundColor3 = THEME.Btn
        sb.BackgroundTransparency = 1
        sb.Text = ""
        sb.TextColor3 = THEME.Dim
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 12
        sb.AutoButtonColor = false
        sb.LayoutOrder = i
        sb.Visible = false
        sb.Parent = seg
        Paint(sb, "BackgroundColor3", "Btn")
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 9)
        do
            local p = Instance.new("UIPadding", sb)
            p.PaddingLeft = UDim.new(0, 16)
            p.PaddingRight = UDim.new(0, 16)
        end
        local u = { btn = sb, tab = nil }
        segBtns[i] = u
        sb.MouseButton1Click:Connect(function()
            if u.tab then ShowTab(u.tab) end
        end)
    end

    K.SegShown = function()
        return K.Current ~= nil and #K.Current.tabs > 1
    end

    K.RenderSeg = function()
        local s = K.Current
        for i, u in ipairs(segBtns) do
            local t = s and #s.tabs > 1 and s.tabs[i]
            if t then
                local on = (t[1] == State.ActiveTab)
                u.tab = t[1]
                u.btn.Text = t[2]
                u.btn.Visible = true
                u.btn.BackgroundTransparency = on and 0 or 1
                u.btn.TextColor3 = on and THEME.Accent or THEME.Dim
            else
                u.tab = nil
                u.btn.Visible = false
            end
        end
        -- mostrar/esconder a faixa muda a altura do Content: o shell recalcula
        local want = (SET.Dock == true) and K.SegShown() and not State.Minimized
        if want ~= seg.Visible and V8.Shell and V8.Shell.Layout then
            pcall(V8.Shell.Layout)
        end
    end

    ----------------------------------------------------------------------------
    -- realce: só com o painel aberto (fechado, nenhum ícone fica aceso)
    ----------------------------------------------------------------------------
    K.Sync = function(active)
        active = active or State.ActiveTab
        local s = K.TabSection[active]
        K.Current = s
        if s then K.LastTab[s.id] = active end
        local open = IsOpenNow()
        for id, u in pairs(K.Btns) do
            local on = open and s ~= nil and s.id == id
            u.label.Visible = on
            u.button.BackgroundTransparency = on and 0 or 1
            IconTint(u.icon, on and THEME.Accent or THEME.Dim)
        end
        K.RenderSeg()
    end

    -- abre a seção (na última sub-aba usada). toggle = clique no dock:
    -- clicar na seção que já está aberta fecha o painel
    K.Open = function(id, toggle)
        local s = K.ById[id]
        if not s then return end
        local open = IsOpenNow()
        if toggle and open and K.Current == s then
            if V8.SetOpen then V8.SetOpen(false) end
            return
        end
        ShowTab(K.LastTab[id] or s.tabs[1][1])
        if not open and V8.SetOpen then V8.SetOpen(true) end
    end

    -- embrulha o ShowTab que já existe: qualquer caminho (busca, situações,
    -- comandos) mantém o dock e as sub-abas em dia
    do
        local base = ShowTab
        ShowTab = function(name)
            base(name)
            pcall(K.Sync, name)
        end
    end

    -- troca de tema: os ícones do dock são pintados à mão (IconTint)
    do
        local baseTheme = ApplyTheme
        if baseTheme then
            ApplyTheme = function(name)
                local r = baseTheme(name)
                pcall(K.Sync, State.ActiveTab)
                return r
            end
        end
    end

    ----------------------------------------------------------------------------
    -- liga / desliga: dock OU sidebar (+ bolinha "H"), nunca os dois
    ----------------------------------------------------------------------------
    K.Apply = function(on)
        SET.Dock = on and true or false
        bar.Visible = SET.Dock
        Sidebar.Visible = (not SET.Dock) and not State.Minimized
        if V8.Orb then V8.Orb.Visible = (not SET.Dock) and not IsOpenNow() end
        -- o HUD do spectate também fica no centro do rodapé: sobe acima do dock
        if SpectateHud then
            SpectateHud.Position = UDim2.new(0.5, 0, 1, SET.Dock and -84 or -24)
        end
        if V8.Shell and V8.Shell.Layout then pcall(V8.Shell.Layout) end
        pcall(K.Sync, State.ActiveTab)
    end

    ----------------------------------------------------------------------------
    -- card nas Settings
    ----------------------------------------------------------------------------
    do
        local nav = CreateCard(Tabs.Settings, "NAVEGAÇÃO", 8)
        SubLabel(nav, "O dock no rodapé da tela é o padrão da v8: 8 ícones, sempre "
            .. "visível, e é ele que abre o painel. Desligue para voltar à sidebar "
            .. "dentro da janela (com a bolinha H para abrir).", 0)

        local render = CheckRow(nav, "Usar dock de ícones",
            "Desligado: sidebar dentro da janela + bolinha H",
            function() return SET.Dock == true end,
            function(v) K.Apply(v) end, 1)
        K.Render = render

        ------------------------------------------------------------------------
        -- os 3 cards de status da Home são configuráveis
        ------------------------------------------------------------------------
        if V8.Dash and V8.Dash.SetSlots then
            SubLabel(nav, "Cards de status da Home: escreva os três toggles "
                .. "separados por espaço (padrão: fly noclip esp). Vale qualquer "
                .. "id da lista: fly, noclip, infjump, god, invisible, wall, esp, "
                .. "chatspy, fullbright, antiafk, freecam, drone.", 2)

            local box = CreateInput(nav, "fly noclip esp", 32)
            box.LayoutOrder = 3
            box.Text = table.concat(V8.Dash.Slots, " ")
            box.FocusLost:Connect(function(enter)
                if not enter then
                    box.Text = table.concat(V8.Dash.Slots, " ")
                    return
                end
                SET.Slots = V8.Dash.SetSlots(box.Text)
                box.Text = SET.Slots
            end)
            K.SlotBox = box
        end
    end

    K.Apply(SET.Dock)
end
--------------------------------------------------------------------------------
-- v8.0 — SHELL (layout novo, estilo do mockup)
-- NAO recria a janela: reconfigura as instancias que o engine ja criou.
--   * janela mais larga e baixa (800x500)
--   * TopBar limpa: "Welcome home, <nome>" + selo de verificado + relogio,
--     minimizar/fechar discretos no canto
--   * dock solto no rodape da tela como navegacao padrao (sidebar segue no
--     codigo); a janela nasce logo acima dele
--   * console mora na aba Scripts (icone de terminal do dock)
-- Tudo em V8.Shell: zero locais novos no chunk principal.
-- Entra DEPOIS de 00_dock.lua e ANTES de 02_situations.lua no build.
--------------------------------------------------------------------------------
do
    V8.Shell = {}
    local H = V8.Shell

    H.W = 800           -- largura da janela
    H.Hgt = 500         -- altura da janela
    H.TopH = 62         -- altura da TopBar (usada tambem no minimizado)
    H.ConsoleH = 168    -- altura do console quando aberto
    H.ConsoleOpen = false
    H.Blue = Color3.fromRGB(0, 175, 255)   -- azul do selo de verificado

    ----------------------------------------------------------------------------
    -- 1. JANELA
    ----------------------------------------------------------------------------
    Window.Size = UDim2.new(0, H.W, 0, H.Hgt)
    -- posição "de casa": com o dock, centralizada logo acima dele; sem o
    -- dock (modo sidebar), no meio da tela. Usada também por 'center'.
    H.HomePos = function()
        if SET.Dock ~= false then
            return UDim2.new(0.5, -H.W * 0.5, 1, -(H.Hgt + 84))
        end
        return UDim2.new(0.5, -H.W * 0.5, 0.5, -H.Hgt * 0.5)
    end
    Window.Position = H.HomePos()
    do
        local c = Window:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    ----------------------------------------------------------------------------
    -- 2. TOPBAR: esconde logo/titulo/versao/Stat (nao destroi — o scheduler
    --    ainda escreve em Stat.Text quando SetChips nao existe)
    ----------------------------------------------------------------------------
    TopBar.Size = UDim2.new(1, 0, 0, H.TopH)
    do
        local c = TopBar:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    for _, c in ipairs(TopBar:GetChildren()) do
        local keep = (c == CloseBtn) or (c == MinBtn) or (c.Name == "StatChips")
        -- o "topFix" (tapa o canto arredondado de baixo) tem essa medida exata
        if c:IsA("Frame") and c.Size == UDim2.new(1, 0, 0, 16) then keep = true end
        if not keep and (c:IsA("TextLabel") or c:IsA("Frame")
            or c:IsA("ImageLabel")) then
            c.Visible = false
        end
    end

    -------------------------------------------------- selo azul de verificado
    -- circulo azul + serrilha (quadrado girado) + check branco
    H.Badge = function(parent, size, order)
        local b = Instance.new("Frame")
        b.Name = "Verified"
        b.Size = UDim2.new(0, size, 0, size)
        b.BackgroundColor3 = H.Blue
        b.BorderSizePixel = 0
        b.LayoutOrder = order or 2
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)

        local star = Instance.new("Frame")
        star.AnchorPoint = Vector2.new(0.5, 0.5)
        star.Position = UDim2.new(0.5, 0, 0.5, 0)
        star.Size = UDim2.new(0.78, 0, 0.78, 0)
        star.Rotation = 45
        star.BackgroundColor3 = H.Blue
        star.BorderSizePixel = 0
        star.ZIndex = 2
        star.Parent = b
        Instance.new("UICorner", star).CornerRadius =
            UDim.new(0, math.max(2, math.floor(size * 0.14)))

        local ck = Icon(b, "check", Color3.new(1, 1, 1),
            math.max(8, math.floor(size * 0.64)), 1)
        ck.AnchorPoint = Vector2.new(0.5, 0.5)
        ck.Position = UDim2.new(0.5, 0, 0.5, 0)
        ck.ZIndex = 3
        return b
    end

    ---------------------------------------------------- "Welcome home, <nome>"
    local head = Instance.new("Frame")
    head.Name = "Welcome"
    head.Position = UDim2.new(0, 20, 0, 10)
    head.Size = UDim2.new(0, 0, 0, 26)
    head.AutomaticSize = Enum.AutomaticSize.X
    head.BackgroundTransparency = 1
    head.Parent = TopBar
    do
        local l = Instance.new("UIListLayout", head)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 7)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    local hi = Instance.new("TextLabel")
    hi.AutomaticSize = Enum.AutomaticSize.X
    hi.Size = UDim2.new(0, 0, 0, 24)
    hi.BackgroundTransparency = 1
    hi.Text = "Welcome home, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
    hi.TextColor3 = Color3.new(1, 1, 1)    -- branco puro de proposito
    hi.Font = Enum.Font.GothamBold
    hi.TextSize = 20
    hi.TextXAlignment = Enum.TextXAlignment.Left
    hi.LayoutOrder = 1
    hi.Parent = head
    H.Badge(head, 18, 2)

    local sub = Instance.new("TextLabel")
    sub.Name = "WelcomeSub"
    sub.Position = UDim2.new(0, 21, 0, 37)
    sub.Size = UDim2.new(0, 320, 0, 14)
    sub.BackgroundTransparency = 1
    sub.Text = "HYGE " .. CONFIG.Version .. "  ·  painel pronto"
    sub.TextColor3 = THEME.Dim
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = TopBar
    Paint(sub, "TextColor3", "Dim")

    ------------------------------------------------------------------ relogio
    local clock = Instance.new("Frame")
    clock.Name = "Clock"
    clock.AnchorPoint = Vector2.new(1, 0.5)
    clock.Position = UDim2.new(1, -84, 0, 21)
    clock.Size = UDim2.new(0, 0, 0, 22)
    clock.AutomaticSize = Enum.AutomaticSize.X
    clock.BackgroundTransparency = 1
    clock.Parent = TopBar
    do
        local l = Instance.new("UIListLayout", clock)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    Icon(clock, "clock", THEME.Dim, 15, 1)

    local clockLbl = Instance.new("TextLabel")
    clockLbl.AutomaticSize = Enum.AutomaticSize.X
    clockLbl.Size = UDim2.new(0, 0, 0, 20)
    clockLbl.BackgroundTransparency = 1
    clockLbl.Text = "--:--"
    clockLbl.TextColor3 = THEME.Text
    clockLbl.Font = Enum.Font.GothamBold
    clockLbl.TextSize = 15
    clockLbl.LayoutOrder = 2
    clockLbl.Parent = clock
    Paint(clockLbl, "TextColor3", "Text")

    -- chamado pelo Every(1) que ja existe em 90_runtime/04_scheduler.lua (nenhum loop novo)
    H.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
    end
    H.Tick()

    --------------------------------------------- minimizar / fechar discretos
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -40, 0, 8)
    CloseBtn.TextSize = 13
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -70, 0, 8)
    MinBtn.TextSize = 13
    do
        local c = CloseBtn:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 9) end
        c = MinBtn:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 9) end
        CloseBtn.BackgroundTransparency = 0.45
        MinBtn.BackgroundTransparency = 0.45
    end

    ------------------------------- chips de FPS/ping na segunda linha, a direita
    do
        local chips = TopBar:FindFirstChild("StatChips")
        if chips then
            chips.AnchorPoint = Vector2.new(1, 0.5)
            chips.Position = UDim2.new(1, -16, 0, 45)
            chips.Size = UDim2.new(0, 430, 0, 20)
            local lay = chips:FindFirstChildOfClass("UIListLayout")
            if lay then lay.Padding = UDim.new(0, 14) end
            -- o chip 4 e o nome do jogo (texto longo): sai da barra limpa,
            -- a informacao continua na aba Servidor
            for _, c in ipairs(chips:GetChildren()) do
                if c:IsA("Frame") and c.LayoutOrder == 4 then c.Visible = false end
            end
        end
    end

    ----------------------------------------------------------------------------
    -- 3. SIDEBAR (segue existindo, so acompanha a TopBar mais alta)
    ----------------------------------------------------------------------------
    Sidebar.Size = UDim2.new(0, 164, 1, -H.TopH)
    Sidebar.Position = UDim2.new(0, 0, 0, H.TopH)

    ----------------------------------------------------------------------------
    -- 4. GEOMETRIA: uma funcao unica manda no Content e nas sub-abas.
    --    O dock agora mora fora da janela: nada e reservado no rodape.
    --    O console nao e mais painel daqui — vive na aba Scripts.
    ----------------------------------------------------------------------------
    H.Layout = function()
        local dockOn = (SET.Dock == true)
        local left = dockOn and 14 or 172
        local wOff = dockOn and -28 or -186
        local top = H.TopH + 10
        local bottom = 14

        -- sub-abas da secao ativa (ex.: Personagem › Movimento | Visual)
        local seg = V8.Dock and V8.Dock.Seg
        if seg then
            local show = dockOn and V8.Dock.SegShown() and not State.Minimized
            seg.Visible = show
            seg.Position = UDim2.new(0, left, 0, top)
            seg.Size = UDim2.new(1, wOff, 0, 30)
            if show then top = top + 40 end
        end

        Content.Position = UDim2.new(0, left, 0, top)
        Content.Size = UDim2.new(1, wOff, 1, -(top + bottom))
    end

    -- compatibilidade: quem pedia "abrir o console" agora abre a aba Scripts
    H.ToggleConsole = function()
        if V8.Dock and V8.Dock.Open then V8.Dock.Open("scripts", true) end
    end

    ----------------------------------------------------------------------------
    -- 5. ajustes no dashboard da Home: o card "Welcome home" sai (subiu pra
    --    TopBar) e o nome sob o avatar ganha o mesmo selo azul
    ----------------------------------------------------------------------------
    if V8.Dash then
        if V8.Dash.Head then V8.Dash.Head.Visible = false end
        if V8.Dash.NameRow then H.Badge(V8.Dash.NameRow, 15, 2) end
    end

    ----------------------------------------------------------------------------
    -- 6. dock como padrao (a sidebar continua a um clique nas Settings)
    ----------------------------------------------------------------------------
    if SET.Dock == nil then SET.Dock = true end
    if V8.Dock and V8.Dock.Apply then
        pcall(V8.Dock.Apply, SET.Dock == true)
    else
        H.Layout()
    end
    H.Layout()

    ----------------------------------------------------------------------------
    -- 7. paleta padrao do shell novo: azul escuro quase preto (nao roxo).
    --    Se houver config salva em disco, o BootStep "Config" roda depois e
    --    o tema salvo ganha — isto e so o padrao de quem nunca salvou.
    ----------------------------------------------------------------------------
    if ApplyTheme and PALETTES[CONFIG.DefaultTheme] then
        SET.Theme = SET.Theme or CONFIG.DefaultTheme
        pcall(ApplyTheme, SET.Theme)
    end
end
--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — SISTEMA DE SITUAÇÕES
-- Um clique troca o modo de operação inteiro: liga o que pertence à situação
-- e DESLIGA o que não pertence. Cards no Dashboard + keybind por situação.
-- Tudo dentro de um do..end (locais liberados no fim, por causa do limite
-- de ~200 slots do Luau).
--------------------------------------------------------------------------------
do
    V8.Sit = {}
    local S = V8.Sit

    S.Current = nil
    S.Keys    = {}   -- [nome] = KeyCode
    S.Order   = { "Moderação", "Caça", "Observação", "Movimento", "Stealth", "Limpeza" }

    -- on   = toggles que a situação liga (o resto é desligado)
    -- esp  = campos de EspOpts sobrescritos
    -- walk / fly / jump = velocidades aplicadas pelos sliders reais
    -- tab  = aba aberta ao aplicar
    S.Defs = {
        ["Moderação"] = {
            icon = "shield", desc = "vigiar a sala", key = Enum.KeyCode.KeypadOne,
            on   = { esp = true, fullbright = true, chatspy = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = false, Allies = true, Enemies = true },
            tab  = "Players",
        },
        ["Caça"] = {
            icon = "eye", desc = "só inimigos", key = Enum.KeyCode.KeypadTwo,
            on   = { esp = true, fly = true, noclip = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = true, Allies = false, Enemies = true },
            fly  = 90,
            tab  = "Visuals",
        },
        ["Observação"] = {
            icon = "cam", desc = "freecam + spectate", key = Enum.KeyCode.KeypadThree,
            on   = { freecam = true, esp = true, chatspy = true, antiafk = true },
            esp  = { Highlight = true, Name = true, Distance = true, Health = false,
                     HealthBar = false, Tracers = false, Allies = true, Enemies = true },
            tab  = "Players",
            hint = "Selecione um jogador e use ASSISTIR (ou 'spec <nome>').",
        },
        ["Movimento"] = {
            icon = "run", desc = "atravessar o mapa", key = Enum.KeyCode.KeypadFour,
            on   = { fly = true, noclip = true, infjump = true, antiafk = true },
            walk = 80, fly = 120, jump = 100,
            tab  = "Movement",
        },
        ["Stealth"] = {
            icon = "ghost", desc = "sumir da tela", key = Enum.KeyCode.KeypadFive,
            on   = { invisible = true, wall = true, esp = true, antiafk = true },
            esp  = { Highlight = true, Name = false, Distance = false, Health = false,
                     HealthBar = false, Tracers = false, Allies = true, Enemies = true },
            tab  = "Visuals",
        },
        ["Limpeza"] = {
            icon = "trash", desc = "desligar tudo", key = Enum.KeyCode.KeypadSix,
            on   = {},
            esp  = { Highlight = true, Name = true, Distance = true, Health = true,
                     HealthBar = true, Tracers = false, Allies = true, Enemies = true,
                     MaxDist = 1000, TeamColors = false },
            walk = 16, fly = 50, jump = 50,
            clean = true,
        },
    }

    for n, d in pairs(S.Defs) do S.Keys[n] = d.key end

    local cards = {}    -- [nome] = { bar = Frame, name = TextLabel, key = TextLabel }
    local keyBtns = {}  -- [nome] = TextButton (aba Settings)
    local header                                     -- label "SITUAÇÃO ATIVA: ..."

    ----------------------------------------------------------------------------
    -- render do estado ativo (cards + header + rótulos de tecla)
    ----------------------------------------------------------------------------
    S.Render = function()
        for n, c in pairs(cards) do
            local active = (S.Current == n)
            c.bar.Visible = active
            c.name.TextColor3 = active and THEME.Accent or THEME.Text
            c.key.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—"
        end
        for n, b in pairs(keyBtns) do
            if b.Text ~= "aperte..." then b.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—" end
        end
        if header then
            header.Text = "SITUAÇÃO ATIVA:  " .. (S.Current and S.Current:upper() or "NENHUMA")
            header.TextColor3 = S.Current and THEME.Accent or THEME.Dim
        end
    end

    ----------------------------------------------------------------------------
    -- aplica uma situação
    ----------------------------------------------------------------------------
    S.Apply = function(name, silent)
        local d = S.Defs[name]
        if not d then
            Log("Situação desconhecida: " .. tostring(name), "warn")
            return false
        end

        local changed = 0
        for _, id in ipairs(ToggleOrder) do
            local want = (d.on[id] == true)
            if IsOn(id) ~= want then
                local ok = pcall(SetToggle, id, want, true)
                if ok then changed = changed + 1 end
            end
        end

        if d.esp then
            for k, v in pairs(d.esp) do EspOpts[k] = v end
        end
        if d.walk and WalkSlider then pcall(WalkSlider, d.walk) end
        if d.fly  and FlySlider  then pcall(FlySlider, d.fly) end
        if d.jump and JumpSlider then pcall(JumpSlider, d.jump) end

        if d.clean then
            pcall(StopSpectate)
            pcall(function() Emote.Stop(true) end)
        end

        S.Current = name
        if d.tab then pcall(ShowTab, d.tab) end
        if RefreshQuick then pcall(RefreshQuick) end
        if RefreshStatus then pcall(RefreshStatus) end
        pcall(S.Render)

        if not silent then
            Log("Situação " .. name .. " aplicada (" .. changed .. " mudança(s))", "action")
            if d.hint then Log(d.hint) end
            Toast("Situação: " .. name, d.clean and "warn" or "ok", 2.5)
        end
        return true
    end

    -- aceita nome parcial / sem acento certo ("mod", "caca", "stealth")
    S.Find = function(q)
        if not q or q == "" then return nil end
        q = tostring(q):lower()
        for _, n in ipairs(S.Order) do
            local low = n:lower()
            if low == q then return n end
        end
        for _, n in ipairs(S.Order) do
            if n:lower():sub(1, #q) == q then return n end
        end
        for _, n in ipairs(S.Order) do
            if n:lower():find(q, 1, true) then return n end
        end
        return nil
    end

    ----------------------------------------------------------------------------
    -- teclas (chamado pelo handler global de 90_runtime/03_input.lua)
    ----------------------------------------------------------------------------
    S.HandleKey = function(input)
        for n, kc in pairs(S.Keys) do
            if kc == input.KeyCode then
                S.Apply(n)
                return true
            end
        end
        return false
    end

    ----------------------------------------------------------------------------
    -- CARDS NO DASHBOARD (aba Home, no topo)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Home"], "SITUAÇÕES", 0)
        SubLabel(card, "Um clique troca o modo de operação: liga o que pertence à "
            .. "situação e desliga o resto. As teclas ficam na aba Settings.", -1)

        header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, 0, 0, 14)
        header.BackgroundTransparency = 1
        header.Text = "SITUAÇÃO ATIVA:  NENHUMA"
        header.TextColor3 = THEME.Dim
        header.Font = Enum.Font.GothamBold
        header.TextSize = 10
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = 0
        header.Parent = card
        table.insert(Painted, { inst = header, prop = "TextColor3", key = "Dim" })

        local grid = Grid(card, 3, 54)
        grid.LayoutOrder = 1

        for i, n in ipairs(S.Order) do
            local d = S.Defs[n]
            local b = CreateButton(grid, "", d.clean and "Danger" or "Accent", 54)
            b.LayoutOrder = i

            local ic = Icon(b, d.icon, d.clean and THEME.Danger or THEME.Accent, 16)
            ic.Position = UDim2.new(0, 10, 0, 9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -76, 0, 15)
            nm.Position = UDim2.new(0, 33, 0, 9)
            nm.BackgroundTransparency = 1
            nm.Text = n:upper()
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = b

            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -44, 0, 12)
            ds.Position = UDim2.new(0, 33, 0, 26)
            ds.BackgroundTransparency = 1
            ds.Text = d.desc
            ds.TextColor3 = THEME.Dim
            ds.Font = Enum.Font.Gotham
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.Parent = b
            table.insert(Painted, { inst = ds, prop = "TextColor3", key = "Dim" })

            local kl = Instance.new("TextLabel")
            kl.AnchorPoint = Vector2.new(1, 0)
            kl.Size = UDim2.new(0, 60, 0, 13)
            kl.Position = UDim2.new(1, -8, 0, 9)
            kl.BackgroundTransparency = 1
            kl.Text = d.key and KeyName(d.key) or "—"
            kl.TextColor3 = THEME.Accent2
            kl.Font = Enum.Font.Code
            kl.TextSize = 10
            kl.TextXAlignment = Enum.TextXAlignment.Right
            kl.Parent = b
            table.insert(Painted, { inst = kl, prop = "TextColor3", key = "Accent2" })

            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 1)
            bar.Position = UDim2.new(0.5, 0, 1, -4)
            bar.Size = UDim2.new(1, -16, 0, 3)
            bar.BackgroundColor3 = THEME.Accent
            bar.BorderSizePixel = 0
            bar.Visible = false
            bar.Parent = b
            Paint(bar, "BackgroundColor3", "Accent")
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            cards[n] = { bar = bar, name = nm, key = kl }
            b.MouseButton1Click:Connect(function() S.Apply(n) end)
        end
    end

    ----------------------------------------------------------------------------
    -- ATALHOS DAS SITUAÇÕES (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "ATALHOS DAS SITUAÇÕES", 5)
        SubLabel(card, "Padrão: teclado numérico 1 a 6. Clique e aperte a tecla; "
            .. "Backspace remove. Conflitos com funções são desfeitos automaticamente.", -1)

        for i, n in ipairs(S.Order) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i
            row.Parent = card

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -110, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Situação " .. n
            lbl.TextColor3 = THEME.Text
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = row
            Paint(lbl, "TextColor3", "Text")

            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.new(1, 0, 0.5, 0)
            btn.Size = UDim2.new(0, 96, 0, 26)
            btn.BackgroundColor3 = THEME.Btn
            btn.Text = S.Keys[n] and KeyName(S.Keys[n]) or "—"
            btn.TextColor3 = THEME.Accent2
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            btn.AutoButtonColor = false
            btn.Parent = row
            Paint(btn, "BackgroundColor3", "Btn")
            Paint(btn, "TextColor3", "Accent2")
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
            local st = Instance.new("UIStroke", btn)
            st.Transparency = 0.6
            Paint(st, "Color", "Accent")

            keyBtns[n] = btn

            btn.MouseButton1Click:Connect(function()
                Drop("SitCapture")
                capturing = "sit:" .. n
                btn.Text = "aperte..."
                Toast("Aperte a tecla da situação " .. n .. " (Backspace remove)", nil, 3)

                Conn.SitCapture = UserInputService.InputBegan:Connect(function(input)
                    if capturing ~= ("sit:" .. n) then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    local kc = input.KeyCode
                    if kc == Enum.KeyCode.Unknown then return end

                    Drop("SitCapture")
                    capturing = nil

                    if kc == Enum.KeyCode.Backspace then
                        S.Keys[n] = nil
                        Log("Atalho da situação " .. n .. " removido")
                    elseif kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey then
                        Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                    else
                        for id, other in pairs(Keybinds) do
                            if other == kc then
                                Keybinds[id] = nil
                                if KeybindLabels[id] then KeybindLabels[id].Text = "—" end
                                Log("Tecla " .. KeyName(kc) .. " tirada de '" .. id .. "'", "warn")
                            end
                        end
                        for other, okc in pairs(S.Keys) do
                            if okc == kc and other ~= n then S.Keys[other] = nil end
                        end
                        S.Keys[n] = kc
                        Log("Situação " .. n .. " = " .. KeyName(kc), "ok")
                    end
                    pcall(S.Render)
                end)
            end)
        end
    end

    S.Render()
end
--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — PERSISTÊNCIA (HYGE/config.json)
-- Salva/carrega keybinds, aparência, comportamento, velocidades, opções de ESP,
-- waypoints, favoritos de emote, notas e a última situação.
-- Se o executor não tiver API de arquivos, avisa na UI e no log — NUNCA finge
-- que salvou. Exportar/importar por clipboard funciona mesmo assim.
--------------------------------------------------------------------------------
do
    V8.Cfg = {}
    local C = V8.Cfg

    C.Folder = "HYGE"
    C.Path   = "HYGE/config.json"

    local Http = nil
    pcall(function() Http = game:GetService("HttpService") end)

    if SET.AutoSave  == nil then SET.AutoSave  = true  end
    if SET.SitOnLoad == nil then SET.SitOnLoad = false end
    if SET.Theme     == nil then SET.Theme     = CONFIG.DefaultTheme end
    if State.Notes   == nil then State.Notes   = {} end   -- [userId] = texto (fase 2)

    -- o painel precisa saber qual tema está ativo para salvar: embrulha ApplyTheme
    do
        local base = ApplyTheme
        if base then
            ApplyTheme = function(name)
                SET.Theme = name
                return base(name)
            end
        end
    end

    ----------------------------------------------------------------------------
    -- suporte do executor
    ----------------------------------------------------------------------------
    local function FileApi()
        return typeof(writefile) == "function" and typeof(readfile) == "function"
            and typeof(isfile) == "function"
    end
    C.Supported = function() return FileApi() and Http ~= nil end

    local function Encode(t)
        local ok, res = pcall(function() return Http:JSONEncode(t) end)
        if ok then return res end
        return nil, tostring(res)
    end
    local function Decode(s)
        local ok, res = pcall(function() return Http:JSONDecode(s) end)
        if ok and type(res) == "table" then return res end
        return nil, tostring(res)
    end

    ----------------------------------------------------------------------------
    -- snapshot / restauração
    ----------------------------------------------------------------------------
    local ESP_KEYS = { "Highlight", "Name", "UseDisplay", "Distance", "Health",
                       "HealthBar", "Tracers", "Allies", "Enemies", "MaxDist",
                       "Rate", "ColorKey", "AllyKey", "TeamColors" }
    local SET_KEYS = { "Animations", "Toasts", "ShowLogs", "Confirm", "EspAuto",
                       "MaxLog", "Compact", "Transparency", "AutoSave", "SitOnLoad",
                       "Dock", "Slots", "WinPos" }

    C.Snapshot = function()
        local d = {
            version = CONFIG.Version,
            theme   = SET.Theme,
            scale   = math.floor((CONFIG.UiScale or 1) * 100 + 0.5),
            set     = {},
            esp     = {},
            keys    = {},
            sitkeys = {},
            speeds  = {
                walk  = State.WalkSpeed,
                fly   = State.FlySpeed,
                jump  = State.JumpPower,
                drone = State.DroneSpeed,
                wall  = State.WallAlpha,
            },
            waypoints = {},
            emotes    = {},
            notes     = {},
            panelkey  = CONFIG.PanelKey and CONFIG.PanelKey.Name or nil,
            consolekey = CONFIG.ConsoleKey and CONFIG.ConsoleKey.Name or nil,
            searchkey = CONFIG.SearchKey and CONFIG.SearchKey.Name or nil,
            searchctrl = CONFIG.SearchCtrl,
            situation = V8.Sit and V8.Sit.Current or nil,
        }
        for _, k in ipairs(SET_KEYS) do d.set[k] = SET[k] end
        for _, k in ipairs(ESP_KEYS) do d.esp[k] = EspOpts[k] end
        for id, kc in pairs(Keybinds) do d.keys[id] = kc.Name end
        if V8.Sit then
            for n, kc in pairs(V8.Sit.Keys) do d.sitkeys[n] = kc.Name end
        end
        for i, w in ipairs(State.Waypoints) do
            local c = { w.cframe:GetComponents() }
            d.waypoints[i] = { name = w.name, cf = c }
        end
        for i, e in ipairs(State.Emotes) do
            d.emotes[i] = { id = e.id, name = e.name }
        end
        for id, txt in pairs(State.Notes) do d.notes[tostring(id)] = txt end
        return d
    end

    local function KC(name)
        if type(name) ~= "string" then return nil end
        local ok, kc = pcall(function() return Enum.KeyCode[name] end)
        if ok then return kc end
        return nil
    end

    C.Restore = function(d)
        if type(d) ~= "table" then return false end
        local ui = V8.UI or {}

        -- comportamento / aparência
        if type(d.set) == "table" then
            for _, k in ipairs(SET_KEYS) do
                if d.set[k] ~= nil then SET[k] = d.set[k] end
            end
            CONFIG.MaxLog = SET.MaxLog or CONFIG.MaxLog
        end
        if d.theme and PALETTES[d.theme] and ApplyTheme then pcall(ApplyTheme, d.theme) end
        if ui.scale and d.scale then pcall(ui.scale, d.scale) end
        if ui.alpha and SET.Transparency then pcall(ui.alpha, math.floor(SET.Transparency * 100 + 0.5)) end
        if ui.maxlog and SET.MaxLog then pcall(ui.maxlog, SET.MaxLog, true) end
        if ui.compact then pcall(ui.compact, SET.Compact == true) end
        if ui.compactRender then pcall(ui.compactRender) end
        -- sidebar x dock: o render do switch é visual, o Apply é que troca o layout
        if V8.Dock then pcall(V8.Dock.Apply, SET.Dock == true) end
        -- v8.0: posição da janela (validada e presa dentro da tela)
        if V8.Win and type(SET.WinPos) == "table" then pcall(V8.Win.Restore, SET.WinPos) end
        -- os 3 cards de status da Home (string "fly noclip esp")
        if type(SET.Slots) == "string" and V8.Dash and V8.Dash.SetSlots then
            pcall(V8.Dash.SetSlots, SET.Slots, true)
            if V8.Dock and V8.Dock.SlotBox then
                V8.Dock.SlotBox.Text = table.concat(V8.Dash.Slots, " ")
            end
        end

        -- opções de ESP
        if type(d.esp) == "table" then
            for _, k in ipairs(ESP_KEYS) do
                if d.esp[k] ~= nil then EspOpts[k] = d.esp[k] end
            end
        end
        -- re-renderiza TODOS os switches registrados (comportamento, esp, etc.)
        if V8.Renders then
            for _, r in ipairs(V8.Renders) do pcall(r) end
        end

        -- velocidades (pelos sliders reais, então a UI acompanha)
        if type(d.speeds) == "table" then
            if d.speeds.walk and WalkSlider then pcall(WalkSlider, d.speeds.walk) end
            if d.speeds.fly and FlySlider then pcall(FlySlider, d.speeds.fly) end
            if d.speeds.jump and JumpSlider then pcall(JumpSlider, d.speeds.jump) end
            if d.speeds.drone and DroneSpeedSlider then pcall(DroneSpeedSlider, d.speeds.drone) end
            if d.speeds.wall then State.WallAlpha = d.speeds.wall end
        end

        -- keybinds
        if type(d.keys) == "table" then
            for id in pairs(Keybinds) do Keybinds[id] = nil end
            for id, name in pairs(d.keys) do
                local kc = KC(name)
                if kc and Toggles[id] then Keybinds[id] = kc end
            end
            for id, lbl in pairs(KeybindLabels) do
                lbl.Text = Keybinds[id] and KeyName(Keybinds[id]) or "—"
            end
        end
        if d.panelkey and KC(d.panelkey) then CONFIG.PanelKey = KC(d.panelkey) end
        if d.consolekey and KC(d.consolekey) then CONFIG.ConsoleKey = KC(d.consolekey) end
        if d.searchkey and KC(d.searchkey) then CONFIG.SearchKey = KC(d.searchkey) end
        if d.searchctrl ~= nil then CONFIG.SearchCtrl = d.searchctrl end

        -- atalhos das situações
        if V8.Sit and type(d.sitkeys) == "table" then
            for n in pairs(V8.Sit.Keys) do V8.Sit.Keys[n] = nil end
            for n, name in pairs(d.sitkeys) do
                local kc = KC(name)
                if kc and V8.Sit.Defs[n] then V8.Sit.Keys[n] = kc end
            end
            pcall(V8.Sit.Render)
        end

        -- waypoints
        if type(d.waypoints) == "table" then
            for i = #State.Waypoints, 1, -1 do State.Waypoints[i] = nil end
            for _, w in ipairs(d.waypoints) do
                local c = w.cf
                if type(c) == "table" and #c >= 12 then
                    local ok, cf = pcall(function() return CFrame.new(table.unpack(c)) end)
                    if ok then
                        table.insert(State.Waypoints, { name = w.name or "WP", cframe = cf })
                    end
                end
            end
            if RenderWaypoints then pcall(RenderWaypoints) end
        end

        -- favoritos de emote
        if type(d.emotes) == "table" then
            for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
            for _, e in ipairs(d.emotes) do
                if e.id then table.insert(State.Emotes, { id = e.id, name = e.name or e.id }) end
            end
            if V8.RenderEmotes then pcall(V8.RenderEmotes) end
        end

        -- notas (fase 2 usa isso)
        if type(d.notes) == "table" then
            for k in pairs(State.Notes) do State.Notes[k] = nil end
            for k, v in pairs(d.notes) do State.Notes[tonumber(k) or k] = v end
        end

        C.LastSituation = d.situation
        if RefreshQuick then pcall(RefreshQuick) end
        if RefreshStatus then pcall(RefreshStatus) end
        return true
    end

    ----------------------------------------------------------------------------
    -- disco
    ----------------------------------------------------------------------------
    local status   -- SubLabel de estado (definido na UI abaixo)
    local function Say(msg, kind)
        Log(msg, kind)
        if status then status.Text = msg end
    end

    C.Save = function(silent)
        if not C.Supported() then
            Say("Não salvei: este executor não expõe writefile/readfile "
                .. "(use EXPORTAR e guarde o JSON à mão)", "error")
            if not silent then Toast("Executor sem API de arquivos — nada foi salvo", "error", 4) end
            return false
        end
        local json, err = Encode(C.Snapshot())
        if not json then
            Say("Falha ao gerar o JSON: " .. tostring(err), "error")
            return false
        end
        local ok, werr = pcall(function()
            if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
                if not isfolder(C.Folder) then makefolder(C.Folder) end
            elseif typeof(makefolder) == "function" then
                pcall(function() makefolder(C.Folder) end)
            end
            writefile(C.Path, json)
        end)
        if not ok then
            Say("Falha ao escrever " .. C.Path .. ": " .. tostring(werr), "error")
            if not silent then Toast("Não deu para salvar a config", "error", 4) end
            return false
        end
        Say("Config salva em " .. C.Path .. " (" .. #json .. " bytes)", "ok")
        if not silent then Toast("Config salva", "ok", 2) end
        return true
    end

    C.Load = function(silent)
        if not C.Supported() then
            if not silent then
                Say("Não carreguei: executor sem API de arquivos (use IMPORTAR)", "error")
                Toast("Executor sem API de arquivos", "error", 4)
            else
                Log("Config em disco indisponível neste executor (use EXPORTAR/IMPORTAR)", "warn")
            end
            return false
        end
        local exists = false
        pcall(function() exists = isfile(C.Path) end)
        if not exists then
            if not silent then Say("Nenhuma config salva ainda em " .. C.Path, "warn") end
            return false
        end
        local ok, raw = pcall(function() return readfile(C.Path) end)
        if not ok or type(raw) ~= "string" then
            Say("Falha ao ler " .. C.Path, "error")
            return false
        end
        local d, derr = Decode(raw)
        if not d then
            Say("JSON inválido em " .. C.Path .. ": " .. tostring(derr), "error")
            return false
        end
        local okR = pcall(C.Restore, d)
        if not okR then
            Say("Config lida, mas falhou ao aplicar", "error")
            return false
        end
        Say("Config carregada de " .. C.Path, "ok")
        if not silent then Toast("Config carregada", "ok", 2) end

        if SET.SitOnLoad and C.LastSituation and V8.Sit then
            pcall(V8.Sit.Apply, C.LastSituation)
        end
        return true
    end

    C.Reset = function()
        local removed = false
        if C.Supported() then
            pcall(function()
                if isfile(C.Path) and typeof(delfile) == "function" then
                    delfile(C.Path)
                    removed = true
                end
            end)
        end
        if V8.UI and V8.UI.restore then pcall(V8.UI.restore) end
        Say(removed and ("Config apagada (" .. C.Path .. ") e padrões restaurados")
            or "Padrões restaurados (não havia arquivo salvo)", "action")
        Toast("Configurações resetadas", "warn", 3)
        return true
    end

    C.Export = function()
        local json = Encode(C.Snapshot())
        if not json then
            Say("Falha ao gerar o JSON", "error")
            return false
        end
        if typeof(setclipboard) == "function" then
            local ok = pcall(function() setclipboard(json) end)
            if ok then
                Say("JSON da config copiado (" .. #json .. " bytes)", "ok")
                Toast("Config copiada", "ok", 2)
                return true
            end
        end
        Log("Sem setclipboard neste executor — o JSON vai para o console do Roblox", "warn")
        print("[HYGE] config:", json)
        Say("Sem clipboard: JSON impresso no console do Roblox (F9)", "warn")
        return false
    end

    C.Import = function(text)
        if type(text) ~= "string" or text:match("^%s*$") then
            Say("Cole o JSON no campo antes de importar", "warn")
            return false
        end
        if not Http then
            Say("HttpService indisponível — não consigo ler o JSON", "error")
            return false
        end
        local d, derr = Decode(text)
        if not d then
            Say("JSON inválido: " .. tostring(derr), "error")
            Toast("JSON inválido", "error", 3)
            return false
        end
        if not pcall(C.Restore, d) then
            Say("JSON lido, mas falhou ao aplicar", "error")
            return false
        end
        Say("Config importada do texto colado", "ok")
        Toast("Config importada", "ok", 2)
        return true
    end

    ----------------------------------------------------------------------------
    -- UI (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "CONFIGURAÇÃO EM DISCO", 6)
        SubLabel(card, "Arquivo: " .. C.Path .. "  —  salva keybinds, aparência, "
            .. "velocidades, opções de ESP, waypoints, emotes favoritos e a última situação.", -1)

        status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, 0, 0, 0)
        status.AutomaticSize = Enum.AutomaticSize.Y
        status.BackgroundTransparency = 1
        status.Text = C.Supported() and "Pronto — este executor suporta salvar em disco."
            or "Este executor NÃO expõe writefile/readfile: salvar e carregar ficam "
               .. "indisponíveis. Use EXPORTAR/IMPORTAR pelo clipboard."
        status.TextColor3 = C.Supported() and THEME.Success or THEME.Warning
        status.Font = Enum.Font.Gotham
        status.TextSize = 11
        status.TextWrapped = true
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.LayoutOrder = 0
        status.Parent = card
        table.insert(Painted, { inst = status, prop = "TextColor3",
            key = C.Supported() and "Success" or "Warning" })

        local g1 = Grid(card, 3, 32)
        g1.LayoutOrder = 1

        local bSave = CreateButton(g1, "SALVAR AGORA", "Success", 32)
        bSave.LayoutOrder = 1
        bSave.MouseButton1Click:Connect(function() C.Save() end)

        local bLoad = CreateButton(g1, "CARREGAR", "Accent", 32)
        bLoad.LayoutOrder = 2
        bLoad.MouseButton1Click:Connect(function() C.Load() end)

        local bReset = CreateButton(g1, "RESETAR", "Danger", 32)
        bReset.LayoutOrder = 3
        bReset.MouseButton1Click:Connect(function()
            Confirm("Apagar " .. C.Path .. " e voltar tudo ao padrão?", function() C.Reset() end)
        end)

        CheckRow(card, "Salvar automaticamente ao fechar",
            "Grava a config no Unload (e ao descarregar pelo botão)",
            function() return SET.AutoSave end,
            function(v) SET.AutoSave = v end, 2)

        CheckRow(card, "Aplicar a última situação ao carregar",
            "No boot, reaplica a situação que estava ativa quando você salvou",
            function() return SET.SitOnLoad end,
            function(v) SET.SitOnLoad = v end, 3)

        local box = CreateInput(card, "cole aqui o JSON da config para importar", 32)
        box.LayoutOrder = 4
        box.Font = Enum.Font.Code
        box.TextSize = 11

        local g2 = Grid(card, 2, 30)
        g2.LayoutOrder = 5

        local bExp = CreateButton(g2, "EXPORTAR (COPIAR JSON)", "Accent2", 30)
        bExp.LayoutOrder = 1
        bExp.MouseButton1Click:Connect(function() C.Export() end)

        local bImp = CreateButton(g2, "IMPORTAR DO CAMPO", "Warning", 30)
        bImp.LayoutOrder = 2
        bImp.MouseButton1Click:Connect(function()
            local t = box.Text
            Confirm("Importar essa config? Ela sobrescreve o que está ativo agora.", function()
                if C.Import(t) then box.Text = "" end
            end)
        end)
    end
end
--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — BUSCA GLOBAL (Ctrl+K)
-- Overlay único que pesquisa situações, funções, jogadores, waypoints e
-- comandos. Enter executa o item selecionado; ↑/↓ navegam; Esc fecha.
-- Nenhum loop novo: só uma conexão de teclado (Conn.SearchKeys).
--------------------------------------------------------------------------------
do
    V8.Search = {}
    local S = V8.Search

    CONFIG.SearchKey  = Enum.KeyCode.K
    CONFIG.SearchCtrl = true

    local ROWS = 8
    local items, sel = {}, 1

    ----------------------------------------------------------------------------
    -- UI
    ----------------------------------------------------------------------------
    local Overlay = Instance.new("Frame")
    Overlay.Name = "Search"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Visible = false
    Overlay.ZIndex = 50
    Overlay.Parent = Gui

    local dim = Instance.new("TextButton")   -- clique fora fecha
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundTransparency = 1
    dim.Text = ""
    dim.AutoButtonColor = false
    dim.ZIndex = 50
    dim.Parent = Overlay

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0)
    box.Position = UDim2.new(0.5, 0, 0, 90)
    box.Size = UDim2.new(0, 560, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y
    box.BackgroundColor3 = THEME.Card
    box.BorderSizePixel = 0
    box.ZIndex = 51
    box.Parent = Overlay
    Paint(box, "BackgroundColor3", "Card")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 13)
    local bst = Instance.new("UIStroke", box)
    bst.Transparency = 0.25
    Paint(bst, "Color", "Accent")

    local pad = Instance.new("UIPadding", box)
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local layout = Instance.new("UIListLayout", box)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local input = CreateInput(box, "buscar situação, função, jogador, waypoint, comando...", 36)
    input.LayoutOrder = 0
    input.ZIndex = 52
    input.TextSize = 14

    local hintTop = Instance.new("TextLabel")
    hintTop.Size = UDim2.new(1, 0, 0, 13)
    hintTop.BackgroundTransparency = 1
    hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha"
    hintTop.TextColor3 = THEME.Dim
    hintTop.Font = Enum.Font.Gotham
    hintTop.TextSize = 10
    hintTop.TextXAlignment = Enum.TextXAlignment.Left
    hintTop.LayoutOrder = 1
    hintTop.ZIndex = 52
    hintTop.Parent = box
    table.insert(Painted, { inst = hintTop, prop = "TextColor3", key = "Dim" })

    local rows = {}
    for i = 1, ROWS do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = THEME.Btn
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = 1 + i
        b.Visible = false
        b.ZIndex = 52
        b.Parent = box
        Paint(b, "BackgroundColor3", "Btn")
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

        local kind = Instance.new("TextLabel")
        kind.Size = UDim2.new(0, 74, 1, 0)
        kind.Position = UDim2.new(0, 8, 0, 0)
        kind.BackgroundTransparency = 1
        kind.Text = ""
        kind.TextColor3 = THEME.Accent2
        kind.Font = Enum.Font.GothamBold
        kind.TextSize = 9
        kind.TextXAlignment = Enum.TextXAlignment.Left
        kind.ZIndex = 53
        kind.Parent = b
        table.insert(Painted, { inst = kind, prop = "TextColor3", key = "Accent2" })

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -230, 1, 0)
        label.Position = UDim2.new(0, 86, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = ""
        label.TextColor3 = THEME.Text
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 53
        label.Parent = b
        Paint(label, "TextColor3", "Text")

        local hint = Instance.new("TextLabel")
        hint.AnchorPoint = Vector2.new(1, 0)
        hint.Size = UDim2.new(0, 200, 1, 0)
        hint.Position = UDim2.new(1, -8, 0, 0)
        hint.BackgroundTransparency = 1
        hint.Text = ""
        hint.TextColor3 = THEME.Dim
        hint.Font = Enum.Font.Gotham
        hint.TextSize = 10
        hint.TextXAlignment = Enum.TextXAlignment.Right
        hint.TextTruncate = Enum.TextTruncate.AtEnd
        hint.ZIndex = 53
        hint.Parent = b
        table.insert(Painted, { inst = hint, prop = "TextColor3", key = "Dim" })

        rows[i] = { btn = b, kind = kind, label = label, hint = hint }
        b.MouseButton1Click:Connect(function()
            sel = i
            S.Run()
        end)
    end

    local empty = Instance.new("TextLabel")
    empty.Size = UDim2.new(1, 0, 0, 26)
    empty.BackgroundTransparency = 1
    empty.Text = "nada encontrado"
    empty.TextColor3 = THEME.Dim
    empty.Font = Enum.Font.Gotham
    empty.TextSize = 12
    empty.TextXAlignment = Enum.TextXAlignment.Left
    empty.LayoutOrder = 40
    empty.Visible = false
    empty.ZIndex = 52
    empty.Parent = box
    table.insert(Painted, { inst = empty, prop = "TextColor3", key = "Dim" })

    ----------------------------------------------------------------------------
    -- coleta dos resultados
    ----------------------------------------------------------------------------
    local function Collect(q)
        local out = {}
        local function add(kind, label, hint, run)
            local score
            local low = tostring(label):lower()
            if q == "" then
                score = 2
            elseif low:sub(1, #q) == q then
                score = 0
            elseif low:find(q, 1, true) then
                score = 1
            elseif kind:find(q, 1, true) then
                score = 3
            end
            if score then
                table.insert(out, { kind = kind, label = label, hint = hint or "",
                                    run = run, score = score, i = #out })
            end
        end

        -- v8.0: seções do dock e suas sub-abas (Visual, Servidor e Moderação
        -- ficam "dentro" de outra seção — a busca acha direto)
        if V8.Dock and V8.Dock.Sections then
            for _, s in ipairs(V8.Dock.Sections) do
                for _, t in ipairs(s.tabs) do
                    local tabName = t[1]
                    local label = (#s.tabs > 1) and (s.label .. " › " .. t[2]) or s.label
                    add("aba", label, "abrir", function()
                        ShowTab(tabName)
                        if V8.IsOpen and not V8.IsOpen() and V8.SetOpen then V8.SetOpen(true) end
                    end)
                end
            end
        end

        if V8.Sit then
            for _, n in ipairs(V8.Sit.Order) do
                local d = V8.Sit.Defs[n]
                add("situação", n, (d and d.desc or "")
                    .. (V8.Sit.Keys[n] and ("   [" .. KeyName(V8.Sit.Keys[n]) .. "]") or ""),
                    function() V8.Sit.Apply(n) end)
            end
        end

        for _, id in ipairs(ToggleOrder) do
            local t = Toggles[id]
            add("função", t.label or id,
                (IsOn(id) and "ligado" or "desligado")
                .. (Keybinds[id] and ("   [" .. KeyName(Keybinds[id]) .. "]") or ""),
                function() Flip(id) end)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            local nm = p.Name
            add("jogador", nm, "selecionar e abrir Players", function()
                if SelectPlayer then SelectPlayer(p) end
                ShowTab("Players")
            end)
        end

        for idx, w in ipairs(State.Waypoints) do
            add("waypoint", w.name or ("WP " .. idx), "teleportar", function()
                local wp = State.Waypoints[idx]
                if wp then
                    TeleportTo(wp.cframe)
                    Log("TP -> " .. (wp.name or idx), "ok")
                end
            end)
        end

        if V8.CmdNames then
            for _, n in ipairs(V8.CmdNames) do
                local c = V8.Commands and V8.Commands[n]
                add("comando", n, c and c.usage or "", function()
                    if c and c.usage and c.usage:find("<") then
                        if V8.OpenCmdBar then V8.OpenCmdBar(n .. " ") end
                    elseif V8.RunCommand then
                        V8.RunCommand(n)
                    end
                end)
            end
        end

        table.sort(out, function(a, b)
            if a.score ~= b.score then return a.score < b.score end
            return a.i < b.i
        end)
        return out
    end

    local function Paint2(i)
        local r = rows[i]
        local active = (i == sel)
        r.btn.BackgroundTransparency = active and 0 or 1
        r.label.TextColor3 = active and THEME.Accent or THEME.Text
    end

    local function Render()
        for i = 1, ROWS do
            local it = items[i]
            local r = rows[i]
            if it then
                r.btn.Visible = true
                r.kind.Text = it.kind:upper()
                r.label.Text = it.label
                r.hint.Text = it.hint
                Paint2(i)
            else
                r.btn.Visible = false
            end
        end
        empty.Visible = (#items == 0)
        empty.Text = (#items == 0) and "nada encontrado" or ""
        if #items > ROWS then
            hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha   •   "
                .. #items .. " resultados (mostrando " .. ROWS .. ")"
        else
            hintTop.Text = "↑ ↓ navega   •   Enter executa   •   Esc fecha"
        end
    end

    local function Refresh()
        local q = (input.Text or ""):lower():gsub("^%s+", "")
        items = Collect(q)
        sel = 1
        Render()
    end

    local function Move(d)
        if #items == 0 then return end
        sel = sel + d
        local cap = math.min(#items, ROWS)
        if sel < 1 then sel = cap end
        if sel > cap then sel = 1 end
        for i = 1, ROWS do
            if rows[i].btn.Visible then Paint2(i) end
        end
    end

    ----------------------------------------------------------------------------
    -- abrir / fechar / executar
    ----------------------------------------------------------------------------
    S.Close = function()
        Overlay.Visible = false
        pcall(function() input:ReleaseFocus() end)
    end

    S.Open = function()
        Overlay.Visible = true
        input.Text = ""
        Refresh()
        pcall(function() input:CaptureFocus() end)
    end

    S.Run = function()
        local it = items[sel]
        if not it then
            S.Close()
            return
        end
        S.Close()
        local ok, err = pcall(it.run)
        if not ok then Log("busca: " .. tostring(err), "error") end
    end

    dim.MouseButton1Click:Connect(function() S.Close() end)

    input:GetPropertyChangedSignal("Text"):Connect(function()
        if Overlay.Visible then pcall(Refresh) end
    end)

    input.FocusLost:Connect(function(enter)
        if not Overlay.Visible then return end
        if enter then S.Run() end
    end)

    Conn.SearchKeys = UserInputService.InputBegan:Connect(function(input2)
        if not Overlay.Visible then return end
        if input2.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local kc = input2.KeyCode
        if kc == Enum.KeyCode.Escape then
            S.Close()
        elseif kc == Enum.KeyCode.Down then
            Move(1)
        elseif kc == Enum.KeyCode.Up then
            Move(-1)
        end
    end)

    -- chamado pelo handler global de teclas (90_runtime/03_input.lua)
    S.HandleKey = function(input3)
        if input3.KeyCode ~= CONFIG.SearchKey then return false end
        if CONFIG.SearchCtrl then
            local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if not ctrl then return false end
        end
        if Overlay.Visible then S.Close() else S.Open() end
        return true
    end

    ----------------------------------------------------------------------------
    -- UI de configuração (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "BUSCA GLOBAL", 7)
        SubLabel(card, "Abre um campo que pesquisa situações, funções, jogadores, "
            .. "waypoints e comandos. Padrão: Ctrl+K.", -1)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundTransparency = 1
        row.LayoutOrder = 1
        row.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -110, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "Tecla da busca"
        lbl.TextColor3 = THEME.Text
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        Paint(lbl, "TextColor3", "Text")

        local btn = Instance.new("TextButton")
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
        btn.Size = UDim2.new(0, 96, 0, 26)
        btn.BackgroundColor3 = THEME.Btn
        btn.Text = KeyName(CONFIG.SearchKey)
        btn.TextColor3 = THEME.Accent2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = row
        Paint(btn, "BackgroundColor3", "Btn")
        Paint(btn, "TextColor3", "Accent2")
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local st = Instance.new("UIStroke", btn)
        st.Transparency = 0.6
        Paint(st, "Color", "Accent")

        btn.MouseButton1Click:Connect(function()
            Drop("SearchCapture")
            capturing = "search"
            btn.Text = "aperte..."
            Toast("Aperte a tecla da busca global", nil, 3)
            Conn.SearchCapture = UserInputService.InputBegan:Connect(function(input4)
                if capturing ~= "search" then return end
                if input4.UserInputType ~= Enum.UserInputType.Keyboard then return end
                local kc = input4.KeyCode
                if kc == Enum.KeyCode.Unknown then return end
                if kc == Enum.KeyCode.LeftControl or kc == Enum.KeyCode.RightControl then return end
                Drop("SearchCapture")
                capturing = nil
                if kc == CONFIG.PanelKey or kc == CONFIG.ConsoleKey then
                    Toast("[" .. KeyName(kc) .. "] já é do painel", "warn")
                else
                    CONFIG.SearchKey = kc
                    Log("Busca global = "
                        .. (CONFIG.SearchCtrl and "Ctrl+" or "") .. KeyName(kc), "ok")
                end
                btn.Text = KeyName(CONFIG.SearchKey)
            end)
        end)

        CheckRow(card, "Exigir Ctrl junto", "Desligue para abrir com a tecla sozinha",
            function() return CONFIG.SearchCtrl end,
            function(v) CONFIG.SearchCtrl = v end, 2)

        local open = CreateButton(card, "ABRIR A BUSCA AGORA", "Accent", 32)
        open.LayoutOrder = 3
        open.MouseButton1Click:Connect(function() S.Open() end)
    end
end
--------------------------------------------------------------------------------
-- NAVEGAÇÃO, COMANDOS, ORB, SCHEDULER, RESPAWN, UNLOAD, BOOT
--------------------------------------------------------------------------------
local CmdBar, CmdInput, ToggleCmdBar, RunCommand  -- forward
local Orb, SetOpen, SetMinimized, isOpen          -- forward

--------------------------------------------------------------------------------
-- STATUS GERAL (topbar + dashboard + abas)
--------------------------------------------------------------------------------
RefreshStatus = function()
    if RefreshQuick then pcall(RefreshQuick) end
    if Tiles and Tiles.remotes then
        local have, total = V8.RemoteStatus()
        Tiles.remotes.Text = have .. "/" .. total
    end
end

--------------------------------------------------------------------------------
-- NAVEGAÇÃO (sidebar — só aparece com o dock desligado)
-- v8.0: mesma ordem das seções do dock, sub-abas logo depois da principal
--------------------------------------------------------------------------------
AddNav("Home", 1)
AddNav("Server", 2)
AddNav("Movement", 3)
AddNav("Visuals", 4)
AddNav("Shop", 5)
AddNav("Scripts", 6)
AddNav("Emotes", 7)
AddNav("Players", 8)
AddNav("Moderation", 9)
AddNav("Settings", 10)
AddNav("Chat", 11)

--------------------------------------------------------------------------------
-- BARRA DE COMANDOS (histórico, autocomplete, aliases)
--------------------------------------------------------------------------------
do
    CmdBar = Instance.new("Frame")
    CmdBar.Name = "CommandBar"
    CmdBar.AnchorPoint = Vector2.new(0.5, 0)
    CmdBar.Position = UDim2.new(0.5, 0, 0, 90)
    CmdBar.Size = UDim2.new(0, 520, 0, 44)
    CmdBar.BackgroundColor3 = THEME.Card
    CmdBar.BorderSizePixel = 0
    CmdBar.Visible = false
    CmdBar.Parent = Gui
    Paint(CmdBar, "BackgroundColor3", "Card")
    Instance.new("UICorner", CmdBar).CornerRadius = UDim.new(0, 11)
    local cmdStroke = Instance.new("UIStroke", CmdBar)
    cmdStroke.Transparency = 0.3
    Paint(cmdStroke, "Color", "Accent")

    CmdInput = CreateInput(CmdBar, "fly | speed 80 | tp joao | preset Visual | help", 32)
    CmdInput.Size = UDim2.new(1, -24, 0, 32)
    CmdInput.Position = UDim2.new(0, 12, 0, 6)
    CmdInput.Font = Enum.Font.Code

    -- painel de sugestões (aparece abaixo da barra)
    local Hint = Instance.new("Frame")
    Hint.AnchorPoint = Vector2.new(0.5, 0)
    Hint.Position = UDim2.new(0.5, 0, 1, 6)
    Hint.Size = UDim2.new(1, 0, 0, 0)
    Hint.AutomaticSize = Enum.AutomaticSize.Y
    Hint.BackgroundColor3 = THEME.Console
    Hint.BorderSizePixel = 0
    Hint.Visible = false
    Hint.Parent = CmdBar
    Paint(Hint, "BackgroundColor3", "Console")
    Instance.new("UICorner", Hint).CornerRadius = UDim.new(0, 9)
    local hintPad = Instance.new("UIPadding", Hint)
    hintPad.PaddingTop = UDim.new(0, 6)
    hintPad.PaddingBottom = UDim.new(0, 6)
    hintPad.PaddingLeft = UDim.new(0, 10)
    hintPad.PaddingRight = UDim.new(0, 10)
    local hintLayout = Instance.new("UIListLayout", Hint)
    hintLayout.Padding = UDim.new(0, 2)
    hintLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local Commands, CmdNames = {}, {}
    local hintLines, matches = {}, {}
    local histPos = 0

    local function DefCmd(name, usage, help, run, alias)
        Commands[name] = { name = name, usage = usage, help = help, run = run }
        table.insert(CmdNames, name)
        if alias then Commands[alias] = Commands[name] end
    end

    local function HintLine(order)
        local l = hintLines[order]
        if l then return l end
        l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 15)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = THEME.Dim
        l.LayoutOrder = order
        l.Parent = Hint
        table.insert(Painted, { inst = l, prop = "TextColor3", key = "Dim" })
        hintLines[order] = l
        return l
    end

    local function ShowHints()
        local text = CmdInput.Text or ""
        local first = text:match("^%s*(%S*)") or ""
        matches = {}
        if first ~= "" and not text:match("^%s*%S+%s") then
            for _, n in ipairs(CmdNames) do
                if n:sub(1, #first):lower() == first:lower() then table.insert(matches, n) end
            end
            table.sort(matches)
        elseif first ~= "" and Commands[first:lower()] then
            matches = { Commands[first:lower()].name }
        end
        for _, l in ipairs(hintLines) do l.Visible = false end
        local shown = 0
        for i = 1, math.min(#matches, 6) do
            local c = Commands[matches[i]:lower()]
            local l = HintLine(i)
            l.Text = "  " .. c.usage .. "   —   " .. c.help
            l.Visible = true
            shown = shown + 1
        end
        if #matches > 6 then
            local l = HintLine(7)
            l.Text = "  ... e mais " .. (#matches - 6) .. " (digite 'help')"
            l.Visible = true
            shown = shown + 1
        end
        Hint.Visible = shown > 0
    end

    local function Complete()
        if #matches == 0 then return end
        CmdInput.Text = matches[1] .. " "
        CmdInput.CursorPosition = #CmdInput.Text + 1
        ShowHints()
    end

    local function Recall(dir)
        local hist = State.CmdHistory
        if #hist == 0 then return end
        histPos = math.clamp(histPos + dir, 0, #hist)
        if histPos == 0 then
            CmdInput.Text = ""
        else
            CmdInput.Text = hist[#hist - histPos + 1] or ""
        end
        CmdInput.CursorPosition = #CmdInput.Text + 1
    end

    RunCommand = function(text)
        text = tostring(text or "")
        if text:match("^%s*$") then return end
        table.insert(State.CmdHistory, text)
        while #State.CmdHistory > 25 do table.remove(State.CmdHistory, 1) end
        histPos = 0

        local args = {}
        for word in text:gmatch("%S+") do table.insert(args, word) end
        local name = table.remove(args, 1):lower()
        local cmd = Commands[name]
        if not cmd then
            local near
            for _, n in ipairs(CmdNames) do
                if n:sub(1, #name) == name then near = n break end
            end
            Log("Comando desconhecido: " .. name
                .. (near and (" — você quis dizer '" .. near .. "'?") or " (use 'help')"), "error")
            Toast("Comando desconhecido: " .. name, "error")
            return
        end
        local ok, err = pcall(cmd.run, args)
        if not ok then
            Log("Erro em '" .. name .. "': " .. tostring(err), "error")
            Toast("Erro no comando " .. name, "error")
        end
    end

    ----------------------------------------------------------------------------
    -- um comando por toggle
    ----------------------------------------------------------------------------
    for _, id in ipairs(ToggleOrder) do
        DefCmd(id, id .. " [on|off]", Toggles[id].label or id, function(args)
            local a = (args[1] or ""):lower()
            if a == "on" then SetToggle(id, true)
            elseif a == "off" then SetToggle(id, false)
            else Flip(id) end
        end)
    end

    ----------------------------------------------------------------------------
    -- comandos gerais
    ----------------------------------------------------------------------------
    DefCmd("speed", "speed <n>", "define WalkSpeed", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: speed <numero>", "warn") return end
        State.WalkSpeed = v
        local h = Hum()
        if h then h.WalkSpeed = v end
        if WalkSlider then WalkSlider(v) end
        Log("WalkSpeed = " .. v, "ok")
    end, "ws")

    DefCmd("flyspeed", "flyspeed <n>", "velocidade do fly", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: flyspeed <numero>", "warn") return end
        State.FlySpeed = v
        if FlySlider then FlySlider(v) end
        Log("FlySpeed = " .. v, "ok")
    end, "fs")

    DefCmd("jp", "jp <n>", "define JumpPower", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: jp <numero>", "warn") return end
        State.JumpPower = v
        local h = Hum()
        if h then h.UseJumpPower = true h.JumpPower = v end
        if JumpSlider then JumpSlider(v) end
        Log("JumpPower = " .. v, "ok")
    end)

    DefCmd("tp", "tp <jogador>", "teleporta você até o jogador", function(args)
        local p = FindPlayer(args[1])
        if p then Goto(p) else Log("Jogador não encontrado: " .. tostring(args[1]), "warn") end
    end)

    DefCmd("bring", "bring <jogador>", "puxa o jogador (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then Bring(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("select", "select <jogador>", "seleciona o alvo do painel", function(args)
        local p = FindPlayer(args[1])
        if p then SelectPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("spectate", "spectate [jogador]", "assiste o jogador (sem nome: sai)", function(args)
        local p = FindPlayer(args[1])
        if p then StartSpectate(p) else StopSpectate() end
        RefreshStatus()
    end, "spec")

    DefCmd("freeze", "freeze <jogador>", "congela (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FreezePlayer(p, true) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("unfreeze", "unfreeze <jogador>", "descongela (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FreezePlayer(p, false) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("kick", "kick <jogador>", "expulsa (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then KickPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    ----------------------------------------------------------------------------
    -- TROLL (v8.0) — todas dependem de Remote no servidor, exceto fakemsg
    ----------------------------------------------------------------------------
    DefCmd("fling", "fling <jogador>", "impulso forte no alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FlingPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("spin", "spin <jogador> [on|off]", "rotação contínua no alvo (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local a = (args[2] or ""):lower()
            local on
            if a == "on" then on = true
            elseif a == "off" then on = false
            else on = not TrollState.Spin[p.UserId] end
            SpinPlayer(p, on)
        end)

    DefCmd("trip", "trip <jogador>", "derruba o alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then TripPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("launch", "launch <jogador>", "lança o alvo bem alto (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then LaunchPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    -- nota: "sit" já é o comando de Situações (v8.0) — usamos "forcesit" pro troll
    DefCmd("forcesit", "forcesit <jogador>", "senta o alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then SitPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("scale", "scale <jogador> <tiny|normal|giant>", "muda o tamanho do alvo (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local mode = (args[2] or ""):lower()
            if mode ~= "tiny" and mode ~= "normal" and mode ~= "giant" then
                Log("uso: scale <jogador> <tiny|normal|giant>", "warn")
                return
            end
            ScalePlayer(p, mode)
        end)

    DefCmd("balloon", "balloon <jogador> [on|off]", "empurrão suave pra cima (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local a = (args[2] or ""):lower()
            local on
            if a == "on" then on = true
            elseif a == "off" then on = false
            else on = not TrollState.Balloon[p.UserId] end
            BalloonPlayer(p, on)
        end)

    DefCmd("fakemsg", "fakemsg <jogador> <kick|ban>", "mensagem de sistema falsa, 100% local",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local kind = (args[2] or "kick"):lower()
            FakeMessage(p, kind)
        end)

    DefCmd("heal", "heal", "cura seu personagem", function()
        local h = Hum()
        if h then h.Health = h.MaxHealth Log("Curado", "ok") else Log("Sem humanoid", "warn") end
    end)

    DefCmd("respawn", "respawn", "força respawn", function()
        local h = Hum()
        if h then h.Health = 0 Log("Respawn forçado", "action") end
    end, "re")

    DefCmd("emote", "emote <id|favorito|stop>", "toca animação no seu personagem",
        function(args)
            local a = args[1]
            if not a or a == "" then
                Log("uso: emote <id> | emote <nome favorito> | emote stop", "warn")
                return
            end
            if a:lower() == "stop" or a:lower() == "off" then
                Emote.Stop()
                return
            end
            -- procura nos favoritos antes de tratar como ID
            local q = a:lower()
            for _, e in ipairs(State.Emotes) do
                if e.name:lower() == q or e.name:lower():find(q, 1, true) == 1 then
                    Emote.Play(e.id, e.name)
                    return
                end
            end
            Emote.Play(a)
        end, "e")

    DefCmd("announce", "announce <mensagem>", "anúncio global (precisa de Remote)", function(args)
        local msg = table.concat(args, " ")
        if msg == "" then Log("uso: announce <mensagem>", "warn") return end
        Announce(msg)
    end)

    DefCmd("wp", "wp save|tp|list", "waypoints", function(args)
        local sub = (args[1] or ""):lower()
        if sub == "save" then
            local r = Root()
            if not r then Log("Sem personagem", "warn") return end
            table.insert(State.Waypoints, { name = "WP " .. (#State.Waypoints + 1), cframe = r.CFrame })
            if RenderWaypoints then RenderWaypoints() end
            Log("Waypoint salvo", "ok")
        elseif sub == "tp" then
            local n = tonumber(args[2])
            local wp = n and State.Waypoints[n] or State.Waypoints[#State.Waypoints]
            if wp then TeleportTo(wp.cframe) Log("TP -> " .. wp.name, "ok")
            else Log("Sem waypoints", "warn") end
        elseif sub == "list" then
            if #State.Waypoints == 0 then Log("Sem waypoints", "warn") return end
            for i, w in ipairs(State.Waypoints) do
                Log(i .. ") " .. w.name .. string.format("  %d, %d, %d",
                    w.cframe.X, w.cframe.Y, w.cframe.Z))
            end
        else
            Log("uso: wp save | wp tp [n] | wp list", "warn")
        end
    end)

    DefCmd("theme", "theme <Roxo|Ciano|Verde|Vermelho|Azul>", "troca a paleta", function(args)
        local n = args[1]
        if not n then Log("uso: theme Roxo|Ciano|Verde|Vermelho|Azul", "warn") return end
        n = n:sub(1, 1):upper() .. n:sub(2):lower()
        if not PALETTES[n] then Log("Tema inexistente: " .. n, "warn") return end
        if ApplyTheme then ApplyTheme(n) end
    end)

    DefCmd("preset", "preset <Default|Admin|Visual|Movement|Minimal>", "aplica um preset",
        function(args)
            local n = args[1]
            if not n then Log("uso: preset Default|Admin|Visual|Movement|Minimal", "warn") return end
            n = n:sub(1, 1):upper() .. n:sub(2):lower()
            if ApplyPreset then ApplyPreset(n) end
        end)

    DefCmd("status", "status", "resumo do estado atual", function()
        local on = {}
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then table.insert(on, id) end
        end
        Log("Ligado: " .. (#on > 0 and table.concat(on, ", ") or "nada"))
        Log(string.format("FPS %d  •  WalkSpeed %d  •  FlySpeed %d  •  Waypoints %d",
            State.Fps, State.WalkSpeed, State.FlySpeed, #State.Waypoints))
        Log("Spectate: " .. (State.Spectating and State.SpectateTarget
            and State.SpectateTarget.Name or "off"))
        RefreshStatus()
    end)

    DefCmd("players", "players", "lista os jogadores online", function()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
        table.sort(names)
        Log(#names .. " online: " .. table.concat(names, ", "))
    end)

    DefCmd("server", "server", "info do servidor e Remotes", function()
        Log("PlaceId " .. game.PlaceId .. "  •  JobId "
            .. (game.JobId ~= "" and game.JobId or "estúdio"))
        local have, total, miss = V8.RemoteStatus()
        if #miss == 0 then Log("Todos os " .. total .. " Remotes presentes", "ok")
        else Log("Remotes " .. have .. "/" .. total .. " — ausentes: "
            .. table.concat(miss, ", "), "warn") end
        if UpdateServerInfo then UpdateServerInfo() end
    end)

    DefCmd("center", "center", "traz a janela de volta para o centro da tela", function()
        if V8.Win then V8.Win.Center() end
    end)

    DefCmd("clear", "clear", "limpa o console", function()
        if ClearLog then ClearLog() end
        Log("Log limpo")
    end, "cls")

    DefCmd("reset", "reset", "volta às configurações padrão", function()
        if ApplyPreset then ApplyPreset("Default") end
        Log("Configurações restauradas", "ok")
    end)

    DefCmd("alloff", "alloff", "desliga todas as funções", function()
        for _, id in ipairs(ToggleOrder) do SetToggle(id, false, true) end
        StopSpectate()
        RefreshStatus()
        Log("Tudo desligado", "warn")
        Toast("Tudo desligado", "warn")
    end, "off")

    DefCmd("unload", "unload", "descarrega o painel", function()
        if Unload then Unload() end
    end)

    DefCmd("help", "help [comando]", "lista comandos ou explica um", function(args)
        if args[1] then
            local c = Commands[args[1]:lower()]
            if c then Log(c.usage .. "   —   " .. c.help, "ok")
            else Log("Sem ajuda para: " .. args[1], "warn") end
            return
        end
        local sorted = {}
        for _, n in ipairs(CmdNames) do table.insert(sorted, n) end
        table.sort(sorted)
        Log(#sorted .. " comandos: " .. table.concat(sorted, ", "))
        Log("Dica: Tab completa, ↑/↓ repete o histórico, Esc fecha.")
    end, "?")

    ----------------------------------------------------------------------------
    -- v8.0: situações, busca global e configuração em disco
    ----------------------------------------------------------------------------
    DefCmd("sit", "sit <situação>", "aplica uma situação", function(args)
        if not V8.Sit then Log("Situações indisponíveis", "error") return end
        local q = table.concat(args, " ")
        if q == "" then
            Log("Situações: " .. table.concat(V8.Sit.Order, ", "))
            return
        end
        local name = V8.Sit.Find(q)
        if not name then Log("Situação não encontrada: " .. q, "warn") return end
        V8.Sit.Apply(name)
    end, "modo")

    DefCmd("search", "search", "abre a busca global", function()
        if V8.Search then V8.Search.Open() else Log("Busca indisponível", "error") end
    end, "s")

    DefCmd("save", "save", "salva a configuração em disco", function()
        if V8.Cfg then V8.Cfg.Save() else Log("Persistência indisponível", "error") end
    end)

    DefCmd("loadcfg", "loadcfg", "carrega a configuração do disco", function()
        if V8.Cfg then V8.Cfg.Load() else Log("Persistência indisponível", "error") end
    end)

    ----------------------------------------------------------------------------
    -- abrir / fechar a barra
    ----------------------------------------------------------------------------
    ToggleCmdBar = function(show)
        CmdBar.Visible = show
        if show then
            CmdInput.Text = ""
            histPos = 0
            Hint.Visible = false
            CmdInput:CaptureFocus()
        else
            Hint.Visible = false
            pcall(function() CmdInput:ReleaseFocus() end)
        end
    end

    -- v8.0: hooks para a busca global (o do..end esconde os locais daqui)
    V8.RunCommand = RunCommand
    V8.Commands   = Commands
    V8.CmdNames   = CmdNames
    V8.OpenCmdBar = function(text)
        ToggleCmdBar(true)
        CmdInput.Text = text or ""
        CmdInput.CursorPosition = #CmdInput.Text + 1
    end

    CmdInput:GetPropertyChangedSignal("Text"):Connect(function()
        if CmdBar.Visible then pcall(ShowHints) end
    end)

    CmdInput.FocusLost:Connect(function(enter)
        local text = CmdInput.Text
        CmdInput.Text = ""
        ToggleCmdBar(false)
        if enter then RunCommand(text) end
    end)

    -- Tab completa, ↑/↓ percorre o histórico
    Conn.CmdKeys = UserInputService.InputBegan:Connect(function(input)
        if not CmdBar.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            pcall(Complete)
        elseif input.KeyCode == Enum.KeyCode.Up then
            pcall(Recall, 1)
        elseif input.KeyCode == Enum.KeyCode.Down then
            pcall(Recall, -1)
        end
    end)
end

--------------------------------------------------------------------------------
-- ORB FLUTUANTE
--------------------------------------------------------------------------------
do
    Orb = Instance.new("TextButton")
    Orb.Name = "Orb"
    Orb.Size = UDim2.new(0, 46, 0, 46)
    Orb.Position = UDim2.new(0, 18, 0.5, -23)
    Orb.BackgroundColor3 = THEME.Accent
    Orb.Text = "H"
    Orb.TextColor3 = Color3.new(0, 0, 0)
    Orb.Font = Enum.Font.GothamBlack
    Orb.TextSize = 20
    Orb.AutoButtonColor = false
    Orb.Visible = false
    Orb.Parent = Gui
    if CONFIG.LogoId ~= "" then
        Orb.Text = ""
        local orbImg = Instance.new("ImageLabel")
        orbImg.Size = UDim2.new(1, -6, 1, -6)
        orbImg.Position = UDim2.new(0, 3, 0, 3)
        orbImg.BackgroundTransparency = 1
        orbImg.Image = CONFIG.LogoId
        orbImg.ScaleType = Enum.ScaleType.Fit
        orbImg.Parent = Orb
    end
    Paint(Orb, "BackgroundColor3", "Accent")
    Instance.new("UICorner", Orb).CornerRadius = UDim.new(1, 0)
    V8.Orb = Orb   -- o dock (que carrega antes) esconde/mostra a bolinha
end

--------------------------------------------------------------------------------
-- ABRIR / FECHAR / MINIMIZAR
--------------------------------------------------------------------------------
do
    isOpen = false

    SetOpen = function(open)
        isOpen = open
        if open then
            Window.Visible = true
            if SET.Animations then
                WindowScale.Scale = CONFIG.UiScale * 0.92
                TweenService:Create(WindowScale, TweenInfo.new(0.18, Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out), { Scale = CONFIG.UiScale }):Play()
            else
                WindowScale.Scale = CONFIG.UiScale
            end
            Orb.Visible = false
            RefreshStatus()
            if TabHooks[State.ActiveTab] then pcall(TabHooks[State.ActiveTab]) end
            if V8.Dock and V8.Dock.Sync then pcall(V8.Dock.Sync, State.ActiveTab) end
        else
            if SET.Animations then
                local t = TweenService:Create(WindowScale, TweenInfo.new(0.14),
                    { Scale = CONFIG.UiScale * 0.9 })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then Window.Visible = false end
                    WindowScale.Scale = CONFIG.UiScale
                end)
            else
                Window.Visible = false
            end
            -- v8.0: com o dock na tela a bolinha não é necessária
            Orb.Visible = (SET.Dock ~= true)
            if V8.Dock and V8.Dock.Sync then pcall(V8.Dock.Sync, State.ActiveTab) end
        end
    end

    -- v8.0: o dock carrega antes deste bloco e não enxerga os locais daqui
    V8.SetOpen = function(open) SetOpen(open) end
    V8.IsOpen = function() return isOpen end

    SetMinimized = function(min)
        State.Minimized = min
        Content.Visible = not min
        MinBtn.Text = min and "+" or "—"

        -- v8: as medidas vem do shell (nao ficam mais chumbadas aqui) e a
        -- sidebar so reaparece se ela for o modo de navegacao escolhido
        -- (o dock fica na tela e o console mora na aba Scripts: nenhum dos dois
        -- é escondido aqui — o Content inteiro some quando minimiza)
        if V8.Shell and V8.Shell.Layout then
            Sidebar.Visible = (not min) and (SET.Dock ~= true)
            pcall(V8.Shell.Layout)
            Anim(Window, 0.18, { Size = min
                and UDim2.new(0, V8.Shell.W, 0, V8.Shell.TopH)
                or  UDim2.new(0, V8.Shell.W, 0, V8.Shell.Hgt) })
            return
        end

        Sidebar.Visible = not min
        ConsoleFrame.Visible = not min
        Anim(Window, 0.18, {
            Size = min and UDim2.new(0, 920, 0, 56) or UDim2.new(0, 920, 0, 600) })
    end

    CloseBtn.MouseButton1Click:Connect(function() SetOpen(false) end)
    MinBtn.MouseButton1Click:Connect(function() SetMinimized(not State.Minimized) end)
    Orb.MouseButton1Click:Connect(function() SetOpen(true) end)
end

--------------------------------------------------------------------------------
-- DRAG (mouse + touch) da janela e do orb
--------------------------------------------------------------------------------
do
    ----------------------------------------------------------------------------
    -- v8.0: janela sempre alcançável + posição vai para a config (SET.WinPos)
    ----------------------------------------------------------------------------
    local KEEP_X, KEEP_Y = 120, 40   -- quanto da TopBar sempre fica na tela
    V8.Win = {}

    -- empurra a janela de volta se ela estiver (mesmo que parcialmente) perdida
    V8.Win.Clamp = function()
        local vp, p, s = Gui.AbsoluteSize, Window.AbsolutePosition, Window.AbsoluteSize
        if vp.X <= KEEP_X * 2 or vp.Y <= KEEP_Y * 2 then return end
        local nx = math.clamp(p.X, KEEP_X - s.X, vp.X - KEEP_X)
        local ny = math.clamp(p.Y, 0, vp.Y - KEEP_Y)
        if nx ~= p.X or ny ~= p.Y then
            local cur = Window.Position
            Window.Position = UDim2.new(cur.X.Scale, cur.X.Offset + (nx - p.X),
                cur.Y.Scale, cur.Y.Offset + (ny - p.Y))
        end
    end

    V8.Win.Save = function()
        local p = Window.Position
        SET.WinPos = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    end

    V8.Win.Restore = function(t)
        if type(t) ~= "table" then return end
        for i = 1, 4 do
            if type(t[i]) ~= "number" or t[i] ~= t[i] then return end   -- NaN/lixo
        end
        Window.Position = UDim2.new(t[1], t[2], t[3], t[4])
        task.defer(function() pcall(V8.Win.Clamp) end)   -- Absolute* só no próximo frame
    end

    V8.Win.Center = function()
        if V8.Shell and V8.Shell.HomePos then
            Window.Position = V8.Shell.HomePos()   -- com dock: logo acima dele
        else
            local w, h = Window.Size.X.Offset, Window.Size.Y.Offset
            Window.Position = UDim2.new(0.5, -w * 0.5, 0.5, -h * 0.5)
        end
        task.defer(function() pcall(V8.Win.Clamp) end)
        SET.WinPos = nil
        Log("Janela centralizada", "action")
    end

    -- resolução mudou (janela redimensionada, celular girou): reencaixa
    Conn.WinFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        pcall(V8.Win.Clamp)
    end)

    local dragging, dragStart, startPos, startAbs = false, nil, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            startAbs = Window.AbsolutePosition
        end
    end)
    Conn.Drag = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        -- conta feita na posição absoluta do início do arrasto (estável), não
        -- na AbsolutePosition atual (que só atualiza no próximo frame)
        local vp, size = Gui.AbsoluteSize, Window.AbsoluteSize
        if vp.X > KEEP_X * 2 and vp.Y > KEEP_Y * 2 then
            dx = math.clamp(startAbs.X + dx, KEEP_X - size.X, vp.X - KEEP_X) - startAbs.X
            dy = math.clamp(startAbs.Y + dy, 0, vp.Y - KEEP_Y) - startAbs.Y
        end
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx,
            startPos.Y.Scale, startPos.Y.Offset + dy)
    end)
    Conn.DragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then pcall(V8.Win.Save) end
            dragging = false
        end
    end)

    local orbDrag, orbStart, orbPos = false, nil, nil
    Orb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            orbDrag = true
            orbStart = input.Position
            orbPos = Orb.Position
        end
    end)
    Conn.OrbDrag = UserInputService.InputChanged:Connect(function(input)
        if not orbDrag then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - orbStart
        if delta.Magnitude < 4 then return end
        Orb.Position = UDim2.new(orbPos.X.Scale, orbPos.X.Offset + delta.X,
            orbPos.Y.Scale, orbPos.Y.Offset + delta.Y)
    end)
    Conn.OrbDragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            orbDrag = false
        end
    end)
end

--------------------------------------------------------------------------------
-- INPUT GLOBAL (teclas)
--------------------------------------------------------------------------------
-- v8.0: teclas que cada modo usa para se mover. Com o modo ligado, um atalho
-- nessa tecla NÃO dispara (antes: subir com E no freecam/drone ligava o ESP).
-- O atalho do próprio modo continua valendo (ex.: G desliga o drone).
V8.ModeKeys = {
    freecam = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.LeftShift },
    drone   = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.LeftShift,
                Enum.KeyCode.LeftControl },
    fly     = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },
}
V8.KeyWarned = {}

-- devolve o modo que está usando a tecla (ou nil). 'self' = toggle que o
-- atalho dispararia: ele nunca bloqueia a si mesmo.
V8.KeyBusy = function(kc, selfId)
    for mode, keys in pairs(V8.ModeKeys) do
        if mode ~= selfId and IsOn(mode) then
            for _, k in ipairs(keys) do
                if k == kc then return mode end
            end
        end
    end
    return nil
end

Conn.Input = UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if capturing then return end   -- está capturando um keybind na aba Settings

    if input.KeyCode == Enum.KeyCode.Escape and CmdBar.Visible then
        ToggleCmdBar(false)
        return
    end
    if gpe then return end

    if input.KeyCode == CONFIG.PanelKey then
        SetOpen(not isOpen)
        return
    end
    if input.KeyCode == CONFIG.ConsoleKey then
        ToggleCmdBar(not CmdBar.Visible)
        return
    end
    -- v8.0: busca global (Ctrl+K) e atalhos das situações (Keypad 1-6)
    if V8.Search and V8.Search.HandleKey(input) then return end
    if V8.Sit and V8.Sit.HandleKey(input) then return end

    for id, kc in pairs(Keybinds) do
        if kc == input.KeyCode then
            local busy = V8.KeyBusy(kc, id)
            if busy then
                -- avisa uma vez por combinação (sem spam a cada tecla)
                local tag = busy .. ":" .. kc.Name
                if not V8.KeyWarned[tag] then
                    V8.KeyWarned[tag] = true
                    local mode = Toggles[busy] and Toggles[busy].label or busy
                    local who = Toggles[id] and Toggles[id].label or id
                    Log("[" .. KeyName(kc) .. "] ignorada: o " .. mode .. " usa essa tecla "
                        .. "para se mover (o atalho de " .. who .. " volta ao desligar)", "warn")
                end
                return
            end
            Flip(id)
            return
        end
    end
end)

--------------------------------------------------------------------------------
-- SCHEDULER ÚNICO (um Heartbeat para todo o painel)
--------------------------------------------------------------------------------
do
    local jobs = {}
    local function Every(interval, fn)
        table.insert(jobs, { i = interval, acc = math.huge, fn = fn })
    end

    local frames, frameClock = 0, 0
    Conn.Loop = RunService.Heartbeat:Connect(function(dt)
        frames = frames + 1
        frameClock = frameClock + dt
        if frameClock >= 1 then
            State.Fps = math.floor(frames / frameClock + 0.5)
            frames, frameClock = 0, 0
        end
        for _, job in ipairs(jobs) do
            job.acc = job.acc + dt
            if job.acc >= job.i then
                job.acc = 0
                local ok, err = pcall(job.fn)
                if not ok then Log("job: " .. tostring(err), "error") end
            end
        end
    end)

    -- topbar: sempre, barato
    Every(0.5, function()
        local extra = ""
        if State.Spectating and State.SpectateTarget then
            extra = "   •   ASSISTINDO " .. State.SpectateTarget.Name
        end
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 2000)
        if SetChips then
            SetChips(State.Fps, ping, #Players:GetPlayers(), Players.MaxPlayers,
                LocalPlayer.Name,
                (State.Spectating and State.SpectateTarget) and State.SpectateTarget.Name or nil)
        else
            Stat.Text = string.format("FPS %d   •   PING %dms   •   %d/%d jogadores   •   %s%s",
                State.Fps, ping, #Players:GetPlayers(), Players.MaxPlayers,
                LocalPlayer.Name, extra)
        end
    end)

    -- painel: só a aba visível trabalha
    Every(1, function()
        if not isOpen or State.Minimized then return end
        local tab = State.ActiveTab
        if V8.Shell then pcall(V8.Shell.Tick) end   -- v8.0: relógio da TopBar
        if tab == "Home" then
            if Tiles.fps then Tiles.fps.Text = tostring(State.Fps) end
            if Tiles.ping then
                Tiles.ping.Text = math.floor(LocalPlayer:GetNetworkPing() * 2000) .. "ms"
            end
            if Tiles.players then
                Tiles.players.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
            end
            if Tiles.uptime then
                Tiles.uptime.Text = math.floor((os.time() - (serverStart or os.time())) / 60) .. "m"
            end
            RefreshStatus()
            if V8.Dash then pcall(V8.Dash.Tick) end   -- v8.0: relógio + tira de status
        elseif tab == "Players" then
            if UpdatePlayerRows then UpdatePlayerRows() end
        elseif tab == "Moderation" then
            if UpdateSelectedInfo then UpdateSelectedInfo() end
        elseif tab == "Server" then
            if UpdateServerInfo then UpdateServerInfo() end
        end
    end)

    -- v8.0: faxina do registry de tema. Listas que se redesenham (jogadores,
    -- waypoints, amigos, favoritos) deixavam entradas mortas em Painted até a
    -- próxima troca de tema. Removida só depois de 2 passadas seguidas sem
    -- Parent (~20s), para nunca pegar algo que ainda vai ser parentado.
    Every(20, function()
        local j = 0
        for i = 1, #Painted do
            local e = Painted[i]
            local inst = e and e.inst
            local keep = false
            if inst then
                if inst.Parent or inst == Gui then
                    e.dead = nil
                    keep = true
                else
                    e.dead = (e.dead or 0) + 1
                    keep = e.dead < 2
                end
            end
            if keep then
                j = j + 1
                Painted[j] = e
            end
        end
        for i = #Painted, j + 1, -1 do Painted[i] = nil end
    end)
end

--------------------------------------------------------------------------------
-- RESPAWN: reaplica o que estava ligado (e avisa o que não deu)
--------------------------------------------------------------------------------
Conn.CharAdded = LocalPlayer.CharacterAdded:Connect(function(char)
    pcall(function() char:WaitForChild("Humanoid", 5) end)
    task.wait(0.4)

    local falhou = {}
    local function Redo(name, fn)
        local ok = pcall(fn)
        if not ok then table.insert(falhou, name) end
    end

    -- o drone ancora partes do corpo antigo: no respawn ele sempre desliga
    if IsOn("drone") then
        pcall(function() SetToggle("drone", false, true) end)
        Log("Modo Drone desligado (respawn) — ligue de novo se quiser", "warn")
        Toast("Drone desligado no respawn", "warn")
    end

    if IsOn("fly") then Redo("fly", StartFly) end
    if IsOn("noclip") then Redo("noclip", CacheNoclipParts) end
    if IsOn("god") then Redo("god", function() ApplyGod(Hum()) end) end
    if IsOn("invisible") then Redo("invisible", function() ApplyInvisible(true) end) end

    Redo("velocidade", function()
        local h = Hum()
        if not h then error("sem humanoid") end
        if State.WalkSpeed ~= 16 then h.WalkSpeed = State.WalkSpeed end
        if State.JumpPower ~= 50 then
            h.UseJumpPower = true
            h.JumpPower = State.JumpPower
        end
    end)

    if IsOn("esp") then
        if SET.EspAuto then
            Redo("esp", function()
                ClearEsp()
                for _, p in ipairs(Players:GetPlayers()) do BuildEsp(p) end
            end)
        else
            Log("ESP não foi reconstruído (opção 'reconstruir ESP no respawn' desligada)", "warn")
        end
    end

    if #falhou > 0 then
        Log("Não deu para reaplicar: " .. table.concat(falhou, ", "), "error")
        Toast("Falhou reaplicar: " .. table.concat(falhou, ", "), "error")
    else
        Log("Personagem recarregado — funções reaplicadas", "ok")
    end
    RefreshStatus()
end)

--------------------------------------------------------------------------------
-- v8.0: ENTRADA / SAÍDA DE JOGADORES
-- Antes não existia nenhum PlayerAdded/PlayerRemoving: a aba Players só via
-- gente nova ao ser reaberta, o ESP de quem saiu ficava na memória (tracer
-- incluso) e o "tempo no servidor" nunca era preenchido.
-- Quem já estava no servidor quando o painel abriu fica com "—": o cliente não
-- sabe a hora de entrada deles, e o painel não inventa número.
--------------------------------------------------------------------------------
Conn.PlayerAdded = Players.PlayerAdded:Connect(function(p)
    State.JoinTimes[p.UserId] = os.clock()
    Log("Entrou: " .. p.Name .. " (" .. p.DisplayName .. ")")
    if isOpen and State.ActiveTab == "Players" and RebuildPlayerRows then
        pcall(RebuildPlayerRows)
    end
end)

Conn.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    local id = p.UserId
    State.JoinTimes[id] = nil
    TrollState.Spin[id] = nil
    TrollState.Balloon[id] = nil
    pcall(RemoveEsp, id)
    if State.SpectateTarget == p then pcall(StopSpectate) end
    if State.SelectedPlayer == p then
        State.SelectedPlayer = nil
        if UpdateSelectedInfo then pcall(UpdateSelectedInfo) end
    end
    Log("Saiu: " .. p.Name)
    -- durante este evento o Player ainda está em Players: reconstrói depois
    task.delay(0.2, function()
        if RebuildPlayerRows then pcall(RebuildPlayerRows) end
    end)
end)

--------------------------------------------------------------------------------
-- MENSAGENS DO SERVIDOR (AdminWhisper)
--------------------------------------------------------------------------------
if Remotes.Whisper then
    Conn.Whisper = Remotes.Whisper.OnClientEvent:Connect(function(fromName, message)
        Log("[ADMIN " .. tostring(fromName) .. "] " .. tostring(message), "action")
        Toast("ADMIN " .. tostring(fromName) .. ": " .. tostring(message), nil, 6)
    end)
end
-- v8.0: com o script de server/ o anúncio volta para todos (já filtrado pelo
-- Roblox); o painel registra no próprio console como confirmação real
if Remotes.Announce then
    Conn.Announce = Remotes.Announce.OnClientEvent:Connect(function(fromName, message)
        Log("[ANÚNCIO " .. tostring(fromName) .. "] " .. tostring(message), "action")
    end)
end

--------------------------------------------------------------------------------
-- UNLOAD (desfaz tudo)
--------------------------------------------------------------------------------
Unload = function()
    Log("Descarregando...", "warn")
    -- v8.0: captura de keybind em andamento tinha conexão fora de Conn
    pcall(StopCapture)

    -- v8.0: salva a configuração antes de derrubar tudo (se o autosave estiver ligado)
    pcall(function()
        if V8.Cfg and SET.AutoSave then V8.Cfg.Save(true) end
    end)

    for _, id in ipairs(ToggleOrder) do
        if IsOn(id) then pcall(Toggles[id].disable) end
    end
    pcall(StopSpectate)
    pcall(ClearEsp)
    pcall(function() Emote.Stop(true) end)

    for name in pairs(Conn) do pcall(Drop, name) end
    for _, inst in ipairs(Bin) do pcall(function() inst:Destroy() end) end

    pcall(function()
        local h = Hum()
        if h then
            h.WalkSpeed = 16
            h.UseJumpPower = true
            h.JumpPower = 50
            h.PlatformStand = false
        end
    end)
    pcall(function() RunService:UnbindFromRenderStep("HYGE_FlyPose") end)
    pcall(function() Gui:Destroy() end)

    for i = #Bin, 1, -1 do Bin[i] = nil end
    for i = #Painted, 1, -1 do Painted[i] = nil end
    for k in pairs(Esp) do Esp[k] = nil end
    for k in pairs(Keybinds) do Keybinds[k] = nil end
    for i = #State.Waypoints, 1, -1 do State.Waypoints[i] = nil end
    for i = #State.CmdHistory, 1, -1 do State.CmdHistory[i] = nil end
    State.SelectedPlayer = nil
    State.SpectateTarget = nil

    print("[HYGE] painel descarregado.")
end

--------------------------------------------------------------------------------
-- BOOT
--------------------------------------------------------------------------------
do
    local falhas = {}
    local function BootStep(name, fn)
        local ok, err = pcall(fn)
        if not ok then
            warn("[HYGE] falha no boot (" .. name .. "): " .. tostring(err))
            table.insert(falhas, name)
        end
        return ok
    end

    BootStep("ShowTab",       function() ShowTab("Home") end)
    BootStep("RefreshStatus", function() RefreshStatus() end)
    BootStep("PlayerRows",    function() if RebuildPlayerRows then RebuildPlayerRows() end end)
    BootStep("Waypoints",     function() if RenderWaypoints then RenderWaypoints() end end)
    BootStep("ServerInfo",    function() if UpdateServerInfo then UpdateServerInfo() end end)
    BootStep("Config",        function() if V8.Cfg then V8.Cfg.Load(true) end end)
    BootStep("Friends",       function() if V8.Dash then V8.Dash.Friends(true) end end)
    BootStep("SetOpen",       function() SetOpen(true) end)
    -- v8.0: em tela baixa a janela "acima do dock" pode nascer cortada
    BootStep("Janela",        function() if V8.Win then task.defer(V8.Win.Clamp) end end)

    -- garante que sempre existe um jeito de abrir, mesmo se algo acima falhar:
    -- o dock (padrão) ou, no modo sidebar, a bolinha H
    Gui.Enabled = true
    Orb.Visible = (not isOpen) and (SET.Dock ~= true)

    print("[HYGE] pronto. Aperte " .. KeyName(CONFIG.PanelKey)
        .. (SET.Dock == true and " ou use o dock no rodapé." or " ou clique na bolinha."))

    Log("HYGE " .. CONFIG.Version .. " carregado", "ok")
    Log("[" .. KeyName(CONFIG.PanelKey) .. "] painel  •  ["
        .. KeyName(CONFIG.ConsoleKey) .. "] comandos  •  'help' lista tudo")
    Log("["
        .. (CONFIG.SearchCtrl and "Ctrl+" or "")
        .. KeyName(CONFIG.SearchKey) .. "] busca global  •  [Keypad 1-6] situações", "ok")
    if #falhas > 0 then
        Log("Boot com falhas em: " .. table.concat(falhas, ", "), "error")
        Toast("Boot parcial — veja o log", "error", 5)
    else
        Toast("HYGE " .. CONFIG.Version .. " pronto — aperte " .. KeyName(CONFIG.PanelKey), "ok", 4)
    end
end
