local M = {}
local H = {}

-- ===========================================================================
-- Public API
-- ===========================================================================

M.config = {
  show_icons = true,
  format = nil,
  -- Maximum fraction of the screen width the tab pills section may occupy.
  -- Pills grow dynamically up to this cap; the rest is left for buffers.
  max_pills_width = 0.25,
  -- When the active tab name alone exceeds max_pills_width, the cap grows up
  -- to this fraction before the name gets tail-truncated with '…'.
  max_tab_width = 0.50,
}

M.setup = function(config)
  config = H.setup_config(config)
  H.apply_config(config)
  H.create_autocommands()
  H.create_default_hl()

  vim.api.nvim_exec2(
    [[function! TablineSwitchBuffer(buf_id, clicks, button, mod)
        execute 'buffer' a:buf_id
      endfunction]],
    {}
  )
end

M.make_tabline_string = function()
  if H.is_disabled() then
    return ''
  end

  local pills = H.make_tab_pills()

  H.list_tabs()
  H.finalize_labels()
  H.fit_width()
  local bufs = H.concat_tabs()

  return pills .. '%#TablineFill# │ ' .. bufs
end

M.default_format = function(buf_id, label)
  if H.get_icon == nil then
    return string.format(' %s ', label)
  end
  return string.format(' %s %s ', H.get_icon(vim.api.nvim_buf_get_name(buf_id)), label)
end

-- ===========================================================================
-- Tab pills
-- ===========================================================================

H.get_tab_label = function(tab)
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tab_name')
  if ok and name and name ~= '' then
    return name
  end
  local tabnr = vim.api.nvim_tabpage_get_number(tab)
  local cwd = vim.fn.getcwd(-1, tabnr)
  return vim.fn.fnamemodify(cwd, ':t')
end

-- Returns the fixed char width the pills section always occupies.
-- Used by H.compute_display_interval without re-rendering.
H.pills_display_width = function()
  local config = H.get_config()
  return math.floor(vim.o.columns * config.max_pills_width) + H.strwidth(' │ ')
end

-- Returns the rendered pill string. The section is always exactly `cap` chars
-- wide — it never shrinks or grows. Short content is padded with fill highlight;
-- long content is scrolled (ring-style) with '…' indicators on clipped sides.
H.make_tab_pills = function()
  local config = H.get_config()
  local cap = math.floor(vim.o.columns * config.max_pills_width)
  local current = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()

  -- Build pill data (untruncated).
  local pills = {}
  local active_idx = 1
  local total_raw_width = 0
  for i, tab in ipairs(tabpages) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local name = H.get_tab_label(tab)
    local label = string.format(' %d:%s ', tabnr, name)
    local is_cur = tab == current
    local hl = is_cur and '%#TablineTabActive#' or '%#TablineTabInactive#'
    local w = H.strwidth(label)
    pills[i] = {
      tabnr = tabnr,
      label = label,
      name = name,
      hl = hl,
      width = w,
      chars_on_left = total_raw_width,
    }
    total_raw_width = total_raw_width + w
    if is_cur then
      active_idx = i
    end
  end

  local function render(p)
    return string.format('%s%%%dT%s%%T', p.hl, p.tabnr, p.label)
  end

  -- The active pill may claim at most max_tab_width chars, but is always
  -- truncated to fit within cap regardless. We truncate if it exceeds cap.
  local active = pills[active_idx]
  local active_max = math.min(cap, math.floor(vim.o.columns * config.max_tab_width))

  if active.width > active_max then
    local prefix = string.format(' %d:', active.tabnr)
    local suffix = ' '
    local ellipsis = '…'
    local name_budget = active_max - H.strwidth(prefix) - H.strwidth(suffix) - H.strwidth(ellipsis)
    local name_trunc = vim.fn.strcharpart(active.name, 0, math.max(0, name_budget))
    active.label = prefix .. name_trunc .. ellipsis .. suffix
    active.width = H.strwidth(active.label)
    for j = active_idx + 1, #pills do
      pills[j].chars_on_left = pills[j - 1].chars_on_left + pills[j - 1].width
    end
    total_raw_width = 0
    for _, p in ipairs(pills) do
      total_raw_width = total_raw_width + p.width
    end
  end

  -- Distribute remaining cap to neighbours with ring wrapping.
  local neighbour_budget = cap - active.width
  local half_left = math.floor(neighbour_budget / 2)
  local half_right = neighbour_budget - half_left

  local avail_left = active.chars_on_left
  local avail_right = total_raw_width - (active.chars_on_left + active.width)

  local want_left = math.min(avail_left, half_left + math.max(0, half_right - avail_right))
  local want_right = math.min(avail_right, half_right + math.max(0, half_left - avail_left))

  local win_left = active.chars_on_left - want_left + 1
  local win_right = active.chars_on_left + active.width + want_right

  -- Collect visible pills. Pills fully inside the window render normally.
  -- Pills that partially overlap a window edge are clipped to the available
  -- chars and get a '…' appended/prepended so the name is still visible.
  local parts = {}
  local need_left_trunc = false
  local need_right_trunc = false
  local content_width = 0
  for _, p in ipairs(pills) do
    local p_left = p.chars_on_left + 1
    local p_right = p.chars_on_left + p.width
    if p_left <= win_right and p_right >= win_left then
      local clip_left = math.max(0, win_left - p_left)
      local clip_right = math.max(0, p_right - win_right)
      if clip_left > 0 then
        -- Partially visible on the left edge: show '…' then clipped label.
        need_left_trunc = true
        local visible = p.width - clip_left - clip_right - 1 -- reserve 1 for the '…'
        if visible > 0 then
          local clipped = vim.fn.strcharpart(p.label, clip_left, visible)
          parts[#parts + 1] = p.hl .. clipped
          content_width = content_width + visible
        end
      elseif clip_right > 0 then
        -- Partially visible on the right edge: show clipped label then '…'.
        need_right_trunc = true
        local visible = p.width - clip_right - 1 -- reserve 1 for the '…'
        if visible > 0 then
          local clipped = vim.fn.strcharpart(p.label, 0, visible)
          parts[#parts + 1] = p.hl .. clipped
          content_width = content_width + visible
        end
      else
        parts[#parts + 1] = render(p)
        content_width = content_width + p.width
      end
    end
  end

  -- '…' indicators each consume 1 char; remainder becomes padding.
  local indicator_width = (need_left_trunc and 1 or 0) + (need_right_trunc and 1 or 0)
  local pad_width = cap - content_width - indicator_width

  local result = ''
  if need_left_trunc then
    result = result .. '%#TablineTrunc#…'
  end
  result = result .. table.concat(parts)
  if need_right_trunc then
    result = result .. '%#TablineTrunc#…'
  end
  if pad_width > 0 then
    result = result .. '%#TablineTabInactive#' .. string.rep(' ', pad_width)
  end
  return result
end

-- ===========================================================================
-- Internals
-- ===========================================================================

H.default_config = vim.deepcopy(M.config)
H.tabs = {}
H.unnamed_buffers_seq_ids = {}
H.path_sep = package.config:sub(1, 1)
H.trunc = { left = '', right = '', needs_left = false, needs_right = false }
H.center_buf_id = nil

-- Settings ------------------------------------------------------------------
H.setup_config = function(config)
  H.check_type('config', config, 'table', true)
  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})
  H.check_type('show_icons', config.show_icons, 'boolean')
  H.check_type('format', config.format, 'function', true)
  H.check_type('max_pills_width', config.max_pills_width, 'number')
  H.check_type('max_tab_width', config.max_tab_width, 'number')
  if config.max_pills_width <= 0 or config.max_pills_width >= 1 then
    H.error('`max_pills_width` should be a fraction between 0 and 1 (exclusive)')
  end
  if config.max_tab_width <= 0 or config.max_tab_width >= 1 then
    H.error('`max_tab_width` should be a fraction between 0 and 1 (exclusive)')
  end
  if config.max_tab_width < config.max_pills_width then
    H.error('`max_tab_width` should be >= `max_pills_width`')
  end
  return config
end

H.apply_config = function(config)
  M.config = config
  vim.o.showtabline = 2
  H.cache_trunc_chars()
  _G._Tabline = M
  vim.o.tabline = '%!v:lua._Tabline.make_tabline_string()'
end

H.create_autocommands = function()
  local gr = vim.api.nvim_create_augroup('Tabline', {})
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = gr,
    callback = H.create_default_hl,
    desc = 'Ensure tabline colors',
  })
  vim.api.nvim_create_autocmd('OptionSet', {
    group = gr,
    pattern = { 'list', 'listchars' },
    callback = H.cache_trunc_chars,
    desc = 'Ensure truncation characters',
  })
end

H.create_default_hl = function()
  local function set_hl(name, data)
    data.default = true
    vim.api.nvim_set_hl(0, name, data)
  end
  set_hl('TablineCurrent', { link = 'TabLineSel' })
  set_hl('TablineVisible', { link = 'TabLineSel' })
  set_hl('TablineHidden', { link = 'TabLine' })
  set_hl('TablineModifiedCurrent', { link = 'StatusLine' })
  set_hl('TablineModifiedVisible', { link = 'StatusLine' })
  set_hl('TablineModifiedHidden', { link = 'StatusLineNC' })
  set_hl('TablineTabActive', { link = 'Search' })
  set_hl('TablineTabInactive', { link = 'TabLine' })
  set_hl('TablineFill', { link = 'TabLineFill' })
  set_hl('TablineTrunc', { link = 'TabLine' })
end

H.is_disabled = function()
  return vim.g.tabline_disable == true or vim.b.tabline_disable == true
end

H.get_config = function(config)
  return vim.tbl_deep_extend('force', M.config, vim.b.tabline_config or {}, config or {})
end

-- Tabs ----------------------------------------------------------------------
H.list_tabs = function()
  local tabs = {}
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf_id].buflisted then
      local tab = { buf_id = buf_id }
      tab['hl'] = H.construct_highlight(buf_id)
      tab['tabfunc'] = '%' .. buf_id .. '@TablineSwitchBuffer@'
      tab['label'], tab['label_extender'] = H.construct_label_data(buf_id)
      table.insert(tabs, tab)
    end
  end
  H.tabs = tabs
end

H.construct_highlight = function(buf_id)
  local hl_type = buf_id == vim.api.nvim_get_current_buf() and 'Current'
    or (vim.fn.bufwinnr(buf_id) > 0 and 'Visible' or 'Hidden')
  if vim.bo[buf_id].modified then
    hl_type = 'Modified' .. hl_type
  end
  return '%#Tabline' .. hl_type .. '#'
end

H.construct_label_data = function(buf_id)
  local label, label_extender
  local bufpath = vim.api.nvim_buf_get_name(buf_id)
  if bufpath ~= '' then
    label = vim.fn.fnamemodify(bufpath, ':t')
    label_extender = H.make_path_extender(buf_id)
  else
    label = H.make_unnamed_label(buf_id)
    label_extender = function(x)
      return x
    end
  end
  return label, label_extender
end

H.make_path_extender = function(buf_id)
  return function(label)
    local full_path = vim.api.nvim_buf_get_name(buf_id)
    local pattern = string.format('[^%s]+%s%s$', H.path_sep, H.path_sep, vim.pesc(label))
    return string.match(full_path, pattern) or label
  end
end

-- Unnamed buffers -----------------------------------------------------------
H.make_unnamed_label = function(buf_id)
  local buftype = vim.bo[buf_id].buftype
  local label = buftype == 'quickfix'
      and (vim.fn.getqflist({ qfbufnr = true }).qfbufnr == buf_id and '*quickfix*' or '*location*')
    or ((buftype == 'nofile' or buftype == 'acwrite') and '!' or '*')
  local unnamed_id = H.get_unnamed_id(buf_id)
  if unnamed_id > 1 then
    label = string.format('%s(%d)', label, unnamed_id)
  end
  return label
end

H.get_unnamed_id = function(buf_id)
  local seq_id = H.unnamed_buffers_seq_ids[buf_id]
  if seq_id ~= nil then
    return seq_id
  end
  H.unnamed_buffers_seq_ids[buf_id] = vim.tbl_count(H.unnamed_buffers_seq_ids) + 1
  return H.unnamed_buffers_seq_ids[buf_id]
end

-- Labels --------------------------------------------------------------------
H.finalize_labels = function()
  if #H.tabs == 0 then
    return
  end

  local nonunique_buf_ids = H.get_nonunique_buf_ids()
  while #nonunique_buf_ids > 0 do
    local nothing_changed = true
    for _, buf_id in ipairs(nonunique_buf_ids) do
      local tab = H.tabs[buf_id]
      local old_label = tab.label
      tab.label = tab.label_extender(tab.label)
      if old_label ~= tab.label then
        nothing_changed = false
      end
    end
    if nothing_changed then
      break
    end
    nonunique_buf_ids = H.get_nonunique_buf_ids()
  end

  local config = H.get_config()
  H.ensure_get_icon(config)
  local format = config.format or M.default_format
  for _, tab in pairs(H.tabs) do
    tab.label = format(tab.buf_id, tab.label)
  end
end

H.get_nonunique_buf_ids = function()
  local label_counts = {}
  for _, tab in ipairs(H.tabs) do
    label_counts[tab.label] = (label_counts[tab.label] or 0) + 1
  end
  local res = {}
  for i, tab in ipairs(H.tabs) do
    if label_counts[tab.label] > 1 then
      table.insert(res, i)
    end
  end
  return res
end

-- Fit width -----------------------------------------------------------------
H.fit_width = function()
  if #H.tabs == 0 then
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if vim.bo[cur_buf].buflisted then
    H.center_buf_id = cur_buf
  end

  local center_offset = 1
  local tot_width = 0
  for _, tab in pairs(H.tabs) do
    tab.label_width = H.strwidth(tab.label)
    tab.chars_on_left = tot_width
    tot_width = tot_width + tab.label_width
    if tab.buf_id == H.center_buf_id then
      center_offset = tot_width
    end
  end

  local display_interval = H.compute_display_interval(center_offset, tot_width)
  H.truncate_tabs_display(display_interval)
end

H.compute_display_interval = function(center_offset, tabline_width)
  local tot_width = math.max(1, vim.o.columns - H.pills_display_width())

  local right = math.min(tabline_width, math.floor(center_offset + 0.5 * tot_width))
  local left = math.max(1, right - tot_width + 1)
  right = left + math.min(tot_width, tabline_width) - 1
  return { left, right }
end

H.truncate_tabs_display = function(display_interval)
  local display_left, display_right = display_interval[1], display_interval[2]

  local tabs, first, last = {}, nil, nil
  for i, tab in ipairs(H.tabs) do
    local tab_left = tab.chars_on_left + 1
    local tab_right = tab.chars_on_left + tab.label_width
    if (display_left <= tab_right) and (tab_left <= display_right) then
      local n_trunc_left = math.max(0, display_left - tab_left)
      local n_trunc_right = math.max(0, tab_right - display_right)
      tab.label = vim.fn.strcharpart(tab.label, n_trunc_left, tab.label_width - n_trunc_right)
      table.insert(tabs, tab)
      first, last = first or i, i
    end
  end

  H.trunc.needs_left = H.trunc.left ~= ''
    and (first > 1 or H.strwidth(tabs[1].label) < tabs[1].label_width)
  if H.trunc.needs_left then
    tabs[1].label = vim.fn.strcharpart(tabs[1].label, 1)
  end

  local n = #tabs
  H.trunc.needs_right = H.trunc.right ~= ''
    and (last < #H.tabs or H.strwidth(tabs[n].label) < tabs[n].label_width)
  if H.trunc.needs_right then
    tabs[n].label = vim.fn.strcharpart(tabs[n].label, 0, H.strwidth(tabs[n].label) - 1)
  end

  H.tabs = tabs
end

H.cache_trunc_chars = function()
  local trunc_chars = { left = '', right = '' }
  if vim.go.list then
    local listchars = vim.go.listchars
    trunc_chars.left = listchars:match('precedes:(.[^,]*)') or ''
    trunc_chars.right = listchars:match('extends:(.[^,]*)') or ''
  end
  H.trunc = trunc_chars
end

-- Concatenate ---------------------------------------------------------------
H.concat_tabs = function()
  local t = {}
  if H.trunc.needs_left then
    table.insert(t, '%#TablineTrunc#' .. H.trunc.left:gsub('%%', '%%%%'))
  end
  for _, tab in ipairs(H.tabs) do
    table.insert(t, tab.hl .. tab.tabfunc .. tab.label:gsub('%%', '%%%%'))
  end
  if H.trunc.needs_right then
    table.insert(t, '%#TablineTrunc#' .. H.trunc.right:gsub('%%', '%%%%'))
  end
  return table.concat(t, '') .. '%X%#TablineFill#%='
end

-- Utilities -----------------------------------------------------------------
H.error = function(msg)
  error('(tabline) ' .. msg, 0)
end

H.strwidth = function(x)
  return vim.api.nvim_strwidth(x)
end

H.check_type = function(name, val, ref, allow_nil)
  if
    type(val) == ref
    or (ref == 'callable' and vim.is_callable(val))
    or (allow_nil and val == nil)
  then
    return
  end
  H.error(string.format('`%s` should be %s, not %s', name, ref, type(val)))
end

H.ensure_get_icon = function(config)
  if not config.show_icons then
    H.get_icon = nil
  elseif H.get_icon ~= nil then
    return
  elseif _G.MiniIcons ~= nil then
    H.get_icon = function(name)
      return (_G.MiniIcons.get('file', name))
    end
  else
    local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
    if not has_devicons then
      return
    end
    H.get_icon = function(name)
      return (devicons.get_icon(vim.fn.fnamemodify(name, ':t'), nil, { default = true }))
    end
  end
end

return M
