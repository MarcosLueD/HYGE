--------------------------------------------------------------------------------
-- v8.1 — RECURSOS AUTOMÁTICOS (Configurações › Ajustes › Automático)
-- * escolha quais funções ligam sozinhas toda vez que o painel carrega
--   (SET.Auto, vai na config em disco). O BootStep "Automático" roda depois do
--   "Config", então vale o que estava salvo.
-- * "Reconectar se cair": quando o Roblox mostra a tela de erro (desconexão,
--   expulsão), pede para entrar de novo no mesmo jogo — até 5 tentativas.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Auto = { rejoining = false }
        local A = V8.Auto
        if type(SET.Auto) ~= "table" then SET.Auto = {} end
        if SET.AutoRejoin == nil then SET.AutoRejoin = false end

        local function Auto()
            if type(SET.Auto) ~= "table" then SET.Auto = {} end
            return SET.Auto
        end

        A.List = {
            { "antiafk",    "Anti-AFK",      "Evita o kick por inatividade" },
            { "antifall",   "Anti-Fall",     "Sem tombo, sem dano de queda, salva do void" },
            { "esp",        "ESP",           nil },
            { "fullbright", "Fullbright",    nil },
            { "infjump",    "Infinite Jump", nil },
            { "chatspy",    "Chat Spy",      "Chat do servidor no console" },
            { "noclip",     "Noclip",        nil },
        }

        A.Run = function()
            local on = {}
            for _, item in ipairs(A.List) do
                local id = item[1]
                if Auto()[id] and Toggles[id] and not IsOn(id) then
                    SetToggle(id, true, true)
                    if IsOn(id) then table.insert(on, item[2]) end
                end
            end
            if #on > 0 then
                Log("Automático: " .. table.concat(on, ", ") .. " ligado(s) ao carregar", "ok")
            end
            if RefreshStatus then RefreshStatus() end
        end

        local card = CreateCard(Tabs.Settings, "AUTOMÁTICO", 5)
        SubLabel(card, "Liga sozinho toda vez que o painel carrega (a partir do próximo "
            .. "carregamento). Vai junto na config em disco.", -1)
        for i, item in ipairs(A.List) do
            CheckRow(card, item[2], item[3],
                function() return Auto()[item[1]] == true end,
                function(v) Auto()[item[1]] = v and true or nil end, i)
        end

        CheckRow(card, "Reconectar se cair",
            "Desconectou ou foi expulso: entra de novo no jogo (até 5 tentativas)",
            function() return SET.AutoRejoin == true end,
            function(v) SET.AutoRejoin = v and true or false end, 20)

        Conn.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(arg)
            if not SET.AutoRejoin or A.rejoining then return end
            local msg = type(arg) == "string" and arg or ""
            if msg == "" then pcall(function() msg = GuiService:GetErrorMessage() end) end
            if type(msg) ~= "string" or msg == "" then return end
            A.rejoining = true
            Log("Desconectado (" .. msg .. ") — reconectando...", "warn")
            task.spawn(function()
                for i = 1, 5 do
                    task.wait(i == 1 and 2 or 10)
                    local ok, err = pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                    Log("Reconectar: tentativa " .. i .. (ok and "" or (" falhou: " .. tostring(err))),
                        ok and "action" or "error")
                end
                A.rejoining = false
            end)
        end)
    end
    Build()
end
