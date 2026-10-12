# Fleet-watch shell functions. Add to ~/.zshrc:  source ~/.claude/skills/fleet-watch/aliases.zsh
# Everything here is read-only except wstart/wstop (the sentinel window) and wgo (switches the tmux window).

_fw_home="${${(%):-%x}:A:h}"               # where this skill lives (sentinel.py, brief.sh, harness.sh)
export WATCH_DIR="${FLEET_WATCH_DIR:-$HOME/.config/fleet-watch}"
set -a; [[ -f "$WATCH_DIR/config.env" ]] && source "$WATCH_DIR/config.env"; set +a
_w_roles="<a window name of your session>"

# ---- sentinel (the event daemon) -------------------------------------------------

# wstart [--fresh] / wstop / wup: manage the sentinel window through the harness
wstart() { "$_fw_home/harness.sh" start "$@"; }
wstop()  { "$_fw_home/harness.sh" stop; }
wup()    { tmux list-panes -t "${FLEET_WATCH_SESSION}:sentinel" -F '#{pane_start_command}' 2>/dev/null | grep -q 'sentinel\.py' && echo "sentinel: running" || echo "sentinel: NOT running (wstart)"; }

# ---- reading the ledger ------------------------------------------------------------

# wlog: live feed, one readable line per event; noisy busy/idle flips hidden unless `wlog all`
wlog() {
  local filter='select(.kind!="state" or .now=="asking" or .now=="none")'
  [[ "$1" == all ]] && filter='.'
  tail -n 0 -f "$WATCH_DIR/events.jsonl" | jq -rc --unbuffered "$filter | \"\(.at[11:19]) \(.kind) \(.role // \"-\") \(.risk // .now // .pr // .device // \"\") \(.summary // \"\")\""
}
# wev [hours]: what needed you in the last hours (asking, risky commands, PR changes, disk, long locks)
wev() {
  python3 -I - "$WATCH_DIR/events.jsonl" "${1:-3}" <<'PY'
import json, sys
from datetime import datetime, timezone, timedelta
cut = datetime.now(timezone.utc) - timedelta(hours=float(sys.argv[2]))
keep = ('risky-command', 'pr-change', 'disk-low', 'lock-long', 'sentinel-error')
for l in open(sys.argv[1]):
    try: r = json.loads(l)
    except ValueError: continue
    if datetime.fromisoformat(r['at']) < cut: continue
    if r['kind'] in keep or r.get('now') in ('asking', 'none'):
        print(r['at'][11:19], r['kind'], r.get('role') or '-', r.get('risk') or r.get('now') or r.get('pr') or '', '|', (r.get('summary') or '')[:110])
PY
}
# wrisk [hours]: only the risky tool calls, with the matched snippet
wrisk() { jq -rc 'select(.kind=="risky-command") | "\(.at[11:19]) \(.role) \(.risk): \(.snippet[0:160])"' "$WATCH_DIR/events.jsonl" | tail -n "${1:-20}"; }
# wmerges: every PR change to merged/closed seen by the sentinel
wmerges() { jq -rc 'select(.kind=="pr-change" and (.now=="merged" or .now=="closed")) | "\(.at[0:16]) \(.now) \(.pr) \(.title)"' "$WATCH_DIR/events.jsonl" | tail -n "${1:-15}"; }
# wasked: agents that asked a question, newest last
wasked() { jq -rc 'select(.kind=="state" and .now=="asking") | "\(.at[11:19]) \(.role) | \(.summary[0:120])"' "$WATCH_DIR/events.jsonl" | tail -n "${1:-10}"; }
# wdigest [--peek]: what mattered since your last wdigest (its own cursor, separate from the Claude monitor's); silent when nothing
wdigest() { "$_fw_home/harness.sh" digest --as shell "$@"; }
# wmon [minutes]: the same digest every N minutes (default 10) in this terminal, until Ctrl-C
wmon() { "$_fw_home/harness.sh" monitor "${1:-10}" shell; }

# ---- the agents --------------------------------------------------------------------

# wpanes: current state and harness of each watched agent (from the sentinel's own state files)
wpanes() {
  local w
  for w in $(tmux list-windows -t "$FLEET_WATCH_SESSION" -F '#{window_name}'); do
    [[ -f "$WATCH_DIR/state/role-$w" ]] && printf '%-10s %-6s %s\n' "$w" "$(cat "$WATCH_DIR/state/role-$w")" "$(cat "$WATCH_DIR/state/agent-$w" 2>/dev/null)"
  done
}
# wgo <window>: jump to an agent window
wgo() { tmux select-window -t "$FLEET_WATCH_SESSION:${1:?window: $_w_roles}" && tmux switch-client -t "$FLEET_WATCH_SESSION" 2>/dev/null; }
# wtail <window> [lines]: last lines of an agent's pane, without switching to it
wtail() {
  local p
  p=$(tmux list-panes -s -t "$FLEET_WATCH_SESSION" -F '#{window_name} #{pane_id} #{pane_current_command}' \
      | awk -v w="${1:?window: $_w_roles}" '$1==w && $3!="zsh" && $3!="bash" {print $2; exit}')
  [[ -n "$p" ]] && tmux capture-pane -p -J -t "$p" -S -200 | grep -vE '^\s*$' | tail -n "${2:-30}" | cut -c1-220 || echo "no agent in window $1"
}

# ---- digest (costs a Haiku call, only when you run it) -----------------------------

wbrief()  { "$_fw_home/brief.sh" "${1:-3}"; }              # wbrief [hours]
wbrief6() { "$_fw_home/brief.sh" 6; }
wdry()    { "$_fw_home/brief.sh" "${1:-3}" --dry | less; } # the exact input the model would see, free
wstate()  { ${PAGER:-less} "$WATCH_DIR/STATE.md"; }         # durable state: open decisions, rules, what notifies

# ---- utilities ---------------------------------------------------------------------

wlocks()  { [[ -n "$FLEET_WATCH_LOCK_CMD" ]] && eval "$FLEET_WATCH_LOCK_CMD" || echo "no lock command configured"; }
wdisk()   { df -h /System/Volumes/Data | tail -1 | awk '{printf "free %s of %s (%s used)\n", $4, $2, $5}'; }
wdocker() { docker system df; }                              # what Docker holds (builder cache, images, volumes)
wsims()   { xcrun simctl list devices booted | sed 1,1d; adb devices 2>/dev/null | sed 1d | grep -v '^$'; }   # booted simulators and emulators
wprs()    { gh search prs --author @me ${FLEET_WATCH_GH_OWNER:+--owner $FLEET_WATCH_GH_OWNER} --state open --json repository,number,title,isDraft --jq '.[] | "\(.repository.nameWithOwner)#\(.number) \(if .isDraft then "[draft] " else "" end)\(.title[0:80])"'; }
wsweep()  { echo "Run the Claude skill /disk-sweep in a Claude session; it prepares the plan and you run the sweep command."; wdisk; }
# wnow: one screen for "what is going on right now", no model involved
wnow() { echo "== sentinel"; wup; echo "== agents"; wpanes; echo "== locks"; wlocks; echo "== disk"; wdisk; echo "== needed you (3h)"; wev 3 | tail -n 8; }
