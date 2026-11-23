-- =============================================================================
-- HYGE loader — cole ESTE arquivo no executor no lugar do main.lua.
--
-- Toda vez que roda, baixa o main.lua mais novo do GitHub, guarda uma cópia em
-- HYGE/main.lua (pasta do executor) e abre o painel. Sem internet (ou com o
-- GitHub fora do ar), abre a última cópia guardada.
-- Ele também conta ao painel qual build abriu: assim Configurações ›
-- Atualização sabe na hora quando sai uma versão nova.
--
-- Precisa de: game:HttpGet ou request(), e loadstring. writefile/readfile são
-- opcionais (só para a cópia offline).
-- =============================================================================
local URL   = "https://raw.githubusercontent.com/MarcosLueD/HYGE/main/main.lua"
local CACHE = "HYGE/main.lua"

local function Get(url)
    local req = (typeof(request) == "function" and request)
        or (typeof(http_request) == "function" and http_request)
        or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
    if req then
        local res = req({ Url = url, Method = "GET" })
        if type(res) == "table" and tonumber(res.StatusCode) == 200 then return res.Body end
        error("HTTP " .. tostring(type(res) == "table" and res.StatusCode or "?"))
    end
    return game:HttpGet(url)
end

local function Valid(s)
    return type(s) == "string" and #s > 1000 and s:find("-- build:", 1, true) ~= nil
end

local src, from
local ok, body = pcall(Get, URL .. "?t=" .. tostring(os.time()))
if ok and Valid(body) then
    src, from = body, "GitHub"
    pcall(function()
        if typeof(makefolder) == "function" then
            local has = typeof(isfolder) == "function" and isfolder("HYGE")
            if not has then makefolder("HYGE") end
        end
        if typeof(writefile) == "function" then writefile(CACHE, body) end
    end)
else
    warn("[HYGE loader] não deu para baixar (" .. tostring(body) .. ") — tentando a cópia local")
    pcall(function()
        if typeof(isfile) == "function" and isfile(CACHE) then
            local cached = readfile(CACHE)
            if Valid(cached) then src, from = cached, "cópia local" end
        end
    end)
end
if not src then
    error("[HYGE loader] não consegui baixar o painel nem achar a cópia em " .. CACHE)
end

local build = src:match("%-%- build: (%x+)")
local env = (typeof(getgenv) == "function" and getgenv()) or _G
env.HYGE_LOADER = { url = URL, build = build, from = from }

local fn, err = loadstring(src, "=HYGE")
if not fn then error("[HYGE loader] o main.lua não compila: " .. tostring(err)) end
print("[HYGE loader] build " .. tostring(build) .. " (" .. from .. ")")
fn()
