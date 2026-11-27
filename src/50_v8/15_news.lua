--------------------------------------------------------------------------------
-- v9.0 — NOVIDADES / BOAS-VINDAS
-- Na primeira vez que uma versão nova abre, aparece um cartão com o que
-- mudou. Quem nunca usou o HYGE (sem config salva) vê os primeiros passos.
-- Aparece uma vez por versão (SET.SeenVersion, vai na config). Reabrir:
-- comando 'novidades' ou Configurações › Sobre.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.News = {}
        local W = V8.News

        -- já existia config ANTES deste boot? (decide boas-vindas x novidades)
        W.HadConfig = false
        pcall(function()
            if V8.Cfg and V8.Cfg.Supported() and isfile(V8.Cfg.Path) then W.HadConfig = true end
        end)

        -- v9.4: o visual do logo no painel inteiro
        W.Subtitle = "Visual novo, com as cores do logo:"
        W.Items = {
            { "gem",      "Tema HYGE", "Azul-marinho com rosa neon, as cores do logo. É o padrão agora; quem usava o Grafite passou para ele — os outros temas continuam em Configurações › Aparência." },
            { "layers",   "Janela neon", "Borda rosa com um brilho que respira devagar e um véu azul no alto. No cabeçalho, o triângulo do logo e o \"HYGE\" em degradê." },
            { "home",     "Faixa do Início", "O logo refeito no topo do Início: triângulo neon, \"HYGE\" por cima, a bolinha e o brilho. A coruja aparece com CONFIG.MascotId." },
            { "bolt",     "Detalhes que acendem", "Switches ligados e sliders brilham, botões têm contorno neon, títulos de seção ganham um tracinho e os cartões, um vidro." },
            { "signal",   "Ilha e dock", "As barras do HUD trocaram o neon azul pelo rosa do logo, em vidro índigo. Mesmos botões, mesmo lugar." },
        }
        -- função: as teclas podem ter mudado depois que a config carregou
        W.Tips = function()
            return {
                { "home",     "Dock no rodapé", "Cada ícone abre uma seção. Clique de novo para fechar." },
                { "keyboard", "Teclas", "[" .. KeyName(CONFIG.PanelKey) .. "] abre/fecha  ·  ["
                    .. KeyName(CONFIG.ConsoleKey) .. "] comandos  ·  "
                    .. (CONFIG.SearchCtrl and "Ctrl+" or "") .. KeyName(CONFIG.SearchKey) .. " busca tudo." },
                { "star",     "Favoritos", "A estrela ao lado de cada função fixa ela na Home." },
                { "gear",     "Do seu jeito", "Temas, teclas e perfis em Configurações." },
            }
        end

        local overlay, box, titleLbl, subLbl, list

        local function Row(parent, order, item)
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, 0)
            r.AutomaticSize = Enum.AutomaticSize.Y
            r.BackgroundTransparency = 1
            r.LayoutOrder = order
            r.Parent = parent
            local pad = Instance.new("Frame")
            pad.Size = UDim2.new(0, 30, 0, 30)
            pad.BackgroundColor3 = THEME.Btn
            pad.BorderSizePixel = 0
            pad.Parent = r
            Instance.new("UICorner", pad).CornerRadius = UDim.new(0, 9)
            local ic = Icon(pad, item[1], THEME.Accent, 16)
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.Position = UDim2.new(0.5, 0, 0.5, 0)
            local t = Instance.new("TextLabel")
            t.Position = UDim2.new(0, 42, 0, 0)
            t.Size = UDim2.new(1, -42, 0, 16)
            t.BackgroundTransparency = 1
            t.Text = item[2]
            t.TextColor3 = THEME.Text
            t.Font = Enum.Font.GothamBold
            t.TextSize = 13
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = r
            local d = Instance.new("TextLabel")
            d.Position = UDim2.new(0, 42, 0, 17)
            d.Size = UDim2.new(1, -42, 0, 0)
            d.AutomaticSize = Enum.AutomaticSize.Y
            d.BackgroundTransparency = 1
            d.Text = item[3]
            d.TextColor3 = THEME.Dim
            d.Font = Enum.Font.GothamMedium
            d.TextSize = 11
            d.TextWrapped = true
            d.TextXAlignment = Enum.TextXAlignment.Left
            d.Parent = r
        end

        local function Create()
            overlay = Instance.new("Frame")
            overlay.Name = "News"
            overlay.Size = UDim2.new(1, 0, 1, 0)
            overlay.BackgroundColor3 = Color3.new(0, 0, 0)
            overlay.BackgroundTransparency = 0.4
            overlay.Visible = false
            overlay.ZIndex = 65
            overlay.Parent = Gui

            box = Instance.new("Frame")
            box.AnchorPoint = Vector2.new(0.5, 0.5)
            box.Position = UDim2.new(0.5, 0, 0.5, 0)
            box.Size = UDim2.new(0, 430, 0, 470)
            box.BackgroundColor3 = THEME.Card
            box.BorderSizePixel = 0
            box.Parent = overlay
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 18)
            local st = Instance.new("UIStroke", box)
            st.Color = THEME.Line
            st.Transparency = 0.1

            -- v9.4: borda neon + a marca do logo ao lado do título
            local tx = 22
            if V8.Brand then
                pcall(function()
                    st.Color = THEME.Accent
                    st.Transparency = 0.2
                    Paint(st, "Color", "Accent")
                    V8.Brand.Glow(box, 18)
                    local m = V8.Brand.Mark(box, 34)
                    m.Position = UDim2.new(0, 20, 0, 22)
                    tx = 64
                end)
            end

            titleLbl = Instance.new("TextLabel")
            titleLbl.Position = UDim2.new(0, tx, 0, 18)
            titleLbl.Size = UDim2.new(1, -(tx + 22), 0, 26)
            titleLbl.BackgroundTransparency = 1
            titleLbl.TextColor3 = THEME.Text
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextSize = 21
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = box

            subLbl = Instance.new("TextLabel")
            subLbl.Position = UDim2.new(0, tx, 0, 46)
            subLbl.Size = UDim2.new(1, -(tx + 22), 0, 16)
            subLbl.BackgroundTransparency = 1
            subLbl.TextColor3 = THEME.Dim
            subLbl.Font = Enum.Font.GothamMedium
            subLbl.TextSize = 12
            subLbl.TextXAlignment = Enum.TextXAlignment.Left
            subLbl.Parent = box

            list = Instance.new("ScrollingFrame")
            list.Position = UDim2.new(0, 22, 0, 76)
            list.Size = UDim2.new(1, -36, 1, -140)
            list.BackgroundTransparency = 1
            list.BorderSizePixel = 0
            list.ScrollBarThickness = 3
            list.ScrollBarImageColor3 = THEME.Accent
            list.CanvasSize = UDim2.new(0, 0, 0, 0)
            list.AutomaticCanvasSize = Enum.AutomaticSize.Y
            list.Parent = box
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 12)
            l.SortOrder = Enum.SortOrder.LayoutOrder
            local p = Instance.new("UIPadding", list)
            p.PaddingRight = UDim.new(0, 10)

            local ok = CreateButton(box, "BORA!", "Success", 38)
            ok.AnchorPoint = Vector2.new(0.5, 1)
            ok.Position = UDim2.new(0.5, 0, 1, -16)
            ok.Size = UDim2.new(1, -44, 0, 38)
            ok.TextSize = 14
            ok.Font = Enum.Font.GothamBold
            ok.MouseButton1Click:Connect(function() W.Close() end)
        end

        W.Close = function()
            if overlay then overlay.Visible = false end
        end

        -- welcome = true: primeiros passos (quem nunca usou)
        W.Show = function(welcome)
            if not overlay then Create() end
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            -- cores do tema atual (o cartão não fica no registry: é efêmero)
            box.BackgroundColor3 = THEME.Card
            titleLbl.TextColor3 = THEME.Text
            subLbl.TextColor3 = THEME.Dim
            if welcome then
                titleLbl.Text = "Bem-vindo ao HYGE " .. CONFIG.Version
                subLbl.Text = "Quatro coisas para começar:"
                for i, it in ipairs(W.Tips()) do Row(list, i, it) end
            else
                titleLbl.Text = "Novidades da " .. CONFIG.Version
                subLbl.Text = W.Subtitle or "O que mudou:"
                for i, it in ipairs(W.Items) do Row(list, i, it) end
            end
            -- tela baixa (celular deitado): o cartão encolhe e a lista rola
            local vp = Gui.AbsoluteSize
            local h = 470
            if vp.Y > 100 then h = math.clamp(vp.Y - 40, 260, 470) end
            local w = 430
            if vp.X > 100 then w = math.min(430, vp.X - 24) end
            box.Size = UDim2.new(0, w, 0, h)
            overlay.Visible = true
        end

        W.Boot = function()
            if SET.SeenVersion == CONFIG.Version then return end
            local welcome = not W.HadConfig
            SET.SeenVersion = CONFIG.Version   -- o salvamento automático grava
            task.delay(0.8, function() pcall(W.Show, welcome) end)
        end

        Conn.NewsKeys = UserInputService.InputBegan:Connect(function(input)
            if overlay and overlay.Visible and (input.KeyCode == Enum.KeyCode.Escape
                or input.KeyCode == Enum.KeyCode.Return) then
                W.Close()
            end
        end)
    end
    Build()
end
