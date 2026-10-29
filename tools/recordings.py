"""Real voice recordings: print a script to read from, then bring the takes into the game.

Usage:
    python tools/recordings.py script grandma         # lines to read, by speaker (or "all")
    python tools/recordings.py script grandma > grandma.md
    python tools/recordings.py import ~/Desktop/takes # files named <line id>.<ext>
    python tools/recordings.py status                 # what's recorded, what's still TTS

Name each take after its line id (gma_1.m4a, ch3_knock.wav...). Any format macOS can
read works (m4a from Voice Memos, wav, mp3, aiff, caf). Import converts to mono 16-bit
WAV, trims silence at both ends, evens out the level and writes audio/voice/<id>.wav.
Imported ids are listed in data/recorded.json: the game plays them at their natural
pitch (no TTS pitch nudge) and tools/generate_voices.py never overwrites them.
"""
import array
import json
import os
import shutil
import subprocess
import sys
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINES = os.path.join(ROOT, "data", "lines.json")
RECORDED = os.path.join(ROOT, "data", "recorded.json")
OUT = os.path.join(ROOT, "audio", "voice")

SPEAKER_NOTES = {
    "leo": "Leo, 8 years old. Quiet, it's the middle of the night; curious more than scared.",
    "grandma": "Grandma. Warm, unhurried, a little teasing. She's saying goodbye but won't let it be sad.",
    "mom": "Mom. Tired, loving. In chapter 3's morning she realizes where the candy came from.",
    "dad": "Dad. Sleepy, then worried when he can't find Leo.",
    "sibling": "Older sibling, shouting through a closed door.",
    "tv": "TV announcer, big and cheesy.",
}

TARGET_PEAK = 0.7       # of full scale, after normalizing
SILENCE = 0.02          # below this (of full scale) counts as silence when trimming
PAD = 0.12              # seconds of room tone kept at each end


def load_lines():
    with open(LINES, encoding="utf-8") as f:
        return {k: v for k, v in json.load(f).items() if not k.startswith("_")}


def load_recorded():
    if not os.path.exists(RECORDED):
        return []
    with open(RECORDED, encoding="utf-8") as f:
        return json.load(f)


def script(speaker):
    lines = load_lines()
    speakers = sorted({l["speaker"] for l in lines.values()}) if speaker == "all" else [speaker]
    for spk in speakers:
        mine = [(k, l) for k, l in lines.items() if l["speaker"] == spk]
        if not mine:
            sys.exit(f"no lines for speaker '{spk}'")
        print(f"# {spk.title()} ({len(mine)} lines)\n")
        if spk in SPEAKER_NOTES:
            print(f"_{SPEAKER_NOTES[spk]}_\n")
        print("Save each take as the file name shown. One line per file; leave a beat of silence before and after.\n")
        for k, l in mine:
            # The line before, so the reader knows what they're answering.
            before = [p for p, pl in lines.items() if pl.get("next") == k and pl["speaker"] != spk]
            if before:
                prev = lines[before[0]]
                print(f"> {prev['speaker'].title()}: {prev['text']}\n")
            print(f"**{k}**.m4a\n\n    {l['text']}\n")
        print()


def to_wav(src, dst):
    """Any format -> mono 16-bit 44.1k WAV, via macOS afconvert (or ffmpeg)."""
    if shutil.which("afconvert"):
        cmd = ["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1", src, dst]
    elif shutil.which("ffmpeg"):
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", src, "-ac", "1", "-ar", "44100", "-sample_fmt", "s16", dst]
    else:
        sys.exit("Need afconvert (macOS) or ffmpeg to convert recordings.")
    subprocess.run(cmd, check=True)


def clean(path):
    """Trim silence at the ends (keeping a little padding) and normalize the peak."""
    with wave.open(path, "rb") as w:
        rate = w.getframerate()
        samples = array.array("h", w.readframes(w.getnframes()))
    if sys.byteorder == "big":
        samples.byteswap()
    if not samples:
        return 0.0
    threshold = int(32767 * SILENCE)
    loud = [i for i, s in enumerate(samples) if abs(s) > threshold]
    if loud:
        pad = int(PAD * rate)
        samples = samples[max(0, loud[0] - pad):min(len(samples), loud[-1] + pad)]
    peak = max(abs(s) for s in samples) or 1
    gain = TARGET_PEAK * 32767 / peak
    samples = array.array("h", (max(-32768, min(32767, int(s * gain))) for s in samples))
    # Short fades so the trim never clicks.
    fade = min(int(0.01 * rate), len(samples) // 2)
    for i in range(fade):
        k = i / fade
        samples[i] = int(samples[i] * k)
        samples[-1 - i] = int(samples[-1 - i] * k)
    if sys.byteorder == "big":
        samples.byteswap()
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(samples.tobytes())
    return len(samples) / rate


def import_takes(folder):
    lines = load_lines()
    recorded = set(load_recorded())
    os.makedirs(OUT, exist_ok=True)
    done, skipped = [], []
    for name in sorted(os.listdir(folder)):
        line_id, ext = os.path.splitext(name)
        if name.startswith(".") or not ext:
            continue
        if line_id not in lines:
            skipped.append(name)
            continue
        dst = os.path.join(OUT, line_id + ".wav")
        with tempfile.TemporaryDirectory() as tmp:
            wav = os.path.join(tmp, "take.wav")
            to_wav(os.path.join(folder, name), wav)
            length = clean(wav)
            shutil.move(wav, dst)
        # A leftover .ogg/.mp3 with the same name would win in-game.
        for other in (".ogg", ".mp3"):
            stale = os.path.join(OUT, line_id + other)
            if os.path.exists(stale):
                os.remove(stale)
        recorded.add(line_id)
        done.append(line_id)
        print(f"  {line_id:<20} {length:5.1f}s  {lines[line_id]['text'][:50]}")
    with open(RECORDED, "w", encoding="utf-8") as f:
        json.dump(sorted(recorded), f, indent=1)
        f.write("\n")
    print(f"imported {len(done)} take(s) into {os.path.relpath(OUT, ROOT)}")
    if skipped:
        print("skipped (not a line id in data/lines.json):", ", ".join(skipped))
    if done:
        print("Open the project in Godot so it re-imports the new files.")


def status():
    lines = load_lines()
    recorded = set(load_recorded())
    by_spk = {}
    for k, l in lines.items():
        by_spk.setdefault(l["speaker"], []).append(k)
    for spk, ids in sorted(by_spk.items()):
        real = [k for k in ids if k in recorded]
        print(f"{spk:<8} {len(real):>2}/{len(ids):<2} recorded")
        missing = [k for k in ids if k not in recorded]
        if real and missing:
            print("         still TTS:", ", ".join(missing))


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("script", "import", "status"):
        sys.exit(__doc__)
    if args[0] == "script":
        script(args[1] if len(args) > 1 else "all")
    elif args[0] == "import":
        folder = os.path.expanduser(args[1]) if len(args) > 1 else ""
        if not os.path.isdir(folder):
            sys.exit("usage: python tools/recordings.py import <folder of takes>")
        import_takes(folder)
    else:
        status()


if __name__ == "__main__":
    main()
