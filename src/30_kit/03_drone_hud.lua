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
