# Auditoria 13: a tarde (12h às 15h30) em 1x

*Sessão C (arte), 01/11/2026. Feita sobre a main em `b639bfa` (as três cenas da tarde ligadas). As capturas são reais, pelo código-fonte, com `--sem-config` e `--mundo-novo`, a janela no segundo monitor e sem foco, sem o mouse real. Os comandos estão em `capturar13.sh`.*

> **A pasta de dados do usuário:** fiz a cópia antes e, no fim, copiei por cima, sem apagar nada. Os testes não a usam.

## Como foi feito

| Mundo | O que tem na tarde | Quadros |
|---|---|---|
| s7, dia 12 (acampamento) | a sesta | 105 quadros de 12h01 a 15h42, um a cada 4 s |
| s3, dia 20 (acampamento, outono) | a sesta e o artesanato | idem |
| s3, 60 anos (vila de pedra, estágio 4) | o ensinar (12h58 a 13h36) | idem, mais 3 rajadas de 0,1 s em cada arremesso: o do velho, o erro e o acerto |

- **Em que dias a cena de ensinar aparece:** num script temporário (já apagado), contei as cenas em 8 dias para cada mundo e idade.
  - O ensinar precisa de uma criança de 8 a 13 anos e de um adulto de 35 anos ou mais. Por isso não aparece em todo mundo novo (s7: 0 em 8 dias).
  - Nos outros mundos, aparece em 2 a 7 dias de cada 8.
- **Em 1x, a lança voa por 0,3 minuto de jogo, o que dá 0,56 s reais.** Os quadros de 4 s nunca a pegam, e só as rajadas mostram o voo.

Os quadros inteiros estão em `capturas13/` e os recortes ampliados em `recortes13/`. Os scripts que fazem as folhas e os recortes são `folha13.py` e `recorte13.py`.

## A tarde, cena a cena

| Cena | Lê-se em 1x? | Por quê |
|---|---|---|
| **Sesta** (12h35 às 13h45) | **Sim, em parte** | Os deitados de lado se veem junto da cabana, e o balão de raiva de quem ralha se lê bem (`04_sesta.png`, quadro 28). A cutucada e a fuga se leem pelo movimento. **O que pesa:** a sesta fica "à sombra da casa", mas colada na base da cabana, que cobre metade dos corpos (quadros 36 e 40). |
| **Artesanato** (13h50 às 15h25) | **Pouco** | A roda cai em cima de uma cabana: o centro dela, a 18 px do fogo, é a própria cabana (`05b_roda_em_volta_da_cabana.png`). Os dois de lado ficam de frente um para o outro com a cabana no meio, e o terceiro senta na porta escura. A peça (cesto, pote, lança) não aparece contra a cabana. Erguer a peça no fim se lê, porque sobe acima do telhado. |
| **Ensinar** (12h58 às 13h36) | **Não, de longe** | Veja a seção seguinte. |
| O resto da tarde | Sim | Antes e depois das cenas há gente andando, a vigia e conversas perto do fogo (`01` e `02`). A tarde deixou de ser o trecho parado do dia. |

## O arremesso e a lança cravada se leem de longe?

O orquestrador perguntou sobre `capturas/tarde-ensinar.png`, da B. Lá, os três ficam colados contra o pomar florido.

**Resposta: não se leem na escala da janela (2x).** A captura da B é um recorte ampliado 5 vezes, e nele quase tudo se lê. Em 2x, a cena inteira tem uns 30 px de largura na tela.

**Medido na vila do estágio 4** (`06`, `07`, `03`):

1. **O arremesso não se vê:**
   - a lança voa por 0,56 s;
   - ela é um traço de 1 px, marrom;
   - cruza a parede da casa na altura do beiral, que também é uma linha marrom horizontal.

   Nas rajadas, ela só aparece em 3 ou 4 quadros, e só ampliada.
2. **Não dá para saber quem ensina quem:**
   - o mestre fica a 4 px da criança, e as duas figuras viram uma silhueta só;
   - às 13h, na frente do templo, há mais 6 a 8 pessoas em volta deles.
3. **O alvo não parecia alvo:** o feixe amarelo com duas faixas escuras, de longe, lia-se como um barril, uma colmeia ou uma lanterna. Contra o pomar florido (amarelo e rosa), ainda some na cor.
4. **A lança cravada se lê um pouco melhor,** porque fica 4 min de jogo (7,5 s) no alvo. Mas ela entra pelo lado da parede da casa, e o escuro dela se confunde com a porta.

### Quem resolve o quê

| Parte | O problema | O que fazer | Quem |
|---|---|---|---|
| **Arte** | O alvo parecia um barril. | **Feito:** `alvo_capim` agora tem um círculo de ocre vermelho com o miolo branco. Em `alvo_capim_lanca`, a lança escura entra no miolo. Os tamanhos e o encaixe são os mesmos (8 × 14 e 12 × 14), então não há nada a mudar no código. Em 2x, ele vira um disco vermelho e branco numa estaca e se distingue de tudo na vila (`03`, embaixo, e `08`). | C |
| Arte | A lança voando tem 1 px de espessura (`objetos/lanca_voando`, a mesma da caçada). | Posso fazer uma versão de 2 px com a ponta clara, só para o alvo, se a B quiser. Não mexi na da caçada. | C, se pedido |
| **Encenação** | O voo dura 0,56 s em 1x. | Usar `SOLTA_ALVO` 0,4 e `CRAVA_ALVO` 0,9 (uns 0,9 s), e, em 1x, um arco de 8 a 10 px em vez de 5, para a lança passar acima da linha dos beirais. | B |
| **Encenação** | O mestre fica a 4 px da criança e cobre a figura dela. | **Sim, espaçar para 8 a 10 px.** A figura de 12 px do velho passa a ficar inteira atrás da criança, sem cobrir a dela, e se leem duas pessoas. | B (a posição `xv` vem do núcleo, `_cena_ensinar`; quem troca o 4 é a A, ou a B por cima) |
| **Lugar** | "Na borda da vila, do lado de terra, a 34 px do fogo" cai **dentro** da vila quando ela cresce. Na vila de 60 anos, fica na frente do templo, entre as duas metades da vila, com o alvo encostado na parede de uma casa e muita gente em volta. | Pôr o atirador **além da última casa** do lado de terra (a borda da faixa do povo, `c["faixa"]`) e o alvo a 26 a 30 px, com capim e céu atrás. Assim a lança voa contra o fundo limpo. | A |
| **Lugar** | O artesanato fica a 18 px do fogo, em cima de uma cabana, e a sesta fica colada na base da cabana, que cobre os corpos. | Afastar o centro da roda das casas (`_na_vila` hoje só evita o fogo) e deitar os da sesta ao lado da casa, a 6 a 8 px da parede, e não colados na base. | A |

### Sobre o fundo do pomar (a captura da B)

O pomar florido é o lugar mais cheio de manchas do acampamento: pontos amarelos e rosa na mesma cor do capim do alvo e das roupas. Ali, nenhuma figura pequena se lê bem.
- Com o alvo novo (o vermelho e o branco não estão no pomar), o alvo passa a se ler.
- As pessoas e a lança continuam dependendo do lugar. Esse é o mesmo pedido de "fundo limpo" à A.

## Correção à parte: o balão de fala

O balão de fala branco com dois traços (`sinais/balao_5v`, variação 0), na conversa da roda, parecia uma caveira em 1x. A B achou o mesmo.
- Agora é um traço inteiro, com o canto de baixo à esquerda puxado para a ponta (`amostra_baloes_4x.png`).
- O tamanho e a ordem das variações são os mesmos.

## Nota da tarde: 4

- **Sobe:** a tarde tem cenas, e não é mais o trecho parado do dia. A sesta com a cutucada, o ralho e a fuga é o melhor momento dela.
- **Segura em 4:** o ensinar não se lê de longe, e o artesanato fica escondido atrás de uma cabana.

**Para 5:**
1. **A:** o ensinar além da última casa, com fundo limpo, e a roda e a sesta longe das paredes das casas.
2. **B:** o mestre a 8 a 10 px, e o voo da lança mais longo e mais alto.
3. **B:** sincronizar o alvo novo e o balão de fala (`objetos/alvo_capim`, `objetos/alvo_capim_lanca` e `sinais/balao_5v`).

Feito o item 1, o resto é ajuste fino. Vale refazer esta auditoria no `.exe` da 0.1.2.
