#!/usr/bin/env bash
# On-demand digest of the agent sessions. Paying for a model only when this is run.
#   brief.sh [hours] [--dry]        hours of ledger to include (default 3); --dry prints the input instead of calling a model
#   MODEL=claude-haiku-5-5 brief.sh  to pick the model (default claude-haiku-5-5)
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
W="${FLEET_WATCH_DIR:-$HOME/.config/fleet-watch}"
set -a; [[ -f "$W/config.env" ]] && source "$W/config.env"; set +a
HOURS="${1:-3}"; [[ "$HOURS" == --dry ]] && { HOURS=3; DRY=1; } || DRY="${2:+1}"
MODEL="${MODEL:-claude-haiku-5-5}"
SESSION="${FLEET_WATCH_SESSION:?set FLEET_WATCH_SESSION in $W/config.env}"

input() {
  echo "## STATE.md"; cat "$W/STATE.md"
  echo; echo "## Ledger, last ${HOURS}h (notifying kinds first, then the rest)"
  python3 -I - "$W/events.jsonl" "$HOURS" <<'PY'
import json, sys
from datetime import datetime, timezone, timedelta
cut = datetime.now(timezone.utc) - timedelta(hours=float(sys.argv[2]))
rows = []
for l in open(sys.argv[1]):
    try: r = json.loads(l)
    except ValueError: continue
    if datetime.fromisoformat(r['at']) >= cut: rows.append(r)
imp = [r for r in rows if r['kind'] in ('risky-command','pr-change','disk-low','lock-long','sentinel-error') or r.get('now') in ('asking','none')]
rest = [r for r in rows if r not in imp and r['kind'] != 'state']
for r in imp + rest[-40:]:
    print(json.dumps(r, ensure_ascii=False)[:400])
print(f'(state flips omitted: {sum(1 for r in rows if r["kind"]=="state")})')
PY
  echo; echo "## Pane tails (last 25 non-empty lines)"
  # the sentinel's own discovery: same ignore list, same harness detection
  python3 -I "$HERE/sentinel.py" panes | while IFS=$'\t' read -r w p k; do
    echo "### $w ($k)"; tmux capture-pane -p -J -t "$p" -S -60 | grep -vE '^\s*$' | tail -25 | cut -c1-400
  done
  [[ -n "${FLEET_WATCH_LOCK_CMD:-}" ]] && { echo; echo "## Locks"; eval "$FLEET_WATCH_LOCK_CMD" || true; }
  echo; df -h /System/Volumes/Data | tail -1
}

PROMPT='Sei il watcher di una flotta di agenti di coding. Rispondi in italiano, breve. Dall INPUT: 1) cosa ha fatto ogni agente nelle ultime ore, 2) rischi o azioni che sembrano non autorizzate (usa le regole di STATE.md), 3) le decisioni che il proprietario deve prendere ora, nell ordine di urgenza. Distingui cio che e nel ledger da cio che deduci. Non inventare: se un dato manca, dillo.'

if [[ "${DRY:-}" == 1 ]]; then input; exit 0; fi
input | claude -p --model "$MODEL" "$PROMPT"
