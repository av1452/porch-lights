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
            elif wave_kind == "bell":
                s = (math.sin(TAU * ph) + 0.3 * math.sin(TAU * 2.76 * ph)) * math.exp(-tt * 4)
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


def tv_football(name="tv_football", whistle_at=3.4):
    """A crowd through a TV speaker: murmur, two cheers, and (for football) a
    whistle. Loops."""
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
    if whistle_at is not None:
        mix(out, whistle, whistle_at)
    sfx(name, crossfade_loop(out, 0.5), 0.5)


def bulb_flicker():
    random.seed(18)
    buzz = [(math.sin(TAU * 120 * k / SR) + random.uniform(-0.6, 0.6) * (random.random() < 0.3)) * 0.6 for k in range(int(0.5 * SR))]
    sfx("bulb_flicker", buzz)


def tv_parade():
    """A marching band through a TV speaker: an original brassy tune over a bass
    drum and snare, with the crowd along the street. Loops."""
    random.seed(23)
    secs = 9.6
    step = 0.3
    notes = [67, 72, 76, 79, 76, 72, 74, 77, 81, 79, 77, 74, 72, 76, 79, 84, 83, 79, 81, 79, 77, 76, 74, 72,
             67, 72, 76, 79, 77, 76, 74, 72]
    out = buf(secs)
    for i, note in enumerate(notes):
        f = midi(note)
        n = int(step * 0.9 * SR)
        seg = []
        for k in range(n):
            tt = k / SR
            # A brassy stack of odd harmonics, swelling in.
            s = sum(math.sin(TAU * f * h * tt) / h for h in (1, 2, 3, 4, 5))
            seg.append(s * 0.32 * min(1, tt * 25) * min(1, (step * 0.9 - tt) * 12))
        mix(out, seg, i * step, wrap=True)
    for b in range(int(secs / step)):
        at = b * step
        if b % 2 == 0:
            n = int(0.18 * SR)
            mix(out, [math.sin(TAU * 60 * k / SR) * math.exp(-k / SR * 18) * 0.9 for k in range(n)], at, wrap=True)
        else:
            mix(out, [random.uniform(-1, 1) * math.exp(-k / SR * 30) * 0.35 for k in range(int(0.12 * SR))], at, wrap=True)
    crowd = highpass(lowpass(noise(secs, 1.0), 1000), 200)
    out = [a + c * (0.12 + 0.1 * math.exp(-((k / SR - 4.8) / 0.8) ** 2)) for k, (a, c) in enumerate(zip(out, crowd))]
    out = highpass(lowpass(out, 3500), 250)
    sfx("tv_parade", crossfade_loop(out, 0.3), 0.55)


def tv_yulelog():
    """A fireplace on TV: crackles and pops, a low rumble of flame, and a
    soft music-box carol under it. Loops."""
    random.seed(29)
    secs = 9.6
    out = [s * 0.25 for s in lowpass(noise(secs, 1.0), 300)]
    for _ in range(140):
        at = random.uniform(0, secs)
        n = int(random.uniform(0.004, 0.02) * SR)
        mix(out, [random.uniform(-1, 1) * math.exp(-k / n * 4) * random.uniform(0.3, 1.0) for k in range(n)], at, wrap=True)
    bells = buf(secs)
    for i, note in enumerate([72, 72, 74, 72, 77, 76, 72, 72, 74, 72, 79, 77, 72, 72, 84, 81, 77, 76, 74, 82, 82, 81, 77, 79, 77]):
        f = midi(note)
        n = int(0.6 * SR)
        mix(bells, [(math.sin(TAU * f * k / SR) + 0.2 * math.sin(TAU * 3 * f * k / SR)) * math.exp(-k / SR * 5) * 0.22
                    for k in range(n)], i * 0.38, wrap=True)
    out = [a + b for a, b in zip(out, bells)]
    sfx("tv_yulelog", crossfade_loop(out, 0.4), 0.5)


def tv_videogame():
    """Two-player racing game: a bouncy chip tune and two little engines. Loops."""
    secs = 6.4
    out = buf(secs)
    lead = [76, 79, 83, 79, 81, 84, 88, 84, 76, 79, 83, 86, 88, 86, 83, 79]
    bass = [52, 52, 55, 55, 57, 57, 55, 55]
    for i in range(int(secs / 0.2)):
        f = midi(lead[i % len(lead)])
        n = int(0.17 * SR)
        mix(out, [(1.0 if (f * k / SR) % 1 < 0.25 else -1.0) * 0.18 * math.exp(-k / SR * 7) for k in range(n)], i * 0.2, wrap=True)
    for i in range(int(secs / 0.4)):
        f = midi(bass[i % len(bass)])
        n = int(0.36 * SR)
        mix(out, [(2 * ((f * k / SR) % 1) - 1) * 0.16 for k in range(n)], i * 0.4, wrap=True)
    for k in range(len(out)):
        t = k / SR
        engine = math.sin(TAU * (95 + 25 * math.sin(TAU * 0.5 * t)) * t) * 0.08
        engine += math.sin(TAU * (120 + 30 * math.sin(TAU * 0.37 * t + 1)) * t) * 0.06
        out[k] += engine
    sfx("tv_videogame", crossfade_loop(lowpass(out, 5000), 0.2), 0.5)


SOUNDS = {
    "tv_show": lambda: tv_tune("tv_show", [69, 72, 76, 75, 74, 72, 69, 68, 69, 76, 77, 76], 0.33, "theremin", 7.92),
    "tv_ad": lambda: tv_tune("tv_ad", [72, 76, 79, 84, 79, 76, 72, 76, 77, 81, 84, 81], 0.15, "square", 5.4),
    "tv_signoff": lambda: sfx("tv_signoff", [math.sin(TAU * 1000 * k / SR) * 0.3 for k in range(int(4.0 * SR))], 0.3),
    "bulb_flicker": bulb_flicker,
    "im_message": im_message,
    "tv_football": tv_football,
    "tv_newyear": lambda: tv_football("tv_newyear", None),
    # "The Night Before": an original little bell tune for the Christmas special.
    "tv_christmas": lambda: tv_tune("tv_christmas", [76, 79, 81, 79, 76, 74, 72, 74, 76, 76, 79, 84, 83, 79, 81, 79], 0.3, "bell", 9.6),
    "tv_parade": tv_parade,
    "tv_yulelog": tv_yulelog,
    "tv_videogame": tv_videogame,
}


def main():
    names = sys.argv[1:] or list(SOUNDS)
    for name in names:
        if name not in SOUNDS:
            sys.exit(f"unknown sound '{name}'. Known: {', '.join(SOUNDS)}")
        SOUNDS[name]()


if __name__ == "__main__":
    main()
