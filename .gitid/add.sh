#!/bin/bash

set -e

STORE="$HOME/.git-identities.json"
DEFAULT_KEY="$HOME/.ssh/id_ed25519"

echo "🔧 Add a New Git Identity"

read -r -p "👤 Enter display name: " NAME
read -r -p "📧 Enter email address: " EMAIL
read -r -p "🔖 Enter alias (e.g., jay, vibe, bmd): " ALIAS
read -r -p "🗂️  SSH key file path [$DEFAULT_KEY]: " SSH_KEY_PATH

SSH_KEY_PATH="${SSH_KEY_PATH:-$DEFAULT_KEY}"

echo
echo "📝 Please confirm the details:"
echo "👤 Name:  $NAME"
echo "📧 Email: $EMAIL"
echo "🔖 Alias: $ALIAS"
echo "🗂️  SSH Key: $SSH_KEY_PATH"
echo

read -r -p "✅ Confirm and save? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Aborted."
  exit 1
fi

# Ensure file exists
touch "$STORE"
if ! jq empty "$STORE" 2>/dev/null; then
  echo "[]" > "$STORE"
fi

# Append identity using jq
jq_output=$(jq --arg name "$NAME" \
               --arg alias "$ALIAS" \
               --arg email "$EMAIL" \
               --arg ssh_key "$SSH_KEY_PATH" \
               '. += [{"name": $name, "alias": $alias, "email": $email, "ssh_key": $ssh_key}]' "$STORE")

echo "$jq_output" > "$STORE"

echo "🎉 Identity added successfully!"
