"""Síntese dos sons do jogo, sem amostras: ruído filtrado, osciladores, envelopes e um eco curto.

Duas famílias de ferramentas:
- **Laços** (ambiente): tudo é periódico no comprimento do laço, então o fim emenda no começo
  sem nenhum degrau. O ruído é feito no domínio da frequência (o espectro moldado volta pela
  FFT inversa, que é periódica), as modulações têm um número inteiro de ciclos no laço, os
  eventos que passam do fim continuam no começo e o eco é uma convolução circular.
- **Curtos** (acontecimentos): filtros e eco comuns, com a cauda do eco no fim.

Mono, 22 050 Hz: basta para um som de janela aberta, abafado e quente, e deixa os arquivos leves.
"""
import numpy as np
from scipy import signal
import soundfile as sf

SR = 22050


def db(x):
    return 10.0 ** (x / 20.0)


def tempo(dur):
    return np.arange(int(round(dur * SR))) / SR


# --- ruído e filtros -------------------------------------------------------------------------

def ruido_moldado(n, rng, forma):
    """Ruído periódico de n amostras cujo espectro de amplitude é forma(f) (f em Hz)."""
    f = np.fft.rfftfreq(n, 1.0 / SR)
    X = (rng.standard_normal(f.size) + 1j * rng.standard_normal(f.size)) * forma(f)
    X[0] = 0.0
    x = np.fft.irfft(X, n)
    return x / (np.std(x) + 1e-12)


def banda(lo, hi, inclinacao=0.0, suave=1.5):
    """Forma de espectro: passa-faixa suave de lo a hi Hz, com inclinação em dB por oitava
    (negativa = mais grave, como o ruído rosa)."""
    def forma(f):
        f = np.maximum(f, 1.0)
        g = np.ones_like(f)
        if lo > 0:
            g *= 1.0 / np.sqrt(1.0 + (lo / f) ** (2 * suave))
        if hi > 0:
            g *= 1.0 / np.sqrt(1.0 + (f / hi) ** (2 * suave))
        return g * (f / 1000.0) ** (inclinacao / 6.02)
    return forma


def passa(x, lo=None, hi=None, ordem=2):
    """Filtro Butterworth comum (para os sons curtos)."""
    if lo and hi:
        sos = signal.butter(ordem, [lo, hi], "bandpass", fs=SR, output="sos")
    elif lo:
        sos = signal.butter(ordem, lo, "highpass", fs=SR, output="sos")
    else:
        sos = signal.butter(ordem, hi, "lowpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def passa_circular(x, forma):
    """Filtro no domínio da frequência, circular (mantém o laço sem emenda)."""
    f = np.fft.rfftfreq(x.size, 1.0 / SR)
    return np.fft.irfft(np.fft.rfft(x) * forma(f), x.size)


# --- modulações periódicas -------------------------------------------------------------------

def lfo(n, rng, ciclos=(1, 2, 3, 5), profundidade=1.0):
    """Uma curva lenta e irregular de 0 a 1, periódica em n amostras: soma de senos com um
    número inteiro de ciclos no laço e fases ao acaso."""
    t = np.arange(n) / n
    y = np.zeros(n)
    for c in ciclos:
        y += rng.uniform(0.4, 1.0) * np.sin(2 * np.pi * (c * t + rng.uniform()))
    y = (y - y.min()) / (np.ptp(y) + 1e-12)
    return 1.0 - profundidade + profundidade * y


def suaviza(x, seg):
    """Média móvel circular de seg segundos (para envelopes de rajada)."""
    k = max(1, int(seg * SR))
    nucleo = np.zeros(x.size)
    nucleo[:k] = 1.0 / k
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(nucleo), x.size)


# --- envelopes e osciladores -----------------------------------------------------------------

def env(n, ataque, queda, sustenta=0.0, curva=4.0):
    """Envelope: sobe em `ataque` s (seno), fica em 1 por `sustenta` s e cai exponencialmente
    em `queda` s até o fim (ou até n)."""
    t = np.arange(n) / SR
    e = np.ones(n)
    a = max(ataque, 1e-4)
    e[t < a] = np.sin(0.5 * np.pi * t[t < a] / a)
    d = t >= a + sustenta
    e[d] = np.exp(-curva * (t[d] - a - sustenta) / max(queda, 1e-4))
    return e


def fase(freq):
    """Fase acumulada de uma frequência que pode variar (array em Hz)."""
    return 2 * np.pi * np.cumsum(freq) / SR


def sino(dur, f0, parciais=((1.0, 1.0, 1.0), (2.76, 0.45, 0.55), (5.40, 0.25, 0.35), (8.93, 0.12, 0.2)),
         queda=2.5, ataque=0.004):
    """Sino ou carrilhão: parciais inarmônicos (razão, amplitude, fração da queda)."""
    t = tempo(dur)
    x = np.zeros(t.size)
    for r, a, q in parciais:
        x += a * np.sin(2 * np.pi * f0 * r * t + 0.3 * r) * np.exp(-t / (queda * q))
    fim = np.clip((t[-1] - t) / (0.3 * dur), 0.0, 1.0) ** 2  # some de vez no último terço
    return x * env(t.size, ataque, dur, sustenta=dur) * fim


def voz(rng, dur, f0, vogais, rouca=0.15):
    """Uma voz sem palavras: trem de pulsos (dente de serra suave) com o tom f0 (array ou
    número), filtrado por formantes que vão de uma vogal a outra. vogais: lista de
    (F1, F2, F3) que se sucedem ao longo da duração."""
    n = int(dur * SR)
    f0 = np.broadcast_to(np.asarray(f0, dtype=float), (n,)).copy()
    f0 *= 1.0 + 0.01 * passa(rng.standard_normal(n), hi=8)  # tremor natural
    ph = np.cumsum(f0) / SR
    serra = 2.0 * (ph % 1.0) - 1.0
    fonte = passa(serra, hi=2500) + rouca * passa(rng.standard_normal(n), 300, 3000)
    out = np.zeros(n)
    trechos = np.array_split(np.arange(n), len(vogais))
    for (f1, f2, f3), idx in zip(vogais, trechos):
        seg = np.zeros(n)
        for fo, g in ((f1, 1.0), (f2, 0.6), (f3, 0.25)):
            seg += g * passa(fonte, fo * 0.85, min(fo * 1.15, SR / 2 - 100))
        w = np.zeros(n)
        w[idx] = 1.0
        out += seg * suaviza(w, 0.03)
    return out


VOGAIS = {"a": (750, 1200, 2600), "o": (500, 900, 2500), "u": (350, 800, 2300),
          "e": (500, 1700, 2500), "i": (300, 2200, 2900), "é": (600, 1800, 2500)}


# --- eco ------------------------------------------------------------------------------------

def resposta(rng, dur=0.9, escuro=3000.0):
    """Resposta de uma sala aberta: ruído que cai exponencialmente, abafado."""
    n = int(dur * SR)
    ir = passa(rng.standard_normal(n), hi=escuro) * np.exp(-6.0 * np.arange(n) / n)
    ir[0] = 0.0
    return ir / np.sqrt(np.sum(ir ** 2))


def eco_circular(x, ir, mistura=0.3):
    h = np.zeros(x.size)
    h[:ir.size] = ir
    molhado = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), x.size)
    return (1 - mistura) * x + mistura * molhado


def eco(x, ir, mistura=0.3):
    molhado = signal.fftconvolve(x, ir)
    y = np.concatenate([x, np.zeros(ir.size - 1)])
    return (1 - mistura) * y + mistura * molhado


# --- montagem -------------------------------------------------------------------------------

def colocar(buf, ev, pos, ganho=1.0, circular=True):
    """Soma o evento ev em buf a partir da amostra pos; no laço, o que passa do fim volta ao começo."""
    pos = int(pos)
    idx = pos + np.arange(ev.size)
    if circular:
        np.add.at(buf, idx % buf.size, ganho * ev)
    else:
        ok = idx < buf.size
        buf[idx[ok]] += ganho * ev[ok]


def nivelar(x, rms_db, pico_db=-3.0, ativo=False):
    """Ajusta o volume para o RMS pedido (em dBFS), medido no trecho ativo (onde o envelope de
    50 ms passa de -30 dB do máximo) quando ativo=True. O pico nunca passa de pico_db: se
    passaria, o som fica mais baixo que o RMS pedido, sem distorcer."""
    medir = x
    if ativo:
        k = int(0.05 * SR)
        envelope = np.sqrt(np.convolve(x ** 2, np.ones(k) / k, "same"))
        janela = envelope > envelope.max() * db(-30)
        medir = x[janela] if janela.any() else x
    rms = np.sqrt(np.mean(medir ** 2)) + 1e-12
    ganho = min(db(rms_db) / rms, db(pico_db) / (np.max(np.abs(x)) + 1e-12))
    return x * ganho


def bordas(x, ataque=0.01, queda=0.05):
    """Sem clique no começo e no fim de um som curto."""
    n = x.size
    e = np.ones(n)
    a, q = min(int(ataque * SR), n // 2), min(int(queda * SR), n // 2)
    if a:
        e[:a] = np.linspace(0, 1, a)
    if q:
        e[-q:] *= np.linspace(1, 0, q)
    return x * e


def medir(x):
    """(RMS em dBFS, pico em dBFS)."""
    return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12), 20 * np.log10(np.max(np.abs(x)) + 1e-12)


def gravar(caminho, x):
    """Grava em Ogg Vorbis, mono, 22 050 Hz, na qualidade padrão do libsndfile. Em blocos de
    2048 amostras: no Windows, o libsndfile fecha o Python sem aviso se o bloco for grande."""
    x = np.clip(x, -1.0, 1.0).astype(np.float32)
    with sf.SoundFile(str(caminho), "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, x.size, 2048):
            f.write(x[i:i + 2048])
