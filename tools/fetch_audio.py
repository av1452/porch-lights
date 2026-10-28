"""Downloads the game's real recorded sounds and music (all CC0) and cuts them
into the clips the game uses. Re-run any time; downloads are cached in
tools/.audio_cache (gitignored).

Usage:  python tools/fetch_audio.py

Sources (all CC0 / public domain, no attribution required; credited anyway in
audio/CREDITS.md):
  - BigSoundBank (Joseph Sardin)  https://bigsoundbank.com
  - Kenney (Impact Sounds, RPG Audio)  https://kenney.nl
  - OpenGameArt: "Midnight" (Anton Revin), "First Light Particles" and
    "Starfield Romance" (Yoiyami)
Synthesized TV jingles and the bulb buzz still come from tools/generate_audio.py.
"""
import math
import os
import random
import shutil
import struct
import urllib.request
import wave
import zipfile

from generate_audio import reverb as _reverb

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "tools", ".audio_cache")
SFX = os.path.join(ROOT, "audio", "sfx")
MUSIC = os.path.join(ROOT, "audio", "music")
UA = {"User-Agent": "porch-lights-asset-fetch"}

BSB = "https://bigsoundbank.com/UPLOAD/bwf-en/{}.wav"
BSB_SOUNDS = {
    "3205": "Creaking Door #2", "3206": "Creaking door #3", "0026": "Electric switch",
    "0540": "Old switch", "0007": "Clock", "1880": "Campaign at Night #4",
    "0904": "Forest wind in the trees", "0034": "Refrigerator", "1037": "White Noise",
    "2134": "Zapping", "1783": "Cathode screen off #1", "0844": "Blister",
    "2352": "Old dog barking #1", "2955": "Barking dog #3", "1060": "2 small dogs bark and growl",
    "2450": "Dog singing #1",
    "3098": "Car interior, 80 km/h", "1021": "Blinker", "0971": "Car door #1",
    # music box notes, for the chapter 1 lullaby
    "1866": "Music box, A# #1", "1867": "Music box, C #1", "1868": "Music box, C# #1",
    "1869": "Music box, D# #1", "1870": "Music box, F #1", "1871": "Music box, G #1",
    "1872": "Music box, G# #2", "1874": "Music box, C #2", "1875": "Music box, C# #2",
}
KENNEY = ["impact-sounds", "rpg-audio"]
OGA_MUSIC = {
    "dream_hall.mp3": ("https://opengameart.org/sites/default/files/first_light_particles_1.mp3",
                       '"First Light Particles" by Yoiyami (CC0) https://opengameart.org/node/182244'),
    "ch2_night.mp3": ("https://opengameart.org/sites/default/files/Midnight%20-%20LQ.mp3",
                      '"Midnight" by Anton Revin (CC0) https://opengameart.org/content/midnight'),
    "ending.mp3": ("https://opengameart.org/sites/default/files/starfield_romance_5.mp3",
                   '"Starfield Romance" by Yoiyami (CC0) https://opengameart.org/node/182246'),
}


# ---------------------------------------------------------------- io

def fetch(url, dest):
    if not os.path.exists(dest):
        print("downloading", os.path.basename(dest))
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req) as r, open(dest, "wb") as f:
            shutil.copyfileobj(r, f)
    return dest


def kenney(pack):
    """Kenney packs are downloaded by hand (kenney.nl hands out one-time links)."""
    folder = os.path.join(CACHE, "kenney-" + pack)
    zip_path = folder + ".zip"
    if not os.path.isdir(folder) and os.path.exists(zip_path):
        with zipfile.ZipFile(zip_path) as z:
            z.extractall(folder)
    if not os.path.isdir(os.path.join(folder, "Audio")):
        raise SystemExit(f"Download https://kenney.nl/assets/{pack} (free, CC0) and save the zip as\n  {zip_path}")
    return os.path.join(folder, "Audio")


def read(id_):
    """Mono float samples and sample rate of a BigSoundBank clip."""
    path = fetch(BSB.format(id_), os.path.join(CACHE, "bsb-" + id_ + ".wav"))
    with wave.open(path) as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if width == 2:
        vals = struct.unpack("<%dh" % (len(raw) // 2), raw)
        scale = 32768.0
    else:  # 24-bit
        vals = [int.from_bytes(raw[i:i + 3], "little", signed=True) for i in range(0, len(raw), 3)]
        scale = 8388608.0
    if ch == 2:
        vals = [(vals[i] + vals[i + 1]) / 2 for i in range(0, len(vals), 2)]
    return [v / scale for v in vals], rate


def write(folder, name, data, rate, peak=0.9):
    m = max(1e-9, max(abs(s) for s in data))
    g = peak / m
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * g)) * 32767)) for s in data))
    print("wrote", os.path.relpath(path, ROOT), f"{len(data) / rate:.1f}s")


def copy(src, folder, name):
    ext = os.path.splitext(src)[1]
    shutil.copyfile(src, os.path.join(folder, name + ext))
    print("copied", name + ext)


# ---------------------------------------------------------------- editing

def cut(data, rate, start, end):
    return data[int(start * rate):int(end * rate)]


def fade(data, rate, fin=0.005, fout=0.05):
    a, b = int(fin * rate), int(fout * rate)
    out = data[:]
    for i in range(min(a, len(out))):
        out[i] *= i / a
    for i in range(min(b, len(out))):
        out[-1 - i] *= i / b
    return out


def loop(data, rate, xfade=1.0):
    k = int(xfade * rate)
    body = data[:-k]
    for i in range(k):
        t = i / k
        body[i] = body[i] * t + data[len(data) - k + i] * (1 - t)
    return body


def envelope(data, rate, hop=0.01):
    h = int(hop * rate)
    return [math.sqrt(sum(x * x for x in data[i:i + h]) / h) for i in range(0, len(data) - h, h)], h


def events(data, rate, rel=0.25, min_gap=0.08):
    """(start, end) sample ranges where the sound rises above `rel` x peak level."""
    env, h = envelope(data, rate)
    thr = max(env) * rel
    out, start, quiet = [], None, 0
    for i, e in enumerate(env):
        if e >= thr:
            if start is None:
                start = i
            quiet = 0
        elif start is not None:
            quiet += 1
            if quiet * h / rate >= min_gap:
                out.append((max(0, start * h - h), (i - quiet + 1) * h + h))
                start = None
    if start is not None:
        out.append((start * h, len(data)))
    return out


def loudest(data, rate, seconds):
    env, h = envelope(data, rate)
    w = max(1, int(seconds * rate / h))
    best = max(range(len(env) - w), key=lambda i: sum(env[i:i + w]))
    return data[best * h:best * h + int(seconds * rate)]


def pitch_shift(data, ratio):
    n = int(len(data) / ratio)
    out = []
    for i in range(n):
        x = i * ratio
        j = int(x)
        if j + 1 >= len(data):
            break
        f = x - j
        out.append(data[j] * (1 - f) + data[j + 1] * f)
    return out


def detect_f0(data, rate):
    seg = data[int(0.02 * rate):int(0.02 * rate) + 2048]
    best, lag = 0, 1
    for l in range(rate // 3000, rate // 200):
        c = sum(seg[i] * seg[i + l] for i in range(0, len(seg) - l, 2))
        if c > best:
            best, lag = c, l
    return rate / lag


# ---------------------------------------------------------------- clips

def sound_effects():
    impact = kenney("impact-sounds")
    rpg = kenney("rpg-audio")
    for i in range(4):
        copy(os.path.join(impact, f"footstep_wood_00{i}.ogg"), SFX, f"footstep_wood_{i + 1}")
        copy(os.path.join(rpg, f"footstep0{i}.ogg"), SFX, f"footstep_porch_{i + 1}")
    for i in range(3):
        copy(os.path.join(impact, f"impactWood_medium_00{i}.ogg"), SFX, f"knock_{i + 1}")
    copy(os.path.join(rpg, "handleCoins.ogg"), SFX, "dog_tags")

    d, r = read("3205")
    write(SFX, "door_open", fade(d, r, 0.01, 0.3), r)
    d, r = read("3206")
    write(SFX, "door_close", fade(d, r, 0.01, 0.3), r)

    d, r = read("0026")
    s, e = events(d, r)[0]
    write(SFX, "switch_click", fade(d[s:e + int(0.05 * r)], r), r)
    d, r = read("0540")
    s, e = max(events(d, r), key=lambda ev: max(abs(x) for x in d[ev[0]:ev[1]]))
    write(SFX, "light_out", fade(d[s:e + int(0.1 * r)], r), r)

    d, r = read("0007")
    ev = events(d, r, 0.3, 0.2)
    k = len(ev) - 1 if (len(ev) - 1) % 2 == 0 else len(ev) - 2
    write(SFX, "clock_tick", d[ev[0][0]:ev[k][0]], r, 0.5)

    d, r = read("1880")
    write(SFX, "crickets", loop(cut(d, r, 60, 82), r), r, 0.6)
    d, r = read("0904")
    write(SFX, "wind", loop(cut(d, r, 40, 64), r, 2.0), r, 0.6)
    d, r = read("0034")
    write(SFX, "room_tone", loop(cut(d, r, 0.5, 8.5), r), r, 0.4)
    d, r = read("1037")
    write(SFX, "tv_static", loop(cut(d, r, 10, 14), r, 0.3), r, 0.4)
    d, r = read("2134")
    write(SFX, "tv_zap", fade(d, r), r, 0.6)
    d, r = read("1783")
    write(SFX, "tv_off", fade(d, r, 0.002, 0.02), r, 0.7)
    d, r = read("0844")
    write(SFX, "candy_rustle", fade(loudest(d, r, 1.2), r, 0.02, 0.2), r)

    # dog: two single barks from an older dog, a growl, and a whine
    d, r = read("2352")
    barks = [ev for ev in events(d, r, 0.3, 0.12) if 0.08 * r < ev[1] - ev[0] < 0.7 * r]
    barks.sort(key=lambda ev: -max(abs(x) for x in d[ev[0]:ev[1]]))
    if len(barks) < 2:
        d2, r2 = read("2955")
        barks2 = [ev for ev in events(d2, r2, 0.3, 0.12) if 0.08 * r2 < ev[1] - ev[0] < 0.7 * r2]
        write(SFX, "dog_bark_2", fade(d2[barks2[0][0]:barks2[0][1] + int(0.25 * r2)], r2, 0.003, 0.2), r2)
    else:
        write(SFX, "dog_bark_2", fade(d[barks[1][0]:barks[1][1] + int(0.25 * r)], r, 0.003, 0.2), r)
    write(SFX, "dog_bark_1", fade(d[barks[0][0]:barks[0][1] + int(0.25 * r)], r, 0.003, 0.2), r)

    d, r = read("1060")
    write(SFX, "dog_growl", fade(_growl(d, r), r, 0.1, 0.3), r)
    d, r = read("2450")
    write(SFX, "dog_whine", fade(d, r, 0.02, 0.2), r)

    # the drive home
    d, r = read("3098")
    write(SFX, "car_interior", loop(cut(d, r, 5, 29), r, 2.0), r, 0.6)
    d, r = read("1021")
    ev = events(d, r, 0.3, 0.15)
    k = len(ev) - 1 if (len(ev) - 1) % 2 == 0 else len(ev) - 2
    write(SFX, "blinker", d[ev[0][0]:ev[max(k, 2)][0]], r, 0.5)
    d, r = read("0971")
    write(SFX, "car_door", fade(loudest(d, r, 1.2), r, 0.01, 0.3), r)


def _growl(data, rate):
    """Longest stretch of steady, low-pitched (low zero-crossing) sound."""
    hop = int(0.05 * rate)
    frames = []
    for i in range(0, len(data) - hop, hop):
        f = data[i:i + hop]
        e = math.sqrt(sum(x * x for x in f) / hop)
        z = sum(1 for a, b in zip(f, f[1:]) if (a < 0) != (b < 0)) / hop
        frames.append((e, z))
    emax = max(e for e, _ in frames)
    zs = sorted(z for e, z in frames if e > emax * 0.08)
    zlow = zs[len(zs) // 3] if zs else 1
    best, cur, best_end = 0, 0, 0
    for i, (e, z) in enumerate(frames):
        cur = cur + 1 if (e > emax * 0.08 and z <= zlow) else 0
        if cur > best:
            best, best_end = cur, i
    start = max(0, best_end - max(best, 20) + 1) * hop
    return data[start:start + max(best, 20) * hop]


def lullaby():
    """Chapter 1: a little waltz played on real music-box notes."""
    random.seed(1)
    samples = []
    for id_ in ("1866", "1867", "1868", "1869", "1870", "1871", "1872", "1874", "1875"):
        d, r = read(id_)
        s = events(d, r, 0.1)[0][0]
        d = d[s:]
        midi = 69 + 12 * math.log2(detect_f0(d, r) / 440)
        samples.append((midi, d, r))
    rate = samples[0][2]

    def note(m, vel):
        src_midi, d, r = min(samples, key=lambda s: abs(s[0] - m))
        out = pitch_shift(d, 2 ** ((m - src_midi) / 12) * r / rate)
        return [x * vel for x in fade(out[:int(2.5 * rate)], rate, 0.001, 0.4)]

    beat = 60 / 76
    chords = ["C", "Am", "F", "G", "C", "Em", "F", "G", "Am", "F", "C", "G", "F", "G", "C", "C"]
    tones = {"C": [60, 64, 67], "Am": [57, 60, 64], "F": [53, 57, 60], "G": [55, 59, 62], "Em": [52, 55, 59]}
    out = [0.0] * int(len(chords) * 3 * beat * rate)

    def put(m, t, vel):
        n = note(m, vel)
        start = int(t * rate)
        for i, x in enumerate(n):
            out[(start + i) % len(out)] += x

    prev = 76
    for b, ch in enumerate(chords):
        t0 = b * 3 * beat
        tri = tones[ch]
        put(tri[0] + 12, t0, 0.45)
        put(tri[1] + 12, t0 + beat, 0.2)
        put(tri[2] + 12, t0 + 2 * beat, 0.2)
        cands = sorted((n + 24 for n in tri if 72 <= n + 24 <= 88), key=lambda n: abs(n - prev) + random.random() * 4)
        cands = cands or [n + 12 for n in tri]
        melody = cands[0]
        put(melody, t0, 0.8)
        if random.random() < 0.6:
            put(melody + random.choice([-2, -1, 2]), t0 + 1.5 * beat, 0.5)
        if random.random() < 0.7:
            put(cands[min(1, len(cands) - 1)], t0 + 2 * beat, 0.55)
        prev = melody
    write(MUSIC, "ch1_living_room", _reverb(out, 0.3, 1.2, wrap=True), rate, 0.7)

    sting = [0.0] * int(5 * rate)
    for i, m in enumerate([57, 64, 69, 72, 76]):
        n = note(m + 12, 0.7)
        for j, x in enumerate(n):
            k = int(i * 0.12 * rate) + j
            if k < len(sting):
                sting[k] += x
    write(SFX, "title_sting", _reverb(sting, 0.5, 1.4)[:len(sting)], rate, 0.8)


def music():
    lines = []
    for name, (url, credit) in OGA_MUSIC.items():
        src = fetch(url, os.path.join(CACHE, "oga-" + name))
        shutil.copyfile(src, os.path.join(MUSIC, name))
        print("copied", name)
        lines.append(f"- `audio/music/{name}`: {credit}")
    return lines


def credits(music_lines):
    bsb = "\n".join(f"- #{k} {v}: https://bigsoundbank.com/s{k}.html" for k, v in BSB_SOUNDS.items())
    text = f"""# Audio credits

Every recording here is CC0 (public domain). Attribution isn't required, but thanks to:

## Music
{chr(10).join(music_lines)}
- `audio/music/ch1_living_room.wav`: original lullaby, played on BigSoundBank music-box notes (below)

## Sound effects
- Kenney, Impact Sounds + RPG Audio (CC0): footsteps, knocks, dog tags. https://kenney.nl
- BigSoundBank by Joseph Sardin (CC0):
{bsb}

## Voices
Generated with Piper (https://github.com/rhasspy/piper) using the en_US lessac, ryan and
libritts_r voices. See tools/generate_voices.py.

## Synthesized
`tv_show`, `tv_ad`, `tv_signoff`, `bulb_flicker`: tools/generate_audio.py
"""
    with open(os.path.join(ROOT, "audio", "CREDITS.md"), "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote audio/CREDITS.md")


def main():
    os.makedirs(CACHE, exist_ok=True)
    os.makedirs(SFX, exist_ok=True)
    os.makedirs(MUSIC, exist_ok=True)
    sound_effects()
    lullaby()
    credits(music())


if __name__ == "__main__":
    main()
