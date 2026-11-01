# Os 11 poderes, vistos como jogador

*Sessão A (simulação), 01/11/2026.* Gerado por `ferramentas_sim/poderes.gd`. Para cada poder:
- **um gesto** sobre o povo maior, em 3 intensidades (0,2, 0,6 e 0,95) e em 3 mundos:
  - o primeiro povo, no ano 5;
  - a agricultura, no ano 60;
  - estágios altos, no ano 165;
- **o que mudou um dia depois:**
  - mortos, abrigos, estoque, comida e água da zona;
  - a fé média, o nome do deus;
  - crenças, costumes e lugares novos;
  - os eventos, a linha da crônica e o pensamento de alguém do povo;
- **a repetição:** o mesmo poder 10 vezes, um gesto a cada 2 dias, no mundo da agricultura.

As tabelas estão em `<poder>.md`.

## A regra das intensidades

O gesto tem 3 graus:
- **sinal:** intensidade abaixo de 0,5;
- **milagre:** intensidade de 0,5 para cima;
- **imposição:** o 3º uso do mesmo poder na mesma zona em 3 dias.

Em alguns poderes, a intensidade só conta pelo grau. Em outros, conta também dentro do grau, de modo proporcional:

| Poder | O que a intensidade muda |
|---|---|
| chuva, fartura, seca, fogo, dilúvio, terremoto | proporcional: mais intensidade, mais comida, mais seca, mais fogo, mais casas no chão |
| raio, sonho, cura, presságio, erguer | só o grau: o sinal é fraco (o raio não mata, o sonho convence metade das vezes, a cura só sara quem está doente), e o milagre é igual de 0,5 a 1,0 |
| fogo | abaixo de 0,35 é fogo brando: aquece e não queima |

Isso é previsível o bastante para aprender, se a tela mostrar o grau (veja "Para a B").

## Poder por poder

| Poder | O efeito (agricultura, ano 60, 0,6 → 0,95) | A reação do povo | 10 vezes seguidas | Veredito |
|---|---|---|---|---|
| **chuva** | comida da zona de 58 para 91 → 107; acaba a seca no milagre | fé +0,05; atende a prece de seca | fé +0,41; **antes:** só isso; **agora:** a festa da chuva (4ª vez) e a dependência, quando o povo deixa de poupar água (6ª vez) | bom; a repetição agora gera hábito |
| **fartura** | estoque de 43 para 435 → 579 (de 2 a 8 dias de comida por pessoa) | fé +0,06; atende a fome; nomeia o lugar quando havia fome | fé +0,52; **agora:** oferendas (4ª vez) e dependência, quando o povo deixa de guardar comida (6ª vez) | forte, mas proporcional e passageiro |
| **raio** | mata quem está sob o gesto (milagre); o sinal cai perto | crença de castigo ou martírio, nome do deus ("o Que Fere"), costume, lugar ("do Raio"); fé −0,16 | 10 mortos, fé −0,92, 2 renomeações, oferendas: medo | coerente; o poder mais pessoal |
| **fogo** | brando (< 0,35) aquece; 0,6 derruba metade dos abrigos e mata 0 a 1; 0,95 mata até 5 | crença ("o Que Queima"), lugar ("das Cinzas"), purificação ou maldição; contraria preces | 27 mortos, fé −0,58, o costume de queimar os mortos, silêncio do deus | proporcional; o brando é o oposto útil |
| **seca** | água da zona de 1,0 para 0,45; estoque −35% na agricultura | crença de castigo, "o Sedento", oferendas; contraria preces | fé −0,49, castigo e oferendas | coerente |
| **dilúvio** | 0,2 mata 0 a 1 e derruba um terço dos abrigos; 0,95 mata 13 e deixa 2 de 15 abrigos | "a Grande Água", crença do dilúvio, lugar | 50 mortos em 20 dias | **o mais forte**, mas proporcional e sem segredo; a tela deve deixar claro o tamanho |
| **terremoto** | derruba de 5 a 14 abrigos e mata 0 a 2 | "a Terra Brava", castigo; atende a prece de guerra quando cai no inimigo | 21 mortos, fé −0,46, castigo | não é inútil: muda as casas de verdade |
| **erguer** | a pedra alta, lugar sagrado com nome; trégua entre povos em guerra | "o Que Ergue", crença do lugar sagrado, fé +0,15 | fé +0,62, o lugar sagrado | bom, sem custo; a força está na trégua |
| **sonho** | uma ideia para quem sonha: no estágio 1, a agricultura; depois, o saber do próximo estágio; ou uma visão que faz um sacerdote | a fé de quem sonha +0,5 (a média do povo quase não muda) | em 10 sonhos, o povo subiu um estágio | **não é fraco: é o atalho da técnica**. Só não aparece na fé média |
| **presságio** | uma luz no céu para o mundo inteiro | fé +0,15 a +0,22; nome do deus ("o Que Acende o Céu") em todos os povos; vale a metade no estágio 5 e um quarto no 6 | fé +0,65, 3 renomeações | bom para começar crenças; fraco nos estágios altos, de propósito |
| **cura** | cura quem está doente ou fraco (milagre); a imposição cura todos os doentes do povo; em quem está são, não faz nada (sinal) | o curado vira devoto e às vezes sacerdote; atende a prece pelo filho | **agora** só conta a cura de quem estava doente: 10 curas em gente sã não criam nada; em doentes, oferendas e dependência | não esvazia a morte: não cura a velhice nem a fome |

## O que mudou no núcleo

- **Os gestos bons repetidos viram hábito** (`Mundo.GESTOS_BONS`, `gestos_bons`). Antes, 10 chuvas ou 10 farturas só subiam a fé.
  - **Na 4ª vez em um ano, sobre o mesmo povo, vira costume:**
    - a chuva vira a festa da chuva;
    - a fartura e a cura viram oferendas;
    - o sonho, o presságio e a terra erguida fazem nascer a crença de que o deus ouve.
  - **Na 6ª vez:** a chuva, a fartura e a cura viram dependência. O povo deixa de guardar comida ou água (evento `dependencia`, com `por`). A crônica conta:

    > «Zeor se acostumou: a Estrela de Cauda mandava a chuva sem que ninguém pedisse, e o povo deixou de se preparar.»
- **A cura de quem não estava doente não conta** para o hábito.
- Os gestos que ferem já criavam o medo (castigo, oferendas, renomeação) e continuam iguais.

## Para a B (na tela)

1. **Mostrar o grau ao soltar o gesto.**
   - Mostrar "sinal", "milagre" ou "imposição", com a cor da carga: o jogador precisa saber que, no raio, no sonho, na cura, no presságio e na terra erguida, passar de 0,5 é o que conta.
   - No fogo, a marca de 0,35: abaixo dela, fogo brando.
2. **O dilúvio é o poder mais forte:** pode matar 13 de 148 num gesto. Vale um aviso visual na carga alta, como uma água que sobe.
3. **A cura sobre alguém são não faz nada.** Na dica do gesto, sugerir os doentes; a `preces_abertas` já traz o `alvo` da prece pelo filho.
4. **O sonho não muda a fé do povo:** muda uma pessoa. A tela pode marcar quem sonhou, que é quem aprende a ideia.
5. **O hábito e a dependência** são eventos de nota (`costume`, `dependencia`) e merecem um sinal: são a consequência de longo prazo da repetição.
