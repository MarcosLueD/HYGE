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

