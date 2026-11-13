#!/bin/bash
# usage: q.sh file.lua | q.sh -e 'lua'
# Bridge folder: $RON_BRIDGE, else %LOCALAPPDATA%\Temp\ronbridge (same default as dev/RonBridge).
D=${RON_BRIDGE:-$(cygpath -u "$LOCALAPPDATA")/Temp/ronbridge}; mkdir -p "$D"; rm -f "$D/out.txt"
if [ "$1" = "-e" ]; then printf '%s' "$2" > "$D/cmd.tmp"; else cp "$1" "$D/cmd.tmp"; fi; mv "$D/cmd.tmp" "$D/cmd.lua"
for i in $(seq 1 50); do [ -f "$D/out.txt" ] && { sleep 0.2; cat "$D/out.txt"; echo; exit 0; }; sleep 0.2; done; echo TIMEOUT
