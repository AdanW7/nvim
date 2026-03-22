---@type Adan.LazySpec
return {
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = {
    'rafamadriz/friendly-snippets',
    'L3MON4D3/LuaSnip',
    'xzbdmw/colorful-menu.nvim',
  },

  -- use a release tag to download pre-built binaries
  version = '1.*',
  opts = {
    keymap = {
      -- preset = "enter",
      ['<M-CR>'] = { 'accept', 'fallback' }, -- use enter to accept
      ['<Tab>'] = { 'select_next', 'fallback' }, --use tab to select next option
      ['<S-Tab>'] = { 'select_prev', 'fallback' }, --use shift tab to go back an option
      ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      nerd_font_variant = 'mono',

      -- sets the fallback highlight groups to nvim-cmp's highlight groups
      -- useful for when your theme doesn't support blink.cmp
      -- will be removed in a future release, assuming themes add support
      use_nvim_cmp_as_default = true,
    },

    completion = {
      accept = {
        -- experimental auto-brackets support
        auto_brackets = {
          enabled = true,
        },
      },
      menu = {
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

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      per_filetype = {},
      -- compat = {},
      default = {
        'lsp',
        'path',
        'snippets',
        'buffer',
      },
      providers = {},
    },

    fuzzy = {
      implementation = 'prefer_rust_with_warning',
      sorts = {
        'score', -- Primary sort: by fuzzy matching score
        'sort_text', -- Secondary sort: by sortText field if scores are equal
        'label', -- Tertiary sort: by label if still tied
      },
    },
  },
  opts_extend = { 'sources.default' },
}
