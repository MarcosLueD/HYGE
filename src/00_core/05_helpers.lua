--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function Char()      return LocalPlayer.Character end
local function Root()
    local c = Char()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function Hum()
    local c = Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function KeyName(kc)
    if not kc then return "—" end
    local n = tostring(kc):gsub("Enum.KeyCode.", "")
    local short = {
        LeftControl = "LCtrl", RightControl = "RCtrl",
        LeftShift = "LShift", RightShift = "RShift",
        LeftAlt = "LAlt", RightAlt = "RAlt",
        Semicolon = ";", Quote = "'", Comma = ",", Period = ".", Slash = "/",
        LeftBracket = "[", RightBracket = "]", Backquote = "`", Minus = "-", Equals = "=",
    }
    return short[n] or n
end

local function FindPlayer(query)
    if not query or query == "" then return nil end
    query = query:lower()
    if query == "me" then return LocalPlayer end
    local best, bestLen = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        local a, b = p.Name:lower(), p.DisplayName:lower()
        if a == query or b == query then return p end
        local hit = a:find(query, 1, true) or b:find(query, 1, true)
        if hit and #a < bestLen then best, bestLen = p, #a end
    end
    return best
end

local function Comma(n) return tostring(n) end

