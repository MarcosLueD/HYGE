--------------------------------------------------------------------------------
-- NAVEGAÇÃO, COMANDOS, ORB, SCHEDULER, RESPAWN, UNLOAD, BOOT
--------------------------------------------------------------------------------
local CmdBar, CmdInput, ToggleCmdBar, RunCommand  -- forward
local Orb, SetOpen, SetMinimized, isOpen          -- forward

--------------------------------------------------------------------------------
-- STATUS GERAL (topbar + dashboard + abas)
--------------------------------------------------------------------------------
RefreshStatus = function()
    if RefreshQuick then pcall(RefreshQuick) end
    if Tiles and Tiles.remotes then
        local have, total = V8.RemoteStatus()
        Tiles.remotes.Text = have .. "/" .. total
    end
end

--------------------------------------------------------------------------------
-- NAVEGAÇÃO (ordem das abas)
--------------------------------------------------------------------------------
AddNav("Home", 1)
AddNav("Movement", 2)
AddNav("Visuals", 3)
AddNav("Players", 4)
AddNav("Moderation", 5)
AddNav("Server", 6)
AddNav("Emotes", 7)
AddNav("Settings", 8)

