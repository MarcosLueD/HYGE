// Etapa 1 — descoberta, ordem e isolamento dos módulos
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const B = require('../build');
const { ROOT, fixture, cleanup } = require('./helpers/project');

test.after(cleanup);

test('acha todos os .lua (inclusive em subpastas) e ignora o resto', () => {
  const root = fixture({
    'src/10_ui/00_a.lua': 'V8.a = 1\n',
    'src/10_ui/deep/er/01_b.lua': 'V8.b = 1\n',
    'src/20_x/notas.txt': 'não é lua',
    'src/20_x/00_c.lua.bak': 'V8.c = 1\n',
    'src/20_x/01_d.lua': 'V8.d = 1\n',
  });
  const a = B.assemble(root);
  assert.deepEqual(a.files, [
    'src/00_core/00_state.lua',
    'src/10_ui/00_a.lua',
    'src/10_ui/deep/er/01_b.lua',
    'src/20_x/01_d.lua',
  ]);
});

test('ordem é a do caminho, byte a byte (não a do locale)', () => {
  // (sem nomes que só mudam a caixa: no Windows seriam o mesmo arquivo)
  const names = ['src/10_ui/b.lua', 'src/10_ui/Z.lua', 'src/10_ui/a_b.lua', 'src/10_ui/ab.lua',
                 'src/10_ui/a.lua', 'src/9_late.lua', 'src/10_ui/a/z.lua'];
  const files = {};
  for (const n of names) files[n] = 'V8.x = 1\n';
  const a = B.assemble(fixture(files));
  const expected = ['src/00_core/00_state.lua', ...names].sort((x, y) => (x < y ? -1 : x > y ? 1 : 0));
  assert.deepEqual(a.files, expected);
  // "Z" (0x5A) antes de "a" (0x61); "a.lua" antes de "a/z.lua" ("." < "/");
  // "10_ui" antes de "9_late" ("1" < "9": por isso os prefixos têm 2 dígitos)
  assert.ok(a.files.indexOf('src/10_ui/Z.lua') < a.files.indexOf('src/10_ui/a.lua'));
  assert.ok(a.files.indexOf('src/10_ui/b.lua') < a.files.indexOf('src/9_late.lua'));
  assert.ok(a.files.indexOf('src/10_ui/a.lua') < a.files.indexOf('src/10_ui/a/z.lua'));
});

test('o projeto real sai na ordem do caminho e com src/00_core primeiro', () => {
  const a = B.assemble(ROOT);
  const sorted = [...a.files].sort((x, y) => (x < y ? -1 : x > y ? 1 : 0));
  assert.deepEqual(a.files, sorted);
  const firstOther = a.files.findIndex(f => !f.startsWith('src/00_core/'));
  assert.ok(a.files.slice(firstOther).every(f => !f.startsWith('src/00_core/')));
});

test('quem é isolado (V8.Mod) e quem não é', () => {
  const root = fixture({
    'src/00_core/01_shared.lua': 'V8.core = true\n',             // núcleo: nunca
    'src/10_ui/00_wrap.lua': 'do\n  V8.ok = 1\nend\n',            // só blocos: sim
    'src/10_ui/01_local.lua': 'local Shared = 1\nV8.s = Shared\n', // local no topo: não
    'src/10_ui/02_localfn.lua': 'local function F() end\nV8.f = F\n',
    'src/10_ui/03_return.lua': 'V8.r = 1\nreturn\n',
    'src/10_ui/04_nested.lua': 'do\n  local inner = 1\n  V8.n = inner\nend\n', // local dentro do do: sim
    'src/10_ui/05_broken.lua': 'do\n  V8.x = (\nend\n',            // não compila: não embrulha
  });
  const a = B.assemble(root);
  assert.deepEqual(a.wrappedFiles, ['src/10_ui/00_wrap.lua', 'src/10_ui/04_nested.lua']);
  assert.match(a.body, /V8\.Mod\("src\/10_ui\/00_wrap\.lua", \d+, \d+, function\(\) do\r\n/);
  assert.doesNotMatch(a.body, /V8\.Mod\("src\/00_core/);
  assert.doesNotMatch(a.body, /V8\.Mod\("src\/10_ui\/01_local/);
});

test('o wrapper não desloca as linhas: linha N do src = linha ini+N-1 do main.lua', () => {
  const mod = ['do', '  V8.alpha = 1', '  V8.MARCA_BETA = 2', 'end'].join('\n') + '\n';
  const root = fixture({ 'src/10_ui/00_pre.lua': 'local x = 1\nV8.x = x\n', 'src/10_ui/01_mod.lua': mod });
  const a = B.assemble(root);
  const lines = a.text.split('\r\n');
  const head = lines.findIndex(l => l.startsWith('V8.Mod("src/10_ui/01_mod.lua"'));
  assert.ok(head >= 0);
  const m = lines[head].match(/V8\.Mod\("[^"]+", (\d+), (\d+)/);
  const ini = Number(m[1]);
  assert.equal(ini, head + 1, 'ini do wrapper aponta para a própria linha');
  assert.equal(lines[ini + 3 - 1 - 1], '  V8.MARCA_BETA = 2');   // linha 3 do src
  assert.equal(Number(m[2]), ini + 4 - 1);
  // o mapa de linhas vai no fim e traduz de volta
  assert.match(lines[lines.length - 2], /^V8\.SrcMap = \{ /);
  const bodyLine = ini - B.BANNER_LINES + 2;   // linha 3 do módulo, em linhas do corpo
  assert.equal(a.where(bodyLine), 'src/10_ui/01_mod.lua:3');
});

test('BOM no começo de um módulo é removido', () => {
  const root = fixture({ 'src/10_ui/00_bom.lua': '﻿V8.bom = 1\n' });
  const a = B.assemble(root);
  assert.doesNotMatch(a.text, /﻿/);
});

test('src/ vazio é erro (não gera main.lua vazio)', () => {
  const { tmpDir } = require('./helpers/project');
  const root = tmpDir('empty');
  assert.throws(() => B.assemble(root), /Nenhum \.lua em src/);
});
