#!/usr/bin/env bash
# install.sh — install gitid v2
#
# Author: Jay (jaybilgaye.github.io)
#
# Supports: macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf/yum),
#           Arch Linux (pacman). gum is optional — gitid falls back to plain
#           prompts if it is not installed.

set -euo pipefail

INSTALL_HOME="${GITID_HOME:-$HOME/.gitid}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── OS / architecture detection ──────────────────────────────────────────────

_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

_arch() {
  case "$(uname -m)" in
    x86_64)          echo "x86_64" ;;
    aarch64 | arm64) echo "arm64" ;;
    *)               echo "unknown" ;;
  esac
}

# ── Package manager helpers ───────────────────────────────────────────────────

# Try to install $1 using whatever package manager is available.
# Returns 1 if nothing could install it (caller decides whether to abort).
_pkg_install() {
  local pkg="$1"

  if command -v brew >/dev/null 2>&1; then
    brew install "$pkg"
    return 0
  fi

  if [[ "$(_os)" == "linux" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq && sudo apt-get install -y "$pkg"
      return 0
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y "$pkg"
      return 0
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y "$pkg"
      return 0
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm "$pkg"
      return 0
    fi
  fi

  return 1
}

# Install gum (optional TUI library).
# macOS/Linux-with-brew: brew install gum
# Debian/Ubuntu: charm.sh APT repo
# Fedora/RHEL:   charm.sh RPM repo
# Others:        print instructions and continue
_install_gum() {
  if command -v gum >/dev/null 2>&1; then return 0; fi

  echo "   Installing gum (optional rich TUI)..."

  if command -v brew >/dev/null 2>&1; then
    brew install gum
    return 0
  fi

  if [[ "$(_os)" == "linux" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      # Charm's official APT repo
      if command -v gpg >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key \
          | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
          | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y gum
        return 0
      fi
    elif command -v dnf >/dev/null 2>&1; then
      echo "[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key" | sudo tee /etc/yum.repos.d/charm.repo >/dev/null
      sudo dnf install -y gum
      return 0
    fi
  fi

  # Could not install gum — it is optional, so just inform the user
  echo "   gum could not be installed automatically."
  echo "   gitid will use plain prompts (works fine without gum)."
  echo "   To install gum manually: https://github.com/charmbracelet/gum#installation"
}

# ── Determine binary install path ────────────────────────────────────────────
#
# Priority:
#   1. /usr/local/bin   (writable without sudo — common on macOS with Homebrew)
#   2. /usr/local/bin   (via sudo — common on Linux)
#   3. ~/.local/bin     (no-sudo fallback; user must ensure it is in PATH)

_pick_bin_dir() {
  if [[ -w "/usr/local/bin" ]]; then
    echo "/usr/local/bin"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    echo "/usr/local/bin"   # sudo available without password prompt
  else
    echo "$HOME/.local/bin"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo "gitid v2 — Git Identity Manager"
echo "Author: Jay (jaybilgaye.github.io)"
echo
echo "  OS:   $(_os) / $(_arch)"
echo "  Home: $INSTALL_HOME"
echo

# --- jq (required) ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Installing jq..."
  if ! _pkg_install jq; then
    echo "❌ Could not install jq automatically."
    echo "   Please install jq manually and re-run this script."
    echo "   See: https://jqlang.github.io/jq/download/"
    exit 1
  fi
fi
echo "   jq: $(jq --version)"

# --- git (required, should already be present) ---
if ! command -v git >/dev/null 2>&1; then
  echo "Installing git..."
  if ! _pkg_install git; then
    echo "❌ Could not install git automatically. Please install git and re-run."
    exit 1
  fi
fi
echo "   git: $(git --version)"

# --- gum (optional) ---
_install_gum

echo

# ── Copy files ───────────────────────────────────────────────────────────────

mkdir -p "${INSTALL_HOME}/lib"
mkdir -p "${INSTALL_HOME}/commands"
mkdir -p "${INSTALL_HOME}/hooks"
chmod 700 "$INSTALL_HOME"

cp "${REPO_DIR}/lib/"*.sh      "${INSTALL_HOME}/lib/"
cp "${REPO_DIR}/commands/"*.sh "${INSTALL_HOME}/commands/"
cp "${REPO_DIR}/bin/gitid"     "${INSTALL_HOME}/gitid"

chmod +x "${INSTALL_HOME}/gitid"
chmod +x "${INSTALL_HOME}/lib/"*.sh
chmod +x "${INSTALL_HOME}/commands/"*.sh

echo "   Files installed to: $INSTALL_HOME"

# ── Bootstrap identity store ─────────────────────────────────────────────────

STORE="${INSTALL_HOME}/identities.json"
if [[ ! -f "$STORE" ]]; then
  printf '{"version":1,"active":null,"identities":[]}\n' > "$STORE"
  chmod 600 "$STORE"
  echo "   Created store: $STORE"
fi

# ── Link binary ──────────────────────────────────────────────────────────────

BIN_DIR=$(_pick_bin_dir)
BIN_PATH="${BIN_DIR}/gitid"

mkdir -p "$BIN_DIR"

if [[ -w "$BIN_DIR" ]]; then
  ln -sf "${INSTALL_HOME}/gitid" "$BIN_PATH"
else
  echo "   Linking to $BIN_PATH (requires sudo)..."
  sudo ln -sf "${INSTALL_HOME}/gitid" "$BIN_PATH"
fi

echo "   Binary: $BIN_PATH"

# Warn if ~/.local/bin was chosen and may not be in PATH
if [[ "$BIN_DIR" == "$HOME/.local/bin" ]]; then
  echo
  echo "   ⚠️  $BIN_DIR is not always in PATH."
  echo "   Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
  echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo
echo "✅ gitid installed successfully!"
echo
"${INSTALL_HOME}/gitid" help
