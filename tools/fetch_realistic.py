"""Downloads the realistic 3D models, photo-based materials and sky HDRIs the
game uses, all CC0 from Poly Haven (https://polyhaven.com, no account needed).

Usage:  python tools/fetch_realistic.py           # fetch anything missing
        python tools/fetch_realistic.py --force   # re-download everything

Writes assets/polyhaven/{models,textures,hdris}/. Credits: audio/CREDITS.md
lists audio; Poly Haven assets are CC0 and need no credit (thanks anyway!).
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "polyhaven")
API = "https://api.polyhaven.com/files/"
UA = {"User-Agent": "porch-lights-asset-fetch"}
RES = "1k"

# Furniture and props (glTF). Grouped by where they show up.
MODELS = [
    # living room
    "Sofa_01", "ArmChair_01", "CoffeeTable_01", "wooden_bookshelf_worn", "side_table_01",
    "potted_plant_02", "wall_clock", "hanging_picture_frame_01", "hanging_picture_frame_02",
    "throw_pillows_01", "gaming_console", "gamepad", "book_encyclopedia_set_01",
    # kitchen
    "dining_table", "dining_chair_02", "electric_stove", "vintage_microwave", "vintage_electric_kettle",
    # bedrooms
    "old_bed_frame", "painted_wooden_nightstand", "alarm_clock_01", "boombox", "desk_lamp_arm_01",
    # holidays
    "fir_sapling", "cardboard_box_01", "wicker_basket_01",
    # school
    "SchoolDesk_01", "SchoolChair_01", "mounted_fluorescent_lights", "stationery_supplies",
    # outside
    "shrub_02", "dead_tree_trunk", "metal_trash_can", "fire_hydrant", "garden_gnome",
]

# Materials (diffuse, OpenGL normal, roughness).
TEXTURES = [
    "wood_floor", "painted_plaster_wall", "white_plaster_rough_01", "old_linoleum_flooring_01",
    "fabric_pattern_05", "dirty_carpet", "weathered_plank_siding", "wood_floor_deck",
    "grey_roof_tiles", "asphalt_02", "concrete_pavement", "snow_02", "leafy_grass",
    "terrazzo_tiles", "painted_concrete", "laminate_floor_02", "oak_wood_planks",
    "fabric_leather_01", "yellow_plaster", "old_wooden_floor_01",
]
TEXTURE_MAPS = {"Diffuse": "diff", "nor_gl": "nor_gl", "Rough": "rough"}

# Sky images for lighting and backgrounds.
HDRIS = ["qwantani_night_puresky", "snow_field_2_puresky", "kloofendal_overcast_puresky"]


def get(url, dest, force):
    if os.path.exists(dest) and not force:
        return False
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req) as r, open(dest, "wb") as f:
        f.write(r.read())
    return True


def files(asset_id):
    req = urllib.request.Request(API + asset_id, headers=UA)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode("utf-8"))


def main():
    force = "--force" in sys.argv
    got = 0
    for m in MODELS:
        info = files(m)["gltf"][RES]["gltf"]
        folder = os.path.join(OUT, "models", m)
        got += get(info["url"], os.path.join(folder, os.path.basename(info["url"])), force)
        for rel, inc in info["include"].items():
            got += get(inc["url"], os.path.join(folder, rel), force)
        print("model", m)
    for t in TEXTURES:
        info = files(t)
        for key, short in TEXTURE_MAPS.items():
            if key in info:
                url = info[key][RES]["jpg"]["url"]
                got += get(url, os.path.join(OUT, "textures", t, f"{t}_{short}_{RES}.jpg"), force)
        print("texture", t)
    for h in HDRIS:
        url = files(h)["hdri"][RES]["hdr"]["url"]
        got += get(url, os.path.join(OUT, "hdris", f"{h}_{RES}.hdr"), force)
        print("hdri", h)
    print(f"downloaded {got} file(s) into {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
