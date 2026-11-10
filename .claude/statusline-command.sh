#!/usr/bin/env bash
# Claude Code statusline — Catppuccin Macchiato powerline
# Companion config: ~/.claude/claude-powerline.json

set -euo pipefail
input=$(cat)

# ── JSON fields ──────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
fast=$(echo "$input" | jq -r '.fast_mode // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Catppuccin Macchiato palette (true color) ────────────────
base="\033[48;2;36;39;58m"       # #24273a
mantle="\033[48;2;30;32;48m"     # #1e2030
surface0="\033[48;2;54;58;79m"   # #363a4f

txt="\033[38;2;202;211;245m"     # #cad3f5
sub="\033[38;2;165;173;203m"     # #a5adcb
overlay="\033[38;2;110;115;141m" # #6e738d

blue="\033[38;2;138;173;244m"    # #8aadf4
green="\033[38;2;166;218;149m"   # #a6da95
mauve="\033[38;2;198;160;246m"   # #c6a0f6
lavender="\033[38;2;183;189;248m" # #b7bdf8
yellow="\033[38;2;238;212;159m"  # #eed49f
peach="\033[38;2;245;169;127m"   # #f5a97f
red="\033[38;2;237;135;150m"     # #ed8796
teal="\033[38;2;139;213;202m"    # #8bd5ca
pink="\033[38;2;245;189;230m"    # #f5bde6
sky="\033[38;2;145;215;227m"     # #91d7e3

base_f="\033[38;2;36;39;58m"
mantle_f="\033[38;2;30;32;48m"
surface0_f="\033[38;2;54;58;79m"

rst="\033[0m"
sep=""

# ── Helpers ──────────────────────────────────────────────────
fmt_tokens() {
  local t=$1
  if [ "$t" -ge 1000000 ] 2>/dev/null; then
    printf "%.1fM" "$(echo "$t / 1000000" | bc -l)"
  elif [ "$t" -ge 1000 ] 2>/dev/null; then
    printf "%.0fK" "$(echo "$t / 1000" | bc -l)"
  else
    printf "%s" "$t"
  fi
}

fmt_cost() {
  local c=$1
  if echo "$c" | grep -qE '^[0-9]+\.?[0-9]*$' 2>/dev/null; then
    printf "%.2f" "$c"
  else
    printf "%s" "$c"
  fi
}

transition() {
  local from=$1 to=$2
  local from_f to_bg
  case "$from" in
    surface0) from_f="$surface0_f" ;;
    mantle)   from_f="$mantle_f" ;;
    *)        from_f="$base_f" ;;
  esac
  case "$to" in
    surface0) to_bg="$surface0" ;;
    mantle)   to_bg="$mantle" ;;
    *)        to_bg="$base" ;;
  esac
  printf "%b" "${to_bg}${from_f}${sep}${rst}"
}

# ── Directory ────────────────────────────────────────────────
short_cwd="${cwd/#$HOME/~}"
if [[ "$short_cwd" == */*/* ]]; then
  short_cwd="…/$(echo "$short_cwd" | rev | cut -d/ -f1-2 | rev)"
fi

out="${surface0}${blue}  ${short_cwd} ${rst}"
prev_bg="surface0"

# ── Git ──────────────────────────────────────────────────────
branch=""
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)

  if ! git -C "$cwd" diff --quiet HEAD 2>/dev/null; then
    git_info+=" ●"
  fi

  stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  [ "$stash_count" -gt 0 ] 2>/dev/null && git_info+="  ${stash_count}"

  upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$cwd" rev-list --count '@{upstream}..HEAD' 2>/dev/null)
    behind=$(git -C "$cwd" rev-list --count 'HEAD..@{upstream}' 2>/dev/null)
    [ "$ahead" -gt 0 ] 2>/dev/null && git_info+=" ↑${ahead}"
    [ "$behind" -gt 0 ] 2>/dev/null && git_info+=" ↓${behind}"
  fi

  tag=$(git -C "$cwd" tag --points-at HEAD 2>/dev/null | head -1)
  [ -n "$tag" ] && git_info+=" 󰓹 ${tag}"

  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
  if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
    git_info+=" ${red}REBASING${green}"
  elif [ -f "$git_dir/MERGE_HEAD" ]; then
    git_info+=" ${red}MERGING${green}"
  elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
    git_info+=" ${red}CHERRY-PICK${green}"
  fi

  last_epoch=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null)
  if [ -n "$last_epoch" ]; then
    now=$(date +%s)
    diff_sec=$((now - last_epoch))
    if [ "$diff_sec" -ge 60 ]; then
      if [ "$diff_sec" -lt 3600 ]; then
        time_ago="$((diff_sec / 60))m"
      elif [ "$diff_sec" -lt 86400 ]; then
        time_ago="$((diff_sec / 3600))h"
      else
        time_ago="$((diff_sec / 86400))d"
      fi
      git_info+="  ${time_ago}"
    fi
  fi
fi
[ -n "$git_worktree" ] && branch="$git_worktree"

if [ -n "$branch" ]; then
  out+="$(transition "$prev_bg" mantle)"
  out+="${mantle}${green}  ${branch}${git_info} ${rst}"
  prev_bg="mantle"
fi

# ── Model + Effort ───────────────────────────────────────────
if [ -n "$model" ]; then
  out+="$(transition "$prev_bg" surface0)"

  effort_str=""
  if [ -n "$effort" ]; then
    case "$effort" in
      low)    effort_str=" ${overlay}⚡low" ;;
      medium) effort_str=" ${teal}⚡med" ;;
      high)   effort_str=" ${mauve}⚡high" ;;
      xhigh)  effort_str=" ${pink}⚡max" ;;
      *)      effort_str=" ${sub}⚡${effort}" ;;
    esac
  fi

  fast_str=""
  if [ "$fast" = "true" ]; then
    fast_str=" ${sky}🚀"
  fi

  out+="${surface0}${mauve}󰧑 ${model}${effort_str}${fast_str} ${rst}"
  prev_bg="surface0"
fi

# ── Context window ───────────────────────────────────────────
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")

  if [ "$used_int" -gt 0 ]; then
    out+="$(transition "$prev_bg" mantle)"

    if [ "$used_int" -ge 80 ]; then
      c_fg="$red"
    elif [ "$used_int" -ge 50 ]; then
      c_fg="$peach"
    else
      c_fg="$lavender"
    fi

    ctx_label="${used_int}%"
    if [ -n "$used_tokens" ]; then
      ctx_label="$(fmt_tokens "$used_tokens") · ${used_int}%"
    fi

    out+="${mantle}${c_fg}󰊠 ${ctx_label} ${rst}"
    prev_bg="mantle"
  fi
fi

# ── Session cost (only on API billing, not subscription) ─────
is_subscription="false"
[ -n "$rl_5h" ] || [ -n "$rl_7d" ] && is_subscription="true"

if [ "$is_subscription" = "false" ] && [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
  out+="$(transition "$prev_bg" surface0)"
  out+="${surface0}${yellow} \$$(fmt_cost "$cost") ${rst}"
  prev_bg="surface0"
fi

# ── Rate limits (contextual: only when ≥70%) ─────────────────
rl_show=""
rl_worst=0
rl_label=""

for pair in "5h:${rl_5h:-0}" "7d:${rl_7d:-0}"; do
  period="${pair%%:*}"
  pct="${pair#*:}"
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  if [ "$pct_int" -gt "$rl_worst" ]; then
    rl_worst="$pct_int"
    rl_label="${period} ${pct_int}%"
  fi
done

if [ "$rl_worst" -ge 70 ]; then
  out+="$(transition "$prev_bg" mantle)"

  if [ "$rl_worst" -ge 95 ]; then
    rl_fg="$red"
    rl_icon="󰀦"
  else
    rl_fg="$peach"
    rl_icon="⏱"
  fi

  out+="${mantle}${rl_fg}${rl_icon} ${rl_label} ${rst}"
  prev_bg="mantle"
fi

# ── Final cap ────────────────────────────────────────────────
case "$prev_bg" in
  surface0) out+="${surface0_f}${sep}${rst}" ;;
  mantle)   out+="${mantle_f}${sep}${rst}" ;;
  *)        out+="${base_f}${sep}${rst}" ;;
esac

printf "%b" "$out"
