# Making the people and Biscuit look real

The game already uses real scanned furniture and materials (`python tools/fetch_realistic.py`).
People and Biscuit work the same way: **drop a model file into the right folder with the
right name, and the game uses it automatically** in every chapter. It scales each person to
the right height, swaps out the built-in figure, and keeps everything else the same.
Anyone you haven't made yet keeps the built-in figure, so you can do them one at a time.

```
assets/people/mom.fbx            standing
assets/people/mom_sitting.fbx    sitting (Thanksgiving table, car, couch)
assets/animals/biscuit.glb       the dog
```

Accepted formats: `.fbx`, `.glb`, `.gltf`, `.dae`, or a folder `<name>/scene.gltf`.
After adding files, open the project in Godot once so it imports them, then play.

---

## People: MakeHuman (free)

1. Download **MakeHuman 1.2** from <https://static.makehumancommunity.org/makehuman.html>
   and install it. Everything it makes is **CC0** (yours to use, no credit needed).
2. For each person below:
   - **Modelling → Main:** set gender, age, weight, height. (Age goes down to kids.)
   - **Modelling → Face / Torso:** nudge until they look like *them*.
   - **Geometries → Clothes:** pick 2003-ish clothes (jeans, sweaters, a hoodie, sneakers).
     Get more free clothes from the in-app **Settings → Plugins → Asset downloader**, or
     <http://www.makehumancommunity.org/clothes.html>.
   - **Geometries → Hair / Eyebrows / Eyelashes:** don't skip eyebrows and eyelashes;
     they make the biggest difference to looking real.
   - **Pose/Expression → Skeleton:** choose **Game engine**.
   - **Pose/Expression → Pose:** pick a relaxed **standing** pose (not the T-pose).
     **Expression:** a soft smile.
3. **Files → Export:** choose **Filmbox (fbx)**, set **Scale units: meter**, tick
   **Feet on ground**, and save into `porch-lights/assets/people/` with the exact file
   name below (lowercase, no spaces).
4. For anyone who **sits** somewhere, change **Pose** to a **sitting** pose and export
   again as `<name>_sitting.fbx`.

### Who to make (most important first)

| File name | Who | Notes (early 2000s) | Sitting version? |
|---|---|---|---|
| `mom` | Mom, ~40 | brown shoulder-length hair, lavender sweater, jeans | yes (car, Thanksgiving) |
| `dad` | Dad, ~42 | short brown hair, red flannel shirt, khakis | yes (car, Thanksgiving) |
| `jamie` | Jamie, 15 | black hair, black hoodie, jeans; keep it gender-neutral | yes (computer, couch, car) |
| `grandma` | Grandma, ~70 | short gray curly hair, pink cardigan, slacks, apron | yes (pie scene) |
| `mrspatterson` | teacher, ~35 | red holiday sweater, long brown hair | no |
| `maya`, `emily` | classmates, 8 | purple top / pink top, long hair | no |
| `tylerb`, `marcus` | classmates, 8 | orange shirt, blond / green shirt, dark hair | no |
| `josh` | classmate, 8 | blue shirt, brown hair | yes (at his desk) |
| `uncleray`, `auntlisa` | Thanksgiving | Uncle Ray: big laugh, mustard sweater; Aunt Lisa: teal blouse | yes (both at the table) |
| `maddie`, `tyler`, `ben` | cousins, 4-10 | Ben is the littlest (4¾) | yes (kids' table) |

Leo is you, so he doesn't need a model.

**If someone shows up facing backwards**, tell Claude which file; it's a one-line fix.

---

## Biscuit: a real dog (free)

MakeHuman only makes people, so Biscuit comes from Sketchfab, which has realistic, rigged,
animated dogs for free:

1. Make a free account at <https://sketchfab.com>.
2. Search for **beagle** (or **dog**), and use the filters **Downloadable** and, if offered,
   **Animated**. A beagle-ish dog with a **walk**, **sit** and **lie/sleep** animation is
   ideal; Biscuit is a tan, black and white beagle mix.
3. Check the license under the model. **CC0** needs nothing; **CC Attribution (CC-BY)**
   just needs a credit line, so add the model name and author to `audio/CREDITS.md`
   (there's a section for it). Avoid "Editorial" or "No commercial use" licenses if you
   might ever share the game.
4. Click **Download 3D Model → glTF**. Unzip it into `porch-lights/assets/animals/biscuit/`
   so that `assets/animals/biscuit/scene.gltf` exists (or export a single
   `assets/animals/biscuit.glb`).

The game sizes him to a medium dog and plays his walk, run, sit, lie-down and idle
animations automatically, matching what he's doing in the story. A model without
animations still works; he'll just glide.

**Credits section for `audio/CREDITS.md`:**
```
## Biscuit
- "<model name>" by <author> (<license>) <link>
```
