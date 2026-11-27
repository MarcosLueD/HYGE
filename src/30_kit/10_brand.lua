--------------------------------------------------------------------------------
-- v9.4 — IDENTIDADE VISUAL (o logo dentro do painel)
-- O logo: fundo azul, triângulo azul-marinho com contorno rosa neon, "HYGE"
-- em rosa com brilho e a coruja. Peças reutilizáveis, todas em V8.Brand:
--   Tri(parent, w, o)    triângulo neon (contorno + brilho + miolo opcional)
--   Word(parent, size)   "HYGE" em degradê rosa → lilás, com contorno e brilho
--   Mark(parent, size)   a marca pequena: triângulo + H (ou CONFIG.LogoId)
--   Glow(frame, radius)  borda neon por fora de uma moldura (janela, cartões)
--   Wash(frame, radius)  véu da cor secundária no alto de uma moldura
--   Hero(parent, order)  faixa do Início: o logo refeito em UI
-- As cores seguem o tema (Accent = contorno/palavra, Accent2 = véu): no tema
-- HYGE ficam iguais às do logo; nos outros, na cor de cada um.
-- O Roblox não desenha triângulo nem sombra de UI: o contorno são 3 Frames
-- girados com pontas redondas (as pontas se encontram e viram cantos
-- arredondados), o miolo são faixas horizontais escondidas embaixo do
-- contorno e o brilho são UIStroke bem transparentes por fora.
-- Tudo em V8.Brand: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
-- [brand:begin] (tests/brand.test.js roda este bloco)
do
    V8.Brand = {}
    local B = V8.Brand

    -- Triângulo equilátero, ponta para cima, dentro de uma caixa de largura w,
    -- com traço de espessura t. O traço inteiro (pontas redondas incluídas)
    -- cabe na caixa. Devolve:
    --   altura da caixa,
    --   os 3 traços { centro x, centro y, comprimento, rotação em graus }
    --     (rotação no sentido horário, como a Rotation do Roblox),
    --   os 3 vértices { x, y } (base esq., base dir., topo) na linha do traço.
    -- Cada traço vai de um vértice ao outro com meia espessura a mais em cada
    -- ponta: com o canto redondo, as pontas viram círculos centrados nos
    -- vértices e os dois traços se encontram sem dente.
    B.TriGeom = function(w, t)
        t = t or 2
        local c = w - t                       -- lado do triângulo (linha do traço)
        local h = c * math.sqrt(3) / 2 + t
        local yb, yt = h - t / 2, t / 2
        local xl, xr, xm = t / 2, w - t / 2, w / 2
        return h, {
            { xm, yb, c + t, 0 },                              -- base
            { (xl + xm) / 2, (yb + yt) / 2, c + t, -60 },      -- esquerda
            { (xm + xr) / 2, (yb + yt) / 2, c + t, 60 },       -- direita
        }, { { xl, yb }, { xr, yb }, { xm, yt } }
    end

    -- Miolo em faixas horizontais de altura step (a última pode ser menor).
    -- Cada faixa tem a largura do triângulo no meio dela; o degrau que sobra
    -- (menos de meio traço de cada lado) fica embaixo do contorno.
    -- Devolve { { y, altura, largura } } a partir do topo da caixa, centradas.
    B.TriFill = function(w, t, step)
        local _, _, v = B.TriGeom(w, t)
        step = step or 3
        local top, base = v[3][2], v[1][2]
        local c = w - (t or 2)
        local out, y = {}, top
        while y < base - 1e-9 do
            local hh = math.min(step, base - y)
            local mid = y + hh / 2
            table.insert(out, { y, hh, c * (mid - top) / (base - top) })
            y = y + hh
        end
        return out
    end

    -- "v9.3" / "9.4" / "v9.4.1" -> { 9, 3, 0 } (nil se não for versão)
    B.Ver = function(v)
        if type(v) ~= "string" then return nil end
        local a, b, c = v:match("^v?(%d+)%.(%d+)%.?(%d*)")
        if not a then return nil end
        return { tonumber(a), tonumber(b), tonumber(c) or 0 }
    end

    -- v é anterior a ref? (versão ilegível: não é)
    B.Older = function(v, ref)
        local x, y = B.Ver(v), B.Ver(ref)
        if not x or not y then return false end
        for i = 1, 3 do
            if x[i] ~= y[i] then return x[i] < y[i] end
        end
        return false
    end

    -- Tema ao carregar a config do disco. Quem estava no padrão antigo
    -- (Grafite) e salvou antes da v9.4 passa UMA vez para o tema do logo; a
    -- próxima gravação já sai com a versão nova, então quem voltar para o
    -- Grafite depois fica nele. Devolve (tema, mudou?).
    B.NEW_DEFAULT, B.OLD_DEFAULT, B.SINCE = "HYGE", "Grafite", "v9.4"
    B.ThemeFor = function(theme, version)
        if theme == B.OLD_DEFAULT and (version == nil or B.Older(version, B.SINCE)) then
            return B.NEW_DEFAULT, true
        end
        return theme, false
    end
end
-- [brand:end]

do
    local B = V8.Brand
    B.ROYAL = Color3.fromRGB(44, 40, 196)   -- o azul do fundo do logo (faixa do Início)
    B.Pulses = {}                             -- { stroke, base, peak } que "respiram"

    -- troca de tema: o que não cabe no registry Paint (degradês) se repinta aqui
    local function OnTheme(fn)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, fn)
        pcall(fn)
    end

    local function Stroke(parent, thick, transp, key)
        local st = Instance.new("UIStroke")
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.Thickness = thick
        st.Transparency = transp
        st.Parent = parent
        Paint(st, "Color", key or "Accent")
        return st
    end

    ----------------------------------------------------------------------------
    -- triângulo neon. o = { thick, glow (true), glowSize, fill (chave do tema
    -- ou nil), fillT, z, pulse }. Devolve a caixa e os UIStroke do brilho.
    ----------------------------------------------------------------------------
    B.Tri = function(parent, w, o)
        o = o or {}
        local t = o.thick or math.max(2, math.floor(w / 18 + 0.5))
        local h, edges = B.TriGeom(w, t)
        local z = o.z or 1
        local box = Instance.new("Frame")
        box.Name = "NeonTri"
        box.Size = UDim2.new(0, w, 0, math.ceil(h))
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Active = false
        box.ZIndex = z
        box.Parent = parent

        if o.fill then
            for _, f in ipairs(B.TriFill(w, t, 3)) do
                local band = Instance.new("Frame")
                band.AnchorPoint = Vector2.new(0.5, 0)
                band.Position = UDim2.new(0, w / 2, 0, f[1])
                band.Size = UDim2.new(0, f[3], 0, f[2] + 0.5)   -- +0.5: sem fresta entre faixas
                band.BackgroundTransparency = o.fillT or 0
                band.BorderSizePixel = 0
                band.ZIndex = z
                band.Parent = box
                Paint(band, "BackgroundColor3", o.fill)
            end
        end

        local glows = {}
        for _, e in ipairs(edges) do
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.new(0, e[1], 0, e[2])
            f.Size = UDim2.new(0, e[3], 0, t)
            f.Rotation = e[4]
            f.BorderSizePixel = 0
            f.ZIndex = z + 1
            f.Parent = box
            Paint(f, "BackgroundColor3", o.color or "Accent")
            Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
            if o.glow ~= false then
                local st = Stroke(f, o.glowSize or math.max(2, t * 1.4), 0.62, o.color)
                table.insert(glows, st)
                if o.pulse then table.insert(B.Pulses, { st, 0.62, 0.38 }) end
            end
        end
        return box, glows, h, t
    end

    ----------------------------------------------------------------------------
    -- "HYGE" do logo: letras grossas em degradê rosa → lilás, contorno escuro
    -- fino (como o adesivo do logo) e um brilho rosa atrás (uma cópia do texto
    -- transparente com contorno largo). Moldura com largura automática.
    ----------------------------------------------------------------------------
    B.Word = function(parent, size, text)
        local box = Instance.new("Frame")
        box.Name = "BrandWord"
        box.AutomaticSize = Enum.AutomaticSize.X
        box.Size = UDim2.new(0, 0, 0, size + 6)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Active = false
        box.Parent = parent

        local function Lbl(z)
            local l = Instance.new("TextLabel")
            l.AutomaticSize = Enum.AutomaticSize.X
            l.Size = UDim2.new(0, 0, 1, 0)
            l.BackgroundTransparency = 1
            l.Text = text or "HYGE"
            l.Font = Enum.Font.GothamBlack
            l.TextSize = size
            l.ZIndex = z
            l.Parent = box
            return l
        end

        local glow = Lbl(box.ZIndex)
        glow.Name = "Glow"
        glow.TextTransparency = 0.55
        Paint(glow, "TextColor3", "Accent")
        local gs = Instance.new("UIStroke", glow)   -- texto: contorno das letras
        gs.Thickness = math.max(2, size / 6)
        gs.Transparency = 0.84
        Paint(gs, "Color", "Accent")

        local main = Lbl(box.ZIndex + 1)
        main.Name = "Text"
        main.TextColor3 = Color3.new(1, 1, 1)   -- quem pinta é o degradê
        local ms = Instance.new("UIStroke", main)
        ms.Thickness = math.max(1, size / 16)
        ms.Transparency = 0.3
        Paint(ms, "Color", "Main")
        local g = Instance.new("UIGradient", main)
        g.Rotation = 20
        OnTheme(function()
            g.Color = ColorSequence.new(THEME.Accent, THEME.Accent:Lerp(THEME.Accent2, 0.5))
        end)
        return box
    end

    -- muda o ZIndex das duas camadas da palavra juntas (brilho atrás)
    B.ZWord = function(word, z)
        for _, c in ipairs(word:GetChildren()) do
            if c:IsA("TextLabel") then c.ZIndex = z + (c.Name == "Text" and 1 or 0) end
        end
    end

    ----------------------------------------------------------------------------
    -- marca pequena (cabeçalho, ilha, novidades): triângulo neon com miolo
    -- escuro e um H claro dentro. Com CONFIG.LogoId, a imagem da marca.
    ----------------------------------------------------------------------------
    B.Mark = function(parent, size, z)
        z = z or 1
        local box = Instance.new("Frame")
        box.Name = "BrandMark"
        box.Size = UDim2.new(0, size, 0, size)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Active = false
        box.ZIndex = z
        box.Parent = parent

        if CONFIG.LogoId ~= "" then
            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, 0, 1, 0)
            img.BackgroundTransparency = 1
            img.Image = CONFIG.LogoId
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = z + 1
            img.Parent = box
            return box
        end

        local t = math.max(2, math.floor(size / 12 + 0.5))
        local tri, _, h = B.Tri(box, size, { thick = t, glowSize = t, fill = "Main",
            fillT = 0.05, z = z + 1 })
        tri.AnchorPoint = Vector2.new(0.5, 0.5)
        tri.Position = UDim2.new(0.5, 0, 0.5, 0)

        -- o H no centro do triângulo (2/3 da altura, a partir da ponta)
        local cy = t / 2 + (h - t) * 2 / 3
        local hl = Instance.new("TextLabel")
        hl.AnchorPoint = Vector2.new(0.5, 0.5)
        hl.Position = UDim2.new(0.5, 0, 0, cy + 0.5)
        hl.Size = UDim2.new(0, size, 0, size)
        hl.BackgroundTransparency = 1
        hl.Text = "H"
        hl.Font = Enum.Font.GothamBlack
        hl.TextSize = math.max(8, math.floor(size * 0.36))
        hl.ZIndex = z + 3
        hl.Parent = tri
        Paint(hl, "TextColor3", "Text")
        return box
    end

    ----------------------------------------------------------------------------
    -- borda neon por fora de uma moldura: dois anéis (largo e bem fraco,
    -- estreito e mais forte), filhos com o mesmo tamanho e o mesmo canto. O
    -- UIStroke desenha por FORA da borda, então nada cobre o conteúdo; ZIndex
    -- 0 deixa tudo da moldura por cima. Devolve a lista de anéis.
    ----------------------------------------------------------------------------
    B.Glow = function(f, radius, pulse)
        local rings = {}
        for i, spec in ipairs({ { 10, 0.92, 0.84 }, { 4, 0.78, 0.66 } }) do
            local r = Instance.new("Frame")
            r.Name = "NeonGlow" .. i
            r.Size = UDim2.new(1, 0, 1, 0)
            r.BackgroundTransparency = 1
            r.BorderSizePixel = 0
            r.Active = false
            r.ZIndex = 0
            r.Parent = f
            Instance.new("UICorner", r).CornerRadius = UDim.new(0, radius)
            local st = Stroke(r, spec[1], spec[2], "Accent")
            if pulse then table.insert(B.Pulses, { st, spec[2], spec[3] }) end
            rings[i] = r
        end
        return rings
    end

    -- véu da cor secundária no alto (o "azul do fundo do logo" entrando pela
    -- janela). Altura em escala: some junto quando a janela minimiza.
    B.Wash = function(f, radius)
        local w = Instance.new("Frame")
        w.Name = "NeonWash"
        w.Size = UDim2.new(1, 0, 0.34, 0)
        w.BorderSizePixel = 0
        w.Active = false
        w.ZIndex = 0
        w.Parent = f
        Paint(w, "BackgroundColor3", "Accent2")
        Instance.new("UICorner", w).CornerRadius = UDim.new(0, radius)
        local g = Instance.new("UIGradient", w)
        g.Rotation = 90
        g.Transparency = NumberSequence.new(0.83, 1)
        return w
    end

    -- acerta o canto dos anéis / véu (a janela muda de canto entre os modos)
    B.Radius = function(list, radius)
        for _, r in ipairs(list or {}) do
            local c = r and r:FindFirstChildOfClass("UICorner")
            if c then c.CornerRadius = UDim.new(0, radius) end
        end
    end

    ----------------------------------------------------------------------------
    -- FAIXA DO INÍCIO: o logo refeito em UI. À esquerda, a saudação; à
    -- direita, o triângulo com miolo escuro, o "HYGE" por cima (passando das
    -- bordas, como no logo), a bolinha escura e o brilho branco. Com
    -- CONFIG.MascotId, a coruja sentada no canto do triângulo.
    -- Fundo: no tema HYGE, o azul do logo; nos outros, a cor de botão do tema.
    ----------------------------------------------------------------------------
    B.Hero = function(parent, order)
        local H = 96
        local hero = Instance.new("Frame")
        hero.Name = "Card"   -- entra com o mesmo deslize dos outros cartões
        hero.Size = UDim2.new(1, 0, 0, H)
        hero.BorderSizePixel = 0
        hero.LayoutOrder = order or -4
        hero.Parent = parent
        Instance.new("UICorner", hero).CornerRadius = UDim.new(0, 14)
        local edge = Instance.new("UIStroke", hero)
        edge.Color = Color3.new(1, 1, 1)
        edge.Transparency = 0.86
        local g = Instance.new("UIGradient", hero)
        g.Rotation = 18
        g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(140, 140, 160))
        OnTheme(function()
            hero.BackgroundColor3 = (SET.Theme == B.NEW_DEFAULT) and B.ROYAL or THEME.Btn
        end)

        -- saudação
        local hi = Instance.new("TextLabel")
        hi.Position = UDim2.new(0, 18, 0, 22)
        hi.Size = UDim2.new(1, -170, 0, 24)
        hi.BackgroundTransparency = 1
        hi.Text = "Olá, " .. (LocalPlayer.DisplayName or LocalPlayer.Name)
        hi.Font = Enum.Font.GothamBold
        hi.TextSize = 19
        hi.TextXAlignment = Enum.TextXAlignment.Left
        hi.TextTruncate = Enum.TextTruncate.AtEnd
        hi.Parent = hero
        Paint(hi, "TextColor3", "Text")

        local sub = Instance.new("TextLabel")
        sub.Position = UDim2.new(0, 18, 0, 50)
        sub.Size = UDim2.new(1, -170, 0, 16)
        sub.BackgroundTransparency = 1
        sub.Text = "HYGE " .. CONFIG.Version .. "  ·  painel pronto"
        sub.Font = Enum.Font.GothamMedium
        sub.TextSize = 12
        sub.TextTransparency = 0.25
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.Parent = hero
        Paint(sub, "TextColor3", "Text")

        -- o logo, à direita (triângulo de 96 px: ~84 de altura, cabe na faixa)
        local TW = 96
        local logo = Instance.new("Frame")
        logo.Name = "Logo"
        logo.AnchorPoint = Vector2.new(1, 0.5)
        logo.Position = UDim2.new(1, -26, 0.5, 0)
        logo.Size = UDim2.new(0, TW, 0, H - 8)
        logo.BackgroundTransparency = 1
        logo.Active = false
        logo.Parent = hero

        local tri, _, th = B.Tri(logo, TW, { thick = 3, glowSize = 5, fill = "Main",
            fillT = 0.08, z = 2, pulse = true })
        tri.AnchorPoint = Vector2.new(0.5, 0.5)
        tri.Position = UDim2.new(0.5, 0, 0.5, 0)

        local word = B.Word(logo, 25)
        word.AnchorPoint = Vector2.new(0.5, 0.5)
        word.Position = UDim2.new(0.5, 4, 0.5, th * 0.12)
        B.ZWord(word, 6)

        -- bolinha escura (à esquerda do lado de cima) e brilho branco (à
        -- direita), na mesma proporção do logo
        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(0, 20, 0, 26)
        dot.Size = UDim2.new(0, 11, 0, 11)
        dot.BorderSizePixel = 0
        dot.BackgroundTransparency = 0.1
        dot.ZIndex = 2
        dot.Parent = logo
        Paint(dot, "BackgroundColor3", "Main")
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local spark = Instance.new("Frame")
        spark.AnchorPoint = Vector2.new(0.5, 0.5)
        spark.Position = UDim2.new(0, 74, 0, 16)
        spark.Size = UDim2.new(0, 7, 0, 7)
        spark.Rotation = 45
        spark.BackgroundColor3 = Color3.fromRGB(240, 244, 255)
        spark.BorderSizePixel = 0
        spark.ZIndex = 2
        spark.Parent = logo
        Instance.new("UICorner", spark).CornerRadius = UDim.new(0, 2)
        local sg = Instance.new("UIStroke", spark)
        sg.Color = Color3.fromRGB(240, 244, 255)
        sg.Thickness = 2
        sg.Transparency = 0.75

        -- a coruja (opcional): sentada no canto de baixo à esquerda
        if type(CONFIG.MascotId) == "string" and CONFIG.MascotId ~= "" then
            local owl = Instance.new("ImageLabel")
            owl.AnchorPoint = Vector2.new(0.5, 1)
            owl.Position = UDim2.new(0, 12, 1, 2)
            owl.Size = UDim2.new(0, 38, 0, 38)
            owl.BackgroundTransparency = 1
            owl.Image = CONFIG.MascotId
            owl.ScaleType = Enum.ScaleType.Fit
            owl.ZIndex = 8
            owl.Parent = logo
        end

        B.HeroFrame = hero
        return hero
    end

    ----------------------------------------------------------------------------
    -- o brilho "respira" devagar (borda da janela e triângulo da faixa). Sem
    -- loop novo: um job do scheduler a cada 1,8 s. Só com a janela aberta e
    -- "Animações" ligado; desligado, volta ao brilho parado.
    ----------------------------------------------------------------------------
    local up, still = false, true
    V8.Job(1.8, function()
        if not SET.Animations or not Window.Visible then
            if not still then
                still = true
                for _, p in ipairs(B.Pulses) do
                    if p[1].Parent then p[1].Transparency = p[2] end
                end
            end
            return
        end
        still = false
        up = not up
        local info = TweenInfo.new(1.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        for _, p in ipairs(B.Pulses) do
            if p[1].Parent then
                TweenService:Create(p[1], info, { Transparency = up and p[3] or p[2] }):Play()
            end
        end
    end)
end
