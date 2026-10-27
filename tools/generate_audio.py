"""Synthesizes the placeholder music and sound effects (stdlib only).

Usage:  python tools/generate_audio.py
Writes audio/music/*.wav and audio/sfx/*.wav. Swap any file for a real
recording with the same name and the game picks it up.
"""
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


# ---------------------------------------------------------------- instruments

def music_box(freq, dur=2.5, vel=1.0, detune=0.0):
    n = int(dur * SR)
    out = []
    f = freq * (1 + detune)
    for i in range(n):
        t = i / SR
        e = math.exp(-t * 2.2)
        s = (math.sin(TAU * f * t)
             + 0.35 * math.sin(TAU * f * 2.0 * t) * math.exp(-t * 4)
             + 0.18 * math.sin(TAU * f * 4.07 * t) * math.exp(-t * 9)
             + 0.08 * math.sin(TAU * f * 5.9 * t) * math.exp(-t * 14))
        out.append(s * e * vel * min(1.0, t * 400))
    return out


def piano(freq, dur=4.0, vel=1.0):
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.0
        for k, amp in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)):
            s += amp * math.sin(TAU * freq * k * (1 + 0.0004 * k * k) * t) * math.exp(-t * (0.9 + 0.7 * k))
        out.append(s * vel * min(1.0, t * 300))
    return lowpass(out, 3200)


def pad(freqs, dur, attack=2.5, release=3.0, vel=1.0):
    n = int(dur * SR)
    e = env_ar(n, attack, release)
    out = [0.0] * n
    for f in freqs:
        for det in (-0.004, 0.0, 0.005):
            ph = random.random() * TAU
            ff = f * (1 + det)
            for i in range(n):
                t = i / SR
                vib = 1 + 0.002 * math.sin(TAU * 0.3 * t + ph)
                x = math.sin(TAU * ff * vib * t + ph)
                out[i] += (x + 0.25 * math.sin(2 * (TAU * ff * vib * t + ph))) * e[i] * vel
    return lowpass(out, 1800)


def noise(seconds, amp=1.0):
    return [random.uniform(-amp, amp) for _ in range(int(seconds * SR))]


# ---------------------------------------------------------------- music

def music_ch1(tempo=72, detune_wobble=0.0, name="ch1_living_room"):
    random.seed(1)
    beat = 60 / tempo
    chords = ["C", "Am", "F", "G", "C", "Em", "F", "G",
              "Am", "F", "C", "G", "F", "G", "C", "C"]
    tones = {"C": [60, 64, 67], "Am": [57, 60, 64], "F": [53, 57, 60],
             "G": [55, 59, 62], "Em": [52, 55, 59]}
    bars = len(chords)
    length = bars * 3 * beat
    out = buf(length)
    prev = 76
    for b, ch in enumerate(chords):
        t0 = b * 3 * beat
        tri = tones[ch]
        wob = lambda: random.uniform(-detune_wobble, detune_wobble)
        # low music-box bass on beat one, soft broken chord on 2 and 3
        mix(out, music_box(midi(tri[0] - 12 + 12), 3.0, 0.5, wob()), t0, wrap=True)
        mix(out, music_box(midi(tri[1] + 12), 2.0, 0.22, wob()), t0 + beat, wrap=True)
        mix(out, music_box(midi(tri[2] + 12), 2.0, 0.22, wob()), t0 + 2 * beat, wrap=True)
        # melody: walk to a nearby chord tone, sometimes with a passing eighth
        cands = [n + o for n in tri for o in (12, 24) if 69 <= n + o <= 88]
        cands.sort(key=lambda n: abs(n - prev) + random.random() * 4)
        note = cands[0] if b % 4 != 3 else cands[min(1, len(cands) - 1)]
        mix(out, music_box(midi(note), 2.6, 0.8, wob()), t0, wrap=True)
        if random.random() < 0.6:
            step = random.choice([-2, -1, 2]) if b % 8 != 7 else -1
            mix(out, music_box(midi(note + step), 2.0, 0.55, wob()), t0 + 1.5 * beat, wrap=True)
        if random.random() < 0.7:
            mix(out, music_box(midi(cands[min(2, len(cands) - 1)]), 2.0, 0.6, wob()), t0 + 2 * beat, wrap=True)
        prev = note
    out = reverb(out, 0.35, 1.1, wrap=True)
    write(os.path.join(ROOT, "audio/music", name + ".wav"), out, 0.7)


def music_dream():
    random.seed(2)
    chords = [[45, 57, 64, 71], [41, 57, 64, 69], [38, 53, 62, 64], [40, 56, 59, 64]]
    seg = 8.0
    out = buf(seg * len(chords))
    for i, ch in enumerate(chords):
        mix(out, pad([midi(n) for n in ch], seg + 3.0, 3.0, 3.0, 0.18), i * seg, wrap=True)
    for _ in range(14):
        t = random.uniform(0, len(out) / SR)
        note = random.choice([69, 72, 76, 79, 81, 84])
        mix(out, music_box(midi(note) * 0.985, 4.0, 0.25, random.uniform(-0.01, 0.01)), t, wrap=True)
    out = reverb(out, 0.6, 1.6, wrap=True)
    write(os.path.join(ROOT, "audio/music/dream_hall.wav"), out, 0.6)


def music_ch2():
    random.seed(3)
    length = 40.0
    out = buf(length)
    for i in range(len(out)):
        t = i / SR
        swell = 0.6 + 0.4 * math.sin(TAU * t / length)
        out[i] = (math.sin(TAU * midi(38) * t) * 0.5 + math.sin(TAU * midi(45) * t) * 0.25
                  + math.sin(TAU * midi(50) * 1.003 * t) * 0.15) * 0.12 * swell
    scale = [62, 64, 65, 67, 69, 70, 72, 74]
    t = 1.0
    while t < length - 1:
        mix(out, piano(midi(random.choice(scale)), 5.0, random.uniform(0.25, 0.45)), t, wrap=True)
        if random.random() < 0.3:
            mix(out, piano(midi(random.choice(scale) - 12), 5.0, 0.2), t + 0.05, wrap=True)
        t += random.choice([2.0, 2.5, 3.0, 4.0])
    out = reverb(out, 0.5, 1.4, wrap=True)
    write(os.path.join(ROOT, "audio/music/ch2_night.wav"), out, 0.6)


# ---------------------------------------------------------------- sfx

def sfx(name, data, peak=0.89):
    write(os.path.join(ROOT, "audio/sfx", name + ".wav"), data, peak)


def footstep(i, hollow=False):
    random.seed(100 + i + (50 if hollow else 0))
    n = int(0.22 * SR)
    thump_f = random.uniform(70, 95) if hollow else random.uniform(95, 130)
    out = []
    nz = lowpass(noise(0.22), 1800 if hollow else 2600)
    for k in range(n):
        t = k / SR
        s = math.sin(TAU * thump_f * t) * math.exp(-t * (28 if hollow else 45))
        s += nz[k] * math.exp(-t * 60) * 0.8
        out.append(s)
    if hollow:
        out = [a + b * 0.5 for a, b in zip(out, resonate(out, 190, 40))]
    sfx(("footstep_porch_" if hollow else "footstep_wood_") + str(i), out)


def click(pitch=4000, length=0.03):
    n = int(length * SR)
    return [random.uniform(-1, 1) * math.exp(-k / SR * 300) + math.sin(TAU * pitch * k / SR) * math.exp(-k / SR * 200) * 0.5 for k in range(n)]


def door_creak(dur=1.3):
    random.seed(7)
    n = int(dur * SR)
    out = []
    ph = 0.0
    for k in range(n):
        t = k / SR
        f = 260 + 140 * math.sin(TAU * 0.7 * t) + 40 * math.sin(TAU * 5.3 * t)
        ph += f / SR
        saw = 2 * (ph % 1) - 1
        stick = 1.0 if random.random() < 0.35 else 0.2
        out.append(saw * stick * min(1, t * 8) * min(1, (dur - t) * 4))
    out = resonate(out, 900, 300)
    return out


def bark(seed, f0=430):
    random.seed(seed)
    dur = 0.28
    n = int(dur * SR)
    src = []
    ph = 0.0
    for k in range(n):
        t = k / SR
        f = f0 * (1.15 - 0.6 * t / dur) * (1 + random.uniform(-0.03, 0.03))
        ph += f / SR
        pulse = 1.0 if (ph % 1) < 0.18 else -0.2
        e = min(1, t * 150) * math.exp(-t * 9)
        src.append((pulse + random.uniform(-0.5, 0.5)) * e)
    a = resonate(src, 750, 160)
    b = resonate(src, 1450, 220)
    c = resonate(src, 2600, 400)
    return [x + 0.7 * y + 0.3 * z for x, y, z in zip(a, b, c)]


def growl(dur=1.8):
    random.seed(9)
    n = int(dur * SR)
    src = []
    ph = 0.0
    for k in range(n):
        t = k / SR
        f = 85 + 10 * math.sin(TAU * 3 * t) + random.uniform(-6, 6)
        ph += f / SR
        pulse = 1.0 if (ph % 1) < 0.12 else -0.1
        am = 0.6 + 0.4 * math.sin(TAU * 11 * t)
        src.append(pulse * am * min(1, t * 6) * min(1, (dur - t) * 3))
    a = resonate(src, 420, 120)
    b = resonate(src, 1100, 250)
    return [x + 0.5 * y for x, y in zip(a, b)]


def whine(dur=1.1):
    n = int(dur * SR)
    out = []
    ph = 0.0
    for k in range(n):
        t = k / SR
        f = 820 + 300 * math.sin(math.pi * t / dur) + 25 * math.sin(TAU * 7 * t)
        ph += f / SR
        out.append((math.sin(TAU * ph) + 0.3 * math.sin(2 * TAU * ph)) * math.sin(math.pi * t / dur) ** 0.6)
    return resonate(out, 1200, 600)


def jingle(hits=4):
    random.seed(11)
    out = buf(1.2)
    for h in range(hits):
        t0 = h * random.uniform(0.07, 0.16)
        partials = [random.uniform(2200, 2600), random.uniform(3300, 3700), random.uniform(5000, 5600)]
        n = int(0.5 * SR)
        hit = [sum(math.sin(TAU * f * k / SR) / (j + 1) for j, f in enumerate(partials)) * math.exp(-k / SR * 12) for k in range(n)]
        mix(out, hit, t0, random.uniform(0.5, 1.0))
    return out


def crickets(seconds=6.0):
    random.seed(13)
    out = buf(seconds)
    for c in range(5):
        f = random.uniform(4200, 4900)
        rate = random.uniform(1.2, 2.2)
        offset = random.uniform(0, 1)
        gain = random.uniform(0.3, 1.0)
        for k in range(len(out)):
            t = k / SR
            cyc = (t * rate + offset) % 1
            if cyc < 0.18:
                pulse = 0.5 + 0.5 * math.sin(TAU * 30 * t)
                out[k] += math.sin(TAU * f * t) * pulse * gain * math.sin(math.pi * cyc / 0.18)
    return out


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


def main():
    music_ch1()
    music_ch1(tempo=50, detune_wobble=0.012, name="ending_music_box")
    music_dream()
    music_ch2()

    for i in range(1, 5):
        footstep(i)
        footstep(i, hollow=True)

    random.seed(5)
    sw = buf(0.25)
    mix(sw, click(3800), 0.0)
    mix(sw, click(2600), 0.05, 0.6)
    sfx("switch_click", sw)

    d = buf(1.6)
    mix(d, click(1800, 0.06), 0.0)
    mix(d, door_creak(), 0.08, 0.5)
    sfx("door_open", reverb(d, 0.2, 0.6))

    random.seed(6)
    dc = buf(0.6)
    mix(dc, [math.sin(TAU * 70 * k / SR) * math.exp(-k / SR * 18) for k in range(int(0.4 * SR))], 0.0)
    mix(dc, click(2000, 0.05), 0.02, 0.5)
    sfx("door_close", dc)

    sfx("dog_bark_1", reverb(bark(20), 0.2, 0.5))
    sfx("dog_bark_2", reverb(bark(21, 380), 0.2, 0.5))
    sfx("dog_growl", growl())
    sfx("dog_whine", whine())
    sfx("dog_tags", jingle())

    sfx("crickets", crossfade_loop(crickets(6.5)), 0.5)
    random.seed(14)
    wind = lowpass(lowpass(noise(9.0), 500), 700)
    wind = [s * (0.6 + 0.4 * math.sin(TAU * k / SR / 4.5)) for k, s in enumerate(wind)]
    sfx("wind", crossfade_loop(wind, 1.0), 0.5)

    random.seed(15)
    room = buf(6.5)
    hum = [0.3 * math.sin(TAU * 60 * k / SR) + 0.15 * math.sin(TAU * 120 * k / SR) for k in range(len(room))]
    rn = lowpass(noise(6.5), 300)
    sfx("room_tone", crossfade_loop([a + b for a, b in zip(hum, rn)]), 0.3)

    tick = buf(2.0)
    mix(tick, click(3000, 0.02), 0.0)
    mix(tick, click(2200, 0.02), 1.0)
    sfx("clock_tick", tick, 0.4)

    tv_tune("tv_show", [69, 72, 76, 75, 74, 72, 69, 68, 69, 76, 77, 76], 0.33, "theremin", 7.92)
    tv_tune("tv_ad", [72, 76, 79, 84, 79, 76, 72, 76, 77, 81, 84, 81], 0.15, "square", 5.4)
    sfx("tv_signoff", [math.sin(TAU * 1000 * k / SR) * 0.3 for k in range(int(4.0 * SR))], 0.3)
    random.seed(16)
    sfx("tv_static", crossfade_loop(highpass(noise(3.5), 800)), 0.4)

    random.seed(17)
    rustle = buf(0.9)
    for _ in range(25):
        burst = highpass(noise(random.uniform(0.01, 0.04)), 2500)
        mix(rustle, burst, random.uniform(0, 0.8), random.uniform(0.3, 1.0))
    sfx("candy_rustle", rustle)

    random.seed(18)
    sfx("light_out", reverb([s * math.exp(-k / SR * 40) for k, s in enumerate(lowpass(noise(0.2), 1200))], 0.5, 1.2))
    buzz = [(math.sin(TAU * 120 * k / SR) + random.uniform(-0.6, 0.6) * (random.random() < 0.3)) * 0.6 for k in range(int(0.5 * SR))]
    sfx("bulb_flicker", buzz)

    sting = buf(6.0)
    for f, g in ((midi(45), 1.0), (midi(57), 0.6), (midi(64), 0.4), (midi(76), 0.25)):
        mix(sting, piano(f, 6.0, g), 0.0)
    sfx("title_sting", reverb(sting, 0.5, 1.5)[: int(6.0 * SR)])


if __name__ == "__main__":
    main()
