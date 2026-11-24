-- =============================================================================
-- HYGE loader (v9.1) — cole ESTE arquivo no executor no lugar do main.lua.
--
-- Toda vez que roda:
--   1. lê o manifest.json do GitHub (versão, build, tamanho e SHA-256)
--   2. se a cópia local (HYGE/main.lua) já é esse build, abre ela — nada a baixar
--   3. senão baixa o main.lua e CONFERE: tamanho, SHA-256, build e se compila
--   4. só então a cópia anterior vira HYGE/main.backup.lua e a nova é guardada
--   5. qualquer passo falhou (sem internet, download cortado, arquivo
--      adulterado, build quebrado): abre a última versão que funcionava
--      (HYGE/main.lua e, se ela também não servir, HYGE/main.backup.lua)
-- O SHA-256 é calculado aqui mesmo (Lua puro): não depende do executor.
-- Ele também conta ao painel qual build abriu: assim Configurações ›
-- Atualização sabe na hora quando sai uma versão nova.
--
-- Precisa de: game:HttpGet ou request(), e loadstring. writefile/readfile são
-- opcionais (só para a cópia offline e o backup).
-- =============================================================================
local BASE    = "https://raw.githubusercontent.com/MarcosLueD/HYGE/main/"
local URL     = BASE .. "main.lua"
local MAN_URL = BASE .. "manifest.json"
local DIR     = "HYGE"
local CACHE, CACHE_MAN   = DIR .. "/main.lua", DIR .. "/manifest.json"
local BACKUP, BACKUP_MAN = DIR .. "/main.backup.lua", DIR .. "/manifest.backup.json"
-- [sha256:begin]
local Sha256
do
    local band, bxor, bnot = bit32.band, bit32.bxor, bit32.bnot
    local rrotate, rshift = bit32.rrotate, bit32.rshift
    local byte, char, rep, fmt = string.byte, string.char, string.rep, string.format
    local MOD = 4294967296
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }
    local function be32(n)
        return char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
    end
    -- hex minúsculo do SHA-256 dos bytes de msg
    Sha256 = function(msg)
        local len = #msg
        local hi = math.floor(len * 8 / MOD)
        local lo = len * 8 - hi * MOD
        msg = msg .. "\128" .. rep("\0", (55 - len) % 64) .. be32(hi) .. be32(lo)
        local H1, H2, H3, H4 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
        local H5, H6, H7, H8 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        local w = {}
        for i = 1, #msg, 64 do
            for j = 1, 16 do
                local p = i + (j - 1) * 4
                local a, b, c, d = byte(msg, p, p + 3)
                w[j] = ((a * 256 + b) * 256 + c) * 256 + d
            end
            for j = 17, 64 do
                local x, y = w[j - 15], w[j - 2]
                local s0 = bxor(rrotate(x, 7), rrotate(x, 18), rshift(x, 3))
                local s1 = bxor(rrotate(y, 17), rrotate(y, 19), rshift(y, 10))
                w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % MOD
            end
            local a, b, c, d, e, f, g, h = H1, H2, H3, H4, H5, H6, H7, H8
            for j = 1, 64 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = (h + S1 + ch + K[j] + w[j]) % MOD
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                h, g, f, e = g, f, e, (d + t1) % MOD
                d, c, b, a = c, b, a, (t1 + S0 + maj) % MOD
            end
            H1, H2, H3, H4 = (H1 + a) % MOD, (H2 + b) % MOD, (H3 + c) % MOD, (H4 + d) % MOD
            H5, H6, H7, H8 = (H5 + e) % MOD, (H6 + f) % MOD, (H7 + g) % MOD, (H8 + h) % MOD
        end
        -- em metades de 16 bits: "%08x" com número >= 2^31 quebra em Lua de
        -- inteiro 32 bits (e assim o mesmo código roda em qualquer Lua)
        local out = {}
        for i, v in ipairs({ H1, H2, H3, H4, H5, H6, H7, H8 }) do
            out[i] = fmt("%04x%04x", math.floor(v / 65536), v % 65536)
        end
        return table.concat(out)
    end
end
-- [sha256:end]

local Http = game:GetService("HttpService")
local function Fn(f) return typeof(f) == "function" end

local function Get(url)
    local req = (Fn(request) and request) or (Fn(http_request) and http_request)
        or (typeof(syn) == "table" and Fn(syn.request) and syn.request)
    if req then
        local res = req({ Url = url, Method = "GET" })
        if type(res) == "table" and tonumber(res.StatusCode) == 200 then return res.Body end
        error("HTTP " .. tostring(type(res) == "table" and res.StatusCode or "?"))
    end
    return game:HttpGet(url)
end

local function Fetch(url)
    local ok, body = pcall(Get, url .. "?t=" .. tostring(os.time()))
    if ok and type(body) == "string" and body ~= "" then return body end
    return nil, ok and "resposta vazia" or tostring(body)
end

local function Json(s)
    if type(s) ~= "string" then return nil end
    local ok, d = pcall(function() return Http:JSONDecode(s) end)
    if ok and type(d) == "table" then return d end
    return nil
end

-- disco (tudo opcional: sem as funções, só não há cópia offline)
local function Read(p)
    if not (Fn(isfile) and Fn(readfile)) then return nil end
    local ok, s = pcall(function() if isfile(p) then return readfile(p) end end)
    if ok and type(s) == "string" then return s end
    return nil
end
local function Write(p, s)
    if not Fn(writefile) then return false end
    local ok = pcall(function()
        if Fn(makefolder) and not (Fn(isfolder) and isfolder(DIR)) then makefolder(DIR) end
        writefile(p, s)
    end)
    return ok and Read(p) == s
end

-- confere um main.lua contra o manifesto. Devolve a função compilada ou
-- nil + motivo. O hash é do texto com quebras LF (o GitHub serve LF).
local function Verify(src, man)
    if type(src) ~= "string" or #src == 0 then return nil, "arquivo vazio" end
    if type(man) ~= "table" or type(man.sha256) ~= "string" or type(man.size) ~= "number" then
        return nil, "manifesto inválido"
    end
    local lf = src:gsub("\r\n", "\n")
    if #lf ~= man.size then
        return nil, "incompleto (" .. #lf .. " de " .. tostring(man.size) .. " bytes)"
    end
    if Sha256(lf) ~= man.sha256:lower() then return nil, "SHA-256 não confere" end
    local build = src:match("%-%- build: (%x+)")
    if man.build and build ~= man.build then return nil, "build diferente do manifesto" end
    local fn, err = loadstring(src, "=HYGE")
    if not fn then return nil, "não compila: " .. tostring(err) end
    return fn
end

-- cópia local: com manifesto, conferida; cópia de um loader antigo (sem
-- manifesto) só precisa ser o main.lua do painel e compilar
local function Usable(src, man)
    if man then return Verify(src, man) end
    if type(src) ~= "string" or not src:find("-- build:", 1, true) then return nil, "não é o main.lua do HYGE" end
    local fn, err = loadstring(src, "=HYGE")
    if not fn then return nil, "não compila: " .. tostring(err) end
    return fn
end

local src, fn, from, man
local why = {}

-- 1) o manifesto diz qual é o build mais novo
local remote
do
    local body, err = Fetch(MAN_URL)
    remote = Json(body)
    if not remote then table.insert(why, "manifesto: " .. tostring(err or "ilegível")) end
end

-- 2) a cópia local já é esse build? Então não precisa baixar nada
local cached, cachedMan = Read(CACHE), Json(Read(CACHE_MAN))
if remote and cached and cachedMan and cachedMan.sha256 == remote.sha256 then
    local f = Verify(cached, remote)
    if f then src, fn, from, man = cached, f, "cópia local, já é a mais nova", remote end
end

-- 3) baixa e confere ANTES de mexer em qualquer arquivo
if not fn and remote then
    local body, err = Fetch(URL)
    local f, bad
    if body then f, bad = Verify(body, remote) else bad = tostring(err) end
    if not f then
        table.insert(why, "download recusado: " .. bad)
    else
        src, fn, from, man = body, f, "GitHub", remote
        -- a versão que funcionava vira backup (só se ela for boa mesmo)
        if cached and cached ~= body and Usable(cached, cachedMan) then
            Write(BACKUP, cached)
            if cachedMan then Write(BACKUP_MAN, Http:JSONEncode(cachedMan)) end
        end
        -- o main.lua antes do manifesto: gravação cortada no meio = a cópia não
        -- confere na próxima vez e o backup é usado
        if not (Write(CACHE, body) and Write(CACHE_MAN, Http:JSONEncode(remote))) then
            warn("[HYGE loader] não deu para guardar a cópia local (segue com o download)")
        end
    end
end

-- 4) sem download bom: a última versão que funcionava
if not fn then
    for _, c in ipairs({ { CACHE, CACHE_MAN, "cópia local" }, { BACKUP, BACKUP_MAN, "backup local" } }) do
        local s = Read(c[1])
        if s then
            local m = Json(Read(c[2]))
            local f, bad = Usable(s, m)
            if f then
                src, fn, man = s, f, m
                from = c[3] .. (m and "" or ", sem manifesto: não conferida")
                break
            end
            table.insert(why, c[3] .. ": " .. tostring(bad))
        end
    end
    if fn then warn("[HYGE loader] abrindo a " .. from .. " — " .. table.concat(why, "; ")) end
end
if not fn then
    error("[HYGE loader] nada para abrir: " .. table.concat(why, "; "))
end

local build = src:match("%-%- build: (%x+)")
local env = (Fn(getgenv) and getgenv()) or _G
env.HYGE_LOADER = { url = URL, manifest = MAN_URL, build = build, from = from,
                    sha256 = man and man.sha256 or nil, verified = man ~= nil }
print("[HYGE loader] build " .. tostring(build) .. " (" .. from .. ")")
fn()