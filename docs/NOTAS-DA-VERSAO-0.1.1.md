# Simulador de vida 0.1.1

*Texto pronto para a página da Release no GitHub. Copie a partir da linha abaixo.*

---

**A primeira versão pública do Simulador de vida:** um pequeno mundo de pixel art que vive sozinho num canto da sua tela. Um povo nasce, caça, planta, reza e envelhece, ano após ano, mesmo com você olhando para outra coisa. Você é o deus dele, mas ninguém pode te ver: você só faz gestos e vê o que o povo faz com eles. Tudo fica escrito numa crônica.

Gratuito, para Windows, sem instalador, sem internet e sem modelo de linguagem. Feito inteiramente por IA ([como foi feito](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-foi-feito.md)).

## Baixar e jogar

1. Baixe o `Simulador de vida.exe` (cerca de 110 MB) aqui embaixo, em **Assets**, e rode. Não há instalador.
2. O Windows pode mostrar "O Windows protegeu o computador", porque o jogo não tem assinatura digital. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. O mundo começa vazio. Clique sobre ele para fazer nascer o primeiro povo.

**Requisitos:** Windows 10 ou 11, 64 bits.

O guia completo está em [Como jogar](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-jogar.md).

## O que tem nesta versão

- **Uma janela transparente, sempre por cima**, que deixa o mouse passar pelos espaços vazios. Dá para arrastar, mudar de tamanho (2x, 3x, 4x), esconder com **H** e trazer de volta pelo ícone perto do relógio ou com **Ctrl+Alt+H**.
- **Um povo que vive sozinho:** famílias, traços, caçada, pesca, roças, brincadeiras, a roda em volta do fogo ao entardecer, a vigia da madrugada, estações com neve e colheita, migrações, cismas e guerras.
- **11 poderes por gesto:** chuva, raio, fogo, fartura, erguer a terra, sonho, seca, dilúvio, terremoto, presságio e cura. Quanto mais tempo você segura, mais forte: um sinal discreto, um milagre inegável, ou o fogo brando, que aquece sem queimar.
- **Preces e religião:** o povo reza quando precisa, dá um nome ao deus pelo que viu, explica o silêncio dele, tem sacerdotes, profetas e cismas, e pode deixar de crer.
- **6 estágios:** coleta, agricultura, pedra, metal, escrita e engenharia (canais e moinhos). O saber vive nas pessoas e pode se perder.
- **Culturas** que se separam e mudam, cada uma com o seu nome para o deus, os seus costumes e a sua aparência.
- **A crônica do mundo** (tecla **C**), escrita ano a ano a partir do que de fato aconteceu, com um capítulo por estágio.
- **A ausência:** com o jogo fechado, o mundo continua no ritmo normal até 1 ano de jogo, e um resumo conta o que aconteceu.
- **O fim do mundo e a estante:** o povo pode acabar. O mundo vazio continua, as ruínas ficam, e um povo novo pode nascer sobre elas. Cada mundo que acaba, ou que você abandona, vira um livro na estante (tecla **E**).
- **A família acompanhada** (tecla **L**), que passa aos descendentes.
- **O modo discreto** (tecla **D**): as cenas mais pesadas não são mostradas em detalhe, mas ficam na crônica.
- **Velocidades** 1x (um dia de jogo em cerca de 45 min), 10x, 50x e o salto até o próximo acontecimento (tecla **S**).
- **Leve:** por volta de 5% de um núcleo do processador em 1x, e 0,2% escondido.

**Novo na 0.1.1:** no mundo vazio, aparecem um cervo e uma garça nos primeiros segundos (um coelho, no inverno), e os pássaros passam com mais frequência até o primeiro povo; a dica "Clique para fazer nascer um povo aqui" aparece também junto do cursor; a crônica com um capítulo só fica centrada, sem o índice.

## Problemas conhecidos

- **O aviso do SmartScreen.** O jogo não tem assinatura digital. Veja acima como abrir.
- **Não tem som.** O jogo é silencioso nesta versão.
- **Só Windows 10 e 11, 64 bits, e só em português.**
- **O ícone perto do relógio pode estar escondido** na setinha "^" do Windows 11. Para trazer a janela de volta, use também o **Ctrl+Alt+H** ou o jogo na barra de tarefas.
- **O Ctrl+Alt+H pode já estar em uso** por outro programa. Nesse caso, esse atalho não funciona no jogo; use o ícone ou a barra de tarefas.
- **Engasgos em 50x num mundo grande, em computadores mais lentos.** Com cerca de 240 pessoas, a montagem do dia pode levar mais de 1 s. Na máquina de testes, isso não travou o jogo; num computador 2 a 3 vezes mais lento, o QA estima uma pausa de 1 a 2 s uma ou duas vezes por dia de jogo, só em 50x.
- **A memória cresce com o mundo:** cerca de 110 MB no Gerenciador de Tarefas num mundo novo e de 170 a 180 MB depois de 150 a 200 anos.
- **A tarde (das 12h às 15h30 do jogo) é o período mais parado do dia.**
- **O relógio do Windows conta como tempo fora.** Se o relógio pular para a frente, o mundo avança junto, até o teto de 1 ano de jogo.
- **Testado sobretudo por máquinas.** Quase todos os testes foram automáticos ou feitos por sessões de IA jogando o jogo, inclusive no próprio executável. Esta é a primeira versão nas mãos de pessoas, então os seus relatos ajudam muito.

## Como relatar um erro

Abra uma [issue](https://github.com/agentevsagente-debug/SimuladorVida/issues) com:
1. **a versão:** passe o cursor sobre o relógio, no canto da alça (deve dizer "Simulador de vida 0.1.1");
2. **o que você fez logo antes** do erro;
3. **o arquivo de registro** `godot.log`, anexado. Ele fica em:
   ```
   %APPDATA%\Simulador de vida\logs\godot.log
   ```
   Cole esse caminho na barra de endereço do Explorador de Arquivos.

Se o problema for com o mundo salvo, anexe também o `mundo.txt` da pasta `%APPDATA%\Simulador de vida`.
