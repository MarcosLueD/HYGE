-- ESP ------------------------------------------------------------------------
local EspGui = Instance.new("Frame")
EspGui.Name = "EspLayer"
EspGui.Size = UDim2.new(1, 0, 1, 0)
EspGui.BackgroundTransparency = 1
EspGui.Visible = false
EspGui.Parent = Gui

local EspOpts = {
    Highlight  = true,
    Name       = true,
    UseDisplay = true,   -- DisplayName em vez de @username
    Distance   = true,
    Health     = true,
    HealthBar  = true,
    Tracers    = false,
    Allies     = true,   -- mesma equipe
    Enemies    = true,   -- equipe diferente
    MaxDist    = 1000,
    Rate       = 0.066,  -- segundos entre atualizações (15Hz)
    ColorKey   = "Accent",
    AllyKey    = "Success",
    TeamColors = false,  -- pinta pela cor da equipe
}

local function RemoveEsp(userId)
    local e = Esp[userId]
    if not e then return end
    if e.highlight then e.highlight:Destroy() end
    if e.billboard then e.billboard:Destroy() end
    if e.tracer then e.tracer:Destroy() end
    Esp[userId] = nil
end

local function ClearEsp()
    for id in pairs(Esp) do RemoveEsp(id) end
    Esp = {}
end

local function IsAlly(player)
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function EspColorFor(player)
    if EspOpts.TeamColors and player.Team then
        return player.TeamColor.Color
    end
    if IsAlly(player) then return THEME[EspOpts.AllyKey] or THEME.Success end
    return THEME[EspOpts.ColorKey] or THEME.Accent
end

local function BuildEsp(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    RemoveEsp(player.UserId)

    local hl = Instance.new("Highlight")
    hl.Name = "HYGE_ESP"
    hl.Adornee = char
    hl.FillTransparency = 0.85
    hl.OutlineTransparency = 0
    hl.FillColor = THEME.Accent
    hl.OutlineColor = THEME.Accent
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    local entry = { highlight = hl }

    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "HYGE_ESP_Tag"
        bb.Adornee = head
        bb.Size = UDim2.new(0, 150, 0, 46)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, 0, 0, 16)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.DisplayName
        nameLbl.TextColor3 = THEME.Accent
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextStrokeTransparency = 0.35
        nameLbl.Parent = bb

        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, 0, 0, 14)
        distLbl.Position = UDim2.new(0, 0, 0, 16)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = ""
        distLbl.TextColor3 = THEME.Accent2
        distLbl.Font = Enum.Font.Code
        distLbl.TextSize = 11
        distLbl.TextStrokeTransparency = 0.4
        distLbl.Parent = bb

        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0, 70, 0, 4)
        hpBg.Position = UDim2.new(0.5, -35, 0, 34)
        hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = bb
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = THEME.Success
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

        entry.billboard = bb
        entry.name = nameLbl
        entry.dist = distLbl
        entry.hpBg = hpBg
        entry.hpFill = hpFill
    end

    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 2, 0, 0)
    tracer.ZIndex = 0
    tracer.BackgroundColor3 = THEME.Accent
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.Parent = EspGui
    entry.tracer = tracer

    Esp[player.UserId] = entry
end

-- Converte um ponto do mundo para o espaço de tela DA GUI.
-- WorldToViewportPoint devolve coordenadas da viewport 3D, que começa ABAIXO da
-- topbar do Roblox. Como o painel usa IgnoreGuiInset = true, o (0,0) da GUI é o
-- topo real da tela: sem somar o inset a linha fica ~36px fora de lugar.
local espInsetY = 0
pcall(function()
    if Gui.IgnoreGuiInset then espInsetY = GuiService:GetGuiInset().Y end
end)

-- Desenha uma linha entre dois pontos de tela reaproveitando o Frame já criado.
-- Rotation no Roblox pivota no CENTRO do objeto (não no AnchorPoint), por isso a
-- barra é posicionada no PONTO MÉDIO do segmento com AnchorPoint (0.5, 0.5).
local function DrawLine(frame, x1, y1, x2, y2, color, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 2 then
        frame.Visible = false
        return
    end
    frame.Size = UDim2.new(0, thickness or 2, 0, len)
    frame.Position = UDim2.new(0, (x1 + x2) * 0.5, 0, (y1 + y2) * 0.5)
    -- barra nasce apontando para +Y (90° do eixo X): R = ângulo do vetor - 90
    frame.Rotation = math.deg(math.atan2(dy, dx)) - 90
    frame.BackgroundColor3 = color
    frame.Visible = true
end

-- Só a geometria das linhas. Roda a cada frame (barato: nada é criado aqui).
local function UpdateTracers()
    local screen = EspGui.AbsoluteSize
    if screen.X < 2 then screen = Camera.ViewportSize end
    local originX, originY = screen.X * 0.5, screen.Y

    for _, e in pairs(Esp) do
        local tracer = e.tracer
        if tracer then
            local root = e.root
            if not (EspOpts.Tracers and e.show and root and root.Parent) then
                tracer.Visible = false
            else
                local pos, _ = Camera:WorldToViewportPoint(root.Position)
                -- pos.Z > 0 = está na frente da câmera. Usar 'onScreen' aqui fazia
                -- a linha sumir sempre que o alvo saía das bordas da tela.
                if pos.Z > 0 then
                    DrawLine(tracer, originX, originY,
                        pos.X, pos.Y + espInsetY, e.col or THEME.Accent, 2)
                else
                    tracer.Visible = false
                end
            end
        end
    end
end

-- Atualiza o ESP reaproveitando os objetos já criados por BuildEsp.
-- Nada é recriado por frame: fora do filtro os objetos só ficam desligados.
local function UpdateEsp()
    local myRoot = Root()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local e = Esp[p.UserId]
            local char = p.Character
            if char and (not e or not e.highlight or not e.highlight.Parent) then
                BuildEsp(p)
                e = Esp[p.UserId]
            end

            if e and char then
                local root = char:FindFirstChild("HumanoidRootPart")
                    or char.PrimaryPart or char:FindFirstChild("Torso")
                    or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
                local h = char:FindFirstChildOfClass("Humanoid")

                -- guardado para o loop de tracers (que roda em outra taxa)
                e.root = root

                -- distância (usada no filtro e no texto)
                local dist
                if myRoot and root then
                    dist = (myRoot.Position - root.Position).Magnitude
                end

                -- filtros: equipe e distância
                local ally = IsAlly(p)
                local show = ally and EspOpts.Allies or ((not ally) and EspOpts.Enemies)
                if show and dist and EspOpts.MaxDist > 0 and dist > EspOpts.MaxDist then
                    show = false
                end
                if show and h and h.Health <= 0 then show = false end
                e.show = show

                if not show then
                    if e.highlight then e.highlight.Enabled = false end
                    if e.billboard then e.billboard.Enabled = false end
                    if e.tracer then e.tracer.Visible = false end
                else
                    local col = EspColorFor(p)
                    e.col = col

                    if e.highlight then
                        e.highlight.Enabled = EspOpts.Highlight
                        e.highlight.FillColor = col
                        e.highlight.OutlineColor = col
                    end

                    local anyTag = EspOpts.Name or EspOpts.Distance
                        or EspOpts.Health or EspOpts.HealthBar
                    if e.billboard then e.billboard.Enabled = anyTag end

                    if e.name then
                        e.name.Visible = EspOpts.Name
                        if EspOpts.Name then
                            e.name.Text = EspOpts.UseDisplay and p.DisplayName
                                or ("@" .. p.Name)
                            e.name.TextColor3 = col
                        end
                    end

                    if e.dist then
                        local wantsInfo = EspOpts.Distance or EspOpts.Health
                        e.dist.Visible = wantsInfo
                        if wantsInfo then
                            local parts = {}
                            if EspOpts.Distance and dist then
                                table.insert(parts, math.floor(dist) .. "m")
                            end
                            if EspOpts.Health and h then
                                table.insert(parts, math.floor(h.Health) .. " HP")
                            end
                            e.dist.Text = table.concat(parts, "  |  ")
                        end
                    end

                    if e.hpBg then
                        e.hpBg.Visible = EspOpts.HealthBar
                        if EspOpts.HealthBar and h and h.MaxHealth > 0 and e.hpFill then
                            local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
                            e.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                            e.hpFill.BackgroundColor3 = pct > 0.5 and THEME.Success
                                or (pct > 0.25 and THEME.Warning or THEME.Danger)
                        end
                    end
                end
            elseif e then
                e.show = false
                e.root = nil
                if e.tracer then e.tracer.Visible = false end
            end
        end
    end

    -- tracers acompanham a câmera imediatamente ao aplicar o filtro
    if EspOpts.Tracers then pcall(UpdateTracers) end
end

DefineToggle({
    id = "esp", label = "ESP", desc = "Contorno, nome, distância, vida e tracers",
    enable = function()
        EspGui.Visible = true
        for _, p in ipairs(Players:GetPlayers()) do BuildEsp(p) end
        local acc = 0
        Conn.Esp = RunService.RenderStepped:Connect(function(dt)
            -- pesado (filtros, textos, vida): na taxa configurada, 15Hz por padrão
            acc = acc + dt
            if acc >= (EspOpts.Rate or 0.066) then
                acc = 0
                local ok, err = pcall(UpdateEsp)
                if not ok then Log("ESP: " .. tostring(err), "error") end
            -- leve (só posição/rotação das linhas): todo frame, sem criar nada
            elseif EspOpts.Tracers then
                local ok, err = pcall(UpdateTracers)
                if not ok then Log("ESP tracer: " .. tostring(err), "error") end
            end
        end)
    end,
    disable = function()
        Drop("Esp")
        ClearEsp()
        EspGui.Visible = false
    end,
})

