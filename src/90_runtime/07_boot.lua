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
    BootStep("Friends",       function() if V8.Dash then V8.Dash.Friends(true) end end)
    BootStep("SetOpen",       function() SetOpen(true) end)

    -- garante que sempre existe um jeito de abrir, mesmo se algo acima falhar
    Gui.Enabled = true
    Orb.Visible = not isOpen

    print("[HYGE] pronto. Aperte " .. KeyName(CONFIG.PanelKey) .. " ou clique na bolinha.")

    Log("HYGE " .. CONFIG.Version .. " carregado", "ok")
    Log("[" .. KeyName(CONFIG.PanelKey) .. "] painel  •  ["
        .. KeyName(CONFIG.ConsoleKey) .. "] comandos  •  'help' lista tudo")
    Log("["
        .. (CONFIG.SearchCtrl and "Ctrl+" or "")
        .. KeyName(CONFIG.SearchKey) .. "] busca global  •  [Keypad 1-6] situações", "ok")
    if #falhas > 0 then
        Log("Boot com falhas em: " .. table.concat(falhas, ", "), "error")
        Toast("Boot parcial — veja o log", "error", 5)
    else
        Toast("HYGE " .. CONFIG.Version .. " pronto — aperte " .. KeyName(CONFIG.PanelKey), "ok", 4)
    end
end
