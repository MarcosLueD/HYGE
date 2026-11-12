--------------------------------------------------------------------------------
-- V8.0 / FASE 1 — PERSISTÊNCIA (HYGE/config.json)
-- Salva/carrega keybinds, aparência, comportamento, velocidades, opções de ESP,
-- waypoints, favoritos de emote, notas e a última situação.
-- Se o executor não tiver API de arquivos, avisa na UI e no log — NUNCA finge
-- que salvou. Exportar/importar por clipboard funciona mesmo assim.
--------------------------------------------------------------------------------
do
    V8.Cfg = {}
    local C = V8.Cfg

    C.Folder = "HYGE"
    C.Path   = "HYGE/config.json"

    local Http = nil
    pcall(function() Http = game:GetService("HttpService") end)

    if SET.AutoSave  == nil then SET.AutoSave  = true  end
    if SET.SitOnLoad == nil then SET.SitOnLoad = false end
    if SET.Theme     == nil then SET.Theme     = CONFIG.DefaultTheme end
    if State.Notes   == nil then State.Notes   = {} end   -- [userId] = texto (fase 2)

    -- o painel precisa saber qual tema está ativo para salvar: embrulha ApplyTheme
    do
        local base = ApplyTheme
        if base then
            ApplyTheme = function(name)
                SET.Theme = name
                return base(name)
            end
        end
    end

    ----------------------------------------------------------------------------
    -- suporte do executor
    ----------------------------------------------------------------------------
    local function FileApi()
        return typeof(writefile) == "function" and typeof(readfile) == "function"
            and typeof(isfile) == "function"
    end
    C.Supported = function() return FileApi() and Http ~= nil end

    local function Encode(t)
        local ok, res = pcall(function() return Http:JSONEncode(t) end)
        if ok then return res end
        return nil, tostring(res)
    end
    local function Decode(s)
        local ok, res = pcall(function() return Http:JSONDecode(s) end)
        if ok and type(res) == "table" then return res end
        return nil, tostring(res)
    end

    ----------------------------------------------------------------------------
    -- snapshot / restauração
    ----------------------------------------------------------------------------
    local ESP_KEYS = { "Highlight", "Name", "UseDisplay", "Distance", "Health",
                       "HealthBar", "Tracers", "Allies", "Enemies", "MaxDist",
                       "Rate", "ColorKey", "AllyKey", "TeamColors" }
    local SET_KEYS = { "Animations", "Toasts", "ShowLogs", "Confirm", "EspAuto",
                       "MaxLog", "Compact", "Transparency", "AutoSave", "SitOnLoad",
                       "Dock", "Slots", "WinPos" }

    C.Snapshot = function()
        local d = {
            version = CONFIG.Version,
            theme   = SET.Theme,
            scale   = math.floor((CONFIG.UiScale or 1) * 100 + 0.5),
            set     = {},
            esp     = {},
            keys    = {},
            sitkeys = {},
            speeds  = {
                walk  = State.WalkSpeed,
                fly   = State.FlySpeed,
                jump  = State.JumpPower,
                drone = State.DroneSpeed,
                wall  = State.WallAlpha,
            },
            waypoints = {},
            emotes    = {},
            notes     = {},
            panelkey  = CONFIG.PanelKey and CONFIG.PanelKey.Name or nil,
            consolekey = CONFIG.ConsoleKey and CONFIG.ConsoleKey.Name or nil,
            searchkey = CONFIG.SearchKey and CONFIG.SearchKey.Name or nil,
            searchctrl = CONFIG.SearchCtrl,
            situation = V8.Sit and V8.Sit.Current or nil,
        }
        for _, k in ipairs(SET_KEYS) do d.set[k] = SET[k] end
        for _, k in ipairs(ESP_KEYS) do d.esp[k] = EspOpts[k] end
        for id, kc in pairs(Keybinds) do d.keys[id] = kc.Name end
        if V8.Sit then
            for n, kc in pairs(V8.Sit.Keys) do d.sitkeys[n] = kc.Name end
        end
        for i, w in ipairs(State.Waypoints) do
            local c = { w.cframe:GetComponents() }
            d.waypoints[i] = { name = w.name, cf = c }
        end
        for i, e in ipairs(State.Emotes) do
            d.emotes[i] = { id = e.id, name = e.name }
        end
        for id, txt in pairs(State.Notes) do d.notes[tostring(id)] = txt end
        return d
    end

    local function KC(name)
        if type(name) ~= "string" then return nil end
        local ok, kc = pcall(function() return Enum.KeyCode[name] end)
        if ok then return kc end
        return nil
    end

    C.Restore = function(d)
        if type(d) ~= "table" then return false end
        local ui = V8.UI or {}

        -- comportamento / aparência
        if type(d.set) == "table" then
            for _, k in ipairs(SET_KEYS) do
                if d.set[k] ~= nil then SET[k] = d.set[k] end
            end
            CONFIG.MaxLog = SET.MaxLog or CONFIG.MaxLog
        end
        if d.theme and PALETTES[d.theme] and ApplyTheme then pcall(ApplyTheme, d.theme) end
        if ui.scale and d.scale then pcall(ui.scale, d.scale) end
        if ui.alpha and SET.Transparency then pcall(ui.alpha, math.floor(SET.Transparency * 100 + 0.5)) end
        if ui.maxlog and SET.MaxLog then pcall(ui.maxlog, SET.MaxLog, true) end
        if ui.compact then pcall(ui.compact, SET.Compact == true) end
        if ui.compactRender then pcall(ui.compactRender) end
        -- sidebar x dock: o render do switch é visual, o Apply é que troca o layout
        if V8.Dock then pcall(V8.Dock.Apply, SET.Dock == true) end
        -- v8.0: posição da janela (validada e presa dentro da tela)
        if V8.Win and type(SET.WinPos) == "table" then pcall(V8.Win.Restore, SET.WinPos) end
        -- os 3 cards de status da Home (string "fly noclip esp")
        if type(SET.Slots) == "string" and V8.Dash and V8.Dash.SetSlots then
            pcall(V8.Dash.SetSlots, SET.Slots, true)
            if V8.Dock and V8.Dock.SlotBox then
                V8.Dock.SlotBox.Text = table.concat(V8.Dash.Slots, " ")
            end
        end

        -- opções de ESP
        if type(d.esp) == "table" then
            for _, k in ipairs(ESP_KEYS) do
                if d.esp[k] ~= nil then EspOpts[k] = d.esp[k] end
            end
        end
        -- re-renderiza TODOS os switches registrados (comportamento, esp, etc.)
        if V8.Renders then
            for _, r in ipairs(V8.Renders) do pcall(r) end
        end

        -- velocidades (pelos sliders reais, então a UI acompanha)
        if type(d.speeds) == "table" then
            if d.speeds.walk and WalkSlider then pcall(WalkSlider, d.speeds.walk) end
            if d.speeds.fly and FlySlider then pcall(FlySlider, d.speeds.fly) end
            if d.speeds.jump and JumpSlider then pcall(JumpSlider, d.speeds.jump) end
            if d.speeds.drone and DroneSpeedSlider then pcall(DroneSpeedSlider, d.speeds.drone) end
            if d.speeds.wall then State.WallAlpha = d.speeds.wall end
        end

        -- keybinds
        if type(d.keys) == "table" then
            for id in pairs(Keybinds) do Keybinds[id] = nil end
            for id, name in pairs(d.keys) do
                local kc = KC(name)
                if kc and Toggles[id] then Keybinds[id] = kc end
            end
            for id, lbl in pairs(KeybindLabels) do
                lbl.Text = Keybinds[id] and KeyName(Keybinds[id]) or "—"
            end
        end
        if d.panelkey and KC(d.panelkey) then CONFIG.PanelKey = KC(d.panelkey) end
        if d.consolekey and KC(d.consolekey) then CONFIG.ConsoleKey = KC(d.consolekey) end
        if d.searchkey and KC(d.searchkey) then CONFIG.SearchKey = KC(d.searchkey) end
        if d.searchctrl ~= nil then CONFIG.SearchCtrl = d.searchctrl end

        -- atalhos das situações
        if V8.Sit and type(d.sitkeys) == "table" then
            for n in pairs(V8.Sit.Keys) do V8.Sit.Keys[n] = nil end
            for n, name in pairs(d.sitkeys) do
                local kc = KC(name)
                if kc and V8.Sit.Defs[n] then V8.Sit.Keys[n] = kc end
            end
            pcall(V8.Sit.Render)
        end

        -- waypoints
        if type(d.waypoints) == "table" then
            for i = #State.Waypoints, 1, -1 do State.Waypoints[i] = nil end
            for _, w in ipairs(d.waypoints) do
                local c = w.cf
                if type(c) == "table" and #c >= 12 then
                    local ok, cf = pcall(function() return CFrame.new(table.unpack(c)) end)
                    if ok then
                        table.insert(State.Waypoints, { name = w.name or "WP", cframe = cf })
                    end
                end
            end
            if RenderWaypoints then pcall(RenderWaypoints) end
        end

        -- favoritos de emote
        if type(d.emotes) == "table" then
            for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
            for _, e in ipairs(d.emotes) do
                if e.id then table.insert(State.Emotes, { id = e.id, name = e.name or e.id }) end
            end
            if V8.RenderEmotes then pcall(V8.RenderEmotes) end
        end

        -- notas (fase 2 usa isso)
        if type(d.notes) == "table" then
            for k in pairs(State.Notes) do State.Notes[k] = nil end
            for k, v in pairs(d.notes) do State.Notes[tonumber(k) or k] = v end
        end

        C.LastSituation = d.situation
        if RefreshQuick then pcall(RefreshQuick) end
        if RefreshStatus then pcall(RefreshStatus) end
        return true
    end

    ----------------------------------------------------------------------------
    -- disco
    ----------------------------------------------------------------------------
    local status   -- SubLabel de estado (definido na UI abaixo)
    local function Say(msg, kind)
        Log(msg, kind)
        if status then status.Text = msg end
    end

    C.Save = function(silent)
        if not C.Supported() then
            Say("Não salvei: este executor não expõe writefile/readfile "
                .. "(use EXPORTAR e guarde o JSON à mão)", "error")
            if not silent then Toast("Executor sem API de arquivos — nada foi salvo", "error", 4) end
            return false
        end
        local json, err = Encode(C.Snapshot())
        if not json then
            Say("Falha ao gerar o JSON: " .. tostring(err), "error")
            return false
        end
        local ok, werr = pcall(function()
            if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
                if not isfolder(C.Folder) then makefolder(C.Folder) end
            elseif typeof(makefolder) == "function" then
                pcall(function() makefolder(C.Folder) end)
            end
            writefile(C.Path, json)
        end)
        if not ok then
            Say("Falha ao escrever " .. C.Path .. ": " .. tostring(werr), "error")
            if not silent then Toast("Não deu para salvar a config", "error", 4) end
            return false
        end
        Say("Config salva em " .. C.Path .. " (" .. #json .. " bytes)", "ok")
        if not silent then Toast("Config salva", "ok", 2) end
        return true
    end

    C.Load = function(silent)
        if not C.Supported() then
            if not silent then
                Say("Não carreguei: executor sem API de arquivos (use IMPORTAR)", "error")
                Toast("Executor sem API de arquivos", "error", 4)
            else
                Log("Config em disco indisponível neste executor (use EXPORTAR/IMPORTAR)", "warn")
            end
            return false
        end
        local exists = false
        pcall(function() exists = isfile(C.Path) end)
        if not exists then
            if not silent then Say("Nenhuma config salva ainda em " .. C.Path, "warn") end
            return false
        end
        local ok, raw = pcall(function() return readfile(C.Path) end)
        if not ok or type(raw) ~= "string" then
            Say("Falha ao ler " .. C.Path, "error")
            return false
        end
        local d, derr = Decode(raw)
        if not d then
            Say("JSON inválido em " .. C.Path .. ": " .. tostring(derr), "error")
            return false
        end
        local okR = pcall(C.Restore, d)
        if not okR then
            Say("Config lida, mas falhou ao aplicar", "error")
            return false
        end
        Say("Config carregada de " .. C.Path, "ok")
        if not silent then Toast("Config carregada", "ok", 2) end

        if SET.SitOnLoad and C.LastSituation and V8.Sit then
            pcall(V8.Sit.Apply, C.LastSituation)
        end
        return true
    end

    C.Reset = function()
        local removed = false
        if C.Supported() then
            pcall(function()
                if isfile(C.Path) and typeof(delfile) == "function" then
                    delfile(C.Path)
                    removed = true
                end
            end)
        end
        if V8.UI and V8.UI.restore then pcall(V8.UI.restore) end
        Say(removed and ("Config apagada (" .. C.Path .. ") e padrões restaurados")
            or "Padrões restaurados (não havia arquivo salvo)", "action")
        Toast("Configurações resetadas", "warn", 3)
        return true
    end

    C.Export = function()
        local json = Encode(C.Snapshot())
        if not json then
            Say("Falha ao gerar o JSON", "error")
            return false
        end
        if typeof(setclipboard) == "function" then
            local ok = pcall(function() setclipboard(json) end)
            if ok then
                Say("JSON da config copiado (" .. #json .. " bytes)", "ok")
                Toast("Config copiada", "ok", 2)
                return true
            end
        end
        Log("Sem setclipboard neste executor — o JSON vai para o console do Roblox", "warn")
        print("[HYGE] config:", json)
        Say("Sem clipboard: JSON impresso no console do Roblox (F9)", "warn")
        return false
    end

    C.Import = function(text)
        if type(text) ~= "string" or text:match("^%s*$") then
            Say("Cole o JSON no campo antes de importar", "warn")
            return false
        end
        if not Http then
            Say("HttpService indisponível — não consigo ler o JSON", "error")
            return false
        end
        local d, derr = Decode(text)
        if not d then
            Say("JSON inválido: " .. tostring(derr), "error")
            Toast("JSON inválido", "error", 3)
            return false
        end
        if not pcall(C.Restore, d) then
            Say("JSON lido, mas falhou ao aplicar", "error")
            return false
        end
        Say("Config importada do texto colado", "ok")
        Toast("Config importada", "ok", 2)
        return true
    end

    ----------------------------------------------------------------------------
    -- UI (aba Settings)
    ----------------------------------------------------------------------------
    do
        local card = CreateCard(Tabs["Settings"], "CONFIGURAÇÃO EM DISCO", 6)
        SubLabel(card, "Arquivo: " .. C.Path .. "  —  salva keybinds, aparência, "
            .. "velocidades, opções de ESP, waypoints, emotes favoritos e a última situação.", -1)

        status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, 0, 0, 0)
        status.AutomaticSize = Enum.AutomaticSize.Y
        status.BackgroundTransparency = 1
        status.Text = C.Supported() and "Pronto — este executor suporta salvar em disco."
            or "Este executor NÃO expõe writefile/readfile: salvar e carregar ficam "
               .. "indisponíveis. Use EXPORTAR/IMPORTAR pelo clipboard."
        status.TextColor3 = C.Supported() and THEME.Success or THEME.Warning
        status.Font = Enum.Font.Gotham
        status.TextSize = 11
        status.TextWrapped = true
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.LayoutOrder = 0
        status.Parent = card
        table.insert(Painted, { inst = status, prop = "TextColor3",
            key = C.Supported() and "Success" or "Warning" })

        local g1 = Grid(card, 3, 32)
        g1.LayoutOrder = 1

        local bSave = CreateButton(g1, "SALVAR AGORA", "Success", 32)
        bSave.LayoutOrder = 1
        bSave.MouseButton1Click:Connect(function() C.Save() end)

        local bLoad = CreateButton(g1, "CARREGAR", "Accent", 32)
        bLoad.LayoutOrder = 2
        bLoad.MouseButton1Click:Connect(function() C.Load() end)

        local bReset = CreateButton(g1, "RESETAR", "Danger", 32)
        bReset.LayoutOrder = 3
        bReset.MouseButton1Click:Connect(function()
            Confirm("Apagar " .. C.Path .. " e voltar tudo ao padrão?", function() C.Reset() end)
        end)

        CheckRow(card, "Salvar automaticamente ao fechar",
            "Grava a config no Unload (e ao descarregar pelo botão)",
            function() return SET.AutoSave end,
            function(v) SET.AutoSave = v end, 2)

        CheckRow(card, "Aplicar a última situação ao carregar",
            "No boot, reaplica a situação que estava ativa quando você salvou",
            function() return SET.SitOnLoad end,
            function(v) SET.SitOnLoad = v end, 3)

        local box = CreateInput(card, "cole aqui o JSON da config para importar", 32)
        box.LayoutOrder = 4
        box.Font = Enum.Font.Code
        box.TextSize = 11

        local g2 = Grid(card, 2, 30)
        g2.LayoutOrder = 5

        local bExp = CreateButton(g2, "EXPORTAR (COPIAR JSON)", "Accent2", 30)
        bExp.LayoutOrder = 1
        bExp.MouseButton1Click:Connect(function() C.Export() end)

        local bImp = CreateButton(g2, "IMPORTAR DO CAMPO", "Warning", 30)
        bImp.LayoutOrder = 2
        bImp.MouseButton1Click:Connect(function()
            local t = box.Text
            Confirm("Importar essa config? Ela sobrescreve o que está ativo agora.", function()
                if C.Import(t) then box.Text = "" end
            end)
        end)
    end
end
