"""Records every spoken line in the chapter scripts with Kokoro (free, offline neural TTS).

It finds dialogue in scripts/*.gd automatically:
  say([["Mom", "Candy tax. Rules are rules."], ...])     speaker/text pairs
  add_chatter(node, "Uncle Ray", ["...", "..."])          chatter lists
  var pool := [...]  ...  say([["Dad", pool[i]]])         random line pools
Narration (speaker "") stays silent text. Each line is saved as
audio/voice/<speaker>_<md5 of text>.wav, which is what scripts/audio.gd plays.

Usage:
    python tools/generate_voices.py --setup     # one time: Python env + Kokoro model (~350 MB, gitignored)
    python tools/generate_voices.py             # record lines that don't have a file yet
    python tools/generate_voices.py --force     # re-record everything
    python tools/generate_voices.py --prune     # also delete recordings no script uses anymore
    python tools/generate_voices.py --list      # print every line and its file name

Real recordings dropped in with the same file name replace these.
Kokoro has no child voices: kids are young-sounding voices pitched up in-game
(PITCH in scripts/audio.gd).
"""
import glob
import hashlib
import os
import re
import subprocess
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KOKORO_DIR = os.path.join(ROOT, "tools", "kokoro")
VENV = os.path.join(KOKORO_DIR, "venv")
VENV_PY = os.path.join(VENV, "Scripts", "python.exe") if os.name == "nt" else os.path.join(VENV, "bin", "python")
MODEL = os.path.join(KOKORO_DIR, "kokoro-v1.0.onnx")
VOICES = os.path.join(KOKORO_DIR, "voices-v1.0.bin")
MODEL_URL = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/"
OUT = os.path.join(ROOT, "audio", "voice")

# speaker key -> Kokoro voice and pace (speed: <1 slower).
SPEAKERS = {
    "mom": {"voice": "af_heart", "speed": 1.0},
    "dad": {"voice": "am_michael", "speed": 0.95},
    "jamie": {"voice": "am_echo", "speed": 1.05},
    "grandma": {"voice": "af_bella", "speed": 0.85},
    "uncle_ray": {"voice": "am_onyx", "speed": 1.0},
    "aunt_lisa": {"voice": "af_sarah", "speed": 1.0},
    # cousins (pitched up in-game)
    "maddie": {"voice": "af_sky", "speed": 1.05},
    "tyler": {"voice": "am_puck", "speed": 1.05},
    "ben": {"voice": "af_nicole", "speed": 1.0},
    # school
    "mrs._patterson": {"voice": "af_kore", "speed": 1.0},
    "maya": {"voice": "af_aoede", "speed": 1.05},
    "tyler_b.": {"voice": "am_eric", "speed": 1.05},
    "marcus": {"voice": "am_adam", "speed": 1.05},
    "emily": {"voice": "af_alloy", "speed": 1.05},
    "josh": {"voice": "am_liam", "speed": 1.1},
}

STRING = r'"((?:[^"\\]|\\.)*)"'
# A speaker is a short name, optionally with a place: "Uncle Ray", "Mom (kitchen)".
SPEAKER = r'"([A-Z][A-Za-z .]{0,20}(?: \([a-z ]+\))?)"'
# Story scripts only (chapters and interludes).
SCRIPTS = ["chapter*.gd", "interlude*.gd", "school*.gd"]


def setup():
    os.makedirs(KOKORO_DIR, exist_ok=True)
    if not os.path.exists(VENV_PY):
        print("creating Python environment in tools/kokoro/venv...")
        subprocess.run([sys.executable, "-m", "venv", VENV], check=True)
    subprocess.run([VENV_PY, "-m", "pip", "install", "-q", "--upgrade", "pip"], check=True)
    subprocess.run([VENV_PY, "-m", "pip", "install", "-q", "kokoro-onnx", "soundfile"], check=True)
    for path in (MODEL, VOICES):
        if not os.path.exists(path):
            print("downloading", os.path.basename(path))
            urllib.request.urlretrieve(MODEL_URL + os.path.basename(path), path)
    print("ready")


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


_kokoro = None


def record(vid, speaker, text):
    global _kokoro
    import soundfile
    from kokoro_onnx import Kokoro
    if _kokoro is None:
        _kokoro = Kokoro(MODEL, VOICES)
    spk = SPEAKERS[speaker_key(speaker)]
    # A leading "..." reads as an odd hesitation; start on the words.
    spoken = re.sub(r"^\.\.\.\s*", "", text)
    audio, rate = _kokoro.create(spoken, voice=spk["voice"], speed=spk["speed"])
    soundfile.write(os.path.join(OUT, vid + ".wav"), audio, rate, subtype="PCM_16")


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
    if not (os.path.exists(VENV_PY) and os.path.exists(MODEL)):
        sys.exit("Kokoro not set up. Run: python tools/generate_voices.py --setup\n"
                 "(onnxruntime may need Python 3.13 or older; if setup fails, run it with that.)")
    # Kokoro lives in its own environment; hop into it.
    if os.path.realpath(sys.prefix) != os.path.realpath(VENV):
        os.execv(VENV_PY, [VENV_PY, os.path.abspath(__file__)] + args)
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
