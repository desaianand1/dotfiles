# Terminal Dashboard - Mission Control
# Prints a rich, informative dashboard on terminal open
# Uses Catppuccin Macchiato colors, Nerd Font icons, and Unicode charts

_dashboard() {
  # Skip in non-interactive or nested shells
  [[ -o interactive ]] || return
  [[ -z "$DASHBOARD_DISABLE" ]] || return

  # --- Catppuccin Macchiato palette (24-bit ANSI) ---
  local RST=$'\e[0m'
  local BOLD=$'\e[1m'
  local DIM=$'\e[2m'
  local RED=$'\e[38;2;237;135;150m'
  local GREEN=$'\e[38;2;166;218;149m'
  local YELLOW=$'\e[38;2;238;212;159m'
  local BLUE=$'\e[38;2;138;173;244m'
  local MAUVE=$'\e[38;2;198;160;246m'
  local TEAL=$'\e[38;2;139;213;202m'
  local PINK=$'\e[38;2;245;189;230m'
  local PEACH=$'\e[38;2;245;169;127m'
  local FG=$'\e[38;2;202;211;245m'
  local SUBTEXT=$'\e[38;2;165;173;203m'
  local SURFACE=$'\e[38;2;54;58;79m'

  local CACHE_DIR="${HOME}/.cache/dashboard"
  mkdir -p "$CACHE_DIR" 2>/dev/null

  # --- Helper: bar chart ---
  _bar() {
    local percent=$1 width=${2:-15} color=$3
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    printf "%s" "$color"
    for (( i=0; i<filled; i++ )); do printf "█"; done
    printf "%s" "$SURFACE"
    for (( i=0; i<empty; i++ )); do printf "░"; done
    printf "%s" "$RST"
  }

  # --- Helper: human-readable time ago ---
  _time_ago() {
    local seconds=$1
    if (( seconds < 60 )); then printf "just now"
    elif (( seconds < 3600 )); then printf "%dm ago" $(( seconds / 60 ))
    elif (( seconds < 86400 )); then printf "%dh ago" $(( seconds / 3600 ))
    elif (( seconds < 604800 )); then printf "%dd ago" $(( seconds / 86400 ))
    elif (( seconds < 2592000 )); then printf "%dw ago" $(( seconds / 604800 ))
    else printf "%dmo ago" $(( seconds / 2592000 ))
    fi
  }

  # --- Helper: section header ---
  _header() {
    local icon=$1 title=$2
    printf "\n %s%s %s%s%s\n" "$MAUVE" "$icon" "$BOLD" "$title" "$RST"
    printf " %s" "$SURFACE"
    printf '─%.0s' {1..50}
    printf "%s\n" "$RST"
  }

  # --- Collect data in parallel ---
  local tmpdir=$(mktemp -d)

  # System metrics
  {
    # CPU
    local cpu_name=$(sysctl -n machdep.cpu.brand_string 2>/dev/null | sed 's/Apple //')
    local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null)
    local cpu_pct=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s / NR}' 2>/dev/null)

    # Memory
    local mem_total=$(sysctl -n hw.memsize 2>/dev/null)
    local mem_total_gb=$(( mem_total / 1073741824 ))
    local page_size=$(sysctl -n hw.pagesize 2>/dev/null)
    local vm_stat_out=$(vm_stat 2>/dev/null)
    local pages_active=$(echo "$vm_stat_out" | awk '/Pages active/ {gsub(/\./,"",$3); print $3}')
    local pages_wired=$(echo "$vm_stat_out" | awk '/Pages wired/ {gsub(/\./,"",$4); print $4}')
    local pages_compressed=$(echo "$vm_stat_out" | awk '/Pages occupied by compressor/ {gsub(/\./,"",$5); print $5}')
    local mem_used_bytes=$(( (pages_active + pages_wired + pages_compressed) * page_size ))
    local mem_used_gb=$(( mem_used_bytes / 1073741824 ))
    local mem_pct=$(( mem_used_bytes * 100 / mem_total ))

    # Disk
    local disk_line=$(df -h / 2>/dev/null | tail -1)
    local disk_used=$(echo "$disk_line" | awk '{print $3}')
    local disk_total=$(echo "$disk_line" | awk '{print $2}')
    local disk_pct=$(echo "$disk_line" | awk '{gsub(/%/,"",$5); print $5}')

    # Battery
    local batt_pct="" batt_state="" batt_line=""
    if batt_line=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%; [a-z]*'); then
      batt_pct=$(echo "$batt_line" | grep -o '[0-9]*')
      batt_state=$(echo "$batt_line" | sed 's/.*; //')
    fi

    # Network
    local net_ip=$(ifconfig en0 2>/dev/null | awk '/inet / {print $2}')
    local wifi_name=$(networksetup -getairportnetwork en0 2>/dev/null | grep -v "not associated" | sed 's/Current Wi-Fi Network: //')
    [[ -z "$wifi_name" ]] && wifi_name=""

    # Output
    printf "  ${TEAL}  ${FG}%-6s ${RST}" "CPU"
    _bar "${cpu_pct:-0}" 15 "$TEAL"
    printf "  ${FG}%s (%s cores)${RST}\n" "$cpu_name" "$cpu_cores"

    printf "  ${GREEN}  ${FG}%-6s ${RST}" "MEM"
    _bar "$mem_pct" 15 "$GREEN"
    printf "  ${FG}%dG / %dG${RST} ${SUBTEXT}(%d%%)${RST}\n" "$mem_used_gb" "$mem_total_gb" "$mem_pct"

    printf "  ${YELLOW}󰋊  ${FG}%-6s ${RST}" "DISK"
    _bar "$disk_pct" 15 "$YELLOW"
    printf "  ${FG}%s / %s${RST} ${SUBTEXT}(%s%%)${RST}\n" "$disk_used" "$disk_total" "$disk_pct"

    if [[ -n "$batt_pct" ]]; then
      local batt_icon="󰁹"
      local batt_color="$GREEN"
      if (( batt_pct <= 20 )); then batt_icon="󰁻"; batt_color="$RED"
      elif (( batt_pct <= 50 )); then batt_icon="󰁾"; batt_color="$YELLOW"
      fi
      local charge_icon=""
      [[ "$batt_state" == "charging" ]] && charge_icon=" 󰚥"
      [[ "$batt_state" == "charged" ]] && charge_icon=" 󰚥"
      printf "  ${batt_color}%s  ${FG}%-6s ${RST}" "$batt_icon" "BAT"
      _bar "$batt_pct" 15 "$batt_color"
      printf "  ${FG}%d%%${RST}${GREEN}%s${RST} ${SUBTEXT}%s${RST}\n" "$batt_pct" "$charge_icon" "$batt_state"
    fi

    if [[ -n "$net_ip" ]]; then
      local net_label="${wifi_name:-ethernet}"
      printf "  ${BLUE}󰖩  ${FG}%-6s ${SUBTEXT}%s${RST}  ${DIM}%s${RST}\n" "NET" "$net_ip" "$net_label"
    else
      printf "  ${SURFACE}󰖪  ${SUBTEXT}%-6s disconnected${RST}\n" "NET"
    fi
  } > "$tmpdir/system" 2>/dev/null &

  # Recent Projects
  {
    local projects_dir="$HOME/Developer/Projects"
    if [[ -d "$projects_dir" ]]; then
      local entries=()
      for dir in "$projects_dir"/*/; do
        [[ -d "$dir" ]] || continue
        local mtime=$(stat -f "%m" "$dir" 2>/dev/null)
        entries+=("$mtime $dir")
      done

      local now=$(date +%s)
      local idx=0
      printf "%s\n" "${entries[@]}" | sort -rn | head -5 | while IFS= read -r line; do
        local mtime=${line%% *}
        local dir=${line#* }
        local name=$(basename "$dir")
        idx=$((idx + 1))

        # Git status
        local git_icon="${SURFACE}○${RST}"
        local last_commit=""
        if [[ -d "${dir}.git" ]]; then
          if [[ -z $(git -C "$dir" status --porcelain 2>/dev/null | head -1) ]]; then
            git_icon="${GREEN} ${RST}"
          else
            git_icon="${YELLOW} ${RST}"
          fi
          last_commit=$(git -C "$dir" log -1 --format="%cr" 2>/dev/null)
        fi

        # Language detection
        local lang_icon="${SUBTEXT} ${RST}"
        if [[ -f "${dir}pubspec.yaml" ]]; then lang_icon="${BLUE} ${RST}"
        elif [[ -f "${dir}go.mod" ]]; then lang_icon="${TEAL} ${RST}"
        elif [[ -f "${dir}Cargo.toml" ]]; then lang_icon="${PEACH} ${RST}"
        elif [[ -f "${dir}pyproject.toml" || -f "${dir}requirements.txt" || -f "${dir}setup.py" ]]; then lang_icon="${YELLOW}󰌠 ${RST}"
        elif [[ -f "${dir}Gemfile" ]]; then lang_icon="${RED} ${RST}"
        elif [[ -f "${dir}build.gradle" || -f "${dir}build.gradle.kts" ]]; then lang_icon="${PEACH} ${RST}"
        elif [[ -f "${dir}package.json" ]]; then lang_icon="${GREEN} ${RST}"
        fi

        printf "  ${MAUVE}%d${RST} %s %s %-25s ${SUBTEXT}%s${RST}\n" \
          "$idx" "$lang_icon" "$git_icon" "$name" "${last_commit:-"no git"}"
      done
    else
      printf "  ${SUBTEXT}No projects directory found${RST}\n"
    fi
  } > "$tmpdir/projects" 2>/dev/null &

  # Docker status
  {
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
      local running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
      local stopped=$(docker ps -aq --filter "status=exited" 2>/dev/null | wc -l | tr -d ' ')

      printf "  ${GREEN} %s running${RST}  ${RED} %s stopped${RST}\n" "$running" "$stopped"

      docker ps --format '{{.Names}}' 2>/dev/null | head -4 | while read -r name; do
        printf "    ${GREEN}●${RST} ${FG}%s${RST}\n" "$name"
      done
      local extra=$((running - 4))
      (( extra > 0 )) && printf "    ${SUBTEXT}...and %d more${RST}\n" "$extra"
    else
      printf "  ${SUBTEXT}󰡨 Docker not running${RST}\n"
    fi
  } > "$tmpdir/docker" 2>/dev/null &

  # Git Heatmap (GitHub-style, past 4 weeks)
  {
    local projects_dir="$HOME/Developer/Projects"
    local cache_file="$CACHE_DIR/heatmap.cache"
    local cache_max_age=3600

    # Check cache
    local use_cache=0
    if [[ -f "$cache_file" ]]; then
      local cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null) ))
      (( cache_age < cache_max_age )) && use_cache=1
    fi

    if (( use_cache )); then
      cat "$cache_file"
    else
      # Collect all commit dates
      typeset -A day_counts
      for dir in "$projects_dir"/*/; do
        [[ -d "${dir}.git" ]] || continue
        while IFS= read -r date; do
          [[ -n "$date" ]] && day_counts[$date]=$(( ${day_counts[$date]:-0} + 1 ))
        done < <(git -C "$dir" log --all --since="4 weeks ago" --format="%ad" --date=format:"%Y-%m-%d" 2>/dev/null)
      done

      local today=$(date +%Y-%m-%d)
      local dow=$(date +%u) # 1=Mon, 7=Sun
      local start_offset=$(( (dow - 1) + 21 ))

      # Build heatmap: 7 rows (Mon-Sun) x 4 columns (weeks)
      local day_labels=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
      local output=""
      for row in 0 1 2 3 4 5 6; do
        output+="  ${SUBTEXT}${day_labels[$((row+1))]}${RST} "
        for col in 0 1 2 3; do
          local offset=$(( col * 7 + row ))
          local days_back=$(( start_offset - offset ))
          local check_date=$(date -v-${days_back}d +%Y-%m-%d 2>/dev/null)

          # Skip future dates
          if [[ "$check_date" > "$today" ]]; then
            output+="  "
            continue
          fi

          local count=${day_counts[$check_date]:-0}
          local color="$SURFACE"
          if (( count >= 10 )); then color="$MAUVE"
          elif (( count >= 6 )); then color="$GREEN"
          elif (( count >= 3 )); then color="$TEAL"
          elif (( count >= 1 )); then color="$BLUE"
          fi
          output+="${color}██${RST}"
        done
        output+="\n"
      done

      # Legend
      output+="       ${SUBTEXT}less${RST} ${SURFACE}██${RST}${BLUE}██${RST}${TEAL}██${RST}${GREEN}██${RST}${MAUVE}██${RST} ${SUBTEXT}more${RST}\n"

      printf "%b" "$output" | tee "$cache_file"
    fi
  } > "$tmpdir/heatmap" 2>/dev/null &

  # Recent Docs
  {
    local docs_dir="$HOME/Documents"
    if [[ -d "$docs_dir" ]]; then
      local now=$(date +%s)
      find "$docs_dir" -maxdepth 3 -type f \
        \( -name "*.md" -o -name "*.pdf" -o -name "*.txt" -o -name "*.docx" \) \
        -not -path "*/.obsidian/*" \
        -not -path "*/.*" \
        -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -5 | while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        local mtime=${line%% *}
        local filepath=${line#* }
        local filename=$(basename "$filepath")
        local ext="${filename##*.}"

        local icon="${SUBTEXT} ${RST}"
        case "$ext" in
          md)   icon="${BLUE} ${RST}" ;;
          pdf)  icon="${RED} ${RST}" ;;
          txt)  icon="${FG} ${RST}" ;;
          docx) icon="${BLUE}󰈬 ${RST}" ;;
        esac

        local age=$(( now - mtime ))
        local age_str=$(_time_ago $age)

        # Truncate long filenames
        local display="${filename}"
        (( ${#display} > 38 )) && display="${display:0:35}..."

        printf "  %s %-38s ${SUBTEXT}%s${RST}\n" "$icon" "$display" "$age_str"
      done
    fi
  } > "$tmpdir/docs" 2>/dev/null &

  # Tip of the Day
  {
    local tips_file="$HOME/.config/zsh/tips/tips.json"
    if [[ -f "$tips_file" ]] && command -v jq &>/dev/null; then
      local count=$(jq 'length' "$tips_file" 2>/dev/null)
      if (( count > 0 )); then
        local idx=$(( RANDOM % count ))
        local category=$(jq -r ".[$idx].category" "$tips_file")
        local title=$(jq -r ".[$idx].title" "$tips_file")
        local cmd=$(jq -r ".[$idx].command" "$tips_file")
        local explanation=$(jq -r ".[$idx].explanation" "$tips_file")

        local cat_icon=""
        case "$category" in
          unix)   cat_icon="  " ;;
          vim)    cat_icon="  " ;;
          zsh)    cat_icon="  " ;;
          fzf)    cat_icon="  " ;;
          git)    cat_icon="  " ;;
          tools)  cat_icon="  " ;;
          zellij) cat_icon="  " ;;
        esac

        printf "  ${PEACH}%s${RST}${MAUVE}%s${RST}  ${BOLD}${YELLOW}%s${RST}\n" "$cat_icon" "$category" "$title"
        printf "  ${GREEN}%s${RST}\n" "$cmd"
        printf "  ${SUBTEXT}%s${RST}\n" "$explanation"
      fi
    else
      printf "  ${SUBTEXT}Tips not configured (install jq and create tips.json)${RST}\n"
    fi
  } > "$tmpdir/tip" 2>/dev/null &

  # Wait for all parallel jobs
  wait

  # --- Render ---
  printf "\n"

  _header "" "SYSTEM"
  cat "$tmpdir/system"

  _header "" "PROJECTS"
  cat "$tmpdir/projects"

  _header "󰡨" "DOCKER"
  cat "$tmpdir/docker"

  _header "" "GIT ACTIVITY"
  cat "$tmpdir/heatmap"

  _header "" "RECENT DOCS"
  cat "$tmpdir/docs"

  _header "󰛨" "TIP OF THE DAY"
  cat "$tmpdir/tip"

  printf "\n"

  # Cleanup
  rm -rf "$tmpdir" 2>/dev/null
}

# Run dashboard
_dashboard
