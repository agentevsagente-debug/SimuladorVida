# Relatório de QA (sessão D)

*Primeira rodada, 01/11/2026, sobre a branch `claude/qa-cenarios-3b8628`, com a `main` até `c06e4d0` (a correção da falha ao fechar e a versão visível). A fonte de verdade é o documento funcional. A matriz completa está em `qa/cenarios.md`.*

## Números

*Rodada de 01/11/2026 na main `5f6e018`, com as entregas da A e da B para os itens que bloqueavam (D-01, D-02, D-03, D-09, D-14 e D-15).*

| | Quantos |
|---|---|
| Cenários na matriz | 124 |
| Automatizados no núcleo (`jogo/qa/rodar_qa.gd`) | 103 |
| Automatizados em janela (`jogo/qa/janela/rodar_janela.ps1`) | 12 |
| Só manuais (precisam de mouse e teclado) | 9 (QA-019, QA-037, QA-084, QA-152, QA-160, QA-161, QA-163, QA-165, QA-173) |
| **Passam** | **107** |
| **Falham** | **5**, todos no núcleo e nenhum que bloqueie a 0.1 |
| Pulados (a condição não aconteceu nas sementes) | 3 (QA-053, QA-110, QA-127) |

**Nenhum defeito que bloqueia a 0.1 continua aberto.** Os 5 que falham são da A e não bloqueiam: D-05, D-06, D-11, D-12 e D-13.

**Por área:**

| Área | Cenários | Passam | Falham | Pulados | Manuais, não rodados |
|---|---|---|---|---|---|
| Começo do mundo | 5 | 5 | 0 | 0 | 0 |
| Cotidiano | 10 | 9 | 0 | 0 | 1 |
| Os 11 poderes e as 3 intensidades | 18 | 16 | 1 | 0 | 1 |
| Preces e respostas | 9 | 9 | 0 | 0 | 0 |
| Religião, crença e nome do deus | 5 | 4 | 0 | 1 | 0 |
| Culturas | 6 | 5 | 1 | 0 | 0 |
| Estágios 1 a 6 e regressão | 5 | 5 | 0 | 0 | 0 |
| Linhagem acompanhada | 5 | 4 | 0 | 0 | 1 |
| Ausência e teto de 1 ano | 9 | 8 | 1 | 0 | 0 |
| Persistência e saves corrompidos | 12 | 9 | 2 | 1 | 0 |
| Fim do mundo, mundo vazio, criar povo e ruínas | 12 | 11 | 0 | 1 | 0 |
| Estante e abandono | 6 | 6 | 0 | 0 | 0 |
| Modo discreto | 3 | 2 | 0 | 0 | 1 |
| Moldura (esconder, escala, passagem do mouse) | 8 | 4 | 0 | 0 | 4 |
| Leveza | 7 | 6 | 0 | 0 | 1 |
| Robustez da API e cenas (achados durante a leitura) | 4 | 4 | 0 | 0 | 0 |
| **Total** | **124** | **107** | **5** | **3** | **9** |

**Os defeitos e a situação de cada um:**

| # | Defeito | Gravidade | Bloqueia a 0.1 | Área | Situação na main `5f6e018` |
|---|---|---|---|---|---|
| D-01 | Os testes do núcleo escreviam e apagavam a estante real do jogador | alta | prioridade | A | **corrigido**: os mundos de teste guardam os livros em `<nome>.estante`; QA-109 e QA-182 passam |
| D-02 | O raio e o sonho acertavam onde a pessoa estaria no fim da hora | alta | sim | A, B | **corrigido**: o núcleo mira pelo minuto (QA-027: 100% dos toques), e a interface passa o minuto e quem está sob o cursor (QA-185 passa) |
| D-03 | O mundo só ficava vazio na virada do dia | média | sim | A | **corrigido** (QA-131 passa; na tela, o aviso aparece aos 6 s) |
| D-04 | Sem número de versão | média | sim | B | **corrigido** (versão 0.1.0; QA-166 passa) |
| D-05 | Um mundo salvo que não se lê é sobrescrito em silêncio | média | não (antes da 0.2) | A, B | **aberto** (QA-105 falha) |
| D-06 | Um mundo carregado escreve a crônica com frases que mudam | média | não | A | **aberto** (QA-111 falha) |
| D-07 | A thread da rotina leva mais de 1 s com 240 pessoas | média | não | A | aberto como risco; o QA-170 passa (nenhuma espera no 50x) |
| D-08 | O mundo velho passava de 8% de um núcleo | média | não | B | **corrigido**: 7,2% no mundo de 200 anos (QA-172 passa) |
| D-09 | O mundo novo começava com o povo | média | decidido: começa vazio | A, B | **corrigido**: o jogo abre vazio às 7h, com o convite na clareira, e criar povo abre a Primeira Era (QA-002 passa; `QA-002-comeco.png`) |
| D-10 | A noite tinha 18,75 min, e o documento dizia 15 | baixa | não | — | **resolvido pelo documento** (QA-016 passa) |
| D-11 | Um milagre pode cair na camada "ambiente" | baixa | não | A | **aberto** (QA-026 falha) |
| D-12 | Dois povos dão o mesmo nome ao mesmo lugar | baixa | não | A | **aberto** (QA-064 falha) |
| D-13 | Exatamente um ano fora não conta como "teto atingido" | baixa | não | A | **aberto** (QA-092 falha) |
| D-14 | Os testes de QA iriam dentro do executável | baixa | não | B | **corrigido** (QA-181 passa) |
| D-15 | O aviso "Não resta ninguém" saía pelos lados do pergaminho | média | sim | B | **corrigido**: o texto quebra dentro do pergaminho (`QA-129-extincao_00.png`) |

**Nesta rodada, também:**
- **Leveza em 1x, visível** (semente 7, 120 s): o mundo novo fica em 5,85%, o de 50 anos em 3,46% e o de 200 anos em 7,18% de um núcleo (pico de 9,65%), com 234 a 299 MB.
- **Fechar o jogo:** 12 fechamentos com o atalho ligado (6 pela mensagem da janela, 6 pelo "Sair"), todos com código 0 e com "threads encerradas" no log.
- **Observação menor para a B:** num fechamento, o log escreve "threads encerradas" 3 vezes, porque mais de um caminho de saída chama `encerrar()`. É inofensivo.

A saída completa da última rodada está em `qa/ultima-rodada.txt`, e os resultados em janela em `qa/janela/resultado-*.json`.

## Defeitos

Gravidade:
- **alta:** perde dados, ou quebra uma promessa central na frente do jogador;
- **média:** o jogador percebe, mas contorna;
- **baixa:** inconsistência com o documento ou com a API, sem efeito visível grave.

"Bloqueia" é a minha proposta para a 0.1; quem decide é o orquestrador.

### D-01. A estante real do jogador é escrita e apagada pelos testes do núcleo
**Cenários:** QA-109, QA-182 · **Gravidade:** alta · **Bloqueia:** não (os amigos não rodam as ferramentas), mas ameaça agora a estante do usuário nesta máquina · **Área:** A

- **Passos:**
  1. `Persistencia.salvar(mundo_com_livro_fechado, "user://qualquer/teste.txt")`;
  2. olhar `user://estante`.
- **Esperado:** um mundo salvo num caminho de teste não escreve na estante do jogador, e nenhuma ferramenta apaga a estante do jogador.
- **Obtido:**
  - `_preparar()` e `abandonar()` chamam `Estante.guardar(livro)` sem a pasta, então o livro vai sempre para `user://estante`, a estante real. A bateria confirma: 0 → 1 livro.
  - `testar_fase2.gd` usa `PASTA := "user://estante"` e `_limpar_estante()` **apaga todos os arquivos** dessa pasta, no começo e no fim.
  - Gravam livros na estante real, além dele: `testar_persistencia.gd`, `testar_antigos.gd`, `resistencia.gd` e `resistencia_ciclo.gd`. Esses só gravam, mas sujam a estante.
- **Visto ao vivo nesta sessão, na pasta de dados real** (`%APPDATA%\Godot\app_userdata\Simulador de vida`):
  - às 18h55, a estante estava vazia, com a pasta modificada às 18h52;
  - às 19h10, tinha 7 livros (`001` a `007`, sementes 1, 4 e 5) e `teste_fim.txt` com as 3 cópias, vindos de um teste no worktree `fase0-simulacao-81d444`;
  - no fim da sessão, tinha **4 livros diferentes** (`001` a `004`), ou seja, **foi apagada e regravada no meio**;
  - se o usuário tivesse um livro de verdade ali, ele teria sumido.
- **Sugestão:**
  - a pasta da estante segue a pasta do mundo, por exemplo `caminho.get_base_dir() + "/estante"`, ou entra como parâmetro em `salvar` e `abandonar`;
  - as ferramentas usam uma pasta de teste;
  - ou rodam com `APPDATA` isolado, como `rodar_qa.gd`.

### D-02. O raio e o sonho acertam onde a pessoa estará no fim da hora, não onde ela está na tela
**Cenário:** QA-027 · **Gravidade:** alta · **Bloqueia:** sim (proposta). "Atingir uma pessoa específica" é uma promessa central dos poderes · **Área:** A (ou A e B)

- **Passos:**
  1. `pessoas_visiveis()` às 10h;
  2. `usar_poder("raio", posicao_de(id), 0.9)`.
- **Esperado:** o raio de milagre atinge quem está sob o gesto (API: "a pessoa mais perto de x, se estiver a até 6 pixels").
- **Obtido:**
  - `alvo = -1`, e o raio cai no chão.
  - `_pessoa_perto(x)` compara x com `agenda(id, h)[-1]["x1"]`, que é o ponto do **fim** da hora. Na tela, porém, a pessoa anda pelos trechos da agenda durante a hora inteira (112,5 s em 1x).
  - Medido em 5 sementes, das 8h às 16h, com 540 pessoas acordadas:
    - a pessoa está a mais de 6 px do ponto que o núcleo acerta durante **de 50% a 64%** do tempo;
    - 64% supõe que ela anda em linha reta pelo trecho;
    - 50% é o limite inferior, supondo que ela chega logo ao destino de cada trecho e espera ali, como a vista faz;
    - no meio da hora (`posicao_de`), 363 das 540 estão longe demais.
  - Mirando o `x` do fim da hora, o raio mata (a mecânica funciona).
- **Ressalva:** a verdade fica entre os dois números; mesmo o limite inferior é 10 vezes a tolerância de 5% do teste.
- **Sugestão:**
  - a apresentação passa a fração da hora (ou o id de quem está sob o cursor) para `usar_poder`, e o núcleo mira em `ro.instante(id, minuto)`;
  - `_poder` já aceita `alvo`.

### D-03. Quando o último morre, o mundo só fica vazio na virada do dia (corrigido em `ece2046`)
**Cenários:** QA-131, e por isso QA-129 · **Gravidade:** média · **Bloqueia:** sim (proposta). A extinção é uma promessa central, e a correção parece pequena · **Área:** A (e B para a tela)

- **Passos:**
  1. Às 10h, restando uma pessoa, o raio de milagre a mata (`populacao() == 0`).
  2. Avançar 1 hora.
- **Esperado:** `fim_do_mundo` verdadeiro, o evento `fim_do_mundo`, o livro fechado e `criar_povo()` funcionando.
- **Obtido:**
  - `fim_do_mundo` continua falso, e `criar_povo` recusa: "só se cria um povo com o mundo vazio";
  - o fim só vem **15 horas de jogo depois**, no passo da 1h, porque `os_ultimos` e `fim_do_mundo` são conferidos só em `_novo_dia()`;
  - nesse intervalo, os poderes ainda são aceitos: a chuva sobre o mundo sem ninguém devolve `ok: true` (testado);
  - em 1x, são **uns 28 minutos reais** com o mundo morto, sem o aviso "Não resta ninguém" e sem o botão de criar povo.
- **Na tela** (QA-129), com `--extinguir` no 50x:
  - aos 6 s, ainda aparece gente perto do fogo, e nenhum aviso (`QA-129-extincao_00.png`). É o R4 da auditoria 11;
  - aos 40 s, depois da meia-noite do jogo, o aviso aparece (`QA-129-extincao_01.png`);
  - então a tela responde certo ao núcleo, e o atraso é só a conferência na virada do dia. O aviso tem outro defeito, o D-15.
- **Depois de `ece2046`:** com o mesmo comando, o aviso já aparece no quadro dos 6 s (`QA-129-extincao_00.png`). A correção chegou à tela. O D-15 continua.
- **Sugestão:** conferir `populacao() == 0` (e `<= 5`) também ao fim de `usar_poder` e de cada passo, e não só na virada do dia.

### D-04. O jogo não mostra o número da versão (corrigido)
**Cenário:** QA-166 · **Situação:** corrigido pela B em `c06e4d0`. O `project.godot` agora tem `config/version="0.1.0"`, e o QA-166 passa. Não conferi na tela onde a versão aparece. · **Área:** B

O registro original fica abaixo.

- **Obtido:**
  - `project.godot` não tem `config/version`;
  - a versão 0.1.0.0 está só nas propriedades do `.exe` (`export_presets.cfg`);
  - nenhum script da apresentação mostra uma versão.
- **Esperado:** a versão visível, na dica do relógio ou na estante, para os relatos dos amigos.

### D-05. Um mundo salvo que não se lê é sobrescrito em silêncio
**Cenários:** QA-104, QA-105 · **Gravidade:** média · **Bloqueia:** não para a 0.1; precisa estar resolvido antes da primeira versão nova (0.2) · **Área:** B (o aviso) e A (não rodar as cópias por cima de um arquivo ilegível)

- **Passos:**
  1. Os 4 arquivos (`mundo.txt` e `.1` a `.3`) ficam ilegíveis para esta versão. Por exemplo, salvos por uma versão mais nova (`["versao", 99]`), ou todos estragados.
  2. Abrir o jogo e deixá-lo correr 4 dias de jogo (3 h em 1x), que são 4 salvamentos.
- **Esperado:**
  - o jogador fica sabendo que o mundo dele não pôde ser aberto;
  - o arquivo ilegível fica guardado à parte, por exemplo `mundo.ilegivel.txt`.
- **Obtido:**
  - `carregar()` devolve null, e `existe()` continua verdadeiro;
  - `simulacao.iniciar()` cria um mundo novo sem nenhum aviso: não há nenhuma menção a `recuperado_de` ou "estragado" na apresentação;
  - a cada salvamento, a rotação empurra os arquivos antigos, e depois de 4 salvamentos **nenhum dos 4 arquivos do mundo antigo existe mais** (0 de 4).
- **Quando acontece:** um amigo que volta da 0.2 para a 0.1, ou um disco que estraga os 4 arquivos. As gravações interrompidas estão cobertas: QA-102 passa com o arquivo cortado, vazio, com lixo, só com o cabeçalho, binário, com o cabeçalho trocado e sem o fim.

### D-06. Um mundo carregado do arquivo escreve a crônica com frases que mudam de uma vez para outra
**Cenário:** QA-111 · **Gravidade:** média (o jogador não vê; mas quebra a reprodução de problemas e a promessa de determinismo) · **Bloqueia:** não · **Área:** A

- **Passos:**
  1. Semente 7, 10 anos; `Persistencia.salvar`.
  2. Carregar o mesmo arquivo 6 vezes no mesmo processo. Em cada vez: deixar uma pessoa, fraca, e `avancar_ausencia(40 dias)`.
- **Esperado:** os 6 relatos iguais. O documento técnico diz que "a mesma semente com os mesmos comandos produz o mesmo mundo", e a API diz que um mundo salvo e carregado "segue igual, passo a passo".
- **Obtido:**
  - o sorteio termina igual nas 6 vezes, mas o texto vem em **2 versões**;
  - a frase do epitáfio de Suim sai ora "Foi quem deu ao deus o nome de «o Que Sacode»", ora "Tinha sido o primeiro a plantar";
  - sem salvar e carregar, 3 processos dão sempre o mesmo texto;
  - com salvar e carregar, 2 de 3 processos deram o outro;
  - não depende do `salvo_em`: o mesmo `salvo_em` dá as duas versões.
- **Pista:**
  - logo depois de carregar, o estado do cronista é idêntico nas 6 cargas, com o mesmo hash de `_usados`, `_recentes`, `_narrados`, `_primeiros`, `anos_escritos`, `_cursor`, `_fatia` e `_indice_ate`;
  - o sorteio do mundo termina igual;
  - então a divergência nasce **durante o avanço**, e não na leitura do arquivo.
- **Suspeitos:**
  - o adiantamento por relógio em `avancar_hora()` (mundo.gd:286 a 320), que prepara a hora seguinte só quando sobra tempo (`Time.get_ticks_usec()`);
  - o `RandomNumberGenerator` único do cronista (`rt`, cronista.gd:41), resemeado por evento, se for usado fora da escrita oficial ao mesmo tempo (na thread da rotina, ou nessa preparação).
- **Nota:** a falha é intermitente. O teste carrega 6 vezes para pegá-la com alta probabilidade.

### D-07. A thread da rotina leva mais de 1 s com 240 pessoas, e o passo espera por ela
**Cenário:** sonda à parte (o QA-170 passa) · **Gravidade:** média (risco nas máquinas dos amigos) · **Bloqueia:** não · **Área:** A

- **Passos:** mundo da semente 3 no ano 250, com 240 pessoas; um passo, a consulta completa, e o passo seguinte depois de uma folga.
- **Obtido:**

  | Folga entre passos | Pior passo | Esperas pela thread |
  |---|---|---|
  | 0 ms | 6 ms | 0 (a rotina não é montada sem consulta entre passos) |
  | 300 ms | **600 ms (0h) e 1095 ms (2h)** | 2 |
  | 1500 ms | 7 ms | 0 |

  - A primeira consulta depois do salto de 250 anos leva 1138 ms; a API diz cerca de 100 ms.
  - O passo comum fica entre 3 e 7 ms, com a máquina a 18% de carga, por causa das outras sessões.
- **Leitura:**
  - a API diz de 60 a 220 ms de thread; aqui foram mais de 1 s;
  - no 50x (2,25 s entre passos), não trava nesta máquina, de 28 núcleos;
  - num notebook 2 a 3 vezes mais lento, o 50x travaria de 1 a 2 s uma ou duas vezes por dia de jogo.
- **Na bateria (QA-170, que passa), com 2,25 s entre passos, como no 50x:**
  - nenhuma espera pela thread;
  - o passo das 22h ficou em 22 a 32 ms nas 3 rodadas, e os outros, de 3 a 8 ms;
  - a meta da API é de 5 ms; como a máquina estava carregada pelas outras sessões, não conto como falha e deixo a medida fina para o `desempenho.gd` da A;
  - a primeira consulta depois do salto levou de 1017 a 1253 ms.

### D-08. Com o mundo velho, a CPU passa de 8% de um núcleo em 1x (corrigido em `a30292f`, confirmado)
**Cenário:** QA-172 · **Gravidade:** média · **Bloqueia:** não para a 0.1 (os amigos começam com o mundo novo, que fica em 6%) · **Área:** B (o desenho) e A (o passo e a rotina)

- **Obtido:** 14,36% de um núcleo em média, com pico de 16,76%, no mundo de 200 anos, visível, em 1x.
- **Esperado:** abaixo de 8%.
- O mundo novo fica em 5,98%, e o de 50 anos em 7,38%, já no limite. Os números estão em "Pontos conhecidos", abaixo.

### D-09. O mundo novo já começa com o povo, e o documento diz que começa vazio (decidido: começa vazio)
**Cenário:** QA-002 · **Gravidade:** média · **Bloqueia:** não. É uma decisão do orquestrador · **Área:** A e B

- **Documento funcional, "Começo do mundo" e "Menor conjunto", item 1:**
  - a região começa vazia;
  - "o primeiro gesto do jogador é criar o primeiro povo, usando o mesmo poder que recria a humanidade";
  - "Começo e recomeço funcionam igual."
- **Obtido:**
  - `Mundo.new()` já nasce com 12 pessoas às 7h;
  - a apresentação abre direto com o povo andando;
  - criar o povo só existe depois de uma extinção.
- **Ressalva:** a auditoria 11 elogia abrir de manhã com gente andando, e o plano da fase 1 diz "cria o primeiro povo". Se a escolha foi deliberada, o documento funcional precisa ser atualizado. Senão, o recomeço (que já tem a chegada do povo e a primeira fogueira) serve também para o começo.

### D-10. A noite dura 18,75 min reais, e o documento diz 15 (resolvido: o documento mudou em `f87b764`)
**Cenário:** QA-016 · **Gravidade:** baixa · **Bloqueia:** não · **Área:** A

- O documento funcional diz "cerca de 45 minutos reais por dia de jogo (30 de dia e 15 de noite)". Isso dá 8 horas de jogo de noite.
- `tempo().noite` vale das 20h às 6h, que são 10 horas, ou 18,75 min reais; o dia fica com 26,25 min.

### D-11. Um milagre pode cair na camada "ambiente"
**Cenário:** QA-026 · **Gravidade:** baixa · **Bloqueia:** não · **Área:** A

- **Obtido:**
  - a chuva de milagre (0,6) sem seca tem importância 3 e camada "ambiente";
  - a cura de milagre em quem está são tem importância 2 e camada "ambiente".
- **Por que importa:**
  - a API diz que os atos do deus são "nota ou chamado";
  - o documento define o milagre como "um efeito visível e inegável";
  - na camada ambiente, o gesto não entra na crônica nem para o salto.
- Os outros 9 poderes, a 0,6, saem como nota ou chamado.

### D-12. Dois povos dão o mesmo nome ao mesmo lugar
**Cenário:** QA-064 · **Gravidade:** baixa · **Bloqueia:** não · **Área:** A

- O documento funcional diz: "o mesmo lago tem um nome para cada povo".
- **Obtido**, no mundo da semente 3 no ano 120:
  - o lago é "Lago da Vitória" para Koil (que venceu Toran ali no ano 98) e para Peak (que venceu Koil ali no ano 101);
  - o morro é "Morro da Vitória" para Peak e para Toran.
- Os nomes batem com quem venceu: o vencido diz "do Luto". A repetição vem de vitórias diferentes no mesmo lugar.
- **Sugestão:** quando o nome já é de outro povo vivo, usar outra variante ou o nome do vencido ("Lago da Vitória sobre Koil").

### D-13. Exatamente um ano fora não conta como "teto atingido"
**Cenário:** QA-092 · **Gravidade:** baixa · **Bloqueia:** não · **Área:** A

- `avancar_ausencia(960 × 112,5 s)` dá 960 passos, mas com `teto_atingido = false`, porque a conta usa `pedidos > TETO_AUSENCIA`.
- A apresentação usa `teto_atingido` para o título "um ano" e para voltar ao ritmo normal. No limite exato, o título fica "40 dias".

### D-14. Os testes de QA iriam dentro do executável
**Cenário:** QA-181 · **Gravidade:** baixa · **Bloqueia:** não, mas é uma linha só · **Área:** B

- `exclude_filter` exclui `ferramentas_sim/*` mas não `qa/*`. Basta acrescentar `qa/*`.

### D-15. No aviso "Não resta ninguém", a linha do livro sai pelos lados do pergaminho
**Cenário:** QA-129 · **Gravidade:** média · **Bloqueia:** sim (proposta). É o momento mais marcante do jogo, e a correção é de quebra de linha · **Área:** B

- **Passos:** `--sem-config --mundo-novo --semente=7 --dias=12 --hora=10 --extinguir --ritmo=rapido2`, e esperar o aviso (uns 35 s).
- **Obtido:**
  - a linha "A Primeira Era: de Toan ao último de Toan terminou: do ano 1 ao ano 1." não quebra e passa das duas bordas do pergaminho;
  - o "A" do começo e o "ano 1." do fim ficam fora da caixa (`qa/capturas/QA-129-extincao_01.png`);
  - os títulos com epíteto da A ("de Toan ao último de Toan") deixaram a linha mais longa do que a caixa;
  - os dois-pontos seguidos ("Toan terminou: do ano") também pedem revisão do texto.
- **Esperado:** a linha quebra dentro do pergaminho, como as outras.
- **Reconferido na main `f87b764`:** continua igual. O "A" do começo e o "ano 1." do fim passam das bordas (`QA-129-extincao_00.png`).

### O-1. Observação: importar o projeto num worktree novo muda um `.import`
**Área:** B · Não é defeito do jogo.

- `--headless --import` num worktree sem `.godot/` reescreve 1166 arquivos `.import`, só nas quebras de linha.
- Também troca `arte/interface/fonte_5x7_titulo.png.import` de `importer="texture"` para `importer="skip"`.
- Voltei todos ao estado do git, porque não são da minha área. Vale conferir qual dos dois é o certo: o `skip` aparece quando a fonte `.fnt` usa a imagem.

### O-2. Observação: o `.exe` guarda os dados em outra pasta
**Área:** B · Para a página "como jogar" (B2 da auditoria 11).

- O jogo pelo editor usa `%APPDATA%\Godot\app_userdata\Simulador de vida\`.
- O `.exe` exportado usa uma pasta própria, `%APPDATA%\Simulador de vida\` (`config/use_custom_user_dir.template` no `project.godot`), separada da pasta do Godot que os testes usam.
- É essa a pasta que a página deve indicar para "onde fica o mundo salvo e como começar de novo".

## Pontos conhecidos, conferidos

### Falha de segmentação ao fechar: corrigida e confirmada (QA-167 passa)
A B corrigiu em `c06e4d0`: `simulacao.encerrar()` espera as threads do núcleo em todas as saídas, e o fechamento pela janela agora também chama `_parar_atalho_global()`.

**Confirmado com o atalho ligado** (QA-167), usando Ctrl+Alt+J (`--atalho-global=J`), porque o Ctrl+Alt+H estava com outro jogo aberto:

| Caminho, com o atalho ligado | Aberturas | Código 0 | Atalho registrado | "threads encerradas" no log | Auxiliar órfão | Aviso de thread |
|---|---|---|---|---|---|---|
| Mensagem de fechar a janela (Alt+F4), no 50x, de 6 a 52 s (5 durante um `salvar_async`) | 10 | 10 | 10 | 10 | 0 | 0 |
| `sair()`, pelo `--duracao` (5 com mundo de teste, 5 com o mundo salvo) | 10 | 10 | 10 | 10 | 0 | 0 |

**Antes da correção**, sem o atalho, também não reproduzi em 36 fechamentos:

| Caminho | Aberturas | Código 0 | Observação |
|---|---|---|---|
| `sair()`, pelo `--duracao` (o mesmo da bandeja "Sair") | 10 | 10 | 5 com mundo de teste, 5 com o mundo salvo; os 5 salvos carregaram e salvaram |
| Mensagem de fechar a janela (WM_CLOSE: Alt+F4, fechar pela barra de tarefas), pelo `CloseMainWindow()`, no 50x | 10 | 10 | de 6 a 52 s; em 5 havia um `salvar_async` do dia na sessão |
| Os dois caminhos acima com `--atalho-global` | 16 | 16 | **não vale:** o atalho falhou ao registrar (`atalho_em_uso`), porque outro teste da B, um `.exe` de 1 hora aberto às 19h23 com `--atalho-global`, segurava o Ctrl+Alt+H |

**A suspeita que eu tinha, já resolvida por `c06e4d0`:**
- O fechamento pela janela (`_notification(NOTIFICATION_WM_CLOSE_REQUEST)`) salva, mas **não chama `_parar_atalho_global()`**, que só roda em `sair()`.
- Com o atalho ligado, que é o padrão do jogo de verdade:
  - a thread `_atalho_leitor` fica bloqueada lendo o processo auxiliar;
  - o Godot destrói um `Thread` em andamento ao sair;
  - o PowerShell auxiliar pode ficar órfão.
- É o caminho mais provável da falha de segmentação.
- Para repetir a confirmação: `rodar_janela.ps1 -Parte fecharjanela -ComAtalho` e `-Parte fechar -ComAtalho`. A tecla padrão é J; use `-Tecla` para trocar.

### A cena de guerra no horário antigo depois de um ataque forçado (A investigando)
- **No núcleo, está corrigido (QA-180 passa).** Um ataque às 8h, com o mundo consultado a cada hora como faz a apresentação, gera a cena `guerra` com `ini` 10,0 e `fim` 14,5, vista a partir da hora 10. É o que a API promete: começa em hora + 2 e dura 4h30.
- **Na tela, ficou inconclusivo.** As 3 capturas do `--cenario-raro=batalha` no 50x (8, 10 e 12 s depois de abrir) mostram uma fileira de gente no meio da vila, mas não dá para afirmar só pelo quadro parado que são as duas linhas lutando (`qa/capturas/QA-180-batalha_*.png`). Precisa de um GIF ou de olho humano.

### Leveza: abaixo de 8% de um núcleo, visível, em 1x (confirmado depois de `a30292f`)
Medido com `rodar_janela.ps1 -Parte leveza`:
- jogo pelo editor (Godot 4.7.2, Compatibilidade), visível, semente 7, ritmo normal, começando às 17h;
- 20 s de aquecimento e 120 s de medida;
- CPU do processo do jogo (o filho do `_console.exe`) ÷ tempo real;
- a máquina estava a 0% a 7% de carga.

| Mundo | Antes (main `ae1faa8`) | **Depois (main `69791ad`, com `a30292f`)** | Pico de amostra (5 s), depois | Conjunto de trabalho, depois | Meta de 8% |
|---|---|---|---|---|---|
| Novo (ano 1, 12 pessoas) | 5,98% | **4,50%** | 6,47% | 234 MB | passa (QA-171) |
| 50 anos (2 povos) | 7,38% | **5,62%** | 8,38% | 239 MB | passa |
| 200 anos (estágio 6, 4 povos) | 14,36% | **7,30% e 7,11%** (duas medidas) | 8,97% e 9,85% | 281 MB | **passa (QA-172)** |

- **Confirmo a melhora da B no D-08**: no mundo de 200 anos, o consumo caiu para menos da metade e ficou abaixo da meta.
- **Mas fica acima dos 6,08% que a B mediu.** A B usou outro mundo: `medir.ps1 -Cenario grande`, semente 3, durante 186 s. Na semente 7, deu de 7,1% a 7,3%. As duas medidas estão abaixo de 8%. A folga é pequena: picos de amostra de 5 s chegam a 9 a 10%.
- **A meta do documento técnico** ("média abaixo de 2% num computador comum") não diz se é da máquina ou de um núcleo. A régua de "% de um núcleo" do orquestrador é a que vale. Num notebook de 4 núcleos, 7,3% de um núcleo são 1,8% da máquina.
- **No máximo 30 quadros por segundo:** `run/max_fps=30` no `project.godot` (QA-174 passa). Pelo commit da B, o 1x e a pausa agora desenham a 20 quadros por segundo.
- **Memória:** de 234 a 282 MB de conjunto de trabalho. A meta é 200 MB, e o usuário aceitou passar nessa medida.
- **Uma armadilha do meu script:** passar `-AnosLeveza 0,50,200` pelo `powershell -File` vira o número 50200, e o jogo tenta gerar 50 mil anos. É preciso rodar uma idade por vez (`-AnosLeveza 200`).

## O que passou e vale registrar

Procurei onde o jogo quebra a promessa, então os acertos abaixo valem por terem sido testados contra o documento, e não só contra a API.

- **Determinismo e consultas puras** (QA-004, QA-005):
  - a mesma semente com os mesmos gestos dá a mesma crônica, os mesmos eventos e o mesmo sorteio em 30 anos;
  - consultar tudo a cada hora, por 960 horas, não muda o mundo.
- **Ninguém na água** em 960 horas consultadas (QA-010).
- **Poderes:**
  - os 11 funcionam no primeiro dia (QA-020);
  - os limites de grau estão certos: 0,499 é sinal e 0,5 é milagre (QA-021);
  - a imposição vem no 3º uso em 3 dias e não vem em outra zona nem com 4 dias entre os usos (QA-022, QA-023);
  - entradas fora da faixa não quebram (QA-024);
  - o fogo brando atende o frio, e 0,35 já queima e contraria (QA-029);
  - as 3 formas do presságio (QA-031);
  - o dilúvio imposto alaga as 4 zonas e deixa 6 de 12 vivos: o quase fim (QA-033, QA-130);
  - 6 chuvas viram a festa da chuva e depois a dependência (QA-035).
- **Preces:**
  - atendida pelo poder certo no fogo do povo (QA-041);
  - silêncio (QA-042);
  - contrariada (QA-043);
  - ponto cego: em 100 anos, nenhuma prece de povo sem crença ou cético (QA-044);
  - falso milagre com "acaso" na crônica (QA-046).
- **Religião:**
  - milagres fazem nascer a crença em 2 dias (QA-050);
  - em 120 anos, dois povos sem parentesco nunca chamam o deus igual (QA-051);
  - a fé varia de pessoa para pessoa (QA-054).
- **Culturas:** 6 dimensões válidas, origem completa dos povos novos, costumes com origem, aparências diferentes, reformas (QA-060 a QA-065).
- **Estágios:**
  - agricultura em até 50 anos em 5 sementes, 20 com `--longo` (QA-070);
  - estágio entre 1 e 6 em 250 anos, e o 6 alcançado (QA-071);
  - regressão quando morre o último que sabia (QA-072, depois de corrigido o meu teste: a regressão é conferida a cada 5 dias).
- **Linhagem:**
  - o raio do deus mata a pessoa acompanhada, e a linhagem passa ao descendente vivo mais velho, com o evento (QA-081);
  - as sugestões trazem quem acabou de sonhar (QA-083).
- **Ausência:**
  - 16 h fora são 512 passos;
  - 30 dias e 5 anos param no teto;
  - o relógio para trás e o salvamento "no futuro" não andam nem quebram;
  - a extinção durante a ausência vem nos chamados e no relato (QA-090 a QA-097);
  - um ano de ausência no mundo de 250 anos leva 2,3 s (QA-176).
- **Persistência:**
  - salvar e carregar dá o mesmo mundo, passo a passo, 10 anos depois (QA-100);
  - 7 tipos de estrago voltam da cópia, com o aviso no relato (QA-102);
  - tudo estragado devolve null sem quebrar (QA-103);
  - só as cópias bastam (QA-106);
  - `salvar_async` com o mundo andando (QA-107);
  - índice da estante estragado (QA-108).
- **Fim do mundo:**
  - o deus acaba com o povo só com raios, em 27 raios (QA-120);
  - os últimos e o fim do mundo (QA-121, QA-122);
  - o mundo vazio continua, as ruínas envelhecem e os poderes recusam (QA-123);
  - a Segunda Era com 12 pessoas e a recusa num mundo habitado (QA-124);
  - o povo criado no lago nasce na praia (QA-125);
  - o mito das ruínas (QA-126);
  - o mundo vazio salvo e carregado (QA-128).
- **Estante:** abandonar fecha o livro e apaga o mundo com as cópias; o livro sobrevive ao mundo novo e se lê pela cópia; dois abandonos (QA-140 a QA-144).

## TDD: o contrato de cada teste

Cada linha abaixo é um teste que **falha hoje** (conferido na rodada de `f87b764`) e diz exatamente o que precisa ser verdade para passar. Para rodar só ele: `-- --so=ID`. Um teste só conta como passando com **todas** as suas conferências `ok`.

### Itens da A

| Defeito | Teste | Falha hoje com | Passa quando |
|---|---|---|---|
| **D-01** (prioridade) | QA-109 | `salvar(mundo_com_livro, "user://qa_tmp/isolado/mundo.txt")` grava 1 livro em `user://estante` | salvar e abandonar um mundo fora do caminho padrão **não muda** `Estante.livros()` da pasta padrão (0 → 0). O livro vai para uma estante ligada ao caminho do mundo, ou para uma pasta passada como parâmetro |
| D-01 | QA-182 | `testar_fase2.gd` usa `"user://estante"` e apaga arquivos dela | nenhum `ferramentas_sim/*.gd` tem a string `"user://estante"` junto de `.remove(` ou `remove_absolute` |
| **D-02** (bloqueia) | QA-027 | a pessoa fica a mais de 6 px do ponto que o raio acerta de 50,2% a 64,0% do tempo da hora | em 5 sementes, das 8h às 16h, a pessoa acordada fica a até 6 px do ponto que o núcleo acerta em **pelo menos 95%** das frações da hora, mesmo no limite inferior (cada trecho já no destino). Na prática: mirar onde a pessoa está naquele instante (`ro.instante(id, minuto)`, ou a apresentação passa o minuto ou o id). A primeira conferência (mirar o `x` do fim da hora mata) continua valendo |
| **D-09** (decidido) | QA-002 | o jogo novo abre com 12 pessoas, e `criar_povo` recusa ("só se cria um povo com o mundo vazio") | pela `simulacao.gd`, com `iniciar(4242, -1, false)`: população 0 e hora entre 6h e 9h; depois, `criar_povo(260)` devolve `ok` com 12 pessoas, 1 povo no estágio 1 na floresta, `era == 1`, nenhum livro e nenhum evento `fim_do_mundo`, e com uma pessoa acompanhada. Os outros testes não dependem disso: `_mundo(s)` cria o povo se o mundo vier vazio |
| D-05 | QA-105 | 0 dos 4 arquivos de um mundo ilegível (versão 99) sobrevivem a 4 salvamentos de um mundo novo no mesmo caminho | pelo menos 1 arquivo com `["versao", 99]` ainda existe depois dos 4 salvamentos (por exemplo, guardado à parte como `mundo.ilegivel.txt` ao lado). O aviso ao jogador é da B e fica para a janela |
| D-06 | QA-111 | 6 cargas do mesmo arquivo dão 2 textos de crônica diferentes | as 6 cargas dão **1** texto e 1 estado de sorteio |
| D-11 | QA-026 | a chuva de milagre (0,6) sem seca e a cura de milagre em quem está são saem na camada "ambiente" | os 11 poderes, a 0,6 no primeiro dia, geram evento com `x`, `grau` e `intensidade` e camada "nota" ou "chamado" |
| D-12 | QA-064 | no mundo da semente 3 no ano 120, "Lago da Vitória" (Koil e Peak) e "Morro da Vitória" (Peak e Toran) | nenhum par de povos vivos dá o mesmo nome à mesma zona |
| D-13 | QA-092 | `carregar_e_avancar` com exatamente 960 × 112,5 s dá `teto_atingido = false` | 960 passos e `teto_atingido = true` (a conta usa `>=`). Os outros casos de ausência continuam: 16 h dão 512 passos sem teto, e 30 dias e 5 anos dão 960 com teto |
| ~~D-03~~ | QA-131 | — | **já passa** desde `ece2046` |

### Itens da B

| Defeito | Teste | Falha hoje com | Passa quando |
|---|---|---|---|
| **D-02** (bloqueia), a parte da tela | QA-185 | `simulacao.usar_poder(poder, x, intensidade)` não passa o minuto; no minuto 50, o raio cai no chão (núcleo da A) ou acerta outra pessoa (main) | pela `simulacao.gd`, no minuto 50 da hora 11 da semente 4, o raio solto onde a pessoa está na tela (a agenda naquele minuto) devolve `alvo` igual ao id dela |
| **D-15** (bloqueia) | QA-129, em janela | a linha do livro sai pelas duas bordas do pergaminho do "Não resta ninguém" | `rodar_janela.ps1 -Parte capturas`: no quadro `QA-129-extincao_01.png` o aviso aparece e todo o texto fica dentro do pergaminho (conferência a olho na captura). Com o D-03 corrigido, o aviso deve aparecer já no primeiro quadro |
| D-14 | QA-181 | `exclude_filter` sem `qa/*` | `exclude_filter` contém `qa/` |
| D-05 (aviso) | manual | nenhum aviso quando o mundo salvo não se lê | a apresentação mostra um aviso quando `Persistencia.existe()` é verdadeiro e `carregar_e_avancar()` devolve null |

### Sem dono por enquanto

| Defeito | Teste | Situação |
|---|---|---|
| D-07 | sonda à parte | risco de desempenho; o QA-170 passa (nenhuma espera pela thread no 50x) |
| ~~D-08~~ | QA-172, em janela | passa desde `a30292f`: 7,1% a 7,3% de um núcleo |

Daqui em diante, cada funcionalidade nova avisada pelo orquestrador ganha primeiro o cenário em `qa/cenarios.md` e o teste em `rodar_qa.gd`, que deve falhar antes da entrega.

## Como rodar

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path jogo --script res://qa/rodar_qa.gd
```

- Opções, depois de `--`:
  - `--longo` roda mais sementes e mais anos (uns 4 min);
  - `--so=QA-090,QA-091` roda só esses cenários.
- A bateria se relança sozinha com `APPDATA` em `%TEMP%\simvida_qa_appdata`. Assim, o `user://` dela nunca é a pasta de dados real do jogador. Isso é necessário porque `Persistencia.salvar()` grava a estante sempre em `user://estante` (D-01).
- A saída tem uma linha por conferência e, no fim, `PASSOU`, `FALHOU` ou `PULADO` por cenário. O processo sai com código 1 se algo falhou.
- Os cenários em janela:

```bash
powershell -ExecutionPolicy Bypass -File jogo/qa/janela/rodar_janela.ps1 -Parte tudo
```

  - Abrem o jogo com as opções de teste, sem mouse nem teclado, com `APPDATA` em `%TEMP%\simvida_qa_janela`.
  - Os resultados vão para `qa/janela/resultado-*.json` e as capturas para `qa/capturas/`.
  - **Antes da primeira vez num worktree novo**, importe os recursos com `--headless --path jogo --import`. Sem isso, a janela abre sem arte. Depois, volte os `.import` ao estado do git (veja a observação O-1).

## Pasta de dados do jogador

- Antes de começar, fiz cópia de `estante/`, `estante_teste/` e dos `.cfg`, e uma lista de todos os arquivos (fora `logs/` e `shader_cache/`).
- Nenhum teste meu tocou a pasta real: todos rodam com o `APPDATA` isolado.
- Mesmo assim, a lista do fim tem **arquivos que não são meus**:
  - a estante com 4 livros, depois de ter tido 7 e de ter sido regravada (veja D-01);
  - `teste_fim.txt` com as 3 cópias;
  - `antigos_teste/caprichoso-3*` e `mundo_grande.txt` regravados.
- Tudo isso veio dos testes da sessão A, rodando ao mesmo tempo no worktree `fase0-simulacao-81d444`.
- Não apaguei nada.
