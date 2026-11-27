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
    Version   = "v9.4",
    -- quem ABRE o painel neste cliente. Quem pode agir nos outros jogadores é
    -- decidido só pelo servidor (CONFIG.AdminIds do server/HYGE_AdminServer)
    AdminIds  = { LocalPlayer.UserId },  -- << coloque os UserIds dos seus admins
    DefaultTheme = "HYGE",               -- tema de quem nunca salvou config (v9.4: as cores do logo)
    PanelKey  = Enum.KeyCode.B,
    ConsoleKey= Enum.KeyCode.Semicolon,
    UiScale   = 1,
    MaxLog    = 60,

    -- Logo: suba a imagem em create.roblox.com > Development Items > Decals,
    -- copie o ID e cole aqui como "rbxassetid://SEU_ID". Vazio = logo em texto.
    LogoId    = "",
    -- v9.4: a coruja do logo. Suba só a coruja (PNG com fundo transparente)
    -- do mesmo jeito e cole o ID aqui: ela aparece sentada no triângulo da
    -- faixa do Início, como no logo. Vazio = sem coruja.
    MascotId  = "",

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

