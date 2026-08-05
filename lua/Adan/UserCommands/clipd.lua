local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

M.config = {
  limit = 500,
  clipd_cmd = 'clipd',
  timeout_ms = 5000,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

--- Collapse whitespace and truncate for a single-line display.
local function make_display(entry)
  local collapsed = entry.content:gsub('%s+', ' ')
  local max_len = 90
  if #collapsed > max_len then
    collapsed = collapsed:sub(1, max_len) .. '…'
  end
  return string.format('[%s] %s', entry.created_at:sub(1, 19), collapsed)
end

--- Copy the given clip's content back onto the system clipboard
local function copy_to_clipboard(entry)
  vim.fn.setreg('"', entry.content)
  vim.fn.setreg('+', entry.content)
  local preview = entry.content:gsub('%s+', ' ')
  if #preview > 50 then
    preview = preview:sub(1, 50) .. '…'
  end
  vim.notify('clipd: copied to clipboard — ' .. preview)
end

--- Build and open the Telescope picker over an already-fetched entry list.
local function open_picker(entries)
  if vim.tbl_isempty(entries) then
    vim.notify('clipd: no clipboard history yet (is `clipd daemon` running?)', vim.log.levels.WARN)
    return
  end

  pickers
    .new({}, {
      prompt_title = 'Clipboard History',
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display(entry),
            ordinal = entry.content, -- fuzzy-match against full content, not just the preview
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function select_and_copy()
          -- Grab the selection *before* closing the picker; action_state
          -- becomes unreliable once the prompt buffer is torn down.
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          copy_to_clipboard(selection.value)
        end

        -- <CR> in either mode just restores the clip to the clipboard.
        map('i', '<CR>', select_and_copy)
        map('n', '<CR>', select_and_copy)
        return true
      end,
    })
    :find()
end

--- Fetch clip history asynchronously via `clipd list --json` and open the picker once it lands.
function M.history()
  vim.system(
    { M.config.clipd_cmd, 'list', '--json', '--limit', tostring(M.config.limit) },
    { text = true, timeout = M.config.timeout_ms },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          local reason = result.signal ~= 0 and ('killed by signal ' .. result.signal)
            or (result.stderr ~= '' and result.stderr)
            or ('exited ' .. result.code)
          vim.notify(
            'clipd: `' .. M.config.clipd_cmd .. ' list --json` failed: ' .. reason,
            vim.log.levels.ERROR
          )
          return
        end

        local decoded_ok, entries = pcall(vim.json.decode, result.stdout or '')
        if not decoded_ok then
          vim.notify('clipd: could not parse JSON output', vim.log.levels.ERROR)
          return
        end

        open_picker(entries)
      end)
    end
  )
end

vim.api.nvim_create_user_command('ClipdHistory', M.history, {})

return M
