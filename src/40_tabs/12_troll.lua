--------------------------------------------------------------------------------
-- v8.1 — SEÇÃO TROLL (ícone de máscara do dock)
-- * Walk on Walls (20_features/10_wallwalk.lua): roda no SEU personagem, então
--   funciona em qualquer jogo — e os outros veem você andando na parede.
-- * Ações no alvo (veio da aba Moderação): Fling/Spin/Trip/Launch/Sit/Scale/
--   Balloon mexem no personagem de OUTRA pessoa, e isso só o servidor pode
--   fazer. Sem o RemoteEvent (script em server/) o botão fica indisponível e
--   explica o motivo — nada é fingido. Fake Message é só na sua tela.
-- O alvo é o jogador escolhido em Jogadores › Lista (botão ALVO).
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local tab = CreateTab("Troll")

        ----------------------------------------------------------------------------
        -- MOVIMENTO
        ----------------------------------------------------------------------------
        local mov = CreateCard(tab, "MOVIMENTO", 1)
        V8.SrvTag(mov, nil, 0, "roda no SEU personagem: funciona em qualquer jogo, sem servidor "
            .. "(os outros veem você na parede).")
        SwitchRow(mov, "wallwalk", "Walk on Walls", Toggles.wallwalk.desc)
        SubLabel(mov, "Ande contra uma parede para subir nela; continue para chegar ao "
            .. "teto. WASD segue a câmera, Space pula para fora da superfície e, sem "
            .. "nada embaixo por ~1 s, a gravidade volta ao normal. Usa a WalkSpeed e o "
            .. "JumpPower de Personagem. Desliga sozinho no respawn ou se Fly/Drone/"
            .. "Freecam forem ligados.", 2)

        ----------------------------------------------------------------------------
        -- ALVO
        ----------------------------------------------------------------------------
        local tgt = CreateCard(tab, "ALVO", 2)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 58)
        holder.LayoutOrder = 1
        holder.Parent = tgt
        V8.Cell(holder, 0)

        local av = Avatar(holder, 1, 40)
        av.Position = UDim2.new(0, 0, 0.5, -20)

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -160, 0, 18)
        name.Position = UDim2.new(0, 50, 0, 11)
        name.BackgroundTransparency = 1
        name.Text = "Nenhum alvo"
        name.TextColor3 = THEME.Text
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = holder
        Paint(name, "TextColor3", "Text")

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -160, 0, 14)
        sub.Position = UDim2.new(0, 50, 0, 30)
        sub.BackgroundTransparency = 1
        sub.Text = "escolha em Jogadores › Lista (botão ALVO)"
        sub.TextColor3 = THEME.Dim
        sub.Font = Enum.Font.Code
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.Parent = holder
        Paint(sub, "TextColor3", "Dim")

        local pick = CreateButton(holder, "ESCOLHER", "Accent", 28)
        pick.AnchorPoint = Vector2.new(1, 0.5)
        pick.Position = UDim2.new(1, 0, 0.5, 0)
        pick.Size = UDim2.new(0, 96, 0, 28)
        pick.TextSize = 11
        pick.MouseButton1Click:Connect(function() ShowTab("Players") end)

        local function Target()
            local p = State.SelectedPlayer
            if not p or not p.Parent then
                name.Text = "Nenhum alvo"
                sub.Text = "escolha em Jogadores › Lista (botão ALVO)"
                av.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48"
                return
            end
            av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
            name.Text = p.DisplayName
            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mine = Root()
            sub.Text = "@" .. p.Name .. ((root and mine)
                and ("  ·  " .. math.floor((root.Position - mine.Position).Magnitude) .. "m")
                or "  ·  sem personagem")
        end

        ----------------------------------------------------------------------------
        -- AÇÕES NO ALVO (servidor)
        ----------------------------------------------------------------------------
        local troll = CreateCard(tab, "AÇÕES NO ALVO", 3)
        V8.SrvTag(troll, { "Fling", "Spin", "Trip", "Launch", "Sit", "Balloon", "Scale" }, -1)
        SubLabel(troll, "Mexer no personagem de outra pessoa é coisa do servidor: o painel só "
            .. "pede, e o servidor confere o seu cargo, o alvo e o limite antes de fazer. "
            .. "SPIN e BALLOON mostram ON só depois que o servidor confirma.", 0)

        local grid = Grid(troll, 3, 32)
        grid.LayoutOrder = 1

        -- declarado antes: os botões chamam depois de enviar
        local Sync

        ActionBtn(grid, "FLING", "Danger", "Fling", function()
            local p = RequireSelected()
            if p then FlingPlayer(p) end
        end, "Aplicar Fling no alvo?")

        local spinBtn
        spinBtn = ActionBtn(grid, "SPIN: OFF", "Warning", "Spin", function()
            local p = RequireSelected()
            if not p then return end
            SpinPlayer(p, not TrollState.Spin[p.UserId])
            Sync()
        end)

        ActionBtn(grid, "TRIP", "Warning", "Trip", function()
            local p = RequireSelected()
            if p then TripPlayer(p) end
        end)

        ActionBtn(grid, "LAUNCH", "Danger", "Launch", function()
            local p = RequireSelected()
            if p then LaunchPlayer(p) end
        end, "Lançar o alvo bem alto?")

        ActionBtn(grid, "FORCE SIT", "Warning", "Sit", function()
            local p = RequireSelected()
            if p then SitPlayer(p) end
        end)

        local balloonBtn
        balloonBtn = ActionBtn(grid, "BALLOON: OFF", "Accent", "Balloon", function()
            local p = RequireSelected()
            if not p then return end
            BalloonPlayer(p, not TrollState.Balloon[p.UserId])
            Sync()
        end)

        ActionBtn(grid, "TINY", "Accent", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "tiny") end
        end, "Encolher o alvo?")

        ActionBtn(grid, "NORMAL", "Success", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "normal") end
        end)

        ActionBtn(grid, "GIANT", "Accent", "Scale", function()
            local p = RequireSelected()
            if p then ScalePlayer(p, "giant") end
        end, "Deixar o alvo gigante?")

        Divider(troll).LayoutOrder = 10

        local fake = Grid(troll, 2, 32)
        fake.LayoutOrder = 11

        ActionBtn(fake, "FAKE KICK MSG", "Warning", nil, function()
            local p = RequireSelected()
            if p then FakeMessage(p, "kick") end
        end)

        ActionBtn(fake, "FAKE BAN MSG", "Danger", nil, function()
            local p = RequireSelected()
            if p then FakeMessage(p, "ban") end
        end)

        V8.SrvTag(troll, nil, 12, "FAKE KICK/BAN MSG aparece só na SUA tela — não afeta o alvo "
            .. "nem o servidor.")

        -- os botões de liga/desliga seguem o alvo atual e o que o SERVIDOR
        -- confirmou (TrollState muda no HYGE_Result)
        Sync = function()
            local p = State.SelectedPlayer
            local id = p and p.UserId
            -- indisponível o botão mostra o motivo: não mexe no texto
            if not V8.Srv.Short("Spin") then
                spinBtn.Text = (id and TrollState.Spin[id]) and "SPIN: ON" or "SPIN: OFF"
            end
            if not V8.Srv.Short("Balloon") then
                balloonBtn.Text = (id and TrollState.Balloon[id]) and "BALLOON: ON" or "BALLOON: OFF"
            end
        end
        table.insert(V8.Srv.Hooks, function() pcall(Sync) end)

        V8.TabTick.Troll = function() Target() Sync() end
        OnTabOpen("Troll", function() pcall(Target) pcall(Sync) end)
        Target()
    end
    Build()
end
