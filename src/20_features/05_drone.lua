-- DRONE ----------------------------------------------------------------------
-- Câmera livre estilo drone: o personagem fica 100% travado no lugar (ancorado),
-- a câmera voa com inércia suave. Scroll muda a velocidade, Shift acelera,
-- Ctrl freia. Com o painel aberto o mouse volta a funcionar pra clicar na UI.
local droneBackup = { anchored = {}, ws = 16, jp = 50, autorotate = true }
DefineToggle({
    id = "drone", label = "Modo Drone", desc = "Câmera voa, personagem fica parado (WASD + E/Q, scroll = velocidade)",
    enable = function()
        local char = Char()
        if not char then error("personagem não carregado") end

        -- congela o personagem
        droneBackup.anchored = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                droneBackup.anchored[part] = part.Anchored
                part.Anchored = true
            end
        end
        local h = Hum()
        if h then
            droneBackup.ws = h.WalkSpeed
            droneBackup.jp = h.JumpPower
            droneBackup.autorotate = h.AutoRotate
            h.WalkSpeed = 0
            h.JumpPower = 0
            h.AutoRotate = false
            h:ChangeState(Enum.HumanoidStateType.Physics)
        end

        -- câmera
        droneBackup.type = Camera.CameraType
        droneBackup.subject = Camera.CameraSubject
        droneBackup.fov = Camera.FieldOfView
        Camera.CameraType = Enum.CameraType.Scriptable
        if DroneHUD.Show then pcall(DroneHUD.Show) end

        local pos = Camera.CFrame.Position
        local look = Camera.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        local pitch = math.asin(math.clamp(look.Y, -1, 1))
        local vel = Vector3.zero

        Conn.DroneScroll = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel and not Window.Visible then
                State.DroneSpeed = math.clamp(State.DroneSpeed + input.Position.Z * 8, 5, 400)
                if DroneSpeedSlider then DroneSpeedSlider(State.DroneSpeed) end
            end
        end)

        Conn.Drone = RunService.RenderStepped:Connect(function(dt)
            local uiOpen = Window.Visible
            UserInputService.MouseBehavior = uiOpen
                and Enum.MouseBehavior.Default
                or Enum.MouseBehavior.LockCenter

            if not uiOpen then
                local d = UserInputService:GetMouseDelta()
                yaw = yaw - d.X * State.DroneSens * 0.003
                pitch = math.clamp(pitch - d.Y * State.DroneSens * 0.003, -1.45, 1.45)
            end

            local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

            local dir = Vector3.zero
            if not uiOpen and not V8.Typing() then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.yAxis end
            end

            local mult = 1
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mult = 3 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mult = 0.25 end

            local target = Vector3.zero
            if dir.Magnitude > 0 then
                target = dir.Unit * State.DroneSpeed * mult
            end
            -- inércia (quanto menor o Smooth, mais "pesado" o drone)
            local a = math.clamp(dt * (State.DroneSmooth or 8), 0, 1)
            vel = vel:Lerp(target, a)
            pos = pos + vel * dt

            Camera.CFrame = CFrame.new(pos) * rot
            Camera.FieldOfView = droneBackup.fov + math.clamp(vel.Magnitude * 0.08, 0, 20)
            if DroneHUD.Update then pcall(DroneHUD.Update, dt, pos, vel, yaw, pitch) end
        end)
    end,
    disable = function()
        Drop("Drone")
        Drop("DroneScroll")
        if DroneHUD.Hide then pcall(DroneHUD.Hide) end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default

        for part, was in pairs(droneBackup.anchored) do
            if part and part.Parent then part.Anchored = was end
        end
        droneBackup.anchored = {}

        local h = Hum()
        if h then
            h.WalkSpeed = State.WalkSpeed or droneBackup.ws
            h.JumpPower = droneBackup.jp
            h.AutoRotate = droneBackup.autorotate
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Camera.FieldOfView = droneBackup.fov or 70
        Camera.CameraType = droneBackup.type or Enum.CameraType.Custom
        Camera.CameraSubject = droneBackup.subject or Hum()
    end,
})

