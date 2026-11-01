# Relatório da sessão A: simulação só em texto

*Fase 0, 01/11/2026. Pergunta: a simulação produz histórias que valem a pena ler?*

## Resposta curta

**Sim, com ressalvas.** As quatro crônicas de 100 anos têm arcos que dá vontade de seguir:
- um eclipse vira a primeira fé;
- uma rixa racha a família original;
- a primeira guerra deixa um lugar com dois nomes, um para cada povo;
- o saber de plantar passa de um povo a outro por casamento;
- um sacerdote proíbe tratar com os vizinhos "em nome do deus";
- um costume sobrevive à lembrança de por que existe.

Com intervenção, a diferença aparece de imediato: o povo rebatiza o deus a cada ato forte e passa a guerrear em nome do novo nome.

As ressalvas: da metade em diante, a crônica fica repetitiva (preces atendidas por acaso, ciclos de ataque e trégua). Os personagens raramente reaparecem. E a população tende a se fragmentar em povos pequenos demais. Na minha leitura, 3 das 4 crônicas são interessantes do começo ao fim do primeiro terço e ainda legíveis no resto. Detalhes em "Avaliação honesta".

## Como rodar

O executável de console do Godot 4.7.2 está no caminho da seção "Ambiente" do documento técnico. O script `ferramentas/godot.sh` já usa esse caminho e filtra o ruído de saída do motor.

```bash
cd prototipos/simulacao
ferramentas/gerar_todas.sh                      # gera as 4 crônicas, duas vezes cada, e compara
ferramentas/godot.sh res://ferramentas/gerar.gd -- 7 - cronicas/teste.md        # uma semente qualquer
ferramentas/godot.sh res://ferramentas/gerar.gd -- 1 cenarios/semente1-intervencoes.txt saida.md
ferramentas/godot.sh res://ferramentas/testar_gramatica.gd   # casos difíceis de concordância
ferramentas/godot.sh res://ferramentas/sondar.gd -- 1 2 3 4 5 # população por década e contagem de eventos
```

## O que foi entregue

| Caminho | O que é |
|---|---|
| `nucleo/` | O núcleo, em GDScript puro (`RefCounted`, sem nós nem cenas). Usa `preload` em vez de `class_name`, para poder ser copiado para `jogo/` sem mudanças. |
| `nucleo/mundo.gd` | A simulação: tempo, zonas, pessoas, grupos, economia, sociedade, conflito, religião, memória e os 6 poderes. |
| `nucleo/pessoa.gd`, `grupo.gd`, `zona.gd`, `evento.gd` | Os dados. O evento é estruturado: tipo, participantes, lugar, ano/dia/hora, causa (natural, social ou divina), importância e dados. |
| `nucleo/cronista.gd` | Lê os eventos, escolhe o que importa a cada ano e escreve a crônica. |
| `nucleo/gramatica.gd` | Artigos, contrações (do, na, à, pelo), concordância de gênero e número, números por extenso e um pequeno motor de modelos de frase. |
| `nucleo/nomes.gd` | Nomes por sílabas de cada cultura. Um povo novo herda as sílabas do povo mãe e troca algumas. |
| `nucleo/cenario.gd` | Leitor do arquivo de cenário do deus. |
| `cenarios/semente1-intervencoes.txt` | Cenário com 8 intervenções, que usam os 6 poderes. |
| `cronicas/semente-1.md`, `-2.md`, `-3.md` | Crônicas de 100 anos sem intervenção. |
| `cronicas/semente-1-intervencoes.md` | Crônica de 100 anos da semente 1 com o cenário. |
| `cronicas/*.resumo.txt` | Tempos, contagens e o que entrou em cada crônica, por tipo de evento. |
| `ferramentas/` | Scripts de linha de comando (`extends SceneTree`): gerar, sondar, testar a gramática, diagnosticar. |

## O que foi implementado

**Tempo.** Cada passo é 1 hora de jogo. O dia tem 24 passos e o ano tem 40 dias em 4 estações. Para caber no orçamento de CPU, quase nada roda a cada hora:
- **a cada hora:** tempestades e comandos do deus;
- **duas vezes por dia:** coleta (8h) e refeição (19h);
- **uma vez por dia:** a vida de cada pessoa;
- **a cada 5 dias:** casamentos, rixas, migrações e ensino;
- **por estação e por ano:** clima e envelhecimento.

**Mundo.** Quatro zonas: praia, lago, floresta e morro.
- Cada uma tem comida, água e madeira, que se renovam conforme a estação e a água disponível.
- Cada uma tem também terra cultivável e risco de raio próprios.
- Eventos naturais: seca (todo o mundo, mas o lago resiste), tempestade com raios, inverno rigoroso, doença por grupo, ano de fartura e eclipse. O eclipse é o presságio natural.

**Pessoas.**
- Começo: 12 coletores, uma família estendida (avós, três filhos casados e netos), na floresta.
- Cada pessoa tem nome, idade, sexo, pai, mãe, cônjuge, filhos e 2 traços de uma lista de 10: ambicioso, pacífico, rancoroso, curioso, devoto, desconfiado, generoso, engenhoso, corajoso e medroso. Traços opostos se excluem, e os filhos tendem a herdar os dos pais.
- Cada pessoa tem também memória dos eventos vividos, saúde, fé pessoal (de -1 a 1), rancores contra outras pessoas e o que sabe (agricultura).
- Necessidades:
  - **comida:** fome tira saúde, primeiro das crianças e dos velhos;
  - **abrigo:** no inverno, quem fica sem cabana perde saúde;
  - **relações:** solteiros procuram par no grupo e, se não acham, nos vizinhos.
- Ciclo de vida: nascimento, gravidez, morte no parto, casamento sem irmãos nem pais, envelhecimento e morte por idade.

**Sociedade.**
- **Liderança:** o líder é escolhido por idade e traços. Um ambicioso preterido guarda rancor.
- **Separação de grupos**, de três formas:
  - **migração:** quando falta comida ou o grupo cresce além da zona;
  - **briga:** um rancor forte entre duas pessoas;
  - **cisma:** uma explicação religiosa que divide o grupo.

  O fundador leva a família e quem pensa como ele. O povo novo herda costumes e crenças e ganha nomes com sonoridade derivada.
- **Coletores com fome** levantam acampamento e mudam de zona.
- **Sem lugar para onde ir**, alguém pode partir além da borda do mundo, e o povo cria um mito sobre o que existe lá.
- **Conflito:** a hostilidade entre grupos cresce com a inveja durante a fome, a disputa da mesma zona e os éditos de sacerdotes. Vêm então ataques com mortos e saque, tréguas e conquista do vencido pequeno.
- **Progresso:** a agricultura é descoberta pela necessidade (fome recente) e por pessoas engenhosas ou curiosas.
  - O saber vive em quem o tem e é ensinado devagar. O generoso ensina mais; o desconfiado e o ambicioso, menos.
  - O grupo chega ao estágio 2 quando gente suficiente sabe plantar.
  - Se o último que sabe morre antes disso, o conhecimento se perde.
  - O saber também viaja por casamento.

**Religião.**
- Fatos sem explicação deixam impressões em quem os vê, e cada pessoa reage conforme os traços. O devoto se impressiona mais; o desconfiado, menos ou ao contrário; o rancoroso e a família ferida pelo deus se voltam contra ele.
- Esses fatos são o eclipse, o raio que mata, a seca, a fome, a doença e todo ato do deus.
- Quando a soma passa de um limiar, nasce a crença: alguém (o "profeta") dá ao deus um nome tirado do fato que mais impressionou. Exemplos: «o Que Apaga o Sol», «o Que Leva», «o Que Nega», «o Que Rega».
- Um fato forte depois disso pode **rebatizar** o deus. É assim que as culturas divergem: o mesmo deus vira «o Olho Escuro» num povo e «o Que Apaga o Sol» no vizinho.
- **Preces** nascem de necessidades reais: seca, fome, filho doente, frio, ataque. Cada prece vira um evento com autor e, se houver, a pessoa por quem se reza.
  - Se a necessidade passa, a prece é tida como atendida. Quase sempre é um **falso milagre**, e a crônica diz isso.
  - Se não passa, ou se o filho morre, fica sem resposta, e a fé de quem rezou despenca.
- **Silêncio prolongado:** depois de várias preces sem resposta, o grupo explica o silêncio pelos traços de quem está vivo. As seis explicações do documento funcional têm consequência:
  - **"nós pecamos":** oferendas e busca de culpado (expulso ou apedrejado);
  - **"ele está nos testando":** fé mais forte;
  - **"ele está dormindo":** a fé esfria;
  - **"ele favorece os outros":** rancor contra o povo atendido;
  - **"os sacerdotes mentem":** o sacerdote é deposto, com cisma dos céticos;
  - **"ele não existe":** as preces param, com cisma dos fiéis.
- **Sacerdotes** surgem entre os de fé alta e emitem **éditos** que o deus nunca deu, como proibir trato com outro povo. A crônica aponta a mentira.

**O deus.** Os 6 poderes do menor conjunto funcionam como comandos de cenário. Todos são interpretados pelos habitantes.
- **chuva:** acaba a seca só naquela zona. Os vizinhos que continuam secos sentem inveja.
- **raio:** em alguém da zona, ou no líder. O povo lê a morte como castigo, martírio ou azar, conforme quem morreu. A família fica ferida, e os descendentes nascem com menos fé.
- **fartura:** a zona e o celeiro se enchem.
- **fogo:** a zona queima e há mortos. O povo lê o fogo como purificação ou maldição, e a maldição empurra o povo para longe.
- **erguer terra:** aparece um lugar sagrado, e uma trégua é imposta a povos em guerra.
- **sonho:** dá a ideia da agricultura a alguém, que pode ignorá-la, ou uma visão que faz um sacerdote.

**Memória e cultura.**
- **Lugares ganham nome** por fome, raio, chuva milagrosa, fartura, cinzas, pedra erguida, vitória, luto ou trégua. Cada povo dá o próprio nome: o mesmo chão é "Lago da Vitória" para um e "Lago do Luto" para o outro.
- **Costumes nascem de eventos:**

  | Evento | Costume |
  |---|---|
  | fome | estocar comida |
  | seca com mortes | não desperdiçar água |
  | seca atendida | festa da chuva |
  | raio | não sair na tempestade |
  | epidemia | queimar os mortos |
  | derrota | treinar com lanças |
  | silêncio lido como pecado | oferendas |

- **Esquecimento:** quando morre o último que cresceu ouvindo os que viveram a origem, o costume continua, mas "ninguém sabe mais dizer por quê". A crônica registra isso.

**Crônica.**
- **Seleção:** a cada ano, o cronista dá nota aos eventos. A nota soma a importância do evento, um bônus de novidade (primeira vez no mundo ou no povo) e uma penalidade por repetição recente.
- **Orçamento:** até 5 eventos por ano. Atos do deus, separações, conquistas, fusões e crenças sempre entram.
- **Fusões:** alguns eventos são contados juntos, como a prece com a sua resposta, a fome do início ao fim e os dois nomes de um mesmo lugar.
- **Anos quietos** viram uma linha só, e a cada 10 anos há um censo.
- **O texto** sai de modelos com variações, escolhidas por um gerador próprio do cronista. Assim, mudar a gramática não muda o mundo.
- **Contexto:** a crônica usa o nome que o deus tinha naquele momento, o nome que o povo deu ao lugar e a referência ao passado ("A seca voltou, como no ano 36"; "Veio a pior fome que o mundo tinha visto").
- **Epílogo:** cada povo vivo, de onde nasceu, como chama o deus, os costumes (e se a origem foi esquecida), os povos extintos e os lugares com nome.

## O que ficou de fora ou simplificado

- **Uma só cultura em números.** Das seis dimensões culturais, só a violência existe como número. Devoção e partilha aparecem indiretamente (fé pessoal média, costume de estocar). Poder, mortos e estranhos não existem.
- **Nada espacial.** Não há posições nem caminhos: a zona é o lugar. Não há construções além de "abrigos" contados, nem templos.
- **Graus de intervenção.** Sinal, milagre e imposição não são escolhidos no comando. O grau sai do contexto: chuva na seca ou fora dela, raio que mata ou que só queima a terra. Não há intensidade.
- **Sem linhagem acompanhada.** A crônica marca os descendentes da matriarca, mas não segue uma linhagem como fio narrativo.
- **Sonho estreito.** O sonho só trata de agricultura ou de visão religiosa.
- **Estágios.** Não há estágios além do 2, nem ruínas, nem fim de era com novo povo. Se todos morrem, a crônica fecha a "Primeira Era", mas isso não aconteceu nas sementes entregues.
- **Sem persistência.** Não há salvamento nem retomada (`user://`). O avanço durante a ausência é o mesmo laço sem gráfico, e a velocidade cabe com folga.
- **Dois mecanismos que nunca se viram nas crônicas entregues:**
  - **conhecimento perdido:** nas sementes 1 a 3, a agricultura se espalhou antes que o último que sabia morresse;
  - **expedição além da borda:** exige todas as zonas cheias e fome ao mesmo tempo.

  Os dois apareceram em testes com outras sementes e versões.

## Tempos

Medidos dentro do Godot com `Time.get_ticks_usec()`, sem contar a partida do motor. O processo inteiro leva cerca de 2 s por crônica, incluindo a partida.

| Crônica | 1º ano | Ano mais lento | 100 anos | Escrever a crônica | População no ano 100 |
|---|---|---|---|---|---|
| Semente 1 | 0,002 s | 0,026 s | 1,0 s | 0,28 s | 121 em 4 povos |
| Semente 2 | 0,002 s | 0,030 s | 1,3 s | 0,45 s | 210 em 5 povos |
| Semente 3 | 0,002 s | 0,021 s | 0,7 s | 0,14 s | 55 em 4 povos |
| Semente 1 com o deus | 0,002 s | 0,025 s | 1,1 s | 0,39 s | 124 em 4 povos |

O ano mais lento, com cerca de 200 pessoas, leva 0,03 s, cerca de 100 vezes abaixo da meta de "poucos segundos". O teto de ausência (1 ano) custa nada. Os valores exatos estão em `cronicas/*.resumo.txt`.

## Critérios de aceite

| Critério | Situação | Evidência |
|---|---|---|
| Mesma semente, mesma crônica | **Atendido** | `ferramentas/gerar_todas.sh` gera cada crônica duas vezes, em processos separados, e compara byte a byte. As quatro saíram iguais. Todo sorteio usa um único `RandomNumberGenerator` com semente fixa (nunca `randi()` global, `shuffle()` ou `pick_random()`). O cronista tem gerador próprio, derivado da semente. |
| 1 ano em poucos segundos | **Atendido** | 0,002 a 0,03 s por ano (tabela acima). |
| Nascimentos e mortes que importam | **Atendido nas 4** | A primeira criança de cada povo, filhos de líderes, nascidos em plena fome e filhos de casais de povos diferentes. Mortes de fundadores, líderes e sacerdotes, morte no parto, o filho que morre depois da prece da mãe ("e Vitorem nunca mais rezou") e o culpado apedrejado. |
| Uma separação de grupos | **Atendido nas 4** | Semente 1: 2 brigas e 2 migrações. Semente 2: 4 brigas e 2 migrações. Semente 3: 6 brigas e 2 migrações. Com o deus: 2 brigas, 4 migrações e 1 cisma. |
| Um conflito | **Atendido nas 4** | Ataques narrados: 5, 20, 15 e 19. Tréguas e conquistas também aparecem. |
| O surgimento de uma crença | **Atendido nas 4** | Sem o deus, a fé nasce de coincidências naturais: da febre («o Que Leva», semente 1) e da fome («o Que Nega», sementes 2 e 3). Com o deus, nasce da chuva no meio da seca («o Que Rega»). |
| Um costume nascido de um evento | **Atendido nas 4** | De 8 a 13 costumes narrados por crônica, cada um com a origem. Exemplo: "Desde a morte de Lomiem, ninguém em Zeor chega perto do lago em dia de tempestade." |
| As 3 sementes visivelmente diferentes | **Atendido** | Semente 1: um deus da febre, um mundo que fica pacífico por 70 anos, e a primeira morte em guerra só no ano 70. Semente 2: sacerdotes que proíbem trato com vizinhos (10 éditos) e uma era de guerras e conquistas. Semente 3: muitas rixas, povos que nascem e morrem (5 extintos, entre eles o povo original) e um mundo que termina com só 55 pessoas. |

## Avaliação honesta

### As crônicas são interessantes?

**Os primeiros 30 a 50 anos são bons de ler em todas as sementes.** Cada ano traz algo novo: a primeira criança, a primeira fé, a primeira prece, a primeira separação, a primeira roça, a primeira guerra. A crônica nomeia tudo isso como "primeiro", o que dá ritmo. A família original tem nomes que voltam: a matriarca que funda, o filho que racha o grupo, a filha que leva o saber de plantar para os vizinhos.

**A crônica com intervenção é a mais interessante**, e isso é uma boa notícia para o jogo. Cada ato do deus produz uma leitura clara:

> No verão do ano 28, do céu limpo, um raio caiu no lago e matou Mik, que guiava Zeor. Ninguém em Zeor teve dúvida: era castigo. Depois disso, Zeor deixou de chamar o deus de «o Que Rega» e passou a chamá-lo de «o Senhor do Trovão». Zeor passou a acreditar que o Senhor do Trovão castiga quem duvida, e que Mik tinha duvidado. Nasceu ali um costume: quando o céu escurece, ninguém em Zeor sai de casa. Lembram de Mik.

No ano 45, a chuva divina cai depois da prece de Linut, e o povo da floresta, que tinha sido esquecido na seca do ano 18, troca o nome do deus para «o Que Rega». Pela primeira vez, a crônica diz "Dessa vez, tinha sido mesmo o deus". O contraste entre milagre verdadeiro e falso milagre funciona.

**O melhor achado é a voz do cronista que sabe a verdade.** O deus é o único que conhece os fatos, e a crônica comenta:
- "O deus nada fez: o crédito era de graça";
- "Era vontade de Rue, não do deus";
- "O que aconteceu no ano 11, só a crônica guarda".

Isso dá ao texto um tom próprio e encarna o diferencial do documento funcional: o povo interpreta, o deus sabe.

### Que tipos de história surgiram

- **Fundação e cisão:** a família que vira dois povos por rixa ou por fome, e a árvore de culturas no epílogo.
- **Fé por coincidência:** a febre que passa depois da prece e a seca que acaba depois do pedido. A religião nasce sozinha, sem o deus, como o documento pede.
- **A dor da prece sem resposta:** a mãe que reza pelo filho, o filho morre, e ela "cuspia no chão quando falavam do deus".
- **Política religiosa:** o sacerdote que inventa proibições, a guerra "em nome do Que Apaga o Sol" e o sacerdote acusado de mentir e deposto.
- **Divergência cultural:** o mesmo deus com três nomes em três povos, depois de um eclipse ou de um raio. Lugares com dois nomes.
- **Esquecimento:** a festa da chuva que continua sem que ninguém saiba por quê.
- **Guerra e conquista:** vencidos levados para o povo vencedor, "guardando seus costumes em segredo".
- **Fomes catastróficas:** "Veio a pior fome que o mundo tinha visto".

### O que se repete demais

1. **Preces atendidas por acaso.** De 14 a 20 por crônica, quase sempre no mesmo molde: seca ou febre, prece, "a chuva voltou", "o deus nada fez". As primeiras são ótimas; a décima cansa. As variações de frase não bastam: falta consequência diferente a cada vez.
2. **O ciclo ataque e trégua** depois do ano 60 nas sementes 2 e 3. Já pus "A guerra entre X e Y continuou" e reduzi as tréguas automáticas, mas as guerras ainda são uma sequência de batalhas iguais. Falta uma guerra com começo, meio e fim (motivo, campanha e desfecho).
3. **Morte de líderes e sacerdotes "dormindo, aos 52 anos".** É correto e importante, mas é frequente e sem contexto. Falta dizer o que a pessoa fez em vida.
4. **O eclipse domina a religião.** Ele rebatiza o deus em quase todas as sementes («o Que Apaga o Sol», «o Olho Escuro»). Ele também é a única fonte forte de "mistério" sem o deus.
5. **Fragmentação.** Povos de 3 a 8 pessoas nascem, guerreiam e somem em poucos anos. Isso confunde o leitor (Lion, Nies, Isor...) e dilui a identidade das culturas.
6. **Personagens rasos.** Os traços aparecem como epíteto ("Satora, a corajosa") e nas reações, mas raramente uma mesma pessoa tem um arco de vida visível na crônica.
7. **Costumes iguais em todos os povos.** Os povos filhos herdam tudo, e no ano 100 todos "fazem a festa da chuva, estocam comida e treinam com lanças". Falta a reforma (uma geração rejeitar o costume) e a diferenciação.

### Riscos confirmados para o jogo

- **A segunda metade de um mundo estável fica previsível.** É o risco de "estagnação" do documento funcional, que aqui aparece como repetição de guerras e preces. As forças internas que perturbam existem, mas são poucas.
- **O cenário fixo é cego.** Depois da primeira intervenção, o mundo diverge, e os comandos seguintes caem onde caírem. A fartura do ano 60, por exemplo, chegou depois da fome. No jogo isso não é problema, porque o jogador vê o mundo. Para testes automatizados, convém aceitar comandos condicionais ("na próxima seca", "no líder do povo X").

## Recomendações para a fase 1

1. **Manter a arquitetura.** Ela se pagou: núcleo puro, eventos estruturados como fonte única, cronista separado com gerador próprio e determinismo garantido por um só `RandomNumberGenerator`. O núcleo pode ir para `jogo/` como está. A moldura só lê `mundo.grupos`, `mundo.pessoas`, `mundo.zonas` e `mundo.eventos`, e chama `avancar_hora()`.
2. **Dar arco aos personagens.** Acompanhar uma linhagem (o menor conjunto pede isso) e deixar a crônica lembrar o que cada pessoa fez quando ela morre: "morreu Saut, que rezou pelo filho e nunca mais rezou".
3. **Transformar repetição em escalada.** A terceira seca atendida deve gerar algo novo: um ritual, um sacerdote mais forte, dependência ("deixaram de estocar água"). A décima prece deve virar "exigência banal", como o documento funcional prevê para o deus que sempre responde. Na crônica, agrupar eventos repetidos num resumo de período ("Nos anos 60, as preces por chuva viraram rotina").
4. **Guerras como episódios.** Dar a cada guerra motivo, campanha, desfecho e um nome ("a Guerra do Lago"), e contá-la como um parágrafo, não como uma linha por batalha.
5. **Segurar a fragmentação.** Exigir pelo menos uns 8 fundadores e reunir os grupos pequenos mais cedo. Talvez limitar a 3 ou 4 povos vivos no recorte da fase 1, que pede "uma vila e depois duas ou três".
6. **Diferenciar as culturas.** Mutar os costumes herdados (reforma e esquecimento ativo), implementar ao menos mais duas dimensões culturais (relação com estranhos e o que fazer com os mortos) e variar as fontes de mistério natural além do eclipse.
7. **Comandos condicionais no cenário,** para testes e regressão: "na próxima seca: chuva sobre o povo X".
8. **Preces como canal do jogador.** Os eventos `prece` já trazem autor, necessidade, alvo e o texto pode ser gerado. É exatamente o que a moldura precisa para os "chamados".
9. **Ler mais sementes.** Avaliei 3 sementes e um cenário. Antes de fechar a fase 1, vale gerar 10 sementes com `sondar.gd` e ler pelo menos o primeiro terço de cada uma.

## Formato do cenário

```
# comentário
ano 6, dia 22: chuva sobre a floresta
ano 28, dia 15: raio sobre o líder do lago
ano 12, dia 4, hora 3: sonho no lago
```

Poderes: `chuva`, `raio`, `fartura`, `fogo`, `erguer` (terra) e `sonho`. Zonas: `praia`, `lago`, `floresta` e `morro`. A palavra `líder` mira o líder do grupo que vive na zona. O dia vai de 1 a 40; a hora, de 0 a 23 (padrão: 12). Linhas que o leitor não entende geram aviso e são ignoradas.
