# Changelog

## v9.1

Versão de estabilidade: não perder configuração, não instalar build ruim,
perfil nunca pela metade, servidor auditado e vazamentos à vista.

### Testes automáticos (`npm test`)
- `tests/` com o test runner do Node: build (módulos, ordem, isolamento,
  sintaxe, globais, limite de 200 locais/upvalues, `main.lua` editado à mão),
  gravação segura, SHA-256 e loader, troca de perfil, servidor e conexões.
- O código Lua roda de verdade nos testes (`fengari`, devDependency).
- `build.js` agora exporta as funções (a linha de comando continua igual).

### Backup e recuperação
- Config, perfis e tempo de jogo gravam assim: `.tmp` conferido → backup da
  versão anterior (só se ela for válida) → principal conferido → apaga o `.tmp`.
  Uma queda em qualquer passo não perde a última config boa (testado com queda
  simulada em cada gravação).
- Config estragada ao abrir: o painel pergunta se quer recuperar; o
  salvamento automático fica parado até lá. **RECUPERAR BACKUP** e o comando
  `recover` (`recover perfis`) também desfazem o último salvamento ou um RESETAR.
- Perfis e tempo de jogo estragados voltam sozinhos do backup (antes a lista
  começava vazia e o próximo salvamento apagava tudo).

### Integridade do loader e da atualização
- O build gera `manifest.json` (versão, build, tamanho e SHA-256 do texto LF).
- O loader lê o manifesto primeiro; se a cópia local já é esse build, nem
  baixa. Download é conferido (tamanho, SHA-256, build, compila) antes de
  qualquer arquivo ser trocado; a versão anterior vira `main.backup.lua`.
  Qualquer falha abre a última versão que funcionava.
- SHA-256 em Lua puro (sem depender do executor), o mesmo bloco no loader e no
  painel. ATUALIZAR AGORA também confere com o manifesto.

### Troca segura de perfis
- Validação completa antes de mexer em qualquer coisa (tipos, números finitos,
  faixas). Perfil inválido não muda nada.
- Preferências aplicadas tudo-ou-nada, com conferência no fim; deu erro no
  meio, volta ao estado anterior. As funções só ligam depois, separadas; a que
  não ligar vai para o relatório. Freecam e Drone continuam nunca ligando.
- O resultado vai para o log e para o Diagnóstico.

### Servidor auditado
- Argumentos validados por RemoteEvent; UserId do alvo inteiro e de alguém no
  servidor (funciona com os UserIds negativos do Studio).
- Limite por ação (`CONFIG.Cooldowns`) em vez de um único para tudo.
- Registro de ações aceitas **e** recusas (`shared.HYGE_AUDIT` + Output, sem spam).
- Texto conferido antes de processar, corte sem partir UTF-8, mensagem
  censurada inteira pelo filtro não é enviada.
- Roteiro de teste no Studio em `docs/TESTES.md` (o servidor ainda precisa
  ser testado lá antes de publicar).

### Diagnóstico de memória e conexões
- Conexões criadas / ativas / encerradas, ativas por módulo e monitor de
  respawn; tarefas agendadas, pendentes e rodando.
- Trocar `Conn.X` sem `Drop` agora desconecta a antiga (antes vazava).
- Unload confere se ficou limpo (`CLEAN` ou o que sobrou), avisa tarefa que
  rodar depois dele e grava o resultado para a próxima sessão.
- Rodar o script de novo descarrega a instância anterior de verdade (antes só
  a GUI sumia e as conexões dela continuavam rodando).
- Slider arrastado durante o unload não deixa mais conexão para trás.
- `tools/leaks.js`: acusa conexão em serviço/jogador que não esteja no `Conn`.

### Outros
- Shift Lock do Roblox bloqueado (Configurações › Comportamento): o Shift não
  prende mais o mouse no centro — o Fly usa o Shift para acelerar.

## v9.0

A maior atualização até agora: o painel ficou mais organizado, mais seu e
mais difícil de quebrar.

### Configurações organizadas
- **Categorias** no topo de Configurações › Ajustes: Tudo · Geral · Teclas ·
  Visual · Dados · Sistema. Os ~20 cartões passam a seguir essa ordem.
- **Busca dentro dos ajustes**, sem acento ("aparencia" acha "Aparência") e
  olhando também o texto de cada opção do cartão.
- A busca global (Ctrl+K) acha os cartões de ajuste (abre já filtrado) e os
  perfis, e também ficou sem acento.

### Favoritos
- Toda linha de função ganhou uma **estrela**. As funções com estrela são as
  **Ações rápidas** da Home (padrão: as 8 de antes; até 12). Comando `fav`.

### Perfis
- Configurações › Dados › **Perfis**: o painel inteiro salvo com um nome —
  tema, tamanho, teclas, macros, velocidades, ESP, favoritos, ajustes e as
  funções ligadas. **USAR** troca tudo de uma vez.
- **JOGO**: o perfil abre sozinho toda vez que você entra neste jogo.
- Ficam fora do perfil: waypoints (são por jogo), emotes favoritos, notas,
  pacotes de animação e a posição da janela. Freecam e Drone nunca ligam
  sozinhos. Arquivo próprio: `HYGE/profiles.json` (até 10 perfis).
- Comando `perfil list | save <nome> | use <nome> | del <nome> | jogo <nome|off>`.

### Notificações
- Todo aviso fica guardado (os últimos 60) no **sino da ilha** do topo. O
  número conta só o que pede atenção (avisos, erros, mensagens longas);
  "Fly ativado" fica na lista mas não acende o sino. Repetido vira "x2".
- **Não perturbe**: nada pula na tela (menos erro), tudo vai para o sino.
- **Tempo dos avisos na tela**: 50% a 200%.
- Comando `notif [limpar|dnd]`.

### Macros de teclado
- Configurações › Teclas › **Macros**: uma tecla roda qualquer comando da
  barra (`tp joao`, `sit caça`, `theme rosa`...). Vários de uma vez com `&&`.
  Até 12. O botão ▶ de cada linha testa sem precisar da tecla.
- A tecla não pode ser de outra coisa; dar a tecla de uma macro para uma
  função, situação ou para o painel tira a tecla da macro (com aviso). Com
  Fly/Freecam/Drone/Walk on Walls ligados, as teclas de movimento não disparam
  macro.

### Temas
- Três temas novos: **Rosa**, **Laranja** e **Meia-noite**.
- **Cor personalizada**: escolha matiz e intensidade (com prévia); o fundo
  ganha um leve tom da cor. Com o tema ativo, os sliders mudam ao vivo.
  `theme personalizado`. O comando `theme` aceita nome sem acento e sem nome
  lista os temas.

### Estabilidade e diagnóstico
- **Módulos isolados**: o build embrulha cada módulo em `V8.Mod(...)`. Se um
  módulo quebrar ao carregar, só ele falha — o painel abre e o boot diz qual
  foi e em que linha.
- **Erros apontam para o `src/`**: o log troca `HYGE:12345:` por
  `src/arquivo.lua:linha` (mapa `V8.SrcMap` no fim do `main.lua`).
- Configurações › Sistema › **Diagnóstico**: o que o executor suporta
  (request, HttpGet, arquivos, clipboard, loadstring, gethui, getgenv,
  GetObjects), tempo de boot, módulos mais lentos, memória, conexões e os
  últimos erros. **COPIAR RELATÓRIO**. Comando `diag [copiar]`.
- **Config salva sozinha** a cada 30 s quando algo muda. Antes ela só ia para
  o disco ao descarregar o painel — quem saía do jogo perdia o que tinha
  mudado. Se o arquivo existir mas não der para ler, o automático não
  sobrescreve até você salvar na mão.
- A lista de amigos da Home (chamada web) carrega em paralelo: o painel abre
  sem esperar por ela.

### Outros
- Cartão de **novidades** na primeira abertura de cada versão; quem nunca usou
  vê os primeiros passos. Reabre em Configurações › Sobre ou `novidades`.
- Locais no chunk principal: 187 → 168 (o isolamento tira as locais dos
  blocos do chunk) — sobra espaço para as próximas versões.
- `tools/check.js` conhece `identifyexecutor`, `getexecutorname` e `gcinfo`.

## v8.2

### Pacote de animação no personagem todo
- Novo cartão **Personagem › Pacote de animação**: cole o ID ou o link de um
  pacote do catálogo; o painel lê a lista de itens (AssetService ou catálogo
  público) e abre cada item com `game:GetObjects`. O resultado fica na config.
- **USAR** troca os IDs do script `Animate` do seu personagem e reinicia ele —
  andar, correr, pular, parado, cair, escalar e nadar com o pacote, e os outros
  jogadores veem. **VOLTAR AO NORMAL** devolve os IDs originais (o unload também).
  Reaplica sozinho no respawn e ao carregar o painel.
- **VOO** escolhe o pacote do Fly. `CONFIG.FlyPackBundle` aceita o ID do pacote
  direto (padrão: Super Gogeta DBZ); `FlyPackMoveSlot`/`FlyPackIdleSlot` dizem
  qual animação do pacote vai voando e parado.
- Super Gogeta DBZ e Endless Aura já vêm na lista (itens conferidos no catálogo).
- Comando `pack list | add <id> | use <nome> | fly <nome> | off`.

### Celular
- Botões na tela (Configurações › Celular e toque): FLY, e com o voo ligado
  SUBIR, DESCER e 2x. Ligado por padrão em aparelho com toque.
- O Fly usa o analógico (ControlModule) quando nenhuma tecla está apertada,
  seguindo a câmera. Controle no PC também funciona.
- Tela baixa: a janela do dock fica mais curta (300–520) para caber acima do
  dock; o dock encolhe (até 60%) se for mais largo que a tela.

### Playtime Shop: missões e bônus diário
- **Missões de hoje**: 30 min com o painel aberto (+20), voar 10 min (+30),
  5 emotes (+15), salvar 1 waypoint (+10), usar um pacote de animação (+10).
  Zeram à meia-noite; completa, aparece RESGATAR.
- **Bônus diário** na primeira abertura do dia: 10, 15, 20... até 40 com 7 dias
  seguidos; pulou um dia, volta a 10.
- Os pontos de missão/bônus entram no `bonus` do `playtime.json` (o tempo de
  jogo mostrado continua sendo o real). Comando `missoes [resgatar]`.

### Teleporte e waypoints
- Toggle **Ctrl + clique TP** (`clicktp`): leva até o ponto embaixo do mouse,
  em pé na superfície. Clique em cima de GUI não conta.
- Waypoints **por jogo** (`wpplaces` na config). A lista única da config antiga
  fica com o primeiro jogo em que a v8.2 abrir (o log avisa).

### Atualização
- `loader.lua` (raiz do repositório): cole no executor. Baixa o `main.lua` do
  GitHub, guarda cópia em `HYGE/main.lua`, abre a cópia se estiver offline.
- **Configurações › Atualização**: confere ao abrir e a cada 15 min (pelo build
  exato quando aberto pelo loader; pela versão quando colado direto). ATUALIZAR
  AGORA baixa, confere se compila, descarrega e abre a versão nova. Comando
  `update [now]`.
- `CONFIG.UpdateUrl` (padrão: o `main.lua` do repositório no GitHub).

### Outros
- Comandos `givepoints [n|max]` e `unlockall` (Playtime Shop).
- `tools/check.js` conhece `loadstring` e `getgenv`.

## v8.1.2

### Fly com o pacote Endless Aura (Aura Eterna Flutuante)
- Descoberto por que o pacote "nunca carregava": os IDs da config eram de
  **item do catálogo** (AssetType FallAnimation/IdleAnimation), não de animação.
  O item é uma caixa com um Animation dentro; o Animator recebia o ID errado.
- O Fly agora abre a caixa com `game:GetObjects` (executor), pega o ID real e
  toca: **Fall do pacote voando, Idle parado no ar**. O padrão passou a ser esse
  (`FlyStyle = "pacote"`).
- Primeira vez: enquanto o pacote é lido, voa com o nadar do jogo e troca
  sozinho quando fica pronto. O resultado fica em cache.
- Se o executor não tiver `game:GetObjects` ou o Roblox recusar o pacote neste
  jogo (o pacote é UGC, do grupo "Animations"), volta para o nadar e avisa.
- Personagem › Velocidades › **Animação do voo**: Aura flutuante · Nadar · Pose
  do painel. Escolher "Aura flutuante" de novo tenta o pacote outra vez.
- A config lista os IDs das outras animações do pacote (Run, Walk, Swim...)
  para quem quiser trocar a de voo.

## v8.1.1

### Animação de voo que todo mundo vê
- O Fly agora usa, por padrão, as animações do **próprio personagem**: a de
  nadar enquanto voa (o corpo deita na direção do voo, mais quanto mais rápido)
  e a de flutuar/cair parado no ar. Elas carregam em qualquer jogo e replicam
  para os outros jogadores — a pose antiga do painel escreve direto nas juntas
  no seu cliente, então só você via.
- Personagem › Velocidades: **Animação de voo do jogo** (desligado volta para a
  pose do painel) e **Inclinação voando** (0–90°). Os dois vão na config.
- Personagem R6 (não tem animação de nadar) ou jogo com Animate próprio sem ela:
  o Fly usa a pose do painel e avisa uma vez no console.
- Animação "parado no ar" que não carrega agora é descartada sozinha (antes o
  personagem ficava sem animação ao parar).
- Config: `FlyStyle` (`"jogo"` | `"pose"` | `"pacote"`), `FlySwimTilt`. Os IDs do
  Endless Aura viraram `FlyPackMove`/`FlyPackIdle` e só são usados com
  `FlyStyle = "pacote"`; `FlyAnimIdle` agora é a SUA animação de parado no ar.

## v8.1

### Dock de 8 seções
Início · Personagem · Playtime Shop · Troll · Emotes · Jogadores ·
Configurações · Chat. Scripts saiu do dock: o console virou a sub-aba
**Configurações › Console** e Emotes ganhou seção própria.

### Novidades
- **Início**: card **Mapa atual** (nome do jogo, Place ID, Job ID, jogadores) com
  **Rejoin**, **Trocar servidor** (lista pública de servidores pelo HTTP do
  executor; sem HTTP, Teleport comum) e **Discord** (copia `CONFIG.Discord`).
  Card **Perfil**: tempo de jogo, sessão, pontos da loja e idade da conta; o
  rank/título/ícone equipados aparecem no cartão do avatar.
- **Playtime Shop**: 1 ponto por minuto com o painel aberto
  (`HYGE/playtime.json`). Categorias All, Ranks, Icons, Titles, Effects,
  Nametags e Bundles (preço do pacote cai pelo que você já tem). Efeitos e
  nametag são locais — a loja diz que só você vê.
- **Personagem**: **Anti-Fall** (sem tombo/ragdoll, pouso suave, volta do void)
  e **Anti-Gravidade** com slider de 0–100% da gravidade.
- **Troll**: **Walk on Walls** (paredes, tetos, quinas; WASD + Space) e as ações
  no alvo que estavam em Moderação.
- **Emotes**: catálogo pesquisável (emotes padrão do jogo + emotes/danças da
  Roblox), filtro Danças/Emotes/Padrão, dança aleatória, **Playback Speed** e
  **Andar com o emote**. Animação recusada pelo Roblox (duração 0) agora é
  detectada, avisada e marcada na lista.
- **Jogadores**: cada linha tem ALVO, **ESP** (só daquele jogador), **TP** e
  **SPEC**.
- **Configurações**: **tecla do painel remapeável**, card **Automático** (funções
  que ligam ao carregar) e **Reconectar se cair**. "Escala da interface" virou
  "Tamanho da GUI".
- **Chat › HYGE**: conversa entre usuários do painel, sala do servidor e global,
  via relay próprio (`server/chat-relay`, `npm run chat`). Chat do jogo continua
  em **Chat › Jogo**.
- Comandos novos: `rejoin`, `hop`, `discord`, `gravity`, `playtime` (e um por
  toggle novo: `antifall`, `antigrav`, `wallwalk`).

### Interno
- `V8.Job` (trabalho periódico no scheduler único) e `V8.TabTick` (atualização
  1x/s da aba visível) para os módulos novos.
- `V8.Net`/`V8.Disk`: HTTP e arquivos do executor, sempre testados antes de usar.
- O validador aceita as globais `request`, `http_request` e `http` (APIs de
  executor, testadas com `typeof`).

### Fora desta versão
- A "Ferramenta Jerk" da referência não foi feita.

## v8.0

### Estrutura
- O `main.lua` de ~9.000 linhas virou 47 módulos em `src/`, agrupados por
  assunto. O `main.lua` continua existindo como arquivo único (gerado pelo
  `build.js`), então o jeito de rodar no executor não muda.
- `build.js` + `tools/check.js`: cada build valida sintaxe, o limite de 200
  locais do Luau, o limite de upvalues e globais desconhecidas, e aponta o
  erro como `src/arquivo.lua:linha`. Build com erro não grava nada.
- O build se recusa a sobrescrever um `main.lua` editado à mão.

### Novidades
- **Dock novo, solto no rodapé da tela** e sempre visível (substitui a bolinha
  H), com 7 ícones de contorno: Início, Personagem, Shop, Scripts, Jogadores,
  Configurações e Chat. O ícone ativo mostra o nome; clicar nele de novo fecha
  o painel.
- **Visual novo no modo dock**: janela em pé (460×520) logo acima do dock,
  título grande da seção + selo HYGE no topo, seções com título discreto e cada
  opção em um cartão (switch branco/escuro, slider com botão R). Tema padrão
  **Grafite** (monocromático); os outros temas continuam em Configurações.
- **Sub-abas em pílula** no topo da janela: Início (Painel · Servidor),
  Personagem (Movimento · Visual), Jogadores (Lista · Moderação). A busca
  (Ctrl+K) também encontra cada uma.
- **Barra de sub-ícones** acima do dock na seção Scripts: Console e Emotes.
- **Ilha no topo da tela**: hora, FPS e ping sempre à vista; clique abre/fecha
  o painel. Some no modo drone.
- **Aba Scripts**: o console de log saiu do rodapé da janela e ocupa a aba
  inteira, com linha de comando (Enter executa, ↑/↓ histórico).
- **Aba Chat**: feed do chat do servidor atual, enviar no chat do jogo e
  mensagem privada para o jogador selecionado (com AdminWhisper).
- **Aba Shop**: reservada ("em breve").
- **Script de servidor** (`server/`): cria e valida os 13 RemoteEvents
  (kick, bring, freeze, goto, anúncio, mensagem privada, fling, spin, trip,
  launch, sit, scale, balloon). Admin checado no servidor, cooldown, proteção
  entre admins, texto filtrado pelo Roblox, confirmação real no console do
  painel. Script cliente para todos verem anúncios e mensagens privadas.
- **Catálogo único de Remotes** (`V8.RemoteInfo`): aba Server lista os 13
  agrupados (antes 6), e o tile da Home, o comando `server` e Ajustes › Sobre
  leem da mesma lista.
- **Lista de jogadores e ESP em tempo real**: quem entra aparece na aba
  Players na hora; quem sai some da lista, do ESP (inclusive o tracer), da
  seleção e do spectate. Tempo no servidor preenchido para quem entra depois
  do painel abrir.
- **Freecam refeito**: sem a câmera "rolar" de lado, o personagem não anda
  junto, mouse livre com o painel aberto, scroll muda a velocidade.
- **Janela sempre alcançável**: arrastar fica preso dentro da tela, a posição
  é salva na config, e há `center` / Ajustes › Sistema › Centralizar janela.
  Reencaixa sozinha se a resolução mudar.
- **Chat Spy** funciona em jogos com TextChatService (o chat atual do Roblox;
  antes ficava mudo nesses jogos).
- Rodapé de atalhos da Home mostra as teclas reais (antes era texto fixo).
- O painel registra no console os anúncios que voltam do servidor.

### Correções
- Subir com `E` no freecam/drone ligava/desligava o ESP: teclas de movimento
  agora são ignoradas pelos atalhos enquanto o modo que as usa está ligado.
- Fly, freecam e drone se mexiam com as letras digitadas no chat/console.
- "Registrar no console" (Ajustes) não fazia nada; agora, desligado, só erros
  aparecem.
- Cada linha de log criava uma entrada permanente no registry de tema
  (vazamento com Chat Spy ligado). Também há faxina periódica das entradas de
  listas que se redesenham.
- Keybind podia ser colocado na tecla do console, da busca ou de uma situação
  e nunca disparar; agora o painel recusa ou avisa quem perdeu a tecla.
- Restaurar padrões voltava para o tema Roxo; agora volta para o padrão da v8
  (`CONFIG.DefaultTheme = "Azul"`). A lógica de restaurar existia duplicada.
- Comandos `sit`/`search`/`save`/`loadcfg` registravam erros como INFO.
- Comando `theme` não listava o tema Azul.
- Texto dos waypoints dizia que não eram salvos (são, desde a fase 1 da v8).
- Captura de keybind em andamento não era encerrada no Unload.
