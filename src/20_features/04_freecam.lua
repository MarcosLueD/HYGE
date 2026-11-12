-- FREECAM --------------------------------------------------------------------
-- v8.0: refeito.
--   * yaw/pitch guardados separados (antes girava em cima do CFrame acumulado
--     e a câmera "rolava" de lado com o tempo)
--   * o personagem não anda junto (controles desligados pelo PlayerModule)
--   * painel aberto = mouse livre para clicar na UI (igual ao drone)
--   * scroll muda a velocidade; digitando, a câmera não se mexe
local camBackup = {}
DefineToggle({
    id = "freecam", label = "Freecam",
    desc = "Câmera livre (WASD + E/Q, scroll = velocidade)",
    enable = function()
        camBackup.type = Camera.CameraType
        camBackup.subject = Camera.CameraSubject
        Camera.CameraType = Enum.CameraType.Scriptable

        -- trava os controles do personagem (se o jogo usar o PlayerModule padrão)
        camBackup.controls = nil
        pcall(function()
            local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then
                local controls = require(pm):GetControls()
                controls:Disable()
                camBackup.controls = controls
            end
        end)

        local pos = Camera.CFrame.Position
        local look = Camera.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        local pitch = math.asin(math.clamp(look.Y, -1, 1))
        State.FreecamSpeed = State.FreecamSpeed or 60

        Conn.FreecamScroll = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel and not Window.Visible then
                State.FreecamSpeed = math.clamp(State.FreecamSpeed + input.Position.Z * 8, 5, 400)
            end
        end)

        Conn.Freecam = RunService.RenderStepped:Connect(function(dt)
            local uiOpen = Window.Visible
            UserInputService.MouseBehavior = uiOpen
                and Enum.MouseBehavior.Default
                or Enum.MouseBehavior.LockCenter

            if not uiOpen then
                local d = UserInputService:GetMouseDelta()
                yaw = yaw - math.rad(d.X * 0.25)
                pitch = math.clamp(pitch - math.rad(d.Y * 0.25), -1.45, 1.45)
            end
            local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

            local move = Vector3.zero
            if not V8.Typing() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.yAxis end
            end
            local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1
            if move.Magnitude > 0 then
                pos = pos + move.Unit * State.FreecamSpeed * mult * dt
            end
            Camera.CFrame = CFrame.new(pos) * rot
        end)
    end,
    disable = function()
        Drop("Freecam")
        Drop("FreecamScroll")
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if camBackup.controls then
            pcall(function() camBackup.controls:Enable() end)
            camBackup.controls = nil
        end
        Camera.CameraType = camBackup.type or Enum.CameraType.Custom
        Camera.CameraSubject = camBackup.subject or Hum()
    end,
})

