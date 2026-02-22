#!/usr/bin/env bash
# commands/list.sh — list all saved identities

store_ensure

active=$(store_get_active)
identities=$(store_get_identities)
count=$(echo "$identities" | jq 'length')

if [[ "$count" -eq 0 ]]; then
  ui_info "No identities saved. Run 'gitid add' to create one."
  exit 0
fi


ui_header "Saved Identities ($count)"

while IFS= read -r row; do
  alias=$(echo "$row" | jq -r '.alias')
  name=$(echo "$row"  | jq -r '.name')
  email=$(echo "$row" | jq -r '.email')
  key=$(echo "$row"   | jq -r '.ssh_key')

  marker=""
  [[ "$alias" == "$active" ]] && marker="  ← active"

  echo "  [$alias]${marker}"
  echo "    Name:    $name"
  echo "    Email:   $email"
  echo "    SSH Key: $key"
  echo
done < <(echo "$identities" | jq -c '.[]')
