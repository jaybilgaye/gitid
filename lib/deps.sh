#!/usr/bin/env bash
# lib/deps.sh — dependency checking

# Print the OS family: "macos", "linux", or "unknown"
_gitid_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

# Return a platform-appropriate install hint for a package
_gitid_install_hint() {
  local pkg="$1"
  local os; os=$(_gitid_os)
  case "$os" in
    macos)
      echo "brew install $pkg"
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        echo "sudo apt-get install -y $pkg"
      elif command -v dnf >/dev/null 2>&1; then
        echo "sudo dnf install -y $pkg"
      elif command -v yum >/dev/null 2>&1; then
        echo "sudo yum install -y $pkg"
      elif command -v pacman >/dev/null 2>&1; then
        echo "sudo pacman -S $pkg"
      else
        echo "install $pkg via your package manager"
      fi
      ;;
    *)
      echo "install $pkg via your package manager"
      ;;
  esac
}

deps_require_core() {
  local missing=0
  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required.  Install: $(_gitid_install_hint jq)" >&2
    missing=1
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ git is required.  Install: $(_gitid_install_hint git)" >&2
    missing=1
  fi
  [[ $missing -eq 0 ]] || exit 1
}

deps_check_gum() {
  command -v gum >/dev/null 2>&1
}
