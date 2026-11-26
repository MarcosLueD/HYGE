// v9.3 — barras do HUD: o que dá para conferir fora do Roblox.
// O visual (vidro, neon, animações) só dá para ver no jogo (docs/TESTES.md);
// aqui ficam as regras: qualidade da conexão pelo ping, cor do FPS e a
// geometria do dock recolhível (nunca meio visível; a alça sempre à vista e
// nunca embaixo da janela).
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { runLua, block } = require('./helpers/lua');
const { ROOT } = require('./helpers/project');

const HUD = block('src/30_kit/09_hud.lua', '-- [hud:begin]', '-- [hud:end]');
const GEO = block('src/50_v8/00_dock.lua', '-- [dockgeo:begin]', '-- [dockgeo:end]');
const PRE = `
  Color3 = { fromRGB = function(r, g, b) return { r = r, g = g, b = b } end }
  V8, K = {}, {}
`;
const run = code => runLua([{ name: 'hud.lua', code: PRE + HUD + '\n' + GEO + '\n' + code }]);

test('qualidade da conexão pelo ping: barras, cor e nome', () => {
  run(`
    local Q = V8.Hud.Quality
    local cases = {
      { 0, 4, "Good" }, { 40, 4, "Good" }, { 80, 4, "Good" },
      { 81, 3, "Good" }, { 150, 3, "Good" },
      { 151, 2, "Warn" }, { 280, 2, "Warn" },
      { 281, 1, "Bad" }, { 5000, 1, "Bad" },
    }
    for _, c in ipairs(cases) do
      local n, key = Q(c[1])
      assert(n == c[2] and key == c[3], c[1] .. " ms -> " .. n .. " " .. key)
    end
    -- sem dado (antes da primeira medida, valor estranho): nenhuma barra acesa
    for _, v in ipairs({ "x", -1, 0/0, math.huge }) do
      local n, key = Q(v)
      assert(n == 0 and key == "Dim", "valor " .. tostring(v))
    end
    local n, key = Q(nil)
    assert(n == 0 and key == "Dim")
    -- toda chave devolvida existe na paleta do HUD
    for _, k in ipairs({ "Good", "Warn", "Bad", "Dim" }) do assert(V8.Hud.C[k], k) end
  `);
});

test('FPS só ganha cor quando pede atenção', () => {
  run(`
    local F = V8.Hud.FpsKey
    assert(F(60) == "Text" and F(50) == "Text")
    assert(F(49) == "Warn" and F(30) == "Warn")
    assert(F(29) == "Bad" and F(1) == "Bad")
    assert(F(nil) == "Text" and F(0/0) == "Text")
  `);
});

test('dock recolhido fica inteiro abaixo da tela; a alça continua à vista', () => {
  run(`
    -- alturas reais: normal, celular (escala 0.6), escala maior, e sem medida
    for _, h in ipairs({ 56, 33.6, 80, 0 }) do
      local t = K.Targets(true, h)
      local real = (h > 0) and h or K.H
      -- AnchorPoint embaixo: a borda de cima do dock fica em t.bar - altura
      -- (positivo = abaixo do rodapé da tela)
      assert(t.bar - real >= 1, "dock aparecendo com altura " .. h .. ": " .. (t.bar - real))
      -- a alça: base acima do rodapé e topo dentro da tela
      assert(t.handle < 0, "alça abaixo do rodapé")
      assert(-t.handle + K.HANDLE_H <= 40, "alça longe demais do rodapé")
    end
  `);
});

test('dock aberto: a alça fica logo acima dele, sem encostar nem ficar embaixo da janela', () => {
  run(`
    for _, h in ipairs({ 56, 33.6 }) do
      local t = K.Targets(false, h)
      assert(t.bar == -K.BOTTOM, "o dock saiu do lugar de sempre")
      local barTop = K.BOTTOM + h
      local handleBottom = -t.handle
      assert(handleBottom >= barTop, "alça em cima do dock (" .. h .. ")")
      assert(handleBottom - barTop <= 4, "alça longe do dock (" .. h .. ")")
      -- a janela "em casa" nasce acima de Reserve(): a alça nunca fica embaixo dela
      assert(handleBottom + K.HANDLE_H <= K.Reserve(), "a janela cobriria a alça (" .. h .. ")")
    end
    -- e o recolhido não muda a reserva (recolher não mexe na janela)
    assert(K.Reserve() == K.BOTTOM + K.H + K.HANDLE_GAP + K.HANDLE_H + 6)
  `);
});

test('o estado recolhido e a moldura vão para a config (e para os perfis)', () => {
  const keys = block('src/50_v8/03_persist.lua', 'local SET_KEYS = {', '}');
  for (const k of ['DockHidden', 'TopbarFrame', 'Dock', 'Island']) {
    assert.match(keys, new RegExp('"' + k + '"'), k + ' fora da lista de SET_KEYS');
  }
  // os perfis não pulam essas chaves
  const prof = fs.readFileSync(path.join(ROOT, 'src/50_v8/10_profiles.lua'), 'utf8');
  const skip = (prof.match(/local SKIP = \{[^}]*\}/) || [''])[0];
  assert.doesNotMatch(skip, /DockHidden|TopbarFrame/);
});
