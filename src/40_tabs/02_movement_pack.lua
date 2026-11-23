--------------------------------------------------------------------------------
-- v8.2 — CARTÃO "PACOTE DE ANIMAÇÃO" (Personagem › Movimento)
-- Cole o ID ou o link de um pacote do catálogo; o painel lê as animações dele
-- (V8.Pack, 30_kit/06_animpack.lua) e guarda na lista. Em cada pacote:
--   USAR  -> troca as animações do seu personagem (andar, correr, pular,
--            parado...) — os outros jogadores veem
--   VOO   -> o Fly (estilo "Pacote") usa a animação de cair/parado dele
--   X     -> tira da lista
-- VOLTAR AO NORMAL devolve as animações originais do jogo.
-- Entra logo depois de 02_movement.lua no build (ordem alfabética).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local K = V8.Pack
        if not K then return end
        local card = CreateCard(Tabs.Movement, "PACOTE DE ANIMAÇÃO", 3)
        SubLabel(card, "Pacotes de animação do catálogo (só R15). USAR troca as "
            .. "animações do seu personagem e todo mundo vê. VOO põe o pacote no Fly.", -1)

        local status = SubLabel(card, "", 0)

        local box = CreateInput(card, "ID ou link do pacote (roblox.com/bundles/...)", 32)
        box.LayoutOrder = 1

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 2
        local add = CreateButton(g, "ADICIONAR", "Success", 32)
        add.LayoutOrder = 1
        local normal = CreateButton(g, "VOLTAR AO NORMAL", "Warning", 32)
        normal.LayoutOrder = 2

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 3
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local function Describe(p)
            if K.busy[p.id] then return "lendo o pacote...", "Warning" end
            local n = K.Count(p)
            if K.fail[p.id] and n == 0 then return "não deu: " .. tostring(K.fail[p.id]), "Danger" end
            if n == 0 then return "ainda não lido (lê ao usar)  ·  ID " .. p.id, "Dim" end
            local names = {}
            for _, s in ipairs(K.Slots) do
                if p.anims[s] then table.insert(names, K.SlotName[s]) end
            end
            return n .. " animações: " .. table.concat(names, ", "), "Dim"
        end

        local function SmallBtn(parent, text, key, w, x)
            local b = CreateButton(parent, text, key, 26)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Size = UDim2.new(0, w, 0, 26)
            b.Position = UDim2.new(1, x, 0.5, 0)
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            return b
        end

        local function Row(p, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -196, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 7)
            nm.BackgroundTransparency = 1
            nm.Text = p.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 13
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local text, key = Describe(p)
            local ds = Instance.new("TextLabel")
            ds.Size = UDim2.new(1, -196, 0, 14)
            ds.Position = UDim2.new(0, 12, 0, 27)
            ds.BackgroundTransparency = 1
            ds.Text = text
            ds.TextColor3 = THEME[key] or THEME.Dim
            ds.Font = Enum.Font.GothamMedium
            ds.TextSize = 10
            ds.TextXAlignment = Enum.TextXAlignment.Left
            ds.TextTruncate = Enum.TextTruncate.AtEnd
            ds.Parent = row
            Paint(ds, "TextColor3", key)

            local onChar = (SET.PackOn == p.id)
            local fp = K.FlyPack()
            local onFly = (fp ~= nil and fp.id == p.id)

            -- da direita para a esquerda: X, VOO, USAR
            local del = SmallBtn(row, "X", "Danger", 30, -10)
            local fly = SmallBtn(row, onFly and "NO VOO" or "VOO",
                onFly and "Success" or "Accent2", 62, -46)
            local use = SmallBtn(row, onChar and "EM USO" or "USAR",
                onChar and "Success" or "Accent", 70, -114)
            if onChar then use.TextColor3 = THEME.Success end
            if onFly then fly.TextColor3 = THEME.Success end

            use.MouseButton1Click:Connect(function()
                if SET.PackOn == p.id then K.Off() else K.Use(p) end
            end)
            fly.MouseButton1Click:Connect(function()
                local cur = K.FlyPack()
                if cur and cur.id == p.id then
                    Toast(p.name .. " já é o pacote do voo", nil, 2)
                    return
                end
                K.SetFly(p)
                Log("Voo agora usa o pacote " .. p.name
                    .. ((SET.FlyStyle or CONFIG.FlyStyle) ~= "pacote"
                        and "  (escolha 'Pacote' em Animação do voo)" or ""), "ok")
                if K.Count(p) == 0 then K.Resolve(p) end
            end)
            del.MouseButton1Click:Connect(function()
                Confirm("Tirar " .. p.name .. " da lista?", function()
                    K.Remove(p)
                    Log("Pacote removido: " .. p.name, "action")
                end)
            end)
        end

        local function Render()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local packs = K.List()
            for i, p in ipairs(packs) do Row(p, i) end
            local on = SET.PackOn and K.Get(SET.PackOn)
            local fp = K.FlyPack()
            status.Text = "No personagem: " .. (on and on.name or "animações do jogo")
                .. "   ·   No voo: " .. (fp and fp.name or "itens da config")
                .. ((#packs == 0) and "\nLista vazia — cole o ID de um pacote acima." or "")
        end
        K.Render = Render

        local function DoAdd()
            local raw = box.Text
            if raw:match("^%s*$") then
                Toast("Cole o ID ou o link do pacote", "warn", 2)
                return
            end
            local p, why = K.Add(raw, function(pk, n, err)
                if n then
                    Log("Pacote lido: " .. pk.name .. " (" .. n .. " animações)", "ok")
                    Toast(pk.name .. " adicionado", "ok", 2)
                else
                    Log("Pacote " .. pk.id .. " não foi lido: " .. tostring(err), "error")
                    Toast("Não deu para ler o pacote", "error", 3)
                end
            end)
            if not p then
                Toast(tostring(why), "warn", 3)
                return
            end
            box.Text = ""
        end
        add.MouseButton1Click:Connect(DoAdd)
        box.FocusLost:Connect(function(enter) if enter then DoAdd() end end)
        normal.MouseButton1Click:Connect(function() K.Off() end)

        K.OnChange(function() pcall(Render) end)
        OnTabOpen("Movement", function() pcall(Render) end)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(Render) end)
        Render()
    end
    Build()
end
