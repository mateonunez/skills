---
summary: Tmux configuration — TPM plugins, copy mode, session management, and Colemak pane navigation.
read_when: Configuring tmux, managing sessions, or debugging keybinding conflicts.
---

# Tmux Configuration

## Basics

- **Config file**: `~/.tmux.conf` + `~/.tmux.conf.local`
- **Prefix**: `C-a` (GNU-Screen compatible, replaces default `C-b`)
- **Plugin manager**: TPM (Tmux Plugin Manager)

## Key Bindings

### Session Management

| Key | Action |
|-----|--------|
| `C-a C-c` | Create new session |
| `C-a C-f` | Find session |

### Window Management

| Key | Action |
|-----|--------|
| `C-a c` | Create window |
| `C-a Space` | Next window |
| `C-a Bspace` | Previous window |
| `C-a Tab` | Last active window |

### Pane Management

| Key | Action |
|-----|--------|
| `C-a -` | Split horizontal |
| `C-a _` | Split vertical |
| `C-a h` | Select pane left |
| `C-a n` | Select pane down |
| `C-a e` | Select pane up |
| `C-a i` | Select pane right |
| `C-a H` | Resize pane left (2 cells) |
| `C-a N` | Resize pane down (2 cells) |
| `C-a E` | Resize pane up (2 cells) |
| `C-a I` | Resize pane right (2 cells) |

### Copy Mode (vi-style with Colemak)

| Key | Action |
|-----|--------|
| `Enter` | Enter copy mode |
| `v` | Begin selection |
| `h` | Cursor left |
| `n` | Cursor down |
| `e` | Cursor up |
| `i` | Cursor right |
| `C-c` | Copy to system clipboard (pbcopy) |
| `C-v` | Toggle rectangle selection |
| `j` | Copy selection to clipboard |

## Settings

```bash
# Mouse support
set -g mouse on

# History
set -g history-limit 300000

# Window/pane indexing starts at 1
set -g base-index 1
setw -g pane-base-index 1

# Auto-rename windows based on running command
setw -g automatic-rename on

# Renumber windows when one is closed
set -g renumber-windows on
```

## Plugins (via TPM)

| Plugin | Purpose |
|--------|---------|
| tpm | Plugin manager |
| tmux-net-speed | Network speed display |
| tmux-open | Open URLs/files from tmux |
| tmux-cpu | CPU usage display |
| tmux-resurrect | Session persistence across restarts |

### Installing Plugins

```bash
# Install TPM (if not already)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux: install plugins
# Press: C-a P (capital P)
```

## Local Overrides

`~/.tmux.conf.local` is sourced after the main config for machine-specific settings (not committed to dotfiles repo).
