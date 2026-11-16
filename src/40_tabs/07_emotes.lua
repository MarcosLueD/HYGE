--------------------------------------------------------------------------------
-- ABA EMOTES (catálogo pesquisável + tocar por ID + favoritos)
--
-- Limitação do Roblox, não do painel: o Animator só carrega animação cujo
-- asset pertença ao dono do jogo (você ou o grupo) ou à própria Roblox. ID de
-- terceiro "carrega" com duração 0 e não anima nada — o painel confere isso
-- depois de tocar e avisa no log (e marca a linha do catálogo), em vez de
-- fingir que tocou.
--
-- v8.1:
--   * catálogo pesquisável: emotes padrão DO JOGO (lidos do script Animate do
--     seu personagem — sempre carregam, R6 e R15) + emotes e danças que a
--     Roblox publicou (só R15)
--   * velocidade de reprodução (Playback Speed) e "Andar com o emote":
--     desligado, o emote para quando você anda (como no Roblox); ligado, ele
--     continua enquanto você se move
--
-- Só mexe no SEU personagem. A animação replica para os outros normalmente
-- (você é o dono da física dele). Forçar emote em outra pessoa é server-side.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Emotes")
        if SET.EmoteWalk == nil then SET.EmoteWalk = false end

        local E = { failed = {}, filter = "Todos", query = "" }
        V8.Emotes = E
        local currentBox   -- "tocando agora"

        ----------------------------------------------------------------------------
        -- MOTOR
        ----------------------------------------------------------------------------
        -- Aceita "123456", "rbxassetid://123456" e a URL do catálogo.
        local function ParseId(raw)
            if not raw then return nil end
            local s = tostring(raw):gsub("%s+", "")
            if s == "" then return nil end
            local n = s:match("(%d%d%d%d+)")
            return n and tonumber(n) or nil
        end
        E.ParseId = ParseId

        local function Animator()
            local h = Hum()
            if not h then return nil end
            local a = h:FindFirstChildOfClass("Animator")
            if not a then
                local ok = pcall(function()
                    a = Instance.new("Animator")
                    a.Parent = h
                end)
                if not ok then return nil end
            end
            return a
        end

        local function SetStatus(text, colorKey)
            if not currentBox then return end
            currentBox.Text = text
            currentBox.TextColor3 = THEME[colorKey or "Dim"]
        end

        Emote.Stop = function(quiet)
            Drop("EmoteMove")
            if Emote.track then
                pcall(function() Emote.track:Stop(0.15) end)
                pcall(function() Emote.track:Destroy() end)
            end
            Emote.track = nil
            Emote.id = nil
            -- libera a animação do voo, se o fly estiver ligado
            pcall(function() if FlyPose then FlyPose.muted = false end end)
            SetStatus("Nada tocando.", "Dim")
            if not quiet then Log("Emote parado", "action") end
        end

        -- entry (opcional): linha do catálogo — r15 = só toca em R15
        Emote.Play = function(raw, label, entry)
            local id = ParseId(raw)
            if not id then
                Log("ID de animação inválido: " .. tostring(raw), "warn")
                Toast("ID inválido", "warn", 2)
                return false
            end

            local h = Hum()
            if not h then
                Toast("Sem personagem", "warn", 2)
                return false
            end
            if entry and entry.r15 and h.RigType == Enum.HumanoidRigType.R6 then
                Log(tostring(label or id) .. " é um emote R15 — seu personagem é R6 "
                    .. "(este jogo usa R6). Os emotes 'Padrão' funcionam.", "warn")
                Toast("Emote só para R15", "warn", 2)
                return false
            end

            local anim = Animator()
            if not anim then
                Log("Não consegui acessar o Animator do personagem", "error")
                return false
            end

            Emote.Stop(true)

            -- o emote vence a pose/animação do voo (as duas escrevem nas juntas)
            pcall(function() if FlyPose and FlyPose.active then FlyPose.Stop() end end)
            pcall(function()
                if FlyPose then FlyPose.muted = true end
                if flyTrack and flyTrack.IsPlaying then flyTrack:Stop(0.15) end
                if FlyPose and FlyPose.idleTrack and FlyPose.idleTrack.IsPlaying then
                    FlyPose.idleTrack:Stop(0.15)
                end
            end)

            local obj = Instance.new("Animation")
            obj.AnimationId = "rbxassetid://" .. id
            local ok, track = pcall(function() return anim:LoadAnimation(obj) end)
            pcall(function() obj:Destroy() end)

            if not ok or not track then
                Log("Animação " .. id .. " não carregou. O asset precisa pertencer "
                    .. "ao dono do jogo (ou à Roblox).", "error")
                Toast("Animação não carregou", "error", 3)
                return false
            end

            local ok2, err = pcall(function()
                track.Priority = Enum.AnimationPriority.Action4
                track.Looped = true
                track:Play(0.15)
                track:AdjustSpeed(Emote.Speed or 1)
            end)
            if not ok2 then
                Log("Falha ao tocar a animação: " .. tostring(err), "error")
                pcall(function() track:Destroy() end)
                return false
            end

            Emote.track = track
            Emote.id = id
            label = label or ("ID " .. id)
            SetStatus(label .. "  •  em loop", "Success")
            Log("Emote tocando: " .. label, "action")

            -- "Andar com o emote" desligado: andar encerra o emote
            Conn.EmoteMove = h:GetPropertyChangedSignal("MoveDirection"):Connect(function()
                if SET.EmoteWalk or Emote.track ~= track then return end
                if h.MoveDirection.Magnitude > 0.1 then
                    Emote.Stop(true)
                    Log("Emote parou porque você andou (ligue 'Andar com o emote' "
                        .. "para continuar andando com ele)")
                end
            end)

            -- asset recusado pelo Roblox: a track existe, mas com duração 0
            task.delay(3, function()
                if Emote.track ~= track then return end
                local len = 0
                pcall(function() len = track.Length end)
                if len > 0 then return end
                E.failed[id] = true
                Emote.Stop(true)
                SetStatus("Não carregou: " .. label, "Danger")
                Log("Animação " .. id .. " (" .. label .. ") não carregou — o Roblox recusou "
                    .. "o asset neste jogo", "error")
                if E.Render then pcall(E.Render) end
            end)
            return true
        end

        ----------------------------------------------------------------------------
        -- CATÁLOGO
        -- Emotes e danças que a própria Roblox publicou (R15). Os IDs ainda não
        -- foram conferidos um a um em jogo: o que não carregar é avisado no log e
        -- marcado como "não carregou" na lista.
        ----------------------------------------------------------------------------
        E.Catalog = {
            -- danças
            { "Hype Dance", 3695333486, "Dança" },     { "Line Dance", 4049037604, "Dança" },
            { "Baby Dance", 4265725525, "Dança" },     { "Dorky Dance", 4212455378, "Dança" },
            { "Air Dance", 4555808220, "Dança" },      { "Floss Dance", 5917459365, "Dança" },
            { "Dolphin Dance", 5918726674, "Dança" },  { "Old Town Road", 5937560570, "Dança" },
            { "Rodeo Dance", 5918728267, "Dança" },    { "Around Town", 3303391864, "Dança" },
            { "Top Rock", 3361276673, "Dança" },       { "Fancy Feet", 3333432454, "Dança" },
            { "Robot", 3338025566, "Dança" },          { "Monkey", 3333499508, "Dança" },
            { "Fashionable", 3333331310, "Dança" },    { "Twirl", 3334968680, "Dança" },
            { "Bunny Hop", 4641985101, "Dança" },      { "Rock Out", 5915714366, "Dança" },
            -- emotes
            { "Salute", 3360689775, "Emote" },         { "Tilt", 3360692915, "Emote" },
            { "Stadium", 3360686498, "Emote" },        { "Shrug", 3576968026, "Emote" },
            { "Hello", 3576686446, "Emote" },          { "Point", 3576823880, "Emote" },
            { "Godlike", 3337994105, "Emote" },        { "Superhero Reveal", 3695373233, "Emote" },
            { "Heisman Pose", 3695263073, "Emote" },   { "Celebrate", 3338097973, "Emote" },
            { "Haha", 3337966527, "Emote" },           { "Greatest", 3338042785, "Emote" },
            { "Sneaky", 3334424322, "Emote" },         { "Bodybuilder", 3333387824, "Emote" },
            { "Happy", 4841405708, "Emote" },          { "Jumping Wave", 4940564896, "Emote" },
            { "Confused", 4940561610, "Emote" },       { "Cower", 4940563117, "Emote" },
            { "Zombie", 4210116953, "Emote" },         { "Curtsy", 4555816777, "Emote" },
            { "Sleep", 4686925579, "Emote" },          { "Shy", 3337978742, "Emote" },
            { "T", 3338010159, "Emote" },              { "Tree", 4049551434, "Emote" },
            { "Fishing", 3994127840, "Emote" },
        }

        -- emotes padrão do jogo: o script Animate do personagem guarda os IDs
        -- (/e wave, /e dance...). Sempre carregam, R6 ou R15.
        local DEFAULTS = {
            { "wave", "Acenar" }, { "point", "Apontar" }, { "cheer", "Comemorar" },
            { "laugh", "Rir" }, { "dance", "Dança 1" }, { "dance2", "Dança 2" },
            { "dance3", "Dança 3" },
        }
        E.FromGame = function()
            local out = {}
            local char = Char()
            local animate = char and char:FindFirstChild("Animate")
            if not animate then return out end
            for _, d in ipairs(DEFAULTS) do
                local folder = animate:FindFirstChild(d[1])
                local a = folder and folder:FindFirstChildOfClass("Animation")
                local id = a and ParseId(a.AnimationId)
                if id then table.insert(out, { name = d[2], id = id, kind = "Padrão" }) end
            end
            return out
        end

        E.All = function()
            local rows = E.FromGame()
            for _, c in ipairs(E.Catalog) do
                table.insert(rows, { name = c[1], id = c[2], kind = c[3], r15 = true })
            end
            return rows
        end

        local function AddFav(id, name)
            for _, f in ipairs(State.Emotes) do
                if tonumber(f.id) == tonumber(id) then
                    Toast(name .. " já está nos favoritos", "warn", 1.6)
                    return
                end
            end
            table.insert(State.Emotes, { name = name, id = id })
            Log("Emote salvo: " .. name .. " (" .. id .. ")", "ok")
            Toast("Salvo nos favoritos", "ok", 1.5)
            if V8.RenderEmotes then V8.RenderEmotes() end
        end

        ----------------------------------------------------------------------------
        -- AGORA (status, parar, velocidade, andar com o emote)
        ----------------------------------------------------------------------------
        local now = CreateCard(tab, "TOCANDO AGORA", 1)
        currentBox = SubLabel(now, "Nada tocando.", 1)
        currentBox.Font = Enum.Font.GothamBold
        currentBox.TextSize = 12

        local nowBtns = Grid(now, 2, 32)
        nowBtns.LayoutOrder = 2
        local stopBtn = CreateButton(nowBtns, "PARAR", "Danger", 32)
        stopBtn.LayoutOrder = 1
        stopBtn.MouseButton1Click:Connect(function() Emote.Stop() end)

        local rnd = CreateButton(nowBtns, "DANÇA ALEATÓRIA", "Accent", 32)
        rnd.LayoutOrder = 2
        rnd.MouseButton1Click:Connect(function()
            local pool = {}
            local h = Hum()
            local r6 = h and h.RigType == Enum.HumanoidRigType.R6
            for _, e in ipairs(E.All()) do
                local dance = e.kind == "Dança" or (e.kind == "Padrão" and e.name:find("Dança"))
                if dance and not E.failed[e.id] and not (r6 and e.r15) then
                    table.insert(pool, e)
                end
            end
            if #pool == 0 then
                Toast("Nenhuma dança disponível para este personagem", "warn", 2)
                return
            end
            local e = pool[math.random(1, #pool)]
            Emote.Play(e.id, e.name, e)
        end)

        SliderRow(now, {
            label = "Velocidade (Playback Speed)", min = 10, max = 300, def = 100,
            suffix = "%", order = 3,
            apply = function(v)
                Emote.Speed = v / 100
                if Emote.track then
                    pcall(function() Emote.track:AdjustSpeed(Emote.Speed) end)
                end
            end,
        })

        CheckRow(now, "Andar com o emote",
            "Desligado: o emote para quando você anda (como no Roblox)",
            function() return SET.EmoteWalk == true end,
            function(v) SET.EmoteWalk = v and true or false end, 4)

        ----------------------------------------------------------------------------
        -- CATÁLOGO (busca + filtro + lista)
        ----------------------------------------------------------------------------
        local cat = CreateCard(tab, "CATÁLOGO", 2)
        local search = CreateInput(cat, "Buscar emote ou dança...", 32)
        search.LayoutOrder = 1

        local pills = Grid(cat, 4, 28)
        pills.LayoutOrder = 2
        local pillBtns = {}

        local countLbl = SubLabel(cat, "", 3)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 4
        list.Parent = cat
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local function PaintPills()
            for name, b in pairs(pillBtns) do
                local on = (name == E.filter)
                b.BackgroundColor3 = on and THEME.Accent or THEME.Btn
                b.TextColor3 = on and THEME.Main or THEME.Text
            end
        end

        for i, name in ipairs({ "Todos", "Danças", "Emotes", "Padrão" }) do
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
                E.filter = name
                PaintPills()
                E.Render()
            end)
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, PaintPills)

        local KIND_OF = { ["Danças"] = "Dança", ["Emotes"] = "Emote", ["Padrão"] = "Padrão" }

        local function Row(e, order)
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = THEME.Btn
            row.Text = ""
            row.AutoButtonColor = false
            row.LayoutOrder = order
            row.Parent = list
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -140, 0, 18)
            nm.Position = UDim2.new(0, 12, 0, 4)
            nm.BackgroundTransparency = 1
            nm.Text = e.name
            nm.TextColor3 = THEME.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row
            Paint(nm, "TextColor3", "Text")

            local failed = E.failed[e.id]
            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(1, -140, 0, 13)
            sub.Position = UDim2.new(0, 12, 0, 22)
            sub.BackgroundTransparency = 1
            sub.Text = failed and "não carregou neste jogo"
                or (e.kind == "Padrão" and "padrão do jogo" or (e.kind .. " · R15"))
            sub.TextColor3 = failed and THEME.Danger or THEME.Dim
            sub.Font = Enum.Font.GothamMedium
            sub.TextSize = 10
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Parent = row
            Paint(sub, "TextColor3", failed and "Danger" or "Dim")

            local play = CreateButton(row, "TOCAR", "Accent", 26)
            play.Size = UDim2.new(0, 62, 0, 26)
            play.Position = UDim2.new(1, -128, 0.5, -13)
            play.TextSize = 11
            play.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name, e) end)

            local fav = CreateButton(row, "+ FAV", "Accent2", 26)
            fav.Size = UDim2.new(0, 56, 0, 26)
            fav.Position = UDim2.new(1, -62, 0.5, -13)
            fav.TextSize = 11
            fav.MouseButton1Click:Connect(function() AddFav(e.id, e.name) end)

            row.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name, e) end)
        end

        E.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local q = E.query
            local want = KIND_OF[E.filter]
            local shown, total = 0, 0
            for _, e in ipairs(E.All()) do
                total = total + 1
                local passKind = (want == nil) or (e.kind == want)
                local passQ = (q == "") or (e.name:lower():find(q, 1, true) ~= nil)
                if passKind and passQ then
                    shown = shown + 1
                    Row(e, shown)
                end
            end
            local h = Hum()
            countLbl.Text = shown .. " de " .. total .. " animações"
                .. ((h and h.RigType == Enum.HumanoidRigType.R6)
                    and "   ·   personagem R6: só os 'padrão' tocam" or "")
        end

        search:GetPropertyChangedSignal("Text"):Connect(function()
            E.query = search.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
            E.Render()
        end)
        -- personagem novo (R6/R15, Animate diferente): a lista acompanha
        OnTabOpen("Emotes", function() pcall(E.Render) end)
        PaintPills()
        E.Render()

        ----------------------------------------------------------------------------
        -- TOCAR POR ID
        ----------------------------------------------------------------------------
        local play = CreateCard(tab, "TOCAR POR ID", 3)
        SubLabel(play, "Cole o ID da animação (aceita rbxassetid:// ou a URL do "
            .. "catálogo). Toca em loop até você apertar PARAR.", 1)

        local idBox = CreateInput(play, "rbxassetid://0000000000", 34)
        idBox.LayoutOrder = 2

        local nameBox = CreateInput(play, "nome para salvar nos favoritos (opcional)", 32)
        nameBox.LayoutOrder = 3

        local rowA = Grid(play, 2, 32)
        rowA.LayoutOrder = 4
        local playBtn = CreateButton(rowA, "TOCAR", "Accent", 32)
        playBtn.LayoutOrder = 1
        local addBtn = CreateButton(rowA, "SALVAR NOS FAVORITOS", "Accent2", 32)
        addBtn.LayoutOrder = 2

        playBtn.MouseButton1Click:Connect(function() Emote.Play(idBox.Text) end)
        idBox.FocusLost:Connect(function(enter)
            if enter then Emote.Play(idBox.Text) end
        end)
        addBtn.MouseButton1Click:Connect(function()
            local id = ParseId(idBox.Text)
            if not id then
                Toast("Cole um ID válido no campo acima", "warn", 2)
                return
            end
            local nm = nameBox.Text
            if nm == "" then nm = "Emote " .. (#State.Emotes + 1) end
            nameBox.Text = ""
            AddFav(id, nm)
        end)

        ----------------------------------------------------------------------------
        -- FAVORITOS
        ----------------------------------------------------------------------------
        local fav = CreateCard(tab, "FAVORITOS", 4)
        SubLabel(fav, "Os favoritos vão na config em disco. O nome também funciona no "
            .. "comando: emote <nome>.", 1)

        local favList = Instance.new("Frame")
        favList.Size = UDim2.new(1, 0, 0, 0)
        favList.AutomaticSize = Enum.AutomaticSize.Y
        favList.BackgroundTransparency = 1
        favList.LayoutOrder = 4
        favList.Parent = fav
        do
            local l = Instance.new("UIListLayout", favList)
            l.Padding = UDim.new(0, 5)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end

        local favEmpty = SubLabel(fav, "Nenhum favorito salvo — use + FAV no catálogo.", 5)

        local function RenderFavs()
            for _, c in ipairs(favList:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            favEmpty.Visible = (#State.Emotes == 0)

            for i, e in ipairs(State.Emotes) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 32)
                row.BackgroundColor3 = THEME.Btn
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                row.Parent = favList
                Paint(row, "BackgroundColor3", "Btn")
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                local nb = Instance.new("TextBox")
                nb.Size = UDim2.new(1, -244, 1, 0)
                nb.Position = UDim2.new(0, 10, 0, 0)
                nb.BackgroundTransparency = 1
                nb.Text = e.name
                nb.TextColor3 = THEME.Text
                nb.Font = Enum.Font.GothamMedium
                nb.TextSize = 12
                nb.TextXAlignment = Enum.TextXAlignment.Left
                nb.ClearTextOnFocus = false
                nb.Parent = row
                Paint(nb, "TextColor3", "Text")
                nb.FocusLost:Connect(function()
                    local t = nb.Text
                    if t == "" then nb.Text = e.name return end
                    Log("Emote renomeado: " .. e.name .. " -> " .. t, "action")
                    e.name = t
                end)

                local idLbl = Instance.new("TextLabel")
                idLbl.AnchorPoint = Vector2.new(1, 0.5)
                idLbl.Position = UDim2.new(1, -150, 0.5, 0)
                idLbl.Size = UDim2.new(0, 90, 1, 0)
                idLbl.BackgroundTransparency = 1
                idLbl.Text = tostring(e.id)
                idLbl.TextColor3 = THEME.Dim
                idLbl.Font = Enum.Font.Code
                idLbl.TextSize = 11
                idLbl.TextXAlignment = Enum.TextXAlignment.Right
                idLbl.Parent = row
                Paint(idLbl, "TextColor3", "Dim")

                local go = CreateButton(row, "TOCAR", "Accent", 24)
                go.Size = UDim2.new(0, 62, 0, 24)
                go.Position = UDim2.new(1, -138, 0.5, -12)
                go.MouseButton1Click:Connect(function() Emote.Play(e.id, e.name) end)

                local del = CreateButton(row, "EXCLUIR", "Danger", 24)
                del.Size = UDim2.new(0, 68, 0, 24)
                del.Position = UDim2.new(1, -70, 0.5, -12)
                del.MouseButton1Click:Connect(function()
                    for k, item in ipairs(State.Emotes) do
                        if item == e then
                            table.remove(State.Emotes, k)
                            break
                        end
                    end
                    Log("Emote removido: " .. e.name, "action")
                    RenderFavs()
                end)
            end
        end

        local clearBtn = CreateButton(fav, "LIMPAR TODOS", "Line", 30)
        clearBtn.LayoutOrder = 6
        clearBtn.MouseButton1Click:Connect(function()
            if #State.Emotes == 0 then return end
            Confirm("Apagar todos os " .. #State.Emotes .. " favoritos?", function()
                for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
                Log("Favoritos de emote limpos", "action")
                RenderFavs()
            end)
        end)

        RenderFavs()
        V8.RenderEmotes = RenderFavs  -- 50_v8/03_persist.lua re-renderiza favoritos importados

        ----------------------------------------------------------------------------
        -- COMO FUNCIONA
        ----------------------------------------------------------------------------
        local info = CreateCard(tab, "COMO FUNCIONA", 5)
        SubLabel(info, "1. O Roblox só carrega animação cujo asset pertença ao dono do "
            .. "jogo ou à própria Roblox. O que não carregar é avisado no console e "
            .. "marcado na lista.", 1)
        SubLabel(info, "2. 'Padrão' são os emotes do próprio jogo (/e wave, /e dance...): "
            .. "funcionam em R6 e R15. O resto do catálogo é R15.", 2)
        SubLabel(info, "3. A animação roda no SEU personagem e os outros jogadores veem. "
            .. "Forçar emote em outra pessoa é server-side — o painel não faz.", 3)
        SubLabel(info, "4. Durante o Fly, tocar um emote desliga a pose de voo (as duas "
            .. "mexem nas mesmas juntas). Respawn derruba a animação.", 4)
    end
    Build()
end
