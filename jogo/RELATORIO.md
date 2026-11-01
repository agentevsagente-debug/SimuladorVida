# Relatório da apresentação (sessão B, fase 1)

Tarefas 1 a 5 do briefing `sessoes/fase1-b-apresentacao.md`. Este relatório cobre o ajuste das pessoas no acampamento e as tarefas 4 (interação) e 5 (leveza). As capturas estão em `jogo/capturas/`.

## Ajuste: pessoas no acampamento

**Antes:** à noite, o povo inteiro se amontoava sobre a fogueira.

**Agora:**
- **Roda da fogueira:** quem está `fogueira` ganha um lugar na roda, dos dois lados do fogo, a 11 px do centro e com 7 px entre vizinhos.
- **Os outros:** querem o x que o núcleo dá. Todos os que não dormem entram numa única fila empacotada, com 7 px entre vizinhos; blocos que se encostam se juntam e se centram nas posições desejadas.
- **Estabilidade:** a ordem segue o x desejado e o id, então ninguém troca de lugar entre quadros.
- **Margem:** ninguém fica à esquerda de x = 130, que é água.
- **Andar:** as pessoas andam até o lugar em velocidade de caminhada, igual para todos (9 px/s, ou 36 px/s no ritmo rápido). Assim, quem sai em fila chega em fila. O ritmo normal da API tem um passo a cada 112,5 s, e interpolar entre passos faria todos deslizarem.
- **Cabanas:** quem acorda junto sai da cabana em fila, com um pequeno atraso por pessoa.

**Medido** (`CONTAR_SOBREPOSICAO=1`, ritmo rápido, cerca de 2 dias de jogo, sementes 7 e 3, até 20 pessoas): conta quantas figuras cobrem a mesma coluna de pixels.
- **Pessoas paradas:** no máximo 1. Nunca há duas no mesmo pixel; vizinhas a 7 px, com sprites de 8 px, só encostam a borda.
- **Contando quem anda:** no máximo 4, por um instante, na volta do trabalho para a fogueira, quando as pessoas se cruzam porque a ordem na roda não é a mesma do trabalho.

Captura: `tarefa4-noite-vs-alvo.png` (20h).

## Tarefa 4: interação

| Item | Como funciona | Captura |
|---|---|---|
| **6 poderes por gesto** | Escolha o poder na alça e segure o botão sobre o mundo. A intensidade vai de 0 a 1 em 2 s, numa caixinha escura com o ícone e a barra de carga. Soltar chama `usar_poder(poder, x, intensidade)`. O botão direito cancela. O resultado aparece na alça: "Raio: um milagre sobre Doim". | `tarefa4-poder-*.png`, `sequencia-fogo/` |
| **Efeitos** | **Chuva:** nuvens, gotas e respingos, por 8 a 16 s conforme o grau. **Raio:** canal, impacto, poeira e clarão. **Fogo:** chamas, brasas e fumaça; depois a zona fica queimada, com terra queimada e árvores carbonizadas enquanto o núcleo marcar `queimada`. **Fartura:** aura e brilhos. **Erguer a terra:** terra subindo, poeira e depois a pedra erguida no lugar que o núcleo dá. **Sonho:** espiral e brilhos sobre a pessoa atingida. | |
| **Seletor de poder discreto** | A alça mostra só o poder escolhido e o ritmo atual. Clicar abre a fileira de opções, que se fecha depois da escolha. Os ícones ficam só sobre a madeira escura da alça ou numa caixa escura, nunca direto sobre o céu. | `tarefa4-alca-poderes.png` |
| **Dica do cursor** | **Pessoa:** nome, idade, traços, papel e a prece, com o ícone da necessidade. **Sinal:** quem reza, o texto e há quantos dias espera. **Lugar:** o nome da zona, os nomes dados pelos povos e o estado (seca, queimada, farta). Caixa e fontes da sessão C. | `tarefa4-dica-*.png` |
| **Sinais de prece** | Ficam sobre a cabeça de quem reza; se a pessoa dorme, acima da cabana. A intensidade segue a regra do orquestrador: comum até 10 dias, urgente até 30, desesperado acima disso ou com importância 8 ou mais. A prece banal é sempre comum. "Os últimos": facho sobre a vila enquanto restarem 5 pessoas ou menos. | `tarefa4-sinal-prece.png` |
| **Tempo** | Pausa, normal (112,5 s por hora de jogo), rápido (1,9 s) e salto até o próximo acontecimento de camada "nota" ou "chamado", com aviso do que houve. A barra de espaço pausa. | `tarefa4-salto.png` |
| **Seguir a linhagem** | O botão (ou L) aproxima a vista 2x e segue a pessoa acompanhada, com paralaxe nas montanhas e na mata. Se ela dorme, mira a cabana. Clicar numa pessoa sem poder escolhido passa a acompanhá-la (`acompanhar`). | `tarefa4-seguir-linhagem.png` |
| **Crônica** | O botão (ou C) abre o pergaminho com `cronica()`, no fim, onde está o mais recente; a roda do mouse rola. Ao voltar de uma ausência de 1 dia ou mais, abre sozinha com "Enquanto você esteve fora (N dias)" e o relato da ausência. | `tarefa4-cronica.png` |
| **Modo discreto e esconder** | D liga e desliga o modo discreto: o fogo e o raio do deus não mostram chamas nem impacto, e a crônica continua igual. H ou F8 escondem; também escondem o botão da alça, a bandeja e o atalho global opcional. | |
| **Salvar e carregar** | O jogo salva em `user://mundo.txt` a cada dia de jogo e ao fechar, e carrega com `carregar_e_avancar()` ao abrir. | |
| **Ícone** | O ícone da sessão C aparece na janela, na barra de tarefas (conferido na captura da barra) e na bandeja. O `.ico` está ligado para a exportação. | |
| **Céus da fase 2** | O `ceu_seca` substitui o céu de dia enquanto `clima.seca` for verdadeiro, e o `ceu_eclipse` por 3 horas depois de um evento `eclipse`. | |

**Verificação no Windows** (`jogo/ferramentas/verificar.ps1`, 19 de 19 itens; resultado em `capturas/verificacao.json`):
- os itens da moldura: transparência, sempre por cima, clique atravessando, arrastar, escala pela roda na alça, esconder e mostrar, nitidez em 2x, 3x e 4x;
- **o gesto real:** abre os poderes, escolhe o raio, segura 1,5 s sobre o céu e solta. Resultado: raio em x = 300, intensidade 0,75, um milagre.

**Teste de fidelidade** (`jogo/ferramentas/fidelidade.sh`): 0,00% de diferença com a montagem da arte, de dia e de noite.

**Teste de ausência:** salvei, fechei e reabri; o mundo voltou no mesmo passo. Depois, com 30 horas de ausência simulada (`--simular-ausencia=30`), passaram 40 dias e o relato abriu na crônica. Apaguei os arquivos de teste (`mundo.txt` e o `moldura.cfg` da tarefa 1) da pasta do jogo, para a primeira abertura do jogador começar do zero.

### Problemas encontrados e corrigidos

- **Clique duplo no Windows:** o Godot entrega um segundo "apertou", marcado como duplo, sem soltar no meio. Na alça, isso apertava o botão duas vezes; no gesto, reiniciava a carga. Agora o segundo evento é ignorado.
- **Pessoas na água:** o espalhamento empurrava gente para dentro da água. Agora existe a margem de x = 130.

### O que fica em aberto (decisão do orquestrador)

- **Clique numa pessoa:** sem poder escolhido, ele chama `acompanhar()`. Isso troca a linhagem no núcleo, então um clique distraído muda quem o jogador segue. Alternativa: pedir confirmação ou exigir clique duplo.
- **Os 5 poderes da fase 2** (seca, dilúvio, terremoto, presságio e cura) não estão na API. Só os céus de seca e de eclipse estão ligados. O núcleo já emite `cometa` e `terremoto`; os efeitos `cometa_4q` e fenda, poeira e pedras podem ser ligados quando o orquestrador quiser.
- **Poses:** `colher`, `rezar` e `sentado` só existem para o adulto A, então as mulheres aparecem com a silhueta dele. Os idosos não têm nenhuma das três. É assunto da sessão C.
- **Clique perdido:** numa rodada da verificação, o primeiro clique na moldura logo depois de um clique na janela de trás se perdeu. A janela-alvo, que não é o jogo, perdeu um clique do mesmo jeito noutra rodada. Num teste de 10 repetições, chegaram 10 de 10. Parece ser do clique sintético, não da moldura, mas convém observar no uso real.
- **Argumentos de teste**, que não são funções do jogo: `--demo`, `--dica`, `--abrir`, `--anos`, `--simular-ausencia`, `--capturar*`, `--quadros`, `--intervalo`, `--cena=layout`, `--efeito` e as variáveis `CONTAR_SOBREPOSICAO` e `DEPURAR_ALCA`.

## Correção do céu (grade de pontos)

**Causa:** nas horas de transição (5h–7h, 17h–18h, 19h–20h), o shader misturava os dois céus com pontilhado ordenado na tela inteira. No ritmo normal, cada transição dura cerca de 2 minutos reais, por isso a grade aparecia e sumia. A neblina noturna também desenhava pontos em grade na base das montanhas.

**Correção:**
- **Céu:** a troca de horário é uma frente (a noite desce do alto, a manhã sobe do horizonte), com pontilhado só numa faixa de 2 linhas.
- **Resto da cena:** montanhas, chão e pessoas trocam inteiros no meio da transição.
- **Neblina:** não existe à noite; de manhã, fiapos esparsos e irregulares (ruído fixo, não grade), num tom vizinho.

**Teste:** `ferramentas/ceu_sem_grade.py` captura a vista de meia em meia hora, o dia inteiro, com e sem chuva (96 capturas), e conta os pixels isolados do céu.
- **Reprova a versão antiga:** 22.212 pixels isolados às 19h30, contra um limite de 8.198.
- **Aprova a atual:** 96 de 96. À noite, o céu tem os mesmos 115 pixels isolados da cena-alvo.

## Vida em cena (API v8 e arte da seção 18)

Em `apresentacao/vida.gd`:

- **Agenda:** cada pessoa segue os trechos da hora (`x0` → `x1`, ação, para onde olha, cena).
  - Como a agenda espalha uma caminhada pelo trecho inteiro (uma hora são 112,5 s), a pessoa anda em passo natural até o destino, de 7 a 11 px/s conforme a pessoa, com pausas curtas no caminho. Lá, faz a ação até o trecho seguinte.
- **Ações e folhas** (mapa da seção 18):

  | Ação | Folha |
  |---|---|
  | andar | adulto A, adulto B ou idoso andando; as crianças correm |
  | colher | colher; com roça perto, enxada; na margem, pescar e segurar o peixe |
  | pescar | pescar e segurar o peixe |
  | lenha | carregar lenha |
  | construir, forjar, escrever, remar, lutar | a folha de mesmo nome |
  | rezar | rezar |
  | fogueira | sentado ou sentado no chão |
  | conversar | um fala e o outro ouve, alternando |
  | cuidar | mãe com bebê |
  | dançar | dançar; na festa, o primeiro participante toca o tambor |
  | carregar_morto | carregar no funeral |

- **Parado com vida:** microanimações de olhar para os lados, esticar, sentar no chão, agachar, coçar a cabeça e bocejar, em fatias de tempo irregulares e fixas por pessoa. O idoso fica apoiado na bengala, e as crianças pulam de vez em quando.
- **Cenas:**
  - **funeral:** dois carregadores com a mortalha por cima;
  - **festa e casamento:** dança, tambor e bandeirolas sobre a roda;
  - **migração:** trouxa e cesto;
  - **guerra:** o primeiro da cena leva o estandarte, e os outros lutam.
- **Ainda sem efeito na tela:** a cena `corvos` (ver "Criaturas"), as folhas dos estágios 3 a 6 (`estagioN/adulto_eN_*`) e o casal de mãos dadas.
- **Teste de sobreposição** (`CONTAR_SOBREPOSICAO=1`): entre os parados, no máximo 1 figura por coluna de pixels; com quem anda, no máximo 4 por um instante, quando as pessoas se cruzam.
- **Sequências:** `capturas/cotidiano-dia.gif` (9h) e `capturas/cotidiano-tarde.gif` (17h), cada uma com 15 s a 4 quadros por segundo.

## Estações e vida ambiente

- **Estações:** cada peça é procurada primeiro em `arte/estacoes/<estação>/` e, se não estiver lá, vale a de verão, como no `montar.py`. Isso vale para o terreno, a vegetação, as construções, as marcas, os planos de fundo e o céu. Os fundos da estação anterior são soltos na troca.
- **Inverno:** as 3 colunas de água mais perto da praia congelam (`gelo_superficie`), e cai neve em boa parte dos dias.
- **Outono:** folhas secas caem das copas.
- **Criaturas** (`apresentacao/criaturas.gd`), conforme a tabela de estação e horário da seção 17: bandos de pássaros, pássaro pousado, peixe saltando, sapo, garça na margem, coelho (que pula para longe de gente), cervo pastando no morro, morcegos ao entardecer e o bando migrando no inverno. Os corvos ainda não estão ligados à cena `corvos` da API.
- **Captura:** `capturas/estacoes.png` mostra primavera, verão, outono e inverno, nessa ordem.

## Memória: o que foi medido e o que foi feito

1. **Peças usadas só na CPU importadas como Image.** Terreno, peças, camadas, folhas de pessoas e estações (292 arquivos) eram importados como textura. Ler a imagem de volta criava uma textura no driver para cada um. Ganho de 9,5 MB em 3x: de 224,6 para 215,1 MB de conjunto de trabalho.
2. **Testes que não mudaram nada:**
   - reduzir o buffer de lote 2D, o atlas de sombras e a fila de mensagens;
   - pôr todas as pessoas numa folha só: só 1,4 MB, então um atlas de texturas renderia pouco.
3. **Contadores do Godot:** comparado ao protótipo da fase 0, o jogo tem 6,5 MB a mais de memória estática do motor, 3 MB de texturas e 3 MB de vídeo. O resto da diferença está fora do motor: driver, bibliotecas e sobra do heap depois da montagem.
4. **Correção de método:** desde a fase 0, chamei o conjunto de trabalho de "a Memória do Gerenciador de Tarefas", e isso está errado. A coluna "Memória" do Gerenciador de Tarefas é o conjunto de trabalho **privado**, que não conta as páginas compartilhadas do executável do editor. O `medir.ps1` agora grava as três medidas.

## Auditoria visual da sessão C (itens da B)

"Antes" são as capturas da auditoria, em `arte_claude/auditoria/`. "Depois" são as capturas em `jogo/capturas/auditoria-*.png`.

| Item | O que mudou | Depois |
|---|---|---|
| **1. Construções** | `apresentacao/obras.gd` liga `construcoes()` (tipo e estágio) às peças da arte: cabana, taipa, casa de pedra, enxaimel e tijolo; templo de cada estágio; celeiro; forja; arquivo; moinho; muralha; barco na linha d'água; roça (irrigada no estágio 6). As ruínas de `ruinas_visiveis()` ficam atrás. As variações de cultura (telhado e símbolo) ainda usam a peça de exemplo, porque a API não diz a cultura de cada povo. | `auditoria-1-mundo-60-anos.png`, `auditoria-1-mundo-150-anos.png` |
| **2. Gente sobre o lago** | Só quem `remar` fica sobre a água. Os outros têm o x preso à margem (x ≥ 130), inclusive nos trechos da agenda. | mundo de 150 anos |
| **3 e 4. Multidão e acampamento** | Com mais de 14 pessoas paradas, formam-se duas fileiras: uma meio passo atrás, 2 px acima e desenhada antes. A roda da fogueira pula as cabanas. A distribuição fina depende do x de descanso que a sessão A vai dar a cada pessoa. | `cotidiano-*.gif` |
| **6. Chuva** | Nuvens em duas camadas, com espaço, altura, quadro e lado irregulares, cobrindo o alto do céu sobre a chuva. | `auditoria-6-chuva.png` |
| **9. Os 5 poderes da fase 2** | Seca, dilúvio, terremoto, presságio e cura no seletor (ícones da C) e no gesto. Efeitos: seca (calor e rachaduras), dilúvio (chuva pesada), terremoto (tela tremendo, fenda, poeira e pedras), presságio (cometa, eclipse com o céu de eclipse, ou luzes) e cura (luz e brilhos). | `auditoria-9-*.png` |
| **10. Manhã** | A noite vira entardecer até as 6h30, e o dia só fica pleno às 8h. Às 7h há amanhecer. | `auditoria-10-manha-7h.png` |
| **12. Raio** | A descarga e o canal esfriando duram 0,6 s, o impacto 0,8 s e o clarão 0,12 s. | `auditoria-12-raio.png` |
| **13. Cabanas à noite** | As construções têm etiqueta própria e pegam um nível a menos de luz do fogo, então perdem o contorno néon. Por isso a fidelidade de noite com a montagem da arte passou de 0 para 59 pixels (0,08%), todos nas bordas das cabanas perto do fogo. | `auditoria-13-noite.png` |

**Também mudou:**
- **Inverno:** as pessoas usam o capuz e o manto da C.
- **Fumaça, mata e montanhas:** vêm da arte corrigida, sincronizada por `ferramentas/sincronizar_arte.py`.

## Relógio do mundo

- **Onde e como:** canto superior direito da faixa da alça, numa pastilha escura (`caixa_dica_9s`), com a fonte 5×7 clara (dourada à noite).
- **Minutos:** saem da fração da hora; no ritmo rápido, de 10 em 10; na pausa, parado; no salto, avançam junto.
- **Cursor por cima:** a dica mostra "Dia 12 do outono, ano 37".
- **Mouse:** a área do relógio entra no polígono de passagem do mouse.

## Tarefa 5: leveza

**Método:** o mesmo da fase 0. `jogo/ferramentas/medir.ps1`:
- espera 10 s de aquecimento e depois lê, a cada 5 s durante 10 minutos, o tempo de CPU e a memória do processo;
- a CPU % é Δ tempo de CPU ÷ (Δ tempo real × 28 núcleos) × 100;
- usa o executável do editor; os modelos de exportação não foram autorizados;
- o mundo é novo, com a semente 7, começando às 17h, na escala padrão desta tela (3x, 144 dpi);
- os CSVs estão em `jogo/medicoes/`.

**Cenários:**
- **normal:** visível, ritmo normal;
- **rápido:** visível, ritmo rápido, com gente andando o tempo todo;
- **escondido:** minimizado.

**Medições de 10 minutos** (código de `f78be96`, peças de CPU importadas como Image, escala 3x):

| Cenário | CPU média (máquina) | % de 1 núcleo | Conjunto de trabalho (médio) | Gerenciador de Tarefas, "Memória" (médio) | Bytes privados (máx.) |
|---|---|---|---|---|---|
| normal | 0,164% | 4,6% | 216,9 MB | 113,3 MB | 217,3 MB |
| rápido | 0,185% | 5,2% | 215,6 MB | 112,3 MB | 215,3 MB |
| escondido, 6 min sozinho | ~0,014% | 0,4% | 199–200 MB | — | — |

**Leitura de 60 s com o código final** (construções, poderes, relógio), em 3x: 217,8 MB de conjunto de trabalho, 114,7 MB na coluna "Memória" do Gerenciador de Tarefas e 217,1 MB de bytes privados.

- **CPU:** muito abaixo da meta de 2% nos três cenários.
- **Memória:** depende de qual medida vale para a meta.
  - Na coluna "Memória" do Gerenciador de Tarefas, que é o que o usuário vê, o jogo usa cerca de 113 MB, abaixo de 200.
  - No conjunto de trabalho e nos bytes privados, usa cerca de 216 MB, acima de 200.
  - **Decisão do orquestrador:** qual das medidas vale para a meta, e se autoriza os modelos de exportação, que tirariam o código do editor.
- **Escondido nas medições em lote:** nas duas vezes, algo de fora restaurou a janela por volta de 150 a 250 s, e a CPU e a memória subiram ao nível do visível. O CSV de `escondido` registra isso. Rodando sozinho por 6 minutos, o cenário ficou minimizado o tempo todo, sem restaurações, com 199–200 MB e 0,4% de um núcleo.
