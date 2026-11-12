--------------------------------------------------------------------------------
-- AÇÕES DE MODERAÇÃO
--------------------------------------------------------------------------------
local function RequireSelected()
    if not State.SelectedPlayer or not State.SelectedPlayer.Parent then
        Toast("Selecione um jogador na aba Players", "warn")
        Log("Nenhum jogador selecionado", "warn")
        return nil
    end
    return State.SelectedPlayer
end

local function TeleportTo(cframe)
    local root = Root()
    if not root then Toast("Sem personagem", "warn") return end
    root.CFrame = cframe
end

local function Goto(player)
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then Toast("Alvo sem personagem", "warn") return end
    TeleportTo(root.CFrame * CFrame.new(0, 0, 4))
    Log("Goto -> " .. player.Name, "ok")
end

local function Bring(player)
    if Remotes.Pull then
        Remotes.Pull:FireServer(player.UserId, "selected")
        Log("Bring (server) -> " .. player.Name, "ok")
        return
    end
    local myRoot, theirRoot = Root(), player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and theirRoot then
        theirRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
        Log("Bring (local) -> " .. player.Name, "warn")
    else
        Toast("Não foi possível trazer", "error")
    end
end

local function FreezePlayer(player, freeze)
    if Remotes.Freeze then Remotes.Freeze:FireServer(player.UserId, freeze) end
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local h = char:FindFirstChildOfClass("Humanoid")
        if root then root.Anchored = freeze end
        if h then
            h.PlatformStand = freeze
            h.WalkSpeed = freeze and 0 or 16
        end
    end
    Log((freeze and "Freeze: " or "Unfreeze: ") .. player.Name, "ok")
end

local function KickPlayer(player, reason)
    if Remotes.Kick then
        Remotes.Kick:FireServer(player.UserId, reason or "Removido por um admin")
        Log("Kick enviado: " .. player.Name, "ok")
    else
        Log("Remote AdminKick ausente — kick precisa do servidor", "error")
        Toast("Sem AdminKick no ReplicatedStorage", "error")
    end
end

--------------------------------------------------------------------------------
-- AÇÕES DE TROLL (v8.0) — 100% dependentes de servidor, cliente só pede.
-- Estado local (Spin/Balloon) é só o que o painel PEDIU, não confirmação real
-- de que o servidor aplicou — deixado claro no Log.
--------------------------------------------------------------------------------
local TrollState = { Spin = {}, Balloon = {} }

local function FlingPlayer(player)
    if not Remotes.Fling then
        Log("Remote AdminFling ausente — fling precisa do servidor", "error")
        Toast("Sem AdminFling no ReplicatedStorage", "error")
        return
    end
    Remotes.Fling:FireServer(player.UserId)
    Log("Fling enviado: " .. player.Name, "ok")
end

local function SpinPlayer(player, on)
    if not Remotes.Spin then
        Log("Remote AdminSpin ausente — spin precisa do servidor", "error")
        Toast("Sem AdminSpin no ReplicatedStorage", "error")
        return
    end
    Remotes.Spin:FireServer(player.UserId, on)
    TrollState.Spin[player.UserId] = on
    Log((on and "Spin ON pedido: " or "Spin OFF pedido: ") .. player.Name, "ok")
end

local function TripPlayer(player)
    if not Remotes.Trip then
        Log("Remote AdminTrip ausente — trip precisa do servidor", "error")
        Toast("Sem AdminTrip no ReplicatedStorage", "error")
        return
    end
    Remotes.Trip:FireServer(player.UserId)
    Log("Trip enviado: " .. player.Name, "ok")
end

local function LaunchPlayer(player)
    if not Remotes.Launch then
        Log("Remote AdminLaunch ausente — launch precisa do servidor", "error")
        Toast("Sem AdminLaunch no ReplicatedStorage", "error")
        return
    end
    Remotes.Launch:FireServer(player.UserId)
    Log("Launch enviado: " .. player.Name, "ok")
end

local function SitPlayer(player)
    if not Remotes.Sit then
        Log("Remote AdminSit ausente — force sit precisa do servidor", "error")
        Toast("Sem AdminSit no ReplicatedStorage", "error")
        return
    end
    Remotes.Sit:FireServer(player.UserId)
    Log("Force Sit enviado: " .. player.Name, "ok")
end

local function ScalePlayer(player, mode)
    if not Remotes.Scale then
        Log("Remote AdminScale ausente — mudar tamanho precisa do servidor", "error")
        Toast("Sem AdminScale no ReplicatedStorage", "error")
        return
    end
    Remotes.Scale:FireServer(player.UserId, mode)
    Log("Scale (" .. mode .. ") enviado: " .. player.Name, "ok")
end

local function BalloonPlayer(player, on)
    if not Remotes.Balloon then
        Log("Remote AdminBalloon ausente — balão precisa do servidor", "error")
        Toast("Sem AdminBalloon no ReplicatedStorage", "error")
        return
    end
    Remotes.Balloon:FireServer(player.UserId, on)
    TrollState.Balloon[player.UserId] = on
    Log((on and "Balloon ON pedido: " or "Balloon OFF pedido: ") .. player.Name, "ok")
end

local function FakeMessage(player, kind)
    local texts = {
        kick = "[SISTEMA] " .. player.Name .. " foi expulso do servidor.",
        ban  = "[SISTEMA] " .. player.Name .. " foi banido permanentemente.",
    }
    local msg = texts[kind] or texts.kick
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = msg, Color = THEME.Danger, Font = Enum.Font.GothamBold })
    end)
    Log("Fake message exibida SÓ na sua tela — o alvo e o servidor não veem nada: "
        .. msg, "warn")
    Toast("Fake message é 100% local", "warn", 3)
end

local function Announce(msg)
    if Remotes.Announce then
        Remotes.Announce:FireServer(msg)
        Log("Anúncio enviado: " .. msg, "ok")
    else
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "[ADMIN] " .. msg, Color = THEME.Accent, Font = Enum.Font.GothamBold })
        end)
        Log("Anúncio local: " .. msg, "warn")
    end
end

local function Copy(text, what)
    if setclipboard then
        setclipboard(text)
        Log(what .. " copiado: " .. text, "ok")
        Toast(what .. " copiado", "ok", 1.5)
    else
        Log(what .. ": " .. text)
    end
end

