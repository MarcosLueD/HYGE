--------------------------------------------------------------------------------
-- v9.0 — DIAGNÓSTICO (Configurações › Sistema › Diagnóstico)
-- Num lugar só: o que este executor suporta, quanto o boot demorou, qual
-- módulo falhou (e em que linha do src/), memória, FPS/ping e os últimos
-- erros do log. COPIAR RELATÓRIO manda tudo para o clipboard — é o que pedir
-- para alguém quando "não funciona". Comando: diag.
-- Só calcula quando a aba Ajustes abre ou no botão (sem loop).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Diag = {}
        local D = V8.Diag

        local function Fn(f) return typeof(f) == "function" end
        local function Member(get)
            local ok, v = pcall(get)
            return ok and v ~= nil
        end

        D.Executor = function()
            local name
            pcall(function()
                if Fn(identifyexecutor) then
                    local a, b = identifyexecutor()
                    name = tostring(a) .. ((b ~= nil) and (" " .. tostring(b)) or "")
                elseif Fn(getexecutorname) then
                    name = tostring(getexecutorname())
                end
            end)
            return name or "não identificado"
        end

        -- { nome, tem?, para que serve }
        D.Caps = function()
            return {
                { "request()",    V8.Net and V8.Net.Fn() ~= nil, "enviar no Chat HYGE, trocar de servidor" },
                { "HttpGet",      Member(function() return game.HttpGet end), "ler catálogo e atualização" },
                { "Arquivos",     V8.Disk and V8.Disk.Ok() or false, "config, perfis, tempo de jogo" },
                { "Clipboard",    Fn(setclipboard), "copiar IDs, log e config" },
                { "loadstring",   Fn(loadstring), "atualizar sem sair do jogo" },
                { "gethui",       Fn(gethui), "GUI escondida do jogo" },
                { "getgenv",      Fn(getgenv), "loader e atualização" },
                { "GetObjects",   Member(function() return game.GetObjects end), "pacotes de animação" },
            }
        end

        -- v9.1: o Unload da sessão anterior (gravado em HYGE/unload.json)
        pcall(function()
            local raw = V8.Disk and V8.Disk.Read("HYGE/unload.json")
            if raw and V8.Net and V8.Net.Http then
                local d = V8.Net.Http:JSONDecode(raw)
                if type(d) == "table" and type(d.status) == "string" then D.PrevUnload = d end
            end
        end)

        -- pasta do src/ -> nome da seção "Modules"
        local GROUPS = {
            { "src/00_core/", "Core" }, { "src/10_ui/", "UI" }, { "src/20_features/", "Features" },
            { "src/30_kit/", "Kit" }, { "src/40_tabs/", "Tabs" }, { "src/50_v8/", "Painel" },
            { "src/90_runtime/", "Runtime" },
        }

        local function Count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

        -- v9.1: relatório em seções (Runtime, Modules, Connections, Tasks,
        -- Unload, Config, Erros) — o mesmo texto vai no COPIAR RELATÓRIO
        D.Lines = function()
            local out = {}
            local function add(s) table.insert(out, s) end
            local function head(s) if #out > 0 then add("") end add(s) end
            local mods, fails, total, slow = 0, {}, 0, {}
            for _, m in ipairs(V8.Mods) do
                mods = mods + 1
                total = total + (m.ms or 0)
                if not m.ok then table.insert(fails, m) end
                table.insert(slow, m)
            end
            table.sort(slow, function(a, b) return (a.ms or 0) > (b.ms or 0) end)

            add("HYGE DIAGNOSTICS")
            head("Runtime")
            local U = V8.Update
            local build = (U and U.MyBuild ~= "" and U.MyBuild) or "?"
            local how = "colado direto"
            if U and U.Loader then
                how = "loader" .. (U.Loader.verified and " (SHA-256 conferido)"
                    or (U.Loader.from and (" (" .. tostring(U.Loader.from) .. ")") or ""))
            end
            add("  Versão: HYGE " .. CONFIG.Version .. "  ·  build " .. build .. "  ·  " .. how)
            add("  Executor: " .. D.Executor())
            add("  Jogo: PlaceId " .. tostring(game.PlaceId) .. "  ·  JobId "
                .. (game.JobId ~= "" and game.JobId:sub(1, 8) .. "…" or "estúdio")
                .. "  ·  " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " jogadores")
            add(string.format("  Boot: %.2f s  ·  %d módulos isolados (%d ms)",
                (V8.BootMs or 0) / 1000, mods, math.floor(total + 0.5)))
            local lua, mem, ping = 0, 0, 0
            pcall(function() lua = gcinfo() / 1024 end)
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 2000) end)
            add(string.format("  Memória: Lua %.1f MB  ·  total %d MB  ·  FPS %d  ·  ping %d ms",
                lua, math.floor(mem), State.Fps or 0, ping))

            head("Modules")
            for _, g in ipairs(GROUPS) do
                local bad = {}
                for _, m in ipairs(fails) do
                    if m.name:sub(1, #g[1]) == g[1] then table.insert(bad, m) end
                end
                if #bad == 0 then
                    add("  " .. g[2] .. ": OK")
                else
                    add("  " .. g[2] .. ": " .. #bad .. " FALHOU")
                    for _, m in ipairs(bad) do add("    " .. m.name .. ": " .. tostring(m.err)) end
                end
            end
            if #slow > 0 then
                local t = {}
                for i = 1, math.min(3, #slow) do
                    local nm = slow[i].name:gsub("^src/", ""):gsub("%.lua$", "")
                    table.insert(t, nm .. " " .. math.floor(slow[i].ms + 0.5) .. " ms")
                end
                add("  Mais lentos: " .. table.concat(t, ", "))
            end

            head("Connections")
            local S = V8.Conns
            local active = Count(S.live)
            add(string.format("  Created: %d  ·  Active: %d  ·  Disconnected: %d", S.created, active, S.closed))
            if S.replaced > 0 then
                add("  Reaproveitadas sem Drop: " .. S.replaced .. " (eram vazamento; já desconectadas)")
            end
            local byMod = {}
            for _, meta in pairs(S.meta) do
                local w = V8.SrcOf(meta.lines)
                local mod = w and w:gsub("^src/", ""):gsub("%.lua:%d+$", "") or "?"
                byMod[mod] = (byMod[mod] or 0) + 1
            end
            local list = {}
            for mod, n in pairs(byMod) do table.insert(list, { mod, n }) end
            table.sort(list, function(a, b) return a[2] > b[2] end)
            if #list > 0 then
                local t = {}
                for i = 1, math.min(6, #list) do table.insert(t, list[i][1] .. " " .. list[i][2]) end
                add("  Ativas por módulo: " .. table.concat(t, " · "))
            end
            local r = S.respawns
            if #r == 0 then
                add("  Respawn: nenhum ainda (morra/renasça e confira de novo)")
            else
                local grow = #r >= 3 and r[#r] > r[#r - 1] and r[#r - 1] > r[#r - 2]
                add("  Respawn: boot " .. tostring(S.boot or "?") .. " → " .. table.concat(r, " → ")
                    .. (grow and "  << cresce a cada respawn: possível vazamento" or "  (estável)"))
            end

            head("Tasks")
            local T = V8.Tasks
            add(string.format("  Agendadas: %d  ·  pendentes: %d  ·  rodando agora: %d",
                T.scheduled, V8.Pending(), T.running))

            head("Unload")
            local P = D.PrevUnload
            if P then
                add(string.format("  Último (%s): %s — %d criadas, %d encerradas, %d ativas, %d rodando",
                    os.date("%d/%m %H:%M", tonumber(P.time) or 0), P.status, tonumber(P.created) or 0,
                    tonumber(P.closed) or 0, tonumber(P.active) or 0, tonumber(P.running) or 0))
                if type(P.left) == "table" and #P.left > 0 then
                    add("    sobrou: " .. table.concat(P.left, ", "))
                end
            else
                add("  Ainda sem registro (aparece depois do primeiro DESCARREGAR PAINEL)")
            end
            add("  Agora: o Unload encerraria " .. active .. " conexão(ões)")

            head("Config")
            local cfg = V8.Cfg and V8.Cfg.LoadState or nil
            add("  " .. (V8.Cfg and V8.Cfg.Supported() and "Em disco" or "Sem disco")
                .. (cfg and ("  ·  carregamento: " .. cfg) or "")
                .. "  ·  salvar sozinho " .. (SET.AutoSave and "ligado" or "desligado")
                .. ((V8.Cfg and V8.Cfg.Recoverable and #V8.Cfg.Recoverable > 0)
                    and ("  ·  dá para recuperar: " .. V8.Cfg.Recoverable[1].label) or ""))
            local PR = V8.Prof and V8.Prof.LastResult
            if PR then
                add("  Último perfil: " .. PR.name .. " (" .. PR.time .. ") — "
                    .. (PR.ok and ("aplicado" .. (#PR.rep.failed > 0 and (", não ligou: "
                        .. table.concat(PR.rep.failed, ", ")) or ""))
                        or ("RECUSADO: " .. table.concat(PR.rep.errors, "; ")
                            .. (PR.rep.rolledBack and " (voltou ao anterior)" or ""))))
            end
            local on = 0
            for _, id in ipairs(ToggleOrder) do if IsOn(id) then on = on + 1 end end
            add("  Funções ligadas " .. on .. "/" .. #ToggleOrder .. "  ·  registry de tema " .. #Painted
                .. "  ·  Remotes " .. (select(1, V8.RemoteStatus())) .. "/" .. #V8.RemoteInfo)
            -- v9.2: integração com o servidor (estado, cargo, pedidos sem resposta)
            if V8.Srv then
                local pend = 0
                for _ in pairs(V8.Srv.Pending) do pend = pend + 1 end
                add("  Servidor: " .. (V8.Srv.Summary()) .. "  ·  estado " .. V8.Srv.State
                    .. "  ·  pedidos aguardando " .. pend)
            end

            head("Executor")
            local caps = {}
            for _, c in ipairs(D.Caps()) do
                table.insert(caps, c[1] .. (c[2] and " sim" or " NÃO"))
            end
            add("  " .. table.concat(caps, " · "))

            head("Erros")
            if #V8.Errors > 0 then
                for i = math.max(1, #V8.Errors - 4), #V8.Errors do
                    local e = V8.Errors[i]
                    add("  [" .. e.time .. "] " .. e.msg)
                end
            else
                add("  Nenhum erro registrado nesta sessão.")
            end
            return out
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Diagnóstico
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "DIAGNÓSTICO", 19)
        SubLabel(card, "O que o executor suporta, o boot e os erros recentes. Se algo "
            .. "não funcionar, COPIAR RELATÓRIO e mande junto.", -1)

        local capGrid = Grid(card, 2, 30)
        capGrid.LayoutOrder = 1
        local capCells = {}
        for i, c in ipairs(D.Caps()) do
            local cell = Instance.new("Frame")
            cell.LayoutOrder = i
            cell.BackgroundColor3 = THEME.Btn
            cell.BorderSizePixel = 0
            cell.Parent = capGrid
            Paint(cell, "BackgroundColor3", "Btn")
            Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 8)
            local dot = Instance.new("Frame")
            dot.AnchorPoint = Vector2.new(0, 0.5)
            dot.Position = UDim2.new(0, 10, 0.5, 0)
            dot.Size = UDim2.new(0, 8, 0, 8)
            dot.BorderSizePixel = 0
            dot.Parent = cell
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            local lbl = Instance.new("TextLabel")
            lbl.Position = UDim2.new(0, 26, 0, 0)
            lbl.Size = UDim2.new(1, -32, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = c[1]
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = cell
            capCells[i] = { dot = dot, lbl = lbl }
        end

        local report = Instance.new("TextLabel")
        report.Size = UDim2.new(1, 0, 0, 0)
        report.AutomaticSize = Enum.AutomaticSize.Y
        report.BackgroundTransparency = 1
        report.Text = ""
        report.TextColor3 = THEME.Dim
        report.Font = Enum.Font.Code
        report.TextSize = 11
        report.TextWrapped = true
        report.TextXAlignment = Enum.TextXAlignment.Left
        report.TextYAlignment = Enum.TextYAlignment.Top
        report.LayoutOrder = 2
        report.Parent = card
        Paint(report, "TextColor3", "Dim")

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 3
        local bRefresh = CreateButton(g, "ATUALIZAR", "Accent", 32)
        bRefresh.LayoutOrder = 1
        local bCopy = CreateButton(g, "COPIAR RELATÓRIO", "Success", 32)
        bCopy.LayoutOrder = 2

        D.Render = function()
            for i, c in ipairs(D.Caps()) do
                local cell = capCells[i]
                if cell then
                    cell.dot.BackgroundColor3 = c[2] and THEME.Success or THEME.Danger
                    cell.lbl.TextColor3 = c[2] and THEME.Text or THEME.Dim
                    cell.lbl.Text = c[1] .. (c[2] and "" or "  —  não tem")
                end
            end
            report.Text = table.concat(D.Lines(), "\n")
        end

        D.Copy = function()
            local text = "HYGE — diagnóstico (" .. os.date("%d/%m/%Y %H:%M") .. ")\n"
                .. table.concat(D.Lines(), "\n")
            if Fn(setclipboard) and pcall(setclipboard, text) then
                Toast("Relatório copiado", "ok", 2)
                return true
            end
            print(text)
            Toast("Sem clipboard: o relatório foi para o console do Roblox (F9)", "warn", 3)
            return false
        end

        bRefresh.MouseButton1Click:Connect(function() pcall(D.Render) end)
        bCopy.MouseButton1Click:Connect(function() pcall(D.Render) D.Copy() end)
        OnTabOpen("Settings", function() pcall(D.Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(D.Render) end)
    end
    Build()
end
