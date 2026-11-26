-- Roblox de servidor imitado para rodar server/HYGE_AdminServer.server.lua.
-- Só o que o script usa. Players/Remotes/TextService controláveis pelo teste.

CLOCK = 1000
os.clock = function() return CLOCK end
shared = {}

local function Signal()
    local s = { fns = {} }
    function s:Connect(fn) table.insert(self.fns, fn) return { Disconnect = function() end } end
    function s:Fire(...) for _, fn in ipairs(self.fns) do fn(...) end end
    return s
end

Enum = {
    CreatorType = { User = "User", Group = "Group" },
    TextFilterContext = { PublicChat = "PublicChat", PrivateChat = "PrivateChat" },
    ActuatorRelativeTo = { World = "World" },
    VelocityConstraintMode = { Line = "Line" },
}

local V3 = {}
V3.__index = V3
V3.__mul = function(a, b) if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end return b * a end
Vector3 = { new = function(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end }
Vector3.yAxis = Vector3.new(0, 1, 0)
local CF = {}
CF.__index = CF
CF.__mul = function(a, b) return setmetatable({ p = (a.p or 0) + (b.p or 0) }, CF) end
CFrame = { new = function(x, y, z) return setmetatable({ p = (x or 0) + (y or 0) + (z or 0), RightVector = Vector3.new(1, 0, 0) }, CF) end }
workspace = { Gravity = 196.2 }

-- instâncias genéricas
local function Inst(class, name)
    local o = { ClassName = class, Name = name or class, children = {}, Parent = nil }
    function o:IsA(c) return self.ClassName == c end
    function o:FindFirstChild(n) for _, c in ipairs(self.children) do if c.Name == n and not c.destroyed then return c end end return nil end
    function o:FindFirstChildOfClass(cl) for _, c in ipairs(self.children) do if c.ClassName == cl and not c.destroyed then return c end end return nil end
    function o:WaitForChild(n) return self:FindFirstChild(n) end
    function o:Destroy() self.destroyed = true self.Parent = nil end
    function o:Clone()
        local c = Instance.new(self.ClassName)
        c.Name = self.Name
        c.clonedFrom = self
        return c
    end
    return o
end

ReplicatedStorage = Inst("ReplicatedStorage")
ServerStorage = Inst("ServerStorage")
local realChildren = ReplicatedStorage.children
REMOTES = {}

Instance = {
    new = function(class)
        local o = Inst(class)
        if class == "RemoteEvent" then
            o.OnServerEvent = Signal()
            o.sent = {}         -- FireClient / FireAllClients
            function o:FireClient(p, ...) table.insert(self.sent, { to = p, args = { ... } }) end
            function o:FireAllClients(...) table.insert(self.sent, { to = "all", args = { ... } }) end
        end
        return setmetatable(o, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                if k == "Parent" and v == ReplicatedStorage then
                    table.insert(realChildren, t)
                    REMOTES[t.Name] = t
                elseif k == "Parent" and type(v) == "table" and v.children then
                    table.insert(v.children, t)
                end
            end,
        })
    end,
}
-- Parent é atribuído depois do Name no script: o __newindex cuida disso;
-- rawset não dispara __newindex, então Parent começa ausente (nil)
do
    local new = Instance.new
    Instance.new = function(class)
        local o = new(class)
        rawset(o, "Parent", nil)
        return o
    end
end

-- jogadores
Players = Inst("Players")
Players.PlayerAdded, Players.PlayerRemoving = Signal(), Signal()
PLAYERS = {}
function Players:GetPlayerByUserId(id) for _, p in ipairs(PLAYERS) do if p.UserId == id then return p end end return nil end
function Players:GetPlayers() return PLAYERS end

-- opts: ranks = { [grupo] = rank } | rankError = true | noCharacter = true
function AddPlayer(name, userId, opts)
    opts = opts or {}
    local p = Inst("Player", name)
    p.UserId, p.Parent = userId, Players
    local gui = Inst("PlayerGui", "PlayerGui")
    gui.Parent = p
    table.insert(p.children, gui)
    local char = Inst("Model", name)
    local root = Inst("Part", "HumanoidRootPart")
    root.Parent, root.CFrame, root.AssemblyMass, root.Anchored = char, CFrame.new(0, 0, 0), 10, false
    root.SetNetworkOwner = function() end
    table.insert(char.children, root)
    local hum = Inst("Humanoid", "Humanoid")
    hum.Parent = char
    table.insert(char.children, hum)
    char.PivotTo = function(self, cf) self.pivoted = cf end
    char.ScaleTo = function(self, f) self.scale = f end
    if not opts.noCharacter then p.Character = char end
    p.Kick = function(self, msg) self.kicked = msg or "" self.Parent = nil end
    p.GetRankInGroup = function(self, g)
        if opts.rankError then error("HTTP 503") end
        return (opts.ranks or {})[g] or 0
    end
    table.insert(PLAYERS, p)
    Players.PlayerAdded:Fire(p)
    return p
end

-- o jogador sai do servidor (alvo que some entre o clique e o pedido)
function RemovePlayer(p)
    for i, q in ipairs(PLAYERS) do if q == p then table.remove(PLAYERS, i) break end end
    Players.PlayerRemoving:Fire(p)
    p.Parent = nil
end

-- filtro de texto: FILTER = "ok" | "error" | "hash" | function(texto) -> texto
FILTER = "ok"
FILTERED = {}   -- { text, from, ctx, to }
TextService = {
    FilterStringAsync = function(_, text, from, ctx)
        table.insert(FILTERED, { text = text, from = from, ctx = ctx })
        if FILTER == "error" then error("filtro fora do ar") end
        local function out(to)
            FILTERED[#FILTERED].to = to
            if FILTER == "hash" then return (text:gsub("%S", "#")) end
            if type(FILTER) == "function" then return FILTER(text) end
            return "[f]" .. text
        end
        return {
            GetNonChatStringForBroadcastAsync = function() return out("all") end,
            GetNonChatStringForUserAsync = function(_, uid) return out(uid) end,
        }
    end,
}

game = {
    CreatorType = Enum.CreatorType.User,
    CreatorId = 1,
    GetService = function(_, n)
        local s = ({ Players = Players, ReplicatedStorage = ReplicatedStorage, TextService = TextService,
                     ServerStorage = ServerStorage })[n]
        return s or error("serviço não imitado: " .. n)
    end,
}

-- chama um RemoteEvent como se fosse o cliente 'player'
function Call(remote, player, ...)
    REMOTES[remote].OnServerEvent:Fire(player, ...)
end
-- chama o HYGE_Status (RemoteFunction) como o cliente 'player'
function Ask(player, ...)
    return REMOTES.HYGE_Status.OnServerInvoke(player, ...)
end
-- respostas estruturadas que o servidor mandou para 'player' (HYGE_Result)
function ResultsFor(player)
    local out = {}
    for _, s in ipairs(REMOTES.HYGE_Result.sent) do
        if s.to == player then table.insert(out, s.args[1]) end
    end
    return out
end
function LastResult(player) local r = ResultsFor(player) return r[#r] end
-- as mesmas respostas como o console do painel mostra ("✓ Kick: Bob")
function NotesFor(player)
    local out = {}
    for _, r in ipairs(ResultsFor(player)) do
        table.insert(out, (r.ok and "✓ " or "✗ ") .. tostring(r.message))
    end
    return table.concat(out, " | ")
end
function LastAudit() return shared.HYGE_AUDIT[#shared.HYGE_AUDIT] end
-- o registro inteiro como texto (para conferir o que NÃO pode estar lá)
function AuditText()
    local out = {}
    for _, e in ipairs(shared.HYGE_AUDIT) do
        local t = {}
        for k, v in pairs(e) do table.insert(t, tostring(k) .. "=" .. tostring(v)) end
        table.insert(out, table.concat(t, " "))
    end
    return table.concat(out, "\n")
end
