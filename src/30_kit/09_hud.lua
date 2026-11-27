--------------------------------------------------------------------------------
-- v9.3 — ESTILO DAS BARRAS DO HUD
-- Um visual só para as barras que ficam por cima do jogo: a ilha do topo
-- (status), o dock (navegação), a alça de recolher o dock e a moldura atrás
-- da barra do Roblox. Pílulas de vidro azul-marinho com borda neon e um
-- brilho em volta.
-- As cores são fixas (não seguem o tema do painel): as barras têm identidade
-- própria por cima de qualquer jogo. A marca da ilha segue a cor do tema.
-- v9.4: as cores do logo — vidro índigo e neon rosa (era azul na v9.3).
-- O Roblox não tem desfoque nem sombra de UI: o "vidro" é transparência +
-- degradê, e o brilho são contornos neon bem transparentes (U.Halo).
-- Tudo em V8.Hud: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
-- [hud:begin] (tests/hud.test.js roda este bloco)
do
    V8.Hud = {}
    local U = V8.Hud

    U.C = {
        Glass    = Color3.fromRGB(13, 10, 40),     -- fundo índigo (o miolo do logo)
        GlassT   = 0.12,                           -- transparência do fundo
        Neon     = Color3.fromRGB(255, 64, 200),   -- borda, brilho e seção ativa (o rosa do logo)
        StrokeT  = 0.05,                           -- transparência da borda
        Icon     = Color3.fromRGB(255, 255, 255),  -- ícone em foco
        IconDim  = Color3.fromRGB(214, 210, 240),  -- ícone em repouso
        Text     = Color3.fromRGB(248, 244, 255),
        Dim      = Color3.fromRGB(164, 158, 212),
        Sep      = Color3.fromRGB(255, 255, 255),  -- separadores (ilha e dock)
        SepT     = 0.8,
        Good     = Color3.fromRGB(92, 222, 104),   -- conexão boa: verde
        Warn     = Color3.fromRGB(255, 196, 92),
        Bad      = Color3.fromRGB(255, 98, 112),
    }

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

    U.PILL = UDim.new(1, 0)   -- canto de pílula (as pontas são meio círculo)

    -- vidro: fundo + degradê (um pouco mais claro em cima) + borda neon.
    -- radius: pixels ou um UDim (U.PILL). Reaproveita UICorner/UIStroke que a
    -- barra já tiver. Devolve o UIStroke.
    U.Glass = function(f, radius)
        f.BackgroundColor3 = C.Glass
        f.BackgroundTransparency = C.GlassT
        f.BorderSizePixel = 0
        local corner = f:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", f)
        corner.CornerRadius = (typeof(radius) == "UDim") and radius or UDim.new(0, radius or 14)

        local g = f:FindFirstChild("HudGlass") or Instance.new("UIGradient")
        g.Name = "HudGlass"
        g.Rotation = 90
        g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 200, 230))
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.06) })
        g.Parent = f

        local st = f:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", f)
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Color = C.Neon
        st.Thickness = 1.5
        st.Transparency = C.StrokeT
        local sg = st:FindFirstChild("HudGlow") or Instance.new("UIGradient")
        sg.Name = "HudGlow"
        sg.Rotation = 90
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.2) })
        sg.Parent = st
        return st
    end

    -- brilho neon em volta de uma barra em pílula: dois contornos bem
    -- transparentes (um largo, um estreito) numa moldura IRMÃ da barra, logo
    -- atrás dela. Irmã e não filha: as barras têm UIListLayout, que poria a
    -- moldura na fila dos ícones. Copia posição e âncora da barra e o tamanho
    -- REAL dela (já com a escala do celular, que é aplicada a partir da
    -- âncora); some junto com ela. Chamar com a barra já num Parent.
    -- Devolve { frame, outer, inner } (os dois UIStroke, para o hover).
    U.Halo = function(f)
        if not f.Parent then return nil end
        local h = Instance.new("Frame")
        h.Name = f.Name .. "Halo"
        h.BackgroundTransparency = 1
        h.BorderSizePixel = 0
        h.Active = false
        h.ZIndex = math.max(1, f.ZIndex - 1)
        local function Ring(obj, thick, tr)
            Instance.new("UICorner", obj).CornerRadius = U.PILL
            local st = Instance.new("UIStroke", obj)
            st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            st.Color = C.Neon
            st.Thickness = thick
            st.Transparency = tr
            return st
        end
        local inner = Instance.new("Frame")
        inner.Name = "Inner"
        inner.Size = UDim2.new(1, 0, 1, 0)
        inner.BackgroundTransparency = 1
        inner.BorderSizePixel = 0
        inner.Active = false
        inner.ZIndex = h.ZIndex
        inner.Parent = h
        local r = { frame = h, outer = Ring(h, 7, 0.9), inner = Ring(inner, 3.5, 0.76) }
        local function Sync()
            local s = f.AbsoluteSize
            h.AnchorPoint = f.AnchorPoint
            h.Position = f.Position
            h.Size = UDim2.new(0, s.X, 0, s.Y)
            h.Visible = f.Visible and s.X > 0 and s.Y > 0
        end
        for _, p in ipairs({ "AbsoluteSize", "Position", "AnchorPoint", "Visible" }) do
            f:GetPropertyChangedSignal(p):Connect(Sync)
        end
        Sync()
        h.Parent = f.Parent
        return r
    end

    -- hover de uma barra com brilho: borda e brilho acendem um pouco
    U.Lit = function(stroke, halo, on)
        if stroke then U.Tween(stroke, 0.14, { Transparency = on and 0 or C.StrokeT }) end
        if halo then
            U.Tween(halo.inner, 0.14, { Transparency = on and 0.6 or 0.76 })
            U.Tween(halo.outer, 0.14, { Transparency = on and 0.84 or 0.9 })
        end
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
