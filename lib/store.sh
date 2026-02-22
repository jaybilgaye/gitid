#!/usr/bin/env bash
# lib/store.sh — identity store I/O layer
#
# Storage layout:
#   ~/.gitid/identities.json   (chmod 600)
#   ~/.gitid/                  (chmod 700)
#
# JSON schema:
#   { "version": 1, "active": "<alias>|null", "identities": [...] }

GITID_HOME="${GITID_HOME:-$HOME/.gitid}"
STORE="${GITID_HOME}/identities.json"

# --- Internal helpers ---

# Write raw content to store atomically (temp file + mv).
# Sets chmod 600 on the result.
_store_write_raw() {
  local content="$1"
  local tmp
  tmp=$(mktemp "${STORE}.tmp.XXXXXX")
  printf '%s\n' "$content" > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$STORE"
}

# --- Public API ---

# Ensure ~/.gitid/ and identities.json exist with correct permissions.
store_ensure() {
  mkdir -p "$GITID_HOME"
  chmod 700 "$GITID_HOME"
  if [[ ! -f "$STORE" ]]; then
    _store_write_raw '{"version":1,"active":null,"identities":[]}'
  fi
  chmod 600 "$STORE"
}

# Read and validate the store. Outputs raw JSON. Exits on corruption.
store_read() {
  store_ensure
  local content
  content=$(cat "$STORE")
  if ! echo "$content" | jq empty 2>/dev/null; then
    ui_error "Store is corrupted: $STORE"
    ui_error "Delete it to start fresh, or restore from a backup."
    exit 1
  fi
  echo "$content"
}

# Validate then atomically write JSON to store.
store_write() {
  local content="$1"
  if ! echo "$content" | jq empty 2>/dev/null; then
    ui_error "Internal error: refusing to write invalid JSON to store"
    exit 1
  fi
  _store_write_raw "$content"
}

# Return .identities as a JSON array.
store_get_identities() {
  store_read | jq '.identities'
}

# Return identity object for a given alias, or empty if not found.
store_find_by_alias() {
  local alias="$1"
  store_read | jq --arg a "$alias" '.identities | map(select(.alias == $a)) | .[0] // empty'
}

# Return 0 if alias exists in store, 1 otherwise.
store_alias_exists() {
  local alias="$1"
  local count
  count=$(store_read | jq --arg a "$alias" '[.identities[] | select(.alias == $a)] | length')
  [[ "$count" -gt 0 ]]
}

# Return the active alias string, or empty if none set.
store_get_active() {
  store_read | jq -r '.active // empty'
}

# Set .active to the given alias.
store_set_active() {
  local alias="$1"
  local current
  current=$(store_read)
  store_write "$(echo "$current" | jq --arg a "$alias" '.active = $a')"
}

# Append a new identity to the store.
store_add() {
  local name="$1" alias="$2" email="$3" ssh_key="$4"
  local current
  current=$(store_read)
  store_write "$(echo "$current" | jq \
    --arg name    "$name"    \
    --arg alias   "$alias"   \
    --arg email   "$email"   \
    --arg ssh_key "$ssh_key" \
    '.identities += [{"name":$name,"alias":$alias,"email":$email,"ssh_key":$ssh_key}]')"
}

# Remove an identity by alias. Clears .active if it pointed to that alias.
store_remove() {
  local alias="$1"
  local current active updated
  current=$(store_read)
  active=$(echo "$current" | jq -r '.active // empty')

  updated=$(echo "$current" | jq --arg a "$alias" \
    '.identities = [.identities[] | select(.alias != $a)]')

  if [[ "$active" == "$alias" ]]; then
    updated=$(echo "$updated" | jq '.active = null')
  fi

  store_write "$updated"
}
