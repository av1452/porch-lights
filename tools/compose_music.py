"""Composes the stand-in themes from the story bible that don't have a recording
yet, so no scene borrows another scene's music. All original, written here as
note lists and synthesized (no samples, no outside music).

    grandma_house   Thanksgiving at Grandma's: a slow, warm waltz
    drive_home      the night drive home: electric piano, gentle
    class_party     the classroom party: glockenspiel and pizzicato bass
    snow_dream      the snowy school dream: soft pad, falling celesta notes
    static_parade   Jamie's band, through one earbud: 2000s pop-punk

And the radio songs: public-domain holiday music (the compositions are
traditional or 100+ years old), arranged and synthesized here, so there are
no recording rights to worry about. They play on the kitchen radio, the car
radio, and the TV at midnight (scripts/radio.gd).

    radio_mountain_king   Grieg, "In the Hall of the Mountain King" (1875)   Halloween
    radio_toccata         Bach, Toccata in D minor (opening)                 Halloween
    radio_deck_the_halls  "Deck the Halls" (traditional Welsh)              Christmas
    radio_we_wish_you     "We Wish You a Merry Christmas" (traditional)     Christmas
    radio_wenceslas       "Good King Wenceslas" (1853)                      Christmas
    radio_auld_lang_syne  "Auld Lang Syne" (traditional Scottish)           New Year's

To use the real track, drop it in audio/music/ with the same name (.ogg,
.mp3 or .wav); delete the stand-in .wav so the real one isn't shadowed.

Usage:  python tools/compose_music.py               # all of them
        python tools/compose_music.py drive_home    # just the named ones
        python tools/compose_music.py radio_toccata
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_audio import SR, ROOT, TAU, buf, mix, midi, lowpass, reverb, write  # noqa: E402

OUT = os.path.join(ROOT, "audio", "music")

# Note names → MIDI numbers, so melodies read like music.
NOTES = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
         "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def n(name):
    """'F4' → 65. '-' is a rest (None)."""
    if name == "-":
        return None
    pitch, octave = name[:-1], int(name[-1])
    return 12 * (octave + 1) + NOTES[pitch]


# ---------------------------------------------------------------- instruments

def piano(f, dur, vel=1.0):
    """A soft, warm piano-ish tone: a few harmonics with a gentle decay."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        env = math.exp(-t * 2.2) * min(1.0, t * 300) * min(1.0, (dur - t) * 12)
        s = (math.sin(TAU * f * t) + 0.35 * math.sin(TAU * 2 * f * t) * math.exp(-t * 3)
             + 0.12 * math.sin(TAU * 3 * f * t) * math.exp(-t * 5))
        out.append(s * env * vel * 0.35)
    return out


def epiano(f, dur, vel=1.0):
    """Electric piano: a bell-ish FM tone that mellows as it rings."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        mod = math.sin(TAU * f * t) * 1.4 * math.exp(-t * 4)
        env = math.exp(-t * 1.6) * min(1.0, t * 200) * min(1.0, (dur - t) * 10)
        out.append(math.sin(TAU * f * t + mod) * env * vel * 0.3)
    return out


def glock(f, dur, vel=1.0):
    """Glockenspiel / celesta: bright, pure, ringing."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        env = math.exp(-t * 3.0) * min(1.0, t * 800)
        s = math.sin(TAU * f * t) + 0.25 * math.sin(TAU * 2.76 * f * t) * math.exp(-t * 8)
        out.append(s * env * vel * 0.3)
    return out


def pluck(f, dur, vel=1.0):
    """Pizzicato bass: a quick thump that dies away."""
    k = int(dur * SR)
    return [math.sin(TAU * f * (i / SR)) * math.exp(-(i / SR) * 9) * min(1.0, i / 40) * vel * 0.5 for i in range(k)]


def pad(freqs, dur, vel=1.0, bright=0.3):
    """A soft chord pad: slightly detuned tones that swell in and out."""
    k = int(dur * SR)
    out = [0.0] * k
    for f in freqs:
        for det in (0.997, 1.003):
            ph = random.random() * TAU
            for i in range(k):
                t = i / SR
                s = math.sin(TAU * f * det * t + ph) + bright * math.sin(TAU * 2 * f * det * t)
                out[i] += s
    swell = min(1.2, dur / 3)
    g = vel * 0.08 / max(1, len(freqs))
    return [s * g * min(1.0, (i / SR) / swell) * min(1.0, (dur - i / SR) / swell) for i, s in enumerate(out)]


def power_chord(f, dur, vel=1.0):
    """Overdriven guitar power chord (root + fifth + octave), palm-muted-ish."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        s = 0.0
        for mult in (1.0, 1.498, 2.0):
            ph = (f * mult * t) % 1.0
            s += 2.0 * ph - 1.0  # sawtooth
        s = math.tanh(s * 2.2)
        env = min(1.0, t * 400) * min(1.0, (dur - t) * 40) * (0.75 + 0.25 * math.exp(-t * 6))
        out.append(s * env * vel * 0.18)
    return lowpass(out, 2600)


def lead(f, dur, vel=1.0):
    """A square-wave lead line, slightly soft."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        s = 1.0 if (f * t) % 1.0 < 0.5 else -1.0
        env = min(1.0, t * 300) * min(1.0, (dur - t) * 30)
        out.append(s * env * vel * 0.08)
    return lowpass(out, 3200)


def kick():
    k = int(0.25 * SR)
    return [math.sin(TAU * (50 + 90 * math.exp(-i / SR * 30)) * i / SR) * math.exp(-i / SR * 14) * 0.9 for i in range(k)]


def snare():
    k = int(0.2 * SR)
    rnd = random.Random(3)
    return [(rnd.uniform(-1, 1) * 0.7 + math.sin(TAU * 190 * i / SR) * 0.3) * math.exp(-i / SR * 18) * 0.6 for i in range(k)]


def hat():
    k = int(0.06 * SR)
    rnd = random.Random(5)
    raw = [rnd.uniform(-1, 1) for _ in range(k)]
    hp = [raw[i] - raw[i - 1] if i else 0.0 for i in range(k)]
    return [s * math.exp(-i / SR * 60) * 0.25 for i, s in enumerate(hp)]


# ---------------------------------------------------------------- helpers

def place(out, inst, notes, start_beat, beat, vel=1.0, gap=0.95):
    """notes: list of (name or [names], beats). Plays them in order from start_beat."""
    t = start_beat
    for names, beats in notes:
        if not isinstance(names, list):
            names = [names]
        for name in names:
            m = n(name)
            if m is not None:
                mix(out, inst(midi(m), beats * beat * gap, vel), t * beat, wrap=True)
        t += beats
    return t


def chord(names):
    return [midi(n(x)) for x in names]


def finish(name, data, wet=0.25, size=1.0, peak=0.8):
    data = reverb(data, wet, size, wrap=True)
    write(os.path.join(OUT, name + ".wav"), data, peak)


# ---------------------------------------------------------------- the themes

def grandma_house():
    """A slow waltz in F: Grandma's kitchen, the good dishes, everybody talking at once."""
    random.seed(1)
    bpm = 84
    beat = 60 / bpm
    bars = [("F", ["A3", "C4"]), ("Bb", ["Bb3", "D4"]), ("C", ["Bb3", "E4"]), ("F", ["A3", "C4"]),
            ("D", ["A3", "D4"]), ("G", ["Bb3", "D4"]), ("C", ["Bb3", "E4"]), ("F", ["A3", "C4"])] * 2
    out = buf(len(bars) * 3 * beat)
    for b, (root, upper) in enumerate(bars):
        bass = {"F": "F2", "Bb": "Bb2", "C": "C3", "D": "D3", "G": "G2"}[root]
        place(out, piano, [(bass, 1), (upper, 1), (upper, 1)], b * 3, beat, 0.8)
    melody = [("C5", 2), ("A4", 1), ("D5", 2), ("Bb4", 1), ("C5", 1.5), ("Bb4", 0.5), ("G4", 1), ("A4", 3),
              ("D5", 2), ("F5", 1), ("D5", 2), ("Bb4", 1), ("A4", 1), ("G4", 1), ("E4", 1), ("F4", 3),
              ("A4", 2), ("C5", 1), ("F5", 2), ("E5", 1), ("D5", 1.5), ("C5", 0.5), ("Bb4", 1), ("A4", 3),
              ("Bb4", 2), ("D5", 1), ("C5", 2), ("A4", 1), ("G4", 1), ("A4", 1), ("E4", 1), ("F4", 3)]
    place(out, piano, melody, 0, beat, 1.0)
    finish("grandma_house", out, 0.3, 1.0)


def drive_home():
    """Night drive: slow electric piano chords, a melody that doesn't hurry."""
    random.seed(2)
    bpm = 66
    beat = 60 / bpm
    prog = [["A2", "E3", "A3", "C4", "E4"], ["F2", "C3", "F3", "A3", "E4"], ["C3", "G3", "C4", "E4", "G4"], ["G2", "D3", "G3", "B3", "D4"]] * 4
    out = buf(len(prog) * 4 * beat)
    for b, ch in enumerate(prog):
        place(out, epiano, [(ch, 4)], b * 4, beat, 0.6, 1.0)
        mix(out, pad(chord(ch[1:4]), 4 * beat, 0.6, 0.15), b * 4 * beat, wrap=True)
    melody = [("E5", 3), ("D5", 1), ("C5", 4), ("-", 2), ("A4", 1), ("C5", 1), ("D5", 4),
              ("E5", 2), ("G5", 2), ("E5", 3), ("D5", 1), ("B4", 4), ("-", 4),
              ("A4", 2), ("C5", 2), ("E5", 4), ("F5", 2), ("E5", 1), ("C5", 1), ("C5", 4),
              ("G4", 2), ("C5", 2), ("D5", 3), ("C5", 1), ("A4", 8)]
    place(out, epiano, melody, 0, beat, 0.9)
    finish("drive_home", lowpass(out, 5000), 0.35, 1.2)


def class_party():
    """Classroom party: bright glockenspiel, bouncing bass, a little sleigh bell."""
    random.seed(3)
    bpm = 122
    beat = 60 / bpm
    prog = ["C", "Am", "F", "G"] * 4
    roots = {"C": ("C2", "G2"), "Am": ("A2", "E2"), "F": ("F2", "C3"), "G": ("G2", "D3")}
    out = buf(len(prog) * 4 * beat)
    for b, c in enumerate(prog):
        r, fifth = roots[c]
        place(out, pluck, [(r, 1), (fifth, 1), (r, 1), (fifth, 1)], b * 4, beat, 0.9)
    tune = [("E5", 1), ("G5", 1), ("C6", 1), ("G5", 1), ("A5", 1.5), ("G5", 0.5), ("E5", 2),
            ("F5", 1), ("A5", 1), ("G5", 1), ("E5", 1), ("D5", 3), ("-", 1),
            ("E5", 1), ("G5", 1), ("C6", 1), ("D6", 1), ("E6", 1.5), ("D6", 0.5), ("C6", 2),
            ("A5", 1), ("G5", 1), ("E5", 1), ("D5", 1), ("C5", 3), ("-", 1)]
    place(out, glock, tune * 2, 0, beat, 1.0)
    # sleigh-bell shake on the off-beats
    rnd = random.Random(9)
    bell = [rnd.uniform(-1, 1) * math.exp(-i / SR * 25) * 0.12 for i in range(int(0.12 * SR))]
    for k in range(len(prog) * 4):
        mix(out, bell, (k + 0.5) * beat, wrap=True)
    finish("class_party", out, 0.18, 0.8)


def snow_dream():
    """Snow falling indoors: a slow pad and celesta notes that drift down."""
    random.seed(4)
    bpm = 56
    beat = 60 / bpm
    prog = [["E3", "B3", "G4"], ["C3", "G3", "E4", "B4"], ["A2", "E3", "C4", "G4"], ["B2", "F#3", "D#4"]] * 2
    out = buf(len(prog) * 4 * beat)
    for b, ch in enumerate(prog):
        mix(out, pad(chord(ch), 4 * beat, 1.2, 0.2), b * 4 * beat, wrap=True)
    scale = ["E5", "F#5", "G5", "B5", "D6", "E6", "G6"]
    rnd = random.Random(11)
    t = 0.5
    while t < len(prog) * 4:
        mix(out, glock(midi(n(rnd.choice(scale))), 2.5, rnd.uniform(0.35, 0.7)), t * beat, wrap=True)
        t += rnd.choice([0.75, 1.0, 1.5, 2.0])
    finish("snow_dream", lowpass(out, 6000), 0.5, 1.6, 0.7)


def static_parade():
    """Jamie's band: crunchy power chords, bass, drums, a lead that sticks in your head."""
    random.seed(5)
    bpm = 148
    beat = 60 / bpm
    prog = ["D3", "A2", "B2", "G2"] * 4
    out = buf(len(prog) * 4 * beat)
    k_, s_, h_ = kick(), snare(), hat()
    for b, root in enumerate(prog):
        for e in range(8):
            mix(out, power_chord(midi(n(root)), beat * 0.48, 0.9 if e % 2 == 0 else 0.7), (b * 4 + e * 0.5) * beat, wrap=True)
            mix(out, pluck(midi(n(root) - 12), beat * 0.45, 0.8), (b * 4 + e * 0.5) * beat, wrap=True)
            mix(out, h_, (b * 4 + e * 0.5) * beat, wrap=True)
        for q in range(4):
            mix(out, k_ if q % 2 == 0 else s_, (b * 4 + q) * beat, wrap=True)
    hook = [("F#5", 1), ("F#5", 0.5), ("E5", 0.5), ("D5", 1), ("A4", 1), ("E5", 1.5), ("D5", 0.5), ("C#5", 2),
            ("D5", 1), ("D5", 0.5), ("E5", 0.5), ("F#5", 1), ("A5", 1), ("G5", 1.5), ("F#5", 0.5), ("E5", 2)]
    place(out, lead, [("-", 16)] + hook * 3, 0, beat, 1.0)
    finish("static_parade", out, 0.12, 0.7, 0.85)


# ---------------------------------------------------------------- radio songs

def organ(f, dur, vel=1.0):
    """Church organ: stacked harmonics, steady, with a little tremolo."""
    k = int(dur * SR)
    out = []
    for i in range(k):
        t = i / SR
        s = 0.0
        for h, a in ((1, 1.0), (2, 0.6), (3, 0.3), (4, 0.25), (6, 0.12), (8, 0.08)):
            s += a * math.sin(TAU * f * h * t)
        env = min(1.0, t * 40) * min(1.0, (dur - t) * 20) * (1 + 0.04 * math.sin(TAU * 5.5 * t))
        out.append(s * env * vel * 0.12)
    return out


def bells(f, dur, vel=1.0):
    """Sleigh-bell-bright melody voice: glockenspiel over a soft piano."""
    a = glock(f, dur, vel * 0.6)
    b = piano(f, dur, vel * 0.8)
    return [x + y for x, y in zip(a, b)]


def song(melody, chords, bpm, beats_per_bar, voice=bells, bass=pluck, comp=piano, swing_bells=True, pickup=0.0):
    """A carol arrangement: melody, bass on the downbeats, chords on the off-beats,
    sleigh bells on every beat. `chords` is one chord (list of names) per bar."""
    beat = 60 / bpm
    total = pickup + len(chords) * beats_per_bar
    out = buf(total * beat + 2.0)
    for b, ch in enumerate(chords):
        start = pickup + b * beats_per_bar
        root = midi(n(ch[0]) - 12)
        mix(out, bass(root, beat * 0.9, 0.9), start * beat)
        if beats_per_bar == 4:
            mix(out, bass(midi(n(ch[0]) - 5), beat * 0.9, 0.7), (start + 2) * beat)
        for off in range(1, beats_per_bar):
            for name in ch[1:]:
                mix(out, comp(midi(n(name)), beat * 0.8, 0.35), (start + off) * beat)
    place(out, voice, melody, 0, beat, 1.0)
    if swing_bells:
        rnd = random.Random(7)
        bell = [rnd.uniform(-1, 1) * math.exp(-i / SR * 22) * 0.1 for i in range(int(0.15 * SR))]
        for k in range(int(total)):
            mix(out, bell, k * beat)
    return out


def deck_the_halls():
    a = [("G4", 1.5), ("F4", 0.5), ("E4", 1), ("D4", 1), ("C4", 1), ("D4", 1), ("E4", 1), ("C4", 1),
         ("D4", 0.5), ("E4", 0.5), ("F4", 0.5), ("D4", 0.5), ("E4", 1.5), ("D4", 0.5), ("C4", 1), ("B3", 1), ("C4", 2)]
    b = [("D4", 1.5), ("E4", 0.5), ("F4", 1), ("D4", 1), ("E4", 1.5), ("F4", 0.5), ("G4", 1), ("D4", 1),
         ("E4", 0.5), ("F#4", 0.5), ("G4", 1), ("A4", 0.5), ("B4", 0.5), ("C5", 1), ("B4", 1), ("A4", 1), ("G4", 2)]
    c = [("G4", 1.5), ("F4", 0.5), ("E4", 1), ("D4", 1), ("C4", 1), ("D4", 1), ("E4", 1), ("C4", 1),
         ("A4", 0.5), ("A4", 0.5), ("A4", 0.5), ("A4", 0.5), ("G4", 1.5), ("F4", 0.5), ("E4", 1), ("D4", 1), ("C4", 2)]
    C, G, F, D = ["C4", "E4", "G4"], ["G3", "B3", "D4"], ["F3", "A3", "C4"], ["D4", "F#4", "A4"]
    chords_a = [C, C, G, C]
    melody = [(x, y) for x, y in a + a + b + c]
    out = song([(nm.replace("4", "5").replace("3", "4"), d) for nm, d in melody], chords_a * 2 + [G, C, D, G] + [C, C, F, C], 112, 4)
    finish("radio_deck_the_halls", out, 0.2, 0.9)


def we_wish_you():
    m = [("D4", 1), ("G4", 1), ("G4", 0.5), ("A4", 0.5), ("G4", 0.5), ("F#4", 0.5), ("E4", 1), ("E4", 1), ("E4", 1),
         ("A4", 1), ("A4", 0.5), ("B4", 0.5), ("A4", 0.5), ("G4", 0.5), ("F#4", 1), ("D4", 1), ("D4", 1),
         ("B4", 1), ("B4", 0.5), ("C5", 0.5), ("B4", 0.5), ("A4", 0.5), ("G4", 1), ("E4", 1), ("D4", 0.5), ("D4", 0.5),
         ("E4", 1), ("A4", 1), ("F#4", 1), ("G4", 2), ("-", 1)]
    G, Cc, A7, D, B7, Em = ["G3", "B3", "D4"], ["C4", "E4", "G4"], ["A3", "C#4", "G4"], ["D4", "F#4", "A4"], ["B3", "D#4", "A4"], ["E3", "G3", "B3"]
    melody = [(nm if nm == "-" else nm[:-1] + str(int(nm[-1]) + 1), d) for nm, d in m]
    out = song(melody, [G, Cc, A7, D, B7, Em, D, G], 132, 3, pickup=1.0)
    finish("radio_we_wish_you", out, 0.2, 0.9)


def wenceslas():
    v = [("G4", 1), ("G4", 1), ("G4", 1), ("A4", 1), ("G4", 1), ("G4", 1), ("D4", 2),
         ("E4", 1), ("D4", 1), ("E4", 1), ("F#4", 1), ("G4", 2), ("G4", 2)]
    w = [("D5", 1), ("C5", 1), ("B4", 1), ("A4", 1), ("B4", 1), ("A4", 1), ("G4", 2),
         ("E4", 1), ("D4", 1), ("E4", 1), ("F#4", 1), ("G4", 2), ("G4", 2),
         ("D4", 1), ("D4", 1), ("E4", 1), ("F#4", 1), ("G4", 1), ("G4", 1), ("A4", 2),
         ("D5", 1), ("C5", 1), ("B4", 1), ("A4", 1), ("G4", 2), ("C5", 2), ("G4", 4)]
    G, D, Cc = ["G3", "B3", "D4"], ["D3", "F#3", "A3"], ["C4", "E4", "G4"]
    chords = [G, G, Cc, G] * 2 + [G, G, Cc, G, D, G, G, Cc, G]
    out = song(v + v + w, chords, 100, 4, voice=bells)
    finish("radio_wenceslas", out, 0.25, 1.0)


def auld_lang_syne():
    verse = [("C4", 1), ("F4", 1.5), ("F4", 0.5), ("F4", 1), ("A4", 1), ("G4", 1.5), ("F4", 0.5), ("G4", 1), ("A4", 1),
             ("F4", 1.5), ("F4", 0.5), ("A4", 1), ("C5", 1), ("D5", 3), ("D5", 1),
             ("C5", 1.5), ("A4", 0.5), ("A4", 1), ("F4", 1), ("G4", 1.5), ("F4", 0.5), ("G4", 1), ("A4", 0.5), ("G4", 0.5),
             ("F4", 1.5), ("D4", 0.5), ("D4", 1), ("C4", 1), ("F4", 3), ("D5", 1),
             ("C5", 1.5), ("A4", 0.5), ("A4", 1), ("F4", 1), ("G4", 1.5), ("F4", 0.5), ("G4", 1), ("D5", 1),
             ("C5", 1.5), ("A4", 0.5), ("A4", 1), ("C5", 1), ("D5", 3), ("F5", 1),
             ("C5", 1.5), ("A4", 0.5), ("A4", 1), ("F4", 1), ("G4", 1.5), ("F4", 0.5), ("G4", 1), ("A4", 0.5), ("G4", 0.5),
             ("F4", 1.5), ("D4", 0.5), ("D4", 1), ("C4", 1), ("F4", 4)]
    F, C, Bb, Dm = ["F3", "A3", "C4"], ["C3", "E3", "G3"], ["Bb3", "D4", "F4"], ["D3", "F3", "A3"]
    chords = [F, C, F, Bb, F, C, Dm, F, F, C, F, Bb, F, C, Dm, F]
    out = song(verse, chords, 76, 4, voice=piano, comp=pad_note, swing_bells=False, pickup=1.0)
    finish("radio_auld_lang_syne", out, 0.35, 1.2)


def pad_note(f, dur, vel=1.0):
    return pad([f], dur, vel * 2.0, 0.2)


def mountain_king():
    """Starts low and quiet, and keeps getting faster and louder."""
    phrase = [("B3", 0.5), ("C#4", 0.5), ("D4", 0.5), ("E4", 0.5), ("F#4", 0.5), ("D4", 0.5), ("F#4", 1),
              ("F4", 0.5), ("C#4", 0.5), ("F4", 1), ("E4", 0.5), ("C4", 0.5), ("E4", 1),
              ("B3", 0.5), ("C#4", 0.5), ("D4", 0.5), ("E4", 0.5), ("F#4", 0.5), ("D4", 0.5), ("F#4", 0.5), ("B4", 0.5),
              ("A4", 0.5), ("F#4", 0.5), ("D4", 0.5), ("F#4", 0.5), ("A4", 2)]
    parts = []
    for rep, (bpm, shift, vel) in enumerate([(100, -12, 0.5), (112, -12, 0.65), (126, 0, 0.8), (142, 0, 0.95), (160, 12, 1.0)]):
        beat = 60 / bpm
        seg = buf(16 * beat)
        mel = [(nm if nm == "-" else nm[:-1] + str(int(nm[-1]) + shift // 12), d) for nm, d in phrase]
        place(seg, pluck if rep < 2 else bells, mel, 0, beat, vel)
        for q in range(16):
            mix(seg, pluck(midi(n("B1") if q % 2 == 0 else n("F#1")), beat * 0.8, vel), q * beat)
        if rep >= 3:
            k_ = kick()
            for q in range(16):
                mix(seg, k_, q * beat, gain=0.5)
        parts.extend(seg)
    finish("radio_mountain_king", parts, 0.2, 1.0)


def toccata():
    """The famous opening flourish, on organ, with a low pedal underneath."""
    beat = 60 / 72
    out = buf(16 * beat + 3)
    t = 0.0
    for grp in ([("A5", 0.15), ("G5", 0.15), ("A5", 1.7)], [("G5", 0.25), ("F5", 0.25), ("E5", 0.25), ("D5", 0.25), ("C#5", 1.0), ("D5", 2.0)],
                [("A4", 0.15), ("G4", 0.15), ("A4", 1.7)], [("E4", 0.5), ("F4", 0.5), ("C#4", 0.5), ("D4", 2.0)],
                [("A3", 0.15), ("G3", 0.15), ("A3", 1.7)], [("G3", 0.25), ("F3", 0.25), ("E3", 0.25), ("D3", 0.25), ("C#3", 1.0), ("D3", 2.0)]):
        t = place(out, organ, grp, t, beat, 1.0, 1.0)
    mix(out, organ(midi(n("D2")), 4 * beat, 1.2), t * beat)
    for name in ("C#3", "E3", "G3", "Bb3"):
        mix(out, organ(midi(n(name)), 3 * beat, 0.8), (t + 1) * beat)
    for name in ("D3", "F#3", "A3", "D4"):
        mix(out, organ(midi(n(name)), 3 * beat, 0.9), (t + 4) * beat)
    finish("radio_toccata", out, 0.45, 1.8)


RADIO = {
    "radio_mountain_king": mountain_king,
    "radio_toccata": toccata,
    "radio_deck_the_halls": deck_the_halls,
    "radio_we_wish_you": we_wish_you,
    "radio_wenceslas": wenceslas,
    "radio_auld_lang_syne": auld_lang_syne,
}


THEMES = {
    "grandma_house": grandma_house,
    "drive_home": drive_home,
    "class_party": class_party,
    "snow_dream": snow_dream,
    "static_parade": static_parade,
}


def main():
    every = {**THEMES, **RADIO}
    names = sys.argv[1:] or list(every)
    for name in names:
        if name not in every:
            sys.exit(f"unknown theme '{name}'. Known: {', '.join(every)}")
        every[name]()


if __name__ == "__main__":
    main()
