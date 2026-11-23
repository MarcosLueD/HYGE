--------------------------------------------------------------------------------
-- v8.2 — ATUALIZAÇÃO (Configurações › Ajustes › Atualização)
-- Confere se existe um main.lua mais novo no endereço de atualização:
--   * aberto pelo loader.lua: o loader conta qual build ele rodou
--     (getgenv().HYGE_LOADER = { url, build }) e a comparação é pelo build
--     exato — qualquer mudança publicada conta
--   * colado direto: compara CONFIG.Version com o Version do arquivo novo
--     (só avisa se o de lá for MAIOR)
-- Achou: avisa (toast + log + este cartão). ATUALIZAR AGORA baixa, confere se
-- compila, descarrega este painel e roda o novo — sem sair do jogo.
-- Precisa de HTTP no executor (request ou game:HttpGet) e, para atualizar sem
-- sair, de loadstring. Nada é baixado sem a opção ligada ou o botão.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Update = { state = "idle", msg = "", notified = {} }
        local U = V8.Update
        if SET.UpdateCheck == nil then SET.UpdateCheck = true end

        -- tabela global do executor (compartilhada entre scripts)
        local function Env()
            if typeof(getgenv) == "function" then
                local ok, g = pcall(getgenv)
                if ok and type(g) == "table" then return g end
            end
            return _G
        end
        -- lido e apagado: se depois alguém colar o main.lua direto no mesmo
        -- jogo, essa instância não herda o build de um loader antigo
        pcall(function()
            local env = Env()
            local L = env.HYGE_LOADER
            U.Loader = (type(L) == "table") and L or nil
            env.HYGE_LOADER = nil
        end)
        U.MyBuild = U.Loader and tostring(U.Loader.build or "") or ""

        U.Url = function()
            local L = U.Loader
            if L and type(L.url) == "string" and L.url ~= "" then return L.url end
            return tostring(CONFIG.UpdateUrl or "")
        end

        -- "v8.1.2" -> { 8, 1, 2 }
        local function Ver(s)
            local t = {}
            for n in tostring(s or ""):gmatch("%d+") do table.insert(t, tonumber(n)) end
            return t
        end
        local function Greater(a, b)
            local x, y = Ver(a), Ver(b)
            for i = 1, math.max(#x, #y) do
                local p, q = x[i] or 0, y[i] or 0
                if p ~= q then return p > q end
            end
            return false
        end

        -- baixa o main.lua de lá: { src, version, build } ou nil + motivo
        U.Fetch = function()
            local url = U.Url()
            if url == "" then return nil, "sem endereço de atualização (CONFIG.UpdateUrl)" end
            if not (V8.Net and V8.Net.Request) then return nil, "sem HTTP" end
            local sep = url:find("?", 1, true) and "&" or "?"
            local ok, body, code = V8.Net.Request("GET", url .. sep .. "t=" .. os.time())
            if not ok then
                return nil, (code and code > 0) and ("HTTP " .. code) or tostring(body)
            end
            if type(body) ~= "string" or #body < 1000 or not body:find("-- build:", 1, true) then
                return nil, "o arquivo baixado não é o main.lua do painel"
            end
            return {
                src = body,
                version = body:match('Version%s*=%s*"([^"]+)"'),
                build = body:match("%-%- build: (%x+)"),
            }
        end

        U.IsNewer = function(info)
            if U.MyBuild ~= "" and info.build then return info.build ~= U.MyBuild end
            return info.version ~= nil and Greater(info.version, CONFIG.Version)
        end

        U.Check = function(manual)
            if U.state == "checking" then return end
            U.state, U.msg = "checking", "Conferindo..."
            if U.Render then pcall(U.Render) end
            task.spawn(function()
                local info, why = U.Fetch()
                if not info then
                    U.state, U.msg = "error", "Não deu para conferir: " .. tostring(why)
                    if manual then
                        Log("Atualização: " .. tostring(why), "error")
                        Toast("Não deu para conferir a atualização", "error", 3)
                    end
                elseif U.IsNewer(info) then
                    U.state, U.info = "new", info
                    U.msg = "Versão nova disponível: " .. tostring(info.version or "?")
                        .. (info.build and ("  (build " .. info.build .. ")") or "")
                    local key = tostring(info.build or info.version)
                    if manual or not U.notified[key] then
                        U.notified[key] = true
                        Log("Atualização disponível: HYGE " .. tostring(info.version or "?")
                            .. " — Configurações › Ajustes › Atualização", "ok")
                        Toast("HYGE " .. tostring(info.version or "novo")
                            .. " disponível (Ajustes › Atualização)", "ok", 5)
                    end
                else
                    U.state, U.info = "ok", info
                    U.msg = "Você está na versão mais nova."
                    if manual then
                        Log("Atualização: você já está na versão mais nova", "ok")
                        Toast("Já está na versão mais nova", "ok", 2)
                    end
                end
                U.checked = os.date("%H:%M")
                if U.Render then pcall(U.Render) end
            end)
        end

        U.Apply = function()
            if typeof(loadstring) ~= "function" then
                Log("Este executor não tem loadstring: baixe o main.lua novo e rode no executor "
                    .. "(ou use o loader.lua, que sempre abre a versão nova)", "error")
                Toast("Executor sem loadstring", "error", 3)
                return
            end
            if U.state == "applying" then return end
            U.state, U.msg = "applying", "Baixando a versão nova..."
            if U.Render then pcall(U.Render) end
            task.spawn(function()
                local info, why = U.Fetch()
                if not info then
                    U.state, U.msg = "error", "Não deu para baixar: " .. tostring(why)
                    Log("Atualização: " .. tostring(why), "error")
                    if U.Render then pcall(U.Render) end
                    return
                end
                local fn, err = loadstring(info.src, "=HYGE")
                if not fn then
                    U.state, U.msg = "error", "O arquivo novo não compila"
                    Log("O main.lua baixado não compila (nada foi trocado): " .. tostring(err), "error")
                    if U.Render then pcall(U.Render) end
                    return
                end
                -- o painel novo fica sabendo de onde veio e qual build é
                pcall(function()
                    local env = Env()
                    env.HYGE_LOADER = { url = U.Url(), build = info.build, from = "atualização" }
                end)
                Log("Atualizando para HYGE " .. tostring(info.version or "?") .. "...", "action")
                Toast("Atualizando o HYGE...", "ok", 2)
                task.wait(0.4)
                pcall(Unload)
                task.defer(function()
                    local ok, e = pcall(fn)
                    if not ok then warn("[HYGE] a versão nova falhou ao iniciar: " .. tostring(e)) end
                end)
            end)
        end

        -- a cada 15 min (o primeiro disparo do scheduler é ignorado: quem
        -- confere ao abrir é o U.Boot, depois da config carregada)
        V8.Job(900, function()
            if U.booted and SET.UpdateCheck then U.Check(false) end
        end)

        U.Boot = function()
            U.booted = true
            if SET.UpdateCheck and U.Url() ~= "" then
                task.delay(6, function() U.Check(false) end)
            end
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Atualização
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "ATUALIZAÇÃO", 13)
        local infoLbl = SubLabel(card, "", 0)
        local status = SubLabel(card, "", 1)

        local g = Grid(card, 2, 32)
        g.LayoutOrder = 2
        local bCheck = CreateButton(g, "VERIFICAR AGORA", "Accent", 32)
        bCheck.LayoutOrder = 1
        bCheck.MouseButton1Click:Connect(function() U.Check(true) end)
        local bApply = CreateButton(g, "ATUALIZAR AGORA", "Success", 32)
        bApply.LayoutOrder = 2
        bApply.MouseButton1Click:Connect(function()
            Confirm("Baixar a versão nova e reabrir o painel agora? (o que estiver "
                .. "ligado é desligado; a config é salva antes)", U.Apply)
        end)

        CheckRow(card, "Conferir sozinho",
            "Ao abrir o painel e a cada 15 minutos (só avisa, não troca nada)",
            function() return SET.UpdateCheck == true end,
            function(v) SET.UpdateCheck = v and true or false end, 3)

        SubLabel(card, "Para abrir sempre a versão mais nova: rode o loader.lua do "
            .. "repositório no executor em vez do main.lua. Ele baixa do GitHub, guarda uma "
            .. "cópia em HYGE/main.lua e usa a cópia se estiver sem internet.", 4)

        U.Render = function()
            local how = U.Loader and ("aberto pelo loader" .. (U.MyBuild ~= ""
                and (", build " .. U.MyBuild) or "")) or "colado direto (sem loader)"
            infoLbl.Text = "Versão atual: " .. CONFIG.Version .. "  ·  " .. how
                .. "\nEndereço: " .. (U.Url() ~= "" and U.Url() or "nenhum")
            status.Text = (U.msg ~= "" and U.msg or "Ainda não conferido.")
                .. (U.checked and ("  (às " .. U.checked .. ")") or "")
            local key = (U.state == "new") and "Success"
                or (U.state == "error") and "Danger" or "Dim"
            status.TextColor3 = THEME[key]
            bApply.Text = (U.state == "new") and "ATUALIZAR AGORA" or "REINSTALAR AGORA"
        end
        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(U.Render) end)
        U.Render()
    end
    Build()
end
