// v9.4 — identidade visual: o que dá para conferir fora do Roblox.
// O desenho em si (neon, degradê, brilho) só dá para ver no jogo
// (docs/TESTES.md); aqui ficam as regras: a geometria do triângulo (o
// contorno fecha nos cantos, o miolo fica embaixo do contorno e tudo cabe na
// caixa), a troca única do tema padrão antigo e a paleta (as mesmas chaves em
// todos os temas e contraste legível no tema HYGE e nas barras do HUD).
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { runLua, block } = require('./helpers/lua');
const { ROOT } = require('./helpers/project');

const BRAND = block('src/30_kit/10_brand.lua', '-- [brand:begin]', '-- [brand:end]');
const HUD = block('src/30_kit/09_hud.lua', '-- [hud:begin]', '-- [hud:end]');
const THEME_SRC = fs.readFileSync(path.join(ROOT, 'src/00_core/02_theme.lua'), 'utf8').replace(/^﻿/, '');
const CONFIG_SRC = fs.readFileSync(path.join(ROOT, 'src/00_core/01_config.lua'), 'utf8');

const PRE = `
  Color3 = { fromRGB = function(r, g, b) return { r = r, g = g, b = b } end }
  CONFIG = { DefaultTheme = "HYGE" }
  V8 = {}
  function near(a, b, what) assert(math.abs(a - b) < 1e-6, (what or "") .. ": " .. a .. " ~= " .. b) end
`;
const run = code => runLua([{ name: 'brand.lua', code: PRE + BRAND + '\n' + code }]);
// a paleta: 02_theme.lua inteiro no mesmo chunk (PALETTES e THEME_ORDER são locais)
const runTheme = code => runLua([{ name: 'theme.lua',
  code: PRE + THEME_SRC + '\n' + BRAND + '\n' + HUD + '\n' + code }]);

test('triângulo: equilátero, os traços ligam os vértices e tudo cabe na caixa', () => {
  run(`
    local G = V8.Brand.TriGeom
    local function d(a, b) return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2) end
    -- tamanhos usados no painel (marca 26/28/34, faixa 96) e alguns a mais
    for _, case in ipairs({ { 26, 2 }, { 28, 2 }, { 34, 3 }, { 96, 3 }, { 200, 5 }, { 12, 2 } }) do
      local w, t = case[1], case[2]
      local h, edges, v = G(w, t)
      local tag = w .. "/" .. t
      local c = w - t
      near(d(v[1], v[2]), c, "base " .. tag)
      near(d(v[2], v[3]), c, "direita " .. tag)
      near(d(v[3], v[1]), c, "esquerda " .. tag)
      -- cada traço (rotação no sentido horário, y para baixo, como no Roblox)
      -- vai de um vértice ao outro, com meia espessura a mais em cada ponta
      local ends = { { 1, 2 }, { 1, 3 }, { 3, 2 } }   -- base, esquerda, direita
      for i, e in ipairs(edges) do
        local a = math.rad(e[4])
        local half = (e[3] - t) / 2
        local p = { e[1] - half * math.cos(a), e[2] - half * math.sin(a) }
        local q = { e[1] + half * math.cos(a), e[2] + half * math.sin(a) }
        near(d(p, v[ends[i][1]]), 0, "traço " .. i .. " início " .. tag)
        near(d(q, v[ends[i][2]]), 0, "traço " .. i .. " fim " .. tag)
        near(e[3], c + t, "comprimento " .. tag)
      end
      -- as pontas redondas (raio t/2 nos vértices) encostam nas bordas da caixa
      local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
      for _, p in ipairs(v) do
        minX = math.min(minX, p[1] - t / 2); maxX = math.max(maxX, p[1] + t / 2)
        minY = math.min(minY, p[2] - t / 2); maxY = math.max(maxY, p[2] + t / 2)
      end
      near(minX, 0, "esquerda da caixa " .. tag); near(maxX, w, "direita da caixa " .. tag)
      near(minY, 0, "topo da caixa " .. tag); near(maxY, h, "base da caixa " .. tag)
    end
  `);
});

test('miolo do triângulo: faixas sem fresta, do topo à base, escondidas pelo contorno', () => {
  run(`
    for _, case in ipairs({ { 26, 2 }, { 34, 3 }, { 96, 3 }, { 200, 5 } }) do
      local w, t = case[1], case[2]
      local _, _, v = V8.Brand.TriGeom(w, t)
      local top, base, c = v[3][2], v[1][2], w - t
      local bands = V8.Brand.TriFill(w, t, 3)
      assert(#bands >= 3, "poucas faixas")
      local y = top
      for i, b in ipairs(bands) do
        near(b[1], y, "faixa " .. i .. " começa onde a anterior terminou")
        assert(b[2] > 0 and b[2] <= 3 + 1e-9, "altura da faixa " .. i)
        assert(b[3] >= 0, "largura negativa")
        -- nas duas pontas da faixa, o degrau (diferença para o triângulo de
        -- verdade, de cada lado) é menor que meio traço: o contorno cobre
        for _, yy in ipairs({ b[1], b[1] + b[2] }) do
          local trueHalf = (c / 2) * (yy - top) / (base - top)
          assert(math.abs(b[3] / 2 - trueHalf) <= t / 2 + 1e-9,
            "degrau aparecendo na faixa " .. i .. " (" .. w .. "/" .. t .. ")")
        end
        y = b[1] + b[2]
      end
      near(y, base, "o miolo chega na base")
    end
  `);
});

test('versões: comparação numérica (não alfabética)', () => {
  run(`
    local O = V8.Brand.Older
    assert(O("v9.3", "v9.4") and O("v8.2", "v9.4") and O("v9.3.1", "v9.4"))
    assert(O("9.3", "v9.4"), "sem o v")
    assert(not O("v9.4", "v9.4") and not O("v9.4.1", "v9.4") and not O("v10.0", "v9.4"))
    assert(not O("v9.10", "v9.4"), "9.10 vem depois de 9.4")
    assert(O("v9.4", "v9.10"))
    -- ilegível: não é "anterior" (não mexe em nada)
    for _, x in ipairs({ "lixo", "", "v", 94 }) do assert(not O(x, "v9.4"), tostring(x)) end
    assert(not O(nil, "v9.4"))
  `);
});

test('tema padrão antigo (Grafite) passa uma vez para o HYGE; o resto fica', () => {
  run(`
    local T = V8.Brand.ThemeFor
    local function is(theme, version, want, moved)
      local t, m = T(theme, version)
      assert(t == want and m == moved, tostring(theme) .. " @ " .. tostring(version)
        .. " -> " .. tostring(t) .. " " .. tostring(m))
    end
    is("Grafite", "v9.3", "HYGE", true)       -- padrão antigo: troca
    is("Grafite", "v8.2", "HYGE", true)
    is("Grafite", nil, "HYGE", true)          -- config sem versão = antiga
    is("Grafite", "v9.4", "Grafite", false)   -- voltou para o Grafite depois: fica
    is("Grafite", "v9.5", "Grafite", false)
    is("Grafite", "lixo", "Grafite", false)   -- versão ilegível: não mexe
    is("Azul", "v9.3", "Azul", false)         -- escolheu outro tema: fica
    is("Personalizado", "v9.0", "Personalizado", false)
    is(nil, "v9.3", nil, false)
  `);
});

test('a versão do painel nunca é anterior à da troca (senão ela repetiria a cada boot)', () => {
  const version = (CONFIG_SRC.match(/Version\s*=\s*"([^"]+)"/) || [])[1];
  assert.ok(version, 'CONFIG.Version não achado');
  run(`assert(not V8.Brand.Older("${version}", V8.Brand.SINCE), "${version} < " .. V8.Brand.SINCE)`);
  // e a troca só acontece na config do disco (perfil/importação mantêm o tema)
  const persist = fs.readFileSync(path.join(ROOT, 'src/50_v8/03_persist.lua'), 'utf8');
  const load = persist.slice(persist.indexOf('C.Load = function'));
  assert.ok(load.indexOf('ThemeFor(d.theme, d.version)') > 0, 'C.Load não chama ThemeFor');
  assert.ok(load.indexOf('ThemeFor') < load.indexOf('pcall(C.Restore, d)'), 'ThemeFor depois do Restore');
  assert.equal(persist.slice(0, persist.indexOf('C.Load = function')).indexOf('ThemeFor'), -1,
    'ThemeFor fora do C.Load (o Restore também serve perfis e importação)');
});

test('padrão: HYGE, primeiro da lista; todos os temas com as mesmas chaves', () => {
  assert.match(CONFIG_SRC, /DefaultTheme\s*=\s*"HYGE"/);
  runTheme(`
    assert(THEME_ORDER[1] == "HYGE", "HYGE não é o primeiro")
    assert(THEME.Accent == PALETTES.HYGE.Accent, "o painel não nasce no HYGE")
    assert(V8.Brand.NEW_DEFAULT == "HYGE" and PALETTES[V8.Brand.OLD_DEFAULT])
    local seen = {}
    for _, n in ipairs(THEME_ORDER) do
      assert(PALETTES[n], n .. " na lista sem paleta")
      assert(not seen[n], n .. " repetido na lista")
      seen[n] = true
    end
    for n in pairs(PALETTES) do assert(seen[n], n .. " fora de THEME_ORDER") end
    -- a troca de tema copia chave por chave: chave faltando num tema deixaria
    -- a cor do tema anterior
    local ref = PALETTES.Grafite
    for name, p in pairs(PALETTES) do
      for k in pairs(ref) do assert(p[k], name .. " sem " .. k) end
      for k in pairs(p) do assert(ref[k], name .. " com chave a mais: " .. k) end
    end
  `);
});

test('contraste legível no tema HYGE, na faixa do Início e nas barras do HUD', () => {
  runTheme(`
    local function lin(c) c = c / 255 return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
    local function L(x) return 0.2126 * lin(x.r) + 0.7152 * lin(x.g) + 0.0722 * lin(x.b) end
    local function ratio(a, b)
      local la, lb = L(a), L(b)
      if la < lb then la, lb = lb, la end
      return (la + 0.05) / (lb + 0.05)
    end
    local P = PALETTES.HYGE
    -- texto: 7:1 (AAA); texto secundário, destaque e estados: 4.5:1 (AA)
    local checks = {
      { "Text", "Main", 7 }, { "Text", "Card", 7 }, { "Text", "Btn", 7 },
      { "Dim", "Main", 4.5 }, { "Dim", "Card", 4.5 }, { "Dim", "Btn", 4.5 },
      { "Accent", "Main", 4.5 }, { "Accent", "Card", 4.5 }, { "Accent2", "Card", 4.5 },
      { "Danger", "Card", 4.5 }, { "Success", "Card", 4.5 }, { "Warning", "Card", 4.5 },
      { "Main", "Accent", 4.5 },   -- texto escuro do botão em hover / sub-aba ativa
    }
    for _, c in ipairs(checks) do
      local r = ratio(P[c[1]], P[c[2]])
      assert(r >= c[3], c[1] .. " sobre " .. c[2] .. ": " .. string.format("%.2f", r))
    end
    -- faixa do Início: texto claro sobre o azul do logo
    local royal = { r = 44, g = 40, b = 196 }
    assert(ratio(P.Text, royal) >= 7, "saudação sobre o azul da faixa")
    -- barras do HUD (cores fixas)
    local C = V8.Hud.C
    assert(ratio(C.Text, C.Glass) >= 7, "texto da ilha")
    assert(ratio(C.Dim, C.Glass) >= 4.5, "texto apagado da ilha")
    assert(ratio(C.Neon, C.Glass) >= 4.5, "ícone ativo do dock")
    assert(ratio(C.IconDim, C.Glass) >= 7, "ícones do dock")
  `);
});

test('o azul da faixa no código é o mesmo conferido no contraste', () => {
  const src = fs.readFileSync(path.join(ROOT, 'src/30_kit/10_brand.lua'), 'utf8');
  assert.match(src, /B\.ROYAL = Color3\.fromRGB\(44, 40, 196\)/);
});
