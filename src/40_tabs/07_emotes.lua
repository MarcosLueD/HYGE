--------------------------------------------------------------------------------
-- ABA EMOTES (animações por ID + favoritos)
--
-- Limitação do Roblox, não do painel: o Animator só carrega AnimationId cujo
-- asset pertença ao dono do jogo (você ou o grupo) ou à própria Roblox. ID de
-- animação de terceiro simplesmente não carrega — por isso o erro aparece no
-- log em vez de fingir que tocou.
--
-- Só mexe no SEU personagem. Forçar animação em outro jogador é server-side e
-- precisaria de Remote com validação, igual kick/freeze.
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Emotes")

    local currentBox      -- label de status "tocando agora"
    local favList, favEmpty, RenderFavs

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

    Emote.Play = function(raw, label)
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
        SetStatus((label or ("ID " .. id)) .. "  •  em loop", "Success")
        Log("Emote tocando: " .. (label or tostring(id)), "action")
        return true
    end

    ----------------------------------------------------------------------------
    -- TOCAR POR ID
    ----------------------------------------------------------------------------
    local play = CreateCard(tab, "TOCAR ANIMAÇÃO", 1)

    SubLabel(play, "Cole o ID da animação (aceita rbxassetid:// ou a URL do "
        .. "catálogo). Toca em loop até você apertar PARAR.", 1)

    local idBox = CreateInput(play, "rbxassetid://0000000000", 34)
    idBox.LayoutOrder = 2

    local rowA = Instance.new("Frame")
    rowA.Size = UDim2.new(1, 0, 0, 34)
    rowA.BackgroundTransparency = 1
    rowA.LayoutOrder = 3
    rowA.Parent = play

    local playBtn = CreateButton(rowA, "TOCAR", "Accent", 34)
    playBtn.Size = UDim2.new(0.5, -4, 0, 34)

    local stopBtn = CreateButton(rowA, "PARAR", "Danger", 34)
    stopBtn.Size = UDim2.new(0.5, -4, 0, 34)
    stopBtn.Position = UDim2.new(0.5, 4, 0, 0)

    currentBox = SubLabel(play, "Nada tocando.", 4)

    SliderRow(play, {
        label = "Velocidade", min = 10, max = 300, def = 100, suffix = "%", order = 5,
        apply = function(v)
            Emote.Speed = v / 100
            if Emote.track then
                pcall(function() Emote.track:AdjustSpeed(Emote.Speed) end)
            end
        end,
    })

    playBtn.MouseButton1Click:Connect(function()
        Emote.Play(idBox.Text)
    end)
    stopBtn.MouseButton1Click:Connect(function()
        Emote.Stop()
    end)
    idBox.FocusLost:Connect(function(enter)
        if enter then Emote.Play(idBox.Text) end
    end)

    ----------------------------------------------------------------------------
    -- FAVORITOS
    ----------------------------------------------------------------------------
    local fav = CreateCard(tab, "FAVORITOS", 2)

    SubLabel(fav, "Salve os IDs que você mais usa. O nome também funciona no "
        .. "comando: emote <nome>.", 1)

    local nameBox = CreateInput(fav, "nome do emote (ex: dance)", 34)
    nameBox.LayoutOrder = 2

    local addBtn = CreateButton(fav, "SALVAR O ID ACIMA NOS FAVORITOS", "Accent2", 34)
    addBtn.LayoutOrder = 3

    favList = Instance.new("Frame")
    favList.Size = UDim2.new(1, 0, 0, 0)
    favList.AutomaticSize = Enum.AutomaticSize.Y
    favList.BackgroundTransparency = 1
    favList.LayoutOrder = 4
    favList.Parent = fav
    local favLayout = Instance.new("UIListLayout", favList)
    favLayout.Padding = UDim.new(0, 5)
    favLayout.SortOrder = Enum.SortOrder.LayoutOrder

    favEmpty = SubLabel(fav, "Nenhum favorito salvo.", 5)

    RenderFavs = function()
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
            idLbl.Size = UDim2.new(0, 150, 1, 0)
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
            go.MouseButton1Click:Connect(function()
                Emote.Play(e.id, e.name)
            end)

            local del = CreateButton(row, "EXCLUIR", "Danger", 24)
            del.Size = UDim2.new(0, 68, 0, 24)
            del.Position = UDim2.new(1, -66, 0.5, -12)
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

    addBtn.MouseButton1Click:Connect(function()
        local id = ParseId(idBox.Text)
        if not id then
            Toast("Cole um ID válido no campo acima", "warn", 2)
            return
        end
        local nm = nameBox.Text
        if nm == "" then nm = "Emote " .. (#State.Emotes + 1) end
        table.insert(State.Emotes, { name = nm, id = id })
        nameBox.Text = ""
        Log("Emote salvo: " .. nm .. " (" .. id .. ")", "ok")
        Toast("Emote salvo", "ok", 1.5)
        RenderFavs()
    end)

    local clearBtn = CreateButton(fav, "LIMPAR TODOS", "Line", 30)
    clearBtn.LayoutOrder = 6
    clearBtn.MouseButton1Click:Connect(function()
        Confirm("Apagar todos os " .. #State.Emotes .. " favoritos?", function()
            for i = #State.Emotes, 1, -1 do State.Emotes[i] = nil end
            Log("Favoritos de emote limpos", "action")
            RenderFavs()
        end)
    end)

    RenderFavs()
    V8.RenderEmotes = RenderFavs  -- v8.0: 50_v8/03_persist.lua re-renderiza favoritos importados

    ----------------------------------------------------------------------------
    -- AVISO
    ----------------------------------------------------------------------------
    local info = CreateCard(tab, "COMO FUNCIONA", 3)
    SubLabel(info, "1. O Roblox só carrega animação cujo asset pertença ao dono "
        .. "do jogo (você/seu grupo) ou à própria Roblox. ID de terceiro falha "
        .. "e o erro aparece no console.", 1)
    SubLabel(info, "2. A animação roda no SEU personagem e replica normalmente "
        .. "para os outros jogadores — é você quem tem network ownership dele.", 2)
    SubLabel(info, "3. Forçar emote em outro jogador é server-side. Sem Remote "
        .. "com validação, o painel não faz e não finge que fez.", 3)
    SubLabel(info, "4. O emote continua durante o Fly: ao tocar, a pose de "
        .. "superman é desligada para não brigar pelas mesmas juntas.", 4)
    SubLabel(info, "5. Respawn derruba a animação (o personagem é outro). "
        .. "É só apertar TOCAR de novo.", 5)
end
