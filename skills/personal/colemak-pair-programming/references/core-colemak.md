---
summary: Complete Colemak keyboard remapping table across Neovim, Tmux, and Vim.
read_when: Understanding navigation keybindings, configuring new tools, or debugging key conflicts.
---

# Colemak Key Remappings

## Core Navigation (HNEI = HJKL)

The fundamental remapping across all tools:

| Colemak Key | QWERTY Equivalent | Action |
|------------|-------------------|--------|
| `h` | `h` | Left (unchanged) |
| `n` | `j` | Down |
| `e` | `k` | Up |
| `i` | `l` | Right |

## Neovim Full Remap Table

From `.config/nvim/lua/custom/keybindings.vim`:

| Colemak | QWERTY Function | Description |
|---------|-----------------|-------------|
| `d` | `g` | Go command prefix |
| `D` | `G` | Go to end of file |
| `e` | `k` | Up |
| `E` | `K` | Keyword lookup |
| `f` | `e` | End of word |
| `F` | `E` | End of WORD |
| `g` | `t` | Till character |
| `G` | `T` | Till character (backward) |
| `i` | `l` | Right |
| `I` | `L` | Bottom of screen |
| `j` | `y` | Yank (copy) |
| `J` | `Y` | Yank line |
| `k` | `n` | Next search match |
| `K` | `N` | Previous search match |
| `l` | `u` | Undo |
| `L` | `U` | Undo line |
| `n` | `j` | Down |
| `N` | `J` | Join lines |
| `o` | `p` | Paste after |
| `O` | `P` | Paste before |
| `p` | `r` | Replace character |
| `P` | `R` | Replace mode |
| `r` | `s` | Substitute |
| `R` | `S` | Substitute line |
| `s` | `d` | Delete |
| `S` | `D` | Delete to end of line |
| `t` | `f` | Find character |
| `T` | `F` | Find character (backward) |
| `u` | `i` | Insert mode |
| `U` | `I` | Insert at beginning of line |
| `y` | `o` | Open line below |
| `Y` | `O` | Open line above |

### Compound Remaps

| Colemak | QWERTY | Description |
|---------|--------|-------------|
| `dd` | `gg` | Go to start of file |
| `df` | `ge` | End of previous word |
| `dF` | `gE` | End of previous WORD |
| `jj` | `yy` | Yank whole line |
| `jf` | `yf` | Yank to character |
| `jF` | `yF` | Yank to character (backward) |
| `gg` | `tt` | Till character (repeat) |
| `gG` | `tT` | Till character backward (repeat) |

### System Clipboard

| Keys | Action |
|------|--------|
| `Y` (normal) | Yank to system clipboard (`"+y`) |
| `Y` (visual) | Yank selection to system clipboard |
| `yY` | Yank line to system clipboard (`^"+y$`) |
| `D` (normal) | Delete to system clipboard (`"+d`) |
| `D` (visual) | Delete selection to system clipboard |
| `dD` | Delete line to system clipboard (`^"+d$`) |

## Tmux Remappings

From `.tmux.conf`:

### Pane Navigation

```
bind -r h select-pane -L   # Left
bind -r n select-pane -D   # Down
bind -r e select-pane -U   # Up
bind -r i select-pane -R   # Right
```

### Pane Resizing

```
bind -r H resize-pane -L 2
bind -r N resize-pane -D 2
bind -r E resize-pane -U 2
bind -r I resize-pane -R 2
```

### Copy Mode (vi keys)

```
bind -T copy-mode-vi n send -X cursor-down
bind -T copy-mode-vi e send -X cursor-up
bind -T copy-mode-vi i send -X cursor-right
bind -T copy-mode-vi h send -X cursor-left
bind -T copy-mode-vi j send -X copy-pipe "pbcopy"  # Yank (j = y in Colemak)
```

## Quick Reference Card

```
         e (up)
          ↑
h (left) ← → i (right)
          ↓
         n (down)

Mnemonic: H stays, N-E-I follow Colemak home row positions
```
