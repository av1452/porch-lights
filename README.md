# Porch Lights — Chapter 1 prototype (Halloween night)

Open in **Godot 4.3+** (Import → select `project.godot`), then press F5.

## Controls
WASD / arrows: move · Mouse: look · Shift: run · C or Ctrl: crouch
E or left click: interact · Esc: free the mouse (click to recapture)

## What's in it
- Kid-height first-person player (eyes at 1.15 m), head bob, crouch, short reach
- Living room + hallway built from CSG boxes (placeholder geometry, swap in your models)
- 6 interactables with first-time and repeat thoughts: TV, candy pile, mask, window, sibling's door, couch
- Lie on the couch → fall asleep → the hallway stretches into a dream → open the door at the end → wake up

## Where things live
- `scripts/player.gd`: movement, look, interaction raycast (tune feel in the Inspector)
- `scripts/interactable.gd`: attach to any StaticBody3D; write `prompt`, `memory_text`, `repeat_text` in the Inspector
- `scripts/hud.gd`: crosshair, prompt, memory text, fades
- `scripts/main.gd`: chapter logic (TV flicker, dream in/out)
- `scenes/main.tscn`: the level

Rendering is 640×360 scaled 2× for a low-res PS2-era look (Project Settings → Display → Window).
