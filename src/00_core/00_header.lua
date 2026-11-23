--[[
================================================================================
    HYGE ADMIN PANEL v8.2
    Evolucao direta da v7.0 — nada foi reescrito do zero.

    O que a v8.2 trouxe:
      * Pacote de animacao no personagem todo (andar, correr, pular, parado...)
        por ID ou link do pacote; lista salva; o mesmo pacote no Fly
      * Celular: botoes na tela (FLY, SUBIR, DESCER, 2x), voo pelo analogico,
        janela e dock que cabem em tela pequena
      * Playtime Shop: missoes do dia e bonus diario por dias seguidos
      * Ctrl + clique teleporta; waypoints salvos por jogo
      * Atualizacao: confere a versao nova e atualiza sem sair do jogo
        (loader.lua sempre abre a mais nova)

    O que a v8.1 trouxe (dock de 8 secoes):
      * Inicio: mapa atual, perfil com tempo de jogo, Rejoin / Trocar de
        servidor / Discord
      * Personagem: Anti-Fall e Anti-Gravidade (com slider)
      * Playtime Shop: loja paga com tempo de jogo (Ranks, Icons, Titles,
        Effects, Nametags, Bundles) — tudo visual e local
      * Troll: Walk on Walls + acoes no alvo (vindas da Moderacao)
      * Emotes: catalogo pesquisavel, Playback Speed, andar com o emote
      * Jogadores: ESP / TP / SPEC por linha da lista
      * Configuracoes: tecla do painel remapeavel, funcoes automaticas,
        reconectar se cair; Console virou sub-aba
      * Chat HYGE entre usuarios do painel (relay em server/chat-relay)

    O que a v8.0 trouxe:
      * Shell novo: janela 800x500, TopBar "Welcome home" com relogio e
        dock de icones no rodape (a sidebar continua a um clique em Ajustes)
      * Situacoes (Keypad 1-6): um clique troca o modo de operacao inteiro
      * Busca global (Ctrl+K): situacoes, funcoes, jogadores, waypoints, comandos
      * Config em disco (HYGE/config.json) + exportar/importar por clipboard,
        incluindo a posicao da janela
      * Dashboard da Home: cards de status configuraveis, chat rapido e
        Friend Activity
      * Acoes de servidor completas (kick, bring, freeze, announce, whisper,
        fling, spin, trip, launch, sit, scale, balloon) com script de servidor
        pronto em server/ — catalogo unico de Remotes no painel
      * Lista de jogadores e ESP acompanham entradas e saidas em tempo real
      * Freecam refeito (sem "roll", nao anda com o personagem, solta o mouse
        com o painel aberto, scroll muda a velocidade)
      * Teclas de movimento (WASD/E/Q...) nao disparam atalhos enquanto o
        freecam, o drone ou o fly estao usando essas teclas
      * Correcoes: "Registrar no console" agora funciona, log nao vaza memoria
        no registry de tema, conflitos de tecla com console/busca/situacoes,
        janela nao some fora da tela (botao/comando 'center')

    Continua valendo: registry unico de toggles, scheduler unico (1 Heartbeat),
    tudo em pcall, pose de superman procedural no Fly, modo Drone e R6/R15.

    Acoes de servidor SO funcionam com os RemoteEvents correspondentes e
    validacao no servidor (veja server/). Sem eles o botao fica indisponivel e
    o log explica o motivo — nada e simulado.

    Teclas padrao: [B] painel  [F] fly  [N] noclip  [E] esp  [C] freecam
                   [G] drone   [;] comandos  [Ctrl+K] busca  [Keypad 1-6] situacoes

    ESTE ARQUIVO E GERADO a partir de src/ (npm run build). Edite em src/.
================================================================================
]]

