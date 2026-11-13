--------------------------------------------------------------------------------
-- BARRA DE COMANDOS (histórico, autocomplete, aliases)
--------------------------------------------------------------------------------
do
    CmdBar = Instance.new("Frame")
    CmdBar.Name = "CommandBar"
    CmdBar.AnchorPoint = Vector2.new(0.5, 0)
    CmdBar.Position = UDim2.new(0.5, 0, 0, 90)
    CmdBar.Size = UDim2.new(0, 520, 0, 44)
    CmdBar.BackgroundColor3 = THEME.Card
    CmdBar.BorderSizePixel = 0
    CmdBar.Visible = false
    CmdBar.Parent = Gui
    Paint(CmdBar, "BackgroundColor3", "Card")
    Instance.new("UICorner", CmdBar).CornerRadius = UDim.new(0, 11)
    local cmdStroke = Instance.new("UIStroke", CmdBar)
    cmdStroke.Transparency = 0.3
    Paint(cmdStroke, "Color", "Accent")

    CmdInput = CreateInput(CmdBar, "fly | speed 80 | tp joao | preset Visual | help", 32)
    CmdInput.Size = UDim2.new(1, -24, 0, 32)
    CmdInput.Position = UDim2.new(0, 12, 0, 6)
    CmdInput.Font = Enum.Font.Code

    -- painel de sugestões (aparece abaixo da barra)
    local Hint = Instance.new("Frame")
    Hint.AnchorPoint = Vector2.new(0.5, 0)
    Hint.Position = UDim2.new(0.5, 0, 1, 6)
    Hint.Size = UDim2.new(1, 0, 0, 0)
    Hint.AutomaticSize = Enum.AutomaticSize.Y
    Hint.BackgroundColor3 = THEME.Console
    Hint.BorderSizePixel = 0
    Hint.Visible = false
    Hint.Parent = CmdBar
    Paint(Hint, "BackgroundColor3", "Console")
    Instance.new("UICorner", Hint).CornerRadius = UDim.new(0, 9)
    local hintPad = Instance.new("UIPadding", Hint)
    hintPad.PaddingTop = UDim.new(0, 6)
    hintPad.PaddingBottom = UDim.new(0, 6)
    hintPad.PaddingLeft = UDim.new(0, 10)
    hintPad.PaddingRight = UDim.new(0, 10)
    local hintLayout = Instance.new("UIListLayout", Hint)
    hintLayout.Padding = UDim.new(0, 2)
    hintLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local Commands, CmdNames = {}, {}
    local hintLines, matches = {}, {}
    local histPos = 0

    local function DefCmd(name, usage, help, run, alias)
        Commands[name] = { name = name, usage = usage, help = help, run = run }
        table.insert(CmdNames, name)
        if alias then Commands[alias] = Commands[name] end
    end

    local function HintLine(order)
        local l = hintLines[order]
        if l then return l end
        l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 15)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = THEME.Dim
        l.LayoutOrder = order
        l.Parent = Hint
        table.insert(Painted, { inst = l, prop = "TextColor3", key = "Dim" })
        hintLines[order] = l
        return l
    end

    local function ShowHints()
        local text = CmdInput.Text or ""
        local first = text:match("^%s*(%S*)") or ""
        matches = {}
        if first ~= "" and not text:match("^%s*%S+%s") then
            for _, n in ipairs(CmdNames) do
                if n:sub(1, #first):lower() == first:lower() then table.insert(matches, n) end
            end
            table.sort(matches)
        elseif first ~= "" and Commands[first:lower()] then
            matches = { Commands[first:lower()].name }
        end
        for _, l in ipairs(hintLines) do l.Visible = false end
        local shown = 0
        for i = 1, math.min(#matches, 6) do
            local c = Commands[matches[i]:lower()]
            local l = HintLine(i)
            l.Text = "  " .. c.usage .. "   —   " .. c.help
            l.Visible = true
            shown = shown + 1
        end
        if #matches > 6 then
            local l = HintLine(7)
            l.Text = "  ... e mais " .. (#matches - 6) .. " (digite 'help')"
            l.Visible = true
            shown = shown + 1
        end
        Hint.Visible = shown > 0
    end

    local function Complete()
        if #matches == 0 then return end
        CmdInput.Text = matches[1] .. " "
        CmdInput.CursorPosition = #CmdInput.Text + 1
        ShowHints()
    end

    local function Recall(dir)
        local hist = State.CmdHistory
        if #hist == 0 then return end
        histPos = math.clamp(histPos + dir, 0, #hist)
        if histPos == 0 then
            CmdInput.Text = ""
        else
            CmdInput.Text = hist[#hist - histPos + 1] or ""
        end
        CmdInput.CursorPosition = #CmdInput.Text + 1
    end

    RunCommand = function(text)
        text = tostring(text or "")
        if text:match("^%s*$") then return end
        table.insert(State.CmdHistory, text)
        while #State.CmdHistory > 25 do table.remove(State.CmdHistory, 1) end
        histPos = 0

        local args = {}
        for word in text:gmatch("%S+") do table.insert(args, word) end
        local name = table.remove(args, 1):lower()
        local cmd = Commands[name]
        if not cmd then
            local near
            for _, n in ipairs(CmdNames) do
                if n:sub(1, #name) == name then near = n break end
            end
            Log("Comando desconhecido: " .. name
                .. (near and (" — você quis dizer '" .. near .. "'?") or " (use 'help')"), "error")
            Toast("Comando desconhecido: " .. name, "error")
            return
        end
        local ok, err = pcall(cmd.run, args)
        if not ok then
            Log("Erro em '" .. name .. "': " .. tostring(err), "error")
            Toast("Erro no comando " .. name, "error")
        end
    end

    ----------------------------------------------------------------------------
    -- um comando por toggle
    ----------------------------------------------------------------------------
    for _, id in ipairs(ToggleOrder) do
        DefCmd(id, id .. " [on|off]", Toggles[id].label or id, function(args)
            local a = (args[1] or ""):lower()
            if a == "on" then SetToggle(id, true)
            elseif a == "off" then SetToggle(id, false)
            else Flip(id) end
        end)
    end

    ----------------------------------------------------------------------------
    -- comandos gerais
    ----------------------------------------------------------------------------
    DefCmd("speed", "speed <n>", "define WalkSpeed", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: speed <numero>", "warn") return end
        State.WalkSpeed = v
        local h = Hum()
        if h then h.WalkSpeed = v end
        if WalkSlider then WalkSlider(v) end
        Log("WalkSpeed = " .. v, "ok")
    end, "ws")

    DefCmd("flyspeed", "flyspeed <n>", "velocidade do fly", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: flyspeed <numero>", "warn") return end
        State.FlySpeed = v
        if FlySlider then FlySlider(v) end
        Log("FlySpeed = " .. v, "ok")
    end, "fs")

    DefCmd("jp", "jp <n>", "define JumpPower", function(args)
        local v = tonumber(args[1])
        if not v then Log("uso: jp <numero>", "warn") return end
        State.JumpPower = v
        local h = Hum()
        if h then h.UseJumpPower = true h.JumpPower = v end
        if JumpSlider then JumpSlider(v) end
        Log("JumpPower = " .. v, "ok")
    end)

    DefCmd("tp", "tp <jogador>", "teleporta você até o jogador", function(args)
        local p = FindPlayer(args[1])
        if p then Goto(p) else Log("Jogador não encontrado: " .. tostring(args[1]), "warn") end
    end)

    DefCmd("bring", "bring <jogador>", "puxa o jogador (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then Bring(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("select", "select <jogador>", "seleciona o alvo do painel", function(args)
        local p = FindPlayer(args[1])
        if p then SelectPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("spectate", "spectate [jogador]", "assiste o jogador (sem nome: sai)", function(args)
        local p = FindPlayer(args[1])
        if p then StartSpectate(p) else StopSpectate() end
        RefreshStatus()
    end, "spec")

    DefCmd("freeze", "freeze <jogador>", "congela (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FreezePlayer(p, true) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("unfreeze", "unfreeze <jogador>", "descongela (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FreezePlayer(p, false) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("kick", "kick <jogador>", "expulsa (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then KickPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    ----------------------------------------------------------------------------
    -- TROLL (v8.0) — todas dependem de Remote no servidor, exceto fakemsg
    ----------------------------------------------------------------------------
    DefCmd("fling", "fling <jogador>", "impulso forte no alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then FlingPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("spin", "spin <jogador> [on|off]", "rotação contínua no alvo (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local a = (args[2] or ""):lower()
            local on
            if a == "on" then on = true
            elseif a == "off" then on = false
            else on = not TrollState.Spin[p.UserId] end
            SpinPlayer(p, on)
        end)

    DefCmd("trip", "trip <jogador>", "derruba o alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then TripPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("launch", "launch <jogador>", "lança o alvo bem alto (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then LaunchPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    -- nota: "sit" já é o comando de Situações (v8.0) — usamos "forcesit" pro troll
    DefCmd("forcesit", "forcesit <jogador>", "senta o alvo (precisa de Remote)", function(args)
        local p = FindPlayer(args[1])
        if p then SitPlayer(p) else Log("Jogador não encontrado", "warn") end
    end)

    DefCmd("scale", "scale <jogador> <tiny|normal|giant>", "muda o tamanho do alvo (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local mode = (args[2] or ""):lower()
            if mode ~= "tiny" and mode ~= "normal" and mode ~= "giant" then
                Log("uso: scale <jogador> <tiny|normal|giant>", "warn")
                return
            end
            ScalePlayer(p, mode)
        end)

    DefCmd("balloon", "balloon <jogador> [on|off]", "empurrão suave pra cima (precisa de Remote)",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local a = (args[2] or ""):lower()
            local on
            if a == "on" then on = true
            elseif a == "off" then on = false
            else on = not TrollState.Balloon[p.UserId] end
            BalloonPlayer(p, on)
        end)

    DefCmd("fakemsg", "fakemsg <jogador> <kick|ban>", "mensagem de sistema falsa, 100% local",
        function(args)
            local p = FindPlayer(args[1])
            if not p then Log("Jogador não encontrado", "warn") return end
            local kind = (args[2] or "kick"):lower()
            FakeMessage(p, kind)
        end)

    DefCmd("heal", "heal", "cura seu personagem", function()
        local h = Hum()
        if h then h.Health = h.MaxHealth Log("Curado", "ok") else Log("Sem humanoid", "warn") end
    end)

    DefCmd("respawn", "respawn", "força respawn", function()
        local h = Hum()
        if h then h.Health = 0 Log("Respawn forçado", "action") end
    end, "re")

    DefCmd("emote", "emote <id|favorito|stop>", "toca animação no seu personagem",
        function(args)
            local a = args[1]
            if not a or a == "" then
                Log("uso: emote <id> | emote <nome favorito> | emote stop", "warn")
                return
            end
            if a:lower() == "stop" or a:lower() == "off" then
                Emote.Stop()
                return
            end
            -- procura nos favoritos antes de tratar como ID
            local q = a:lower()
            for _, e in ipairs(State.Emotes) do
                if e.name:lower() == q or e.name:lower():find(q, 1, true) == 1 then
                    Emote.Play(e.id, e.name)
                    return
                end
            end
            Emote.Play(a)
        end, "e")

    DefCmd("announce", "announce <mensagem>", "anúncio global (precisa de Remote)", function(args)
        local msg = table.concat(args, " ")
        if msg == "" then Log("uso: announce <mensagem>", "warn") return end
        Announce(msg)
    end)

    DefCmd("wp", "wp save|tp|list", "waypoints", function(args)
        local sub = (args[1] or ""):lower()
        if sub == "save" then
            local r = Root()
            if not r then Log("Sem personagem", "warn") return end
            table.insert(State.Waypoints, { name = "WP " .. (#State.Waypoints + 1), cframe = r.CFrame })
            if RenderWaypoints then RenderWaypoints() end
            Log("Waypoint salvo", "ok")
        elseif sub == "tp" then
            local n = tonumber(args[2])
            local wp = n and State.Waypoints[n] or State.Waypoints[#State.Waypoints]
            if wp then TeleportTo(wp.cframe) Log("TP -> " .. wp.name, "ok")
            else Log("Sem waypoints", "warn") end
        elseif sub == "list" then
            if #State.Waypoints == 0 then Log("Sem waypoints", "warn") return end
            for i, w in ipairs(State.Waypoints) do
                Log(i .. ") " .. w.name .. string.format("  %d, %d, %d",
                    w.cframe.X, w.cframe.Y, w.cframe.Z))
            end
        else
            Log("uso: wp save | wp tp [n] | wp list", "warn")
        end
    end)

    DefCmd("theme", "theme <Grafite|Azul|Roxo|Ciano|Verde|Vermelho>", "troca a paleta", function(args)
        local n = args[1]
        if not n then Log("uso: theme Grafite|Azul|Roxo|Ciano|Verde|Vermelho", "warn") return end
        n = n:sub(1, 1):upper() .. n:sub(2):lower()
        if not PALETTES[n] then Log("Tema inexistente: " .. n, "warn") return end
        if ApplyTheme then ApplyTheme(n) end
    end)

    DefCmd("preset", "preset <Default|Admin|Visual|Movement|Minimal>", "aplica um preset",
        function(args)
            local n = args[1]
            if not n then Log("uso: preset Default|Admin|Visual|Movement|Minimal", "warn") return end
            n = n:sub(1, 1):upper() .. n:sub(2):lower()
            if ApplyPreset then ApplyPreset(n) end
        end)

    DefCmd("status", "status", "resumo do estado atual", function()
        local on = {}
        for _, id in ipairs(ToggleOrder) do
            if IsOn(id) then table.insert(on, id) end
        end
        Log("Ligado: " .. (#on > 0 and table.concat(on, ", ") or "nada"))
        Log(string.format("FPS %d  •  WalkSpeed %d  •  FlySpeed %d  •  Waypoints %d",
            State.Fps, State.WalkSpeed, State.FlySpeed, #State.Waypoints))
        Log("Spectate: " .. (State.Spectating and State.SpectateTarget
            and State.SpectateTarget.Name or "off"))
        RefreshStatus()
    end)

    DefCmd("players", "players", "lista os jogadores online", function()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
        table.sort(names)
        Log(#names .. " online: " .. table.concat(names, ", "))
    end)

    DefCmd("server", "server", "info do servidor e Remotes", function()
        Log("PlaceId " .. game.PlaceId .. "  •  JobId "
            .. (game.JobId ~= "" and game.JobId or "estúdio"))
        local have, total, miss = V8.RemoteStatus()
        if #miss == 0 then Log("Todos os " .. total .. " Remotes presentes", "ok")
        else Log("Remotes " .. have .. "/" .. total .. " — ausentes: "
            .. table.concat(miss, ", "), "warn") end
        if UpdateServerInfo then UpdateServerInfo() end
    end)

    DefCmd("center", "center", "traz a janela de volta para o centro da tela", function()
        if V8.Win then V8.Win.Center() end
    end)

    DefCmd("clear", "clear", "limpa o console", function()
        if ClearLog then ClearLog() end
        Log("Log limpo")
    end, "cls")

    DefCmd("reset", "reset", "volta às configurações padrão", function()
        if ApplyPreset then ApplyPreset("Default") end
        Log("Configurações restauradas", "ok")
    end)

    DefCmd("alloff", "alloff", "desliga todas as funções", function()
        for _, id in ipairs(ToggleOrder) do SetToggle(id, false, true) end
        StopSpectate()
        RefreshStatus()
        Log("Tudo desligado", "warn")
        Toast("Tudo desligado", "warn")
    end, "off")

    DefCmd("unload", "unload", "descarrega o painel", function()
        if Unload then Unload() end
    end)

    DefCmd("help", "help [comando]", "lista comandos ou explica um", function(args)
        if args[1] then
            local c = Commands[args[1]:lower()]
            if c then Log(c.usage .. "   —   " .. c.help, "ok")
            else Log("Sem ajuda para: " .. args[1], "warn") end
            return
        end
        local sorted = {}
        for _, n in ipairs(CmdNames) do table.insert(sorted, n) end
        table.sort(sorted)
        Log(#sorted .. " comandos: " .. table.concat(sorted, ", "))
        Log("Dica: Tab completa, ↑/↓ repete o histórico, Esc fecha.")
    end, "?")

    ----------------------------------------------------------------------------
    -- v8.0: situações, busca global e configuração em disco
    ----------------------------------------------------------------------------
    DefCmd("sit", "sit <situação>", "aplica uma situação", function(args)
        if not V8.Sit then Log("Situações indisponíveis", "error") return end
        local q = table.concat(args, " ")
        if q == "" then
            Log("Situações: " .. table.concat(V8.Sit.Order, ", "))
            return
        end
        local name = V8.Sit.Find(q)
        if not name then Log("Situação não encontrada: " .. q, "warn") return end
        V8.Sit.Apply(name)
    end, "modo")

    DefCmd("search", "search", "abre a busca global", function()
        if V8.Search then V8.Search.Open() else Log("Busca indisponível", "error") end
    end, "s")

    DefCmd("save", "save", "salva a configuração em disco", function()
        if V8.Cfg then V8.Cfg.Save() else Log("Persistência indisponível", "error") end
    end)

    DefCmd("loadcfg", "loadcfg", "carrega a configuração do disco", function()
        if V8.Cfg then V8.Cfg.Load() else Log("Persistência indisponível", "error") end
    end)

    ----------------------------------------------------------------------------
    -- abrir / fechar a barra
    ----------------------------------------------------------------------------
    ToggleCmdBar = function(show)
        CmdBar.Visible = show
        if show then
            CmdInput.Text = ""
            histPos = 0
            Hint.Visible = false
            CmdInput:CaptureFocus()
        else
            Hint.Visible = false
            pcall(function() CmdInput:ReleaseFocus() end)
        end
    end

    -- v8.0: hooks para a busca global (o do..end esconde os locais daqui)
    V8.RunCommand = RunCommand
    V8.Commands   = Commands
    V8.CmdNames   = CmdNames
    V8.OpenCmdBar = function(text)
        ToggleCmdBar(true)
        CmdInput.Text = text or ""
        CmdInput.CursorPosition = #CmdInput.Text + 1
    end

    CmdInput:GetPropertyChangedSignal("Text"):Connect(function()
        if CmdBar.Visible then pcall(ShowHints) end
    end)

    CmdInput.FocusLost:Connect(function(enter)
        local text = CmdInput.Text
        CmdInput.Text = ""
        ToggleCmdBar(false)
        if enter then RunCommand(text) end
    end)

    -- Tab completa, ↑/↓ percorre o histórico
    Conn.CmdKeys = UserInputService.InputBegan:Connect(function(input)
        if not CmdBar.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            pcall(Complete)
        elseif input.KeyCode == Enum.KeyCode.Up then
            pcall(Recall, 1)
        elseif input.KeyCode == Enum.KeyCode.Down then
            pcall(Recall, -1)
        end
    end)
end

