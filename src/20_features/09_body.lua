--------------------------------------------------------------------------------
-- v8.1 — ANTI-FALL e ANTI-GRAVIDADE (seção Personagem)
--
-- Anti-Fall, três camadas, tudo no SEU personagem:
--   1. desliga os estados FallingDown/Ragdoll do Humanoid (sem tombo)
--   2. pouso suave: caindo rápido com o chão logo abaixo, a velocidade de
--      queda é cortada antes do impacto (jogos que dão dano por velocidade
--      de pouso deixam de dar)
--   3. void: abaixo de FallenPartsDestroyHeight + 60, volta para o último
--      lugar em que você estava pisando
-- Dano de queda feito por script do servidor com outra regra continua valendo.
--
-- Anti-Gravidade: workspace.Gravity vale só para a física que roda no SEU
-- cliente — o seu personagem (você é o dono da física dele) e peças soltas
-- que o seu cliente simula. Os outros jogadores não mudam. Se o jogo trocar
-- a gravidade enquanto está ligado, o valor novo vira a base.
--
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        ------------------------------------------------------------ ANTI-FALL
        local AF = { hum = nil, safe = nil, acc = 0 }
        V8.AntiFall = AF
        local STATES = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll }
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        -- reaplica sozinho no respawn: o Humanoid novo é detectado no loop
        local function Guard(h)
            if AF.hum == h then return end
            AF.hum = h
            for _, st in ipairs(STATES) do
                pcall(function() h:SetStateEnabled(st, false) end)
            end
        end

        local function Unguard()
            local h = AF.hum
            AF.hum = nil
            if h and h.Parent then
                for _, st in ipairs(STATES) do
                    pcall(function() h:SetStateEnabled(st, true) end)
                end
            end
        end

        DefineToggle({
            id = "antifall", label = "Anti-Fall",
            desc = "Sem tombo nem dano de queda; volta se cair no void",
            enable = function()
                AF.safe = nil
                AF.acc = 0
                Conn.AntiFall = RunService.Heartbeat:Connect(function(dt)
                    local h, root = Hum(), Root()
                    if not h or not root then return end
                    Guard(h)
                    local pos = root.Position
                    local vel = root.AssemblyLinearVelocity
                    local voidY = workspace.FallenPartsDestroyHeight

                    -- último chão seguro (4x por segundo, parado em algo)
                    AF.acc = AF.acc + dt
                    if AF.acc >= 0.25 then
                        AF.acc = 0
                        if h.FloorMaterial ~= Enum.Material.Air and math.abs(vel.Y) < 5
                            and pos.Y > voidY + 80 then
                            AF.safe = root.CFrame
                        end
                    end

                    -- void
                    if pos.Y < voidY + 60 and AF.safe then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.CFrame = AF.safe + Vector3.new(0, 3, 0)
                        Log("Anti-Fall: caiu no void — voltou para o último chão", "action")
                        return
                    end

                    -- pouso suave
                    if vel.Y < -55 then
                        params.FilterDescendantsInstances = { Char() }
                        local reach = 6 + math.abs(vel.Y) * dt * 3
                        local hit = workspace:Raycast(pos, Vector3.new(0, -reach, 0), params)
                        if hit then
                            root.AssemblyLinearVelocity = Vector3.new(vel.X, -12, vel.Z)
                        end
                    end
                end)
            end,
            disable = function()
                Drop("AntiFall")
                Unguard()
                AF.safe = nil
            end,
        })

        ------------------------------------------------------- ANTI-GRAVIDADE
        local AG = { base = nil, busy = false }
        V8.AntiGrav = AG

        local function Want()
            return (AG.base or 196.2) * math.clamp(State.GravityPct or 25, 0, 100) / 100
        end

        local function Write()
            AG.busy = true
            pcall(function() workspace.Gravity = Want() end)
            AG.busy = false
        end

        -- slider da seção Personagem (e comando 'gravity')
        AG.Set = function(pct)
            State.GravityPct = math.clamp(math.floor((tonumber(pct) or 25) + 0.5), 0, 100)
            if IsOn("antigrav") then Write() end
        end

        DefineToggle({
            id = "antigrav", label = "Anti-Gravidade",
            desc = "Gravidade baixa só para você: pula alto e cai devagar",
            enable = function()
                AG.base = workspace.Gravity
                Write()
                Conn.AntiGrav = workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
                    if AG.busy then return end
                    local cur = workspace.Gravity
                    if math.abs(cur - Want()) > 0.01 then
                        AG.base = cur   -- o jogo trocou a gravidade: vira a base nova
                        Write()
                    end
                end)
            end,
            disable = function()
                Drop("AntiGrav")
                if AG.base then
                    AG.busy = true
                    pcall(function() workspace.Gravity = AG.base end)
                    AG.busy = false
                end
                AG.base = nil
            end,
        })
    end
    Build()
end
