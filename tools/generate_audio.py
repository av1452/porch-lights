"""Synthesizes the few sounds that are meant to sound electronic: the TV
cartoon and toy-ad jingles, the broadcast sign-off tone, the bulb buzz and
the instant-message chime.
Everything else is real recordings from tools/fetch_audio.py (which also
borrows reverb() from here).

Usage:  python tools/generate_audio.py            # all of them
        python tools/generate_audio.py im_message  # just the named ones
"""
import sys
import math
import os
import random
import struct
import wave

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAU = math.tau


# ---------------------------------------------------------------- helpers

def buf(seconds):
    return [0.0] * int(seconds * SR)


def write(path, data, peak=0.89):
    m = max(1e-9, max(abs(s) for s in data))
    g = peak / m
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * g)) * 32767)) for s in data))
    print("wrote", os.path.relpath(path, ROOT), f"{len(data) / SR:.1f}s")


def mix(dst, src, at=0.0, gain=1.0, wrap=False):
    start = int(at * SR)
    n = len(dst)
    for i, s in enumerate(src):
        j = start + i
        if j >= n:
            if not wrap:
                break
            j %= n
        dst[j] += s * gain


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def lowpass(data, cutoff):
    a = 1 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    out = []
    for s in data:
        y += a * (s - y)
        out.append(y)
    return out


def highpass(data, cutoff):
    lp = lowpass(data, cutoff)
    return [s - l for s, l in zip(data, lp)]


def resonate(data, freq, bw):
    r = math.exp(-math.pi * bw / SR)
    a1 = 2 * r * math.cos(TAU * freq / SR)
    a2 = -r * r
    y1 = y2 = 0.0
    out = []
    for s in data:
        y = (1 - r) * s + a1 * y1 + a2 * y2
        y2, y1 = y1, y
        out.append(y)
    return out


def reverb(data, wet=0.3, size=1.0, wrap=False):
    """Small Schroeder reverb. wrap=True folds the tail back for seamless loops."""
    n = len(data)
    out = data[:]
    combs = [(int(d * size), 0.78) for d in (1557, 1617, 1491, 1422)]
    tail = int(SR * 2.5 * size)
    total = n + tail
    acc = [0.0] * total
    src = data + [0.0] * tail
    for d, fb in combs:
        line = [0.0] * d
        idx = 0
        damp = 0.0
        for i in range(total):
            o = line[idx]
            damp += 0.4 * (o - damp)
            line[idx] = src[i] + damp * fb
            idx = (idx + 1) % d
            acc[i] += o * 0.25
    for d in (225, 556):
        line = [0.0] * d
        idx = 0
        for i in range(total):
            b = line[idx]
            x = acc[i]
            line[idx] = x + b * 0.5
            acc[i] = b - x
            idx = (idx + 1) % d
    for i in range(total):
        if i < n:
            out[i] += acc[i] * wet
        elif wrap:
            out[i % n] += acc[i] * wet
        else:
            out.append(acc[i] * wet)
    return out


def crossfade_loop(data, seconds=0.5):
    """Make a noise bed loop seamlessly by fading its end into its start."""
    k = int(seconds * SR)
    body = data[:-k]
    for i in range(k):
        t = i / k
        body[i] = body[i] * t + data[len(data) - k + i] * (1 - t)
    return body


def env_ar(n, attack, release):
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    return [min(1.0, i / a) * min(1.0, (n - i) / r) for i in range(n)]


def noise(seconds, amp=1.0):
    return [random.uniform(-amp, amp) for _ in range(int(seconds * SR))]


# ---------------------------------------------------------------- sfx

def sfx(name, data, peak=0.89):
    write(os.path.join(ROOT, "audio/sfx", name + ".wav"), data, peak)


def tv_tune(name, notes, step, wave_kind, seconds):
    out = buf(seconds)
    t = 0.0
    i = 0
    while t < seconds:
        f = midi(notes[i % len(notes)])
        n = int(step * 0.95 * SR)
        seg = []
        for k in range(n):
            tt = k / SR
            vib = 1 + (0.012 * math.sin(TAU * 6 * tt) if wave_kind == "theremin" else 0)
            ph = f * vib * tt
            if wave_kind == "square":
                s = 1.0 if (ph % 1) < 0.5 else -1.0
                s *= math.exp(-tt * 6)
            else:
                s = math.sin(TAU * ph) * min(1, tt * 20) * min(1, (step - tt) * 10)
            seg.append(s * 0.6)
        mix(out, seg, t, wrap=True)
        t += step
        i += 1
    hiss = lowpass(noise(seconds, 0.08), 6000)
    out = [a + b for a, b in zip(out, hiss)]
    sfx(name, out, 0.6)


def im_message():
    """A soft two-note chime for an incoming instant message (original, not any real app's)."""
    out = buf(0.5)
    for at, note in ((0.0, 88), (0.09, 93)):
        n = int(0.35 * SR)
        f = midi(note)
        tone = [(math.sin(TAU * f * k / SR) + 0.25 * math.sin(TAU * 2 * f * k / SR)) * math.exp(-k / SR * 11)
                for k in range(n)]
        mix(out, [a * e for a, e in zip(tone, env_ar(n, 0.003, 0.05))], at, 0.5)
    sfx("im_message", out, 0.5)


def tv_football():
    """A football crowd through a TV speaker: murmur, two cheers, a whistle. Loops."""
    random.seed(11)
    secs = 8.0
    crowd = highpass(lowpass(noise(secs, 1.0), 1100), 180)
    out = []
    for k, s in enumerate(crowd):
        t = k / SR
        cheer = 0.9 * math.exp(-((t - 2.4) / 0.7) ** 2) + 0.6 * math.exp(-((t - 6.1) / 0.5) ** 2)
        out.append(s * (0.35 + cheer + 0.05 * math.sin(TAU * 0.3 * t)))
    whistle = [math.sin(TAU * (2900 + 60 * math.sin(TAU * 28 * k / SR)) * k / SR) * 0.25 * min(1, (0.45 - k / SR) * 30)
               for k in range(int(0.45 * SR))]
    mix(out, whistle, 3.4)
    sfx("tv_football", crossfade_loop(out, 0.5), 0.5)


def bulb_flicker():
    random.seed(18)
    buzz = [(math.sin(TAU * 120 * k / SR) + random.uniform(-0.6, 0.6) * (random.random() < 0.3)) * 0.6 for k in range(int(0.5 * SR))]
    sfx("bulb_flicker", buzz)


SOUNDS = {
    "tv_show": lambda: tv_tune("tv_show", [69, 72, 76, 75, 74, 72, 69, 68, 69, 76, 77, 76], 0.33, "theremin", 7.92),
    "tv_ad": lambda: tv_tune("tv_ad", [72, 76, 79, 84, 79, 76, 72, 76, 77, 81, 84, 81], 0.15, "square", 5.4),
    "tv_signoff": lambda: sfx("tv_signoff", [math.sin(TAU * 1000 * k / SR) * 0.3 for k in range(int(4.0 * SR))], 0.3),
    "bulb_flicker": bulb_flicker,
    "im_message": im_message,
    "tv_football": tv_football,
}


def main():
    names = sys.argv[1:] or list(SOUNDS)
    for name in names:
        if name not in SOUNDS:
            sys.exit(f"unknown sound '{name}'. Known: {', '.join(SOUNDS)}")
        SOUNDS[name]()


if __name__ == "__main__":
    main()
