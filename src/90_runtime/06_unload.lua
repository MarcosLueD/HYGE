--------------------------------------------------------------------------------
-- UNLOAD (desfaz tudo)
--------------------------------------------------------------------------------
Unload = function()
    Log("Descarregando...", "warn")
    -- v8.0: captura de keybind em andamento tinha conexão fora de Conn
    pcall(StopCapture)

    -- v8.0: salva a configuração antes de derrubar tudo (se o autosave estiver ligado)
    pcall(function()
        if V8.Cfg and SET.AutoSave then V8.Cfg.Save(true) end
    end)

    for _, id in ipairs(ToggleOrder) do
        if IsOn(id) then pcall(Toggles[id].disable) end
    end
    pcall(StopSpectate)
    pcall(ClearEsp)
    pcall(function() Emote.Stop(true) end)

    for name in pairs(Conn) do pcall(Drop, name) end
    for _, inst in ipairs(Bin) do pcall(function() inst:Destroy() end) end

    pcall(function()
        local h = Hum()
        if h then
            h.WalkSpeed = 16
            h.UseJumpPower = true
            h.JumpPower = 50
            h.PlatformStand = false
        end
    end)
    pcall(function() RunService:UnbindFromRenderStep("HYGE_FlyPose") end)
    pcall(function() Gui:Destroy() end)

    for i = #Bin, 1, -1 do Bin[i] = nil end
    for i = #Painted, 1, -1 do Painted[i] = nil end
    for k in pairs(Esp) do Esp[k] = nil end
    for k in pairs(Keybinds) do Keybinds[k] = nil end
    for i = #State.Waypoints, 1, -1 do State.Waypoints[i] = nil end
    for i = #State.CmdHistory, 1, -1 do State.CmdHistory[i] = nil end
    State.SelectedPlayer = nil
    State.SpectateTarget = nil

    print("[HYGE] painel descarregado.")
end

