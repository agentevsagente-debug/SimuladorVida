# Verifica a moldura no Windows: estilo da janela, transparência, mouse
# atravessando, cliques, arraste, troca de escala, nitidez e esconder/mostrar.
# Move o cursor por instantes e devolve ele ao lugar. Leva cerca de 1 minuto.
param(
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe",
    [int]$X = 200,
    [int]$Y = 200
)
$ErrorActionPreference = 'Stop'
$projeto = Split-Path $PSScriptRoot -Parent
$saida = Join-Path $projeto 'capturas'
New-Item -ItemType Directory -Force $saida | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'Win32.cs') -ReferencedAssemblies System.Drawing
[Win32]::SetProcessDPIAware() | Out-Null

$resultados = [ordered]@{}
function Registrar($nome, $ok, $detalhe) {
    $resultados[$nome] = [pscustomobject]@{ ok = $ok; detalhe = $detalhe }
    '{0,-28} {1,-5} {2}' -f $nome, $(if ($ok) { 'OK' } else { 'FALHA' }), $detalhe
}

function Iniciar-Moldura([int]$escala, [string]$log) {
    if (Test-Path $log) { Remove-Item $log }
    $p = Start-Process -FilePath $Godot -PassThru -ArgumentList @(
        '--path', "`"$projeto`"", '--log-file', "`"$log`"", '--',
        "--pos=$X,$Y", "--escala=$escala", '--duracao=90')
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
$fundo = [Win32]::Capturar($X, $Y, 960, 352)

# 2. Moldura em 2x por cima.
$log = Join-Path $env:TEMP 'moldura-verificacao.log'
$g = Iniciar-Moldura 2 $log
$h = $g.MainWindowHandle
$ex = [Win32]::GetWindowLong($h, -20)
Registrar 'sempre por cima' (($ex -band 0x8) -ne 0) ('WS_EX = 0x{0:X8} (TOPMOST=0x8, LAYERED=0x80000, TRANSPARENT=0x20)' -f $ex)

$k = 2
$pontoFaixa = @(($X + 300 * $k), ($Y + 8 * $k))
$pontoAlca = @(($X + 20 * $k), ($Y + 7 * $k))
$pontoCeu = @(($X + 240 * $k), ($Y + 60 * $k))
$pontoChao = @(($X + 240 * $k), ($Y + 170 * $k))
$hFaixa = [Win32]::RaizEm($pontoFaixa[0], $pontoFaixa[1])
Registrar 'faixa: janela de tras' ($hFaixa -ne $h) ("WindowFromPoint -> '{0}'" -f [Win32]::Titulo($hFaixa))
Registrar 'alca: moldura' ([Win32]::RaizEm($pontoAlca[0], $pontoAlca[1]) -eq $h) ''
Registrar 'mundo: moldura' ([Win32]::RaizEm($pontoCeu[0], $pontoCeu[1]) -eq $h) ''

$com = [Win32]::Capturar($X, $Y, 960, 352)
$com.Save((Join-Path $saida 'escala2.png'))
$transp = [Win32]::Iguais($fundo, $com, 90 * $k, 0, 390 * $k, 16 * $k)
$mundoDif = 1 - [Win32]::Iguais($fundo, $com, 0, 16 * $k, 480 * $k, 160 * $k)
Registrar 'transparencia da faixa' ($transp -gt 0.999) ('{0:P2} dos pixels iguais ao fundo' -f $transp)
Registrar 'mundo opaco' ($mundoDif -gt 0.99) ('{0:P2} dos pixels diferentes do fundo' -f $mundoDif)
$nitidez = [Win32]::BlocosUniformes($com, 0, 16 * $k, 480 * $k, 160 * $k, $k)
Registrar 'nitidez 2x' ($nitidez -gt 0.999) ('{0:P2} dos blocos 2x2 de cor unica' -f $nitidez)

# 3. Cliques: um na faixa transparente (deve chegar ao alvo) e um no céu (chuva).
[Win32]::Clicar($pontoFaixa[0], $pontoFaixa[1])
Start-Sleep -Milliseconds 500
$n = [int](Get-Content $cliques)
Registrar 'clique atravessa' ($n -eq 1) "cliques recebidos pelo alvo: $n"
[Win32]::Clicar($pontoCeu[0], $pontoCeu[1])
Start-Sleep -Milliseconds 800
$chuva = [Win32]::Capturar($X, $Y, 960, 352)
$chuva.Save((Join-Path $saida 'chuva.png'))
[Win32]::Clicar($pontoChao[0], $pontoChao[1])
Start-Sleep -Milliseconds 300
$n2 = [int](Get-Content $cliques)
Registrar 'clique no mundo fica' ($n2 -eq 1) "alvo continua com $n2 clique(s)"

# 4. Arrastar pela alça.
Start-Sleep -Seconds 1
$antes = Retangulo $h
[Win32]::Arrastar($pontoAlca[0], $pontoAlca[1], 120, 60)
Start-Sleep -Milliseconds 500
$depois = Retangulo $h
$dx = $depois.Left - $antes.Left; $dy = $depois.Top - $antes.Top
Registrar 'arrastar' ($dx -eq 120 -and $dy -eq 60) "deslocou ($dx, $dy), esperado (120, 60)"

# 5. Botão "+" (2x -> 3x).
$bx = $depois.Left + 65 * $k; $by = $depois.Top + 7 * $k
[Win32]::Clicar($bx, $by)
Start-Sleep -Milliseconds 800
$r3 = Retangulo $h
Registrar 'botao + (3x)' ((($r3.Right - $r3.Left) -eq 1440) -and (($r3.Bottom - $r3.Top) -eq 528)) ("janela {0}x{1}" -f ($r3.Right - $r3.Left), ($r3.Bottom - $r3.Top))
$hFaixa3 = [Win32]::RaizEm($r3.Left + 300 * 3, $r3.Top + 8 * 3)
Registrar 'passagem refeita em 3x' ($hFaixa3 -ne $h) ''

# 6. Esconder pelo botão.
[Win32]::Clicar($r3.Left + 79 * 3, $r3.Top + 7 * 3)
Start-Sleep -Milliseconds 800
$escondida = (-not [Win32]::IsWindowVisible($h)) -or [Win32]::IsIconic($h)
$hMeio = [Win32]::RaizEm($r3.Left + 240 * 3, $r3.Top + 100 * 3)
Registrar 'esconder (botao)' ($escondida -and $hMeio -ne $h) ("minimizada={0}; no meio do mundo agora: '{1}'" -f [Win32]::IsIconic($h), [Win32]::Titulo($hMeio))
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
    $img = [Win32]::Capturar($r.Left, $r.Top, 480 * $e, 176 * $e)
    $img.Save((Join-Path $saida "escala$e.png"))
    $nit = [Win32]::BlocosUniformes($img, 0, 16 * $e, 480 * $e, 160 * $e, $e)
    Registrar "nitidez ${e}x" ($nit -gt 0.999) ('{0:P2} dos blocos {1}x{1} de cor unica' -f $nit, $e)
    Stop-Process -Id $g.Id -ErrorAction SilentlyContinue
}

Stop-Process -Id $alvo.Id -ErrorAction SilentlyContinue
$resultados | ConvertTo-Json | Set-Content (Join-Path $saida 'verificacao.json') -Encoding utf8
