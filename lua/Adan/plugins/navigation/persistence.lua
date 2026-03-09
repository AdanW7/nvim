local uv = vim.uv or vim.loop

---@return { session: string, dir: string, branch?: string }[]
local function session_items(persistence)
  ---@type { session: string, dir: string, branch?: string }[]
  local items = {}
  local have = {} ---@type table<string, boolean>
  local sessions = persistence.list()
  for _, session in ipairs(sessions) do
    if uv.fs_stat(session) then
      local file = vim.fn.fnamemodify(session, ':t:r')
      local dir = unpack(vim.split(file, '%%', { plain = true }))
      dir = dir:gsub('%%', '/')
      if jit.os:find('Windows') then
        dir = dir:gsub('^(%w)/', '%1:/')
      end
      if not have[dir] then
        have[dir] = true
        items[#items + 1] = { session = session, dir = dir }
      end
    end
  end
  return items
end

local function load_session(persistence, item)
  if not (item and item.dir) then
    return
  end
  vim.fn.chdir(item.dir)
  persistence.load()
end

local function session_select_session()
  local ok_persistence, persistence = pcall(require, 'persistence')
  if not ok_persistence then
    return
  end
  local items = session_items(persistence)

  local ok_telescope, pickers = pcall(require, 'telescope.pickers')
  if ok_telescope then
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers
      .new({}, {
        prompt_title = 'Persistence Sessions',
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return {
              value = item,
              display = vim.fn.fnamemodify(item.dir, ':p:~'),
              ordinal = item.dir,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          local function on_confirm()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection and selection.value then
              load_session(persistence, selection.value)
            end
          end
          map('i', '<CR>', on_confirm)
          map('n', '<CR>', on_confirm)
          return true
        end,
      })
      :find()
    return
  end

  local ok_snacks, snacks_select = pcall(require, 'snacks.picker.select')
  if ok_snacks then
    snacks_select.select(items, {
      prompt = 'Select a session:',
      format_item = function(item)
        return vim.fn.fnamemodify(item.dir, ':p:~')
      end,
    }, function(item)
      load_session(persistence, item)
    end)
    return
  end

  persistence.select()
end

---@type LazySpec
return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  keys = {
    {
      '<leader>ss',
      function()
        require('persistence').load()
      end,
      desc = 'Restore Session for the Current Directory',
    },
    {
      '<leader>sS',
      function()
        require('persistence').select()
      end,
      desc = 'Select a Session to Load',
    },
    {
      '<leader>st',
      function()
        session_select_session()
      end,
      desc = 'Session Picker (Telescope/Snacks)',
    },
    {
      '<leader>sl',
      function()
        require('persistence').load({ last = true })
      end,
      desc = 'Restore Last Session',
    },
    {
      '<leader>sd',
      function()
        require('persistence').stop()
      end,
      desc = "Don't Save Current Session",
    },
  },
}
