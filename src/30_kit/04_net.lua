--------------------------------------------------------------------------------
-- v8.1 — REDE E DISCO (helpers do executor)
--
-- O Roblox não deixa LocalScript fazer HTTP. Executores expõem request()
-- (ou http_request / syn.request / http.request) e game:HttpGet. Tudo aqui é
-- testado antes de usar: sem suporte, quem chama recebe nil + o motivo — nunca
-- uma resposta inventada. Usado pela troca de servidor (Início) e pelo chat
-- HYGE (Chat › HYGE).
-- V8.Disk lê/grava arquivos pequenos na pasta do executor (playtime da loja).
-- Tudo em V8.Net / V8.Disk: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    V8.Net = {}
    V8.Disk = {}
    local N, D = V8.Net, V8.Disk

    N.Http = nil
    pcall(function() N.Http = game:GetService("HttpService") end)

    -- a função request do executor (a primeira que existir), ou nil
    N.Fn = function()
        if typeof(request) == "function" then return request end
        if typeof(http_request) == "function" then return http_request end
        if typeof(syn) == "table" and typeof(syn.request) == "function" then return syn.request end
        if typeof(http) == "table" and typeof(http.request) == "function" then return http.request end
        return nil
    end

    N.CanPost = function() return N.Fn() ~= nil end

    N.Encode = function(s)
        local ok, r = pcall(function() return N.Http:UrlEncode(tostring(s)) end)
        if ok and type(r) == "string" then return r end
        return (tostring(s):gsub("[^%w%-_%.~]", function(c)
            return string.format("%%%02X", string.byte(c))
        end))
    end

    -- devolve ok, corpo (ou o erro), status
    N.Request = function(method, url, body, headers)
        local fn = N.Fn()
        if fn then
            local ok, res = pcall(fn, { Url = url, Method = method,
                Headers = headers or {}, Body = body })
            if not ok then return false, tostring(res), 0 end
            if type(res) ~= "table" then return false, "resposta vazia do executor", 0 end
            local code = tonumber(res.StatusCode) or 0
            local good = (code >= 200 and code < 300) or (code == 0 and res.Success == true)
            return good, tostring(res.Body or ""), code
        end
        if method == "GET" then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" then return true, res, 200 end
            return false, "executor sem HTTP (nem request() nem game:HttpGet)", 0
        end
        return false, "executor sem request(): só dá para ler, não para enviar", 0
    end

    -- JSON de ida e volta. Devolve a tabela ou nil + motivo
    N.Json = function(method, url, tbl)
        if not N.Http then return nil, "HttpService indisponível" end
        local body, headers
        if tbl ~= nil then
            local ok, enc = pcall(function() return N.Http:JSONEncode(tbl) end)
            if not ok then return nil, "JSON: " .. tostring(enc) end
            body = enc
            headers = { ["Content-Type"] = "application/json" }
        end
        local ok, res, code = N.Request(method, url, body, headers)
        if not ok then
            local why = tostring(res)
            if #why > 120 then why = why:sub(1, 120) .. "…" end
            return nil, (code and code > 0 and ("HTTP " .. code .. ": ") or "") .. why
        end
        local okD, data = pcall(function() return N.Http:JSONDecode(res) end)
        if not okD or type(data) ~= "table" then return nil, "a resposta não é JSON" end
        return data
    end

    ----------------------------------------------------------------------------
    -- disco
    ----------------------------------------------------------------------------
    D.Ok = function()
        return typeof(writefile) == "function" and typeof(readfile) == "function"
            and typeof(isfile) == "function"
    end

    D.Read = function(path)
        if not D.Ok() then return nil, "executor sem readfile" end
        local exists = false
        pcall(function() exists = isfile(path) end)
        if not exists then return nil, "arquivo não existe" end
        local ok, raw = pcall(function() return readfile(path) end)
        if ok and type(raw) == "string" then return raw end
        return nil, "falha ao ler " .. path
    end

    D.Write = function(path, text)
        if not D.Ok() then return false, "executor sem writefile" end
        local ok, err = pcall(function()
            local folder = path:match("^(.+)/[^/]+$")
            if folder and typeof(makefolder) == "function" then
                local has = false
                if typeof(isfolder) == "function" then
                    pcall(function() has = isfolder(folder) end)
                end
                if not has then pcall(function() makefolder(folder) end) end
            end
            writefile(path, text)
        end)
        if ok then return true end
        return false, tostring(err)
    end
end
