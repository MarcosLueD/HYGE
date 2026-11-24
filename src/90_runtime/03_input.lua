--------------------------------------------------------------------------------
-- INPUT GLOBAL (teclas)
--------------------------------------------------------------------------------
-- v8.0: teclas que cada modo usa para se mover. Com o modo ligado, um atalho
-- nessa tecla NÃO dispara (antes: subir com E no freecam/drone ligava o ESP).
-- O atalho do próprio modo continua valendo (ex.: G desliga o drone).
V8.ModeKeys = {
    freecam = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.LeftShift },
    drone   = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.LeftShift,
                Enum.KeyCode.LeftControl },
    fly     = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },
    -- v8.1
    wallwalk = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
                 Enum.KeyCode.Space },
}
V8.KeyWarned = {}

-- devolve o modo que está usando a tecla (ou nil). 'self' = toggle que o
-- atalho dispararia: ele nunca bloqueia a si mesmo.
V8.KeyBusy = function(kc, selfId)
    for mode, keys in pairs(V8.ModeKeys) do
        if mode ~= selfId and IsOn(mode) then
            for _, k in ipairs(keys) do
                if k == kc then return mode end
            end
        end
    end
    return nil
end

Conn.Input = UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if capturing then return end   -- está capturando um keybind na aba Settings

    if input.KeyCode == Enum.KeyCode.Escape and CmdBar.Visible then
        ToggleCmdBar(false)
        return
    end
    if gpe then return end

    if input.KeyCode == CONFIG.PanelKey then
        SetOpen(not isOpen)
        return
    end
    if input.KeyCode == CONFIG.ConsoleKey then
        ToggleCmdBar(not CmdBar.Visible)
        return
    end
    -- v8.0: busca global (Ctrl+K) e atalhos das situações (Keypad 1-6)
    if V8.Search and V8.Search.HandleKey(input) then return end
    if V8.Sit and V8.Sit.HandleKey(input) then return end
    -- v9.0: macros (tecla -> comando), antes dos atalhos das funções
    if V8.Macro then
        local okM, handled = pcall(V8.Macro.HandleKey, input)
        if okM and handled then return end
    end

    for id, kc in pairs(Keybinds) do
        if kc == input.KeyCode then
            local busy = V8.KeyBusy(kc, id)
            if busy then
                -- avisa uma vez por combinação (sem spam a cada tecla)
                local tag = busy .. ":" .. kc.Name
                if not V8.KeyWarned[tag] then
                    V8.KeyWarned[tag] = true
                    local mode = Toggles[busy] and Toggles[busy].label or busy
                    local who = Toggles[id] and Toggles[id].label or id
                    Log("[" .. KeyName(kc) .. "] ignorada: o " .. mode .. " usa essa tecla "
                        .. "para se mover (o atalho de " .. who .. " volta ao desligar)", "warn")
                end
                return
            end
            Flip(id)
            return
        end
    end
end)

--------------------------------------------------------------------------------
-- v9.0.1: SHIFT LOCK DO ROBLOX
-- Em jogo que libera o Shift Lock, o Shift prende o mouse no centro da tela —
-- inclusive no Fly, que usa o Shift para acelerar. (Freecam e Drone não sofrem:
-- a câmera deles é Scriptable e o próprio HYGE manda no mouse.)
-- Com SET.NoShiftLock (Configurações › Comportamento, padrão ligado) o painel
-- desliga LocalPlayer.DevEnableMouseLock: o PlayerModule solta o mouse na hora
-- e para de ouvir o Shift. Se o jogo religar, desliga de novo. Desligando a
-- opção ou descarregando o painel, volta o valor que o jogo queria.
-- (Shift Lock feito pelo próprio jogo, fora do PlayerModule, não é coberto.)
--------------------------------------------------------------------------------
do
    local SL = { held = false, saved = false, warned = false }
    V8.ShiftLock = SL

    local function Get()
        local ok, v = pcall(function() return LocalPlayer.DevEnableMouseLock end)
        if ok then return v end
        return nil
    end
    local function Set(v)
        return pcall(function() LocalPlayer.DevEnableMouseLock = v end)
    end

    -- devolve o Shift Lock como o jogo deixou (opção desligada / unload)
    SL.Release = function()
        if not SL.held then return end
        SL.held = false
        if SL.saved then Set(true) end
        SL.saved = false
    end

    SL.Sync = function()
        if SL.dead then return end
        if SET.NoShiftLock == false then
            SL.Release()
            return
        end
        local cur = Get()
        if cur == nil then return end
        if not SL.held then SL.held, SL.saved = true, cur end
        if cur then
            -- ligado (pelo jogo no começo ou religado depois): guarda e desliga
            SL.saved = true
            if not Set(false) and not SL.warned then
                SL.warned = true
                Log("Não deu para bloquear o Shift Lock neste executor", "warn")
            end
        end
    end

    -- o jogo mexeu na propriedade: confere de novo (Set(false) aqui dentro
    -- dispara o sinal outra vez, mas aí já está false e não faz nada)
    pcall(function()
        Conn.ShiftLock = LocalPlayer:GetPropertyChangedSignal("DevEnableMouseLock")
            :Connect(function() pcall(SL.Sync) end)
    end)
    -- unload: para de vigiar ANTES de devolver (senão o sinal desligaria de novo)
    SL.Stop = function()
        SL.dead = true
        Drop("ShiftLock")
        SL.Release()
    end
    -- config / perfil carregado ou "restaurar padrões" mudaram SET.NoShiftLock
    V8.Renders = V8.Renders or {}
    table.insert(V8.Renders, function() pcall(SL.Sync) end)
    SL.Sync()
end

