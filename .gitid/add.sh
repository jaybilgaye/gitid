#!/bin/bash

STORE="$HOME/.git-identities.json"
[ ! -f "$STORE" ] && echo "[]" > "$STORE"

echo "🔧 Add New Git Identity"
read -p "👤 Enter display name: " NAME
read -p "📧 Enter email address: " EMAIL
read -p "🔖 Enter alias (e.g., jay, vibe, bmd): " ALIAS
DEFAULT_KEY="$HOME/.ssh/id_ed25519_$ALIAS"
read -p "🗂️  SSH key file path [$DEFAULT_KEY]: " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-$DEFAULT_KEY}

echo ""
gum style --padding "1 2" --border normal --foreground 212 --border-foreground 82 "
📋 Review:
👤 Name  : $NAME
📧 Email : $EMAIL
🔖 Alias : $ALIAS
🔑 SSH   : $SSH_KEY_PATH
"
gum confirm "✅ Confirm adding this Git identity?" || { echo "❌ Cancelled."; exit 0; }

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "⚙️  SSH key not found. Generating..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY_PATH"
else
  echo "✅ SSH key already exists."
fi

jq --arg name "$NAME" --arg email "$EMAIL" --arg alias "$ALIAS" --arg ssh_key "$SSH_KEY_PATH"    '. += [{"name":$name, "email":$email, "alias":$alias, "ssh_key":$ssh_key}]' "$STORE" > "$STORE.tmp" && mv "$STORE.tmp" "$STORE"

echo "✅ Identity saved to $STORE"

gum confirm "🔐 Add to ~/.ssh/config as Host github-$ALIAS?" && {
  echo -e "
# $NAME ($ALIAS)
Host github-$ALIAS
  HostName github.com
  User git
  IdentityFile $SSH_KEY_PATH
  IdentitiesOnly yes
" >> ~/.ssh/config
  echo "✅ SSH config updated."
}
