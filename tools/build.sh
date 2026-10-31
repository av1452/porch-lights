#!/bin/sh
# Builds Porch Lights for itch.io: Mac, Windows and Linux, each as a zip in builds/.
#
#   sh tools/build.sh            # all three
#   sh tools/build.sh Windows    # just one (preset name from export_presets.cfg)
#
# Needs Godot 4.3 and its export templates (Godot > Editor > Manage Export
# Templates > Download). Set GODOT to your Godot binary if it isn't the default.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/Downloads/Godot.app/Contents/MacOS/Godot}"
PRESETS="${*:-macOS Windows Linux}"

"$GODOT" --headless --import --path . >/dev/null 2>&1 || true
mkdir -p builds/windows builds/linux

for preset in $PRESETS; do
	echo "== $preset"
	case "$preset" in
		macOS) out="builds/Porch Lights (Mac).zip" ;;
		Windows) out="builds/windows/Porch Lights.exe" ;;
		Linux) out="builds/linux/Porch Lights.x86_64" ;;
		*) echo "unknown preset: $preset"; exit 1 ;;
	esac
	"$GODOT" --headless --path . --export-release "$preset" "$out"
	case "$preset" in
		Windows) (cd builds/windows && rm -f "../Porch Lights (Windows).zip" && zip -qr "../Porch Lights (Windows).zip" .) ;;
		Linux) (cd builds/linux && chmod +x "Porch Lights.x86_64" && rm -f "../Porch Lights (Linux).zip" && zip -qr "../Porch Lights (Linux).zip" .) ;;
	esac
done
echo
ls -lh builds/*.zip
