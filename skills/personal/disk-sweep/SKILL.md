---
name: disk-sweep
description: Sweep my Mac for what is safe to delete — merged worktrees and branches, Docker leftovers, tool caches, simulators and emulators — grill me once on the doubtful rest, and hand me one command that deletes only what I approved.
argument-hint: "[--root <dir>]... [--exclude <pattern>]... [--keep <pattern>]... [--days <N>] [--no-fetch] [--dry]"
disable-model-invocation: true
---

# /disk-sweep

The disk fills up with closed work: worktrees of merged PRs, squash-merged branches, stopped containers of old stacks, tool caches, simulators nobody boots. A sweep is three moves: the script takes a deterministic **inventory**, I **grill** the user once on what only they can decide, and the user runs **one command** that deletes exactly the approved rows.

## Constants

- Inventory: `~/.claude/skills/disk-sweep/inventory.sh [--root DIR]... [--exclude P]... [--keep P]... [--days N] [--no-fetch] [--out FILE]` — reads only, plus `git fetch --prune`. Writes `$TMPDIR/disk-sweep/inventory.tsv` (`id kind verdict size_kb age_days reason target extra`) and prints a summary grouped by verdict.
- Sweep: `~/.claude/skills/disk-sweep/sweep.sh PLAN.tsv [--dry]` — deletes the plan's rows with the tool's own command, re-checks each row first, writes an undo log beside the plan.
- `--exclude` hides a path from the inventory entirely; `--keep` lists it but pins it to keep. Both match substrings.

## Verdicts

The script decides, I review:

| Verdict | Meaning |
|---|---|
| **safe** | Nothing is lost: PR merged or commits already in the default branch (ancestor or patch-equivalent, so squash merges count), clean worktree, dangling image, container stopped for more than `--days`, regenerable cache, simulator whose runtime is gone. |
| **ask** | Something could be lost or slow to rebuild: dirty worktree, PR closed without merge, remote branch deleted but commits not on main, unpushed branch older than `--days`, unused image, dangling volume (holds data), Playwright/CocoaPods/Gradle caches, simulator or emulator unused for `--days`. |
| **keep** | Never offered: open PR, tmux pane cwd, worktree touched in the last two days, running container, image used by a container, booted simulator, keep-list match. |

## Steps

1. **Scope.** Roots from the arguments, default `~/source`. Add to `--exclude` every project the user's instructions or memory put off limits, so it never appears; add to `--keep` what a disk-cleanup memory says to keep. Done when the inventory command line is written out.
2. **Inventory.** Run it and read the summary to the end. Then overrule the script where you know better: a session running in this conversation, a campaign the user said is still open, an evidence folder someone needs — move those rows to keep and say why. Done when every safe and ask row has been read and none contradicts what you know.
3. **Grill.** One round, AskUserQuestion with `multiSelect` (a numbered list otherwise). One option per group — safe git, safe Docker, safe caches, then each ask group (dirty worktrees, closed or orphaned branches, images and volumes, simulators and emulators) — each with its row count, size and two or three named examples; recommended groups first. Keep rows are never asked. A group the user splits ("yes, but not X") becomes row-level. Done when every safe and ask row is approved or declined.
4. **Plan.** Copy the approved rows verbatim from `inventory.tsv` into `plan.tsv` beside it, selecting by id. Run `sweep.sh plan.tsv --dry` and read it. Done when the dry run lists exactly the approved rows and nothing else.
5. **Hand over.** Give the user `! bash ~/.claude/skills/disk-sweep/sweep.sh <plan path>` — the `!` prefix runs it in this session so the output lands in the conversation. The deletion stays in the user's hands; with `--dry` among the arguments, stop after step 4.
6. **Report.** Freed space, rows done and skipped with the reason, the undo log path (`git branch <name> <sha>` restores a branch, `git worktree add <path> <sha>` a worktree), and what was declined, to look at next time. When a disk-cleanup memory exists, update it with the outcome and the keep-list.

## Rules

- An approved list is the only permission, and it covers that list alone: rows that changed since the inventory are skipped by the sweep, new candidates wait for the next run.
- Everything stays local: remote branches, pushes and hosted services are out of scope.
- Tool-native cleaners first (`uv cache clean`, `docker builder prune`, `xcrun simctl delete`); plain removal only for caches that have none.
