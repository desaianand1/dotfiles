#!/usr/bin/env bash
# Claude Code statusline — Catppuccin Macchiato, left/right powerline
# Companion config: ~/.claude/claude-powerline.json

set -euo pipefail
input=$(cat)

# ── JSON fields ──────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
fast=$(echo "$input" | jq -r '.fast_mode // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Catppuccin Macchiato ─────────────────────────────────────
base="\033[48;2;36;39;58m"
mantle="\033[48;2;30;32;48m"
surface0="\033[48;2;54;58;79m"

overlay="\033[38;2;110;115;141m"
sub="\033[38;2;165;173;203m"

blue="\033[38;2;138;173;244m"
green="\033[38;2;166;218;149m"
mauve="\033[38;2;198;160;246m"
lavender="\033[38;2;183;189;248m"
yellow="\033[38;2;238;212;159m"
peach="\033[38;2;245;169;127m"
red="\033[38;2;237;135;150m"
teal="\033[38;2;139;213;202m"
pink="\033[38;2;245;189;230m"
sky="\033[38;2;145;215;227m"

base_f="\033[38;2;36;39;58m"
mantle_f="\033[38;2;30;32;48m"
surface0_f="\033[38;2;54;58;79m"

rst="\033[0m"

# Powerline glyphs
rsep=""    # left-to-right separator
lsep=""    # right-to-left opener
rcap=""    # rounded right cap (end of left side)
lcap=""    # rounded left cap (start of right side)

cols=$(tput cols 2>/dev/null || echo 120)

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

strip_ansi() {
  printf "%s" "$1" | sed $'s/\033\\[[0-9;]*m//g'
}

visible_len() {
  local stripped
  stripped=$(strip_ansi "$1")
  printf "%s" "$stripped" | wc -m | tr -d ' '
}

transition_lr() {
  local from=$1 to=$2
  local from_f to_bg
  case "$from" in
    surface0) from_f="$surface0_f" ;; mantle) from_f="$mantle_f" ;; *) from_f="$base_f" ;;
  esac
  case "$to" in
    surface0) to_bg="$surface0" ;; mantle) to_bg="$mantle" ;; *) to_bg="$base" ;;
  esac
  printf "%b" "${to_bg}${from_f}${rsep}${rst}"
}

# ── LEFT SIDE ────────────────────────────────────────────────

# Directory
short_cwd="${cwd/#$HOME/~}"
if [[ "$short_cwd" == */*/* ]]; then
  short_cwd="…/$(echo "$short_cwd" | rev | cut -d/ -f1-2 | rev)"
fi

left="${surface0}${blue}  ${short_cwd} ${rst}"
prev_bg="surface0"

# Git
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
  left+="$(transition_lr "$prev_bg" mantle)"
  left+="${mantle}${green}  ${branch}${git_info} ${rst}"
  prev_bg="mantle"
fi

# Model + Effort + Fast
if [ -n "$model" ]; then
  left+="$(transition_lr "$prev_bg" surface0)"

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
  [ "$fast" = "true" ] && fast_str=" ${sky}🚀"

  left+="${surface0}${mauve} 󰧑 ${model}${effort_str}${fast_str} ${rst}"
  prev_bg="surface0"
fi

# Left cap (rounded end)
case "$prev_bg" in
  surface0) left+="${surface0_f}${rcap}${rst}" ;;
  mantle)   left+="${mantle_f}${rcap}${rst}" ;;
  *)        left+="${base_f}${rcap}${rst}" ;;
esac

# ── RIGHT SIDE ───────────────────────────────────────────────
right=""

# Context window
ctx_seg=""
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -gt 0 ]; then
    if [ "$used_int" -ge 80 ]; then
      c_fg="$red"
    elif [ "$used_int" -ge 50 ]; then
      c_fg="$peach"
    else
      c_fg="$lavender"
    fi

    ctx_label="${used_int}%"
    [ -n "$used_tokens" ] && ctx_label="$(fmt_tokens "$used_tokens") · ${used_int}%"

    ctx_seg="${surface0_f}${lcap}${rst}${surface0}${c_fg} 󰊠 ${ctx_label} ${rst}"
  fi
fi

# Rate limits (contextual: ≥70% warning, ≥95% critical)
rl_seg=""
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
  if [ "$rl_worst" -ge 95 ]; then
    rl_fg="$red"; rl_icon="󰀦"
  else
    rl_fg="$peach"; rl_icon="⏱"
  fi
  if [ -n "$ctx_seg" ]; then
    rl_seg="${mantle_f}${lcap}${rst}${mantle}${rl_fg} ${rl_icon} ${rl_label} ${rst}${surface0}${mantle_f}${rsep}${rst}"
  else
    rl_seg="${mantle_f}${lcap}${rst}${mantle}${rl_fg} ${rl_icon} ${rl_label} ${rst}"
  fi
fi

# Assemble right: rate limit (if any) then context
if [ -n "$rl_seg" ] && [ -n "$ctx_seg" ]; then
  right="${rl_seg}${ctx_seg}"
elif [ -n "$ctx_seg" ]; then
  right="${ctx_seg}"
elif [ -n "$rl_seg" ]; then
  right="${rl_seg}"
fi

# ── PAD & OUTPUT ─────────────────────────────────────────────
left_len=$(visible_len "$left")
right_len=$(visible_len "$right")
pad=$((cols - left_len - right_len))
[ "$pad" -lt 1 ] && pad=1

padding=$(printf "%${pad}s" "")

printf "%b" "${left}${padding}${right}"
