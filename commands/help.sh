#!/usr/bin/env bash
# commands/help.sh — usage text

cat << 'EOF'
gitid — Git Identity Manager v2

Usage:
  gitid <command> [options]

Commands:
  add          Add a new identity (name, email, alias, SSH key)
  list         List all saved identities
  switch       Apply an identity to the current git repo
  current      Show the active git identity
  remove       Remove a saved identity
  config-ssh   Sync identities to the gitid block in ~/.ssh/config
  test         Test SSH connection for an identity
  import-ssh   Import Host entries from existing ~/.ssh/config
  uninstall    Remove gitid from the system
  help         Show this help

Storage:
  Identities:  ~/.gitid/identities.json  (chmod 600)
  SSH backups: ~/.gitid/backups/

Docs:
  https://github.com/your-org/gitid
EOF
