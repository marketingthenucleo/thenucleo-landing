#!/usr/bin/env bash
# Hook Stop: tras N turnos con cambios sin commitear en working tree,
# muestra systemMessage recordando guardar progreso. Soft nudge — no bloquea ni commitea.
# Se resetea en cuanto el working tree queda limpio (= acabas de commitear).
# Independiente del log-reminder-stop.sh (ese vigila la doc; este vigila el código).
# JSON emitido vía python (portable: funciona en Windows local sin jq y en cloud containers).
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$repo_root" ] && exit 0
cd "$repo_root"

THRESHOLD=5
COUNTER="${TMPDIR:-/tmp}/claude-thenucleo-dirty-counter"

modified=$(git status --porcelain 2>/dev/null || true)

if [ -z "$modified" ]; then
  rm -f "$COUNTER"
  exit 0
fi

n=$(cat "$COUNTER" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$COUNTER"

[ "$n" -lt "$THRESHOLD" ] && exit 0

echo 0 > "$COUNTER"

count=$(printf '%s\n' "$modified" | wc -l | tr -d ' ')
preview=$(printf '%s\n' "$modified" | head -6)

if command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  PY=python
fi

THRESHOLD="$THRESHOLD" COUNT="$count" PREVIEW="$preview" "$PY" -c '
import json, os
threshold = int(os.environ["THRESHOLD"])
count = int(os.environ["COUNT"])
preview = os.environ["PREVIEW"]
msg = (
    f"Llevas {threshold}+ turnos con {count} cambio(s) sin commitear:\n"
    f"{preview}\n\n"
    "Si son cambios funcionales que quieres conservar, considera guardar progreso "
    "(git add + commit + push) antes de seguir."
)
print(json.dumps({"systemMessage": msg}))
'
