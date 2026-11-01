# O uso real: 4 semanas de um jogador típico

*Sessão A (simulação), 01/11/2026.* Gerado por `ferramentas_sim/uso_real.gd`, nas sementes 1 a 5 (`semente-<n>.md`).

## O jogador simulado

| Momento | Duração real | Tempo de jogo |
|---|---|---|
| Jogo aberto em 1x, de segunda a sexta | 8 h | 256 passos, uns 11 dias |
| Noite fora, de segunda a quinta | 16 h | 512 passos, uns 21 dias |
| Fim de semana fora, de sexta à noite a segunda de manhã | 64 h | o teto da ausência: um ano |

Ele faz 3 gestos por dia: responde à prece aberta mais antiga com o poder que a atende; sem prece, faz um sinal bom.

**A escala de tempo:**
- Um ano de jogo dura 30 h reais em 1x (112,5 s por hora de jogo). No relatório das preces, eu disse "uns 30 minutos": estava errado.
- Uma semana real dá uns 4,5 anos de jogo, e as 4 semanas, uns 18 anos.

## O que o jogador viu, por dia real (somando as 5 sementes, 100 dias)

| | Semente 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Chamados nas sessões (4 semanas) | 9 | 5 | 5 | 7 | 3 |
| Notas nas sessões | 58 | 61 | 69 | 61 | 53 |
| Notáveis do próprio mundo (fora os gestos e as reações a eles) | 22 | 22 | 23 | 22 | 13 |
| Dias sem nenhum chamado nem nota | 2 | 2 | 3 | 2 | 2 |
| Dias sem nada notável do próprio mundo, **antes do ajuste** | 11 | 14 | 14 | 15 | 10 |
| Os mesmos dias, **depois do ajuste** | 9 | 6 | 9 | 10 | 9 |

Cada tabela por semente tem uma linha por dia real, com:
- o ano e o dia de jogo no fim da sessão;
- chamados, notas e os notáveis do mundo;
- preces, gestos, mudança de estágio (na sessão ou "fora", na ausência), nascimentos e mortes com nome;
- o começo do resumo da ausência que abriu o dia.

## As respostas

**Há dias reais em que nada de notável acontece?**
- Com o jogador ativo, quase nunca: só 2 ou 3 dias em 20 ficam sem nenhum chamado nem nota.
- Mas boa parte do que ele vê é a consequência dos próprios gestos.
- Do próprio mundo, numa sessão de 8 h (11 dias de jogo), num povo de 12 a 30 pessoas, não acontecia nada notável em metade a três quartos dos dias. Depois do ajuste, são de 30% a 50% dos dias.
- O que preenche esses dias é o cotidiano na tela: a caçada em 2 de cada 3 dias, as cenas da tarde, os incidentes, a noite. Isso não é evento de crônica.

**A ausência de fim de semana devolve um mundo reconhecível?**
- Sim. Nos 20 fins de semana, os 27 povos continuaram, 25 com o mesmo líder e 26 com o mesmo nome do deus, e nenhum povo novo apareceu.
- A população mudou pouco.
- O resumo conta o ano que passou e, no fim, o de sempre (veja a auditoria 8).
- O jogador perde momentos grandes: em 3 das 4 sementes que chegaram à agricultura, as primeiras roças vieram num fim de semana. O resumo conta isso, e o evento vem como chamado na ausência.

**Em 4 semanas, o jogador vê o povo mudar de verdade?**
- Sim, nos primeiros 18 anos:
  - todos os povos ganham crença e nome para o deus (e muitos renomeiam);
  - 4 das 5 sementes chegam à agricultura;
  - 3 das 5 têm um povo novo, nascido de uma separação;
  - há fomes, secas, preces, sacerdotes e líderes novos.
- As casas de pedra (estágio 3) ficam para o segundo ou terceiro mês: a mediana do estágio 3 está acima de 40 anos.

## O ajuste do ritmo (sem mudar a escala de tempo)

- **Num povo de até 40 pessoas, cada vida conta.** O nascimento, o casamento, a rixa e o roubo, que num povo grande passam sem ninguém notar (camada "ambiente"), viram nota: importância 4, abaixo do que entra na crônica do ano. O novo líder também passa de 3 para 4, em qualquer povo.
- **O rito de passagem** (evento `rito`, nota). Num povo de até 60 pessoas, quem faz 14 anos vai pela primeira vez com os adultos:
  - à caçada;
  - à pesca, nos povos do lago e da praia;
  - ou à roça, conforme o povo.

  > «Kira fez catorze anos e foi à primeira caçada com os adultos.»
- **O mundo é o mesmo.** Essas mudanças não mexem no sorteio: a crônica oficial e a simulação são as mesmas. Só mudam a camada das notas e o relato da ausência, que conta da importância 4 para cima.

Os textos curtos novos:
- "Kira e Enem se casaram";
- "Oro e Aru brigaram";
- "Mik roubou de Viem";
- "Kira vai à primeira caçada".
