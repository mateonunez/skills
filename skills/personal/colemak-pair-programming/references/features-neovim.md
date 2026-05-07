---
summary: Neovim setup — NvChad framework, Lazy.nvim plugins, LSP config, Treesitter, and custom mappings.
read_when: Configuring Neovim, adding plugins, or debugging LSP/Treesitter issues.
---

# Neovim Configuration

## Framework: NvChad

- **Base**: NvChad (provides base46 themes, UI components, defaults)
- **Plugin manager**: Lazy.nvim (lazy-loading, lockfile)
- **Config location**: `~/.config/nvim/`

## Init Flow

```lua
-- init.lua
require "core"                                    -- NvChad core
require("core.utils").load_mappings()             -- Load keybindings
require "plugins"                                  -- Lazy.nvim plugin specs
vim.cmd [[source ~/.config/nvim/lua/custom/keybindings.vim]]  -- Colemak remaps
```

## Directory Structure

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lazy-lock.json              # Plugin lockfile
├── .stylua.toml                # Lua formatter config
└── lua/
    ├── core/
    │   ├── bootstrap.lua       # Lazy.nvim bootstrap
    │   ├── default_config.lua  # NvChad defaults
    │   ├── init.lua           # Core setup
    │   ├── mappings.lua       # Default keybindings
    │   └── utils.lua          # Helper functions
    ├── plugins/
    │   └── init.lua           # Plugin specifications
    └── custom/
        ├── chadrc.lua         # NvChad customization
        ├── highlights.lua     # Custom highlight groups
        ├── init.lua           # Custom init
        ├── keybindings.vim    # Colemak remaps (see core-colemak.md)
        ├── mappings.lua       # Additional mappings
        ├── plugins.lua        # Plugin overrides
        └── configs/
            ├── lspconfig.lua  # LSP server setup
            ├── null-ls.lua    # Formatting/linting
            └── overrides.lua  # Plugin config overrides
```

## Key Mappings (NvChad defaults)

### Normal Mode

| Key | Action |
|-----|--------|
| `Esc` | Clear search highlights (`:noh`) |
| `C-h/j/k/l` | Navigate between windows |
| `C-s` | Save file |
| `C-c` | Copy entire file |

### LSP

| Key | Action |
|-----|--------|
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gi` | Go to implementation |
| `gr` | List references |
| `<leader>ca` | Code action |
| `<leader>fm` | Format file |

### Telescope

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fw` | Live grep (find word) |
| `<leader>fb` | Browse buffers |
| `<leader>fh` | Help tags |
| `<leader>fo` | Old (recent) files |
| `<leader>fz` | Current buffer fuzzy find |

### NvimTree

| Key | Action |
|-----|--------|
| `C-n` | Toggle NvimTree |
| `<leader>e` | Focus NvimTree |

### Terminal

| Key | Action |
|-----|--------|
| `A-i` | Float terminal toggle |
| `A-h` | Horizontal terminal toggle |
| `A-v` | Vertical terminal toggle |

## Custom Mappings

```lua
-- custom/mappings.lua
-- Enter command mode with ; (no Shift needed)
M.general = {
  n = {
    [";"] = { ":", "enter command mode" },
  },
}
```

## LSP Configuration

```lua
-- custom/configs/lspconfig.lua
local servers = { "html", "cssls", "tsserver", "clangd" }

-- All servers configured via mason-lspconfig
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end
```

## Plugins (custom/plugins.lua)

- **nvim-lspconfig** + **null-ls.nvim** — LSP and formatting
- **mason.nvim** — LSP/formatter installer
- **nvim-treesitter** — Syntax highlighting and code understanding
- **nvim-tree.lua** — File explorer
- **better-escape.nvim** — Fast insert mode exit

## StyLua Config

```toml
# .stylua.toml
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
```
