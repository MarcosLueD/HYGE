// Etapa 4 — troca segura de perfil (V8.ProfTx). Critério: um perfil inválido
// não pode deixar o painel parcialmente configurado.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua } = require('./helpers/lua');

// um "painel" de mentira: estado, restore que aplica chave por chave (e pode
// quebrar no meio) e funções que podem se recusar a ligar
const PANEL = {
  name: 'painel.lua',
  code: `
    V8 = {}
    function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
    function same(a, b)
      if type(a) ~= type(b) then return false end
      if type(a) ~= "table" then return a == b end
      for k, v in pairs(a) do if not same(v, b[k]) then return false end end
      for k in pairs(b) do if a[k] == nil then return false end end
      return true
    end
    STATE = { set = { Toasts = true, MaxLog = 60, Dock = true }, theme = "Grafite",
              keys = { fly = "F" }, speeds = { walk = 16 } }
    ON = { fly = false, noclip = false, esp = false, freecam = false, drone = false }
    ORDER = { "fly", "noclip", "esp", "freecam", "drone" }
    RESTORES, BREAK_AFTER, VERIFY_FAIL, REFUSE = 0, nil, nil, {}
    function Restore(d)
      RESTORES = RESTORES + 1
      local n = 0
      for k, v in pairs(d.set or {}) do
        STATE.set[k] = v
        n = n + 1
        if BREAK_AFTER and n >= BREAK_AFTER then BREAK_AFTER = nil error("quebrou no meio") end
      end
      if d.theme then STATE.theme = d.theme end
      if d.keys then STATE.keys = copy(d.keys) end
      if d.speeds then STATE.speeds = copy(d.speeds) end
    end
    function Deps()
      return {
        ctx = { setKeys = { Toasts = true, MaxLog = 60, Dock = true, Compact = true },
                toggles = { fly = true, noclip = true, esp = true, freecam = true, drone = true },
                noauto = { freecam = true, drone = true },
                themes = { Grafite = true, Roxo = true },
                keyOk = function(n) return n == "F" or n == "G" or n == "N" end },
        snapshot = function() return copy(STATE) end,
        restore = Restore,
        clear = function(k) STATE.set[k] = nil end,
        verify = function() if VERIFY_FAIL then return false, VERIFY_FAIL end return true end,
        order = ORDER,
        isOn = function(id) return ON[id] end,
        setToggle = function(id, on) if not REFUSE[id] then ON[id] = on end end,
      }
    end
    function Profile(extra)
      local p = { set = { Toasts = false, MaxLog = 120, Compact = true }, theme = "Roxo",
                  keys = { fly = "G", noclip = "N" }, speeds = { walk = 40 }, on = { "noclip", "esp" } }
      for k, v in pairs(extra or {}) do p[k] = v end
      return p
    end
  `,
};
const run = code => runLua([PANEL, 'src/30_kit/08_profile_tx.lua', { name: 'teste.lua', code }]);

test('perfil válido: preferências e funções aplicadas', () => {
  run(`
    local ok, rep = V8.ProfTx.Apply(Profile(), Deps())
    assert(ok and rep.applied and not rep.rolledBack, table.concat(rep.errors, "; "))
    assert(STATE.set.Toasts == false and STATE.set.MaxLog == 120 and STATE.set.Compact == true)
    assert(STATE.theme == "Roxo" and STATE.keys.fly == "G" and STATE.speeds.walk == 40)
    assert(ON.noclip and ON.esp and not ON.fly)
    assert(#rep.failed == 0 and #rep.warnings == 0)
  `);
});

test('Freecam e Drone nunca ligam pelo perfil (e não são desligados se já estão)', () => {
  run(`
    ON.drone = true
    local ok, rep = V8.ProfTx.Apply(Profile({ on = { "freecam", "fly" } }), Deps())
    assert(ok)
    assert(ON.fly and not ON.freecam, "freecam ligou")
    assert(ON.drone, "drone ligado pelo usuário foi desligado")
    assert(rep.warnings[1]:find("freecam"), "deveria avisar")
  `);
});

for (const [name, extra] of [
  ['sem ajustes (set)', '{ set = false }'],
  ['lista de funções não é lista', '{ on = "fly" }'],
  ['tamanho fora da faixa', '{ scale = 500 }'],
  ['velocidade NaN', '{ speeds = { walk = 0/0 } }'],
  ['velocidade infinita', '{ speeds = { fly = math.huge } }'],
  ['velocidade negativa', '{ speeds = { jump = -5 } }'],
  ['tecla com tipo errado', '{ keys = { fly = 5 } }'],
  ['ajuste com tipo errado', '{ set = { Toasts = function() end } }'],
  ['tema que não é texto', '{ theme = 42 }'],
  ['função com nome que não é texto', '{ on = { "fly", 7 } }'],
]) {
  test(`perfil inválido (${name}): nada muda`, () => {
    run(`
      local before, beforeOn = copy(STATE), copy(ON)
      local p = Profile(${extra})
      if p.set == false then p.set = nil end
      local ok, rep = V8.ProfTx.Apply(p, Deps())
      assert(ok == false, "aceitou um perfil inválido")
      assert(#rep.errors > 0)
      assert(RESTORES == 0, "mexeu no painel antes de validar")
      assert(same(STATE, before) and same(ON, beforeOn), "o painel mudou")
    `);
  });
}

test('erro NO MEIO da aplicação: volta ao estado anterior inteiro', () => {
  run(`
    local before, beforeOn = copy(STATE), copy(ON)
    BREAK_AFTER = 3   -- todas as 3 chaves entram (inclusive Compact, que não existia) e aí quebra
    local ok, rep = V8.ProfTx.Apply(Profile(), Deps())
    assert(ok == false and rep.rolledBack, "não voltou")
    assert(rep.errors[1]:find("quebrou no meio"))
    assert(same(STATE.set, before.set), "ficou pela metade: Toasts=" .. tostring(STATE.set.Toasts))
    assert(same(STATE, before))
    assert(same(ON, beforeOn), "ligou funções de um perfil que falhou")
  `);
});

test('aplicou mas não terminou certo (conferência falhou): volta ao anterior', () => {
  run(`
    local before = copy(STATE)
    VERIFY_FAIL = "tema: ApplyTheme quebrou"
    local ok, rep = V8.ProfTx.Apply(Profile(), Deps())
    assert(ok == false and rep.rolledBack)
    assert(rep.errors[1]:find("não terminou certo"))
    assert(same(STATE, before))
    assert(not ON.noclip)
  `);
});

test('função que não liga (sem personagem) não desfaz as preferências: vai pro relatório', () => {
  run(`
    REFUSE.esp = true
    local ok, rep = V8.ProfTx.Apply(Profile(), Deps())
    assert(ok and rep.applied)
    assert(STATE.theme == "Roxo", "preferências desfeitas")
    assert(ON.noclip and not ON.esp)
    assert(#rep.failed == 1 and rep.failed[1] == "esp")
  `);
});

test('itens desconhecidos viram aviso e são ignorados (perfil de outra versão)', () => {
  run(`
    local p = Profile({ theme = "Neon", keys = { fly = "Tecla", voar = "F" }, on = { "esp", "superpulo" } })
    p.set.CoisaNova = true
    local ok, rep = V8.ProfTx.Apply(p, Deps())
    assert(ok, table.concat(rep.errors, "; "))
    local all = table.concat(rep.warnings, " | ")
    for _, w in ipairs({ "Neon", "Tecla", "voar", "superpulo", "CoisaNova" }) do
      assert(all:find(w), "faltou aviso de " .. w .. ": " .. all)
    end
  `);
});

test('não deu nem para copiar o estado atual: não aplica nada', () => {
  run(`
    local d = Deps()
    d.snapshot = function() error("sem estado") end
    local ok, rep = V8.ProfTx.Apply(Profile(), d)
    assert(ok == false and RESTORES == 0)
    assert(rep.errors[1]:find("copiar"))
  `);
});
