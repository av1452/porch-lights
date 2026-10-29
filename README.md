# Porch Lights

A short, first-person story game about being a kid in the early 2000s, from Halloween
to the last day of winter break. You play Leo, an 8-year-old. Your older sibling Jamie
is 15, Mom and Dad are doing their best, Biscuit is a very good dog, and Grandma brings
the fudge. Candy taxes, the kids' table, untangling the lights, matching pajamas, and
the porch light you leave on so everyone can find their way home.

![Living room](docs/1_living_room.png)

| | |
|---|---|
| ![Kitchen](docs/3_kitchen.png) | ![Jamie's room](docs/5_jamie_room.png) |
| ![Your room](docs/6_kid_room.png) | ![The dream hallway](docs/7_dream_hall.png) |
| ![Grandma's house](docs/10_kids_table.png) | |

## Play it
Open in **Godot 4.3+** (Import → select `project.godot`), then press F5.

The title screen has Continue, New Game, Chapters (every chapter you've reached),
Photo Album and Settings (volumes, mouse sensitivity, subtitles, fullscreen). Progress,
settings and photos save automatically.

WASD / arrows: move · Mouse: look · Shift: run · C or Ctrl: crouch
E or left click: interact · Esc: pause menu

**Photo album:** whenever somebody pulls out a disposable camera, the picture really
gets taken and saved as a "developed print" with the orange date stamp in the corner.
Your pictures come back from the drugstore at the end of the game, and you can flip
through them any time from the menu.

## Story

**Chapter 1: October 31, Halloween.** Sort your candy. Pay the candy tax (and catch Mom
and Dad plotting to keep the full-size bars). Turn off the porch light and watch the rest
of the street go dark one house at a time. Show Jamie your haul and hang out in their
room until Mom calls bedtime. Fall asleep, and the hallway keeps going, all the way to a
warm door that smells like Grandma's kitchen.

**Interlude: 2:14 a.m., The Midnight Candy Raid.** A crinkle wakes you. Jamie heard it
too. Flashlight in hand, you catch Mom and Dad in the kitchen eating your Halloween candy.
Everybody gets one. Then Biscuit needs to go out, and from the porch you watch the
neighborhood's porch lights click off one by one. Goodnight, Halloween.

**Chapter 2: November, Thanksgiving.**
*Getting Ready:* Thanksgiving morning. Grab your coat, your handheld and Biscuit's leash
while Mom guards the pies, Dad warms up the van and Jamie protests the hour. Then the
drive: autumn trees, the parade on the radio, and "over the river..." ("Every. Single. Year.").
*At Grandma's:* say hi to Grandma and open the canned cranberry sauce (ridges and all).
Football's on the TV cart. Take your seat at the kids' table while Jamie moves up to the
big table. After dinner, Mom and Dad quietly notice Grandma's moving slower this year, and
Grandma saves you the first slice of pie.
*The Drive Home:* the back seat, leftovers on your lap, Biscuit's head in your lap too,
streetlights sliding over the ceiling. Jamie lends you one earbud: Static Parade. Mom and
Dad talk low about Grandma. Mom circles things in the Black Friday ads ("nobody look"),
and the first Christmas song of the year comes on the radio. You fall asleep as the first
snow starts falling in the headlights, and in your dream every porch light you pass turns
into Christmas lights, all the way to Grandma's porch.

**School: December 19, The Class Party.** Mrs. Patterson's third grade, last day before
break. The handprint turkeys and paper bats are still up. Put your letter in the North Pole
mailbox, cut a paper snowflake, do Secret Santa (a Slinky for you, glitter gel pens for
Maya), cupcakes with the crunchy sprinkles, juice boxes, candy canes, the class picture,
the claymation special on the TV cart, one last "Jingle Bells" for the concert... and
the bell.

**Chapter 4: December 19, Home for Winter Break.** Two whole weeks off. Sprinkles duty on Mom's sugar cookies.
The advent calendar (Jamie ate tomorrow's). The toy catalog, page 47. Help Jamie find
the one dead bulb so the whole tree lights up. Grandma calls: she's coming for Christmas
Eve. You fall asleep to the claymation special and dream it's snowing in the living
room, then wake up to real snow.

**Chapter 5: December 24, Christmas Eve.** Grandma's here with her fudge. One present
tonight: matching reindeer pajamas for everybody, even Dad, and a bandana for Biscuit.
The disposable-camera family picture. Cookies and milk for Santa, carrots for the
reindeer, and the porch light on so Santa can find the house. Was that sleigh bells?

**Chapter 6: December 25, Christmas Morning.** 5:52 a.m. He came! A stocking with an
orange in the toe, like every year. The Mega Robo Racer: batteries not included, but
Grandma always brings batteries. Dad's snowman pancakes (snow blobs). A snowball ambush
from Jamie, and an afternoon nap with everybody you love in one room.

**Chapter 7: January 3, The Last Day of Winter Break.** Take down the tree, one ornament
memory at a time. Write Grandma a thank-you note. One more round as player two, practicing
what you'll tell everyone at school. Then the porch light that's been on since Christmas
Eve finally clicks off. Until next Halloween.

## Project layout
- `scenes/chapter_1_halloween.tscn` ... `scenes/chapter_7_last_day_of_break.tscn`: levels.
  The interlude plays in the Chapter 1 house. Chapters 4-7 inherit that house and
  redecorate it in code (`scripts/house_chapter.gd`, `scripts/decorations.gd`).
- `scripts/chapter.gd`: base class for chapters: `say()` dialogue (voiced automatically),
  `objective()`, `open_chapter()` title cards, `swing_door()`, `add_chatter()`, room-state swapping
- `scripts/chapter_1_halloween.gd`, `scripts/interlude_porch_light.gd`, and
  `scripts/chapter_2_...` through `scripts/chapter_7_...`: story steps
- `scripts/car_ride.gd`: the family car at night, with the road sliding past
- `scripts/figure.gd`: builds people in code (Mom, Dad, Jamie, Grandma) to match the scenes
- `scripts/player.gd`: Leo's kid-height first-person controller (walk, run, crouch, sit, footsteps)
- `scripts/interactable.gd`: attach to any StaticBody3D. Set `prompt`,
  `memory_text`, `repeat_text` and `use_sfx` in the Inspector, or connect to `used`
- `scripts/trigger.gd`: invisible zone that fires when you walk in
- `scripts/hud.gd`: thoughts, dialogue, objective, fades, chapter cards
- `scripts/dog.gd`: Biscuit (naps, follows you, sits, whines, barks, growls)
- `scripts/street.gd`: the neighborhood outside, with porch lights that go out
- `scripts/tv_screen.gd`, `scripts/tv_show.gd`: the live picture on the TV. Drop an Ogg
  Theora video at `media/<channel>.ogv` (`special`, `commercial`, `dream`, `signoff`, `static`) to use real footage
- `scripts/audio.gd`: autoload `Audio` (music, sound effects, voices)
- `scripts/game.gd`: autoload `Game` (chapter order, save, settings, photo album, pause menu)
- `scripts/main_menu.gd`, `scripts/pause_menu.gd`, `scripts/ui.gd`: menus and the album
- `scripts/classroom.gd`, `scripts/school_class_party.gd`: the school chapter
- `scripts/look.gd`: the realism pass
- `tests/`: automated playthroughs and a screenshot tool

Rendering is 854×480 (480p, the PS2/DVD era) with smooth filtering and MSAA, a night
sky, SSAO/SSIL and volumetric fog. `scripts/look.gd` runs on every chapter: it rounds
off shapes, gives flat materials subtle surface grain, and turns the block people into
rounded ones with hands, shoes and faces. Geometry is still CSG, ready for real models.

## Audio
- **Voices**: every character line in `say()` and `add_chatter()` is voiced with
  [Piper](https://github.com/rhasspy/piper), offline and free. Narration stays silent text.
  `python tools/generate_voices.py --setup` once (downloads Piper + voices into the gitignored
  `tools/piper/`), then `python tools/generate_voices.py` records any new or changed lines
  (`--prune` removes unused ones, `--list` shows every line). Voice casting is `SPEAKERS` in that script.
- **Music and sound effects**: real CC0 recordings from BigSoundBank, Kenney and OpenGameArt, cut
  by `python tools/fetch_audio.py` (credits in `audio/CREDITS.md`). The Kenney packs must be
  downloaded by hand; the script tells you where to put them.
- `python tools/generate_audio.py` makes the few deliberately electronic sounds (TV jingles, sign-off tone, bulb buzz).

To use your own recordings, drop a `.wav`, `.ogg` or `.mp3` with the same name into
`audio/voice/`, `audio/music/` or `audio/sfx/`.

## Testing
```
godot --headless -s res://tests/playtest_chapter_1.gd   # Chapter 1 + the interlude
godot --headless -s res://tests/playtest_chapter_2_getting_ready.gd
godot --headless -s res://tests/playtest_chapter_2.gd
godot --headless -s res://tests/playtest_chapter_3.gd
godot --headless -s res://tests/playtest_school.gd
godot --headless -s res://tests/playtest_chapter_4.gd
godot --headless -s res://tests/playtest_chapter_5.gd
godot --headless -s res://tests/playtest_chapter_6.gd
godot --headless -s res://tests/playtest_chapter_7.gd
```
