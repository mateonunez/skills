#!/usr/bin/env python3
"""Fleet-watch sentinel: event skeleton for a tmux fleet of coding agents, no LLM involved.

Every event is appended to events.jsonl. Only events that need the owner raise a macOS notification.
Reads only: tmux panes, the process table, agent transcripts (Codex and Claude Code JSONL, Hermes and OpenCode SQLite,
opened read-only), `gh search prs`, df, the device lock helper. Writes only under WATCH_DIR.

    sentinel.py          run the watch loop
    sentinel.py panes    print the agent panes it would watch now: window, pane, harness
"""
import json, os, re, shlex, sqlite3, subprocess, sys, time, glob
from contextlib import closing
from datetime import datetime, timezone, timedelta

HOME = os.path.expanduser('~')
WATCH_DIR = os.environ.get('FLEET_WATCH_DIR', f'{HOME}/.config/fleet-watch')
STATE_DIR = f'{WATCH_DIR}/state'
LEDGER = f'{WATCH_DIR}/events.jsonl'


def load_config():
    cfg = {}
    try:
        for line in open(f'{WATCH_DIR}/config.env'):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                cfg[k.strip()] = os.path.expandvars(shlex.split(v.strip())[0]) if v.strip() else ''
    except FileNotFoundError:
        pass
    return {**cfg, **{k: v for k, v in os.environ.items() if k.startswith('FLEET_WATCH_')}}


CONFIG = load_config()
TMUX_SESSION = CONFIG.get('FLEET_WATCH_SESSION', '')
GH_OWNER = CONFIG.get('FLEET_WATCH_GH_OWNER', '')
LOCK_CMD = CONFIG.get('FLEET_WATCH_LOCK_CMD', '')
IGNORE_FILE = f'{WATCH_DIR}/ignore.txt'          # one tmux window name per line
ROLES_FILE = f'{WATCH_DIR}/roles.json'     # {"<session-id-prefix>": "<role>"}
DISK_PATH = '/System/Volumes/Data'
DISK_ALERT_GB = float(os.environ.get('DISK_ALERT_GB', '8'))
LOCK_ALERT_MIN = int(os.environ.get('LOCK_ALERT_MIN', '45'))
SHELLS = {'zsh', 'bash', 'fish', '-zsh', 'sh'}
# what tmux reports as the pane command for an agent CLI; Claude Code reports its version (2.1.296)
AGENT_CMDS = {'node', 'claude', 'codex', 'opencode', 'agy', 'agent', 'cursor-agent', 'grok', 'gemini', 'copilot', 'qwen'}
INTERPRETERS = re.compile(r'(python|Python|bun|deno)[0-9.]*')   # an agent may run as one of these (Hermes is python3)
VERSION = re.compile(r'\d+\.\d+\.\d+')
# executable or script name -> harness; anything under ~/.hermes/ is Hermes
HARNESS_NAMES = {'claude': 'claude', 'codex': 'codex', 'opencode': 'opencode', 'hermes': 'hermes', 'hermes-agent': 'hermes',
                 'agy': 'antigravity', 'agent': 'cursor', 'cursor-agent': 'cursor', 'grok': 'grok', 'gemini': 'gemini',
                 'copilot': 'copilot', 'qwen': 'qwen', 'pi': 'pi'}
NOTIFY_STATES = {'asking', 'none'}
# transcripts kept in SQLite; their tool calls are read like the JSONL ones
TRANSCRIPT_DBS = {'hermes': f'{HOME}/.hermes/state.db', 'opencode': f'{HOME}/.local/share/opencode/opencode.db'}
HERMES_SHELL_TOOLS = {'terminal': 'command', 'execute_code': 'code'}   # tool name -> argument holding the text it runs

ASKING = re.compile(r'Enter to select|Do you want to|❯ [0-9]\. |› [0-9]\. |Esc to cancel|Would you like to|Allow command|\? [0-9]+ question|Action Required|Type your answer')
BUSY = re.compile(r'(…|\.\.\.) \([0-9]+[smh]|esc to interrupt')

# (kind, regex, notify) applied to the text of tool calls only, never to outputs
RISKY = [
    ('pr-merge', re.compile(r'\bgh pr merge\b'), True),
    ('pr-ready', re.compile(r'\bgh pr ready\b'), True),
    ('force-push', re.compile(r'\bgit push\b[^\n"]*(--force|--force-with-lease|\s-f\b)'), True),
    ('commit-flags', re.compile(r'\bgit commit\b[^\n"]*(\s-n\b|--no-verify|--no-gpg-sign|\s-s\b)'), True),
    ('infra-apply', re.compile(r'\b(terraform|terragrunt|atlantis)\b[^\n"]*\b(apply|destroy|import)\b'), True),
    ('kube-mutation', re.compile(r'\bkubectl\b[^\n"]*\b(apply|delete|patch|replace|scale|rollout restart|annotate|label)\b'), True),
    ('aws-mutation', re.compile(r'\baws\b[^\n"]*\b(create|delete|put|update|attach|detach|invalidate)[a-z-]*'), True),
    ('workflow-run', re.compile(r'\bgh workflow run\b'), True),
    ('gh-write-api', re.compile(r'\bgh api\b[^\n"]*(-X|--method)\s+(POST|PUT|PATCH|DELETE)'), True),
    ('pr-create', re.compile(r'\bgh pr create\b'), False),
    ('pr-edit', re.compile(r'\bgh pr (edit|comment|review)\b'), False),
    ('push', re.compile(r'\bgit push\b'), False),
]


def now():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def run(cmd, timeout=20):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ''


def emit(kind, role=None, notify=False, **fields):
    rec = {'at': now(), 'kind': kind, 'role': role, **fields}
    if notify:
        rec['notify'] = True     # readers (digest, monitor) tell "needed me" from "for the record" by this flag
    with open(LEDGER, 'a') as f:
        f.write(json.dumps(rec, ensure_ascii=False) + '\n')
    print(json.dumps(rec, ensure_ascii=False), flush=True)
    if notify:
        title = f'Fleet watch: {role}' if role else 'Fleet watch'
        body = fields.get('summary') or kind
        script = f'display notification {json.dumps(body[:180])} with title {json.dumps(title)}'
        subprocess.run(['osascript', '-e', script], capture_output=True)


def read_set(path):
    try:
        return {l.strip() for l in open(path) if l.strip() and not l.startswith('#')}
    except FileNotFoundError:
        return set()


def process_tree():
    """pid -> command line, and parent pid -> children, from one `ps` call."""
    args, kids = {}, {}
    for line in run(['ps', '-axo', 'pid=,ppid=,args=']).splitlines():
        parts = line.split(None, 2)
        if len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit():
            pid, ppid = int(parts[0]), int(parts[1])
            args[pid] = parts[2] if len(parts) > 2 else ''
            kids.setdefault(ppid, []).append(pid)
    return args, kids


def argv_harness(cmdline):
    """Harness named by a command line: its executable, or the script an interpreter runs. Never the other arguments
    (a Codex pane working in ~/source/hermes-notes must not look like Hermes)."""
    tokens = cmdline.split()
    if not tokens:
        return None
    exe = tokens[0]
    script = next((t for t in tokens[1:] if not t.startswith('-')), '')
    if '/.hermes/' in exe or '/.hermes/' in script:
        return 'hermes'
    for t in (exe, script):
        name = os.path.basename(t)
        if name in HARNESS_NAMES:
            return HARNESS_NAMES[name]
        if VERSION.fullmatch(name):
            return 'claude'
    return None


def pane_harness(cmd, pane_pid, procs):
    """Which agent CLI runs in a pane: the first process under the pane that names one, breadth first."""
    if VERSION.fullmatch(cmd):
        return 'claude'
    args, kids = procs
    todo = [pane_pid]
    while todo:
        pid = todo.pop(0)
        found = argv_harness(args.get(pid, ''))
        if found:
            return found
        todo += kids.get(pid, [])
    return HARNESS_NAMES.get(cmd)


def agent_panes():
    """Discovery: every window of the session, minus the ignore list, with its agent pane and harness."""
    ignore = read_set(IGNORE_FILE)
    out = run(['tmux', 'list-panes', '-s', '-t', TMUX_SESSION, '-F',
               '#{window_name}\t#{pane_id}\t#{pane_current_command}\t#{pane_pid}'])
    procs = None
    found = {}
    for line in out.splitlines():
        parts = line.split('\t')
        if len(parts) != 4 or not parts[3].isdigit():
            continue
        window, pane, cmd, pid = parts
        if window in ignore or (window in found and found[window][1] != 'node'):
            continue
        if not (cmd in AGENT_CMDS or VERSION.fullmatch(cmd) or INTERPRETERS.fullmatch(cmd)):
            continue
        procs = procs or process_tree()
        kind = pane_harness(cmd, int(pid), procs)
        if kind:
            found[window] = (pane, kind)
        elif cmd == 'node' and window not in found:
            found[window] = (pane, 'node')    # an unknown node CLI still counts, as before; a known harness replaces it
    # windows that exist but have no agent process
    names = {l.split('\t')[0] for l in out.splitlines() if '\t' in l} - ignore
    return found, names


def classify(text):
    tail = '\n'.join(text.splitlines()[-16:])
    if ASKING.search(text):
        return 'asking'
    if BUSY.search(tail):
        return 'busy'
    return 'idle'


def last_line(text):
    # pane chrome, not what the agent said: footers ("GPT-6.1-Sol high · ~/repo · Main"), tips, folds
    skip = re.compile(r'^\s*$|^[─━ ]*$|Ask Codex|for agents|shortcuts|warnings|Context:|auto mode|Model:|Session:|⎇| · ~/|Tip: |Show details')
    lines = [l for l in text.splitlines() if not skip.search(l)]
    return re.sub(r'^[•⏺›❯ ]*', '', lines[-1])[:200] if lines else ''


def state_get(name, default=None):
    try:
        return open(f'{STATE_DIR}/{name}').read().strip()
    except FileNotFoundError:
        return default


def state_put(name, value):
    with open(f'{STATE_DIR}/{name}', 'w') as f:
        f.write(str(value))


def check_sessions():
    panes, names = agent_panes()
    known = set(filter(None, (state_get('known-windows') or '').split(',')))
    for w in sorted(set(panes) - known):
        emit('window-discovered', w, agent=panes[w][1], summary=f'new {panes[w][1]} window {w}')
    for w in sorted(known - set(panes)):
        emit('state', w, notify=True, prev=state_get(f'role-{w}'), now='none', summary=f'{w}: no agent running')
        state_put(f'role-{w}', 'none')
    state_put('known-windows', ','.join(sorted(panes)))
    for role, (pane, kind) in panes.items():
        if state_get(f'agent-{role}') != kind:
            state_put(f'agent-{role}', kind)
        text = run(['tmux', 'capture-pane', '-p', '-J', '-t', pane, '-S', '-40'])
        now_state = classify(text)
        prev = state_get(f'role-{role}')
        if now_state != prev:
            summ = last_line(text)
            emit('state', role, notify=(now_state in NOTIFY_STATES), prev=prev, now=now_state, summary=summ)
            state_put(f'role-{role}', now_state)


def check_disk():
    out = run(['df', '-k', DISK_PATH]).splitlines()
    if len(out) < 2:
        return
    free_gb = int(out[1].split()[3]) / 1024 / 1024
    low = free_gb < DISK_ALERT_GB
    was = state_get('disk-low') == '1'
    if low and not was:
        emit('disk-low', notify=True, free_gb=round(free_gb, 1), summary=f'disk free {free_gb:.1f} GB')
    if not low and was:
        emit('disk-ok', free_gb=round(free_gb, 1))
    state_put('disk-low', '1' if low else '0')


def check_locks():
    if not LOCK_CMD:
        return
    out = run(shlex.split(LOCK_CMD))
    held = {}
    for line in out.splitlines():
        m = re.match(r'(\S+): BUSY owner=(\S+) purpose="([^"]*)"', line)
        if m:
            held[m.group(1)] = (m.group(2), m.group(3))
    prev = json.loads(state_get('locks') or '{}')
    for dev, (owner, purpose) in held.items():
        if dev not in prev:
            emit('lock-taken', owner, device=dev, purpose=purpose)
            prev[dev] = {'owner': owner, 'since': time.time(), 'alerted': False}
        elif not prev[dev].get('alerted') and time.time() - prev[dev]['since'] > LOCK_ALERT_MIN * 60:
            emit('lock-long', owner, notify=True, device=dev, purpose=purpose, summary=f'{dev} held by {owner} over {LOCK_ALERT_MIN} min')
            prev[dev]['alerted'] = True
    for dev in list(prev):
        if dev not in held:
            emit('lock-released', prev[dev]['owner'], device=dev)
            del prev[dev]
    state_put('locks', json.dumps(prev))


def roles_map():
    try:
        return json.load(open(ROLES_FILE))
    except Exception:
        return {}


def role_of(source, agent='codex'):
    """Role of a transcript (file path or session id): a roles.json prefix, else `<agent>?<id8>`."""
    base = os.path.basename(source)
    for prefix, role in roles_map().items():
        if prefix in base:
            return role
    m = re.search(r'([0-9a-f]{8})-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', base)   # Codex, Claude, Hermes job-/acp: a uuid
    return f'{agent}?{m.group(1) if m else base.rsplit("_", 1)[-1][:8]}'   # Hermes run_<hex>, YYYYMMDD_HHMMSS_<hex>; OpenCode ses_…


def tool_calls(obj):
    """Tool-call texts of one transcript record: Codex rollouts and Claude Code transcripts."""
    out = []
    p = obj.get('payload') or {}
    if obj.get('type') == 'response_item' and p.get('type') in ('function_call', 'custom_tool_call', 'local_shell_call'):
        text = p.get('arguments') or p.get('input') or json.dumps(p.get('action') or '')
        out.append((p.get('call_id') or p.get('id'), text if isinstance(text, str) else json.dumps(text)))
    elif obj.get('type') == 'assistant':
        content = (obj.get('message') or {}).get('content')
        for b in content if isinstance(content, list) else []:
            if isinstance(b, dict) and b.get('type') == 'tool_use' and b.get('name') == 'Bash':
                cmd = (b.get('input') or {}).get('command')
                if isinstance(cmd, str):
                    out.append((b.get('id'), cmd))
    return out


def _arg_text(args, key):
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except ValueError:
            return args
    if isinstance(args, dict) and isinstance(args.get(key), str):
        return args[key]
    return json.dumps(args)


def hermes_calls(raw):
    """Shell tool calls of one Hermes assistant message (`tool_calls` column, OpenAI shape; `tool_call` nests a batch)."""
    try:
        calls = json.loads(raw or '[]')
    except ValueError:
        return []
    out = []
    for c in calls if isinstance(calls, list) else []:
        fn = (c.get('function') or {}) if isinstance(c, dict) else {}
        name, args = fn.get('name'), fn.get('arguments')
        if name in HERMES_SHELL_TOOLS:
            out.append((c.get('id'), _arg_text(args, HERMES_SHELL_TOOLS[name])))
        elif name == 'tool_call':
            try:
                inner = json.loads(args) if isinstance(args, str) else args or {}
            except ValueError:
                inner = {}
            for n in inner.get('calls') or [] if isinstance(inner, dict) else []:
                if isinstance(n, dict) and n.get('name') in HERMES_SHELL_TOOLS:
                    out.append((c.get('id'), _arg_text(n.get('arguments'), HERMES_SHELL_TOOLS[n['name']])))
    return out


def opencode_call(data):
    """Command of one OpenCode bash part, once its input is filled (a pending part has none yet)."""
    try:
        d = json.loads(data)
    except ValueError:
        return None
    if not isinstance(d, dict) or d.get('type') != 'tool' or d.get('tool') != 'bash':
        return None
    cmd = ((d.get('state') or {}).get('input') or {}).get('command')
    return cmd if isinstance(cmd, str) and cmd else None


def scan(role, agent, call_id, text):
    for kind, rx, notify in RISKY:
        m = rx.search(text)
        if m:
            snippet = text[max(0, m.start() - 40): m.end() + 120].replace('\n', ' ')
            emit('risky-command', role, notify=notify, risk=kind, call_id=call_id, agent=agent, snippet=snippet, summary=f'{role}: {kind}')


def transcript_paths():
    day = datetime.now()
    codex, claude = [], glob.glob(f'{HOME}/.claude/projects/*/*.jsonl')
    for d in (day, day - timedelta(days=1)):
        codex += glob.glob(f'{HOME}/.codex/sessions/{d:%Y/%m/%d}/rollout-*.jsonl')
    return [('codex', x) for x in codex] + [('claude', x) for x in claude]


def check_rollouts():
    cutoff = time.time() - 15 * 60
    ignore = read_set(IGNORE_FILE)
    offsets = json.loads(state_get('offsets') or '{}')
    for agent, path in transcript_paths():
        try:
            st = os.stat(path)
        except OSError:
            continue
        if st.st_mtime < cutoff:
            continue
        # first sight of a file: start at its end so history is never replayed
        start = offsets.get(path, st.st_size)
        if st.st_size <= start:
            offsets[path] = st.st_size
            continue
        with open(path, 'rb') as f:
            f.seek(start)
            chunk = f.read(st.st_size - start)
        offsets[path] = st.st_size
        role = role_of(path, agent)
        if role in ignore:
            continue
        for raw in chunk.decode('utf-8', 'replace').splitlines():
            try:
                obj = json.loads(raw)
            except ValueError:
                continue
            for call_id, text in tool_calls(obj):
                scan(role, agent, call_id, text)
    state_put('offsets', json.dumps(offsets))


def open_db(path):
    return closing(sqlite3.connect(f'file:{path}?mode=ro', uri=True, timeout=2))


def check_hermes(path=TRANSCRIPT_DBS['hermes']):
    if not os.path.exists(path):
        return
    ignore = read_set(IGNORE_FILE)
    with open_db(path) as db:
        last = state_get('cursor-hermes')
        if last is None:   # first sight: start at the end so history is never replayed
            state_put('cursor-hermes', db.execute('SELECT coalesce(max(id), 0) FROM messages').fetchone()[0])
            return
        rows = db.execute("SELECT id, session_id, tool_calls FROM messages WHERE id > ? AND role = 'assistant' "
                          "AND tool_calls IS NOT NULL ORDER BY id LIMIT 2000", (int(last),)).fetchall()
    for _, sid, raw in rows:
        role = role_of(sid, 'hermes')
        if role not in ignore:
            for call_id, text in hermes_calls(raw):
                scan(role, 'hermes', call_id, text)
    if rows:
        state_put('cursor-hermes', rows[-1][0])


def check_opencode(path=TRANSCRIPT_DBS['opencode']):
    """A bash part is written when the call starts and filled later: read by update time, remember the ids seen."""
    if not os.path.exists(path):
        return
    ignore = read_set(IGNORE_FILE)
    with open_db(path) as db:
        last = state_get('cursor-opencode')
        if last is None:   # first sight: start at the end so history is never replayed
            state_put('cursor-opencode', db.execute('SELECT coalesce(max(time_updated), 0) FROM part').fetchone()[0])
            return
        rows = db.execute("SELECT id, session_id, time_updated, data FROM part WHERE time_updated > ? "
                          "AND json_extract(data, '$.tool') = 'bash' ORDER BY time_updated LIMIT 2000", (int(last),)).fetchall()
    seen = json.loads(state_get('seen-opencode') or '[]')
    for part_id, sid, _, data in rows:
        cmd = opencode_call(data)
        if cmd and part_id not in seen:
            seen.append(part_id)
            role = role_of(sid, 'opencode')
            if role not in ignore:
                scan(role, 'opencode', part_id, cmd)
    if rows:
        state_put('cursor-opencode', rows[-1][2])
        state_put('seen-opencode', json.dumps(seen[-500:]))


def guarded(name, check):
    """Run one external source; report a failure once, not every cycle, and clear it when the source recovers."""
    try:
        check()
        if state_get(f'err-{name}'):
            state_put(f'err-{name}', '')
    except Exception as e:
        if state_get(f'err-{name}') != repr(e)[:300]:
            emit('sentinel-error', None, source=name, error=repr(e)[:300])
            state_put(f'err-{name}', repr(e)[:300])


def check_prs():
    if not GH_OWNER:
        return
    since = (datetime.now(timezone.utc) - timedelta(days=2)).strftime('%Y-%m-%d')
    out = run(['gh', 'search', 'prs', '--author', '@me', '--owner', GH_OWNER, f'--updated=>={since}', '--limit', '60',
               '--json', 'repository,number,title,state,isDraft,updatedAt,url'], timeout=40)
    try:
        prs = json.loads(out)
    except ValueError:
        return
    seen = json.loads(state_get('prs') or '{}')
    first_run = not seen
    for pr in prs:
        key = f"{pr['repository']['nameWithOwner']}#{pr['number']}"
        cur = 'draft' if pr.get('isDraft') and pr['state'] == 'open' else pr['state']
        old = seen.get(key)
        if old != cur and not first_run:
            notify = cur in ('merged', 'closed') or (old is None and cur == 'open') or (old == 'draft' and cur == 'open')
            emit('pr-change', None, notify=notify, pr=key, prev=old, now=cur, title=pr['title'][:90], url=pr['url'],
                 summary=f'{key} {old or "new"} -> {cur}')
        seen[key] = cur
    state_put('prs', json.dumps(seen))


def main():
    if not TMUX_SESSION:
        sys.exit(f'FLEET_WATCH_SESSION is not set (see {WATCH_DIR}/config.env)')
    if sys.argv[1:] == ['panes']:
        for window, (pane, kind) in sorted(agent_panes()[0].items()):
            print(f'{window}\t{pane}\t{kind}')
        return
    os.makedirs(STATE_DIR, exist_ok=True)
    emit('sentinel-start', summary='sentinel started')
    tick = 0
    while True:
        try:
            check_sessions()
            if tick % 5 == 0:
                check_rollouts()
                guarded('hermes', check_hermes)
                guarded('opencode', check_opencode)
            if tick % 10 == 0:
                check_disk()
                check_locks()
            if tick % 50 == 0:
                check_prs()
        except Exception as e:  # never die silently
            emit('sentinel-error', None, error=repr(e)[:300])
        tick += 1
        time.sleep(6)


if __name__ == '__main__':
    main()
