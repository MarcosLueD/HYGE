--------------------------------------------------------------------------------
-- v8.2 — PACOTES DE ANIMAÇÃO (motor; a UI fica em 40_tabs/02_movement_pack.lua)
--
-- Um pacote (bundle) do catálogo é uma lista de itens: Idle, Walk, Run, Jump,
-- Fall, Climb, Swim. Cada item é uma "caixa" (Folder > StringValue "run" >
-- Animation) e o que toca é o AnimationId de dentro. Para ler um pacote:
--   1. a lista de itens: AssetService:GetBundleDetailsAsync (API do Roblox)
--      ou, se o jogo não deixar, o catálogo público pelo HTTP do executor
--   2. cada item: game:GetObjects (executor) abre a caixa
-- O resultado (AnimationId por animação) vai na config (SET.Packs): da segunda
-- vez em diante não precisa de rede. Os dois pacotes que já vêm na lista têm os
-- itens conferidos no catálogo, então só o passo 2 roda.
--
-- USAR no personagem = trocar os AnimationId do script Animate do SEU
-- personagem e reiniciar o Animate. As animações tocam pelo seu Animator,
-- então os outros jogadores veem (igual a um pacote equipado no avatar). Só
-- R15 e só em jogo com o Animate padrão — quando não dá, o painel diz por quê.
-- Os IDs originais ficam guardados: "voltar ao normal" devolve tudo.
--
-- VOO: o Fly (estilo "pacote") pede K.FlyIds() — fall voando e idle parado, do
-- pacote marcado como VOO (SET.FlyPack) ou do CONFIG.FlyPackBundle.
-- Tudo em V8.Pack: zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Pack = { busy = {}, fail = {}, waiters = {}, temp = {},
                    orig = {}, origChar = nil, Listeners = {} }
        local K = V8.Pack

        K.Slots = { "idle", "walk", "run", "jump", "fall", "climb", "swim" }
        K.SlotName = { idle = "parado", walk = "andar", run = "correr", jump = "pular",
            fall = "cair", climb = "escalar", swim = "nadar" }
        local IS_SLOT = {}
        for _, s in ipairs(K.Slots) do IS_SLOT[s] = true end

        K.OnChange = function(fn) table.insert(K.Listeners, fn) end
        K.Changed = function()
            for _, fn in ipairs(K.Listeners) do pcall(fn) end
        end

        -- ID grande (14-15 dígitos) sempre como texto: nem o JSON da config nem
        -- o tostring viram notação científica
        local function IdStr(v)
            if type(v) == "number" then
                if v ~= v or v < 1 or v >= 2 ^ 53 then return nil end
                return string.format("%d", v)
            end
            if v == nil then return nil end
            return tostring(v):match("(%d%d%d%d+)")
        end
        K.IdStr = IdStr

        -- aceita "60179708829279", "rbxassetid://..." e o link do catálogo
        -- (roblox.com/pt/bundles/60179708829279/Nome?pid=share...)
        K.Parse = function(raw)
            local s = tostring(raw or "")
            return s:match("bundles/(%d+)") or s:match("(%d%d%d%d%d+)")
        end

        -- pacotes que já vêm na lista (itens conferidos no catálogo)
        local SEED = {
            { id = "60179708829279", name = "Super Gogeta DBZ", items = {
                idle = "110189334321552", walk = "71567557250866", run = "95473441710999",
                jump = "111658291175493", fall = "124330094243355", climb = "137524336110065",
                swim = "97745837467465" } },
            { id = "4899847411546", name = "Endless Aura Floating", items = {
                idle = "75638427965557", walk = "131290152729043", run = "77610456891399",
                jump = "74451563346167", fall = "74203422263286", climb = "116293937663140",
                swim = "110044773049875" } },
        }

        -- SET.Packs = { { id, name, items = {slot = itemId}, anims = {slot = AnimationId} } }
        -- Valida o que veio da config (ou cria a lista na primeira vez).
        K.List = function()
            if type(SET.Packs) ~= "table" then
                SET.Packs = {}
                for _, s in ipairs(SEED) do
                    local items = {}
                    for k, v in pairs(s.items) do items[k] = v end
                    table.insert(SET.Packs, { id = s.id, name = s.name, items = items, anims = {} })
                end
            end
            -- já conferida (a config carregada troca a tabela inteira)
            if K.checked == SET.Packs then return SET.Packs end
            local clean, dirty = {}, false
            for _, p in ipairs(SET.Packs) do
                local id = type(p) == "table" and IdStr(p.id)
                if id then
                    p.id = id
                    if type(p.name) ~= "string" or p.name == "" then p.name = "Pacote " .. id end
                    local items, anims = {}, {}
                    for _, s in ipairs(K.Slots) do
                        local iid = type(p.items) == "table" and IdStr(p.items[s])
                        if iid then items[s] = iid end
                        local a = type(p.anims) == "table" and p.anims[s]
                        if type(a) == "string" and a:match("^rbxassetid://%d+$") then anims[s] = a end
                    end
                    p.items, p.anims = items, anims
                    table.insert(clean, p)
                else
                    dirty = true
                end
            end
            if dirty then SET.Packs = clean end
            K.checked = SET.Packs
            return SET.Packs
        end

        K.Get = function(id)
            id = IdStr(id)
            if not id then return nil end
            for _, p in ipairs(K.List()) do
                if p.id == id then return p end
            end
            return nil
        end

        -- por ID / link ou por pedaço do nome ("gogeta")
        K.Find = function(q)
            q = tostring(q or "")
            local p = K.Get(K.Parse(q))
            if p then return p end
            q = q:lower()
            if q == "" then return nil end
            for _, it in ipairs(K.List()) do
                if it.name:lower():find(q, 1, true) then return it end
            end
            return nil
        end

        K.Count = function(p)
            local n = 0
            for _, s in ipairs(K.Slots) do
                if p and p.anims and p.anims[s] then n = n + 1 end
            end
            return n
        end

        -- grava a config (a lista e as animações lidas) se o executor deixar
        K.Persist = function()
            if V8.Cfg and V8.Cfg.Supported and V8.Cfg.Supported() then
                pcall(V8.Cfg.Save, true)
            end
        end

        ----------------------------------------------------------------------------
        -- leitura do pacote
        ----------------------------------------------------------------------------
        local function SlotFromName(name)
            local n = tostring(name or ""):lower()
            for _, s in ipairs(K.Slots) do
                if n:find(s, 1, true) then return s end
            end
            return nil
        end

        -- itens do pacote: { {id=, name=}, ... }, nome do pacote  (ou nil, nil, motivo)
        local function FetchBundle(bid)
            local okA, info = pcall(function()
                return game:GetService("AssetService"):GetBundleDetailsAsync(tonumber(bid))
            end)
            if okA and type(info) == "table" and type(info.Items) == "table" then
                local bt = tostring(info.BundleType or "")
                if bt ~= "" and not bt:find("Animation") then
                    return nil, nil, "este pacote é de " .. bt .. ", não de animação"
                end
                local list = {}
                for _, it in ipairs(info.Items) do
                    local iid = IdStr(it.Id)
                    if it.Type == "Asset" and iid then
                        table.insert(list, { id = iid, name = tostring(it.Name or "") })
                    end
                end
                if #list > 0 then return list, info.Name end
            end
            if not (V8.Net and V8.Net.Json) then
                return nil, nil, "o jogo não deixou ler o pacote e o executor não tem HTTP"
            end
            local d, why = V8.Net.Json("GET",
                "https://catalog.roblox.com/v1/bundles/" .. bid .. "/details")
            if not d then return nil, nil, "catálogo: " .. tostring(why) end
            local bt = tostring(d.bundleType or "")
            if bt ~= "" and not bt:find("Animation") then
                return nil, nil, "este pacote é de " .. bt .. ", não de animação"
            end
            local list = {}
            for _, it in ipairs(type(d.items) == "table" and d.items or {}) do
                local iid = IdStr(it.id)
                if it.type == "Asset" and iid then
                    table.insert(list, { id = iid, name = tostring(it.name or "") })
                end
            end
            if #list == 0 then return nil, nil, "o pacote não tem itens (ID errado?)" end
            return list, d.name
        end

        -- abre a caixa do item: slot ("run"...) e o AnimationId de dentro
        local function ReadItem(itemId, hint)
            local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. itemId) end)
            if not ok or type(objs) ~= "table" then
                return nil, nil, "o executor não tem game:GetObjects (ou o Roblox recusou o item)"
            end
            local slot, anim
            for _, o in ipairs(objs) do
                local all = o:GetDescendants()
                table.insert(all, 1, o)
                for _, d in ipairs(all) do
                    if not anim and d:IsA("StringValue") and IS_SLOT[d.Name:lower()] then
                        local a = d:FindFirstChildOfClass("Animation")
                        if a and a.AnimationId ~= "" then slot, anim = d.Name:lower(), a.AnimationId end
                    end
                end
                if not anim then
                    for _, d in ipairs(all) do
                        if d:IsA("Animation") and d.AnimationId ~= "" then
                            anim = d.AnimationId
                            break
                        end
                    end
                end
            end
            for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
            local key = anim and tostring(anim):match("(%d%d%d%d+)")
            if not key then return nil, nil, "o item não tem animação dentro" end
            return slot or SlotFromName(hint), "rbxassetid://" .. key
        end

        -- lê o que falta (BLOQUEIA: rode em task.spawn). Devolve quantas
        -- animações ficaram prontas, ou nil + motivo
        K.ResolveNow = function(p)
            if K.Count(p) >= #K.Slots then return K.Count(p) end
            local lastWhy
            if next(p.items) == nil then
                local list, name, why = FetchBundle(p.id)
                if not list then return nil, why end
                if type(name) == "string" and name ~= "" then p.name = name end
                for _, it in ipairs(list) do
                    local slot, anim, why2 = ReadItem(it.id, it.name)
                    if slot and anim then
                        p.items[slot] = it.id
                        p.anims[slot] = anim
                    elseif why2 then
                        lastWhy = why2
                    end
                end
            else
                for _, s in ipairs(K.Slots) do
                    local iid = p.items[s]
                    if iid and not p.anims[s] then
                        local slot, anim, why2 = ReadItem(iid, s)
                        if anim then
                            p.anims[(slot and IS_SLOT[slot]) and slot or s] = anim
                        else
                            lastWhy = why2
                        end
                    end
                end
            end
            local n = K.Count(p)
            if n == 0 then return nil, lastWhy or "nenhuma animação encontrada no pacote" end
            return n
        end

        -- assíncrono; done(n, motivo) roda quando terminar (vários podem esperar)
        K.Resolve = function(p, done)
            if not p then return end
            local w = K.waiters[p.id]
            if w then
                if done then table.insert(w, done) end
                return
            end
            w = {}
            if done then table.insert(w, done) end
            K.waiters[p.id] = w
            K.busy[p.id] = true
            K.fail[p.id] = nil
            K.Changed()
            task.spawn(function()
                local ok, n, why = pcall(K.ResolveNow, p)
                if not ok then n, why = nil, tostring(n) end
                K.busy[p.id] = nil
                K.waiters[p.id] = nil
                K.fail[p.id] = (not n) and (why or "não deu para ler") or nil
                if n and K.Get(p.id) == p then K.Persist() end
                K.Changed()
                for _, fn in ipairs(w) do pcall(fn, n, why) end
            end)
        end

        -- adiciona pelo ID/link e já lê. done(pacote, n, motivo)
        K.Add = function(raw, done)
            local id = IdStr(K.Parse(raw))
            if not id then return nil, "não achei o ID do pacote (cole o número ou o link)" end
            local p = K.Get(id)
            if not p then
                p = K.temp[id] or { id = id, name = "Pacote " .. id, items = {}, anims = {} }
                K.temp[id] = nil
                table.insert(K.List(), p)
            end
            K.Changed()
            if K.Count(p) > 0 and not done then return p end
            K.Resolve(p, function(n, why)
                if done then pcall(done, p, n, why) end
            end)
            return p
        end

        ----------------------------------------------------------------------------
        -- no personagem
        ----------------------------------------------------------------------------
        local function Animate()
            local c = Char()
            return c and c:FindFirstChild("Animate")
        end

        -- reinicia o Animate: ele relê os IDs e volta a tocar com os novos.
        -- Antes, para as tracks dele (Core/Idle/Movement) — emote e voo ficam.
        local function Restart(h, animate)
            local animator = h:FindFirstChildOfClass("Animator")
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                    local mine = (t == Emote.track) or (t == flyTrack) or (t == FlyPose.idleTrack)
                    local pr = t.Priority
                    if not mine and (pr == Enum.AnimationPriority.Core
                        or pr == Enum.AnimationPriority.Idle
                        or pr == Enum.AnimationPriority.Movement) then
                        pcall(function() t:Stop(0.1) end)
                    end
                end
            end
            pcall(function() animate.Disabled = true end)
            task.wait()
            pcall(function() animate.Disabled = false end)
        end

        -- o Roblox recusa asset em alguns jogos: a track "toca" com Length 0
        local function Verify(p, h)
            task.delay(4, function()
                local animator = h and h.Parent and h:FindFirstChildOfClass("Animator")
                if not animator or SET.PackOn ~= p.id then return end
                local mineIds = {}
                for _, a in pairs(p.anims) do mineIds[a] = true end
                local seen, good = 0, 0
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                    local aid = t.Animation and t.Animation.AnimationId
                    if aid and mineIds[aid] then
                        seen = seen + 1
                        if t.Length > 0 then good = good + 1 end
                    end
                end
                if seen > 0 and good == 0 then
                    Log("O Roblox não carregou as animações de " .. p.name .. " neste jogo "
                        .. "(asset recusado). Em outros jogos pode funcionar.", "error")
                    Toast("Este jogo recusou o pacote", "error", 3)
                end
            end)
        end

        -- devolve ok, quantas trocou (ou o motivo), animações sem lugar no Animate
        K.Apply = function(p)
            local h, animate = Hum(), Animate()
            if not h then return false, "sem personagem" end
            if h.RigType == Enum.HumanoidRigType.R6 then
                return false, "pacotes de animação são R15 e este jogo usa R6"
            end
            if not animate then
                return false, "seu personagem não tem o script Animate (o jogo anima do jeito dele)"
            end
            if K.Count(p) == 0 then return false, "o pacote ainda não foi lido" end
            local char = Char()
            if K.origChar ~= char then K.origChar, K.orig = char, {} end
            local changed, missing = 0, {}
            for _, s in ipairs(K.Slots) do
                local id = p.anims[s]
                if id then
                    local f = animate:FindFirstChild(s)
                    local any = false
                    if f then
                        for _, a in ipairs(f:GetChildren()) do
                            if a:IsA("Animation") then
                                if K.orig[a] == nil then K.orig[a] = a.AnimationId end
                                a.AnimationId = id
                                changed = changed + 1
                                any = true
                            end
                        end
                    end
                    if not any then table.insert(missing, K.SlotName[s]) end
                end
            end
            if changed == 0 then
                return false, "o Animate deste jogo não tem as pastas padrão (idle, walk, run...)"
            end
            task.spawn(Restart, h, animate)
            Verify(p, h)
            return true, changed, missing
        end

        -- devolve os IDs originais do Animate deste personagem
        K.Restore = function()
            local n = 0
            for a, id in pairs(K.orig) do
                if a.Parent then
                    pcall(function() a.AnimationId = id end)
                    n = n + 1
                end
            end
            K.orig = {}
            local h, animate = Hum(), Animate()
            if n > 0 and h and animate then task.spawn(Restart, h, animate) end
            return n
        end

        -- põe o pacote no personagem (lê antes, se precisar). quiet = boot/respawn
        K.Use = function(p, quiet)
            if not p then return end
            local function Go()
                local ok, a, b = K.Apply(p)
                if ok then
                    SET.PackOn = p.id
                    if not quiet then
                        Log("Pacote " .. p.name .. " no personagem (" .. K.Count(p) .. " animações)"
                            .. ((b and #b > 0) and ("  ·  sem lugar no Animate: "
                                .. table.concat(b, ", ")) or ""), "ok")
                        Toast(p.name .. " no personagem", "ok", 2)
                    end
                else
                    Log("Pacote " .. p.name .. ": " .. tostring(a), quiet and "warn" or "error")
                    if not quiet then Toast("Não deu: " .. tostring(a), "error", 3) end
                end
                K.Changed()
            end
            if K.Count(p) > 0 then Go() return end
            if not quiet then Toast("Lendo " .. p.name .. "...", nil, 2) end
            K.Resolve(p, function(n, why)
                if n then
                    Go()
                else
                    Log("Pacote " .. p.name .. " não foi lido: " .. tostring(why), "error")
                    if not quiet then Toast("Pacote não foi lido", "error", 3) end
                end
            end)
        end

        K.Off = function(quiet)
            SET.PackOn = nil
            local n = K.Restore()
            if not quiet then
                Log(n > 0 and "Animações do personagem de volta ao normal"
                    or "Nenhum pacote estava no personagem", "action")
            end
            K.Changed()
        end

        K.Remove = function(p)
            if not p then return end
            if SET.PackOn == p.id then K.Off(true) end
            if SET.FlyPack == p.id then SET.FlyPack = nil end
            local list = K.List()
            for i = #list, 1, -1 do
                if list[i] == p then table.remove(list, i) end
            end
            K.Persist()
            K.Changed()
        end

        ----------------------------------------------------------------------------
        -- voo
        ----------------------------------------------------------------------------
        -- o pacote do Fly: o marcado como VOO; sem marca, o CONFIG.FlyPackBundle
        -- (que não precisa estar na lista: fica só na memória desta sessão)
        K.FlyPack = function()
            local p = SET.FlyPack and K.Get(SET.FlyPack)
            if p then return p end
            local id = IdStr(CONFIG.FlyPackBundle)
            if not id then return nil end
            p = K.Get(id)
            if p then return p end
            if not K.temp[id] then
                K.temp[id] = { id = id, name = "Pacote " .. id, items = {}, anims = {} }
            end
            return K.temp[id]
        end

        -- moveId, idleId, pacote (moveId nil = ainda não lido)
        K.FlyIds = function()
            local p = K.FlyPack()
            if not p then return nil, nil, nil end
            local a = p.anims
            local move = a[CONFIG.FlyPackMoveSlot or "fall"] or a.fall or a.swim
            local idle = a[CONFIG.FlyPackIdleSlot or "idle"]
            return move, idle, p
        end

        K.SetFly = function(p)
            SET.FlyPack = p and p.id or nil
            FlyPose.packFailed = false
            FlyPose.warnedPack = false
            if IsOn("fly") and not Emote.track and FlyPose.Restart then FlyPose.Restart() end
            if V8.FlyStyleRender then pcall(V8.FlyStyleRender) end
            K.Changed()
        end

        ----------------------------------------------------------------------------
        -- boot e respawn
        ----------------------------------------------------------------------------
        K.Boot = function()
            K.List()
            local p = SET.PackOn and K.Get(SET.PackOn)
            if p then K.Use(p, true) end
        end

        Conn.PackChar = LocalPlayer.CharacterAdded:Connect(function(char)
            K.origChar, K.orig = nil, {}
            if not SET.PackOn then return end
            task.spawn(function()
                pcall(function() char:WaitForChild("Animate", 6) end)
                task.wait(0.3)
                local p = K.Get(SET.PackOn)
                if p and Char() == char then K.Use(p, true) end
            end)
        end)
    end
    Build()
end
