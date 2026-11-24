--------------------------------------------------------------------------------
-- BOOT
--------------------------------------------------------------------------------
do
    local falhas = {}
    local function BootStep(name, fn)
        local ok, err = pcall(fn)
        if not ok then
            warn("[HYGE] falha no boot (" .. name .. "): " .. tostring(err))
            table.insert(falhas, name)
        end
        return ok
    end

    BootStep("ShowTab",       function() ShowTab("Home") end)
    BootStep("RefreshStatus", function() RefreshStatus() end)
    BootStep("PlayerRows",    function() if RebuildPlayerRows then RebuildPlayerRows() end end)
    BootStep("Waypoints",     function() if RenderWaypoints then RenderWaypoints() end end)
    BootStep("ServerInfo",    function() if UpdateServerInfo then UpdateServerInfo() end end)
    BootStep("Config",        function() if V8.Cfg then V8.Cfg.Load(true) end end)
    -- v8.1: funções marcadas em Configurações › Automático (depois da config)
    BootStep("Automático",    function() if V8.Auto then V8.Auto.Run() end end)
    -- v9.0: perfil marcado para este jogo (ganha da config e do Automático)
    BootStep("Perfil do jogo", function() if V8.Prof then V8.Prof.Boot() end end)
    BootStep("Cosméticos",    function() if V8.Cos then V8.Cos.Apply() end end)
    -- v8.2: pacote salvo no personagem, missões/bônus diário, tela do celular
    -- e conferência de versão nova (todos depois da config carregada)
    BootStep("Pacote",        function() if V8.Pack then V8.Pack.Boot() end end)
    BootStep("Missões",       function() if V8.Quest then V8.Quest.Boot() end end)
    BootStep("Celular",       function() if V8.Mobile then V8.Mobile.Fit() V8.Mobile.Render() end end)
    BootStep("Atualização",   function() if V8.Update then V8.Update.Boot() end end)
    BootStep("Voo",           function() if V8.FlyStyleRender then V8.FlyStyleRender() end end)
    -- v9.0: a lista de amigos é uma chamada web (espera a resposta): vai em
    -- paralelo, o painel abre sem esperar por ela
    BootStep("Friends",       function()
        if V8.Dash then task.spawn(function() pcall(V8.Dash.Friends, true) end) end
    end)
    BootStep("SetOpen",       function() SetOpen(true) end)
    -- v8.0: em tela baixa a janela "acima do dock" pode nascer cortada
    BootStep("Janela",        function() if V8.Win then task.defer(V8.Win.Clamp) end end)
    -- v9.0: cartão de novidades (uma vez por versão)
    BootStep("Novidades",     function() if V8.News then V8.News.Boot() end end)

    -- v9.0: módulos que quebraram ao carregar (o resto do painel abriu)
    local modFails = {}
    for _, m in ipairs(V8.Mods) do
        if not m.ok then
            table.insert(modFails, (m.name:gsub("^src/", "")))
            Log("Módulo " .. m.name .. " não carregou: " .. tostring(m.err), "error")
        end
    end
    if #modFails > 0 then
        table.insert(falhas, #modFails .. " módulo(s): " .. table.concat(modFails, ", "))
    end
    V8.BootMs = (os.clock() - (V8.BootT0 or os.clock())) * 1000
    -- v9.1: conexões vivas logo depois do boot (base para o monitor de respawn)
    pcall(function()
        local n = 0
        for _ in pairs(V8.Conns.live) do n = n + 1 end
        V8.Conns.boot = n
    end)

    -- garante que sempre existe um jeito de abrir, mesmo se algo acima falhar:
    -- o dock (padrão) ou, no modo sidebar, a bolinha H
    Gui.Enabled = true
    Orb.Visible = (not isOpen) and (SET.Dock ~= true)

    print("[HYGE] pronto. Aperte " .. KeyName(CONFIG.PanelKey)
        .. (SET.Dock == true and " ou use o dock no rodapé." or " ou clique na bolinha."))

    Log("HYGE " .. CONFIG.Version .. " carregado", "ok")
    Log("[" .. KeyName(CONFIG.PanelKey) .. "] painel  •  ["
        .. KeyName(CONFIG.ConsoleKey) .. "] comandos  •  'help' lista tudo")
    Log("["
        .. (CONFIG.SearchCtrl and "Ctrl+" or "")
        .. KeyName(CONFIG.SearchKey) .. "] busca global  •  [Keypad 1-6] situações", "ok")
    if #falhas > 0 then
        Log("Boot com falhas em: " .. table.concat(falhas, ", "), "error")
        Toast("Boot parcial — veja Configurações › Diagnóstico", "error", 5)
    else
        Log(string.format("Boot em %d ms (%d módulos isolados)", math.floor(V8.BootMs), #V8.Mods), "ok")
        Toast("HYGE " .. CONFIG.Version .. " pronto — aperte " .. KeyName(CONFIG.PanelKey), "ok", 4)
    end
end
