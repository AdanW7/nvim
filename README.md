# Neovim Config Structure

This repo is organized by responsibility: core bootstrap and settings live at the top level, while plugin modules and feature-specific logic live under `lua/Adan/`.

## Top Level

- [`init.lua`](./init.lua) — entrypoint; loads [`lua/Adan/init.lua`](./lua/Adan/init.lua).
- [`.stylua.toml`](./.stylua.toml) — Lua formatter settings.
- [`.gitignore`](./.gitignore) — repo ignores.

## `lua/Adan/` Layout

- [`init.lua`](./lua/Adan/init.lua) — main module entry; loads core, pack, autocommands, overrides, and user commands.
- [`core/`](./lua/Adan/core/) — baseline config (options, keymaps, compatibility shims).
- [`pack.lua`](./lua/Adan/pack.lua) — `vim.pack` bootstrap and plugin setup wiring.
- [`plugins/`](./lua/Adan/plugins/) — plugin setup modules, grouped by category.
- [`autocommands/`](./lua/Adan/autocommands/) — general and plugin-specific autocommands.
- [`overrides/`](./lua/Adan/overrides/) — Advanced setup configuration (LSP, telescope, treesitter).
- [`UserCommands/`](./lua/Adan/UserCommands/) — custom user commands.
- [`dap/`](./lua/Adan/dap/) — DAP adapters/configurations and UI/keymaps.
- [`snacks/`](./lua/Adan/snacks/) — Snacks-specific config modules.
- [`utils/`](./lua/Adan/utils/) — small helper modules used across the config.

## `plugins/` Categories

Each folder holds imperative plugin setup modules for that feature set.

- [`plugins/completion/`](./lua/Adan/plugins/completion/) — completion engine + sources.
- [`plugins/dap/`](./lua/Adan/plugins/dap/) — DAP-related plugins.
- [`plugins/formatting/`](./lua/Adan/plugins/formatting/) — formatters and formatting orchestration.
- [`plugins/git/`](./lua/Adan/plugins/git/) — Git UI and integrations.
- [`plugins/keybinds/`](./lua/Adan/plugins/keybinds/) — which-key and keymap helpers.
- [`plugins/lsp/`](./lua/Adan/plugins/lsp/) — LSP setup and related tools.
- [`plugins/markdown/`](./lua/Adan/plugins/markdown/) — Markdown-specific tooling.
- [`plugins/mini/`](./lua/Adan/plugins/mini/) — mini.nvim modules.
- [`plugins/navigation/`](./lua/Adan/plugins/navigation/) — navigation/session/project helpers.
- [`plugins/snacks/`](./lua/Adan/plugins/snacks/) — snacks.nvim configuration modules.
- [`plugins/snippets/`](./lua/Adan/plugins/snippets/) — snippet engines/snippet sources.
- [`plugins/theme/`](./lua/Adan/plugins/theme/) — colorscheme, statusline, UI theming.

## Load Order (High Level)

1. [`init.lua`](./init.lua) → [`lua/Adan/init.lua`](./lua/Adan/init.lua)
2. [`core/`](./lua/Adan/core/) (options + keymaps)
3. [`pack.lua`](./lua/Adan/pack.lua) (`vim.pack` plugin manager + setup)
4. [`autocommands/`](./lua/Adan/autocommands/)
5. [`UserCommands/`](./lua/Adan/UserCommands/)

## Notes

- Plugin setup modules are grouped to make it easy to find and reason about a feature area.
- When adding a new feature, prefer placing its plugin setup module in the relevant `plugins/<category>/` folder and any runtime logic in [`autocommands/`](./lua/Adan/autocommands/) or [`utils/`](./lua/Adan/utils/) as needed.
