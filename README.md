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

## Uninstall

```bash
# 1. Remove the binary symlink
rm -f /usr/local/bin/gitid          # default location
# or, if installed to ~/.local/bin:
rm -f ~/.local/bin/gitid

# 2. Remove all gitid data and scripts
rm -rf ~/.gitid

# 3. (Optional) Remove the gitid block from ~/.ssh/config
#    Open ~/.ssh/config and delete the lines between:
#      # BEGIN gitid managed block
#      # END gitid managed block
```

> Your SSH keys, git config, and any repos are untouched — only the files
> created by `install.sh` are removed.

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
# 1a. Add a new identity manually
gitid add
# → prompts for name, email, alias, SSH key path

# 1b. OR import existing Host entries from ~/.ssh/config
gitid import-ssh
# → reads all 'Host github-<alias>' entries; prompts for name & email only

# 2. Sync identities into ~/.ssh/config (only touches gitid's own block)
gitid config-ssh

# 3. Switch identity — must be inside a git repo
cd ~/code/my-work-project
gitid switch

# 4. Verify
gitid current
```

> **`fatal: not in a git directory`** — If you see this error after `gitid switch`,
> you are not inside a git repository. `gitid switch` sets `git config user.name`
> and `git config user.email` locally on the current repo.
> Always `cd` into a project directory first:
> ```bash
> cd ~/code/my-project   # ← must be a git repo
> gitid switch
> ```

## SSH Host Alias Naming

gitid uses the convention `Host github-<alias>` in `~/.ssh/config`. The `<alias>`
is a short identifier you choose (e.g. `work`, `personal`, `jay`, `bmd`).

**Your `~/.ssh/config` entries must follow this pattern** for `gitid import-ssh`
to detect them automatically:

```
# ✅ Recognised by gitid import-ssh
Host github-jay
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_jay
  IdentitiesOnly yes

Host github-work
  HostName github.com
  ...

# ❌ NOT recognised — different naming scheme
Host my-github
Host work.github.com
```

The alias must start with `github-`. Everything after `github-` becomes the alias
inside gitid (e.g. `Host github-jay` → alias `jay`).

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

## Troubleshooting

### `fatal: not in a git directory`

```
$ gitid switch
...
fatal: not in a git directory
```

`gitid switch` sets `git config user.name` and `git config user.email` **locally**
on the current repository. Running it outside a git repo causes this error.

**Fix:** `cd` into a git project first.

```bash
cd ~/code/my-project
gitid switch
```

---

### `gitid import-ssh` finds no entries

```
❌  No 'Host github-<alias>' entries found in ~/.ssh/config
```

Your SSH config hosts must be named `github-<alias>`. See the
[SSH Host Alias Naming](#ssh-host-alias-naming) section above for the required
format. If your hosts use a different naming scheme, add identities manually:

```bash
gitid add
```

---

### Alias already exists on import

If you already added an identity with `gitid add` and then run `gitid import-ssh`,
entries with matching aliases are skipped (not duplicated). Remove the existing
entry first if you want to re-import:

```bash
gitid remove <alias>
gitid import-ssh
```

---

## Differences from v1

- Non-destructive SSH config updates (only replaces gitid's own block)
- Atomic writes — no store corruption on interrupted writes
- All commands implemented (remove, test, import-ssh were stubs in v1)
- Input validation — email format, alias character rules, SSH key existence check
- No shell injection — all jq queries use `--arg` flags
- Active identity pointer — unambiguous tracking across identities sharing an email
- gum is optional — works in plain terminals and CI
- File permissions hardened at creation (600/700)
