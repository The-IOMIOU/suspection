#!/bin/bash
# Builds dist/SuspectMode_<ver>.zip = UE4SS (downloaded, MIT) + mod/RonSuspect + installer/*. Needs gh, unzip, powershell.
set -e; VER=${1:-v0.1}; cd "$(dirname "$0")/.."; ROOT=$PWD
UE=experimental-latest; ASSET=$(gh release view $UE -R UE4SS-RE/RE-UE4SS --json assets -q '.assets[].name' | grep -E '^UE4SS_v.*\.zip$' | head -1)
rm -rf build && mkdir -p build/dl build/pkg/payload dist
gh release download $UE -R UE4SS-RE/RE-UE4SS -p "$ASSET" -D build/dl
unzip -oq "build/dl/$ASSET" -d build/pkg/payload
cp -r mod/RonSuspect build/pkg/payload/ue4ss/Mods/
sed -i 's/^Keybinds : 1/RonSuspect : 1\nKeybinds : 1/' build/pkg/payload/ue4ss/Mods/mods.txt
cp installer/* build/pkg/
rm -f "dist/SuspectMode_$VER.zip"; (cd build/pkg && powershell -c "Compress-Archive -Path * -DestinationPath '$(cygpath -m "$ROOT")/dist/SuspectMode_$VER.zip'")
echo "built dist/SuspectMode_$VER.zip (UE4SS asset: $ASSET)"
