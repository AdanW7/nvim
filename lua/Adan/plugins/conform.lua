local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/stevearc/conform.nvim' }, { load = true, confirm = false })

  require('conform').setup({
    formatters_by_ft = {
      toml = { 'taplo' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      lua = { 'stylua' },
      rust = { 'rustfmt', lsp_format = 'fallback' },
      go = { 'goimports', 'gofmt' },
      zig = { 'zigfmt' },
      python = {
        'ruff_fix',
        'ruff_format',
        'ruff_organize_imports',
      },
      ocaml = { 'ocamlformat' },
      gleam = { 'gleam' },
      markdown = { 'prettierd' },
    },
    default_format_opts = {
      lsp_format = 'fallback',
    },
    formatters = {
      gleam = {
        command = 'gleam',
        args = { 'format', '--stdin' },
        stdin = true,
      },
      prettierd = {
        env = {
          PRETTIERD_DEFAULT_CONFIG = vim.fn.expand('~/.config/nvim/prettier-markdown.json'),
        },
      },
    },
    notify_on_error = true,
    notify_no_formatters = true,
  })

  vim.keymap.set({ 'n', 'v' }, '<leader>lf', function()
    require('conform').format({ async = true, lsp_fallback = true })
  end, { desc = 'LSP Format' })
end

return M
