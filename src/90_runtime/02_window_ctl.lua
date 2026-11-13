--------------------------------------------------------------------------------
-- ORB FLUTUANTE
--------------------------------------------------------------------------------
do
    Orb = Instance.new("TextButton")
    Orb.Name = "Orb"
    Orb.Size = UDim2.new(0, 46, 0, 46)
    Orb.Position = UDim2.new(0, 18, 0.5, -23)
    Orb.BackgroundColor3 = THEME.Accent
    Orb.Text = "H"
    Orb.TextColor3 = Color3.new(0, 0, 0)
    Orb.Font = Enum.Font.GothamBlack
    Orb.TextSize = 20
    Orb.AutoButtonColor = false
    Orb.Visible = false
    Orb.Parent = Gui
    if CONFIG.LogoId ~= "" then
        Orb.Text = ""
        local orbImg = Instance.new("ImageLabel")
        orbImg.Size = UDim2.new(1, -6, 1, -6)
        orbImg.Position = UDim2.new(0, 3, 0, 3)
        orbImg.BackgroundTransparency = 1
        orbImg.Image = CONFIG.LogoId
        orbImg.ScaleType = Enum.ScaleType.Fit
        orbImg.Parent = Orb
    end
    Paint(Orb, "BackgroundColor3", "Accent")
    Instance.new("UICorner", Orb).CornerRadius = UDim.new(1, 0)
    V8.Orb = Orb   -- o dock (que carrega antes) esconde/mostra a bolinha
end

--------------------------------------------------------------------------------
-- ABRIR / FECHAR / MINIMIZAR
--------------------------------------------------------------------------------
do
    isOpen = false

    SetOpen = function(open)
        isOpen = open
        if open then
            Window.Visible = true
            if SET.Animations then
                WindowScale.Scale = CONFIG.UiScale * 0.92
                TweenService:Create(WindowScale, TweenInfo.new(0.18, Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out), { Scale = CONFIG.UiScale }):Play()
            else
                WindowScale.Scale = CONFIG.UiScale
            end
            Orb.Visible = false
            RefreshStatus()
            if TabHooks[State.ActiveTab] then pcall(TabHooks[State.ActiveTab]) end
            if V8.Dock and V8.Dock.Sync then pcall(V8.Dock.Sync, State.ActiveTab) end
        else
            if SET.Animations then
                local t = TweenService:Create(WindowScale, TweenInfo.new(0.14),
                    { Scale = CONFIG.UiScale * 0.9 })
                t:Play()
                t.Completed:Connect(function()
                    if not isOpen then Window.Visible = false end
                    WindowScale.Scale = CONFIG.UiScale
                end)
            else
                Window.Visible = false
            end
            -- v8.0: com o dock na tela a bolinha não é necessária
            Orb.Visible = (SET.Dock ~= true)
            if V8.Dock and V8.Dock.Sync then pcall(V8.Dock.Sync, State.ActiveTab) end
        end
    end

    -- v8.0: o dock carrega antes deste bloco e não enxerga os locais daqui
    V8.SetOpen = function(open) SetOpen(open) end
    V8.IsOpen = function() return isOpen end

    SetMinimized = function(min)
        State.Minimized = min
        Content.Visible = not min
        MinBtn.Text = min and "+" or "—"

        -- v8: as medidas vem do shell (nao ficam mais chumbadas aqui) e a
        -- sidebar so reaparece se ela for o modo de navegacao escolhido
        -- (o dock fica na tela e o console mora na aba Scripts: nenhum dos dois
        -- é escondido aqui — o Content inteiro some quando minimiza)
        if V8.Shell and V8.Shell.Layout then
            Sidebar.Visible = (not min) and (SET.Dock ~= true)
            pcall(V8.Shell.Layout)
            Anim(Window, 0.18, { Size = min
                and UDim2.new(0, V8.Shell.W, 0, V8.Shell.TopH)
                or  UDim2.new(0, V8.Shell.W, 0, V8.Shell.Hgt) })
            return
        end

        Sidebar.Visible = not min
        ConsoleFrame.Visible = not min
        Anim(Window, 0.18, {
            Size = min and UDim2.new(0, 920, 0, 56) or UDim2.new(0, 920, 0, 600) })
    end

    CloseBtn.MouseButton1Click:Connect(function() SetOpen(false) end)
    MinBtn.MouseButton1Click:Connect(function() SetMinimized(not State.Minimized) end)
    Orb.MouseButton1Click:Connect(function() SetOpen(true) end)
end

--------------------------------------------------------------------------------
-- DRAG (mouse + touch) da janela e do orb
--------------------------------------------------------------------------------
do
    ----------------------------------------------------------------------------
    -- v8.0: janela sempre alcançável + posição vai para a config (SET.WinPos)
    ----------------------------------------------------------------------------
    local KEEP_X, KEEP_Y = 120, 40   -- quanto da TopBar sempre fica na tela
    V8.Win = {}

    -- empurra a janela de volta se ela estiver (mesmo que parcialmente) perdida
    V8.Win.Clamp = function()
        local vp, p, s = Gui.AbsoluteSize, Window.AbsolutePosition, Window.AbsoluteSize
        if vp.X <= KEEP_X * 2 or vp.Y <= KEEP_Y * 2 then return end
        local nx = math.clamp(p.X, KEEP_X - s.X, vp.X - KEEP_X)
        local ny = math.clamp(p.Y, 0, vp.Y - KEEP_Y)
        if nx ~= p.X or ny ~= p.Y then
            local cur = Window.Position
            Window.Position = UDim2.new(cur.X.Scale, cur.X.Offset + (nx - p.X),
                cur.Y.Scale, cur.Y.Offset + (ny - p.Y))
        end
    end

    V8.Win.Save = function()
        local p = Window.Position
        SET.WinPos = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
    end

    V8.Win.Restore = function(t)
        if type(t) ~= "table" then return end
        for i = 1, 4 do
            if type(t[i]) ~= "number" or t[i] ~= t[i] then return end   -- NaN/lixo
        end
        Window.Position = UDim2.new(t[1], t[2], t[3], t[4])
        task.defer(function() pcall(V8.Win.Clamp) end)   -- Absolute* só no próximo frame
    end

    V8.Win.Center = function()
        if V8.Shell and V8.Shell.HomePos then
            Window.Position = V8.Shell.HomePos()   -- com dock: logo acima dele
        else
            local w, h = Window.Size.X.Offset, Window.Size.Y.Offset
            Window.Position = UDim2.new(0.5, -w * 0.5, 0.5, -h * 0.5)
        end
        task.defer(function() pcall(V8.Win.Clamp) end)
        SET.WinPos = nil
        Log("Janela centralizada", "action")
    end

    -- resolução mudou (janela redimensionada, celular girou): reencaixa
    Conn.WinFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        pcall(V8.Win.Clamp)
    end)

    local dragging, dragStart, startPos, startAbs = false, nil, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            startAbs = Window.AbsolutePosition
        end
    end)
    Conn.Drag = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y
        -- conta feita na posição absoluta do início do arrasto (estável), não
        -- na AbsolutePosition atual (que só atualiza no próximo frame)
        local vp, size = Gui.AbsoluteSize, Window.AbsoluteSize
        if vp.X > KEEP_X * 2 and vp.Y > KEEP_Y * 2 then
            dx = math.clamp(startAbs.X + dx, KEEP_X - size.X, vp.X - KEEP_X) - startAbs.X
            dy = math.clamp(startAbs.Y + dy, 0, vp.Y - KEEP_Y) - startAbs.Y
        end
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx,
            startPos.Y.Scale, startPos.Y.Offset + dy)
    end)
    Conn.DragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then pcall(V8.Win.Save) end
            dragging = false
        end
    end)

    local orbDrag, orbStart, orbPos = false, nil, nil
    Orb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            orbDrag = true
            orbStart = input.Position
            orbPos = Orb.Position
        end
    end)
    Conn.OrbDrag = UserInputService.InputChanged:Connect(function(input)
        if not orbDrag then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - orbStart
        if delta.Magnitude < 4 then return end
        Orb.Position = UDim2.new(orbPos.X.Scale, orbPos.X.Offset + delta.X,
            orbPos.Y.Scale, orbPos.Y.Offset + delta.Y)
    end)
    Conn.OrbDragEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            orbDrag = false
        end
    end)
end

