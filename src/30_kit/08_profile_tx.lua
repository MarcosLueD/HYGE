--------------------------------------------------------------------------------
-- v9.1 — TROCA SEGURA DE PERFIL (usado por 50_v8/10_profiles.lua)
-- Um perfil nunca deixa o painel pela metade:
--   1. VALIDA tudo antes de mexer em qualquer coisa (tipos, números finitos,
--      faixas). Inválido = nada muda.
--   2. copia o estado atual
--   3. aplica as PREFERÊNCIAS (aparência, teclas, ajustes, velocidades) e
--      confere se terminou certo. Deu erro no meio = volta para a cópia.
--   4. só então liga/desliga as FUNÇÕES (as que mexem no personagem). Freecam
--      e Drone nunca ligam sozinhos. Função que não ligou (ex.: sem
--      personagem) não desfaz as preferências: vai para o relatório.
-- Sem UI aqui: tests/profiles.test.js roda este arquivo de verdade.
--------------------------------------------------------------------------------
do
    V8.ProfTx = {}
    local T = V8.ProfTx

    local function finite(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
    local SPEED_MAX = 100000

    -- ctx = { setKeys = {k=true}, toggles = {id=true}, noauto = {id=true},
    --         themes = {nome=true}, keyOk = function(nome) -> bool }
    -- devolve ok, erros, avisos (avisos não impedem: o item é ignorado)
    T.Validate = function(d, ctx)
        local errs, warns = {}, {}
        local function E(s) table.insert(errs, s) end
        local function W(s) table.insert(warns, s) end
        if type(d) ~= "table" then return false, { "o perfil não tem dados" }, warns end
        ctx = ctx or {}
        local keyOk = ctx.keyOk or function() return true end

        if type(d.set) ~= "table" then E("faltam os ajustes (set)") end
        if d.on ~= nil and type(d.on) ~= "table" then E("lista de funções (on) inválida") end

        if type(d.set) == "table" then
            for k, v in pairs(d.set) do
                local t = type(v)
                if type(k) ~= "string" then
                    E("ajuste com nome inválido")
                elseif t == "number" and not finite(v) then
                    E("ajuste " .. k .. " não é um número válido")
                elseif t ~= "boolean" and t ~= "number" and t ~= "string" and t ~= "table" then
                    E("ajuste " .. k .. " tem tipo " .. t)
                elseif ctx.setKeys and not ctx.setKeys[k] then
                    W("ajuste desconhecido " .. k .. " (ignorado)")
                end
            end
        end
        for _, k in ipairs({ "esp", "keys", "sitkeys", "speeds" }) do
            if d[k] ~= nil and type(d[k]) ~= "table" then E(k .. " inválido") end
        end
        if d.theme ~= nil then
            if type(d.theme) ~= "string" then E("tema inválido")
            elseif ctx.themes and not ctx.themes[d.theme] then W("tema " .. d.theme .. " não existe (ignorado)") end
        end
        if d.scale ~= nil and not (finite(d.scale) and d.scale >= 50 and d.scale <= 200) then
            E("tamanho da GUI fora de 50–200%")
        end
        if type(d.speeds) == "table" then
            for k, v in pairs(d.speeds) do
                if not (finite(v) and v >= 0 and v <= SPEED_MAX) then E("velocidade " .. tostring(k) .. " inválida") end
            end
        end
        if type(d.keys) == "table" then
            for id, name in pairs(d.keys) do
                if type(id) ~= "string" or type(name) ~= "string" then
                    E("tecla com formato inválido")
                elseif not keyOk(name) then
                    W("tecla " .. name .. " não existe (ignorada)")
                elseif ctx.toggles and not ctx.toggles[id] then
                    W("tecla de função desconhecida " .. id .. " (ignorada)")
                end
            end
        end
        if type(d.sitkeys) == "table" then
            for n, name in pairs(d.sitkeys) do
                if type(n) ~= "string" or type(name) ~= "string" then E("atalho de situação inválido") end
            end
        end
        for _, k in ipairs({ "panelkey", "consolekey", "searchkey" }) do
            if d[k] ~= nil then
                if type(d[k]) ~= "string" then E(k .. " inválido")
                elseif not keyOk(d[k]) then W(k .. " " .. d[k] .. " não existe (ignorada)") end
            end
        end
        if d.searchctrl ~= nil and type(d.searchctrl) ~= "boolean" then E("searchctrl inválido") end
        if type(d.on) == "table" then
            for _, id in ipairs(d.on) do
                if type(id) ~= "string" then
                    E("função com nome inválido")
                elseif ctx.noauto and ctx.noauto[id] then
                    W(id .. " nunca liga pelo perfil (ignorado)")
                elseif ctx.toggles and not ctx.toggles[id] then
                    W("função desconhecida " .. id .. " (ignorada)")
                end
            end
        end
        return #errs == 0, errs, warns
    end

    -- deps = { ctx, snapshot(), restore(d), verify(d) -> ok, motivo,
    --          clear(chave) (apaga um ajuste na volta), order = {ids},
    --          isOn(id), setToggle(id, on) }
    -- devolve ok, relatório { applied, rolledBack, errors, warnings, failed }
    T.Apply = function(d, deps)
        local rep = { applied = false, rolledBack = false, errors = {}, warnings = {}, failed = {} }
        local ok, errs, warns = T.Validate(d, deps.ctx)
        rep.warnings = warns
        if not ok then
            rep.errors = errs
            return false, rep
        end

        local okS, prev = pcall(deps.snapshot)
        if not okS or type(prev) ~= "table" then
            rep.errors = { "não deu para copiar o estado atual: " .. tostring(prev) }
            return false, rep
        end

        local okA, errA = pcall(deps.restore, d)
        local okV, whyV = okA, nil
        if okA and deps.verify then
            local okC, a, b = pcall(deps.verify, d)
            if okC then okV, whyV = a, b else okV, whyV = false, a end
        end
        if not okA or not okV then
            rep.errors = { okA and ("não terminou certo: " .. tostring(whyV))
                or ("falhou ao aplicar: " .. tostring(errA)) }
            local okB, errB = pcall(deps.restore, prev)
            -- o restore só escreve o que está na cópia: ajuste que o perfil
            -- criou (antes era nil) tem que ser apagado à parte
            if okB and deps.clear and type(d.set) == "table" then
                local had = type(prev.set) == "table" and prev.set or {}
                for k in pairs(d.set) do
                    if had[k] == nil then pcall(deps.clear, k) end
                end
            end
            rep.rolledBack = okB
            if not okB then
                table.insert(rep.errors, "e a volta ao estado anterior também falhou: " .. tostring(errB))
            end
            return false, rep
        end
        rep.applied = true

        if type(d.on) == "table" then
            local want = {}
            for _, id in ipairs(d.on) do want[id] = true end
            local noauto = (deps.ctx and deps.ctx.noauto) or {}
            for _, id in ipairs(deps.order or {}) do
                if not noauto[id] then
                    local w = want[id] == true
                    if deps.isOn(id) ~= w then
                        pcall(deps.setToggle, id, w)
                        if deps.isOn(id) ~= w then table.insert(rep.failed, id) end
                    end
                end
            end
        end
        return true, rep
    end
end
