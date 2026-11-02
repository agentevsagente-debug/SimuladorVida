# Verifica a moldura do jogo no Windows: estilo da janela, transparência, mouse
# atravessando, cliques, arraste, troca de escala, nitidez e esconder/mostrar.
# Move o cursor por instantes e devolve ele ao lugar. Leva cerca de 1 minuto,
# mais 1 a 2 minutos do item 8 (exportar e abrir o executável).
param(
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe",
    [int]$X = 200,
    [int]$Y = 200,
    [switch]$SemExportar,  # pula o item 8 (gerar e abrir o executável)
    [switch]$Executavel    # $Godot é o jogo exportado (builds\Simulador de vida.exe): sem --path
)
$ErrorActionPreference = 'Stop'
$projeto = Split-Path $PSScriptRoot -Parent
$saida = Join-Path $projeto 'capturas'
New-Item -ItemType Directory -Force $saida | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'Win32.cs') -ReferencedAssemblies System.Drawing
[Win32]::SetProcessDPIAware() | Out-Null

$resultados = [ordered]@{}
# Um passo que não deu certo com interferência no meio (o cursor fora do ponto, ou
# outra janela tomou o foco: Win32.Interferencias) sai como INTERFERENCIA, e não FALHA:
# não diz nada do jogo. Rode de novo com o computador parado.
$script:interfAntes = 0
function Registrar($nome, $ok, $detalhe) {
    $interf = (-not $ok) -and ([Win32]::Interferencias -gt $script:interfAntes)
    $script:interfAntes = [Win32]::Interferencias
    $resultados[$nome] = [pscustomobject]@{ ok = $ok; interferencia = $interf; detalhe = $detalhe }
    '{0,-28} {1,-5} {2}' -f $nome, $(if ($ok) { 'OK' } elseif ($interf) { 'INTERFERENCIA' } else { 'FALHA' }), $detalhe
}

function Iniciar-Moldura([int]$escala, [string]$log) {
    if (Test-Path $log) { Remove-Item $log }
    $caminho = if ($Executavel) { @() } else { @('--path', "`"$projeto`"") }
    $p = Start-Process -FilePath $Godot -PassThru -ArgumentList (@($caminho) + @('--log-file', "`"$log`"", '--',
        "--pos=$X,$Y", "--escala=$escala", '--duracao=90', '--sem-config', '--mundo-novo', '--com-povo'))
    for ($i = 0; $i -lt 50 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 200; $p.Refresh() }
    Start-Sleep -Seconds 2
    $p.Refresh()
    return $p
}

function Retangulo($h) { $r = New-Object Win32+RECT; [Win32]::GetWindowRect($h, [ref]$r) | Out-Null; $r }

# 1. Janela-alvo atrás e captura do fundo sem a moldura.
$cliques = Join-Path $env:TEMP 'moldura-cliques.txt'
$alvo = Start-Process powershell -PassThru -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSScriptRoot\alvo.ps1`"",
    '-X', $X, '-Y', $Y, '-Arquivo', "`"$cliques`"", '-Segundos', 150)
Start-Sleep -Seconds 3
$fundo = [Win32]::Capturar($X, $Y, 960, 356)

# 2. Moldura em 2x por cima.
$log = Join-Path $env:TEMP 'moldura-verificacao.log'
$g = Iniciar-Moldura 2 $log
$h = $g.MainWindowHandle
[Win32]::Nossas.Add($h) | Out-Null
$alvo.Refresh()
if ($alvo.MainWindowHandle -ne 0) { [Win32]::Nossas.Add($alvo.MainWindowHandle) | Out-Null }
$ex = [Win32]::GetWindowLong($h, -20)
Registrar 'sempre por cima' (($ex -band 0x8) -ne 0) ('WS_EX = 0x{0:X8} (TOPMOST=0x8, LAYERED=0x80000, TRANSPARENT=0x20)' -f $ex)

$k = 2
$faixa = 18
$pontoFaixa = @(($X + 300 * $k), ($Y + 8 * $k))
$pontoAlca = @(($X + 5 * $k), ($Y + 9 * $k))
$pontoCeu = @(($X + 240 * $k), ($Y + 60 * $k))
$pontoChao = @(($X + 240 * $k), ($Y + 170 * $k))
$hFaixa = [Win32]::RaizEm($pontoFaixa[0], $pontoFaixa[1])
Registrar 'faixa: janela de tras' ($hFaixa -ne $h) ("WindowFromPoint -> '{0}'" -f [Win32]::Titulo($hFaixa))
Registrar 'alca: moldura' ([Win32]::RaizEm($pontoAlca[0], $pontoAlca[1]) -eq $h) ''
Registrar 'mundo: moldura' ([Win32]::RaizEm($pontoCeu[0], $pontoCeu[1]) -eq $h) ''

$com = [Win32]::Capturar($X, $Y, 960, 356)
$com.Save((Join-Path $saida 'escala2.png'))
# a faixa entre a alça e o relógio (438 em diante) é transparente
$transp = [Win32]::Iguais($fundo, $com, 190 * $k, 0, 240 * $k, $faixa * $k)
$mundoDif = 1 - [Win32]::Iguais($fundo, $com, 0, $faixa * $k, 480 * $k, 160 * $k)
Registrar 'transparencia da faixa' ($transp -gt 0.999) ('{0:P2} dos pixels iguais ao fundo' -f $transp)
Registrar 'mundo opaco' ($mundoDif -gt 0.99) ('{0:P2} dos pixels diferentes do fundo' -f $mundoDif)
$nitidez = [Win32]::BlocosUniformes($com, 0, $faixa * $k, 480 * $k, 160 * $k, $k)
Registrar 'nitidez 2x' ($nitidez -gt 0.999) ('{0:P2} dos blocos 2x2 de cor unica' -f $nitidez)

# 3. Cliques: um na faixa transparente (deve chegar ao alvo) e um no céu (chuva).
# O primeiro clique sintético numa janela que acabou de perder o foco às vezes
# se perde no Windows (aconteceu também com a janela-alvo, que não é o jogo).
# Por isso cada clique é tentado de novo uma vez, e o relatório diz quantas.
$tentativas = 1
[Win32]::Clicar($pontoFaixa[0], $pontoFaixa[1])
Start-Sleep -Milliseconds 500
if ([int](Get-Content $cliques) -eq 0) { $tentativas++; [Win32]::Clicar($pontoFaixa[0], $pontoFaixa[1]); Start-Sleep -Milliseconds 500 }
$n = [int](Get-Content $cliques)
Registrar 'clique atravessa' ($n -eq 1) "cliques recebidos pelo alvo: $n (tentativas: $tentativas)"
$tentativas = 1
[Win32]::Clicar($pontoCeu[0], $pontoCeu[1])
Start-Sleep -Milliseconds 800
if (-not (Select-String -Path $log -Pattern 'clique no mundo' -Quiet)) { $tentativas++; [Win32]::Clicar($pontoCeu[0], $pontoCeu[1]); Start-Sleep -Milliseconds 800 }
$cliqueMundo = Select-String -Path $log -Pattern 'clique no mundo' -Quiet
Registrar 'clique chega ao mundo' ([bool]$cliqueMundo) "registrado no log da moldura (tentativas: $tentativas)"
[Win32]::Clicar($pontoChao[0], $pontoChao[1])
Start-Sleep -Milliseconds 300
$n2 = [int](Get-Content $cliques)
Registrar 'clique no mundo fica' ($n2 -eq 1) "alvo continua com $n2 clique(s)"

# Cada passo com o mouse confere o próprio efeito (no registro ou na janela) e tenta
# de novo, até 3 vezes: o clique sintético às vezes se perde (o foco acabou de mudar,
# ou o cursor de verdade se mexeu entre o posicionar e o clicar). E cada passo deixa a
# alça como a encontrou (poderes fechados, nenhum poder escolhido), para que uma falha
# não mude a posição dos botões do passo seguinte e derrube os outros em cascata.
function Linhas([string]$padrao) { @(Select-String -Path $log -Pattern $padrao).Count }
function Tentar([scriptblock]$acao, [scriptblock]$feito, [int]$espera = 800) {
    for ($i = 1; $i -le 3; $i++) {
        & $acao
        Start-Sleep -Milliseconds $espera
        if (& $feito) { return $i }
    }
    return 0
}

# 3b. O gesto de um poder, com o mouse de verdade: abre os poderes na alça,
# escolhe o raio (2º botão da fileira aberta), segura 1,5 s sobre o céu e solta.
$abertos = Linhas 'alca largura=354'
$t1 = Tentar { [Win32]::Clicar($X + 18 * $k, $Y + 9 * $k) } { (Linhas 'alca largura=354') -gt $abertos }
$t2 = Tentar { [Win32]::Clicar($X + (10 + 17 + 8) * $k, $Y + 9 * $k) } { (Linhas 'poder escolhido: raio') -gt 0 }
$t3 = Tentar { [Win32]::Segurar($X + 300 * $k, $Y + 70 * $k, 1500) } { (Linhas 'poder raio em x=[0-9]+ intensidade=0\.(6|7|8)') -gt 0 } 600
$gesto = Select-String -Path $log -Pattern 'poder raio em x=[0-9]+ intensidade=0\.(6|7|8)' | Select-Object -First 1
Registrar 'gesto do poder (raio)' ([bool]$gesto) $(if ($gesto) { "$($gesto.Line) (tentativas: $t1, $t2, $t3)" } else { "nada no log (tentativas: $t1, $t2, $t3)" })
# larga o raio (botão direito no mundo): a alça volta ao normal para os passos seguintes
$largados = Linhas 'poder escolhido: nenhum'
Tentar { [Win32]::ClicarDireito($pontoCeu[0], $pontoCeu[1]) } { (Linhas 'poder escolhido: nenhum') -gt $largados } | Out-Null

# 4. Arrastar pela alça: cada tentativa mede de onde a janela partiu.
Start-Sleep -Seconds 1
$dx = 0; $dy = 0; $t4 = 0
for ($i = 1; $i -le 3 -and $t4 -eq 0; $i++) {
    $antes = Retangulo $h
    [Win32]::Arrastar($antes.Left + 5 * $k, $antes.Top + 9 * $k, 120, 60)
    Start-Sleep -Milliseconds 500
    $depois = Retangulo $h
    $dx = $depois.Left - $antes.Left; $dy = $depois.Top - $antes.Top
    # o arraste nativo pode pegar o cursor 1 px depois do clique sintético
    if ([math]::Abs($dx - 120) -le 2 -and [math]::Abs($dy - 60) -le 2) { $t4 = $i }
}
Registrar 'arrastar' ($t4 -gt 0) "deslocou ($dx, $dy), esperado (120, 60) +- 2 px (tentativas: $(if ($t4) { $t4 } else { 3 }))"

# 5. Roda do mouse sobre a alça (2x -> 3x).
$t5 = Tentar { $d = Retangulo $h; [Win32]::Rolar($d.Left + 5 * $k, $d.Top + 9 * $k, 1) } { $r = Retangulo $h; ($r.Right - $r.Left) -eq 1440 }
$r3 = Retangulo $h
Registrar 'roda na alca (3x)' ((($r3.Right - $r3.Left) -eq 1440) -and (($r3.Bottom - $r3.Top) -eq 534)) ("janela {0}x{1} (tentativas: {2})" -f ($r3.Right - $r3.Left), ($r3.Bottom - $r3.Top), $t5)
$hFaixa3 = [Win32]::RaizEm($r3.Left + 300 * 3, $r3.Top + 8 * 3)
Registrar 'passagem refeita em 3x' ($hFaixa3 -ne $h) ''

# 6. Esconder pelo botão (o décimo da alça: poderes, 5 ritmos, crônica, estante, linhagem, esconder).
$t6 = Tentar { [Win32]::Clicar($r3.Left + 171 * 3, $r3.Top + 9 * 3) } { (-not [Win32]::IsWindowVisible($h)) -or [Win32]::IsIconic($h) }
$escondida = (-not [Win32]::IsWindowVisible($h)) -or [Win32]::IsIconic($h)
$hMeio = [Win32]::RaizEm($r3.Left + 240 * 3, $r3.Top + 100 * 3)
Registrar 'esconder (botao)' ($escondida -and $hMeio -ne $h) ("minimizada={0}; no meio do mundo agora: '{1}' (tentativas: {2})" -f [Win32]::IsIconic($h), [Win32]::Titulo($hMeio), $t6)
# Mostrar de novo. O ícone da bandeja vai para o menu de ícones ocultos ("^")
# no Windows 11, em posição variável, então aqui o teste usa o botão da barra
# de tarefas (ShowWindow SW_RESTORE). O clique no ícone foi testado à mão.
[Win32]::ShowWindow($h, 9) | Out-Null
Start-Sleep -Milliseconds 1500
$r4 = Retangulo $h
$ok = [Win32]::IsWindowVisible($h) -and -not [Win32]::IsIconic($h) -and $r4.Left -eq $r3.Left -and $r4.Top -eq $r3.Top -and ($r4.Right - $r4.Left) -eq 1440
Registrar 'mostrar (barra tarefas)' $ok ("janela de volta em ({0}, {1}) {2}x{3}" -f $r4.Left, $r4.Top, ($r4.Right - $r4.Left), ($r4.Bottom - $r4.Top))
Registrar 'passagem apos mostrar' ([Win32]::RaizEm($r4.Left + 300 * 3, $r4.Top + 8 * 3) -ne $h) ''
Stop-Process -Id $g.Id -ErrorAction SilentlyContinue
Copy-Item $log (Join-Path $saida 'verificacao.log')

# 7. Nitidez em 3x e 4x.
foreach ($e in 3, 4) {
    $g = Iniciar-Moldura $e (Join-Path $env:TEMP "moldura-$e.log")
    $r = Retangulo $g.MainWindowHandle
    $img = [Win32]::Capturar($r.Left, $r.Top, 480 * $e, 178 * $e)
    $img.Save((Join-Path $saida "escala$e.png"))
    $nit = [Win32]::BlocosUniformes($img, 0, $faixa * $e, 480 * $e, 160 * $e, $e)
    Registrar "nitidez ${e}x" ($nit -gt 0.999) ('{0:P2} dos blocos {1}x{1} de cor unica' -f $nit, $e)
    Stop-Process -Id $g.Id -ErrorAction SilentlyContinue
}

Stop-Process -Id $alvo.Id -ErrorAction SilentlyContinue

# 8. O executável: exporta com o preset "Windows" (modelos de exportação instalados) e
# abre por 15 s. A exportação reimporta e troca as quebras de linha dos .import; as que
# só mudaram nisso voltam ao que está no git.
if (-not $SemExportar) {
    $console = $Godot -replace '\.exe$', '_console.exe'
    $exe = Join-Path (Split-Path $projeto -Parent) 'builds\Simulador de vida.exe'
    $antes = if (Test-Path $exe) { (Get-Item $exe).LastWriteTime } else { [datetime]::MinValue }
    New-Item -ItemType Directory -Force (Split-Path $exe -Parent) | Out-Null
    $ErrorActionPreference = 'Continue'  # o Godot escreve avisos na saída de erro
    & $console --headless --path $projeto --export-release 'Windows' 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
    $novo = (Test-Path $exe) -and (Get-Item $exe).LastWriteTime -gt $antes
    Registrar 'exportar' $novo $(if ($novo) { '{0:N0} MB' -f ((Get-Item $exe).Length / 1MB) } else { 'sem executável novo' })
    foreach ($f in (git -C $projeto diff --name-only -- '*.import')) {
        git -C $projeto diff --ignore-cr-at-eol --quiet -- $f
        if ($LASTEXITCODE -eq 0) { git -C $projeto checkout -- $f }
    }
    if ($novo) {
        $logx = Join-Path $env:TEMP 'moldura-exe.log'
        if (Test-Path $logx) { Remove-Item $logx }
        $p = Start-Process -FilePath $exe -PassThru -ArgumentList @('--log-file', "`"$logx`"", '--',
            "--pos=$X,$Y", '--escala=2', '--duracao=15', '--sem-config', '--mundo-novo', '--com-povo')
        for ($i = 0; $i -lt 50 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 200; $p.Refresh() }
        Start-Sleep -Seconds 3
        $h = $p.MainWindowHandle
        $r = Retangulo $h
        $janela = $h -ne 0 -and ($r.Right - $r.Left) -eq 960
        $passa = $janela -and ([Win32]::RaizEm($r.Left + 300 * 2, $r.Top + 8 * 2) -ne $h)
        Registrar 'executavel abre' $janela ('{0}x{1}' -f ($r.Right - $r.Left), ($r.Bottom - $r.Top))
        Registrar 'executavel passagem' $passa ''
        $p.WaitForExit(20000) | Out-Null
        $erros = if (Test-Path $logx) { @(Select-String -Path $logx -Pattern 'ERROR|SCRIPT ERROR').Count } else { -1 }
        Registrar 'executavel sem erros' ($erros -eq 0) "$erros erros no log"
        Stop-Process -Id $p.Id -ErrorAction SilentlyContinue
    }
}

$resultados | ConvertTo-Json | Set-Content (Join-Path $saida 'verificacao.json') -Encoding utf8
