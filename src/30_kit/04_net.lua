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

    D.Exists = function(path)
        if not D.Ok() then return false end
        local ok, has = pcall(function() return isfile(path) end)
        return ok and has == true
    end

    -- sem delfile no executor, o arquivo fica (quem lê sabe lidar)
    D.Delete = function(path)
        if typeof(delfile) ~= "function" then return false end
        return (pcall(function() delfile(path) end))
    end

    ----------------------------------------------------------------------------
    -- v9.1 — GRAVAÇÃO SEGURA (config.json, profiles.json)
    -- Executor não tem "renomear", então não dá para trocar o arquivo de forma
    -- atômica. A estratégia é nunca ficar sem uma cópia boa:
    --   1. a versão nova vai inteira para <nome>.tmp e é conferida (relida)
    --   2. a versão atual, SE for válida, vira <nome>.backup.json (conferida);
    --      um principal estragado nunca apaga um backup bom
    --   3. a versão nova vai para o principal (conferida)
    --   4. o .tmp é apagado
    -- Caiu no meio? Sempre sobra o principal válido, ou o .tmp (a nova
    -- completa), ou o backup (a anterior). D.SafeRead acha qual.
    -- check(text) diz se o conteúdo é válido (ex.: decodifica o JSON).
    ----------------------------------------------------------------------------
    D.Paths = function(path)
        local base = path:gsub("%.json$", "")
        return base .. ".backup.json", base .. ".tmp", base .. ".corrupt.json"
    end

    local function Valid(text, check)
        if type(text) ~= "string" or text == "" then return false end
        if not check then return true end
        local ok, good = pcall(check, text)
        return ok and good == true
    end

    -- releu igual? (ou, se o executor mexer em algo, continua válido e inteiro)
    local function Verify(path, text, check)
        local back = D.Read(path)
        if back == text then return true end
        return check ~= nil and back ~= nil and #back >= #text and Valid(back, check)
    end

    D.SafeWrite = function(path, text, check)
        if not D.Ok() then return false, "executor sem writefile" end
        if not Valid(text, check) then return false, "conteúdo inválido (nada foi gravado)" end
        local bak, tmp, bad = D.Paths(path)

        local ok, err = D.Write(tmp, text)
        if not ok or not Verify(tmp, text, check) then
            D.Delete(tmp)
            return false, "não deu para gravar o temporário (" .. tostring(err or "conferência falhou")
                .. ") — nada foi trocado"
        end

        local cur = D.Exists(path) and D.Read(path) or nil
        if cur ~= nil and cur ~= text then
            if Valid(cur, check) then
                local okB = D.Write(bak, cur)
                if not okB or not Verify(bak, cur, check) then
                    D.Delete(tmp)
                    return false, "não deu para criar o backup — nada foi trocado"
                end
            elseif cur ~= "" then
                -- o principal já estava estragado: guarda para análise, não
                -- vira backup (o backup bom que existir continua lá)
                D.Write(bad, cur)
            end
        end

        local okM, errM = D.Write(path, text)
        if not okM or not Verify(path, text, check) then
            return false, "falhou ao gravar " .. path .. " (" .. tostring(errM or "conferência falhou")
                .. ") — a versão nova ficou em " .. tmp .. " e a anterior em " .. bak
        end
        D.Delete(tmp)
        return true
    end

    -- Lê o principal e diz o que sobrou para recuperar.
    -- Devolve { state = "ok"|"missing"|"corrupt", text = principal válido,
    --           raw = principal como veio, recover = { {path, text, label} } }
    -- recover só vem preenchido quando o principal não presta: o .tmp primeiro
    -- (versão nova que não terminou de ir para o principal), depois o backup.
    D.SafeRead = function(path, check)
        local r = { state = "missing", recover = {} }
        if not D.Ok() then return r end
        local bak, tmp = D.Paths(path)
        if D.Exists(path) then
            r.raw = D.Read(path)
            if Valid(r.raw, check) then
                r.state, r.text = "ok", r.raw
                -- .tmp que sobrou de uma gravação que terminou (ou executor
                -- sem delfile): não serve para nada
                if D.Exists(tmp) then D.Delete(tmp) end
                return r
            end
            r.state = "corrupt"
        end
        for _, c in ipairs({ { tmp, "gravação interrompida (mais nova)" }, { bak, "backup (anterior)" } }) do
            local s = D.Exists(c[1]) and D.Read(c[1]) or nil
            if Valid(s, check) and s ~= r.raw then
                table.insert(r.recover, { path = c[1], text = s, label = c[2] })
            end
        end
        return r
    end

    -- troca o principal pela cópia escolhida (o SafeWrite guarda o estragado
    -- em .corrupt.json antes)
    D.Recover = function(path, text, check)
        if not Valid(text, check) then return false, "a cópia escolhida não é válida" end
        return D.SafeWrite(path, text, check)
    end
end
