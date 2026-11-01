# Teste de resistência: 1000 anos

5 sementes (1 a 5), cada uma por 1000 anos, sem intervenção do deus e com o deus caprichoso (um poder qualquer, em qualquer lugar e força, a cada 25 dias em média, a partir do ano 5: 1.600 gestos em 1000 anos). Um mundo por processo, 5 processos ao mesmo tempo. Quando o mundo fica vazio, o jogador cria um povo novo 10 anos depois.

- `resistencia.gd` roda um mundo e mede a cada 50 anos. As tabelas completas estão em `medidas/`, e a crônica dos últimos 200 anos de cada mundo em `cronicas/`.
- `resistencia_passos.gd` carrega o mundo do ano 1000 e mede passo a passo, como a apresentação usa o mundo.
- `resistencia_ciclo.gd` roda o fim do mundo e o recomeço. A crônica do período está em `ciclo-semente-2.md`.

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

**Para decidir:** o núcleo não descarta nada do histórico, porque a crônica e a memória do mundo leem eventos antigos. Se 2 s para carregar e 11 MB depois de 1000 anos forem demais, as saídas são:
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
