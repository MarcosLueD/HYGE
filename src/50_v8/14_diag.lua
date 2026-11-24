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

        D.Lines = function()
            local out = {}
            local function add(s) table.insert(out, s) end
            local mods, fails, total = 0, {}, 0
            local slow = {}
            for _, m in ipairs(V8.Mods) do
                mods = mods + 1
                total = total + (m.ms or 0)
                if not m.ok then table.insert(fails, m) end
                table.insert(slow, m)
            end
            table.sort(slow, function(a, b) return (a.ms or 0) > (b.ms or 0) end)

            local build = (V8.Update and V8.Update.MyBuild ~= "" and V8.Update.MyBuild) or "?"
            add("HYGE " .. CONFIG.Version .. "  ·  build " .. build
                .. "  ·  " .. ((V8.Update and V8.Update.Loader) and "loader" or "colado direto"))
            add("Executor: " .. D.Executor())
            add("Jogo: PlaceId " .. tostring(game.PlaceId) .. "  ·  JobId "
                .. (game.JobId ~= "" and game.JobId:sub(1, 8) .. "…" or "estúdio")
                .. "  ·  " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " jogadores")
            add(string.format("Boot: %d ms  ·  %d módulos isolados (%d ms)  ·  %d falha(s)",
                math.floor(V8.BootMs or 0), mods, math.floor(total + 0.5), #fails))
            for _, m in ipairs(fails) do
                add("  FALHOU " .. m.name .. ": " .. tostring(m.err))
            end
            if #slow > 0 then
                local t = {}
                for i = 1, math.min(3, #slow) do
                    local nm = slow[i].name:gsub("^src/", ""):gsub("%.lua$", "")
                    table.insert(t, nm .. " " .. math.floor(slow[i].ms + 0.5) .. " ms")
                end
                add("Mais lentos: " .. table.concat(t, ", "))
            end

            local lua = 0
            pcall(function() lua = gcinfo() / 1024 end)
            local mem = 0
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 2000) end)
            add(string.format("FPS %d  ·  ping %d ms  ·  memória Lua %.1f MB  ·  total %d MB",
                State.Fps or 0, ping, lua, math.floor(mem)))

            local conns, on = 0, 0
            for _ in pairs(Conn) do conns = conns + 1 end
            for _, id in ipairs(ToggleOrder) do if IsOn(id) then on = on + 1 end end
            add("Conexões " .. conns .. "  ·  registry de tema " .. #Painted
                .. "  ·  funções ligadas " .. on .. "/" .. #ToggleOrder
                .. "  ·  Remotes " .. (select(1, V8.RemoteStatus())) .. "/" .. #V8.RemoteInfo)

            local cfg = V8.Cfg and V8.Cfg.LoadState or nil
            add("Config: " .. (V8.Cfg and V8.Cfg.Supported() and "em disco" or "sem disco")
                .. (cfg and ("  ·  carregamento: " .. cfg) or "")
                .. "  ·  salvar sozinho " .. (SET.AutoSave and "ligado" or "desligado")
                .. ((V8.Prof and V8.Prof.Current) and ("  ·  perfil " .. V8.Prof.Current) or ""))

            local caps = {}
            for _, c in ipairs(D.Caps()) do
                table.insert(caps, c[1] .. (c[2] and " sim" or " NÃO"))
            end
            add("Executor tem: " .. table.concat(caps, " · "))

            if #V8.Errors > 0 then
                add("Últimos erros (" .. #V8.Errors .. "):")
                for i = math.max(1, #V8.Errors - 4), #V8.Errors do
                    local e = V8.Errors[i]
                    add("  [" .. e.time .. "] " .. e.msg)
                end
            else
                add("Nenhum erro registrado nesta sessão.")
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
