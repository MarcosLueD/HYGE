-- CHAT SPY -------------------------------------------------------------------
DefineToggle({
    id = "chatspy", label = "Chat Spy", desc = "Mostra o chat no console",
    enable = function()
        -- v8.0: jogos com TextChatService (o padrão atual do Roblox) não
        -- disparam o PlayerChatted antigo — sem isso o Chat Spy ficava mudo.
        -- Usa UM dos dois sistemas, nunca os dois (evita linha duplicada).
        local modern = false
        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
            Conn.ChatSpy = tcs.MessageReceived:Connect(function(msg)
                local src = msg.TextSource
                if not src or src.UserId == LocalPlayer.UserId then return end
                local p = Players:GetPlayerByUserId(src.UserId)
                Log("[CHAT] " .. (p and p.Name or tostring(src.Name)) .. ": "
                    .. tostring(msg.Text))
            end)
            modern = true
        end)
        if modern then return end
        Conn.ChatSpy = Players.PlayerChatted:Connect(function(_, player, message)
            if player ~= LocalPlayer then
                Log("[CHAT] " .. player.Name .. ": " .. message)
            end
        end)
    end,
    disable = function() Drop("ChatSpy") end,
})

-- FULLBRIGHT -----------------------------------------------------------------
local lightBackup
DefineToggle({
    id = "fullbright", label = "Fullbright", desc = "Remove escuridão e neblina",
    enable = function()
        lightBackup = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd,
            ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows,
        }
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end,
    disable = function()
        if not lightBackup then return end
        for k, v in pairs(lightBackup) do Lighting[k] = v end
    end,
})

-- ANTI-AFK -------------------------------------------------------------------
DefineToggle({
    id = "antiafk", label = "Anti-AFK", desc = "Evita kick por inatividade",
    enable = function()
        Conn.AntiAfk = LocalPlayer.Idled:Connect(function()
            local ok = pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            if not ok then
                local h = Hum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            Log("Anti-AFK: entrada simulada")
        end)
    end,
    disable = function() Drop("AntiAfk") end,
})

