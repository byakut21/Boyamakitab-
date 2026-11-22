"""Uygulamanın müziğini ve ses efektlerini sıfırdan üretir (tamamen özgün, telifsiz).

Kullanım: python3 tool/make_audio.py  (numpy ve ffmpeg gerekir)
Çıktı: assets/audio/muzik.ogg, plop.ogg, cikartma.ogg
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
BPM = 108
BEAT = 60 / BPM
BAR = 4 * BEAT


def midi_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def marimba(freq, dur, amp):
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 6.5)
    attack = np.minimum(1, t / 0.004)
    tone = (np.sin(2 * np.pi * freq * t)
            + 0.35 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t * 18)
            + 0.15 * np.sin(2 * np.pi * freq * 2.0 * t))
    return amp * tone * env * attack


def bell(freq, dur, amp):
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 3.5) * np.minimum(1, t / 0.003)
    tone = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 8)
    return amp * tone * env


def bass(freq, dur, amp):
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t * 2.2) * np.minimum(1, t / 0.01)
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * freq * 2 * t)
    return amp * tone * env


def shaker(dur, amp, rng):
    n = int(SR * dur)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = np.diff(noise, prepend=0)  # tiz bir hışırtı
    return amp * noise * np.exp(-t * 45)


def add(buf, start, sig):
    """Döngünün sonundan taşan kısım başa sarar; böylece müzik kesintisiz döner."""
    i = int(round(start * SR)) % len(buf)
    end = i + len(sig)
    if end <= len(buf):
        buf[i:end] += sig
    else:
        k = len(buf) - i
        buf[i:] += sig[:k]
        buf[: len(sig) - k] += sig[k:]


def music():
    # Basit, neşeli bir akor yürüyüşü: Do - La minör - Fa - Sol (16 ölçü)
    chords = [
        (48, [60, 64, 67]), (45, [57, 60, 64]), (41, [53, 57, 60]), (43, [55, 59, 62]),
    ] * 4
    # Ezgi: (ölçü içindeki vuruş, MIDI notası, süre vuruş olarak). Do majör beşli dizi.
    phrase_a = [
        [(0, 72, 1), (1, 74, 0.5), (1.5, 76, 0.5), (2, 79, 1), (3, 76, 1)],
        [(0, 74, 1), (1, 72, 1), (2, 69, 1.5), (3.5, 72, 0.5)],
        [(0, 72, 0.5), (0.5, 74, 0.5), (1, 76, 1), (2, 74, 0.5), (2.5, 72, 0.5), (3, 74, 1)],
        [(0, 79, 1.5), (1.5, 76, 0.5), (2, 74, 2)],
    ]
    phrase_b = [
        [(0, 76, 0.5), (0.5, 79, 0.5), (1, 81, 1), (2, 79, 0.5), (2.5, 76, 0.5), (3, 79, 1)],
        [(0, 76, 1), (1, 74, 0.5), (1.5, 72, 0.5), (2, 69, 2)],
        [(0, 72, 0.5), (0.5, 72, 0.5), (1, 74, 0.5), (1.5, 76, 0.5), (2, 81, 1), (3, 79, 1)],
        [(0, 74, 1), (1, 79, 1), (2, 72, 2)],
    ]
    melody = phrase_a + phrase_b + phrase_a + [
        phrase_b[0], phrase_b[1], phrase_a[2],
        [(0, 76, 1), (1, 74, 1), (2, 72, 2)],
    ]
    total = BAR * len(chords)
    buf = np.zeros(int(round(total * SR)))
    rng = np.random.default_rng(7)
    for bar, ((root, triad), notes) in enumerate(zip(chords, melody)):
        t0 = bar * BAR
        # Bas: 1. ve 3. vuruşta kök, 2.5'te beşli
        add(buf, t0, bass(midi_hz(root), BEAT * 1.6, 0.30))
        add(buf, t0 + 2.5 * BEAT, bass(midi_hz(root + 7), BEAT * 0.9, 0.20))
        add(buf, t0 + 3 * BEAT, bass(midi_hz(root), BEAT * 0.9, 0.22))
        # Arka planda yumuşak akor çanları, ara vuruşlarda
        for k, beat in enumerate((0.5, 1.5, 2.5, 3.5)):
            note = triad[k % 3] + 12
            add(buf, t0 + beat * BEAT, bell(midi_hz(note), BEAT * 1.2, 0.055))
        # Ezgi
        for beat, note, length in notes:
            add(buf, t0 + beat * BEAT, marimba(midi_hz(note), max(0.35, length * BEAT * 1.4), 0.26))
        # Hafif sallantılı ritim
        for e in range(8):
            add(buf, t0 + e * BEAT / 2, shaker(0.08, 0.035 if e % 2 else 0.02, rng))
    buf /= np.max(np.abs(buf)) / 0.8
    return buf


def plop():
    dur = 0.22
    t = np.arange(int(SR * dur)) / SR
    freq = 380 + 900 * (t / dur) ** 0.6  # yukarı kayan "plop"
    phase = 2 * np.pi * np.cumsum(freq) / SR
    sig = np.sin(phase) * np.exp(-t * 16) * np.minimum(1, t / 0.003)
    return 0.8 * sig / np.max(np.abs(sig))


def sparkle():
    out = np.zeros(int(SR * 0.6))
    for i, n in enumerate((84, 88, 91, 96)):
        s = bell(midi_hz(n), 0.45, 0.5)
        start = int(i * 0.05 * SR)
        out[start:start + len(s)] += s[: len(out) - start]
    return 0.8 * out / np.max(np.abs(out))


def write_ogg(name, sig, quality):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(sig, -1, 1) * 32767).astype("<i2").tobytes())
    out = os.path.join(OUT, name)
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", str(quality), out],
        check=True,
    )
    os.remove(path)
    print(out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write_ogg("muzik.ogg", music(), 3)
    write_ogg("plop.ogg", plop(), 4)
    write_ogg("cikartma.ogg", sparkle(), 4)
