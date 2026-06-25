-- ============================================================
-- scope (vendored from https://github.com/tiagovla/scope.nvim)
-- ============================================================
local scope = {}
do
  local config = {
    hooks = {
      pre_tab_enter = nil,
      post_tab_enter = nil,
      pre_tab_leave = nil,
      post_tab_leave = nil,
      pre_tab_close = nil,
      post_tab_close = nil,
    },
  }
  local utils = {}
  local function is_valid(buf_num)
    if not buf_num or buf_num < 1 then
      return false
    end
    return vim.api.nvim_get_option_value('buflisted', { buf = buf_num })
      and vim.api.nvim_buf_is_valid(buf_num)
  end
  function utils.get_valid_buffers()
    local ids = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if is_valid(buf) then
        ids[#ids + 1] = buf
      end
    end
    return ids
  end
  function utils.open_bufs_if_closed(buf_names)
    for _, buf_name in pairs(buf_names) do
      local buf_is_open = false
      for _, buf_num in pairs(vim.api.nvim_list_bufs()) do
        if buf_name ~= '' and buf_name == vim.api.nvim_buf_get_name(buf_num) then
          buf_is_open = true
          break
        end
      end
      if not buf_is_open and buf_name ~= '' then
        vim.api.nvim_command('badd ' .. buf_name)
        vim.api.nvim_set_option_value('buflisted', false, { buf = vim.fn.bufnr(buf_name) })
      end
    end
  end
  function utils.get_buffer_ids(buf_names)
    utils.open_bufs_if_closed(buf_names)
    local buf_ids = {}
    for _, buf_name in pairs(buf_names) do
      for _, buf_num in pairs(vim.api.nvim_list_bufs()) do
        if buf_name ~= '' and buf_name == vim.api.nvim_buf_get_name(buf_num) then
          buf_ids[#buf_ids + 1] = buf_num
        end
      end
    end
    return buf_ids
  end
  local core = { cache = {}, last_tab = 0 }
  function core.on_tab_new_entered()
    vim.api.nvim_set_option_value('buflisted', true, { buf = 0 })
  end
  function core.on_tab_enter()
    if config.hooks.pre_tab_enter then
      config.hooks.pre_tab_enter()
    end
    local tab = vim.api.nvim_get_current_tabpage()
    local buf_nums = core.cache[tab]
    if buf_nums then
      for _, k in pairs(buf_nums) do
        if vim.api.nvim_buf_is_valid(k) then
          vim.api.nvim_set_option_value('buflisted', true, { buf = k })
        end
      end
    end
    if config.hooks.post_tab_enter then
      config.hooks.post_tab_enter()
    end
  end
  function core.on_tab_leave()
    if config.hooks.pre_tab_leave then
      config.hooks.pre_tab_leave()
    end
    local tab = vim.api.nvim_get_current_tabpage()
    core.cache[tab] = utils.get_valid_buffers()
    for _, k in pairs(core.cache[tab]) do
      vim.api.nvim_set_option_value('buflisted', false, { buf = k })
    end
    core.last_tab = tab
    if config.hooks.post_tab_leave then
      config.hooks.post_tab_leave()
    end
  end
  function core.on_tab_closed()
    if config.hooks.pre_tab_close then
      config.hooks.pre_tab_close()
    end
    core.cache[core.last_tab] = nil
    if config.hooks.post_tab_close then
      config.hooks.post_tab_close()
    end
  end
  function core.revalidate()
    local tab = vim.api.nvim_get_current_tabpage()
    core.cache[tab] = utils.get_valid_buffers()
  end
  function core.print_summary()
    print('tab buf name')
    for tab, buf_item in pairs(core.cache) do
      for _, buf in pairs(buf_item) do
        print(tab .. ' ' .. buf .. ' ' .. vim.api.nvim_buf_get_name(buf))
      end
    end
  end
  function core.close_buffer(opts)
    opts = opts or {}
    local current_tab = vim.api.nvim_get_current_tabpage()
    local current_buf = opts.buf or vim.api.nvim_get_current_buf()
    core.revalidate()
    local buffers_in_current_tab = core.cache[current_tab]
    local buffer_exists_in_other_tabs = false
    for tab, buffers in pairs(core.cache) do
      if tab ~= current_tab then
        for _, buffer in ipairs(buffers) do
          if buffer == current_buf then
            buffer_exists_in_other_tabs = true
            break
          end
        end
      end
      if buffer_exists_in_other_tabs then
        break
      end
    end
    if buffer_exists_in_other_tabs then
      if #buffers_in_current_tab > 1 then
        vim.api.nvim_set_option_value('buflisted', false, { buf = current_buf })
        vim.cmd([[bprev]])
      else
        vim.cmd('tabclose')
      end
    else
      local tab_count = #vim.api.nvim_list_tabpages()
      if #buffers_in_current_tab == 1 then
        if tab_count > 1 then
          vim.api.nvim_buf_delete(current_buf, { force = opts.force })
          vim.cmd('tabclose')
        else
          local choice = 1
          if opts.ask then
            choice = vim.fn.confirm(
              "You're about to close the last tab. Do you want to quit?",
              '&Yes\n&No'
            )
          end
          if choice == 1 then
            vim.cmd('qa!')
          end
        end
      else
        vim.cmd([[bprev]])
        vim.api.nvim_buf_delete(current_buf, { force = opts.force })
      end
    end
    core.revalidate()
  end
  function core.move_buf(bufnr, target)
    local target_bufs = core.cache[target] or {}
    target_bufs[#target_bufs + 1] = bufnr
    core.cache[target] = target_bufs
    if #utils.get_valid_buffers() > 1 then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
      if bufnr == vim.api.nvim_get_current_buf() then
        vim.cmd('bprevious')
      end
    end
  end
  function core.move_current_buf(opts)
    if not vim.api.nvim_get_option_value('buflisted', { buf = 0 }) then
      return
    end
    local target = tonumber(opts.args)
    if target == nil then
      local input = vim.fn.input('Move buf to: ')
      if input == '' then
        return
      end
      target = tonumber(input)
    end
    local target_handle = vim.api.nvim_list_tabpages()[target]
    if target_handle == nil then
      vim.notify('Invalid target tab', vim.log.levels.ERROR)
      return
    end
    core.move_buf(vim.api.nvim_get_current_buf(), target_handle)
  end
  function scope.setup(overrides)
    for k, v in pairs(overrides or {}) do
      config[k] = v
    end
    local group = vim.api.nvim_create_augroup('ScopeAU', {})
    vim.api.nvim_create_autocmd('TabEnter', { group = group, callback = core.on_tab_enter })
    vim.api.nvim_create_autocmd('TabLeave', { group = group, callback = core.on_tab_leave })
    vim.api.nvim_create_autocmd('TabClosed', { group = group, callback = core.on_tab_closed })
    vim.api.nvim_create_autocmd(
      'TabNewEntered',
      { group = group, callback = core.on_tab_new_entered }
    )
    vim.api.nvim_create_user_command('ScopeList', core.print_summary, {})
    vim.api.nvim_create_user_command('ScopeMoveBuf', core.move_current_buf, { nargs = '?' })

    -- Defer telescope integration until after startup
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TelescopeReady',
      once = true,
      callback = function()
        local ok, telescope = pcall(require, 'telescope')
        if not ok then
          return
        end
        local _ = telescope -- registered via telescope._extensions below
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local make_entry = require('telescope.make_entry')
        local pickers = require('telescope.pickers')
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local transform = require('telescope.actions.mt').transform_mod
        local function get_all_scope_buffers()
          local bufs = {}
          for _, tab_bufs in pairs(core.cache) do
            for _, buf in pairs(tab_bufs) do
              table.insert(bufs, buf)
            end
          end
          return bufs
        end
        local function find_buffer_tabindex(bufnr)
          for tabi, bufs in pairs(core.cache) do
            for _, b in pairs(bufs) do
              if b == bufnr then
                return tabi
              end
            end
          end
        end
        local function scope_buffers(opts)
          opts = opts or {}
          core.revalidate()
          local all = vim.tbl_filter(function(b)
            return vim.fn.buflisted(b) == 1
          end, vim.api.nvim_list_bufs())
          for _, b in ipairs(get_all_scope_buffers()) do
            if not vim.tbl_contains(all, b) then
              all[#all + 1] = b
            end
          end
          local bufnrs = vim.tbl_filter(function(b)
            if opts.show_all_buffers == false and not vim.api.nvim_buf_is_loaded(b) then
              return false
            end
            if opts.ignore_current_buffer and b == vim.api.nvim_get_current_buf() then
              return false
            end
            if
              opts.cwd_only
              and not string.find(vim.api.nvim_buf_get_name(b), vim.uv.cwd(), 1, true)
            then
              return false
            end
            if
              not opts.cwd_only
              and opts.cwd
              and not string.find(vim.api.nvim_buf_get_name(b), opts.cwd, 1, true)
            then
              return false
            end
            return true
          end, all)
          if not next(bufnrs) then
            return
          end
          if opts.sort_mru then
            table.sort(bufnrs, function(a, b)
              return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
            end)
          end
          local buffers = {}
          local default_selection_idx = 1
          for _, bufnr in ipairs(bufnrs) do
            local flag = bufnr == vim.fn.bufnr('') and '%'
              or (bufnr == vim.fn.bufnr('#') and '#' or ' ')
            if opts.sort_lastused and not opts.ignore_current_buffer and flag == '#' then
              default_selection_idx = 2
            end
            local element = { bufnr = bufnr, flag = flag, info = vim.fn.getbufinfo(bufnr)[1] }
            if opts.sort_lastused and (flag == '#' or flag == '%') then
              table.insert(buffers, ((buffers[1] and buffers[1].flag == '%') and 2 or 1), element)
            else
              table.insert(buffers, element)
            end
          end
          opts.bufnr_width = opts.bufnr_width or #tostring(math.max(unpack(bufnrs)))
          pickers
            .new(opts, {
              prompt_title = 'Scope Buffers',
              finder = finders.new_table({
                results = buffers,
                entry_maker = opts.entry_maker or make_entry.gen_from_buffer(opts),
              }),
              previewer = conf.grep_previewer(opts),
              sorter = conf.generic_sorter(opts),
              default_selection_index = default_selection_idx,
              attach_mappings = function(prompt_bufnr, map)
                local open_in_window = transform({
                  run = function()
                    local sel = action_state.get_selected_entry()
                    if not sel then
                      return
                    end
                    actions.close(prompt_bufnr)
                    vim.cmd('buffer ' .. sel.bufnr)
                  end,
                })
                map('i', '<C-w>', open_in_window.run)
                map('n', '<C-w>', open_in_window.run)
                actions.select_default:replace(function()
                  local sel = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  local tabi = find_buffer_tabindex(sel.bufnr)
                  if tabi then
                    vim.api.nvim_set_current_tabpage(tabi)
                  end
                  vim.cmd('buffer ' .. sel.bufnr)
                end)
                return true
              end,
            })
            :find()
        end
        require('telescope._extensions')['scope'] = {
          exports = { buffers = scope_buffers },
        }
        vim.keymap.set('n', '<leader>fB', scope_buffers, { desc = 'All buffers (all tabs)' })
        vim.keymap.set(
          'n',
          '<leader>tmb',
          '<cmd>ScopeMoveBuf<cr>',
          { desc = 'Move buffer to a specific tab' }
        )
      end,
    })
  end
end
-- ============================================================
local M = {}
function M.setup()
  scope.setup({
    hooks = {
      pre_tab_enter = function() end,
      post_tab_enter = function() end,
      pre_tab_leave = function() end,
      post_tab_leave = function() end,
      pre_tab_close = function() end,
      post_tab_close = function() end,
    },
  })
end
return M
