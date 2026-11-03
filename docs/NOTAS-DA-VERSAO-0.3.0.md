# Simulador de vida 0.3.0

*Texto pronto para a página da Release no GitHub. Copie a partir da linha abaixo.*

---

**Ouça o que o povo pede.** A 0.3.0 traz a caixa de preces e um termômetro de fé por povo. A crônica passa a contar quem nasceu, quem casou e quem morreu.

Gratuito, para Windows, sem instalador e sem internet. Código aberto, sob a [licença MIT](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/LICENSE). O guia completo está em [Como jogar](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-jogar.md).

## Baixar e jogar

1. Baixe o `Simulador.de.vida.exe` aqui embaixo, em **Assets**, e rode. Não há instalador.
2. O Windows pode mostrar "O Windows protegeu o computador", porque o jogo não tem assinatura digital. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. O mundo começa vazio. Clique sobre ele para fazer nascer o primeiro povo.

Quem já joga uma versão anterior pode só trocar o `.exe`: o mundo salvo continua.

**Requisitos:** Windows 10 ou 11, 64 bits.

## O que mudou desde a 0.2.1

- **A caixa de preces:**
  - abre com um botão novo na alça, ao lado da lupa, ou com a tecla **P**;
  - mostra o que o povo pede ao deus, das preces mais novas para as mais antigas: quem pediu, de que povo, quando e com que palavras;
  - mostra o que aconteceu com cada pedido: **esperando**, **atendida**, **sem resposta** ou **"atendida, mas não por você"**, quando a ajuda veio por acaso e o povo achou que foi o deus;
  - clicar numa prece leva a vista até quem rezou;
  - um ponto no botão avisa quando chega prece nova.
  - Povos que não rezam continuam fora da caixa: os problemas deles chegam tarde.
- **O termômetro de fé, por povo:** sem número: quanto mais cheio, mais fé. Uma setinha diz se a fé está subindo ou caindo e some quando ela está parada. Aparece no topo da caixa e ao passar o cursor sobre a vila ou, de noite, sobre as tendas. A fé continua sendo de cada pessoa.
- **A vida do povo na crônica:**
  - num povo pequeno, cada nascimento, casamento e morte entra com o nome, mesmo num ano cheio de milagres. As mortes contam a idade aproximada e a causa;
  - num povo grande, a crônica dá a conta do ano, como "nasceram seis crianças e morreram quatro", e cita por nome só os casos marcantes;
  - o primeiro filho do povo já aparece no ano em curso, e não só quando o ano fecha.

## Problemas conhecidos

- **O aviso do SmartScreen.** O jogo não tem assinatura digital. Veja acima como abrir.
- **Só Windows 10 e 11, 64 bits, e só em português.**
- **O ícone perto do relógio pode estar escondido** na setinha "^" do Windows 11. Para trazer a janela de volta, use também o **Ctrl+Alt+H** ou o jogo na barra de tarefas.
- **O Ctrl+Alt+H pode já estar em uso** por outro programa. Nesse caso, use o ícone ou a barra de tarefas.
- **A crônica de mundos longos ficou maior,** porque agora conta a vida do povo. Num mundo de 250 anos, o livro passou de cerca de 48 mil para cerca de 89 mil caracteres.
- **O termômetro de um mundo salvo antes da 0.3.0** começa sem setinha. A tendência aparece depois de cerca de um ano de jogo.
- **Testado sobretudo por máquinas.** Quase todos os testes foram automáticos ou feitos por sessões de IA jogando o jogo, inclusive no próprio executável. Os seus relatos ajudam muito.

## Como relatar um erro

Abra uma [issue](https://github.com/agentevsagente-debug/SimuladorVida/issues) com:
1. **a versão:** passe o cursor sobre o relógio, no canto da alça (deve dizer "Simulador de vida 0.3.0");
2. **o que você fez logo antes** do erro;
3. **o arquivo de registro** `godot.log`, anexado. Ele fica em:
   ```
   %APPDATA%\Simulador de vida\logs\godot.log
   ```
   Cole esse caminho na barra de endereço do Explorador de Arquivos.

Se o problema for com o mundo salvo, anexe também o `mundo.txt` da pasta `%APPDATA%\Simulador de vida`.
