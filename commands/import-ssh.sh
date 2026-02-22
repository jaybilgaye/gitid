#!/usr/bin/env bash
# commands/import-ssh.sh — import github-* Host entries from ~/.ssh/config

SSH_FILE="${HOME}/.ssh/config"

if [[ ! -f "$SSH_FILE" ]]; then
  ui_error "No ~/.ssh/config found at $SSH_FILE"
  exit 1
fi

ui_header "Import from ~/.ssh/config"

# Find all github-<alias> host entries (exclude gitid's own managed block markers)
ALIASES=()
while IFS= read -r line; do
  ALIASES+=("$line")
done < <(grep -E '^Host github-' "$SSH_FILE" | awk '{print $2}' | sed 's/^github-//')

if [[ ${#ALIASES[@]} -eq 0 ]]; then
  ui_error "No 'Host github-<alias>' entries found in $SSH_FILE"
  exit 1
fi

ui_info "Found ${#ALIASES[@]} GitHub host entry(s): ${ALIASES[*]}"
echo

store_ensure

imported=0
skipped=0

for alias in "${ALIASES[@]}"; do
  if store_alias_exists "$alias"; then
    ui_info "Alias '$alias' already exists — skipping."
    skipped=$((skipped + 1))
    continue
  fi

  # Extract IdentityFile path for this host block
  KEY=$(awk "
    /^Host github-${alias}[[:space:]]*\$/ { found=1; next }
    found && /^Host /                      { exit }
    found && /IdentityFile/                { print \$2; exit }
  " "$SSH_FILE")
  KEY="${KEY/#\~/$HOME}"

  echo "  Importing: $alias"
  if [[ -n "$KEY" ]]; then ui_info "  SSH key:   $KEY"; fi

  NAME=$(ui_input "  Display name for '$alias'")
  if ! validate_nonempty "$NAME" "Name" 2>/dev/null; then
    ui_info "  Skipping '$alias' (no name provided)."
    skipped=$((skipped + 1))
    continue
  fi

  EMAIL=$(ui_input "  Email for '$alias'")
  if ! validate_nonempty "$EMAIL" "Email" 2>/dev/null; then
    ui_info "  Skipping '$alias' (no email provided)."
    skipped=$((skipped + 1))
    continue
  fi
  if ! validate_email "$EMAIL" 2>/dev/null; then
    ui_info "  Skipping '$alias' (invalid email)."
    skipped=$((skipped + 1))
    continue
  fi

  store_add "$NAME" "$alias" "$EMAIL" "${KEY:-}"
  ui_success "Imported '$alias'"
  imported=$((imported + 1))
  echo
done

echo
ui_success "Done: imported $imported, skipped $skipped."
