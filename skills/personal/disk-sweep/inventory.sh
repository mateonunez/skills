#!/usr/bin/env bash
roots=()
excludes=()
keeps=()
days=30
fetch=1
out="${TMPDIR:-/tmp}"
out="${out%/}/disk-sweep/inventory.tsv"

while [ $# -gt 0 ]; do
  case "$1" in
    --root) roots+=("$2"); shift 2 ;;
    --exclude) excludes+=("$2"); shift 2 ;;
    --keep) keeps+=("$2"); shift 2 ;;
    --days) days="$2"; shift 2 ;;
    --no-fetch) fetch=0; shift ;;
    --out) out="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ ${#roots[@]} -eq 0 ] && roots=("$HOME/source")

mkdir -p "$(dirname "$out")"
rows="$out.rows"
: > "$rows"
now=$(date +%s)
panes=$(tmux list-panes -a -F '#{pane_current_path}' 2>/dev/null)

matches() {
  local subject=$1 p
  shift
  for p in "$@"; do
    case "$subject" in *$p*) return 0 ;; esac
  done
  return 1
}
excluded() { [ ${#excludes[@]} -gt 0 ] && matches "$1" "${excludes[@]}"; }
kept() { [ ${#keeps[@]} -gt 0 ] && matches "$1" "${keeps[@]}"; }

row() {
  local kind=$1 verdict=$2 size=$3 age=$4 reason=$5 target=$6 extra=$7
  if [ "$verdict" != keep ] && kept "$target $extra"; then verdict=keep; reason="keep-list; $reason"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$verdict" "${size:-0}" "${age:--}" "$reason" "$target" "$extra" >> "$rows"
}

with_timeout() {
  local t=$1
  shift
  "$@" &
  local pid=$!
  ( sleep "$t"; kill "$pid" ) >/dev/null 2>&1 &
  local watcher=$!
  wait "$pid" 2>/dev/null
  local rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  return $rc
}

sizekb() { du -sk "$1" 2>/dev/null | cut -f1; }

agedays() {
  local m
  m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || { echo -; return; }
  echo $(( (now - m) / 86400 ))
}

inpane() { [ -n "$panes" ] && printf '%s\n' "$panes" | grep -q "^$1"; }

older() { [ "$1" != - ] && [ "$1" -ge "$days" ]; }

ago_days() {
  local n unit
  n=$(printf '%s\n' "$1" | grep -oE '[0-9]+ (second|minute|hour|day|week|month|year)' | head -1)
  [ -z "$n" ] && { echo 0; return; }
  unit=${n#* }
  n=${n%% *}
  case "$unit" in
    day) echo "$n" ;;
    week) echo $((n * 7)) ;;
    month) echo $((n * 30)) ;;
    year) echo $((n * 365)) ;;
    *) echo 0 ;;
  esac
}

human_kb() {
  printf '%s\n' "$1" | awk '{
    v = $1; u = v; sub(/[0-9.]+/, "", u); sub(/[A-Za-z]+$/, "", v)
    m = (u ~ /^[Tt]/) ? 1073741824 : (u ~ /^[Gg]/) ? 1048576 : (u ~ /^[Mm]/) ? 1024 : (u ~ /^[Kk]/) ? 1 : 1 / 1024
    printf "%d\n", v * m
  }'
}

merged_state() {
  local dir=$1 ref=$2 def=$3 cherry
  [ -z "$def" ] && { echo no; return; }
  git -C "$dir" merge-base --is-ancestor "$ref" "$def" 2>/dev/null && { echo ancestor; return; }
  cherry=$(git -C "$dir" cherry "$def" "$ref" 2>/dev/null) || { echo no; return; }
  if [ -n "$cherry" ] && ! printf '%s\n' "$cherry" | grep -q '^+'; then echo patch; else echo no; fi
}

git_section() {
  local root
  for root in "${roots[@]}"; do
    find "$root" -maxdepth 5 -name node_modules -prune -o -name .git -type d -print -prune 2>/dev/null
  done | sed 's|/\.git$||' | sort -u | while read -r repo; do
    excluded "$repo" && continue
    local remote def prs cur wtb
    remote=$(git -C "$repo" remote get-url origin 2>/dev/null) || continue
    [ "$fetch" = 1 ] && git -C "$repo" fetch -q --prune origin 2>/dev/null
    def=$(git -C "$repo" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    if [ -z "$def" ]; then
      for c in origin/main origin/master origin/develop; do
        git -C "$repo" rev-parse -q --verify "$c" >/dev/null && { def=$c; break; }
      done
    fi
    prs=""
    case "$remote" in
      *github.com*)
        prs=$(gh pr list -R "$(printf '%s\n' "$remote" | sed -E 's#.*github.com[:/]##; s#\.git$##')" --state all --limit 300 \
          --json headRefName,state,number --jq '.[] | "\(.headRefName)\t\(.state)#\(.number)"' 2>/dev/null)
        ;;
    esac
    prstate() {
      [ -z "$prs" ] && { echo -; return; }
      local s
      s=$(printf '%s\n' "$prs" | awk -F'\t' -v b="$1" '$1 == b { print $2; exit }')
      echo "${s:-none}"
    }

    git -C "$repo" worktree list --porcelain | awk '/^worktree /{ print substr($0, 10) }' | tail -n +2 | while read -r w; do
      excluded "$w" && continue
      if [ ! -d "$w" ]; then row worktree safe 0 - "missing on disk, prune" "$w" "$repo"; continue; fi
      local b dirty ahead merged pr size age reason v
      b=$(git -C "$w" branch --show-current)
      dirty=$(git -C "$w" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      ahead=$(git -C "$w" rev-list --count '@{u}..HEAD' 2>/dev/null || echo -)
      merged=$(merged_state "$w" HEAD "$def")
      pr=$(prstate "$b")
      size=$(sizekb "$w")
      age=$(agedays "$(git -C "$w" rev-parse --absolute-git-dir)/logs/HEAD")
      reason="branch:${b:-detached} pr:$pr dirty:$dirty merged:$merged unpushed:$ahead"
      if inpane "$w"; then v=keep; reason="tmux pane cwd; $reason"
      elif [ "${pr%%#*}" = OPEN ]; then v=keep
      elif [ "$dirty" != 0 ]; then v=ask
      elif [ "$age" != - ] && [ "$age" -lt 2 ] && [ "${pr%%#*}" != MERGED ]; then v=keep; reason="touched <2d; $reason"
      elif [ "$pr" = none ] && [ "$merged" = ancestor ]; then v=ask; reason="no commits of its own, maybe a fresh workspace; $reason"
      elif [ "$merged" != no ] || { [ "${pr%%#*}" = MERGED ] && { [ "$ahead" = 0 ] || [ "$ahead" = - ]; }; }; then v=safe
      else v=ask
      fi
      row worktree "$v" "$size" "$age" "$reason" "$w" "$repo"
    done

    cur=$(git -C "$repo" branch --show-current)
    wtb=$(git -C "$repo" worktree list --porcelain | awk '/^branch /{ sub("refs/heads/", "", $2); print $2 }')
    git -C "$repo" for-each-ref --format='%(refname:short)%1f%(upstream:track)%1f%(upstream:short)%1f%(committerdate:raw)' refs/heads |
      while IFS=$'\x1f' read -r b track up ts; do
        case "$b" in "${def#origin/}"|"$cur"|main|master|develop|dev|qa|staging|production) continue ;; esac
        printf '%s\n' "$wtb" | grep -qx "$b" && continue
        local pr merged age remote reason v
        pr=$(prstate "$b")
        merged=$(merged_state "$repo" "refs/heads/$b" "$def")
        age=$(( (now - ${ts%% *}) / 86400 ))
        remote=tracked
        [ "$track" = "[gone]" ] && remote=gone
        [ -z "$up" ] && remote=none
        reason="pr:$pr remote:$remote merged:$merged"
        if [ "${pr%%#*}" = OPEN ]; then v=keep
        elif [ "${pr%%#*}" = MERGED ] || [ "$merged" != no ]; then v=safe
        elif [ "${pr%%#*}" = CLOSED ] || [ "$remote" = gone ] || older "$age"; then v=ask
        else v=keep; reason="recent, unmerged; $reason"
        fi
        row branch "$v" 0 "$age" "$reason" "$b" "$repo"
      done
  done
}

docker_section() {
  with_timeout 15 docker info >/dev/null 2>&1 || { row docker keep 0 - "daemon not responding, skipped" docker -; return; }
  local used
  used=$(docker ps -aq | xargs docker inspect -f '{{.Image}}' 2>/dev/null | sort -u)

  docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.State}}\t{{.Status}}' | while IFS=$'\t' read -r name image state status; do
    excluded "$name $image" && continue
    local age v
    age=$(ago_days "$status")
    case "$state" in
      running|restarting|paused) v=keep ;;
      *) if older "$age"; then v=safe; else v=ask; fi ;;
    esac
    row container "$v" 0 "$age" "$state, image $image" "$name" "$image"
  done

  docker images --no-trunc --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}' | while IFS=$'\t' read -r ref id size since; do
    excluded "$ref" && continue
    local age v reason target
    age=$(ago_days "$since")
    target=$ref
    if printf '%s\n' "$used" | grep -qx "$id"; then v=keep; reason="used by a container"
    elif [ "$ref" = "<none>:<none>" ]; then v=safe; reason="dangling"; target=$id
    elif older "$age"; then v=ask; reason="unused"
    else v=keep; reason="unused, recent"
    fi
    case "$ref" in *:\<none\>) target=$id ;; esac
    row image "$v" "$(human_kb "$size")" "$age" "$reason" "$target" "$id"
  done

  local df
  df=$(with_timeout 90 docker system df -v 2>/dev/null)
  docker volume ls -qf dangling=true | while read -r vol; do
    excluded "$vol" && continue
    local size
    size=$(printf '%s\n' "$df" | awk -v v="$vol" '$1 == v { print $3; exit }')
    row volume ask "$(human_kb "${size:-0B}")" - "dangling, holds data" "$vol" -
  done

  local cache
  cache=$(docker system df --format '{{.Type}}\t{{.Reclaimable}}' 2>/dev/null | awk -F'\t' '$1 == "Build Cache" { print $2 }')
  [ -n "$cache" ] && row builder safe "$(human_kb "${cache%% *}")" - "reclaimable build cache" docker-builder -
}

cache_section() {
  local entries name path verdict size reason
  entries="uv|$(uv cache dir 2>/dev/null)|safe
pnpm|$(pnpm store path 2>/dev/null)|safe
npm|$HOME/.npm/_cacache|safe
pip|$(pip3 cache dir 2>/dev/null)|safe
go|$(go env GOCACHE 2>/dev/null)|safe
brew|$(brew --cache 2>/dev/null)|safe
derived-data|$HOME/Library/Developer/Xcode/DerivedData|safe
playwright|$HOME/Library/Caches/ms-playwright|ask
playwright|$HOME/.cache/ms-playwright|ask
cocoapods|$HOME/Library/Caches/CocoaPods|ask
gradle|$HOME/.gradle/caches|ask"
  printf '%s\n' "$entries" | while IFS='|' read -r name path verdict; do
    [ -n "$path" ] && [ -d "$path" ] || continue
    size=$(sizekb "$path")
    [ "${size:-0}" -ge 102400 ] || continue
    if [ "$verdict" = safe ]; then reason="regenerates on next use"; else reason="regenerates, slow to rebuild"; fi
    row cache "$verdict" "$size" - "$reason" "$name" "$path"
  done
}

device_section() {
  if command -v xcrun >/dev/null 2>&1 && xcrun simctl help >/dev/null 2>&1; then
    xcrun simctl list devices --json 2>/dev/null | python3 -c '
import json, sys
for runtime, devices in json.load(sys.stdin).get("devices", {}).items():
    for d in devices:
        print("\t".join([d["udid"], d["name"], d.get("state", ""), str(d.get("isAvailable", True)), d.get("dataPath", "")]))
' | while IFS=$'\t' read -r udid name state available data; do
      local dir size age v
      dir=${data%/data}
      if [ "$available" = False ]; then row sim safe "$(sizekb "$dir")" - "runtime unavailable" "$udid" "$name"; continue; fi
      excluded "$name" && continue
      size=$(sizekb "$dir")
      [ "${size:-0}" -ge 204800 ] || continue
      age=$(agedays "$data")
      if [ "$state" = Booted ]; then v=keep
      elif older "$age"; then v=ask
      else v=keep
      fi
      row sim "$v" "$size" "$age" "iOS simulator, $state" "$udid" "$name"
    done
  fi

  for avd in "$HOME"/.android/avd/*.avd; do
    [ -d "$avd" ] || continue
    local name age v
    name=$(basename "$avd" .avd)
    excluded "$name" && continue
    age=$(agedays "$avd")
    if pgrep -f "avd $name" >/dev/null 2>&1; then v=keep
    elif older "$age"; then v=ask
    else v=keep
    fi
    row avd "$v" "$(sizekb "$avd")" "$age" "Android emulator" "$name" "$avd"
  done
}

git_section
docker_section
cache_section
device_section

awk -F'\t' 'BEGIN { OFS = "\t" } { print NR, $0 }' "$rows" > "$out"
rm -f "$rows"

awk -F'\t' -v out="$out" '
  function h(kb) { return kb >= 1048576 ? sprintf("%.1fG", kb / 1048576) : sprintf("%dM", kb / 1024) }
  {
    name = $7
    if ($2 == "branch") { n = split($8, parts, "/"); name = parts[n] ": " $7 }
    if ($2 == "sim") name = $8 " (" $7 ")"
    total[$3] += $4; count[$3]++
    line[$3] = line[$3] sprintf("  %4s  %-9s %7s  %5s  %s  [%s]\n", $1, $2, h($4), $5, name, $6)
  }
  END {
    printf "inventory: %s\n\n", out
    split("safe ask keep", order, " ")
    for (i = 1; i <= 3; i++) {
      v = order[i]
      printf "%s: %d rows, %s\n%s\n", toupper(v), count[v], h(total[v]), line[v]
    }
  }' "$out"
df -h "$HOME" | awk 'NR == 2 { print "free on disk: " $4 }'
