--------------------------------------------------------------------------------
-- v8.1 — PLAYTIME SHOP (ícone de sacola do dock)
-- Loja do próprio painel paga com tempo de jogo: 1 ponto por minuto com o HYGE
-- aberto (V8.Play, 30_kit/05_playtime.lua). Categorias: All, Ranks, Icons,
-- Titles, Effects, Nametags, Bundles. Tudo é visual e local — nada de Robux,
-- nada que mexa no jogo. Effects e Nametags são criados pelo SEU cliente no
-- seu personagem: só você vê (a loja diz isso na cara, não esconde).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Shop")
        local P = V8.Play
        local S = { cat = "All" }
        V8.Shop = S

        ----------------------------------------------------------------------------
        -- SALDO
        ----------------------------------------------------------------------------
        local wallet = CreateCard(tab, "SALDO", 1)
        local tiles = Grid(wallet, 3, 48)
        tiles.LayoutOrder = 1
        local tPoints = StatTile(tiles, "PONTOS", "—", 1, "Success")
        local tTime = StatTile(tiles, "TEMPO DE JOGO", "—", 2, "Accent2")
        local tItems = StatTile(tiles, "ITENS", "—", 3)
        local status = SubLabel(wallet, "", 2)

        ----------------------------------------------------------------------------
        -- EQUIPADO
        ----------------------------------------------------------------------------
        local eq = CreateCard(tab, "EQUIPADO", 2)
        local eqLbl = SubLabel(eq, "", 1)
        eqLbl.TextColor3 = THEME.Text
        eqLbl.Font = Enum.Font.GothamMedium
        eqLbl.TextSize = 12
        for _, e in ipairs(Painted) do   -- SubLabel nasce "Dim": troca no registry
            if e.inst == eqLbl then e.key = "Text" end
        end

        local off = CreateButton(eq, "TIRAR TUDO", "Line", 30)
        off.LayoutOrder = 2
        off.MouseButton1Click:Connect(function()
            P.UnequipAll()
            Log("Playtime Shop: tudo desequipado", "action")
        end)

        ----------------------------------------------------------------------------
        -- ITENS (categorias + lista)
        ----------------------------------------------------------------------------
        local shop = CreateCard(tab, "ITENS", 3)
        local pills = Grid(shop, 4, 28)
        pills.LayoutOrder = 1
        local pillBtns = {}

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 3
        list.Parent = shop
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local hint = SubLabel(shop, "", 2)

        local CAT_HINT = {
            All      = "Tudo o que dá para comprar com tempo de jogo.",
            Ranks    = "Seu rank aparece no perfil da Home, na nametag e no chat HYGE.",
            Icons    = "Desenho ao lado do seu nome no perfil da Home.",
            Titles   = "Título embaixo do nome (perfil, nametag e chat HYGE).",
            Effects  = "Efeito no seu personagem — criado no seu cliente: SÓ VOCÊ VÊ.",
            Nametags = "Placa acima da sua cabeça — criada no seu cliente: SÓ VOCÊ VÊ.",
            Bundles  = "Pacotes com desconto; o preço cai pelo que você já tem.",
        }
        local CAT_ICON = { Ranks = "shield", Icons = "star", Titles = "clip",
            Effects = "sun", Nametags = "user", Bundles = "bag" }

        local function PaintPills()
            for name, b in pairs(pillBtns) do
                local on = (name == S.cat)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        -- miniatura à esquerda de cada item
        local function Preview(parent, it)
            local box = Instance.new("Frame")
            box.Size = UDim2.new(0, 36, 0, 36)
            box.Position = UDim2.new(0, 8, 0.5, -18)
            box.BackgroundColor3 = it.color or THEME.Track
            box.BorderSizePixel = 0
            box.Parent = parent
            if not it.color then Paint(box, "BackgroundColor3", "Track") end
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
            if it.cat == "Titles" then
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, 0, 1, 0)
                t.BackgroundTransparency = 1
                t.Text = "Aa"
                t.TextColor3 = THEME.Text
                t.Font = Enum.Font.GothamBlack
                t.TextSize = 14
                t.Parent = box
                Paint(t, "TextColor3", "Text")
            elseif it.cat ~= "Ranks" then
                local ic = Icon(box, it.icon or CAT_ICON[it.cat] or "dot", THEME.Text, 20, 1)
                ic.AnchorPoint = Vector2.new(0.5, 0.5)
                ic.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
        end

        local function Describe(it)
            if it.cat == "Bundles" then
                local names = {}
                for _, sub in ipairs(it.items or {}) do
                    local s = P.ById[sub]
                    if s then table.insert(names, s.name) end
                end
                local _, have, total = P.BundlePrice(it)
                return table.concat(names, " + ")
                    .. (have > 0 and ("  (você já tem " .. have .. "/" .. total .. ")") or "")
            end
            return it.desc or it.cat
        end

        local function Row(it, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 52)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            Preview(row, it)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -160, 0, 18)
            nm.Position = UDim2.new(0, 54, 0, 8)
            nm.BackgroundTransparency = 1
            nm.Text = it.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 13
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -160, 0, 14)
            ds.Position = UDim2.new(0, 54, 0, 27)
            ds.BackgroundTransparency = 1
            ds.Text = (S.cat == "All" and (it.cat .. " · ") or "") .. Describe(it)
            ds.TextColor3 = THEME.Dim
            ds.Font = Enum.Font.GothamMedium
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.TextTruncate = Enum.TextTruncate.AtEnd
            ds.Parent = row
            Paint(ds, "TextColor3", "Dim")

            -- botão: preço / equipar / equipado / completo
            local slot = P.SlotOf[it.cat]
            local owned = P.Owned[it.id]
            local price = P.PriceOf(it)
            local text, key
            if it.cat == "Bundles" then
                local _, have, total = P.BundlePrice(it)
                if have >= total then
                    text, key = "COMPLETO", "Line"
                else
                    text, key = price .. " PTS", (P.Points() >= price) and "Success" or "Line"
                end
            elseif owned then
                if slot and P.Equip[slot] == it.id then
                    text, key = "EQUIPADO", "Success"
                else
                    text, key = "EQUIPAR", "Accent"
                end
            else
                text, key = price .. " PTS", (P.Points() >= price) and "Success" or "Line"
            end

            local b = CreateButton(row, text, key, 30)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -10, 0.5, 0)
            b.Size = UDim2.new(0, 92, 0, 30)
            b.TextSize = 11
            if key == "Line" then
                b.TextColor3 = THEME.Dim
                Paint(b, "TextColor3", "Dim")
            end

            b.MouseButton1Click:Connect(function()
                if text == "COMPLETO" then
                    Toast("Você já tem tudo deste pacote", nil, 2)
                elseif text == "EQUIPADO" then
                    P.Unequip(slot)
                    Log("Playtime Shop: " .. it.name .. " desequipado", "action")
                elseif text == "EQUIPAR" then
                    P.EquipItem(it.id)
                    Log("Playtime Shop: " .. it.name .. " equipado", "ok")
                    Toast(it.name .. " equipado", "ok", 1.6)
                else
                    if P.Points() < price then
                        Toast("Faltam " .. (price - P.Points()) .. " pontos ("
                            .. P.Fmt((price - P.Points()) * 60) .. " de jogo)", "warn", 3)
                        return
                    end
                    Confirm("Comprar " .. it.name .. " por " .. price .. " pontos?", function()
                        local ok, res = P.Buy(it.id)
                        if not ok then
                            Toast(tostring(res), "warn", 3)
                            return
                        end
                        Log("Playtime Shop: comprou " .. it.name .. " (" .. tostring(res)
                            .. " pts)", "ok")
                        Toast(it.name .. " comprado", "ok", 2)
                        -- item avulso já entra equipado
                        if slot then P.EquipItem(it.id) end
                    end)
                end
            end)
        end

        S.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local n = 0
            for _, it in ipairs(P.Items) do
                if S.cat == "All" or it.cat == S.cat then
                    n = n + 1
                    Row(it, n)
                end
            end
            hint.Text = CAT_HINT[S.cat] or ""
        end

        S.Tick = function()
            tPoints.Text = tostring(P.Points())
            tTime.Text = P.Fmt(P.Total)
            local owned, total = 0, 0
            for _, it in ipairs(P.Items) do
                if it.cat ~= "Bundles" then
                    total = total + 1
                    if P.Owned[it.id] then owned = owned + 1 end
                end
            end
            tItems.Text = owned .. "/" .. total
            local nextMin = 60 - math.floor(P.Total % 60)
            status.Text = "1 ponto por minuto com o HYGE aberto — próximo em " .. nextMin
                .. "s.  " .. tostring(P.Status or "")
        end

        local SLOT_NAME = { rank = "Rank", icon = "Ícone", title = "Título",
            effect = "Efeito", nametag = "Nametag" }
        local function RenderEquip()
            local parts = {}
            for _, slot in ipairs({ "rank", "icon", "title", "effect", "nametag" }) do
                local it = P.Equipped(slot)
                table.insert(parts, SLOT_NAME[slot] .. ": " .. (it and it.name or "—"))
            end
            eqLbl.Text = table.concat(parts, "   ·   ")
        end

        for i, name in ipairs(P.Cats) do
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = THEME.Btn
            b.Text = name
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.LayoutOrder = i
            b.Parent = pills
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
            pillBtns[name] = b
            b.MouseButton1Click:Connect(function()
                S.cat = name
                PaintPills()
                S.Render()
            end)
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, PaintPills)

        -- a lista só redesenha quando algo muda (compra, equipar, carregar)
        P.OnChange(function()
            pcall(S.Render)
            pcall(S.Tick)
            pcall(RenderEquip)
        end)
        -- a cada minuto o saldo sobe: o preço pode ficar verde sem compra nenhuma
        do
            local lastPts = -1
            V8.TabTick.Shop = function()
                S.Tick()
                local pts = P.Points()
                if pts ~= lastPts then
                    lastPts = pts
                    S.Render()
                end
            end
        end
        OnTabOpen("Shop", function()
            pcall(S.Tick)
            pcall(S.Render)
        end)

        PaintPills()
        S.Render()
        S.Tick()
        RenderEquip()
    end
    Build()
end
