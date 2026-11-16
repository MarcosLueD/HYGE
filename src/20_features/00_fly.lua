--------------------------------------------------------------------------------
-- FEATURES
--------------------------------------------------------------------------------

-- FLY -------------------------------------------------------------------------
local flyBv, flyBg, flyTrack

--------------------------------------------------------------------------------
-- POSE DE SUPERMAN (procedural, sem asset id)
-- Escreve direto no Transform das juntas depois que a animação padrão roda,
-- então vence o Animate do jogo sem precisar de animação publicada.
--------------------------------------------------------------------------------
local FlyPose = { active = false }
do
    local RENDER_NAME = "HYGE_FlyPose"

    local function rad(v) return math.rad(v or 0) end

    function FlyPose.Stop()
        if not FlyPose.active then return end
        FlyPose.active = false
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
    end

    function FlyPose.Start()
        FlyPose.Stop()
        local char = Char()
        local h = Hum()
        if not char or not h then return end

        local r6 = (h.RigType == Enum.HumanoidRigType.R6)
        local joints = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") or d:IsA("Motor") then
                joints[d.Name] = d
            end
        end

        local P = CONFIG.Pose
        local ok = pcall(function()
            RunService:BindToRenderStep(RENDER_NAME,
                Enum.RenderPriority.Character.Value + 1, function()
                    if r6 then
                        -- R6: sem cotovelo/joelho, só ombro (Z+X) e quadril (Z+X)
                        local rs = joints["Right Shoulder"]
                        local ls = joints["Left Shoulder"]
                        local rh = joints["Right Hip"]
                        local lh = joints["Left Hip"]
                        local nk = joints["Neck"]
                        if rs then rs.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(P.ArmFront)) end
                        if ls then ls.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(-P.ArmBack)) end
                        if rh then rh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(-P.LegSpread)) end
                        if lh then lh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(P.LegSpread)) end
                        if nk then nk.Transform = CFrame.Angles(rad(P.Neck), 0, 0) end
                    else
                        -- R15: ombro+cotovelo, quadril+joelho, cintura, pescoço
                        local rs = joints["RightShoulder"]
                        local ls = joints["LeftShoulder"]
                        local re = joints["RightElbow"]
                        local le = joints["LeftElbow"]
                        local rh = joints["RightHip"]
                        local lh = joints["LeftHip"]
                        local rk = joints["RightKnee"]
                        local lk = joints["LeftKnee"]
                        local wa = joints["Waist"]
                        local nk = joints["Neck"]
                        if rs then rs.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(P.ArmFront)) end
                        if ls then ls.Transform = CFrame.Angles(rad(P.ArmOut), 0, rad(-P.ArmBack)) end
                        if re then re.Transform = CFrame.Angles(rad(P.Elbow), 0, 0) end
                        if le then le.Transform = CFrame.Angles(rad(P.Elbow), 0, 0) end
                        if rh then rh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(-P.LegSpread)) end
                        if lh then lh.Transform = CFrame.Angles(rad(P.HipLift), 0, rad(P.LegSpread)) end
                        if rk then rk.Transform = CFrame.Angles(rad(P.KneeFold), 0, 0) end
                        if lk then lk.Transform = CFrame.Angles(rad(P.KneeFold), 0, 0) end
                        if wa then wa.Transform = CFrame.Angles(rad(P.Waist), 0, 0) end
                        if nk then nk.Transform = CFrame.Angles(rad(P.Neck), 0, 0) end
                    end
                end)
        end)
        FlyPose.active = ok
        if not ok then Log("Pose de voo falhou ao iniciar", "warn") end
    end
end

-- Animação do voo (ordem explicada em CONFIG, "ANIMAÇÃO DO VOO"):
--   ID seu  >  estilo "jogo" (nadar/flutuar do próprio personagem)  >
--   estilo "pacote"  >  pose procedural (reserva, só você vê)
-- FlyPose.tilt = true faz o loop do Fly deitar o corpo na direção do voo.
local function StartFlyAnim()
    local h = Hum()
    if not h then return end
    local animator = h:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = h
    end
    FlyPose.tilt = false

    -- AnimationId de uma pasta do script Animate do personagem (nil se não há)
    local function FromGame(names)
        local char = Char()
        local animate = char and char:FindFirstChild("Animate")
        if not animate then return nil end
        for _, n in ipairs(names) do
            local f = animate:FindFirstChild(n)
            local a = f and f:FindFirstChildOfClass("Animation")
            if a and a.AnimationId ~= "" then return a.AnimationId end
        end
        return nil
    end

    local style = SET.FlyStyle or CONFIG.FlyStyle or "jogo"
    local source = "sua"
    local moveId = (h.RigType == Enum.HumanoidRigType.R6)
        and CONFIG.FlyAnimR6 or CONFIG.FlyAnimR15
    local idleId = CONFIG.FlyAnimIdle
    if not moveId or moveId == "" then
        moveId, idleId = nil, nil
        if style == "jogo" then
            source = "do jogo"
            moveId = FromGame({ "swim" })
            if moveId then
                idleId = FromGame({ "swimidle", "fall" })
            elseif not FlyPose.warnedNoSwim then
                FlyPose.warnedNoSwim = true
                Log("Fly: este personagem não tem animação de nadar (R6 ou Animate "
                    .. "próprio do jogo) — usando a pose do painel, que só você vê", "warn")
            end
        elseif style == "pacote" then
            source = "do pacote Endless Aura"
            moveId, idleId = CONFIG.FlyPackMove, CONFIG.FlyPackIdle
        end
    end

    local function LoadTrack(id)
        if not id or id == "" then return nil end
        local obj = Instance.new("Animation")
        obj.AnimationId = id
        local ok, tr = pcall(function() return animator:LoadAnimation(obj) end)
        pcall(function() obj:Destroy() end)
        if not ok or not tr then return nil end
        pcall(function()
            tr.Priority = Enum.AnimationPriority.Action4
            tr.Looped = true
            tr:AdjustSpeed(CONFIG.FlyAnimSpeed or 1)
        end)
        return tr
    end

    flyTrack = LoadTrack(moveId)
    FlyPose.idleTrack = LoadTrack(idleId)
    if not flyTrack and FlyPose.idleTrack then
        flyTrack = FlyPose.idleTrack
        FlyPose.idleTrack = nil
    end

    if not flyTrack then
        -- nenhuma animação disponível: a pose procedural (se CONFIG.FlyUsePose)
        if CONFIG.FlyUsePose then FlyPose.Start() end
        return
    end

    FlyPose.muted = false
    FlyPose.tilt = (source == "do jogo")   -- nadar no ar: o corpo deita
    pcall(function() flyTrack:Play(0.2) end)

    -- O Roblox só recusa asset de terceiro DEPOIS de carregar: track fica com
    -- Length 0 e nada anima. Se for o caso, volta pra pose procedural e avisa.
    local mine = flyTrack
    task.delay(1.2, function()
        if not flyTrack or flyTrack ~= mine then return end   -- voo já reiniciou
        -- a de "parado no ar" não carregou: fica só a de movimento
        if FlyPose.idleTrack then
            local ilen = 0
            pcall(function() ilen = FlyPose.idleTrack.Length end)
            if ilen <= 0 then
                pcall(function() FlyPose.idleTrack:Stop(0) end)
                pcall(function() FlyPose.idleTrack:Destroy() end)
                FlyPose.idleTrack = nil
            end
        end
        local len = 0
        pcall(function() len = flyTrack.Length end)
        if len > 0 then return end
        pcall(function() flyTrack:Stop(0) end)
        pcall(function() flyTrack:Destroy() end)
        flyTrack = nil
        FlyPose.tilt = false
        if FlyPose.idleTrack then
            pcall(function() FlyPose.idleTrack:Stop(0) end)
            pcall(function() FlyPose.idleTrack:Destroy() end)
            FlyPose.idleTrack = nil
        end
        Log("O Roblox recusou a animação de voo " .. source .. " (asset que não é "
            .. "do dono do jogo nem da Roblox) — usando a pose do painel.", "error")
        if CONFIG.FlyUsePose then FlyPose.Start() end
    end)
end

local function StopFlyAnim()
    FlyPose.Stop()
    FlyPose.muted = false
    FlyPose.tilt = false
    if flyTrack then
        pcall(function() flyTrack:Stop(0.2) end)
        pcall(function() flyTrack:Destroy() end)
        flyTrack = nil
    end
    if FlyPose.idleTrack then
        pcall(function() FlyPose.idleTrack:Stop(0.2) end)
        pcall(function() FlyPose.idleTrack:Destroy() end)
        FlyPose.idleTrack = nil
    end
end

local function StopFly()
    Drop("Fly")
    Drop("FlyAnimKeep")
    StopFlyAnim()
    if flyBv then flyBv:Destroy() flyBv = nil end
    if flyBg then flyBg:Destroy() flyBg = nil end
    local h = Hum()
    if h then h.PlatformStand = false end
end

local function StartFly()
    local root = Root()
    local h = Hum()
    if not root or not h then error("sem personagem") end
    StopFly()

    flyBv = Instance.new("BodyVelocity")
    flyBv.Name = "HYGE_Fly"
    flyBv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBv.Velocity = Vector3.zero
    flyBv.Parent = root

    flyBg = Instance.new("BodyGyro")
    flyBg.Name = "HYGE_Gyro"
    flyBg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBg.P = 15000
    flyBg.D = 1000
    flyBg.CFrame = root.CFrame
    flyBg.Parent = root

    local vel = Vector3.zero
    Conn.Fly = RunService.RenderStepped:Connect(function()
        if not flyBv or not flyBv.Parent then return end
        local cam = Camera.CFrame
        local dir = Vector3.zero
        -- v8.0: digitando no chat/console o personagem não sai voando
        if not V8.Typing() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
        end

        local speed = State.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2 end

        local target = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        vel = vel:Lerp(target, target.Magnitude > 0 and 0.18 or 0.1)
        flyBv.Velocity = vel

        local look = vel.Magnitude > 2 and vel.Unit or cam.LookVector
        -- v8.1.1: parado no ar com a animação do jogo, fica em pé olhando para
        -- onde a câmera aponta no plano (sem inclinar junto com a câmera)
        if FlyPose.tilt and vel.Magnitude <= 2 then
            local flat = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
            if flat.Magnitude > 1e-3 then look = flat.Unit end
        end
        local r = Root()
        if r and flyBg then
            local aim = CFrame.lookAt(r.Position, r.Position + look)
            if FlyPose.active then
                -- deita o corpo na direção do voo (pose de superman)
                aim = aim * CFrame.Angles(math.rad(CONFIG.Pose.BodyTilt or -90), 0, 0)
            elseif FlyPose.tilt and not FlyPose.muted then
                -- animação de nadar do jogo: deita mais quanto mais rápido voa
                -- (cabeça para onde você vai; parado, fica em pé)
                local k = math.clamp(vel.Magnitude / math.max(State.FlySpeed, 1), 0, 1)
                local deg = SET.FlyTilt or CONFIG.FlySwimTilt or 75
                aim = aim * CFrame.Angles(math.rad(-deg * k), 0, 0)
            end
            flyBg.CFrame = flyBg.CFrame:Lerp(aim, 0.15)
        end
        local h2 = Hum()
        if h2 then h2.PlatformStand = true end
    end)

    StartFlyAnim()
    -- PlatformStand / troca de state às vezes derruba a track: religa sozinho
    Conn.FlyAnimKeep = RunService.Heartbeat:Connect(function()
        if not flyTrack or FlyPose.muted then return end
        local idle = FlyPose.idleTrack
        if idle then
            -- parado no ar = flutuar; em deslocamento = animação de voo
            local moving = (flyBv and flyBv.Velocity.Magnitude > 6)
            local want = moving and flyTrack or idle
            local other = moving and idle or flyTrack
            if other.IsPlaying then pcall(function() other:Stop(0.25) end) end
            if not want.IsPlaying then pcall(function() want:Play(0.25) end) end
        elseif not flyTrack.IsPlaying then
            pcall(function() flyTrack:Play(0.15) end)
        end
    end)
end

DefineToggle({
    id = "fly", label = "Fly", desc = "WASD + Space/Ctrl, Shift = 2x",
    enable = StartFly, disable = StopFly,
})

