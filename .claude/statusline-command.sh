#!/usr/bin/env bash
# Claude Code statusline — Catppuccin Macchiato powerline
# Companion config: ~/.claude/claude-powerline.json

set -euo pipefail
input=$(cat)

# ── JSON fields ──────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.used_tokens // empty')
effort=$(echo "$input" | jq -r '.effort // .model.effort // empty')
cost=$(echo "$input" | jq -r '.cost.total_usd // .session_cost_usd // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

# ── Catppuccin Macchiato palette (true color) ────────────────
# Backgrounds
base="\033[48;2;36;39;58m"       # #24273a
mantle="\033[48;2;30;32;48m"     # #1e2030
surface0="\033[48;2;54;58;79m"   # #363a4f

# Foregrounds
txt="\033[38;2;202;211;245m"     # #cad3f5
sub="\033[38;2;165;173;203m"     # #a5adcb
overlay="\033[38;2;110;115;141m" # #6e738d

# Accents (fg)
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

# Transition fg (bg colors as fg for separators)
base_f="\033[38;2;36;39;58m"
mantle_f="\033[38;2;30;32;48m"
surface0_f="\033[38;2;54;58;79m"

rst="\033[0m"
sep=""

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
  out+="${mantle}${surface0_f}${sep}${rst}"
  out+="${mantle}${green}  ${branch}${git_info} ${rst}"
  prev_bg="mantle"
fi

# ── Model + Effort ───────────────────────────────────────────
if [ -n "$model" ]; then
  if [ "$prev_bg" = "mantle" ]; then
    out+="${surface0}${mantle_f}${sep}${rst}"
  else
    out+="${surface0}${surface0_f}${sep}${rst}"
  fi

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

  out+="${surface0}${mauve}󰧑 ${model}${effort_str} ${rst}"
  prev_bg="surface0"
fi

# ── Context window ───────────────────────────────────────────
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

if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")

  if [ "$used_int" -gt 0 ]; then
    if [ "$prev_bg" = "surface0" ]; then
      out+="${mantle}${surface0_f}${sep}${rst}"
    else
      out+="${mantle}${mantle_f}${sep}${rst}"
    fi

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

# ── Session cost ─────────────────────────────────────────────
if [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
  if [ "$prev_bg" = "mantle" ]; then
    out+="${surface0}${mantle_f}${sep}${rst}"
  else
    out+="${surface0}${surface0_f}${sep}${rst}"
  fi

  out+="${surface0}${yellow} \$${cost} ${rst}"
  prev_bg="surface0"
fi

# ── Final cap ────────────────────────────────────────────────
if [ "$prev_bg" = "surface0" ]; then
  out+="${surface0_f}${sep}${rst}"
elif [ "$prev_bg" = "mantle" ]; then
  out+="${mantle_f}${sep}${rst}"
else
  out+="${base_f}${sep}${rst}"
fi

printf "%b" "$out"
