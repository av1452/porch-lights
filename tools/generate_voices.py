"""Records the voice lines in data/lines.json with Piper (offline neural TTS).

Usage:
    python tools/generate_voices.py --setup     # one time: download Piper + voices (~330 MB, gitignored)
    python tools/generate_voices.py             # record lines that don't have a file yet
    python tools/generate_voices.py --force     # re-record everything
    python tools/generate_voices.py leo_final   # re-record specific ids

Real recordings dropped into audio/voice/<id>.wav (or .ogg) replace these.
Per-speaker in-game pitch lives in scripts/audio.gd (SPEAKERS).
"""
import json
import os
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

# speaker -> model, optional multi-speaker id, pace (length_scale: >1 slower),
# and expressiveness (noise_scale / noise_w: higher = more varied delivery).
SPEAKERS = {
    # Highest voice in libritts_r; pitched up a touch in-game to read as an 8-year-old.
    "leo": {"model": "libritts_r-medium", "speaker": 517, "pace": 1.05, "noise": 0.75, "noise_w": 0.9},
    "mom": {"model": "lessac-high", "pace": 1.05, "noise": 0.7, "noise_w": 0.85},
    "dad": {"model": "ryan-high", "pace": 1.08, "noise": 0.7, "noise_w": 0.85},
    "sibling": {"model": "libritts_r-medium", "speaker": 22, "pace": 0.9, "noise": 0.8, "noise_w": 0.9},
    "tv": {"model": "libritts_r-medium", "speaker": 119, "pace": 0.88, "noise": 0.6, "noise_w": 0.7},
}


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


def record(line_id, line):
    spk = SPEAKERS[line["speaker"]]
    cmd = [PIPER, "-m", os.path.join(VOICES, f"en_US-{spk['model']}.onnx"),
           "-f", os.path.join(OUT, line_id + ".wav"),
           "--length_scale", str(spk["pace"]),
           "--noise_scale", str(spk["noise"]),
           "--noise_w", str(spk["noise_w"]),
           "--sentence_silence", "0.25"]
    if "speaker" in spk:
        cmd += ["-s", str(spk["speaker"])]
    subprocess.run(cmd, input=line["text"].encode("utf-8"), check=True, capture_output=True)


def main():
    args = sys.argv[1:]
    if "--setup" in args:
        setup()
        return
    if not os.path.exists(PIPER):
        sys.exit("Piper not found. Run: python tools/generate_voices.py --setup")
    force = "--force" in args
    only = [a for a in args if not a.startswith("--")]
    with open(os.path.join(ROOT, "data", "lines.json"), encoding="utf-8") as f:
        lines = json.load(f)
    os.makedirs(OUT, exist_ok=True)
    made = 0
    for line_id, line in lines.items():
        if line_id.startswith("_") or (only and line_id not in only):
            continue
        if not (force or only) and os.path.exists(os.path.join(OUT, line_id + ".wav")):
            continue
        record(line_id, line)
        made += 1
    print(f"recorded {made} line(s) into {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
