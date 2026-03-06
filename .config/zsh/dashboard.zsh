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

  # --- Terminal capabilities ---
  local term_width=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
  local bar_width=15
  (( term_width < 100 )) && bar_width=10

  # Nerd Font detection (kitty, wezterm, iTerm, and most modern terminals support them)
  local NF=1
  if [[ -z "$KITTY_WINDOW_ID" && "$TERM_PROGRAM" != "kitty" && \
        "$TERM_PROGRAM" != "WezTerm" && "$TERM_PROGRAM" != "iTerm.app" && \
        "$TERM_PROGRAM" != "vscode" ]]; then
    # Conservative: assume no nerd fonts in unknown terminals
    [[ "$TERM" == "xterm-256color" || "$TERM" == "screen-256color" ]] && NF=0
  fi

  # Icon sets (nerd font vs ASCII fallback)
  local IC_CPU="" IC_MEM="" IC_DISK="󰋊" IC_BAT="󰁹" IC_NET="󰖩" IC_TS="󰒒"
  local IC_HOST="" IC_NO_NET="󰖪" IC_BATOK="󰁹" IC_BATLOW="󰁻" IC_BATMID="󰁾"
  local IC_CHARGE="󰚥" IC_CHARGED="󰄬" IC_DOCKER="󰡨" IC_GIT="" IC_TIP="󰛨"
  local IC_PROJ="" IC_DOCS="" IC_CLEAN="" IC_DIRTY="" IC_NO_GIT="○"
  if (( ! NF )); then
    IC_CPU=">" IC_MEM="~" IC_DISK="#" IC_BAT="B" IC_NET="W" IC_TS="T"
    IC_HOST="@" IC_NO_NET="X" IC_BATOK="B" IC_BATLOW="!" IC_BATMID="B"
    IC_CHARGE="+" IC_CHARGED="*" IC_DOCKER="D" IC_GIT="G" IC_TIP="?"
    IC_PROJ="P" IC_DOCS="D" IC_CLEAN="o" IC_DIRTY="x" IC_NO_GIT="-"
  fi

  # --- Helper: bar chart ---
  _bar() {
    local percent=$1 width=${2:-$bar_width} color=$3
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
    local divider_width=50
    (( term_width < 100 )) && divider_width=35
    printf "\n %s%s %s%s%s\n" "$MAUVE" "$icon" "$BOLD" "$title" "$RST"
    printf " %s" "$SURFACE"
    printf '─%.0s' $(seq 1 $divider_width)
    printf "%s\n" "$RST"
  }

  # --- Collect data in parallel ---
  local tmpdir=$(mktemp -d)

  # System metrics
  {
    # Host info
    local hostname=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
    local macos_ver=$(sw_vers -productVersion 2>/dev/null)
    local uptime_str=$(uptime | sed 's/.*up //' | sed 's/,.*//' | xargs)
    printf "  ${MAUVE}%s  ${FG}%s${RST}  ${SUBTEXT}macOS %s${RST}  ${DIM}up %s${RST}\n" \
      "$IC_HOST" "$hostname" "$macos_ver" "$uptime_str"

    # CPU
    local cpu_name=$(sysctl -n machdep.cpu.brand_string 2>/dev/null | sed 's/Apple //')
    local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null)
    local cpu_pct=$(ps -A -o %cpu | awk -v cores="${cpu_cores:-1}" \
      'NR>1 {s+=$1} END {pct=s/cores; printf "%.0f", (pct>100 ? 100 : pct)}' 2>/dev/null)

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

    # Tailscale
    local ts_ip="" ts_name=""
    if command -v tailscale &>/dev/null; then
      local ts_json=$(tailscale status --self --json 2>/dev/null)
      if [[ -n "$ts_json" ]]; then
        local ts_online=$(echo "$ts_json" | jq -r '.BackendState' 2>/dev/null)
        if [[ "$ts_online" == "Running" ]]; then
          ts_ip=$(echo "$ts_json" | jq -r '.Self.TailscaleIPs[0]' 2>/dev/null)
          ts_name=$(echo "$ts_json" | jq -r '.Self.DNSName' 2>/dev/null | sed 's/\.$//')
        fi
      fi
    fi

    # Output
    printf "  ${TEAL}%s  ${FG}%-6s ${RST}" "$IC_CPU" "CPU"
    _bar "${cpu_pct:-0}" "$bar_width" "$TEAL"
    printf "  ${FG}%s (%s cores)${RST}\n" "$cpu_name" "$cpu_cores"

    printf "  ${GREEN}%s  ${FG}%-6s ${RST}" "$IC_MEM" "MEM"
    _bar "$mem_pct" "$bar_width" "$GREEN"
    printf "  ${FG}%dG / %dG${RST} ${SUBTEXT}(%d%%)${RST}\n" "$mem_used_gb" "$mem_total_gb" "$mem_pct"

    printf "  ${YELLOW}%s  ${FG}%-6s ${RST}" "$IC_DISK" "DISK"
    _bar "$disk_pct" "$bar_width" "$YELLOW"
    printf "  ${FG}%s / %s${RST} ${SUBTEXT}(%s%%)${RST}\n" "$disk_used" "$disk_total" "$disk_pct"

    if [[ -n "$batt_pct" ]]; then
      local batt_icon="$IC_BATOK"
      local batt_color="$GREEN"
      if (( batt_pct <= 20 )); then batt_icon="$IC_BATLOW"; batt_color="$RED"
      elif (( batt_pct <= 50 )); then batt_icon="$IC_BATMID"; batt_color="$YELLOW"
      fi
      local charge_icon=""
      [[ "$batt_state" == "charging" ]] && charge_icon=" $IC_CHARGE"
      [[ "$batt_state" == "charged" ]] && charge_icon=" $IC_CHARGED"
      printf "  ${batt_color}%s  ${FG}%-6s ${RST}" "$batt_icon" "BAT"
      _bar "$batt_pct" "$bar_width" "$batt_color"
      printf "  ${FG}%d%%${RST}${GREEN}%s${RST} ${SUBTEXT}%s${RST}\n" "$batt_pct" "$charge_icon" "$batt_state"
    fi

    if [[ -n "$net_ip" ]]; then
      local net_label="${wifi_name:-ethernet}"
      printf "  ${BLUE}%s  ${FG}%-6s ${SUBTEXT}%s${RST}  ${DIM}%s${RST}\n" "$IC_NET" "NET" "$net_ip" "$net_label"
    else
      printf "  ${SURFACE}%s  ${SUBTEXT}%-6s disconnected${RST}\n" "$IC_NO_NET" "NET"
    fi

    if [[ -n "$ts_ip" ]]; then
      printf "  ${TEAL}%s  ${FG}%-6s ${SUBTEXT}%s${RST}  ${DIM}%s${RST}\n" "$IC_TS" "TS" "$ts_ip" "$ts_name"
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
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        local mtime=${line%% *}
        local dir=${line#* }
        local name=$(basename "$dir")
        idx=$((idx + 1))

        # Git status
        local git_icon="${SURFACE}${IC_NO_GIT}${RST}"
        local last_commit=""
        if [[ -d "${dir}.git" ]]; then
          if [[ -z $(git -C "$dir" status --porcelain 2>/dev/null | head -1) ]]; then
            git_icon="${GREEN}${IC_CLEAN} ${RST}"
          else
            git_icon="${YELLOW}${IC_DIRTY} ${RST}"
          fi
          last_commit=$(git -C "$dir" log -1 --format="%cr" 2>/dev/null)
        fi

        # Language detection
        local lang_icon="${SUBTEXT} ${RST}"
        if (( NF )); then
          if [[ -f "${dir}pubspec.yaml" ]]; then lang_icon="${BLUE} ${RST}"
          elif [[ -f "${dir}go.mod" ]]; then lang_icon="${TEAL} ${RST}"
          elif [[ -f "${dir}Cargo.toml" ]]; then lang_icon="${PEACH} ${RST}"
          elif [[ -f "${dir}pyproject.toml" || -f "${dir}requirements.txt" || -f "${dir}setup.py" ]]; then lang_icon="${YELLOW}󰌠 ${RST}"
          elif [[ -f "${dir}Gemfile" ]]; then lang_icon="${RED} ${RST}"
          elif [[ -f "${dir}build.gradle" || -f "${dir}build.gradle.kts" ]]; then lang_icon="${PEACH} ${RST}"
          elif [[ -f "${dir}package.json" ]]; then lang_icon="${GREEN} ${RST}"
          fi
        fi

        printf "  ${MAUVE}%d${RST} %s %s %-25s ${SUBTEXT}%s${RST}\n" \
          "$idx" "$lang_icon" "$git_icon" "$name" "${last_commit:-"no git"}"
      done < <(printf "%s\n" "${entries[@]}" | sort -rn | head -5)
    else
      printf "  ${SUBTEXT}No projects directory found${RST}\n"
    fi
  } > "$tmpdir/projects" 2>/dev/null &

  # Docker status
  {
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
      local running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
      local stopped=$(docker ps -aq --filter "status=exited" 2>/dev/null | wc -l | tr -d ' ')

      printf "  ${GREEN}${IC_CLEAN} %s running${RST}  ${RED}${IC_DIRTY} %s stopped${RST}\n" "$running" "$stopped"

      docker ps --format '{{.Names}}' 2>/dev/null | head -4 | while read -r name; do
        printf "    ${GREEN}●${RST} ${FG}%s${RST}\n" "$name"
      done
      local extra=$((running - 4))
      (( extra > 0 )) && printf "    ${SUBTEXT}...and %d more${RST}\n" "$extra"
    else
      printf "  ${SUBTEXT}${IC_DOCKER} Docker not running${RST}\n"
    fi
  } > "$tmpdir/docker" 2>/dev/null &

  # Git Heatmap (GitHub-style, past 8 weeks)
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
        done < <(git -C "$dir" log --all --since="8 weeks ago" --format="%ad" --date=format:"%Y-%m-%d" 2>/dev/null)
      done

      local today=$(date +%Y-%m-%d)
      local dow=$(date +%u) # 1=Mon, 7=Sun
      local num_weeks=8
      (( term_width < 100 )) && num_weeks=4
      local start_offset=$(( (dow - 1) + (num_weeks - 1) * 7 ))

      # Build heatmap: 7 rows (Mon-Sun) x num_weeks columns
      local day_labels=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
      local output=""
      for row in 0 1 2 3 4 5 6; do
        output+="  ${SUBTEXT}${day_labels[$((row+1))]}${RST} "
        for (( col=0; col<num_weeks; col++ )); do
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
    local docs_cache="$CACHE_DIR/docs.cache"
    local docs_cache_max_age=600

    local use_docs_cache=0
    if [[ -f "$docs_cache" ]]; then
      local docs_cache_age=$(( $(date +%s) - $(stat -f %m "$docs_cache" 2>/dev/null) ))
      (( docs_cache_age < docs_cache_max_age )) && use_docs_cache=1
    fi

    if (( use_docs_cache )); then
      cat "$docs_cache"
    elif [[ -d "$docs_dir" ]]; then
      local now=$(date +%s)
      local docs_output=""
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        local mtime=${line%% *}
        local filepath=${line#* }
        local filename=$(basename "$filepath")
        local ext="${filename##*.}"

        local icon="${SUBTEXT} ${RST}"
        if (( NF )); then
          case "$ext" in
            md)   icon="${BLUE} ${RST}" ;;
            pdf)  icon="${RED} ${RST}" ;;
            txt)  icon="${FG} ${RST}" ;;
            docx) icon="${BLUE}󰈬 ${RST}" ;;
          esac
        fi

        local age=$(( now - mtime ))
        local age_str=$(_time_ago $age)

        # Truncate long filenames
        local display="${filename}"
        (( ${#display} > 38 )) && display="${display:0:35}..."

        docs_output+="$(printf "  %s %-38s ${SUBTEXT}%s${RST}\n" "$icon" "$display" "$age_str")"$'\n'
      done < <(find "$docs_dir" -maxdepth 3 -type f \
        \( -name "*.md" -o -name "*.pdf" -o -name "*.txt" -o -name "*.docx" \) \
        -not -path "*/.obsidian/*" \
        -not -path "*/.*" \
        -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -5)
      printf "%s" "$docs_output" | tee "$docs_cache"
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
          unix)       cat_icon="  " ;;
          vim)        cat_icon="  " ;;
          zsh)        cat_icon="  " ;;
          fzf)        cat_icon="  " ;;
          git)        cat_icon="  " ;;
          tools)      cat_icon="  " ;;
          zellij)     cat_icon="  " ;;
          docker)     cat_icon="󰡨  " ;;
          ssh)        cat_icon="  " ;;
          macos)      cat_icon="  " ;;
          tailscale)  cat_icon="󰒒  " ;;
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

  _header "$IC_HOST" "SYSTEM"
  cat "$tmpdir/system"

  _header "$IC_PROJ" "PROJECTS"
  cat "$tmpdir/projects"

  _header "$IC_DOCKER" "DOCKER"
  cat "$tmpdir/docker"

  _header "$IC_GIT" "GIT ACTIVITY"
  cat "$tmpdir/heatmap"

  if (( term_width >= 100 )); then
    _header "$IC_DOCS" "RECENT DOCS"
    cat "$tmpdir/docs"
  fi

  _header "$IC_TIP" "TIP OF THE DAY"
  cat "$tmpdir/tip"

  printf "\n"

  # Cleanup
  rm -rf "$tmpdir" 2>/dev/null
}

# Run dashboard
_dashboard
