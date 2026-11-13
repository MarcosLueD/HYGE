# HYGE Admin Panel v8.0

Painel admin client-side para Roblox (executor ou LocalScript) + script de
servidor opcional para as ações que afetam outros jogadores.

## Estrutura

```
HYGE/
├── main.lua            ← GERADO pelo build. É o arquivo que vai pro executor.
├── src/                ← código-fonte, dividido por assunto (edite aqui)
│   ├── 00_core/        config, temas, checagem de admin, estado, helpers
│   ├── 10_ui/          janela, toasts, console, topbar/sidebar, fábrica de UI, toggles/keybinds
│   ├── 20_features/    fly, noclip/god/invisível/paredes, ESP, chat spy/fullbright/anti-afk,
│   │                   freecam, drone, ações de moderação/troll, spectate
│   ├── 30_kit/         widgets v7 (sliders, switches, confirmação), ícones, chips, HUD do drone
│   ├── 40_tabs/        uma aba por arquivo: home, dashboard, movement, visuals, players,
│   │                   moderation, server, emotes, settings, shop, scripts, chat
│   ├── 50_v8/          dock, shell, situações, persistência (config.json), busca global
│   └── 90_runtime/     comandos, abrir/fechar/arrastar, teclas, scheduler, eventos, unload, boot
├── server/             ← opcional: vai no SEU jogo pelo Roblox Studio
│   ├── HYGE_AdminServer.server.lua   (ServerScriptService)
│   └── HYGE_AdminClient.client.lua   (StarterPlayer › StarterPlayerScripts)
├── tools/check.js      validador estático (usado pelo build)
└── build.js            junta src/ → main.lua
```

A ordem do build é a ordem alfabética do caminho — por isso os prefixos
`00_`, `10_`, ... Um módulo pode usar tudo que foi declarado nos anteriores.

## Gerar o main.lua

Precisa do [Node.js](https://nodejs.org). Uma vez só:

```
npm install
```

Depois de editar qualquer coisa em `src/`:

```
npm run build      # valida e grava main.lua
npm run check      # só valida, não grava
```

O build **não grava** o `main.lua` se encontrar:

- erro de sintaxe — mostra `src/arquivo.lua:linha`
- variável global desconhecida (quase sempre erro de digitação ou local fora
  de escopo) — no Roblox isso só explodiria em jogo
- mais de **200 locais** no chunk principal (limite do Luau: o script nem
  carrega). O painel está em ~187. Código novo vai dentro de `do ... end` ou
  pendurado na tabela `V8` — nunca como `local` solto no topo de um módulo.

Se o `main.lua` for editado à mão, o build se recusa a sobrescrever (para não
apagar sua mudança). Leve a mudança para `src/` ou use `node build.js --force`.

## Servidor (opcional, só em jogo seu)

Sem os RemoteEvents, kick/bring/freeze/anúncio/mensagem/troll ficam
indisponíveis no painel (com aviso — nada é simulado). Para ativar:

1. No Roblox Studio, crie um **Script** em `ServerScriptService` e cole
   `server/HYGE_AdminServer.server.lua`.
2. Crie um **LocalScript** em `StarterPlayer › StarterPlayerScripts` e cole
   `server/HYGE_AdminClient.client.lua` (mostra anúncios e mensagens privadas
   no chat de todos os jogadores).
3. No topo do script de servidor, coloque os UserIds dos admins em
   `CONFIG.AdminIds` (os mesmos do `CONFIG.AdminIds` do painel). O dono do
   jogo já é admin por padrão; também dá para liberar um rank de grupo.

O servidor valida tudo (admin, alvo, cooldown, tamanho do texto), passa
anúncios e mensagens pelo filtro de texto do Roblox (se o filtro falhar, nada
é enviado) e devolve a confirmação real para o console do painel
(`[ADMIN HYGE] ✓ Kick: Fulano`). A aba **Server** mostra quantos dos 13
Remotes foram encontrados.

> Esses scripts não foram testados dentro de um jogo — teste no Studio
> (Play com 2 jogadores em *Test › Clients and Servers*) antes de publicar.

## Navegação (dock)

O dock fica solto no rodapé da tela, sempre visível — é ele que abre o painel.
O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel. A
janela (em pé, 460×520) nasce logo acima dele, com o título da seção e o selo
HYGE no topo.

| Ícone | Seção | Dentro da seção |
|---|---|---|
| casinha | Início | sub-abas Painel · Servidor |
| pessoa | Personagem | sub-abas Movimento · Visual |
| sacola | Shop | (em breve) |
| terminal | Scripts | barra de sub-ícones acima do dock: Console · Emotes |
| pessoas | Jogadores | sub-abas Lista · Moderação |
| engrenagem | Configurações | — |
| balão | Chat | chat do servidor + enviar/privado |

No alto da tela fica a **ilha** (hora, FPS e ping; clique abre/fecha o painel)
— desliga em Configurações › Ilha no topo.

Prefere a navegação antiga? **Configurações › Navegação › Usar dock de ícones**
desligado volta para a janela larga com sidebar (e a bolinha H para abrir).

## Teclas padrão

| Tecla | Ação |
|---|---|
| `B` | abre/fecha o painel |
| `;` | barra de comandos (`help` lista tudo) |
| `Ctrl+K` | busca global |
| `Keypad 1–6` | situações (Moderação, Caça, Observação, Movimento, Stealth, Limpeza) |
| `F` `N` `E` `C` `G` | fly, noclip, ESP, freecam, drone |

Tudo remapeável em **Ajustes**. Com freecam/drone/fly ligados, as teclas que
eles usam para se mover (WASD, E/Q, Space, Ctrl, Shift) não disparam atalhos.

Janela perdida fora da tela: comando `center` ou **Ajustes › Sistema ›
Centralizar janela**.

## Config em disco

`HYGE/config.json` (pasta do executor) guarda keybinds, tema, escala,
velocidades, opções de ESP, waypoints, emotes favoritos, a última situação e a
posição da janela. Executor sem `writefile`/`readfile`: use
**Exportar/Importar** pelo clipboard em Ajustes.

## Versão anterior

A v7.0 era um `main.lua` único. Para recuperar aquele arquivo, use o
histórico de versões do OneDrive (botão direito no `main.lua` › *Histórico de
versões*).
