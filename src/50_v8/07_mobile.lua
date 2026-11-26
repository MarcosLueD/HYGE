--------------------------------------------------------------------------------
-- v8.2 — CELULAR (botões na tela + janela que cabe)
-- * Botões na tela (SET.TouchHud; padrão: ligado em aparelho com toque):
--   FLY liga/desliga o voo; com ele ligado aparecem SUBIR, DESCER e 2x.
--   A direção do voo vem do analógico do Roblox (o ControlModule, o mesmo que
--   anda com o personagem) e segue a câmera: olhando para cima, sobe. Vale
--   também para controle (gamepad) no PC. O Fly chama M.FlyDir só quando
--   nenhuma tecla de movimento está apertada.
-- * Tela pequena (celular deitado): a janela do dock fica mais baixa para
--   caber acima do dock (o conteúdo rola) e o dock encolhe se não couber na
--   largura. Recalcula quando a tela muda (girar o aparelho).
-- Entra depois do dock e do shell no build. Tudo em V8.Mobile: zero locais
-- novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Mobile = { up = false, down = false, boost = false }
        local M = V8.Mobile
        M.Touch = UserInputService.TouchEnabled
        if SET.TouchHud == nil then SET.TouchHud = M.Touch end

        ----------------------------------------------------------------------------
        -- direção do voo
        ----------------------------------------------------------------------------
        local controls   -- nil = ainda não tentou; false = não deu
        local function Controls()
            if controls == nil then
                controls = false
                pcall(function()
                    local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
                    local pm = ps and ps:FindFirstChild("PlayerModule")
                    if pm then controls = require(pm):GetControls() or false end
                end)
            end
            return controls or nil
        end

        M.FlyDir = function(cam)
            local dir = Vector3.zero
            local mv
            local c = Controls()
            if c then pcall(function() mv = c:GetMoveVector() end) end
            if typeof(mv) == "Vector3" and mv.Magnitude > 0.05 then
                -- relativo à câmera: x = direita, -z = frente
                dir = cam.LookVector * (-mv.Z) + cam.RightVector * mv.X
            else
                -- sem ControlModule: a direção que o Roblox calcula (sem subir/descer)
                local h = Hum()
                local md = h and h.MoveDirection
                if md and md.Magnitude > 0.05 then dir = md end
            end
            if M.up then dir = dir + Vector3.yAxis end
            if M.down then dir = dir - Vector3.yAxis end
            return dir
        end

        ----------------------------------------------------------------------------
        -- botões na tela (coluna no lado direito, acima do pulo do Roblox)
        ----------------------------------------------------------------------------
        local hud = Instance.new("Frame")
        hud.Name = "TouchHud"
        hud.AnchorPoint = Vector2.new(1, 0.5)
        hud.Position = UDim2.new(1, -18, 0.4, 0)
        hud.Size = UDim2.new(0, 62, 0, 0)
        hud.AutomaticSize = Enum.AutomaticSize.Y
        hud.BackgroundTransparency = 1
        hud.Visible = false
        hud.ZIndex = 30
        hud.Parent = Gui
        do
            local l = Instance.new("UIListLayout", hud)
            l.Padding = UDim.new(0, 8)
            l.HorizontalAlignment = Enum.HorizontalAlignment.Center
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        M.Hud = hud

        local function Btn(text, order, size)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, size, 0, size)
            b.BackgroundColor3 = THEME.Card
            b.BackgroundTransparency = 0.12
            b.Text = text
            b.TextColor3 = THEME.Text
            b.Font = Enum.Font.GothamBlack
            b.TextSize = 12
            b.AutoButtonColor = false
            b.LayoutOrder = order
            b.ZIndex = 30
            b.Parent = hud
            Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke", b)
            st.Transparency = 0.25
            st.Thickness = 1.5
            Paint(st, "Color", "Line")
            return b
        end
        local bFly = Btn("FLY", 1, 62)
        local bUp = Btn("SUBIR", 2, 56)
        local bDown = Btn("DESCER", 3, 56)
        local bBoost = Btn("2x", 4, 46)

        -- segurar: guarda o InputObject do dedo (o analógico é outro dedo e não
        -- solta o botão); soltar fora do botão também solta
        local held = {}
        local function Paint4()
            local fly = IsOn("fly")
            bFly.BackgroundColor3 = fly and THEME.Accent or THEME.Card
            bFly.TextColor3 = fly and THEME.Main or THEME.Text
            bUp.Visible, bDown.Visible, bBoost.Visible = fly, fly, fly
            bUp.BackgroundColor3 = M.up and THEME.Accent or THEME.Card
            bUp.TextColor3 = M.up and THEME.Main or THEME.Text
            bDown.BackgroundColor3 = M.down and THEME.Accent or THEME.Card
            bDown.TextColor3 = M.down and THEME.Main or THEME.Text
            bBoost.BackgroundColor3 = M.boost and THEME.Accent or THEME.Card
            bBoost.TextColor3 = M.boost and THEME.Main or THEME.Text
        end
        local function Press(input)
            local t = input.UserInputType
            return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
        end
        local function Hold(b, key)
            b.InputBegan:Connect(function(input)
                if not Press(input) then return end
                held[key] = input
                M[key] = true
                Paint4()
            end)
        end
        Hold(bUp, "up")
        Hold(bDown, "down")
        Conn.TouchHudEnd = UserInputService.InputEnded:Connect(function(input)
            if not Press(input) then return end
            for key, obj in pairs(held) do
                if obj == input or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    held[key] = nil
                    M[key] = false
                end
            end
            Paint4()
        end)

        bFly.MouseButton1Click:Connect(function() Flip("fly") end)
        bBoost.MouseButton1Click:Connect(function()
            M.boost = not M.boost
            Paint4()
        end)

        table.insert(Toggles.fly.listeners, function(on)
            if not on then
                M.up, M.down = false, false
                for k in pairs(held) do held[k] = nil end
            end
            Paint4()
        end)

        M.Render = function()
            hud.Visible = SET.TouchHud == true
            Paint4()
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, M.Render)

        ----------------------------------------------------------------------------
        -- janela e dock que cabem na tela
        ----------------------------------------------------------------------------
        local dockScale
        if V8.Dock and V8.Dock.Bar then
            dockScale = Instance.new("UIScale")
            dockScale.Parent = V8.Dock.Bar()
        end

        M.Fit = function()
            local vp = Gui.AbsoluteSize
            if vp.X < 100 or vp.Y < 100 then vp = Camera.ViewportSize end
            if vp.X < 100 or vp.Y < 100 then return end
            -- dock: encolhe (até 60%) se for mais largo que a tela
            if dockScale then
                local bar = V8.Dock.Bar()
                local w = bar.AbsoluteSize.X / math.max(dockScale.Scale, 0.01)
                local s = 1
                if w > 0 and w > vp.X - 24 then s = math.max(0.6, (vp.X - 24) / w) end
                dockScale.Scale = s
            end
            -- janela do dock: a altura que cabe acima dele (300 a 520)
            local H = V8.Shell
            if not H then return end
            local sc = CONFIG.UiScale or 1
            -- dock + alça + respiro (o mesmo do HomePos) + margem
            local reserve = (V8.Dock and V8.Dock.Reserve) and V8.Dock.Reserve() or 82
            local room = vp.Y - reserve - 12
            local newH = math.clamp(math.floor(room / sc), 300, 520)
            if newH ~= H.DockH then
                H.DockH = newH
                pcall(H.Layout)
                if SET.WinPos == nil then pcall(function() Window.Position = H.HomePos() end) end
            end
        end

        Conn.MobileFit = Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(function() pcall(M.Fit) end)
        end)

        ----------------------------------------------------------------------------
        -- Ajustes › Celular e toque
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "CELULAR E TOQUE", 12)
        SubLabel(card, "Este aparelho " .. (M.Touch and "tem" or "não tem") .. " tela de toque. "
            .. "No celular, o analógico dirige o voo seguindo a câmera; SUBIR e DESCER "
            .. "aparecem com o Fly ligado. A janela encolhe sozinha em tela pequena.", -1)
        CheckRow(card, "Botões na tela",
            "FLY, SUBIR, DESCER e 2x no lado direito da tela",
            function() return SET.TouchHud == true end,
            function(v)
                SET.TouchHud = v and true or false
                M.Render()
            end, 1)

        M.Render()
    end
    Build()
end
