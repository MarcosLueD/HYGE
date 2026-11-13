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
-- NAVEGAÇÃO (sidebar — só aparece com o dock desligado)
-- v8.0: mesma ordem das seções do dock, sub-abas logo depois da principal
--------------------------------------------------------------------------------
AddNav("Home", 1)
AddNav("Server", 2)
AddNav("Movement", 3)
AddNav("Visuals", 4)
AddNav("Shop", 5)
AddNav("Scripts", 6)
AddNav("Emotes", 7)
AddNav("Players", 8)
AddNav("Moderation", 9)
AddNav("Settings", 10)
AddNav("Chat", 11)

