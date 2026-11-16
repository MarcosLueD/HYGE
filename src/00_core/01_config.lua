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
    Version   = "v8.1.1",
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

    -- ANIMAÇÃO DO VOO (v8.1.1). O Fly escolhe nesta ordem:
    --   1. FlyAnimR6 / FlyAnimR15: animação SUA publicada. Só carrega em jogo
    --      seu ou do seu grupo (em jogo de outros o Roblox recusa).
    --      FlyAnimIdle (opcional) = sua animação para parado no ar.
    --   2. FlyStyle = "jogo" (padrão): as animações do PRÓPRIO personagem —
    --      nadar enquanto voa (o corpo deita na direção do voo) e flutuar/cair
    --      parado. Carregam em qualquer jogo e TODO MUNDO vê. Só R15 tem a de
    --      nadar; em R6 cai na pose (4). Dá para trocar em Personagem.
    --   3. FlyStyle = "pacote": Endless Aura (FlyPackMove/FlyPackIdle, abaixo)
    --   4. pose procedural (FlyUsePose): reserva. Escreve direto nas juntas no
    --      SEU cliente — só você vê; os outros veem o personagem parado.
    FlyAnimR6   = "",
    FlyAnimR15  = "",
    FlyAnimIdle = "",
    FlyAnimSpeed = 1,
    FlyStyle    = "jogo",   -- "jogo" | "pose" | "pacote"
    FlySwimTilt = 75,       -- graus que o corpo deita voando no estilo "jogo"

    -- Pacote "Endless Aura Floating Pack" (bundle 4899847411546). Os IDs
    -- abaixo ficam guardados pra quando/se o dono do jogo (ou o grupo HYGE)
    -- republicar os assets — hoje o Roblox RECUSA carregar animação de
    -- terceiro (o próprio catálogo marca isPurchasable=false/isOffSale=true
    -- pra esses dois IDs) e a track carrega com Length 0, sem animar nada.
    -- Move = catalog 74203422263286 ("Fall Animation" do pacote)
    -- Idle = catalog 75638427965557 ("Idle Animation" do pacote)
    FlyPackMove = "rbxassetid://74203422263286",
    FlyPackIdle = "rbxassetid://75638427965557",
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

