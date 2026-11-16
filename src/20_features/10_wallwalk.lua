--------------------------------------------------------------------------------
-- v8.1 — WALK ON WALLS (seção Troll)
--
-- O Humanoid só sabe andar com o "para cima" do mundo, então aqui o painel
-- assume o controle do personagem (PlatformStand, igual ao Fly) e cuida da
-- "gravidade" sozinho:
--   * um raio para baixo (no "para cima" atual) acha a superfície e prende os
--     pés nela; superfície curva vai virando o corpo aos poucos
--   * andando contra uma parede, ela vira o chão (sobe a parede, anda no teto)
--   * passando de uma quina, um raio "dobra" a borda e continua do outro lado
--   * sem nada embaixo por ~1,2 s, volta para a gravidade normal
-- WASD anda (relativo à câmera), Space pula para fora da superfície. Usa a
-- WalkSpeed/JumpPower dos sliders e a gravidade atual (Anti-Gravidade vale).
-- Quem está em volta vê você na parede: o personagem é seu, a posição replica.
--
-- Liga junto com Fly/Drone/Freecam não dá (todos mandam no personagem): ligar
-- um deles desliga este. No respawn ele sempre desliga.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        local W = { up = Vector3.yAxis, fall = 0, air = 0 }
        V8.WallWalk = W

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        local function Proj(v, n) return v - n * v:Dot(n) end

        -- distância do centro do HumanoidRootPart até a sola do pé
        local function HipOffset(h, root)
            if h.RigType == Enum.HumanoidRigType.R15 then
                return h.HipHeight + root.Size.Y * 0.5
            end
            return root.Size.Y * 0.5 + 2   -- R6: perna fixa de 2 studs
        end

        -- animação de andar do próprio jogo (pasta Animate), se existir
        local function LoadWalk(h)
            local char = Char()
            local animate = char and char:FindFirstChild("Animate")
            local folder = animate and (animate:FindFirstChild("walk") or animate:FindFirstChild("run"))
            local anim = folder and folder:FindFirstChildOfClass("Animation")
            local animator = h:FindFirstChildOfClass("Animator")
            if not anim or not animator then return nil end
            local ok, tr = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok or not tr then return nil end
            pcall(function()
                tr.Looped = true
                tr.Priority = Enum.AnimationPriority.Movement
            end)
            return tr
        end

        local function Stop()
            Drop("WallWalk")
            if W.bv then pcall(function() W.bv:Destroy() end) W.bv = nil end
            if W.bg then pcall(function() W.bg:Destroy() end) W.bg = nil end
            if W.anim then
                pcall(function() W.anim:Stop(0.2) end)
                pcall(function() W.anim:Destroy() end)
                W.anim = nil
            end
            for part, cc in pairs(W.coll or {}) do
                if part.Parent then pcall(function() part.CanCollide = cc end) end
            end
            W.coll = nil
            local h, root = Hum(), Root()
            if h then h.PlatformStand = false end
            if root and W.up ~= Vector3.yAxis then
                -- volta em pé, olhando para o mesmo lado (no plano do chão)
                local look = Proj(root.CFrame.LookVector, Vector3.yAxis)
                if look.Magnitude < 0.1 then look = Proj(-W.up, Vector3.yAxis) end
                if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
                pcall(function()
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit)
                    root.AssemblyLinearVelocity = Vector3.zero
                end)
            end
            W.up = Vector3.yAxis
            W.fall, W.air = 0, 0
            W.rot = nil
        end

        local function Key(kc) return UserInputService:IsKeyDown(kc) end

        local function Step(dt)
            local root, h = Root(), Hum()
            if not root or not h or not W.bv or not W.bv.Parent then return end
            -- outro modo assumiu o personagem: sai de cena
            if IsOn("fly") or IsOn("drone") or IsOn("freecam") then
                SetToggle("wallwalk", false)
                return
            end
            dt = math.min(dt, 0.1)
            h.PlatformStand = true
            for part in pairs(W.coll) do
                if part.Parent and part.CanCollide then part.CanCollide = false end
            end

            local up = W.up
            local hip = HipOffset(h, root)
            local pos = root.Position

            -- direção pedida, relativa à câmera e projetada na superfície
            local cam = Camera.CFrame
            local fwd = Proj(cam.LookVector, up)
            if fwd.Magnitude < 0.25 then fwd = Proj(cam.UpVector, up) end
            if fwd.Magnitude < 1e-3 and W.facing then fwd = Proj(W.facing, up) end
            if fwd.Magnitude < 1e-3 then fwd = Proj(Vector3.new(0, 0, -1), up) end
            if fwd.Magnitude < 1e-3 then fwd = Proj(Vector3.xAxis, up) end
            fwd = fwd.Unit
            local right = fwd:Cross(up)
            local ix, iz = 0, 0
            if not V8.Typing() then
                if Key(Enum.KeyCode.W) then iz = iz + 1 end
                if Key(Enum.KeyCode.S) then iz = iz - 1 end
                if Key(Enum.KeyCode.D) then ix = ix + 1 end
                if Key(Enum.KeyCode.A) then ix = ix - 1 end
            end
            local move = fwd * iz + right * ix
            if move.Magnitude > 1e-3 then move = move.Unit else move = Vector3.zero end
            local moving = move.Magnitude > 0
            local speed = math.max(0, State.WalkSpeed or 16)

            -- 1) parede à frente vira o chão
            if moving then
                local reach = root.Size.Z * 0.5 + 1.6
                local hit = workspace:Raycast(pos, move * reach, params)
                if hit and hit.Normal:Dot(up) < 0.6 then
                    local old = up
                    up = hit.Normal
                    W.up = up
                    pos = hit.Position + up * hip
                    W.fall, W.air = 0, 0
                    local f = Proj(old, up)
                    if f.Magnitude > 1e-3 then W.facing = f.Unit end
                    move = Vector3.zero   -- o próximo quadro já anda no plano novo
                end
            end

            -- 2) chão no "para baixo" atual
            local ground = workspace:Raycast(pos, -up * (hip + 1.5), params)
            if ground and W.fall <= 0 then
                if ground.Normal:Dot(up) > 0.3 then
                    up = up:Lerp(ground.Normal, math.min(1, dt * 12)).Unit
                    W.up = up
                end
                pos = ground.Position + up * hip
                W.fall, W.air = 0, 0
                if not V8.Typing() and Key(Enum.KeyCode.Space) then
                    W.fall = math.max(30, State.JumpPower or 50)
                end
            else
                -- 3) passou da quina: procura a face do outro lado da borda
                local wrapped = false
                if not ground and moving and W.fall <= 0 then
                    local probe = pos - up * (hip + 0.8) + move * 0.8
                    local hit = workspace:Raycast(probe, -move * 3, params)
                    if hit and hit.Normal:Dot(up) < 0.6 then
                        local old = up
                        up = hit.Normal
                        W.up = up
                        pos = hit.Position + up * hip
                        local f = Proj(-old, up)
                        if f.Magnitude > 1e-3 then W.facing = f.Unit end
                        W.fall, W.air = 0, 0
                        move = Vector3.zero
                        wrapped = true
                    end
                end
                if not wrapped then
                    if not ground then W.air = W.air + dt end
                    W.fall = math.max(W.fall - workspace.Gravity * dt, -150)
                    if W.air > 1.2 and up ~= Vector3.yAxis then
                        -- soltou da parede/teto: gravidade normal de novo
                        up = Vector3.yAxis
                        W.up = up
                        W.fall = math.min(W.fall, 0)
                    end
                end
            end

            local vel = move * speed + up * W.fall
            pos = pos + vel * dt

            -- frente do corpo: para onde anda (ou a última), sempre no plano
            if moving and move.Magnitude > 0 then W.facing = move end
            local face = Proj(W.facing or fwd, up)
            if face.Magnitude < 1e-3 then face = fwd end
            face = face.Unit
            local back = -face
            local target = CFrame.fromMatrix(Vector3.zero, up:Cross(back), up, back)
            W.rot = W.rot and W.rot:Lerp(target, math.min(1, dt * 14)) or target

            local cf = CFrame.new(pos) * W.rot
            root.CFrame = cf
            root.AssemblyAngularVelocity = Vector3.zero
            W.bv.Velocity = vel
            if W.bg then W.bg.CFrame = cf end

            -- anda com a animação de andar do jogo (parado = sem animação)
            if W.anim then
                local walking = moving and speed > 0
                if walking and not W.anim.IsPlaying then
                    pcall(function() W.anim:Play(0.15) end)
                elseif not walking and W.anim.IsPlaying then
                    pcall(function() W.anim:Stop(0.2) end)
                end
                if walking then pcall(function() W.anim:AdjustSpeed(speed / 16) end) end
            end
        end

        local function Start()
            local root, h, char = Root(), Hum(), Char()
            if not root or not h or not char then error("sem personagem") end
            for _, id in ipairs({ "fly", "drone", "freecam" }) do
                if IsOn(id) then SetToggle(id, false, true) end
            end
            Stop()
            params.FilterDescendantsInstances = { char }
            W.up = Vector3.yAxis
            W.fall, W.air = 0, 0
            W.facing = Proj(root.CFrame.LookVector, Vector3.yAxis)
            if W.facing.Magnitude < 1e-3 then W.facing = Vector3.new(0, 0, -1) end
            W.facing = W.facing.Unit

            -- colisão do corpo desligada: quem prende na superfície é o raio
            W.coll = {}
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    W.coll[p] = p.CanCollide
                    p.CanCollide = false
                end
            end

            -- BodyVelocity anula a gravidade do motor; BodyGyro segura a rotação
            local bv = Instance.new("BodyVelocity")
            bv.Name = "HYGE_WallWalk"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            W.bv = bv

            local bg = Instance.new("BodyGyro")
            bg.Name = "HYGE_WallGyro"
            bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bg.P = 30000
            bg.D = 500
            bg.CFrame = root.CFrame
            bg.Parent = root
            W.bg = bg

            W.anim = LoadWalk(h)
            Conn.WallWalk = RunService.RenderStepped:Connect(function(dt)
                local ok, err = pcall(Step, dt)
                if not ok then
                    Log("Walk on Walls: " .. tostring(err), "error")
                    SetToggle("wallwalk", false)
                end
            end)
        end

        DefineToggle({
            id = "wallwalk", label = "Walk on Walls",
            desc = "Anda em paredes e tetos (WASD; Space pula)",
            enable = Start, disable = Stop,
        })

        -- o personagem novo não tem as peças de controle: desliga e avisa
        Conn.WallRespawn = LocalPlayer.CharacterAdded:Connect(function()
            if IsOn("wallwalk") then
                SetToggle("wallwalk", false, true)
                Log("Walk on Walls desligado (respawn) — ligue de novo se quiser", "warn")
            end
        end)
    end
    Build()
end
