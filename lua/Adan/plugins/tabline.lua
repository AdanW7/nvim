-- tabline.lua  —  vendored single-file tabline
--
--   • Tab pills (left, fixed-width, ring-scroll): icon + number + name
--   • Buffer chips (right): icon, modified ●, LSP diag counts
--   • Path disambiguation (unique-mode: extend until all labels differ)
--   • Rich special-buffer names (terminal, qf, neo-tree, lazy, …)
--   • Tab rename via  :let t:tab_name = "foo"  or  <leader>tr
--

local M = {}
local H = {}

-- ============================================================
-- Config
-- ============================================================

M.config = {
  show_icons = true,
  show_diagnostics = false,
  format = nil, -- function(buf_id, label) -> string | nil for default
  max_pills_width = 0.25,
  max_tab_width = 0.25,
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

-- ============================================================
-- Render entry-point
-- ============================================================

M.make_tabline_string = function()
  if H.is_disabled() then
    return ''
  end
  return H.make_tab_pills() .. H.make_buf_section()
end

-- ============================================================
-- TAB PILLS  (left section, fixed-width, ring-scroll)
-- ============================================================

H.get_tab_label = function(tab)
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'tab_name')
  if ok and name and name ~= '' then
    return name
  end
  local tabnr = vim.api.nvim_tabpage_get_number(tab)
  local cwd = vim.fn.getcwd(-1, tabnr)
  return vim.fn.fnamemodify(cwd, ':t')
end

H.pills_display_width = function()
  return math.floor(vim.o.columns * H.get_config().max_pills_width)
end

H.make_tab_pills = function()
  local cfg = H.get_config()
  local cap = H.pills_display_width()
  local current = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()

  -- Build raw pill metadata
  local pills = {}
  local active_i = 1
  local total_w = 0

  for i, tab in ipairs(tabpages) do
    local tabnr = vim.api.nvim_tabpage_get_number(tab)
    local name = H.get_tab_label(tab)
    local is_cur = (tab == current)
    local icon = is_cur and '󰆤 ' or '󰆣 '
    local body = string.format(' %s%d:%s ', icon, tabnr, name)
    local w = H.strwidth(body)

    pills[i] = {
      tabnr = tabnr,
      name = name,
      icon = icon,
      body = body,
      is_cur = is_cur,
      hl_grp = is_cur and 'TablineTabActive' or 'TablineTabInactive',
      width = w,
      chars_on_left = total_w,
    }
    total_w = total_w + w
    if is_cur then
      active_i = i
    end
  end

  -- Possibly truncate active pill name
  local active = pills[active_i]
  local active_max = math.min(cap, math.floor(vim.o.columns * cfg.max_tab_width))

  if active.width > active_max then
    local prefix = string.format(' %s%d:', active.icon, active.tabnr)
    local suffix = ' '
    local budget = active_max - H.strwidth(prefix) - H.strwidth(suffix) - 1
    local trname = vim.fn.strcharpart(active.name, 0, math.max(0, budget)) .. '…'
    active.body = prefix .. trname .. suffix
    active.width = H.strwidth(active.body)
    local running = 0
    for _, p in ipairs(pills) do
      p.chars_on_left = running
      running = running + p.width
    end
    total_w = running
  end

  -- Ring-scroll: pick window around active pill
  local nb = cap - active.width
  local hl = math.floor(nb / 2)
  local hr = nb - hl
  local al = active.chars_on_left
  local ar = total_w - (al + active.width)
  local wl = math.min(al, hl + math.max(0, hr - ar))
  local wr = math.min(ar, hr + math.max(0, hl - al))
  local wl_abs = al - wl + 1
  local wr_abs = al + active.width + wr

  -- Render visible pills
  local parts = {}
  local need_ltrunc = false
  local need_rtrunc = false
  local content_w = 0

  for _, p in ipairs(pills) do
    local pl = p.chars_on_left + 1
    local pr = p.chars_on_left + p.width

    if pl <= wr_abs and pr >= wl_abs then
      local clip_l = math.max(0, wl_abs - pl)
      local clip_r = math.max(0, pr - wr_abs)
      local pill_hl = '%#' .. p.hl_grp .. '#'
      local click = string.format('%%%dT', p.tabnr)

      if clip_l > 0 then
        need_ltrunc = true
        local vis = p.width - clip_l - clip_r - 1
        if vis > 0 then
          parts[#parts + 1] = pill_hl .. vim.fn.strcharpart(p.body, clip_l, vis)
          content_w = content_w + vis
        end
      elseif clip_r > 0 then
        need_rtrunc = true
        local vis = p.width - clip_r - 1
        if vis > 0 then
          parts[#parts + 1] = pill_hl .. vim.fn.strcharpart(p.body, 0, vis)
          content_w = content_w + vis
        end
      else
        parts[#parts + 1] = pill_hl .. click .. p.body .. '%T'
        content_w = content_w + p.width
      end
    end
  end

  local zone_sep = '%#TablineSep#  '
  local zone_sep_w = 3 -- " ┃ " = 3 display cells
  local indicator_w = (need_ltrunc and 1 or 0) + (need_rtrunc and 1 or 0)
  local pad_w = math.max(0, cap - content_w - indicator_w - zone_sep_w)

  local result = '%#TablineFill#'
  if need_ltrunc then
    result = result .. '%#TablineTrunc#'
  end
  result = result .. table.concat(parts)
  if need_rtrunc then
    result = result .. '%#TablineTrunc#'
  end
  if pad_w > 0 then
    result = result .. '%#TablineFill#' .. string.rep(' ', pad_w)
  end
  result = result .. zone_sep

  return result
end

-- ============================================================
-- BUFFER SECTION  (right of zone separator)
-- ============================================================

H.bufs = {}
H.unnamed_seq_ids = {}
H.path_sep = package.config:sub(1, 1)
H.center_buf_id = nil

-- Rich special-buffer names

H.rich_buf_name = function(buf_id)
  local bt = vim.bo[buf_id].buftype
  local ft = vim.bo[buf_id].filetype
  local bn = vim.api.nvim_buf_get_name(buf_id)

  if ft == 'fzf' then
    return ' FZF'
  elseif bt == 'terminal' then
    local t = (vim.b[buf_id].term_title or ''):gsub('~/.*/', '')
    return ' ' .. t
  elseif ft == 'checkhealth' then
    return ' Health'
  elseif ft == 'qf' then
    return vim.fn.getqflist({ qfbufnr = true }).qfbufnr == buf_id and ' Quickfix' or ' Location'
  elseif ft == 'pager' then
    return ' Pager'
  elseif ft == 'NvimTree' then
    return ' Tree'
  elseif ft == 'neo-tree' then
    return ' Tree'
  elseif ft == 'mason' then
    return '󱌣 Mason'
  elseif ft == 'lazy' then
    return '󰒲 Lazy'
  elseif ft == 'dap-view' or ft == 'dap-view-help' then
    return ' DAP'
  elseif ft == 'dap-repl' then
    return ' REPL'
  elseif ft == 'dap-view-hover' then
    return ' Hover'
  elseif ft == 'octo_panel' then
    return ' Octo'
  elseif bn:match('^octo://') then
    local pr = bn:match('pull/%d+')
    return pr and (' PR#' .. pr:sub(6)) or ' Octo'
  elseif ft:match('^Neogit') then
    return ' ' .. ft
  elseif ft:match('^Diffview') then
    return ' ' .. ft
  elseif bn == 'kulala://ui' then
    return '󰴖 Kulala'
  elseif bt == 'help' then
    return ' ' .. vim.fn.fnamemodify(bn, ':t')
  elseif bn:match('^diffview://') then
    return vim.fn.fnamemodify(bn, ':t')
  elseif bn == '' then
    return ' [No Name]'
  elseif bt == '' then
    return vim.fn.fnamemodify(bn, ':.')
  else
    return bn
  end
end

-- Path disambiguation (unique mode: extend by one parent segment until all unique)

H.make_path_extender = function(buf_id)
  local full = vim.api.nvim_buf_get_name(buf_id)
  return function(label)
    local pat = '([^' .. H.path_sep .. ']+' .. H.path_sep .. vim.pesc(label) .. ')$'
    return full:match(pat) or label
  end
end

H.disambiguate = function(list)
  for _ = 1, 20 do
    local counts = {}
    for _, b in ipairs(list) do
      counts[b.label] = (counts[b.label] or 0) + 1
    end
    local changed = false
    for _, b in ipairs(list) do
      if counts[b.label] > 1 then
        local new = b.label_extender(b.label)
        if new ~= b.label then
          b.label = new
          changed = true
        end
      end
    end
    if not changed then
      break
    end
    local seen = {}
    local all_unique = true
    for _, b in ipairs(list) do
      if seen[b.label] then
        all_unique = false
        break
      end
      seen[b.label] = true
    end
    if all_unique then
      break
    end
  end
end

H.make_unnamed_label = function(buf_id)
  local bt = vim.bo[buf_id].buftype
  local label = (bt == 'quickfix')
      and (vim.fn.getqflist({ qfbufnr = true }).qfbufnr == buf_id and ' Quickfix' or ' Location')
    or ((bt == 'nofile' or bt == 'acwrite') and '!' or '*')
  local uid = H.get_unnamed_id(buf_id)
  if uid > 1 then
    label = label .. '(' .. uid .. ')'
  end
  return label
end

H.get_unnamed_id = function(buf_id)
  if H.unnamed_seq_ids[buf_id] then
    return H.unnamed_seq_ids[buf_id]
  end
  H.unnamed_seq_ids[buf_id] = vim.tbl_count(H.unnamed_seq_ids) + 1
  return H.unnamed_seq_ids[buf_id]
end

-- Diagnostic counts
-- Numbers are coloured via TablineDiagError (red) and TablineDiagWarn (yellow).
-- %* resets back to the buffer's own highlight group after each count.

H.buf_diagnostics = function(buf_id, buf_hl_grp)
  if not vim.diagnostic then
    return nil
  end
  local diags = vim.diagnostic.get(buf_id)
  if #diags == 0 then
    return nil
  end
  local E, W = 0, 0
  for _, d in ipairs(diags) do
    if d.severity == vim.diagnostic.severity.ERROR then
      E = E + 1
    elseif d.severity == vim.diagnostic.severity.WARN then
      W = W + 1
    end
  end
  -- Reset back to the buffer's own hl group (not %* which snaps to Normal)
  -- so the diag counts share the same background as the rest of the chip.
  local reset = '%#' .. buf_hl_grp .. '#'
  local s = ''
  if E > 0 then
    s = s .. '  %#TablineDiagError#' .. E .. reset
  end
  if W > 0 then
    s = s .. '  %#TablineDiagWarn#' .. W .. reset
  end
  return s ~= '' and s or nil
end

-- Collect listed buffers

H.list_bufs = function()
  local result = {}
  local cur_buf = vim.api.nvim_get_current_buf()

  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf_id].buflisted then
      local bn = vim.api.nvim_buf_get_name(buf_id)
      local bt = vim.bo[buf_id].buftype
      local label, extender, is_file

      if bn ~= '' and bt == '' then
        label = vim.fn.fnamemodify(bn, ':t')
        extender = H.make_path_extender(buf_id)
        is_file = true
      else
        label = H.rich_buf_name(buf_id)
        extender = function(x)
          return x
        end
        is_file = false
      end

      local is_cur = (buf_id == cur_buf)
      local visible = vim.fn.bufwinnr(buf_id) > 0
      local modified = vim.bo[buf_id].modified
      local hl_grp

      if modified then
        hl_grp = is_cur and 'TablineModifiedCurrent'
          or visible and 'TablineModifiedVisible'
          or 'TablineModifiedHidden'
      else
        hl_grp = is_cur and 'TablineCurrent' or visible and 'TablineVisible' or 'TablineHidden'
      end

      result[#result + 1] = {
        buf_id = buf_id,
        hl_grp = hl_grp,
        is_cur = is_cur,
        modified = modified,
        is_file = is_file,
        label = label,
        label_extender = extender,
      }
    end
  end

  H.bufs = result
end

-- Finalize labels: disambiguate then add icon / modified dot / diag counts

H.finalize_labels = function()
  if #H.bufs == 0 then
    return
  end

  H.disambiguate(H.bufs)

  local cfg = H.get_config()
  H.ensure_get_icon(cfg)

  for _, b in ipairs(H.bufs) do
    local s = b.label

    if H.get_icon and b.is_file then
      local icon = H.get_icon(vim.api.nvim_buf_get_name(b.buf_id))
      s = icon .. ' ' .. s
    end

    if b.modified then
      s = s .. ' ●'
    end

    -- Diag string is stored separately: it contains raw %#...# tabline escapes
    -- that must NOT pass through the gsub('%%','%%%%') in make_buf_section.
    if cfg.show_diagnostics then
      b.diag = H.buf_diagnostics(b.buf_id, b.hl_grp)
    end

    b.label = ' ' .. s .. ' '
  end
end

-- Scroll to keep current buffer centred

H.fit_width = function()
  if #H.bufs == 0 then
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if vim.bo[cur_buf].buflisted then
    H.center_buf_id = cur_buf
  end

  local center_offset = 1
  local tot = 0
  for _, b in ipairs(H.bufs) do
    b.label_width = H.strwidth(b.label)
    b.chars_on_left = tot
    tot = tot + b.label_width
    if b.buf_id == H.center_buf_id then
      center_offset = tot
    end
  end

  local avail = math.max(1, vim.o.columns - H.pills_display_width() - 4)
  local right = math.min(tot, math.floor(center_offset + 0.5 * avail))
  local left = math.max(1, right - avail + 1)
  right = left + math.min(avail, tot) - 1

  local kept = {}
  for _, b in ipairs(H.bufs) do
    local bl = b.chars_on_left + 1
    local br = b.chars_on_left + b.label_width
    if bl <= right and br >= left then
      local nl = math.max(0, left - bl)
      local nr = math.max(0, br - right)
      if nl > 0 or nr > 0 then
        b.label = vim.fn.strcharpart(b.label, nl, b.label_width - nl - nr)
        b.clipped = true
      end
      kept[#kept + 1] = b
    end
  end
  H.bufs = kept
end

-- Render buffer string

H.make_buf_section = function()
  H.list_bufs()
  H.finalize_labels()
  H.fit_width()

  if #H.bufs == 0 then
    return '%#TablineFill#%='
  end

  local parts = {}
  for _, b in ipairs(H.bufs) do
    local pill_hl = '%#' .. b.hl_grp .. '#'
    local click = '%' .. b.buf_id .. '@TablineSwitchBuffer@'
    local label = b.label:gsub('%%', '%%%%') .. (b.diag or '')
    parts[#parts + 1] = pill_hl .. click .. label .. '%X'
  end

  return table.concat(parts) .. '%#TablineFill#%='
end

-- ============================================================
-- Highlight groups
-- ============================================================

H.create_default_hl = function()
  local function hl(name, data)
    data.default = true
    vim.api.nvim_set_hl(0, name, data)
  end
  hl('TablineCurrent', { link = 'TabLineSel' })
  hl('TablineVisible', { link = 'TabLine' })
  hl('TablineHidden', { link = 'TabLine' })
  hl('TablineModifiedCurrent', { link = 'DiffAdd' })
  hl('TablineModifiedVisible', { link = 'DiffChange' })
  hl('TablineModifiedHidden', { link = 'DiffChange' })
  hl('TablineTabActive', { link = 'TabLineSel' })
  hl('TablineTabInactive', { link = 'TabLine' })
  hl('TablineFill', { link = 'TabLineFill' })
  hl('TablineTrunc', { link = 'Comment' })
  hl('TablineSep', { link = 'TabLine' })
  --   hl('TablineDiagError', { fg = '#ff6060', bold = true })
  --   hl('TablineDiagWarn',  { fg = '#e5c07b', bold = true })
end

-- ============================================================
-- Autocommands
-- ============================================================

H.create_autocommands = function()
  local gr = vim.api.nvim_create_augroup('Tabline', { clear = true })

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = gr,
    callback = H.create_default_hl,
    desc = 'Refresh tabline highlights',
  })

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = gr,
    callback = function()
      vim.cmd('redrawtabline')
    end,
    desc = 'Refresh tabline on diagnostic change',
  })
end

-- ============================================================
-- Utilities
-- ============================================================

H.setup_config = function(config)
  H.check_type('config', config, 'table', true)
  config = vim.tbl_deep_extend('force', vim.deepcopy(M.config), config or {})
  H.check_type('show_icons', config.show_icons, 'boolean')
  H.check_type('show_diagnostics', config.show_diagnostics, 'boolean')
  H.check_type('format', config.format, 'function', true)
  H.check_type('max_pills_width', config.max_pills_width, 'number')
  H.check_type('max_tab_width', config.max_tab_width, 'number')
  if config.max_pills_width <= 0 or config.max_pills_width >= 1 then
    H.error('`max_pills_width` must be a fraction between 0 and 1 (exclusive)')
  end
  if config.max_tab_width <= 0 or config.max_tab_width >= 1 then
    H.error('`max_tab_width` must be a fraction between 0 and 1 (exclusive)')
  end
  if config.max_tab_width < config.max_pills_width then
    H.error('`max_tab_width` must be >= `max_pills_width`')
  end
  return config
end

H.apply_config = function(config)
  M.config = config
  vim.o.showtabline = 2
  _G._Tabline = M
  vim.o.tabline = '%!v:lua._Tabline.make_tabline_string()'
end

H.is_disabled = function()
  return vim.g.tabline_disable == true or vim.b.tabline_disable == true
end

H.get_config = function(override)
  return vim.tbl_deep_extend('force', M.config, vim.b.tabline_config or {}, override or {})
end

H.strwidth = function(x)
  return vim.api.nvim_strwidth(x)
end

H.error = function(msg)
  error('(tabline) ' .. msg, 0)
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

H.ensure_get_icon = function(cfg)
  if not cfg.show_icons then
    H.get_icon = nil
    return
  end
  if H.get_icon then
    return
  end
  if _G.MiniIcons then
    H.get_icon = function(name)
      return (_G.MiniIcons.get('file', name))
    end
  else
    local ok, dv = pcall(require, 'nvim-web-devicons')
    if not ok then
      return
    end
    H.get_icon = function(name)
      return (dv.get_icon(vim.fn.fnamemodify(name, ':t'), nil, { default = true }))
    end
  end
end

return M
