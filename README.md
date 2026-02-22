<div align="center">

# 🪪 gitid

### Switch Git identities in one command — work, personal, and client profiles, sorted.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform: macOS + Linux](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey?logo=apple)](https://github.com/jaybilgaye/gitid)
[![Version](https://img.shields.io/badge/version-v2-orange)](https://github.com/jaybilgaye/gitid)
[![Maintained by Jay](https://img.shields.io/badge/maintained%20by-Jay-blueviolet)](https://jaybilgaye.github.io)

</div>

---

## 😤 The Problem

You juggle **multiple GitHub accounts** — work, personal, maybe a client or two.

Every time you switch context, you either:

- 😬 Push a commit to a client repo with your personal email
- 🔑 Fight SSH key conflicts between accounts
- 📋 Manually edit `~/.gitconfig` or `~/.ssh/config` and forget something
- 🤦 Google "how to switch git user" for the 50th time

**gitid fixes all of this in a single command.**

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔀 **One-command switch** | `gitid switch` applies name, email & SSH key instantly |
| 🔒 **Secure storage** | Identity store at `~/.gitid/` with `600`/`700` permissions |
| 🛡️ **Non-destructive SSH** | Only manages its own block in `~/.ssh/config` — never touches your other entries |
| 💾 **Atomic writes** | Zero risk of a corrupt identity store on interrupted writes |
| 🎨 **Rich TUI** | Beautiful menus with [gum](https://github.com/charmbracelet/gum) — falls back gracefully to plain prompts |
| 📥 **Import existing SSH config** | One command to pull in your existing `Host github-*` entries |
| 🔁 **Hooks** | `post-switch` hook for custom automation (re-sign commits, update prompts, etc.) |
| 🧪 **SSH test** | Verify an identity's SSH connection before committing |
| 🚀 **No runtime deps** | Just `bash`, `git`, and `jq` — all auto-installed by the installer |

---

## 🚀 Quick Install

```bash
git clone https://github.com/jaybilgaye/gitid.git
cd gitid
bash install.sh
```

That's it. The installer handles `jq` and `git` automatically.

> **Optional:** Install [gum](https://github.com/charmbracelet/gum) for a beautiful interactive TUI.
> gitid works perfectly without it — gum is a quality-of-life upgrade only.

---

## 📖 How It Works

```
You run: gitid switch
              │
              ▼
  ┌───────────────────────┐
  │  Pick an identity     │  ← gum selector (or plain list)
  │  > work               │
  │    personal           │
  │    client-acme        │
  └───────────┬───────────┘
              │
              ▼
  ┌───────────────────────┐
  │  gitid applies:       │
  │  git config user.name │  ← scoped to current repo only
  │  git config user.email│
  └───────────┬───────────┘
              │
              ▼
  ┌───────────────────────┐
  │  SSH key wired up     │  ← via ~/.ssh/config managed block
  │  Host github-work     │
  │    IdentityFile ...   │
  └───────────────────────┘
              │
              ▼
         ✅ Done. Commits now go out as the right person.
```

---

## 🎯 Example Walkthrough

### Step 1 — Add your identities

```bash
gitid add
# Prompts:
#   Name      → Jay Work
#   Email     → jay@company.com
#   Alias     → work
#   SSH key   → ~/.ssh/id_ed25519_work

gitid add
#   Name      → Jay Personal
#   Email     → jay@gmail.com
#   Alias     → personal
#   SSH key   → ~/.ssh/id_ed25519_personal
```

Already have `Host github-*` entries in `~/.ssh/config`? Import them instead:

```bash
gitid import-ssh
# Reads all 'Host github-<alias>' blocks; prompts only for name & email
```

### Step 2 — Wire up SSH

```bash
gitid config-ssh
# Writes a gitid-managed block into ~/.ssh/config
# Your existing SSH config is untouched
```

### Step 3 — Switch identity in any repo

```bash
cd ~/code/work-project
gitid switch
# Select: work
# ✅ Switched to work (jay@company.com)

cd ~/code/personal-site
gitid switch
# Select: personal
# ✅ Switched to personal (jay@gmail.com)
```

### Step 4 — Verify

```bash
gitid current
# Active identity : work
# git user.name   : Jay Work
# git user.email  : jay@company.com
```

### Step 5 — Update your remote URL

After `gitid config-ssh`, push/pull via the alias host:

```bash
git remote set-url origin git@github-work:acme/backend.git
git remote set-url origin git@github-personal:jay/my-site.git
```

---

## 📋 All Commands

| Command | What it does |
|---------|-------------|
| `gitid add` | Add a new identity (interactive) |
| `gitid list` | List all saved identities |
| `gitid switch` | Apply an identity to the current repo |
| `gitid current` | Show the active git identity |
| `gitid remove` | Remove a saved identity |
| `gitid config-ssh` | Sync identities to `~/.ssh/config` |
| `gitid test` | Test SSH connection for an identity |
| `gitid import-ssh` | Import `Host github-<alias>` entries from `~/.ssh/config` |
| `gitid uninstall` | Cleanly remove gitid from your system |

---

## 🖥️ Platform Support

| Platform | Status | Deps auto-installed via |
|----------|--------|------------------------|
| macOS (Intel + Apple Silicon) | ✅ Tested | Homebrew |
| Ubuntu / Debian | ✅ Tested | apt-get |
| Fedora / RHEL | ✅ Tested | dnf |
| Arch Linux | ✅ Tested | pacman |
| Other Linux | ✅ Works | manual install required |

---

## 🗂️ How Data Is Stored

```
~/.gitid/
├── identities.json    ← identity store (chmod 600)
├── lib/               ← library scripts
├── commands/          ← command scripts
├── hooks/             ← optional automation hooks
└── backups/           ← timestamped SSH config backups
```

Your SSH keys, git config, and repos are **never touched** by gitid outside of these files.

---

## 🔁 Hooks

Drop executable scripts into `~/.gitid/hooks/` to run custom logic after a switch:

```bash
# ~/.gitid/hooks/post-switch
#!/usr/bin/env bash
echo "Switched to $1 — remember to check your GPG signing key"
```

---

## 🔑 SSH Host Alias Naming

gitid uses the `Host github-<alias>` convention. Your `~/.ssh/config` entries **must** follow this pattern for `gitid import-ssh` to detect them:

```
# ✅ Recognised
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# ❌ NOT recognised
Host my-github
Host work.github.com
```

The alias is everything after `github-` (e.g. `Host github-work` → alias `work`).

---

## 🛠️ Troubleshooting

### `fatal: not in a git directory`

`gitid switch` sets `git config` **locally** on the current repo — you must be inside one:

```bash
cd ~/code/my-project   # ← must be a git repo
gitid switch
```

---

### `gitid import-ssh` finds no entries

Your SSH hosts must be named `github-<alias>`. If they use a different scheme, add identities manually with `gitid add`.

---

### Alias already exists on import

Matching aliases are skipped to prevent duplicates. Remove first if you want to re-import:

```bash
gitid remove <alias>
gitid import-ssh
```

---

## 🗑️ Uninstall

```bash
gitid uninstall
# or manually:
rm -f /usr/local/bin/gitid    # (or ~/.local/bin/gitid)
rm -rf ~/.gitid
# Remove the gitid block from ~/.ssh/config if present
```

---

## 🔄 Migrating from gitid v1

v1 used `~/.git-identities.json`. Just re-add your identities:

```bash
gitid add
# or import from SSH config:
gitid import-ssh
```

---

## 📜 License

MIT © [Jay](https://jaybilgaye.github.io)
