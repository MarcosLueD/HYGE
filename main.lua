-- =============================================================================
-- HYGE v9.1 — ARQUIVO GERADO, NÃO EDITE AQUI.
-- Fonte: src/   ·   gerar de novo: npm run build  (ou: node build.js)
-- build: c01b15b8b296
-- =============================================================================
--[[
================================================================================
    HYGE ADMIN PANEL v9.0
    Evolucao direta da v7.0 — nada foi reescrito do zero.

    O que a v9.0 trouxe (a maior atualizacao ate agora):
      * Ajustes organizados: categorias + busca dentro de Configuracoes
      * Favoritos: estrela em qualquer funcao vira acao rapida da Home
      * Perfis: o painel inteiro salvo com um nome; um perfil por jogo
      * Central de notificacoes no sino da ilha + modo Nao perturbe
      * Macros de teclado (tecla -> qualquer comando)
      * Temas Rosa, Laranja, Meia-noite e cor personalizada
      * Diagnostico (executor, boot, erros) com relatorio para copiar
      * Config salva sozinha a cada 30 s (antes: so ao descarregar)
      * Modulos isolados: um modulo com erro nao derruba o painel; erros do
        log apontam para src/arquivo.lua:linha
      * Busca global sem acento, achando ajustes e perfis

    O que a v8.2 trouxe:
      * Pacote de animacao no personagem todo (andar, correr, pular, parado...)
        por ID ou link do pacote; lista salva; o mesmo pacote no Fly
      * Celular: botoes na tela (FLY, SUBIR, DESCER, 2x), voo pelo analogico,
        janela e dock que cabem em tela pequena
      * Playtime Shop: missoes do dia e bonus diario por dias seguidos
      * Ctrl + clique teleporta; waypoints salvos por jogo
      * Atualizacao: confere a versao nova e atualiza sem sair do jogo
        (loader.lua sempre abre a mais nova)

    O que a v8.1 trouxe (dock de 8 secoes):
      * Inicio: mapa atual, perfil com tempo de jogo, Rejoin / Trocar de
        servidor / Discord
      * Personagem: Anti-Fall e Anti-Gravidade (com slider)
      * Playtime Shop: loja paga com tempo de jogo (Ranks, Icons, Titles,
        Effects, Nametags, Bundles) — tudo visual e local
      * Troll: Walk on Walls + acoes no alvo (vindas da Moderacao)
      * Emotes: catalogo pesquisavel, Playback Speed, andar com o emote
      * Jogadores: ESP / TP / SPEC por linha da lista
      * Configuracoes: tecla do painel remapeavel, funcoes automaticas,
        reconectar se cair; Console virou sub-aba
      * Chat HYGE entre usuarios do painel (relay em server/chat-relay)

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
    Version   = "v9.1",
    AdminIds  = { LocalPlayer.UserId },  -- << coloque os UserIds dos seus admins
    DefaultTheme = "Grafite",            -- tema de quem nunca salvou config
    PanelKey  = Enum.KeyCode.B,
    ConsoleKey= Enum.KeyCode.Semicolon,
    UiScale   = 1,
    MaxLog    = 60,

    -- Logo: suba a imagem em create.roblox.com > Development Items > Decals,
    -- copie o ID e cole aqui como "rbxassetid://SEU_ID". Vazio = logo em texto.
    LogoId    = "",

    -- v8.1: convite do Discord (botão da Home e comando 'discord'). Vazio = o
    -- botão avisa que não há link configurado, em vez de copiar qualquer coisa.
    Discord   = "",

    -- v8.1: chat entre usuários do HYGE (Chat › HYGE). Precisa de um relay
    -- rodando (server/chat-relay — veja o README). Vazio = desligado; o
    -- endereço também pode ser colado depois, na própria aba.
    ChatRelay = "",
    ChatKey   = "",   -- senha opcional: a mesma do HYGE_CHAT_KEY do relay

    -- v8.2: de onde o painel confere (e baixa) a versão nova. É o main.lua
    -- "raw" do GitHub. Vazio = não confere. Quem usa o loader.lua já passa a
    -- URL dele; esta só vale para quem cola o main.lua direto.
    UpdateUrl = "https://raw.githubusercontent.com/MarcosLueD/HYGE/main/main.lua",

    -- ANIMAÇÃO DO VOO. O Fly escolhe nesta ordem:
    --   1. FlyAnimR6 / FlyAnimR15: animação SUA publicada. Só carrega em jogo
    --      seu ou do seu grupo (em jogo de outros o Roblox recusa).
    --      FlyAnimIdle (opcional) = sua animação para parado no ar.
    --   2. FlyStyle = "pacote" (padrão, v8.1.2): pacote de animação do
    --      catálogo. v8.2: o pacote escolhido em Personagem › Pacote de
    --      animação (botão VOO); sem escolha, FlyPackBundle; vazio, os itens
    --      FlyPackMove/FlyPackIdle. Se o executor não deixar ler o pacote ou o
    --      Roblox recusar neste jogo, cai no 3 e avisa.
    --   3. FlyStyle = "jogo": as animações do PRÓPRIO personagem — nadar
    --      enquanto voa (o corpo deita na direção do voo) e flutuar/cair parado.
    --      Carregam em qualquer jogo. Só R15 tem a de nadar; em R6 cai no 4.
    --   4. pose procedural (FlyUsePose): reserva. Escreve direto nas juntas no
    --      SEU cliente — só você vê; os outros veem o personagem parado.
    -- O estilo também se troca em Personagem › Velocidades › Animação do voo.
    FlyAnimR6   = "",
    FlyAnimR15  = "",
    FlyAnimIdle = "",
    FlyAnimSpeed = 1,
    FlyStyle    = "pacote", -- "pacote" | "jogo" | "pose"
    FlySwimTilt = 75,       -- graus que o corpo deita voando no estilo "jogo"

    -- v8.2: ID do PACOTE (bundle) — o número do link
    -- roblox.com/bundles/<ID>/... O painel lê a lista de animações dele
    -- sozinho. Vazio = usa os dois itens abaixo.
    FlyPackBundle    = "60179708829279",   -- Super Gogeta DBZ
    FlyPackMoveSlot  = "fall",   -- animação do pacote voando: fall | swim | run | idle...
    FlyPackIdleSlot  = "idle",   -- e parado no ar

    -- Pacote "Super Gogeta DBZ" (bundle 60179708829279, grupo
    -- "Benere & Chenere's UGC" — UGC, não é da Roblox).
    -- Estes são IDs de ITEM DO CATÁLOGO (AssetType FallAnimation/IdleAnimation),
    -- não de animação: o item é uma "caixa" com um Animation dentro, e é o ID
    -- desse Animation que toca. O painel abre a caixa com game:GetObjects
    -- (executor) e usa o ID de dentro.
    -- Outras animações do mesmo pacote, se quiser trocar:
    --   Run 95473441710999 · Walk 71567557250866 · Swim 97745837467465
    --   Jump 111658291175493 · Climb 137524336110065
    -- Pacote anterior (Endless Aura, bundle 4899847411546):
    --   Fall 74203422263286 · Idle 75638427965557
    FlyPackMove = "rbxassetid://124330094243355",  -- Fall (voando)
    FlyPackIdle = "rbxassetid://110189334321552",  -- Idle (parado no ar)
    -- true: sem nenhuma animação que carregue, usa a pose procedural abaixo
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
    -- v8.0: monocromático (quase preto + destaque branco) — padrão do dock novo
    Grafite = {
        Main = Color3.fromRGB(17, 17, 19),   Sidebar = Color3.fromRGB(23, 23, 26),
        Card = Color3.fromRGB(30, 31, 35),   Console = Color3.fromRGB(12, 12, 14),
        Accent = Color3.fromRGB(236, 236, 240), Accent2 = Color3.fromRGB(196, 198, 206),
        Text = Color3.fromRGB(245, 245, 247), Dim = Color3.fromRGB(165, 166, 175),
        Danger = Color3.fromRGB(255, 92, 98), Success = Color3.fromRGB(110, 222, 150),
        Warning = Color3.fromRGB(255, 192, 72), Btn = Color3.fromRGB(40, 41, 46),
        BtnHover = Color3.fromRGB(52, 53, 59), Track = Color3.fromRGB(56, 57, 63),
        Line = Color3.fromRGB(46, 47, 53),
    },
    -- v9.0: três paletas novas (a "Personalizado" é montada em 50_v8/12_colors.lua)
    Rosa = {
        Main = Color3.fromRGB(19, 12, 17),   Sidebar = Color3.fromRGB(14, 8, 13),
        Card = Color3.fromRGB(29, 18, 26),   Console = Color3.fromRGB(12, 6, 10),
        Accent = Color3.fromRGB(255, 105, 180), Accent2 = Color3.fromRGB(255, 170, 210),
        Text = Color3.fromRGB(252, 244, 248), Dim = Color3.fromRGB(175, 140, 160),
        Danger = Color3.fromRGB(255, 70, 90), Success = Color3.fromRGB(120, 225, 165),
        Warning = Color3.fromRGB(255, 190, 70), Btn = Color3.fromRGB(40, 24, 35),
        BtnHover = Color3.fromRGB(55, 32, 48), Track = Color3.fromRGB(58, 34, 50),
        Line = Color3.fromRGB(74, 44, 64),
    },
    Laranja = {
        Main = Color3.fromRGB(19, 14, 10),   Sidebar = Color3.fromRGB(14, 10, 7),
        Card = Color3.fromRGB(30, 22, 15),   Console = Color3.fromRGB(12, 8, 5),
        Accent = Color3.fromRGB(255, 140, 50), Accent2 = Color3.fromRGB(255, 190, 120),
        Text = Color3.fromRGB(252, 248, 242), Dim = Color3.fromRGB(175, 155, 135),
        Danger = Color3.fromRGB(255, 75, 85), Success = Color3.fromRGB(120, 225, 160),
        Warning = Color3.fromRGB(255, 205, 80), Btn = Color3.fromRGB(42, 30, 20),
        BtnHover = Color3.fromRGB(58, 42, 28), Track = Color3.fromRGB(60, 44, 30),
        Line = Color3.fromRGB(78, 57, 38),
    },
    ["Meia-noite"] = {
        Main = Color3.fromRGB(9, 10, 22),    Sidebar = Color3.fromRGB(6, 7, 16),
        Card = Color3.fromRGB(16, 18, 36),   Console = Color3.fromRGB(5, 6, 13),
        Accent = Color3.fromRGB(124, 108, 255), Accent2 = Color3.fromRGB(170, 160, 255),
        Text = Color3.fromRGB(238, 240, 255), Dim = Color3.fromRGB(135, 138, 175),
        Danger = Color3.fromRGB(255, 80, 110), Success = Color3.fromRGB(90, 220, 160),
        Warning = Color3.fromRGB(255, 195, 80), Btn = Color3.fromRGB(24, 26, 52),
        BtnHover = Color3.fromRGB(34, 36, 70), Track = Color3.fromRGB(32, 34, 66),
        Line = Color3.fromRGB(44, 46, 86),
    },
}
-- v9.0: ordem em que os temas aparecem (Ajustes › Aparência e comando 'theme')
local THEME_ORDER = { "Grafite", "Azul", "Roxo", "Ciano", "Verde", "Vermelho",
                      "Rosa", "Laranja", "Meia-noite" }

-- v8.0: nasce no tema padrão (antes nascia Roxo e era repintado depois — o que
-- não é registrado em Paint, como os switches, ficava com a cor errada)
local THEME = {}
for k, v in pairs(PALETTES[CONFIG.DefaultTheme] or PALETTES.Roxo) do THEME[k] = v end

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

-- Evita duas instâncias abertas ao mesmo tempo (em qualquer um dos parents).
-- v9.1: antes de destruir a GUI, descarrega a instância anterior de verdade
-- (conexões, scheduler, funções ligadas; a config dela é salva) — antes só a
-- GUI sumia e o resto continuava rodando junto com o painel novo
do
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    local prevUnload = env.HYGE_UNLOAD
    if type(prevUnload) == "function" then
        env.HYGE_UNLOAD = nil
        local ok, err = pcall(prevUnload)
        if not ok then warn("[HYGE] não deu para descarregar a instância anterior: " .. tostring(err)) end
    end
end
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

V8.Mod("src/10_ui/01_toasts.lua", 782, 924, function() --------------------------------------------------------------------------------
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

end)
V8.Mod("src/10_ui/02_console.lua", 926, 1145, function() --------------------------------------------------------------------------------
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
    msg = tostring(msg)
    -- v9.0: erro aponta para o src/ (não para a linha do main.lua) e fica
    -- guardado para o Diagnóstico (Configurações › Sistema)
    if kind == "error" then
        if V8.Where then
            local okW, w = pcall(V8.Where, msg)
            if okW then msg = w end
        end
        table.insert(V8.Errors, { time = os.date("%H:%M:%S"), msg = msg })
        while #V8.Errors > 20 do table.remove(V8.Errors, 1) end
    end
    local entry = { time = os.date("%H:%M:%S"), cat = kind, msg = msg }
    table.insert(LogEntries, entry)
    while #LogEntries > math.max(SET.MaxLog, 10) do table.remove(LogEntries, 1) end
    RenderLog(entry)
    print("[HYGE] " .. entry.msg)
end

-- chips de filtro + ações do console
do
    local function Chip(text, filter, order, colorKey)
        -- v8.0: chips mais estreitos e sem o rótulo "LOGS" (o título da janela
        -- já diz "Console") — tudo cabe na janela de 460px do dock
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 48, 0, 22)
        b.Position = UDim2.new(0, (order - 1) * 52, 0, 0)
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
    logTitle.Visible = false   -- v8.0: ver comentário no Chip
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
        b.Size = UDim2.new(0, 50, 0, 22)   -- v8.0: era 66
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

    MiniBtn("COPIAR", 54, "Accent", function()
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

end)
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
        Moderation = "shield", Server = "server", Emotes = "smile", Settings = "gear",
        Shop = "bag", Scripts = "terminal", Chat = "chat",   -- v8.0
        Troll = "mask", HyChat = "chat",                      -- v8.1
    }
    local NAV_LABEL = { Shop = "Playtime Shop", HyChat = "Chat HYGE",
        Chat = "Chat do jogo", Scripts = "Console" }          -- v8.1
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 29)   -- v8.1: 13 abas precisam caber na sidebar
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
    lbl.Text = NAV_LABEL[name] or name
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

-- v8.0: título de seção em caixa de frase ("MOVIMENTO E VELOCIDADE" vira
-- "Movimento e velocidade"), preservando siglas. string.lower não conhece
-- acento (UTF-8), então as maiúsculas acentuadas do português vão por tabela.
do
    local LOWER = { ["Á"] = "á", ["À"] = "à", ["Â"] = "â", ["Ã"] = "ã", ["É"] = "é",
        ["Ê"] = "ê", ["Í"] = "í", ["Ó"] = "ó", ["Ô"] = "ô", ["Õ"] = "õ", ["Ú"] = "ú",
        ["Ç"] = "ç" }
    local KEEP = { ESP = true, HUD = true, ID = true, FPS = true, AFK = true,
        JSON = true, HYGE = true, UI = true, TP = true }
    V8.Sentence = function(s)
        if type(s) ~= "string" or s == "" or s:upper() ~= s then return s end
        local out = s:lower():gsub("\195[\128-\159]", function(c) return LOWER[c] end)
        out = out:gsub("%a+", function(w)
            if KEEP[w:upper()] then return w:upper() end
        end)
        return (out:gsub("^%l", string.upper))
    end
end

-- v8.0: transforma um Frame em "cartão" (fundo, borda sutil, cantos, respiro
-- interno). As linhas (switch, slider, keybind) são cartões soltos.
V8.Cell = function(f, padV)
    f.BackgroundColor3 = THEME.Card
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    Paint(f, "BackgroundColor3", "Card")
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", f)
    st.Transparency = 0.25
    Paint(st, "Color", "Line")
    local p = Instance.new("UIPadding", f)
    p.PaddingLeft = UDim.new(0, 14)
    p.PaddingRight = UDim.new(0, 12)
    p.PaddingTop = UDim.new(0, padV or 0)
    p.PaddingBottom = UDim.new(0, padV or 0)
    return f
end

-- v8.0: o "card" virou SEÇÃO — título pequeno em cima e o conteúdo solto
-- embaixo (cada linha é seu próprio cartão). Antes era uma caixa com tudo dentro.
local function CreateCard(parent, title, order)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = parent

    local layout = Instance.new("UIListLayout", card)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    if title then
        local head = Instance.new("TextLabel")
        head.Size = UDim2.new(1, 0, 0, 18)
        head.BackgroundTransparency = 1
        head.Text = V8.Sentence(title)
        head.TextColor3 = THEME.Text
        head.Font = Enum.Font.GothamBold
        head.TextSize = 13
        head.TextXAlignment = Enum.TextXAlignment.Left
        head.LayoutOrder = -1
        head.Parent = card
        Paint(head, "TextColor3", "Text")
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
    b.TextWrapped = true   -- v8.0: na janela estreita, texto longo quebra em vez de vazar
    b.AutoButtonColor = false
    b.Parent = parent
    Paint(b, "BackgroundColor3", "Btn")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

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

--------------------------------------------------------------------------------
-- v9.0 — FAVORITOS
-- Toda linha de função (SwitchRow) ganha uma estrela. As funções com estrela
-- são as "Ações rápidas" da Home (padrão: as 8 de sempre). Vai na config
-- (SET.Favs) e em cada perfil.
--------------------------------------------------------------------------------
V8.Fav = { Max = 12, Stars = {} }   -- Stars[id] = { ícone, ... }
V8.Fav.Default = { "fly", "noclip", "esp", "freecam", "infjump", "god", "invisible", "fullbright" }
V8.Fav.List = function()
    if type(SET.Favs) ~= "table" then return V8.Fav.Default end
    return SET.Favs
end
V8.Fav.Has = function(id)
    for _, x in ipairs(V8.Fav.List()) do
        if x == id then return true end
    end
    return false
end
V8.Fav.Paint = function()
    for id, list in pairs(V8.Fav.Stars) do
        local on = V8.Fav.Has(id)
        for _, ic in ipairs(list) do
            if ic.Parent then IconTint(ic, on and THEME.Warning or THEME.Track) end
        end
    end
end
-- liga/desliga a estrela. Devolve true se a função ficou nos favoritos
V8.Fav.Toggle = function(id, silent)
    if not Toggles[id] then return false end
    local list, had = {}, false
    for _, x in ipairs(V8.Fav.List()) do
        if x == id then had = true elseif Toggles[x] then table.insert(list, x) end
    end
    if not had then
        if #list >= V8.Fav.Max then
            if not silent then
                Toast("Limite de " .. V8.Fav.Max .. " favoritos — tire uma estrela antes", "warn", 3)
            end
            return false
        end
        table.insert(list, id)
    end
    SET.Favs = list
    pcall(V8.Fav.Paint)
    if V8.Fav.OnChange then pcall(V8.Fav.OnChange) end
    if not silent then
        local label = Toggles[id].label or id
        Toast(had and (label .. " saiu das ações rápidas") or (label .. " fixado nas ações rápidas"),
            had and "info" or "ok", 1.8)
    end
    return not had
end
V8.Renders = V8.Renders or {}
table.insert(V8.Renders, function() V8.Fav.Paint() end)   -- troca de tema / config

-- Switch animado
local function SwitchRow(parent, id, labelText, description)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, description and 56 or 44)
    row.BackgroundTransparency = 1
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cada linha é um cartão

    -- v9.0: estrela dos favoritos, entre o texto e o switch
    if Toggles[id] and Icon then
        local star = Instance.new("TextButton")
        star.AnchorPoint = Vector2.new(1, 0.5)
        star.Position = UDim2.new(1, -52, 0.5, 0)
        star.Size = UDim2.new(0, 26, 0, 26)
        star.BackgroundTransparency = 1
        star.Text = ""
        star.AutoButtonColor = false
        star.Parent = row
        local ic = Icon(star, "star", THEME.Track, 14)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.new(0.5, 0, 0.5, 0)
        V8.Fav.Stars[id] = V8.Fav.Stars[id] or {}
        table.insert(V8.Fav.Stars[id], ic)
        IconTint(ic, V8.Fav.Has(id) and THEME.Warning or THEME.Track)
        star.MouseEnter:Connect(function()
            if not V8.Fav.Has(id) then IconTint(ic, THEME.Dim) end
        end)
        star.MouseLeave:Connect(function()
            IconTint(ic, V8.Fav.Has(id) and THEME.Warning or THEME.Track)
        end)
        star.MouseButton1Click:Connect(function() V8.Fav.Toggle(id) end)
    end

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -96, 0, 18)
    name.Position = UDim2.new(0, 0, 0, description and 4 or 8)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -96, 0, 14)
        desc.Position = UDim2.new(0, 0, 0, 24)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.TextColor3 = THEME.Dim
        desc.Font = Enum.Font.GothamMedium
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextTruncate = Enum.TextTruncate.AtEnd
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
    knob.BackgroundColor3 = THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- v8.0: ligado = trilho no destaque + bolinha escura; desligado = trilho
    -- escuro + bolinha clara (com destaque branco, bolinha branca sumia)
    local function render(on)
        TweenService:Create(track, TweenInfo.new(0.16), {
            BackgroundColor3 = on and THEME.Accent or THEME.Track }):Play()
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and THEME.Main or THEME.Text }):Play()
    end

    track.MouseButton1Click:Connect(function() Flip(id) end)
    if Toggles[id] then
        table.insert(Toggles[id].listeners, render)
        render(Toggles[id].state)
        -- troca de tema repinta também os switches (V8.Renders roda no ApplyTheme)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() render(Toggles[id].state) end)
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
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -110, 1, 0)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
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

        captureConn = UserInputService.InputBegan:Connect(function(input, gpe) -- conn:ok StopCapture desconecta (o Unload chama)
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
            -- v9.0: macro com a mesma tecla perde a tecla (o handler global
            -- roda macro antes dos atalhos — senão este nunca dispararia)
            if V8.Macro and V8.Macro.Release then pcall(V8.Macro.Release, kc) end
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

--------------------------------------------------------------------------------
-- v8.1.2: PACOTE DE ANIMAÇÃO DO CATÁLOGO
-- O ID de um item de pacote (AssetType RunAnimation, FallAnimation...) não é
-- uma animação: é uma "caixa" (Folder > StringValue > Animation) e o que toca
-- é o AnimationId do Animation de dentro. game:GetObjects (do executor) abre a
-- caixa; o resultado fica em cache (false = tentou e não deu).
-- FlyPose.Known(id): já sabe a resposta (não precisa esperar a rede)
-- FlyPose.Resolve(id): devolve o AnimationId real ou nil (pode esperar a rede)
--------------------------------------------------------------------------------
do
    FlyPose.cache = {}
    FlyPose.Key = function(id) return tostring(id or ""):match("(%d+)") end
    FlyPose.Known = function(id)
        local k = FlyPose.Key(id)
        return k == nil or FlyPose.cache[k] ~= nil
    end
    FlyPose.Resolve = function(id)
        local k = FlyPose.Key(id)
        if not k then return nil end
        if FlyPose.cache[k] ~= nil then return FlyPose.cache[k] or nil end
        local found = false
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. k) end)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                if o:IsA("KeyframeSequence") then
                    found = "rbxassetid://" .. k   -- o ID já era de uma animação
                else
                    local list = o:IsA("Animation") and { o } or o:GetDescendants()
                    for _, d in ipairs(list) do
                        if d:IsA("Animation") and d.AnimationId ~= "" then
                            found = d.AnimationId
                            break
                        end
                    end
                end
                if found then break end
            end
            for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
        end
        FlyPose.cache[k] = found
        return found or nil
    end
end

-- Animação do voo (ordem explicada em CONFIG, "ANIMAÇÃO DO VOO"):
--   ID seu  >  estilo "jogo" (nadar/flutuar do próprio personagem)  >
--   estilo "pacote"  >  pose procedural (reserva, só você vê)
-- FlyPose.tilt = true faz o loop do Fly deitar o corpo na direção do voo.
local function StartFlyAnim()
    local h = Hum()
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = h
    end
    FlyPose.tilt = false

    -- AnimationId de uma pasta do script Animate do personagem (nil se não há)
    local function FromGame(names)
        local char = Char()
        local animate = char and char:FindFirstChild("Animate")
        if not animate then return nil end
        for _, n in ipairs(names) do
            local f = animate:FindFirstChild(n)
            local a = f and f:FindFirstChildOfClass("Animation")
            if a and a.AnimationId ~= "" then return a.AnimationId end
        end
        return nil
    end

    local style = SET.FlyStyle or CONFIG.FlyStyle or "pacote"
    local source = "sua"
    local moveId = (h.RigType == Enum.HumanoidRigType.R6)
        and CONFIG.FlyAnimR6 or CONFIG.FlyAnimR15
    local idleId = CONFIG.FlyAnimIdle
    if not moveId or moveId == "" then
        moveId, idleId = nil, nil

        -- pacote do catálogo (R15). Primeira vez: lê o pacote em segundo plano
        -- e, enquanto isso, voa com o nadar do jogo; pronto, troca sozinho.
        -- v8.2: o pacote vem por ID de bundle (V8.Pack — o marcado como VOO
        -- em Personagem › Pacote de animação, ou CONFIG.FlyPackBundle). Só sem
        -- bundle nenhum é que valem os itens FlyPackMove/FlyPackIdle.
        local pm, pi, pk
        if style == "pacote" and V8.Pack then pm, pi, pk = V8.Pack.FlyIds() end
        if style == "pacote" and not FlyPose.packFailed
            and h.RigType ~= Enum.HumanoidRigType.R6 and pk then
            if pm then
                moveId, idleId, source = pm, pi, "do pacote"
            elseif V8.Pack.fail[pk.id] then
                if not FlyPose.warnedPack then
                    FlyPose.warnedPack = true
                    Log("Fly: não deu para ler o pacote " .. pk.name .. " ("
                        .. tostring(V8.Pack.fail[pk.id]) .. ") — voando com o nadar do jogo", "warn")
                end
            else
                V8.Pack.Resolve(pk, function(n)
                    if n and IsOn("fly") and not FlyPose.muted and FlyPose.Restart then
                        FlyPose.Restart()
                    end
                end)
            end
        elseif style == "pacote" and not FlyPose.packFailed
            and h.RigType ~= Enum.HumanoidRigType.R6 then
            if FlyPose.Known(CONFIG.FlyPackMove) and FlyPose.Known(CONFIG.FlyPackIdle) then
                moveId = FlyPose.Resolve(CONFIG.FlyPackMove)
                idleId = moveId and FlyPose.Resolve(CONFIG.FlyPackIdle) or nil
                if moveId then
                    source = "do pacote"
                elseif not FlyPose.warnedPack then
                    FlyPose.warnedPack = true
                    Log("Fly: não deu para ler o pacote de animação (o executor precisa "
                        .. "de game:GetObjects) — voando com o nadar do jogo", "warn")
                end
            elseif not FlyPose.resolving then
                FlyPose.resolving = true
                task.spawn(function()
                    FlyPose.Resolve(CONFIG.FlyPackMove)
                    FlyPose.Resolve(CONFIG.FlyPackIdle)
                    FlyPose.resolving = false
                    if IsOn("fly") and not FlyPose.muted and FlyPose.Restart then
                        FlyPose.Restart()
                    end
                end)
            end
        end

        if not moveId and (style == "jogo" or style == "pacote") then
            source = "do jogo"
            moveId = FromGame({ "swim" })
            if moveId then
                idleId = FromGame({ "swimidle", "fall" })
            elseif not FlyPose.warnedNoSwim then
                FlyPose.warnedNoSwim = true
                Log("Fly: este personagem não tem animação de nadar (R6 ou Animate "
                    .. "próprio do jogo) — usando a pose do painel, que só você vê", "warn")
            end
        end
    end

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
        -- nenhuma animação disponível: a pose procedural (se CONFIG.FlyUsePose)
        if CONFIG.FlyUsePose then FlyPose.Start() end
        return
    end

    FlyPose.muted = false
    FlyPose.tilt = (source == "do jogo")   -- nadar no ar: o corpo deita
    pcall(function() flyTrack:Play(0.2) end)

    -- O Roblox só recusa asset de terceiro DEPOIS de carregar: track fica com
    -- Length 0 e nada anima. Se for o caso, volta pra pose procedural e avisa.
    -- (pacote do catálogo vem pela rede na 1ª vez: espera mais antes de julgar)
    local mine = flyTrack
    task.delay(source == "do pacote" and 4 or 1.2, function()
        if not flyTrack or flyTrack ~= mine then return end   -- voo já reiniciou
        -- a de "parado no ar" não carregou: fica só a de movimento
        if FlyPose.idleTrack then
            local ilen = 0
            pcall(function() ilen = FlyPose.idleTrack.Length end)
            if ilen <= 0 then
                pcall(function() FlyPose.idleTrack:Stop(0) end)
                pcall(function() FlyPose.idleTrack:Destroy() end)
                FlyPose.idleTrack = nil
            end
        end
        local len = 0
        pcall(function() len = flyTrack.Length end)
        if len > 0 then return end
        pcall(function() flyTrack:Stop(0) end)
        pcall(function() flyTrack:Destroy() end)
        flyTrack = nil
        FlyPose.tilt = false
        if FlyPose.idleTrack then
            pcall(function() FlyPose.idleTrack:Stop(0) end)
            pcall(function() FlyPose.idleTrack:Destroy() end)
            FlyPose.idleTrack = nil
        end
        if source == "do pacote" then
            -- não insiste neste jogo: segue com o nadar do personagem
            FlyPose.packFailed = true
            Log("O Roblox recusou o pacote de animação de voo neste jogo — voando "
                .. "com o nadar do jogo.", "error")
            if FlyPose.Restart then FlyPose.Restart() end
            return
        end
        Log("O Roblox recusou a animação de voo " .. source .. " (asset que não é "
            .. "do dono do jogo nem da Roblox) — usando a pose do painel.", "error")
        if CONFIG.FlyUsePose then FlyPose.Start() end
    end)
end

local function StopFlyAnim()
    FlyPose.Stop()
    FlyPose.muted = false
    FlyPose.tilt = false
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

-- v8.1.2: troca a animação com o Fly ligado (pacote pronto, estilo mudado)
FlyPose.Restart = function()
    StopFlyAnim()
    StartFlyAnim()
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
            -- v8.2: sem tecla nenhuma, vale o analógico (celular/controle) e os
            -- botões SUBIR/DESCER da tela (50_v8/07_mobile.lua)
            if dir.Magnitude == 0 and V8.Mobile then
                local ok, md = pcall(V8.Mobile.FlyDir, cam)
                if ok and typeof(md) == "Vector3" then dir = md end
            end
        end

        local speed = State.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or (V8.Mobile and V8.Mobile.boost) then speed = speed * 2 end

        local target = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        vel = vel:Lerp(target, target.Magnitude > 0 and 0.18 or 0.1)
        flyBv.Velocity = vel

        local look = vel.Magnitude > 2 and vel.Unit or cam.LookVector
        -- v8.1.1: parado no ar com a animação do jogo, fica em pé olhando para
        -- onde a câmera aponta no plano (sem inclinar junto com a câmera)
        if FlyPose.tilt and vel.Magnitude <= 2 then
            local flat = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
            if flat.Magnitude > 1e-3 then look = flat.Unit end
        end
        local r = Root()
        if r and flyBg then
            local aim = CFrame.lookAt(r.Position, r.Position + look)
            if FlyPose.active then
                -- deita o corpo na direção do voo (pose de superman)
                aim = aim * CFrame.Angles(math.rad(CONFIG.Pose.BodyTilt or -90), 0, 0)
            elseif FlyPose.tilt and not FlyPose.muted then
                -- animação de nadar do jogo: deita mais quanto mais rápido voa
                -- (cabeça para onde você vai; parado, fica em pé)
                local k = math.clamp(vel.Magnitude / math.max(State.FlySpeed, 1), 0, 1)
                local deg = SET.FlyTilt or CONFIG.FlySwimTilt or 75
                aim = aim * CFrame.Angles(math.rad(-deg * k), 0, 0)
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
    -- v8.1: ESP por jogador (botão ESP da lista de Jogadores). Com alguém
    -- marcado, o ESP mostra SÓ os marcados (ignorando equipe e distância);
    -- sem ninguém marcado, vale o ESP normal com os filtros. Não vai pra config.
    Pick       = {},     -- [userId] = true
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
                if next(EspOpts.Pick) ~= nil then
                    show = EspOpts.Pick[p.UserId] == true
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

V8.Mod("src/20_features/08_spectate_hud.lua", 3303, 3376, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/20_features/09_body.lua", 3378, 3523, function() --------------------------------------------------------------------------------
-- v8.1 — ANTI-FALL e ANTI-GRAVIDADE (seção Personagem)
--
-- Anti-Fall, três camadas, tudo no SEU personagem:
--   1. desliga os estados FallingDown/Ragdoll do Humanoid (sem tombo)
--   2. pouso suave: caindo rápido com o chão logo abaixo, a velocidade de
--      queda é cortada antes do impacto (jogos que dão dano por velocidade
--      de pouso deixam de dar)
--   3. void: abaixo de FallenPartsDestroyHeight + 60, volta para o último
--      lugar em que você estava pisando
-- Dano de queda feito por script do servidor com outra regra continua valendo.
--
-- Anti-Gravidade: workspace.Gravity vale só para a física que roda no SEU
-- cliente — o seu personagem (você é o dono da física dele) e peças soltas
-- que o seu cliente simula. Os outros jogadores não mudam. Se o jogo trocar
-- a gravidade enquanto está ligado, o valor novo vira a base.
--
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        ------------------------------------------------------------ ANTI-FALL
        local AF = { hum = nil, safe = nil, acc = 0 }
        V8.AntiFall = AF
        local STATES = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll }
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        -- reaplica sozinho no respawn: o Humanoid novo é detectado no loop
        local function Guard(h)
            if AF.hum == h then return end
            AF.hum = h
            for _, st in ipairs(STATES) do
                pcall(function() h:SetStateEnabled(st, false) end)
            end
        end

        local function Unguard()
            local h = AF.hum
            AF.hum = nil
            if h and h.Parent then
                for _, st in ipairs(STATES) do
                    pcall(function() h:SetStateEnabled(st, true) end)
                end
            end
        end

        DefineToggle({
            id = "antifall", label = "Anti-Fall",
            desc = "Sem tombo nem dano de queda; volta se cair no void",
            enable = function()
                AF.safe = nil
                AF.acc = 0
                Conn.AntiFall = RunService.Heartbeat:Connect(function(dt)
                    local h, root = Hum(), Root()
                    if not h or not root then return end
                    Guard(h)
                    local pos = root.Position
                    local vel = root.AssemblyLinearVelocity
                    local voidY = workspace.FallenPartsDestroyHeight

                    -- último chão seguro (4x por segundo, parado em algo)
                    AF.acc = AF.acc + dt
                    if AF.acc >= 0.25 then
                        AF.acc = 0
                        if h.FloorMaterial ~= Enum.Material.Air and math.abs(vel.Y) < 5
                            and pos.Y > voidY + 80 then
                            AF.safe = root.CFrame
                        end
                    end

                    -- void
                    if pos.Y < voidY + 60 and AF.safe then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.CFrame = AF.safe + Vector3.new(0, 3, 0)
                        Log("Anti-Fall: caiu no void — voltou para o último chão", "action")
                        return
                    end

                    -- pouso suave
                    if vel.Y < -55 then
                        params.FilterDescendantsInstances = { Char() }
                        local reach = 6 + math.abs(vel.Y) * dt * 3
                        local hit = workspace:Raycast(pos, Vector3.new(0, -reach, 0), params)
                        if hit then
                            root.AssemblyLinearVelocity = Vector3.new(vel.X, -12, vel.Z)
                        end
                    end
                end)
            end,
            disable = function()
                Drop("AntiFall")
                Unguard()
                AF.safe = nil
            end,
        })

        ------------------------------------------------------- ANTI-GRAVIDADE
        local AG = { base = nil, busy = false }
        V8.AntiGrav = AG

        local function Want()
            return (AG.base or 196.2) * math.clamp(State.GravityPct or 25, 0, 100) / 100
        end

        local function Write()
            AG.busy = true
            pcall(function() workspace.Gravity = Want() end)
            AG.busy = false
        end

        -- slider da seção Personagem (e comando 'gravity')
        AG.Set = function(pct)
            State.GravityPct = math.clamp(math.floor((tonumber(pct) or 25) + 0.5), 0, 100)
            if IsOn("antigrav") then Write() end
        end

        DefineToggle({
            id = "antigrav", label = "Anti-Gravidade",
            desc = "Gravidade baixa só para você: pula alto e cai devagar",
            enable = function()
                AG.base = workspace.Gravity
                Write()
                Conn.AntiGrav = workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
                    if AG.busy then return end
                    local cur = workspace.Gravity
                    if math.abs(cur - Want()) > 0.01 then
                        AG.base = cur   -- o jogo trocou a gravidade: vira a base nova
                        Write()
                    end
                end)
            end,
            disable = function()
                Drop("AntiGrav")
                if AG.base then
                    AG.busy = true
                    pcall(function() workspace.Gravity = AG.base end)
                    AG.busy = false
                end
                AG.base = nil
            end,
        })
    end
    Build()
end
end)
V8.Mod("src/20_features/10_wallwalk.lua", 3525, 3804, function() --------------------------------------------------------------------------------
-- v8.1 — WALK ON WALLS (seção Troll)
--
-- O Humanoid só sabe andar com o "para cima" do mundo, então aqui o painel
-- assume o controle do personagem (PlatformStand, igual ao Fly) e cuida da
-- "gravidade" sozinho:
--   * um raio para baixo (no "para cima" atual) acha a superfície e prende os
--     pés nela; superfície curva vai virando o corpo aos poucos
--   * andando contra uma parede, ela vira o chão (sobe a parede, anda no teto)
--   * passando de uma quina, um raio "dobra" a borda e continua do outro lado
--   * sem nada embaixo por ~1,2 s, volta para a gravidade normal
-- WASD anda (relativo à câmera), Space pula para fora da superfície. Usa a
-- WalkSpeed/JumpPower dos sliders e a gravidade atual (Anti-Gravidade vale).
-- Quem está em volta vê você na parede: o personagem é seu, a posição replica.
--
-- Liga junto com Fly/Drone/Freecam não dá (todos mandam no personagem): ligar
-- um deles desliga este. No respawn ele sempre desliga.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local W = { up = Vector3.yAxis, fall = 0, air = 0 }
        V8.WallWalk = W

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        local function Proj(v, n) return v - n * v:Dot(n) end

        -- distância do centro do HumanoidRootPart até a sola do pé
        local function HipOffset(h, root)
            if h.RigType == Enum.HumanoidRigType.R15 then
                return h.HipHeight + root.Size.Y * 0.5
            end
            return root.Size.Y * 0.5 + 2   -- R6: perna fixa de 2 studs
        end

        -- animação de andar do próprio jogo (pasta Animate), se existir
        local function LoadWalk(h)
            local char = Char()
            local animate = char and char:FindFirstChild("Animate")
            local folder = animate and (animate:FindFirstChild("walk") or animate:FindFirstChild("run"))
            local anim = folder and folder:FindFirstChildOfClass("Animation")
            local animator = h:FindFirstChildOfClass("Animator")
            if not anim or not animator then return nil end
            local ok, tr = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok or not tr then return nil end
            pcall(function()
                tr.Looped = true
                tr.Priority = Enum.AnimationPriority.Movement
            end)
            return tr
        end

        local function Stop()
            Drop("WallWalk")
            if W.bv then pcall(function() W.bv:Destroy() end) W.bv = nil end
            if W.bg then pcall(function() W.bg:Destroy() end) W.bg = nil end
            if W.anim then
                pcall(function() W.anim:Stop(0.2) end)
                pcall(function() W.anim:Destroy() end)
                W.anim = nil
            end
            for part, cc in pairs(W.coll or {}) do
                if part.Parent then pcall(function() part.CanCollide = cc end) end
            end
            W.coll = nil
            local h, root = Hum(), Root()
            if h then h.PlatformStand = false end
            if root and W.up ~= Vector3.yAxis then
                -- volta em pé, olhando para o mesmo lado (no plano do chão)
                local look = Proj(root.CFrame.LookVector, Vector3.yAxis)
                if look.Magnitude < 0.1 then look = Proj(-W.up, Vector3.yAxis) end
                if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
                pcall(function()
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit)
                    root.AssemblyLinearVelocity = Vector3.zero
                end)
            end
            W.up = Vector3.yAxis
            W.fall, W.air = 0, 0
            W.rot = nil
        end

        local function Key(kc) return UserInputService:IsKeyDown(kc) end

        local function Step(dt)
            local root, h = Root(), Hum()
            if not root or not h or not W.bv or not W.bv.Parent then return end
            -- outro modo assumiu o personagem: sai de cena
            if IsOn("fly") or IsOn("drone") or IsOn("freecam") then
                SetToggle("wallwalk", false)
                return
            end
            dt = math.min(dt, 0.1)
            h.PlatformStand = true
            for part in pairs(W.coll) do
                if part.Parent and part.CanCollide then part.CanCollide = false end
            end

            local up = W.up
            local hip = HipOffset(h, root)
            local pos = root.Position

            -- direção pedida, relativa à câmera e projetada na superfície
            local cam = Camera.CFrame
            local fwd = Proj(cam.LookVector, up)
            if fwd.Magnitude < 0.25 then fwd = Proj(cam.UpVector, up) end
            if fwd.Magnitude < 1e-3 and W.facing then fwd = Proj(W.facing, up) end
            if fwd.Magnitude < 1e-3 then fwd = Proj(Vector3.new(0, 0, -1), up) end
            if fwd.Magnitude < 1e-3 then fwd = Proj(Vector3.xAxis, up) end
            fwd = fwd.Unit
            local right = fwd:Cross(up)
            local ix, iz = 0, 0
            if not V8.Typing() then
                if Key(Enum.KeyCode.W) then iz = iz + 1 end
                if Key(Enum.KeyCode.S) then iz = iz - 1 end
                if Key(Enum.KeyCode.D) then ix = ix + 1 end
                if Key(Enum.KeyCode.A) then ix = ix - 1 end
            end
            local move = fwd * iz + right * ix
            if move.Magnitude > 1e-3 then move = move.Unit else move = Vector3.zero end
            local moving = move.Magnitude > 0
            local speed = math.max(0, State.WalkSpeed or 16)

            -- 1) parede à frente vira o chão
            if moving then
                local reach = root.Size.Z * 0.5 + 1.6
                local hit = workspace:Raycast(pos, move * reach, params)
                if hit and hit.Normal:Dot(up) < 0.6 then
                    local old = up
                    up = hit.Normal
                    W.up = up
                    pos = hit.Position + up * hip
                    W.fall, W.air = 0, 0
                    local f = Proj(old, up)
                    if f.Magnitude > 1e-3 then W.facing = f.Unit end
                    move = Vector3.zero   -- o próximo quadro já anda no plano novo
                end
            end

            -- 2) chão no "para baixo" atual
            local ground = workspace:Raycast(pos, -up * (hip + 1.5), params)
            if ground and W.fall <= 0 then
                if ground.Normal:Dot(up) > 0.3 then
                    up = up:Lerp(ground.Normal, math.min(1, dt * 12)).Unit
                    W.up = up
                end
                pos = ground.Position + up * hip
                W.fall, W.air = 0, 0
                if not V8.Typing() and Key(Enum.KeyCode.Space) then
                    W.fall = math.max(30, State.JumpPower or 50)
                end
            else
                -- 3) passou da quina: procura a face do outro lado da borda
                local wrapped = false
                if not ground and moving and W.fall <= 0 then
                    local probe = pos - up * (hip + 0.8) + move * 0.8
                    local hit = workspace:Raycast(probe, -move * 3, params)
                    if hit and hit.Normal:Dot(up) < 0.6 then
                        local old = up
                        up = hit.Normal
                        W.up = up
                        pos = hit.Position + up * hip
                        local f = Proj(-old, up)
                        if f.Magnitude > 1e-3 then W.facing = f.Unit end
                        W.fall, W.air = 0, 0
                        move = Vector3.zero
                        wrapped = true
                    end
                end
                if not wrapped then
                    if not ground then W.air = W.air + dt end
                    W.fall = math.max(W.fall - workspace.Gravity * dt, -150)
                    if W.air > 1.2 and up ~= Vector3.yAxis then
                        -- soltou da parede/teto: gravidade normal de novo
                        up = Vector3.yAxis
                        W.up = up
                        W.fall = math.min(W.fall, 0)
                    end
                end
            end

            local vel = move * speed + up * W.fall
            pos = pos + vel * dt

            -- frente do corpo: para onde anda (ou a última), sempre no plano
            if moving and move.Magnitude > 0 then W.facing = move end
            local face = Proj(W.facing or fwd, up)
            if face.Magnitude < 1e-3 then face = fwd end
            face = face.Unit
            local back = -face
            local target = CFrame.fromMatrix(Vector3.zero, up:Cross(back), up, back)
            W.rot = W.rot and W.rot:Lerp(target, math.min(1, dt * 14)) or target

            local cf = CFrame.new(pos) * W.rot
            root.CFrame = cf
            root.AssemblyAngularVelocity = Vector3.zero
            W.bv.Velocity = vel
            if W.bg then W.bg.CFrame = cf end

            -- anda com a animação de andar do jogo (parado = sem animação)
            if W.anim then
                local walking = moving and speed > 0
                if walking and not W.anim.IsPlaying then
                    pcall(function() W.anim:Play(0.15) end)
                elseif not walking and W.anim.IsPlaying then
                    pcall(function() W.anim:Stop(0.2) end)
                end
                if walking then pcall(function() W.anim:AdjustSpeed(speed / 16) end) end
            end
        end

        local function Start()
            local root, h, char = Root(), Hum(), Char()
            if not root or not h or not char then error("sem personagem") end
            for _, id in ipairs({ "fly", "drone", "freecam" }) do
                if IsOn(id) then SetToggle(id, false, true) end
            end
            Stop()
            params.FilterDescendantsInstances = { char }
            W.up = Vector3.yAxis
            W.fall, W.air = 0, 0
            W.facing = Proj(root.CFrame.LookVector, Vector3.yAxis)
            if W.facing.Magnitude < 1e-3 then W.facing = Vector3.new(0, 0, -1) end
            W.facing = W.facing.Unit

            -- colisão do corpo desligada: quem prende na superfície é o raio
            W.coll = {}
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    W.coll[p] = p.CanCollide
                    p.CanCollide = false
                end
            end

            -- BodyVelocity anula a gravidade do motor; BodyGyro segura a rotação
            local bv = Instance.new("BodyVelocity")
            bv.Name = "HYGE_WallWalk"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            W.bv = bv

            local bg = Instance.new("BodyGyro")
            bg.Name = "HYGE_WallGyro"
            bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bg.P = 30000
            bg.D = 500
            bg.CFrame = root.CFrame
            bg.Parent = root
            W.bg = bg

            W.anim = LoadWalk(h)
            Conn.WallWalk = RunService.RenderStepped:Connect(function(dt)
                local ok, err = pcall(Step, dt)
                if not ok then
                    Log("Walk on Walls: " .. tostring(err), "error")
                    SetToggle("wallwalk", false)
                end
            end)
        end

        DefineToggle({
            id = "wallwalk", label = "Walk on Walls",
            desc = "Anda em paredes e tetos (WASD; Space pula)",
            enable = Start, disable = Stop,
        })

        -- o personagem novo não tem as peças de controle: desliga e avisa
        Conn.WallRespawn = LocalPlayer.CharacterAdded:Connect(function()
            if IsOn("wallwalk") then
                SetToggle("wallwalk", false, true)
                Log("Walk on Walls desligado (respawn) — ligue de novo se quiser", "warn")
            end
        end)
    end
    Build()
end
end)
V8.Mod("src/20_features/11_clicktp.lua", 3806, 3859, function() --------------------------------------------------------------------------------
-- v8.2 — CTRL + CLIQUE TELEPORTA (Personagem › Movimento › Teleporte)
-- Com a função ligada, Ctrl + clique esquerdo leva o personagem até o ponto do
-- mapa embaixo do mouse. Clique em cima de GUI (painel, chat) não conta: o
-- Roblox marca esse clique como "processado" (gpe).
-- O raio sai da câmera e ignora o próprio personagem. O personagem chega em pé
-- na superfície (altura do quadril do rig) e continua olhando para o mesmo lado.
-- Tudo dentro do do..end: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Pick()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local pos = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(pos.X, pos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = Char() and { Char() } or {}
        return workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
    end

    local function Enable()
        Drop("ClickTp")
        Conn.ClickTp = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
            local r, h = Root(), Hum()
            if not r or not h then return end
            local hit = Pick()
            if not hit then
                Toast("Nada embaixo do mouse", "warn", 1.4)
                return
            end
            -- R15: centro do HumanoidRootPart fica HipHeight + meia altura acima
            -- do chão; R6 tem HipHeight 0 e pernas de 2 studs
            local stand = (h.RigType == Enum.HumanoidRigType.R15)
                and (h.HipHeight + r.Size.Y * 0.5) or 3
            local at = hit.Position + hit.Normal * 0.5 + Vector3.new(0, stand + 0.25, 0)
            local rot = r.CFrame - r.CFrame.Position
            TeleportTo(CFrame.new(at) * rot)
            pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
            V8.ClickTps = (V8.ClickTps or 0) + 1
            Log(string.format("TP clique -> %d, %d, %d", at.X, at.Y, at.Z), "action")
        end)
    end

    DefineToggle({
        id = "clicktp", label = "Ctrl + clique TP",
        desc = "Ctrl + clique esquerdo leva você até onde o mouse aponta",
        enable = Enable,
        disable = function() Drop("ClickTp") end,
    })
end
end)
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
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundTransparency = 1
    row.LayoutOrder = o.order or 10
    row.Parent = parent
    V8.Cell(row, 10)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -112, 0, 18)
    name.BackgroundTransparency = 1
    name.Text = o.label
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    -- v8.0: valor solto à direita (dá para digitar) + "R" redondo para resetar
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0)
    box.Position = UDim2.new(1, 0, 0, -1)
    box.Size = UDim2.new(0, 58, 0, 20)
    box.BackgroundColor3 = THEME.Btn
    box.BackgroundTransparency = 1
    box.Text = tostring(o.def)
    box.TextColor3 = THEME.Text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Right
    box.ClearTextOnFocus = false
    box.Parent = row
    Paint(box, "TextColor3", "Text")

    local reset = Instance.new("TextButton")
    reset.AnchorPoint = Vector2.new(1, 0)
    reset.Position = UDim2.new(1, -66, 0, -1)
    reset.Size = UDim2.new(0, 20, 0, 20)
    reset.BackgroundColor3 = THEME.Btn
    reset.Text = "R"
    reset.TextColor3 = THEME.Dim
    reset.Font = Enum.Font.GothamBold
    reset.TextSize = 10
    reset.AutoButtonColor = false
    reset.Parent = row
    Paint(reset, "BackgroundColor3", "Btn")
    Paint(reset, "TextColor3", "Dim")
    Instance.new("UICorner", reset).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 30)
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

    -- v9.1: o arrasto vai para Conn (um slider por vez): se o painel
    -- descarregar no meio do arrasto, o Unload desconecta
    bar.MouseButton1Down:Connect(function()
        local function fromInput(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)
                / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            apply(minV + rel * (maxV - minV))
        end
        Anim(knob, 0.1, { Size = UDim2.new(0, 18, 0, 18) })
        Drop("SliderMove")
        Drop("SliderEnd")
        Conn.SliderMove = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                fromInput(input)
            end
        end)
        Conn.SliderEnd = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                Drop("SliderMove")
                Drop("SliderEnd")
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
    row.Size = UDim2.new(1, 0, 0, description and 56 or 44)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 10
    row.Parent = parent
    V8.Cell(row, 5)   -- v8.0: cartão

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -66, 0, 18)
    name.Position = UDim2.new(0, 0, 0, description and 4 or 8)
    name.BackgroundTransparency = 1
    name.Text = labelText
    name.TextColor3 = THEME.Text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row
    Paint(name, "TextColor3", "Text")

    if description then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -66, 0, 14)
        d.Position = UDim2.new(0, 0, 0, 24)
        d.BackgroundTransparency = 1
        d.Text = description
        d.TextColor3 = THEME.Dim
        d.Font = Enum.Font.GothamMedium
        d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextTruncate = Enum.TextTruncate.AtEnd
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
    knob.BackgroundColor3 = THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- v8.0: mesmo esquema do SwitchRow (bolinha escura no ligado)
    local function render()
        local on = not not get()
        Anim(track, 0.15, { BackgroundColor3 = on and THEME.Accent or THEME.Track })
        Anim(knob, 0.15, {
            Position = on and UDim2.new(1, -18, 0.5, -7.5) or UDim2.new(0, 3, 0.5, -7.5),
            BackgroundColor3 = on and THEME.Main or THEME.Text })
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
        b.Text = text .. " (servidor)"
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

V8.Mod("src/30_kit/01_icons.lua", 4319, 4436, function() --------------------------------------------------------------------------------
-- ÍCONES VETORIAIS
-- Sem asset: cada ícone é um punhado de Frames posicionados numa grade 24x24 e
-- escalados. shape = { x, y, w, h, rot, corner, outline }
--------------------------------------------------------------------------------
do
    local S = {
        -- v8.0: casinha em contorno (telhado em ^, paredes, chão e porta)
        home   = { {0.5,6.5,13.5,2,-43,1}, {10,6.5,13.5,2,43,1}, {5,11,2,11,0,1},
                   {17,11,2,11,0,1}, {5,20,14,2,0,1}, {10,15,4,7,0,1,1} },
        run    = { {13,1,6,6,0,3}, {6,7,3,10,-25,2}, {12,9,3,11,20,2}, {3,12,9,3,15,2} },
        eye    = { {2,6,20,12,0,6,1}, {9,9,6,6,0,3} },
        -- v8.0: duas pessoas em contorno (a de trás menor, sem se cruzarem)
        users  = { {3,3,8,8,0,4,1}, {1,13,12,9,0,5,1}, {14,4,7,7,0,4,1},
                   {15,14,8,8,0,4,1} },
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
        -- v8.1: Troll, Playtime Shop, Emotes e botões da Home
        mask     = { {2,4,20,16,0,8,1}, {5.5,8.5,5,2,20,1}, {13.5,8.5,5,2,-20,1},
                     {7,14,10,3,0,2} },
        star     = { {6,6,12,12,0,2}, {6,6,12,12,45,2} },
        crown    = { {4,15,16,4,0,1}, {4,7,3.5,10,0,1}, {10.25,4,3.5,13,0,1},
                     {16.5,7,3.5,10,0,1} },
        heart    = { {3,5,10,10,0,5}, {11,5,10,10,0,5}, {6.5,8.5,11,11,45,2} },
        gem      = { {6,6,12,12,45,2} },
        play     = { {7,5,2.5,14,0,1}, {7.45,7.25,12.6,2.5,33.7,1},
                     {7.45,14.25,12.6,2.5,-33.7,1} },
        swap     = { {3,6,16,2.5,0,1}, {14.5,3.5,6,2.5,40,1},
                     {5,15.5,16,2.5,0,1}, {3.5,18,6,2.5,40,1} },
        link     = { {2,8,11,8,0,4,1}, {11,8,11,8,0,4,1} },
        -- v9.0: notificações, macros, perfis
        bell     = { {6,4,12,13,0,6,1}, {3,15,18,2.5,0,1}, {10,19,4,3,0,1.5},
                     {11,1.5,2,3,0,1} },
        keyboard = { {2,6,20,13,0,3,1}, {5,9,2.5,2.5,0,0.5}, {9,9,2.5,2.5,0,0.5},
                     {13,9,2.5,2.5,0,0.5}, {17,9,2.5,2.5,0,0.5}, {7,14,10,2,0,1} },
        layers   = { {4,3,16,7,0,2,1}, {4,9,16,7,0,2,1}, {4,15,16,6,0,2,1} },
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
end)
V8.Mod("src/30_kit/02_topbar_chips.lua", 4438, 4517, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/30_kit/03_drone_hud.lua", 4519, 4906, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/30_kit/04_net.lua", 4908, 5137, function() --------------------------------------------------------------------------------
-- v8.1 — REDE E DISCO (helpers do executor)
--
-- O Roblox não deixa LocalScript fazer HTTP. Executores expõem request()
-- (ou http_request / syn.request / http.request) e game:HttpGet. Tudo aqui é
-- testado antes de usar: sem suporte, quem chama recebe nil + o motivo — nunca
-- uma resposta inventada. Usado pela troca de servidor (Início) e pelo chat
-- HYGE (Chat › HYGE).
-- V8.Disk lê/grava arquivos pequenos na pasta do executor (playtime da loja).
-- Tudo em V8.Net / V8.Disk: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    V8.Net = {}
    V8.Disk = {}
    local N, D = V8.Net, V8.Disk

    N.Http = nil
    pcall(function() N.Http = game:GetService("HttpService") end)

    -- a função request do executor (a primeira que existir), ou nil
    N.Fn = function()
        if typeof(request) == "function" then return request end
        if typeof(http_request) == "function" then return http_request end
        if typeof(syn) == "table" and typeof(syn.request) == "function" then return syn.request end
        if typeof(http) == "table" and typeof(http.request) == "function" then return http.request end
        return nil
    end

    N.CanPost = function() return N.Fn() ~= nil end

    N.Encode = function(s)
        local ok, r = pcall(function() return N.Http:UrlEncode(tostring(s)) end)
        if ok and type(r) == "string" then return r end
        return (tostring(s):gsub("[^%w%-_%.~]", function(c)
            return string.format("%%%02X", string.byte(c))
        end))
    end

    -- devolve ok, corpo (ou o erro), status
    N.Request = function(method, url, body, headers)
        local fn = N.Fn()
        if fn then
            local ok, res = pcall(fn, { Url = url, Method = method,
                Headers = headers or {}, Body = body })
            if not ok then return false, tostring(res), 0 end
            if type(res) ~= "table" then return false, "resposta vazia do executor", 0 end
            local code = tonumber(res.StatusCode) or 0
            local good = (code >= 200 and code < 300) or (code == 0 and res.Success == true)
            return good, tostring(res.Body or ""), code
        end
        if method == "GET" then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" then return true, res, 200 end
            return false, "executor sem HTTP (nem request() nem game:HttpGet)", 0
        end
        return false, "executor sem request(): só dá para ler, não para enviar", 0
    end

    -- JSON de ida e volta. Devolve a tabela ou nil + motivo
    N.Json = function(method, url, tbl)
        if not N.Http then return nil, "HttpService indisponível" end
        local body, headers
        if tbl ~= nil then
            local ok, enc = pcall(function() return N.Http:JSONEncode(tbl) end)
            if not ok then return nil, "JSON: " .. tostring(enc) end
            body = enc
            headers = { ["Content-Type"] = "application/json" }
        end
        local ok, res, code = N.Request(method, url, body, headers)
        if not ok then
            local why = tostring(res)
            if #why > 120 then why = why:sub(1, 120) .. "…" end
            return nil, (code and code > 0 and ("HTTP " .. code .. ": ") or "") .. why
        end
        local okD, data = pcall(function() return N.Http:JSONDecode(res) end)
        if not okD or type(data) ~= "table" then return nil, "a resposta não é JSON" end
        return data
    end

    ----------------------------------------------------------------------------
    -- disco
    ----------------------------------------------------------------------------
    D.Ok = function()
        return typeof(writefile) == "function" and typeof(readfile) == "function"
            and typeof(isfile) == "function"
    end

    D.Read = function(path)
        if not D.Ok() then return nil, "executor sem readfile" end
        local exists = false
        pcall(function() exists = isfile(path) end)
        if not exists then return nil, "arquivo não existe" end
        local ok, raw = pcall(function() return readfile(path) end)
        if ok and type(raw) == "string" then return raw end
        return nil, "falha ao ler " .. path
    end

    D.Write = function(path, text)
        if not D.Ok() then return false, "executor sem writefile" end
        local ok, err = pcall(function()
            local folder = path:match("^(.+)/[^/]+$")
            if folder and typeof(makefolder) == "function" then
                local has = false
                if typeof(isfolder) == "function" then
                    pcall(function() has = isfolder(folder) end)
                end
                if not has then pcall(function() makefolder(folder) end) end
            end
            writefile(path, text)
        end)
        if ok then return true end
        return false, tostring(err)
    end

    D.Exists = function(path)
        if not D.Ok() then return false end
        local ok, has = pcall(function() return isfile(path) end)
        return ok and has == true
    end

    -- sem delfile no executor, o arquivo fica (quem lê sabe lidar)
    D.Delete = function(path)
        if typeof(delfile) ~= "function" then return false end
        return (pcall(function() delfile(path) end))
    end

    ----------------------------------------------------------------------------
    -- v9.1 — GRAVAÇÃO SEGURA (config.json, profiles.json)
    -- Executor não tem "renomear", então não dá para trocar o arquivo de forma
    -- atômica. A estratégia é nunca ficar sem uma cópia boa:
    --   1. a versão nova vai inteira para <nome>.tmp e é conferida (relida)
    --   2. a versão atual, SE for válida, vira <nome>.backup.json (conferida);
    --      um principal estragado nunca apaga um backup bom
    --   3. a versão nova vai para o principal (conferida)
    --   4. o .tmp é apagado
    -- Caiu no meio? Sempre sobra o principal válido, ou o .tmp (a nova
    -- completa), ou o backup (a anterior). D.SafeRead acha qual.
    -- check(text) diz se o conteúdo é válido (ex.: decodifica o JSON).
    ----------------------------------------------------------------------------
    D.Paths = function(path)
        local base = path:gsub("%.json$", "")
        return base .. ".backup.json", base .. ".tmp", base .. ".corrupt.json"
    end

    local function Valid(text, check)
        if type(text) ~= "string" or text == "" then return false end
        if not check then return true end
        local ok, good = pcall(check, text)
        return ok and good == true
    end

    -- releu igual? (ou, se o executor mexer em algo, continua válido e inteiro)
    local function Verify(path, text, check)
        local back = D.Read(path)
        if back == text then return true end
        return check ~= nil and back ~= nil and #back >= #text and Valid(back, check)
    end

    D.SafeWrite = function(path, text, check)
        if not D.Ok() then return false, "executor sem writefile" end
        if not Valid(text, check) then return false, "conteúdo inválido (nada foi gravado)" end
        local bak, tmp, bad = D.Paths(path)

        local ok, err = D.Write(tmp, text)
        if not ok or not Verify(tmp, text, check) then
            D.Delete(tmp)
            return false, "não deu para gravar o temporário (" .. tostring(err or "conferência falhou")
                .. ") — nada foi trocado"
        end

        local cur = D.Exists(path) and D.Read(path) or nil
        if cur ~= nil and cur ~= text then
            if Valid(cur, check) then
                local okB = D.Write(bak, cur)
                if not okB or not Verify(bak, cur, check) then
                    D.Delete(tmp)
                    return false, "não deu para criar o backup — nada foi trocado"
                end
            elseif cur ~= "" then
                -- o principal já estava estragado: guarda para análise, não
                -- vira backup (o backup bom que existir continua lá)
                D.Write(bad, cur)
            end
        end

        local okM, errM = D.Write(path, text)
        if not okM or not Verify(path, text, check) then
            return false, "falhou ao gravar " .. path .. " (" .. tostring(errM or "conferência falhou")
                .. ") — a versão nova ficou em " .. tmp .. " e a anterior em " .. bak
        end
        D.Delete(tmp)
        return true
    end

    -- Lê o principal e diz o que sobrou para recuperar.
    -- Devolve { state = "ok"|"missing"|"corrupt", text = principal válido,
    --           raw = principal como veio, recover = { {path, text, label} } }
    -- recover só vem preenchido quando o principal não presta: o .tmp primeiro
    -- (versão nova que não terminou de ir para o principal), depois o backup.
    D.SafeRead = function(path, check)
        local r = { state = "missing", recover = {} }
        if not D.Ok() then return r end
        local bak, tmp = D.Paths(path)
        if D.Exists(path) then
            r.raw = D.Read(path)
            if Valid(r.raw, check) then
                r.state, r.text = "ok", r.raw
                -- .tmp que sobrou de uma gravação que terminou (ou executor
                -- sem delfile): não serve para nada
                if D.Exists(tmp) then D.Delete(tmp) end
                return r
            end
            r.state = "corrupt"
        end
        for _, c in ipairs({ { tmp, "gravação interrompida (mais nova)" }, { bak, "backup (anterior)" } }) do
            local s = D.Exists(c[1]) and D.Read(c[1]) or nil
            if Valid(s, check) and s ~= r.raw then
                table.insert(r.recover, { path = c[1], text = s, label = c[2] })
            end
        end
        return r
    end

    -- troca o principal pela cópia escolhida (o SafeWrite guarda o estragado
    -- em .corrupt.json antes)
    D.Recover = function(path, text, check)
        if not Valid(text, check) then return false, "a cópia escolhida não é válida" end
        return D.SafeWrite(path, text, check)
    end
end
end)
V8.Mod("src/30_kit/05_playtime.lua", 5139, 5636, function() --------------------------------------------------------------------------------
-- v8.1 — TEMPO DE JOGO + COSMÉTICOS (base da Playtime Shop)
--
-- Moeda da loja = tempo com o HYGE aberto: 1 ponto por minuto. O total vai em
-- HYGE/playtime.json (arquivo próprio, gravado a cada minuto e no Unload —
-- separado da config para não depender do "salvar ao fechar"). Executor sem
-- writefile: conta só a sessão atual, e a loja avisa.
--
-- Tudo o que a loja vende é visual e local:
--   Ranks / Icons / Titles  -> aparecem no painel (perfil da Home, chat HYGE)
--   Effects / Nametags      -> criados no SEU personagem pelo SEU cliente:
--                              só você vê (instância criada no cliente não
--                              replica para os outros)
--   Bundles                 -> pacotes; o preço cai pelo que você já tem
-- Nada aqui é vendido por Robux nem mexe em dados do jogo.
--
-- V8.Play = dados + regras; V8.Cos = efeitos/nametag no personagem.
-- A UI fica em 40_tabs/09_shop.lua. Zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Play = {
            Total = 0,            -- segundos acumulados (todas as sessões)
            Spent = 0,            -- pontos gastos
            Bonus = 0,            -- pontos dados à mão (givepoints) e por missões
            Quests = nil,         -- v8.2: progresso das missões (50_v8/08_quests.lua)
            Owned = {},           -- [itemId] = true
            Equip = {},           -- [slot] = itemId
            Path = "HYGE/playtime.json",
            Start = os.clock(),
            Listeners = {},
            Status = "",
        }
        local P = V8.Play

        P.Cats = { "All", "Ranks", "Icons", "Titles", "Effects", "Nametags", "Bundles" }
        P.SlotOf = { Ranks = "rank", Icons = "icon", Titles = "title",
                     Effects = "effect", Nametags = "nametag" }

        -- preço em pontos (= minutos jogados com o painel aberto)
        P.Items = {
            -- Ranks
            { id = "rank_bronze",   cat = "Ranks", name = "Bronze",   price = 30,
              color = Color3.fromRGB(205, 127, 50),  desc = "O primeiro degrau" },
            { id = "rank_prata",    cat = "Ranks", name = "Prata",    price = 120,
              color = Color3.fromRGB(196, 200, 210), desc = "Duas horas de casa" },
            { id = "rank_ouro",     cat = "Ranks", name = "Ouro",     price = 360,
              color = Color3.fromRGB(255, 200, 60),  desc = "Seis horas de casa" },
            { id = "rank_platina",  cat = "Ranks", name = "Platina",  price = 900,
              color = Color3.fromRGB(140, 228, 228), desc = "Quinze horas de casa" },
            { id = "rank_diamante", cat = "Ranks", name = "Diamante", price = 1800,
              color = Color3.fromRGB(110, 175, 255), desc = "Trinta horas de casa" },
            { id = "rank_lenda",    cat = "Ranks", name = "Lenda",    price = 3600,
              color = Color3.fromRGB(255, 90, 120),  desc = "Sessenta horas de casa" },
            -- Icons (desenho vetorial ao lado do seu nome no painel)
            { id = "icon_bolt",  cat = "Icons", name = "Raio",     price = 20,  icon = "bolt" },
            { id = "icon_star",  cat = "Icons", name = "Estrela",  price = 45,  icon = "star" },
            { id = "icon_heart", cat = "Icons", name = "Coração",  price = 45,  icon = "heart" },
            { id = "icon_ghost", cat = "Icons", name = "Fantasma", price = 90,  icon = "ghost" },
            { id = "icon_gem",   cat = "Icons", name = "Joia",     price = 240, icon = "gem" },
            { id = "icon_crown", cat = "Icons", name = "Coroa",    price = 600, icon = "crown" },
            -- Titles
            { id = "title_novato",     cat = "Titles", name = "Novato",          price = 10 },
            { id = "title_explorador", cat = "Titles", name = "Explorador",      price = 60 },
            { id = "title_coruja",     cat = "Titles", name = "Coruja Noturna",  price = 180 },
            { id = "title_veterano",   cat = "Titles", name = "Veterano",        price = 480 },
            { id = "title_sem_vida",   cat = "Titles", name = "Sem Vida Social", price = 1200 },
            { id = "title_lenda",      cat = "Titles", name = "Lenda do HYGE",   price = 3000 },
            -- Effects (no seu personagem, só você vê)
            { id = "fx_brilho",  cat = "Effects", name = "Brilho",  price = 40,  fx = "light",
              desc = "Luz em volta do personagem" },
            { id = "fx_faiscas", cat = "Effects", name = "Faíscas", price = 90,  fx = "sparkles",
              desc = "Faíscas saindo do corpo" },
            { id = "fx_rastro",  cat = "Effects", name = "Rastro",  price = 150, fx = "trail",
              desc = "Rastro de luz ao andar" },
            { id = "fx_aura",    cat = "Effects", name = "Aura",    price = 300, fx = "aura",
              desc = "Partículas flutuando em volta" },
            { id = "fx_fogo",    cat = "Effects", name = "Fogo",    price = 500, fx = "fire",
              desc = "Chamas no corpo (não queima)" },
            -- Nametags (placa acima da cabeça, só você vê)
            { id = "tag_classica",  cat = "Nametags", name = "Clássica",  price = 25,  style = "classic",
              desc = "Fundo escuro, texto branco" },
            { id = "tag_neon",      cat = "Nametags", name = "Neon",      price = 120, style = "neon",
              desc = "Contorno brilhante na cor do tema" },
            { id = "tag_dourada",   cat = "Nametags", name = "Dourada",   price = 420, style = "gold",
              desc = "Texto dourado" },
            { id = "tag_arcoiris",  cat = "Nametags", name = "Arco-íris", price = 900, style = "rainbow",
              desc = "Cores correndo pelo nome" },
            -- Bundles
            { id = "pack_inicio",   cat = "Bundles", name = "Pacote Início",   price = 50,
              items = { "rank_bronze", "icon_bolt", "title_novato", "tag_classica" } },
            { id = "pack_veterano", cat = "Bundles", name = "Pacote Veterano", price = 900,
              items = { "rank_ouro", "icon_ghost", "title_veterano", "fx_rastro" } },
            { id = "pack_lenda",    cat = "Bundles", name = "Pacote Lenda",    price = 6900,
              items = { "rank_lenda", "icon_crown", "title_lenda", "fx_fogo", "tag_arcoiris" } },
        }
        P.ById = {}
        for i, it in ipairs(P.Items) do
            it.order = i
            P.ById[it.id] = it
        end

        ----------------------------------------------------------------------------
        -- consultas
        ----------------------------------------------------------------------------
        P.Points = function()
            return math.max(0, math.floor(P.Total / 60) + P.Bonus - P.Spent)
        end
        P.Session = function() return os.clock() - P.Start end

        P.Fmt = function(sec)
            sec = math.max(0, math.floor(tonumber(sec) or 0))
            local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
            if h > 0 then return h .. "h " .. string.format("%02d", m) .. "min" end
            if m > 0 then return m .. "min" end
            return sec .. "s"
        end

        P.Equipped = function(slot)
            local id = P.Equip[slot]
            return id and P.ById[id] or nil
        end

        -- pacote: preço proporcional ao que ainda falta
        P.BundlePrice = function(it)
            local full, missing, have = 0, 0, 0
            for _, sub in ipairs(it.items or {}) do
                local s = P.ById[sub]
                if s then
                    full = full + s.price
                    if P.Owned[sub] then have = have + 1 else missing = missing + s.price end
                end
            end
            local price = (full > 0) and math.ceil(it.price * missing / full) or it.price
            return price, have, #(it.items or {})
        end

        P.PriceOf = function(it)
            if it.cat == "Bundles" then return (P.BundlePrice(it)) end
            return it.price
        end

        -- "Ouro · Veterano" (rank e título equipados)
        P.Line = function()
            local parts = {}
            local r, t = P.Equipped("rank"), P.Equipped("title")
            if r then table.insert(parts, r.name) end
            if t then table.insert(parts, t.name) end
            return table.concat(parts, " · ")
        end

        P.OnChange = function(fn) table.insert(P.Listeners, fn) end
        P.Changed = function()
            for _, fn in ipairs(P.Listeners) do pcall(fn) end
        end

        ----------------------------------------------------------------------------
        -- disco
        ----------------------------------------------------------------------------
        P.Save = function(silent)
            local Http = V8.Net and V8.Net.Http
            if not Http then return false end
            local owned = {}
            for id in pairs(P.Owned) do table.insert(owned, id) end
            table.sort(owned)
            local ok, json = pcall(function()
                return Http:JSONEncode({ v = 1, total = math.floor(P.Total),
                    spent = P.Spent, bonus = P.Bonus, owned = owned, equip = P.Equip,
                    quests = P.Quests })
            end)
            if not ok then return false end
            -- v9.1: gravação segura (temporário + backup), igual à config
            local wrote, err = V8.Disk.SafeWrite(P.Path, json, P.JsonOk)
            if not wrote and not silent then
                Log("Playtime não foi salvo: " .. tostring(err), "error")
            end
            return wrote
        end

        P.JsonOk = function(s)
            local ok, d = pcall(function() return V8.Net.Http:JSONDecode(s) end)
            return ok and type(d) == "table"
        end

        P.Load = function()
            -- v9.1: estragado -> volta do .tmp/backup (antes: começava do zero)
            local r = V8.Disk.SafeRead(P.Path, P.JsonOk)
            local raw = r.text
            if r.state == "corrupt" and r.recover[1] then
                raw = r.recover[1].text
                V8.Disk.Recover(P.Path, raw, P.JsonOk)
                Log("playtime.json estragado — recuperado do " .. r.recover[1].label, "warn")
            end
            if not raw then
                P.Status = (r.state == "corrupt")
                    and "playtime.json ilegível e sem backup — começando do zero (o antigo fica em playtime.corrupt.json)."
                    or (V8.Disk.Ok() and "Primeira sessão: o contador começa agora."
                    or "Executor sem writefile/readfile: o tempo desta sessão se perde ao sair.")
                return false, r.state
            end
            local ok, d = pcall(function() return V8.Net.Http:JSONDecode(raw) end)
            if not ok or type(d) ~= "table" then
                P.Status = "playtime.json ilegível — começando do zero."
                return false
            end
            local total = tonumber(d.total)
            if total and total >= 0 and total < 1e9 then P.Total = total end
            local spent = tonumber(d.spent)
            if spent and spent >= 0 and spent < 1e9 then P.Spent = math.floor(spent) end
            local bonus = tonumber(d.bonus)
            if bonus and bonus >= 0 and bonus < 1e9 then P.Bonus = math.floor(bonus) end
            if type(d.quests) == "table" then P.Quests = d.quests end   -- validado em 08_quests
            if type(d.owned) == "table" then
                for _, id in ipairs(d.owned) do
                    if type(id) == "string" and P.ById[id] then P.Owned[id] = true end
                end
            end
            if type(d.equip) == "table" then
                for slot, id in pairs(d.equip) do
                    local it = type(id) == "string" and P.ById[id]
                    if it and P.Owned[id] and P.SlotOf[it.cat] == slot then P.Equip[slot] = id end
                end
            end
            P.Status = "Salvo em " .. P.Path .. " a cada minuto."
            return true
        end

        ----------------------------------------------------------------------------
        -- compra / equipar
        ----------------------------------------------------------------------------
        P.Buy = function(id)
            local it = P.ById[id]
            if not it then return false, "item desconhecido" end
            local price = P.PriceOf(it)
            if it.cat == "Bundles" then
                local _, have, total = P.BundlePrice(it)
                if have >= total then return false, "você já tem tudo deste pacote" end
            elseif P.Owned[id] then
                return false, "você já tem este item"
            end
            local pts = P.Points()
            if pts < price then return false, "faltam " .. (price - pts) .. " ponto(s)" end
            P.Spent = P.Spent + price
            P.Owned[id] = true
            for _, sub in ipairs(it.items or {}) do
                if P.ById[sub] then P.Owned[sub] = true end
            end
            P.Save(true)
            P.Changed()
            return true, price
        end

        -- pontos que faltam para comprar tudo o que ainda não é seu
        P.MissingCost = function()
            local sum = 0
            for _, it in ipairs(P.Items) do
                if it.cat ~= "Bundles" and not P.Owned[it.id] then sum = sum + it.price end
            end
            return sum
        end

        -- soma pontos sem mexer no tempo de jogo (Total continua honesto)
        P.Grant = function(n)
            n = math.floor(tonumber(n) or 0)
            if n <= 0 then return false end
            P.Bonus = math.min(P.Bonus + n, 1e9 - 1)
            P.Save(true)
            P.Changed()
            return true, n
        end

        -- libera todos os itens de graça (não gasta pontos)
        P.UnlockAll = function()
            local n = 0
            for _, it in ipairs(P.Items) do
                if not P.Owned[it.id] then P.Owned[it.id] = true n = n + 1 end
            end
            P.Save(true)
            P.Changed()
            return n
        end

        P.EquipItem = function(id)
            local it = P.ById[id]
            local slot = it and P.SlotOf[it.cat]
            if not slot or not P.Owned[id] then return false end
            P.Equip[slot] = id
            P.Save(true)
            P.Changed()
            return true
        end

        P.Unequip = function(slot)
            if not P.Equip[slot] then return end
            P.Equip[slot] = nil
            P.Save(true)
            P.Changed()
        end

        P.UnequipAll = function()
            for k in pairs(P.Equip) do P.Equip[k] = nil end
            P.Save(true)
            P.Changed()
        end

        -- contador: o scheduler roda os dois (V8.Job), sem loop próprio
        do
            local last = os.clock()
            V8.Job(1, function()
                local now = os.clock()
                P.Total = P.Total + math.clamp(now - last, 0, 5)
                last = now
            end)
        end
        V8.Job(60, function() P.Save(true) end)

        P.Load()

        ----------------------------------------------------------------------------
        -- COSMÉTICOS NO PERSONAGEM (efeito + nametag equipados)
        ----------------------------------------------------------------------------
        V8.Cos = { fx = {}, tag = nil }
        local C = V8.Cos

        C.Clear = function()
            for _, inst in ipairs(C.fx) do pcall(function() inst:Destroy() end) end
            C.fx = {}
            if C.tag then pcall(function() C.tag:Destroy() end) end
            C.tag = nil
        end

        local function Keep(inst)
            table.insert(C.fx, inst)
            return inst
        end

        local function Effect(root, kind)
            local accent = THEME.Accent
            if kind == "light" then
                local l = Keep(Instance.new("PointLight"))
                l.Brightness = 1.6
                l.Range = 14
                l.Color = accent
                l.Shadows = false
                l.Parent = root
            elseif kind == "sparkles" then
                local s = Keep(Instance.new("Sparkles"))
                s.SparkleColor = accent
                s.Parent = root
            elseif kind == "trail" then
                local a0 = Keep(Instance.new("Attachment"))
                a0.Name = "HYGE_TrailTop"
                a0.Position = Vector3.new(0, 1.1, 0)
                a0.Parent = root
                local a1 = Keep(Instance.new("Attachment"))
                a1.Name = "HYGE_TrailBottom"
                a1.Position = Vector3.new(0, -1.1, 0)
                a1.Parent = root
                local t = Keep(Instance.new("Trail"))
                t.Attachment0 = a0
                t.Attachment1 = a1
                t.Lifetime = 0.45
                t.MinLength = 0.05
                t.FaceCamera = true
                t.LightEmission = 0.6
                t.Color = ColorSequence.new(accent)
                t.Transparency = NumberSequence.new(0.2, 1)
                t.Parent = root
            elseif kind == "aura" then
                local e = Keep(Instance.new("ParticleEmitter"))
                e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                e.Color = ColorSequence.new(accent)
                e.LightEmission = 0.7
                e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5),
                    NumberSequenceKeypoint.new(1, 0) })
                e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 1) })
                e.Lifetime = NumberRange.new(0.8, 1.4)
                e.Rate = 22
                e.Speed = NumberRange.new(0.5, 1.5)
                e.SpreadAngle = Vector2.new(180, 180)
                e.Rotation = NumberRange.new(0, 360)
                e.RotSpeed = NumberRange.new(-90, 90)
                e.Parent = root
            elseif kind == "fire" then
                local f = Keep(Instance.new("Fire"))
                f.Size = 3.5
                f.Heat = 4
                f.Color = Color3.fromRGB(255, 140, 40)
                f.SecondaryColor = Color3.fromRGB(255, 60, 20)
                f.Parent = root
            end
        end

        local function Nametag(head, style)
            local bb = Instance.new("BillboardGui")
            bb.Name = "HYGE_Nametag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 220, 0, 46)
            bb.StudsOffset = Vector3.new(0, 3.6, 0)
            bb.MaxDistance = 150
            bb.LightInfluence = 0
            bb.Parent = head

            local rank = P.Equipped("rank")
            local title = P.Equipped("title")
            local name = LocalPlayer.DisplayName or LocalPlayer.Name
            if rank then name = "[" .. rank.name .. "] " .. name end

            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.BackgroundColor3 = Color3.new(0, 0, 0)
            holder.BackgroundTransparency = (style == "classic") and 0.45 or 1
            holder.BorderSizePixel = 0
            holder.Parent = bb
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 10)

            local top = Instance.new("TextLabel")
            top.Size = UDim2.new(1, 0, 0, title and 26 or 46)
            top.BackgroundTransparency = 1
            top.Text = name
            top.Font = Enum.Font.GothamBlack
            top.TextSize = 18
            top.TextColor3 = Color3.new(1, 1, 1)
            top.TextStrokeTransparency = 0.5
            top.Parent = holder

            if title then
                local sub = Instance.new("TextLabel")
                sub.Size = UDim2.new(1, 0, 0, 18)
                sub.Position = UDim2.new(0, 0, 0, 26)
                sub.BackgroundTransparency = 1
                sub.Text = title.name
                sub.Font = Enum.Font.GothamBold
                sub.TextSize = 13
                sub.TextColor3 = Color3.fromRGB(220, 220, 228)
                sub.TextStrokeTransparency = 0.6
                sub.Parent = holder
            end

            if rank and rank.color and style == "classic" then
                top.TextColor3 = rank.color
            elseif style == "neon" then
                top.TextStrokeTransparency = 1
                local st = Instance.new("UIStroke", top)
                st.Thickness = 2
                st.Color = THEME.Accent
                st.Transparency = 0.15
            elseif style == "gold" then
                top.TextColor3 = Color3.fromRGB(255, 205, 80)
                top.TextStrokeColor3 = Color3.fromRGB(90, 55, 10)
                top.TextStrokeTransparency = 0.2
            elseif style == "rainbow" then
                local g = Instance.new("UIGradient", top)
                g.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
                    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 230, 90)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(160, 100, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 70)),
                })
                g.Offset = Vector2.new(-0.5, 0)
                -- tween infinito (vai e volta): nenhum loop do painel envolvido
                TweenService:Create(g, TweenInfo.new(2.5, Enum.EasingStyle.Linear,
                    Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.5, 0) }):Play()
            end
            return bb
        end

        C.Apply = function()
            C.Clear()
            local char = Char()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local fx = P.Equipped("effect")
            if fx and root then pcall(Effect, root, fx.fx) end
            local tag = P.Equipped("nametag")
            if tag and head then
                local ok, bb = pcall(Nametag, head, tag.style)
                if ok then C.tag = bb end
            end
        end

        Conn.CosChar = LocalPlayer.CharacterAdded:Connect(function(char)
            pcall(function()
                char:WaitForChild("HumanoidRootPart", 5)
                char:WaitForChild("Head", 5)
            end)
            pcall(C.Apply)
        end)
        P.OnChange(function() pcall(C.Apply) end)
        -- troca de tema: efeitos na cor nova (V8.Renders roda no ApplyTheme)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(C.Apply) end)
    end
    Build()
end
end)
V8.Mod("src/30_kit/06_animpack.lua", 5638, 6162, function() --------------------------------------------------------------------------------
-- v8.2 — PACOTES DE ANIMAÇÃO (motor; a UI fica em 40_tabs/02_movement_pack.lua)
--
-- Um pacote (bundle) do catálogo é uma lista de itens: Idle, Walk, Run, Jump,
-- Fall, Climb, Swim. Cada item é uma "caixa" (Folder > StringValue "run" >
-- Animation) e o que toca é o AnimationId de dentro. Para ler um pacote:
--   1. a lista de itens: AssetService:GetBundleDetailsAsync (API do Roblox)
--      ou, se o jogo não deixar, o catálogo público pelo HTTP do executor
--   2. cada item: game:GetObjects (executor) abre a caixa
-- O resultado (AnimationId por animação) vai na config (SET.Packs): da segunda
-- vez em diante não precisa de rede. Os dois pacotes que já vêm na lista têm os
-- itens conferidos no catálogo, então só o passo 2 roda.
--
-- USAR no personagem = trocar os AnimationId do script Animate do SEU
-- personagem e reiniciar o Animate. As animações tocam pelo seu Animator,
-- então os outros jogadores veem (igual a um pacote equipado no avatar). Só
-- R15 e só em jogo com o Animate padrão — quando não dá, o painel diz por quê.
-- Os IDs originais ficam guardados: "voltar ao normal" devolve tudo.
--
-- VOO: o Fly (estilo "pacote") pede K.FlyIds() — fall voando e idle parado, do
-- pacote marcado como VOO (SET.FlyPack) ou do CONFIG.FlyPackBundle.
-- Tudo em V8.Pack: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Pack = { busy = {}, fail = {}, waiters = {}, temp = {},
                    orig = {}, origChar = nil, Listeners = {} }
        local K = V8.Pack

        K.Slots = { "idle", "walk", "run", "jump", "fall", "climb", "swim" }
        K.SlotName = { idle = "parado", walk = "andar", run = "correr", jump = "pular",
            fall = "cair", climb = "escalar", swim = "nadar" }
        local IS_SLOT = {}
        for _, s in ipairs(K.Slots) do IS_SLOT[s] = true end

        K.OnChange = function(fn) table.insert(K.Listeners, fn) end
        K.Changed = function()
            for _, fn in ipairs(K.Listeners) do pcall(fn) end
        end

        -- ID grande (14-15 dígitos) sempre como texto: nem o JSON da config nem
        -- o tostring viram notação científica
        local function IdStr(v)
            if type(v) == "number" then
                if v ~= v or v < 1 or v >= 2 ^ 53 then return nil end
                return string.format("%d", v)
            end
            if v == nil then return nil end
            return tostring(v):match("(%d%d%d%d+)")
        end
        K.IdStr = IdStr

        -- aceita "60179708829279", "rbxassetid://..." e o link do catálogo
        -- (roblox.com/pt/bundles/60179708829279/Nome?pid=share...)
        K.Parse = function(raw)
            local s = tostring(raw or "")
            return s:match("bundles/(%d+)") or s:match("(%d%d%d%d%d+)")
        end

        -- pacotes que já vêm na lista (itens conferidos no catálogo)
        local SEED = {
            { id = "60179708829279", name = "Super Gogeta DBZ", items = {
                idle = "110189334321552", walk = "71567557250866", run = "95473441710999",
                jump = "111658291175493", fall = "124330094243355", climb = "137524336110065",
                swim = "97745837467465" } },
            { id = "4899847411546", name = "Endless Aura Floating", items = {
                idle = "75638427965557", walk = "131290152729043", run = "77610456891399",
                jump = "74451563346167", fall = "74203422263286", climb = "116293937663140",
                swim = "110044773049875" } },
        }

        -- SET.Packs = { { id, name, items = {slot = itemId}, anims = {slot = AnimationId} } }
        -- Valida o que veio da config (ou cria a lista na primeira vez).
        K.List = function()
            if type(SET.Packs) ~= "table" then
                SET.Packs = {}
                for _, s in ipairs(SEED) do
                    local items = {}
                    for k, v in pairs(s.items) do items[k] = v end
                    table.insert(SET.Packs, { id = s.id, name = s.name, items = items, anims = {} })
                end
            end
            -- já conferida (a config carregada troca a tabela inteira)
            if K.checked == SET.Packs then return SET.Packs end
            local clean, dirty = {}, false
            for _, p in ipairs(SET.Packs) do
                local id = type(p) == "table" and IdStr(p.id)
                if id then
                    p.id = id
                    if type(p.name) ~= "string" or p.name == "" then p.name = "Pacote " .. id end
                    local items, anims = {}, {}
                    for _, s in ipairs(K.Slots) do
                        local iid = type(p.items) == "table" and IdStr(p.items[s])
                        if iid then items[s] = iid end
                        local a = type(p.anims) == "table" and p.anims[s]
                        if type(a) == "string" and a:match("^rbxassetid://%d+$") then anims[s] = a end
                    end
                    p.items, p.anims = items, anims
                    table.insert(clean, p)
                else
                    dirty = true
                end
            end
            if dirty then SET.Packs = clean end
            K.checked = SET.Packs
            return SET.Packs
        end

        K.Get = function(id)
            id = IdStr(id)
            if not id then return nil end
            for _, p in ipairs(K.List()) do
                if p.id == id then return p end
            end
            return nil
        end

        -- por ID / link ou por pedaço do nome ("gogeta")
        K.Find = function(q)
            q = tostring(q or "")
            local p = K.Get(K.Parse(q))
            if p then return p end
            q = q:lower()
            if q == "" then return nil end
            for _, it in ipairs(K.List()) do
                if it.name:lower():find(q, 1, true) then return it end
            end
            return nil
        end

        K.Count = function(p)
            local n = 0
            for _, s in ipairs(K.Slots) do
                if p and p.anims and p.anims[s] then n = n + 1 end
            end
            return n
        end

        -- grava a config (a lista e as animações lidas) se o executor deixar
        K.Persist = function()
            if V8.Cfg and V8.Cfg.Supported and V8.Cfg.Supported() then
                pcall(V8.Cfg.Save, true)
            end
        end

        ----------------------------------------------------------------------------
        -- leitura do pacote
        ----------------------------------------------------------------------------
        local function SlotFromName(name)
            local n = tostring(name or ""):lower()
            for _, s in ipairs(K.Slots) do
                if n:find(s, 1, true) then return s end
            end
            return nil
        end

        -- itens do pacote: { {id=, name=}, ... }, nome do pacote  (ou nil, nil, motivo)
        local function FetchBundle(bid)
            local okA, info = pcall(function()
                return game:GetService("AssetService"):GetBundleDetailsAsync(tonumber(bid))
            end)
            if okA and type(info) == "table" and type(info.Items) == "table" then
                local bt = tostring(info.BundleType or "")
                if bt ~= "" and not bt:find("Animation") then
                    return nil, nil, "este pacote é de " .. bt .. ", não de animação"
                end
                local list = {}
                for _, it in ipairs(info.Items) do
                    local iid = IdStr(it.Id)
                    if it.Type == "Asset" and iid then
                        table.insert(list, { id = iid, name = tostring(it.Name or "") })
                    end
                end
                if #list > 0 then return list, info.Name end
            end
            if not (V8.Net and V8.Net.Json) then
                return nil, nil, "o jogo não deixou ler o pacote e o executor não tem HTTP"
            end
            local d, why = V8.Net.Json("GET",
                "https://catalog.roblox.com/v1/bundles/" .. bid .. "/details")
            if not d then return nil, nil, "catálogo: " .. tostring(why) end
            local bt = tostring(d.bundleType or "")
            if bt ~= "" and not bt:find("Animation") then
                return nil, nil, "este pacote é de " .. bt .. ", não de animação"
            end
            local list = {}
            for _, it in ipairs(type(d.items) == "table" and d.items or {}) do
                local iid = IdStr(it.id)
                if it.type == "Asset" and iid then
                    table.insert(list, { id = iid, name = tostring(it.name or "") })
                end
            end
            if #list == 0 then return nil, nil, "o pacote não tem itens (ID errado?)" end
            return list, d.name
        end

        -- abre a caixa do item: slot ("run"...) e o AnimationId de dentro
        local function ReadItem(itemId, hint)
            local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. itemId) end)
            if not ok or type(objs) ~= "table" then
                return nil, nil, "o executor não tem game:GetObjects (ou o Roblox recusou o item)"
            end
            local slot, anim
            for _, o in ipairs(objs) do
                local all = o:GetDescendants()
                table.insert(all, 1, o)
                for _, d in ipairs(all) do
                    if not anim and d:IsA("StringValue") and IS_SLOT[d.Name:lower()] then
                        local a = d:FindFirstChildOfClass("Animation")
                        if a and a.AnimationId ~= "" then slot, anim = d.Name:lower(), a.AnimationId end
                    end
                end
                if not anim then
                    for _, d in ipairs(all) do
                        if d:IsA("Animation") and d.AnimationId ~= "" then
                            anim = d.AnimationId
                            break
                        end
                    end
                end
            end
            for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
            local key = anim and tostring(anim):match("(%d%d%d%d+)")
            if not key then return nil, nil, "o item não tem animação dentro" end
            return slot or SlotFromName(hint), "rbxassetid://" .. key
        end

        -- lê o que falta (BLOQUEIA: rode em task.spawn). Devolve quantas
        -- animações ficaram prontas, ou nil + motivo
        K.ResolveNow = function(p)
            if K.Count(p) >= #K.Slots then return K.Count(p) end
            local lastWhy
            if next(p.items) == nil then
                local list, name, why = FetchBundle(p.id)
                if not list then return nil, why end
                if type(name) == "string" and name ~= "" then p.name = name end
                for _, it in ipairs(list) do
                    local slot, anim, why2 = ReadItem(it.id, it.name)
                    if slot and anim then
                        p.items[slot] = it.id
                        p.anims[slot] = anim
                    elseif why2 then
                        lastWhy = why2
                    end
                end
            else
                for _, s in ipairs(K.Slots) do
                    local iid = p.items[s]
                    if iid and not p.anims[s] then
                        local slot, anim, why2 = ReadItem(iid, s)
                        if anim then
                            p.anims[(slot and IS_SLOT[slot]) and slot or s] = anim
                        else
                            lastWhy = why2
                        end
                    end
                end
            end
            local n = K.Count(p)
            if n == 0 then return nil, lastWhy or "nenhuma animação encontrada no pacote" end
            return n
        end

        -- assíncrono; done(n, motivo) roda quando terminar (vários podem esperar)
        K.Resolve = function(p, done)
            if not p then return end
            local w = K.waiters[p.id]
            if w then
                if done then table.insert(w, done) end
                return
            end
            w = {}
            if done then table.insert(w, done) end
            K.waiters[p.id] = w
            K.busy[p.id] = true
            K.fail[p.id] = nil
            K.Changed()
            task.spawn(function()
                local ok, n, why = pcall(K.ResolveNow, p)
                if not ok then n, why = nil, tostring(n) end
                K.busy[p.id] = nil
                K.waiters[p.id] = nil
                K.fail[p.id] = (not n) and (why or "não deu para ler") or nil
                if n and K.Get(p.id) == p then K.Persist() end
                K.Changed()
                for _, fn in ipairs(w) do pcall(fn, n, why) end
            end)
        end

        -- adiciona pelo ID/link e já lê. done(pacote, n, motivo)
        K.Add = function(raw, done)
            local id = IdStr(K.Parse(raw))
            if not id then return nil, "não achei o ID do pacote (cole o número ou o link)" end
            local p = K.Get(id)
            if not p then
                p = K.temp[id] or { id = id, name = "Pacote " .. id, items = {}, anims = {} }
                K.temp[id] = nil
                table.insert(K.List(), p)
            end
            K.Changed()
            if K.Count(p) > 0 and not done then return p end
            K.Resolve(p, function(n, why)
                if done then pcall(done, p, n, why) end
            end)
            return p
        end

        ----------------------------------------------------------------------------
        -- no personagem
        ----------------------------------------------------------------------------
        local function Animate()
            local c = Char()
            return c and c:FindFirstChild("Animate")
        end

        -- reinicia o Animate: ele relê os IDs e volta a tocar com os novos.
        -- Antes, para as tracks dele (Core/Idle/Movement) — emote e voo ficam.
        local function Restart(h, animate)
            local animator = h:FindFirstChildOfClass("Animator")
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                    local mine = (t == Emote.track) or (t == flyTrack) or (t == FlyPose.idleTrack)
                    local pr = t.Priority
                    if not mine and (pr == Enum.AnimationPriority.Core
                        or pr == Enum.AnimationPriority.Idle
                        or pr == Enum.AnimationPriority.Movement) then
                        pcall(function() t:Stop(0.1) end)
                    end
                end
            end
            pcall(function() animate.Disabled = true end)
            task.wait()
            pcall(function() animate.Disabled = false end)
        end

        -- o Roblox recusa asset em alguns jogos: a track "toca" com Length 0
        local function Verify(p, h)
            task.delay(4, function()
                local animator = h and h.Parent and h:FindFirstChildOfClass("Animator")
                if not animator or SET.PackOn ~= p.id then return end
                local mineIds = {}
                for _, a in pairs(p.anims) do mineIds[a] = true end
                local seen, good = 0, 0
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                    local aid = t.Animation and t.Animation.AnimationId
                    if aid and mineIds[aid] then
                        seen = seen + 1
                        if t.Length > 0 then good = good + 1 end
                    end
                end
                if seen > 0 and good == 0 then
                    Log("O Roblox não carregou as animações de " .. p.name .. " neste jogo "
                        .. "(asset recusado). Em outros jogos pode funcionar.", "error")
                    Toast("Este jogo recusou o pacote", "error", 3)
                end
            end)
        end

        -- devolve ok, quantas trocou (ou o motivo), animações sem lugar no Animate
        K.Apply = function(p)
            local h, animate = Hum(), Animate()
            if not h then return false, "sem personagem" end
            if h.RigType == Enum.HumanoidRigType.R6 then
                return false, "pacotes de animação são R15 e este jogo usa R6"
            end
            if not animate then
                return false, "seu personagem não tem o script Animate (o jogo anima do jeito dele)"
            end
            if K.Count(p) == 0 then return false, "o pacote ainda não foi lido" end
            local char = Char()
            if K.origChar ~= char then K.origChar, K.orig = char, {} end
            local changed, missing = 0, {}
            for _, s in ipairs(K.Slots) do
                local id = p.anims[s]
                if id then
                    local f = animate:FindFirstChild(s)
                    local any = false
                    if f then
                        for _, a in ipairs(f:GetChildren()) do
                            if a:IsA("Animation") then
                                if K.orig[a] == nil then K.orig[a] = a.AnimationId end
                                a.AnimationId = id
                                changed = changed + 1
                                any = true
                            end
                        end
                    end
                    if not any then table.insert(missing, K.SlotName[s]) end
                end
            end
            if changed == 0 then
                return false, "o Animate deste jogo não tem as pastas padrão (idle, walk, run...)"
            end
            task.spawn(Restart, h, animate)
            Verify(p, h)
            return true, changed, missing
        end

        -- devolve os IDs originais do Animate deste personagem
        K.Restore = function()
            local n = 0
            for a, id in pairs(K.orig) do
                if a.Parent then
                    pcall(function() a.AnimationId = id end)
                    n = n + 1
                end
            end
            K.orig = {}
            local h, animate = Hum(), Animate()
            if n > 0 and h and animate then task.spawn(Restart, h, animate) end
            return n
        end

        -- põe o pacote no personagem (lê antes, se precisar). quiet = boot/respawn
        K.Use = function(p, quiet)
            if not p then return end
            local function Go()
                local ok, a, b = K.Apply(p)
                if ok then
                    SET.PackOn = p.id
                    if not quiet then
                        Log("Pacote " .. p.name .. " no personagem (" .. K.Count(p) .. " animações)"
                            .. ((b and #b > 0) and ("  ·  sem lugar no Animate: "
                                .. table.concat(b, ", ")) or ""), "ok")
                        Toast(p.name .. " no personagem", "ok", 2)
                    end
                else
                    Log("Pacote " .. p.name .. ": " .. tostring(a), quiet and "warn" or "error")
                    if not quiet then Toast("Não deu: " .. tostring(a), "error", 3) end
                end
                K.Changed()
            end
            if K.Count(p) > 0 then Go() return end
            if not quiet then Toast("Lendo " .. p.name .. "...", nil, 2) end
            K.Resolve(p, function(n, why)
                if n then
                    Go()
                else
                    Log("Pacote " .. p.name .. " não foi lido: " .. tostring(why), "error")
                    if not quiet then Toast("Pacote não foi lido", "error", 3) end
                end
            end)
        end

        K.Off = function(quiet)
            SET.PackOn = nil
            local n = K.Restore()
            if not quiet then
                Log(n > 0 and "Animações do personagem de volta ao normal"
                    or "Nenhum pacote estava no personagem", "action")
            end
            K.Changed()
        end

        K.Remove = function(p)
            if not p then return end
            if SET.PackOn == p.id then K.Off(true) end
            if SET.FlyPack == p.id then SET.FlyPack = nil end
            local list = K.List()
            for i = #list, 1, -1 do
                if list[i] == p then table.remove(list, i) end
            end
            K.Persist()
            K.Changed()
        end

        ----------------------------------------------------------------------------
        -- voo
        ----------------------------------------------------------------------------
        -- o pacote do Fly: o marcado como VOO; sem marca, o CONFIG.FlyPackBundle
        -- (que não precisa estar na lista: fica só na memória desta sessão)
        K.FlyPack = function()
            local p = SET.FlyPack and K.Get(SET.FlyPack)
            if p then return p end
            local id = IdStr(CONFIG.FlyPackBundle)
            if not id then return nil end
            p = K.Get(id)
            if p then return p end
            if not K.temp[id] then
                K.temp[id] = { id = id, name = "Pacote " .. id, items = {}, anims = {} }
            end
            return K.temp[id]
        end

        -- moveId, idleId, pacote (moveId nil = ainda não lido)
        K.FlyIds = function()
            local p = K.FlyPack()
            if not p then return nil, nil, nil end
            local a = p.anims
            local move = a[CONFIG.FlyPackMoveSlot or "fall"] or a.fall or a.swim
            local idle = a[CONFIG.FlyPackIdleSlot or "idle"]
            return move, idle, p
        end

        K.SetFly = function(p)
            SET.FlyPack = p and p.id or nil
            FlyPose.packFailed = false
            FlyPose.warnedPack = false
            if IsOn("fly") and not Emote.track and FlyPose.Restart then FlyPose.Restart() end
            if V8.FlyStyleRender then pcall(V8.FlyStyleRender) end
            K.Changed()
        end

        ----------------------------------------------------------------------------
        -- boot e respawn
        ----------------------------------------------------------------------------
        K.Boot = function()
            K.List()
            local p = SET.PackOn and K.Get(SET.PackOn)
            if p then K.Use(p, true) end
        end

        Conn.PackChar = LocalPlayer.CharacterAdded:Connect(function(char)
            K.origChar, K.orig = nil, {}
            if not SET.PackOn then return end
            task.spawn(function()
                pcall(function() char:WaitForChild("Animate", 6) end)
                task.wait(0.3)
                local p = K.Get(SET.PackOn)
                if p and Char() == char then K.Use(p, true) end
            end)
        end)
    end
    Build()
end
end)
V8.Mod("src/30_kit/07_sha256.lua", 6164, 6257, function() --------------------------------------------------------------------------------
-- v9.1 — SHA-256 (integridade da atualização)
-- A atualização do painel (50_v8/09_update.lua) confere o main.lua baixado
-- contra o manifest.json do repositório antes de trocar qualquer coisa.
-- Lua puro + bit32 (FIPS 180-4): não depende de criptografia do executor.
-- O bloco entre os marcadores é CÓPIA EXATA do que está no loader.lua — o
-- tests/integrity.test.js confere as duas cópias e compara com o SHA-256 do
-- Node. Mudou aqui, mude lá.
--------------------------------------------------------------------------------
do
-- [sha256:begin]
local Sha256
do
    local band, bxor, bnot = bit32.band, bit32.bxor, bit32.bnot
    local rrotate, rshift = bit32.rrotate, bit32.rshift
    local byte, char, rep, fmt = string.byte, string.char, string.rep, string.format
    local MOD = 4294967296
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }
    local function be32(n)
        return char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
    end
    -- hex minúsculo do SHA-256 dos bytes de msg
    Sha256 = function(msg)
        local len = #msg
        local hi = math.floor(len * 8 / MOD)
        local lo = len * 8 - hi * MOD
        msg = msg .. "\128" .. rep("\0", (55 - len) % 64) .. be32(hi) .. be32(lo)
        local H1, H2, H3, H4 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
        local H5, H6, H7, H8 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        local w = {}
        for i = 1, #msg, 64 do
            for j = 1, 16 do
                local p = i + (j - 1) * 4
                local a, b, c, d = byte(msg, p, p + 3)
                w[j] = ((a * 256 + b) * 256 + c) * 256 + d
            end
            for j = 17, 64 do
                local x, y = w[j - 15], w[j - 2]
                local s0 = bxor(rrotate(x, 7), rrotate(x, 18), rshift(x, 3))
                local s1 = bxor(rrotate(y, 17), rrotate(y, 19), rshift(y, 10))
                w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % MOD
            end
            local a, b, c, d, e, f, g, h = H1, H2, H3, H4, H5, H6, H7, H8
            for j = 1, 64 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = (h + S1 + ch + K[j] + w[j]) % MOD
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                h, g, f, e = g, f, e, (d + t1) % MOD
                d, c, b, a = c, b, a, (t1 + S0 + maj) % MOD
            end
            H1, H2, H3, H4 = (H1 + a) % MOD, (H2 + b) % MOD, (H3 + c) % MOD, (H4 + d) % MOD
            H5, H6, H7, H8 = (H5 + e) % MOD, (H6 + f) % MOD, (H7 + g) % MOD, (H8 + h) % MOD
        end
        -- em metades de 16 bits: "%08x" com número >= 2^31 quebra em Lua de
        -- inteiro 32 bits (e assim o mesmo código roda em qualquer Lua)
        local out = {}
        for i, v in ipairs({ H1, H2, H3, H4, H5, H6, H7, H8 }) do
            out[i] = fmt("%04x%04x", math.floor(v / 65536), v % 65536)
        end
        return table.concat(out)
    end
end
-- [sha256:end]
    V8.Sha256 = Sha256

    -- confere um main.lua baixado contra o manifest.json do repositório.
    -- Devolve true ou false + motivo. O hash é do texto com quebras LF (o
    -- GitHub serve LF; o build calcula igual).
    V8.VerifyBuild = function(src, man)
        if type(src) ~= "string" or #src == 0 then return false, "arquivo vazio" end
        if type(man) ~= "table" or type(man.sha256) ~= "string" or type(man.size) ~= "number" then
            return false, "manifesto inválido"
        end
        local lf = src:gsub("\r\n", "\n")
        if #lf ~= man.size then
            return false, "incompleto (" .. #lf .. " de " .. tostring(man.size) .. " bytes)"
        end
        if Sha256(lf) ~= man.sha256:lower() then return false, "SHA-256 não confere" end
        local build = src:match("%-%- build: (%x+)")
        if man.build and build ~= man.build then return false, "build diferente do manifesto" end
        return true
    end
end
end)
V8.Mod("src/30_kit/08_profile_tx.lua", 6259, 6420, function() --------------------------------------------------------------------------------
-- v9.1 — TROCA SEGURA DE PERFIL (usado por 50_v8/10_profiles.lua)
-- Um perfil nunca deixa o painel pela metade:
--   1. VALIDA tudo antes de mexer em qualquer coisa (tipos, números finitos,
--      faixas). Inválido = nada muda.
--   2. copia o estado atual
--   3. aplica as PREFERÊNCIAS (aparência, teclas, ajustes, velocidades) e
--      confere se terminou certo. Deu erro no meio = volta para a cópia.
--   4. só então liga/desliga as FUNÇÕES (as que mexem no personagem). Freecam
--      e Drone nunca ligam sozinhos. Função que não ligou (ex.: sem
--      personagem) não desfaz as preferências: vai para o relatório.
-- Sem UI aqui: tests/profiles.test.js roda este arquivo de verdade.
--------------------------------------------------------------------------------
do
    V8.ProfTx = {}
    local T = V8.ProfTx

    local function finite(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
    local SPEED_MAX = 100000

    -- ctx = { setKeys = {k=true}, toggles = {id=true}, noauto = {id=true},
    --         themes = {nome=true}, keyOk = function(nome) -> bool }
    -- devolve ok, erros, avisos (avisos não impedem: o item é ignorado)
    T.Validate = function(d, ctx)
        local errs, warns = {}, {}
        local function E(s) table.insert(errs, s) end
        local function W(s) table.insert(warns, s) end
        if type(d) ~= "table" then return false, { "o perfil não tem dados" }, warns end
        ctx = ctx or {}
        local keyOk = ctx.keyOk or function() return true end

        if type(d.set) ~= "table" then E("faltam os ajustes (set)") end
        if d.on ~= nil and type(d.on) ~= "table" then E("lista de funções (on) inválida") end

        if type(d.set) == "table" then
            for k, v in pairs(d.set) do
                local t = type(v)
                if type(k) ~= "string" then
                    E("ajuste com nome inválido")
                elseif t == "number" and not finite(v) then
                    E("ajuste " .. k .. " não é um número válido")
                elseif t ~= "boolean" and t ~= "number" and t ~= "string" and t ~= "table" then
                    E("ajuste " .. k .. " tem tipo " .. t)
                elseif ctx.setKeys and not ctx.setKeys[k] then
                    W("ajuste desconhecido " .. k .. " (ignorado)")
                end
            end
        end
        for _, k in ipairs({ "esp", "keys", "sitkeys", "speeds" }) do
            if d[k] ~= nil and type(d[k]) ~= "table" then E(k .. " inválido") end
        end
        if d.theme ~= nil then
            if type(d.theme) ~= "string" then E("tema inválido")
            elseif ctx.themes and not ctx.themes[d.theme] then W("tema " .. d.theme .. " não existe (ignorado)") end
        end
        if d.scale ~= nil and not (finite(d.scale) and d.scale >= 50 and d.scale <= 200) then
            E("tamanho da GUI fora de 50–200%")
        end
        if type(d.speeds) == "table" then
            for k, v in pairs(d.speeds) do
                if not (finite(v) and v >= 0 and v <= SPEED_MAX) then E("velocidade " .. tostring(k) .. " inválida") end
            end
        end
        if type(d.keys) == "table" then
            for id, name in pairs(d.keys) do
                if type(id) ~= "string" or type(name) ~= "string" then
                    E("tecla com formato inválido")
                elseif not keyOk(name) then
                    W("tecla " .. name .. " não existe (ignorada)")
                elseif ctx.toggles and not ctx.toggles[id] then
                    W("tecla de função desconhecida " .. id .. " (ignorada)")
                end
            end
        end
        if type(d.sitkeys) == "table" then
            for n, name in pairs(d.sitkeys) do
                if type(n) ~= "string" or type(name) ~= "string" then E("atalho de situação inválido") end
            end
        end
        for _, k in ipairs({ "panelkey", "consolekey", "searchkey" }) do
            if d[k] ~= nil then
                if type(d[k]) ~= "string" then E(k .. " inválido")
                elseif not keyOk(d[k]) then W(k .. " " .. d[k] .. " não existe (ignorada)") end
            end
        end
        if d.searchctrl ~= nil and type(d.searchctrl) ~= "boolean" then E("searchctrl inválido") end
        if type(d.on) == "table" then
            for _, id in ipairs(d.on) do
                if type(id) ~= "string" then
                    E("função com nome inválido")
                elseif ctx.noauto and ctx.noauto[id] then
                    W(id .. " nunca liga pelo perfil (ignorado)")
                elseif ctx.toggles and not ctx.toggles[id] then
                    W("função desconhecida " .. id .. " (ignorada)")
                end
            end
        end
        return #errs == 0, errs, warns
    end

    -- deps = { ctx, snapshot(), restore(d), verify(d) -> ok, motivo,
    --          clear(chave) (apaga um ajuste na volta), order = {ids},
    --          isOn(id), setToggle(id, on) }
    -- devolve ok, relatório { applied, rolledBack, errors, warnings, failed }
    T.Apply = function(d, deps)
        local rep = { applied = false, rolledBack = false, errors = {}, warnings = {}, failed = {} }
        local ok, errs, warns = T.Validate(d, deps.ctx)
        rep.warnings = warns
        if not ok then
            rep.errors = errs
            return false, rep
        end

        local okS, prev = pcall(deps.snapshot)
        if not okS or type(prev) ~= "table" then
            rep.errors = { "não deu para copiar o estado atual: " .. tostring(prev) }
            return false, rep
        end

        local okA, errA = pcall(deps.restore, d)
        local okV, whyV = okA, nil
        if okA and deps.verify then
            local okC, a, b = pcall(deps.verify, d)
            if okC then okV, whyV = a, b else okV, whyV = false, a end
        end
        if not okA or not okV then
            rep.errors = { okA and ("não terminou certo: " .. tostring(whyV))
                or ("falhou ao aplicar: " .. tostring(errA)) }
            local okB, errB = pcall(deps.restore, prev)
            -- o restore só escreve o que está na cópia: ajuste que o perfil
            -- criou (antes era nil) tem que ser apagado à parte
            if okB and deps.clear and type(d.set) == "table" then
                local had = type(prev.set) == "table" and prev.set or {}
                for k in pairs(d.set) do
                    if had[k] == nil then pcall(deps.clear, k) end
                end
            end
            rep.rolledBack = okB
            if not okB then
                table.insert(rep.errors, "e a volta ao estado anterior também falhou: " .. tostring(errB))
            end
            return false, rep
        end
        rep.applied = true

        if type(d.on) == "table" then
            local want = {}
            for _, id in ipairs(d.on) do want[id] = true end
            local noauto = (deps.ctx and deps.ctx.noauto) or {}
            for _, id in ipairs(deps.order or {}) do
                if not noauto[id] then
                    local w = want[id] == true
                    if deps.isOn(id) ~= w then
                        pcall(deps.setToggle, id, w)
                        if deps.isOn(id) ~= w then table.insert(rep.failed, id) end
                    end
                end
            end
        end
        return true, rep
    end
end
end)
V8.Mod("src/40_tabs/00_home.lua", 6422, 6756, function() --------------------------------------------------------------------------------
-- ABA HOME (dashboard)
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Home")

    ----------------------------------------------------------------------------
    -- VISÃO GERAL
    ----------------------------------------------------------------------------
    -- v8.1: MAPA ATUAL (0) e PERFIL (1) entram antes, em 01_home_server.lua
    local overview = CreateCard(tab, "VISÃO GERAL", 2)
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
    local grid2 = Grid(overview, 2, 62)   -- v8.0: janela estreita (era 4)

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
    local quick = CreateCard(tab, "AÇÕES RÁPIDAS", 3)
    -- v9.0: as ações rápidas são os FAVORITOS (estrela em qualquer função)
    SubLabel(quick, "Um clique liga/desliga. Toque na estrela ao lado de qualquer "
        .. "função (Personagem, Visual, Troll...) para fixar ou tirar daqui.", -1)

    local qGrid = Grid(quick, 2, 40)   -- v8.0: janela estreita (era 4)
    local quickBtns = {}

    -- v9.0: nome curto, ícone e cor de cada função (vale para qualquer
    -- toggle que virar favorito)
    V8.ToggleLook = {
        fly        = { "Fly", "bolt", "Accent2" },
        noclip     = { "Noclip", "ghost", "Accent" },
        esp        = { "ESP", "eye", "Success" },
        freecam    = { "Freecam", "cam", "Accent" },
        infjump    = { "Inf Jump", "up", "Accent2" },
        god        = { "God", "shield", "Success" },
        invisible  = { "Invisível", "circle", "Accent" },
        fullbright = { "Fullbright", "sun", "Warning" },
        wall       = { "Paredes", "box", "Accent" },
        chatspy    = { "Chat Spy", "clip", "Accent2" },
        antiafk    = { "Anti-AFK", "clock", "Success" },
        drone      = { "Drone", "wifi", "Accent" },
        antifall   = { "Anti-Fall", "shield", "Accent2" },
        antigrav   = { "Anti-Grav", "up", "Accent" },
        wallwalk   = { "Wall Walk", "mask", "Warning" },
        clicktp    = { "Clique TP", "link", "Accent2" },
    }

    local quickEmpty = SubLabel(quick, "Nenhuma função fixada. Toque na estrela de "
        .. "uma função para ela aparecer aqui.", 2)
    quickEmpty.Visible = false
    local quickSig = nil

    local function QuickPill(i, id)
        local look = V8.ToggleLook[id] or { Toggles[id].label or id, "dot", "Accent" }
        local label, kind, ck = look[1], look[2], look[3]

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
        lb.TextTruncate = Enum.TextTruncate.AtEnd
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

    -- monta (de novo) as pílulas a partir da lista de favoritos
    local function BuildQuick()
        local list = V8.Fav and V8.Fav.List() or {}
        quickSig = table.concat(list, " ")
        for _, c in ipairs(qGrid:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for k in pairs(quickBtns) do quickBtns[k] = nil end
        local shown = 0
        for _, id in ipairs(list) do
            if Toggles[id] then
                shown = shown + 1
                QuickPill(shown, id)
            end
        end
        quickEmpty.Visible = (shown == 0)
        if RefreshQuick then pcall(RefreshQuick) end
    end
    BuildQuick()
    if V8.Fav then V8.Fav.OnChange = BuildQuick end
    -- config/perfil carregado trocou a lista: remonta só se mudou
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, function()
        local list = V8.Fav and V8.Fav.List() or {}
        if table.concat(list, " ") ~= quickSig then BuildQuick() end
    end)

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
    local info = CreateCard(tab, nil, 4)
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
end)
V8.Mod("src/40_tabs/01_home_dashboard.lua", 6758, 7325, function() --------------------------------------------------------------------------------
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
        antifall = "shield", antigrav = "up", wallwalk = "mask",   -- v8.1
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
end)
V8.Mod("src/40_tabs/01_home_server.lua", 7327, 7600, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/40_tabs/02_movement.lua", 7602, 7934, function() --------------------------------------------------------------------------------
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
    SwitchRow(main, "antifall", "Anti-Fall", Toggles.antifall.desc)        -- v8.1
    SwitchRow(main, "antigrav", "Anti-Gravidade", Toggles.antigrav.desc)  -- v8.1

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

    -- v8.1: força da gravidade com Anti-Gravidade ligado (0% = flutua)
    V8.GravSlider = SliderRow(speeds, {
        label = "Gravidade (Anti-Gravidade)", min = 0, max = 100, def = State.GravityPct,
        suffix = "%", order = 4,
        apply = function(v) if V8.AntiGrav then V8.AntiGrav.Set(v) end end,
    })

    -- v8.1.2: animação do voo — pacote do catálogo (v8.2: o marcado como VOO
    -- no cartão "Pacote de animação"), nadar do próprio personagem, ou a pose do
    -- painel (só você vê). Com o Fly ligado, troca na hora (menos se houver um
    -- emote tocando por cima).
    do
        local function FlyStyleRow()
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 82)
            row.LayoutOrder = 5
            row.Parent = speeds
            V8.Cell(row, 8)

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 18)
            title.BackgroundTransparency = 1
            title.Text = "Animação do voo"
            title.TextColor3 = THEME.Text
            title.Font = Enum.Font.GothamBold
            title.TextSize = 13
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = row
            Paint(title, "TextColor3", "Text")

            local hint = Instance.new("TextLabel")
            hint.Size = UDim2.new(1, 0, 0, 14)
            hint.Position = UDim2.new(0, 0, 0, 52)
            hint.BackgroundTransparency = 1
            hint.Text = ""
            hint.TextColor3 = THEME.Dim
            hint.Font = Enum.Font.GothamMedium
            hint.TextSize = 11
            hint.TextXAlignment = Enum.TextXAlignment.Left
            hint.TextTruncate = Enum.TextTruncate.AtEnd
            hint.Parent = row
            Paint(hint, "TextColor3", "Dim")

            local OPTS = {
                { "pacote", "Pacote",         "Pacote do catálogo (R15) — todos veem" },
                { "jogo",   "Nadar",          "Nadar do seu personagem (R15) — todos veem" },
                { "pose",   "Pose do painel", "Pose desenhada pelo painel — só você vê" },
            }
            local btns = {}
            local function Paint3()
                local cur = SET.FlyStyle or CONFIG.FlyStyle or "pacote"
                for i, o in ipairs(OPTS) do
                    local on = (o[1] == cur)
                    btns[i].BackgroundColor3 = on and THEME.Accent or THEME.Btn
                    btns[i].TextColor3 = on and THEME.Main or THEME.Text
                    if on then hint.Text = o[3] end
                end
                -- v8.2: o nome do pacote que o voo está usando
                if cur == "pacote" and V8.Pack then
                    local fp = V8.Pack.FlyPack()
                    if fp then hint.Text = "Pacote " .. fp.name .. " (R15) — todos veem" end
                end
            end
            V8.FlyStyleRender = Paint3
            for i, o in ipairs(OPTS) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1 / 3, -4, 0, 28)
                b.Position = UDim2.new((i - 1) / 3, (i - 1) * 2, 0, 22)
                b.Text = o[2]
                b.Font = Enum.Font.GothamBold
                b.TextSize = 11
                b.AutoButtonColor = false
                b.Parent = row
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
                btns[i] = b
                b.MouseButton1Click:Connect(function()
                    SET.FlyStyle = o[1]
                    if o[1] == "pacote" then FlyPose.packFailed = false end   -- tenta de novo
                    Paint3()
                    Log("Animação do voo: " .. o[2], "action")
                    if IsOn("fly") and not Emote.track then FlyPose.Restart() end
                end)
            end
            V8.Renders = V8.Renders or {}
            table.insert(V8.Renders, Paint3)   -- tema e config carregada
            Paint3()
        end
        FlyStyleRow()
    end

    V8.FlyTiltSlider = SliderRow(speeds, {
        label = "Inclinação voando (nadar)", min = 0, max = 90,
        def = CONFIG.FlySwimTilt or 75, suffix = "°", order = 6,
        apply = function(v) SET.FlyTilt = v end,
    })

    ----------------------------------------------------------------------------
    -- CÂMERA / DRONE
    ----------------------------------------------------------------------------
    -- v8.2: a ordem 3 é do cartão "Pacote de animação" (02_movement_pack.lua)
    local drone = CreateCard(tab, "CÂMERA E DRONE", 4)
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
    local tp = CreateCard(tab, "TELEPORTE", 5)
    local tpGrid = Grid(tp, 3, 34)
    tpGrid.LayoutOrder = 1
    -- v8.2: Ctrl + clique teleporta (toggle "clicktp", 20_features/11_clicktp.lua)
    SwitchRow(tp, "clicktp", "Ctrl + clique TP", Toggles.clicktp.desc).LayoutOrder = 2

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
    local wp = CreateCard(tab, "WAYPOINTS", 6)
    SubLabel(wp, "Salva a posição atual do personagem. Cada jogo tem a sua lista "
        .. "(v8.2): aqui só aparecem os waypoints deste jogo. Vão junto na config "
        .. "em disco (Ajustes › Configuração em disco).", -1)

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
end)
V8.Mod("src/40_tabs/02_movement_pack.lua", 7936, 8121, function() --------------------------------------------------------------------------------
-- v8.2 — CARTÃO "PACOTE DE ANIMAÇÃO" (Personagem › Movimento)
-- Cole o ID ou o link de um pacote do catálogo; o painel lê as animações dele
-- (V8.Pack, 30_kit/06_animpack.lua) e guarda na lista. Em cada pacote:
--   USAR  -> troca as animações do seu personagem (andar, correr, pular,
--            parado...) — os outros jogadores veem
--   VOO   -> o Fly (estilo "Pacote") usa a animação de cair/parado dele
--   X     -> tira da lista
-- VOLTAR AO NORMAL devolve as animações originais do jogo.
-- Entra logo depois de 02_movement.lua no build (ordem alfabética).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local K = V8.Pack
        if not K then return end
        local card = CreateCard(Tabs.Movement, "PACOTE DE ANIMAÇÃO", 3)
        SubLabel(card, "Pacotes de animação do catálogo (só R15). USAR troca as "
            .. "animações do seu personagem e todo mundo vê. VOO põe o pacote no Fly.", -1)

        local status = SubLabel(card, "", 0)

        local box = CreateInput(card, "ID ou link do pacote (roblox.com/bundles/...)", 32)
        box.LayoutOrder = 1

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 2
        local add = CreateButton(g, "ADICIONAR", "Success", 32)
        add.LayoutOrder = 1
        local normal = CreateButton(g, "VOLTAR AO NORMAL", "Warning", 32)
        normal.LayoutOrder = 2

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 3
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local function Describe(p)
            if K.busy[p.id] then return "lendo o pacote...", "Warning" end
            local n = K.Count(p)
            if K.fail[p.id] and n == 0 then return "não deu: " .. tostring(K.fail[p.id]), "Danger" end
            if n == 0 then return "ainda não lido (lê ao usar)  ·  ID " .. p.id, "Dim" end
            local names = {}
            for _, s in ipairs(K.Slots) do
                if p.anims[s] then table.insert(names, K.SlotName[s]) end
            end
            return n .. " animações: " .. table.concat(names, ", "), "Dim"
        end

        local function SmallBtn(parent, text, key, w, x)
            local b = CreateButton(parent, text, key, 26)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Size = UDim2.new(0, w, 0, 26)
            b.Position = UDim2.new(1, x, 0.5, 0)
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            return b
        end

        local function Row(p, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -196, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 7)
            nm.BackgroundTransparency = 1
            nm.Text = p.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 13
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local text, key = Describe(p)
            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -196, 0, 14)
            ds.Position = UDim2.new(0, 12, 0, 27)
            ds.BackgroundTransparency = 1
            ds.Text = text
            ds.TextColor3 = THEME[key] or THEME.Dim
            ds.Font = Enum.Font.GothamMedium
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.TextTruncate = Enum.TextTruncate.AtEnd
            ds.Parent = row
            Paint(ds, "TextColor3", key)

            local onChar = (SET.PackOn == p.id)
            local fp = K.FlyPack()
            local onFly = (fp ~= nil and fp.id == p.id)

            -- da direita para a esquerda: X, VOO, USAR
            local del = SmallBtn(row, "X", "Danger", 30, -10)
            local fly = SmallBtn(row, onFly and "NO VOO" or "VOO",
                onFly and "Success" or "Accent2", 62, -46)
            local use = SmallBtn(row, onChar and "EM USO" or "USAR",
                onChar and "Success" or "Accent", 70, -114)
            if onChar then use.TextColor3 = THEME.Success end
            if onFly then fly.TextColor3 = THEME.Success end

            use.MouseButton1Click:Connect(function()
                if SET.PackOn == p.id then K.Off() else K.Use(p) end
            end)
            fly.MouseButton1Click:Connect(function()
                local cur = K.FlyPack()
                if cur and cur.id == p.id then
                    Toast(p.name .. " já é o pacote do voo", nil, 2)
                    return
                end
                K.SetFly(p)
                Log("Voo agora usa o pacote " .. p.name
                    .. ((SET.FlyStyle or CONFIG.FlyStyle) ~= "pacote"
                        and "  (escolha 'Pacote' em Animação do voo)" or ""), "ok")
                if K.Count(p) == 0 then K.Resolve(p) end
            end)
            del.MouseButton1Click:Connect(function()
                Confirm("Tirar " .. p.name .. " da lista?", function()
                    K.Remove(p)
                    Log("Pacote removido: " .. p.name, "action")
                end)
            end)
        end

        local function Render()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local packs = K.List()
            for i, p in ipairs(packs) do Row(p, i) end
            local on = SET.PackOn and K.Get(SET.PackOn)
            local fp = K.FlyPack()
            status.Text = "No personagem: " .. (on and on.name or "animações do jogo")
                .. "   ·   No voo: " .. (fp and fp.name or "itens da config")
                .. ((#packs == 0) and "\nLista vazia — cole o ID de um pacote acima." or "")
        end
        K.Render = Render

        local function DoAdd()
            local raw = box.Text
            if raw:match("^%s*$") then
                Toast("Cole o ID ou o link do pacote", "warn", 2)
                return
            end
            local p, why = K.Add(raw, function(pk, n, err)
                if n then
                    Log("Pacote lido: " .. pk.name .. " (" .. n .. " animações)", "ok")
                    Toast(pk.name .. " adicionado", "ok", 2)
                else
                    Log("Pacote " .. pk.id .. " não foi lido: " .. tostring(err), "error")
                    Toast("Não deu para ler o pacote", "error", 3)
                end
            end)
            if not p then
                Toast(tostring(why), "warn", 3)
                return
            end
            box.Text = ""
        end
        add.MouseButton1Click:Connect(DoAdd)
        box.FocusLost:Connect(function(enter) if enter then DoAdd() end end)
        normal.MouseButton1Click:Connect(function() K.Off() end)

        K.OnChange(function() pcall(Render) end)
        OnTabOpen("Movement", function() pcall(Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(Render) end)
        Render()
    end
    Build()
end
end)
V8.Mod("src/40_tabs/03_visuals.lua", 8123, 8216, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/40_tabs/04_players.lua", 8218, 8462, function() --------------------------------------------------------------------------------
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

    -- v8.1: ESP de UM jogador. Marcar alguém liga o ESP (se estava desligado)
    -- só nos marcados; desmarcar o último devolve o ESP como estava.
    V8.EspPick = { auto = false }
    V8.EspPick.Flip = function(p)
        local pick = EspOpts.Pick
        if pick[p.UserId] then pick[p.UserId] = nil else pick[p.UserId] = true end
        local any = next(pick) ~= nil
        if any and not IsOn("esp") then
            SetToggle("esp", true, true)
            V8.EspPick.auto = true
        elseif not any and V8.EspPick.auto then
            V8.EspPick.auto = false
            SetToggle("esp", false, true)
        end
        Log((pick[p.UserId] and "ESP em " or "ESP removido de ") .. p.Name
            .. (any and "" or " — ESP volta a mostrar todos"), "action")
        if RefreshStatus then RefreshStatus() end
    end
    -- desligar o ESP por qualquer caminho limpa as marcações
    if Toggles.esp then
        table.insert(Toggles.esp.listeners, function(on)
            if on then return end
            for k in pairs(EspOpts.Pick) do EspOpts.Pick[k] = nil end
            V8.EspPick.auto = false
        end)
    end

    local function MakeRow(p)
        local row = Instance.new("Frame")
        row.Name = "Row_" .. p.UserId
        row.Size = UDim2.new(1, 0, 0, 62)
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

        -- v8.1: 3 linhas à esquerda, 4 botões (2x2) à direita
        local function Line(y, h, font, size, key)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -206, 0, h)
            l.Position = UDim2.new(0, 56, 0, y)
            l.BackgroundTransparency = 1
            l.Text = ""
            l.TextColor3 = THEME[key]
            l.Font = font
            l.TextSize = size
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.Parent = row
            Paint(l, "TextColor3", key)
            return l
        end
        local dn = Line(7, 17, Enum.Font.GothamBold, 13, "Text")
        dn.Text = p.DisplayName .. (p == LocalPlayer and "   (você)" or "")
        local un = Line(24, 14, Enum.Font.Code, 11, "Dim")
        un.Text = "@" .. p.Name
        local hp = Line(40, 14, Enum.Font.Code, 10, "Success")
        hp.Size = UDim2.new(0, 72, 0, 14)
        local meta = Line(40, 14, Enum.Font.Code, 10, "Dim")
        meta.Position = UDim2.new(0, 132, 0, 40)
        meta.Size = UDim2.new(1, -282, 0, 14)

        local function Btn(text, key, x, y)
            local b = CreateButton(row, text, key, 24)
            b.Size = UDim2.new(0, 64, 0, 24)
            b.Position = UDim2.new(1, x, 0, y)
            b.TextSize = 11
            return b
        end
        local sel = Btn("ALVO", "Accent", -138, 6)
        sel.MouseButton1Click:Connect(function() SelectPlayer(p) end)

        local esp = Btn("ESP", "Success", -70, 6)
        esp.MouseButton1Click:Connect(function()
            V8.EspPick.Flip(p)
            UpdatePlayerRows()
        end)

        local tp = Btn("TP", "Success", -138, 33)
        tp.MouseButton1Click:Connect(function() Goto(p) end)

        local spec = Btn("SPEC", "Accent2", -70, 33)
        spec.MouseButton1Click:Connect(function()
            if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
            UpdatePlayerRows()
        end)

        if p == LocalPlayer then
            tp.Visible = false
            spec.Visible = false
            esp.Visible = false
        end

        local entry = { frame = row, player = p, meta = meta, hp = hp,
            stroke = stroke, select = sel, esp = esp, spec = spec }
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
                    e.hp.Text = math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth) .. " HP"
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
                e.meta.Text = (p == LocalPlayer and ("ping " .. ping .. " · ") or "")
                    .. dist .. " · " .. team .. " · " .. Elapsed(State.JoinTimes[p.UserId]
                        and (os.clock() - State.JoinTimes[p.UserId]) or nil)

                local isSel = (State.SelectedPlayer == p)
                e.stroke.Transparency = isSel and 0.15 or 1
                e.select.Text = isSel and "É O ALVO" or "ALVO"
                e.esp.Text = EspOpts.Pick[p.UserId] and "ESP ON" or "ESP"
                e.spec.Text = (State.SpectateTarget == p) and "PARAR" or "SPEC"
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
end)
V8.Mod("src/40_tabs/05_moderation.lua", 8464, 8655, function() --------------------------------------------------------------------------------
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

    -- v8.1: o card TROLL mudou para a seção própria (40_tabs/12_troll.lua)

    OnTabOpen("Moderation", UpdateSelectedInfo)
    UpdateSelectedInfo()
end
end)
V8.Mod("src/40_tabs/06_server.lua", 8657, 8790, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/40_tabs/07_emotes.lua", 8792, 9384, function() --------------------------------------------------------------------------------
-- ABA EMOTES (catálogo pesquisável + tocar por ID + favoritos)
--
-- Limitação do Roblox, não do painel: o Animator só carrega animação cujo
-- asset pertença ao dono do jogo (você ou o grupo) ou à própria Roblox. ID de
-- terceiro "carrega" com duração 0 e não anima nada — o painel confere isso
-- depois de tocar e avisa no log (e marca a linha do catálogo), em vez de
-- fingir que tocou.
--
-- v8.1:
--   * catálogo pesquisável: emotes padrão DO JOGO (lidos do script Animate do
--     seu personagem — sempre carregam, R6 e R15) + emotes e danças que a
--     Roblox publicou (só R15)
--   * velocidade de reprodução (Playback Speed) e "Andar com o emote":
--     desligado, o emote para quando você anda (como no Roblox); ligado, ele
--     continua enquanto você se move
--
-- Só mexe no SEU personagem. A animação replica para os outros normalmente
-- (você é o dono da física dele). Forçar emote em outra pessoa é server-side.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Emotes")
        if SET.EmoteWalk == nil then SET.EmoteWalk = false end

        local E = { failed = {}, filter = "Todos", query = "" }
        V8.Emotes = E
        local currentBox   -- "tocando agora"

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
        E.ParseId = ParseId

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
            Drop("EmoteMove")
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

        -- entry (opcional): linha do catálogo — r15 = só toca em R15
        Emote.Play = function(raw, label, entry)
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
            if entry and entry.r15 and h.RigType == Enum.HumanoidRigType.R6 then
                Log(tostring(label or id) .. " é um emote R15 — seu personagem é R6 "
                    .. "(este jogo usa R6). Os emotes 'Padrão' funcionam.", "warn")
                Toast("Emote só para R15", "warn", 2)
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
            label = label or ("ID " .. id)
            SetStatus(label .. "  •  em loop", "Success")
            Log("Emote tocando: " .. label, "action")

            -- "Andar com o emote" desligado: andar encerra o emote
            Conn.EmoteMove = h:GetPropertyChangedSignal("MoveDirection"):Connect(function()
                if SET.EmoteWalk or Emote.track ~= track then return end
                if h.MoveDirection.Magnitude > 0.1 then
                    Emote.Stop(true)
                    Log("Emote parou porque você andou (ligue 'Andar com o emote' "
                        .. "para continuar andando com ele)")
                end
            end)

            -- asset recusado pelo Roblox: a track existe, mas com duração 0
            task.delay(3, function()
                if Emote.track ~= track then return end
                local len = 0
                pcall(function() len = track.Length end)
                if len > 0 then return end
                E.failed[id] = true
                Emote.Stop(true)
                SetStatus("Não carregou: " .. label, "Danger")
                Log("Animação " .. id .. " (" .. label .. ") não carregou — o Roblox recusou "
                    .. "o asset neste jogo", "error")
                if E.Render then pcall(E.Render) end
            end)
            return true
        end

        ----------------------------------------------------------------------------
        -- CATÁLOGO
        -- Emotes e danças que a própria Roblox publicou (R15). Os IDs ainda não
        -- foram conferidos um a um em jogo: o que não carregar é avisado no log e
        -- marcado como "não carregou" na lista.
        ----------------------------------------------------------------------------
        E.Catalog = {
            -- danças
            { "Hype Dance", 3695333486, "Dança" },     { "Line Dance", 4049037604, "Dança" },
            { "Baby Dance", 4265725525, "Dança" },     { "Dorky Dance", 4212455378, "Dança" },
            { "Air Dance", 4555808220, "Dança" },      { "Floss Dance", 5917459365, "Dança" },
            { "Dolphin Dance", 5918726674, "Dança" },  { "Old Town Road", 5937560570, "Dança" },
            { "Rodeo Dance", 5918728267, "Dança" },    { "Around Town", 3303391864, "Dança" },
            { "Top Rock", 3361276673, "Dança" },       { "Fancy Feet", 3333432454, "Dança" },
            { "Robot", 3338025566, "Dança" },          { "Monkey", 3333499508, "Dança" },
            { "Fashionable", 3333331310, "Dança" },    { "Twirl", 3334968680, "Dança" },
            { "Bunny Hop", 4641985101, "Dança" },      { "Rock Out", 5915714366, "Dança" },
            -- emotes
            { "Salute", 3360689775, "Emote" },         { "Tilt", 3360692915, "Emote" },
            { "Stadium", 3360686498, "Emote" },        { "Shrug", 3576968026, "Emote" },
            { "Hello", 3576686446, "Emote" },          { "Point", 3576823880, "Emote" },
            { "Godlike", 3337994105, "Emote" },        { "Superhero Reveal", 3695373233, "Emote" },
            { "Heisman Pose", 3695263073, "Emote" },   { "Celebrate", 3338097973, "Emote" },
            { "Haha", 3337966527, "Emote" },           { "Greatest", 3338042785, "Emote" },
            { "Sneaky", 3334424322, "Emote" },         { "Bodybuilder", 3333387824, "Emote" },
            { "Happy", 4841405708, "Emote" },          { "Jumping Wave", 4940564896, "Emote" },
            { "Confused", 4940561610, "Emote" },       { "Cower", 4940563117, "Emote" },
            { "Zombie", 4210116953, "Emote" },         { "Curtsy", 4555816777, "Emote" },
            { "Sleep", 4686925579, "Emote" },          { "Shy", 3337978742, "Emote" },
            { "T", 3338010159, "Emote" },              { "Tree", 4049551434, "Emote" },
            { "Fishing", 3994127840, "Emote" },
        }

        -- emotes padrão do jogo: o script Animate do personagem guarda os IDs
        -- (/e wave, /e dance...). Sempre carregam, R6 ou R15.
        local DEFAULTS = {
            { "wave", "Acenar" }, { "point", "Apontar" }, { "cheer", "Comemorar" },
            { "laugh", "Rir" }, { "dance", "Dança 1" }, { "dance2", "Dança 2" },
            { "dance3", "Dança 3" },
        }
        E.FromGame = function()
            local out = {}
            local char = Char()
            local animate = char and char:FindFirstChild("Animate")
            if not animate then return out end
            for _, d in ipairs(DEFAULTS) do
                local folder = animate:FindFirstChild(d[1])
                local a = folder and folder:FindFirstChildOfClass("Animation")
                local id = a and ParseId(a.AnimationId)
                if id then table.insert(out, { name = d[2], id = id, kind = "Padrão" }) end
            end
            return out
        end

        E.All = function()
            local rows = E.FromGame()
            for _, c in ipairs(E.Catalog) do
                table.insert(rows, { name = c[1], id = c[2], kind = c[3], r15 = true })
            end
            return rows
        end

        local function AddFav(id, name)
            for _, f in ipairs(State.Emotes) do
                if tonumber(f.id) == tonumber(id) then
                    Toast(name .. " já está nos favoritos", "warn", 1.6)
                    return
                end
            end
            table.insert(State.Emotes, { name = name, id = id })
            Log("Emote salvo: " .. name .. " (" .. id .. ")", "ok")
            Toast("Salvo nos favoritos", "ok", 1.5)
            if V8.RenderEmotes then V8.RenderEmotes() end
        end

        ----------------------------------------------------------------------------
        -- AGORA (status, parar, velocidade, andar com o emote)
        ----------------------------------------------------------------------------
        local now = CreateCard(tab, "TOCANDO AGORA", 1)
        currentBox = SubLabel(now, "Nada tocando.", 1)
        currentBox.Font = Enum.Font.GothamBold
        currentBox.TextSize = 12

        local nowBtns = Grid(now, 2, 32)
        nowBtns.LayoutOrder = 2
        local stopBtn = CreateButton(nowBtns, "PARAR", "Danger", 32)
        stopBtn.LayoutOrder = 1
        stopBtn.MouseButton1Click:Connect(function() Emote.Stop() end)

        local rnd = CreateButton(nowBtns, "DANÇA ALEATÓRIA", "Accent", 32)
        rnd.LayoutOrder = 2
        rnd.MouseButton1Click:Connect(function()
            local pool = {}
            local h = Hum()
            local r6 = h and h.RigType == Enum.HumanoidRigType.R6
            for _, e in ipairs(E.All()) do
                local dance = e.kind == "Dança" or (e.kind == "Padrão" and e.name:find("Dança"))
                if dance and not E.failed[e.id] and not (r6 and e.r15) then
                    table.insert(pool, e)
                end
            end
            if #pool == 0 then
                Toast("Nenhuma dança disponível para este personagem", "warn", 2)
                return
            end
            local e = pool[math.random(1, #pool)]
            Emote.Play(e.id, e.name, e)
        end)

        SliderRow(now, {
            label = "Velocidade (Playback Speed)", min = 10, max = 300, def = 100,
            suffix = "%", order = 3,
            apply = function(v)
                Emote.Speed = v / 100
                if Emote.track then
                    pcall(function() Emote.track:AdjustSpeed(Emote.Speed) end)
                end
            end,
        })

        CheckRow(now, "Andar com o emote",
            "Desligado: o emote para quando você anda (como no Roblox)",
            function() return SET.EmoteWalk == true end,
            function(v) SET.EmoteWalk = v and true or false end, 4)

        ----------------------------------------------------------------------------
        -- CATÁLOGO (busca + filtro + lista)
        ----------------------------------------------------------------------------
        local cat = CreateCard(tab, "CATÁLOGO", 2)
        local search = CreateInput(cat, "Buscar emote ou dança...", 32)
        search.LayoutOrder = 1

        local pills = Grid(cat, 4, 28)
        pills.LayoutOrder = 2
        local pillBtns = {}

        local countLbl = SubLabel(cat, "", 3)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 4
        list.Parent = cat
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local function PaintPills()
            for name, b in pairs(pillBtns) do
                local on = (name == E.filter)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        for i, name in ipairs({ "Todos", "Danças", "Emotes", "Padrão" }) do
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = THEME.Btn
            b.Text = name
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = pills
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
            pillBtns[name] = b
            b.MouseButton1Click:Connect(function()
                E.filter = name
                PaintPills()
                E.Render()
            end)
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, PaintPills)

        local KIND_OF = { ["Danças"] = "Dança", ["Emotes"] = "Emote", ["Padrão"] = "Padrão" }

        local function Row(e, order)
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = THEME.Btn
            row.Text = ""
            row.AutoButtonColor = false
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -140, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 4)
            nm.BackgroundTransparency = 1
            nm.Text = e.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local failed = E.failed[e.id]
            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(1, -140, 0, 13)
            sub.Position = UDim2.new(0, 12, 0, 22)
            sub.BackgroundTransparency = 1
            sub.Text = failed and "não carregou neste jogo"
                or (e.kind == "Padrão" and "padrão do jogo" or (e.kind .. " · R15"))
            sub.TextColor3 = failed and THEME.Danger or THEME.Dim
            sub.Font = Enum.Font.GothamMedium
            sub.TextSize = 10
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Parent = row
            Paint(sub, "TextColor3", failed and "Danger" or "Dim")

            local play = CreateButton(row, "TOCAR", "Accent", 26)
            play.Size = UDim2.new(0, 62, 0, 26)
            play.Position = UDim2.new(1, -128, 0.5, -13)
            play.TextSize = 11
            play.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name, e) end)

            local fav = CreateButton(row, "+ FAV", "Accent2", 26)
            fav.Size = UDim2.new(0, 56, 0, 26)
            fav.Position = UDim2.new(1, -62, 0.5, -13)
            fav.TextSize = 11
            fav.MouseButton1Click:Connect(function() AddFav(e.id, e.name) end)

            row.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name, e) end)
        end

        E.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local q = E.query
            local want = KIND_OF[E.filter]
            local shown, total = 0, 0
            for _, e in ipairs(E.All()) do
                total = total + 1
                local passKind = (want == nil) or (e.kind == want)
                local passQ = (q == "") or (e.name:lower():find(q, 1, true) ~= nil)
                if passKind and passQ then
                    shown = shown + 1
                    Row(e, shown)
                end
            end
            local h = Hum()
            countLbl.Text = shown .. " de " .. total .. " animações"
                .. ((h and h.RigType == Enum.HumanoidRigType.R6)
                    and "   ·   personagem R6: só os 'padrão' tocam" or "")
        end

        search:GetPropertyChangedSignal("Text"):Connect(function()
            E.query = search.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
            E.Render()
        end)
        -- personagem novo (R6/R15, Animate diferente): a lista acompanha
        OnTabOpen("Emotes", function() pcall(E.Render) end)
        PaintPills()
        E.Render()

        ----------------------------------------------------------------------------
        -- TOCAR POR ID
        ----------------------------------------------------------------------------
        local play = CreateCard(tab, "TOCAR POR ID", 3)
        SubLabel(play, "Cole o ID da animação (aceita rbxassetid:// ou a URL do "
            .. "catálogo). Toca em loop até você apertar PARAR.", 1)

        local idBox = CreateInput(play, "rbxassetid://0000000000", 34)
        idBox.LayoutOrder = 2

        local nameBox = CreateInput(play, "nome para salvar nos favoritos (opcional)", 32)
        nameBox.LayoutOrder = 3

        local rowA = Grid(play, 2, 32)
        rowA.LayoutOrder = 4
        local playBtn = CreateButton(rowA, "TOCAR", "Accent", 32)
        playBtn.LayoutOrder = 1
        local addBtn = CreateButton(rowA, "SALVAR NOS FAVORITOS", "Accent2", 32)
        addBtn.LayoutOrder = 2

        playBtn.MouseButton1Click:Connect(function() Emote.Play(idBox.Text) end)
        idBox.FocusLost:Connect(function(enter)
            if enter then Emote.Play(idBox.Text) end
        end)
        addBtn.MouseButton1Click:Connect(function()
            local id = ParseId(idBox.Text)
            if not id then
                Toast("Cole um ID válido no campo acima", "warn", 2)
                return
            end
            local nm = nameBox.Text
            if nm == "" then nm = "Emote " .. (#State.Emotes + 1) end
            nameBox.Text = ""
            AddFav(id, nm)
        end)

        ----------------------------------------------------------------------------
        -- FAVORITOS
        ----------------------------------------------------------------------------
        local fav = CreateCard(tab, "FAVORITOS", 4)
        SubLabel(fav, "Os favoritos vão na config em disco. O nome também funciona no "
            .. "comando: emote <nome>.", 1)

        local favList = Instance.new("Frame")
        favList.Size = UDim2.new(1, 0, 0, 0)
        favList.AutomaticSize = Enum.AutomaticSize.Y
        favList.BackgroundTransparency = 1
        favList.LayoutOrder = 4
        favList.Parent = fav
        do
            local l = Instance.new("UIListLayout", favList)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local favEmpty = SubLabel(fav, "Nenhum favorito salvo — use + FAV no catálogo.", 5)

        local function RenderFavs()
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
                idLbl.Size = UDim2.new(0, 90, 1, 0)
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
                go.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name) end)

                local del = CreateButton(row, "EXCLUIR", "Danger", 24)
                del.Size = UDim2.new(0, 68, 0, 24)
                del.Position = UDim2.new(1, -70, 0.5, -12)
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

        local clearBtn = CreateButton(fav, "LIMPAR TODOS", "Line", 30)
        clearBtn.LayoutOrder = 6
        clearBtn.MouseButton1Click:Connect(function()
            if #State.Emotes == 0 then return end
            Confirm("Apagar todos os " .. #State.Emotes .. " favoritos?", function()
                for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
                Log("Favoritos de emote limpos", "action")
                RenderFavs()
            end)
        end)

        RenderFavs()
        V8.RenderEmotes = RenderFavs  -- 50_v8/03_persist.lua re-renderiza favoritos importados

        ----------------------------------------------------------------------------
        -- COMO FUNCIONA
        ----------------------------------------------------------------------------
        local info = CreateCard(tab, "COMO FUNCIONA", 5)
        SubLabel(info, "1. O Roblox só carrega animação cujo asset pertença ao dono do "
            .. "jogo ou à própria Roblox. O que não carregar é avisado no console e "
            .. "marcado na lista.", 1)
        SubLabel(info, "2. 'Padrão' são os emotes do próprio jogo (/e wave, /e dance...): "
            .. "funcionam em R6 e R15. O resto do catálogo é R15.", 2)
        SubLabel(info, "3. A animação roda no SEU personagem e os outros jogadores veem. "
            .. "Forçar emote em outra pessoa é server-side — o painel não faz.", 3)
        SubLabel(info, "4. Durante o Fly, tocar um emote desliga a pose de voo (as duas "
            .. "mexem nas mesmas juntas). Respawn derruba a animação.", 4)
    end
    Build()
end
end)
V8.Mod("src/40_tabs/08_settings.lua", 9386, 9819, function() --------------------------------------------------------------------------------
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

    for i, id in ipairs(ToggleOrder) do
        KeybindRow(keyCard, id, Toggles[id].label).LayoutOrder = i
    end

    -- v8.1: a tecla que abre/fecha o painel também é remapeável (vai na config)
    do
        local function PanelKeyRow()
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 44)
            row.LayoutOrder = 0
            row.Parent = keyCard
            V8.Cell(row, 5)

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -110, 1, 0)
            name.BackgroundTransparency = 1
            name.Text = "Abrir/fechar o painel"
            name.TextColor3 = THEME.Text
            name.Font = Enum.Font.GothamBold
            name.TextSize = 13
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = row
            Paint(name, "TextColor3", "Text")

            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.new(1, 0, 0.5, 0)
            btn.Size = UDim2.new(0, 96, 0, 28)
            btn.BackgroundColor3 = THEME.Btn
            btn.Text = KeyName(CONFIG.PanelKey)
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
            V8.PanelKeyLabel = btn

            btn.MouseButton1Click:Connect(function()
                StopCapture()   -- encerra outra captura em andamento
                Drop("PanelCapture")
                capturing = "panel"
                btn.Text = "aperte..."
                Toast("Aperte a nova tecla do painel", nil, 3)
                Conn.PanelCapture = UserInputService.InputBegan:Connect(function(input)
                    if capturing ~= "panel" then
                        Drop("PanelCapture")
                        btn.Text = KeyName(CONFIG.PanelKey)
                        return
                    end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    local kc = input.KeyCode
                    if kc == Enum.KeyCode.Unknown then return end
                    Drop("PanelCapture")
                    -- solta a captura só depois deste evento: senão o handler
                    -- global vê a tecla nova e já abre/fecha o painel
                    task.defer(function()
                        if capturing == "panel" then capturing = nil end
                    end)
                    local clash
                    if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace
                        or kc == Enum.KeyCode.Return then
                        clash = "uso do Roblox"
                    elseif kc == CONFIG.ConsoleKey then
                        clash = "barra de comandos"
                    elseif kc == CONFIG.SearchKey and not CONFIG.SearchCtrl then
                        clash = "busca global"
                    end
                    for tid, k in pairs(Keybinds) do
                        if k == kc then clash = Toggles[tid] and Toggles[tid].label or tid end
                    end
                    if clash then
                        Toast("[" .. KeyName(kc) .. "] já é de " .. clash .. " — nada mudou", "warn", 3)
                    else
                        CONFIG.PanelKey = kc
                        Log("Tecla do painel = " .. KeyName(kc), "ok")
                        -- v9.0: a tecla do painel ganha de tudo: macro nela some
                        if V8.Macro and V8.Macro.Release then pcall(V8.Macro.Release, kc) end
                    end
                    btn.Text = KeyName(CONFIG.PanelKey)
                end)
            end)
        end
        PanelKeyRow()
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
        CONFIG.PanelKey = Enum.KeyCode.B   -- v8.1: a tecla do painel também volta
        if V8.PanelKeyLabel then V8.PanelKeyLabel.Text = KeyName(CONFIG.PanelKey) end
        Log("Keybinds restaurados (painel B · F/N/E/C/G)", "ok")
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
        -- v9.0: a prévia ao vivo da cor personalizada reaplica o tema várias
        -- vezes seguidas; nessas o log fica quieto
        if not V8.QuietTheme then Log("Tema: " .. paletteName, "ok") end
    end

    local themeGrid = Grid(look, 3, 32)
    themeGrid.LayoutOrder = 1
    -- v9.0: 9 temas (Rosa, Laranja e Meia-noite novos); a cor personalizada
    -- tem cartão próprio (50_v8/12_colors.lua)
    for i, n in ipairs(THEME_ORDER) do
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
        label = "Tamanho da GUI", min = 70, max = 130, def = 100, suffix = "%", order = 2,
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

    -- v9.0.1: o Shift do Roblox prendia o mouse no centro (Shift Lock) — e o
    -- Fly usa o Shift para acelerar. Quem aplica é o V8.ShiftLock (03_input).
    CheckRow(beh, "Bloquear Shift Lock do Roblox", "O Shift não prende mais o mouse no centro da tela",
        function() return SET.NoShiftLock ~= false end,
        function(v)
            SET.NoShiftLock = v
            if V8.ShiftLock then V8.ShiftLock.Sync() end
        end, 5)

    local maxLogSet = SliderRow(beh, {
        label = "Linhas guardadas no log", min = 20, max = 300, def = SET.MaxLog, order = 6,
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
                     chatspy = false, antiafk = true, freecam = false, drone = false,
                     antifall = false, antigrav = false, wallwalk = false },
        Admin    = { esp = true, fullbright = true, antiafk = true, chatspy = true,
                     noclip = false, fly = false, drone = false, freecam = false },
        Visual   = { esp = true, fullbright = true, wall = true, chatspy = false,
                     fly = false, noclip = false, drone = false, freecam = false },
        Movement = { fly = true, noclip = true, infjump = true, esp = false,
                     fullbright = false, drone = false, freecam = false,
                     antifall = true, wallwalk = false },
        Minimal  = { antiafk = true, fly = false, noclip = false, esp = false,
                     fullbright = false, infjump = false, god = false,
                     invisible = false, wall = false, chatspy = false,
                     freecam = false, drone = false, antifall = false,
                     antigrav = false, wallwalk = false },
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

    local preGrid = Grid(pre, 3, 32)   -- v8.0: janela estreita (era 5)
    for i, n in ipairs({ "Default", "Admin", "Visual", "Movement", "Minimal" }) do
        local b = CreateButton(preGrid, n:upper(), "Accent", 32)
        b.LayoutOrder = i
        b.MouseButton1Click:Connect(function() ApplyPreset(n) end)
    end

    ----------------------------------------------------------------------------
    -- SISTEMA
    ----------------------------------------------------------------------------
    -- v8.2: 12 = Celular e toque, 13 = Atualização (50_v8); Sistema e Sobre no fim
    local sys = CreateCard(tab, "SISTEMA", 20)
    local sysGrid = Grid(sys, 2, 32)   -- v8.0: janela estreita (era 4)

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
            SET.NoShiftLock = true
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

    local about = CreateCard(tab, "SOBRE", 21)
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

    -- v9.0: reabre o cartão de novidades (50_v8/15_news.lua)
    local news = CreateButton(about, "VER NOVIDADES DA " .. CONFIG.Version:upper(), "Accent", 32)
    news.LayoutOrder = 2
    news.MouseButton1Click:Connect(function()
        if V8.News then V8.News.Show(false) end
    end)
end
end)
V8.Mod("src/40_tabs/09_shop.lua", 9821, 10144, function() --------------------------------------------------------------------------------
-- v8.1 — PLAYTIME SHOP (ícone de sacola do dock)
-- Loja do próprio painel paga com tempo de jogo: 1 ponto por minuto com o HYGE
-- aberto (V8.Play, 30_kit/05_playtime.lua). Categorias: All, Ranks, Icons,
-- Titles, Effects, Nametags, Bundles. Tudo é visual e local — nada de Robux,
-- nada que mexa no jogo. Effects e Nametags são criados pelo SEU cliente no
-- seu personagem: só você vê (a loja diz isso na cara, não esconde).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Shop")
        local P = V8.Play
        local S = { cat = "All" }
        V8.Shop = S

        ----------------------------------------------------------------------------
        -- SALDO
        ----------------------------------------------------------------------------
        local wallet = CreateCard(tab, "SALDO", 1)
        local tiles = Grid(wallet, 3, 48)
        tiles.LayoutOrder = 1
        local tPoints = StatTile(tiles, "PONTOS", "—", 1, "Success")
        local tTime = StatTile(tiles, "TEMPO DE JOGO", "—", 2, "Accent2")
        local tItems = StatTile(tiles, "ITENS", "—", 3)
        local status = SubLabel(wallet, "", 2)

        ----------------------------------------------------------------------------
        -- EQUIPADO
        ----------------------------------------------------------------------------
        -- v8.2: a ordem 2 é das Missões (50_v8/08_quests.lua)
        local eq = CreateCard(tab, "EQUIPADO", 3)
        local eqLbl = SubLabel(eq, "", 1)
        eqLbl.TextColor3 = THEME.Text
        eqLbl.Font = Enum.Font.GothamMedium
        eqLbl.TextSize = 12
        for _, e in ipairs(Painted) do   -- SubLabel nasce "Dim": troca no registry
            if e.inst == eqLbl then e.key = "Text" end
        end

        local off = CreateButton(eq, "TIRAR TUDO", "Line", 30)
        off.LayoutOrder = 2
        off.MouseButton1Click:Connect(function()
            P.UnequipAll()
            Log("Playtime Shop: tudo desequipado", "action")
        end)

        ----------------------------------------------------------------------------
        -- ITENS (categorias + lista)
        ----------------------------------------------------------------------------
        local shop = CreateCard(tab, "ITENS", 4)
        local pills = Grid(shop, 4, 28)
        pills.LayoutOrder = 1
        local pillBtns = {}

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 3
        list.Parent = shop
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local hint = SubLabel(shop, "", 2)

        local CAT_HINT = {
            All      = "Tudo o que dá para comprar com tempo de jogo.",
            Ranks    = "Seu rank aparece no perfil da Home, na nametag e no chat HYGE.",
            Icons    = "Desenho ao lado do seu nome no perfil da Home.",
            Titles   = "Título embaixo do nome (perfil, nametag e chat HYGE).",
            Effects  = "Efeito no seu personagem — criado no seu cliente: SÓ VOCÊ VÊ.",
            Nametags = "Placa acima da sua cabeça — criada no seu cliente: SÓ VOCÊ VÊ.",
            Bundles  = "Pacotes com desconto; o preço cai pelo que você já tem.",
        }
        local CAT_ICON = { Ranks = "shield", Icons = "star", Titles = "clip",
            Effects = "sun", Nametags = "user", Bundles = "bag" }

        local function PaintPills()
            for name, b in pairs(pillBtns) do
                local on = (name == S.cat)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        -- miniatura à esquerda de cada item
        local function Preview(parent, it)
            local box = Instance.new("Frame")
            box.Size = UDim2.new(0, 36, 0, 36)
            box.Position = UDim2.new(0, 8, 0.5, -18)
            box.BackgroundColor3 = it.color or THEME.Track
            box.BorderSizePixel = 0
            box.Parent = parent
            if not it.color then Paint(box, "BackgroundColor3", "Track") end
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
            if it.cat == "Titles" then
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, 0, 1, 0)
                t.BackgroundTransparency = 1
                t.Text = "Aa"
                t.TextColor3 = THEME.Text
                t.Font = Enum.Font.GothamBlack
                t.TextSize = 14
                t.Parent = box
                Paint(t, "TextColor3", "Text")
            elseif it.cat ~= "Ranks" then
                local ic = Icon(box, it.icon or CAT_ICON[it.cat] or "dot", THEME.Text, 20, 1)
                ic.AnchorPoint = Vector2.new(0.5, 0.5)
                ic.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
        end

        local function Describe(it)
            if it.cat == "Bundles" then
                local names = {}
                for _, sub in ipairs(it.items or {}) do
                    local s = P.ById[sub]
                    if s then table.insert(names, s.name) end
                end
                local _, have, total = P.BundlePrice(it)
                return table.concat(names, " + ")
                    .. (have > 0 and ("  (você já tem " .. have .. "/" .. total .. ")") or "")
            end
            return it.desc or it.cat
        end

        local function Row(it, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 52)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            Preview(row, it)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -160, 0, 18)
            nm.Position = UDim2.new(0, 54, 0, 8)
            nm.BackgroundTransparency = 1
            nm.Text = it.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 13
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -160, 0, 14)
            ds.Position = UDim2.new(0, 54, 0, 27)
            ds.BackgroundTransparency = 1
            ds.Text = (S.cat == "All" and (it.cat .. " · ") or "") .. Describe(it)
            ds.TextColor3 = THEME.Dim
            ds.Font = Enum.Font.GothamMedium
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.TextTruncate = Enum.TextTruncate.AtEnd
            ds.Parent = row
            Paint(ds, "TextColor3", "Dim")

            -- botão: preço / equipar / equipado / completo
            local slot = P.SlotOf[it.cat]
            local owned = P.Owned[it.id]
            local price = P.PriceOf(it)
            local text, key
            if it.cat == "Bundles" then
                local _, have, total = P.BundlePrice(it)
                if have >= total then
                    text, key = "COMPLETO", "Line"
                else
                    text, key = price .. " PTS", (P.Points() >= price) and "Success" or "Line"
                end
            elseif owned then
                if slot and P.Equip[slot] == it.id then
                    text, key = "EQUIPADO", "Success"
                else
                    text, key = "EQUIPAR", "Accent"
                end
            else
                text, key = price .. " PTS", (P.Points() >= price) and "Success" or "Line"
            end

            local b = CreateButton(row, text, key, 30)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -10, 0.5, 0)
            b.Size = UDim2.new(0, 92, 0, 30)
            b.TextSize = 11
            if key == "Line" then
                b.TextColor3 = THEME.Dim
                Paint(b, "TextColor3", "Dim")
            end

            b.MouseButton1Click:Connect(function()
                if text == "COMPLETO" then
                    Toast("Você já tem tudo deste pacote", nil, 2)
                elseif text == "EQUIPADO" then
                    P.Unequip(slot)
                    Log("Playtime Shop: " .. it.name .. " desequipado", "action")
                elseif text == "EQUIPAR" then
                    P.EquipItem(it.id)
                    Log("Playtime Shop: " .. it.name .. " equipado", "ok")
                    Toast(it.name .. " equipado", "ok", 1.6)
                else
                    if P.Points() < price then
                        Toast("Faltam " .. (price - P.Points()) .. " pontos ("
                            .. P.Fmt((price - P.Points()) * 60) .. " de jogo)", "warn", 3)
                        return
                    end
                    Confirm("Comprar " .. it.name .. " por " .. price .. " pontos?", function()
                        local ok, res = P.Buy(it.id)
                        if not ok then
                            Toast(tostring(res), "warn", 3)
                            return
                        end
                        Log("Playtime Shop: comprou " .. it.name .. " (" .. tostring(res)
                            .. " pts)", "ok")
                        Toast(it.name .. " comprado", "ok", 2)
                        -- item avulso já entra equipado
                        if slot then P.EquipItem(it.id) end
                    end)
                end
            end)
        end

        S.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local n = 0
            for _, it in ipairs(P.Items) do
                if S.cat == "All" or it.cat == S.cat then
                    n = n + 1
                    Row(it, n)
                end
            end
            hint.Text = CAT_HINT[S.cat] or ""
        end

        S.Tick = function()
            tPoints.Text = tostring(P.Points())
            tTime.Text = P.Fmt(P.Total)
            local owned, total = 0, 0
            for _, it in ipairs(P.Items) do
                if it.cat ~= "Bundles" then
                    total = total + 1
                    if P.Owned[it.id] then owned = owned + 1 end
                end
            end
            tItems.Text = owned .. "/" .. total
            local nextMin = 60 - math.floor(P.Total % 60)
            status.Text = "1 ponto por minuto com o HYGE aberto — próximo em " .. nextMin
                .. "s. Missões e bônus diário dão mais.  " .. tostring(P.Status or "")
        end

        local SLOT_NAME = { rank = "Rank", icon = "Ícone", title = "Título",
            effect = "Efeito", nametag = "Nametag" }
        local function RenderEquip()
            local parts = {}
            for _, slot in ipairs({ "rank", "icon", "title", "effect", "nametag" }) do
                local it = P.Equipped(slot)
                table.insert(parts, SLOT_NAME[slot] .. ": " .. (it and it.name or "—"))
            end
            eqLbl.Text = table.concat(parts, "   ·   ")
        end

        for i, name in ipairs(P.Cats) do
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = THEME.Btn
            b.Text = name
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = pills
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
            pillBtns[name] = b
            b.MouseButton1Click:Connect(function()
                S.cat = name
                PaintPills()
                S.Render()
            end)
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, PaintPills)

        -- a lista só redesenha quando algo muda (compra, equipar, carregar)
        P.OnChange(function()
            pcall(S.Render)
            pcall(S.Tick)
            pcall(RenderEquip)
        end)
        -- a cada minuto o saldo sobe: o preço pode ficar verde sem compra nenhuma
        do
            local lastPts = -1
            V8.TabTick.Shop = function()
                S.Tick()
                local pts = P.Points()
                if pts ~= lastPts then
                    lastPts = pts
                    S.Render()
                end
            end
        end
        OnTabOpen("Shop", function()
            pcall(S.Tick)
            pcall(S.Render)
        end)

        PaintPills()
        S.Render()
        S.Tick()
        RenderEquip()
    end
    Build()
end
end)
V8.Mod("src/40_tabs/10_scripts.lua", 10146, 10220, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/40_tabs/11_chat.lua", 10222, 10351, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/40_tabs/12_troll.lua", 10353, 10541, function() --------------------------------------------------------------------------------
-- v8.1 — SEÇÃO TROLL (ícone de máscara do dock)
-- * Walk on Walls (20_features/10_wallwalk.lua): roda no SEU personagem, então
--   funciona em qualquer jogo — e os outros veem você andando na parede.
-- * Ações no alvo (veio da aba Moderação): Fling/Spin/Trip/Launch/Sit/Scale/
--   Balloon mexem no personagem de OUTRA pessoa, e isso só o servidor pode
--   fazer. Sem o RemoteEvent (script em server/) o botão fica indisponível e
--   explica o motivo — nada é fingido. Fake Message é só na sua tela.
-- O alvo é o jogador escolhido em Jogadores › Lista (botão ALVO).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Troll")

        ----------------------------------------------------------------------------
        -- MOVIMENTO
        ----------------------------------------------------------------------------
        local mov = CreateCard(tab, "MOVIMENTO", 1)
        SwitchRow(mov, "wallwalk", "Walk on Walls", Toggles.wallwalk.desc)
        SubLabel(mov, "Ande contra uma parede para subir nela; continue para chegar ao "
            .. "teto. WASD segue a câmera, Space pula para fora da superfície e, sem "
            .. "nada embaixo por ~1 s, a gravidade volta ao normal. Usa a WalkSpeed e o "
            .. "JumpPower de Personagem. Desliga sozinho no respawn ou se Fly/Drone/"
            .. "Freecam forem ligados.", 2)

        ----------------------------------------------------------------------------
        -- ALVO
        ----------------------------------------------------------------------------
        local tgt = CreateCard(tab, "ALVO", 2)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 58)
        holder.LayoutOrder = 1
        holder.Parent = tgt
        V8.Cell(holder, 0)

        local av = Avatar(holder, 1, 40)
        av.Position = UDim2.new(0, 0, 0.5, -20)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -160, 0, 18)
        name.Position = UDim2.new(0, 50, 0, 11)
        name.BackgroundTransparency = 1
        name.Text = "Nenhum alvo"
        name.TextColor3 = THEME.Text
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = holder
        Paint(name, "TextColor3", "Text")

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -160, 0, 14)
        sub.Position = UDim2.new(0, 50, 0, 30)
        sub.BackgroundTransparency = 1
        sub.Text = "escolha em Jogadores › Lista (botão ALVO)"
        sub.TextColor3 = THEME.Dim
        sub.Font = Enum.Font.Code
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.Parent = holder
        Paint(sub, "TextColor3", "Dim")

        local pick = CreateButton(holder, "ESCOLHER", "Accent", 28)
        pick.AnchorPoint = Vector2.new(1, 0.5)
        pick.Position = UDim2.new(1, 0, 0.5, 0)
        pick.Size = UDim2.new(0, 96, 0, 28)
        pick.TextSize = 11
        pick.MouseButton1Click:Connect(function() ShowTab("Players") end)

        local function Target()
            local p = State.SelectedPlayer
            if not p or not p.Parent then
                name.Text = "Nenhum alvo"
                sub.Text = "escolha em Jogadores › Lista (botão ALVO)"
                av.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48"
                return
            end
            av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
            name.Text = p.DisplayName
            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mine = Root()
            sub.Text = "@" .. p.Name .. ((root and mine)
                and ("  ·  " .. math.floor((root.Position - mine.Position).Magnitude) .. "m")
                or "  ·  sem personagem")
        end

        ----------------------------------------------------------------------------
        -- AÇÕES NO ALVO (servidor)
        ----------------------------------------------------------------------------
        local troll = CreateCard(tab, "AÇÕES NO ALVO", 3)
        SubLabel(troll, "Mexer no personagem de outra pessoa é coisa do servidor: estes "
            .. "botões só funcionam com o RemoteEvent + validação (script pronto em "
            .. "server/). Sem o Remote o botão fica indisponível — nada aqui é fingido.", -1)

        local grid = Grid(troll, 3, 32)

        ActionBtn(grid, "FLING", "Danger", "Fling", function()
            local p = RequireSelected()
            if p then FlingPlayer(p) end
        end, "Aplicar Fling no alvo?")

        local spinBtn
        spinBtn = ActionBtn(grid, "SPIN: OFF", "Warning", "Spin", function()
            local p = RequireSelected()
            if not p then return end
            local on = not TrollState.Spin[p.UserId]
            SpinPlayer(p, on)
            spinBtn.Text = on and "SPIN: ON" or "SPIN: OFF"
        end)

        ActionBtn(grid, "TRIP", "Warning", "Trip", function()
            local p = RequireSelected()
            if p then TripPlayer(p) end
        end)

        ActionBtn(grid, "LAUNCH", "Danger", "Launch", function()
            local p = RequireSelected()
            if p then LaunchPlayer(p) end
        end, "Lançar o alvo bem alto?")

        ActionBtn(grid, "FORCE SIT", "Warning", "Sit", function()
            local p = RequireSelected()
            if p then SitPlayer(p) end
        end)

        local balloonBtn
        balloonBtn = ActionBtn(grid, "BALLOON: OFF", "Accent", "Balloon", function()
            local p = RequireSelected()
            if not p then return end
            local on = not TrollState.Balloon[p.UserId]
            BalloonPlayer(p, on)
            balloonBtn.Text = on and "BALLOON: ON" or "BALLOON: OFF"
        end)

        ActionBtn(grid, "TINY", "Accent", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "tiny") end
        end, "Encolher o alvo?")

        ActionBtn(grid, "NORMAL", "Success", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "normal") end
        end)

        ActionBtn(grid, "GIANT", "Accent", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "giant") end
        end, "Deixar o alvo gigante?")

        Divider(troll).LayoutOrder = 10

        local fake = Grid(troll, 2, 32)
        fake.LayoutOrder = 11

        ActionBtn(fake, "FAKE KICK MSG", "Warning", nil, function()
            local p = RequireSelected()
            if p then FakeMessage(p, "kick") end
        end)

        ActionBtn(fake, "FAKE BAN MSG", "Danger", nil, function()
            local p = RequireSelected()
            if p then FakeMessage(p, "ban") end
        end)

        SubLabel(troll, "Fake Message só aparece na SUA tela — não afeta o alvo nem o "
            .. "servidor.", 12)

        -- os botões de liga/desliga seguem o alvo atual
        local function Sync()
            local p = State.SelectedPlayer
            local id = p and p.UserId
            -- sem o Remote o botão mostra "(servidor)": não mexe no texto
            if Remotes.Spin then
                spinBtn.Text = (id and TrollState.Spin[id]) and "SPIN: ON" or "SPIN: OFF"
            end
            if Remotes.Balloon then
                balloonBtn.Text = (id and TrollState.Balloon[id]) and "BALLOON: ON" or "BALLOON: OFF"
            end
        end

        V8.TabTick.Troll = function() Target() Sync() end
        OnTabOpen("Troll", function() pcall(Target) pcall(Sync) end)
        Target()
    end
    Build()
end
end)
V8.Mod("src/40_tabs/13_hychat.lua", 10543, 10923, function() --------------------------------------------------------------------------------
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
end)
V8.Mod("src/50_v8/00_dock.lua", 10925, 11391, function() --------------------------------------------------------------------------------
-- v8.0 — DOCK (navegação principal)
-- Barra solta no rodapé da TELA, visível mesmo com o painel fechado (é ela que
-- abre o painel; a bolinha "H" só aparece no modo sidebar). v8.1: 8 seções:
--   Início · Personagem · Playtime Shop · Troll · Emotes · Jogadores ·
--   Configurações · Chat
-- O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel.
-- Navegação dentro da seção (as duas posicionadas pelo V8.Shell):
--   * sub-abas em pílula no topo da janela (Início, Personagem, Jogadores,
--     Configurações › Ajustes · Console, Chat › HYGE · Jogo)
--   * uma seção com subdock = true ganha uma segunda barra de ícones logo
--     acima do dock (nenhuma usa na v8.1; o mecanismo continua disponível)
-- O título grande da janela (V8.Shell.SetTitle) acompanha a seção ativa.
-- A sidebar continua existindo: SET.Dock escolhe dock OU sidebar (Ajustes).
-- Tudo em V8.Dock: zero locais novos. Entra DEPOIS das abas (40_tabs) no build.
--------------------------------------------------------------------------------
do
    V8.Dock = {}
    local K = V8.Dock

    if SET.Dock == nil then SET.Dock = true end

    K.BOTTOM, K.H = 14, 56      -- distância do rodapé da tela e altura do dock
    K.SUB_H, K.GAP = 50, 10     -- barra de sub-ícones (Scripts) e respiro

    -- tabs: { aba interna, nome, ícone (só usado na barra de sub-ícones) }
    K.Sections = {
        { id = "inicio",  icon = "home",     label = "Início",
          tabs = { { "Home", "Painel" }, { "Server", "Servidor" } } },
        { id = "char",    icon = "user",     label = "Personagem",
          tabs = { { "Movement", "Movimento" }, { "Visuals", "Visual" } } },
        { id = "shop",    icon = "bag",      label = "Playtime Shop",
          tabs = { { "Shop", "Shop" } } },
        { id = "troll",   icon = "mask",     label = "Troll",
          tabs = { { "Troll", "Troll" } } },
        { id = "emotes",  icon = "smile",    label = "Emotes",
          tabs = { { "Emotes", "Emotes" } } },
        { id = "players", icon = "users",    label = "Jogadores",
          tabs = { { "Players", "Lista" }, { "Moderation", "Moderação" } } },
        { id = "config",  icon = "gear",     label = "Configurações",
          tabs = { { "Settings", "Ajustes" }, { "Scripts", "Console" } } },
        { id = "chat",    icon = "chat",     label = "Chat",
          tabs = { { "HyChat", "HYGE" }, { "Chat", "Jogo" } } },
    }

    K.ById = {}        -- id -> seção
    K.TabSection = {}  -- aba interna -> seção
    K.LastTab = {}     -- id -> última sub-aba usada (volta nela ao reabrir)
    K.Btns = {}        -- id -> { button, icon, label }
    K.Current = nil    -- seção da aba ativa
    K.SubWasOn = false -- a barra de sub-ícones estava visível? (o shell usa)
    for _, s in ipairs(K.Sections) do
        K.ById[s.id] = s
        for _, t in ipairs(s.tabs) do K.TabSection[t[1]] = s end
    end

    local function IsOpenNow() return V8.IsOpen and V8.IsOpen() or false end

    -- moldura padrão das duas barras (dock e sub-ícones)
    local function BarFrame(name, height, radius)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 1)
        f.Size = UDim2.new(0, 0, 0, height)
        f.AutomaticSize = Enum.AutomaticSize.X
        f.BackgroundColor3 = THEME.Sidebar
        f.BackgroundTransparency = 0.02
        f.BorderSizePixel = 0
        f.Visible = false
        f.ZIndex = 20
        f.Parent = Gui
        Paint(f, "BackgroundColor3", "Sidebar")
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, radius)
        local st = Instance.new("UIStroke", f)
        st.Transparency = 0.2
        Paint(st, "Color", "Line")
        local l = Instance.new("UIListLayout", f)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.SortOrder = Enum.SortOrder.LayoutOrder
        return f, l
    end

    -- nome no hover (o ícone ativo do dock já mostra o nome ao lado)
    local function Tip(parent)
        local t = Instance.new("TextLabel")
        t.AnchorPoint = Vector2.new(0.5, 1)
        t.Position = UDim2.new(0.5, 0, 0, -8)
        t.Size = UDim2.new(0, 0, 0, 22)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundColor3 = THEME.Card
        t.Text = ""
        t.TextColor3 = THEME.Text
        t.Font = Enum.Font.GothamBold
        t.TextSize = 11
        t.Visible = false
        t.ZIndex = 22
        t.Parent = parent
        Paint(t, "BackgroundColor3", "Card")
        Paint(t, "TextColor3", "Text")
        Instance.new("UICorner", t).CornerRadius = UDim.new(0, 7)
        local p = Instance.new("UIPadding", t)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)
        return t
    end

    ----------------------------------------------------------------------------
    -- o dock (filho da ScreenGui, não da janela)
    ----------------------------------------------------------------------------
    local bar, barLayout = BarFrame("Dock", K.H, 18)
    bar.Position = UDim2.new(0.5, 0, 1, -K.BOTTOM)
    barLayout.Padding = UDim.new(0, 2)
    do
        local pad = Instance.new("UIPadding", bar)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
    end
    K.Bar = function() return bar end
    local tip = Tip(bar)

    -- os 8 botões: ícone sozinho; o ativo ganha o nome ao lado (sem fundo)
    for i, s in ipairs(K.Sections) do
        local b = Instance.new("TextButton")
        b.Name = s.id
        b.Size = UDim2.new(0, 44, 0, 44)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.LayoutOrder = i
        b.ZIndex = 20
        b.Parent = bar
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
        lbl.TextSize = 14
        lbl.Visible = false
        lbl.LayoutOrder = 2
        lbl.ZIndex = 20
        lbl.Parent = b
        Paint(lbl, "TextColor3", "Text")

        K.Btns[s.id] = { button = b, icon = ico, label = lbl }

        b.MouseEnter:Connect(function()
            if lbl.Visible then return end   -- ativo: nome já está à vista
            tip.Text = s.label
            tip.Visible = true
            IconTint(ico, THEME.Text)
        end)
        b.MouseLeave:Connect(function()
            tip.Visible = false
            if not lbl.Visible then IconTint(ico, THEME.Dim) end
        end)
        b.MouseButton1Click:Connect(function()
            tip.Visible = false
            K.Open(s.id, true)
        end)
    end

    ----------------------------------------------------------------------------
    -- barra de sub-ícones (seção com subdock = true): uma por seção, logo
    -- acima do dock. Ativo = quadradinho claro com o ícone escuro.
    ----------------------------------------------------------------------------
    for _, s in ipairs(K.Sections) do
        if s.subdock then
            local f, l = BarFrame("SubDock_" .. s.id, K.SUB_H, 16)
            f.Position = UDim2.new(0.5, 0, 1, -(K.BOTTOM + K.H + K.GAP))
            l.Padding = UDim.new(0, 6)
            do
                local p = Instance.new("UIPadding", f)
                p.PaddingLeft = UDim.new(0, 5)
                p.PaddingRight = UDim.new(0, 5)
            end
            local subTip = Tip(f)
            s.sub, s.subBtns = f, {}

            for i, t in ipairs(s.tabs) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 40, 0, 40)
                b.BackgroundColor3 = THEME.Accent
                b.BackgroundTransparency = 1
                b.Text = ""
                b.AutoButtonColor = false
                b.LayoutOrder = i
                b.ZIndex = 20
                b.Parent = f
                Paint(b, "BackgroundColor3", "Accent")
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 11)

                local ico = Icon(b, t[3] or "dot", THEME.Dim, 20, 1)
                ico.AnchorPoint = Vector2.new(0.5, 0.5)
                ico.Position = UDim2.new(0.5, 0, 0.5, 0)
                ico.ZIndex = 21

                local u = { button = b, icon = ico, tab = t[1] }
                s.subBtns[i] = u

                b.MouseEnter:Connect(function()
                    subTip.Text = t[2]
                    subTip.Visible = true
                    if u.tab ~= State.ActiveTab then IconTint(ico, THEME.Text) end
                end)
                b.MouseLeave:Connect(function()
                    subTip.Visible = false
                    if u.tab ~= State.ActiveTab then IconTint(ico, THEME.Dim) end
                end)
                b.MouseButton1Click:Connect(function()
                    subTip.Visible = false
                    ShowTab(u.tab)
                end)
            end
        end
    end

    ----------------------------------------------------------------------------
    -- sub-abas em pílula no topo da janela (largura toda, divididas por igual)
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
        sb.Size = UDim2.new(0.5, -3, 1, 0)
        sb.BackgroundColor3 = THEME.Btn
        sb.Text = ""
        sb.TextColor3 = THEME.Text
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 12
        sb.AutoButtonColor = false
        sb.LayoutOrder = i
        sb.Visible = false
        sb.Parent = seg
        Paint(sb, "BackgroundColor3", "Btn")
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 10)
        local u = { btn = sb, tab = nil }
        segBtns[i] = u
        sb.MouseButton1Click:Connect(function()
            if u.tab then ShowTab(u.tab) end
        end)
    end

    K.SegShown = function()
        local s = K.Current
        return s ~= nil and not s.subdock and #s.tabs > 1
    end

    K.SubShown = function()
        local s = K.Current
        return s ~= nil and s.subdock == true and SET.Dock == true
            and IsOpenNow() and not State.Minimized
    end

    K.RenderSeg = function()
        local s = K.Current
        local n = K.SegShown() and #s.tabs or 0
        local gap = (n > 1) and math.ceil(6 * (n - 1) / n) or 0
        for i, u in ipairs(segBtns) do
            local t = (n > 1) and s.tabs[i]
            if t then
                local on = (t[1] == State.ActiveTab)
                u.tab = t[1]
                u.btn.Text = t[2]
                u.btn.Visible = true
                u.btn.Size = UDim2.new(1 / n, -gap, 1, 0)
                u.btn.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                u.btn.TextColor3 = on and THEME.Main or THEME.Text
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

    K.RenderSub = function()
        local subOn = false
        for _, s in ipairs(K.Sections) do
            if s.sub then
                local show = (K.Current == s) and K.SubShown()
                s.sub.Visible = show
                if show then
                    subOn = true
                    for _, u in ipairs(s.subBtns) do
                        local on = (u.tab == State.ActiveTab)
                        u.button.BackgroundTransparency = on and 0 or 1
                        IconTint(u.icon, on and THEME.Main or THEME.Dim)
                    end
                end
            end
        end
        -- a janela "em casa" sobe/desce para não cobrir a barra de sub-ícones.
        -- Só com o painel aberto: fechando, ela não "desce" enquanto some (e
        -- reabrindo na mesma seção, nada se mexe)
        if IsOpenNow() and subOn ~= K.SubWasOn then
            K.SubWasOn = subOn
            if V8.Shell and V8.Shell.Reflow then pcall(V8.Shell.Reflow) end
        end
    end

    -- título da janela: seção com sub-ícones mostra a sub-aba ("Emotes");
    -- as outras mostram o nome da seção ("Personagem")
    K.TitleFor = function(s, active)
        if not s then return tostring(active or "") end
        if s.subdock then
            for _, t in ipairs(s.tabs) do
                if t[1] == active then return t[2] end
            end
        end
        return s.label
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
            IconTint(u.icon, on and THEME.Text or THEME.Dim)
        end
        K.RenderSeg()
        K.RenderSub()
        if V8.Shell and V8.Shell.SetTitle then
            pcall(V8.Shell.SetTitle, K.TitleFor(s, active))
        end
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
    -- comandos) mantém o dock, as sub-abas e o título em dia
    do
        local base = ShowTab
        ShowTab = function(name)
            base(name)
            pcall(K.Sync, name)
        end
    end

    -- troca de tema: ícones (IconTint) e switches não ficam no registry
    -- Painted — repinta tudo que se desenha à mão
    do
        local baseTheme = ApplyTheme
        if baseTheme then
            ApplyTheme = function(name)
                local r = baseTheme(name)
                pcall(K.Sync, State.ActiveTab)
                if V8.Renders then
                    for _, render in ipairs(V8.Renders) do pcall(render) end
                end
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
            .. "dentro da janela larga (com a bolinha H para abrir).", 0)

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
                .. "chatspy, fullbright, antiafk, freecam, drone, antifall, antigrav, "
                .. "wallwalk.", 2)

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
end)
V8.Mod("src/50_v8/01_shell.lua", 11393, 11781, function() --------------------------------------------------------------------------------
-- v8.0 — SHELL (layout novo)
-- NAO recria a janela: reconfigura as instancias que o engine ja criou.
-- Dois modos, escolhidos por SET.Dock (Ajustes › Navegação):
--   * DOCK (padrao): janela "em pe" de 460x520, estilo cartao — titulo grande
--     da secao a esquerda e o selo "HYGE" a direita. Sem fechar/minimizar: o
--     dock (clicar de novo no icone ativo) e a tecla do painel fecham. A janela
--     nasce logo acima do dock (e sobe quando a barra de sub-icones aparece).
--   * SIDEBAR: janela larga de 800x500 com "Welcome home", relogio, chips de
--     FPS/ping e os botoes de fechar/minimizar.
-- Tudo em V8.Shell: zero locais novos no chunk principal.
-- Entra DEPOIS de 00_dock.lua e ANTES de 02_situations.lua no build.
--------------------------------------------------------------------------------
do
    V8.Shell = {}
    local H = V8.Shell

    H.DockW, H.DockH, H.DockTop = 460, 520, 54   -- modo dock
    H.SideW, H.SideH, H.SideTop = 800, 500, 62   -- modo sidebar
    H.W, H.Hgt, H.TopH = H.DockW, H.DockH, H.DockTop
    H.ConsoleH = 168    -- compat: o console mora na aba Scripts
    H.ConsoleOpen = false
    H.Blue = Color3.fromRGB(0, 175, 255)   -- azul do selo de verificado
    H.SideBits = {}     -- pecas do cabecalho que so existem no modo sidebar

    H.IsDock = function() return SET.Dock ~= false end

    ----------------------------------------------------------------------------
    -- 1. TOPBAR: esconde logo/titulo/versao/Stat do motor antigo (nao destroi —
    --    o scheduler ainda escreve em Stat.Text quando SetChips nao existe)
    ----------------------------------------------------------------------------
    for _, c in ipairs(TopBar:GetChildren()) do
        -- o "topFix" (tapa o canto arredondado de baixo) tem essa medida exata
        local isFix = c:IsA("Frame") and c.Size == UDim2.new(1, 0, 0, 16)
        if isFix then H.TopFix = c end
        if c.Name == "StatChips" then H.Chips = c end
        local keep = (c == CloseBtn) or (c == MinBtn) or (c.Name == "StatChips") or isFix
        if not keep and (c:IsA("TextLabel") or c:IsA("Frame")
            or c:IsA("ImageLabel")) then
            c.Visible = false
        end
    end
    do
        local c = TopBar:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, 18) end
    end

    -- borda da janela: linha sutil (o brilho no destaque some no tema claro)
    pcall(function()
        for _, e in ipairs(Painted) do
            if e.inst == winStroke and e.prop == "Color" then e.key = "Line" end
        end
        winStroke.Color = THEME.Line
        winStroke.Transparency = 0.15
        winStroke.Thickness = 1
    end)

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

    ----------------------------------------------------------------------------
    -- 2a. CABECALHO DO MODO SIDEBAR: "Welcome home, <nome>" + relogio
    ----------------------------------------------------------------------------
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

    H.SideBits = { head, sub, clock }

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
    if H.Chips then
        local chips = H.Chips
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

    ----------------------------------------------------------------------------
    -- 2b. CABECALHO DO MODO DOCK: titulo grande da secao + selo "HYGE"
    ----------------------------------------------------------------------------
    local title = Instance.new("TextLabel")
    title.Name = "SectionTitle"
    title.Position = UDim2.new(0, 20, 0, 4)
    title.Size = UDim2.new(1, -120, 1, -4)
    title.BackgroundTransparency = 1
    title.Text = "Início"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = TopBar
    Paint(title, "TextColor3", "Text")
    H.TitleLbl = title

    local pill = Instance.new("TextLabel")
    pill.Name = "Brand"
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -16, 0.5, 2)
    pill.Size = UDim2.new(0, 0, 0, 24)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = THEME.Text
    pill.Text = "HYGE"
    pill.TextColor3 = THEME.Main
    pill.Font = Enum.Font.GothamBold
    pill.TextSize = 12
    pill.Parent = TopBar
    Paint(pill, "BackgroundColor3", "Text")
    Paint(pill, "TextColor3", "Main")
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    do
        local p = Instance.new("UIPadding", pill)
        p.PaddingLeft = UDim.new(0, 12)
        p.PaddingRight = UDim.new(0, 12)
    end
    H.Pill = pill

    -- "Jogadores" ganha a contagem ao lado, como na referencia ("Players 70")
    H.TitleBase = "Início"
    H.TitleText = function()
        local t = H.TitleBase or ""
        if V8.Dock and V8.Dock.Current and V8.Dock.Current.id == "players" then
            t = t .. "   " .. #Players:GetPlayers()
        end
        return t
    end
    H.SetTitle = function(text)
        H.TitleBase = tostring(text or "")
        title.Text = H.TitleText()
    end

    -- chamado pelo Every(1) que ja existe em 90_runtime/04_scheduler.lua
    -- (nenhum loop novo): relogio do modo sidebar + contagem de jogadores
    H.Tick = function()
        pcall(function() clockLbl.Text = os.date("%H:%M") end)
        pcall(function() title.Text = H.TitleText() end)
    end
    H.Tick()

    ----------------------------------------------------------------------------
    -- 3. POSICAO "DE CASA"
    --    dock: centralizada logo acima do dock (ou da barra de sub-icones)
    --    sidebar: no meio da tela. Usada tambem por 'center'.
    ----------------------------------------------------------------------------
    H.HomePos = function()
        local sc = CONFIG.UiScale or 1
        if H.IsDock() then
            local vh = Gui.AbsoluteSize.Y
            if vh < 100 then vh = Camera.ViewportSize.Y end
            local gap = 82                                  -- dock + respiro
            if V8.Dock and V8.Dock.SubWasOn then gap = gap + 60 end
            return UDim2.new(0.5, -H.W * sc * 0.5, 0,
                math.max(8, math.floor(vh - H.Hgt * sc - gap)))
        end
        return UDim2.new(0.5, -H.W * sc * 0.5, 0.5, -H.Hgt * sc * 0.5)
    end

    -- volta para casa (com animacao) — so se o usuario nunca arrastou a janela
    H.Reflow = function()
        if SET.WinPos ~= nil then return end
        Anim(Window, 0.2, { Position = H.HomePos() })
    end

    -- resolucao mudou: a janela "em casa" acompanha
    Conn.ShellFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if SET.WinPos == nil then pcall(function() Window.Position = H.HomePos() end) end
    end)

    ----------------------------------------------------------------------------
    -- 4. MODO (tamanho da janela + cabecalho) e GEOMETRIA do Content
    ----------------------------------------------------------------------------
    H.ApplyMode = function()
        local dock = H.IsDock()
        H.W = dock and H.DockW or H.SideW
        H.Hgt = dock and H.DockH or H.SideH
        H.TopH = dock and H.DockTop or H.SideTop

        -- no dock nao existe botao de restaurar: nunca fica minimizado
        if dock and State.Minimized then
            State.Minimized = false
            Content.Visible = true
            MinBtn.Text = "—"
        end

        TopBar.Size = UDim2.new(1, 0, 0, H.TopH)
        TopBar.BackgroundTransparency = dock and 1 or 0
        if H.TopFix then H.TopFix.Visible = not dock end
        for _, o in ipairs(H.SideBits) do o.Visible = not dock end
        if H.Chips then H.Chips.Visible = not dock end
        CloseBtn.Visible = not dock
        MinBtn.Visible = not dock
        title.Visible = dock
        pill.Visible = dock

        Sidebar.Size = UDim2.new(0, 164, 1, -H.TopH)
        Sidebar.Position = UDim2.new(0, 0, 0, H.TopH)

        local c = Window:FindFirstChildOfClass("UICorner")
        if c then c.CornerRadius = UDim.new(0, dock and 22 or 18) end
        Window.Size = UDim2.new(0, H.W, 0, State.Minimized and H.TopH or H.Hgt)

        if H.LastMode ~= dock then
            H.LastMode = dock
            if SET.WinPos == nil then Window.Position = H.HomePos() end
        end
    end

    -- uma funcao unica manda na janela, no Content e nas sub-abas.
    -- O dock mora fora da janela: nada e reservado no rodape.
    H.Layout = function()
        H.ApplyMode()
        local dockOn = H.IsDock()
        local left = dockOn and 14 or 172
        local wOff = dockOn and -28 or -186
        local top = dockOn and H.TopH or (H.TopH + 10)
        local bottom = 14

        -- sub-abas em pilula da secao ativa (ex.: Personagem › Movimento | Visual)
        local seg = V8.Dock and V8.Dock.Seg
        if seg then
            local show = dockOn and V8.Dock.SegShown() and not State.Minimized
            seg.Visible = show
            seg.Position = UDim2.new(0, left, 0, top)
            seg.Size = UDim2.new(1, wOff, 0, 32)
            if show then top = top + 42 end
        end

        Content.Position = UDim2.new(0, left, 0, top)
        Content.Size = UDim2.new(1, wOff, 1, -(top + bottom))
    end

    -- compatibilidade: quem pedia "abrir o console" agora abre a aba do
    -- console (v8.1: Configurações › Console); com ela aberta, fecha o painel
    H.ToggleConsole = function()
        local open = V8.IsOpen and V8.IsOpen()
        if open and State.ActiveTab == "Scripts" then
            if V8.SetOpen then V8.SetOpen(false) end
            return
        end
        ShowTab("Scripts")
        if not open and V8.SetOpen then V8.SetOpen(true) end
    end

    ----------------------------------------------------------------------------
    -- 5. ajustes no dashboard da Home: o card "Welcome home" sai e o nome sob
    --    o avatar ganha o selo azul
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
    end
    H.Layout()
    if SET.WinPos == nil then Window.Position = H.HomePos() end

    ----------------------------------------------------------------------------
    -- 7. paleta padrao (CONFIG.DefaultTheme = Grafite). Se houver config salva
    --    em disco, o BootStep "Config" roda depois e o tema salvo ganha.
    ----------------------------------------------------------------------------
    if ApplyTheme and PALETTES[CONFIG.DefaultTheme] then
        SET.Theme = SET.Theme or CONFIG.DefaultTheme
        pcall(ApplyTheme, SET.Theme)
    end
end
end)
V8.Mod("src/50_v8/02_situations.lua", 11783, 12122, function() --------------------------------------------------------------------------------
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

        local grid = Grid(card, 2, 54)   -- v8.0: janela estreita (era 3)
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
                        -- v9.0: situação ganha das macros no handler global
                        if V8.Macro and V8.Macro.Release then pcall(V8.Macro.Release, kc) end
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
end)
V8.Mod("src/50_v8/03_persist.lua", 12124, 12719, function() --------------------------------------------------------------------------------
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
    -- v9.1: o que a gravação segura (V8.Disk.SafeWrite) aceita como válido
    local function JsonOk(s) return Decode(s) ~= nil end
    C.JsonOk = JsonOk

    ----------------------------------------------------------------------------
    -- snapshot / restauração
    ----------------------------------------------------------------------------
    local ESP_KEYS = { "Highlight", "Name", "UseDisplay", "Distance", "Health",
                       "HealthBar", "Tracers", "Allies", "Enemies", "MaxDist",
                       "Rate", "ColorKey", "AllyKey", "TeamColors" }
    local SET_KEYS = { "Animations", "Toasts", "ShowLogs", "Confirm", "EspAuto",
                       "MaxLog", "Compact", "Transparency", "AutoSave", "SitOnLoad",
                       "Dock", "Slots", "WinPos", "Island",
                       -- v8.1
                       "Auto", "AutoRejoin", "EmoteWalk", "ChatRelay", "ChatOn",
                       "ChatToasts",
                       -- v8.1.1: animação do voo
                       "FlyStyle", "FlyTilt",
                       -- v8.2: pacotes de animação, botões na tela, atualização
                       "Packs", "PackOn", "FlyPack", "TouchHud", "UpdateCheck",
                       -- v9.0: favoritos, notificações, cor própria, macros,
                       -- tela de novidades
                       "Favs", "Dnd", "ToastDur", "CustomHue", "CustomSat",
                       "Macros", "SeenVersion",
                       -- v9.0.1: bloqueio do Shift Lock do Roblox
                       "NoShiftLock" }
    C.SetKeys = SET_KEYS   -- v9.0: os perfis usam a mesma lista

    -- v8.2: waypoints POR JOGO. State.Waypoints é sempre a lista do jogo
    -- atual; os dos outros jogos ficam aqui (como vieram do arquivo) e voltam
    -- intactos no próximo Save.
    C.WpOther = {}
    local PLACE = tostring(game.PlaceId)
    local function WpEncode(list)
        local out = {}
        for i, w in ipairs(list) do
            out[i] = { name = w.name, cf = { w.cframe:GetComponents() } }
        end
        return out
    end

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
                grav  = State.GravityPct,   -- v8.1
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
        -- v8.2: "waypoints" continua (só os deste jogo) para versões antigas
        -- lerem; "wpplaces" = { [PlaceId] = lista } com todos os jogos
        d.waypoints = WpEncode(State.Waypoints)
        d.wpplaces = {}
        for place, list in pairs(C.WpOther) do d.wpplaces[place] = list end
        if #d.waypoints > 0 then d.wpplaces[PLACE] = d.waypoints end
        if next(d.wpplaces) == nil then d.wpplaces = nil end
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
        -- v9.1: cada passo que falhar fica anotado (antes o pcall engolia e
        -- ninguém sabia). A troca de perfil confere C.LastRestoreErrors.
        local errs = {}
        C.LastRestoreErrors = errs
        local function Try(what, fn, ...)
            local ok, err = pcall(fn, ...)
            if not ok then table.insert(errs, what .. ": " .. tostring(err)) end
            return ok
        end

        -- comportamento / aparência
        if type(d.set) == "table" then
            for _, k in ipairs(SET_KEYS) do
                if d.set[k] ~= nil then SET[k] = d.set[k] end
            end
            CONFIG.MaxLog = SET.MaxLog or CONFIG.MaxLog
        end
        if d.theme and PALETTES[d.theme] and ApplyTheme then Try("tema", ApplyTheme, d.theme) end
        if ui.scale and d.scale then Try("tamanho", ui.scale, d.scale) end
        if ui.alpha and SET.Transparency then Try("transparência", ui.alpha, math.floor(SET.Transparency * 100 + 0.5)) end
        if ui.maxlog and SET.MaxLog then Try("log", ui.maxlog, SET.MaxLog, true) end
        if ui.compact then Try("modo compacto", ui.compact, SET.Compact == true) end
        if ui.compactRender then pcall(ui.compactRender) end
        -- sidebar x dock: o render do switch é visual, o Apply é que troca o layout
        if V8.Dock then Try("dock", V8.Dock.Apply, SET.Dock == true) end
        -- v8.0: posição da janela (validada e presa dentro da tela)
        if V8.Win and type(SET.WinPos) == "table" then pcall(V8.Win.Restore, SET.WinPos) end
        -- os 3 cards de status da Home (string "fly noclip esp")
        if type(SET.Slots) == "string" and V8.Dash and V8.Dash.SetSlots then
            Try("cards da Home", V8.Dash.SetSlots, SET.Slots, true)
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
            if d.speeds.walk and WalkSlider then Try("velocidade", WalkSlider, d.speeds.walk) end
            if d.speeds.fly and FlySlider then Try("velocidade do Fly", FlySlider, d.speeds.fly) end
            if d.speeds.jump and JumpSlider then Try("pulo", JumpSlider, d.speeds.jump) end
            if d.speeds.drone and DroneSpeedSlider then Try("velocidade do Drone", DroneSpeedSlider, d.speeds.drone) end
            if d.speeds.wall then State.WallAlpha = d.speeds.wall end
            if d.speeds.grav and V8.GravSlider then Try("gravidade", V8.GravSlider, d.speeds.grav) end
        end
        -- v8.1.1: o slider mostra a inclinação salva (o valor já veio em SET)
        if type(SET.FlyTilt) == "number" and V8.FlyTiltSlider then
            Try("inclinação do Fly", V8.FlyTiltSlider, SET.FlyTilt, true)
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
        if V8.PanelKeyLabel then V8.PanelKeyLabel.Text = KeyName(CONFIG.PanelKey) end
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

        -- waypoints (v8.2: por jogo; arquivo antigo sem "wpplaces" = a lista
        -- única de antes, que fica com o jogo em que ele foi carregado)
        local wpList = nil
        if type(d.wpplaces) == "table" then
            C.WpOther = {}
            for place, list in pairs(d.wpplaces) do
                if type(list) == "table" then C.WpOther[tostring(place)] = list end
            end
            wpList = C.WpOther[PLACE] or {}
            C.WpOther[PLACE] = nil
        elseif type(d.waypoints) == "table" then
            wpList = d.waypoints
            if #wpList > 0 then
                Log(#wpList .. " waypoint(s) da config antiga ficaram com este jogo "
                    .. "(agora cada jogo tem a sua lista)", "warn")
            end
        end
        if wpList then
            for i = #State.Waypoints, 1, -1 do State.Waypoints[i] = nil end
            for _, w in ipairs(wpList) do
                local c = w.cf
                if type(c) == "table" and #c >= 12 then
                    local ok, cf = pcall(function() return CFrame.new(table.unpack(c)) end)
                    if ok then
                        table.insert(State.Waypoints, { name = w.name or "WP", cframe = cf })
                    end
                end
            end
            if RenderWaypoints then pcall(RenderWaypoints) end
            -- v8.2: lista trocada inteira não conta como "salvou waypoint" nas missões
            if V8.Quest and V8.Quest.ResyncWp then pcall(V8.Quest.ResyncWp) end
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

    -- quiet (v9.0, salvamento automático): não escreve no log, só no status
    C.Save = function(silent, quiet)
        if not C.Supported() then
            if quiet then return false end
            Say("Não salvei: este executor não expõe writefile/readfile "
                .. "(use EXPORTAR e guarde o JSON à mão)", "error")
            if not silent then Toast("Executor sem API de arquivos — nada foi salvo", "error", 4) end
            return false
        end
        local json, err = Encode(C.Snapshot())
        if not json then
            if not quiet then Say("Falha ao gerar o JSON: " .. tostring(err), "error") end
            return false
        end
        if quiet and json == C.LastJson then return true end   -- nada mudou
        -- v9.1: temporário conferido -> backup da anterior -> principal
        -- conferido. Falhou em qualquer passo = a última config boa fica.
        local ok, werr = V8.Disk.SafeWrite(C.Path, json, JsonOk)
        if not ok then
            if quiet then return false end
            Say("Falha ao escrever " .. C.Path .. ": " .. tostring(werr), "error")
            if not silent then Toast("Não deu para salvar a config", "error", 4) end
            return false
        end
        C.LastJson = json
        C.LoadState = "ok"   -- salvou na mão depois de um erro: o automático volta
        if quiet then
            if status then status.Text = "Salvo sozinho às " .. os.date("%H:%M:%S")
                .. " (" .. #json .. " bytes)" end
            return true
        end
        Say("Config salva em " .. C.Path .. " (" .. #json .. " bytes)", "ok")
        if not silent then Toast("Config salva", "ok", 2) end
        return true
    end

    -- v9.0: SALVAMENTO AUTOMÁTICO. Antes a config só ia para o disco no
    -- Unload — quem saía do jogo sem descarregar o painel perdia o que mudou.
    -- Agora, com "Salvar automaticamente" ligado, a cada 30 s grava se algo
    -- mudou. Se o arquivo existia e NÃO deu para ler, não sobrescreve (para
    -- não apagar uma config que só está com problema).
    C.LoadState = nil   -- "ok" | "missing" | "error" (depois do boot)
    V8.Job(30, function()
        if not SET.AutoSave or C.LoadState == nil or C.LoadState == "error" then return end
        pcall(C.Save, true, true)
    end)

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
        -- v9.1: lê pela gravação segura — se o principal não presta, ela diz
        -- o que sobrou (.tmp de uma gravação interrompida ou o backup)
        local r = V8.Disk.SafeRead(C.Path, JsonOk)
        C.Recoverable = r.recover
        if r.state == "missing" then
            C.LoadState = C.LoadState or "missing"
            if not silent then Say("Nenhuma config salva ainda em " .. C.Path, "warn") end
            return false
        end
        if r.state == "corrupt" then
            C.LoadState = "error"
            local why = (r.raw == nil) and "não deu para ler" or (r.raw == "" and "está vazio"
                or ("JSON inválido: " .. tostring(select(2, Decode(r.raw)))))
            if #r.recover > 0 then
                Say(C.Path .. " " .. why .. ". Dá para recuperar: " .. r.recover[1].label
                    .. " — Configuração em disco › RECUPERAR (o salvamento automático fica "
                    .. "parado até lá)", "error")
                if silent then
                    -- no boot: pergunta (depois que a janela abrir)
                    task.delay(1.5, function()
                        pcall(Confirm, "A config salva (" .. C.Path .. ") " .. why
                            .. ". Recuperar do " .. r.recover[1].label .. "?", function()
                                C.RecoverNow(1)
                            end)
                    end)
                    Toast("Config estragada — dá para recuperar do backup", "error", 5)
                end
            else
                Say(C.Path .. " " .. why .. " e não há backup válido — o salvamento "
                    .. "automático fica parado até você SALVAR AGORA", "error")
            end
            return false
        end
        local d = Decode(r.text)
        local okR, rerr = pcall(C.Restore, d)
        if not okR then
            C.LoadState = "error"
            Say("Config lida, mas falhou ao aplicar: " .. tostring(rerr), "error")
            return false
        end
        C.LoadState = "ok"
        C.LastJson = nil
        Say("Config carregada de " .. C.Path, "ok")
        if C.LastRestoreErrors and #C.LastRestoreErrors > 0 then
            Log("Config: " .. #C.LastRestoreErrors .. " passo(s) não aplicaram — "
                .. table.concat(C.LastRestoreErrors, "; "), "warn")
        end
        if not silent then Toast("Config carregada", "ok", 2) end

        if SET.SitOnLoad and C.LastSituation and V8.Sit then
            pcall(V8.Sit.Apply, C.LastSituation)
        end
        return true
    end

    -- v9.1: recuperação. Com o principal estragado, as opções são as que o
    -- SafeRead achou; com ele bom, RECUPERAR volta para o backup (desfaz o
    -- último salvamento ou um RESETAR). O estragado vai para .corrupt.json.
    C.Candidates = function()
        if not C.Supported() then return {} end
        local r = V8.Disk.SafeRead(C.Path, JsonOk)
        if r.state ~= "ok" then return r.recover end
        local bak = V8.Disk.Paths(C.Path)
        local s = V8.Disk.Read(bak)
        if s and s ~= r.text and JsonOk(s) then
            return { { path = bak, text = s, label = "backup (anterior)" } }
        end
        return {}
    end

    C.RecoverNow = function(i)
        local list = C.Candidates()
        local c = list[i or 1]
        if not c then
            Say("Nada para recuperar: não há backup válido de " .. C.Path, "warn")
            return false
        end
        local ok, err = V8.Disk.Recover(C.Path, c.text, JsonOk)
        if not ok then
            Say("Não deu para recuperar: " .. tostring(err), "error")
            return false
        end
        Log("Config recuperada do " .. c.label, "ok")
        C.LoadState = nil
        return C.Load(false)
    end

    C.Reset = function()
        local removed = false
        if C.Supported() then
            pcall(function()
                if isfile(C.Path) and typeof(delfile) == "function" then
                    -- v9.1: a config apagada vira o backup (RECUPERAR desfaz)
                    local cur = V8.Disk.Read(C.Path)
                    if cur and JsonOk(cur) then V8.Disk.Write((V8.Disk.Paths(C.Path)), cur) end
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

        local g1 = Grid(card, 2, 32)   -- v9.1: 4 botões (era 3 colunas)
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
            Confirm("Apagar " .. C.Path .. " e voltar tudo ao padrão? (RECUPERAR desfaz)",
                function() C.Reset() end)
        end)

        -- v9.1: volta para o backup (config estragada, ou desfazer o último
        -- salvamento / um RESETAR)
        local bRec = CreateButton(g1, "RECUPERAR BACKUP", "Warning", 32)
        bRec.LayoutOrder = 4
        bRec.MouseButton1Click:Connect(function()
            local c = C.Candidates()[1]
            if not c then
                Say("Nada para recuperar: não há backup válido de " .. C.Path, "warn")
                return
            end
            Confirm("Trocar a config atual pelo " .. c.label .. " (" .. #c.text .. " bytes)?",
                function() C.RecoverNow(1) end)
        end)

        CheckRow(card, "Salvar automaticamente",
            "A cada 30 s, se algo mudou, e ao descarregar (v9.0)",
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
end)
V8.Mod("src/50_v8/04_search.lua", 12721, 13179, function() --------------------------------------------------------------------------------
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

    local input = CreateInput(box, "buscar função, ajuste, jogador, perfil, comando...", 36)
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
        -- v9.0: sem acento e sem caixa ("situacao" acha "Situação")
        q = V8.Fold and V8.Fold(q) or q
        local function add(kind, label, hint, run)
            local score
            local low = V8.Fold and V8.Fold(label) or tostring(label):lower()
            local k = V8.Fold and V8.Fold(kind) or kind
            if q == "" then
                score = 2
            elseif low:sub(1, #q) == q then
                score = 0
            elseif low:find(q, 1, true) then
                score = 1
            elseif k:find(q, 1, true) then
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

        -- v9.0: cartões de Configurações (abre já filtrado) e perfis
        if V8.SetNav and V8.SetNav.Cards then
            for _, e in ipairs(V8.SetNav.Cards) do
                if e.title ~= "" then
                    add("ajuste", e.title, "Configurações", function() V8.SetNav.Focus(e.title) end)
                end
            end
        end
        if V8.Prof and V8.Prof.Data then
            for _, r in ipairs(V8.Prof.Data.list) do
                local name = r.name
                add("perfil", name, (V8.Prof.Current == name) and "ativo" or "usar este perfil",
                    function()
                        local ok, err = V8.Prof.Use(name)
                        if not ok then Log(tostring(err), "error") end
                    end)
            end
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
end)
V8.Mod("src/50_v8/05_island.lua", 13181, 13315, function() --------------------------------------------------------------------------------
-- v8.0 — ILHA NO TOPO DA TELA
-- Pílula fixa no alto, centralizada: logo, hora, FPS e ping — à vista mesmo
-- com o painel fechado. Clicar abre/fecha o painel.
-- Sem loop próprio: o Every(0.5) do scheduler já chama SetChips(fps, ping, ...)
-- e a ilha pega carona nele. Some durante o drone (a bússola do HUD fica ali).
-- Ajustes › Ilha no topo liga/desliga (vai junto na config em disco).
-- Tudo em V8.Island: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    V8.Island = {}
    local I = V8.Island
    if SET.Island == nil then SET.Island = true end

    local pill = Instance.new("TextButton")
    pill.Name = "Island"
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 8)
    pill.Size = UDim2.new(0, 0, 0, 34)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = THEME.Sidebar
    pill.BackgroundTransparency = 0.02
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Visible = SET.Island ~= false
    pill.ZIndex = 20
    pill.Parent = Gui
    I.Pill = pill   -- v9.0: o sino das notificações mora aqui (50_v8/11_notify.lua)
    Paint(pill, "BackgroundColor3", "Sidebar")
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 12)
    do
        local st = Instance.new("UIStroke", pill)
        st.Transparency = 0.2
        Paint(st, "Color", "Line")
        local p = Instance.new("UIPadding", pill)
        p.PaddingLeft = UDim.new(0, 6)
        p.PaddingRight = UDim.new(0, 14)
        local l = Instance.new("UIListLayout", pill)
        l.FillDirection = Enum.FillDirection.Horizontal
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Padding = UDim.new(0, 12)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end

    -- logo: a mesma caixa "H" da marca (ou a imagem de CONFIG.LogoId)
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 24, 0, 24)
    logo.BackgroundColor3 = THEME.Accent
    logo.BorderSizePixel = 0
    logo.LayoutOrder = 1
    logo.ZIndex = 21
    logo.Parent = pill
    Paint(logo, "BackgroundColor3", "Accent")
    Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 7)
    if CONFIG.LogoId ~= "" then
        logo.BackgroundTransparency = 1
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = CONFIG.LogoId
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 22
        img.Parent = logo
    else
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, 0, 1, 0)
        h.BackgroundTransparency = 1
        h.Text = "H"
        h.TextColor3 = THEME.Main
        h.Font = Enum.Font.GothamBlack
        h.TextSize = 13
        h.ZIndex = 22
        h.Parent = logo
        Paint(h, "TextColor3", "Main")
    end

    local function Txt(order, size, key)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0, 0, 0, 18)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundTransparency = 1
        t.Text = "—"
        t.TextColor3 = THEME[key]
        t.Font = Enum.Font.GothamBold
        t.TextSize = size
        t.LayoutOrder = order
        t.ZIndex = 21
        t.Parent = pill
        Paint(t, "TextColor3", key)
        return t
    end
    local clock = Txt(2, 13, "Text")
    local fps = Txt(3, 12, "Text")
    local ping = Txt(4, 12, "Dim")

    I.Update = function(f, p)
        pill.Visible = (SET.Island ~= false) and not IsOn("drone")
        if not pill.Visible then return end
        clock.Text = os.date("%H:%M")
        fps.Text = "FPS " .. tostring(f or "—")
        ping.Text = tostring(p or "—") .. " ms"
        if type(f) == "number" then
            fps.TextColor3 = (f >= 50 and THEME.Text) or (f >= 30 and THEME.Warning)
                or THEME.Danger
        end
    end

    pill.MouseButton1Click:Connect(function()
        if V8.SetOpen and V8.IsOpen then V8.SetOpen(not V8.IsOpen()) end
    end)

    -- carona no Every(0.5) do scheduler (ele chama SetChips a cada meio segundo)
    do
        local base = SetChips
        SetChips = function(f, p, ...)
            if base then base(f, p, ...) end
            pcall(I.Update, f, p)
        end
    end

    -- Ajustes
    do
        local card = CreateCard(Tabs.Settings, "ILHA NO TOPO", 9)
        CheckRow(card, "Mostrar a ilha",
            "Hora, FPS e ping no alto da tela; clique abre/fecha o painel",
            function() return SET.Island ~= false end,
            function(v)
                SET.Island = v and true or false
                pcall(I.Update, State.Fps, nil)
            end, 1)
    end

    pcall(I.Update, State.Fps, nil)
end
end)
V8.Mod("src/50_v8/06_auto.lua", 13317, 13399, function() --------------------------------------------------------------------------------
-- v8.1 — RECURSOS AUTOMÁTICOS (Configurações › Ajustes › Automático)
-- * escolha quais funções ligam sozinhas toda vez que o painel carrega
--   (SET.Auto, vai na config em disco). O BootStep "Automático" roda depois do
--   "Config", então vale o que estava salvo.
-- * "Reconectar se cair": quando o Roblox mostra a tela de erro (desconexão,
--   expulsão), pede para entrar de novo no mesmo jogo — até 5 tentativas.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Auto = { rejoining = false }
        local A = V8.Auto
        if type(SET.Auto) ~= "table" then SET.Auto = {} end
        if SET.AutoRejoin == nil then SET.AutoRejoin = false end

        local function Auto()
            if type(SET.Auto) ~= "table" then SET.Auto = {} end
            return SET.Auto
        end

        A.List = {
            { "antiafk",    "Anti-AFK",      "Evita o kick por inatividade" },
            { "antifall",   "Anti-Fall",     "Sem tombo, sem dano de queda, salva do void" },
            { "esp",        "ESP",           nil },
            { "fullbright", "Fullbright",    nil },
            { "infjump",    "Infinite Jump", nil },
            { "chatspy",    "Chat Spy",      "Chat do servidor no console" },
            { "noclip",     "Noclip",        nil },
            { "clicktp",    "Ctrl + clique TP", "Ctrl + clique esquerdo teleporta (v8.2)" },
        }

        A.Run = function()
            local on = {}
            for _, item in ipairs(A.List) do
                local id = item[1]
                if Auto()[id] and Toggles[id] and not IsOn(id) then
                    SetToggle(id, true, true)
                    if IsOn(id) then table.insert(on, item[2]) end
                end
            end
            if #on > 0 then
                Log("Automático: " .. table.concat(on, ", ") .. " ligado(s) ao carregar", "ok")
            end
            if RefreshStatus then RefreshStatus() end
        end

        local card = CreateCard(Tabs.Settings, "AUTOMÁTICO", 5)
        SubLabel(card, "Liga sozinho toda vez que o painel carrega (a partir do próximo "
            .. "carregamento). Vai junto na config em disco.", -1)
        for i, item in ipairs(A.List) do
            CheckRow(card, item[2], item[3],
                function() return Auto()[item[1]] == true end,
                function(v) Auto()[item[1]] = v and true or nil end, i)
        end

        CheckRow(card, "Reconectar se cair",
            "Desconectou ou foi expulso: entra de novo no jogo (até 5 tentativas)",
            function() return SET.AutoRejoin == true end,
            function(v) SET.AutoRejoin = v and true or false end, 20)

        Conn.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(arg)
            if not SET.AutoRejoin or A.rejoining then return end
            local msg = type(arg) == "string" and arg or ""
            if msg == "" then pcall(function() msg = GuiService:GetErrorMessage() end) end
            if type(msg) ~= "string" or msg == "" then return end
            A.rejoining = true
            Log("Desconectado (" .. msg .. ") — reconectando...", "warn")
            task.spawn(function()
                for i = 1, 5 do
                    task.wait(i == 1 and 2 or 10)
                    local ok, err = pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                    Log("Reconectar: tentativa " .. i .. (ok and "" or (" falhou: " .. tostring(err))),
                        ok and "action" or "error")
                end
                A.rejoining = false
            end)
        end)
    end
    Build()
end
end)
V8.Mod("src/50_v8/07_mobile.lua", 13401, 13620, function() --------------------------------------------------------------------------------
-- v8.2 — CELULAR (botões na tela + janela que cabe)
-- * Botões na tela (SET.TouchHud; padrão: ligado em aparelho com toque):
--   FLY liga/desliga o voo; com ele ligado aparecem SUBIR, DESCER e 2x.
--   A direção do voo vem do analógico do Roblox (o ControlModule, o mesmo que
--   anda com o personagem) e segue a câmera: olhando para cima, sobe. Vale
--   também para controle (gamepad) no PC. O Fly chama M.FlyDir só quando
--   nenhuma tecla de movimento está apertada.
-- * Tela pequena (celular deitado): a janela do dock fica mais baixa para
--   caber acima do dock (o conteúdo rola) e o dock encolhe se não couber na
--   largura. Recalcula quando a tela muda (girar o aparelho).
-- Entra depois do dock e do shell no build. Tudo em V8.Mobile: zero locais
-- novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Mobile = { up = false, down = false, boost = false }
        local M = V8.Mobile
        M.Touch = UserInputService.TouchEnabled
        if SET.TouchHud == nil then SET.TouchHud = M.Touch end

        ----------------------------------------------------------------------------
        -- direção do voo
        ----------------------------------------------------------------------------
        local controls   -- nil = ainda não tentou; false = não deu
        local function Controls()
            if controls == nil then
                controls = false
                pcall(function()
                    local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
                    local pm = ps and ps:FindFirstChild("PlayerModule")
                    if pm then controls = require(pm):GetControls() or false end
                end)
            end
            return controls or nil
        end

        M.FlyDir = function(cam)
            local dir = Vector3.zero
            local mv
            local c = Controls()
            if c then pcall(function() mv = c:GetMoveVector() end) end
            if typeof(mv) == "Vector3" and mv.Magnitude > 0.05 then
                -- relativo à câmera: x = direita, -z = frente
                dir = cam.LookVector * (-mv.Z) + cam.RightVector * mv.X
            else
                -- sem ControlModule: a direção que o Roblox calcula (sem subir/descer)
                local h = Hum()
                local md = h and h.MoveDirection
                if md and md.Magnitude > 0.05 then dir = md end
            end
            if M.up then dir = dir + Vector3.yAxis end
            if M.down then dir = dir - Vector3.yAxis end
            return dir
        end

        ----------------------------------------------------------------------------
        -- botões na tela (coluna no lado direito, acima do pulo do Roblox)
        ----------------------------------------------------------------------------
        local hud = Instance.new("Frame")
        hud.Name = "TouchHud"
        hud.AnchorPoint = Vector2.new(1, 0.5)
        hud.Position = UDim2.new(1, -18, 0.4, 0)
        hud.Size = UDim2.new(0, 62, 0, 0)
        hud.AutomaticSize = Enum.AutomaticSize.Y
        hud.BackgroundTransparency = 1
        hud.Visible = false
        hud.ZIndex = 30
        hud.Parent = Gui
        do
            local l = Instance.new("UIListLayout", hud)
            l.Padding = UDim.new(0, 8)
            l.HorizontalAlignment = Enum.HorizontalAlignment.Center
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        M.Hud = hud

        local function Btn(text, order, size)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, size, 0, size)
            b.BackgroundColor3 = THEME.Card
            b.BackgroundTransparency = 0.12
            b.Text = text
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBlack
            b.TextSize = 12
            b.AutoButtonColor = false
            b.LayoutOrder = order
            b.ZIndex = 30
            b.Parent = hud
            Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke", b)
            st.Transparency = 0.25
            st.Thickness = 1.5
            Paint(st, "Color", "Line")
            return b
        end
        local bFly = Btn("FLY", 1, 62)
        local bUp = Btn("SUBIR", 2, 56)
        local bDown = Btn("DESCER", 3, 56)
        local bBoost = Btn("2x", 4, 46)

        -- segurar: guarda o InputObject do dedo (o analógico é outro dedo e não
        -- solta o botão); soltar fora do botão também solta
        local held = {}
        local function Paint4()
            local fly = IsOn("fly")
            bFly.BackgroundColor3 = fly and THEME.Accent or THEME.Card
            bFly.TextColor3 = fly and THEME.Main or THEME.Text
            bUp.Visible, bDown.Visible, bBoost.Visible = fly, fly, fly
            bUp.BackgroundColor3 = M.up and THEME.Accent or THEME.Card
            bUp.TextColor3 = M.up and THEME.Main or THEME.Text
            bDown.BackgroundColor3 = M.down and THEME.Accent or THEME.Card
            bDown.TextColor3 = M.down and THEME.Main or THEME.Text
            bBoost.BackgroundColor3 = M.boost and THEME.Accent or THEME.Card
            bBoost.TextColor3 = M.boost and THEME.Main or THEME.Text
        end
        local function Press(input)
            local t = input.UserInputType
            return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
        end
        local function Hold(b, key)
            b.InputBegan:Connect(function(input)
                if not Press(input) then return end
                held[key] = input
                M[key] = true
                Paint4()
            end)
        end
        Hold(bUp, "up")
        Hold(bDown, "down")
        Conn.TouchHudEnd = UserInputService.InputEnded:Connect(function(input)
            if not Press(input) then return end
            for key, obj in pairs(held) do
                if obj == input or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    held[key] = nil
                    M[key] = false
                end
            end
            Paint4()
        end)

        bFly.MouseButton1Click:Connect(function() Flip("fly") end)
        bBoost.MouseButton1Click:Connect(function()
            M.boost = not M.boost
            Paint4()
        end)

        table.insert(Toggles.fly.listeners, function(on)
            if not on then
                M.up, M.down = false, false
                for k in pairs(held) do held[k] = nil end
            end
            Paint4()
        end)

        M.Render = function()
            hud.Visible = SET.TouchHud == true
            Paint4()
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, M.Render)

        ----------------------------------------------------------------------------
        -- janela e dock que cabem na tela
        ----------------------------------------------------------------------------
        local dockScale
        if V8.Dock and V8.Dock.Bar then
            dockScale = Instance.new("UIScale")
            dockScale.Parent = V8.Dock.Bar()
        end

        M.Fit = function()
            local vp = Gui.AbsoluteSize
            if vp.X < 100 or vp.Y < 100 then vp = Camera.ViewportSize end
            if vp.X < 100 or vp.Y < 100 then return end
            -- dock: encolhe (até 60%) se for mais largo que a tela
            if dockScale then
                local bar = V8.Dock.Bar()
                local w = bar.AbsoluteSize.X / math.max(dockScale.Scale, 0.01)
                local s = 1
                if w > 0 and w > vp.X - 24 then s = math.max(0.6, (vp.X - 24) / w) end
                dockScale.Scale = s
            end
            -- janela do dock: a altura que cabe acima dele (300 a 520)
            local H = V8.Shell
            if not H then return end
            local sc = CONFIG.UiScale or 1
            local room = vp.Y - 82 - 12   -- dock + respiro (igual ao HomePos) + margem
            local newH = math.clamp(math.floor(room / sc), 300, 520)
            if newH ~= H.DockH then
                H.DockH = newH
                pcall(H.Layout)
                if SET.WinPos == nil then pcall(function() Window.Position = H.HomePos() end) end
            end
        end

        Conn.MobileFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(function() pcall(M.Fit) end)
        end)

        ----------------------------------------------------------------------------
        -- Ajustes › Celular e toque
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "CELULAR E TOQUE", 12)
        SubLabel(card, "Este aparelho " .. (M.Touch and "tem" or "não tem") .. " tela de toque. "
            .. "No celular, o analógico dirige o voo seguindo a câmera; SUBIR e DESCER "
            .. "aparecem com o Fly ligado. A janela encolhe sozinha em tela pequena.", -1)
        CheckRow(card, "Botões na tela",
            "FLY, SUBIR, DESCER e 2x no lado direito da tela",
            function() return SET.TouchHud == true end,
            function(v)
                SET.TouchHud = v and true or false
                M.Render()
            end, 1)

        M.Render()
    end
    Build()
end
end)
V8.Mod("src/50_v8/08_quests.lua", 13622, 13886, function() --------------------------------------------------------------------------------
-- v8.2 — MISSÕES E BÔNUS DIÁRIO (Playtime Shop › Missões de hoje)
-- Mais um jeito de ganhar pontos além do 1/minuto:
--   * bônus diário: na primeira vez que o painel abre no dia. Dias seguidos
--     aumentam o bônus (10, 15, 20... até 40 no 7º dia); pulou um dia, a
--     sequência volta para 1
--   * missões do dia: zeram à meia-noite (hora do seu computador). Completa,
--     aparece RESGATAR; os pontos entram no saldo na hora
-- O progresso mora em V8.Play.Quests e vai no HYGE/playtime.json junto com os
-- pontos (salvo a cada minuto e no unload).
-- Contadores: tempo e voo pelo scheduler (1/s); emotes embrulhando Emote.Play;
-- waypoints pelo tamanho da lista; pacote pelo SET.PackOn.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local P = V8.Play
        if not P then return end
        V8.Quest = {}
        local Q = V8.Quest

        Q.Defs = {
            { id = "online", name = "Fique 30 min com o HYGE aberto", goal = 1800, min = true, reward = 20 },
            { id = "fly",    name = "Voe por 10 minutos",             goal = 600,  min = true, reward = 30 },
            { id = "emotes", name = "Toque 5 emotes",                 goal = 5,    reward = 15 },
            { id = "wp",     name = "Salve 1 waypoint",               goal = 1,    reward = 10 },
            { id = "pack",   name = "Use um pacote de animação",      goal = 1,    reward = 10 },
        }

        local function Today() return os.date("%Y-%m-%d") end
        local function Yesterday() return os.date("%Y-%m-%d", os.time() - 86400) end

        Q.Bonus = function(streak)
            return 10 + 5 * (math.clamp(streak or 1, 1, 7) - 1)
        end

        -- dados validados (o que veio do arquivo pode estar faltando campo)
        Q.Data = function()
            local d = P.Quests
            if type(d) ~= "table" then
                d = {}
                P.Quests = d
            end
            if type(d.prog) ~= "table" then d.prog = {} end
            if type(d.claimed) ~= "table" then d.claimed = {} end
            d.streak = math.max(0, math.floor(tonumber(d.streak) or 0))
            if d.day ~= Today() then
                d.day = Today()
                d.prog, d.claimed = {}, {}
            end
            for _, m in ipairs(Q.Defs) do
                local v = tonumber(d.prog[m.id]) or 0
                d.prog[m.id] = math.clamp(v, 0, m.goal)
                if d.claimed[m.id] ~= true then d.claimed[m.id] = nil end
            end
            return d
        end

        Q.Add = function(id, n)
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                if m.id == id then
                    local before = d.prog[id]
                    d.prog[id] = math.min(m.goal, before + (n or 1))
                    if before < m.goal and d.prog[id] >= m.goal then
                        Log("Missão completa: " .. m.name .. " — resgate +" .. m.reward
                            .. " na Playtime Shop", "ok")
                        Toast("Missão completa: " .. m.name, "ok", 3)
                        if Q.Render then pcall(Q.Render) end
                    end
                    return
                end
            end
        end

        Q.Claim = function(id)
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                if m.id == id then
                    if d.claimed[id] then return false, "já resgatada" end
                    if d.prog[id] < m.goal then return false, "ainda não completou" end
                    d.claimed[id] = true
                    P.Grant(m.reward)   -- salva e avisa a loja
                    Log("Missão resgatada: " .. m.name .. " (+" .. m.reward .. " pontos)", "ok")
                    Toast("+" .. m.reward .. " pontos", "ok", 2)
                    return true, m.reward
                end
            end
            return false, "missão desconhecida"
        end

        -- bônus diário: 1x por dia, na primeira checagem do dia
        Q.Daily = function()
            local d = Q.Data()
            local today = Today()
            if d.last == today then return false end
            d.streak = (d.last == Yesterday()) and (d.streak + 1) or 1
            d.last = today
            local pts = Q.Bonus(d.streak)
            P.Grant(pts)
            Log("Bônus diário: +" .. pts .. " pontos (" .. d.streak .. " dia(s) seguido(s))", "ok")
            Toast("Bônus diário: +" .. pts .. " pontos", "ok", 3)
            return true, pts
        end

        -- contadores (o scheduler roda 1x/s; o dia vira sozinho)
        do
            local lastWp = #State.Waypoints
            local lastDay = Today()
            V8.Job(1, function()
                Q.Add("online", 1)
                if IsOn("fly") then Q.Add("fly", 1) end
                local n = #State.Waypoints
                if n > lastWp then Q.Add("wp", n - lastWp) end
                lastWp = n
                if SET.PackOn then Q.Add("pack", 1) end
                if Today() ~= lastDay then
                    lastDay = Today()
                    Q.Daily()
                    if Q.Render then pcall(Q.Render) end
                end
            end)
            -- a lista de waypoints é trocada inteira ao carregar a config: não conta
            Q.ResyncWp = function() lastWp = #State.Waypoints end
        end

        -- emotes tocados com sucesso (o catálogo, os favoritos e o comando
        -- chamam Emote.Play pela tabela, então o embrulho pega todos)
        if Emote.Play then
            local base = Emote.Play
            Emote.Play = function(...)
                local ok = base(...)
                if ok then Q.Add("emotes", 1) end
                return ok
            end
        end

        ----------------------------------------------------------------------------
        -- UI: Playtime Shop › Missões de hoje
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Shop, "MISSÕES DE HOJE", 2)
        local streakLbl = SubLabel(card, "", 0)

        local rows = {}
        for i, m in ipairs(Q.Defs) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = card
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -130, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 6)
            nm.BackgroundTransparency = 1
            nm.Text = m.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -190, 0, 6)
            bar.Position = UDim2.new(0, 12, 0, 32)
            bar.BackgroundColor3 = THEME.Track
            bar.BorderSizePixel = 0
            bar.Parent = row
            Paint(bar, "BackgroundColor3", "Track")
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar
            Paint(fill, "BackgroundColor3", "Accent")
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local prog = Instance.new("TextLabel")
            prog.AnchorPoint = Vector2.new(1, 0)
            prog.Size = UDim2.new(0, 64, 0, 14)
            prog.Position = UDim2.new(1, -112, 0, 28)
            prog.BackgroundTransparency = 1
            prog.Text = ""
            prog.TextColor3 = THEME.Dim
            prog.Font = Enum.Font.GothamMedium
            prog.TextSize = 10
            prog.TextXAlignment = Enum.TextXAlignment.Right
            prog.Parent = row
            Paint(prog, "TextColor3", "Dim")

            local b = CreateButton(row, "", "Success", 30)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -10, 0.5, 0)
            b.Size = UDim2.new(0, 92, 0, 30)
            b.TextSize = 11
            b.Font = Enum.Font.GothamBold
            b.MouseButton1Click:Connect(function()
                local ok, why = Q.Claim(m.id)
                if not ok then Toast(tostring(why), nil, 2) end
                pcall(Q.Render)
            end)

            rows[m.id] = { fill = fill, prog = prog, btn = b }
        end

        local function Fmt(m, v)
            if m.min then
                return math.floor(v / 60) .. "/" .. math.floor(m.goal / 60) .. " min"
            end
            return v .. "/" .. m.goal
        end

        Q.Render = function()
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                local r = rows[m.id]
                local v = d.prog[m.id]
                r.fill.Size = UDim2.new(math.clamp(v / m.goal, 0, 1), 0, 1, 0)
                r.prog.Text = Fmt(m, v)
                if d.claimed[m.id] then
                    r.btn.Text = "FEITO"
                    r.btn.TextColor3 = THEME.Dim
                elseif v >= m.goal then
                    r.btn.Text = "RESGATAR +" .. m.reward
                    r.btn.TextColor3 = THEME.Success
                else
                    r.btn.Text = "+" .. m.reward .. " PTS"
                    r.btn.TextColor3 = THEME.Dim
                end
            end
            local s = math.max(d.streak, 1)
            streakLbl.Text = "Bônus diário: " .. d.streak .. " dia(s) seguido(s) — hoje +"
                .. Q.Bonus(s) .. (d.last == Today() and " (recebido)" or "")
                .. ", amanhã +" .. Q.Bonus(s + 1) .. ". As missões zeram à meia-noite."
        end

        -- a loja já tem um TabTick (saldo): roda os dois
        do
            local base = V8.TabTick.Shop
            V8.TabTick.Shop = function()
                if base then base() end
                Q.Render()
            end
        end
        P.OnChange(function() pcall(Q.Render) end)
        OnTabOpen("Shop", function() pcall(Q.Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(Q.Render) end)

        Q.Boot = function()
            Q.ResyncWp()
            Q.Daily()
            Q.Render()
        end
        Q.Render()
    end
    Build()
end
end)
V8.Mod("src/50_v8/09_update.lua", 13888, 14147, function() --------------------------------------------------------------------------------
-- v8.2 — ATUALIZAÇÃO (Configurações › Ajustes › Atualização)
-- Confere se existe um main.lua mais novo no endereço de atualização:
--   * aberto pelo loader.lua: o loader conta qual build ele rodou
--     (getgenv().HYGE_LOADER = { url, build }) e a comparação é pelo build
--     exato — qualquer mudança publicada conta
--   * colado direto: compara CONFIG.Version com o Version do arquivo novo
--     (só avisa se o de lá for MAIOR)
-- Achou: avisa (toast + log + este cartão). ATUALIZAR AGORA baixa, confere se
-- compila, descarrega este painel e roda o novo — sem sair do jogo.
-- v9.1: quem diz se há versão nova é o manifest.json (versão, build, tamanho
-- e SHA-256). O arquivo baixado só é usado se bater com ele (V8.VerifyBuild,
-- 30_kit/07_sha256.lua) — download cortado ou adulterado é recusado e nada
-- é trocado.
-- Precisa de HTTP no executor (request ou game:HttpGet) e, para atualizar sem
-- sair, de loadstring. Nada é baixado sem a opção ligada ou o botão.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Update = { state = "idle", msg = "", notified = {} }
        local U = V8.Update
        if SET.UpdateCheck == nil then SET.UpdateCheck = true end

        -- tabela global do executor (compartilhada entre scripts)
        local function Env()
            if typeof(getgenv) == "function" then
                local ok, g = pcall(getgenv)
                if ok and type(g) == "table" then return g end
            end
            return _G
        end
        -- lido e apagado: se depois alguém colar o main.lua direto no mesmo
        -- jogo, essa instância não herda o build de um loader antigo
        pcall(function()
            local env = Env()
            local L = env.HYGE_LOADER
            U.Loader = (type(L) == "table") and L or nil
            env.HYGE_LOADER = nil
        end)
        U.MyBuild = U.Loader and tostring(U.Loader.build or "") or ""

        U.Url = function()
            local L = U.Loader
            if L and type(L.url) == "string" and L.url ~= "" then return L.url end
            return tostring(CONFIG.UpdateUrl or "")
        end

        -- "v8.1.2" -> { 8, 1, 2 }
        local function Ver(s)
            local t = {}
            for n in tostring(s or ""):gmatch("%d+") do table.insert(t, tonumber(n)) end
            return t
        end
        local function Greater(a, b)
            local x, y = Ver(a), Ver(b)
            for i = 1, math.max(#x, #y) do
                local p, q = x[i] or 0, y[i] or 0
                if p ~= q then return p > q end
            end
            return false
        end

        -- v9.1: o manifest.json fica ao lado do main.lua no repositório
        U.ManUrl = function()
            local L = U.Loader
            if L and type(L.manifest) == "string" and L.manifest ~= "" then return L.manifest end
            local url = U.Url()
            if url == "" then return "" end
            return (url:gsub("[?#].*$", ""):gsub("[^/]+$", "manifest.json"))
        end

        local function Bust(url)
            return url .. (url:find("?", 1, true) and "&" or "?") .. "t=" .. os.time()
        end

        -- manifesto de lá: { version, build, size, sha256 } ou nil + motivo
        U.Manifest = function()
            local url = U.ManUrl()
            if url == "" then return nil, "sem endereço de atualização (CONFIG.UpdateUrl)" end
            if not (V8.Net and V8.Net.Json) then return nil, "sem HTTP" end
            local man, err = V8.Net.Json("GET", Bust(url))
            if not man then return nil, "manifesto: " .. tostring(err) end
            if type(man.sha256) ~= "string" or type(man.size) ~= "number" then
                return nil, "manifesto sem SHA-256/tamanho"
            end
            return man
        end

        -- v9.1: baixa o main.lua e CONFERE com o manifesto (tamanho, SHA-256,
        -- build). { src, version, build, man } ou nil + motivo. Sem manifesto
        -- não há como conferir — e comparar versão não é conferir integridade.
        U.Fetch = function()
            local man, merr = U.Manifest()
            if not man then return nil, merr end
            local ok, body, code = V8.Net.Request("GET", Bust(U.Url()))
            if not ok then
                return nil, (code and code > 0) and ("HTTP " .. code) or tostring(body)
            end
            local good, why = V8.VerifyBuild(body, man)
            if not good then return nil, "download recusado: " .. tostring(why) end
            return {
                src = body, man = man,
                version = body:match('Version%s*=%s*"([^"]+)"'),
                build = body:match("%-%- build: (%x+)"),
            }
        end

        U.IsNewer = function(info)
            if U.MyBuild ~= "" and info.build then return info.build ~= U.MyBuild end
            return info.version ~= nil and Greater(info.version, CONFIG.Version)
        end

        U.Check = function(manual)
            if U.state == "checking" then return end
            U.state, U.msg = "checking", "Conferindo..."
            if U.Render then pcall(U.Render) end
            task.spawn(function()
                -- v9.1: para saber se há versão nova basta o manifesto (pequeno)
                local info, why
                local man, merr = U.Manifest()
                if man then
                    info = { version = man.version, build = man.build, man = man }
                else
                    why = merr
                end
                if not info then
                    U.state, U.msg = "error", "Não deu para conferir: " .. tostring(why)
                    if manual then
                        Log("Atualização: " .. tostring(why), "error")
                        Toast("Não deu para conferir a atualização", "error", 3)
                    end
                elseif U.IsNewer(info) then
                    U.state, U.info = "new", info
                    U.msg = "Versão nova disponível: " .. tostring(info.version or "?")
                        .. (info.build and ("  (build " .. info.build .. ")") or "")
                    local key = tostring(info.build or info.version)
                    if manual or not U.notified[key] then
                        U.notified[key] = true
                        Log("Atualização disponível: HYGE " .. tostring(info.version or "?")
                            .. " — Configurações › Ajustes › Atualização", "ok")
                        Toast("HYGE " .. tostring(info.version or "novo")
                            .. " disponível (Ajustes › Atualização)", "ok", 5)
                    end
                else
                    U.state, U.info = "ok", info
                    U.msg = "Você está na versão mais nova."
                    if manual then
                        Log("Atualização: você já está na versão mais nova", "ok")
                        Toast("Já está na versão mais nova", "ok", 2)
                    end
                end
                U.checked = os.date("%H:%M")
                if U.Render then pcall(U.Render) end
            end)
        end

        U.Apply = function()
            if typeof(loadstring) ~= "function" then
                Log("Este executor não tem loadstring: baixe o main.lua novo e rode no executor "
                    .. "(ou use o loader.lua, que sempre abre a versão nova)", "error")
                Toast("Executor sem loadstring", "error", 3)
                return
            end
            if U.state == "applying" then return end
            U.state, U.msg = "applying", "Baixando a versão nova..."
            if U.Render then pcall(U.Render) end
            task.spawn(function()
                local info, why = U.Fetch()
                if not info then
                    U.state, U.msg = "error", "Não deu para baixar: " .. tostring(why)
                    Log("Atualização: " .. tostring(why), "error")
                    if U.Render then pcall(U.Render) end
                    return
                end
                local fn, err = loadstring(info.src, "=HYGE")
                if not fn then
                    U.state, U.msg = "error", "O arquivo novo não compila"
                    Log("O main.lua baixado não compila (nada foi trocado): " .. tostring(err), "error")
                    if U.Render then pcall(U.Render) end
                    return
                end
                -- o painel novo fica sabendo de onde veio e qual build é
                pcall(function()
                    local env = Env()
                    env.HYGE_LOADER = { url = U.Url(), manifest = U.ManUrl(), build = info.build,
                        from = "atualização", sha256 = info.man and info.man.sha256, verified = true }
                end)
                Log("Atualizando para HYGE " .. tostring(info.version or "?") .. "...", "action")
                Toast("Atualizando o HYGE...", "ok", 2)
                task.wait(0.4)
                pcall(Unload)
                -- task do Roblox direto: esta é a ÚNICA tarefa que deve rodar
                -- depois do unload (o task do painel anotaria como "ficou vivo")
                V8.RawTask.defer(function()
                    local ok, e = pcall(fn)
                    if not ok then warn("[HYGE] a versão nova falhou ao iniciar: " .. tostring(e)) end
                end)
            end)
        end

        -- a cada 15 min (o primeiro disparo do scheduler é ignorado: quem
        -- confere ao abrir é o U.Boot, depois da config carregada)
        V8.Job(900, function()
            if U.booted and SET.UpdateCheck then U.Check(false) end
        end)

        U.Boot = function()
            U.booted = true
            if SET.UpdateCheck and U.Url() ~= "" then
                task.delay(6, function() U.Check(false) end)
            end
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Atualização
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "ATUALIZAÇÃO", 13)
        local infoLbl = SubLabel(card, "", 0)
        local status = SubLabel(card, "", 1)

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 2
        local bCheck = CreateButton(g, "VERIFICAR AGORA", "Accent", 32)
        bCheck.LayoutOrder = 1
        bCheck.MouseButton1Click:Connect(function() U.Check(true) end)
        local bApply = CreateButton(g, "ATUALIZAR AGORA", "Success", 32)
        bApply.LayoutOrder = 2
        bApply.MouseButton1Click:Connect(function()
            Confirm("Baixar a versão nova e reabrir o painel agora? (o que estiver "
                .. "ligado é desligado; a config é salva antes)", U.Apply)
        end)

        CheckRow(card, "Conferir sozinho",
            "Ao abrir o painel e a cada 15 minutos (só avisa, não troca nada)",
            function() return SET.UpdateCheck == true end,
            function(v) SET.UpdateCheck = v and true or false end, 3)

        SubLabel(card, "Para abrir sempre a versão mais nova: rode o loader.lua do "
            .. "repositório no executor em vez do main.lua. Ele baixa do GitHub, guarda uma "
            .. "cópia em HYGE/main.lua e usa a cópia se estiver sem internet.", 4)

        U.Render = function()
            local how = U.Loader and ("aberto pelo loader" .. (U.MyBuild ~= ""
                and (", build " .. U.MyBuild) or "")) or "colado direto (sem loader)"
            infoLbl.Text = "Versão atual: " .. CONFIG.Version .. "  ·  " .. how
                .. "\nEndereço: " .. (U.Url() ~= "" and U.Url() or "nenhum")
            status.Text = (U.msg ~= "" and U.msg or "Ainda não conferido.")
                .. (U.checked and ("  (às " .. U.checked .. ")") or "")
            local key = (U.state == "new") and "Success"
                or (U.state == "error") and "Danger" or "Dim"
            status.TextColor3 = THEME[key]
            bApply.Text = (U.state == "new") and "ATUALIZAR AGORA" or "REINSTALAR AGORA"
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(U.Render) end)
        U.Render()
    end
    Build()
end
end)
V8.Mod("src/50_v8/10_profiles.lua", 14149, 14587, function() --------------------------------------------------------------------------------
-- v9.0 — PERFIS (Configurações › Dados › Perfis)
-- Um perfil é o painel inteiro guardado com um nome: tema, tamanho, teclas,
-- macros, velocidades, opções de ESP, favoritos, ajustes e as funções que
-- estavam ligadas. USAR troca tudo de uma vez.
-- JOGO marca o perfil para abrir sozinho neste jogo (PlaceId): o BootStep
-- "Perfil do jogo" aplica depois da config e das funções automáticas.
-- Ficam FORA do perfil: waypoints (são por jogo), emotes favoritos, notas, os
-- pacotes de animação (biblioteca e o que está em uso) e a posição da janela.
-- Freecam e Drone nunca ligam sozinhos (tomam a câmera).
-- Arquivo próprio: HYGE/profiles.json. Sem writefile, valem só nesta sessão.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local C = V8.Cfg
        if not C then return end
        V8.Prof = { Path = "HYGE/profiles.json", Max = 10,
                    Data = { list = {}, places = {} }, Current = nil }
        local P = V8.Prof
        local Http = V8.Net and V8.Net.Http
        local PLACE = tostring(game.PlaceId)
        local NOAUTO = { freecam = true, drone = true }
        -- pacote de animação fica fora: a biblioteca (Packs) não vai no perfil e
        -- trocar PackOn sem reaplicar o Animate deixaria o personagem no meio
        local SKIP = { Packs = true, PackOn = true, FlyPack = true, WinPos = true, SeenVersion = true }

        ----------------------------------------------------------------------------
        -- disco
        ----------------------------------------------------------------------------
        local function CanDisk() return V8.Disk and V8.Disk.Ok() and Http ~= nil end
        local function JsonOk(s)
            local ok, d = pcall(function() return Http:JSONDecode(s) end)
            return ok and type(d) == "table"
        end

        local function Parse(text)
            local d = Http:JSONDecode(text)
            local list = {}
            if type(d.list) == "table" then
                for _, r in ipairs(d.list) do
                    if type(r) == "table" and type(r.name) == "string" and type(r.data) == "table" then
                        table.insert(list, r)
                    end
                end
            end
            P.Data.list = list
            P.Data.places = type(d.places) == "table" and d.places or {}
        end

        -- v9.1: leitura segura. Arquivo estragado: os perfis voltam sozinhos do
        -- .tmp/backup (lista vazia + o próximo salvamento apagaria tudo); o
        -- estragado fica em profiles.corrupt.json
        local function Load()
            if not CanDisk() then return end
            local r = V8.Disk.SafeRead(P.Path, JsonOk)
            if r.state == "missing" then return end
            local text = r.text
            if r.state == "corrupt" then
                local c = r.recover[1]
                if not c then
                    Log("Perfis: " .. P.Path .. " estragado e sem backup — a lista começa "
                        .. "vazia (o arquivo estragado é guardado em profiles.corrupt.json)", "error")
                    return
                end
                text = c.text
                local ok, err = V8.Disk.Recover(P.Path, c.text, JsonOk)
                Log("Perfis: " .. P.Path .. " estragado — recuperados do " .. c.label
                    .. (ok and "" or ("  (não deu para regravar: " .. tostring(err) .. ")")), "warn")
            end
            local ok, err = pcall(Parse, text)
            if not ok then Log("Perfis: " .. tostring(err), "error") end
        end

        local function Save()
            if not CanDisk() then return false, "executor sem writefile (perfis só nesta sessão)" end
            local ok, json = pcall(function() return Http:JSONEncode(P.Data) end)
            if not ok then return false, "JSON: " .. tostring(json) end
            return V8.Disk.SafeWrite(P.Path, json, JsonOk)
        end

        -- comando "recover perfis": volta a lista para o backup (desfaz o
        -- último salvar/apagar perfil)
        P.Recover = function()
            if not CanDisk() then
                Log("Perfis: executor sem API de arquivos", "error")
                return false
            end
            local r = V8.Disk.SafeRead(P.Path, JsonOk)
            local c = r.recover[1]
            if r.state == "ok" then
                local bak = V8.Disk.Paths(P.Path)
                local s = V8.Disk.Read(bak)
                c = (s and s ~= r.text and JsonOk(s)) and { text = s, label = "backup (anterior)" } or nil
            end
            if not c then
                Log("Perfis: não há backup válido para recuperar", "warn")
                return false
            end
            local ok, err = V8.Disk.Recover(P.Path, c.text, JsonOk)
            if not ok then
                Log("Perfis: não deu para recuperar — " .. tostring(err), "error")
                return false
            end
            pcall(Parse, c.text)
            if P.Render then pcall(P.Render) end
            Log("Perfis recuperados do " .. c.label .. " (" .. #P.Data.list .. " perfis)", "ok")
            return true
        end

        Load()

        ----------------------------------------------------------------------------
        -- lógica
        ----------------------------------------------------------------------------
        local function Clean(name)
            name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if #name > 24 then name = name:sub(1, 24) end
            return name
        end

        -- exato primeiro (sem acento/caixa), depois começo do nome
        P.Find = function(name, exact)
            local q = V8.Fold(Clean(name))
            if q == "" then return nil end
            for _, r in ipairs(P.Data.list) do
                if V8.Fold(r.name) == q then return r end
            end
            if exact then return nil end
            for _, r in ipairs(P.Data.list) do
                if V8.Fold(r.name):sub(1, #q) == q then return r end
            end
            return nil
        end

        P.Capture = function()
            local d = C.Snapshot()
            d.waypoints, d.wpplaces, d.emotes, d.notes, d.situation = nil, nil, nil, nil, nil
            if type(d.set) == "table" then
                for k in pairs(SKIP) do d.set[k] = nil end
            end
            d.on = {}
            for _, id in ipairs(ToggleOrder) do
                if IsOn(id) and not NOAUTO[id] then table.insert(d.on, id) end
            end
            return d
        end

        P.SaveAs = function(name)
            name = Clean(name)
            if name == "" then return false, "dê um nome ao perfil" end
            local rec = P.Find(name, true)
            if not rec then
                if #P.Data.list >= P.Max then return false, "limite de " .. P.Max .. " perfis" end
                rec = { name = name }
                table.insert(P.Data.list, rec)
            end
            rec.data = P.Capture()
            rec.saved = os.time()
            P.Current = rec.name
            local ok, err = Save()
            if P.Render then pcall(P.Render) end
            Log("Perfil '" .. rec.name .. "' salvo (" .. #rec.data.on .. " função(ões) ligada(s))"
                .. (ok and "" or ("  — " .. tostring(err))), ok and "ok" or "warn")
            return true
        end

        -- v9.1: troca segura (V8.ProfTx, 30_kit/08_profile_tx.lua): valida
        -- antes, aplica as preferências tudo-ou-nada (com volta ao estado
        -- anterior) e só depois liga as funções
        local function KeyOk(n)
            if type(n) ~= "string" then return false end
            local ok, kc = pcall(function() return Enum.KeyCode[n] end)
            return ok and kc ~= nil
        end
        local function Ctx()
            local setKeys, toggles, themes = {}, {}, {}
            for _, k in ipairs(C.SetKeys) do setKeys[k] = true end
            for k in pairs(SKIP) do setKeys[k] = nil end
            for id in pairs(Toggles) do toggles[id] = true end
            for n in pairs(PALETTES) do themes[n] = true end
            return { setKeys = setKeys, toggles = toggles, noauto = NOAUTO, themes = themes, keyOk = KeyOk }
        end
        -- terminou certo? (passos do Restore + tema + teclas)
        local function Verify(d)
            local errs = C.LastRestoreErrors or {}
            if #errs > 0 then return false, table.concat(errs, "; ") end
            if type(d.theme) == "string" and PALETTES[d.theme] and SET.Theme ~= d.theme then
                return false, "o tema não ficou"
            end
            if type(d.keys) == "table" then
                for id, n in pairs(d.keys) do
                    if Toggles[id] and KeyOk(n) and not (Keybinds[id] and Keybinds[id].Name == n) then
                        return false, "a tecla de " .. id .. " não ficou"
                    end
                end
            end
            return true
        end

        P.Use = function(name, silent)
            local rec = P.Find(name)
            if not rec then return false, "perfil não encontrado: " .. tostring(name) end
            -- o que o perfil não pode mexer sai antes (mesmo editado à mão)
            local data = rec.data
            if type(data) == "table" and type(data.set) == "table" then
                local clean = {}
                for k, v in pairs(data) do clean[k] = v end
                clean.set = {}
                for k, v in pairs(data.set) do if not SKIP[k] then clean.set[k] = v end end
                clean.waypoints, clean.wpplaces, clean.emotes, clean.notes = nil, nil, nil, nil
                data = clean
            end
            local ok, rep = V8.ProfTx.Apply(data, {
                ctx = Ctx(),
                snapshot = P.Capture,
                restore = C.Restore,
                clear = function(k) SET[k] = nil end,
                verify = Verify,
                order = ToggleOrder,
                isOn = IsOn,
                setToggle = function(id, on) SetToggle(id, on, true) end,
            })
            P.LastResult = { name = rec.name, ok = ok, rep = rep, time = os.date("%H:%M:%S") }
            for _, w in ipairs(rep.warnings) do Log("Perfil '" .. rec.name .. "': " .. w, "warn") end
            if not ok then
                local why = table.concat(rep.errors, "; ")
                Log("Perfil '" .. rec.name .. "' NÃO aplicado: " .. why
                    .. (rep.rolledBack and " — o painel voltou ao que estava" or ""), "error")
                if not silent then Toast("Perfil inválido — nada mudou", "error", 3) end
                if P.Render then pcall(P.Render) end
                return false, why
            end
            P.Current = rec.name
            if RefreshStatus then pcall(RefreshStatus) end
            if P.Render then pcall(P.Render) end
            if #rep.failed > 0 then
                Log("Perfil '" .. rec.name .. "' aplicado, mas não ligou: " .. table.concat(rep.failed, ", ")
                    .. " (personagem/jogo não deixou agora)", "warn")
            end
            if not silent then
                Log("Perfil '" .. rec.name .. "' aplicado", "ok")
                Toast("Perfil: " .. rec.name .. (#rep.failed > 0 and ("  (" .. #rep.failed .. " função(ões) não ligaram)") or ""),
                    #rep.failed > 0 and "warn" or "ok", 2)
            end
            return true
        end

        P.Delete = function(name)
            local rec = P.Find(name, true)
            if not rec then return false, "perfil não encontrado" end
            for i, r in ipairs(P.Data.list) do
                if r == rec then table.remove(P.Data.list, i) break end
            end
            for place, n in pairs(P.Data.places) do
                if n == rec.name then P.Data.places[place] = nil end
            end
            if P.Current == rec.name then P.Current = nil end
            Save()
            if P.Render then pcall(P.Render) end
            Log("Perfil '" .. rec.name .. "' apagado", "action")
            return true
        end

        P.HereName = function() return P.Data.places[PLACE] end

        -- marca (ou desmarca, com name = nil) o perfil que abre sozinho neste jogo
        P.BindHere = function(name)
            if name then
                local rec = P.Find(name, true)
                if not rec then return false, "perfil não encontrado" end
                P.Data.places[PLACE] = rec.name
                Log("Perfil '" .. rec.name .. "' vai abrir sozinho neste jogo (PlaceId "
                    .. PLACE .. ")", "ok")
            else
                P.Data.places[PLACE] = nil
                Log("Este jogo não tem mais perfil automático", "action")
            end
            Save()
            if P.Render then pcall(P.Render) end
            return true
        end

        P.Boot = function()
            local n = P.HereName()
            if not n then return end
            if not P.Find(n, true) then
                P.Data.places[PLACE] = nil
                return
            end
            local ok, err = P.Use(n, true)
            if ok then
                Log("Perfil deste jogo aplicado: " .. n, "ok")
            else
                Log("Perfil deste jogo (" .. n .. "): " .. tostring(err), "error")
            end
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Perfis
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "PERFIS", 6)
        SubLabel(card, "Um perfil guarda o painel do jeito que está agora: tema, teclas, "
            .. "macros, velocidades, ESP, favoritos e as funções ligadas (menos Freecam e "
            .. "Drone). JOGO faz o perfil abrir sozinho neste jogo.", -1)
        local status = SubLabel(card, "", 0)

        local addRow = Instance.new("Frame")
        addRow.Size = UDim2.new(1, 0, 0, 32)
        addRow.BackgroundTransparency = 1
        addRow.LayoutOrder = 1
        addRow.Parent = card
        local nameBox = CreateInput(addRow, "nome do perfil (ex.: Explorar, PvP)", 32)
        nameBox.Size = UDim2.new(1, -150, 1, 0)
        local bSave = CreateButton(addRow, "SALVAR PERFIL", "Success", 32)
        bSave.AnchorPoint = Vector2.new(1, 0)
        bSave.Position = UDim2.new(1, 0, 0, 0)
        bSave.Size = UDim2.new(0, 142, 1, 0)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 2
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        local empty = SubLabel(card, "Nenhum perfil ainda. Deixe o painel do seu jeito, "
            .. "dê um nome e toque em SALVAR PERFIL.", 3)

        local function SmallBtn(parent, text, colorKey, w, x)
            local b = CreateButton(parent, text, colorKey, 26)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, x, 0.5, 0)
            b.Size = UDim2.new(0, w, 0, 26)
            b.TextSize = 10
            return b
        end

        P.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            empty.Visible = (#P.Data.list == 0)
            local here = P.HereName()
            for i, r in ipairs(P.Data.list) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 46)
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = list
                V8.Cell(row, 0)

                local active = (P.Current == r.name)
                local nm = Instance.new("TextLabel")
                nm.Size = UDim2.new(1, -176, 0, 18)
                nm.Position = UDim2.new(0, 0, 0, 6)
                nm.BackgroundTransparency = 1
                nm.Text = r.name .. (active and "  ·  ativo" or "")
                nm.TextColor3 = active and THEME.Accent or THEME.Text
                nm.Font = Enum.Font.GothamBold
                nm.TextSize = 13
                nm.TextXAlignment = Enum.TextXAlignment.Left
                nm.TextTruncate = Enum.TextTruncate.AtEnd
                nm.Parent = row

                local on = (type(r.data) == "table" and type(r.data.on) == "table") and #r.data.on or 0
                local sub = Instance.new("TextLabel")
                sub.Size = UDim2.new(1, -176, 0, 14)
                sub.Position = UDim2.new(0, 0, 0, 25)
                sub.BackgroundTransparency = 1
                sub.Text = (r.saved and os.date("salvo %d/%m %H:%M", r.saved) or "salvo")
                    .. "  ·  " .. on .. " função(ões)"
                    .. ((here == r.name) and "  ·  abre neste jogo" or "")
                sub.TextColor3 = (here == r.name) and THEME.Success or THEME.Dim
                sub.Font = Enum.Font.GothamMedium
                sub.TextSize = 10
                sub.TextXAlignment = Enum.TextXAlignment.Left
                sub.TextTruncate = Enum.TextTruncate.AtEnd
                sub.Parent = row

                local bUse = SmallBtn(row, "USAR", "Accent", 52, -96)
                bUse.MouseButton1Click:Connect(function()
                    local ok, err = P.Use(r.name)
                    if not ok then Log(tostring(err), "error") end
                end)
                -- marcado: borda verde e o texto "abre neste jogo" na linha de baixo
                local bHere = SmallBtn(row, "JOGO", (here == r.name) and "Success" or "Accent", 52, -38)
                if here == r.name then bHere.TextColor3 = THEME.Success end
                bHere.MouseButton1Click:Connect(function()
                    P.BindHere((P.HereName() ~= r.name) and r.name or nil)
                end)
                local bDel = SmallBtn(row, "", "Danger", 30, 0)
                local ic = Icon(bDel, "trash", THEME.Danger, 13)
                ic.AnchorPoint = Vector2.new(0.5, 0.5)
                ic.Position = UDim2.new(0.5, 0, 0.5, 0)
                bDel.MouseButton1Click:Connect(function()
                    Confirm("Apagar o perfil '" .. r.name .. "'?", function() P.Delete(r.name) end)
                end)
            end
            status.Text = (CanDisk() and ("Arquivo: " .. P.Path)
                    or "Este executor não tem writefile: os perfis valem só nesta sessão.")
                .. "  ·  " .. #P.Data.list .. "/" .. P.Max .. " perfis"
                .. (here and ("  ·  este jogo abre com '" .. here .. "'") or "")
        end

        bSave.MouseButton1Click:Connect(function()
            local name = nameBox.Text
            if Clean(name) == "" then name = P.Current or "" end
            if Clean(name) == "" then
                Toast("Dê um nome ao perfil", "warn", 2)
                return
            end
            local exists = P.Find(name, true) ~= nil
            local function go()
                local ok, err = P.SaveAs(name)
                if ok then
                    nameBox.Text = ""
                    Toast("Perfil salvo: " .. Clean(name), "ok", 2)
                else
                    Toast(tostring(err), "warn", 3)
                end
            end
            if exists then
                Confirm("Já existe o perfil '" .. Clean(name) .. "'. Trocar pelo que está agora?", go)
            else
                go()
            end
        end)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(P.Render) end)
        P.Render()
    end
    Build()
end
end)
V8.Mod("src/50_v8/11_notify.lua", 14589, 14909, function() --------------------------------------------------------------------------------
-- v9.0 — CENTRAL DE NOTIFICAÇÕES
-- Todo Toast passa a ficar guardado (os últimos 60). O sino na ilha do topo
-- mostra quantos chegaram desde a última olhada; clicar abre a lista.
-- "Não perturbe": nada pula na tela (menos erro), tudo continua no sino.
-- "Tempo dos avisos": 50% a 200% da duração normal de cada aviso.
-- Sem loop próprio: só embrulha o Toast. Tudo dentro de Build().
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Notif = { List = {}, Unread = 0, Max = 60, Shown = false }
        local N = V8.Notif
        if SET.Dnd == nil then SET.Dnd = false end
        if type(SET.ToastDur) ~= "number" then SET.ToastDur = 100 end

        local KIND = { info = "Accent", ok = "Success", warn = "Warning",
                       error = "Danger", action = "Accent2" }

        ----------------------------------------------------------------------------
        -- sino na ilha (se a ilha existir)
        ----------------------------------------------------------------------------
        local bell, bellIco, badge
        if V8.Island and V8.Island.Pill then
            bell = Instance.new("TextButton")
            bell.Name = "Bell"
            bell.Size = UDim2.new(0, 24, 0, 24)
            bell.BackgroundTransparency = 1
            bell.Text = ""
            bell.AutoButtonColor = false
            bell.LayoutOrder = 9
            bell.ZIndex = 21
            bell.Parent = V8.Island.Pill
            bellIco = Icon(bell, "bell", THEME.Dim, 16)
            bellIco.AnchorPoint = Vector2.new(0.5, 0.5)
            bellIco.Position = UDim2.new(0.5, 0, 0.5, 0)

            badge = Instance.new("TextLabel")
            badge.AnchorPoint = Vector2.new(1, 0)
            badge.Position = UDim2.new(1, 6, 0, -4)
            badge.Size = UDim2.new(0, 16, 0, 14)
            badge.BackgroundColor3 = THEME.Danger
            badge.BorderSizePixel = 0
            badge.Text = ""
            badge.TextColor3 = Color3.new(1, 1, 1)
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 9
            badge.Visible = false
            badge.ZIndex = 23
            badge.Parent = bell
            Paint(badge, "BackgroundColor3", "Danger")
            Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
        end

        N.Badge = function()
            if not badge then return end
            badge.Visible = N.Unread > 0
            badge.Text = (N.Unread > 9) and "9+" or tostring(N.Unread)
            badge.Size = UDim2.new(0, (N.Unread > 9) and 20 or 15, 0, 14)
            IconTint(bellIco, SET.Dnd and THEME.Warning or (N.Unread > 0 and THEME.Text or THEME.Dim))
        end

        ----------------------------------------------------------------------------
        -- painel da lista (abaixo da ilha)
        ----------------------------------------------------------------------------
        local catcher = Instance.new("TextButton")   -- clique fora fecha
        catcher.Name = "NotifCatcher"
        catcher.Size = UDim2.new(1, 0, 1, 0)
        catcher.BackgroundTransparency = 1
        catcher.Text = ""
        catcher.AutoButtonColor = false
        catcher.Visible = false
        catcher.ZIndex = 44
        catcher.Parent = Gui

        local panel = Instance.new("Frame")
        panel.Name = "Notifications"
        panel.AnchorPoint = Vector2.new(0.5, 0)
        panel.Position = UDim2.new(0.5, 0, 0, 50)
        panel.Size = UDim2.new(0, 340, 0, 340)
        panel.BackgroundColor3 = THEME.Card
        panel.BorderSizePixel = 0
        panel.Visible = false
        panel.ZIndex = 45
        panel.Parent = Gui
        Paint(panel, "BackgroundColor3", "Card")
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
        do
            local st = Instance.new("UIStroke", panel)
            st.Transparency = 0.2
            Paint(st, "Color", "Line")
        end

        local title = Instance.new("TextLabel")
        title.Position = UDim2.new(0, 14, 0, 10)
        title.Size = UDim2.new(0, 140, 0, 24)
        title.BackgroundTransparency = 1
        title.Text = "Notificações"
        title.TextColor3 = THEME.Text
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = panel
        Paint(title, "TextColor3", "Text")

        local bDnd = CreateButton(panel, "NÃO PERTURBE", "Warning", 24)
        bDnd.AnchorPoint = Vector2.new(1, 0)
        bDnd.Position = UDim2.new(1, -82, 0, 10)
        bDnd.Size = UDim2.new(0, 104, 0, 24)
        bDnd.TextSize = 10

        local bClear = CreateButton(panel, "LIMPAR", "Danger", 24)
        bClear.AnchorPoint = Vector2.new(1, 0)
        bClear.Position = UDim2.new(1, -12, 0, 10)
        bClear.Size = UDim2.new(0, 64, 0, 24)
        bClear.TextSize = 10

        local scroll = Instance.new("ScrollingFrame")
        scroll.Position = UDim2.new(0, 10, 0, 44)
        scroll.Size = UDim2.new(1, -20, 1, -54)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = panel
        Paint(scroll, "ScrollBarImageColor3", "Accent")
        do
            local l = Instance.new("UIListLayout", scroll)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -6, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "Nenhum aviso por enquanto."
        empty.TextColor3 = THEME.Dim
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 12
        empty.LayoutOrder = 9999
        empty.Parent = scroll
        Paint(empty, "TextColor3", "Dim")

        local function PaintDnd()
            bDnd.Text = SET.Dnd and "NÃO PERTURBE: ON" or "NÃO PERTURBE"
            bDnd.Size = UDim2.new(0, SET.Dnd and 128 or 104, 0, 24)
        end

        -- linhas desenhadas na hora de abrir (não entram no registry de tema)
        N.Render = function()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            empty.Visible = (#N.List == 0)
            for i, e in ipairs(N.List) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -6, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = THEME.Btn
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                row.Parent = scroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)
                local pad = Instance.new("UIPadding", row)
                pad.PaddingTop = UDim.new(0, 7)
                pad.PaddingBottom = UDim.new(0, 7)
                pad.PaddingLeft = UDim.new(0, 10)
                pad.PaddingRight = UDim.new(0, 10)

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 7, 0, 7)
                dot.Position = UDim2.new(0, 0, 0, 5)
                dot.BackgroundColor3 = THEME[KIND[e.kind] or "Accent"]
                dot.BorderSizePixel = 0
                dot.Parent = row
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                local txt = Instance.new("TextLabel")
                txt.Position = UDim2.new(0, 15, 0, 0)
                txt.Size = UDim2.new(1, -58, 0, 0)
                txt.AutomaticSize = Enum.AutomaticSize.Y
                txt.BackgroundTransparency = 1
                txt.Text = e.text
                txt.TextColor3 = THEME.Text
                txt.Font = Enum.Font.GothamMedium
                txt.TextSize = 12
                txt.TextWrapped = true
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.Parent = row

                local tm = Instance.new("TextLabel")
                tm.AnchorPoint = Vector2.new(1, 0)
                tm.Position = UDim2.new(1, 0, 0, 0)
                tm.Size = UDim2.new(0, 40, 0, 16)
                tm.BackgroundTransparency = 1
                tm.Text = e.t .. ((e.n or 1) > 1 and (" x" .. e.n) or "")
                tm.TextColor3 = THEME.Dim
                tm.Font = Enum.Font.Code
                tm.TextSize = 10
                tm.TextXAlignment = Enum.TextXAlignment.Right
                tm.Parent = row
            end
            PaintDnd()
            scroll.CanvasPosition = Vector2.new(0, 0)
        end

        N.Open = function()
            N.Shown = true
            N.Unread = 0
            N.Badge()
            N.Render()
            -- logo abaixo da ilha quando ela está na tela; senão no topo
            local island = V8.Island and V8.Island.Pill
            local y = (island and island.Visible) and 50 or 14
            panel.Position = UDim2.new(0.5, 0, 0, y)
            catcher.Visible = true
            panel.Visible = true
        end
        N.Close = function()
            N.Shown = false
            catcher.Visible = false
            panel.Visible = false
        end
        N.IsOpen = function() return N.Shown end
        N.Clear = function()
            for i = #N.List, 1, -1 do N.List[i] = nil end
            N.Unread = 0
            N.Badge()
            if N.Shown then N.Render() end
        end
        N.SetDnd = function(on)
            SET.Dnd = on and true or false
            N.Badge()
            PaintDnd()
            if N.Render2 then pcall(N.Render2) end
        end

        if bell then
            bell.MouseButton1Click:Connect(function()
                if N.Shown then N.Close() else N.Open() end
            end)
        end
        catcher.MouseButton1Click:Connect(N.Close)
        bClear.MouseButton1Click:Connect(N.Clear)
        bDnd.MouseButton1Click:Connect(function()
            N.SetDnd(not SET.Dnd)
            Log("Não perturbe: " .. (SET.Dnd and "ligado" or "desligado"), "action")
        end)
        Conn.NotifKeys = UserInputService.InputBegan:Connect(function(input)
            if N.Shown and input.KeyCode == Enum.KeyCode.Escape then N.Close() end
        end)

        ----------------------------------------------------------------------------
        -- guarda TODO aviso (repetido seguido vira "x2", "x3"...)
        ----------------------------------------------------------------------------
        -- o número do sino conta só o que pede atenção: aviso, erro e mensagens
        -- longas (atualização, mensagem de admin...). "Fly ativado" fica na
        -- lista mas não acende o sino.
        N.Push = function(text, kind, duration)
            text = tostring(text)
            local top = N.List[1]
            if top and top.text == text and top.kind == kind then
                top.n = (top.n or 1) + 1
                top.t = os.date("%H:%M")
            else
                table.insert(N.List, 1, { t = os.date("%H:%M"), text = text, kind = kind, n = 1 })
                while #N.List > N.Max do table.remove(N.List) end
            end
            -- ("desativado" é um aviso curto, 1.6 s: não conta)
            local dur = tonumber(duration) or 2.6
            local important = kind == "error" or dur >= 4 or (kind == "warn" and dur >= 2.6)
            if important and not N.Shown then N.Unread = N.Unread + 1 end
            N.Badge()
            if N.Shown then N.Render() end
        end

        local base = Toast
        Toast = function(text, kind, duration)
            kind = (kind and KIND[kind]) and kind or "info"
            pcall(N.Push, text, kind, duration)
            if SET.Dnd and kind ~= "error" then return end
            local mult = math.clamp((tonumber(SET.ToastDur) or 100) / 100, 0.5, 2)
            return base(text, kind, (duration or 2.6) * mult)
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Notificações
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "NOTIFICAÇÕES", 10)
        SubLabel(card, "Todo aviso fica guardado no sino da ilha do topo (os últimos "
            .. N.Max .. "). Clique no sino para ver; o número mostra os que você não viu.", -1)
        local dndRender = CheckRow(card, "Não perturbe",
            "Nenhum aviso pula na tela (erros continuam); tudo fica no sino",
            function() return SET.Dnd == true end,
            function(v) N.SetDnd(v) end, 1)
        N.Render2 = dndRender
        local durSet = SliderRow(card, {
            label = "Tempo dos avisos na tela", min = 50, max = 200, def = SET.ToastDur,
            suffix = "%", order = 2,
            apply = function(v) SET.ToastDur = v end,
        })
        local g = Grid(card, 2, 32)
        g.LayoutOrder = 3
        local bOpen = CreateButton(g, "VER HISTÓRICO", "Accent", 32)
        bOpen.LayoutOrder = 1
        bOpen.MouseButton1Click:Connect(function() N.Open() end)
        local bWipe = CreateButton(g, "LIMPAR HISTÓRICO", "Danger", 32)
        bWipe.LayoutOrder = 2
        bWipe.MouseButton1Click:Connect(N.Clear)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function()
            pcall(durSet, tonumber(SET.ToastDur) or 100, true)
            pcall(N.Badge)
            pcall(PaintDnd)
        end)
        N.Badge()
        PaintDnd()
    end
    Build()
end
end)
V8.Mod("src/50_v8/12_colors.lua", 14911, 15073, function() --------------------------------------------------------------------------------
-- v9.0 — COR PERSONALIZADA (Configurações › Visual)
-- Tema "Personalizado": a base escura do Grafite levemente tingida + a cor de
-- destaque que você escolher (matiz 0–360° e intensidade). USAR ESTA COR
-- aplica; com o tema já ativo, mexer nos sliders troca ao vivo.
-- SET.CustomHue / SET.CustomSat vão na config (e nos perfis).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Colors = { Name = "Personalizado" }
        local K = V8.Colors
        if type(SET.CustomHue) ~= "number" then SET.CustomHue = 275 end
        if type(SET.CustomSat) ~= "number" then SET.CustomSat = 60 end

        -- monta a paleta a partir de matiz (0-360) e intensidade (15-100)
        K.Make = function(hue, sat)
            local h = (math.clamp(tonumber(hue) or 275, 0, 360) % 360) / 360
            local s = math.clamp(tonumber(sat) or 60, 15, 100) / 100
            local p = {}
            for k, v in pairs(PALETTES.Grafite) do p[k] = v end
            local tint = 0.18 * s
            p.Accent   = Color3.fromHSV(h, s, 1)
            p.Accent2  = Color3.fromHSV(h, s * 0.55, 1)
            p.Main     = Color3.fromHSV(h, tint, 0.075)
            p.Sidebar  = Color3.fromHSV(h, tint, 0.10)
            p.Card     = Color3.fromHSV(h, tint, 0.135)
            p.Console  = Color3.fromHSV(h, tint, 0.055)
            p.Btn      = Color3.fromHSV(h, tint, 0.175)
            p.BtnHover = Color3.fromHSV(h, tint, 0.225)
            p.Track    = Color3.fromHSV(h, tint * 0.8, 0.245)
            p.Line     = Color3.fromHSV(h, tint * 0.8, 0.21)
            return p
        end
        PALETTES[K.Name] = K.Make(SET.CustomHue, SET.CustomSat)

        -- quem pede o tema "Personalizado" recebe a cor atual de SET
        do
            local base = ApplyTheme
            if base then
                ApplyTheme = function(name)
                    if name == K.Name then
                        PALETTES[K.Name] = K.Make(SET.CustomHue, SET.CustomSat)
                    end
                    return base(name)
                end
            end
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Cor personalizada
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "COR PERSONALIZADA", 2)
        SubLabel(card, "Escolha a cor de destaque. USAR ESTA COR troca o tema; com ele "
            .. "ativo, os sliders mudam ao vivo. Também: theme personalizado.", -1)

        -- prévia: bolinha + botão de exemplo + switch ligado
        local prev = Instance.new("Frame")
        prev.Size = UDim2.new(1, 0, 0, 52)
        prev.LayoutOrder = 0
        prev.Parent = card
        V8.Cell(prev, 0)

        local sw = Instance.new("Frame")
        sw.AnchorPoint = Vector2.new(0, 0.5)
        sw.Position = UDim2.new(0, 0, 0.5, 0)
        sw.Size = UDim2.new(0, 30, 0, 30)
        sw.BorderSizePixel = 0
        sw.Parent = prev
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

        local name = Instance.new("TextLabel")
        name.Position = UDim2.new(0, 42, 0, 0)
        name.Size = UDim2.new(1, -200, 1, 0)
        name.BackgroundTransparency = 1
        name.Text = "Prévia"
        name.Font = Enum.Font.GothamBold
        name.TextSize = 13
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = prev

        local sample = Instance.new("TextLabel")
        sample.AnchorPoint = Vector2.new(1, 0.5)
        sample.Position = UDim2.new(1, -56, 0.5, 0)
        sample.Size = UDim2.new(0, 86, 0, 26)
        sample.BorderSizePixel = 0
        sample.Text = "BOTÃO"
        sample.Font = Enum.Font.GothamBold
        sample.TextSize = 11
        sample.Parent = prev
        Instance.new("UICorner", sample).CornerRadius = UDim.new(0, 9)

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.Position = UDim2.new(1, 0, 0.5, 0)
        track.Size = UDim2.new(0, 46, 0, 24)
        track.BorderSizePixel = 0
        track.Parent = prev
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Position = UDim2.new(1, -21, 0.5, -9)
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        K.Preview = function()
            local p = K.Make(SET.CustomHue, SET.CustomSat)
            prev.BackgroundColor3 = p.Card
            sw.BackgroundColor3 = p.Accent
            name.TextColor3 = p.Text
            sample.BackgroundColor3 = p.Accent
            sample.TextColor3 = p.Main
            track.BackgroundColor3 = p.Accent
            knob.BackgroundColor3 = p.Main
        end

        -- com o tema já ativo: reaplica ao vivo, no máximo ~3x por segundo
        local token = 0
        local function Live()
            pcall(K.Preview)
            if SET.Theme ~= K.Name then return end
            token = token + 1
            local mine = token
            task.delay(0.3, function()
                if mine ~= token or SET.Theme ~= K.Name then return end
                V8.QuietTheme = true
                pcall(ApplyTheme, K.Name)
                V8.QuietTheme = false
            end)
        end

        local hueSet = SliderRow(card, {
            label = "Cor (matiz)", min = 0, max = 360, def = SET.CustomHue, suffix = "°", order = 1,
            apply = function(v) SET.CustomHue = v Live() end,
        })
        local satSet = SliderRow(card, {
            label = "Intensidade", min = 15, max = 100, def = SET.CustomSat, suffix = "%", order = 2,
            apply = function(v) SET.CustomSat = v Live() end,
        })

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 3
        local bUse = CreateButton(g, "USAR ESTA COR", "Success", 32)
        bUse.LayoutOrder = 1
        bUse.MouseButton1Click:Connect(function() ApplyTheme(K.Name) end)
        local bRand = CreateButton(g, "SORTEAR", "Accent", 32)
        bRand.LayoutOrder = 2
        bRand.MouseButton1Click:Connect(function()
            hueSet(math.random(0, 359))
            satSet(math.random(45, 85))
        end)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function()
            pcall(hueSet, SET.CustomHue, true)
            pcall(satSet, SET.CustomSat, true)
            pcall(K.Preview)
        end)
        K.Preview()
    end
    Build()
end
end)
V8.Mod("src/50_v8/13_macros.lua", 15075, 15336, function() --------------------------------------------------------------------------------
-- v9.0 — MACROS DE TECLADO (Configurações › Teclas › Macros de teclado)
-- Uma tecla roda qualquer comando da barra (;) — "tp joao", "sit caça",
-- "flyspeed 200", "theme rosa"... Vários de uma vez: separe com &&
-- ("fly on && flyspeed 150"). Até 12 macros, salvas em SET.Macros
-- ({ key = "H", cmd = "..." }) na config e nos perfis.
-- A tecla não pode ser de outra coisa (painel, barra, busca, função,
-- situação); ao dar a tecla de uma macro para uma função, a macro perde a
-- tecla (com aviso). Com Fly/Freecam/Drone/Walk on Walls ligados, as teclas
-- de movimento deles não disparam macro.
-- O handler global de teclas (90_runtime/03_input.lua) chama V8.Macro.HandleKey.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Macro = { Max = 12 }
        local M = V8.Macro
        local function List()
            if type(SET.Macros) ~= "table" then SET.Macros = {} end
            return SET.Macros
        end
        List()

        local function KC(name)
            if type(name) ~= "string" then return nil end
            local ok, kc = pcall(function() return Enum.KeyCode[name] end)
            return ok and kc or nil
        end

        -- de quem é esta tecla? (nil = livre). 'except' = índice da macro que
        -- está pedindo (ela não conflita consigo mesma)
        M.Owner = function(kc, except)
            if kc == CONFIG.PanelKey then return "abrir o painel" end
            if kc == CONFIG.ConsoleKey then return "barra de comandos" end
            if kc == CONFIG.SearchKey and not CONFIG.SearchCtrl then return "busca global" end
            if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Return
                or kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Tab
                or kc == Enum.KeyCode.Slash then
                return "uso do Roblox"
            end
            for id, k in pairs(Keybinds) do
                if k == kc then return (Toggles[id] and Toggles[id].label or id) end
            end
            if V8.Sit then
                for n, k in pairs(V8.Sit.Keys) do
                    if k == kc then return "situação " .. n end
                end
            end
            for i, m in ipairs(List()) do
                if i ~= except and m.key == kc.Name then return "macro " .. i end
            end
            return nil
        end

        -- outra coisa pegou esta tecla: a macro que tinha ela fica sem tecla
        M.Release = function(kc)
            for i, m in ipairs(List()) do
                if m.key == kc.Name then
                    m.key = nil
                    Log("[" .. KeyName(kc) .. "] estava na macro " .. i .. " ('" .. tostring(m.cmd)
                        .. "') — ela ficou sem tecla", "warn")
                    Toast("Macro " .. i .. " perdeu a tecla " .. KeyName(kc), "warn", 3)
                end
            end
            if M.Render then pcall(M.Render) end
        end

        M.Run = function(m)
            local n = 0
            for part in (tostring(m.cmd or "") .. "&&"):gmatch("(.-)&&") do
                if part:match("%S") and V8.RunCommand then
                    V8.RunCommand(part)
                    n = n + 1
                end
            end
            return n
        end

        M.HandleKey = function(input)
            local kc = input.KeyCode
            for _, m in ipairs(List()) do
                if m.key == kc.Name and type(m.cmd) == "string" and m.cmd:match("%S") then
                    -- WASD do fly/freecam/drone: a tecla está ocupada movendo
                    if V8.KeyBusy and V8.KeyBusy(kc, nil) then return false end
                    M.Run(m)
                    return true
                end
            end
            return false
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Macros de teclado
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "MACROS DE TECLADO", 1)
        SubLabel(card, "Uma tecla roda qualquer comando da barra (;). Exemplos: tp joao · "
            .. "sit caça · flyspeed 200 · theme rosa. Vários comandos: separe com && "
            .. "(fly on && flyspeed 150). Clique na tecla e aperte; Backspace tira.", -1)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 1
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        local empty = SubLabel(card, "Nenhuma macro ainda.", 2)

        local bAdd = CreateButton(card, "+ NOVA MACRO", "Success", 32)
        bAdd.LayoutOrder = 3

        local function Capture(i, btn)
            Drop("MacroCapture")
            if StopCapture then pcall(StopCapture) end
            capturing = "macro"
            btn.Text = "aperte..."
            Toast("Aperte a tecla da macro " .. i .. " (Backspace tira)", nil, 3)
            Conn.MacroCapture = UserInputService.InputBegan:Connect(function(input)
                if capturing ~= "macro" then
                    Drop("MacroCapture")
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                local kc = input.KeyCode
                if kc == Enum.KeyCode.Unknown then return end
                Drop("MacroCapture")
                -- solta depois deste evento: senão o handler global já roda a macro
                task.defer(function() if capturing == "macro" then capturing = nil end end)
                local m = List()[i]
                if not m then return end
                if kc == Enum.KeyCode.Backspace then
                    m.key = nil
                    Log("Macro " .. i .. " sem tecla", "action")
                else
                    local owner = M.Owner(kc, i)
                    if owner then
                        Toast("[" .. KeyName(kc) .. "] já é de " .. owner .. " — escolha outra", "warn", 3)
                    else
                        m.key = kc.Name
                        Log("Macro " .. i .. " = [" .. KeyName(kc) .. "] " .. tostring(m.cmd), "ok")
                    end
                end
                pcall(M.Render)
            end)
        end

        M.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local all = List()
            empty.Visible = (#all == 0)
            for i, m in ipairs(all) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 42)
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = list
                V8.Cell(row, 0)

                local kb = Instance.new("TextButton")
                kb.AnchorPoint = Vector2.new(0, 0.5)
                kb.Position = UDim2.new(0, 0, 0.5, 0)
                kb.Size = UDim2.new(0, 70, 0, 28)
                kb.BackgroundColor3 = THEME.Btn
                kb.Text = m.key and KeyName(KC(m.key)) or "tecla"
                kb.TextColor3 = m.key and THEME.Accent2 or THEME.Dim
                kb.Font = Enum.Font.GothamBold
                kb.TextSize = 12
                kb.AutoButtonColor = false
                kb.Parent = row
                Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 7)
                do
                    local st = Instance.new("UIStroke", kb)
                    st.Transparency = 0.6
                    st.Color = THEME.Accent
                end
                kb.MouseButton1Click:Connect(function() Capture(i, kb) end)

                local box = Instance.new("TextBox")
                box.AnchorPoint = Vector2.new(0, 0.5)
                box.Position = UDim2.new(0, 80, 0.5, 0)
                box.Size = UDim2.new(1, -160, 0, 28)
                box.BackgroundColor3 = THEME.Btn
                box.Text = tostring(m.cmd or "")
                box.PlaceholderText = "comando (ex.: tp joao)"
                box.PlaceholderColor3 = THEME.Dim
                box.TextColor3 = THEME.Text
                box.Font = Enum.Font.Code
                box.TextSize = 12
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.ClearTextOnFocus = false
                box.Parent = row
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
                do
                    local p = Instance.new("UIPadding", box)
                    p.PaddingLeft = UDim.new(0, 8)
                    p.PaddingRight = UDim.new(0, 8)
                end
                box.FocusLost:Connect(function()
                    local t = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
                    if t ~= m.cmd then
                        m.cmd = t
                        Log("Macro " .. i .. ": " .. (t ~= "" and t or "(vazia)"), "action")
                    end
                end)

                local function IconBtn(kind, colorKey, x)
                    local b = Instance.new("TextButton")
                    b.AnchorPoint = Vector2.new(1, 0.5)
                    b.Position = UDim2.new(1, x, 0.5, 0)
                    b.Size = UDim2.new(0, 30, 0, 28)
                    b.BackgroundColor3 = THEME.Btn
                    b.Text = ""
                    b.AutoButtonColor = false
                    b.Parent = row
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
                    local ic = Icon(b, kind, THEME[colorKey], 13)
                    ic.AnchorPoint = Vector2.new(0.5, 0.5)
                    ic.Position = UDim2.new(0.5, 0, 0.5, 0)
                    return b
                end
                -- roda esta macro agora (para testar sem precisar da tecla)
                local run = IconBtn("play", "Success", -36)
                run.MouseButton1Click:Connect(function()
                    if not (m.cmd or ""):match("%S") then
                        Toast("Escreva o comando da macro " .. i .. " antes", "warn", 2)
                        return
                    end
                    M.Run(m)
                end)
                local del = IconBtn("trash", "Danger", 0)
                del.MouseButton1Click:Connect(function()
                    table.remove(List(), i)
                    Log("Macro " .. i .. " apagada", "action")
                    pcall(M.Render)
                end)
            end
            bAdd.Visible = (#all < M.Max)
        end

        bAdd.MouseButton1Click:Connect(function()
            local all = List()
            if #all >= M.Max then
                Toast("Limite de " .. M.Max .. " macros", "warn", 2)
                return
            end
            table.insert(all, { cmd = "" })
            pcall(M.Render)
            Toast("Macro " .. #all .. " criada: escreva o comando e escolha a tecla", "ok", 3)
        end)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(M.Render) end)
        M.Render()
    end
    Build()
end
end)
V8.Mod("src/50_v8/14_diag.lua", 15338, 15642, function() --------------------------------------------------------------------------------
-- v9.0 — DIAGNÓSTICO (Configurações › Sistema › Diagnóstico)
-- Num lugar só: o que este executor suporta, quanto o boot demorou, qual
-- módulo falhou (e em que linha do src/), memória, FPS/ping e os últimos
-- erros do log. COPIAR RELATÓRIO manda tudo para o clipboard — é o que pedir
-- para alguém quando "não funciona". Comando: diag.
-- Só calcula quando a aba Ajustes abre ou no botão (sem loop).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Diag = {}
        local D = V8.Diag

        local function Fn(f) return typeof(f) == "function" end
        local function Member(get)
            local ok, v = pcall(get)
            return ok and v ~= nil
        end

        D.Executor = function()
            local name
            pcall(function()
                if Fn(identifyexecutor) then
                    local a, b = identifyexecutor()
                    name = tostring(a) .. ((b ~= nil) and (" " .. tostring(b)) or "")
                elseif Fn(getexecutorname) then
                    name = tostring(getexecutorname())
                end
            end)
            return name or "não identificado"
        end

        -- { nome, tem?, para que serve }
        D.Caps = function()
            return {
                { "request()",    V8.Net and V8.Net.Fn() ~= nil, "enviar no Chat HYGE, trocar de servidor" },
                { "HttpGet",      Member(function() return game.HttpGet end), "ler catálogo e atualização" },
                { "Arquivos",     V8.Disk and V8.Disk.Ok() or false, "config, perfis, tempo de jogo" },
                { "Clipboard",    Fn(setclipboard), "copiar IDs, log e config" },
                { "loadstring",   Fn(loadstring), "atualizar sem sair do jogo" },
                { "gethui",       Fn(gethui), "GUI escondida do jogo" },
                { "getgenv",      Fn(getgenv), "loader e atualização" },
                { "GetObjects",   Member(function() return game.GetObjects end), "pacotes de animação" },
            }
        end

        -- v9.1: o Unload da sessão anterior (gravado em HYGE/unload.json)
        pcall(function()
            local raw = V8.Disk and V8.Disk.Read("HYGE/unload.json")
            if raw and V8.Net and V8.Net.Http then
                local d = V8.Net.Http:JSONDecode(raw)
                if type(d) == "table" and type(d.status) == "string" then D.PrevUnload = d end
            end
        end)

        -- pasta do src/ -> nome da seção "Modules"
        local GROUPS = {
            { "src/00_core/", "Core" }, { "src/10_ui/", "UI" }, { "src/20_features/", "Features" },
            { "src/30_kit/", "Kit" }, { "src/40_tabs/", "Tabs" }, { "src/50_v8/", "Painel" },
            { "src/90_runtime/", "Runtime" },
        }

        local function Count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

        -- v9.1: relatório em seções (Runtime, Modules, Connections, Tasks,
        -- Unload, Config, Erros) — o mesmo texto vai no COPIAR RELATÓRIO
        D.Lines = function()
            local out = {}
            local function add(s) table.insert(out, s) end
            local function head(s) if #out > 0 then add("") end add(s) end
            local mods, fails, total, slow = 0, {}, 0, {}
            for _, m in ipairs(V8.Mods) do
                mods = mods + 1
                total = total + (m.ms or 0)
                if not m.ok then table.insert(fails, m) end
                table.insert(slow, m)
            end
            table.sort(slow, function(a, b) return (a.ms or 0) > (b.ms or 0) end)

            add("HYGE DIAGNOSTICS")
            head("Runtime")
            local U = V8.Update
            local build = (U and U.MyBuild ~= "" and U.MyBuild) or "?"
            local how = "colado direto"
            if U and U.Loader then
                how = "loader" .. (U.Loader.verified and " (SHA-256 conferido)"
                    or (U.Loader.from and (" (" .. tostring(U.Loader.from) .. ")") or ""))
            end
            add("  Versão: HYGE " .. CONFIG.Version .. "  ·  build " .. build .. "  ·  " .. how)
            add("  Executor: " .. D.Executor())
            add("  Jogo: PlaceId " .. tostring(game.PlaceId) .. "  ·  JobId "
                .. (game.JobId ~= "" and game.JobId:sub(1, 8) .. "…" or "estúdio")
                .. "  ·  " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " jogadores")
            add(string.format("  Boot: %.2f s  ·  %d módulos isolados (%d ms)",
                (V8.BootMs or 0) / 1000, mods, math.floor(total + 0.5)))
            local lua, mem, ping = 0, 0, 0
            pcall(function() lua = gcinfo() / 1024 end)
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 2000) end)
            add(string.format("  Memória: Lua %.1f MB  ·  total %d MB  ·  FPS %d  ·  ping %d ms",
                lua, math.floor(mem), State.Fps or 0, ping))

            head("Modules")
            for _, g in ipairs(GROUPS) do
                local bad = {}
                for _, m in ipairs(fails) do
                    if m.name:sub(1, #g[1]) == g[1] then table.insert(bad, m) end
                end
                if #bad == 0 then
                    add("  " .. g[2] .. ": OK")
                else
                    add("  " .. g[2] .. ": " .. #bad .. " FALHOU")
                    for _, m in ipairs(bad) do add("    " .. m.name .. ": " .. tostring(m.err)) end
                end
            end
            if #slow > 0 then
                local t = {}
                for i = 1, math.min(3, #slow) do
                    local nm = slow[i].name:gsub("^src/", ""):gsub("%.lua$", "")
                    table.insert(t, nm .. " " .. math.floor(slow[i].ms + 0.5) .. " ms")
                end
                add("  Mais lentos: " .. table.concat(t, ", "))
            end

            head("Connections")
            local S = V8.Conns
            local active = Count(S.live)
            add(string.format("  Created: %d  ·  Active: %d  ·  Disconnected: %d", S.created, active, S.closed))
            if S.replaced > 0 then
                add("  Reaproveitadas sem Drop: " .. S.replaced .. " (eram vazamento; já desconectadas)")
            end
            local byMod = {}
            for _, meta in pairs(S.meta) do
                local w = V8.SrcOf(meta.lines)
                local mod = w and w:gsub("^src/", ""):gsub("%.lua:%d+$", "") or "?"
                byMod[mod] = (byMod[mod] or 0) + 1
            end
            local list = {}
            for mod, n in pairs(byMod) do table.insert(list, { mod, n }) end
            table.sort(list, function(a, b) return a[2] > b[2] end)
            if #list > 0 then
                local t = {}
                for i = 1, math.min(6, #list) do table.insert(t, list[i][1] .. " " .. list[i][2]) end
                add("  Ativas por módulo: " .. table.concat(t, " · "))
            end
            local r = S.respawns
            if #r == 0 then
                add("  Respawn: nenhum ainda (morra/renasça e confira de novo)")
            else
                local grow = #r >= 3 and r[#r] > r[#r - 1] and r[#r - 1] > r[#r - 2]
                add("  Respawn: boot " .. tostring(S.boot or "?") .. " → " .. table.concat(r, " → ")
                    .. (grow and "  << cresce a cada respawn: possível vazamento" or "  (estável)"))
            end

            head("Tasks")
            local T = V8.Tasks
            add(string.format("  Agendadas: %d  ·  pendentes: %d  ·  rodando agora: %d",
                T.scheduled, V8.Pending(), T.running))

            head("Unload")
            local P = D.PrevUnload
            if P then
                add(string.format("  Último (%s): %s — %d criadas, %d encerradas, %d ativas, %d rodando",
                    os.date("%d/%m %H:%M", tonumber(P.time) or 0), P.status, tonumber(P.created) or 0,
                    tonumber(P.closed) or 0, tonumber(P.active) or 0, tonumber(P.running) or 0))
                if type(P.left) == "table" and #P.left > 0 then
                    add("    sobrou: " .. table.concat(P.left, ", "))
                end
            else
                add("  Ainda sem registro (aparece depois do primeiro DESCARREGAR PAINEL)")
            end
            add("  Agora: o Unload encerraria " .. active .. " conexão(ões)")

            head("Config")
            local cfg = V8.Cfg and V8.Cfg.LoadState or nil
            add("  " .. (V8.Cfg and V8.Cfg.Supported() and "Em disco" or "Sem disco")
                .. (cfg and ("  ·  carregamento: " .. cfg) or "")
                .. "  ·  salvar sozinho " .. (SET.AutoSave and "ligado" or "desligado")
                .. ((V8.Cfg and V8.Cfg.Recoverable and #V8.Cfg.Recoverable > 0)
                    and ("  ·  dá para recuperar: " .. V8.Cfg.Recoverable[1].label) or ""))
            local PR = V8.Prof and V8.Prof.LastResult
            if PR then
                add("  Último perfil: " .. PR.name .. " (" .. PR.time .. ") — "
                    .. (PR.ok and ("aplicado" .. (#PR.rep.failed > 0 and (", não ligou: "
                        .. table.concat(PR.rep.failed, ", ")) or ""))
                        or ("RECUSADO: " .. table.concat(PR.rep.errors, "; ")
                            .. (PR.rep.rolledBack and " (voltou ao anterior)" or ""))))
            end
            local on = 0
            for _, id in ipairs(ToggleOrder) do if IsOn(id) then on = on + 1 end end
            add("  Funções ligadas " .. on .. "/" .. #ToggleOrder .. "  ·  registry de tema " .. #Painted
                .. "  ·  Remotes " .. (select(1, V8.RemoteStatus())) .. "/" .. #V8.RemoteInfo)

            head("Executor")
            local caps = {}
            for _, c in ipairs(D.Caps()) do
                table.insert(caps, c[1] .. (c[2] and " sim" or " NÃO"))
            end
            add("  " .. table.concat(caps, " · "))

            head("Erros")
            if #V8.Errors > 0 then
                for i = math.max(1, #V8.Errors - 4), #V8.Errors do
                    local e = V8.Errors[i]
                    add("  [" .. e.time .. "] " .. e.msg)
                end
            else
                add("  Nenhum erro registrado nesta sessão.")
            end
            return out
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Diagnóstico
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "DIAGNÓSTICO", 19)
        SubLabel(card, "O que o executor suporta, o boot e os erros recentes. Se algo "
            .. "não funcionar, COPIAR RELATÓRIO e mande junto.", -1)

        local capGrid = Grid(card, 2, 30)
        capGrid.LayoutOrder = 1
        local capCells = {}
        for i, c in ipairs(D.Caps()) do
            local cell = Instance.new("Frame")
            cell.LayoutOrder = i
            cell.BackgroundColor3 = THEME.Btn
            cell.BorderSizePixel = 0
            cell.Parent = capGrid
            Paint(cell, "BackgroundColor3", "Btn")
            Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 8)
            local dot = Instance.new("Frame")
            dot.AnchorPoint = Vector2.new(0, 0.5)
            dot.Position = UDim2.new(0, 10, 0.5, 0)
            dot.Size = UDim2.new(0, 8, 0, 8)
            dot.BorderSizePixel = 0
            dot.Parent = cell
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            local lbl = Instance.new("TextLabel")
            lbl.Position = UDim2.new(0, 26, 0, 0)
            lbl.Size = UDim2.new(1, -32, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = c[1]
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = cell
            capCells[i] = { dot = dot, lbl = lbl }
        end

        local report = Instance.new("TextLabel")
        report.Size = UDim2.new(1, 0, 0, 0)
        report.AutomaticSize = Enum.AutomaticSize.Y
        report.BackgroundTransparency = 1
        report.Text = ""
        report.TextColor3 = THEME.Dim
        report.Font = Enum.Font.Code
        report.TextSize = 11
        report.TextWrapped = true
        report.TextXAlignment = Enum.TextXAlignment.Left
        report.TextYAlignment = Enum.TextYAlignment.Top
        report.LayoutOrder = 2
        report.Parent = card
        Paint(report, "TextColor3", "Dim")

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 3
        local bRefresh = CreateButton(g, "ATUALIZAR", "Accent", 32)
        bRefresh.LayoutOrder = 1
        local bCopy = CreateButton(g, "COPIAR RELATÓRIO", "Success", 32)
        bCopy.LayoutOrder = 2

        D.Render = function()
            for i, c in ipairs(D.Caps()) do
                local cell = capCells[i]
                if cell then
                    cell.dot.BackgroundColor3 = c[2] and THEME.Success or THEME.Danger
                    cell.lbl.TextColor3 = c[2] and THEME.Text or THEME.Dim
                    cell.lbl.Text = c[1] .. (c[2] and "" or "  —  não tem")
                end
            end
            report.Text = table.concat(D.Lines(), "\n")
        end

        D.Copy = function()
            local text = "HYGE — diagnóstico (" .. os.date("%d/%m/%Y %H:%M") .. ")\n"
                .. table.concat(D.Lines(), "\n")
            if Fn(setclipboard) and pcall(setclipboard, text) then
                Toast("Relatório copiado", "ok", 2)
                return true
            end
            print(text)
            Toast("Sem clipboard: o relatório foi para o console do Roblox (F9)", "warn", 3)
            return false
        end

        bRefresh.MouseButton1Click:Connect(function() pcall(D.Render) end)
        bCopy.MouseButton1Click:Connect(function() pcall(D.Render) D.Copy() end)
        OnTabOpen("Settings", function() pcall(D.Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(D.Render) end)
    end
    Build()
end
end)
V8.Mod("src/50_v8/15_news.lua", 15644, 15841, function() --------------------------------------------------------------------------------
-- v9.0 — NOVIDADES / BOAS-VINDAS
-- Na primeira vez que uma versão nova abre, aparece um cartão com o que
-- mudou. Quem nunca usou o HYGE (sem config salva) vê os primeiros passos.
-- Aparece uma vez por versão (SET.SeenVersion, vai na config). Reabrir:
-- comando 'novidades' ou Configurações › Sobre.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.News = {}
        local W = V8.News

        -- já existia config ANTES deste boot? (decide boas-vindas x novidades)
        W.HadConfig = false
        pcall(function()
            if V8.Cfg and V8.Cfg.Supported() and isfile(V8.Cfg.Path) then W.HadConfig = true end
        end)

        -- v9.1: estabilidade
        W.Items = {
            { "check",    "Backup da config", "Config, perfis e tempo de jogo têm backup. Arquivo estragado? RECUPERAR BACKUP (ou o comando recover)." },
            { "shield",   "Atualização conferida", "O loader e o ATUALIZAR AGORA só trocam a versão se o arquivo bater com o SHA-256 do manifesto. Download ruim abre a última que funcionava." },
            { "layers",   "Perfis seguros", "Perfil inválido não muda nada; se algo falhar no meio, o painel volta ao que estava." },
            { "signal",   "Diagnóstico novo", "Conexões por módulo, tarefas, respawn e se o último Unload ficou limpo." },
            { "power",    "Rodar de novo sem duplicar", "Executar o script outra vez descarrega o painel anterior de verdade." },
            { "keyboard", "Shift Lock bloqueado", "O Shift não prende mais o mouse no centro (o Fly usa o Shift para acelerar). Dá para religar em Comportamento." },
        }
        -- função: as teclas podem ter mudado depois que a config carregou
        W.Tips = function()
            return {
                { "home",     "Dock no rodapé", "Cada ícone abre uma seção. Clique de novo para fechar." },
                { "keyboard", "Teclas", "[" .. KeyName(CONFIG.PanelKey) .. "] abre/fecha  ·  ["
                    .. KeyName(CONFIG.ConsoleKey) .. "] comandos  ·  "
                    .. (CONFIG.SearchCtrl and "Ctrl+" or "") .. KeyName(CONFIG.SearchKey) .. " busca tudo." },
                { "star",     "Favoritos", "A estrela ao lado de cada função fixa ela na Home." },
                { "gear",     "Do seu jeito", "Temas, teclas e perfis em Configurações." },
            }
        end

        local overlay, box, titleLbl, subLbl, list

        local function Row(parent, order, item)
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, 0)
            r.AutomaticSize = Enum.AutomaticSize.Y
            r.BackgroundTransparency = 1
            r.LayoutOrder = order
            r.Parent = parent
            local pad = Instance.new("Frame")
            pad.Size = UDim2.new(0, 30, 0, 30)
            pad.BackgroundColor3 = THEME.Btn
            pad.BorderSizePixel = 0
            pad.Parent = r
            Instance.new("UICorner", pad).CornerRadius = UDim.new(0, 9)
            local ic = Icon(pad, item[1], THEME.Accent, 16)
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.Position = UDim2.new(0.5, 0, 0.5, 0)
            local t = Instance.new("TextLabel")
            t.Position = UDim2.new(0, 42, 0, 0)
            t.Size = UDim2.new(1, -42, 0, 16)
            t.BackgroundTransparency = 1
            t.Text = item[2]
            t.TextColor3 = THEME.Text
            t.Font = Enum.Font.GothamBold
            t.TextSize = 13
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = r
            local d = Instance.new("TextLabel")
            d.Position = UDim2.new(0, 42, 0, 17)
            d.Size = UDim2.new(1, -42, 0, 0)
            d.AutomaticSize = Enum.AutomaticSize.Y
            d.BackgroundTransparency = 1
            d.Text = item[3]
            d.TextColor3 = THEME.Dim
            d.Font = Enum.Font.GothamMedium
            d.TextSize = 11
            d.TextWrapped = true
            d.TextXAlignment = Enum.TextXAlignment.Left
            d.Parent = r
        end

        local function Create()
            overlay = Instance.new("Frame")
            overlay.Name = "News"
            overlay.Size = UDim2.new(1, 0, 1, 0)
            overlay.BackgroundColor3 = Color3.new(0, 0, 0)
            overlay.BackgroundTransparency = 0.4
            overlay.Visible = false
            overlay.ZIndex = 65
            overlay.Parent = Gui

            box = Instance.new("Frame")
            box.AnchorPoint = Vector2.new(0.5, 0.5)
            box.Position = UDim2.new(0.5, 0, 0.5, 0)
            box.Size = UDim2.new(0, 430, 0, 470)
            box.BackgroundColor3 = THEME.Card
            box.BorderSizePixel = 0
            box.Parent = overlay
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 18)
            local st = Instance.new("UIStroke", box)
            st.Color = THEME.Line
            st.Transparency = 0.1

            titleLbl = Instance.new("TextLabel")
            titleLbl.Position = UDim2.new(0, 22, 0, 18)
            titleLbl.Size = UDim2.new(1, -44, 0, 26)
            titleLbl.BackgroundTransparency = 1
            titleLbl.TextColor3 = THEME.Text
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextSize = 21
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = box

            subLbl = Instance.new("TextLabel")
            subLbl.Position = UDim2.new(0, 22, 0, 46)
            subLbl.Size = UDim2.new(1, -44, 0, 16)
            subLbl.BackgroundTransparency = 1
            subLbl.TextColor3 = THEME.Dim
            subLbl.Font = Enum.Font.GothamMedium
            subLbl.TextSize = 12
            subLbl.TextXAlignment = Enum.TextXAlignment.Left
            subLbl.Parent = box

            list = Instance.new("ScrollingFrame")
            list.Position = UDim2.new(0, 22, 0, 76)
            list.Size = UDim2.new(1, -36, 1, -140)
            list.BackgroundTransparency = 1
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 3
            list.ScrollBarImageColor3 = THEME.Accent
            list.CanvasSize = UDim2.new(0, 0, 0, 0)
            list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            list.Parent = box
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 12)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            local p = Instance.new("UIPadding", list)
            p.PaddingRight = UDim.new(0, 10)

            local ok = CreateButton(box, "BORA!", "Success", 38)
            ok.AnchorPoint = Vector2.new(0.5, 1)
            ok.Position = UDim2.new(0.5, 0, 1, -16)
            ok.Size = UDim2.new(1, -44, 0, 38)
            ok.TextSize = 14
            ok.Font = Enum.Font.GothamBold
            ok.MouseButton1Click:Connect(function() W.Close() end)
        end

        W.Close = function()
            if overlay then overlay.Visible = false end
        end

        -- welcome = true: primeiros passos (quem nunca usou)
        W.Show = function(welcome)
            if not overlay then Create() end
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            -- cores do tema atual (o cartão não fica no registry: é efêmero)
            box.BackgroundColor3 = THEME.Card
            titleLbl.TextColor3 = THEME.Text
            subLbl.TextColor3 = THEME.Dim
            if welcome then
                titleLbl.Text = "Bem-vindo ao HYGE " .. CONFIG.Version
                subLbl.Text = "Quatro coisas para começar:"
                for i, it in ipairs(W.Tips()) do Row(list, i, it) end
            else
                titleLbl.Text = "Novidades da " .. CONFIG.Version
                subLbl.Text = "A maior atualização do HYGE até agora:"
                for i, it in ipairs(W.Items) do Row(list, i, it) end
            end
            -- tela baixa (celular deitado): o cartão encolhe e a lista rola
            local vp = Gui.AbsoluteSize
            local h = 470
            if vp.Y > 100 then h = math.clamp(vp.Y - 40, 260, 470) end
            local w = 430
            if vp.X > 100 then w = math.min(430, vp.X - 24) end
            box.Size = UDim2.new(0, w, 0, h)
            overlay.Visible = true
        end

        W.Boot = function()
            if SET.SeenVersion == CONFIG.Version then return end
            local welcome = not W.HadConfig
            SET.SeenVersion = CONFIG.Version   -- o salvamento automático grava
            task.delay(0.8, function() pcall(W.Show, welcome) end)
        end

        Conn.NewsKeys = UserInputService.InputBegan:Connect(function(input)
            if overlay and overlay.Visible and (input.KeyCode == Enum.KeyCode.Escape
                or input.KeyCode == Enum.KeyCode.Return) then
                W.Close()
            end
        end)
    end
    Build()
end
end)
V8.Mod("src/50_v8/19_settings_nav.lua", 15843, 16024, function() --------------------------------------------------------------------------------
-- v9.0 — AJUSTES ORGANIZADOS (Configurações › Ajustes)
-- A aba tinha ~20 cartões numa rolagem só. Agora, no topo:
--   * categorias em pílula: Tudo · Geral · Teclas · Visual · Dados · Sistema
--   * busca dentro dos ajustes (sem acento: "aparencia" acha "Aparência";
--     procura no título E no texto de cada opção do cartão)
-- Cada cartão vai para a categoria pelo título (tabela MAP abaixo) e a ordem
-- dentro da aba passa a seguir as categorias. Cartão novo sem entrada no MAP
-- cai em "Geral". A busca global (Ctrl+K) acha os cartões e abre filtrado.
-- Entra DEPOIS de todos os módulos que criam cartões em Ajustes.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = Tabs.Settings
        if not tab then return end
        V8.SetNav = { Cat = "all", Query = "", Cards = {} }
        local N = V8.SetNav

        N.Cats = {
            { "all", "Tudo" }, { "geral", "Geral" }, { "teclas", "Teclas" },
            { "visual", "Visual" }, { "dados", "Dados" }, { "sistema", "Sistema" },
        }
        -- título do cartão (V8.Fold: minúsculo, sem acento) -> { categoria, ordem }
        local MAP = {
            ["comportamento"]          = { "geral", 1 },
            ["automatico"]             = { "geral", 2 },
            ["presets"]                = { "geral", 3 },
            ["celular e toque"]        = { "geral", 4 },
            ["keybinds"]               = { "teclas", 1 },
            ["macros de teclado"]      = { "teclas", 2 },
            ["atalhos das situacoes"]  = { "teclas", 3 },
            ["busca global"]           = { "teclas", 4 },
            ["aparencia"]              = { "visual", 1 },
            ["cor personalizada"]      = { "visual", 2 },
            ["notificacoes"]           = { "visual", 3 },
            ["navegacao"]              = { "visual", 4 },
            ["ilha no topo"]           = { "visual", 5 },
            ["perfis"]                 = { "dados", 1 },
            ["configuracao em disco"]  = { "dados", 2 },
            ["atualizacao"]            = { "sistema", 1 },
            ["diagnostico"]            = { "sistema", 2 },
            ["sistema"]                = { "sistema", 3 },
            ["sobre"]                  = { "sistema", 4 },
        }
        local IDX = {}
        for i, c in ipairs(N.Cats) do IDX[c[1]] = i end

        for _, c in ipairs(tab:GetChildren()) do
            if c:IsA("Frame") and c.Name == "Card" then
                local t = CardTitleRef(c)
                local title = t and t.Text or ""
                local m = MAP[V8.Fold(title)] or { "geral", 50 }
                c.LayoutOrder = IDX[m[1]] * 100 + m[2]
                table.insert(N.Cards, { card = c, title = title, cat = m[1] })
            end
        end
        table.sort(N.Cards, function(a, b) return a.card.LayoutOrder < b.card.LayoutOrder end)

        ----------------------------------------------------------------------------
        -- topo: pílulas + busca (rolam junto com a aba)
        ----------------------------------------------------------------------------
        local head = Instance.new("Frame")
        head.Name = "SettingsNav"
        head.Size = UDim2.new(1, 0, 0, 0)
        head.AutomaticSize = Enum.AutomaticSize.Y
        head.BackgroundTransparency = 1
        head.LayoutOrder = -100
        head.Parent = tab
        do
            local l = Instance.new("UIListLayout", head)
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local chips = Instance.new("Frame")
        chips.Size = UDim2.new(1, 0, 0, 28)
        chips.BackgroundTransparency = 1
        chips.LayoutOrder = 1
        chips.Parent = head
        do
            local l = Instance.new("UIListLayout", chips)
            l.FillDirection = Enum.FillDirection.Horizontal
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local chipBtns = {}
        local n = #N.Cats
        for i, c in ipairs(N.Cats) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1 / n, -5 * (n - 1) / n, 1, 0)
            b.BackgroundColor3 = THEME.Btn
            b.Text = c[2]
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = chips
            Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
            chipBtns[c[1]] = b
        end

        local search = CreateInput(head, "buscar nos ajustes (tema, tecla, salvar...)", 32)
        search.LayoutOrder = 2

        local empty = SubLabel(tab, "", 9999)
        empty.Visible = false

        ----------------------------------------------------------------------------
        -- filtro
        ----------------------------------------------------------------------------
        local function Haystack(card)
            local parts = {}
            for _, d in ipairs(card:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
                    table.insert(parts, d.Text)
                end
            end
            return V8.Fold(table.concat(parts, " "))
        end

        local function PaintChips()
            for id, b in pairs(chipBtns) do
                local on = (id == N.Cat)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        N.Apply = function()
            local q = V8.Fold(N.Query or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local shown = 0
            for _, e in ipairs(N.Cards) do
                local ok = (N.Cat == "all" or e.cat == N.Cat)
                if ok and q ~= "" then
                    ok = V8.Fold(e.title):find(q, 1, true) ~= nil
                        or Haystack(e.card):find(q, 1, true) ~= nil
                end
                e.card.Visible = ok
                if ok then shown = shown + 1 end
            end
            empty.Visible = (shown == 0)
            empty.Text = (q ~= "") and ("Nada nos ajustes com \"" .. (N.Query or "") .. "\""
                .. ((N.Cat ~= "all") and " nesta categoria — tente Tudo." or "."))
                or "Nada nesta categoria."
            PaintChips()
        end

        N.SetCat = function(cat)
            if not IDX[cat] then cat = "all" end
            N.Cat = cat
            N.Apply()
            tab.CanvasPosition = Vector2.new(0, 0)
        end

        for id, b in pairs(chipBtns) do
            b.MouseButton1Click:Connect(function() N.SetCat(id) end)
        end
        search:GetPropertyChangedSignal("Text"):Connect(function()
            N.Query = search.Text
            pcall(N.Apply)
        end)

        -- busca global: abre Configurações › Ajustes mostrando só esse cartão
        N.Focus = function(title)
            N.Cat = "all"
            search.Text = title or ""   -- dispara o filtro
            N.Query = search.Text
            N.Apply()
            ShowTab("Settings")
            if V8.IsOpen and not V8.IsOpen() and V8.SetOpen then V8.SetOpen(true) end
            tab.CanvasPosition = Vector2.new(0, 0)
        end

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(PaintChips) end)
        N.Apply()
    end
    Build()
end
end)
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
AddNav("Troll", 6)        -- v8.1
AddNav("Emotes", 7)
AddNav("Players", 8)
AddNav("Moderation", 9)
AddNav("Settings", 10)
AddNav("Scripts", 11)
AddNav("HyChat", 12)      -- v8.1
AddNav("Chat", 13)

V8.Mod("src/90_runtime/01_commands.lua", 16061, 16802, function() --------------------------------------------------------------------------------
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

    DefCmd("theme", "theme <nome>", "troca a paleta (sem nome: lista)", function(args)
        -- v9.0: lista vem de THEME_ORDER (+ Personalizado); aceita sem acento
        local names = {}
        for _, n in ipairs(THEME_ORDER) do table.insert(names, n) end
        if PALETTES.Personalizado then table.insert(names, "Personalizado") end
        local q = table.concat(args, " ")
        if q == "" then Log("Temas: " .. table.concat(names, ", ")) return end
        local want = V8.Fold(q)
        for _, n in ipairs(names) do
            if V8.Fold(n) == want or V8.Fold(n):sub(1, #want) == want then
                if ApplyTheme then ApplyTheme(n) end
                return
            end
        end
        Log("Tema inexistente: " .. q .. " (temas: " .. table.concat(names, ", ") .. ")", "warn")
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

    ----------------------------------------------------------------------------
    -- v8.1: Início (servidor), Personagem (gravidade) e Playtime Shop
    ----------------------------------------------------------------------------
    DefCmd("rejoin", "rejoin", "sai e volta para este mesmo servidor", function()
        if V8.Hop then V8.Hop.Rejoin() end
    end)

    DefCmd("hop", "hop", "troca para outro servidor público do jogo", function()
        if V8.Hop then V8.Hop.Hop() end
    end, "serverhop")

    DefCmd("discord", "discord", "copia o convite do Discord (CONFIG.Discord)", function()
        if V8.Hop then V8.Hop.Discord() end
    end)

    DefCmd("gravity", "gravity <0-100>", "% da gravidade com Anti-Gravidade ligado", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: gravity <0-100>", "warn") return end
        if V8.GravSlider then V8.GravSlider(v) elseif V8.AntiGrav then V8.AntiGrav.Set(v) end
        Log("Gravidade (Anti-Gravidade) = " .. State.GravityPct .. "%"
            .. (IsOn("antigrav") and "" or "  — ligue o antigrav para valer"), "ok")
    end, "grav")

    DefCmd("playtime", "playtime", "tempo de jogo e pontos da Playtime Shop", function()
        local P = V8.Play
        if not P then return end
        Log("Tempo de jogo: " .. P.Fmt(P.Total) .. "  ·  sessão " .. P.Fmt(P.Session())
            .. "  ·  " .. P.Points() .. " ponto(s)"
            .. (P.Line() ~= "" and ("  ·  " .. P.Line()) or ""), "ok")
    end, "pt")

    DefCmd("givepoints", "givepoints [n|max]", "dá pontos da Playtime Shop (sem n: o que falta pra comprar tudo)",
        function(args)
            local P = V8.Play
            if not P then return end
            local a = (args[1] or ""):lower()
            local n
            if a == "" then
                n = math.max(0, P.MissingCost() - P.Points())
                if n == 0 then Log("Você já tem pontos para comprar tudo (" .. P.Points() .. ")", "ok") return end
            elseif a == "max" then
                n = 999999 - P.Points()
            else
                n = tonumber(a)
            end
            if not n or n <= 0 then Log("uso: givepoints [numero|max]", "warn") return end
            P.Grant(n)
            Log("+" .. math.floor(n) .. " ponto(s)  ·  agora: " .. P.Points(), "ok")
            Toast("+" .. math.floor(n) .. " pontos", "ok", 2)
        end, "gp")

    DefCmd("unlockall", "unlockall", "libera todos os itens da Playtime Shop", function()
        local P = V8.Play
        if not P then return end
        local n = P.UnlockAll()
        Log(n > 0 and (n .. " item(ns) liberado(s) na Playtime Shop") or "Você já tem todos os itens", "ok")
        if n > 0 then Toast(n .. " itens liberados", "ok", 2) end
    end)

    ----------------------------------------------------------------------------
    -- v8.2: pacotes de animação, missões e atualização
    ----------------------------------------------------------------------------
    DefCmd("pack", "pack list|add <id>|use <nome>|fly <nome>|off",
        "pacotes de animação (personagem e voo)", function(args)
            local K = V8.Pack
            if not K then Log("Pacotes indisponíveis", "error") return end
            local sub = (args[1] or "list"):lower()
            local rest = table.concat(args, " ", 2)
            if sub == "list" or sub == "ls" then
                local fp = K.FlyPack()
                for i, p in ipairs(K.List()) do
                    Log(i .. ") " .. p.name .. "  ·  ID " .. p.id .. "  ·  "
                        .. K.Count(p) .. " animações"
                        .. (SET.PackOn == p.id and "  ·  NO PERSONAGEM" or "")
                        .. ((fp and fp.id == p.id) and "  ·  NO VOO" or ""))
                end
                if #K.List() == 0 then Log("Nenhum pacote. Use: pack add <id ou link>", "warn") end
            elseif sub == "add" then
                local p, why = K.Add(rest, function(pk, n, err)
                    if n then Log("Pacote lido: " .. pk.name .. " (" .. n .. " animações)", "ok")
                    else Log("Pacote " .. pk.id .. " não foi lido: " .. tostring(err), "error") end
                end)
                if not p then Log(tostring(why), "warn") end
            elseif sub == "use" or sub == "fly" then
                local p = K.Find(rest)
                if not p and K.Parse(rest) then p = K.Add(rest) end
                if not p then Log("Pacote não encontrado: " .. rest .. " (veja 'pack list')", "warn") return end
                if sub == "use" then K.Use(p) else
                    K.SetFly(p)
                    if K.Count(p) == 0 then K.Resolve(p) end
                    Log("Voo agora usa o pacote " .. p.name, "ok")
                end
            elseif sub == "off" then
                K.Off()
            else
                Log("uso: pack list | pack add <id ou link> | pack use <nome> | pack fly <nome> | pack off", "warn")
            end
        end)

    DefCmd("missoes", "missoes [resgatar]", "missões do dia da Playtime Shop", function(args)
        local Q = V8.Quest
        if not Q then Log("Missões indisponíveis", "error") return end
        local d = Q.Data()
        if (args[1] or ""):lower():find("^resg") then
            local got = 0
            for _, m in ipairs(Q.Defs) do
                local ok, pts = Q.Claim(m.id)
                if ok then got = got + pts end
            end
            Log(got > 0 and ("Resgatado: +" .. got .. " pontos") or "Nada para resgatar agora", got > 0 and "ok" or "warn")
            return
        end
        for _, m in ipairs(Q.Defs) do
            local v = d.prog[m.id]
            local txt = m.min and (math.floor(v / 60) .. "/" .. math.floor(m.goal / 60) .. " min")
                or (v .. "/" .. m.goal)
            Log(m.name .. ": " .. txt .. "  ·  +" .. m.reward
                .. (d.claimed[m.id] and "  ·  resgatada" or (v >= m.goal and "  ·  PRONTA" or "")))
        end
        Log("Bônus diário: " .. d.streak .. " dia(s) seguido(s)", "ok")
    end, "quests")

    DefCmd("update", "update [now]", "confere (ou instala) a versão nova do painel", function(args)
        if not V8.Update then Log("Atualização indisponível", "error") return end
        if (args[1] or ""):lower() == "now" then V8.Update.Apply() else V8.Update.Check(true) end
    end)

    ----------------------------------------------------------------------------
    -- v9.0: favoritos, perfis, notificações, diagnóstico, novidades
    ----------------------------------------------------------------------------
    DefCmd("fav", "fav [função]", "fixa/tira uma função das ações rápidas (sem nome: lista)",
        function(args)
            if not V8.Fav then return end
            local id = (args[1] or ""):lower()
            if id == "" then
                local names = {}
                for _, x in ipairs(V8.Fav.List()) do
                    table.insert(names, Toggles[x] and Toggles[x].label or x)
                end
                Log("Ações rápidas (" .. #names .. "): " .. (#names > 0 and table.concat(names, ", ") or "nenhuma"))
                return
            end
            if not Toggles[id] then
                Log("Função desconhecida: " .. id .. " (ids: " .. table.concat(ToggleOrder, ", ") .. ")", "warn")
                return
            end
            V8.Fav.Toggle(id)
        end)

    DefCmd("perfil", "perfil list|save <nome>|use <nome>|del <nome>|jogo <nome|off>",
        "perfis do painel (v9.0)", function(args)
            local P = V8.Prof
            if not P then Log("Perfis indisponíveis", "error") return end
            local sub = (args[1] or "list"):lower()
            local name = table.concat(args, " ", 2)
            if sub == "list" or sub == "ls" then
                if #P.Data.list == 0 then Log("Nenhum perfil. Use: perfil save <nome>", "warn") return end
                for i, r in ipairs(P.Data.list) do
                    Log(i .. ") " .. r.name .. ((P.Current == r.name) and "  ·  ativo" or "")
                        .. ((P.HereName() == r.name) and "  ·  abre neste jogo" or ""))
                end
            elseif sub == "save" then
                local ok, err = P.SaveAs(name ~= "" and name or (P.Current or ""))
                if not ok then Log(tostring(err), "warn") end
            elseif sub == "use" then
                local ok, err = P.Use(name)
                if not ok then Log(tostring(err), "warn") end
            elseif sub == "del" or sub == "rm" then
                local ok, err = P.Delete(name)
                if not ok then Log(tostring(err), "warn") end
            elseif sub == "jogo" or sub == "here" then
                if name == "" or name:lower() == "off" then P.BindHere(nil)
                else
                    local ok, err = P.BindHere((P.Find(name) or {}).name or name)
                    if not ok then Log(tostring(err), "warn") end
                end
            else
                Log("uso: perfil list | save <nome> | use <nome> | del <nome> | jogo <nome|off>", "warn")
            end
        end, "profile")

    DefCmd("notif", "notif [limpar|dnd]", "abre as notificações (ou limpa / não perturbe)", function(args)
        local N = V8.Notif
        if not N then return end
        local a = (args[1] or ""):lower()
        if a == "limpar" or a == "clear" then N.Clear() Log("Notificações limpas", "action")
        elseif a == "dnd" then
            N.SetDnd(not SET.Dnd)
            Log("Não perturbe: " .. (SET.Dnd and "ligado" or "desligado"), "action")
        else N.Open() end
    end)

    DefCmd("diag", "diag [copiar]", "diagnóstico: executor, boot, erros", function(args)
        if not V8.Diag then return end
        if (args[1] or ""):lower():find("^cop") then V8.Diag.Copy() return end
        for _, l in ipairs(V8.Diag.Lines()) do Log(l) end
    end)

    DefCmd("novidades", "novidades", "mostra o que mudou nesta versão", function()
        if V8.News then V8.News.Show(false) end
    end, "news")

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

    -- v9.1: config (ou perfis) de volta do backup
    DefCmd("recover", "recover [perfis]", "recupera a config (ou os perfis) do backup", function(args)
        if (args[1] or ""):lower():sub(1, 4) == "perf" then
            if V8.Prof and V8.Prof.Recover then V8.Prof.Recover() else Log("Perfis indisponíveis", "error") end
            return
        end
        if V8.Cfg then V8.Cfg.RecoverNow(1) else Log("Persistência indisponível", "error") end
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

end)
V8.Mod("src/90_runtime/02_window_ctl.lua", 16804, 17020, function() --------------------------------------------------------------------------------
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

end)
V8.Mod("src/90_runtime/03_input.lua", 17022, 17171, function() --------------------------------------------------------------------------------
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
    -- v8.1
    wallwalk = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                 Enum.KeyCode.Space },
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
    -- v9.0: macros (tecla -> comando), antes dos atalhos das funções
    if V8.Macro then
        local okM, handled = pcall(V8.Macro.HandleKey, input)
        if okM and handled then return end
    end

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
-- v9.0.1: SHIFT LOCK DO ROBLOX
-- Em jogo que libera o Shift Lock, o Shift prende o mouse no centro da tela —
-- inclusive no Fly, que usa o Shift para acelerar. (Freecam e Drone não sofrem:
-- a câmera deles é Scriptable e o próprio HYGE manda no mouse.)
-- Com SET.NoShiftLock (Configurações › Comportamento, padrão ligado) o painel
-- desliga LocalPlayer.DevEnableMouseLock: o PlayerModule solta o mouse na hora
-- e para de ouvir o Shift. Se o jogo religar, desliga de novo. Desligando a
-- opção ou descarregando o painel, volta o valor que o jogo queria.
-- (Shift Lock feito pelo próprio jogo, fora do PlayerModule, não é coberto.)
--------------------------------------------------------------------------------
do
    local SL = { held = false, saved = false, warned = false }
    V8.ShiftLock = SL

    local function Get()
        local ok, v = pcall(function() return LocalPlayer.DevEnableMouseLock end)
        if ok then return v end
        return nil
    end
    local function Set(v)
        return pcall(function() LocalPlayer.DevEnableMouseLock = v end)
    end

    -- devolve o Shift Lock como o jogo deixou (opção desligada / unload)
    SL.Release = function()
        if not SL.held then return end
        SL.held = false
        if SL.saved then Set(true) end
        SL.saved = false
    end

    SL.Sync = function()
        if SL.dead then return end
        if SET.NoShiftLock == false then
            SL.Release()
            return
        end
        local cur = Get()
        if cur == nil then return end
        if not SL.held then SL.held, SL.saved = true, cur end
        if cur then
            -- ligado (pelo jogo no começo ou religado depois): guarda e desliga
            SL.saved = true
            if not Set(false) and not SL.warned then
                SL.warned = true
                Log("Não deu para bloquear o Shift Lock neste executor", "warn")
            end
        end
    end

    -- o jogo mexeu na propriedade: confere de novo (Set(false) aqui dentro
    -- dispara o sinal outra vez, mas aí já está false e não faz nada)
    pcall(function()
        Conn.ShiftLock = LocalPlayer:GetPropertyChangedSignal("DevEnableMouseLock")
            :Connect(function() pcall(SL.Sync) end)
    end)
    -- unload: para de vigiar ANTES de devolver (senão o sinal desligaria de novo)
    SL.Stop = function()
        SL.dead = true
        Drop("ShiftLock")
        SL.Release()
    end
    -- config / perfil carregado ou "restaurar padrões" mudaram SET.NoShiftLock
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, function() pcall(SL.Sync) end)
    SL.Sync()
end

end)
V8.Mod("src/90_runtime/04_scheduler.lua", 17173, 17279, function() --------------------------------------------------------------------------------
-- SCHEDULER ÚNICO (um Heartbeat para todo o painel)
--------------------------------------------------------------------------------
do
    local jobs = {}
    local function Every(interval, fn)
        table.insert(jobs, { i = interval, acc = math.huge, fn = fn })
    end

    -- v8.1: jobs registrados antes do scheduler existir (V8.Job em 04_state);
    -- daqui em diante V8.Job registra direto
    for _, j in ipairs(V8.Jobs) do Every(j[1], j[2]) end
    V8.Job = Every

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
        -- v8.1: abas novas se atualizam sozinhas (só a visível trabalha)
        if V8.TabTick and V8.TabTick[tab] then pcall(V8.TabTick[tab]) end
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

end)
V8.Mod("src/90_runtime/05_events.lua", 17281, 17399, function() --------------------------------------------------------------------------------
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

    -- v9.1: conexões vivas depois de cada respawn (Diagnóstico). Se o número
    -- sobe a cada vez, alguma função conecta no personagem novo sem largar a
    -- do antigo.
    task.delay(3, function()
        if V8.Unloaded then return end
        local n = 0
        for _ in pairs(V8.Conns.live) do n = n + 1 end
        local r = V8.Conns.respawns
        table.insert(r, n)
        while #r > 8 do table.remove(r, 1) end
    end)
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
    EspOpts.Pick[id] = nil   -- v8.1: ESP por jogador
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

end)
V8.Mod("src/90_runtime/06_unload.lua", 17401, 17497, function() --------------------------------------------------------------------------------
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

    -- v8.1: tempo de jogo da Playtime Shop (arquivo próprio, independe do autosave)
    pcall(function() if V8.Play then V8.Play.Save(true) end end)

    for _, id in ipairs(ToggleOrder) do
        if IsOn(id) then pcall(Toggles[id].disable) end
    end
    -- v9.0.1: Shift Lock do Roblox volta como o jogo deixou
    pcall(function() if V8.ShiftLock then V8.ShiftLock.Stop() end end)
    pcall(StopSpectate)
    pcall(ClearEsp)
    pcall(function() Emote.Stop(true) end)
    pcall(function() if V8.Cos then V8.Cos.Clear() end end)   -- v8.1: efeitos/nametag
    -- v8.2: animações originais de volta (SET.PackOn já foi salvo acima)
    pcall(function() if V8.Pack then V8.Pack.Restore() end end)

    -- v9.1: Conn é um proxy — a lista de verdade fica em V8.Conns.live
    local names = {}
    for name in pairs(V8.Conns.live) do table.insert(names, name) end
    for _, name in ipairs(names) do pcall(Drop, name) end
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

    -- v9.1: CONFERÊNCIA DO UNLOAD. Sobrou conexão? Tarefa agendada que ainda
    -- vai rodar, ou rodando (esperando HTTP/wait)? Vai para o console e para
    -- HYGE/unload.json (o Diagnóstico da próxima sessão mostra).
    pcall(function()
        local left = {}
        for name in pairs(V8.Conns.live) do table.insert(left, name) end
        local pending, running = V8.Pending(), V8.Tasks.running
        local clean = (#left == 0 and running == 0)
        local status = clean and "CLEAN" or "SOBROU"
        local msg = string.format("[HYGE] Unload: %s — %d conexões criadas, %d encerradas, %d ativas"
            .. "; tarefas: %d pendentes, %d rodando", status, V8.Conns.created, V8.Conns.closed,
            #left, pending, running)
        if clean then print(msg) else warn(msg .. (#left > 0 and (" (" .. table.concat(left, ", ") .. ")") or "")) end
        if pending > 0 then
            print("[HYGE] " .. pending .. " tarefa(s) agendada(s) ainda vão rodar (toasts/animações;"
                .. " se alguma fizer algo, aparece como 'tarefa rodou depois do unload')")
        end
        V8.LastUnload = { status = status, created = V8.Conns.created, closed = V8.Conns.closed,
            active = #left, left = left, pending = pending, running = running, time = os.time() }
        if V8.Disk and V8.Disk.Ok() and V8.Net and V8.Net.Http then
            V8.Disk.Write("HYGE/unload.json", V8.Net.Http:JSONEncode(V8.LastUnload))
        end
    end)
    V8.Unloaded = true
    -- a próxima instância não precisa mais chamar este Unload
    pcall(function()
        local env = (typeof(getgenv) == "function" and getgenv()) or _G
        if env.HYGE_UNLOAD == Unload then env.HYGE_UNLOAD = nil end
    end)

    print("[HYGE] painel descarregado.")
end

-- v9.1: rodar o script de novo SEM descarregar deixava a instância anterior
-- viva (só a GUI dela era destruída: conexões, scheduler e teclas continuavam
-- e as duas reagiam juntas). A próxima instância chama este Unload primeiro
-- (00_core/03_bootstrap.lua).
pcall(function()
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    env.HYGE_UNLOAD = Unload
end)

end)
V8.Mod("src/90_runtime/07_boot.lua", 17499, 17582, function() --------------------------------------------------------------------------------
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
    -- v8.1: funções marcadas em Configurações › Automático (depois da config)
    BootStep("Automático",    function() if V8.Auto then V8.Auto.Run() end end)
    -- v9.0: perfil marcado para este jogo (ganha da config e do Automático)
    BootStep("Perfil do jogo", function() if V8.Prof then V8.Prof.Boot() end end)
    BootStep("Cosméticos",    function() if V8.Cos then V8.Cos.Apply() end end)
    -- v8.2: pacote salvo no personagem, missões/bônus diário, tela do celular
    -- e conferência de versão nova (todos depois da config carregada)
    BootStep("Pacote",        function() if V8.Pack then V8.Pack.Boot() end end)
    BootStep("Missões",       function() if V8.Quest then V8.Quest.Boot() end end)
    BootStep("Celular",       function() if V8.Mobile then V8.Mobile.Fit() V8.Mobile.Render() end end)
    BootStep("Atualização",   function() if V8.Update then V8.Update.Boot() end end)
    BootStep("Voo",           function() if V8.FlyStyleRender then V8.FlyStyleRender() end end)
    -- v9.0: a lista de amigos é uma chamada web (espera a resposta): vai em
    -- paralelo, o painel abre sem esperar por ela
    BootStep("Friends",       function()
        if V8.Dash then task.spawn(function() pcall(V8.Dash.Friends, true) end) end
    end)
    BootStep("SetOpen",       function() SetOpen(true) end)
    -- v8.0: em tela baixa a janela "acima do dock" pode nascer cortada
    BootStep("Janela",        function() if V8.Win then task.defer(V8.Win.Clamp) end end)
    -- v9.0: cartão de novidades (uma vez por versão)
    BootStep("Novidades",     function() if V8.News then V8.News.Boot() end end)

    -- v9.0: módulos que quebraram ao carregar (o resto do painel abriu)
    local modFails = {}
    for _, m in ipairs(V8.Mods) do
        if not m.ok then
            table.insert(modFails, (m.name:gsub("^src/", "")))
            Log("Módulo " .. m.name .. " não carregou: " .. tostring(m.err), "error")
        end
    end
    if #modFails > 0 then
        table.insert(falhas, #modFails .. " módulo(s): " .. table.concat(modFails, ", "))
    end
    V8.BootMs = (os.clock() - (V8.BootT0 or os.clock())) * 1000
    -- v9.1: conexões vivas logo depois do boot (base para o monitor de respawn)
    pcall(function()
        local n = 0
        for _ in pairs(V8.Conns.live) do n = n + 1 end
        V8.Conns.boot = n
    end)

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
        Toast("Boot parcial — veja Configurações › Diagnóstico", "error", 5)
    else
        Log(string.format("Boot em %d ms (%d módulos isolados)", math.floor(V8.BootMs), #V8.Mods), "ok")
        Toast("HYGE " .. CONFIG.Version .. " pronto — aperte " .. KeyName(CONFIG.PanelKey), "ok", 4)
    end
end
end)
V8.SrcMap = { { "src/00_core/00_header.lua", 6, 81 }, { "src/00_core/01_config.lua", 82, 190 }, { "src/00_core/02_theme.lua", 191, 304 }, { "src/00_core/03_bootstrap.lua", 305, 382 }, { "src/00_core/04_state.lua", 383, 690 }, { "src/00_core/05_helpers.lua", 691, 732 }, { "src/10_ui/00_window.lua", 733, 781 }, { "src/10_ui/01_toasts.lua", 782, 925 }, { "src/10_ui/02_console.lua", 926, 1146 }, { "src/10_ui/03_topbar_sidebar.lua", 1147, 1292 }, { "src/10_ui/04_factory.lua", 1293, 1597 }, { "src/10_ui/05_toggles_keybinds.lua", 1598, 1910 }, { "src/20_features/00_fly.lua", 1911, 2339 }, { "src/20_features/01_character.lua", 2340, 2471 }, { "src/20_features/02_esp.lua", 2472, 2798 }, { "src/20_features/03_world.lua", 2799, 2870 }, { "src/20_features/04_freecam.lua", 2871, 2952 }, { "src/20_features/05_drone.lua", 2953, 3069 }, { "src/20_features/06_actions.lua", 3070, 3252 }, { "src/20_features/07_spectate.lua", 3253, 3302 }, { "src/20_features/08_spectate_hud.lua", 3303, 3377 }, { "src/20_features/09_body.lua", 3378, 3524 }, { "src/20_features/10_wallwalk.lua", 3525, 3805 }, { "src/20_features/11_clicktp.lua", 3806, 3860 }, { "src/30_kit/00_widgets.lua", 3861, 4318 }, { "src/30_kit/01_icons.lua", 4319, 4437 }, { "src/30_kit/02_topbar_chips.lua", 4438, 4518 }, { "src/30_kit/03_drone_hud.lua", 4519, 4907 }, { "src/30_kit/04_net.lua", 4908, 5138 }, { "src/30_kit/05_playtime.lua", 5139, 5637 }, { "src/30_kit/06_animpack.lua", 5638, 6163 }, { "src/30_kit/07_sha256.lua", 6164, 6258 }, { "src/30_kit/08_profile_tx.lua", 6259, 6421 }, { "src/40_tabs/00_home.lua", 6422, 6757 }, { "src/40_tabs/01_home_dashboard.lua", 6758, 7326 }, { "src/40_tabs/01_home_server.lua", 7327, 7601 }, { "src/40_tabs/02_movement.lua", 7602, 7935 }, { "src/40_tabs/02_movement_pack.lua", 7936, 8122 }, { "src/40_tabs/03_visuals.lua", 8123, 8217 }, { "src/40_tabs/04_players.lua", 8218, 8463 }, { "src/40_tabs/05_moderation.lua", 8464, 8656 }, { "src/40_tabs/06_server.lua", 8657, 8791 }, { "src/40_tabs/07_emotes.lua", 8792, 9385 }, { "src/40_tabs/08_settings.lua", 9386, 9820 }, { "src/40_tabs/09_shop.lua", 9821, 10145 }, { "src/40_tabs/10_scripts.lua", 10146, 10221 }, { "src/40_tabs/11_chat.lua", 10222, 10352 }, { "src/40_tabs/12_troll.lua", 10353, 10542 }, { "src/40_tabs/13_hychat.lua", 10543, 10924 }, { "src/50_v8/00_dock.lua", 10925, 11392 }, { "src/50_v8/01_shell.lua", 11393, 11782 }, { "src/50_v8/02_situations.lua", 11783, 12123 }, { "src/50_v8/03_persist.lua", 12124, 12720 }, { "src/50_v8/04_search.lua", 12721, 13180 }, { "src/50_v8/05_island.lua", 13181, 13316 }, { "src/50_v8/06_auto.lua", 13317, 13400 }, { "src/50_v8/07_mobile.lua", 13401, 13621 }, { "src/50_v8/08_quests.lua", 13622, 13887 }, { "src/50_v8/09_update.lua", 13888, 14148 }, { "src/50_v8/10_profiles.lua", 14149, 14588 }, { "src/50_v8/11_notify.lua", 14589, 14910 }, { "src/50_v8/12_colors.lua", 14911, 15074 }, { "src/50_v8/13_macros.lua", 15075, 15337 }, { "src/50_v8/14_diag.lua", 15338, 15643 }, { "src/50_v8/15_news.lua", 15644, 15842 }, { "src/50_v8/19_settings_nav.lua", 15843, 16025 }, { "src/90_runtime/00_status_nav.lua", 16026, 16060 }, { "src/90_runtime/01_commands.lua", 16061, 16803 }, { "src/90_runtime/02_window_ctl.lua", 16804, 17021 }, { "src/90_runtime/03_input.lua", 17022, 17172 }, { "src/90_runtime/04_scheduler.lua", 17173, 17280 }, { "src/90_runtime/05_events.lua", 17281, 17400 }, { "src/90_runtime/06_unload.lua", 17401, 17498 }, { "src/90_runtime/07_boot.lua", 17499, 17583 } }
