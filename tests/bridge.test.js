// v9.2 — a ponte do painel com o servidor (V8.Srv) e as ações que usam ela.
// Roda o src/20_features/06_actions.lua inteiro de verdade, com um Roblox de
// CLIENTE imitado: Remotes que só registram o FireServer, um HYGE_Status que
// responde o que o teste mandar e um HYGE_Result que o teste "dispara".
// O que se confere aqui é o lado do cliente: sem servidor/cargo/permissão
// nada é enviado nem simulado, os argumentos saem no formato que o servidor
// aceita e o estado só muda com a confirmação. A validação de verdade é a do
// servidor (tests/server.test.js).
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua, source, block } = require('./helpers/lua');

const CATALOG = block('src/00_core/04_state.lua', 'V8.RemoteInfo = {', 'return have, #V8.RemoteInfo, missing\nend');
const ACTIONS = source('src/20_features/06_actions.lua').code;

const PRE = `
  CLOCK = 100
  os.clock = function() return CLOCK end
  LOGS, TOASTS, CHAT = {}, {}, {}
  function Log(msg, level) table.insert(LOGS, { msg = tostring(msg), level = level or "info" }) end
  function Toast(msg, kind) table.insert(TOASTS, { msg = tostring(msg), kind = kind }) end
  function Logged(text, level)
    for _, l in ipairs(LOGS) do
      if l.msg:find(text, 1, true) and (level == nil or l.level == level) then return l end
    end
    return nil
  end
  function Toasted(text) for _, t in ipairs(TOASTS) do if t.msg:find(text, 1, true) then return t end end end

  -- CFrame mínimo (só soma posição)
  local CFm = {}
  CFm.__mul = function(a, b) return CFrame.new(a.x + b.x, a.y + b.y, a.z + b.z) end
  CFm.__eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end
  CFrame = { new = function(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, CFm) end }

  StarterGui = { SetCore = function(_, kind, t) table.insert(CHAT, t.Text) end }
  THEME = { Danger = "danger", Accent = "accent" }
  Enum = { Font = { GothamBold = 1 } }
  LocalPlayer = { Name = "Eu", UserId = 77 }
  MYROOT = { CFrame = CFrame.new(0, 0, 0) }
  function Root() return MYROOT end

  -- jogador alvo: guarda o que alguém mexer no personagem dele
  function MakePlayer(name, id)
    local root = { CFrame = CFrame.new(50, 0, 0), Anchored = false }
    local hum = { WalkSpeed = 16, PlatformStand = false }
    local char = {
      FindFirstChild = function(_, n) if n == "HumanoidRootPart" then return root end end,
      FindFirstChildOfClass = function(_, c) if c == "Humanoid" then return hum end end,
    }
    return { Name = name, UserId = id, Parent = true, Character = char, root = root, hum = hum }
  end
  BOB = MakePlayer("Bob", 200)
  State = { SelectedPlayer = BOB }

  -- ReplicatedStorage do cliente: o que o teste "instalar"
  RS = {}
  ReplicatedStorage = { FindFirstChild = function(_, n) return RS[n] end }
  function Signal()
    local s = { fns = {} }
    function s:Connect(fn)
      table.insert(self.fns, fn)
      local c = { Connected = true }
      function c:Disconnect() self.Connected = false end
      return c
    end
    return s
  end
  function MakeRemote(name, class)
    local r = { Name = name, ClassName = class or "RemoteEvent", fired = {} }
    function r:IsA(c) return self.ClassName == c end
    function r:FireServer(...) table.insert(self.fired, table.pack(...)) end
    r.OnClientEvent = Signal()
    function r:Push(...) for _, fn in ipairs(self.OnClientEvent.fns) do fn(...) end end
    return r
  end
  ACTION_NAMES = { "AdminKick", "AdminPull", "AdminFreeze", "AdminTeleport", "AdminAnnounce",
    "AdminWhisper", "AdminFling", "AdminSpin", "AdminTrip", "AdminLaunch", "AdminSit",
    "AdminScale", "AdminBalloon" }
  -- opts.status: function() -> resposta do HYGE_Status (nil = sem HYGE_Status)
  function Install(opts)
    opts = opts or {}
    for _, n in ipairs(ACTION_NAMES) do RS[n] = MakeRemote(n) end
    RS.HYGE_Result = opts.status and MakeRemote("HYGE_Result") or nil
    if opts.status then
      local f = MakeRemote("HYGE_Status", "RemoteFunction")
      function f:InvokeServer() return opts.status() end
      RS.HYGE_Status = f
    else
      RS.HYGE_Status = nil
    end
  end
  function ALL() local t = {} for _, n in ipairs(ACTION_NAMES) do t[n] = true end return t end
  function Reply(level, actions) return function() return { hyge = "9.2", level = level,
    role = ({ [0] = "jogador", "moderador", "admin", "dono" })[level], actions = actions } end end
  function Fired() local n = 0 for _, k in ipairs(ACTION_NAMES) do if RS[k] then n = n + #RS[k].fired end end return n end
  function RunJobs() for _, fn in ipairs(JOBS) do fn() end end

  Remotes, Conn, JOBS = {}, {}, {}
  V8 = { Job = function(_, fn) table.insert(JOBS, fn) end, RawTask = task }
  setclipboard = nil
`;

const run = code => runLua([{ name: 'bridge.lua', code: PRE + CATALOG + '\n' + ACTIONS + '\n' + code }]);

// ---- sem servidor ------------------------------------------------------------------
test('sem o servidor: toda ação de servidor explica o motivo e não faz nada', () => {
  run(`
    V8.Srv.Refresh()
    assert(V8.Srv.State == "none")
    local calls = {
      function() return Bring(BOB) end,
      function() return FreezePlayer(BOB, true) end,
      function() return KickPlayer(BOB, "x") end,
      function() return FlingPlayer(BOB) end,
      function() return SpinPlayer(BOB, true) end,
      function() return TripPlayer(BOB) end,
      function() return LaunchPlayer(BOB) end,
      function() return SitPlayer(BOB) end,
      function() return ScalePlayer(BOB, "tiny") end,
      function() return BalloonPlayer(BOB, true) end,
      function() return Announce("oi pessoal") end,
      function() return V8.Srv.Whisper(BOB, "oi") end,
    }
    for i, f in ipairs(calls) do
      LOGS, TOASTS = {}, {}
      assert(f() == false, "ação " .. i .. " disse que foi enviada")
      assert(Logged("não está instalado neste jogo", "warn"), "ação " .. i .. " sem explicação no console")
      assert(Logged("ServerScriptService"), "ação " .. i .. " não diz onde instalar")
      assert(Toasted("sem servidor"), "ação " .. i .. " sem aviso na tela")
    end
    -- nada simulado na sua tela
    assert(BOB.root.CFrame == CFrame.new(50, 0, 0), "bring local voltou")
    assert(BOB.root.Anchored == false and BOB.hum.WalkSpeed == 16 and BOB.hum.PlatformStand == false,
      "freeze mexeu no alvo localmente")
    assert(#CHAT == 0, "anúncio apareceu no seu chat como se tivesse ido")
    assert(TrollState.Spin[200] == nil and TrollState.Balloon[200] == nil, "botão mostrou ON")
    assert(V8.Srv.Short("Kick") == "sem servidor")
    assert(V8.Srv.Summary():find("não instalado"))
  `);
});

test('sem o servidor: Teleportar até continua LOCAL (move só o seu personagem)', () => {
  run(`
    V8.Srv.Refresh()
    Goto(BOB)
    assert(MYROOT.CFrame == CFrame.new(50, 0, 4), "não teleportou o seu personagem")
    assert(Logged("local", "ok"))
  `);
});

test('Remote com o nome certo e a classe errada é ignorado', () => {
  run(`
    RS.AdminKick = { Name = "AdminKick", IsA = function(_, c) return c == "Folder" end }
    V8.Srv.Refresh()
    assert(Remotes.Kick == nil and V8.Srv.State == "none")
    assert(KickPlayer(BOB) == false)
  `);
});

// ---- com o servidor --------------------------------------------------------------------
test('servidor instalado e você com cargo: pede com os argumentos exatos', () => {
  run(`
    Install({ status = Reply(2, ALL()) })
    V8.Srv.Refresh()
    assert(V8.Srv.State == "ok" and V8.Srv.Info.level == 2, V8.Srv.State)
    local function last(n) local f = RS[n].fired return f[#f] end

    assert(KickPlayer(BOB, "spam"))
    local a = last("AdminKick") assert(a.n == 2 and a[1] == 200 and a[2] == "spam")
    assert(Bring(BOB))
    a = last("AdminPull") assert(a.n == 1 and a[1] == 200, "bring com argumento a mais (o servidor recusa)")
    FreezePlayer(BOB, true)
    a = last("AdminFreeze") assert(a[1] == 200 and a[2] == true)
    FreezePlayer(BOB, false)
    a = last("AdminFreeze") assert(a[2] == false)
    ScalePlayer(BOB, "giant")
    a = last("AdminScale") assert(a[1] == 200 and a[2] == "giant")
    Announce("olá")
    a = last("AdminAnnounce") assert(a.n == 1 and a[1] == "olá")
    V8.Srv.Whisper(BOB, "psiu")
    a = last("AdminWhisper") assert(a[1] == 200 and a[2] == "psiu")
    -- com o servidor, ir até o jogador é pedido a ele (fica no registro)
    Goto(BOB)
    a = last("AdminTeleport") assert(a.n == 1 and a[1] == 200)
    assert(MYROOT.CFrame == CFrame.new(0, 0, 0), "teleportou localmente também")
    -- o painel diz que pediu, não que fez
    assert(Logged("aguardando o servidor", "action"))
    assert(not Logged("✓"), "o painel não pode confirmar sozinho")
    assert(V8.Srv.Pending.AdminKick, "pedido não ficou aguardando")
    -- pedido nunca carrega "sou admin": o servidor decide pelo jogador que chamou
    for _, n in ipairs(ACTION_NAMES) do
      for _, f in ipairs(RS[n].fired) do
        for i = 1, f.n do assert(type(f[i]) ~= "table", n .. " mandou tabela") end
      end
    end
  `);
});

test('servidor diz que você não é admin: nada é enviado, e o motivo diz o que fazer', () => {
  run(`
    Install({ status = Reply(0, nil) })
    V8.Srv.Refresh()
    assert(V8.Srv.State == "ok" and V8.Srv.Info.level == 0)
    assert(KickPlayer(BOB) == false and FlingPlayer(BOB) == false and Announce("x") == false)
    assert(Fired() == 0, "pediu mesmo sem cargo")
    assert(Logged("não reconhece você como admin"))
    assert(Logged("77"), "não mostrou o UserId para o CONFIG.AdminIds")
    assert(V8.Srv.Short("Kick") == "não é admin")
    assert(V8.Srv.Summary():find("NÃO reconhece"))
    -- ir até: cai no teleporte local do seu personagem
    Goto(BOB)
    assert(#RS.AdminTeleport.fired == 0 and MYROOT.CFrame == CFrame.new(50, 0, 4))
  `);
});

test('cargo sem permissão para a ação: recusa no painel, o resto vai', () => {
  run(`
    Install({ status = Reply(1, { AdminKick = true, AdminWhisper = true, AdminFreeze = true }) })
    V8.Srv.Refresh()
    assert(KickPlayer(BOB))
    assert(#RS.AdminKick.fired == 1)
    LOGS = {}
    assert(FlingPlayer(BOB) == false and #RS.AdminFling.fired == 0)
    assert(Logged("moderador") and Logged("não tem permissão"))
    assert(V8.Srv.Short("Fling") == "sem permissão" and V8.Srv.Short("Kick") == nil)
    assert(V8.Srv.Summary():find("3/13"), V8.Srv.Summary())
  `);
});

// ---- respostas ---------------------------------------------------------------------------
test('liga/desliga só muda com a confirmação do servidor', () => {
  run(`
    Install({ status = Reply(2, ALL()) })
    V8.Srv.Refresh()
    local hooked = 0
    table.insert(V8.Srv.Hooks, function() hooked = hooked + 1 end)
    SpinPlayer(BOB, true)
    assert(TrollState.Spin[200] == nil, "mudou antes da resposta")
    RS.HYGE_Result:Push({ action = "AdminSpin", ok = true, code = "ok", target = 200, state = true, message = "Spin ON: Bob" })
    assert(TrollState.Spin[200] == true and hooked == 1)
    assert(Logged("[SERVIDOR] ✓ Spin ON: Bob", "ok"))
    assert(V8.Srv.Pending.AdminSpin == nil, "o pedido continuou aguardando")
    -- recusa não muda o estado
    RS.HYGE_Result:Push({ action = "AdminSpin", ok = false, code = "cooldown", target = 200, state = false, message = "Spin: espere 0.2s" })
    assert(TrollState.Spin[200] == true)
    assert(Logged("[SERVIDOR] ✗ Spin: espere 0.2s", "error") and Toasted("espere"))
    -- o balão que desliga sozinho também chega como resposta
    BalloonPlayer(BOB, true)
    RS.HYGE_Result:Push({ action = "AdminBalloon", ok = true, target = 200, state = true, message = "Balloon ON: Bob" })
    RS.HYGE_Result:Push({ action = "AdminBalloon", ok = true, target = 200, state = false, message = "Balloon de Bob desligou sozinho (20s)" })
    assert(TrollState.Balloon[200] == false)
    -- resposta malformada é ignorada sem erro
    local n = #LOGS
    RS.HYGE_Result:Push(nil)
    RS.HYGE_Result:Push("✓ Kick: todo mundo")
    RS.HYGE_Result:Push({ action = 1, message = {} })
    RS.HYGE_Result:Push({ action = "AdminSpin", ok = "true", target = "200", state = true, message = "x" })
    assert(TrollState.Spin[200] == true, "resposta malformada mudou o estado")
    assert(#LOGS == n + 1, "só a última (com action e message) vai para o console")
  `);
});

test('pedido sem resposta: o painel avisa depois de 6 s (e não avisa se a resposta veio)', () => {
  run(`
    Install({ status = Reply(2, ALL()) })
    V8.Srv.Refresh()
    KickPlayer(BOB)
    SitPlayer(BOB)
    RS.HYGE_Result:Push({ action = "AdminSit", ok = true, target = 200, message = "Sit: Bob" })
    CLOCK = CLOCK + 7
    RunJobs()
    assert(Logged("Kick: Bob — o servidor não respondeu em 6 s", "warn"))
    assert(not Logged("Force Sit: Bob — o servidor não respondeu"), "avisou de um pedido respondido")
    assert(next(V8.Srv.Pending) == nil)
  `);
});

// ---- servidor antigo / resposta estranha / sem resposta -------------------------------------
test('servidor v9.1 (sem HYGE_Status): pede, avisa que não há confirmação estruturada', () => {
  run(`
    Install({})                                  -- só os 13 Remotes
    V8.Srv.Refresh()
    assert(V8.Srv.State == "legacy")
    assert(SpinPlayer(BOB, true))
    assert(#RS.AdminSpin.fired == 1)
    assert(TrollState.Spin[200] == true, "sem confirmação o botão segue o pedido (como na v9.1)")
    assert(Logged("sem resposta estruturada", "warn"))
    assert(next(V8.Srv.Pending) == nil, "não dá para esperar resposta que não vem")
    -- a confirmação do v9.1 vinha pelo AdminWhisper com remetente "HYGE"
    LOGS, TOASTS = {}, {}
    RS.AdminWhisper:Push("HYGE", "✓ Kick: Bob")
    assert(Logged("[SERVIDOR] ✓ Kick: Bob", "ok") and #TOASTS == 0)
    RS.AdminWhisper:Push("Admin", "oi")
    assert(Logged("[ADMIN Admin] oi") and Toasted("oi"))
  `);
});

test('HYGE_Status com resposta estranha não quebra nem libera nada a mais', () => {
  run(`
    local reply
    Install({ status = function() return reply end })
    for _, r in ipairs({ "lol", 42, { hyge = 1, level = 2 }, { hyge = "9.2", level = 0/0 }, { hyge = "9.2" } }) do
      reply = r
      CLOCK = CLOCK + 3
      V8.Srv.Refresh()
      assert(V8.Srv.State == "noresponse" and V8.Srv.Info == nil, "aceitou " .. tostring(r))
    end
    -- sem confirmação os pedidos vão (o servidor decide) e o painel diz isso
    assert(V8.Srv.Can("Kick") and V8.Srv.Summary():find("sem resposta"))
    -- campos de tipo errado são descartados; cargo fora da faixa é limitado
    reply = { hyge = "9.2", level = 9, role = "admin", actions = { AdminKick = "sim", AdminSit = true, [1] = true } }
    CLOCK = CLOCK + 3
    V8.Srv.Refresh()
    assert(V8.Srv.State == "ok" and V8.Srv.Info.level == 3)
    assert(V8.Srv.Short("Kick") == "sem permissão" and V8.Srv.Short("Sit") == nil)
  `);
});

test('HYGE_Status que trava: vira "sem resposta" em 8 s; resposta atrasada vale; depois do Unload é ignorada', () => {
  run(`
    -- spawn de verdade (corrotina): o InvokeServer fica esperando
    V8.RawTask = { spawn = function(f) local co = coroutine.create(f) assert(coroutine.resume(co)) return co end }
    local waiting
    Install({ status = function() waiting = coroutine.running() return coroutine.yield() end })
    V8.Srv.Refresh()
    assert(V8.Srv.State == "checking")
    CLOCK = CLOCK + 9
    RunJobs()
    assert(V8.Srv.State == "noresponse" and V8.Srv.Why:find("8 s"))
    assert(coroutine.resume(waiting, Reply(2, ALL())()))
    assert(V8.Srv.State == "ok", "resposta atrasada não valeu")
    -- de novo, mas o painel é descarregado antes da resposta
    CLOCK = CLOCK + 3
    V8.Srv.Refresh()
    V8.Unloaded = true
    assert(coroutine.resume(waiting, Reply(0, nil)()))
    assert(V8.Srv.Info.level == 2, "resposta depois do Unload mudou o painel")
  `);
});

test('Remotes criados depois do painel: RECONFERIR acha e liga a escuta', () => {
  run(`
    assert(V8.Srv.State == "none")
    Install({ status = Reply(3, ALL()) })
    V8.Srv.Refresh()
    assert(V8.Srv.State == "ok" and Conn.SrvResult and Conn.Whisper and Conn.Announce)
    local changed = 0
    V8.Srv.OnChange(function() changed = changed + 1 end)
    RS.HYGE_Result:Push({ action = "AdminKick", ok = true, target = 200, message = "Kick: Bob" })
    assert(Logged("[SERVIDOR] ✓ Kick: Bob"))
    RS.AdminAnnounce:Push("Dono", "manutenção às 20h")
    assert(Logged("[ANÚNCIO Dono] manutenção às 20h"))
    CLOCK = CLOCK + 3
    V8.Srv.Refresh()
    assert(changed >= 1, "quem escuta (botões, aba Servidor) não foi avisado")
  `);
});
