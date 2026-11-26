--------------------------------------------------------------------------------
-- v9.3 — ESTILO DAS BARRAS DO HUD
-- Um visual só para as barras que ficam por cima do jogo: a ilha do topo
-- (status), o dock (navegação), a alça de recolher o dock e a moldura atrás
-- da barra do Roblox. Vidro escuro azulado + azul neon discreto.
-- As cores são fixas (não seguem o tema do painel): as barras têm identidade
-- própria por cima de qualquer jogo. O "H" da ilha continua com a cor do tema.
-- O Roblox não tem desfoque de UI: o "vidro" é transparência + degradê +
-- borda mais clara em cima.
-- Tudo em V8.Hud: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
-- [hud:begin] (tests/hud.test.js roda este bloco)
do
    V8.Hud = {}
    local U = V8.Hud

    U.C = {
        Glass    = Color3.fromRGB(11, 17, 32),     -- fundo escuro azulado
        GlassT   = 0.24,                           -- transparência do fundo
        Neon     = Color3.fromRGB(56, 182, 255),   -- destaque
        Icon     = Color3.fromRGB(255, 255, 255),  -- ícone ativo / em foco
        IconDim  = Color3.fromRGB(178, 192, 214),  -- ícone em repouso
        Text     = Color3.fromRGB(240, 246, 255),
        Dim      = Color3.fromRGB(150, 168, 196),
        Sep      = Color3.fromRGB(255, 255, 255),  -- separadores da ilha
        SepT     = 0.85,
        Warn     = Color3.fromRGB(255, 196, 92),
        Bad      = Color3.fromRGB(255, 98, 112),
    }
    U.C.Good = U.C.Neon

    -- qualidade da conexão pelo ping (ms, ida e volta, o mesmo da ilha):
    -- devolve barras acesas (0-4), cor (chave em U.C) e o nome
    U.Quality = function(ping)
        if type(ping) ~= "number" or ping ~= ping or ping < 0 or ping == math.huge then
            return 0, "Dim", "sem dado"
        end
        if ping <= 80 then return 4, "Good", "excelente" end
        if ping <= 150 then return 3, "Good", "boa" end
        if ping <= 280 then return 2, "Warn", "instável" end
        return 1, "Bad", "ruim"
    end

    -- FPS só ganha cor quando pede atenção
    U.FpsKey = function(fps)
        if type(fps) ~= "number" or fps ~= fps then return "Text" end
        if fps >= 50 then return "Text" end
        if fps >= 30 then return "Warn" end
        return "Bad"
    end
end
-- [hud:end]

do
    local U = V8.Hud
    local C = U.C

    -- vidro: fundo + degradê (claro em cima) + borda neon que some para baixo.
    -- Reaproveita UICorner/UIStroke que a barra já tiver. Devolve o UIStroke.
    U.Glass = function(f, radius)
        f.BackgroundColor3 = C.Glass
        f.BackgroundTransparency = C.GlassT
        f.BorderSizePixel = 0
        local corner = f:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", f)
        corner.CornerRadius = UDim.new(0, radius or 14)

        local g = f:FindFirstChild("HudGlass") or Instance.new("UIGradient")
        g.Name = "HudGlass"
        g.Rotation = 90
        g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 206, 226))
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.1) })
        g.Parent = f

        local st = f:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", f)
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Color = C.Neon
        st.Thickness = 1
        st.Transparency = 0.55
        local sg = st:FindFirstChild("HudGlow") or Instance.new("UIGradient")
        sg.Name = "HudGlow"
        sg.Rotation = 90
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.65) })
        sg.Parent = st
        return st
    end

    -- tween curto que respeita "Animações" (Configurações › Aparência)
    U.Tween = function(inst, dur, props)
        if not SET.Animations then
            for k, v in pairs(props) do inst[k] = v end
            return nil
        end
        local t = TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out), props)
        t:Play()
        return t
    end
end
