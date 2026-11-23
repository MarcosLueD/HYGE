--------------------------------------------------------------------------------
-- v8.1 — TEMPO DE JOGO + COSMÉTICOS (base da Playtime Shop)
--
-- Moeda da loja = tempo com o HYGE aberto: 1 ponto por minuto. O total vai em
-- HYGE/playtime.json (arquivo próprio, gravado a cada minuto e no Unload —
-- separado da config para não depender do "salvar ao fechar"). Executor sem
-- writefile: conta só a sessão atual, e a loja avisa.
--
-- Tudo o que a loja vende é visual e local:
--   Ranks / Icons / Titles  -> aparecem no painel (perfil da Home, chat HYGE)
--   Effects / Nametags      -> criados no SEU personagem pelo SEU cliente:
--                              só você vê (instância criada no cliente não
--                              replica para os outros)
--   Bundles                 -> pacotes; o preço cai pelo que você já tem
-- Nada aqui é vendido por Robux nem mexe em dados do jogo.
--
-- V8.Play = dados + regras; V8.Cos = efeitos/nametag no personagem.
-- A UI fica em 40_tabs/09_shop.lua. Zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Play = {
            Total = 0,            -- segundos acumulados (todas as sessões)
            Spent = 0,            -- pontos gastos
            Bonus = 0,            -- pontos dados à mão (givepoints) e por missões
            Quests = nil,         -- v8.2: progresso das missões (50_v8/08_quests.lua)
            Owned = {},           -- [itemId] = true
            Equip = {},           -- [slot] = itemId
            Path = "HYGE/playtime.json",
            Start = os.clock(),
            Listeners = {},
            Status = "",
        }
        local P = V8.Play

        P.Cats = { "All", "Ranks", "Icons", "Titles", "Effects", "Nametags", "Bundles" }
        P.SlotOf = { Ranks = "rank", Icons = "icon", Titles = "title",
                     Effects = "effect", Nametags = "nametag" }

        -- preço em pontos (= minutos jogados com o painel aberto)
        P.Items = {
            -- Ranks
            { id = "rank_bronze",   cat = "Ranks", name = "Bronze",   price = 30,
              color = Color3.fromRGB(205, 127, 50),  desc = "O primeiro degrau" },
            { id = "rank_prata",    cat = "Ranks", name = "Prata",    price = 120,
              color = Color3.fromRGB(196, 200, 210), desc = "Duas horas de casa" },
            { id = "rank_ouro",     cat = "Ranks", name = "Ouro",     price = 360,
              color = Color3.fromRGB(255, 200, 60),  desc = "Seis horas de casa" },
            { id = "rank_platina",  cat = "Ranks", name = "Platina",  price = 900,
              color = Color3.fromRGB(140, 228, 228), desc = "Quinze horas de casa" },
            { id = "rank_diamante", cat = "Ranks", name = "Diamante", price = 1800,
              color = Color3.fromRGB(110, 175, 255), desc = "Trinta horas de casa" },
            { id = "rank_lenda",    cat = "Ranks", name = "Lenda",    price = 3600,
              color = Color3.fromRGB(255, 90, 120),  desc = "Sessenta horas de casa" },
            -- Icons (desenho vetorial ao lado do seu nome no painel)
            { id = "icon_bolt",  cat = "Icons", name = "Raio",     price = 20,  icon = "bolt" },
            { id = "icon_star",  cat = "Icons", name = "Estrela",  price = 45,  icon = "star" },
            { id = "icon_heart", cat = "Icons", name = "Coração",  price = 45,  icon = "heart" },
            { id = "icon_ghost", cat = "Icons", name = "Fantasma", price = 90,  icon = "ghost" },
            { id = "icon_gem",   cat = "Icons", name = "Joia",     price = 240, icon = "gem" },
            { id = "icon_crown", cat = "Icons", name = "Coroa",    price = 600, icon = "crown" },
            -- Titles
            { id = "title_novato",     cat = "Titles", name = "Novato",          price = 10 },
            { id = "title_explorador", cat = "Titles", name = "Explorador",      price = 60 },
            { id = "title_coruja",     cat = "Titles", name = "Coruja Noturna",  price = 180 },
            { id = "title_veterano",   cat = "Titles", name = "Veterano",        price = 480 },
            { id = "title_sem_vida",   cat = "Titles", name = "Sem Vida Social", price = 1200 },
            { id = "title_lenda",      cat = "Titles", name = "Lenda do HYGE",   price = 3000 },
            -- Effects (no seu personagem, só você vê)
            { id = "fx_brilho",  cat = "Effects", name = "Brilho",  price = 40,  fx = "light",
              desc = "Luz em volta do personagem" },
            { id = "fx_faiscas", cat = "Effects", name = "Faíscas", price = 90,  fx = "sparkles",
              desc = "Faíscas saindo do corpo" },
            { id = "fx_rastro",  cat = "Effects", name = "Rastro",  price = 150, fx = "trail",
              desc = "Rastro de luz ao andar" },
            { id = "fx_aura",    cat = "Effects", name = "Aura",    price = 300, fx = "aura",
              desc = "Partículas flutuando em volta" },
            { id = "fx_fogo",    cat = "Effects", name = "Fogo",    price = 500, fx = "fire",
              desc = "Chamas no corpo (não queima)" },
            -- Nametags (placa acima da cabeça, só você vê)
            { id = "tag_classica",  cat = "Nametags", name = "Clássica",  price = 25,  style = "classic",
              desc = "Fundo escuro, texto branco" },
            { id = "tag_neon",      cat = "Nametags", name = "Neon",      price = 120, style = "neon",
              desc = "Contorno brilhante na cor do tema" },
            { id = "tag_dourada",   cat = "Nametags", name = "Dourada",   price = 420, style = "gold",
              desc = "Texto dourado" },
            { id = "tag_arcoiris",  cat = "Nametags", name = "Arco-íris", price = 900, style = "rainbow",
              desc = "Cores correndo pelo nome" },
            -- Bundles
            { id = "pack_inicio",   cat = "Bundles", name = "Pacote Início",   price = 50,
              items = { "rank_bronze", "icon_bolt", "title_novato", "tag_classica" } },
            { id = "pack_veterano", cat = "Bundles", name = "Pacote Veterano", price = 900,
              items = { "rank_ouro", "icon_ghost", "title_veterano", "fx_rastro" } },
            { id = "pack_lenda",    cat = "Bundles", name = "Pacote Lenda",    price = 6900,
              items = { "rank_lenda", "icon_crown", "title_lenda", "fx_fogo", "tag_arcoiris" } },
        }
        P.ById = {}
        for i, it in ipairs(P.Items) do
            it.order = i
            P.ById[it.id] = it
        end

        ----------------------------------------------------------------------------
        -- consultas
        ----------------------------------------------------------------------------
        P.Points = function()
            return math.max(0, math.floor(P.Total / 60) + P.Bonus - P.Spent)
        end
        P.Session = function() return os.clock() - P.Start end

        P.Fmt = function(sec)
            sec = math.max(0, math.floor(tonumber(sec) or 0))
            local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
            if h > 0 then return h .. "h " .. string.format("%02d", m) .. "min" end
            if m > 0 then return m .. "min" end
            return sec .. "s"
        end

        P.Equipped = function(slot)
            local id = P.Equip[slot]
            return id and P.ById[id] or nil
        end

        -- pacote: preço proporcional ao que ainda falta
        P.BundlePrice = function(it)
            local full, missing, have = 0, 0, 0
            for _, sub in ipairs(it.items or {}) do
                local s = P.ById[sub]
                if s then
                    full = full + s.price
                    if P.Owned[sub] then have = have + 1 else missing = missing + s.price end
                end
            end
            local price = (full > 0) and math.ceil(it.price * missing / full) or it.price
            return price, have, #(it.items or {})
        end

        P.PriceOf = function(it)
            if it.cat == "Bundles" then return (P.BundlePrice(it)) end
            return it.price
        end

        -- "Ouro · Veterano" (rank e título equipados)
        P.Line = function()
            local parts = {}
            local r, t = P.Equipped("rank"), P.Equipped("title")
            if r then table.insert(parts, r.name) end
            if t then table.insert(parts, t.name) end
            return table.concat(parts, " · ")
        end

        P.OnChange = function(fn) table.insert(P.Listeners, fn) end
        P.Changed = function()
            for _, fn in ipairs(P.Listeners) do pcall(fn) end
        end

        ----------------------------------------------------------------------------
        -- disco
        ----------------------------------------------------------------------------
        P.Save = function(silent)
            local Http = V8.Net and V8.Net.Http
            if not Http then return false end
            local owned = {}
            for id in pairs(P.Owned) do table.insert(owned, id) end
            table.sort(owned)
            local ok, json = pcall(function()
                return Http:JSONEncode({ v = 1, total = math.floor(P.Total),
                    spent = P.Spent, bonus = P.Bonus, owned = owned, equip = P.Equip,
                    quests = P.Quests })
            end)
            if not ok then return false end
            local wrote, err = V8.Disk.Write(P.Path, json)
            if not wrote and not silent then
                Log("Playtime não foi salvo: " .. tostring(err), "error")
            end
            return wrote
        end

        P.Load = function()
            local raw, why = V8.Disk.Read(P.Path)
            if not raw then
                P.Status = V8.Disk.Ok() and "Primeira sessão: o contador começa agora."
                    or "Executor sem writefile/readfile: o tempo desta sessão se perde ao sair."
                return false, why
            end
            local ok, d = pcall(function() return V8.Net.Http:JSONDecode(raw) end)
            if not ok or type(d) ~= "table" then
                P.Status = "playtime.json ilegível — começando do zero (o arquivo antigo será sobrescrito)."
                return false
            end
            local total = tonumber(d.total)
            if total and total >= 0 and total < 1e9 then P.Total = total end
            local spent = tonumber(d.spent)
            if spent and spent >= 0 and spent < 1e9 then P.Spent = math.floor(spent) end
            local bonus = tonumber(d.bonus)
            if bonus and bonus >= 0 and bonus < 1e9 then P.Bonus = math.floor(bonus) end
            if type(d.quests) == "table" then P.Quests = d.quests end   -- validado em 08_quests
            if type(d.owned) == "table" then
                for _, id in ipairs(d.owned) do
                    if type(id) == "string" and P.ById[id] then P.Owned[id] = true end
                end
            end
            if type(d.equip) == "table" then
                for slot, id in pairs(d.equip) do
                    local it = type(id) == "string" and P.ById[id]
                    if it and P.Owned[id] and P.SlotOf[it.cat] == slot then P.Equip[slot] = id end
                end
            end
            P.Status = "Salvo em " .. P.Path .. " a cada minuto."
            return true
        end

        ----------------------------------------------------------------------------
        -- compra / equipar
        ----------------------------------------------------------------------------
        P.Buy = function(id)
            local it = P.ById[id]
            if not it then return false, "item desconhecido" end
            local price = P.PriceOf(it)
            if it.cat == "Bundles" then
                local _, have, total = P.BundlePrice(it)
                if have >= total then return false, "você já tem tudo deste pacote" end
            elseif P.Owned[id] then
                return false, "você já tem este item"
            end
            local pts = P.Points()
            if pts < price then return false, "faltam " .. (price - pts) .. " ponto(s)" end
            P.Spent = P.Spent + price
            P.Owned[id] = true
            for _, sub in ipairs(it.items or {}) do
                if P.ById[sub] then P.Owned[sub] = true end
            end
            P.Save(true)
            P.Changed()
            return true, price
        end

        -- pontos que faltam para comprar tudo o que ainda não é seu
        P.MissingCost = function()
            local sum = 0
            for _, it in ipairs(P.Items) do
                if it.cat ~= "Bundles" and not P.Owned[it.id] then sum = sum + it.price end
            end
            return sum
        end

        -- soma pontos sem mexer no tempo de jogo (Total continua honesto)
        P.Grant = function(n)
            n = math.floor(tonumber(n) or 0)
            if n <= 0 then return false end
            P.Bonus = math.min(P.Bonus + n, 1e9 - 1)
            P.Save(true)
            P.Changed()
            return true, n
        end

        -- libera todos os itens de graça (não gasta pontos)
        P.UnlockAll = function()
            local n = 0
            for _, it in ipairs(P.Items) do
                if not P.Owned[it.id] then P.Owned[it.id] = true n = n + 1 end
            end
            P.Save(true)
            P.Changed()
            return n
        end

        P.EquipItem = function(id)
            local it = P.ById[id]
            local slot = it and P.SlotOf[it.cat]
            if not slot or not P.Owned[id] then return false end
            P.Equip[slot] = id
            P.Save(true)
            P.Changed()
            return true
        end

        P.Unequip = function(slot)
            if not P.Equip[slot] then return end
            P.Equip[slot] = nil
            P.Save(true)
            P.Changed()
        end

        P.UnequipAll = function()
            for k in pairs(P.Equip) do P.Equip[k] = nil end
            P.Save(true)
            P.Changed()
        end

        -- contador: o scheduler roda os dois (V8.Job), sem loop próprio
        do
            local last = os.clock()
            V8.Job(1, function()
                local now = os.clock()
                P.Total = P.Total + math.clamp(now - last, 0, 5)
                last = now
            end)
        end
        V8.Job(60, function() P.Save(true) end)

        P.Load()

        ----------------------------------------------------------------------------
        -- COSMÉTICOS NO PERSONAGEM (efeito + nametag equipados)
        ----------------------------------------------------------------------------
        V8.Cos = { fx = {}, tag = nil }
        local C = V8.Cos

        C.Clear = function()
            for _, inst in ipairs(C.fx) do pcall(function() inst:Destroy() end) end
            C.fx = {}
            if C.tag then pcall(function() C.tag:Destroy() end) end
            C.tag = nil
        end

        local function Keep(inst)
            table.insert(C.fx, inst)
            return inst
        end

        local function Effect(root, kind)
            local accent = THEME.Accent
            if kind == "light" then
                local l = Keep(Instance.new("PointLight"))
                l.Brightness = 1.6
                l.Range = 14
                l.Color = accent
                l.Shadows = false
                l.Parent = root
            elseif kind == "sparkles" then
                local s = Keep(Instance.new("Sparkles"))
                s.SparkleColor = accent
                s.Parent = root
            elseif kind == "trail" then
                local a0 = Keep(Instance.new("Attachment"))
                a0.Name = "HYGE_TrailTop"
                a0.Position = Vector3.new(0, 1.1, 0)
                a0.Parent = root
                local a1 = Keep(Instance.new("Attachment"))
                a1.Name = "HYGE_TrailBottom"
                a1.Position = Vector3.new(0, -1.1, 0)
                a1.Parent = root
                local t = Keep(Instance.new("Trail"))
                t.Attachment0 = a0
                t.Attachment1 = a1
                t.Lifetime = 0.45
                t.MinLength = 0.05
                t.FaceCamera = true
                t.LightEmission = 0.6
                t.Color = ColorSequence.new(accent)
                t.Transparency = NumberSequence.new(0.2, 1)
                t.Parent = root
            elseif kind == "aura" then
                local e = Keep(Instance.new("ParticleEmitter"))
                e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                e.Color = ColorSequence.new(accent)
                e.LightEmission = 0.7
                e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5),
                    NumberSequenceKeypoint.new(1, 0) })
                e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 1) })
                e.Lifetime = NumberRange.new(0.8, 1.4)
                e.Rate = 22
                e.Speed = NumberRange.new(0.5, 1.5)
                e.SpreadAngle = Vector2.new(180, 180)
                e.Rotation = NumberRange.new(0, 360)
                e.RotSpeed = NumberRange.new(-90, 90)
                e.Parent = root
            elseif kind == "fire" then
                local f = Keep(Instance.new("Fire"))
                f.Size = 3.5
                f.Heat = 4
                f.Color = Color3.fromRGB(255, 140, 40)
                f.SecondaryColor = Color3.fromRGB(255, 60, 20)
                f.Parent = root
            end
        end

        local function Nametag(head, style)
            local bb = Instance.new("BillboardGui")
            bb.Name = "HYGE_Nametag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 220, 0, 46)
            bb.StudsOffset = Vector3.new(0, 3.6, 0)
            bb.MaxDistance = 150
            bb.LightInfluence = 0
            bb.Parent = head

            local rank = P.Equipped("rank")
            local title = P.Equipped("title")
            local name = LocalPlayer.DisplayName or LocalPlayer.Name
            if rank then name = "[" .. rank.name .. "] " .. name end

            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.BackgroundColor3 = Color3.new(0, 0, 0)
            holder.BackgroundTransparency = (style == "classic") and 0.45 or 1
            holder.BorderSizePixel = 0
            holder.Parent = bb
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 10)

            local top = Instance.new("TextLabel")
            top.Size = UDim2.new(1, 0, 0, title and 26 or 46)
            top.BackgroundTransparency = 1
            top.Text = name
            top.Font = Enum.Font.GothamBlack
            top.TextSize = 18
            top.TextColor3 = Color3.new(1, 1, 1)
            top.TextStrokeTransparency = 0.5
            top.Parent = holder

            if title then
                local sub = Instance.new("TextLabel")
                sub.Size = UDim2.new(1, 0, 0, 18)
                sub.Position = UDim2.new(0, 0, 0, 26)
                sub.BackgroundTransparency = 1
                sub.Text = title.name
                sub.Font = Enum.Font.GothamBold
                sub.TextSize = 13
                sub.TextColor3 = Color3.fromRGB(220, 220, 228)
                sub.TextStrokeTransparency = 0.6
                sub.Parent = holder
            end

            if rank and rank.color and style == "classic" then
                top.TextColor3 = rank.color
            elseif style == "neon" then
                top.TextStrokeTransparency = 1
                local st = Instance.new("UIStroke", top)
                st.Thickness = 2
                st.Color = THEME.Accent
                st.Transparency = 0.15
            elseif style == "gold" then
                top.TextColor3 = Color3.fromRGB(255, 205, 80)
                top.TextStrokeColor3 = Color3.fromRGB(90, 55, 10)
                top.TextStrokeTransparency = 0.2
            elseif style == "rainbow" then
                local g = Instance.new("UIGradient", top)
                g.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
                    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 230, 90)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 200, 255)),
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(160, 100, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 70)),
                })
                g.Offset = Vector2.new(-0.5, 0)
                -- tween infinito (vai e volta): nenhum loop do painel envolvido
                TweenService:Create(g, TweenInfo.new(2.5, Enum.EasingStyle.Linear,
                    Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.5, 0) }):Play()
            end
            return bb
        end

        C.Apply = function()
            C.Clear()
            local char = Char()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local fx = P.Equipped("effect")
            if fx and root then pcall(Effect, root, fx.fx) end
            local tag = P.Equipped("nametag")
            if tag and head then
                local ok, bb = pcall(Nametag, head, tag.style)
                if ok then C.tag = bb end
            end
        end

        Conn.CosChar = LocalPlayer.CharacterAdded:Connect(function(char)
            pcall(function()
                char:WaitForChild("HumanoidRootPart", 5)
                char:WaitForChild("Head", 5)
            end)
            pcall(C.Apply)
        end)
        P.OnChange(function() pcall(C.Apply) end)
        -- troca de tema: efeitos na cor nova (V8.Renders roda no ApplyTheme)
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(C.Apply) end)
    end
    Build()
end
