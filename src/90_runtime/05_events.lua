--------------------------------------------------------------------------------
-- RESPAWN: reaplica o que estava ligado (e avisa o que não deu)
--------------------------------------------------------------------------------
Conn.CharAdded = LocalPlayer.CharacterAdded:Connect(function(char)
    pcall(function() char:WaitForChild("Humanoid", 5) end)
    task.wait(0.4)

    local falhou = {}
    local function Redo(name, fn)
        local ok = pcall(fn)
        if not ok then table.insert(falhou, name) end
    end

    -- o drone ancora partes do corpo antigo: no respawn ele sempre desliga
    if IsOn("drone") then
        pcall(function() SetToggle("drone", false, true) end)
        Log("Modo Drone desligado (respawn) — ligue de novo se quiser", "warn")
        Toast("Drone desligado no respawn", "warn")
    end

    if IsOn("fly") then Redo("fly", StartFly) end
    if IsOn("noclip") then Redo("noclip", CacheNoclipParts) end
    if IsOn("god") then Redo("god", function() ApplyGod(Hum()) end) end
    if IsOn("invisible") then Redo("invisible", function() ApplyInvisible(true) end) end

    Redo("velocidade", function()
        local h = Hum()
        if not h then error("sem humanoid") end
        if State.WalkSpeed ~= 16 then h.WalkSpeed = State.WalkSpeed end
        if State.JumpPower ~= 50 then
            h.UseJumpPower = true
            h.JumpPower = State.JumpPower
        end
    end)

    if IsOn("esp") then
        if SET.EspAuto then
            Redo("esp", function()
                ClearEsp()
                for _, p in ipairs(Players:GetPlayers()) do BuildEsp(p) end
            end)
        else
            Log("ESP não foi reconstruído (opção 'reconstruir ESP no respawn' desligada)", "warn")
        end
    end

    if #falhou > 0 then
        Log("Não deu para reaplicar: " .. table.concat(falhou, ", "), "error")
        Toast("Falhou reaplicar: " .. table.concat(falhou, ", "), "error")
    else
        Log("Personagem recarregado — funções reaplicadas", "ok")
    end
    RefreshStatus()
end)

--------------------------------------------------------------------------------
-- v8.0: ENTRADA / SAÍDA DE JOGADORES
-- Antes não existia nenhum PlayerAdded/PlayerRemoving: a aba Players só via
-- gente nova ao ser reaberta, o ESP de quem saiu ficava na memória (tracer
-- incluso) e o "tempo no servidor" nunca era preenchido.
-- Quem já estava no servidor quando o painel abriu fica com "—": o cliente não
-- sabe a hora de entrada deles, e o painel não inventa número.
--------------------------------------------------------------------------------
Conn.PlayerAdded = Players.PlayerAdded:Connect(function(p)
    State.JoinTimes[p.UserId] = os.clock()
    Log("Entrou: " .. p.Name .. " (" .. p.DisplayName .. ")")
    if isOpen and State.ActiveTab == "Players" and RebuildPlayerRows then
        pcall(RebuildPlayerRows)
    end
end)

Conn.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    local id = p.UserId
    State.JoinTimes[id] = nil
    TrollState.Spin[id] = nil
    TrollState.Balloon[id] = nil
    pcall(RemoveEsp, id)
    if State.SpectateTarget == p then pcall(StopSpectate) end
    if State.SelectedPlayer == p then
        State.SelectedPlayer = nil
        if UpdateSelectedInfo then pcall(UpdateSelectedInfo) end
    end
    Log("Saiu: " .. p.Name)
    -- durante este evento o Player ainda está em Players: reconstrói depois
    task.delay(0.2, function()
        if RebuildPlayerRows then pcall(RebuildPlayerRows) end
    end)
end)

--------------------------------------------------------------------------------
-- MENSAGENS DO SERVIDOR (AdminWhisper)
--------------------------------------------------------------------------------
if Remotes.Whisper then
    Conn.Whisper = Remotes.Whisper.OnClientEvent:Connect(function(fromName, message)
        Log("[ADMIN " .. tostring(fromName) .. "] " .. tostring(message), "action")
        Toast("ADMIN " .. tostring(fromName) .. ": " .. tostring(message), nil, 6)
    end)
end
-- v8.0: com o script de server/ o anúncio volta para todos (já filtrado pelo
-- Roblox); o painel registra no próprio console como confirmação real
if Remotes.Announce then
    Conn.Announce = Remotes.Announce.OnClientEvent:Connect(function(fromName, message)
        Log("[ANÚNCIO " .. tostring(fromName) .. "] " .. tostring(message), "action")
    end)
end

