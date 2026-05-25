#!/usr/bin/env bash
# Hook SessionStart: avisa si HEAD está detrás de su upstream remoto.
# Detecta drift cuando se trabaja desde Claude Code on the web/mobile y el clon
# local no se ha refrescado. Silencioso si todo está al día.
# JSON emitido vía python (portable: Windows local sin jq y cloud containers).
# Configurado en .claude/settings.json.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$repo_root" ] && exit 0
cd "$repo_root"

# Rama actual (skip si HEAD detached)
branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
[ -z "$branch" ] && exit 0

# Upstream configurado para la rama (ej. origin/main)
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)
[ -z "$upstream" ] && exit 0

# Remote real de esa rama (normalmente "origin")
remote=$(git config "branch.$branch.remote" 2>/dev/null || echo origin)

# Fetch silencioso. El timeout del hook (10s en settings.json) lo corta si la red está lenta.
git fetch --quiet "$remote" "$branch" 2>/dev/null || exit 0

# Conteo ahead/behind en una sola llamada
counts=$(git rev-list --left-right --count "HEAD...$upstream" 2>/dev/null || printf '0\t0')
ahead=$(printf '%s' "$counts" | cut -f1)
behind=$(printf '%s' "$counts" | cut -f2)

[ "$behind" -eq 0 ] && exit 0

# Lista de commits remotos que aún no están en local (cap 20 por ruido)
new_commits=$(git log --oneline "HEAD..$upstream" 2>/dev/null | head -20)

if command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  PY=python
fi

BEHIND="$behind" AHEAD="$ahead" BRANCH="$branch" UPSTREAM="$upstream" COMMITS="$new_commits" "$PY" -c '
import json, os
behind = int(os.environ["BEHIND"])
ahead = int(os.environ["AHEAD"])
branch = os.environ["BRANCH"]
upstream = os.environ["UPSTREAM"]
commits = os.environ["COMMITS"]

ahead_tail = f" y {ahead} por delante" if ahead > 0 else ""
sys_msg = (
    f"Rama {branch} está {behind} commit(s) detrás de {upstream}. "
    "Considera git pull antes de editar para evitar drift."
)
ctx = (
    f"Hook upstream-sync: {branch} está {behind} commit(s) detrás de {upstream}{ahead_tail}.\n\n"
    f"Commits remotos que aún no tienes localmente:\n{commits}\n\n"
    "Antes de editar archivos del repo, sugiere al usuario ejecutar git pull. "
    "Si hay cambios uncommitted, propón stash + pull --ff-only + stash pop. "
    "NO ejecutes pull sin confirmación explícita del usuario."
)
print(json.dumps({
    "systemMessage": sys_msg,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ctx,
    },
}))
'
