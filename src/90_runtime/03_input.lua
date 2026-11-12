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

