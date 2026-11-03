# Relatório de QA (sessão D)

*Primeira rodada, 01/11/2026, sobre a branch `claude/qa-cenarios-3b8628`, com a `main` até `c06e4d0` (a correção da falha ao fechar e a versão visível). A fonte de verdade é o documento funcional. A matriz completa está em `qa/cenarios.md`.*

## Números

*Rodada de fechamento da 0.2.0, em 02/11/2026, na main `2a516d8` (a tag `v0.2.0` está no `1471190`; depois dele, só documentação e QA). Rodaram a bateria do núcleo, o som e a lupa sem tela e os 13 cenários em janela (sem o mouse real e com o jogo calado). O QA-194 foi rodado pela B, com janela de verdade. O QA-205 rodou com a janela de verdade, depois que o usuário liberou o PC.*

| | Quantos |
|---|---|
| Cenários na matriz | 142 |
| Automatizados no núcleo (`jogo/qa/rodar_qa.gd`) | 105 |
| Automatizados com o jogo inteiro sem tela (`jogo/qa/som/testar_som.gd`, `jogo/qa/lupa/testar_lupa.gd`) | 15 |
| Automatizados em janela (`jogo/qa/janela/rodar_janela.ps1`) | 13 |
| Só manuais (precisam de mouse e teclado) | 9 (QA-019, QA-037, QA-084, QA-152, QA-160, QA-161, QA-163, QA-165, QA-173) |
| **Passam** | **130** |
| **Falham** | **0** |
| Pulados | 3 (QA-053, QA-110, QA-127): por condição rara nas sementes |

**Na main `e4dd9d1` (0.2.1, com o D-18 e o D-19 corrigidos), sem janela, em 02/11/2026:** o núcleo dá **104 passam, 0 falham e 3 pulados** (107 cenários; o QA-206 e o QA-207 passam). O som dá 8 passam e 1 pulado (o QA-194, com janela); a lupa, 5 passam e 1 pulado (o QA-205, com janela). Os cenários em janela não foram repetidos nesta rodada. Com o QA-206 e o QA-207, a matriz tem 144 cenários, e nada falha.

**A 0.2.0 fechou sem nenhuma falha.** Depois, o QA-206 (textos na tela), escrito para o "{p} teve um sonho" que o usuário viu, falha na mesma main: acha o D-18 e o D-19 (A). Com ele, a matriz tem 143 cenários, e o núcleo dá 102 passam, 1 falha e 3 pulados.
- O núcleo dá 102 passam; o som, 9 de 9 (o QA-194 pela B); a lupa, 6 de 6 (o QA-205 com a janela de verdade, com o PC liberado pelo usuário: 24 mudanças de escala nos 4 cantos, nenhuma fora da tela); os 13 cenários em janela passam.
- Leveza em 1x, visível e calado: o mundo novo fica em 5,64% de um núcleo (pico de 7,79%) e o de 200 anos em 5,52% (pico de 9,35%), com 241 e 289 MB. O som custa −0,09% de um núcleo e 2,7 MB (QA-197, 3 pares): dentro do ruído.

**Por área:**

| Área | Cenários | Passam | Falham | Pulados | Manuais, não rodados |
|---|---|---|---|---|---|
| Começo do mundo | 5 | 5 | 0 | 0 | 0 |
| Cotidiano | 11 | 10 | 0 | 0 | 1 |
| Os 11 poderes e as 3 intensidades | 18 | 17 | 0 | 0 | 1 |
| Preces e respostas | 9 | 9 | 0 | 0 | 0 |
| Religião, crença e nome do deus | 5 | 4 | 0 | 1 | 0 |
| Culturas | 6 | 6 | 0 | 0 | 0 |
| Estágios 1 a 6 e regressão | 5 | 5 | 0 | 0 | 0 |
| Linhagem acompanhada | 5 | 4 | 0 | 0 | 1 |
| Ausência e teto de 1 ano | 9 | 9 | 0 | 0 | 0 |
| Persistência e saves corrompidos | 12 | 11 | 0 | 1 | 0 |
| Fim do mundo, mundo vazio, criar povo e ruínas | 12 | 11 | 0 | 1 | 0 |
| Estante e abandono | 6 | 6 | 0 | 0 | 0 |
| Modo discreto | 3 | 2 | 0 | 0 | 1 |
| Moldura (esconder, escala, passagem do mouse) | 8 | 4 | 0 | 0 | 4 |
| Leveza | 7 | 6 | 0 | 0 | 1 |
| Robustez da API e cenas (achados durante a leitura) | 5 | 5 | 0 | 0 | 0 |
| Som | 10 | 10 | 0 | 0 | 0 |
| Lupa | 6 | 6 | 0 | 0 | 0 |
| **Total** | **142** | **130** | **0** | **3** | **9** |

**Os defeitos e a situação de cada um:**

| # | Defeito | Gravidade | Bloqueia a 0.1 | Área | Situação na main `2a516d8` (0.2.0) |
|---|---|---|---|---|---|
| D-01 | Os testes do núcleo escreviam e apagavam a estante real do jogador | alta | prioridade | A | **corrigido**: os mundos de teste guardam os livros em `<nome>.estante`; QA-109 e QA-182 passam |
| D-02 | O raio e o sonho acertavam onde a pessoa estaria no fim da hora | alta | sim | A, B | **corrigido**: o núcleo mira pelo minuto (QA-027: 100% dos toques), e a interface passa o minuto e quem está sob o cursor (QA-185 passa) |
| D-03 | O mundo só ficava vazio na virada do dia | média | sim | A | **corrigido** (QA-131 passa; na tela, o aviso aparece aos 6 s) |
| D-04 | Sem número de versão | média | sim | B | **corrigido** (versão 0.1.0; QA-166 passa) |
| D-05 | Um mundo salvo que não se lê é sobrescrito em silêncio | média | não (antes da 0.2) | A, B | **corrigido** na main `50e5636` (QA-105 passa) |
| D-06 | Um mundo carregado escreve a crônica com frases que mudam | média | não | A | **corrigido** na main `50e5636` (QA-111 passa) |
| D-07 | A thread da rotina leva mais de 1 s com 240 pessoas | média | não | A | **corrigido** (QA-170 passa na main `e27d489`: pior passo de 13 ms em 50x, com 258 pessoas). Na branch da A (`38dadcd`), a rotina passou a ser montada por povo, em paralelo. Na minha sonda, com 258 pessoas, nenhuma espera pela thread com 300 ms entre passos (antes, 600 e 1095 ms), passos de 1 a 4 ms, e a primeira consulta depois do salto de 250 anos em 95 ms (antes, de 1017 a 1253 ms), com a máquina a 17% de carga. Antes disso, estava **contestado pela A**: com a CPU em velocidade plena, a montagem leva de 181 a 195 ms no mesmo mundo (`ferramentas_sim/montagem_rotina.gd`, que calibra a CPU no mesmo processo). As minhas medidas de mais de 1 s foram feitas com a máquina ocupada pelas outras sessões. Fica como risco para máquinas lentas ou em economia de energia; o QA-170 passa |
| D-08 | O mundo velho passava de 8% de um núcleo | média | não | B | **corrigido**: 7,2% no mundo de 200 anos (QA-172 passa) |
| D-09 | O mundo novo começava com o povo | média | decidido: começa vazio | A, B | **corrigido**: o jogo abre vazio às 7h, com o convite na clareira, e criar povo abre a Primeira Era (QA-002 passa; `QA-002-comeco.png`) |
| D-10 | A noite tinha 18,75 min, e o documento dizia 15 | baixa | não | — | **resolvido pelo documento** (QA-016 passa) |
| D-11 | Um milagre pode cair na camada "ambiente" | baixa | não | A | **corrigido** na main `50e5636` (QA-026 passa) |
| D-12 | Dois povos dão o mesmo nome ao mesmo lugar | baixa | não | A | **corrigido** na main `50e5636` (QA-064 passa) |
| D-13 | Exatamente um ano fora não conta como "teto atingido" | baixa | não | A | **corrigido** na main `50e5636` (QA-092 passa) |
| D-14 | Os testes de QA iriam dentro do executável | baixa | não | B | **corrigido** (QA-181 passa) |
| D-16 | A crônica (tecla C) no mundo novo vazio dá "Invalid access to 'grupo' on Nil" | média | **sim** (proposta): é o erro que a B viu, e o primeiro passo provável de um jogador novo | A | **corrigido** (QA-186 passa na main `e27d489`: "No princípio, a região estava vazia…") |
| D-17 | O artesanato aparecia em 40% dos dias, e a API prometia cerca de 7 em 10 | baixa | não | A | **corrigido na branch da A** (`1249c3b`): as cenas disputavam os mesmos adultos; agora o ensinar e o artesanato vêm antes da sesta, e a sesta acaba às 13h40. Em 40 dias: artesanato 55%, sesta 48% e ensinar em 11 dos 20 dias possíveis; a sesta nunca passa das 13h45 (QA-187 passa na main `e27d489`) |
| D-18 | O texto curto do sonho sem alvo sai "{p} teve um sonho" | média | — (0.2.0 já publicada) | A | **corrigido** na main `e4dd9d1` (0.2.1): o sonho usa o sonhador, e o gesto sem ninguém ganhou frase própria ("Um sonho sem ninguém para sonhar"); QA-206 passa |
| D-19 | O raio que mata quem guiava o povo sai "…acertou Marsaim, que guiava {g}…" na crônica e no livro | média | — | A | **corrigido** na main `e4dd9d1`: usa o povo do morto; QA-206 passa |
| D-20 | A vida do povo some da crônica: os atos do deus enchem o ano, e o nascimento da Zeya (o primeiro filho do povo, no save do autor) não aparece no ano 3 | alta (pedido do autor) | — | A | **aberto** (QA-208, QA-209 e QA-210 falham); a A está corrigindo o `cronista.gd` |
| D-15 | O aviso "Não resta ninguém" saía pelos lados do pergaminho | média | sim | B | **corrigido**: o texto quebra dentro do pergaminho (`QA-129-extincao_00.png`) |

**Na rodada anterior (main `e27d489`, 0.2.0 antes da lupa), também:**
- **O som não pesa (QA-197):** mesmo mundo às 17h, em 1x, visível, 3 pares de 90 s. Com `--som-inaudivel` (tudo toca e é mixado, a −80 dB, para não fazer barulho no PC do usuário) contra `--sem-som`:
  - nos três pares, o som custa −0,04%, +0,19% e +2,22% de um núcleo (3,06 contra 3,10; 3,17 contra 2,98; 4,83 contra 2,61);
  - a média é 0,79% e a mediana 0,19%, abaixo do limite de 1%; o terceiro par destoa, com a máquina ocupada pelas outras sessões;
  - a memória fica 2 MB acima (limite: 20 MB).
- **Leveza em 1x na 0.2.0, calado:** o mundo novo fica em 2,75% de um núcleo (pico de 4,36%) e o de 200 anos em 6,28% (pico de 8,11%), com 240 e 288 MB.
- **Fechar o jogo:** 20 fechamentos (10 pelo fim da duração, 10 pela mensagem da janela), todos com código 0.
- **As 11 capturas** saíram (`qa/capturas/`).
- **Os cenários em janela abrem calados** desde a 0.2 (`--sem-som`), para não fazer barulho no PC de quem trabalha.
- **Leveza em 1x na 0.1, visível** (semente 7, 120 s): o mundo novo fica em 5,85%, o de 50 anos em 3,46% e o de 200 anos em 7,18% de um núcleo (pico de 9,65%), com 234 a 299 MB.
- **Opções de teste da janela:**
  - `--mundo-novo` abre o mundo vazio, mesmo junto com `--semente`, a não ser com `--com-povo`;
  - `--semente` sozinha, `--dias`, `--anos`, `--cena` e `--cenario-raro` já trazem o povo;
  - os cenários de fechar e de leveza usam `--com-povo`, e a captura do começo (QA-002) não usa, de propósito.
- **Fechar o jogo:** 12 fechamentos com o atalho ligado (6 pela mensagem da janela, 6 pelo "Sair"), todos com código 0 e com "threads encerradas" no log.
- **Observação menor para a B:** num fechamento, o log escreve "threads encerradas" 3 vezes, porque mais de um caminho de saída chama `encerrar()`. É inofensivo.

A saída completa da última rodada está em `qa/ultima-rodada.txt` (núcleo), `qa/ultima-rodada-som.txt` e `qa/ultima-rodada-lupa.txt`, e os resultados em janela em `qa/janela/resultado-*.json`.

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

### D-16. A crônica no mundo novo vazio dá erro de script
**Cenário:** QA-186 (e o fuzz de entrada) · **Gravidade:** média · **Bloqueia:** sim (proposta). É o erro que a B viu uma vez, e o primeiro passo provável de um jogador novo: a dica da primeira abertura sugere "C abre a crônica" · **Área:** A

- **Caminho mínimo, sem tela:**
  1. `var m := Mundo.new(7)`: o mundo novo do D-09, vazio e com **0 eventos**.
  2. `m.cronica_viva()` ou `m.cronica()`.
- **No jogo:** abrir sem mundo salvo (`--sem-config --mundo-novo`) e apertar C antes de criar o povo.
- **Obtido:**
  - "Invalid access to property or key 'grupo' on a base object of type 'Nil'", em `cronista.gd:2593`, `_prologo`;
  - a pilha é `_prologo` ← `montar` ← `mundo.cronica_viva` ← `interface.alternar_cronica` ← `interface.tecla` ← `moldura._unhandled_input`;
  - `_prologo` começa com `var e = m.evento(0)`, que é nulo no mundo vazio, e depois lê `m.grupos[e.grupo]`;
  - depois de passar um dia, o mesmo ponto dá a variante "Invalid access of index '-1' on a base object of type 'Array'";
  - o mesmo erro sai ao salvar e carregar o mundo vazio e pedir a crônica;
  - a crônica aparece mesmo assim (com 207 caracteres), mas o erro fica no log.
- **Esperado:** a crônica do mundo vazio tem um texto próprio ("A região espera…"), sem erro de script.
- **O resto do mundo vazio está limpo:** as consultas da tela, as dicas, as sugestões, os eventos, um poder, um dia e salvar e carregar não dão erro (QA-186).

### D-17. As cenas novas da tarde apareciam menos do que a API prometia (corrigido na branch da A, `1249c3b`)
**Cenário:** QA-187 · **Gravidade:** baixa · **Bloqueia:** não · **Área:** A

- **Passos:** sementes 1 e 2, no ano 4, 20 dias cada; as cenas que acontecem das 12h às 15h59 (`cenas_ativas()` de hora em hora).
- **Obtido, na branch `38dadcd`:**

  | Cena | Dias com a cena | A API promete |
  |---|---|---|
  | `artesanato` | **16 de 40 (40%)** | cerca de 7 em 10 |
  | `sesta` | 20 de 40 (50%) | cerca de 2 em 3 |
  | `ensinar` | 8 dos 20 dias em que havia criança de 8 a 13 anos e alguém de 35 ou mais (40%) | cerca de 3 em 5 |

- O artesanato fica bem abaixo: com p = 0,7, 16 ou menos em 40 tem chance de menos de 0,1%. A sesta e o ensinar ficam abaixo, mas dentro da folga do teste (metade da frequência prometida).
- Quem dorme na sesta está `deitar` com o detalhe `sesta` (44 de 44).
- **Esperado:** a frequência da API, ou o texto da API ajustado para a frequência real. As três cenas podem estar disputando os mesmos adultos.

### D-18. O sonho sem alvo deixa o "{p}" no texto curto
**Cenário:** QA-206 · **Gravidade:** média (o jogador vê o molde cru na tela) · **Área:** A · **Achado pelo usuário**, depois de um milagre de sonho

- **Passos:** sementes 1 a 6; `usar_poder("sonho", x, intensidade, -1, -1.0)`, sem alvo, em 12 pontos da região (x de 130 a 438) e nas 3 intensidades; depois, `texto_curto(id)` de cada evento.
- **Obtido:** "{p} teve um sonho", em **37** dos eventos `sonho` (por exemplo, o #59 da semente 1).
- **Causa provável** (`cronista.texto_curto`): o `{p}` só é preenchido com `e.participantes[0]`, e o sonho sem alvo não põe o sonhador em `participantes`. É a causa que o orquestrador apontou.
- **Esperado:** o nome de quem sonhou, ou outra frase quando não há sonhador.

### D-19. O raio que mata quem guiava o povo deixa o "{g}" na crônica
**Cenário:** QA-206 · **Gravidade:** média · **Área:** A

- **Passos:** semente 5, os 11 poderes com e sem alvo nas 3 intensidades; o raio acerta quem guiava o povo.
- **Obtido:** "Um raio sem nuvem acertou Marsaim, que guiava {g}, diante de todos." O texto sai igual na crônica em curso, na crônica viva, na crônica, na do ano 1 e no livro.
- **Causa provável** (`cronista._divino`, "raio_divino", com `era_lider`, linhas 2453–2454): a frase usa `{g}`, mas o evento do raio divino não tem grupo (`e.grupo == -1`), então `v["g"]` não existe.
- **Esperado:** o nome do povo de quem morreu.

### D-20. A vida do povo some da crônica quando o deus age muito
**Cenários:** QA-208, QA-209, QA-210 · **Gravidade:** alta (pedido do autor) · **Área:** A · **Achado pelo autor** no próprio save (`qa/save-sergio-ano3.txt`)

- **No save do autor** (ano 3 em curso, povo Mokon, 13 pessoas):
  - o evento 20 é o nascimento da Zeya, o primeiro filho do povo (`motivo: primeiro`);
  - o ano 3 da crônica viva e a crônica do ano em curso contam só o cometa, a enchente e a seca divina, e **não citam a Zeya**;
  - quando o ano 3 fecha (22 dias depois), a crônica do ano 3 passa a citá-la. O defeito que o autor vê é o do ano em curso.
- **Povo pequeno (QA-209):** 8 sementes de 25 anos, com 5 sinais no começo de cada ano. Nos anos com 4 ou mais atos divinos, há 323 nomes de quem nasceu, casou ou morreu num povo de até 30 vivos, e **281 não aparecem** na crônica do ano. Por exemplo: o nascimento de Viraya, no ano 1 da semente 1.
- **Povo grande (QA-210):** no mundo de 250 anos da semente 3, há 45 anos de povo grande (60 ou mais vivos) com 6 ou mais nascimentos. Em **40 deles**, a crônica do ano não dá a conta de nascidos nem de mortos. Por exemplo: o ano 193 do povo Koil, com 94 vivos, 12 nascimentos e 1 morte.
- **O livro:** 48 473 caracteres no mundo de 250 anos, antes da correção.
- **Decisão do orquestrador (revisável):** depois da correção, o QA-210 aceita até **85%** a mais (antes, a proposta era 50%). O autor pediu os nomes, e a A já agrupou e cortou o que dava sem perder conteúdo: na versão dela, o livro tem 87 753 caracteres, ou +81%.
- **Tempo do testar_textos:** os 318 s da rodada de 03/11 foram disputa de máquina; a A mediu 94 s na base e 96 s com o código novo.
- **Causa** (segundo o orquestrador): os atos do deus enchem o orçamento de frases do ano, e os casamentos e as mortes comuns de povo pequeno são zerados.
- **Esperado** (FUN):
  - povo pequeno: cada caso com o nome, e a morte com a idade e a causa;
  - povo grande: a conta do ano por povo, com os nomes só dos casos notáveis;
  - a vida do povo com uma linha própria no ano, que não disputa espaço com os atos do deus.
- **Observação sobre o save no git:** com `core.autocrlf=true`, o checkout no Windows trazia o save com CRLF, a soma md5 não conferia, e o jogo o renomeava para `.ilegivel.txt`. Pus `qa/.gitattributes` com `save-*.txt -text`, e o QA-208 também normaliza as quebras de linha ao copiar.

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

## Fuzz de entrada: a caça ao "grupo on Nil"

**O que é** (`jogo/qa/fuzz/fuzz_entrada.gd`):
- abre o jogo inteiro (`principal.tscn`) e injeta ações sorteadas por `Viewport.push_input`, sem o mouse nem o teclado reais (o cursor não se move);
- as ações são movimentos (dicas), cliques, cliques com o botão direito, gestos segurados de até 2,5 s, rodas, cliques duplos e as teclas C, E, L, D, S, espaço, Esc, Enter, 0 a 3 e setas;
- um terço delas vai para a faixa da alça (botões, poderes e relógio);
- ficam de fora Q (sai), H e F8 (escondem a janela);
- cada erro de script é capturado com `OS.add_logger`, com a pilha, o número da ação, a fase e as 8 ações anteriores;
- `--fuzz-semente` fixa a sequência de ações. O momento exato pode variar uns quadros, porque o jogo segue o relógio.

**As rodadas** (logs em `qa/fuzz/`):

| Rodada | Mundo | Ações | Fases cobertas | Erros |
|---|---|---|---|---|
| sementes 1 a 4 | `--mundo-novo` (vazio, D-09) | 3200 | o mundo vazio do começo (perto de 2000 ações), o primeiro povo nascendo de um clique (sementes 1, 2 e 4) e a chegada; uma extinção na semente 4 | **10, todos o D-16** (tecla C no mundo vazio) |
| sementes 5 e 6 | com povo, extinção na ação 40 | 1400 | o mundo extinto, com o livro fechado, por perto de 650 ações cada | 0 |
| semente 7 | com povo, extinção na ação 40, 30% dos cliques no vazio passando | 900 | 4 extinções e 4 recomeços (eras 2 a 5), com as chegadas do povo | 0 |
| **Total** | | **5500** | | **1 erro distinto (D-16)** |

**Resposta à pergunta:** o erro que a B viu vem da tecla C (crônica) no mundo novo vazio, antes do primeiro povo. Não vem de um clique, de uma dica ou da transição. É da A (`cronista._prologo`), e o caminho mínimo está no D-16. Nos 5500 passos não apareceu nenhum outro erro de script.

**Para repetir:**

```bash
APPDATA=<pasta temporária> Godot_console.exe --path jogo --script res://qa/fuzz/fuzz_entrada.gd -- --sem-config --mundo-novo --semente=7 --sem-foco --sem-atalho --fuzz-semente=1 --fuzz-acoes=800
```

- Outras opções:
  - `--fuzz-extinguir-em=N` força a extinção na ação N;
  - `--fuzz-clique-vazio=0.3` deixa passar mais cliques no mundo vazio, para provocar o recomeço;
  - `--fuzz-teste-erro` provoca um erro de propósito, para provar a captura.
- O fuzz desliga o modo de baixo consumo, para os quadros não pausarem.

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

## Versão 0.2: o som (TDD, antes do som)

*Escritos em 01/11/2026, na main `8a2f13a`, antes de A, B e C começarem o som. Os cenários são QA-188 a QA-197 (área 17 da matriz).*

**Na 0.2.0 (main `2a516d8`): os 10 passam.** O QA-194 passou com a B, numa janela de verdade: o som calou em 0,6 s ao minimizar. Nesta rodada, eu não o repeti, porque ele abre e minimiza uma janela no PC do usuário. A tabela abaixo é a de antes do som, em `8a2f13a`, quando todos falhavam pelo motivo esperado.

**Na 0.2.0, o que os testes viram:** o volume inicial em −12 dB; a escolha gravada como `moldura/som`; com o som ligado, os seis poderes tocaram 11 players, 2 deles pesados; no modo discreto, 9 e nenhum pesado; com o som desligado, nenhum audível, nem no quadro em que foi desligado.

| ID | Hoje | Por quê |
|---|---|---|
| QA-188 | FALHOU | `project.godot` tem `[audio] driver/driver="Dummy"`: o jogo da 0.1 não toca som nenhum, mesmo que o código toque |
| QA-189 | FALHOU | o `Master` abre a 0 dB |
| QA-190 | FALHOU | não há botão `som` na alça, nem no mundo vazio nem com povo |
| QA-191 | FALHOU | M não faz nada |
| QA-192 | FALHOU | não há escolha para guardar |
| QA-193 | FALHOU | a janela se esconde e o `Master` continua aberto |
| QA-194 | PULADO | só roda com `--janela` |
| QA-195 | FALHOU | os seis poderes não tocam nenhum som (nem pesado, nem leve) |
| QA-196 | FALHOU | a prova falha: com o som ligado, nada toca; o silêncio não dá para provar |
| QA-197 | FALHOU | driver `Dummy` e sem a opção `--sem-som` |

**O contrato proposto à B** (revisável; se os nomes mudarem, eu ajusto os testes):
- **Botão:** de id `"som"` em `interface.botoes`, em todas as fases (mundo vazio, com povo, extinto).
- **Tecla:** M (hoje livre).
- **Silêncio:** som desligado = o barramento `Master` mudo (`AudioServer.is_bus_mute`), no mesmo quadro do clique ou da tecla. Esconder e minimizar também calam o `Master`. Mostrar só devolve o som se o jogador o deixou ligado.
- **Escolha guardada:** no `user://moldura.cfg`, gravada ao mudar, e não só ao fechar. Ela vale desde o primeiro quadro da próxima abertura, sem estalo antes de ler a configuração.
- **Volume inicial:** o `Master` entre −60 e −12 dB com a configuração nova.
- **Sons pesados:** os players ficam no grupo `som_pesado`. A B escolhe quais são, mas a lista não pode ser vazia, e os seis poderes na intensidade cheia precisam tocar pelo menos um.
- **Players:** os sons tocam por `AudioStreamPlayer` (ou `2D`/`3D`) na árvore, para o teste ver quem toca e em que barramento.
- **Opção de teste:** `--sem-som` abre com o som desligado sem gravar a escolha. Serve para o QA-197 comparar o mesmo jogo com e sem som.

**Como os testes veem o som:**
- `testar_som.gd` abre o jogo inteiro sem tela e usa os poderes pelo gesto de verdade: escolhe, segura 2,3 s sobre uma pessoa e solta. Os seis dão milagre hoje.
- A cada quadro, anota os players que tocam.
- "Audível" = tocando, acima de −60 dB e num barramento cuja rota até o `Master` não está muda. Assim, um som de acontecimento num barramento que não passa pelo `Master` também é pego.
- O `--headless` força o driver `Dummy`. Os barramentos e os players valem; a CPU do áudio não. Por isso o QA-197 roda em janela.
- O QA-197 tem ruído de ±1,7% de um núcleo em medidas de 10 s. Com 3 pares de 90 s, o ruído fica abaixo do limite de 1%.

## Lupa (TDD, antes do botão)

*Escritos em 02/11/2026, na main `e27d489`. Os cenários são QA-200 a QA-205 (área 18 da matriz).*

**Na main `e27d489`: 0 passam, 5 falham e 1 pulado.** Todos falham pelo motivo esperado: não há botão `lupa` na alça.

**Na 0.2.0 (main `2a516d8`): os 6 passam.** O QA-205 rodou numa janela de verdade, posta pelo teste nos 4 cantos da área útil: em 24 mudanças de escala, ela nunca saiu da tela. Antes, na branch da B (`1471190`), numa cópia temporária, sem tela:
- os cliques esquerdos dão 2x → 3x → 4x → 2x, e os direitos 2x → 4x → 3x → 2x;
- a dica diz "Tamanho: 3x (Ctrl+2, 3, 4) / Botão direito diminui";
- a escala volta em 3x e em 4x depois de fechar e abrir (janela de 1440 × 534 e 1920 × 712), e com `--sem-config` nada é gravado.

Na mesma branch, o som continua com 8 passando. O QA-205 precisa da tela de verdade (`--janela`) e espera o PC livre.

**O contrato proposto à B** (revisável):
- **Botão:** de id `"lupa"` em `interface.botoes`, em todas as fases.
- **Cliques:** o esquerdo sobe (2x → 3x → 4x → 2x) e o direito desce (4x → 3x → 2x → 4x). Hoje, o clique direito na alça não faz nada.
- **Tela:** uma escala que não cabe na área útil da tela é pulada, e a janela fica sempre inteira dentro da área útil de uma tela, mesmo encostada num canto.
- **Dica:** a dica do botão mostra a escala atual ("3x") e acompanha a mudança.
- **Escala guardada:** em `moldura/escala` no `moldura.cfg`, como a de Ctrl+2 a 4; com `--sem-config`, não.
- **Conferência:** o teste lê `moldura.escala`, o tamanho da janela (só com tela) e o texto da dica visível (`interface._dica_textos`).

## Textos na tela (QA-206)

*Escrito em 02/11/2026, na main `2a516d8`, depois do "{p} teve um sonho" que o usuário viu.*

- **O que confere:** todo texto que o núcleo manda para a tela. São a crônica viva, a do ano em curso, a de cada ano, a de cada povo, o livro (a crônica completa) e o texto curto de cada evento, em 6 sementes, depois dos 11 poderes nas 3 intensidades (com e sem alvo) e de 12 sonhos sem alvo por semente.
- **O que acusa:**
  - resto de molde: `{`, `}` e `|` (este último sobra de `{p:o|a}`);
  - qualquer caractere que a fonte da apresentação (`fonte_5x7_escura.fnt`, a mesma das outras três cores) não desenha. A fonte tem ASCII de 32 a 126, menos `# $ & * < > @ [ \ ] ^ _ { | } ~` e o acento grave solto, mais `ª « º »`, as vogais acentuadas, `Ç ç Ü ü`, o travessão e as reticências.
- **Como a tela vê o texto:** a crônica e o livro passam antes pelo `_sem_markdown` da interface, o mesmo do leitor da estante, que tira os `#`, `*` e `_` e troca as aspas curvas. O texto curto vai cru para a dica.
- **Na main `6c23e4e`:** 270 gestos que deram certo, 737 textos, e dois defeitos: D-18 e D-19. Nenhum caractere fora da fonte apareceu; só os moldes.
- **Na branch da A (`5edae7a`, 0.2.1, junto com a main):** o QA-206 passa, e a bateria inteira dá **104 passam, 0 falham e 3 pulados** (`qa/rodada-branch-a-5edae7a.txt`).
- **A regra nova da A:** o cronista só escolhe um molde que tenha valor para todas as variáveis; se nenhum tiver, põe "alguém" e anota em `G.chaves_faltando`.
- **QA-207, o teste de textos da A (`ferramentas_sim/testar_textos.gd`), entra na bateria:**
  - roda num processo à parte e leva uns 95 s;
  - na branch da A, sai com 0: 76 tipos de evento com frase curta, 76 sonhos e 171 curas sem ninguém, 34 367 textos conferidos;
  - avisa que a conquista, o culpado e o ruinas_saber não aconteceram nesses mundos; isso não é falha;
  - na main, enquanto o arquivo não chega, fica PULADO.
- O caractere fora da fonte é conferido só no QA-206, e o "alguém" de reserva só no QA-207.

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
  - `-Parte som` mede o custo do som (QA-197), em pares com e sem `--sem-som` (`-Pares 3`, `-Segundos 90`).
- Os cenários da lupa (QA-200 a QA-205), do mesmo jeito: `--script res://qa/lupa/testar_lupa.gd`, isolados em `%TEMP%\simvida_qa_lupa`; `-- --janela` acrescenta o QA-205.
- Os cenários do som (QA-188 a QA-196):

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path jogo --script res://qa/som/testar_som.gd
```

  - Cada etapa roda num processo próprio, com `APPDATA` em `%TEMP%\simvida_qa_som\<grupo>`; leva uns 2 min.
  - `-- --janela` acrescenta o QA-194 numa janela de verdade (minimizada e restaurada pelo próprio teste, sem mouse).
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
