# Roda os três cenários de 10 minutos em sequência.
foreach ($c in 'parado', 'andando', 'escondido') {
    & (Join-Path $PSScriptRoot 'medir.ps1') -Cenario $c -Segundos 600 | Format-List
}
