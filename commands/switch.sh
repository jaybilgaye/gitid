#!/usr/bin/env bash
# commands/switch.sh — apply a saved identity to the current git repo

store_ensure

identities=$(store_get_identities)
count=$(echo "$identities" | jq 'length')

if [[ "$count" -eq 0 ]]; then
  ui_error "No identities saved. Run 'gitid add' first."
  exit 1
fi

# Build alias list for the selector
ALIASES=()
while IFS= read -r line; do
  ALIASES+=("$line")
done < <(echo "$identities" | jq -r '.[].alias')

CHOSEN=$(ui_choose "Select identity to switch to:" "${ALIASES[@]}")

if [[ -z "$CHOSEN" ]]; then
  ui_info "No identity selected."
  exit 0
fi

IDENTITY=$(store_find_by_alias "$CHOSEN")

if [[ -z "$IDENTITY" ]]; then
  ui_error "Identity '$CHOSEN' not found in store."
  exit 1
fi

GIT_NAME=$(echo "$IDENTITY"  | jq -r '.name')
GIT_EMAIL=$(echo "$IDENTITY" | jq -r '.email')

git config user.name  "$GIT_NAME"
git config user.email "$GIT_EMAIL"

store_set_active "$CHOSEN"

ui_success "Switched to '$CHOSEN' ($GIT_NAME <$GIT_EMAIL>)"

# Run post-switch hook if present
HOOK="${GITID_HOME}/hooks/post-switch"
if [[ -x "$HOOK" ]]; then
  "$HOOK" "$CHOSEN"
fi
