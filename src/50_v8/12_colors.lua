--------------------------------------------------------------------------------
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
