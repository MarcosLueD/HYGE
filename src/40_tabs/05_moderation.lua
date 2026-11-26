--------------------------------------------------------------------------------
-- ABA MODERATION
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Moderation")

    ----------------------------------------------------------------------------
    -- PAINEL DO SELECIONADO
    ----------------------------------------------------------------------------
    local sel = CreateCard(tab, "JOGADOR SELECIONADO", 1)

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 64)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = 1
    holder.Parent = sel

    local av = Avatar(holder, 1, 56)
    av.Position = UDim2.new(0, 0, 0, 4)

    local dn = Instance.new("TextLabel")
    dn.Size = UDim2.new(1, -76, 0, 20)
    dn.Position = UDim2.new(0, 68, 0, 4)
    dn.BackgroundTransparency = 1
    dn.Text = "Nenhum jogador selecionado"
    dn.TextColor3 = THEME.Text
    dn.Font = Enum.Font.GothamBold
    dn.TextSize = 15
    dn.TextXAlignment = Enum.TextXAlignment.Left
    dn.Parent = holder
    Paint(dn, "TextColor3", "Text")

    local un = Instance.new("TextLabel")
    un.Size = UDim2.new(1, -76, 0, 15)
    un.Position = UDim2.new(0, 68, 0, 25)
    un.BackgroundTransparency = 1
    un.Text = "selecione alguém em Jogadores › Lista"
    un.TextColor3 = THEME.Dim
    un.Font = Enum.Font.Code
    un.TextSize = 12
    un.TextXAlignment = Enum.TextXAlignment.Left
    un.Parent = holder
    Paint(un, "TextColor3", "Dim")

    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -76, 0, 15)
    stats.Position = UDim2.new(0, 68, 0, 43)
    stats.BackgroundTransparency = 1
    stats.Text = ""
    stats.TextColor3 = THEME.Accent2
    stats.Font = Enum.Font.Code
    stats.TextSize = 11
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = holder
    Paint(stats, "TextColor3", "Accent2")

    local idRow = Grid(sel, 2, 30)
    idRow.LayoutOrder = 2
    local copyId = CreateButton(idRow, "COPIAR USERID", "Accent", 30)
    copyId.LayoutOrder = 1
    local copyName = CreateButton(idRow, "COPIAR @USERNAME", "Accent", 30)
    copyName.LayoutOrder = 2

    copyId.MouseButton1Click:Connect(function()
        local p = RequireSelected()
        if p then Copy(tostring(p.UserId), "UserId") end
    end)
    copyName.MouseButton1Click:Connect(function()
        local p = RequireSelected()
        if p then Copy(p.Name, "Username") end
    end)

    UpdateSelectedInfo = function()
        local p = State.SelectedPlayer
        if not p or not p.Parent then
            dn.Text = "Nenhum jogador selecionado"
            un.Text = "selecione alguém em Jogadores › Lista"
            stats.Text = ""
            av.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48"
            return
        end
        av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
        dn.Text = p.DisplayName
        un.Text = "@" .. p.Name .. "   ·   UserId " .. p.UserId

        local char = p.Character
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local myRoot = Root()
        local hp = h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth) .. " HP")
            or "sem personagem"
        local dist = (myRoot and root)
            and (math.floor((myRoot.Position - root.Position).Magnitude) .. "m") or "—"
        stats.Text = hp .. "   ·   " .. dist .. "   ·   "
            .. (p.Team and p.Team.Name or "sem equipe") .. "   ·   ping —"
    end

    ----------------------------------------------------------------------------
    -- MOVIMENTAÇÃO
    ----------------------------------------------------------------------------
    local mov = CreateCard(tab, "MOVIMENTAÇÃO", 2)
    SubLabel(mov, "TELEPORTAR ATÉ e SPECTATE são LOCAIS (o seu personagem e a sua câmera: "
        .. "funcionam em qualquer jogo). Com o servidor HYGE, TELEPORTAR passa por ele. "
        .. "TRAZER mexe no personagem de outra pessoa: só pelo SERVIDOR.", 0)
    local movGrid = Grid(mov, 3, 32)
    movGrid.LayoutOrder = 1

    ActionBtn(movGrid, "TELEPORTAR ATÉ", "Success", nil, function()
        local p = RequireSelected()
        if p then Goto(p) end
    end)

    ActionBtn(movGrid, "TRAZER (BRING)", "Warning", "Pull", function()
        local p = RequireSelected()
        if p then Bring(p) end
    end)

    ActionBtn(movGrid, "SPECTATE", "Accent", nil, function()
        local p = RequireSelected()
        if not p then return end
        if State.SpectateTarget == p then StopSpectate() else StartSpectate(p) end
    end)

    ----------------------------------------------------------------------------
    -- MODERAÇÃO (depende do servidor)
    ----------------------------------------------------------------------------
    local mod = CreateCard(tab, "MODERAÇÃO", 3)
    V8.SrvTag(mod, { "Kick", "Freeze" }, -1)

    local modGrid = Grid(mod, 3, 32)

    ActionBtn(modGrid, "KICK", "Danger", "Kick", function()
        local p = RequireSelected()
        if p then KickPlayer(p, "Removido por um admin") end
    end, "Enviar KICK para o jogador selecionado? A decisão final é do servidor.")

    ActionBtn(modGrid, "FREEZE", "Warning", "Freeze", function()
        local p = RequireSelected()
        if p then FreezePlayer(p, true) end
    end, "Congelar o jogador selecionado?")

    ActionBtn(modGrid, "UNFREEZE", "Success", "Freeze", function()
        local p = RequireSelected()
        if p then FreezePlayer(p, false) end
    end)

    ----------------------------------------------------------------------------
    -- COMUNICAÇÃO
    ----------------------------------------------------------------------------
    local com = CreateCard(tab, "COMUNICAÇÃO", 4)
    V8.SrvTag(com, { "Whisper", "Announce" }, 0)

    local wIn = CreateInput(com, "Mensagem privada para o selecionado...", 32)
    wIn.LayoutOrder = 1
    ActionBtn(com, "ENVIAR PRIVADO", "Accent", "Whisper", function()
        local p = RequireSelected()
        if not p then return end
        if wIn.Text:match("^%s*$") then
            Toast("Escreva a mensagem primeiro", "warn", 1.6)
            return
        end
        if V8.Srv.Whisper(p, wIn.Text) then wIn.Text = "" end
    end).LayoutOrder = 2

    Divider(com).LayoutOrder = 3

    local aIn = CreateInput(com, "Anúncio para o servidor...", 32)
    aIn.LayoutOrder = 4
    local aBtn = ActionBtn(com, "ANUNCIAR", "Warning", "Announce", function()
        if aIn.Text:match("^%s*$") then
            Toast("Escreva o anúncio primeiro", "warn", 1.6)
            return
        end
        if Announce(aIn.Text) then aIn.Text = "" end
    end, "Enviar este anúncio? O servidor filtra o texto antes de mostrar para todos.")
    aBtn.LayoutOrder = 5

    -- v8.1: o card TROLL mudou para a seção própria (40_tabs/12_troll.lua)

    OnTabOpen("Moderation", UpdateSelectedInfo)
    UpdateSelectedInfo()
end
