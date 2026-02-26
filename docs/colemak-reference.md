---
summary: Quick reference card for Colemak keyboard navigation across all tools.
read_when: Configuring keybindings for a new tool or remembering Colemak nav keys.
---

# Colemak Quick Reference

## Core Navigation

```
         e (up)
          ↑
h (left) ← → i (right)
          ↓
         n (down)
```

**HNEI replaces HJKL** in all tools.

## Tool-Specific Bindings

### Neovim

| Colemak | Action |
|---------|--------|
| `h/n/e/i` | Left/Down/Up/Right |
| `u` | Enter insert mode (was `i`) |
| `U` | Insert at line start (was `I`) |
| `s` | Delete (was `d`) |
| `j` | Yank/copy (was `y`) |
| `jj` | Yank whole line (was `yy`) |
| `l` | Undo (was `u`) |
| `k` | Next search match (was `n`) |
| `y` | Open line below (was `o`) |
| `o` | Paste after (was `p`) |
| `;` | Enter command mode (no Shift) |

### Tmux (prefix: C-a)

| Key | Action |
|-----|--------|
| `C-a h/n/e/i` | Navigate panes (L/D/U/R) |
| `C-a H/N/E/I` | Resize panes (L/D/U/R) |
| `C-a -` | Split horizontal |
| `C-a _` | Split vertical |
| `C-a Space` | Next window |
| `C-a Tab` | Last window |

### Tmux Copy Mode

| Key | Action |
|-----|--------|
| `h/n/e/i` | Navigate (L/D/U/R) |
| `v` | Begin selection |
| `j` | Yank to clipboard |
| `C-c` | Copy to pbcopy |

## Mnemonic

The Colemak home row is: `a r s t d h n e i o`

Navigation keys `h n e i` sit on the right side of the home row, in the same relative positions as QWERTY's `h j k l`.

## Adding Colemak to New Tools

When configuring a new tool with vi-style keybindings, apply these remaps:

```
h → h  (left, unchanged)
j → n  (down)
k → e  (up)
l → i  (right)
```

Then remap displaced keys:
- `n` (next search) → `k`
- `e` (end of word) → `f`
- `i` (insert) → `u`
