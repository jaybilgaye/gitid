#!/bin/bash

set -e

REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/gitid/main"
INSTALL_PATH="/usr/local/bin/gitid"
ADD_SCRIPT_PATH="$HOME/.gitid/add.sh"

mkdir -p ~/.gitid

command -v gum >/dev/null || { echo "Installing gum..."; brew install gum; }
command -v jq >/dev/null || { echo "Installing jq..."; brew install jq; }

echo "📥 Installing gitid to $INSTALL_PATH..."
curl -s "$REPO_URL/gitid" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "📥 Installing add.sh..."
curl -s "$REPO_URL/.gitid/add.sh" -o "$ADD_SCRIPT_PATH"
chmod +x "$ADD_SCRIPT_PATH"

if [ ! -f "$HOME/.git-identities.json" ]; then
  echo "[]" > "$HOME/.git-identities.json"
fi

echo "✅ GitID installed successfully!"
which gitid && gitid
