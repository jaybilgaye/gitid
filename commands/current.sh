#!/usr/bin/env bash
# commands/current.sh — show the active git identity

git_name=$(git config user.name  2>/dev/null || echo "(not set)")
git_email=$(git config user.email 2>/dev/null || echo "(not set)")

active=""
if [[ -f "${GITID_HOME}/identities.json" ]]; then
  active=$(store_get_active 2>/dev/null || true)
fi

ui_header "Active Git Identity"
ui_info "Name:  $git_name"
ui_info "Email: $git_email"
if [[ -n "$active" ]]; then ui_info "gitid: $active"; fi
