#!/usr/bin/env bash
# commands/remove.sh — remove a saved identity
# Usage: gitid remove [alias]

store_ensure

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  identities=$(store_get_identities)
  count=$(echo "$identities" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    ui_error "No identities saved."
    exit 1
  fi

  ALIASES=()
  while IFS= read -r line; do
    ALIASES+=("$line")
  done < <(echo "$identities" | jq -r '.[].alias')

  TARGET=$(ui_choose "Select identity to remove:" "${ALIASES[@]}")
fi

if [[ -z "$TARGET" ]]; then
  ui_info "No identity selected."
  exit 0
fi

if ! store_alias_exists "$TARGET"; then
  ui_error "Identity '$TARGET' not found."
  exit 1
fi

if ! ui_confirm "Remove identity '$TARGET'? This cannot be undone."; then
  ui_info "Aborted."
  exit 0
fi

store_remove "$TARGET"
ui_success "Identity '$TARGET' removed."
