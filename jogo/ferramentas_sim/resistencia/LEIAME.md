# Teste de resistência: 1000 anos

5 sementes (1 a 5), cada uma por 1000 anos, sem intervenção do deus e com o deus caprichoso (um poder qualquer, em qualquer lugar e força, a cada 25 dias em média, a partir do ano 5: 1.600 gestos em 1000 anos). Um mundo por processo, 5 processos ao mesmo tempo. Quando o mundo fica vazio, o jogador cria um povo novo 10 anos depois.

- `resistencia.gd` roda um mundo e mede a cada 50 anos. As tabelas completas estão em `medidas/`, e a crônica dos últimos 200 anos de cada mundo em `cronicas/`.
- `resistencia_passos.gd` carrega o mundo do ano 1000 e mede passo a passo, como a apresentação usa o mundo.
- `resistencia_ciclo.gd` roda o fim do mundo e o recomeço. A crônica do período está em `ciclo-semente-2.md`.

## Depois do arquivo dos antigos (novembro de 2026)

Os eventos e os mortos de mais de 300 anos que a memória do mundo não usa mais foram para um arquivo à parte, ao lado do mundo salvo (veja "Os antigos" em `nucleo/API.md`). O mundo é o mesmo: nos 10 mundos de 1000 anos, as colunas de pessoas, povos e eventos são idênticas às de antes. `testar_antigos.gd` compara, a cada 50 anos, um mundo sem arquivar, um arquivando e um salvo e carregado (também no meio da virada do ano): mesma crônica, sorteio, passo, eventos e livros, em 3 sementes, inclusive com o caprichoso e com um fim do mundo no ano 550.

**Metas, no ano 1000, medidas sem outra carga na máquina** (`resistencia_passos.gd`, 2 execuções em 2 mundos):

| | Antes | Depois | Meta |
|---|---|---|---|
| Carregar | 1,4 a 2,2 s | **360 a 384 ms** | menos de 0,5 s |
| Memória do mundo (o núcleo, carregado) | 136 a 165 MB | **82 a 88 MB** | abaixo de 120 MB |
| Memória com a rotina da apresentação | — | 94 a 107 MB no dia; pico de 125 a 132 MB por alguns ms às 2h, quando a rotina refeita depois dos eventos do dia entra e a anterior ainda está sendo solta numa thread | |
| Mundo salvo (`mundo.txt`) | 9 a 11,5 MB | 4,5 a 5,3 MB, mais 6 MB no arquivo dos antigos | |
| Salvar (`salvar_async`, linha principal) | ~1 ms | ~1 a 3 ms | |
| Salvar (na thread) | 1,1 a 1,9 s | 0,5 a 0,6 s | |
| Ausência de 1 ano | 30 a 70 ms | 60 a 100 ms (o arquivamento diário entra nos passos) | |
| A virada do ano (a escrita da crônica) | 4,7 a 5,8 ms | ~4 ms, em duas fatias: 1h e 2h do dia 0 | 5 ms |

- **A rotina da apresentação também ficou menor:** planos e blocos fixos são soltos ao fim da montagem, as agendas das horas que passaram são soltas, e a rotina de amanhã montada às 23h (que é refeita na 1h) corta só as primeiras horas. Uma rotina com 250 pessoas passou de ~45 MB para ~20 a 30 MB.
- **O passo das 3h** (o arquivamento diário, no máximo 12 eventos por dia) fica entre 1 e 4 ms; houve picos isolados de 6 a 10 ms em passos variados, que mudam de lugar de uma execução para outra (a máquina).
- **Um mundo salvo antes do arquivo dos antigos** abre normalmente e arquiva o que já passou dos 300 anos aos poucos, até 12 eventos por dia, sem travar.

**As tabelas de 10 mundos, com o arquivo** (5 processos ao mesmo tempo, faixa entre as 5 sementes; medidas com o limite anterior de 30 eventos por dia):

**Sem deus:**

| Ano | Pessoas | Eventos | Arquivo (MB) | Salvar (ms) | Carregar (ms) | Ausência de 1 ano (ms) | Memória (MB) | Pico (MB) | Objetos |
|---|---|---|---|---|---|---|---|---|---|
| 100 | 2–128 | 341–1.803 | 0,1–0,5 | 18–73 | 6–33 | 2–18 | 30–35 | 75 | 1.883–3.727 |
| 250 | 149–288 | 1.711–7.763 | 0,4–2,1 | 68–373 | 30–180 | 21–51 | 34–56 | 109 | 3.584–11.593 |
| 500 | 184–258 | 9.835–17.894 | 2,5–3,8 | 407–478 | 195–313 | 32–67 | 61–81 | 184 | 13.460–19.842 |
| 750 | 206–271 | 19.545–27.966 | 3,8–4,5 | 462–607 | 295–362 | 60–79 | 81–93 | 211 | 19.174–22.451 |
| 1000 | 209–261 | 29.710–37.452 | 4,5–4,9 | 578–671 | 385–438 | 78–100 | 93–102 | 237 | 22.150–23.806 |

**Com o caprichoso** (a memória inclui a rotina, que cada poder monta para achar o alvo):

| Ano | Pessoas | Eventos | Arquivo (MB) | Salvar (ms) | Carregar (ms) | Ausência de 1 ano (ms) | Memória (MB) | Pico (MB) | Objetos |
|---|---|---|---|---|---|---|---|---|---|
| 100 | 23–230 | 902–2.044 | 0,2–0,6 | 46–135 | 18–70 | 5–43 | 33–45 | 75 | 2.582–4.159 |
| 250 | 111–229 | 4.652–7.789 | 1,3–2,2 | 159–289 | 101–170 | 17–38 | 50–63 | 118 | 7.498–11.595 |
| 500 | 128–190 | 12.621–16.711 | 2,9–3,6 | 358–595 | 234–303 | 42–62 | 72–84 | 178 | 14.746–17.582 |
| 750 | 210–258 | 21.769–26.749 | 3,8–4,5 | 505–571 | 313–372 | 53–70 | 90–100 | 216 | 18.243–21.465 |
| 1000 | 190–258 | 31.714–37.376 | 4,7–5,3 | 583–733 | 399–499 | 63–87 | 107–114 | 256 | 21.882–24.478 |

O "Pico" é o do processo de teste, que carrega uma cópia inteira do mundo ao lado do original para comparar os dois; no jogo, há um mundo só. "Salvar" é o `salvar()` síncrono, que agora inclui regravar o arquivo dos antigos quando passam de 300 linhas novas (de tempos em tempos); nos outros salvamentos, as linhas novas vão dentro do próprio mundo salvo.

O resto deste documento é a medição anterior, sem o arquivo dos antigos.

## Travamentos e erros

- **Nenhum erro, aviso ou vazamento** nos 10 mundos: nenhuma linha de erro do Godot na saída, e todos chegaram ao ano 1001.
- **Salvar e carregar dá o mesmo mundo**, a cada 50 anos, nos 10 mundos: a mesma crônica, o mesmo estado do sorteio e o mesmo passo.
- **Pior ano:** 0,10 s sem deus.
  - Com o caprichoso, chega a 0,58 s. Isso é custo do teste: sem a apresentação olhando, cada poder monta a rotina do dia na linha principal (~130 ms) para achar o alvo. No jogo, a rotina já está pronta.
- **Pior dia (24 passos seguidos):** de 16 a 43 ms, com 5 processos disputando a máquina.

**Passo a passo no mundo do ano 1000** (`resistencia_passos.gd`, 251 pessoas, 34 mil eventos, 2 anos de jogo, 3 execuções sem outra carga na máquina):

| | Ano 1000 | Ano 286 (regressão) | Limite |
|---|---|---|---|
| Pior passo | 4,7 a 5,8 ms, sempre na virada do ano (1h do dia 0, quando a crônica do ano é escrita) | 3,6 ms | 5 ms |
| Outros passos | até 5,4 ms numa execução, 4,0 a 4,7 nas outras (a 0h, com a preparação da hora seguinte) | | |
| Pior consulta | 1,8 a 2,9 ms, na primeira hora depois de carregar | 1,05 ms | 2 ms |
| Montagem da rotina, na thread | 119 a 164 ms | até 175 ms | — |
| `salvar_async`, linha principal | 1,2 ms | < 1 ms | — |

- **O que passa do limite:** em mundos de séculos, a virada do ano passa um pouco dos 5 ms, por causa da escrita da crônica. A consulta logo depois de carregar também passa, mas é um momento de carregamento.
- **O que não cresce:** o resto do custo acompanha a população, não a história. Nenhuma função do dia percorre a história inteira; a mais cara (`_novo_ano`) fica abaixo de 1 ms.
- **Sobra:** no jogo, há 1,9 s entre passos.

## Tamanho do mundo salvo, salvar, carregar, memória e ausência

Faixa entre as 5 sementes. Salvar é o `salvar()` síncrono; `salvar_async` custa ~1 ms na linha principal, e o resto vai para a thread.

**Sem deus:**

| Ano | Pessoas | Eventos | Arquivo (MB) | Salvar (ms) | Carregar (ms) | Ausência de 1 ano (ms) | Memória (MB) | Pico (MB) | Objetos |
|---|---|---|---|---|---|---|---|---|---|
| 100 | 2–128 | 341–1.803 | 0,1–0,5 | 40–77 | 10–73 | 2–24 | 29–34 | 70 | 1.881–3.725 |
| 250 | 149–288 | 1.711–7.763 | 0,4–2,3 | 74–282 | 62–331 | 25–43 | 34–56 | 117 | 3.582–11.591 |
| 500 | 184–258 | 9.835–17.894 | 2,8–5,3 | 425–750 | 400–897 | 28–52 | 63–93 | 234 | 14.196–25.149 |
| 750 | 206–271 | 19.545–27.966 | 5,8–8,4 | 699–1.309 | 1.015–1.433 | 40–82 | 99–130 | 350 | 27.246–38.675 |
| 1000 | 209–261 | 29.710–37.452 | 8,8–11,3 | 1.046–1.860 | 1.363–2.106 | 35–46 | 136–165 | 466 | 40.785–51.455 |

**Com o caprichoso:**

| Ano | Pessoas | Eventos | Arquivo (MB) | Salvar (ms) | Carregar (ms) | Ausência de 1 ano (ms) | Memória (MB) | Pico (MB) | Objetos |
|---|---|---|---|---|---|---|---|---|---|
| 100 | 23–230 | 902–2.044 | 0,3–0,6 | 43–108 | 32–95 | 5–54 | 36–75 | 114 | 2.580–4.157 |
| 250 | 111–229 | 4.652–7.789 | 1,4–2,4 | 202–401 | 262–519 | 27–44 | 63–85 | 148 | 7.496–11.593 |
| 500 | 128–190 | 12.621–16.711 | 3,9–5,1 | 536–754 | 596–1.010 | 29–50 | 95–124 | 256 | 17.965–23.411 |
| 750 | 210–258 | 21.769–26.749 | 6,7–8,2 | 853–1.018 | 1.146–1.304 | 36–57 | 147–164 | 377 | 30.181–36.906 |
| 1000 | 190–258 | 31.714–37.376 | 9,9–11,5 | 1.145–1.714 | 1.460–2.168 | 33–69 | 186–200 | 504 | 43.367–51.028 |

**O que cresce, e por quê:**
- **O mundo salvo** cresce cerca de 1,1 MB a cada 100 anos: são uns 37 eventos por ano. A população não cresce (fica entre 150 e 290, pelo limite da terra).
- **Salvar, carregar e a memória** crescem com o arquivo.
  - Com 1000 anos, salvar leva até 1,9 s (na thread, com `salvar_async`), e carregar até 2,2 s. Carregar é uma vez por sessão.
  - A memória chega a 165 MB sem deus e a 200 MB com o caprichoso.
  - O pico de memória, de 470 a 500 MB, é o de carregar uma cópia inteira do mundo ao lado do original, só para o teste comparar os dois; no jogo, há um mundo só.
- **Não há vazamento.** Os objetos vivos são os eventos e as pessoas, inclusive as mortas, que a crônica e a memória do mundo leem: 37 mil eventos e ~12 mil pessoas dão os ~50 mil objetos.
- **A ausência máxima** (1 ano, 960 passos) não cresce com a história: fica entre 30 e 70 ms do ano 250 ao 1000.

**Decidido:** a primeira saída abaixo foi aprovada e está feita (veja "Depois do arquivo dos antigos", no começo). Na época: o núcleo não descartava nada do histórico, porque a crônica e a memória do mundo leem eventos antigos. Se 2 s para carregar e 11 MB depois de 1000 anos forem demais, as saídas são:
- arquivar os eventos de mais de 300 anos num arquivo à parte, lido só quando a crônica precisa;
- ou guardar só os eventos antigos que a memória usa, como mortes de quem ainda é lembrado e origens de costumes e nomes.

As duas mudam o formato do arquivo e precisam de aprovação. Até 300 anos (~3 MB), carregar leva menos de 0,5 s.

## A crônica dos séculos finais: repetição cortada

Medida nas crônicas dos últimos 200 anos dos 10 mundos (7.250 frases). Antes, com o código do commit `ca006e4`; depois, com o desta entrega.

| | Antes | Depois |
|---|---|---|
| Parte das 10 frases mais repetidas | 10,8% | 5,3% |
| Frases que aparecem 10 vezes ou mais | 23,9% | 16,0% |
| Frases repetidas dentro de 25 anos | 14,2% | 6,0% |
| A frase mais repetida | "Nunca voltaram." (121 vezes) | "Ninguém os viu de novo." (52) |

**O que mudou:**
- **A crônica lembra as frases que usou.**
  - Quando um evento tem mais de uma frase possível, ela evita a que já entrou nos últimos 25 anos. Se todas entraram, fica a mais antiga.
  - Essa memória (`_recentes`) é gravada com o mundo, e os arquivos antigos, sem ela, continuam abrindo.
  - Só a escrita oficial do ano mexe nela: as notas ao vivo e o relato da ausência não mudam a crônica.
- **Ganharam variantes** as frases que mais voltavam em 1000 anos:
  - a partida pela borda do mundo;
  - o raio que não acerta ninguém;
  - os gêmeos;
  - a terra erguida;
  - a fartura e a seca do deus;
  - o fogo que deixa um lugar amaldiçoado;
  - o dilúvio (a água que cobre a zona, as cabanas levadas, os afogados);
  - os três presságios (cometa, eclipse, luzes);
  - o terremoto;
  - o cometa;
  - o sonho e as mortes na guerra, no perfil de quem morreu.
- **O que ainda se repete** é, na maioria, o que o deus caprichoso faz 1.600 vezes em 1000 anos: cada poder tem agora de 2 a 4 descrições. O que segue mais repetido:
  - o censo da década ("No fim do ano N, N pessoas viviam no mundo..."), que é de propósito;
  - "Era coisa de outro povo, diziam.", com 33 vezes em 2000 anos de crônica.

**Os nomes do deus:**
- Um povo que dá nome ao deus, ou o rebatiza, ou um profeta, ou os fiéis de um cisma, agora escolhem um nome que nenhum outro povo vivo usa. Antes, dois povos que nunca se falaram chegavam a "a Mão Que Cura" cada um por conta própria.
- O nome repetido continua quando um povo se separa de outro e leva a fé junto, porque é o mesmo deus. A tabela de estilos agora mostra isso como "o Olho Escuro (2 povos)".

## O ciclo completo

`resistencia_ciclo.gd`, semente 2, sem deus:

1. **O fim.** O mundo acaba no ano 137. A primeira era vira o livro "A Primeira Era" (9.621 caracteres), na estante.
2. **O recomeço.** No ano 147, o jogador cria um povo novo, Beres, da era 2.
3. **As ruínas.** Beres encontra as ruínas de Esar e faz delas um mito: "diante das ruínas de Esar, o chão batido de casas sem ninguém, Beres disse que ali viveu um povo que o deus destruiu, e tomou cuidado para não fazer o mesmo".
4. **Depois.** Nasce a crença, e Beres chega à agricultura. Em 1000 anos, o mundo chega a 4 povos.
5. **Salvar depois do fim.** O mundo salvo e carregado depois do fim dá a mesma crônica.

Nos 10 mundos de 1000 anos, só esse acabou: os outros 9, inclusive os 5 do caprichoso, chegaram ao ano 1000 com 3 ou 4 povos.
