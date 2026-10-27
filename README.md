# Porch Lights

A short, first-person story game about growing up in the early 2000s, told through
the holidays from Halloween to Christmas. You play an 8-year-old. Your older
sibling Jamie is 15. Everything is a little too big, the grown-ups talk quietly in
the kitchen, and every chapter ends with you falling asleep.

![Living room](docs/1_living_room.png)

| | |
|---|---|
| ![Kitchen](docs/3_kitchen.png) | ![Jamie's room](docs/5_jamie_room.png) |
| ![Your room](docs/6_kid_room.png) | ![The dream hallway](docs/7_dream_hall.png) |
| ![Grandma's house](docs/10_kids_table.png) | |

## Play it
Open in **Godot 4.3+** (Import → select `project.godot`), then press F5.

WASD / arrows: move · Mouse: look · Shift: run · C or Ctrl: crouch
E or left click: interact · Esc: free the mouse (click to recapture)

## Story so far

**Chapter 1: October 31, Halloween.** Sort your candy. Pay the candy tax (and
overhear Mom and Dad worrying about Grandma). Turn off the porch light. Show Jamie
your haul and hang out in their room until Mom calls bedtime. Fall asleep, and the
hallway keeps going: Jamie's door is open, the room is full of boxes, and at the
very end there's a warm door that smells like Grandma's kitchen.

**Chapter 2: November, Thanksgiving at Grandma's** (opening). Say hi to Grandma,
who sits down while she cooks now. Take your seat at the kids' table while Jamie
moves up to the big table. After dinner, the house goes quiet, and Grandma saves
you the first slice of pie.

**Planned:** the drive home (dream), the last week before winter break, Christmas
Eve, Christmas morning and the quiet after.

## Project layout
- `scenes/chapter_1_halloween.tscn`, `scenes/chapter_2_thanksgiving.tscn`: levels
- `scripts/chapter.gd`: base class for chapters: `say()` dialogue, `objective()`,
  `open_chapter()` title cards, `swing_door()`, `add_chatter()`, room-state swapping
- `scripts/chapter_1_halloween.gd`, `scripts/chapter_2_thanksgiving.gd`: story steps
- `scripts/player.gd`: kid-height first-person controller (walk, run, crouch, sit)
- `scripts/interactable.gd`: attach to any StaticBody3D. Set `prompt`,
  `memory_text` and `repeat_text` in the Inspector, or connect to `used`
- `scripts/trigger.gd`: invisible zone that fires when you walk in
- `scripts/hud.gd`: thoughts, dialogue, objective, fades, chapter cards
- `tests/`: automated playthroughs and a screenshot tool

Rendering is 640×360 scaled 2× for a low-res PS2-era look
(Project Settings → Display → Window). Everything is placeholder CSG geometry and
flat colors, ready to be replaced with real models and textures.

## Testing
```
godot --headless -s res://tests/playtest_chapter_1.gd
godot --headless -s res://tests/playtest_chapter_2.gd
```
