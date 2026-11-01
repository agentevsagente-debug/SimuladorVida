# A passada do B1 no jogo exportado, além do que o verificar.ps1 -Executavel cobre:
#   1. Ctrl+Alt+H esconde e traz de volta (o atalho global, processo à parte);
#   2. fechar pelo X da janela (WM_CLOSE): sai limpo, com as threads encerradas;
#   3. a janela fica por cima dos outros programas por -Minutos (padrão 60),
#      conferida a cada minuto: visível, sempre por cima, sem erro no registro.
# Aperta teclas só no item 1. Usa --mundo-novo: não grava nada na pasta do jogador.
param(
    [string]$Exe = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'builds\Simulador de vida.exe'),
    [int]$Minutos = 60,
    [int]$X = 200,
    [int]$Y = 200
)
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Win32.cs') -ReferencedAssemblies System.Drawing
[Win32]::SetProcessDPIAware() | Out-Null
$resultados = [ordered]@{}
function Registrar($nome, $ok, $detalhe) {
    $resultados[$nome] = [pscustomobject]@{ ok = $ok; detalhe = $detalhe }
    '{0,-28} {1,-5} {2}' -f $nome, $(if ($ok) { 'OK' } else { 'FALHA' }), $detalhe
}
function Abrir([string]$log, [string[]]$extra) {
    if (Test-Path $log) { Remove-Item $log }
    $p = Start-Process -FilePath $Exe -PassThru -ArgumentList (@('--log-file', "`"$log`"", '--',
        "--pos=$X,$Y", '--escala=2', '--sem-config', '--mundo-novo') + $extra)
    for ($i = 0; $i -lt 50 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 200; $p.Refresh() }
    Start-Sleep -Seconds 3
    $p.Refresh()
    return $p
}
function Visivel($h) { [Win32]::IsWindowVisible($h) -and -not [Win32]::IsIconic($h) }
function Erros($log) { @(Select-String -Path $log -Pattern 'ERROR|SCRIPT ERROR|CrashHandler|signal 11').Count }

# 1. Ctrl+Alt+H
$log = Join-Path $env:TEMP 'b1-atalho.log'
$p = Abrir $log @('--atalho-global', '--duracao=60')
$h = $p.MainWindowHandle
Start-Sleep -Seconds 2   # o processo do atalho registra a tecla
[Win32]::Teclas(0x11, 0x12, 0x48)
Start-Sleep -Milliseconds 1200
$escondeu = -not (Visivel $h)
[Win32]::Teclas(0x11, 0x12, 0x48)
Start-Sleep -Milliseconds 1200
$voltou = Visivel $h
Registrar 'Ctrl+Alt+H esconde' $escondeu ''
Registrar 'Ctrl+Alt+H traz de volta' $voltou ''
Stop-Process -Id $p.Id -ErrorAction SilentlyContinue

# 2. Fechar pelo X (WM_CLOSE = 0x10), três vezes
$limpos = 0
for ($k = 0; $k -lt 3; $k++) {
    $log = Join-Path $env:TEMP "b1-fechar-$k.log"
    $p = Abrir $log @('--atalho-global', '--duracao=120')
    Start-Sleep -Seconds 4
    [Win32]::PostMessage($p.MainWindowHandle, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    $saiu = $p.WaitForExit(15000)
    $p.Refresh()
    $atalhos = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*atalho_global*' }).Count
    if ($saiu -and $p.ExitCode -eq 0 -and (Select-String -Path $log -Pattern 'threads encerradas' -Quiet) -and (Erros $log) -eq 0 -and $atalhos -eq 0) { $limpos++ }
}
Registrar 'fechar pelo X' ($limpos -eq 3) "$limpos de 3 limpos (saída 0, threads encerradas, sem erro, sem atalho órfão)"

# 3. Por cima por $Minutos
$log = Join-Path $env:TEMP 'b1-hora.log'
$p = Abrir $log @('--atalho-global', "--duracao=$($Minutos * 60 + 30)")
$h = $p.MainWindowHandle
$falhas = @()
for ($m = 1; $m -le $Minutos; $m++) {
    Start-Sleep -Seconds 60
    $ex = [Win32]::GetWindowLong($h, -20)
    $ok = (-not $p.HasExited) -and (Visivel $h) -and (($ex -band 0x8) -ne 0)
    $p.Refresh()
    if (-not $ok) { $falhas += "min $m" }
    '{0,3} min  visível={1} topmost={2} memória={3:N0} MB' -f $m, (Visivel $h), (($ex -band 0x8) -ne 0), ($p.PrivateMemorySize64 / 1MB)
}
$erros = Erros $log
Registrar "por cima $Minutos min" ($falhas.Count -eq 0 -and $erros -eq 0) ("falhas: {0}; {1} erros no log" -f ($falhas -join ', '), $erros)
[Win32]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
$p.WaitForExit(15000) | Out-Null
$resultados | ConvertTo-Json | Set-Content (Join-Path (Split-Path $PSScriptRoot -Parent) 'capturas\b1.json') -Encoding utf8
