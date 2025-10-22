---@brief
---
--- https://github.com/Feel-ix-343/markdown-oxide
---
--- Editor Agnostic PKM: you bring the text editor and we
--- bring the PKM.
---
--- Inspired by and compatible with Obsidian.
---
--- Check the readme to see how to properly setup.
---@type vim.lsp.Config
return {
  root_markers = { '.git', '.obsidian', '.moxide.toml' },
  filetypes = { 'markdown' },
  cmd = { 'markdown-oxide' },
  capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  }),
  on_attach = function(client, bufnr)
    vim.lsp.codelens.enable(true)

    if client.name == 'markdown_oxide' then
      vim.api.nvim_create_user_command('Daily', function(args)
        client:exec_cmd({
          title = 'Open daily note',
          command = 'jump',
          arguments = { args.args },
        }, { bufnr = bufnr })
      end, { desc = 'Open daily note (natural language)', nargs = '*' })

      local function rewrite_wikilinks(from, to)
        local root = vim.lsp.get_clients({ name = 'markdown_oxide' })[1].root_dir
        local files = vim.fn.glob(root .. '/**/*.md', false, true)
        local count = 0
        for _, path in ipairs(files) do
          local lines = vim.fn.readfile(path)
          local changed = false
          for i, line in ipairs(lines) do
            local new_line = line:gsub('%[%[(.-)%]%]', function(inner)
              return '[['
                .. inner:gsub(from, function()
                  return to
                end)
                .. ']]'
            end)
            if new_line ~= line then
              lines[i] = new_line
              changed = true
            end
          end
          if changed then
            vim.fn.writefile(lines, path)
            count = count + 1
          end
        end
        vim.notify(string.format('Normalized wikilinks in %d files', count), vim.log.levels.INFO)
      end

      vim.api.nvim_create_user_command('WikilinksUnix', function()
        rewrite_wikilinks('\\', '/')
      end, { nargs = 0, desc = 'Normalize backslashes to forward slashes in wikilinks (Unix)' })

      vim.api.nvim_create_user_command('WikilinksWindows', function()
        rewrite_wikilinks('/', '\\')
      end, {
        nargs = 0,
        desc = 'Normalize forward slashes to backslashes in wikilinks (Windows)',
      })
    end
  end,
}
