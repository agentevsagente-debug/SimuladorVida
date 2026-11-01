# Sessão B — teste da moldura

## Objetivo

Responder a duas perguntas técnicas: **a moldura funciona no Windows como companheiro de área de trabalho? E é leve o bastante para ficar aberta o dia todo?**

## Leia antes

1. `prompt-funcional-simulador-de-vida.md`: seções "Formato", "Atenção e sinais" e "A moldura".
2. `tecnico-simulador-de-vida.md`: seções "Moldura", "Resolução e arte" e "Leveza".

## Regras do ambiente

- Trabalhe **somente** em `prototipos/moldura/`. Não edite nenhum outro arquivo do projeto.
- Godot 4.7.2, versão padrão, GDScript. Sem .NET e sem extensões. O comando `godot` não está no PATH. Os caminhos completos dos executáveis estão na seção "Ambiente" do documento técnico.
- Use formas e cores simples no lugar da arte. A arte do Codex chega em `arte/` depois. Se já houver arte aprovada lá, pode usá-la, mas não dependa dela.

## Escopo

**Janela**
- Sem borda, fundo transparente, sempre por cima das outras janelas.
- O mouse atravessa as áreas transparentes. Só a área do mundo recebe cliques.
- Pode ser arrastada (por uma alça ou pela borda) e redimensionada em escala inteira (2x, 3x, 4x) da área base de 480 × 160 pixels, sem distorcer os pixels.
- Atalho para esconder e mostrar a moldura. Investigue se dá para usar um **atalho global**, que funcione com outra janela em foco. Se o Godot não permitir sem extensão, registre isso e proponha alternativas (ícone na bandeja do sistema, atalho só com a moldura em foco etc.).

**Conteúdo de teste**
- Céu desenhado por código, com gradiente que muda num ciclo de dia e noite acelerado (por exemplo, um dia a cada 2 minutos).
- Uma faixa de chão.
- 30 bonecos simples andando de um lado para o outro.
- Um clique no céu faz "chover" sobre aquele ponto (efeito simples), só para testar a entrada do mouse.

**Leveza**
- Máximo de 30 quadros por segundo e modo de baixo consumo quando nada muda.
- Com a moldura escondida, não desenhar nada.

## Entregas

Em `prototipos/moldura/`:
- o projeto Godot;
- `RELATORIO.md` com:
  - o que funcionou e o que não funcionou no Windows (transparência, sempre por cima, mouse atravessando, arrastar, redimensionar, atalho);
  - medições de CPU e memória durante 10 minutos em três situações: moldura visível parada, visível com os 30 bonecos andando e escondida. Diga como mediu;
  - limitações encontradas e recomendações para a fase 1.

## Critérios de aceite

- a janela é transparente fora da área do mundo e fica sempre por cima;
- clicar fora da área do mundo atinge a janela de trás;
- arrastar e redimensionar funcionam, com pixels sempre nítidos;
- com os 30 bonecos andando, CPU média abaixo de 2% e memória abaixo de 200 MB, ou um relatório claro do que impede chegar lá.
