#!/usr/bin/env bash
# commands/uninstall.sh — remove gitid from the system

INSTALL_HOME="${GITID_HOME:-$HOME/.gitid}"

echo "gitid — Uninstaller"
echo

# ── Remove binary symlink(s) ──────────────────────────────────────────────────

BIN_CANDIDATES=("/usr/local/bin/gitid" "$HOME/.local/bin/gitid")

for BIN_PATH in "${BIN_CANDIDATES[@]}"; do
  if [[ -L "$BIN_PATH" ]]; then
    BIN_DIR="$(dirname "$BIN_PATH")"
    if [[ -w "$BIN_DIR" ]]; then
      rm -f "$BIN_PATH"
    else
      echo "   Removing $BIN_PATH (requires sudo)..."
      sudo rm -f "$BIN_PATH"
    fi
    echo "   Removed: $BIN_PATH"
  fi
done

# ── Optionally keep identity data ─────────────────────────────────────────────

KEEP_DATA=false
STORE="${INSTALL_HOME}/identities.json"

if [[ -f "$STORE" ]]; then
  printf "   Keep identity data (%s)? [y/N] " "$STORE"
  read -r REPLY
  [[ "$REPLY" =~ ^[Yy]$ ]] && KEEP_DATA=true
fi

# ── Remove install directory ──────────────────────────────────────────────────

if [[ -d "$INSTALL_HOME" ]]; then
  if $KEEP_DATA; then
    TMPSTORE="$(mktemp)"
    cp "$STORE" "$TMPSTORE"

    TMPBACKUPS=""
    if [[ -d "${INSTALL_HOME}/backups" ]]; then
      TMPBACKUPS="$(mktemp -d)"
      cp -r "${INSTALL_HOME}/backups/." "$TMPBACKUPS/"
    fi

    rm -rf "$INSTALL_HOME"
    mkdir -p "$INSTALL_HOME"
    chmod 700 "$INSTALL_HOME"
    cp "$TMPSTORE" "$STORE"
    chmod 600 "$STORE"
    rm -f "$TMPSTORE"

    if [[ -n "$TMPBACKUPS" ]]; then
      mkdir -p "${INSTALL_HOME}/backups"
      cp -r "${TMPBACKUPS}/." "${INSTALL_HOME}/backups/"
      rm -rf "$TMPBACKUPS"
    fi

    echo "   Removed gitid files; kept data at: $INSTALL_HOME"
  else
    rm -rf "$INSTALL_HOME"
    echo "   Removed: $INSTALL_HOME"
  fi
fi

echo
echo "gitid uninstalled successfully."
if $KEEP_DATA; then
  echo "   Your identity data is preserved at: $INSTALL_HOME"
  echo "   Remove it manually later with:  rm -rf $INSTALL_HOME"
fi
