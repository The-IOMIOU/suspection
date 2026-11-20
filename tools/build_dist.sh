#!/bin/bash
# Builds dist/SuspectMode_<ver>.zip = UE4SS (downloaded, MIT) + mod/RonSuspect + installer/*. Needs gh, unzip, powershell.
set -e; VER=${1:-v0.1}; cd "$(dirname "$0")/.."; ROOT=$PWD
UE=experimental-latest; TESTED=UE4SS_v4.0.0-6-gef15eba8.zip  # the loader version the mod is tested with
# UE4SS_ZIP=/path/to/UE4SS_v*.zip pins a local copy (the experimental release only keeps its newest build)
ASSET=$(gh release view $UE -R UE4SS-RE/RE-UE4SS --json assets -q '.assets[].name' | grep -E '^UE4SS_v.*\.zip$' | head -1)
rm -rf build && mkdir -p build/dl build/pkg/payload dist
if [ -n "$UE4SS_ZIP" ]; then ASSET=$(basename "$UE4SS_ZIP"); mkdir -p build/dl; cp "$UE4SS_ZIP" build/dl/; else gh release download $UE -R UE4SS-RE/RE-UE4SS -p "$ASSET" -D build/dl; fi
[ "$ASSET" != "$TESTED" ] && echo "WARNING: packaging $ASSET, tested with $TESTED"
unzip -oq "build/dl/$ASSET" -d build/pkg/payload
cp -r mod/RonSuspect build/pkg/payload/ue4ss/Mods/
sed -i 's/^Keybinds : 1/RonSuspect : 1\nKeybinds : 1/' build/pkg/payload/ue4ss/Mods/mods.txt
cp installer/* build/pkg/
rm -f "dist/SuspectMode_$VER.zip"; (cd build/pkg && powershell -c "Compress-Archive -Path * -DestinationPath '$(cygpath -m "$ROOT")/dist/SuspectMode_$VER.zip'")
echo "built dist/SuspectMode_$VER.zip (UE4SS asset: $ASSET)"
