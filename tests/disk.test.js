// Etapa 2 — gravação segura (V8.Disk.SafeWrite / SafeRead / Recover)
// Roda o src/30_kit/04_net.lua de verdade, com o disco imitado do prelude.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua } = require('./helpers/lua');

const NET = 'src/30_kit/04_net.lua';
const SETUP = {
  name: 'setup.lua',
  code: `
    V8 = {}
    -- "JSON válido" dos testes: <cfg ... end>  (cortado no meio = inválido)
    CHECK = function(s) return s:match("^<cfg .* end>$") ~= nil end
    function cfg(v) return "<cfg " .. v .. " " .. string.rep("x", 40) .. " end>" end
  `,
};
const run = code => runLua([SETUP, NET, { name: 'teste.lua', code }]);

test('gravação normal: principal, backup da anterior e sem .tmp sobrando', () => {
  run(`
    local D = V8.Disk
    assert(D.SafeWrite("HYGE/config.json", cfg("v1"), CHECK))
    assert(FS.files["HYGE/config.json"] == cfg("v1"))
    assert(FS.files["HYGE/config.backup.json"] == nil, "primeira gravação não tem anterior")
    assert(FS.files["HYGE/config.tmp"] == nil, ".tmp ficou")

    assert(D.SafeWrite("HYGE/config.json", cfg("v2"), CHECK))
    assert(FS.files["HYGE/config.json"] == cfg("v2"))
    assert(FS.files["HYGE/config.backup.json"] == cfg("v1"), "backup não é a anterior")
    assert(FS.files["HYGE/config.tmp"] == nil)

    -- mesmo conteúdo de novo: não troca o backup
    assert(D.SafeWrite("HYGE/config.json", cfg("v2"), CHECK))
    assert(FS.files["HYGE/config.backup.json"] == cfg("v1"))
  `);
});

test('conteúdo inválido não é gravado (nem o .tmp)', () => {
  run(`
    local D = V8.Disk
    assert(D.SafeWrite("HYGE/config.json", cfg("v1"), CHECK))
    local ok, why = D.SafeWrite("HYGE/config.json", "<cfg cortado", CHECK)
    assert(ok == false and why:find("inválido"), tostring(why))
    assert(FS.files["HYGE/config.json"] == cfg("v1"))
    assert(FS.files["HYGE/config.tmp"] == nil)
    assert(D.SafeWrite("HYGE/config.json", "", CHECK) == false)
  `);
});

test('principal estragado não apaga o backup bom; vai para .corrupt.json', () => {
  run(`
    local D = V8.Disk
    assert(D.SafeWrite("HYGE/config.json", cfg("v1"), CHECK))
    assert(D.SafeWrite("HYGE/config.json", cfg("v2"), CHECK))
    FS.files["HYGE/config.json"] = "<cfg v2 lix"          -- estragou por fora
    assert(D.SafeWrite("HYGE/config.json", cfg("v3"), CHECK))
    assert(FS.files["HYGE/config.json"] == cfg("v3"))
    assert(FS.files["HYGE/config.backup.json"] == cfg("v1"), "backup bom foi trocado por lixo")
    assert(FS.files["HYGE/config.corrupt.json"] == "<cfg v2 lix")
  `);
});

test('SafeRead: ok, ausente e estragado (com o que dá para recuperar)', () => {
  run(`
    local D = V8.Disk
    local r = D.SafeRead("HYGE/config.json", CHECK)
    assert(r.state == "missing" and r.text == nil)

    assert(D.SafeWrite("HYGE/config.json", cfg("v1"), CHECK))
    assert(D.SafeWrite("HYGE/config.json", cfg("v2"), CHECK))
    r = D.SafeRead("HYGE/config.json", CHECK)
    assert(r.state == "ok" and r.text == cfg("v2"))

    FS.files["HYGE/config.json"] = ""                     -- executor truncou e caiu
    r = D.SafeRead("HYGE/config.json", CHECK)
    assert(r.state == "corrupt", r.state)
    assert(#r.recover == 1 and r.recover[1].text == cfg("v1"), "deveria oferecer o backup")

    assert(D.Recover("HYGE/config.json", r.recover[1].text, CHECK))
    r = D.SafeRead("HYGE/config.json", CHECK)
    assert(r.state == "ok" and r.text == cfg("v1"))
    assert(D.Recover("HYGE/config.json", "lixo", CHECK) == false, "recuperar com lixo")
  `);
});

for (const mode of ['half', 'empty', 'after']) {
  test(`queda em CADA gravação (${mode}): a config anterior nunca se perde`, () => {
    const out = run(`
      local D = V8.Disk
      local P = "HYGE/config.json"
      local cases = 0
      for k = 1, 8 do
        FS.files, FS.log = {}, {}
        FS_REBOOT()
        assert(D.SafeWrite(P, cfg("v0"), CHECK))
        assert(D.SafeWrite(P, cfg("v1"), CHECK))          -- última config boa: v1
        FS.crashAt, FS.crashMode, FS.ops = k, "${mode}", 0
        pcall(D.SafeWrite, P, cfg("v2"), CHECK)           -- cai na k-ésima gravação
        local crashed = FS.dead
        FS_REBOOT()                                       -- abre o jogo de novo

        local r = D.SafeRead(P, CHECK)
        local got
        if r.state == "ok" then
          got = r.text
        else
          assert(r.state == "corrupt", "k=" .. k .. ": principal sumiu (" .. r.state .. ")")
          assert(#r.recover > 0, "k=" .. k .. ": nada para recuperar")
          got = r.recover[1].text
          assert(D.Recover(P, got, CHECK), "k=" .. k .. ": recuperar falhou")
        end
        assert(got == cfg("v1") or got == cfg("v2"),
          "k=" .. k .. ": sobrou " .. tostring(got) .. " | " .. table.concat(FS.log, ", "))

        -- e o painel continua salvando normalmente depois
        assert(D.SafeWrite(P, cfg("v3"), CHECK), "k=" .. k .. ": não salvou depois da queda")
        assert(D.SafeRead(P, CHECK).text == cfg("v3"))
        if crashed then cases = cases + 1 end
      end
      return tostring(cases)
    `);
    assert.ok(Number(out) >= 3, `só ${out} quedas aconteceram de fato`);
  });
}

test('sem delfile no executor: o .tmp fica, mas nada se perde', () => {
  run(`
    delfile = nil
    local D = V8.Disk
    assert(D.SafeWrite("HYGE/config.json", cfg("v1"), CHECK))
    assert(D.SafeWrite("HYGE/config.json", cfg("v2"), CHECK))
    assert(FS.files["HYGE/config.tmp"] == cfg("v2"))
    local r = D.SafeRead("HYGE/config.json", CHECK)
    assert(r.state == "ok" and r.text == cfg("v2"))
  `);
});

test('executor sem API de arquivos: SafeWrite recusa, SafeRead diz "missing"', () => {
  run(`
    writefile = nil
    local ok, why = V8.Disk.SafeWrite("HYGE/config.json", cfg("v1"), CHECK)
    assert(ok == false and why:find("writefile"))
    assert(V8.Disk.SafeRead("HYGE/config.json", CHECK).state == "missing")
  `);
});
