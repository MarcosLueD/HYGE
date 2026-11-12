-- SPECTATE -------------------------------------------------------------------
local SpectateHud
local StopSpectate, StartSpectate

StopSpectate = function()
    if not State.Spectating then return end
    State.Spectating = false
    State.SpectateTarget = nil
    Drop("SpectateEnd")
    Camera.CameraType = camBackup.type or Enum.CameraType.Custom
    Camera.CameraSubject = Hum()
    if SpectateHud then SpectateHud.Visible = false end
    if RefreshStatus then RefreshStatus() end
    Log("Spectate OFF")
end

StartSpectate = function(player)
    local char = player and player.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if not h then Toast("Alvo sem personagem", "warn") return end
    camBackup.type = camBackup.type or Camera.CameraType
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = h
    State.Spectating = true
    State.SpectateTarget = player
    Drop("SpectateEnd")
    Conn.SpectateEnd = player.CharacterRemoving:Connect(StopSpectate)
    if SpectateHud then
        SpectateHud.Visible = true
        SpectateHud.Label.Text = "Assistindo " .. player.DisplayName .. "  (@" .. player.Name .. ")"
        SpectateHud.Input.PlaceholderText = "Mensagem privada para " .. player.DisplayName
    end
    if RefreshStatus then RefreshStatus() end
    Log("Spectate: " .. player.Name, "ok")
end

local function CycleSpectate(dir)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    if #list == 0 then return end
    local idx = 1
    for i, p in ipairs(list) do
        if p == State.SpectateTarget then idx = i break end
    end
    idx = ((idx - 1 + dir) % #list) + 1
    StartSpectate(list[idx])
end

