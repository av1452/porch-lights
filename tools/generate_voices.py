"""Records every spoken line in the chapter scripts with Piper (offline neural TTS).

It finds dialogue in scripts/*.gd automatically:
  say([["Mom", "Candy tax. Rules are rules."], ...])     speaker/text pairs
  add_chatter(node, "Uncle Ray", ["...", "..."])          chatter lists
  var pool := [...]  ...  say([["Dad", pool[i]]])         random line pools
Narration (speaker "") stays silent text. Each line is saved as
audio/voice/<speaker>_<md5 of text>.wav, which is what scripts/audio.gd plays.

Usage:
    python tools/generate_voices.py --setup     # one time: download Piper + voices (~330 MB, gitignored)
    python tools/generate_voices.py             # record lines that don't have a file yet
    python tools/generate_voices.py --force     # re-record everything
    python tools/generate_voices.py --prune     # also delete recordings no script uses anymore
    python tools/generate_voices.py --list      # print every line and its file name

Real recordings dropped in with the same file name replace these.
"""
import glob
import hashlib
import os
import re
import subprocess
import sys
import urllib.request
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIPER_DIR = os.path.join(ROOT, "tools", "piper")
PIPER = os.path.join(PIPER_DIR, "piper", "piper.exe" if os.name == "nt" else "piper")
VOICES = os.path.join(PIPER_DIR, "voices")
OUT = os.path.join(ROOT, "audio", "voice")

PIPER_URL = "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip"
VOICE_URL = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/{0}/{1}/en_US-{0}-{1}.onnx"

# speaker key -> model, optional multi-speaker id, pace (length_scale: >1 slower),
# and expressiveness (noise_scale / noise_w: higher = more varied delivery).
# libritts_r speaker ids were picked by measured pitch (kids highest).
LIBRITTS = "libritts_r-medium"
SPEAKERS = {
    "mom": {"model": "lessac-high", "pace": 1.05, "noise": 0.7, "noise_w": 0.85},
    "dad": {"model": "ryan-high", "pace": 1.08, "noise": 0.7, "noise_w": 0.85},
    "jamie": {"model": LIBRITTS, "speaker": 253, "pace": 1.0, "noise": 0.75, "noise_w": 0.9},
    "grandma": {"model": LIBRITTS, "speaker": 88, "pace": 1.18, "noise": 0.7, "noise_w": 0.8},
    "uncle_ray": {"model": LIBRITTS, "speaker": 473, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
    "aunt_lisa": {"model": LIBRITTS, "speaker": 154, "pace": 1.0, "noise": 0.75, "noise_w": 0.9},
    "maddie": {"model": LIBRITTS, "speaker": 693, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
    "tyler": {"model": LIBRITTS, "speaker": 869, "pace": 0.95, "noise": 0.8, "noise_w": 0.9},
    "ben": {"model": LIBRITTS, "speaker": 517, "pace": 1.05, "noise": 0.8, "noise_w": 0.9},
    # school
    "mrs._patterson": {"model": LIBRITTS, "speaker": 0, "pace": 1.0, "noise": 0.75, "noise_w": 0.9},
    "maya": {"model": LIBRITTS, "speaker": 737, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
    "tyler_b.": {"model": LIBRITTS, "speaker": 396, "pace": 0.95, "noise": 0.8, "noise_w": 0.9},
    "marcus": {"model": LIBRITTS, "speaker": 550, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
    "emily": {"model": LIBRITTS, "speaker": 561, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
    "josh": {"model": LIBRITTS, "speaker": 539, "pace": 1.0, "noise": 0.8, "noise_w": 0.9},
}

STRING = r'"((?:[^"\\]|\\.)*)"'
# A speaker is a short name, optionally with a place: "Uncle Ray", "Mom (kitchen)".
SPEAKER = r'"([A-Z][A-Za-z .]{0,20}(?: \([a-z ]+\))?)"'
# Story scripts only (chapters and interludes).
SCRIPTS = ["chapter*.gd", "interlude*.gd", "school*.gd"]


def setup():
    os.makedirs(VOICES, exist_ok=True)
    if not os.path.exists(PIPER):
        zip_path = os.path.join(PIPER_DIR, "piper.zip")
        print("downloading Piper...")
        urllib.request.urlretrieve(PIPER_URL, zip_path)
        with zipfile.ZipFile(zip_path) as z:
            z.extractall(PIPER_DIR)
    for model in sorted({s["model"] for s in SPEAKERS.values()}):
        name, quality = model.rsplit("-", 1)
        for ext in (".onnx", ".onnx.json"):
            dest = os.path.join(VOICES, f"en_US-{model}{ext}")
            if not os.path.exists(dest):
                print("downloading", os.path.basename(dest))
                urllib.request.urlretrieve(VOICE_URL.format(name, quality) + ext[5:], dest)


def unescape(s):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def speaker_key(speaker):
    # Must match Audio.speaker_key() in scripts/audio.gd.
    return speaker.split("(")[0].strip().lower().replace(" ", "_")


def voice_id(speaker, text):
    # Must match Audio.voice_id(): md5 of the UTF-8 text, first 8 hex digits.
    return f"{speaker_key(speaker)}_{hashlib.md5(text.encode('utf-8')).hexdigest()[:8]}"


def bracketed(src, start):
    """Text of the [...] or {...} literal that opens at or after `start`."""
    i = min(j for j in (src.find("[", start), src.find("{", start)) if j != -1)
    depth, k, in_str = 0, i, False
    while k < len(src):
        c = src[k]
        if in_str:
            if c == "\\":
                k += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c in "[{":
            depth += 1
        elif c in "]}":
            depth -= 1
            if depth == 0:
                return src[i:k + 1]
        k += 1
    return src[i:]


def find_lines():
    lines = {}

    def add(speaker, text):
        if speaker and text:
            lines[voice_id(speaker, text)] = (speaker, text)

    paths = sorted({p for pat in SCRIPTS for p in glob.glob(os.path.join(ROOT, "scripts", pat))})
    for path in paths:
        src = open(path, encoding="utf-8").read()
        for spk, text in re.findall(r"\[\s*" + SPEAKER + r"\s*,\s*" + STRING + r"\s*\]", src):
            add(unescape(spk), unescape(text))
        for m in re.finditer(r"add_chatter\([^,]+,\s*" + SPEAKER + r"\s*,", src):
            for text in re.findall(STRING, bracketed(src, m.end())):
                add(unescape(m.group(1)), unescape(text))
        for func in re.split(r"\nfunc ", src):
            spk = re.search(r'say\(\[\[\s*' + SPEAKER + r'\s*,\s*(?:pool|lines)\b', func)
            if not spk:
                continue
            for m in re.finditer(r"var (?:pool|lines)\b[^=]*=", func):
                for text in re.findall(STRING, bracketed(func, m.end())):
                    add(unescape(spk.group(1)), unescape(text))
    return lines


def record(vid, speaker, text):
    spk = SPEAKERS[speaker_key(speaker)]
    cmd = [PIPER, "-m", os.path.join(VOICES, f"en_US-{spk['model']}.onnx"),
           "-f", os.path.join(OUT, vid + ".wav"),
           "--length_scale", str(spk["pace"]),
           "--noise_scale", str(spk["noise"]),
           "--noise_w", str(spk["noise_w"]),
           "--sentence_silence", "0.25"]
    if "speaker" in spk:
        cmd += ["-s", str(spk["speaker"])]
    # Leading "..." makes Piper hesitate oddly; a comma pause reads better.
    spoken = re.sub(r"^\.\.\.\s*", "", text)
    subprocess.run(cmd, input=spoken.encode("utf-8"), check=True, capture_output=True)


def main():
    args = sys.argv[1:]
    if "--setup" in args:
        setup()
        return
    lines = find_lines()
    if "--list" in args:
        for vid, (speaker, text) in sorted(lines.items()):
            print(f"{vid}.wav  {speaker}: {text}")
        return
    if not os.path.exists(PIPER):
        sys.exit("Piper not found. Run: python tools/generate_voices.py --setup")
    # Anything else that looked like dialogue (["Thighs", "Shins"]) is skipped;
    # a real new character needs an entry in SPEAKERS.
    unknown = sorted({speaker_key(s) for s, _ in lines.values()} - set(SPEAKERS))
    if unknown:
        print("skipping (no voice in SPEAKERS):", ", ".join(unknown))
        lines = {k: v for k, v in lines.items() if speaker_key(v[0]) in SPEAKERS}
    os.makedirs(OUT, exist_ok=True)
    force = "--force" in args
    made = 0
    for vid, (speaker, text) in lines.items():
        if force or not os.path.exists(os.path.join(OUT, vid + ".wav")):
            record(vid, speaker, text)
            made += 1
    pruned = 0
    if "--prune" in args:
        for f in glob.glob(os.path.join(OUT, "*.wav")):
            if os.path.splitext(os.path.basename(f))[0] not in lines:
                os.remove(f)
                if os.path.exists(f + ".import"):
                    os.remove(f + ".import")
                pruned += 1
    print(f"{len(lines)} voiced lines; recorded {made}, pruned {pruned}")


if __name__ == "__main__":
    main()
