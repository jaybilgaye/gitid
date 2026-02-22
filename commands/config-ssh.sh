#!/usr/bin/env bash
# commands/config-ssh.sh — sync identities to the gitid block in ~/.ssh/config

store_ensure

count=$(store_get_identities | jq 'length')

if [[ "$count" -eq 0 ]]; then
  ui_error "No identities saved. Run 'gitid add' first."
  exit 1
fi

ui_info "Updating gitid managed block in ~/.ssh/config..."
ssh_update_managed_block

ui_success "~/.ssh/config updated (only the gitid section was changed)"
ui_info "Use 'Host github-<alias>' in your remote URLs, e.g.:"
ui_info "  git remote set-url origin git@github-work:org/repo.git"
