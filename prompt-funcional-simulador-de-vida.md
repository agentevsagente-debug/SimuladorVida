# Simulador de vida com intervenção divina — modelo funcional

*Versão consolidada em 31/10/2026, ao fim da primeira rodada de debate. As decisões da seção "Decisões tomadas por coerência" não foram tomadas pelo autor: foram completadas seguindo a linha das decisões dele e estão abertas a revisão.*

## Objetivo deste documento

Registrar a experiência do jogo do ponto de vista funcional: o que acontece no mundo, como o jogador interage, como os habitantes vivem e o que mantém a experiência interessante ao longo do tempo.

Stack, linguagem, framework, arquitetura, banco de dados, infraestrutura e implementação ficam fora deste documento. Essas decisões pertencem a outro fórum.

O documento separa três coisas: o que está **decidido**, o que está **em aberto** e os **riscos** a acompanhar.

## Referências

- **WorldBox – God Simulator** (https://store.steampowered.com/app/1206560/): referência para a **simulação social**. Vilas que crescem, povos com culturas próprias, guerras, alianças, habitantes com traços e acompanhamento de favoritos.
- **Terraglass** (https://store.steampowered.com/app/5440970/): referência para o **formato**. Um pequeno mundo que fica na área de trabalho enquanto o jogador trabalha, calmo, tátil e sempre rodando.

Em uma frase: **a simulação social do WorldBox no formato de companheiro de área de trabalho do Terraglass, com um povo que percebe e interpreta os atos do seu deus.**

### O que fica de fora das referências

- O **arsenal de destruição** do WorldBox (meteoros, bombas, monstros). Os poderes são poucos e naturais.
- A **escala de continentes** do WorldBox. O mundo é pequeno o bastante para ser legível numa janela.
- A **velocidade frenética** do WorldBox. O ritmo padrão é lento, próprio de quem acompanha de canto de olho.

### O diferencial

No WorldBox, as criaturas não sabem que existe um deus. Aqui, **os habitantes percebem os efeitos das intervenções e reagem a eles**: erguem altares, rezam, discutem o significado de um raio, culpam o deus por uma tragédia. O jogo é sobre a relação entre um deus e o seu povo.

---

## Modelo decidido

### Formato

- Jogo individual: o jogador e o mundo simulado, sem outros jogadores.
- **Companheiro de área de trabalho.** O mundo vive **dentro de uma moldura** que fica sobre as outras janelas enquanto o jogador trabalha.
- O mundo não para enquanto a moldura está aberta.
- O mundo é **pequeno**: algumas vilas, de dezenas a poucas centenas de habitantes.
- A experiência é contemplativa. Não existe objetivo obrigatório, pontuação nem sistema de recompensas externas. A recompensa é acompanhar o mundo crescer e as histórias acontecerem.

### Habitantes e sociedade

- **Só humanos.** As diferenças entre os povos surgem das **culturas**, que divergem com o tempo, e não de raças distintas.
- Os habitantes têm vida própria e **traços** de personalidade (ambicioso, pacífico, rancoroso etc.) que geram comportamento e histórias.
- A sociedade cria sozinha as necessidades, dificuldades e conflitos: escassez, disputas entre vizinhos, rivalidade entre vilas e guerras.
- **O mundo tem memória.** Lugares ganham nomes pelo que aconteceu neles ("Vale da Trégua"), milagres antigos viram mitos e rancores passam de geração em geração. Assim, um evento repetido é diferente porque o contexto mudou.
- **Eras reconhecíveis** marcam a evolução (primeira vila, primeiro templo, primeira guerra). Funcionam como marcos que o jogador nota, e não como metas.

### Culturas

- **Cultura é memória que virou hábito.** Cada traço cultural tem origem em algo que aconteceu, muitas vezes testemunhado pelo jogador ou causado por ele:
  - depois da grande seca, Ardem nunca desperdiça água;
  - o dia da chuva milagrosa vira festa anual;
  - depois do raio que matou o herege no morro, ninguém sobe o morro em dia de tempestade.
- **As culturas se separam** a partir de um único povo inicial:
  - **migração:** famílias fundam outra vila;
  - **cisma:** uma disputa religiosa divide a vila;
  - **isolamento:** um obstáculo, inclusive criado pelo deus, separa duas metades;
  - **ambiente:** a vila da praia vive da pesca, a do morro do pastoreio.

  O fundador marca o caráter da nova vila, e os traços individuais viram coletivos.
- **As culturas formam uma árvore genealógica.** A crônica registra de onde cada uma nasceu ("Toril nasceu de um cisma de Ardem há 30 anos").
- **Seis dimensões culturais**, invisíveis como números e visíveis no comportamento:

  | Dimensão | Polos | Como aparece |
  |---|---|---|
  | Relação com o deus | devota, temerosa, cética | templos, preces, oferendas |
  | Relação com estranhos | acolhedora, desconfiada | casamentos entre vilas, comércio, hostilidade |
  | Poder | um líder, conselho, sacerdotes | quem decide guerra e paz |
  | Recursos | partilha, acumula | celeiros comuns ou cercas |
  | Violência | pacífica, guerreira | armas, treinos, honra |
  | Os mortos | enterram, queimam, veneram | túmulos, fogueiras, altares aos ancestrais |

- **As diferenças aparecem na moldura:** construções (forma, cor, tipo de templo), ritos (funerais, festas), nomes de pessoas e lugares (o mesmo lago tem um nome para cada povo).
- **Cada cultura dá um nome ao deus.** Ardem o chama de "o Que Rega", e Toril, depois do raio, de "o Que Fere". É pelo nome que o jogador descobre como cada povo o vê.
- **Só nomes diferentes, sem línguas diferentes.** As vilas sempre se entendem.
- **As culturas mudam:**
  - **reforma:** uma geração rejeita o tabu dos avós;
  - **fusão:** casamentos e comércio misturam costumes;
  - **conquista:** o vencedor impõe a cultura e o vencido a mantém escondida;
  - **esquecimento:** um costume perde a origem, que só o deus e a crônica lembram.
- **O deus não edita culturas.** Ele só as influencia indiretamente, pelos efeitos que causa e pela leitura que os povos fazem deles.

### Progresso técnico

- **A sociedade evolui tecnicamente, se chegar lá sem se destruir.** O progresso não é garantido e não existe árvore de pesquisa escolhida pelo jogador.
- **Progresso é autonomia em relação ao deus.** Cada estágio muda a relação com ele:

  | Estágio | O que muda na moldura | O que muda na relação com o deus |
  |---|---|---|
  | 1. Coleta e abrigos | cabanas, fogueiras | dependência total da natureza, e o deus é tudo |
  | 2. Agricultura | plantações, aldeias fixas | a chuva vira questão de vida ou morte, e as preces aumentam |
  | 3. Pedra | casas e templos de pedra | o templo vira centro de poder e os sacerdotes ganham força |
  | 4. Metal | ferramentas e armas | as guerras ficam mais mortais |
  | 5. Escrita | registros, leis, escrituras | a doutrina se fixa, e o povo escreve a própria versão da história |
  | 6. Engenharia | irrigação, moinhos, muralhas, barcos | a irrigação torna a chuva menos necessária, e o povo passa a precisar menos do deus |

- **O teto é o estágio 6, a engenharia pré-industrial.** Fábricas e cidades grandes não cabem na moldura e tirariam o peso dos poderes. Ao chegar lá, a evolução continua, mas só social e cultural.
- **Como o progresso surge:** da necessidade (a fome leva à agricultura, a guerra às muralhas), de pessoas com traços como "curioso" ou "engenhoso", de períodos de paz e estabilidade, e da troca entre culturas (comércio, casamento, conquista).
- **O deus pode inspirar** com o sonho: dá a alguém a ideia do arado ou da irrigação. A ideia pode ser ignorada ou usada para o mal (o sonho do metal pode virar espadas).
- **O conhecimento vive nas pessoas e pode se perder.** Se o único ferreiro morre sem aprendiz, a vila perde o metal. Doenças e guerras podem fazer um povo regredir. A escrita é o grande marco porque reduz essa perda.
- **Ruínas guardam conhecimento.** Depois de uma extinção, o novo povo pode redescobrir técnicas nas ruínas da era anterior.
- **A escrita gera a crônica do próprio povo.** O jogador pode compará-la com a crônica do deus: "o deus nos deu a vitória sobre Toril", quando na verdade foi um terremoto natural.
- **O conhecimento enfraquece a ambiguidade.** Um povo que estuda o céu passa a prever eclipses, e o presságio perde força.

### O deus e a intervenção

- **O deus é invisível. Os habitantes veem só os efeitos.** A chuva cai, o raio atinge, a colheita prospera, mas ninguém vê a mão que fez isso.
- **O jogador tem seus poderes e usa quando quiser,** incluindo os destrutivos (dilúvio, raio, fogo). Não existe custo em recurso nem medidor de mana.
- Os poderes são **poucos, naturais e táteis**, no espírito do Terraglass: água, terra, fogo, clima, fartura.
- **O custo de intervir é a interpretação.** Cada ato é percebido e interpretado pelos habitantes, e essa interpretação muda a sociedade.
  - *Exemplo:* o jogador força a paz entre Ardem e Toril. Toril, que estava vencendo, entende que o deus protege os inimigos e guarda ressentimento. Ardem passa a acreditar que sempre será salva e deixa de se preparar. Uma geração depois, surge em Toril um culto que rejeita o deus de Ardem.
- **Graus de intervenção**, do mais sutil ao mais forte:
  1. **Sinal:** um presságio ambíguo.
  2. **Inspiração:** uma ideia que surge na mente de alguém, sem garantia de que será seguida.
  3. **Milagre:** um efeito visível e inegável.
  4. **Imposição:** forçar um resultado, como um acordo de paz.

  Quanto mais forte o grau, mais certo o efeito e mais intensa a reação da sociedade.
- Deixar acontecer é uma escolha legítima. A sociedade pode resolver seus problemas sozinha.

### Poderes

**Todos os poderes ficam disponíveis desde o início.** Não há progressão nem desbloqueio. A única exceção é **criar um novo povo**, que só existe com o mundo vazio (ver *Fim do mundo*).

| Família | Poder | Destrutivo? | Parece natural? | Uso típico | Leitura possível dos habitantes |
|---|---|---|---|---|---|
| Água | **Chuva** | não | sim | acabar com uma seca | "As preces foram ouvidas" ou "o tempo virou" |
| Água | **Seca** | sim | sim | punir, enfraquecer uma vila | "Estamos sendo castigados. O que fizemos?" |
| Água | **Dilúvio** | sim | pouco | destruição em grande escala | Fim de uma era, mito fundador |
| Céu | **Raio** | sim | sim, se isolado | atingir uma pessoa, uma casa, um exército | Castigo, mártir ou "foi azar" |
| Céu | **Presságio** | não | não | cometa, eclipse, um sinal no céu | Ninguém sabe o que significa, e todos opinam |
| Terra | **Erguer ou abrir terra** | depende | não | separar vilas, abrir passagem, criar uma fonte | Inegável: lugar sagrado ou proibido |
| Terra | **Terremoto** | sim | sim | derrubar construções | A terra está irritada, o deus está irritado |
| Terra | **Fogo** | sim | sim | queimar uma floresta ou uma plantação | Purificação ou maldição |
| Vida | **Fartura** | não | sim, se moderada | colheita ou caça abundante | Bênção, ou inveja da vila vizinha |
| Vida | **Cura** | não | pouco | salvar um habitante condenado | Milagre pessoal, nasce um devoto ou um profeta |
| Mente | **Sonho** | não | sim | pôr uma ideia na cabeça de alguém | "Tive uma visão", que pode ou não ser seguida |

- **Quanto o efeito parece natural** é uma escolha do jogador. Um efeito **ambíguo** pode passar por sorte, e a reação religiosa é fraca e dividida. Um efeito **inexplicável** deixa claro para todos que foi o deus, e a disputa passa a ser sobre o *porquê*. O jogador escolhe entre agir discretamente, sem levar o crédito, ou agir de forma inegável e provocar reação.
- **O grau vem do uso, não do poder.** O mesmo poder muda de grau conforme a intensidade, a precisão e a repetição:
  - **Sinal:** um raio solitário cai perto do templo.
  - **Milagre:** o raio atinge justamente o homem que tentou queimar o templo.
  - **Imposição:** toda vez que dois exércitos avançam, raios caem entre eles.
- **Imposição sem deus visível:** a imposição é usar um poder de modo tão insistente ou preciso que só um deus faria. A paz forçada pode ser uma tempestade que não para sobre o campo de batalha, um morro que surge entre as vilas ou os dois líderes tendo o mesmo sonho. Os habitantes cedem pelo caminho que escolherem.
- **Gesto tátil:** cada poder é um gesto na moldura. Por exemplo, arrastar uma nuvem sobre a plantação, tocar no céu sobre alguém para o raio, puxar a terra para cima ou segurar sobre uma casa para mandar um sonho. **A intensidade vem do gesto** (quanto mais tempo segurando, mais forte), sem menus.
- **Atingir uma pessoa específica é permitido.** O peso vem da reação: a vítima vira mártir para uns e castigado para outros, e a família guarda essa memória por gerações.
- **Não existe praga.** As doenças são **eventos naturais** do mundo, que o deus pode curar ou ignorar.

### Religião e preces

- A religião nasce da **interpretação dos efeitos** sem autor visível. Como o deus é invisível, os habitantes não conseguem distinguir com certeza uma chuva natural de uma chuva divina. Também podem atribuir ao deus tragédias que ele não causou.
- **As preces são o principal canal de informação do jogador.** É por elas que ele fica sabendo das necessidades: "Que a chuva volte antes da colheita", "Proteja meu filho na guerra", "Por que nos abandonaste?".
- **Existe um ponto cego:** grupos que não rezam não aparecem nas preces. Os problemas deles chegam tarde ao jogador.
- **O silêncio do deus tem consequência.** Se o deus nunca responde, a religião muda com o tempo, mesmo sem um medidor de fé (detalhes abaixo).
- **Eventos naturais existem.** Secas, tempestades, terremotos e doenças acontecem sem o deus. Uma chuva natural depois de uma prece vira **falso milagre**, e um terremoto natural vira **castigo** que o deus não deu. O deus leva crédito e culpa pelo que não fez.
- **Várias crenças surgem sozinhas.** Nenhum credo é definido de antemão: eles nascem das explicações que competem entre si sobre o mesmo deus.
- **Os sacerdotes falam pelo deus.** Eles interpretam a vontade divina e podem distorcê-la. A religião tem peso político, e o jogador pode ver o próprio nome sendo usado para justificar coisas que nunca pediu.

  *Exemplo:* depois de anos de silêncio, o sacerdote de Ardem anuncia que o deus proíbe negociar com Toril. O deus nunca disse isso. A guerra começa em nome dele. O jogador pode desmentir com um sinal, mas sem palavras, e os habitantes leem o sinal como quiserem.

### Silêncio do deus

- **Três tipos de silêncio:**
  - **a uma prece:** a mãe pede a cura do filho e ele morre. É uma dor pessoal, que marca uma família.
  - **prolongado:** o deus não age em lugar nenhum por anos. Muda a sociedade inteira.
  - **seletivo:** o deus atende uma vila e ignora outra. Gera inveja, rivalidade e teologias opostas. Surge naturalmente, porque o deus não consegue atender todos.
- **A fé é de cada pessoa.** Não existe medidor global. Cada habitante tem a própria relação com o deus, moldada pelo que viveu: uma prece atendida, um milagre visto, uma perda depois de rezar. O jogador percebe pelo **comportamento**: quem vai ao templo, quem reza, quem zomba de quem reza. Essa relação passa pela família e pode atravessar gerações.
- **A sociedade explica o silêncio.** A explicação que prevalece depende dos traços e da cultura de cada vila, e duas vilas diante do mesmo silêncio podem seguir caminhos opostos:

  | Explicação | O que provoca na sociedade |
  |---|---|
  | "Nós pecamos." | Penitência, oferendas, regras mais rígidas, busca de culpados |
  | "Ele está nos testando." | Fé mais resistente e orgulho dos que "aguentaram" |
  | "Ele está dormindo ou partiu." | Religião vira tradição, a fé perde força |
  | "Ele favorece os outros." | Inveja e conflito com a vila atendida |
  | "Os sacerdotes mentem." | Revolta contra o templo, novos líderes |
  | "Ele não existe." | Céticos, uma sociedade mais prática e menos religiosa |

- **O custo do silêncio é a cegueira.** Quando as pessoas deixam de rezar, chegam menos preces, e o jogador sabe menos sobre o que o povo sente e quer. O ponto cego cresce, e as preces que restam vêm dos mais devotos, o que distorce a visão do jogador. Ele continua **vendo** o mundo na moldura: as preces não são os olhos dele, são a forma de saber o que as pessoas sentem e querem.
- **Responder a tudo também tem custo.** Um deus sempre presente gera dependência (as vilas deixam de se preparar), sacerdotes poderosos demais e exigências cada vez mais frequentes e banais. Nenhum extremo é ótimo: a escolha é sobre que tipo de povo o jogador quer ver.
- **A religião pode morrer.** Uma sociedade pode deixar de acreditar por completo, e as preces param de vez. É um estado válido do jogo.
- **O retorno do deus.** Depois de um longo silêncio, um único milagre tem enorme impacto e pode gerar um renascimento religioso, um profeta ou uma nova era. Não é recompensa, é consequência narrativa.

### Tom

- **Liberdade total.** A sociedade pode chegar a qualquer extremo que a sua lógica produza: fanatismo, caça a culpados, punições, sacrifícios, guerras santas. O jogo não suaviza as consequências.

### Vínculo com habitantes

- O jogador acompanha uma **linhagem**, não só um indivíduo. Quando o personagem acompanhado morre, o acompanhamento passa para os descendentes.
- O jogo **sugere quem vale acompanhar** ("esta mulher acabou de ter uma visão"), para o jogador não precisar garimpar a população.

### Tempo

- Existe ciclo de dia e noite, com **cerca de 45 minutos reais por dia de jogo** no ritmo normal (30 de dia e 15 de noite).
- Os **anos são curtos**, com cerca de 40 dias (4 estações de aproximadamente 10 dias), para que a sociedade evolua num tempo de uso real.
  - Com a moldura aberta 8 horas por dia, passam uns 10 dias de jogo por dia de trabalho, um ano de jogo a cada 4 dias de trabalho e uma geração (uns 20 anos) a cada 3 meses de uso.
- **O ritmo lento é o padrão.** As velocidades maiores (como 10x e 50x) servem para quando o jogador está olhando ativamente.
- O jogador pode **saltar até o próximo acontecimento relevante**.

### Atenção e sinais

- Os acontecimentos têm três camadas de intensidade:
  - **Ambiente:** o cotidiano, só para olhar.
  - **Nota:** algo mudou e entra na crônica.
  - **Chamado:** algo pede a atenção do deus.
- Os chamados aparecem como **sinais visuais discretos dentro da moldura**: uma fogueira acesa no templo, fumaça subindo, gente olhando para o céu. O jogador percebe com o canto do olho, sem interromper o trabalho.
- **Os sinais esperam.** Uma prece continua visível até ser atendida ou perder importância. O jogo não pausa sozinho.
- As histórias devem ser **legíveis num relance**: o túmulo novo no morro, a casa abandonada, o templo que cresce.

### Ausência e retorno

- Quando a moldura fica fechada, o mundo **avança até um teto de tempo** e depois espera.
- Ao voltar, o jogador recebe uma **crônica** do que aconteceu, contada como um livro de história: "No inverno do ano 12, a vila de Ardem passou fome. Três famílias migraram para o sul."
- Ficar ausente tem consequência, mas não vira castigo. Uma exceção é deliberada: a extinção também pode acontecer durante a ausência (ver *Fim do mundo*).

### Fim do mundo

- **A extinção é real.** A população pode acabar por doença, fome, guerra, evento natural ou ação do deus. Não há volta nem salvamento automático.
- **A extinção pode acontecer durante a ausência.** Liberdade total: o jogador pode voltar e descobrir pela crônica que o povo acabou.
- **"Os últimos" são um chamado.** Quando restam poucos habitantes, o mundo mostra o sinal mais intenso da moldura. Se o jogador estiver presente, tem a chance de decidir se intervém ou deixa acabar.
- **Depois da extinção, o mundo fica vazio e continua vivo.** A natureza retoma o espaço: a floresta cobre a vila, o templo vira ruína, os túmulos ficam. O jogador pode contemplar o mundo vazio pelo tempo que quiser.
- **A crônica se fecha como um livro** ("A Primeira Era") e fica guardada para ser relida.
- **Criar um novo povo** é um poder que **só existe com o mundo vazio**. O deus nunca cria pessoas num mundo habitado, para preservar a autonomia e o peso da população.
- **O novo povo encontra as ruínas do anterior.** O mundo não é zerado. Os novos habitantes criam explicações para templos em ruínas e lugares marcados ("aqui viviam gigantes", "um povo que o deus destruiu"). A memória do mundo atravessa eras, e só o deus lembra de tudo.
- **Um quase fim também é possível.** O deus pode destruir quase tudo e poupar alguém, como num dilúvio que deixa uma família viva. Isso surge do uso preciso dos poderes existentes, sem poder especial.
- **Existe um só mundo.** O jogador pode abandonar o mundo atual, mesmo vivo, e começar outro do zero, mas nunca tem mais de um mundo ao mesmo tempo.

---

## Decisões tomadas por coerência

O autor pediu para não decidir mais nada e deixar o restante seguir a linha já definida. As decisões abaixo foram tomadas assim, aplicando seis princípios que atravessam todas as escolhas dele:
- **liberdade total** para o mundo e para o deus;
- **autonomia** dos habitantes;
- **o deus só aparece pelos efeitos**;
- **a consequência vem da interpretação**, não de recursos;
- **a memória do mundo** como fonte de sentido;
- **contemplação** sem metas.

Todas estão abertas a revisão.

### Começo do mundo

- O jogo começa com a **região já formada e vazia**: morro, praia, lago, floresta.
- O primeiro gesto do jogador é **criar o primeiro povo**, usando o mesmo poder que recria a humanidade depois de uma extinção. Começo e recomeço funcionam igual.
- O primeiro povo é um **pequeno grupo de coletores** (cerca de uma dúzia de pessoas, uma família estendida) no **estágio 1**, sem vila nem religião. A religião nasce das primeiras coisas inexplicáveis que eles virem.

### Ausência

- Com a moldura fechada (à noite, no fim de semana, nas férias), o mundo **segue no ritmo normal até o teto de um ano de jogo**, uma volta completa das estações, e então espera.
  - Uma noite fechada avança cerca de 20 dias de jogo. Um fim de semana já chega perto do teto. Férias longas param no teto.
- Dentro do teto vale a liberdade total: tudo pode acontecer, inclusive a extinção. A crônica conta o período.

### Limite do espaço

- **A moldura não cresce.** O espaço e os recursos são finitos, e essa é uma fonte natural de drama.
- O excesso de população gera **fome, disputa por terra, guerra e migração dentro do mundo**.
- **A borda do mundo é o fim do mundo.** Grupos podem partir em expedição além da borda e **nunca voltam**. O jogo não mostra para onde vão. Os que ficam criam mitos sobre o que existe além, e o jogador sabe tanto quanto eles.

### Mundo abandonado

- Ao abandonar um mundo, o jogador perde o mundo, mas **a crônica fica guardada** para ser relida, numa estante com as crônicas de todos os mundos e eras anteriores. Ela é a única memória que sobrevive.

### Sem possessão

- O jogador **não controla habitantes**. Controle direto quebraria a autonomia e a regra de que o deus só aparece pelos efeitos.
- Em vez disso, ele pode **acompanhar de perto** um habitante: a moldura segue a pessoa, e o jogador vê o que ela faz, suas relações e suas preces. É observação, não controle. O único poder sobre a mente continua sendo o sonho.

### A moldura

- **Tamanho:** a moldura pode ser arrastada e redimensionada, de um canto discreto da tela até uma janela grande para observar com calma.
- **Aproximar:** o jogador aproxima a vista para ler o mundo. De longe, vê vilas e sinais; de perto, vê pessoas, nomes e preces.
- **Leitura:** passar o cursor sobre um habitante, um lugar ou um sinal mostra o essencial: nome, traço marcante, prece ou o que aconteceu ali.
- **Em público:** a simulação nunca é suavizada. O jogador conta com dois recursos que só afetam o que aparece na tela:
  - **esconder a moldura na hora** com um gesto ou atalho;
  - **modo discreto** opcional, que não mostra as cenas mais pesadas em detalhe, mas sempre as registra na crônica.

---

## Menor conjunto que entrega a essência

1. Uma moldura com um mundo pequeno: uma região vazia onde o jogador cria o primeiro povo, que pode formar uma vila e depois duas ou três.
2. Um grupo inicial de coletores que cresce até algumas dezenas de humanos, com famílias, traços, necessidades básicas (comida, abrigo, relações) e memória. O progresso vai do estágio 1 (coleta) ao 2 (agricultura).
3. Um ou dois tipos de conflito que surjam sozinhos, como escassez e disputa entre vilas.
4. Preces como sinais visuais e canal de informação.
5. Seis poderes (chuva, raio, fogo, fartura, erguer terra e sonho), usados em graus de sinal, milagre e imposição, sempre com reação da sociedade.
6. Uma linhagem acompanhada.
7. Ritmo lento por padrão, uma velocidade maior e o salto até o próximo acontecimento.
8. A crônica do mundo.

Se esse recorte não for interessante de acompanhar por algumas horas, nada que vier depois salva a experiência. É o primeiro teste da proposta.

---

## Riscos a acompanhar

- **Virar papel de parede.** Como companhia, o mundo disputa atenção com o trabalho. Se nada legível acontecer num relance, o jogador deixa de olhar.
- **Um WorldBox lento sem graça.** O WorldBox prende pela velocidade e pelo caos. Aqui, o que segura a atenção precisa ser outra coisa: histórias pequenas, preces e o retorno recompensador. Se isso falhar, o jogador acelera tudo e o formato perde o sentido.
- **Diferenciação.** Se a relação entre o povo e o deus for rasa, o jogo vira "WorldBox mais lento" ou "Terraglass com bonequinhos".
- **Repetição.** Eventos genéricos (seca, doença, briga) repetidos sem contexto. A memória do mundo é a principal defesa.
- **Poder destrutivo sem peso.** Como o jogador usa os poderes quando quiser, a reação da sociedade precisa ser forte o bastante para que destruir tenha significado e não seja só um brinquedo.
- **Estagnação.** Um mundo estável e sem mudança (vila em paz, com comida, repetindo os mesmos dias) é um fim silencioso, pior que a extinção. O mundo precisa de forças internas que sempre perturbem o equilíbrio: eventos naturais, traços como a ambição e sacerdotes.
- **Perda durante a ausência.** Voltar e encontrar extinto um povo acompanhado por meses pode frustrar a ponto de o jogador abandonar o jogo. A crônica precisa tornar esse fim compreensível e marcante, e não arbitrário.
- **Mundo sem fé.** Se a religião morrer em todo o mundo, o jogador fica sem preces. É preciso garantir que esse estado continue interessante de acompanhar, e não que pareça que o jogo acabou.
- **Tom sem limites.** Com liberdade total, sacrifícios e caça a culpados podem acontecer na moldura que fica aberta enquanto o jogador trabalha, inclusive à vista de outras pessoas. Isso afeta o público e a classificação indicativa do jogo.

---

## Questões em aberto

Nenhuma questão do modelo funcional está aberta. O próximo passo é revisar as decisões tomadas por coerência e validar a experiência com o menor conjunto de funcionalidades.

## Fora do escopo

Toda discussão técnica: stack, linguagem, framework, arquitetura, banco de dados, infraestrutura e implementação.
