---
name: fleet-watch
description: Operate and troubleshoot my tmux fleet of coding-agent sessions through one deterministic harness — the sentinel event daemon, its ledger, the on-demand brief, the memory monitor and the shell helpers — and keep the watch state file honest.
argument-hint: "[status | doctor | selftest | start | stop | events [h] | risky | merges | asked | digest | monitor [min] | ignore ... | role ... | rotate | brief [h]]"
disable-model-invocation: true
---

# /fleet-watch

The watch is a **daemon plus a ledger, not a model**. `~/.config/fleet-watch/sentinel.py` runs in a pane of the tmux window `sentinel` of
the configured session (`FLEET_WATCH_SESSION`), writes every event to `events.jsonl` and raises a macOS notification only when I am needed. A model
reads the ledger only when I ask (`brief`), when I run this skill, or when the monitor hands it new lines to remember. Never rebuild the old
pattern of a Claude session polling panes: it burned tokens on "nothing new" and lost context at every compaction.

## Constants

- Harness: `~/.claude/skills/fleet-watch/harness.sh <subcommand>`. It is the only way this skill touches the watch.
- Code lives in this skill folder: `harness.sh`, `sentinel.py`, `brief.sh`, `aliases.zsh`.
- Data folder: `~/.config/fleet-watch/` — `events.jsonl` (ledger), `state/` (the sentinel's memory), `cursors/` (where each digest reader
  stopped), `ignore.txt` (windows never watched), `roles.json` (session id prefix to role, personal data), `STATE.md` (durable human state),
  `config.env`, `sentinel.log`.
- `config.env` in the watch folder holds the settings: `FLEET_WATCH_SESSION` (tmux session to watch), `FLEET_WATCH_GH_OWNER` (GitHub org for the PR watch, empty skips it), `FLEET_WATCH_LOCK_CMD` (optional lock helper that prints `<id>: BUSY owner=<who> purpose="<text>"`, empty skips it). Nothing else is project-specific.
- Windows of that session are discovered every cycle; resolve panes by window name, never by pane id. A pane is an agent when the process
  under it is a known harness, read from its executable or script name (never its other arguments): Claude Code, Codex, Hermes, OpenCode,
  Antigravity (`agy`), Cursor (`agent`), Grok, Gemini, Copilot, Qwen, pi. `doctor` prints what it finds now; `status` shows each window's harness.
- Tool calls are read from the transcripts, shell calls only: Codex rollouts in `~/.codex/sessions`, Claude Code in `~/.claude/projects`
  (Bash), Hermes in `~/.hermes/state.db` (`terminal`, `execute_code`), OpenCode in `~/.local/share/opencode/opencode.db` (`bash`); the
  SQLite ones are opened read-only. A transcript maps to a role by session-id prefix in `roles.json`; an unmapped one shows as
  `<harness>?<id8>` (`codex?0123abcd`, `hermes?89abcdef`), and a role listed in `ignore.txt` is skipped.

## Subcommands

| Run | Does |
|---|---|
| `status` | sentinel up or not, last event, agent states and harness, device locks, disk, what needed me in 3 h |
| `doctor` | tools present, one sentinel window and pane, ledger writable, agents found now, windows watched or ignored, transcript sources, no sentinel errors, sentinel compiles. Exit 1 on failure |
| `selftest` | risky patterns (every risky one matches, every safe one stays silent), the extractor of each transcript format, roles, pane discovery, and the SQLite readers end to end on throwaway databases |
| `start [--fresh]` / `stop` / `restart` | manage only the sentinel's pane (other panes in its window keep running); `--fresh` forgets the saved states |
| `events [h]` `risky [n]` `merges [n]` `asked [n]` | read the ledger by what matters |
| `digest [--as reader] [--peek]` | the lines that matter since this reader's last call, then moves its cursor; prints nothing when nothing happened |
| `monitor [min] [reader]` | `digest` every N minutes (default 10) forever, plus one line if the sentinel goes down: the stream a Monitor reads |
| `ignore list/add/rm <window>` | choose which windows the sentinel skips (takes effect next cycle) |
| `role list/add <prefix> <role>` | map a session id prefix (any harness) to a role so risky commands carry the right name |
| `rotate [max-mb]` | archive a ledger above the limit to a `.gz` and start a fresh one |
| `notify-test` | one notification, to check that macOS lets it through |
| `brief [h] [--dry]` | digest by a small model (one call); `--dry` prints exactly what it would send |

## Steps

1. **Orient.** Run `status`. If the sentinel is down, `doctor` first, then `start`. Done when `status` shows it running and
   a fresh last event.
2. **Answer from the ledger.** For "what happened", "what needs me", "who merged" use `events`, `risky`, `merges`, `asked`.
   Say what is in the ledger and what is my inference; the sentinel sees state and tool calls, not intent.
3. **Change the watch only through the harness.** A new tmux window I do not want watched: `ignore add`. A new agent session:
   `role add`. Never edit `sentinel.py`, `ignore.txt` or `roles.json` by hand from this skill.
4. **Verify after any change to patterns or discovery.** `selftest` then `doctor`. A change to the risky patterns is not done
   until `selftest` passes with a case for the new pattern added in `harness.sh`.
5. **Keep `STATE.md` true.** When I decide something about an agent (authorise, defer, decline), update that agent's entry in
   `STATE.md` in the same turn. It is the memory that survives compaction and the retirement of any session.
6. **Report.** Italian, short: state, what needs me ordered by urgency, then the exact command if I must act.

## Monitor (`/fleet-watch monitor [minutes]`)

The monitor gives the ledger a memory without a model polling it: a shell loop does the waiting and the model wakes only when there are lines to keep.

1. **Arm.** Monitor tool, command `~/.claude/skills/fleet-watch/harness.sh monitor <minutes, default 10>`, `timeout_ms` 1800000,
   description `fleet-watch: novità dal ledger`. One monitor per session. The reader `claude` has one cursor, so a second Claude session
   that wants its own monitor passes another reader name as the second argument.
2. **Read a batch.** Each notification is one batch of lines `<flag> <date time>Z <kind> <role> <detail> | <text>`. Flag `!` means the
   sentinel already notified me (an agent asking or gone, a notifying risky command, a PR merged or opened, a long lock, low disk,
   the sentinel down); `.` is for the record (push, PR created, a new agent window, a sentinel error).
3. **Remember it.** One `mem_save` per batch, project `fleet-watch`, type `discovery`, title `Fleet <date> <HH:MM>Z: <who and what, few
   words>`, content the lines grouped by agent, keeping risky snippets and PR urls verbatim, with any inference marked as such. A batch made
   only of `asking` lines is not saved: it is transient, and my decision goes to `STATE.md` when I make it. If `mem_save` asks for a
   judgment, mark each candidate `related`: an event log never supersedes another.
4. **Tell me only what needs me.** When a batch has a `!` line, one or two lines in Italian: who, what, the command to look. Otherwise
   at most one line saying it was saved. No PushNotification: the sentinel already raised the macOS one.
5. **Re-arm** with the same command when the monitor expires, without commentary. Stop it (TaskStop) when I say so.
6. **Never act on a line.** The monitor reads and remembers; it never sends keys or messages to an agent and never calls a remote system.

## Adding a harness

Its executable name goes in `HARNESS_NAMES` (and in `AGENT_CMDS` if tmux reports it under that name) so its pane is watched. If it keeps
readable transcripts, add an extractor and a reader that starts at the end on first sight and never repeats a call, then a `selftest`
case for both in `harness.sh`, then `doctor`. Until then `doctor` lists it as watched by pane state only.

## Rules

- Read-only on the agents and on every remote system. The harness writes only under `~/.config/fleet-watch/` and manages only the
  sentinel's pane.
- Never send keystrokes or messages to an agent pane. Relaying to an agent happens only when I ask in as many words, labelled
  "riportato dal watcher".
- The model never polls. Waiting is the sentinel's job and the notification is how I find out; `monitor` is a shell loop that wakes the
  model only when the ledger has lines worth remembering. Never a `/loop`, a scheduled wakeup or a cron that runs a model to look at the ledger.
- The sentinel does not see: non-shell tool calls (MCP, Edit, Read; Hermes web and browser tools), the tool calls of Antigravity,
  Cursor, Grok, Gemini, Copilot, Qwen and pi (their panes are watched for state only), Bitbucket PRs, production state, an agent's intent.
  Say so when a question lands there instead of guessing.
- A risky-command match is a prompt for me to look, not a verdict: the patterns read tool-call text and can match a command
  that was only quoted. Check the snippet before calling anything unauthorised.
- `brief` costs a model call; offer `--dry` first when the question is only "what would it see".
- Local aliases (`wnow`, `wev`, `wtail`, `wgo`, `wlog`, `wdigest`, `wmon`, `wdisk`, `wlocks`, `wprs`...) are the same reads for my shell;
  this skill and the aliases must agree, so a new subcommand gets a matching function in `aliases.zsh`.
