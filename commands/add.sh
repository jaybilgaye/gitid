#!/usr/bin/env bash
# commands/add.sh — add a new git identity

ui_header "Add a New Git Identity"

NAME=$(ui_input "Display name (e.g. Jay Work)")
validate_nonempty "$NAME" "Name" || exit 1

EMAIL=$(ui_input "Email address")
validate_nonempty "$EMAIL" "Email" || exit 1
validate_email "$EMAIL"   || exit 1

ALIAS=$(ui_input "Alias (e.g. work, personal) — used in SSH host names")
validate_nonempty "$ALIAS" "Alias" || exit 1
validate_alias "$ALIAS"            || exit 1

store_ensure

if store_alias_exists "$ALIAS"; then
  ui_error "An identity with alias '$ALIAS' already exists."
  ui_error "Use 'gitid remove $ALIAS' first, or choose a different alias."
  exit 1
fi

DEFAULT_KEY="$HOME/.ssh/id_ed25519"
SSH_KEY=$(ui_input "SSH key path" "$DEFAULT_KEY")
SSH_KEY="${SSH_KEY:-$DEFAULT_KEY}"
SSH_KEY="${SSH_KEY/#\~/$HOME}"   # expand leading ~

if [[ ! -f "$SSH_KEY" ]]; then
  if ui_confirm "SSH key not found at '$SSH_KEY'. Add identity anyway?"; then
    ui_info "Warning: SSH key path saved but file does not exist yet."
  else
    ui_info "Aborted."
    exit 1
  fi
fi

echo
ui_info "Name:    $NAME"
ui_info "Email:   $EMAIL"
ui_info "Alias:   $ALIAS"
ui_info "SSH Key: $SSH_KEY"
echo

if ! ui_confirm "Save this identity?"; then
  ui_info "Aborted."
  exit 1
fi

store_add "$NAME" "$ALIAS" "$EMAIL" "$SSH_KEY"
ui_success "Identity '$ALIAS' added."
ui_info "Run 'gitid switch' to activate it, or 'gitid config-ssh' to update SSH config."
