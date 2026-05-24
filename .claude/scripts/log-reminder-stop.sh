#!/usr/bin/env bash
# Hook Stop: tras N turnos con cambios en working tree sin tocar docs/log-cambios.md,
# muestra un systemMessage al usuario. Soft nudge — no bloquea ni obliga a Claude.
# Se resetea cuando el log se toca o cuando no hay cambios pendientes.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$repo_root" ] && exit 0
cd "$repo_root"

THRESHOLD=4
COUNTER="${TMPDIR:-/tmp}/claude-thenucleo-log-counter"

modified=$(git status --porcelain 2>/dev/null || true)

if [ -z "$modified" ]; then
  rm -f "$COUNTER"
  exit 0
fi

if printf '%s\n' "$modified" | grep -q 'docs/log-cambios\.md'; then
  rm -f "$COUNTER"
  exit 0
fi

n=$(cat "$COUNTER" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$COUNTER"

[ "$n" -lt "$THRESHOLD" ] && exit 0

echo 0 > "$COUNTER"

files=$(printf '%s\n' "$modified" | head -8)

jq -n --arg files "$files" --arg n "$n" --arg threshold "$THRESHOLD" '
  {
    systemMessage: ("Llevas \($threshold)+ turnos con cambios en working tree sin tocar docs/log-cambios.md:\n\($files)\n\nSi son cambios funcionales, considera pedirle a Claude que actualice el log + CLAUDE.md/docs antes de cerrar la sesión.")
  }
'
