# Auditoria 9: roteiro (os estágios 3 a 6 com tudo ligado)

*Sessão C (arte), 01/11/2026. Preparado antes da entrega da B. É a auditoria 7 refeita com as peças novas ligadas. A meta é **nenhum estágio abaixo de 4**.*

## Como rodar

1. **Trazer a main** com a entrega da B.
2. **Sondar o núcleo:** `sondar_estagios9.gd`, nos mesmos mundos da auditoria 7. Ele dá os povos, o estágio, as pessoas, a aparência, as obras de cada povo e as ruínas. Copie o script para `jogo/ferramentas_sim/` e apague depois.
3. **Capturar:** `capturar9.sh`.
   - Mundos: semente 3 nos anos 60, 140, 161, 250 e 500; semente 7 nos anos 90, 110, 122, 200 e 400.
   - Em cada mundo: 10h, 19h, 22h e inverno.
   - Mais 1 min de tarde em 1x por estágio.
   - Depois, `git checkout -- jogo && git clean -f -q jogo`.
4. **Recortar e comparar** lado a lado com `capturas7/` (`recortar7.py` serve de modelo).

## O que conferir em cada estágio

| # | Da auditoria 7 | Como conferir | Quem ligou |
|---|---|---|---|
| A1 | as roupas dos estágios nas folhas de sempre | o chapéu e as calças em todo o povo do estágio 6, não só em quem faz uma ação de 1x; capacete no 4, túnica no 5, capa no 3 | B |
| A2 | a casa caiada do estágio 5 | as casas do povo do estágio 5 brancas, com o friso escrito | B |
| V1 | a vila amontoada | quantas pessoas ficam na frente das casas; se há a fileira de trás; se as portas e as fogueiras aparecem; quantas casas cada povo tem | A e B |
| E1 | o estágio 5 sem obra própria | o arquivo (`biblioteca`), a estela e o templo de escrita na tela, nos anos 161 (S3) e 122 (S7) | A e B |
| E2 | o estágio 6 sem templo, canal ou muro | a cúpula, a roda d'água ou o canal na roça junto ao lago, e o muro entre as torres | A e B |
| C1 | as culturas iguais | o estandarte no alto da casa principal de cada povo (cor da roupa e símbolo); o vão entre as vilas | B |
| E4 | as baforadas no céu | a fumaça não fica inteira acima da vila | B |

**E também:**
- as ruínas e o mato (revisto agora: a ruína continua lendo como ruína no grau 3);
- de noite, as janelas acesas e as fogueiras;
- no inverno, a neve nos telhados e o capuz.

## Notas

Use a mesma régua da auditoria 7 (estágio 3: 3, estágio 4: 3, estágio 5: 2, estágio 6: 3). Para cada estágio:
- a nota;
- o que a sustenta;
- o que falta para 5.

Se algum ficar abaixo de 4, diga exatamente o porquê e de quem é cada item.
