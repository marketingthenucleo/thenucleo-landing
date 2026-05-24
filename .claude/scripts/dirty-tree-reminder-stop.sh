#!/usr/bin/env bash
# Hook Stop: tras N turnos con cambios sin commitear en working tree,
# muestra systemMessage recordando guardar progreso. Soft nudge — no bloquea ni commitea.
# Se resetea en cuanto el working tree queda limpio (= acabas de commitear).
# Independiente del log-reminder-stop.sh (ese vigila la doc; este vigila el código).
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

jq -n --arg count "$count" --arg preview "$preview" --arg threshold "$THRESHOLD" '
  {
    systemMessage: ("Llevas \($threshold)+ turnos con \($count) cambio(s) sin commitear:\n\($preview)\n\nSi son cambios funcionales que quieres conservar, considera guardar progreso (git add + commit + push) antes de seguir.")
  }
'
