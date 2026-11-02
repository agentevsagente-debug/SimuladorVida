"""Os laços de ambiente (20 a 40 s, sem emenda): vento, pássaros, lago, grilos, fogo, chuva,
tempestade, neve e o murmúrio da vila. Tudo periódico no comprimento do laço (veja sintese.py).

Cada função recebe o gerador de números ao acaso e devolve o laço já nivelado; NIVEL dá o RMS
de cada um (em dBFS), para que todos soem equilibrados com o mesmo volume no jogo.
"""
import numpy as np

from sintese import (SR, VOGAIS, banda, colocar, eco_circular, env, fase, lfo, nivelar, passa,
                     passa_circular, resposta, ruido_moldado, suaviza, tempo, voz)

# o RMS (dBFS) de cada laço: o fundo fica baixo; a chuva e a tempestade, que cobrem tudo, um
# pouco acima; a neve e os grilos, os mais quietos
NIVEL = {"vento": -30, "passaros": -31, "lago": -30, "grilos": -33, "fogo": -30, "chuva": -28,
         "tempestade": -25, "neve": -34, "vila": -31, "festa": -29}


def vento(rng, dur=32.0):
    """Vento leve: ruído rosa grave e médio em rajadas lentas, com um assobio fraco que vem e vai."""
    n = int(dur * SR)
    grave = ruido_moldado(n, rng, banda(80, 500, -3))
    medio = ruido_moldado(n, rng, banda(300, 1200, -3))
    assobio = ruido_moldado(n, rng, banda(650, 900, 0, suave=4))
    rajada = lfo(n, rng, (1, 2, 3, 4, 7), 0.75)
    x = grave * (0.5 + 0.5 * rajada) + 0.6 * medio * rajada ** 2 + 0.12 * assobio * lfo(n, rng, (2, 3, 5), 1.0) ** 3
    return x


def _canto(rng, especie):
    """Um canto de pássaro curto, em seno puro com a altura mudando depressa."""
    if especie == "trinado":  # notas rápidas que descem
        notas = []
        f = rng.uniform(3200, 4200)
        for k in range(rng.integers(5, 10)):
            t = tempo(0.045)
            fr = f * (1.0 + 0.15 * np.sin(np.pi * t / t[-1]))
            notas.append(np.sin(fase(fr)) * np.sin(np.pi * t / t[-1]) ** 2)
            notas.append(np.zeros(int(0.02 * SR)))
            f *= 0.97
        return np.concatenate(notas)
    if especie == "assobio":  # duas notas limpas, a segunda mais grave (tipo sabiá)
        partes = []
        for f in (rng.uniform(2200, 2600), rng.uniform(1700, 2000)):
            t = tempo(rng.uniform(0.18, 0.28))
            fr = f * (1.0 + 0.03 * np.sin(2 * np.pi * 7 * t))
            partes += [np.sin(fase(fr)) * env(t.size, 0.03, t[-1] * 0.7, t[-1] * 0.3), np.zeros(int(0.08 * SR))]
        return np.concatenate(partes)
    if especie == "pio":  # um pio curto que sobe
        t = tempo(0.12)
        fr = np.linspace(2600, 3800, t.size)
        return np.sin(fase(fr)) * np.sin(np.pi * t / t[-1])
    # "gorjeio": uma frase de 4 a 7 notas soltas
    partes = []
    for k in range(rng.integers(4, 8)):
        t = tempo(rng.uniform(0.05, 0.11))
        f0, f1 = rng.uniform(2400, 4200, 2)
        fr = np.linspace(f0, f1, t.size)
        partes += [np.sin(fase(fr)) * np.abs(np.sin(np.pi * t / t[-1])) ** 1.5, np.zeros(int(rng.uniform(0.02, 0.07) * SR))]
    return np.concatenate(partes)


def passaros(rng, dur=36.0):
    """Pássaros da manhã e do dia: 4 espécies, perto e longe, sobre um ar quase parado."""
    n = int(dur * SR)
    x = 0.25 * ruido_moldado(n, rng, banda(100, 900, -3)) * lfo(n, rng, (1, 2, 3), 0.5)
    cantos = np.zeros(n)
    for especie, vezes, dist in (("gorjeio", 9, (0.4, 1.0)), ("assobio", 5, (0.5, 1.0)), ("trinado", 4, (0.3, 0.7)),
                                 ("pio", 12, (0.2, 0.6))):
        for k in range(vezes):
            c = _canto(rng, especie)
            longe = rng.uniform(*dist)
            c = passa(c, hi=2000 + 4000 * longe)  # os de longe, abafados
            colocar(cantos, c, rng.integers(0, n), longe * 0.5)
    cantos = eco_circular(cantos, resposta(rng, 1.2, 5000), 0.45)
    return x + 1.6 * cantos


def lago(rng, dur=30.0):
    """A água do lago: marolas lentas batendo na margem e gotas de vez em quando."""
    n = int(dur * SR)
    base = ruido_moldado(n, rng, banda(120, 1600, -3))
    # marolas: um pulso a cada 2,5 a 4 s, que sobe devagar e escorre
    onda = np.zeros(n)
    t = 0.0
    while t < dur:
        k = int(t * SR)
        m = int(rng.uniform(1.2, 2.0) * SR)
        e = env(m, rng.uniform(0.3, 0.6), m / SR * 0.8, 0.1) * rng.uniform(0.5, 1.0)
        colocar(onda, e, k)
        t += rng.uniform(1.8, 5.5)
    onda = suaviza(onda, 0.05)
    espuma = ruido_moldado(n, rng, banda(700, 3000, -2))
    x = base * (0.45 + 0.6 * onda) + 0.12 * espuma * onda ** 2
    for k in range(int(dur * 0.7)):  # gotas: um "plic" que sobe
        g = tempo(rng.uniform(0.04, 0.08))
        fr = np.linspace(rng.uniform(700, 1100), rng.uniform(1400, 2200), g.size)
        gota = np.sin(fase(fr)) * np.exp(-g / 0.02)
        colocar(x, gota, rng.integers(0, n), rng.uniform(0.2, 0.6))
    return eco_circular(x, resposta(rng, 0.6, 3000), 0.2)


def grilos(rng, dur=30.0):
    """Grilos à noite: vários, cada um no seu tom e no seu passo, uns perto e outros longe."""
    n = int(dur * SR)
    x = 0.2 * ruido_moldado(n, rng, banda(60, 400, -4)) * lfo(n, rng, (1, 2), 0.4)
    canto = np.zeros(n)
    for g in range(7):
        f = rng.uniform(3600, 4800)
        periodo = rng.uniform(0.55, 1.1)
        pulsos = int(rng.integers(2, 5))
        longe = rng.uniform(0.15, 1.0)
        # um chilreio: pulsos de 12 ms a 30 por segundo
        p = tempo(0.012)
        pulso = np.sin(2 * np.pi * f * p) * np.sin(np.pi * p / p[-1])
        chil = np.zeros(int(pulsos / 30 * SR) + p.size)
        for k in range(pulsos):
            colocar(chil, pulso, int(k / 30 * SR), circular=False)
        # o grilo canta em períodos: um trecho cantando, um calado (laço periódico)
        ativo = lfo(n, rng, (1, 2, 3), 1.0) > rng.uniform(0.2, 0.5)
        t = rng.uniform(0, periodo)
        while t < dur:
            k = int(t * SR)
            if ativo[k % n]:
                colocar(canto, chil * rng.uniform(0.8, 1.0), k, longe)
            t += periodo * rng.uniform(0.97, 1.03)
    canto = passa_circular(canto, banda(0, 5200, 0, suave=2))  # sem o chiado agudo
    canto = eco_circular(canto, resposta(rng, 1.0, 4000), 0.4)
    return x + 1.2 * canto


def _estalo(rng, curto=True):
    d = rng.uniform(0.003, 0.012) if curto else rng.uniform(0.02, 0.05)
    e = rng.standard_normal(int(d * SR) + 8) * np.exp(-np.arange(int(d * SR) + 8) / (d * SR / 3))
    return passa(e, rng.uniform(900, 1800), rng.uniform(3000, 6000))


def fogo(rng, dur=28.0):
    """Fogo crepitando: o rugido grave que tremula e estalos de vários tamanhos."""
    n = int(dur * SR)
    rugido = ruido_moldado(n, rng, banda(40, 400, -4))
    tremula = suaviza(np.abs(ruido_moldado(n, rng, banda(1, 6, 0))), 0.08)
    x = rugido * (0.4 + 0.6 * tremula / tremula.max())
    x += 0.15 * ruido_moldado(n, rng, banda(1500, 5000, -2)) * lfo(n, rng, (3, 5, 8), 0.8)  # chiado da lenha
    estalos = np.zeros(n)
    densidade = lfo(n, rng, (1, 2, 4), 0.7)
    for k in range(int(dur * 9)):
        p = rng.integers(0, n)
        if rng.uniform() < densidade[p]:
            colocar(estalos, _estalo(rng), p, rng.uniform(0.3, 1.0) ** 2 * 3)
    for k in range(int(dur * 0.4)):  # um estouro maior, de vez em quando
        colocar(estalos, _estalo(rng, False), rng.integers(0, n), rng.uniform(1.5, 3.0))
    return x + eco_circular(estalos, resposta(rng, 0.3, 4000), 0.2)


def chuva(rng, dur=30.0, forca=1.0):
    """Chuva: o chiado contínuo, o lavado grave e gotas batendo perto (folhas e telhado)."""
    n = int(dur * SR)
    chiado = ruido_moldado(n, rng, banda(500, 3000, -3, suave=3))
    lavado = ruido_moldado(n, rng, banda(100, 900, -3))
    x = (0.8 * chiado + 0.6 * lavado) * lfo(n, rng, (1, 2, 3), 0.25 * forca)
    gotas = np.zeros(n)
    for k in range(int(dur * 25 * forca)):
        d = int(rng.uniform(0.004, 0.015) * SR)
        g = rng.standard_normal(d) * np.exp(-np.arange(d) / (d / 4))
        g = passa(g, rng.uniform(1200, 2500), rng.uniform(3000, 5000))
        colocar(gotas, g, rng.integers(0, n), rng.uniform(0.1, 0.6) ** 2 * 3)
    return x + gotas


def tempestade(rng, dur=36.0):
    """Tempestade: a chuva forte com vento forte em rajadas e um rumor grave ao fundo
    (o trovão é um acontecimento à parte)."""
    n = int(dur * SR)
    c = chuva(rng, dur, 1.8)
    v = vento(rng, dur)
    rajada = lfo(n, rng, (1, 2, 3, 5), 1.0)
    uivo = ruido_moldado(n, rng, banda(250, 700, 0, suave=3)) * rajada ** 3
    rumor = ruido_moldado(n, rng, banda(25, 120, -3)) * lfo(n, rng, (1, 2), 0.6)
    return 0.9 * c + 1.2 * v * (0.4 + rajada) + 0.5 * uivo + 0.7 * rumor


def neve(rng, dur=30.0):
    """Neve abafada: quase silêncio, um vento grave e macio, e um chiado finíssimo de flocos."""
    n = int(dur * SR)
    grave = ruido_moldado(n, rng, banda(50, 260, -4))
    flocos = ruido_moldado(n, rng, banda(2000, 5000, 0, suave=2))
    rajada = lfo(n, rng, (1, 2, 3), 0.7)
    return grave * (0.3 + 0.7 * rajada) + 0.08 * flocos * lfo(n, rng, (2, 3, 5), 0.6)


def _fala(rng, grave):
    """Uma frase sem palavras: 3 a 8 sílabas, com o tom subindo e descendo."""
    silabas = []
    f0 = rng.uniform(95, 130) if grave else rng.uniform(170, 240)
    for k in range(rng.integers(3, 9)):
        d = rng.uniform(0.11, 0.24)
        n = int(d * SR)
        contorno = f0 * (1.0 + 0.12 * np.sin(np.linspace(0, np.pi, n)) * rng.uniform(-1, 1))
        vs = [VOGAIS[v] for v in rng.choice(list(VOGAIS), 2)]
        s = voz(rng, d, contorno, vs) * env(n, 0.03, d * 0.6, d * 0.3)
        silabas += [s, np.zeros(int(rng.uniform(0.01, 0.06) * SR))]
        f0 *= rng.uniform(0.94, 1.04)
    return np.concatenate(silabas)


def vila(rng, dur=36.0):
    """O murmúrio da vila: conversas sem palavras ao longe, umas batidas de trabalho e o ar."""
    n = int(dur * SR)
    x = 0.3 * ruido_moldado(n, rng, banda(80, 700, -3)) * lfo(n, rng, (1, 2, 3), 0.4)
    falas = np.zeros(n)
    for k in range(int(dur * 1.1)):
        f = _fala(rng, rng.uniform() < 0.55)
        colocar(falas, f, rng.integers(0, n), rng.uniform(0.3, 1.0))
    falas = passa_circular(falas, banda(120, 1300, 0, suave=2))  # de longe: sem consoantes
    for k in range(int(dur * 0.5)):  # batidas de madeira (pilão, machado ao longe)
        p = rng.integers(0, n)
        for j in range(rng.integers(2, 5)):
            b = tempo(0.06)
            bat = np.sin(2 * np.pi * rng.uniform(180, 320) * b) * np.exp(-b / 0.015)
            bat += 0.4 * passa(rng.standard_normal(b.size), 600, 2000) * np.exp(-b / 0.01)
            colocar(falas, bat, p + int(j * rng.uniform(0.45, 0.7) * SR), 0.6)
    falas = eco_circular(falas, resposta(rng, 1.0, 2500), 0.4)
    falas /= np.std(falas) + 1e-12
    return 0.35 * x / (np.std(x) + 1e-12) + falas


def _tambor(rng, f0, f1, queda, pele):
    t = tempo(0.5)
    corpo = np.sin(fase(f1 + (f0 - f1) * np.exp(-t / 0.04))) * np.exp(-t / queda)
    return corpo + pele * passa(rng.standard_normal(t.size), 600, 2500) * np.exp(-t / 0.015)


def festa(rng, dur=24.0):
    """O tambor da festa (laço): dois tambores de pele a 100 batidas por minuto (40 batidas no
    laço, que fecha certo), com palmas de vez em quando e o povo ao fundo, ao longe."""
    n = int(dur * SR)
    batida = 0.6  # s
    grave = _tambor(rng, 95, 55, 0.18, 0.3)
    agudo = _tambor(rng, 200, 130, 0.09, 0.5)
    x = np.zeros(n)
    for k in range(int(dur / batida)):  # compasso de 4: grave no 1 e no 3; agudo no 2, no 4 e no "e" do 4
        t0 = k * batida
        if k % 4 in (0, 2):
            colocar(x, grave, int(t0 * SR), rng.uniform(0.85, 1.0))
        if k % 4 in (1, 3):
            colocar(x, agudo, int((t0 + rng.uniform(-0.01, 0.01)) * SR), rng.uniform(0.6, 0.8))
        if k % 4 == 3:
            colocar(x, agudo, int((t0 + batida / 2) * SR), rng.uniform(0.4, 0.6))
        if k % 8 in (1, 3, 5, 7) and rng.uniform() < 0.6:  # palmas
            p = tempo(0.03)
            palma = passa(rng.standard_normal(p.size), 900, 2500) * np.exp(-p / 0.006)
            colocar(x, palma, int((t0 + rng.uniform(-0.02, 0.02)) * SR), rng.uniform(0.3, 0.5))
    x = eco_circular(x, resposta(rng, 0.9, 2500), 0.35)
    povo = vila(rng, dur)
    return x / (np.std(x) + 1e-12) + 0.35 * povo / (np.std(povo) + 1e-12)


LACOS = {"vento": vento, "passaros": passaros, "lago": lago, "grilos": grilos, "fogo": fogo, "chuva": chuva,
         "tempestade": tempestade, "neve": neve, "vila": vila,
         "festa": festa}


def gerar(semente=11):
    out = {}
    for i, (nome, f) in enumerate(LACOS.items()):
        x = f(np.random.default_rng(semente * 100 + i))
        out[nome] = nivelar(x - x.mean(), NIVEL[nome], pico_db=-6.0)
    return out
