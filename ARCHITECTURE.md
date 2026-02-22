# gitid v2 — Architecture

**Author:** Jay · [jaybilgaye.github.io](https://jaybilgaye.github.io)
**License:** MIT

## Overview

gitid is a CLI tool for managing multiple Git identities (name, email, SSH keys).
v2 is a ground-up rewrite that fixes the security, reliability, and structural issues
present in the original single-file shell script.

---

## Directory Structure

```
gitid-v2/
├── bin/
│   └── gitid               # Thin entrypoint — parses command, sources libs, dispatches
├── lib/
│   ├── deps.sh             # Dependency checking
│   ├── store.sh            # Identity store I/O (atomic read/write, schema validation)
│   ├── validate.sh         # Input validation (email, alias, non-empty, SSH key)
│   ├── ui.sh               # UI abstraction (gum with read/echo fallback)
│   └── ssh.sh              # SSH config management (managed-block replacement)
├── commands/
│   ├── help.sh             # Usage text
│   ├── add.sh              # Add a new identity
│   ├── list.sh             # List all identities
│   ├── switch.sh           # Apply identity to current repo
│   ├── current.sh          # Show active git config user
│   ├── remove.sh           # Remove an identity
│   ├── config-ssh.sh       # Sync identities → ~/.ssh/config managed block
│   ├── test.sh             # Test SSH connection for an identity
│   └── import-ssh.sh       # Import Host entries from existing ~/.ssh/config
├── install.sh              # Installer (copies files, installs deps, sets permissions)
├── README.md               # User-facing documentation
├── ARCHITECTURE.md         # This file
└── .github/workflows/
    └── ci.yml              # Lint + basic CLI test pipeline
```

---

## Layered Architecture

```
┌─────────────────────────────────┐
│            bin/gitid            │  Argument parsing + command dispatch
└────────────────┬────────────────┘
                 │ sources
    ┌────────────┴────────────┐
    │       commands/*.sh     │  One file per command; pure logic
    └────────────┬────────────┘
                 │ calls
    ┌────────────┴──────────────────────────────┐
    │  lib/store.sh  lib/ssh.sh  lib/ui.sh  ... │  Library layer
    └───────────────────────────────────────────┘
                 │ reads/writes
    ┌────────────┴────────────┐
    │  ~/.gitid/              │  Data layer (filesystem)
    │    identities.json      │
    │    backups/             │
    └─────────────────────────┘
```

Each layer has one responsibility:

| Layer | File(s) | Responsibility |
|-------|---------|----------------|
| Entrypoint | `bin/gitid` | Parse `$1`, source libs, dispatch to command |
| Commands | `commands/*.sh` | One command per file; calls lib functions |
| Store | `lib/store.sh` | Read/write identity JSON atomically |
| SSH | `lib/ssh.sh` | Replace only the gitid block in `~/.ssh/config` |
| UI | `lib/ui.sh` | Interactive prompts; gum or plain read fallback |
| Validate | `lib/validate.sh` | Input validation functions |
| Deps | `lib/deps.sh` | Check for required binaries |

---

## Data Schema

**File**: `~/.gitid/identities.json`
**Permissions**: `600` (owner read/write only)
**Directory**: `700`

```json
{
  "version": 1,
  "active": "work",
  "identities": [
    {
      "name": "Jay Work",
      "alias": "work",
      "email": "jay@company.com",
      "ssh_key": "/Users/jay/.ssh/id_ed25519_work"
    },
    {
      "name": "Jay Personal",
      "alias": "personal",
      "email": "jay@gmail.com",
      "ssh_key": "/Users/jay/.ssh/id_ed25519_personal"
    }
  ]
}
```

**Fields**:
- `version` — integer; allows future migrations without breaking existing installs
- `active` — alias of the last identity applied via `gitid switch`; `null` if none set
- `identities[].alias` — short unique identifier; used in SSH host names (`github-<alias>`);
  must match `^[a-zA-Z0-9_-]+$`

---

## Key Design Decisions

### 1. Atomic Writes

All writes to `identities.json` use a write-then-move pattern:

```
write content → /tmp/identities.json.tmp.XXXXXX  (unique temp file)
chmod 600 temp file
mv temp → ~/.gitid/identities.json               (atomic on same filesystem)
```

This prevents corruption if the process is interrupted mid-write.

### 2. Managed SSH Config Block

`gitid config-ssh` does **not** overwrite `~/.ssh/config`. It only replaces a clearly
delimited section it owns:

```
# BEGIN GITID MANAGED
# Do not edit this section manually — managed by gitid
Host github-work
  ...
Host github-personal
  ...
# END GITID MANAGED
```

Everything outside this block is left completely untouched. If no block exists yet,
it is appended. A timestamped backup is created in `~/.gitid/backups/` before any change.

### 3. No Shell Injection via jq

All variable interpolation into jq filters uses `--arg` / `--argjson`:

```bash
# Safe — value passed as data, not as code
jq --arg alias "$ALIAS" '.identities[] | select(.alias == $alias)'

# Unsafe (old v1 pattern — never do this)
jq ".[] | select(.alias==\"$ALIAS\")"
```

This fully prevents injection regardless of what characters the alias contains.

### 4. Input Validation Before Storage

Every value is validated before being written to the store:

| Field | Rules |
|-------|-------|
| name | Non-empty |
| alias | Non-empty, `^[a-zA-Z0-9_-]+$` |
| email | Non-empty, basic RFC format regex |
| ssh_key | Non-empty; warns if file does not exist (does not block add) |

### 5. Strict Error Modes

All scripts run with:
```bash
set -euo pipefail
```

- `-e` — exit on any command failure
- `-u` — exit on unset variable reference
- `-o pipefail` — exit if any command in a pipe fails

### 6. UI Abstraction

All interactive prompts go through `lib/ui.sh` functions (`ui_choose`, `ui_input`,
`ui_confirm`). When `gum` is installed, these use the rich TUI. When it is not,
they fall back to plain `read` / `echo`. This means gitid works in non-interactive
or CI environments without crashing.

### 7. Active Identity Pointer

The `active` field in the JSON store tracks which identity was last applied.
`gitid current` reads git config to show what git actually sees, and also shows
the stored active alias for cross-reference. This avoids the v1 bug where two
identities with the same email were indistinguishable.

### 8. File Permissions

| Path | Permissions |
|------|-------------|
| `~/.gitid/` | `700` |
| `~/.gitid/identities.json` | `600` |
| `~/.gitid/backups/` | `700` |
| `~/.ssh/config` | `600` |

---

## Library API Reference

### lib/store.sh

| Function | Description |
|----------|-------------|
| `store_ensure` | Creates store dir + file if missing; sets permissions |
| `store_read` | Reads and validates JSON; exits on corruption |
| `store_write <json>` | Validates then atomically writes JSON |
| `store_get_identities` | Returns `.identities` array as JSON |
| `store_find_by_alias <alias>` | Returns matching identity object or empty |
| `store_alias_exists <alias>` | Returns 0 if alias exists, 1 if not |
| `store_get_active` | Returns active alias string or empty |
| `store_set_active <alias>` | Sets `.active` in store |
| `store_add <name> <alias> <email> <key>` | Appends identity |
| `store_remove <alias>` | Removes identity; clears active if needed |

### lib/ui.sh

| Function | Description |
|----------|-------------|
| `ui_error <msg>` | Prints error to stderr |
| `ui_success <msg>` | Prints success message |
| `ui_info <msg>` | Prints info line |
| `ui_header <msg>` | Prints section header |
| `ui_choose <prompt> [items...]` | Interactive selector; returns chosen item |
| `ui_input <prompt> [default]` | Text input; returns entered value |
| `ui_confirm <prompt>` | Yes/no prompt; returns 0 for yes |

### lib/validate.sh

| Function | Description |
|----------|-------------|
| `validate_nonempty <value> <field>` | Fails if value is empty |
| `validate_email <email>` | Fails if not valid email format |
| `validate_alias <alias>` | Fails if not `^[a-zA-Z0-9_-]+$` |
| `validate_ssh_key <path>` | Fails if file does not exist |

### lib/ssh.sh

| Function | Description |
|----------|-------------|
| `ssh_backup` | Backs up `~/.ssh/config` to `~/.gitid/backups/` |
| `ssh_update_managed_block` | Replaces gitid block; creates/appends if none |

### lib/deps.sh

| Function | Description |
|----------|-------------|
| `deps_require_core` | Exits if `jq` or `git` missing |
| `deps_check_gum` | Returns 0 if `gum` is available |

---

## Extending gitid

### Adding a New Command

1. Create `commands/<name>.sh`
2. Add a case entry in `bin/gitid`:
   ```bash
   mycommand) source "$CMD_DIR/mycommand.sh" ;;
   ```
3. Add it to `commands/help.sh`
4. All lib functions are already available — no imports needed

### Hook Support

gitid checks for executable hook scripts before and after key operations:

```
~/.gitid/hooks/pre-switch   — runs before applying an identity
~/.gitid/hooks/post-switch  — runs after; receives alias as $1
```

If the file exists and is executable, it is sourced. This allows custom automation
(e.g. re-signing git commits, updating shell prompts).

---

## What v2 Fixes vs v1

| Issue | v1 | v2 |
|-------|----|----|
| Shell injection via jq | Unquoted `$NAME` in filter string | `--arg` flag always |
| SSH config destruction | `true > ~/.ssh/config` (wipes everything) | Managed block only |
| Corrupt store on write failure | Error output written to file | Atomic temp+mv |
| Store permissions | Default umask (0644) | Always `chmod 600` |
| Missing commands | `remove`, `test`, `import-ssh` not implemented | All implemented |
| No input validation | Any value accepted | Email, alias, non-empty |
| Unquoted loop variables | Word-splitting bugs on spaces | Process substitution + arrays |
| No active identity tracking | Email lookup (ambiguous) | Explicit `active` pointer |
| SSH config duplicates | Appended every run | Block replaced, not appended |
| No backup before SSH write | None | Timestamped backup always |
| Gum required | Hard exit if missing | Falls back to plain prompts |
