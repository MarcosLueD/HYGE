# HYGE Admin Panel v8.1

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
│   │                   freecam, drone, ações de moderação/troll, spectate,
│   │                   anti-fall/anti-gravidade, walk on walls
│   ├── 30_kit/         widgets v7 (sliders, switches, confirmação), ícones, chips, HUD do drone,
│   │                   rede/disco do executor, tempo de jogo + cosméticos (Playtime Shop)
│   ├── 40_tabs/        uma aba por arquivo: home (+ mapa/perfil), dashboard, movement, visuals,
│   │                   players, moderation, server, emotes, settings, shop, scripts, chat,
│   │                   troll, chat HYGE
│   ├── 50_v8/          dock, shell, situações, persistência (config.json), busca global,
│   │                   ilha, automático
│   └── 90_runtime/     comandos, abrir/fechar/arrastar, teclas, scheduler, eventos, unload, boot
├── server/             ← opcional
│   ├── HYGE_AdminServer.server.lua   (no SEU jogo: ServerScriptService)
│   ├── HYGE_AdminClient.client.lua   (no SEU jogo: StarterPlayer › StarterPlayerScripts)
│   └── chat-relay/server.js          (relay do Chat HYGE: roda num servidor Node seu)
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
  Os módulos da v8.1 usam `do local function Build() ... end Build() end`:
  as locais ficam dentro da função e não contam no chunk.

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
| casinha | Início | Painel (mapa atual, perfil com tempo de jogo, Rejoin / Trocar servidor / Discord) · Servidor |
| pessoa | Personagem | Movimento (Fly, Noclip, Anti-Fall, Anti-Gravidade, WalkSpeed, JumpPower...) · Visual |
| sacola | Playtime Shop | loja paga com tempo de jogo: All, Ranks, Icons, Titles, Effects, Nametags, Bundles |
| máscara | Troll | Walk on Walls + ações no alvo (Fling, Spin... — precisam do servidor) |
| carinha | Emotes | catálogo pesquisável, Playback Speed, andar com o emote, por ID, favoritos |
| pessoas | Jogadores | Lista (busca + ALVO / ESP / TP / SPEC por jogador) · Moderação |
| engrenagem | Configurações | Ajustes (tamanho da GUI, automático, keybinds, temas...) · Console |
| balão | Chat | HYGE (entre usuários do painel, via relay) · Jogo (chat do servidor) |

No alto da tela fica a **ilha** (hora, FPS e ping; clique abre/fecha o painel)
— desliga em Configurações › Ilha no topo.

Prefere a navegação antiga? **Configurações › Navegação › Usar dock de ícones**
desligado volta para a janela larga com sidebar (e a bolinha H para abrir).

### O que cada seção nova faz (v8.1)

- **Início › Trocar servidor** lê a lista pública de servidores do jogo
  (`games.roblox.com`, pelo HTTP do executor) e entra num com vaga. Sem HTTP,
  faz um Teleport comum — o Roblox escolhe e pode cair no mesmo. **Discord**
  copia `CONFIG.Discord` (no topo do script); vazio, ele avisa em vez de copiar.
- **Playtime Shop**: 1 ponto por minuto com o HYGE aberto, salvo em
  `HYGE/playtime.json` a cada minuto (e no unload). Tudo é visual: rank, ícone
  e título aparecem no perfil da Home e no Chat HYGE; **Effects e Nametags são
  criados pelo seu cliente no seu personagem — só você vê**. Sem `writefile`, o
  tempo vale só para a sessão.
- **Personagem**: Anti-Fall desliga tombo/ragdoll, corta a velocidade de queda
  antes do impacto e devolve você ao último chão se cair no void. Anti-Gravidade
  baixa `workspace.Gravity` no seu cliente (só a sua física muda).
- **Fly (v8.1.1)**: voa com as animações do próprio personagem — nadar em
  movimento (o corpo deita na direção do voo) e flutuar parado. Todo mundo vê.
  Em R6 usa a pose do painel, que só você vê. Ajustes em Personagem ›
  Velocidades; para usar uma animação sua (só em jogo seu), `CONFIG.FlyAnimR15`.
- **Troll › Walk on Walls**: anda em paredes e tetos (WASD segue a câmera, Space
  pula). Os outros veem você na parede. As ações no alvo continuam dependendo
  dos Remotes de `server/`.
- **Emotes**: os "Padrão" vêm do script Animate do seu personagem e sempre
  tocam. O resto do catálogo são emotes publicados pela Roblox (R15): os IDs
  não foram conferidos um a um em jogo — o que não carregar é avisado no console
  e marcado na lista.
- **Jogadores › ESP** numa linha mostra o ESP só dos marcados (liga o ESP se
  estiver desligado; desmarcar o último devolve como estava).
- **Configurações**: a tecla do painel agora é remapeável; **Automático** liga
  funções sozinho ao carregar; **Reconectar se cair** tenta entrar de novo
  quando aparece a tela de erro.

## Chat HYGE (relay)

Clientes do Roblox não conversam direto entre si, então o Chat HYGE passa por
um servidor pequeno seu: `server/chat-relay/server.js` (Node 18+, sem
dependências).

```
npm run chat                      # porta 8787
PORT=8080 HYGE_CHAT_KEY=senha npm run chat
```

Hospede onde quiser (VPS, Render, Railway, Fly.io — atrás de proxy use
`TRUST_PROXY=1`) e cole a URL em **Chat › HYGE › Conexão** ou em
`CONFIG.ChatRelay`. Com senha, coloque a mesma em `CONFIG.ChatKey`.

- Salas: **Este servidor** (mesmo JobId) e **Global**. Guarda as últimas 100
  mensagens por sala, só na memória; reiniciou, o histórico some.
- Limites: 200 caracteres, 1 mensagem por segundo (por UserId e por IP).
- **O relay não verifica identidade**: nome e UserId vêm do cliente. Use um
  relay seu e, se for público, com senha.
- O painel precisa de `request()` do executor para enviar; só com
  `game:HttpGet` ele lê mas não envia (e avisa).

## Teclas padrão

| Tecla | Ação |
|---|---|
| `B` | abre/fecha o painel (remapeável em Configurações › Keybinds) |
| `;` | barra de comandos (`help` lista tudo) |
| `Ctrl+K` | busca global |
| `Keypad 1–6` | situações (Moderação, Caça, Observação, Movimento, Stealth, Limpeza) |
| `F` `N` `E` `C` `G` | fly, noclip, ESP, freecam, drone |

Tudo remapeável em **Ajustes**. Com freecam/drone/fly ligados, as teclas que
eles usam para se mover (WASD, E/Q, Space, Ctrl, Shift) não disparam atalhos.

Janela perdida fora da tela: comando `center` ou **Ajustes › Sistema ›
Centralizar janela**.

## Config em disco

`HYGE/config.json` (pasta do executor) guarda keybinds (inclusive a tecla do
painel), tema, escala, velocidades e gravidade, opções de ESP, waypoints, emotes
favoritos, funções automáticas, endereço do Chat HYGE, a última situação e a
posição da janela. O tempo de jogo e os itens da Playtime Shop ficam à parte, em
`HYGE/playtime.json`. Executor sem `writefile`/`readfile`: use
**Exportar/Importar** pelo clipboard em Ajustes.

## Versão anterior

A v7.0 era um `main.lua` único. Para recuperar aquele arquivo, use o
histórico de versões do OneDrive (botão direito no `main.lua` › *Histórico de
versões*).
