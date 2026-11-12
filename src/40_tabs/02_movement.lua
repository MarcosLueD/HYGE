--------------------------------------------------------------------------------
-- ABA MOVEMENT
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Movement")

    ----------------------------------------------------------------------------
    -- TOGGLES
    ----------------------------------------------------------------------------
    local main = CreateCard(tab, "MOVIMENTO", 1)
    SwitchRow(main, "fly", "Fly", Toggles.fly.desc)
    SwitchRow(main, "noclip", "Noclip", Toggles.noclip.desc)
    SwitchRow(main, "infjump", "Infinite Jump", Toggles.infjump.desc)
    SwitchRow(main, "god", "God Mode", Toggles.god.desc)

    ----------------------------------------------------------------------------
    -- VELOCIDADES
    ----------------------------------------------------------------------------
    local speeds = CreateCard(tab, "VELOCIDADES", 2)
    SubLabel(speeds, "Arraste, digite o número ou use RESET. Vale também via comandos.", -1)

    FlySlider = SliderRow(speeds, {
        label = "Fly Speed", min = 10, max = 500, def = State.FlySpeed, order = 1,
        apply = function(v) State.FlySpeed = v end,
    })

    WalkSlider = SliderRow(speeds, {
        label = "WalkSpeed", min = 0, max = 400, def = State.WalkSpeed, order = 2,
        apply = function(v)
            State.WalkSpeed = v
            local h = Hum()
            if h then h.WalkSpeed = v end
        end,
    })

    JumpSlider = SliderRow(speeds, {
        label = "JumpPower", min = 0, max = 400, def = State.JumpPower, order = 3,
        apply = function(v)
            State.JumpPower = v
            local h = Hum()
            if h then
                if h.UseJumpPower ~= nil then h.UseJumpPower = true end
                h.JumpPower = v
            end
        end,
    })

    ----------------------------------------------------------------------------
    -- CÂMERA / DRONE
    ----------------------------------------------------------------------------
    local drone = CreateCard(tab, "CÂMERA E DRONE", 3)
    SwitchRow(drone, "freecam", "Freecam", Toggles.freecam.desc)
    SwitchRow(drone, "drone", "Modo Drone", Toggles.drone.desc)

    DroneSpeedSlider = SliderRow(drone, {
        label = "Drone Speed", min = 10, max = 400, def = State.DroneSpeed, order = 3,
        apply = function(v) State.DroneSpeed = v end,
    })

    SliderRow(drone, {
        label = "Drone Sensibilidade", min = 1, max = 12, def = State.DroneSens, order = 4,
        apply = function(v) State.DroneSens = v end,
    })

    SliderRow(drone, {
        label = "Drone Suavidade", min = 1, max = 20, def = State.DroneSmooth, order = 5,
        apply = function(v) State.DroneSmooth = v end,
    })

    SubLabel(drone, "No drone: WASD move, E/Q sobe/desce, scroll muda a velocidade. "
        .. "O personagem fica ancorado no lugar e volta ao normal ao desligar.", 6)

    ----------------------------------------------------------------------------
    -- TELEPORTE RÁPIDO
    ----------------------------------------------------------------------------
    local tp = CreateCard(tab, "TELEPORTE", 4)
    local tpGrid = Grid(tp, 3, 34)

    local up = CreateButton(tpGrid, "SUBIR 50", "Accent", 34)
    up.LayoutOrder = 1
    up.MouseButton1Click:Connect(function()
        local r = Root()
        if r then TeleportTo(r.CFrame * CFrame.new(0, 50, 0)) end
    end)

    local fwd = CreateButton(tpGrid, "FRENTE 30", "Accent", 34)
    fwd.LayoutOrder = 2
    fwd.MouseButton1Click:Connect(function()
        local r = Root()
        if r then TeleportTo(r.CFrame * CFrame.new(0, 0, -30)) end
    end)

    local toCam = CreateButton(tpGrid, "PARA A CÂMERA", "Accent", 34)
    toCam.LayoutOrder = 3
    toCam.MouseButton1Click:Connect(function()
        TeleportTo(Camera.CFrame * CFrame.new(0, 0, -6))
        Log("Teleporte para a câmera", "action")
    end)

    ----------------------------------------------------------------------------
    -- WAYPOINTS
    ----------------------------------------------------------------------------
    local wp = CreateCard(tab, "WAYPOINTS", 5)
    SubLabel(wp, "Salva a posição atual do personagem. Os waypoints vão junto na "
        .. "config em disco (Ajustes › Configuração em disco).", -1)

    local wpInput = CreateInput(wp, "Nome do waypoint", 32)
    wpInput.LayoutOrder = 1

    local wpBtns = Grid(wp, 2, 32)
    wpBtns.LayoutOrder = 2

    local saveBtn = CreateButton(wpBtns, "SALVAR AQUI", "Success", 32)
    saveBtn.LayoutOrder = 1
    local clearBtn = CreateButton(wpBtns, "LIMPAR TODOS", "Danger", 32)
    clearBtn.LayoutOrder = 2

    local wpList = Instance.new("Frame")
    wpList.Size = UDim2.new(1, 0, 0, 0)
    wpList.AutomaticSize = Enum.AutomaticSize.Y
    wpList.BackgroundTransparency = 1
    wpList.LayoutOrder = 3
    wpList.Parent = wp
    local wpLayout = Instance.new("UIListLayout", wpList)
    wpLayout.Padding = UDim.new(0, 5)
    wpLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local emptyLbl = SubLabel(wp, "Nenhum waypoint salvo.", 4)

    RenderWaypoints = function()
        for _, c in ipairs(wpList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        emptyLbl.Visible = (#State.Waypoints == 0)

        for i, w in ipairs(State.Waypoints) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 32)
            row.BackgroundColor3 = THEME.Btn
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = wpList
            Paint(row, "BackgroundColor3", "Btn")
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local nameBox = Instance.new("TextBox")
            nameBox.Size = UDim2.new(1, -224, 1, 0)
            nameBox.Position = UDim2.new(0, 10, 0, 0)
            nameBox.BackgroundTransparency = 1
            nameBox.Text = w.name
            nameBox.TextColor3 = THEME.Text
            nameBox.Font = Enum.Font.GothamMedium
            nameBox.TextSize = 12
            nameBox.TextXAlignment = Enum.TextXAlignment.Left
            nameBox.ClearTextOnFocus = false
            nameBox.Parent = row
            Paint(nameBox, "TextColor3", "Text")
            nameBox.FocusLost:Connect(function()
                local t = nameBox.Text
                if t == "" then
                    nameBox.Text = w.name
                    return
                end
                Log("Waypoint renomeado: " .. w.name .. " -> " .. t, "action")
                w.name = t
            end)

            local pos = Instance.new("TextLabel")
            pos.AnchorPoint = Vector2.new(1, 0.5)
            pos.Position = UDim2.new(1, -150, 0.5, 0)
            pos.Size = UDim2.new(0, 130, 1, 0)
            pos.BackgroundTransparency = 1
            pos.Text = string.format("%d, %d, %d", w.cframe.X, w.cframe.Y, w.cframe.Z)
            pos.TextColor3 = THEME.Dim
            pos.Font = Enum.Font.Code
            pos.TextSize = 11
            pos.TextXAlignment = Enum.TextXAlignment.Right
            pos.Parent = row
            Paint(pos, "TextColor3", "Dim")

            local go = CreateButton(row, "TP", "Accent", 24)
            go.Size = UDim2.new(0, 56, 0, 24)
            go.Position = UDim2.new(1, -138, 0.5, -12)
            go.MouseButton1Click:Connect(function()
                TeleportTo(w.cframe)
                Log("TP -> " .. w.name, "action")
            end)

            local del = CreateButton(row, "EXCLUIR", "Danger", 24)
            del.Size = UDim2.new(0, 68, 0, 24)
            del.Position = UDim2.new(1, -76, 0.5, -12)
            del.MouseButton1Click:Connect(function()
                for k, item in ipairs(State.Waypoints) do
                    if item == w then
                        table.remove(State.Waypoints, k)
                        break
                    end
                end
                Log("Waypoint removido: " .. w.name, "action")
                RenderWaypoints()
            end)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        local r = Root()
        if not r then
            Toast("Sem personagem", "warn")
            return
        end
        local name = wpInput.Text
        if name == "" then name = "Waypoint " .. (#State.Waypoints + 1) end
        table.insert(State.Waypoints, { name = name, cframe = r.CFrame })
        wpInput.Text = ""
        Log("Waypoint salvo: " .. name, "action")
        Toast("Waypoint salvo", "ok", 1.5)
        RenderWaypoints()
    end)

    clearBtn.MouseButton1Click:Connect(function()
        if #State.Waypoints == 0 then return end
        Confirm("Apagar todos os " .. #State.Waypoints .. " waypoints?", function()
            State.Waypoints = {}
            Log("Waypoints limpos", "action")
            RenderWaypoints()
        end)
    end)

    RenderWaypoints()
end
