"""Records the voice lines in data/lines.json with Kokoro (free, offline neural TTS).

Usage:
    python tools/generate_voices.py --setup     # one time: Python env + Kokoro model (~350 MB, gitignored)
    python tools/generate_voices.py             # record lines that don't have a file yet
    python tools/generate_voices.py --force     # re-record everything
    python tools/generate_voices.py leo_final   # re-record specific ids

Real recordings go in with tools/recordings.py; ids listed in data/recorded.json
are never re-recorded here, even with --force.
Per-speaker in-game pitch lives in scripts/audio.gd (SPEAKERS).
"""
import json
import os
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

# speaker -> Kokoro voice and pace (speed: <1 slower). Kokoro has no child voices;
# Leo is a young male voice pitched up in-game (scripts/audio.gd).
SPEAKERS = {
    "leo": {"voice": "am_puck", "speed": 1.0},
    "mom": {"voice": "af_heart", "speed": 1.0},
    "dad": {"voice": "am_michael", "speed": 0.95},
    "grandma": {"voice": "af_bella", "speed": 0.85},
    "sibling": {"voice": "am_echo", "speed": 1.1},
    "tv": {"voice": "am_fenrir", "speed": 1.1},
}


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


def main():
    args = sys.argv[1:]
    if "--setup" in args:
        setup()
        return
    if not (os.path.exists(VENV_PY) and os.path.exists(MODEL)):
        sys.exit("Kokoro not set up. Run: python tools/generate_voices.py --setup\n"
                 "(onnxruntime may need Python 3.13 or older; if setup fails, run it with that.)")
    # Kokoro lives in its own environment; hop into it.
    if os.path.realpath(sys.prefix) != os.path.realpath(VENV):
        os.execv(VENV_PY, [VENV_PY, os.path.abspath(__file__)] + args)

    import soundfile
    from kokoro_onnx import Kokoro

    force = "--force" in args
    only = [a for a in args if not a.startswith("--")]
    with open(os.path.join(ROOT, "data", "lines.json"), encoding="utf-8") as f:
        lines = json.load(f)
    recorded_path = os.path.join(ROOT, "data", "recorded.json")
    recorded = set()
    if os.path.exists(recorded_path):
        with open(recorded_path, encoding="utf-8") as f:
            recorded = set(json.load(f))
    os.makedirs(OUT, exist_ok=True)
    kokoro = Kokoro(MODEL, VOICES)
    made = 0
    for line_id, line in lines.items():
        if line_id.startswith("_") or line_id in recorded or (only and line_id not in only):
            continue
        dest = os.path.join(OUT, line_id + ".wav")
        if not (force or only) and os.path.exists(dest):
            continue
        spk = SPEAKERS[line["speaker"]]
        audio, rate = kokoro.create(line["text"], voice=spk["voice"], speed=spk["speed"])
        soundfile.write(dest, audio, rate, subtype="PCM_16")
        made += 1
        print(f"  {line_id:<20} {spk['voice']:<11} {line['text'][:50]}")
    print(f"recorded {made} line(s) into {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
