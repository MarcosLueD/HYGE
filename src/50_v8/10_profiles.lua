--------------------------------------------------------------------------------
-- v9.0 — PERFIS (Configurações › Dados › Perfis)
-- Um perfil é o painel inteiro guardado com um nome: tema, tamanho, teclas,
-- macros, velocidades, opções de ESP, favoritos, ajustes e as funções que
-- estavam ligadas. USAR troca tudo de uma vez.
-- JOGO marca o perfil para abrir sozinho neste jogo (PlaceId): o BootStep
-- "Perfil do jogo" aplica depois da config e das funções automáticas.
-- Ficam FORA do perfil: waypoints (são por jogo), emotes favoritos, notas, os
-- pacotes de animação (biblioteca e o que está em uso) e a posição da janela.
-- Freecam e Drone nunca ligam sozinhos (tomam a câmera).
-- Arquivo próprio: HYGE/profiles.json. Sem writefile, valem só nesta sessão.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local C = V8.Cfg
        if not C then return end
        V8.Prof = { Path = "HYGE/profiles.json", Max = 10,
                    Data = { list = {}, places = {} }, Current = nil }
        local P = V8.Prof
        local Http = V8.Net and V8.Net.Http
        local PLACE = tostring(game.PlaceId)
        local NOAUTO = { freecam = true, drone = true }
        -- pacote de animação fica fora: a biblioteca (Packs) não vai no perfil e
        -- trocar PackOn sem reaplicar o Animate deixaria o personagem no meio
        local SKIP = { Packs = true, PackOn = true, FlyPack = true, WinPos = true, SeenVersion = true }

        ----------------------------------------------------------------------------
        -- disco
        ----------------------------------------------------------------------------
        local function CanDisk() return V8.Disk and V8.Disk.Ok() and Http ~= nil end

        local function Load()
            if not CanDisk() then return end
            local raw = V8.Disk.Read(P.Path)
            if not raw then return end
            local ok, d = pcall(function() return Http:JSONDecode(raw) end)
            if not ok or type(d) ~= "table" then
                Log("Perfis: " .. P.Path .. " ilegível — a lista começa vazia", "warn")
                return
            end
            local list = {}
            if type(d.list) == "table" then
                for _, r in ipairs(d.list) do
                    if type(r) == "table" and type(r.name) == "string" and type(r.data) == "table" then
                        table.insert(list, r)
                    end
                end
            end
            P.Data.list = list
            P.Data.places = type(d.places) == "table" and d.places or {}
        end

        local function Save()
            if not CanDisk() then return false, "executor sem writefile (perfis só nesta sessão)" end
            local ok, json = pcall(function() return Http:JSONEncode(P.Data) end)
            if not ok then return false, "JSON: " .. tostring(json) end
            return V8.Disk.Write(P.Path, json)
        end

        Load()

        ----------------------------------------------------------------------------
        -- lógica
        ----------------------------------------------------------------------------
        local function Clean(name)
            name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if #name > 24 then name = name:sub(1, 24) end
            return name
        end

        -- exato primeiro (sem acento/caixa), depois começo do nome
        P.Find = function(name, exact)
            local q = V8.Fold(Clean(name))
            if q == "" then return nil end
            for _, r in ipairs(P.Data.list) do
                if V8.Fold(r.name) == q then return r end
            end
            if exact then return nil end
            for _, r in ipairs(P.Data.list) do
                if V8.Fold(r.name):sub(1, #q) == q then return r end
            end
            return nil
        end

        P.Capture = function()
            local d = C.Snapshot()
            d.waypoints, d.wpplaces, d.emotes, d.notes, d.situation = nil, nil, nil, nil, nil
            if type(d.set) == "table" then
                for k in pairs(SKIP) do d.set[k] = nil end
            end
            d.on = {}
            for _, id in ipairs(ToggleOrder) do
                if IsOn(id) and not NOAUTO[id] then table.insert(d.on, id) end
            end
            return d
        end

        P.SaveAs = function(name)
            name = Clean(name)
            if name == "" then return false, "dê um nome ao perfil" end
            local rec = P.Find(name, true)
            if not rec then
                if #P.Data.list >= P.Max then return false, "limite de " .. P.Max .. " perfis" end
                rec = { name = name }
                table.insert(P.Data.list, rec)
            end
            rec.data = P.Capture()
            rec.saved = os.time()
            P.Current = rec.name
            local ok, err = Save()
            if P.Render then pcall(P.Render) end
            Log("Perfil '" .. rec.name .. "' salvo (" .. #rec.data.on .. " função(ões) ligada(s))"
                .. (ok and "" or ("  — " .. tostring(err))), ok and "ok" or "warn")
            return true
        end

        P.Use = function(name, silent)
            local rec = P.Find(name)
            if not rec then return false, "perfil não encontrado: " .. tostring(name) end
            local ok, err = pcall(C.Restore, rec.data)
            if not ok then return false, "falhou ao aplicar: " .. tostring(err) end
            if type(rec.data.on) == "table" then
                local want = {}
                for _, id in ipairs(rec.data.on) do want[id] = true end
                for _, id in ipairs(ToggleOrder) do
                    if not NOAUTO[id] and IsOn(id) ~= (want[id] == true) then
                        pcall(SetToggle, id, want[id] == true, true)
                    end
                end
            end
            P.Current = rec.name
            if RefreshStatus then pcall(RefreshStatus) end
            if P.Render then pcall(P.Render) end
            if not silent then
                Log("Perfil '" .. rec.name .. "' aplicado", "ok")
                Toast("Perfil: " .. rec.name, "ok", 2)
            end
            return true
        end

        P.Delete = function(name)
            local rec = P.Find(name, true)
            if not rec then return false, "perfil não encontrado" end
            for i, r in ipairs(P.Data.list) do
                if r == rec then table.remove(P.Data.list, i) break end
            end
            for place, n in pairs(P.Data.places) do
                if n == rec.name then P.Data.places[place] = nil end
            end
            if P.Current == rec.name then P.Current = nil end
            Save()
            if P.Render then pcall(P.Render) end
            Log("Perfil '" .. rec.name .. "' apagado", "action")
            return true
        end

        P.HereName = function() return P.Data.places[PLACE] end

        -- marca (ou desmarca, com name = nil) o perfil que abre sozinho neste jogo
        P.BindHere = function(name)
            if name then
                local rec = P.Find(name, true)
                if not rec then return false, "perfil não encontrado" end
                P.Data.places[PLACE] = rec.name
                Log("Perfil '" .. rec.name .. "' vai abrir sozinho neste jogo (PlaceId "
                    .. PLACE .. ")", "ok")
            else
                P.Data.places[PLACE] = nil
                Log("Este jogo não tem mais perfil automático", "action")
            end
            Save()
            if P.Render then pcall(P.Render) end
            return true
        end

        P.Boot = function()
            local n = P.HereName()
            if not n then return end
            if not P.Find(n, true) then
                P.Data.places[PLACE] = nil
                return
            end
            local ok, err = P.Use(n, true)
            if ok then
                Log("Perfil deste jogo aplicado: " .. n, "ok")
            else
                Log("Perfil deste jogo (" .. n .. "): " .. tostring(err), "error")
            end
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Perfis
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "PERFIS", 6)
        SubLabel(card, "Um perfil guarda o painel do jeito que está agora: tema, teclas, "
            .. "macros, velocidades, ESP, favoritos e as funções ligadas (menos Freecam e "
            .. "Drone). JOGO faz o perfil abrir sozinho neste jogo.", -1)
        local status = SubLabel(card, "", 0)

        local addRow = Instance.new("Frame")
        addRow.Size = UDim2.new(1, 0, 0, 32)
        addRow.BackgroundTransparency = 1
        addRow.LayoutOrder = 1
        addRow.Parent = card
        local nameBox = CreateInput(addRow, "nome do perfil (ex.: Explorar, PvP)", 32)
        nameBox.Size = UDim2.new(1, -150, 1, 0)
        local bSave = CreateButton(addRow, "SALVAR PERFIL", "Success", 32)
        bSave.AnchorPoint = Vector2.new(1, 0)
        bSave.Position = UDim2.new(1, 0, 0, 0)
        bSave.Size = UDim2.new(0, 142, 1, 0)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 2
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        local empty = SubLabel(card, "Nenhum perfil ainda. Deixe o painel do seu jeito, "
            .. "dê um nome e toque em SALVAR PERFIL.", 3)

        local function SmallBtn(parent, text, colorKey, w, x)
            local b = CreateButton(parent, text, colorKey, 26)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, x, 0.5, 0)
            b.Size = UDim2.new(0, w, 0, 26)
            b.TextSize = 10
            return b
        end

        P.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            empty.Visible = (#P.Data.list == 0)
            local here = P.HereName()
            for i, r in ipairs(P.Data.list) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 46)
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = list
                V8.Cell(row, 0)

                local active = (P.Current == r.name)
                local nm = Instance.new("TextLabel")
                nm.Size = UDim2.new(1, -176, 0, 18)
                nm.Position = UDim2.new(0, 0, 0, 6)
                nm.BackgroundTransparency = 1
                nm.Text = r.name .. (active and "  ·  ativo" or "")
                nm.TextColor3 = active and THEME.Accent or THEME.Text
                nm.Font = Enum.Font.GothamBold
                nm.TextSize = 13
                nm.TextXAlignment = Enum.TextXAlignment.Left
                nm.TextTruncate = Enum.TextTruncate.AtEnd
                nm.Parent = row

                local on = (type(r.data) == "table" and type(r.data.on) == "table") and #r.data.on or 0
                local sub = Instance.new("TextLabel")
                sub.Size = UDim2.new(1, -176, 0, 14)
                sub.Position = UDim2.new(0, 0, 0, 25)
                sub.BackgroundTransparency = 1
                sub.Text = (r.saved and os.date("salvo %d/%m %H:%M", r.saved) or "salvo")
                    .. "  ·  " .. on .. " função(ões)"
                    .. ((here == r.name) and "  ·  abre neste jogo" or "")
                sub.TextColor3 = (here == r.name) and THEME.Success or THEME.Dim
                sub.Font = Enum.Font.GothamMedium
                sub.TextSize = 10
                sub.TextXAlignment = Enum.TextXAlignment.Left
                sub.TextTruncate = Enum.TextTruncate.AtEnd
                sub.Parent = row

                local bUse = SmallBtn(row, "USAR", "Accent", 52, -96)
                bUse.MouseButton1Click:Connect(function()
                    local ok, err = P.Use(r.name)
                    if not ok then Log(tostring(err), "error") end
                end)
                -- marcado: borda verde e o texto "abre neste jogo" na linha de baixo
                local bHere = SmallBtn(row, "JOGO", (here == r.name) and "Success" or "Accent", 52, -38)
                if here == r.name then bHere.TextColor3 = THEME.Success end
                bHere.MouseButton1Click:Connect(function()
                    P.BindHere((P.HereName() ~= r.name) and r.name or nil)
                end)
                local bDel = SmallBtn(row, "", "Danger", 30, 0)
                local ic = Icon(bDel, "trash", THEME.Danger, 13)
                ic.AnchorPoint = Vector2.new(0.5, 0.5)
                ic.Position = UDim2.new(0.5, 0, 0.5, 0)
                bDel.MouseButton1Click:Connect(function()
                    Confirm("Apagar o perfil '" .. r.name .. "'?", function() P.Delete(r.name) end)
                end)
            end
            status.Text = (CanDisk() and ("Arquivo: " .. P.Path)
                    or "Este executor não tem writefile: os perfis valem só nesta sessão.")
                .. "  ·  " .. #P.Data.list .. "/" .. P.Max .. " perfis"
                .. (here and ("  ·  este jogo abre com '" .. here .. "'") or "")
        end

        bSave.MouseButton1Click:Connect(function()
            local name = nameBox.Text
            if Clean(name) == "" then name = P.Current or "" end
            if Clean(name) == "" then
                Toast("Dê um nome ao perfil", "warn", 2)
                return
            end
            local exists = P.Find(name, true) ~= nil
            local function go()
                local ok, err = P.SaveAs(name)
                if ok then
                    nameBox.Text = ""
                    Toast("Perfil salvo: " .. Clean(name), "ok", 2)
                else
                    Toast(tostring(err), "warn", 3)
                end
            end
            if exists then
                Confirm("Já existe o perfil '" .. Clean(name) .. "'. Trocar pelo que está agora?", go)
            else
                go()
            end
        end)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(P.Render) end)
        P.Render()
    end
    Build()
end
