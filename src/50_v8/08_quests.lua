--------------------------------------------------------------------------------
-- v8.2 — MISSÕES E BÔNUS DIÁRIO (Playtime Shop › Missões de hoje)
-- Mais um jeito de ganhar pontos além do 1/minuto:
--   * bônus diário: na primeira vez que o painel abre no dia. Dias seguidos
--     aumentam o bônus (10, 15, 20... até 40 no 7º dia); pulou um dia, a
--     sequência volta para 1
--   * missões do dia: zeram à meia-noite (hora do seu computador). Completa,
--     aparece RESGATAR; os pontos entram no saldo na hora
-- O progresso mora em V8.Play.Quests e vai no HYGE/playtime.json junto com os
-- pontos (salvo a cada minuto e no unload).
-- Contadores: tempo e voo pelo scheduler (1/s); emotes embrulhando Emote.Play;
-- waypoints pelo tamanho da lista; pacote pelo SET.PackOn.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local P = V8.Play
        if not P then return end
        V8.Quest = {}
        local Q = V8.Quest

        Q.Defs = {
            { id = "online", name = "Fique 30 min com o HYGE aberto", goal = 1800, min = true, reward = 20 },
            { id = "fly",    name = "Voe por 10 minutos",             goal = 600,  min = true, reward = 30 },
            { id = "emotes", name = "Toque 5 emotes",                 goal = 5,    reward = 15 },
            { id = "wp",     name = "Salve 1 waypoint",               goal = 1,    reward = 10 },
            { id = "pack",   name = "Use um pacote de animação",      goal = 1,    reward = 10 },
        }

        local function Today() return os.date("%Y-%m-%d") end
        local function Yesterday() return os.date("%Y-%m-%d", os.time() - 86400) end

        Q.Bonus = function(streak)
            return 10 + 5 * (math.clamp(streak or 1, 1, 7) - 1)
        end

        -- dados validados (o que veio do arquivo pode estar faltando campo)
        Q.Data = function()
            local d = P.Quests
            if type(d) ~= "table" then
                d = {}
                P.Quests = d
            end
            if type(d.prog) ~= "table" then d.prog = {} end
            if type(d.claimed) ~= "table" then d.claimed = {} end
            d.streak = math.max(0, math.floor(tonumber(d.streak) or 0))
            if d.day ~= Today() then
                d.day = Today()
                d.prog, d.claimed = {}, {}
            end
            for _, m in ipairs(Q.Defs) do
                local v = tonumber(d.prog[m.id]) or 0
                d.prog[m.id] = math.clamp(v, 0, m.goal)
                if d.claimed[m.id] ~= true then d.claimed[m.id] = nil end
            end
            return d
        end

        Q.Add = function(id, n)
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                if m.id == id then
                    local before = d.prog[id]
                    d.prog[id] = math.min(m.goal, before + (n or 1))
                    if before < m.goal and d.prog[id] >= m.goal then
                        Log("Missão completa: " .. m.name .. " — resgate +" .. m.reward
                            .. " na Playtime Shop", "ok")
                        Toast("Missão completa: " .. m.name, "ok", 3)
                        if Q.Render then pcall(Q.Render) end
                    end
                    return
                end
            end
        end

        Q.Claim = function(id)
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                if m.id == id then
                    if d.claimed[id] then return false, "já resgatada" end
                    if d.prog[id] < m.goal then return false, "ainda não completou" end
                    d.claimed[id] = true
                    P.Grant(m.reward)   -- salva e avisa a loja
                    Log("Missão resgatada: " .. m.name .. " (+" .. m.reward .. " pontos)", "ok")
                    Toast("+" .. m.reward .. " pontos", "ok", 2)
                    return true, m.reward
                end
            end
            return false, "missão desconhecida"
        end

        -- bônus diário: 1x por dia, na primeira checagem do dia
        Q.Daily = function()
            local d = Q.Data()
            local today = Today()
            if d.last == today then return false end
            d.streak = (d.last == Yesterday()) and (d.streak + 1) or 1
            d.last = today
            local pts = Q.Bonus(d.streak)
            P.Grant(pts)
            Log("Bônus diário: +" .. pts .. " pontos (" .. d.streak .. " dia(s) seguido(s))", "ok")
            Toast("Bônus diário: +" .. pts .. " pontos", "ok", 3)
            return true, pts
        end

        -- contadores (o scheduler roda 1x/s; o dia vira sozinho)
        do
            local lastWp = #State.Waypoints
            local lastDay = Today()
            V8.Job(1, function()
                Q.Add("online", 1)
                if IsOn("fly") then Q.Add("fly", 1) end
                local n = #State.Waypoints
                if n > lastWp then Q.Add("wp", n - lastWp) end
                lastWp = n
                if SET.PackOn then Q.Add("pack", 1) end
                if Today() ~= lastDay then
                    lastDay = Today()
                    Q.Daily()
                    if Q.Render then pcall(Q.Render) end
                end
            end)
            -- a lista de waypoints é trocada inteira ao carregar a config: não conta
            Q.ResyncWp = function() lastWp = #State.Waypoints end
        end

        -- emotes tocados com sucesso (o catálogo, os favoritos e o comando
        -- chamam Emote.Play pela tabela, então o embrulho pega todos)
        if Emote.Play then
            local base = Emote.Play
            Emote.Play = function(...)
                local ok = base(...)
                if ok then Q.Add("emotes", 1) end
                return ok
            end
        end

        ----------------------------------------------------------------------------
        -- UI: Playtime Shop › Missões de hoje
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Shop, "MISSÕES DE HOJE", 2)
        local streakLbl = SubLabel(card, "", 0)

        local rows = {}
        for i, m in ipairs(Q.Defs) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = card
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -130, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 6)
            nm.BackgroundTransparency = 1
            nm.Text = m.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -190, 0, 6)
            bar.Position = UDim2.new(0, 12, 0, 32)
            bar.BackgroundColor3 = THEME.Track
            bar.BorderSizePixel = 0
            bar.Parent = row
            Paint(bar, "BackgroundColor3", "Track")
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar
            Paint(fill, "BackgroundColor3", "Accent")
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local prog = Instance.new("TextLabel")
            prog.AnchorPoint = Vector2.new(1, 0)
            prog.Size = UDim2.new(0, 64, 0, 14)
            prog.Position = UDim2.new(1, -112, 0, 28)
            prog.BackgroundTransparency = 1
            prog.Text = ""
            prog.TextColor3 = THEME.Dim
            prog.Font = Enum.Font.GothamMedium
            prog.TextSize = 10
            prog.TextXAlignment = Enum.TextXAlignment.Right
            prog.Parent = row
            Paint(prog, "TextColor3", "Dim")

            local b = CreateButton(row, "", "Success", 30)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -10, 0.5, 0)
            b.Size = UDim2.new(0, 92, 0, 30)
            b.TextSize = 11
            b.Font = Enum.Font.GothamBold
            b.MouseButton1Click:Connect(function()
                local ok, why = Q.Claim(m.id)
                if not ok then Toast(tostring(why), nil, 2) end
                pcall(Q.Render)
            end)

            rows[m.id] = { fill = fill, prog = prog, btn = b }
        end

        local function Fmt(m, v)
            if m.min then
                return math.floor(v / 60) .. "/" .. math.floor(m.goal / 60) .. " min"
            end
            return v .. "/" .. m.goal
        end

        Q.Render = function()
            local d = Q.Data()
            for _, m in ipairs(Q.Defs) do
                local r = rows[m.id]
                local v = d.prog[m.id]
                r.fill.Size = UDim2.new(math.clamp(v / m.goal, 0, 1), 0, 1, 0)
                r.prog.Text = Fmt(m, v)
                if d.claimed[m.id] then
                    r.btn.Text = "FEITO"
                    r.btn.TextColor3 = THEME.Dim
                elseif v >= m.goal then
                    r.btn.Text = "RESGATAR +" .. m.reward
                    r.btn.TextColor3 = THEME.Success
                else
                    r.btn.Text = "+" .. m.reward .. " PTS"
                    r.btn.TextColor3 = THEME.Dim
                end
            end
            local s = math.max(d.streak, 1)
            streakLbl.Text = "Bônus diário: " .. d.streak .. " dia(s) seguido(s) — hoje +"
                .. Q.Bonus(s) .. (d.last == Today() and " (recebido)" or "")
                .. ", amanhã +" .. Q.Bonus(s + 1) .. ". As missões zeram à meia-noite."
        end

        -- a loja já tem um TabTick (saldo): roda os dois
        do
            local base = V8.TabTick.Shop
            V8.TabTick.Shop = function()
                if base then base() end
                Q.Render()
            end
        end
        P.OnChange(function() pcall(Q.Render) end)
        OnTabOpen("Shop", function() pcall(Q.Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(Q.Render) end)

        Q.Boot = function()
            Q.ResyncWp()
            Q.Daily()
            Q.Render()
        end
        Q.Render()
    end
    Build()
end
