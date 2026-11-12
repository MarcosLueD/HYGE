--------------------------------------------------------------------------------
-- SCHEDULER ÚNICO (um Heartbeat para todo o painel)
--------------------------------------------------------------------------------
do
    local jobs = {}
    local function Every(interval, fn)
        table.insert(jobs, { i = interval, acc = math.huge, fn = fn })
    end

    local frames, frameClock = 0, 0
    Conn.Loop = RunService.Heartbeat:Connect(function(dt)
        frames = frames + 1
        frameClock = frameClock + dt
        if frameClock >= 1 then
            State.Fps = math.floor(frames / frameClock + 0.5)
            frames, frameClock = 0, 0
        end
        for _, job in ipairs(jobs) do
            job.acc = job.acc + dt
            if job.acc >= job.i then
                job.acc = 0
                local ok, err = pcall(job.fn)
                if not ok then Log("job: " .. tostring(err), "error") end
            end
        end
    end)

    -- topbar: sempre, barato
    Every(0.5, function()
        local extra = ""
        if State.Spectating and State.SpectateTarget then
            extra = "   •   ASSISTINDO " .. State.SpectateTarget.Name
        end
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 2000)
        if SetChips then
            SetChips(State.Fps, ping, #Players:GetPlayers(), Players.MaxPlayers,
                LocalPlayer.Name,
                (State.Spectating and State.SpectateTarget) and State.SpectateTarget.Name or nil)
        else
            Stat.Text = string.format("FPS %d   •   PING %dms   •   %d/%d jogadores   •   %s%s",
                State.Fps, ping, #Players:GetPlayers(), Players.MaxPlayers,
                LocalPlayer.Name, extra)
        end
    end)

    -- painel: só a aba visível trabalha
    Every(1, function()
        if not isOpen or State.Minimized then return end
        local tab = State.ActiveTab
        if V8.Shell then pcall(V8.Shell.Tick) end   -- v8.0: relógio da TopBar
        if tab == "Home" then
            if Tiles.fps then Tiles.fps.Text = tostring(State.Fps) end
            if Tiles.ping then
                Tiles.ping.Text = math.floor(LocalPlayer:GetNetworkPing() * 2000) .. "ms"
            end
            if Tiles.players then
                Tiles.players.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
            end
            if Tiles.uptime then
                Tiles.uptime.Text = math.floor((os.time() - (serverStart or os.time())) / 60) .. "m"
            end
            RefreshStatus()
            if V8.Dash then pcall(V8.Dash.Tick) end   -- v8.0: relógio + tira de status
        elseif tab == "Players" then
            if UpdatePlayerRows then UpdatePlayerRows() end
        elseif tab == "Moderation" then
            if UpdateSelectedInfo then UpdateSelectedInfo() end
        elseif tab == "Server" then
            if UpdateServerInfo then UpdateServerInfo() end
        end
    end)

    -- v8.0: faxina do registry de tema. Listas que se redesenham (jogadores,
    -- waypoints, amigos, favoritos) deixavam entradas mortas em Painted até a
    -- próxima troca de tema. Removida só depois de 2 passadas seguidas sem
    -- Parent (~20s), para nunca pegar algo que ainda vai ser parentado.
    Every(20, function()
        local j = 0
        for i = 1, #Painted do
            local e = Painted[i]
            local inst = e and e.inst
            local keep = false
            if inst then
                if inst.Parent or inst == Gui then
                    e.dead = nil
                    keep = true
                else
                    e.dead = (e.dead or 0) + 1
                    keep = e.dead < 2
                end
            end
            if keep then
                j = j + 1
                Painted[j] = e
            end
        end
        for i = #Painted, j + 1, -1 do Painted[i] = nil end
    end)
end

