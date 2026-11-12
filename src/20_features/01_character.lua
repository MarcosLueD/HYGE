-- NOCLIP ---------------------------------------------------------------------
local function CacheNoclipParts()
    NoclipParts = {}
    local c = Char()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(NoclipParts, p) end
    end
end

DefineToggle({
    id = "noclip", label = "Noclip", desc = "Atravessa paredes",
    enable = function()
        CacheNoclipParts()
        Conn.Noclip = RunService.Stepped:Connect(function()
            for i = #NoclipParts, 1, -1 do
                local p = NoclipParts[i]
                if not p.Parent then
                    table.remove(NoclipParts, i)
                elseif p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    end,
    disable = function()
        Drop("Noclip")
        for _, p in ipairs(NoclipParts) do
            if p.Parent and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
    end,
})

-- INFINITE JUMP --------------------------------------------------------------
DefineToggle({
    id = "infjump", label = "Infinite Jump", desc = "Pulo infinito",
    enable = function()
        Conn.InfJump = UserInputService.JumpRequest:Connect(function()
            local h = Hum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end,
    disable = function() Drop("InfJump") end,
})

-- GOD MODE -------------------------------------------------------------------
local savedMaxHealth = 100
local function ApplyGod(h)
    if not h then return end
    savedMaxHealth = (h.MaxHealth ~= math.huge) and h.MaxHealth or savedMaxHealth
    h.MaxHealth = math.huge
    h.Health = math.huge
    Drop("God")
    Conn.God = h.HealthChanged:Connect(function()
        if IsOn("god") then h.Health = math.huge end
    end)
end

DefineToggle({
    id = "god", label = "God Mode", desc = "Vida infinita (client-side)",
    enable = function() ApplyGod(Hum()) end,
    disable = function()
        Drop("God")
        local h = Hum()
        if h then
            h.MaxHealth = savedMaxHealth
            h.Health = savedMaxHealth
        end
    end,
})

-- INVISIBLE ------------------------------------------------------------------
local function ApplyInvisible(on)
    local c = Char()
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = on and 1 or 0
        elseif p:IsA("Decal") then
            p.Transparency = on and 1 or 0
        end
    end
end

DefineToggle({
    id = "invisible", label = "Invisível (local)", desc = "Some só na sua tela",
    enable = function() ApplyInvisible(true) end,
    disable = function() ApplyInvisible(false) end,
})

-- WALL TRANSPARENCY ----------------------------------------------------------
local function IsWorldPart(obj)
    if not obj:IsA("BasePart") then return false end
    if obj:IsDescendantOf(Camera) then return false end
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return false end
    return true
end

DefineToggle({
    id = "wall", label = "Wall Transparency", desc = "Paredes translúcidas (só pra você)",
    enable = function()
        WallCache = {}
        task.spawn(function()
            local count = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not IsOn("wall") then return end
                if IsWorldPart(obj) then
                    WallCache[obj] = true
                    obj.LocalTransparencyModifier = State.WallAlpha
                    count = count + 1
                    if count % 400 == 0 then task.wait() end   -- evita travar o frame
                end
            end
            Log("Wall Transparency: " .. count .. " partes", "ok")
        end)
        Conn.Wall = workspace.DescendantAdded:Connect(function(obj)
            if IsWorldPart(obj) then
                WallCache[obj] = true
                obj.LocalTransparencyModifier = State.WallAlpha
            end
        end)
    end,
    disable = function()
        Drop("Wall")
        for part in pairs(WallCache) do
            if part.Parent then part.LocalTransparencyModifier = 0 end
        end
        WallCache = {}
    end,
})

