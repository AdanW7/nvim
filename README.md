# Neovim Config Structure

This repo is organized by responsibility: core bootstrap and settings live at the top level, while plugin specs and feature-specific logic live under `lua/Adan/`.

## Top Level

- [`init.lua`](./init.lua) — entrypoint; loads [`lua/Adan/init.lua`](./lua/Adan/init.lua).
- [`.stylua.toml`](./.stylua.toml) — Lua formatter settings.
- [`.gitignore`](./.gitignore) — repo ignores.

## `lua/Adan/` Layout

- [`init.lua`](./lua/Adan/init.lua) — main module entry; loads core, lazy, autocommands, overrides, and user commands.
- [`core/`](./lua/Adan/core/) — baseline config (options, keymaps, compatibility shims).
- [`lazy.lua`](./lua/Adan/lazy.lua) — lazy.nvim bootstrap and import wiring.
- [`plugins/`](./lua/Adan/plugins/) — all plugin specs, grouped by category.
- [`autocommands/`](./lua/Adan/autocommands/) — general and plugin-specific autocommands.
- [`overrides/`](./lua/Adan/overrides/) — Advanced setup configuration (LSP, telescope, treesitter).
- [`UserCommands/`](./lua/Adan/UserCommands/) — custom user commands.
- [`dap/`](./lua/Adan/dap/) — DAP adapters/configurations and UI/keymaps.
- [`snacks/`](./lua/Adan/snacks/) — Snacks-specific config modules.
- [`utils/`](./lua/Adan/utils/) — small helper modules used across the config.

## `plugins/` Categories

Each folder holds lazy.nvim specs for that feature set.

- [`plugins/completion/`](./lua/Adan/plugins/completion/) — completion engine + sources.
- [`plugins/dap/`](./lua/Adan/plugins/dap/) — DAP-related plugins.
- [`plugins/formatting/`](./lua/Adan/plugins/formatting/) — formatters and formatting orchestration.
- [`plugins/git/`](./lua/Adan/plugins/git/) — Git UI and integrations.
- [`plugins/keybinds/`](./lua/Adan/plugins/keybinds/) — which-key and keymap helpers.
- [`plugins/lazy/`](./lua/Adan/plugins/lazy/) — lazy.nvim related helpers.
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
3. [`lazy.lua`](./lua/Adan/lazy.lua) (plugin manager bootstrap)
3. [`pack.lua`](./lua/Adan/pack.lua) (built in plugin manager)
4. [`autocommands/`](./lua/Adan/autocommands/)
6. [`UserCommands/`](./lua/Adan/UserCommands/)

## Notes

- Plugin specs are grouped to make it easy to find and reason about a feature area.
- When adding a new feature, prefer placing its plugin spec in the relevant `plugins/<category>/` folder and any runtime logic in [`autocommands/`](./lua/Adan/autocommands/) or [`utils/`](./lua/Adan/utils/) as needed.

| Column1 | Column2 | Column3 | Column4 | Column5 |
| ------- | ------- | ------- | ------- | ------- |
| Item1.1 | Item2.1 | Item3.1 | Item4.1 | Item5.1 |
| a       |         |         |         |         |
