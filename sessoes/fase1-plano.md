# Fase 1 — plano e divisão do trabalho

*Orquestrador: Claude. Início em 01/11/2026.*

## Objetivo

Entregar o **menor conjunto que entrega a essência** (documento funcional): um jogo jogável na moldura, com o primeiro povo, preces como sinais, 6 poderes, uma linhagem acompanhada, ritmo lento com salto e a crônica, rodando o dia todo com leveza.

## Resultado da fase 0 (aprovado)

- **Simulação (A):** as crônicas valem a pena ler, especialmente com intervenção. 100 anos em cerca de 1 s. Problemas: repetição na segunda metade, fragmentação em povos pequenos, personagens rasos, perda de conhecimento e expedição que nunca disparam.
- **Moldura (B):** funciona no Windows. CPU de 0,05%, memória de 180 MB (pouca folga). Esconder é minimizar, o ícone fica na bandeja e o atalho global é opcional, por processo auxiliar.
- **Arte (C):** a cena-alvo do Claude é a referência oficial. As peças modulares remontam a cena.

## Quem é dono de quê

Nenhuma sessão edita arquivos fora da própria área. Quando uma precisa de algo da outra, pede ao orquestrador.

| Sessão | Área (só ela edita) | Missão |
|---|---|---|
| **A, simulação** | `jogo/nucleo/`, `jogo/ferramentas_sim/` | Núcleo da simulação: melhorias da fase 0, persistência, ausência, API para a apresentação |
| **B, apresentação** | todo o resto de `jogo/`, incluindo `project.godot` | Moldura, desenho do mundo, efeitos, interação, interface |
| **C, arte** | `arte_claude/` | Peças do estágio 2, efeitos, sinais, ícones, ruínas |

O `jogo/nucleo/` já foi copiado do protótipo (`prototipos/simulacao/nucleo/`). A partir de agora, a versão oficial é a de `jogo/nucleo/`, e o protótipo fica congelado.

## Contrato entre A e B

- A apresentação **só lê** o estado do mundo e os eventos, e **só age** por chamadas públicas do núcleo (avançar o tempo, usar um poder, salvar e carregar).
- A documenta a API em `jogo/nucleo/API.md` e mantém esse arquivo atualizado. Mudanças que quebrem a API precisam ser avisadas ao orquestrador antes.
- Enquanto a API nova não existir, B usa o que o núcleo já oferece: `mundo.grupos`, `mundo.pessoas`, `mundo.zonas`, `mundo.eventos` e `avancar_hora()`.

## Critério de saída da fase 1

1. O jogo abre na moldura, cria o primeiro povo e roda sozinho.
2. O jogador vê pessoas vivendo, as preces aparecem como sinais e os 6 poderes funcionam por gesto, com reação do povo.
3. Dá para acompanhar uma linhagem e ler a crônica dentro do jogo.
4. Fechar e abrir de novo retoma o mundo, com o avanço da ausência e a crônica do período.
5. Leveza: CPU média abaixo de 2% e memória abaixo de 200 MB com o jogo rodando.
6. O visual em jogo parece a cena-alvo.

## Fase 2 adiantada (01/11/2026)

A e C terminaram a fase 1 antes da integração da B. Para ninguém ficar parado, as duas adiantam a fase 2, cada uma na mesma área de antes:

| Sessão | Fase 2 |
|---|---|
| **A, simulação** | os 5 poderes restantes (seca, dilúvio, terremoto, presságio, cura); estágios 3 a 6 com o efeito de cada um na relação com o deus; a crônica do próprio povo a partir da escrita; o fim do mundo (extinção, mundo vazio, criar novo povo só com o mundo vazio, ruínas que guardam conhecimento, crônica fechada como livro e estante de crônicas); o abandono do mundo; as 6 dimensões culturais completas |
| **C, arte** | estágios 3 a 6 (construções, habitantes com roupas e ferramentas de cada estágio, templo por estágio); efeitos dos 5 poderes restantes (seca, dilúvio, terremoto, cometa e eclipse, cura); ruínas por estágio; cenas de amostra de uma vila em cada estágio; ícone do jogo para a bandeja e a barra de tarefas |

Regras de sempre: nenhuma mudança que quebre a API sem aviso, e o `LEIA-ME` da arte sempre atualizado.
