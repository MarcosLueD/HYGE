--------------------------------------------------------------------------------
-- v9.0 — AJUSTES ORGANIZADOS (Configurações › Ajustes)
-- A aba tinha ~20 cartões numa rolagem só. Agora, no topo:
--   * categorias em pílula: Tudo · Geral · Teclas · Visual · Dados · Sistema
--   * busca dentro dos ajustes (sem acento: "aparencia" acha "Aparência";
--     procura no título E no texto de cada opção do cartão)
-- Cada cartão vai para a categoria pelo título (tabela MAP abaixo) e a ordem
-- dentro da aba passa a seguir as categorias. Cartão novo sem entrada no MAP
-- cai em "Geral". A busca global (Ctrl+K) acha os cartões e abre filtrado.
-- Entra DEPOIS de todos os módulos que criam cartões em Ajustes.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = Tabs.Settings
        if not tab then return end
        V8.SetNav = { Cat = "all", Query = "", Cards = {} }
        local N = V8.SetNav

        N.Cats = {
            { "all", "Tudo" }, { "geral", "Geral" }, { "teclas", "Teclas" },
            { "visual", "Visual" }, { "dados", "Dados" }, { "sistema", "Sistema" },
        }
        -- título do cartão (V8.Fold: minúsculo, sem acento) -> { categoria, ordem }
        local MAP = {
            ["comportamento"]          = { "geral", 1 },
            ["automatico"]             = { "geral", 2 },
            ["presets"]                = { "geral", 3 },
            ["celular e toque"]        = { "geral", 4 },
            ["keybinds"]               = { "teclas", 1 },
            ["macros de teclado"]      = { "teclas", 2 },
            ["atalhos das situacoes"]  = { "teclas", 3 },
            ["busca global"]           = { "teclas", 4 },
            ["aparencia"]              = { "visual", 1 },
            ["cor personalizada"]      = { "visual", 2 },
            ["notificacoes"]           = { "visual", 3 },
            ["navegacao"]              = { "visual", 4 },
            ["ilha no topo"]           = { "visual", 5 },
            ["perfis"]                 = { "dados", 1 },
            ["configuracao em disco"]  = { "dados", 2 },
            ["atualizacao"]            = { "sistema", 1 },
            ["diagnostico"]            = { "sistema", 2 },
            ["sistema"]                = { "sistema", 3 },
            ["sobre"]                  = { "sistema", 4 },
        }
        local IDX = {}
        for i, c in ipairs(N.Cats) do IDX[c[1]] = i end

        for _, c in ipairs(tab:GetChildren()) do
            if c:IsA("Frame") and c.Name == "Card" then
                local t = CardTitleRef(c)
                local title = t and t.Text or ""
                local m = MAP[V8.Fold(title)] or { "geral", 50 }
                c.LayoutOrder = IDX[m[1]] * 100 + m[2]
                table.insert(N.Cards, { card = c, title = title, cat = m[1] })
            end
        end
        table.sort(N.Cards, function(a, b) return a.card.LayoutOrder < b.card.LayoutOrder end)

        ----------------------------------------------------------------------------
        -- topo: pílulas + busca (rolam junto com a aba)
        ----------------------------------------------------------------------------
        local head = Instance.new("Frame")
        head.Name = "SettingsNav"
        head.Size = UDim2.new(1, 0, 0, 0)
        head.AutomaticSize = Enum.AutomaticSize.Y
        head.BackgroundTransparency = 1
        head.LayoutOrder = -100
        head.Parent = tab
        do
            local l = Instance.new("UIListLayout", head)
            l.Padding = UDim.new(0, 8)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local chips = Instance.new("Frame")
        chips.Size = UDim2.new(1, 0, 0, 28)
        chips.BackgroundTransparency = 1
        chips.LayoutOrder = 1
        chips.Parent = head
        do
            local l = Instance.new("UIListLayout", chips)
            l.FillDirection = Enum.FillDirection.Horizontal
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local chipBtns = {}
        local n = #N.Cats
        for i, c in ipairs(N.Cats) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1 / n, -5 * (n - 1) / n, 1, 0)
            b.BackgroundColor3 = THEME.Btn
            b.Text = c[2]
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = chips
            Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
            chipBtns[c[1]] = b
        end

        local search = CreateInput(head, "buscar nos ajustes (tema, tecla, salvar...)", 32)
        search.LayoutOrder = 2

        local empty = SubLabel(tab, "", 9999)
        empty.Visible = false

        ----------------------------------------------------------------------------
        -- filtro
        ----------------------------------------------------------------------------
        local function Haystack(card)
            local parts = {}
            for _, d in ipairs(card:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
                    table.insert(parts, d.Text)
                end
            end
            return V8.Fold(table.concat(parts, " "))
        end

        local function PaintChips()
            for id, b in pairs(chipBtns) do
                local on = (id == N.Cat)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        N.Apply = function()
            local q = V8.Fold(N.Query or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local shown = 0
            for _, e in ipairs(N.Cards) do
                local ok = (N.Cat == "all" or e.cat == N.Cat)
                if ok and q ~= "" then
                    ok = V8.Fold(e.title):find(q, 1, true) ~= nil
                        or Haystack(e.card):find(q, 1, true) ~= nil
                end
                e.card.Visible = ok
                if ok then shown = shown + 1 end
            end
            empty.Visible = (shown == 0)
            empty.Text = (q ~= "") and ("Nada nos ajustes com \"" .. (N.Query or "") .. "\""
                .. ((N.Cat ~= "all") and " nesta categoria — tente Tudo." or "."))
                or "Nada nesta categoria."
            PaintChips()
        end

        N.SetCat = function(cat)
            if not IDX[cat] then cat = "all" end
            N.Cat = cat
            N.Apply()
            tab.CanvasPosition = Vector2.new(0, 0)
        end

        for id, b in pairs(chipBtns) do
            b.MouseButton1Click:Connect(function() N.SetCat(id) end)
        end
        search:GetPropertyChangedSignal("Text"):Connect(function()
            N.Query = search.Text
            pcall(N.Apply)
        end)

        -- busca global: abre Configurações › Ajustes mostrando só esse cartão
        N.Focus = function(title)
            N.Cat = "all"
            search.Text = title or ""   -- dispara o filtro
            N.Query = search.Text
            N.Apply()
            ShowTab("Settings")
            if V8.IsOpen and not V8.IsOpen() and V8.SetOpen then V8.SetOpen(true) end
            tab.CanvasPosition = Vector2.new(0, 0)
        end

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(PaintChips) end)
        N.Apply()
    end
    Build()
end
