# Porch Lights — Chapters 1 & 2 prototype (Halloween night)

You play **Leo**, an 8-year-old, on Halloween night.
Open in **Godot 4.3+** (Import → select `project.godot`), then press F5.

## Controls
WASD / arrows: move · Mouse: look · Shift: run · C or Ctrl: crouch
E or left click: interact · Esc: free the mouse (click to recapture)

## What's in it
- **Chapter 1 — Halloween Night**: living room + hallway. Watch TV, sort candy, pet Biscuit,
  knock on your sibling's door, look out the window at the porch lights. Lie on the couch →
  fall asleep → the hallway stretches into a dream → open the door at the end → wake up.
- **Chapter 2 — The Porch Light**: it's the middle of the night. Biscuit whines at the front
  door. Turn the porch light back on, let him out, and watch the street.
- **Biscuit** (`scripts/dog.gd`): the family dog. Naps, follows Leo, sits, wags, whines, barks.
- **Voices**: every line is in `data/lines.json` with a matching file in `audio/voice/`.
- **Music & sound**: `audio/music/` and `audio/sfx/` (footsteps, doors, TV, crickets, dog, clock).
- **TV picture**: a live animated show on the screen (`scripts/tv_show.gd`). Drop an Ogg Theora
  video at `media/<channel>.ogv` (`special`, `commercial`, `dream`, `signoff`, `static`) and it plays instead.
- **Look**: 640×360 scaled 2× for a PS2-era feel, with SSAO/SSIL, volumetric fog, moonlight and
  textured materials. The street outside is built in `scripts/street.gd`.

## Replacing placeholder audio
All audio is placeholder. To use real recordings, drop a `.wav` or `.ogg` with the **same name**
into `audio/voice/`, `audio/music/` or `audio/sfx/`. Regenerate placeholders with:
- `tools/generate_voices.ps1` (Windows text-to-speech, reads `data/lines.json`; `-Force` re-records all)
- `python tools/generate_audio.py` (synthesized music and sound effects)

Per-speaker pitch and subtitle color live in `SPEAKERS` in `scripts/audio.gd`.

## Where things live
- `scripts/player.gd`: Leo's movement, look, footsteps, interaction raycast
- `scripts/interactable.gd`: attach to any StaticBody3D; set `prompt`, `line_id`, `repeat_line_ids`, `use_sfx`
- `scripts/hud.gd`: crosshair, prompt, subtitles, objective, title cards, fades
- `scripts/audio.gd`: autoload `Audio` — music, sound effects, voiced lines
- `scripts/main.gd`: chapter 1 logic (TV, dream in/out); `scripts/chapter2.gd`: chapter 2
- `scenes/main.tscn`: the level

Debug: run with `-- --chapter=2` (Project → Project Settings → Run → Main Run Args) to start at chapter 2.
