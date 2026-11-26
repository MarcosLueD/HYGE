--------------------------------------------------------------------------------
-- v9.0 — CENTRAL DE NOTIFICAÇÕES
-- Todo Toast passa a ficar guardado (os últimos 60). O sino na ilha do topo
-- mostra quantos chegaram desde a última olhada; clicar abre a lista.
-- "Não perturbe": nada pula na tela (menos erro), tudo continua no sino.
-- "Tempo dos avisos": 50% a 200% da duração normal de cada aviso.
-- Sem loop próprio: só embrulha o Toast. Tudo dentro de Build().
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Notif = { List = {}, Unread = 0, Max = 60, Shown = false }
        local N = V8.Notif
        if SET.Dnd == nil then SET.Dnd = false end
        if type(SET.ToastDur) ~= "number" then SET.ToastDur = 100 end

        local KIND = { info = "Accent", ok = "Success", warn = "Warning",
                       error = "Danger", action = "Accent2" }

        ----------------------------------------------------------------------------
        -- sino na ilha (se a ilha existir)
        ----------------------------------------------------------------------------
        local bell, bellIco, badge
        -- v9.3: cores do HUD (V8.Hud) quando o módulo de estilo existe
        local HC = V8.Hud and V8.Hud.C
        if V8.Island and V8.Island.Pill then
            -- v9.3: sempre o último da ilha, depois de um separador
            if V8.Island.Sep then V8.Island.Sep(19) end
            bell = Instance.new("TextButton")
            bell.Name = "Bell"
            bell.Size = UDim2.new(0, 24, 0, 24)
            bell.BackgroundTransparency = 1
            bell.Text = ""
            bell.AutoButtonColor = false
            bell.LayoutOrder = 20
            bell.ZIndex = 21
            bell.Parent = V8.Island.Pill
            bellIco = Icon(bell, "bell", HC and HC.IconDim or THEME.Dim, 16)
            bellIco.AnchorPoint = Vector2.new(0.5, 0.5)
            bellIco.Position = UDim2.new(0.5, 0, 0.5, 0)

            badge = Instance.new("TextLabel")
            badge.AnchorPoint = Vector2.new(1, 0)
            badge.Position = UDim2.new(1, 6, 0, -4)
            badge.Size = UDim2.new(0, 16, 0, 14)
            badge.BackgroundColor3 = THEME.Danger
            badge.BorderSizePixel = 0
            badge.Text = ""
            badge.TextColor3 = Color3.new(1, 1, 1)
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 9
            badge.Visible = false
            badge.ZIndex = 23
            badge.Parent = bell
            Paint(badge, "BackgroundColor3", "Danger")
            Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
        end

        N.Badge = function()
            if not badge then return end
            badge.Visible = N.Unread > 0
            badge.Text = (N.Unread > 9) and "9+" or tostring(N.Unread)
            badge.Size = UDim2.new(0, (N.Unread > 9) and 20 or 15, 0, 14)
            if HC then
                IconTint(bellIco, SET.Dnd and HC.Warn or (N.Unread > 0 and HC.Icon or HC.IconDim))
            else
                IconTint(bellIco, SET.Dnd and THEME.Warning or (N.Unread > 0 and THEME.Text or THEME.Dim))
            end
        end

        ----------------------------------------------------------------------------
        -- painel da lista (abaixo da ilha)
        ----------------------------------------------------------------------------
        local catcher = Instance.new("TextButton")   -- clique fora fecha
        catcher.Name = "NotifCatcher"
        catcher.Size = UDim2.new(1, 0, 1, 0)
        catcher.BackgroundTransparency = 1
        catcher.Text = ""
        catcher.AutoButtonColor = false
        catcher.Visible = false
        catcher.ZIndex = 44
        catcher.Parent = Gui

        local panel = Instance.new("Frame")
        panel.Name = "Notifications"
        panel.AnchorPoint = Vector2.new(0.5, 0)
        panel.Position = UDim2.new(0.5, 0, 0, 50)
        panel.Size = UDim2.new(0, 340, 0, 340)
        panel.BackgroundColor3 = THEME.Card
        panel.BorderSizePixel = 0
        panel.Visible = false
        panel.ZIndex = 45
        panel.Parent = Gui
        Paint(panel, "BackgroundColor3", "Card")
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
        do
            local st = Instance.new("UIStroke", panel)
            st.Transparency = 0.2
            Paint(st, "Color", "Line")
        end

        local title = Instance.new("TextLabel")
        title.Position = UDim2.new(0, 14, 0, 10)
        title.Size = UDim2.new(0, 140, 0, 24)
        title.BackgroundTransparency = 1
        title.Text = "Notificações"
        title.TextColor3 = THEME.Text
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = panel
        Paint(title, "TextColor3", "Text")

        local bDnd = CreateButton(panel, "NÃO PERTURBE", "Warning", 24)
        bDnd.AnchorPoint = Vector2.new(1, 0)
        bDnd.Position = UDim2.new(1, -82, 0, 10)
        bDnd.Size = UDim2.new(0, 104, 0, 24)
        bDnd.TextSize = 10

        local bClear = CreateButton(panel, "LIMPAR", "Danger", 24)
        bClear.AnchorPoint = Vector2.new(1, 0)
        bClear.Position = UDim2.new(1, -12, 0, 10)
        bClear.Size = UDim2.new(0, 64, 0, 24)
        bClear.TextSize = 10

        local scroll = Instance.new("ScrollingFrame")
        scroll.Position = UDim2.new(0, 10, 0, 44)
        scroll.Size = UDim2.new(1, -20, 1, -54)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = panel
        Paint(scroll, "ScrollBarImageColor3", "Accent")
        do
            local l = Instance.new("UIListLayout", scroll)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -6, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "Nenhum aviso por enquanto."
        empty.TextColor3 = THEME.Dim
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 12
        empty.LayoutOrder = 9999
        empty.Parent = scroll
        Paint(empty, "TextColor3", "Dim")

        local function PaintDnd()
            bDnd.Text = SET.Dnd and "NÃO PERTURBE: ON" or "NÃO PERTURBE"
            bDnd.Size = UDim2.new(0, SET.Dnd and 128 or 104, 0, 24)
        end

        -- linhas desenhadas na hora de abrir (não entram no registry de tema)
        N.Render = function()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            empty.Visible = (#N.List == 0)
            for i, e in ipairs(N.List) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -6, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = THEME.Btn
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                row.Parent = scroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)
                local pad = Instance.new("UIPadding", row)
                pad.PaddingTop = UDim.new(0, 7)
                pad.PaddingBottom = UDim.new(0, 7)
                pad.PaddingLeft = UDim.new(0, 10)
                pad.PaddingRight = UDim.new(0, 10)

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 7, 0, 7)
                dot.Position = UDim2.new(0, 0, 0, 5)
                dot.BackgroundColor3 = THEME[KIND[e.kind] or "Accent"]
                dot.BorderSizePixel = 0
                dot.Parent = row
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                local txt = Instance.new("TextLabel")
                txt.Position = UDim2.new(0, 15, 0, 0)
                txt.Size = UDim2.new(1, -58, 0, 0)
                txt.AutomaticSize = Enum.AutomaticSize.Y
                txt.BackgroundTransparency = 1
                txt.Text = e.text
                txt.TextColor3 = THEME.Text
                txt.Font = Enum.Font.GothamMedium
                txt.TextSize = 12
                txt.TextWrapped = true
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.Parent = row

                local tm = Instance.new("TextLabel")
                tm.AnchorPoint = Vector2.new(1, 0)
                tm.Position = UDim2.new(1, 0, 0, 0)
                tm.Size = UDim2.new(0, 40, 0, 16)
                tm.BackgroundTransparency = 1
                tm.Text = e.t .. ((e.n or 1) > 1 and (" x" .. e.n) or "")
                tm.TextColor3 = THEME.Dim
                tm.Font = Enum.Font.Code
                tm.TextSize = 10
                tm.TextXAlignment = Enum.TextXAlignment.Right
                tm.Parent = row
            end
            PaintDnd()
            scroll.CanvasPosition = Vector2.new(0, 0)
        end

        N.Open = function()
            N.Shown = true
            N.Unread = 0
            N.Badge()
            N.Render()
            -- logo abaixo da ilha quando ela está na tela; senão no topo
            local island = V8.Island and V8.Island.Pill
            local y = (island and island.Visible) and 50 or 14
            panel.Position = UDim2.new(0.5, 0, 0, y)
            catcher.Visible = true
            panel.Visible = true
        end
        N.Close = function()
            N.Shown = false
            catcher.Visible = false
            panel.Visible = false
        end
        N.IsOpen = function() return N.Shown end
        N.Clear = function()
            for i = #N.List, 1, -1 do N.List[i] = nil end
            N.Unread = 0
            N.Badge()
            if N.Shown then N.Render() end
        end
        N.SetDnd = function(on)
            SET.Dnd = on and true or false
            N.Badge()
            PaintDnd()
            if N.Render2 then pcall(N.Render2) end
        end

        if bell then
            bell.MouseButton1Click:Connect(function()
                if N.Shown then N.Close() else N.Open() end
            end)
        end
        catcher.MouseButton1Click:Connect(N.Close)
        bClear.MouseButton1Click:Connect(N.Clear)
        bDnd.MouseButton1Click:Connect(function()
            N.SetDnd(not SET.Dnd)
            Log("Não perturbe: " .. (SET.Dnd and "ligado" or "desligado"), "action")
        end)
        Conn.NotifKeys = UserInputService.InputBegan:Connect(function(input)
            if N.Shown and input.KeyCode == Enum.KeyCode.Escape then N.Close() end
        end)

        ----------------------------------------------------------------------------
        -- guarda TODO aviso (repetido seguido vira "x2", "x3"...)
        ----------------------------------------------------------------------------
        -- o número do sino conta só o que pede atenção: aviso, erro e mensagens
        -- longas (atualização, mensagem de admin...). "Fly ativado" fica na
        -- lista mas não acende o sino.
        N.Push = function(text, kind, duration)
            text = tostring(text)
            local top = N.List[1]
            if top and top.text == text and top.kind == kind then
                top.n = (top.n or 1) + 1
                top.t = os.date("%H:%M")
            else
                table.insert(N.List, 1, { t = os.date("%H:%M"), text = text, kind = kind, n = 1 })
                while #N.List > N.Max do table.remove(N.List) end
            end
            -- ("desativado" é um aviso curto, 1.6 s: não conta)
            local dur = tonumber(duration) or 2.6
            local important = kind == "error" or dur >= 4 or (kind == "warn" and dur >= 2.6)
            if important and not N.Shown then N.Unread = N.Unread + 1 end
            N.Badge()
            if N.Shown then N.Render() end
        end

        local base = Toast
        Toast = function(text, kind, duration)
            kind = (kind and KIND[kind]) and kind or "info"
            pcall(N.Push, text, kind, duration)
            if SET.Dnd and kind ~= "error" then return end
            local mult = math.clamp((tonumber(SET.ToastDur) or 100) / 100, 0.5, 2)
            return base(text, kind, (duration or 2.6) * mult)
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Notificações
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "NOTIFICAÇÕES", 10)
        SubLabel(card, "Todo aviso fica guardado no sino da ilha do topo (os últimos "
            .. N.Max .. "). Clique no sino para ver; o número mostra os que você não viu.", -1)
        local dndRender = CheckRow(card, "Não perturbe",
            "Nenhum aviso pula na tela (erros continuam); tudo fica no sino",
            function() return SET.Dnd == true end,
            function(v) N.SetDnd(v) end, 1)
        N.Render2 = dndRender
        local durSet = SliderRow(card, {
            label = "Tempo dos avisos na tela", min = 50, max = 200, def = SET.ToastDur,
            suffix = "%", order = 2,
            apply = function(v) SET.ToastDur = v end,
        })
        local g = Grid(card, 2, 32)
        g.LayoutOrder = 3
        local bOpen = CreateButton(g, "VER HISTÓRICO", "Accent", 32)
        bOpen.LayoutOrder = 1
        bOpen.MouseButton1Click:Connect(function() N.Open() end)
        local bWipe = CreateButton(g, "LIMPAR HISTÓRICO", "Danger", 32)
        bWipe.LayoutOrder = 2
        bWipe.MouseButton1Click:Connect(N.Clear)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function()
            pcall(durSet, tonumber(SET.ToastDur) or 100, true)
            pcall(N.Badge)
            pcall(PaintDnd)
        end)
        N.Badge()
        PaintDnd()
    end
    Build()
end
