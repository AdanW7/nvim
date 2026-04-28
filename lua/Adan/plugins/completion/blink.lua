local M = {}

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/saghen/blink.lib', version = 'main' },
    { src = 'https://github.com/saghen/blink.cmp', version = 'main' },
    'https://github.com/rafamadriz/friendly-snippets',
    { src = 'https://github.com/L3MON4D3/LuaSnip', version = 'master' },
    'https://github.com/xzbdmw/colorful-menu.nvim',
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
          components = {
            label = {
              text = function(ctx)
                local cm = require('colorful-menu')
                local client = vim.lsp.get_client_by_id(ctx.item.client_id)
                local ls = client and client.name or nil
                if ls == 'pyrefly' then
                  ls = 'pylsp'
                end
                local highlights_info = cm.highlights(ctx.item, ls)
                if highlights_info ~= nil then
                  return highlights_info.text
                end
                return ctx.label
              end,
              highlight = function(ctx)
                local cm = require('colorful-menu')
                local client = vim.lsp.get_client_by_id(ctx.item.client_id)
                local ls = client and client.name or nil
                if ls == 'pyrefly' then
                  ls = 'pylsp'
                end

                local highlights = {}
                local highlights_info = cm.highlights(ctx.item, ls)
                if highlights_info ~= nil then
                  for _, info in ipairs(highlights_info.highlights or {}) do
                    table.insert(highlights, {
                      info.range[1],
                      info.range[2],
                      group = info[1],
                    })
                  end
                end

                for _, idx in ipairs(ctx.label_matched_indices) do
                  table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
                end
                return highlights
              end,
            },
          },
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
      },
    },
    fuzzy = {
      implementation = 'prefer_rust',
      sorts = { 'score', 'sort_text', 'label' },
    },
  })
end

return M
