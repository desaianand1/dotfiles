#!/usr/bin/env bash
# Claude Code statusline — Catppuccin Macchiato, left/right powerline
set -euo pipefail
input=$(cat)

# ── JSON ─────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
fast=$(echo "$input" | jq -r '.fast_mode // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── Palette (Catppuccin Macchiato) ───────────────────────────
c_mantle="30;32;48"
c_surface0="54;58;79"

bg()  { printf "\033[48;2;%sm" "$1"; }
fg()  { printf "\033[38;2;%sm" "$1"; }
rst="\033[0m"

c_blue="138;173;244"
c_green="166;218;149"
c_mauve="198;160;246"
c_lavender="183;189;248"
c_peach="245;169;127"
c_red="237;135;150"
c_teal="139;213;202"
c_pink="245;189;230"
c_sky="145;215;227"
c_overlay="110;115;141"
c_sub="165;173;203"

sep_r=""
sep_l=""

cols=$(tput cols 2>/dev/null || echo 120)

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

# ── Segment arrays ───────────────────────────────────────────
L_bgs=(); L_texts=(); L_widths=()
R_bgs=(); R_texts=(); R_widths=()

add_left()  { L_bgs+=("$1"); L_texts+=("$2"); L_widths+=("$3"); }
add_right() { R_bgs+=("$1"); R_texts+=("$2"); R_widths+=("$3"); }

# ── LEFT: dir, git, context ─────────────────────────────────

# 1. Directory
short_cwd="${cwd/#$HOME/~}"
if [[ "$short_cwd" == */*/* ]]; then
  short_cwd="…/$(echo "$short_cwd" | rev | cut -d/ -f1-2 | rev)"
fi
add_left "$c_surface0" "$(fg "$c_blue")  ${short_cwd} " $(( ${#short_cwd} + 4 ))

# 2. Git
branch=""
git_info=""
git_vis=0
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
  git_vis=${#branch}

  if ! git -C "$cwd" diff --quiet HEAD 2>/dev/null; then
    git_info+=" ●"; git_vis=$((git_vis + 2))
  fi

  stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  if [ "$stash_count" -gt 0 ] 2>/dev/null; then
    git_info+="  ${stash_count}"; git_vis=$((git_vis + 3 + ${#stash_count}))
  fi

  upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$cwd" rev-list --count '@{upstream}..HEAD' 2>/dev/null)
    behind=$(git -C "$cwd" rev-list --count 'HEAD..@{upstream}' 2>/dev/null)
    if [ "$ahead" -gt 0 ] 2>/dev/null; then
      git_info+=" ↑${ahead}"; git_vis=$((git_vis + 2 + ${#ahead}))
    fi
    if [ "$behind" -gt 0 ] 2>/dev/null; then
      git_info+=" ↓${behind}"; git_vis=$((git_vis + 2 + ${#behind}))
    fi
  fi

  tag=$(git -C "$cwd" tag --points-at HEAD 2>/dev/null | head -1)
  if [ -n "$tag" ]; then
    git_info+=" 󰓹 ${tag}"; git_vis=$((git_vis + 4 + ${#tag}))
  fi

  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
  if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
    git_info+=" $(fg "$c_red")REBASING$(fg "$c_green")"; git_vis=$((git_vis + 9))
  elif [ -f "$git_dir/MERGE_HEAD" ]; then
    git_info+=" $(fg "$c_red")MERGING$(fg "$c_green")"; git_vis=$((git_vis + 8))
  elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
    git_info+=" $(fg "$c_red")CHERRY-PICK$(fg "$c_green")"; git_vis=$((git_vis + 12))
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
      git_info+="  ${time_ago}"; git_vis=$((git_vis + 3 + ${#time_ago}))
    fi
  fi
fi
[ -n "$git_worktree" ] && branch="$git_worktree" && git_vis=${#branch}

if [ -n "$branch" ]; then
  add_left "$c_mantle" "$(fg "$c_green")  ${branch}${git_info} " $((git_vis + 4))
fi

# 3. Context window (left side — always visible when > 0%)
# Measure against the compact window, not the model's full window, so the
# percentage reflects when a manual /compact is due.
compact_window="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}"
if [[ "$compact_window" =~ ^[0-9]+$ ]] && [ -n "$used_tokens" ]; then
  used_pct=$(echo "$used_tokens * 100 / $compact_window" | bc -l)
fi
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -gt 0 ]; then
    if [ "$used_int" -ge 80 ]; then ctx_c="$c_red"
    elif [ "$used_int" -ge 50 ]; then ctx_c="$c_peach"
    else ctx_c="$c_lavender"; fi

    ctx_label="${used_int}%"
    [ -n "$used_tokens" ] && ctx_label="$(fmt_tokens "$used_tokens") · ${used_int}%"

    add_left "$c_surface0" "$(fg "$ctx_c") 󰊠 ${ctx_label} " $((${#ctx_label} + 4))
  fi
fi

# ── RIGHT: model+effort, rate limits (contextual) ───────────

# 1. Model + Effort (always present — anchors right side)
if [ -n "$model" ]; then
  m_text="$(fg "$c_mauve") 󰧑 ${model}"
  m_vis=$((${#model} + 4))

  if [ -n "$effort" ]; then
    case "$effort" in
      low)    m_text+=" $(fg "$c_overlay")⚡low"; m_vis=$((m_vis + 4)) ;;
      medium) m_text+=" $(fg "$c_teal")⚡med"; m_vis=$((m_vis + 4)) ;;
      high)   m_text+=" $(fg "$c_mauve")⚡high"; m_vis=$((m_vis + 5)) ;;
      xhigh)  m_text+=" $(fg "$c_pink")⚡max"; m_vis=$((m_vis + 4)) ;;
      *)      m_text+=" $(fg "$c_sub")⚡${effort}"; m_vis=$((m_vis + 1 + ${#effort})) ;;
    esac
  fi

  if [ "$fast" = "true" ]; then
    m_text+=" $(fg "$c_sky")🚀"; m_vis=$((m_vis + 3))
  fi

  add_right "$c_surface0" "${m_text} " $((m_vis + 1))
fi

# 2. Rate limits (contextual — only when close to limits)
rl_worst=0; rl_label=""
for pair in "5h:${rl_5h:-0}" "7d:${rl_7d:-0}"; do
  period="${pair%%:*}"; pct="${pair#*:}"
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  if [ "$pct_int" -gt "$rl_worst" ]; then
    rl_worst="$pct_int"; rl_label="${period} ${pct_int}%"
  fi
done
if [ "$rl_worst" -ge 70 ]; then
  if [ "$rl_worst" -ge 95 ]; then rl_c="$c_red"; else rl_c="$c_peach"; fi
  add_right "$c_mantle" "$(fg "$rl_c") ⏱ ${rl_label} " $((${#rl_label} + 4))
fi

# ── RENDER LEFT ──────────────────────────────────────────────
left_out=""
left_total_w=0
prev_lbg=""
for i in "${!L_bgs[@]}"; do
  cur_bg="${L_bgs[$i]}"
  if [ -n "$prev_lbg" ]; then
    left_out+="$(bg "$cur_bg")$(fg "$prev_lbg")${sep_r}"
    left_total_w=$((left_total_w + 1))
  fi
  left_out+="$(bg "$cur_bg")${L_texts[$i]}"
  left_total_w=$((left_total_w + L_widths[$i]))
  prev_lbg="$cur_bg"
done
# End cap
if [ -n "$prev_lbg" ]; then
  left_out+="${rst}$(fg "$prev_lbg")${sep_r}${rst}"
  left_total_w=$((left_total_w + 1))
fi

# ── RENDER RIGHT ─────────────────────────────────────────────
right_out=""
right_total_w=0
if [ ${#R_bgs[@]} -gt 0 ]; then
  # Right segments flow right-to-left: each opens with sep_l
  # Connect adjacent right segments seamlessly
  for i in "${!R_bgs[@]}"; do
    cur_bg="${R_bgs[$i]}"
    if [ "$i" -eq 0 ]; then
      # First right segment: opens against terminal bg
      right_out+="$(fg "$cur_bg")${sep_l}$(bg "$cur_bg")${R_texts[$i]}"
    else
      # Subsequent: transition from previous segment
      right_out+="$(fg "$cur_bg")${sep_l}$(bg "$cur_bg")${R_texts[$i]}"
    fi
    right_total_w=$((right_total_w + 1 + R_widths[$i]))
  done
  right_out+="${rst}"
fi

# ── PAD & OUTPUT ─────────────────────────────────────────────
if [ "$right_total_w" -gt 0 ]; then
  pad=$((cols - left_total_w - right_total_w))
  [ "$pad" -lt 2 ] && pad=2
  padding=$(printf "%${pad}s" "")
  printf "%b" "${left_out}${padding}${right_out}"
else
  # No right segments — just output left, no trailing space
  printf "%b" "${left_out}"
fi
