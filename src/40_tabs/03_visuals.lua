--------------------------------------------------------------------------------
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
