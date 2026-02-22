#!/usr/bin/env bash
# commands/test.sh — test SSH connection for an identity
# Usage: gitid test [alias]

store_ensure

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  active=$(store_get_active)
  if [[ -n "$active" ]]; then
    TARGET="$active"
    ui_info "Testing active identity: $active"
  else
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
    TARGET=$(ui_choose "Select identity to test:" "${ALIASES[@]}")
  fi
fi

if [[ -z "$TARGET" ]]; then
  ui_info "No identity selected."
  exit 0
fi

if ! store_alias_exists "$TARGET"; then
  ui_error "Identity '$TARGET' not found."
  exit 1
fi

IDENTITY=$(store_find_by_alias "$TARGET")
SSH_KEY=$(echo "$IDENTITY" | jq -r '.ssh_key')
SSH_KEY="${SSH_KEY/#\~/$HOME}"

ui_header "Testing Identity: $TARGET"

# Check SSH key file
if [[ -f "$SSH_KEY" ]]; then
  ui_info "SSH key found:         $SSH_KEY ✓"
else
  ui_error "SSH key not found:     $SSH_KEY"
  exit 1
fi

# Check SSH host entry
HOST="github-${TARGET}"
if grep -qF "Host ${HOST}" "${HOME}/.ssh/config" 2>/dev/null; then
  ui_info "SSH host entry found:  $HOST ✓"
else
  ui_info "SSH host entry missing for $HOST"
  ui_info "Run 'gitid config-ssh' to generate it."
fi

# Test SSH connection (GitHub returns exit code 1 even on success)
ui_info "SSH connection test:   git@${HOST}"
echo
ssh -T "git@${HOST}" 2>&1 || true
