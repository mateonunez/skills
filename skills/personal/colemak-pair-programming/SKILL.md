---
name: colemak-pair-programming
description: When pair-programming on my machine, navigation keys are Colemak hnei, not QWERTY hjkl. Don't suggest hjkl mappings, don't paste default vim chord docs, and don't recommend keybindings that assume QWERTY home row. Use when proposing keybindings, vim chords, tmux shortcuts, or anything keyboard-layout-sensitive on my dotfiles.
---

# Colemak pair-programming

I type Colemak. Every navigation tool on my machine is remapped: `h` left, `n` down, `e` up, `i` right. If you suggest `hjkl` mappings, paste vim docs that assume QWERTY, or recommend a tmux pane-switch chord using `C-h C-j C-k C-l`, the suggestion is wrong on my keyboard.

This skill is a heads-up, not a tutorial. References hold the full mapping if you need them.

## When this skill is active

You are about to:

- Suggest a vim/Neovim keymap
- Suggest a tmux pane or window chord
- Recommend a fzf, telescope, or LSP keybinding
- Paste documentation that assumes QWERTY home row

## The substitutions

```
QWERTY → Colemak
  h → h    (same)
  j → n    (down)
  k → e    (up)
  l → i    (right)
```

So `<C-w>j` (move to window below) is `<C-w>n` on my machine. `<leader>k` is `<leader>e`.

## Anti-patterns

- Telling me to "press `j` to scroll down" in Neovim — I press `n`.
- Generating a vim cheatsheet from public docs without translating.
- Recommending a plugin that hardcodes `hjkl` and isn't configurable.
- Suggesting `C-h`/`C-j`/`C-k`/`C-l` for tmux pane navigation — my prefix is `C-a` and the keys are `h`/`n`/`e`/`i`.

## What's safe

Letters that aren't navigation (e.g. `<leader>ff` for telescope find-files) are layout-independent — Colemak only differs from QWERTY on letter positions, not on chord composition. Safe to suggest as-is.

## References

- [core-colemak](references/core-colemak.md) — complete remapping table across tools
- [features-neovim](references/features-neovim.md) — NvChad + Lazy.nvim setup
- [features-tmux](references/features-tmux.md) — TPM, prefix, pane chords
- [features-zsh](references/features-zsh.md) — oh-my-zsh, aliases, p10k

If you're not sure whether a chord is layout-sensitive, ask — don't guess.
