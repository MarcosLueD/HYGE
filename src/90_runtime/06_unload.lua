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

    -- v8.1: tempo de jogo da Playtime Shop (arquivo próprio, independe do autosave)
    pcall(function() if V8.Play then V8.Play.Save(true) end end)

    for _, id in ipairs(ToggleOrder) do
        if IsOn(id) then pcall(Toggles[id].disable) end
    end
    -- v9.0.1: Shift Lock do Roblox volta como o jogo deixou
    pcall(function() if V8.ShiftLock then V8.ShiftLock.Stop() end end)
    pcall(StopSpectate)
    pcall(ClearEsp)
    pcall(function() Emote.Stop(true) end)
    pcall(function() if V8.Cos then V8.Cos.Clear() end end)   -- v8.1: efeitos/nametag
    -- v8.2: animações originais de volta (SET.PackOn já foi salvo acima)
    pcall(function() if V8.Pack then V8.Pack.Restore() end end)

    -- v9.1: Conn é um proxy — a lista de verdade fica em V8.Conns.live
    local names = {}
    for name in pairs(V8.Conns.live) do table.insert(names, name) end
    for _, name in ipairs(names) do pcall(Drop, name) end
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

    -- v9.1: CONFERÊNCIA DO UNLOAD. Sobrou conexão? Tarefa agendada que ainda
    -- vai rodar, ou rodando (esperando HTTP/wait)? Vai para o console e para
    -- HYGE/unload.json (o Diagnóstico da próxima sessão mostra).
    pcall(function()
        local left = {}
        for name in pairs(V8.Conns.live) do table.insert(left, name) end
        local pending, running = V8.Pending(), V8.Tasks.running
        local clean = (#left == 0 and running == 0)
        local status = clean and "CLEAN" or "SOBROU"
        local msg = string.format("[HYGE] Unload: %s — %d conexões criadas, %d encerradas, %d ativas"
            .. "; tarefas: %d pendentes, %d rodando", status, V8.Conns.created, V8.Conns.closed,
            #left, pending, running)
        if clean then print(msg) else warn(msg .. (#left > 0 and (" (" .. table.concat(left, ", ") .. ")") or "")) end
        if pending > 0 then
            print("[HYGE] " .. pending .. " tarefa(s) agendada(s) ainda vão rodar (toasts/animações;"
                .. " se alguma fizer algo, aparece como 'tarefa rodou depois do unload')")
        end
        V8.LastUnload = { status = status, created = V8.Conns.created, closed = V8.Conns.closed,
            active = #left, left = left, pending = pending, running = running, time = os.time() }
        if V8.Disk and V8.Disk.Ok() and V8.Net and V8.Net.Http then
            V8.Disk.Write("HYGE/unload.json", V8.Net.Http:JSONEncode(V8.LastUnload))
        end
    end)
    V8.Unloaded = true
    -- a próxima instância não precisa mais chamar este Unload
    pcall(function()
        local env = (typeof(getgenv) == "function" and getgenv()) or _G
        if env.HYGE_UNLOAD == Unload then env.HYGE_UNLOAD = nil end
    end)

    print("[HYGE] painel descarregado.")
end

-- v9.1: rodar o script de novo SEM descarregar deixava a instância anterior
-- viva (só a GUI dela era destruída: conexões, scheduler e teclas continuavam
-- e as duas reagiam juntas). A próxima instância chama este Unload primeiro
-- (00_core/03_bootstrap.lua).
pcall(function()
    local env = (typeof(getgenv) == "function" and getgenv()) or _G
    env.HYGE_UNLOAD = Unload
end)

