# GitID 🧙 – Git Identity Manager CLI

Manage multiple Git identities with style, simplicity, and terminal UI ⚡

## 🔧 Features

- `gitid add` – Add a new Git identity (name, email, SSH key)
- `gitid list` – View all saved identities
- `gitid switch` – Apply identity to current Git project
- `gitid current` – Show active Git user/email
- `gitid config-ssh` – Generate `.ssh/config` from identity store (with auto backup)
- `gitid remove` – Delete an identity
- `gitid test` – Check if current identity is valid
- `gitid import-ssh` – Import from existing `.ssh/config` (with email prompts)

## 🚀 Quick Install

```bash
curl -s https://raw.githubusercontent.com/jaybilgaye/gitid/main/install.sh | bash
```

✅ Requires: `jq`, `gum` (installed automatically via Homebrew)
