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

