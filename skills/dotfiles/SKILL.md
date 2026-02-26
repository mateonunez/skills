---
name: dotfiles
description: Knowledge pack for Mateo's dev environment — Colemak keyboard layout, Neovim (NvChad), Tmux, and Zsh configuration.
metadata:
  author: mateonunez
  version: 1.0.0
  source: https://github.com/mateonunez/dotfiles
  stack: Neovim (NvChad + Lazy.nvim), Tmux (TPM), Zsh (oh-my-zsh + p10k)
---

# dotfiles

Development environment configuration centered around the Colemak keyboard layout. All navigation tools (Neovim, Tmux, Vim) are remapped from QWERTY `hjkl` to Colemak `hnei`.

## Preferences

- **Keyboard**: Colemak — `h`=left, `n`=down, `e`=up, `i`=right (replaces QWERTY `hjkl`)
- **Editor**: Neovim with NvChad framework + Lazy.nvim plugin manager
- **Terminal multiplexer**: Tmux with TPM + `C-a` prefix
- **Shell**: Zsh with oh-my-zsh + Powerlevel10k theme
- **OS**: macOS (Darwin)

## References

| Category | Reference | Description |
|----------|-----------|-------------|
| Core | [core-colemak](references/core-colemak.md) | Complete Colemak remapping table across all tools |
| Features | [features-neovim](references/features-neovim.md) | NvChad setup, Lazy.nvim, LSP, Treesitter |
| Features | [features-tmux](references/features-tmux.md) | TPM plugins, copy mode, session/pane management |
| Features | [features-zsh](references/features-zsh.md) | oh-my-zsh, aliases, env setup, tool managers |

## Quick Reference

```
Colemak Navigation (used everywhere):
  h = left    n = down    e = up    i = right

Tmux:
  C-a          prefix
  C-a -        split horizontal
  C-a _        split vertical
  C-a Space    next window
  C-a h/n/e/i  navigate panes

Neovim (NvChad):
  ;            enter command mode (no Shift needed)
  C-n          toggle NvimTree
  leader+ff    find files (Telescope)
  leader+fw    live grep (Telescope)

Zsh shortcuts:
  cl           clear + ls -lah
  c_ait        cd ~/source/mateonunez/ait
  c_mn         cd ~/source/mateonunez/
  wtf [port]   check what process uses a port (default 3000)
```
