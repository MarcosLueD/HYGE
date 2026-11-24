// Etapa 6 — contabilidade de conexões/tarefas (bloco [conns] do
// src/00_core/04_state.lua, rodado de verdade) e o lint de vazamento
// (tools/leaks.js) no src/ inteiro.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua, block } = require('./helpers/lua');
const { scanText, scanDir } = require('../tools/leaks');
const { ROOT } = require('./helpers/project');

const CONNS = block('src/00_core/04_state.lua', '-- [conns:begin]', '-- [conns:end]');
// o bloco usa: V8, Conn, Drop (definidos antes dele no 04_state) e task
const PRE = `
  V8, Conn = {}, {}
  local function Drop(name) if Conn[name] then Conn[name]:Disconnect() Conn[name] = nil end end
  _G.Drop = Drop
  -- conexão falsa (com .Connected, igual à do Roblox)
  function FakeConn(name)
    local c = { name = name, Connected = true }
    function c:Disconnect() self.Connected = false end
    return c
  end
  -- task.spawn com corrotina de verdade (o prelude roda direto)
  task.spawn = function(f, ...) local co = coroutine.create(f) assert(coroutine.resume(co, ...)) return co end
`;
const run = code => runLua([{ name: 'conns.lua', code: PRE + CONNS.replace(/\blocal task\b/, 'task') + '\n' + code }]);

test('conexões: criadas, encerradas e ativas batem', () => {
  run(`
    local S = V8.Conns
    Conn.A = FakeConn("A")
    Conn.B = FakeConn("B")
    assert(S.created == 2 and S.live.A and S.live.B)
    local a = Conn.A
    Drop("A")
    assert(a.Connected == false and Conn.A == nil)
    assert(S.closed == 1 and S.live.A == nil)
    local n = 0 for _ in pairs(S.live) do n = n + 1 end
    assert(n == 1)
    -- pairs(Conn) não enxerga nada: a lista de verdade é V8.Conns.live
    assert(next(Conn) == nil)
  `);
});

test('trocar Conn.X sem Drop desconecta a antiga (antes vazava)', () => {
  run(`
    local S = V8.Conns
    local old = FakeConn("velha")
    Conn.Loop = old
    Conn.Loop = FakeConn("nova")
    assert(old.Connected == false, "a antiga continuou viva")
    assert(S.replaced == 1 and S.closed == 1 and S.created == 2)
    assert(Conn.Loop.name == "nova")
  `);
});

test('Conn.X = nil sem Disconnect também desconecta', () => {
  run(`
    local c = FakeConn("x")
    Conn.X = c
    Conn.X = nil
    assert(c.Connected == false)
    assert(V8.Conns.closed == 1 and V8.Conns.replaced == 0)
  `);
});

test('tarefas: agendadas, pendentes e rodando', () => {
  run(`
    local T = V8.Tasks
    task.delay(1, function() end)
    task.defer(function() end)
    assert(T.scheduled == 2 and V8.Pending() >= 1)
    TASK_FLUSH()
    assert(V8.Pending() == 0, "pendentes: " .. V8.Pending())
    -- spawn que fica esperando (HTTP, wait...) conta como rodando
    local co = task.spawn(function() coroutine.yield() end)
    assert(T.running == 1, "rodando: " .. T.running)
    coroutine.resume(co)
    assert(T.running == 0)
    -- erro dentro do spawn continua sendo erro (não é engolido)
    local ok = pcall(function() task.spawn(function() error("boom") end) end)
    assert(not ok, "erro do spawn sumiu")
    assert(T.running == 0)
  `);
});

test('tarefa que roda DEPOIS do unload é anotada e avisada (uma vez por origem)', () => {
  run(`
    task.delay(5, function() end)
    task.delay(5, function() end)
    V8.Unloaded = true
    TASK_FLUSH()
    assert(#V8.Tasks.late >= 1, "não anotou")
    assert(Said(WARNS, "depois do unload"), "não avisou")
    -- o task do Roblox direto (V8.RawTask) não é contado: é o caminho da atualização
    local before = V8.Tasks.scheduled
    V8.RawTask.delay(1, function() end)
    assert(V8.Tasks.scheduled == before)
  `);
});

// ---- lint de vazamento ---------------------------------------------------------
test('src/ não tem conexão persistente fora do Conn (o Unload desconecta tudo)', () => {
  const found = scanDir(ROOT);
  assert.deepEqual(found.map(f => `${f.file}:${f.line} ${f.code}`), []);
});

test('o lint acha conexão de serviço/jogador fora do Conn e respeita as exceções', () => {
  const code = [
    'UserInputService.InputBegan:Connect(function() end)',             // 1: vaza
    'Conn.Ok = RunService.Heartbeat:Connect(function() end)',           // 2: ok
    'local c = LocalPlayer.CharacterAdded:Connect(function() end)',     // 3: vaza
    'btn.MouseButton1Click:Connect(function() end)',                    // 4: GUI, ok
    'game:GetService("Players").PlayerAdded:Connect(print)',            // 5: vaza
    'Camera:GetPropertyChangedSignal("CFrame"):Connect(print) -- conn:ok motivo', // 6: exceção
    'Conn["Dyn" .. 1] = workspace.ChildAdded:Connect(print)',           // 7: ok
    'Hum().Died:Once(print)',                                           // 8: vaza (Once)
  ].join('\n');
  const lines = scanText('x.lua', code).map(f => f.line);
  assert.deepEqual(lines, [1, 3, 5, 8]);
});
