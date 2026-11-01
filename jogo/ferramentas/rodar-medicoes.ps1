# Roda os quatro cenários de 10 minutos em sequência.
foreach ($c in 'normal', 'rapido', 'escondido', 'avancado') {
    # o mundo de 150 anos leva um tempo para ser gerado antes de abrir
    $aquecer = if ($c -eq 'avancado') { 150 } else { 10 }
    & (Join-Path $PSScriptRoot 'medir.ps1') -Cenario $c -Segundos 600 -Aquecimento $aquecer | Format-List
}
