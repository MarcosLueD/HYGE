# Changelog

## v9.4

Atualização visual: o painel inteiro com a cara do logo (fundo azul, triângulo
azul-marinho com contorno rosa neon, "HYGE" em rosa com brilho). Mesma
estrutura, mesmos botões, mesmas posições e a mesma navegação.

### Tema HYGE (`src/00_core/02_theme.lua`)
- Paleta nova com as cores do logo: azul-marinho/índigo (o miolo do
  triângulo), rosa neon como destaque e o azul do fundo do logo como cor
  secundária. É o padrão (`CONFIG.DefaultTheme`) e o primeiro da lista.
- **Troca única**: config da v9.3 ou anterior que estava no Grafite (o padrão
  antigo) abre no HYGE e o console avisa. Só na config do disco; perfis e
  importação mantêm o tema que trouxerem. Quem voltar para o Grafite fica nele
  (a próxima gravação já sai como v9.4).

### Peças da marca (`src/30_kit/10_brand.lua`, `V8.Brand`)
- **Triângulo neon** feito com 3 Frames girados de pontas redondas (o Roblox
  não desenha triângulo): os cantos fecham redondos, como no logo. Miolo
  escuro opcional em faixas horizontais escondidas embaixo do contorno.
- **"HYGE"** em degradê rosa → lilás, com contorno escuro e um brilho atrás.
- **Marca** (triângulo + H) no cabeçalho, na ilha e nas novidades. Com
  `CONFIG.LogoId`, a imagem continua valendo no lugar dela.
- Tudo segue o tema (destaque e secundária): no HYGE fica igual ao logo.

### Janela
- Borda rosa neon com brilho em volta que respira devagar (só com a janela
  aberta e "Animações" ligado; desligado, fica parado) e um véu da cor
  secundária no alto.
- Cabeçalho: a marca antes do título da seção e o "HYGE" do logo no lugar da
  pílula branca.
- **Faixa do Início** no lugar do "Welcome home": "Olá, <nome>" e o logo
  refeito em UI (triângulo, "HYGE" passando das bordas, bolinha e brilho), no
  azul do logo. `CONFIG.MascotId` (novo) põe a coruja sentada no triângulo.

### Detalhes
- Switch ligado e bolinha do slider com brilho; o preenchimento do slider
  acende em direção à bolinha.
- Botões e campos com contorno na **borda** (antes o UIStroke contornava as
  letras, o padrão do Roblox em botão de texto); texto escuro no hover.
- Tracinho neon antes de cada título de seção; cartões com vidro (um pouco
  mais claros em cima) e borda acesa em cima.
- Sub-abas em pílula com contorno; a ativa com brilho.
- Os 3 cartões de status do Início: a borda e o hover agora aparecem (pelo
  mesmo motivo dos botões). Aro da foto do perfil com brilho.

### Barras do HUD
- Ilha e dock trocaram o neon azul da v9.3 pelo rosa do logo, em vidro índigo
  (`V8.Hud.C`). Continuam com cores fixas.

### Testes
- `tests/brand.test.js` (novo): geometria do triângulo (lados iguais, traços
  ligando os vértices, tudo dentro da caixa), miolo sem fresta e escondido
  pelo contorno, comparação de versões, a troca única do tema, as mesmas
  chaves em todos os temas e contraste (texto 7:1, secundário e destaque
  4.5:1) no tema HYGE, na faixa do Início e nas barras do HUD.
- `docs/TESTES.md`: seção 4, o que conferir no jogo.

## v9.3

Barras do HUD modernizadas, sem refazer a interface: mesma estrutura, mesmos
botões, mesmas posições e a mesma navegação.

### Estilo (`src/30_kit/09_hud.lua`, `V8.Hud`)
- Pílulas de vidro azul-marinho (transparência + degradê) com borda azul neon
  e um brilho em volta, iguais em todas as barras. O Roblox não tem sombra
  nem desfoque de UI: o brilho (`V8.Hud.Halo`) são dois contornos neon bem
  transparentes numa moldura irmã da barra, que acompanha posição, tamanho
  real (com a escala do celular) e visibilidade. Irmã e não filha porque as
  barras têm `UIListLayout`. Cores fixas: não seguem o tema do painel. Sem o
  módulo de estilo, as barras voltam ao visual da v9.2.
- Tweens curtos que respeitam "Animações" (Configurações › Aparência).

### Ilha do topo (status)
- H, hora, FPS, ping e o sino com o contador continuam, na mesma ordem; o
  sino passou a ser sempre o último.
- Separadores finos entre os blocos.
- Ping seguido de 4 barrinhas de qualidade da conexão (≤ 80 ms excelente e
  ≤ 150 boa, em verde; ≤ 280 instável, em amarelo; acima disso ruim, em
  vermelho). O FPS só ganha cor quando cai abaixo de 50/30.
- Contador do sino: bolinha vermelha no canto do sino, com um aro da cor da
  ilha.
- Borda e brilho acendem de leve no hover (a ilha abre/fecha o painel).

### Dock (navegação)
- Mesmos 8 ícones, mesma ordem, centralizado; só ícones (o nome ao lado do
  ativo saiu), com traços finos entre eles.
- Seção aberta: ícone azul neon e um traço brilhante embaixo, que entra e
  sai com uma animação curta.
- O nome no hover fica acima do ícone (em todos, inclusive no ativo). Antes
  ele era filho da barra (que tem `UIListLayout`), entrava na fila e
  empurrava os ícones para o lado.
- **Alça de recolher** (dois traços soltos com brilho, o de cima mais curto,
  centralizada acima do dock): o dock
  desliza para baixo até sair inteiro da tela e só então some; a alça desce
  para o rodapé e traz o dock de volta. Hover acende os traços; clicar
  encolhe a alça um instante. Dois cliques rápidos não deixam o dock no meio
  do caminho. Estado salvo (`SET.DockHidden`, também nos perfis).
- O espaço reservado para o dock no rodapé virou `V8.Dock.Reserve()` (dock +
  alça), usado pela janela "em casa", pelo modo celular e pelo HUD do
  spectate (antes era o número 82 repetido). A janela nasce 13 px mais alta;
  recolher o dock não a move.

### Barra do Roblox (canto superior esquerdo)
- Os botões (Roblox, menu, chat, microfone) são da interface do Roblox e não
  foram tocados. Uma moldura no mesmo vidro fica atrás deles, numa ScreenGui
  própria no PlayerGui (sempre abaixo da interface do Roblox e da do jogo),
  medida pelo `GuiService.TopbarInset`. Configurações › Ilha no topo ›
  Moldura na barra do Roblox (`SET.TopbarFrame`).

### Testes
- `tests/hud.test.js` (novo): qualidade da conexão, cor do FPS, geometria do
  dock recolhível e as chaves novas na config.

## v9.2

Integração com o servidor do seu jogo: o painel continua no cliente, mas tudo
o que mexe em outros jogadores é pedido ao servidor e executado lá, depois da
validação. Guia de instalação novo: `docs/SERVIDOR.md`.

### Servidor (`server/HYGE_AdminServer.server.lua`)
- **Cargos**: moderador (1), admin (2), dono (3) — `ModIds` e `GroupModRank`
  novos; `AdminIds`, `OwnerIsAdmin` e `GroupMinRank` continuam valendo.
- **Permissão por ação** (`CONFIG.Permissions`, cargo mínimo; padrão:
  moderação e privado para moderador, anúncio e troll para admin). Valor
  inválido fica só para o dono e o Output avisa.
- `ProtectAdmins` agora é por hierarquia: ninguém age sobre cargo igual ou
  maior (o dono age sobre admins; antes ninguém agia sobre admin nenhum).
- **`HYGE_Status`** (RemoteFunction): devolve versão, cargo e ações
  liberadas. Quem não tem cargo recebe só a versão e o cargo 0.
- **`HYGE_Result`** (RemoteEvent): resposta estruturada de cada pedido, só
  para quem pediu (`action`, `ok`, `message`, `code`, `target`, `state`).
  Substitui as confirmações pelo `AdminWhisper` com remetente "HYGE".
- **Limite geral** por jogador (`CONFIG.RateLimit`, 30 pedidos em 10 s,
  somando todos os Remotes); quem insiste continua bloqueado; staff recebe um
  aviso só.
- **Formato**: argumento a mais é recusado (`nil` no fim não conta).
- **Alvo**: não vale em você mesmo (kick, bring, ir até); alvo sem personagem
  é recusado com o motivo (antes o Fling sem personagem era registrado como
  feito).
- **Erro interno** não vai para o cliente (só "erro interno"); o detalhe fica
  no Output do servidor e fora do registro.
- **Registro**: a mesma recusa repetida com menos de 10 s de intervalo vira
  uma entrada com contador (`count`, `last`) — um jogador martelando os
  Remotes não apaga mais o histórico. Continua sem o texto de privados, sem o
  motivo do kick e sem os argumentos recusados.
- **Entrega do painel** (opcional): LocalScript `HYGE_Panel` em ServerStorage
  é copiado só para quem tem cargo ≥ `PanelMinLevel` (vai para o registro).

### Painel
- **Ponte com o servidor** (`V8.Srv`, em `20_features/06_actions.lua`): acha
  os Remotes (de novo, se o servidor criar depois), pergunta o cargo, explica
  por que uma ação não pode ir e mostra a resposta real no console
  (`[SERVIDOR] ✓ ...` / `✗ ...`). Pedido sem resposta em 6 s é avisado.
- **LOCAL ou SERVIDOR** em cada cartão (Moderação, Troll, Chat); botões que
  não podem ir mostram **(sem servidor)**, **(não é admin)** ou **(sem
  permissão)** e se atualizam sozinhos.
- **Fim das simulações**: sem servidor, Bring não move o alvo só na sua tela,
  Freeze não mexe no personagem dele no seu cliente e o anúncio não aparece
  "só no seu chat". Com servidor, o Freeze também não mexe mais localmente.
- Spin e Balloon só mostram ON depois da confirmação (e voltam a OFF quando o
  balão desliga sozinho).
- "Teleportar até" passa pelo servidor quando ele está instalado e liberado
  (senão continua local, só o seu personagem).
- Mensagem privada num lugar só (Moderação, Chat e HUD do Spectate faziam
  cada um o seu `FireServer`).
- Bring não manda mais um argumento a mais (`"selected"`).
- **Início › Servidor**: estado da integração, seu cargo, cada ação
  (`[LIBERADA]` / `[SEM PERMISSÃO]` / `[NÃO É ADMIN]` / `[AUSENTE]`),
  RECONFERIR, COPIAR MEU USERID, "O que funciona onde" e o passo a passo da
  instalação. Comando `server check`. Sobre e Diagnóstico mostram o estado.
- Servidor v9.1 continua funcionando (estado "sem o HYGE_Status": os pedidos
  vão, sem resposta estruturada).

### Testes
- `tests/server.test.js`: cargos e permissão por ação, proteção por cargo,
  `HYGE_Status`, alvo que saiu / sem personagem / você mesmo, argumento a
  mais, limite geral, registro sem inundação e sem dados desnecessários, erro
  interno que não vaza, resposta estruturada, entrega do painel.
- `tests/bridge.test.js` (novo): o `06_actions.lua` de verdade com um cliente
  imitado — sem servidor / sem cargo / sem permissão nada é enviado nem
  simulado; formato dos pedidos; estado só com confirmação; servidor v9.1;
  `HYGE_Status` estranho ou que trava; resposta depois do Unload ignorada.

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
