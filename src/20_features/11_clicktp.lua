--------------------------------------------------------------------------------
-- v8.2 — CTRL + CLIQUE TELEPORTA (Personagem › Movimento › Teleporte)
-- Com a função ligada, Ctrl + clique esquerdo leva o personagem até o ponto do
-- mapa embaixo do mouse. Clique em cima de GUI (painel, chat) não conta: o
-- Roblox marca esse clique como "processado" (gpe).
-- O raio sai da câmera e ignora o próprio personagem. O personagem chega em pé
-- na superfície (altura do quadril do rig) e continua olhando para o mesmo lado.
-- Tudo dentro do do..end: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Pick()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local pos = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(pos.X, pos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = Char() and { Char() } or {}
        return workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
    end

    local function Enable()
        Drop("ClickTp")
        Conn.ClickTp = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
            local r, h = Root(), Hum()
            if not r or not h then return end
            local hit = Pick()
            if not hit then
                Toast("Nada embaixo do mouse", "warn", 1.4)
                return
            end
            -- R15: centro do HumanoidRootPart fica HipHeight + meia altura acima
            -- do chão; R6 tem HipHeight 0 e pernas de 2 studs
            local stand = (h.RigType == Enum.HumanoidRigType.R15)
                and (h.HipHeight + r.Size.Y * 0.5) or 3
            local at = hit.Position + hit.Normal * 0.5 + Vector3.new(0, stand + 0.25, 0)
            local rot = r.CFrame - r.CFrame.Position
            TeleportTo(CFrame.new(at) * rot)
            pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
            V8.ClickTps = (V8.ClickTps or 0) + 1
            Log(string.format("TP clique -> %d, %d, %d", at.X, at.Y, at.Z), "action")
        end)
    end

    DefineToggle({
        id = "clicktp", label = "Ctrl + clique TP",
        desc = "Ctrl + clique esquerdo leva você até onde o mouse aponta",
        enable = Enable,
        disable = function() Drop("ClickTp") end,
    })
end
