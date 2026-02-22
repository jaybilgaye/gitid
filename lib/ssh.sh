#!/usr/bin/env bash
# lib/ssh.sh — SSH config management
#
# gitid owns a clearly delimited block inside ~/.ssh/config:
#
#   # BEGIN GITID MANAGED
#   ...
#   # END GITID MANAGED
#
# Only that block is ever modified. All other config is left untouched.
# A timestamped backup is created before every write.

SSH_FILE="${HOME}/.ssh/config"
SSH_BACKUP_DIR="${GITID_HOME:-$HOME/.gitid}/backups"

_BLOCK_START="# BEGIN GITID MANAGED"
_BLOCK_END="# END GITID MANAGED"

# Back up the current ~/.ssh/config to ~/.gitid/backups/.
ssh_backup() {
  mkdir -p "$SSH_BACKUP_DIR"
  chmod 700 "$SSH_BACKUP_DIR"
  if [[ -f "$SSH_FILE" ]]; then
    local dest="${SSH_BACKUP_DIR}/ssh_config.$(date +%Y%m%d_%H%M%S).bkp"
    cp "$SSH_FILE" "$dest"
    ui_info "SSH config backed up → $dest"
  fi
}

# Build the managed block content from the current store.
_ssh_generate_block() {
  local identities
  identities=$(store_read | jq -c '.identities[]' 2>/dev/null) || true

  echo "$_BLOCK_START"
  echo "# Do not edit this section — managed by gitid ($(date '+%Y-%m-%d %H:%M'))"
  echo

  if [[ -n "$identities" ]]; then
    while IFS= read -r row; do
      local name alias key
      name=$(echo "$row"  | jq -r '.name')
      alias=$(echo "$row" | jq -r '.alias')
      key=$(echo "$row"   | jq -r '.ssh_key')

      echo "# ${name}"
      echo "Host github-${alias}"
      echo "  HostName github.com"
      echo "  User git"
      echo "  IdentityFile ${key}"
      echo "  IdentitiesOnly yes"
      echo
    done <<< "$identities"
  fi

  echo "$_BLOCK_END"
}

# Replace the gitid-managed block in ~/.ssh/config.
# If no block exists yet, appends one. Backs up before writing.
ssh_update_managed_block() {
  mkdir -p "$(dirname "$SSH_FILE")"
  touch "$SSH_FILE"
  chmod 600 "$SSH_FILE"

  ssh_backup

  # Write new block to a temp file (avoids passing newlines to awk -v)
  local block_file tmp
  block_file=$(mktemp)
  _ssh_generate_block > "$block_file"
  tmp=$(mktemp)

  if grep -qF "$_BLOCK_START" "$SSH_FILE" 2>/dev/null; then
    # Stream through the existing file; replace the managed block in-place
    local in_block=false
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "$_BLOCK_START" ]]; then
        in_block=true
        cat "$block_file" >> "$tmp"
        continue
      fi
      if [[ "$in_block" == true ]]; then
        if [[ "$line" == "$_BLOCK_END" ]]; then in_block=false; fi
        continue
      fi
      printf '%s\n' "$line" >> "$tmp"
    done < "$SSH_FILE"
  else
    # No existing block — append with a blank separator
    {
      cat "$SSH_FILE"
      if [[ -s "$SSH_FILE" ]]; then echo; fi
      cat "$block_file"
    } > "$tmp"
  fi

  rm -f "$block_file"
  chmod 600 "$tmp"
  mv "$tmp" "$SSH_FILE"
}
