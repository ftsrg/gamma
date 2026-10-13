#!/usr/bin/env bash
# Validates Oomph *.setup models against the real, generated Oomph EPackages.
#
# Plain XML well-formedness is not enough. Oomph renames plural features to
# singular XML element names via extendedMetaData (excludedPaths -> excludedPath),
# and its resource implementation ignores unrecognised elements silently, so a
# misnamed element is simply dropped on load with no error at all. This script
# loads each file, writes it straight back out, and reports any element that did
# not survive the round trip.
#
# Usage:  ./validate-setup.sh <file.setup> [<file.setup> ...]
#         P2_POOL=/path/to/pool/plugins ./validate-setup.sh ...
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POOL="${P2_POOL:-$HOME/.p2/pool/plugins}"

[ -d "$POOL" ] || { echo "p2 plugin pool not found: $POOL" >&2
                    echo "Set P2_POOL to an Eclipse installation's plugins directory." >&2; exit 2; }

# Every org.eclipse.oomph.* bundle, plus the platform bundles they need at class-init.
{ ls "$POOL" | grep '^org\.eclipse\.oomph' | grep -v '\.source_' | sed 's/_[0-9].*//' | sort -u
  grep -v '^#' "$HERE/bundles.txt"
} | sort -u > "$HERE/.bundles.all"

CP=""; MISSING=""
while read -r b; do
  [ -z "$b" ] && continue
  j=$(ls "$POOL" | grep -E "^${b}_[0-9]" | grep -v '\.source_' | sort -V | tail -1 || true)
  if [ -n "$j" ]; then CP="$CP:$POOL/$j"; else MISSING="$MISSING $b"; fi
done < "$HERE/.bundles.all"
rm -f "$HERE/.bundles.all"
[ -n "$MISSING" ] && echo "warning: bundles not found in pool:$MISSING" >&2

mkdir -p "$HERE/.build"
if [ ! -f "$HERE/.build/Roundtrip.class" ] || [ "$HERE/Roundtrip.java" -nt "$HERE/.build/Roundtrip.class" ]; then
  javac -cp "$CP" -d "$HERE/.build" "$HERE/Roundtrip.java"
fi

CLASSPATH_FILE="$HERE/.build/cp.txt"; printf '%s' "$CP" > "$CLASSPATH_FILE"
exec python3 "$HERE/lint.py" "$@"
