#!/usr/bin/env bash
plan=${1:?usage: sweep.sh PLAN.tsv [--dry]}
dry=0
[ "${2:-}" = --dry ] && dry=1
dir=$(cd "$(dirname "$plan")" && pwd)
undo="$dir/undo-$(date +%Y%m%d-%H%M%S).tsv"
before=$(df -k "$HOME" | awk 'NR == 2 { print $4 }')
done_n=0
skip_n=0

skip() { skip_n=$((skip_n + 1)); echo "skipped: $*"; }
run() {
  if [ "$dry" = 1 ]; then echo "would run: $*"; done_n=$((done_n + 1)); return 0; fi
  if "$@" >/dev/null 2>&1; then done_n=$((done_n + 1)); else skip "$* failed"; fi
}
under_home() { case "$1" in "$HOME"/?*) return 0 ;; *) return 1 ;; esac; }

clean_cache() {
  case "$1" in
    uv) run uv cache clean ;;
    pnpm) run pnpm store prune ;;
    npm) run npm cache clean --force ;;
    pip) run pip3 cache purge ;;
    go) run go clean -cache ;;
    brew) run brew cleanup --prune=all ;;
    cocoapods) run pod cache clean --all ;;
    derived-data|playwright|gradle)
      if under_home "$2"; then run find "$2" -mindepth 1 -maxdepth 1 -exec rm -rf {} +; else skip "$2 is outside \$HOME"; fi ;;
    *) skip "unknown cache $1" ;;
  esac
}

while IFS=$'\t' read -r id kind _ _ _ reason target extra; do
  [ -n "$kind" ] || continue
  case "$kind" in
    worktree)
      if [ ! -d "$target" ]; then run git -C "$extra" worktree prune; continue; fi
      want=$(printf '%s\n' "$reason" | sed -n 's/.*dirty:\([0-9]*\).*/\1/p')
      have=$(git -C "$target" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [ "$have" != "${want:-0}" ]; then skip "$target changed since the inventory (dirty ${want:-0} -> $have)"; continue; fi
      [ "$dry" = 1 ] || printf 'worktree\t%s\t%s\t%s\t%s\n' "$extra" "$target" "$(git -C "$target" rev-parse HEAD)" "$(git -C "$target" branch --show-current)" >> "$undo"
      run git -C "$extra" worktree remove --force "$target"
      ;;
    branch)
      if git -C "$extra" worktree list --porcelain | grep -qx "branch refs/heads/$target"; then skip "$extra $target is checked out"; continue; fi
      sha=$(git -C "$extra" rev-parse -q --verify "refs/heads/$target") || { skip "$extra $target no longer exists"; continue; }
      [ "$dry" = 1 ] || printf 'branch\t%s\t%s\t%s\n' "$extra" "$target" "$sha" >> "$undo"
      run git -C "$extra" branch -D "$target"
      ;;
    container) run docker rm "$target" ;;
    image) run docker rmi "$target" ;;
    volume) run docker volume rm "$target" ;;
    builder) run docker builder prune -f ;;
    cache) clean_cache "$target" "$extra" ;;
    sim)
      if [ "$reason" = "runtime unavailable" ]; then run xcrun simctl delete unavailable; else run xcrun simctl delete "$target"; fi
      ;;
    avd)
      if command -v avdmanager >/dev/null 2>&1; then run avdmanager delete avd -n "$target"
      elif under_home "$extra"; then run rm -rf "$extra" "${extra%.avd}.ini"
      else skip "$extra is outside \$HOME"
      fi
      ;;
    *) skip "row $id: unknown kind $kind" ;;
  esac
done < "$plan"

after=$(df -k "$HOME" | awk 'NR == 2 { print $4 }')
echo "done: $done_n, skipped: $skip_n"
[ "$dry" = 1 ] || echo "freed: $(( (after - before) / 1024 )) MB, free now: $(df -h "$HOME" | awk 'NR == 2 { print $4 }')"
[ -f "$undo" ] && echo "undo log: $undo"
