"""Os sons curtos de acontecimento: trovões, terremoto, fogo, dilúvio, os poderes, a caçada, o
choro de bebê, a coruja, o galo, o sino do templo e o clique da alça.

Todos com ataque macio (nada estala de repente) e eco de campo aberto. NIVEL dá o RMS do trecho
ativo e PICO o teto de cada um: o trovão é o mais forte, mas fica longe e rola, sem estalo.
"""
import numpy as np

from sintese import (SR, VOGAIS, bordas, eco, env, fase, nivelar, passa, resposta, sino, tempo, voz)

# (RMS do trecho ativo, pico), em dBFS
NIVEL = {
    "trovao_1": (-26, -9), "trovao_2": (-26, -9), "trovao_3": (-27, -9), "terremoto": (-23, -7),
    "fogo_acender": (-25, -9), "fogo_brando": (-27, -10), "diluvio": (-24, -8), "fartura": (-27, -10),
    "sonho": (-28, -12), "milagre_sino": (-26, -9), "pressagio": (-26, -10), "cura": (-27, -11),
    "arremesso": (-27, -12), "lanca_cravar": (-26, -10), "grito_cacada": (-27, -11), "choro_bebe": (-31, -15),
    "coruja": (-28, -12), "galo": (-28, -11), "sino_templo": (-27, -9), "clique_alca": (-36, -20),
}


def _ruido(rng, dur):
    return rng.standard_normal(int(round(dur * SR)))


def _rolar(rng, dur, estrondos, crack=0.0):
    """O trovão longe: ruído grave com vários estrondos que se sobrepõem e rolam."""
    n = int(dur * SR)
    x = np.zeros(n)
    for t0, forca, queda in estrondos:
        k = int(t0 * SR)
        m = n - k
        r = passa(rng.standard_normal(m), 25, 220, 2) + 0.4 * passa(rng.standard_normal(m), 150, 600)
        x[k:] += forca * r * env(m, rng.uniform(0.08, 0.2), queda)
    # a modulação irregular que faz "rolar"
    am = np.abs(passa(_ruido(rng, dur), hi=6)) + 0.3
    x *= am / am.max()
    if crack:  # o estalo do raio, já amaciado pela distância
        c = passa(_ruido(rng, 0.4), 500, 1500) * env(int(0.4 * SR), 0.06, 0.3)
        x[:c.size] += crack * c
    return passa(x, hi=1800)


def trovao_1(rng):
    return _rolar(rng, 5.0, [(0.0, 1.0, 2.5), (0.5, 0.8, 2.5), (1.4, 0.6, 2.8)], crack=0.12)


def trovao_2(rng):  # mais longe, mais comprido e sem estalo
    return passa(_rolar(rng, 6.0, [(0.0, 0.6, 2.0), (0.9, 1.0, 3.0), (2.2, 0.7, 3.0), (3.4, 0.4, 2.0)]), hi=400)


def trovao_3(rng):  # perto: um estrondo só, mais curto
    return _rolar(rng, 4.0, [(0.0, 1.0, 2.2), (0.25, 0.7, 1.8)], crack=0.18)


def terremoto(rng):
    """O ronco grave do chão e o chacoalhar de pedrinhas, que cresce e passa."""
    dur = 4.5
    n = int(dur * SR)
    ronco = passa(_ruido(rng, dur), 20, 90, 2) + 0.5 * np.sin(fase(np.full(n, 38.0) + 4 * np.sin(np.arange(n) / SR * 3)))
    pedras = np.zeros(n)
    for k in range(120):
        d = int(rng.uniform(0.004, 0.02) * SR)
        p = passa(rng.standard_normal(d), 500, 1800) * np.exp(-np.arange(d) / (d / 4))
        pos = int(rng.uniform(0.3, 4.0) * SR)
        pedras[pos:pos + d] += rng.uniform(0.2, 1.0) * p[:max(0, min(d, n - pos))]
    forma = np.sin(np.pi * np.arange(n) / n) ** 1.5
    return (ronco + 0.35 * passa(pedras, hi=1500, ordem=4)) * forma


def fogo_acender(rng):
    """O fogo pegando: um sopro que sobe e os primeiros estalos."""
    dur = 2.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    sopro = passa(_ruido(rng, dur), 200, 1200) * env(n, 0.35, 1.4, 0.1)
    rugido = passa(_ruido(rng, dur), 40, 300) * np.clip(t / 0.6, 0, 1) * np.exp(-np.maximum(t - 1.0, 0) / 0.8)
    estalos = np.zeros(n)
    for k in range(18):
        d = int(rng.uniform(0.003, 0.01) * SR)
        e = passa(rng.standard_normal(d + 10), 1200, 5000)[:d] * np.exp(-np.arange(d) / (d / 3))
        pos = int(rng.uniform(0.3, 1.9) * SR)
        estalos[pos:pos + d] += rng.uniform(0.3, 1.0) * e[:max(0, min(d, n - pos))]
    return sopro + rugido + 2.0 * estalos


def fogo_brando(rng):
    """O fogo brando do céu: um sopro morno e grave, com um tom quente bem baixinho."""
    dur = 2.6
    n = int(dur * SR)
    sopro = passa(_ruido(rng, dur), 120, 700) * env(n, 0.8, 1.6, 0.2)
    t = tempo(dur)
    tom = (np.sin(2 * np.pi * 147 * t) + 0.5 * np.sin(2 * np.pi * 220.5 * t)) * env(n, 0.9, 1.5, 0.2)
    return sopro + 0.25 * tom


def diluvio(rng):
    """A água do dilúvio chegando: uma correnteza que cresce, borbulha e se espalha."""
    dur = 6.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    corrente = passa(_ruido(rng, dur), 70, 1100) * np.clip(t / 1.5, 0, 1) * np.exp(-np.maximum(t - 3.0, 0) / 0.8)
    espuma = passa(_ruido(rng, dur), 1200, 3200) * np.clip(t / 2.0, 0, 1) ** 2 * np.exp(-np.maximum(t - 3.0, 0) / 0.6)
    bolhas = np.zeros(n)
    for k in range(40):
        b = tempo(rng.uniform(0.04, 0.1))
        fr = np.linspace(rng.uniform(250, 500), rng.uniform(600, 1000), b.size)
        pos = int(rng.uniform(0.6, 4.0) * SR)
        bb = np.sin(fase(fr)) * np.exp(-b / 0.03)
        bolhas[pos:pos + bb.size] += rng.uniform(0.2, 0.6) * bb[:max(0, min(bb.size, n - pos))]
    return corrente + 0.3 * espuma + 0.6 * bolhas


PENTA = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.7]  # dó maior pentatônica


def fartura(rng):
    """O brilho da fartura: um arpejo pentatônico subindo, de sininhos macios, com um brilho de ar."""
    dur = 2.2
    n = int(dur * SR)
    x = np.zeros(n)
    for k, f in enumerate(PENTA[1:6]):
        s = sino(1.4, f * 2, ((1.0, 1.0, 1.0), (2.0, 0.2, 0.4), (3.01, 0.08, 0.25)), queda=0.9)
        pos = int(k * 0.09 * SR)
        x[pos:pos + s.size] += 0.7 * s[:n - pos]
    ar = passa(_ruido(rng, dur), 3000, 7000) * env(n, 0.2, 1.5, 0.1)
    return x + 0.08 * ar


def sonho(rng):
    """O sonho: um tom suave que entra devagar, com vibrato e uma quinta leve, e se desfaz."""
    dur = 3.4
    n = int(dur * SR)
    t = tempo(dur)
    vib = 1.0 + 0.004 * np.sin(2 * np.pi * 4.5 * t)
    x = np.zeros(n)
    for f, a in ((392.0, 1.0), (392.0 * 1.003, 0.7), (587.3, 0.35), (784.0, 0.15)):
        x += a * np.sin(fase(f * vib))
    return passa(x, hi=2500) * env(n, 1.0, 2.2, 0.3)


def milagre_sino(rng):
    """O sino leve do milagre: um sino pequeno, agudo e limpo, com eco."""
    leve = ((1.0, 1.0, 1.0), (2.76, 0.4, 0.55), (5.40, 0.15, 0.3))
    return sino(3.2, 784.0, leve, queda=2.0) + 0.35 * sino(3.2, 1174.7, leve, queda=1.4)


def pressagio(rng):
    """O presságio: um tom grave e escuro, com um batimento lento, que vem e vai."""
    dur = 4.0
    n = int(dur * SR)
    t = tempo(dur)
    x = np.sin(2 * np.pi * 73.4 * t) + 0.7 * np.sin(2 * np.pi * 73.4 * 1.007 * t) + 0.35 * np.sin(2 * np.pi * 110.0 * t)
    x += 0.2 * passa(_ruido(rng, dur), 60, 300)
    return x * env(n, 1.2, 2.4, 0.5)


def cura(rng):
    """A cura: duas notas que sobem, de carrilhão macio, sobre um sopro de ar claro."""
    dur = 2.6
    n = int(dur * SR)
    x = np.zeros(n)
    for k, f in enumerate((659.25, 987.77)):
        s = sino(2.0, f, ((1.0, 1.0, 1.0), (2.0, 0.3, 0.5), (4.0, 0.08, 0.3)), queda=1.4, ataque=0.03)
        pos = int(k * 0.28 * SR)
        x[pos:pos + s.size] += s[:n - pos]
    ar = passa(_ruido(rng, dur), 1200, 4000) * env(n, 0.5, 1.6, 0.2)
    return x + 0.06 * ar


def arremesso(rng):
    """A lança cortando o ar: um zunido curto que desce."""
    dur = 0.45
    n = int(dur * SR)
    r = _ruido(rng, dur)
    x = np.zeros(n)
    passos = 6
    for k in range(passos):  # o filtro desce em degraus suaves
        f = 2400 - 1500 * k / passos
        trecho = np.zeros(n)
        a, b = k * n // passos, (k + 1) * n // passos
        trecho[a:b] = 1.0
        x += passa(r, f * 0.7, f * 1.3) * np.convolve(trecho, np.ones(200) / 200, "same")
    return x * env(n, 0.06, 0.35, 0.05)


def lanca_cravar(rng):
    """A lança cravando no capim: um baque surdo e o farfalhar da palha."""
    dur = 0.5
    n = int(dur * SR)
    t = tempo(dur)
    baque = np.sin(fase(np.linspace(160, 80, n))) * np.exp(-t / 0.05)
    palha = passa(_ruido(rng, dur), 1200, 3500) * np.exp(-t / 0.08)
    return baque + 0.5 * palha


def grito_cacada(rng):
    """O grito curto da caçada, sem palavras: um "ê-ô!" que sobe e cai, ao longe."""
    dur = 0.65
    n = int(dur * SR)
    f0 = 210 + 70 * np.sin(np.pi * np.linspace(0, 1, n)) ** 0.7
    x = voz(rng, dur, f0, [VOGAIS["é"], VOGAIS["o"]], rouca=0.25)
    return passa(x, hi=2200) * env(n, 0.04, 0.4, 0.2)


def choro_bebe(rng):
    """Um recém-nascido chorando ao longe: três "uéé" agudos, abafados pela distância."""
    partes = []
    for k in range(3):
        d = rng.uniform(0.55, 0.8)
        n = int(d * SR)
        f0 = rng.uniform(420, 480) * (1.0 + 0.08 * np.sin(np.pi * np.linspace(0, 1, n))) * \
            (1.0 + 0.02 * np.sin(2 * np.pi * 9 * np.arange(n) / SR))
        s = voz(rng, d, f0, [VOGAIS["u"], VOGAIS["é"], VOGAIS["é"]], rouca=0.1) * env(n, 0.08, d * 0.5, d * 0.4)
        partes += [s, np.zeros(int(rng.uniform(0.25, 0.4) * SR))]
    return passa(np.concatenate(partes), 300, 1800)


def coruja(rng):
    """A coruja: "hu… hu-hu", um tom grave e redondo que cai um pouco no fim de cada pio."""
    partes = []
    for d, pausa in ((0.45, 0.35), (0.22, 0.12), (0.5, 0.0)):
        n = int(d * SR)
        f = 400 * (1.0 - 0.06 * np.linspace(0, 1, n) ** 2)
        s = (np.sin(fase(f)) + 0.15 * np.sin(2 * fase(f))) * env(n, 0.05, d * 0.5, d * 0.35)
        s += 0.05 * passa(_ruido(rng, d), 300, 900) * env(n, 0.05, d * 0.5, d * 0.35)
        partes += [s, np.zeros(int(pausa * SR))]
    return np.concatenate(partes)


def galo(rng):
    """O galo ao amanhecer, ao longe: "có-có-ri-cóóó", tom rouco que sobe e se arrasta."""
    sil = [(0.12, 520, 560, "o"), (0.12, 560, 600, "o"), (0.14, 640, 720, "i"), (0.8, 760, 560, "o")]
    partes = []
    for d, fa, fb, v in sil:
        n = int(d * SR)
        f0 = np.linspace(fa, fb, n) if d < 0.5 else np.concatenate(
            [np.full(int(n * 0.6), fa), np.linspace(fa, fb, n - int(n * 0.6))])
        s = voz(rng, d, f0, [VOGAIS[v], VOGAIS["u"]] if d > 0.5 else [VOGAIS[v]], rouca=0.35)
        partes += [s * env(n, 0.02, d * 0.4, d * 0.5), np.zeros(int(0.03 * SR))]
    return passa(np.concatenate(partes), 400, 3000)


def sino_templo(rng):
    """O sino do templo: grave, de bronze, uma batida longa (o jogo repete para tocar mais)."""
    s = sino(6.0, 196.0, ((1.0, 1.0, 1.0), (2.0, 0.5, 0.6), (2.4, 0.35, 0.5), (3.0, 0.25, 0.35),
                          (4.2, 0.15, 0.25), (5.4, 0.08, 0.2)), queda=3.5, ataque=0.006)
    return s + 0.3 * sino(6.0, 98.0, ((1.0, 1.0, 1.0),), queda=3.0, ataque=0.02)


def clique_alca(rng):
    """O clique da alça: um toque de madeira, curto e baixo."""
    dur = 0.06
    n = int(dur * SR)
    t = tempo(dur)
    x = np.sin(2 * np.pi * 1100 * t) * np.exp(-t / 0.006) + 0.3 * passa(_ruido(rng, dur), 2000, 5000) * np.exp(-t / 0.003)
    return x


SONS = {nome: globals()[nome] for nome in NIVEL}

# o eco de cada um (duração, abafamento, mistura): campo aberto, mais longo nos de longe
ECO = {"trovao_1": (2.0, 1500, 0.4), "trovao_2": (2.5, 1200, 0.45), "trovao_3": (1.8, 1800, 0.35),
       "terremoto": (1.0, 1000, 0.2), "milagre_sino": (2.0, 5000, 0.35), "sino_templo": (2.5, 3000, 0.35),
       "grito_cacada": (1.4, 2500, 0.45), "choro_bebe": (1.2, 2000, 0.45), "coruja": (1.6, 2500, 0.45),
       "galo": (1.4, 2500, 0.45), "fartura": (1.2, 6000, 0.3), "cura": (1.2, 5000, 0.3), "sonho": (1.5, 4000, 0.3),
       "pressagio": (2.0, 1500, 0.3), "clique_alca": (0.1, 4000, 0.0)}


def gerar(semente=23):
    out = {}
    for i, (nome, f) in enumerate(SONS.items()):
        rng = np.random.default_rng(semente * 100 + i)
        x = bordas(f(rng), 0.004, 0.15)
        d, escuro, mix = ECO.get(nome, (0.6, 3000, 0.2))
        if mix > 0:
            x = eco(x, resposta(rng, d, escuro), mix)
        x = bordas(x - np.mean(x), 0.004 if nome == "clique_alca" else 0.01, 0.08)
        rms, pico = NIVEL[nome]
        out[nome] = nivelar(x, rms, pico, ativo=True)
    return out
