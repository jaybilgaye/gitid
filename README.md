# gitid v2 — Git Identity Manager

**Author:** Jay · [jaybilgaye.github.io](https://jaybilgaye.github.io) · MIT License

Manage multiple Git identities (name, email, SSH keys) from the terminal.
Switch between work, personal, and client profiles in one command.

## Features

| Command | Description |
|---------|-------------|
| `gitid add` | Add a new identity |
| `gitid list` | List all saved identities |
| `gitid switch` | Apply an identity to the current repo |
| `gitid current` | Show the active git identity |
| `gitid remove` | Remove a saved identity |
| `gitid config-ssh` | Sync identities to `~/.ssh/config` (non-destructive) |
| `gitid test` | Test SSH connection for an identity |
| `gitid import-ssh` | Import from an existing `~/.ssh/config` |

## Install

```bash
git clone https://github.com/jaybilgaye/gitid.git
cd gitid
bash install.sh
```

Requires: `jq`, `git` (auto-installed by `install.sh` if missing)
Optional: `gum` (rich TUI; falls back to plain prompts without it)

### Platform support

| Platform | Tested | Auto-installs deps |
|----------|--------|--------------------|
| macOS (Intel + Apple Silicon) | ✅ | via Homebrew |
| Ubuntu / Debian | ✅ | via apt-get |
| Fedora / RHEL | ✅ | via dnf |
| Arch Linux | ✅ | via pacman |
| Other Linux | ✅ | manual install required |

## Quick Start

```bash
# 1. Add identities
gitid add
# → prompts for name, email, alias, SSH key path

# 2. Sync to ~/.ssh/config (only touches gitid's own block)
gitid config-ssh

# 3. Switch identity in your repo
cd ~/code/my-work-project
gitid switch

# 4. Verify
gitid current
```

## SSH Remote URLs

After running `gitid config-ssh`, each identity gets a dedicated SSH host:

```
Host github-work       →  git@github-work:org/repo.git
Host github-personal   →  git@github-personal:user/repo.git
```

Set your remote to use the alias host:

```bash
git remote set-url origin git@github-work:acme/backend.git
```

## Hooks

Place executable scripts in `~/.gitid/hooks/` to run automatically:

```
~/.gitid/hooks/post-switch   # Called after 'gitid switch'; receives alias as $1
```

Example:
```bash
#!/usr/bin/env bash
# ~/.gitid/hooks/post-switch
echo "Switched to $1 — remember to check your GPG signing key"
```

## Storage

```
~/.gitid/
├── identities.json    # Identity store (chmod 600)
├── lib/               # Library scripts
├── commands/          # Command scripts
├── hooks/             # Optional hook scripts
└── backups/           # SSH config backups (created before every config-ssh run)
```

## Migrating from gitid v1

If you have a `~/.git-identities.json` from v1, import it:

```bash
# v1 used a flat array; convert it manually or re-add via gitid add
gitid add
```

Or use `gitid import-ssh` if your SSH config already has the host entries.

## Differences from v1

- Non-destructive SSH config updates (only replaces gitid's own block)
- Atomic writes — no store corruption on interrupted writes
- All commands implemented (remove, test, import-ssh were stubs in v1)
- Input validation — email format, alias character rules, SSH key existence check
- No shell injection — all jq queries use `--arg` flags
- Active identity pointer — unambiguous tracking across identities sharing an email
- gum is optional — works in plain terminals and CI
- File permissions hardened at creation (600/700)
