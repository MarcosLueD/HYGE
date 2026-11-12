--------------------------------------------------------------------------------
-- CHECAGEM DE ADMIN
--------------------------------------------------------------------------------
local function IsAdmin(player)
    for _, id in ipairs(CONFIG.AdminIds) do
        if player.UserId == id then return true end
    end
    return false
end

if not IsAdmin(LocalPlayer) then
    warn("[HYGE " .. CONFIG.Version .. "] Acesso negado.")
    return
end

print("[HYGE] iniciando " .. CONFIG.Version .. "...")

-- Onde a GUI vai morar.
-- Executor: gethui() / CoreGui (não some no respawn e não depende do PlayerGui).
-- Studio / LocalScript normal: PlayerGui.
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    or LocalPlayer:WaitForChild("PlayerGui", 10)

local GuiParent
do
    local ok, hui = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
        return nil
    end)
    if ok and hui then
        GuiParent = hui
        print("[HYGE] GUI em: gethui()")
    end

    if not GuiParent then
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then
            local writable = pcall(function()
                local probe = Instance.new("Folder")
                probe.Parent = cg
                probe:Destroy()
            end)
            if writable then
                GuiParent = cg
                print("[HYGE] GUI em: CoreGui")
            end
        end
    end

    if not GuiParent then
        GuiParent = PlayerGui
        print("[HYGE] GUI em: PlayerGui")
    end
    if not GuiParent then
        error("[HYGE] não achei um lugar para colocar a GUI")
    end
end

-- Evita duas instâncias abertas ao mesmo tempo (em qualquer um dos parents)
for _, holder in ipairs({ GuiParent, PlayerGui }) do
    if holder then
        local prev = holder:FindFirstChild("HYGE_PANEL")
        if prev then prev:Destroy() end
    end
end

