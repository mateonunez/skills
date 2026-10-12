#!/usr/bin/env bash
# Harness for the fleet-watch tools. Deterministic, no model calls except `brief`.
#   harness.sh status | doctor | selftest | start [--fresh] | stop | restart
#   harness.sh events [hours] | risky [n] | merges [n] | asked [n]
#   harness.sh digest [--as reader] [--peek]   ledger lines that matter since this reader's last call; silent when none
#   harness.sh monitor [minutes] [reader]      digest every N minutes (default 10), forever: the stream for a Monitor
#   harness.sh ignore list|add <window>|rm <window>
#   harness.sh role list|add <session-id-prefix> <role>
#   harness.sh rotate [max-mb]        archive a big ledger (keeps the live file small)
#   harness.sh notify-test            raise one macOS notification
#   harness.sh brief [hours] [--dry]  digest by a small model (costs one call), or its input with --dry
set -uo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
W="${FLEET_WATCH_DIR:-$HOME/.config/fleet-watch}"
set -a; [[ -f "$W/config.env" ]] && source "$W/config.env"; set +a
S="${FLEET_WATCH_SESSION:?set FLEET_WATCH_SESSION in $W/config.env}"
cmd="${1:-status}"; shift || true

# the sentinel is one pane of the `sentinel` window; other panes there (a Claude session, say) are not ours to touch
sentinel_pane() { tmux list-panes -t "$S:sentinel" -F '#{pane_id} #{pane_start_command}' 2>/dev/null | awk '/sentinel\.py/ {print $1; exit}'; }
have_sentinel() { [[ -n "$(sentinel_pane)" ]]; }
ledger_py() { python3 -I - "$W/events.jsonl" "$@"; }

case "$cmd" in
  status)
    have_sentinel && echo "sentinel: running" || echo "sentinel: NOT running (harness.sh start)"
    echo "last event: $(tail -n 1 "$W/events.jsonl" 2>/dev/null | jq -r '"\(.at) \(.kind) \(.role // "-")"' 2>/dev/null || echo none)"
    echo "== agents"
    for f in "$W"/state/role-*; do
      [[ -f "$f" ]] || continue; w="${f##*/role-}"
      printf '%-10s %-6s %s\n' "$w" "$(cat "$f")" "$(cat "$W/state/agent-$w" 2>/dev/null)"
    done
    [[ -n "${FLEET_WATCH_LOCK_CMD:-}" ]] && { echo "== locks"; eval "$FLEET_WATCH_LOCK_CMD"; }
    echo "== disk"; df -h /System/Volumes/Data | tail -1 | awk '{printf "free %s of %s (%s used)\n", $4, $2, $5}'
    echo "== needed you (3h)"; "$0" events 3 | tail -n 8
    ;;

  start)
    run="python3 -I '$HERE/sentinel.py' 2>&1 | tee -a sentinel.log"
    [[ "${1:-}" == "--fresh" ]] && run="rm -rf '$W/state'; $run"     # inside the pane: the old sentinel is gone first
    p=$(sentinel_pane)
    if [[ -n "$p" ]]; then tmux respawn-pane -k -t "$p" -c "$W" "$run"
    elif tmux list-windows -t "$S" -F '#{window_name}' | grep -qx sentinel; then tmux split-window -d -b -t "$S:sentinel" -c "$W" "$run"
    else tmux new-window -d -t "$S" -n sentinel -c "$W" "$run"
    fi && echo "sentinel started${1:+ ($1)}"
    ;;
  stop)    p=$(sentinel_pane); [[ -n "$p" ]] && tmux kill-pane -t "$p" && echo "sentinel stopped" || echo "sentinel not running" ;;
  restart) "$0" start ;;

  events)
    ledger_py "${1:-3}" <<'PY'
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
    ;;
  risky)  jq -rc 'select(.kind=="risky-command") | "\(.at[11:19]) \(.role) \(.risk): \(.snippet[0:160])"' "$W/events.jsonl" | tail -n "${1:-20}" ;;
  merges) jq -rc 'select(.kind=="pr-change" and (.now=="merged" or .now=="closed")) | "\(.at[0:16]) \(.now) \(.pr) \(.title)"' "$W/events.jsonl" | tail -n "${1:-15}" ;;
  asked)  jq -rc 'select(.kind=="state" and .now=="asking") | "\(.at[11:19]) \(.role) | \(.summary[0:120])"' "$W/events.jsonl" | tail -n "${1:-10}" ;;

  digest)
    who=claude; peek=0
    while (( $# )); do
      case "$1" in --as) who="${2:?reader name}"; shift 2 ;; --peek) peek=1; shift ;; *) echo "digest [--as reader] [--peek]"; exit 2 ;; esac
    done
    mkdir -p "$W/cursors"
    ledger_py "$W/cursors/digest-$who" "$peek" <<'PY'
import json, os, sys
led, cur, peek = sys.argv[1], sys.argv[2], sys.argv[3] == '1'
size = os.path.getsize(led) if os.path.exists(led) else 0
try: off = int(open(cur).read())
except (OSError, ValueError): off = size     # a new reader starts from now: history is never replayed
if off > size: off = 0                        # the ledger was rotated
with open(led, 'rb') as f:
    f.seek(off); chunk = f.read(size - off)
chunk = chunk[:chunk.rfind(b'\n') + 1]        # a line still being written waits for the next call
keep = ('risky-command', 'pr-change', 'disk-low', 'lock-long', 'sentinel-error', 'window-discovered')
for l in chunk.decode('utf-8', 'replace').splitlines():
    try: r = json.loads(l)
    except ValueError: continue
    if r['kind'] not in keep and r.get('now') not in ('asking', 'none'): continue
    needed = r.get('notify') or r.get('now') in ('asking', 'none')
    detail = r.get('risk') or r.get('pr') or r.get('device') or r.get('agent') or r.get('now') or ''
    if r['kind'] == 'pr-change':
        text = f"{r.get('prev') or 'new'} -> {r.get('now')} {r.get('title', '')} {r.get('url', '')}"
    else:
        text = r.get('snippet') or r.get('summary') or r.get('error') or ''
    print('!' if needed else '.', r['at'][:16].replace('T', ' ') + 'Z', r['kind'], r.get('role') or '-', detail, '|', text[:220])
if not peek:                                  # printed first, then the cursor moves: a kill in between repeats, never loses
    with open(cur, 'w') as f: f.write(str(off + len(chunk)))
PY
    ;;
  monitor)
    min="${1:-10}"; who="${2:-claude}"; down=0
    [[ "$min" =~ ^[0-9]+$ ]] && (( min > 0 )) || { echo "monitor [minutes] [reader]"; exit 2; }
    while :; do
      "$0" digest --as "$who"
      if have_sentinel; then down=0
      elif (( ! down )); then echo "! $(date -u '+%Y-%m-%d %H:%MZ') sentinel-down - | the sentinel is not running: harness.sh start"; down=1
      fi
      sleep $(( min * 60 ))
    done
    ;;

  ignore)
    f="$W/ignore.txt"; touch "$f"
    case "${1:-list}" in
      list) grep -v '^#' "$f" ;;
      add)  w="${2:?window name}"; grep -qx "$w" "$f" || echo "$w" >> "$f"; echo "ignoring $w (the sentinel reads this file every cycle)" ;;
      rm)   w="${2:?window name}"; grep -vx "$w" "$f" > "$f.tmp" && mv "$f.tmp" "$f"; echo "watching $w again" ;;
      *) echo "ignore list|add <window>|rm <window>"; exit 2 ;;
    esac
    ;;
  role)
    f="$W/roles.json"
    case "${1:-list}" in
      list) jq . "$f" ;;
      add)  p="${2:?session-id prefix}"; r="${3:?role}"; jq --arg p "$p" --arg r "$r" '.[$p]=$r' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; jq . "$f" ;;
      *) echo "role list|add <session-id-prefix> <role>"; exit 2 ;;
    esac
    ;;

  rotate)
    max="${1:-20}"; f="$W/events.jsonl"
    size=$(( $(stat -f%z "$f" 2>/dev/null || echo 0) / 1048576 ))
    if (( size >= max )); then
      arch="$W/events-$(date +%Y%m%d-%H%M%S).jsonl.gz"
      gzip -c "$f" > "$arch" && : > "$f" && echo "archived ${size} MB to $arch"
    else echo "ledger is ${size} MB (limit ${max}); nothing to do"; fi
    ;;
  notify-test) osascript -e 'display notification "harness test" with title "Fleet watch"' && echo "sent" ;;

  doctor)
    bad=0; ok() { echo "ok    $*"; }; no() { echo "FAIL  $*"; bad=1; }
    for t in python3 tmux jq gh osascript claude; do command -v "$t" >/dev/null && ok "$t found" || no "$t missing"; done
    tmux has-session -t "$S" 2>/dev/null && ok "tmux session $S" || no "tmux session $S missing"
    n=$(tmux list-windows -t "$S" -F '#{window_name}' 2>/dev/null | grep -cx sentinel)
    [[ "$n" == 1 ]] && ok "exactly one sentinel window" || no "sentinel windows: $n (expected 1)"
    p=$(sentinel_pane); [[ -n "$p" ]] && ok "sentinel pane $p" || no "no pane runs sentinel.py (harness.sh start)"
    [[ -w "$W/events.jsonl" ]] && ok "ledger writable ($(( $(stat -f%z "$W/events.jsonl") / 1024 )) KB)" || no "ledger not writable"
    last=$(tail -n 1 "$W/events.jsonl" | jq -r .at 2>/dev/null)
    ok "last event $last"
    [[ -f "$W/state/known-windows" ]] && ok "watching: $(cat "$W/state/known-windows")" || no "no state yet (sentinel never ran?)"
    found=$(python3 -I "$HERE/sentinel.py" panes | awk -F'\t' '{printf "%s=%s ", $1, $3}')
    [[ -n "$found" ]] && ok "agents now: $found" || echo "warn  no agent pane found now"
    ign="$(grep -v '^#' "$W/ignore.txt" 2>/dev/null | tr '\n' ' ')"; ok "ignored windows: ${ign:-none}"
    unseen=$(comm -23 <(tmux list-windows -t "$S" -F '#{window_name}' | sort) <( { cat "$W/state/known-windows" 2>/dev/null | tr ',' '\n'; echo; grep -v '^#' "$W/ignore.txt" 2>/dev/null; } | sort -u))
    [[ -z "$unseen" ]] && ok "every window is watched or ignored" || echo "warn  windows with no agent process and not ignored: $(echo $unseen)"
    read_from=""
    [[ -d "$HOME/.claude/projects" ]] && read_from+="claude "; [[ -d "$HOME/.codex/sessions" ]] && read_from+="codex "
    [[ -f "$HOME/.hermes/state.db" ]] && read_from+="hermes "; [[ -f "$HOME/.local/share/opencode/opencode.db" ]] && read_from+="opencode "
    ok "tool calls read from: ${read_from:-nothing}"
    panes_only=""; for b in agy agent cursor-agent grok pi gemini copilot qwen; do command -v "$b" >/dev/null && panes_only+="$b "; done
    [[ -n "$panes_only" ]] && echo "info  installed, watched by pane state only (tool calls not read): $panes_only"
    errs=$(grep -c '"sentinel-error"' "$W/events.jsonl" 2>/dev/null || true); [[ "${errs:-0}" == 0 ]] && ok "no sentinel errors" || echo "warn  $errs sentinel-error events (harness.sh events 24)"
    python3 -I -m py_compile "$HERE/sentinel.py" && ok "sentinel.py compiles" || no "sentinel.py does not compile"
    exit $bad
    ;;

  selftest)
    python3 -I - "$HERE/sentinel.py" <<'PY'
import importlib.util, json, sqlite3, sys, tempfile
spec = importlib.util.spec_from_file_location('sentinel', sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cases = [
 ('gh pr merge 12 --squash', 'pr-merge'), ('gh pr ready 12', 'pr-ready'),
 ('git push --force-with-lease origin x', 'force-push'), ('git push -f origin x', 'force-push'),
 ('git commit -S -n -m "x"', 'commit-flags'), ('git commit --no-verify -m x', 'commit-flags'),
 ('terragrunt apply', 'infra-apply'), ('kubectl --context prod delete pod x', 'kube-mutation'),
 ('aws cloudfront create-invalidation --id X', 'aws-mutation'), ('gh workflow run release.yml', 'workflow-run'),
 ('gh api -X POST repos/a/b/issues', 'gh-write-api'), ('gh pr create --title x', 'pr-create'), ('git push -u origin feat', 'push'),
]
silent = ['git status --short', 'gh pr view 12', 'kubectl get pods', 'git commit -S -m "feat: x"', 'aws s3 ls', 'git push --dry-run-not-a-flag-name']
bad = 0
def check(name, got, want):
    global bad
    if got != want: print('FAIL ', name, 'got', got, 'want', want); bad += 1
for text, kind in cases:
    hit = [k for k, rx, _ in m.RISKY if rx.search(text)]
    if kind not in hit: print('MISS ', kind, '<-', text); bad += 1
for text in silent:
    hit = [k for k, rx, n in m.RISKY if rx.search(text) and n]
    if hit: print('FALSE', hit, '<-', text); bad += 1

# extractors: one per transcript format
codex = {'type': 'response_item', 'payload': {'type': 'custom_tool_call', 'call_id': 'c1', 'input': 'gh pr merge 3'}}
claude = {'type': 'assistant', 'message': {'content': [{'type': 'text', 'text': 'x'}, {'type': 'tool_use', 'id': 't1', 'name': 'Bash', 'input': {'command': 'git push --force origin x'}}]}}
other = {'type': 'assistant', 'message': {'content': [{'type': 'tool_use', 'id': 't2', 'name': 'Read', 'input': {'file_path': '/x'}}]}}
for name, rec, want in (('codex', codex, 1), ('claude', claude, 1), ('claude non-Bash', other, 0)):
    check('extract ' + name, len(m.tool_calls(rec)), want)
hermes = json.dumps([
    {'id': 'h1', 'type': 'function', 'function': {'name': 'terminal', 'arguments': json.dumps({'command': 'git commit --no-verify -m x'})}},
    {'id': 'h2', 'type': 'function', 'function': {'name': 'web_search', 'arguments': json.dumps({'query': 'gh pr merge'})}},
    {'id': 'h3', 'type': 'function', 'function': {'name': 'tool_call', 'arguments': json.dumps({'calls': [
        {'name': 'terminal', 'arguments': {'command': 'kubectl delete pod x'}}, {'name': 'browser_navigate', 'arguments': {'url': 'x'}}]})}},
    {'id': 'h4', 'type': 'function', 'function': {'name': 'execute_code', 'arguments': json.dumps({'code': 'import os\nos.system("gh pr ready 4")'})}}])
check('extract hermes', [t for _, t in m.hermes_calls(hermes)], ['git commit --no-verify -m x', 'kubectl delete pod x', 'import os\nos.system("gh pr ready 4")'])
oc = lambda status, cmd=None, tool='bash': json.dumps({'type': 'tool', 'tool': tool, 'state': {'status': status, 'input': {'command': cmd} if cmd else {}}})
check('extract opencode pending', m.opencode_call(oc('pending')), None)
check('extract opencode running', m.opencode_call(oc('running', 'gh pr merge 5')), 'gh pr merge 5')
check('extract opencode non-bash', m.opencode_call(oc('completed', 'x', tool='read')), None)

# roles of unmapped transcripts, and a mapped one
m.roles_map = lambda: {}
check('role codex', m.role_of('/s/rollout-2026-01-01T00-00-00-0123abcd-0000-7000-8000-000000000000.jsonl', 'codex'), 'codex?0123abcd')
check('role claude', m.role_of('/p/4567cdef-0000-4000-8000-000000000000.jsonl', 'claude'), 'claude?4567cdef')
check('role hermes', m.role_of('run_89abcdef01234567', 'hermes'), 'hermes?89abcdef')
check('role hermes cli', m.role_of('20260101_120000_a1b2c3', 'hermes'), 'hermes?a1b2c3')
check('role hermes job', m.role_of('job-fedcba98-0000-4000-8000-000000000000', 'hermes'), 'hermes?fedcba98')
check('role opencode', m.role_of('ses_2b3c4d5e9f', 'opencode'), 'opencode?2b3c4d5e')
m.roles_map = lambda: {'89abcdef': 'bot'}
check('role mapped', m.role_of('run_89abcdef01234567', 'hermes'), 'bot')

# pane discovery: the harness comes from the executable or script, never from other arguments
for cmdline, want in (('node /u/.nvm/versions/node/v24/bin/codex resume 0123 -C /u/source/hermes-notes', 'codex'),
                      ('/u/.hermes/tools/python-3.14/bin/python3 -I /u/.hermes/hermes-agent/run.py', 'hermes'),
                      ('/u/.local/share/claude/versions/2.1.296', 'claude'), ('/u/.opencode/bin/opencode', 'opencode'),
                      ('/u/.local/bin/agy', 'antigravity'), ('python3 manage.py runserver', None), ('-zsh', None)):
    check('argv ' + cmdline[:40], m.argv_harness(cmdline), want)
procs = ({10: '-zsh', 11: 'node /u/bin/codex', 12: 'bash -c gh pr merge 3'}, {10: [11], 11: [12]})
check('pane codex under zsh', m.pane_harness('node', 10, procs), 'codex')
check('pane claude by version', m.pane_harness('2.1.296', 99, ({}, {})), 'claude')
codex_tail = '• Working (3m 1s • esc to interrupt)\n  └ Tip: Use /export\n› Ask Codex to do anything\n  GPT-6.1-Sol high · ~/repo · Main [default]\n  ← for agents · ? for shortcuts'
check('summary skips pane chrome', m.last_line(codex_tail), 'Working (3m 1s • esc to interrupt)')

# SQLite readers end to end, on throwaway databases: no replay of history, no duplicates, pending parts wait
st, got = {}, []
m.state_get = lambda n, d=None: st.get(n, d)
m.state_put = lambda n, v: st.__setitem__(n, str(v))
m.emit = lambda kind, role=None, notify=False, **f: got.append((role, f.get('risk')))
m.roles_map = lambda: {}
m.read_set = lambda p: set()
tmp = tempfile.mkdtemp()
h = sqlite3.connect(f'{tmp}/h.db'); h.execute('create table messages (id integer primary key, session_id text, role text, tool_calls text)')
term = lambda cmd: json.dumps([{'id': 'x', 'function': {'name': 'terminal', 'arguments': json.dumps({'command': cmd})}}])
h.execute('insert into messages (session_id, role, tool_calls) values (?, ?, ?)', ('run_old00000', 'assistant', term('gh pr merge 1'))); h.commit()
m.check_hermes(f'{tmp}/h.db')
h.execute('insert into messages (session_id, role, tool_calls) values (?, ?, ?)', ('run_89abcdef', 'assistant', term('kubectl delete pod x'))); h.commit()
m.check_hermes(f'{tmp}/h.db'); m.check_hermes(f'{tmp}/h.db')
check('hermes reader', got, [('hermes?89abcdef', 'kube-mutation')])
got.clear()
o = sqlite3.connect(f'{tmp}/o.db'); o.execute('create table part (id text primary key, session_id text, time_updated integer, data text)')
o.execute('insert into part values (?, ?, ?, ?)', ('p0', 'ses_old', 1, oc('completed', 'gh pr merge 1'))); o.commit()
m.check_opencode(f'{tmp}/o.db')
o.execute('insert into part values (?, ?, ?, ?)', ('p1', 'ses_2b3c4d5e9', 2, oc('pending'))); o.commit()
m.check_opencode(f'{tmp}/o.db')
for t, status in ((3, 'running'), (4, 'completed')):
    o.execute('update part set time_updated = ?, data = ? where id = ?', (t, oc(status, 'git push --force origin x'), 'p1')); o.commit()
    m.check_opencode(f'{tmp}/o.db')
check('opencode reader', got, [('opencode?2b3c4d5e', 'force-push'), ('opencode?2b3c4d5e', 'push')])

print('selftest:', 'FAILED' if bad else f'ok ({len(cases)} risky, {len(silent)} silent, extractors for codex claude hermes opencode, roles, pane discovery, sqlite readers)')
sys.exit(1 if bad else 0)
PY
    ;;

  brief) "$HERE/brief.sh" "${1:-3}" ${2:+"$2"} ;;
  *) sed -n '2,14p' "$0"; exit 2 ;;
esac
