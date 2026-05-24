#!/usr/bin/env bash
# Hook SessionStart: inyecta recordatorio si hay commits sin documentar en docs/log-cambios.md.
# Silencioso si todo está al día. Configurado en .claude/settings.json.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$repo_root" ] && exit 0
cd "$repo_root"

[ -f docs/log-cambios.md ] || exit 0

last_log=$(git log -1 --format=%H -- docs/log-cambios.md 2>/dev/null || true)
[ -z "$last_log" ] && exit 0

new_commits=$(git log --oneline "${last_log}..HEAD" 2>/dev/null || true)
n=$(printf '%s' "$new_commits" | grep -c . || true)
[ "$n" -lt 1 ] && exit 0

jq -n --arg n "$n" --arg commits "$new_commits" '
  {
    systemMessage: ("Sin entrada en log para los \($n) commit(s) posteriores al último update de docs/log-cambios.md."),
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("Recordatorio del hook log-reminder: \($n) commit(s) en HEAD desde la última entrada de docs/log-cambios.md:\n\($commits)\n\nSi esta sesión añade cambios funcionales (frontend, infra, workflows n8n, schema Supabase, docs operativas), antes de cerrar actualiza docs/log-cambios.md (formato `YYYY-MM-DD [TAGS] — Título corto` con Área/Qué/Por qué/Impacto/Refs) y propaga a CLAUDE.md / docs/work/* / docs/portal/* / docs/infra/* según la convención doc-junto-a-código.")
    }
  }
'
