#!/usr/bin/env bash
# lib/ui.sh — UI abstraction: gum with plain read/echo fallback

# gum requires both a binary and an interactive TTY.
# Checking stdin (fd 0) and stdout (fd 1) covers pipes, CI, and redirected shells.
_has_gum() {
  command -v gum >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]
}

ui_error() {
  echo "❌  $*" >&2
}

ui_success() {
  echo "✅  $*"
}

ui_info() {
  echo "   $*"
}

ui_header() {
  echo
  echo "── $* ──"
  echo
}

# Interactive selector. Returns the chosen item on stdout.
# Menu display goes to stderr so callers can capture stdout cleanly.
ui_choose() {
  local prompt="$1"
  shift
  local selected

  if _has_gum; then
    selected=$(printf '%s\n' "$@" | gum choose --header "$prompt" 2>/dev/null) || true
  else
    echo "$prompt" >&2
    local i=1
    local item
    for item in "$@"; do
      echo "  $i) $item" >&2
      i=$((i + 1))
    done
    local total=$#
    local choice
    while true; do
      printf "Choice [1-%d]: " "$total" >&2
      read -r choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= total )); then
        break
      fi
      echo "  Invalid selection, try again." >&2
    done
    # Retrieve item at position $choice
    local idx=1
    for item in "$@"; do
      if [[ $idx -eq $choice ]]; then
        selected="$item"
        break
      fi
      idx=$((idx + 1))
    done
  fi

  echo "$selected"
}

# Text input. Returns entered value on stdout.
ui_input() {
  local prompt="$1"
  local default="${2:-}"
  local value

  if _has_gum; then
    local placeholder="${default:-$prompt}"
    value=$(gum input --placeholder "$placeholder" --prompt "$prompt: " 2>/dev/null) || true
    # If user hits enter on empty with a default, use default
    [[ -z "$value" && -n "$default" ]] && value="$default"
  else
    if [[ -n "$default" ]]; then
      printf "%s [%s]: " "$prompt" "$default" >&2
    else
      printf "%s: " "$prompt" >&2
    fi
    read -r value
    [[ -z "$value" && -n "$default" ]] && value="$default"
  fi

  echo "$value"
}

# Confirmation prompt. Returns 0 for yes, 1 for no.
ui_confirm() {
  local prompt="$1"

  if _has_gum; then
    gum confirm "$prompt" 2>/dev/null
  else
    local answer
    printf "%s (y/n): " "$prompt" >&2
    read -r answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
  fi
}
