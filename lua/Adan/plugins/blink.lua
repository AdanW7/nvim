local M = {}
function M.setup()
  vim.pack.add({
    { src = 'https://github.com/saghen/blink.lib', version = 'main' },
    { src = 'https://github.com/saghen/blink.cmp', version = 'main' },
    'https://github.com/rafamadriz/friendly-snippets',
    'https://github.com/L3MON4D3/LuaSnip',
  }, { load = true, confirm = false })
  require('blink.cmp').setup({
    keymap = {
      ['<M-CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = { 'select_next', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
    },
    appearance = {
      nerd_font_variant = 'mono',
      use_nvim_cmp_as_default = true,
    },
    completion = {
      accept = {
        auto_brackets = { enabled = true },
      },
      trigger = {
        prefetch_on_insert = true,
        show_on_keyword = true,
      },
      menu = {
        auto_show = true,
        auto_show_delay_ms = 0,
        draw = {
          columns = { { 'kind_icon' }, { 'label', gap = 1 } },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      ghost_text = {
        enabled = vim.g.ai_cmp,
      },
    },
    signature = { enabled = true },
    sources = {
      per_filetype = {},
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        lsp = {
          async = true,
          timeout_ms = 250,
        },
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },
    fuzzy = {
      implementation = 'prefer_rust',
      sorts = { 'score', 'sort_text', 'label' },
    },
  })
end
return M
