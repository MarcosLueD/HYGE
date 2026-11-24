// Etapa 3 — SHA-256 em Lua, V8.VerifyBuild e o loader.lua (com rede e disco
// imitados). Critério: uma atualização incompleta ou inválida nunca substitui
// a última versão que funcionava.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { runLua, block, source } = require('./helpers/lua');
const { ROOT } = require('./helpers/project');
const { analyze } = require('../tools/check');
const B = require('../build');

const BEGIN = '-- [sha256:begin]', END = '-- [sha256:end]';
const sha = buf => crypto.createHash('sha256').update(buf).digest('hex');
// bytes -> literal Lua ("\ddd")
const luaStr = buf => '"' + [...buf].map(b => '\\' + b).join('') + '"';
const long = s => { let eq = '='; while (s.includes(']' + eq + ']')) eq += '='; return `[${eq}[\n${s}]${eq}]`; };

test('o bloco SHA-256 é idêntico no loader.lua e no painel', () => {
  assert.equal(block('loader.lua', BEGIN, END), block('src/30_kit/07_sha256.lua', BEGIN, END));
});

test('SHA-256 em Lua bate com o do Node (vetores oficiais, bordas e binário)', () => {
  const inputs = [
    Buffer.from(''), Buffer.from('abc'),
    Buffer.from('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
    Buffer.from('Configuração — ação, você, 漢字 ✓', 'utf8'),
    crypto.randomBytes(10000),
  ];
  for (const n of [1, 54, 55, 56, 57, 63, 64, 65, 119, 120, 127, 128, 129]) inputs.push(crypto.randomBytes(n));
  const code = 'local Sha256\n' + block('src/30_kit/07_sha256.lua', BEGIN, END).replace(/^local Sha256\n/m, '')
    + '\nlocal out = {}\n'
    + inputs.map(b => `out[#out + 1] = Sha256(${luaStr(b)})`).join('\n')
    + '\nreturn table.concat(out, ",")';
  const got = runLua([{ name: 'sha.lua', code }]).split(',');
  assert.deepEqual(got, inputs.map(sha));
  // vetores do FIPS 180-4, conferidos à parte do Node
  assert.equal(got[1], 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  assert.equal(got[2], '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
});

test('loader.lua: sintaxe e globais ok (o mesmo validador do build)', () => {
  const r = analyze(fs.readFileSync(path.join(ROOT, 'loader.lua'), 'utf8'));
  assert.equal(r.syntax, undefined, r.syntax && r.syntax.message);
  assert.deepEqual(r.unknownGlobals, []);
});

// ---- builds falsos -----------------------------------------------------------
function fakeBuild(tag, { crlf = false, broken = false } = {}) {
  let text = [
    '-- =============================================================================',
    `-- HYGE v9.9-${tag} — ARQUIVO GERADO, NÃO EDITE AQUI.`,
    '-- Fonte: src/',
    `-- build: ${crypto.createHash('sha1').update(tag).digest('hex').slice(0, 12)}`,
    '-- =============================================================================',
    `LOADED = "${tag}"`,
    broken ? 'local quebrado = = 1' : `LOADED_ARGS = select("#", ...)`,
    '-- ' + 'x'.repeat(2000),
    '',
  ].join('\n');
  if (crlf) text = text.replace(/\n/g, '\r\n');
  const { size, sha256 } = B.integrity(text);
  const build = text.match(/-- build: ([0-9a-f]{12})/)[1];
  return { text, man: JSON.stringify({ version: 'v9.9-' + tag, build, file: 'main.lua', size, sha256, eol: 'lf' }) };
}

const BASE = 'https://raw.githubusercontent.com/MarcosLueD/HYGE/main/';
// monta a rede/disco, roda o loader e devolve um resumo do que aconteceu
function loader({ net = {}, disk = {}, setup = '', check = '' }) {
  const lines = ['HITS = {}', 'local orig = game.HttpGet',
    'game.HttpGet = function(self, url) table.insert(HITS, (url:gsub("%?t=%d+$", ""))) return orig(self, url) end'];
  for (const [k, v] of Object.entries(net)) lines.push(`NET[ ${long(BASE + k)} ] = ${v === false ? 'false' : long(v)}`);
  for (const [k, v] of Object.entries(disk)) lines.push(`FS.files[ ${long(k)} ] = ${long(v)}`);
  lines.push(setup);
  const ok = 'LOADER_OK, LOADER_ERR = pcall(function() local f = assert(loadstring(LOADER_SRC, "=loader")) f() end)';
  return runLua([
    { name: 'arrange.lua', code: `LOADER_SRC = ${long(source('loader.lua').code)}\n` + lines.join('\n') },
    { name: 'act.lua', code: ok },
    { name: 'assert.lua', code: check + `
      local hitMain = 0 for _, u in ipairs(HITS) do if u:find("main.lua", 1, true) then hitMain = hitMain + 1 end end
      return table.concat({ tostring(LOADER_OK), tostring(LOADED), tostring(hitMain),
        tostring(GENV.HYGE_LOADER and GENV.HYGE_LOADER.from), table.concat(WARNS, " | "),
        tostring(LOADER_ERR) }, "\\n") ` },
  ]).split('\n');
}
const files = (extra = '') => `
  function F(p) return FS.files["HYGE/" .. p] end
  ${extra}`;

test('loader: primeira vez online — baixa, confere, guarda e abre', () => {
  const a = fakeBuild('A');
  const [ok, loaded, hits, from] = loader({
    net: { 'main.lua': a.text, 'manifest.json': a.man },
    check: files(`assert(F("main.lua") == ${long(a.text)}, "cópia local") assert(F("manifest.json"), "manifesto local")
                  assert(F("main.backup.lua") == nil)`),
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.equal(hits, '1');
  assert.equal(from, 'GitHub');
});

test('loader: cópia local já é o build do manifesto — não baixa o main.lua', () => {
  const a = fakeBuild('A');
  const [ok, loaded, hits, from] = loader({
    net: { 'main.lua': a.text, 'manifest.json': a.man },
    disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.equal(hits, '0');
  assert.match(from, /já é a mais nova/);
});

test('loader: build novo — a anterior vira backup e a nova é guardada', () => {
  const a = fakeBuild('A'), b = fakeBuild('B');
  const [ok, loaded] = loader({
    net: { 'main.lua': b.text, 'manifest.json': b.man },
    disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
    check: files(`assert(F("main.lua") == ${long(b.text)}) assert(F("main.backup.lua") == ${long(a.text)})
                  assert(F("manifest.backup.json") ~= nil)`),
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'B');
});

for (const [name, mutate, reason] of [
  ['adulterado (mesmo tamanho)', t => t.replace('LOADED = "B"', 'LOADED = "X"'), /SHA-256 não confere/],
  ['cortado no meio', t => t.slice(0, Math.floor(t.length / 2)), /incompleto/],
  ['vazio', () => '', /download recusado/],
  ['de outro build', () => fakeBuild('C').text, /incompleto|SHA-256|build diferente/],
]) {
  test(`loader: download ${name} é recusado e a versão que funcionava abre`, () => {
    const a = fakeBuild('A'), b = fakeBuild('B');
    const [ok, loaded, , from, warns] = loader({
      net: { 'main.lua': mutate(b.text), 'manifest.json': b.man },
      disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
      check: files(`assert(F("main.lua") == ${long(a.text)}, "a cópia boa foi trocada")
                    assert(F("main.backup.lua") == nil, "mexeu no backup sem ter baixado nada bom")`),
    });
    assert.equal(ok, 'true');
    assert.equal(loaded, 'A');
    assert.equal(from, 'cópia local');
    assert.match(warns, reason);
  });
}

test('loader: build publicado que não compila é recusado (hash certo não basta)', () => {
  const a = fakeBuild('A'), b = fakeBuild('B', { broken: true });
  const [ok, loaded, , , warns] = loader({
    net: { 'main.lua': b.text, 'manifest.json': b.man },
    disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
    check: files(`assert(F("main.lua") == ${long(a.text)})`),
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.match(warns, /não compila/);
});

test('loader: GitHub servindo CRLF ainda confere (hash é do texto LF)', () => {
  const b = fakeBuild('B');
  const crlf = b.text.replace(/\n/g, '\r\n');
  const [ok, loaded, , from] = loader({ net: { 'main.lua': crlf, 'manifest.json': b.man } });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'B');
  assert.equal(from, 'GitHub');
});

test('loader: sem internet — abre a cópia local', () => {
  const a = fakeBuild('A');
  const [ok, loaded, , from, warns] = loader({
    net: { 'main.lua': false, 'manifest.json': false },
    disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.equal(from, 'cópia local');
  assert.match(warns, /manifesto/);
});

test('loader: sem internet e cópia local estragada — abre o backup', () => {
  const a = fakeBuild('A'), b = fakeBuild('B');
  const [ok, loaded, , from] = loader({
    net: { 'main.lua': false, 'manifest.json': false },
    disk: { 'HYGE/main.lua': b.text.slice(0, 900), 'HYGE/manifest.json': b.man,
            'HYGE/main.backup.lua': a.text, 'HYGE/manifest.backup.json': a.man },
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.equal(from, 'backup local');
});

test('loader: queda ao guardar a versão nova — na volta (offline) abre a anterior', () => {
  const a = fakeBuild('A'), b = fakeBuild('B');
  // 1ª execução: baixa B, guarda o backup (A) e cai no meio de gravar HYGE/main.lua
  const first = loader({
    net: { 'main.lua': b.text, 'manifest.json': b.man },
    disk: { 'HYGE/main.lua': a.text, 'HYGE/manifest.json': a.man },
    setup: `
      local real = writefile
      writefile = function(p, s)
        if p == "HYGE/main.lua" then FS.files[p] = s:sub(1, 500) FS.dead = true error("queda") end
        if FS.dead then error("disco congelado") end
        return real(p, s)
      end`,
    check: `
      -- "reabre o jogo" offline com o disco como ficou
      FS.dead = false
      writefile = nil
      for k in pairs(NET) do NET[k] = false end
      LOADED, WARNS = nil, {}
      SECOND_OK = pcall(function() assert(loadstring(LOADER_SRC, "=loader"))() end)
      assert(SECOND_OK, "segunda execução falhou")
      assert(LOADED == "A", "abriu " .. tostring(LOADED))
      assert(GENV.HYGE_LOADER.from == "backup local", GENV.HYGE_LOADER.from)
      LOADED = "B-then-A"`,
  });
  assert.equal(first[0], 'true');
  assert.equal(first[1], 'B-then-A');
});

test('loader: cópia de um loader antigo (sem manifesto) ainda abre offline', () => {
  const a = fakeBuild('A');
  const [ok, loaded, , from] = loader({
    net: { 'main.lua': false, 'manifest.json': false },
    disk: { 'HYGE/main.lua': a.text },
  });
  assert.equal(ok, 'true');
  assert.equal(loaded, 'A');
  assert.match(from, /sem manifesto/);
});

test('loader: nada bom em lugar nenhum — erro claro, nada roda', () => {
  const b = fakeBuild('B');
  const [ok, loaded, , , , err] = loader({
    net: { 'main.lua': b.text.slice(0, 100), 'manifest.json': b.man },
  });
  assert.equal(ok, 'false');
  assert.equal(loaded, 'nil');
  assert.match(err, /nada para abrir/);
});

test('V8.VerifyBuild (atualização dentro do painel) recusa o que o loader recusa', () => {
  const b = fakeBuild('B');
  const out = runLua([
    { name: 's.lua', code: 'V8 = {}' }, 'src/30_kit/07_sha256.lua',
    { name: 't.lua', code: `
      local man = HttpService:JSONDecode(${long(b.man)})
      local src = ${long(b.text)}
      assert(V8.VerifyBuild(src, man) == true)
      assert(V8.VerifyBuild(src:gsub("\\n", "\\r\\n"), man) == true, "CRLF")
      local function why(s, m) local ok, w = V8.VerifyBuild(s, m) assert(not ok) return w end
      assert(why(src:sub(1, 50), man):find("incompleto"))
      assert(why(src:gsub('LOADED = "B"', 'LOADED = "X"'), man):find("SHA%-256"))
      assert(why("", man):find("vazio"))
      assert(why(src, { size = 1 }):find("manifesto"))
      return "ok"` },
  ]);
  assert.equal(out, 'ok');
});
