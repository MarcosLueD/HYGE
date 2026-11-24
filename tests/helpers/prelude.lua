-- Imitação mínima do Luau/Roblox/executor para rodar módulos do HYGE no
-- fengari (Lua 5.3). Só o que os testes usam — nada aqui vai para o main.lua.

unpack = table.unpack
loadstring = function(s, name) return load(s, name) end

function typeof(v)
    local mt = type(v) == "table" and getmetatable(v)
    if mt and rawget(mt, "__type") then return mt.__type end
    return type(v)
end

-- bit32 com a semântica do Luau (número = double; resultado sempre 0..2^32-1).
-- Atenção: os inteiros do fengari têm 32 bits (não 64 como no Lua 5.3), então
-- tudo passa por n() (qualquer número -> inteiro de 32 bits) e u() (-> 0..2^32-1)
do
    local TWO32, TWO31 = 4294967296.0, 2147483648.0
    local function n(x)
        assert(type(x) == "number", "bit32: argumento não é número")
        x = math.floor(x) % TWO32
        if x >= TWO31 then x = x - TWO32 end
        return math.tointeger(x)
    end
    local function u(x) if x < 0 then return x + TWO32 end return x end
    bit32 = {}
    function bit32.band(...) local r = -1 for i = 1, select("#", ...) do r = r & n(select(i, ...)) end return u(r) end
    function bit32.bor(...) local r = 0 for i = 1, select("#", ...) do r = r | n(select(i, ...)) end return u(r) end
    function bit32.bxor(...) local r = 0 for i = 1, select("#", ...) do r = r ~ n(select(i, ...)) end return u(r) end
    function bit32.bnot(x) return u(~n(x)) end
    function bit32.rshift(x, s) if s >= 32 then return 0 end return u(n(x) >> s) end
    function bit32.lshift(x, s) if s >= 32 then return 0 end return u(n(x) << s) end
    function bit32.rrotate(x, s)
        x, s = n(x), s % 32
        if s == 0 then return u(x) end
        return u((x >> s) | (x << (32 - s)))
    end
    function bit32.lrotate(x, s) return bit32.rrotate(x, 32 - (s % 32)) end
end

-- saída capturada (o teste confere; a tela fica limpa)
WARNS, PRINTS = {}, {}
warn = function(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end table.insert(WARNS, table.concat(t, " ")) end
print = function(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end table.insert(PRINTS, table.concat(t, " ")) end
function Said(list, pat)
    for _, s in ipairs(list) do if s:find(pat) then return s end end
    return nil
end

-- task: spawn/defer rodam na hora; delay entra numa fila (TASK_FLUSH roda)
TASK_QUEUE = {}
task = {
    spawn = function(f, ...) f(...) end,
    defer = function(f, ...) f(...) end,
    delay = function(t, f, ...) table.insert(TASK_QUEUE, { t = t, f = f, args = { ... } }) end,
    wait = function() return 0 end,
}
function TASK_FLUSH()
    local q = TASK_QUEUE
    TASK_QUEUE = {}
    for _, j in ipairs(q) do j.f(table.unpack(j.args)) end
    return #q
end

--------------------------------------------------------------------------------
-- disco do executor, com queda simulada
--   FS.crashAt = n  -> a n-ésima gravação (writefile/delfile) daqui em diante
--                      "derruba o jogo": grava só parte (FS.crashMode) e, a
--                      partir dali, o disco congela (nada mais muda), como se
--                      o processo tivesse morrido
--   FS.crashMode    -> "half" (metade do texto) | "empty" (0 bytes) | "after"
--                      (gravou tudo e caiu logo depois)
--------------------------------------------------------------------------------
FS = { files = {}, ops = 0, crashAt = nil, crashMode = "half", dead = false, log = {} }
local function op(kind, p)
    FS.ops = FS.ops + 1
    table.insert(FS.log, kind .. " " .. p)
    if FS.dead then error("disco congelado (processo morto)") end
    return FS.crashAt ~= nil and FS.ops >= FS.crashAt
end
function writefile(p, s)
    assert(type(s) == "string", "writefile sem texto")
    if op("write", p) then
        if FS.crashMode == "half" then FS.files[p] = s:sub(1, math.floor(#s / 2))
        elseif FS.crashMode == "empty" then FS.files[p] = ""
        else FS.files[p] = s end
        FS.dead = true
        error("queda simulada em writefile(" .. p .. ")")
    end
    FS.files[p] = s
end
function delfile(p)
    if op("del", p) then FS.dead = true error("queda simulada em delfile(" .. p .. ")") end
    FS.files[p] = nil
end
function readfile(p)
    if FS.files[p] == nil then error("arquivo não existe: " .. p) end
    return FS.files[p]
end
function isfile(p) return FS.files[p] ~= nil end
function isfolder() return true end
function makefolder() end
function FS_REBOOT()   -- "abre o jogo de novo": o disco volta a funcionar
    FS.crashAt, FS.dead, FS.ops = nil, false, 0
end

--------------------------------------------------------------------------------
-- JSON (o HttpService:JSONEncode/JSONDecode dos testes)
--------------------------------------------------------------------------------
JSON = {}
do
    local function esc(s)
        return (s:gsub('[%c"\\]', function(c)
            local map = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
            return map[c] or string.format("\\u%04x", c:byte())
        end))
    end
    local function isArray(t)
        local n = 0
        for k in pairs(t) do
            if math.type(k) ~= "integer" or k < 1 then return false end
            n = n + 1
        end
        return n == #t
    end
    function JSON.encode(v)
        local t = type(v)
        if t == "nil" then return "null" end
        if t == "boolean" then return tostring(v) end
        if t == "number" then
            if v ~= v or v == math.huge or v == -math.huge then error("número inválido no JSON") end
            if math.type(v) == "integer" then return tostring(v) end
            if v == math.floor(v) and math.abs(v) < 2^53 then return string.format("%d", v) end
            return string.format("%.17g", v)
        end
        if t == "string" then return '"' .. esc(v) .. '"' end
        if t == "table" then
            local out = {}
            if next(v) == nil then return "[]" end
            if isArray(v) then
                for i = 1, #v do out[i] = JSON.encode(v[i]) end
                return "[" .. table.concat(out, ",") .. "]"
            end
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = tostring(k) end
            table.sort(keys)
            for _, k in ipairs(keys) do
                local val = v[k]
                if val == nil then val = v[tonumber(k)] end
                out[#out + 1] = '"' .. esc(k) .. '":' .. JSON.encode(val)
            end
            return "{" .. table.concat(out, ",") .. "}"
        end
        error("tipo sem JSON: " .. t)
    end
    function JSON.decode(s)
        local i = 1
        local function ws() i = s:find("[^ \t\r\n]", i) or (#s + 1) end
        local val
        local function str()
            local out = {}
            i = i + 1
            while true do
                local c = s:sub(i, i)
                if c == "" then error("JSON: string sem fim") end
                if c == '"' then i = i + 1 break end
                if c == "\\" then
                    local e = s:sub(i + 1, i + 1)
                    local map = { n = "\n", r = "\r", t = "\t", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
                    if e == "u" then
                        out[#out + 1] = utf8.char(tonumber(s:sub(i + 2, i + 5), 16))
                        i = i + 6
                    else
                        out[#out + 1] = map[e] or error("JSON: escape inválido")
                        i = i + 2
                    end
                else
                    out[#out + 1] = c
                    i = i + 1
                end
            end
            return table.concat(out)
        end
        function val()
            ws()
            local c = s:sub(i, i)
            if c == "{" then
                local t = {}
                i = i + 1 ws()
                if s:sub(i, i) == "}" then i = i + 1 return t end
                while true do
                    ws()
                    if s:sub(i, i) ~= '"' then error("JSON: chave esperada") end
                    local k = str()
                    ws()
                    if s:sub(i, i) ~= ":" then error("JSON: ':' esperado") end
                    i = i + 1
                    t[k] = val()
                    ws()
                    local d = s:sub(i, i)
                    i = i + 1
                    if d == "}" then return t end
                    if d ~= "," then error("JSON: ',' ou '}' esperado") end
                end
            elseif c == "[" then
                local t = {}
                i = i + 1 ws()
                if s:sub(i, i) == "]" then i = i + 1 return t end
                while true do
                    t[#t + 1] = val()
                    ws()
                    local d = s:sub(i, i)
                    i = i + 1
                    if d == "]" then return t end
                    if d ~= "," then error("JSON: ',' ou ']' esperado") end
                end
            elseif c == '"' then return str()
            elseif s:sub(i, i + 3) == "true" then i = i + 4 return true
            elseif s:sub(i, i + 4) == "false" then i = i + 5 return false
            elseif s:sub(i, i + 3) == "null" then i = i + 4 return nil
            else
                local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
                if not num or num == "" then error("JSON: valor inválido na posição " .. i) end
                i = i + #num
                return math.tointeger(tonumber(num)) or tonumber(num)
            end
        end
        local r = val()
        ws()
        if i <= #s then error("JSON: lixo depois do fim") end
        return r
    end
end

HttpService = {
    JSONEncode = function(_, v) return JSON.encode(v) end,
    JSONDecode = function(_, s) return JSON.decode(s) end,
    UrlEncode = function(_, s) return s end,
}

-- game:GetService / game:HttpGet (a rede é trocada por cada teste em NET)
NET = {}   -- [url sem ?t=] = corpo  |  NET[url] = false -> erro de rede
SERVICES = { HttpService = HttpService }
game = setmetatable({
    PlaceId = 123,
    JobId = "",
    GetService = function(_, name)
        return SERVICES[name] or error("serviço não imitado: " .. tostring(name))
    end,
    HttpGet = function(_, url)
        local base = url:gsub("[?&]t=%d+$", "")
        local body = NET[base]
        if body == nil or body == false then error("HTTP 404 (" .. base .. ")") end
        return body
    end,
}, { __type = "Instance" })

-- sandbox de getgenv
GENV = {}
getgenv = function() return GENV end
