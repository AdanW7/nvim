-- ==================================================================================
-- context (vendored from https://github.com/nvim-treesitter/nvim-treesitter-context)
-- ==================================================================================
local M = {}

-- ============================================================
-- context (internal module table)
-- ============================================================
local context = (function()
  local cache = (function()
    local C = {}
    function C.memoize(fn, hash_fn)
      local cache_store = setmetatable({}, { __mode = 'kv' }) ---@type table<any,any>
      return function(...)
        local key = hash_fn(...)
        if cache_store[key] == nil then
          local v = fn(...) ---@type any
          cache_store[key] = v ~= nil and v or vim.NIL
        end
        local v = cache_store[key]
        return v ~= vim.NIL and vim.deepcopy(v) or nil
      end
    end
    return C
  end)()

  local util = (function()
    local U = {}
    ---@param r Range4
    ---@return integer
    function U.get_range_height(r)
      return r[3] - r[1] + (r[4] == 0 and 0 or 1)
    end
    return U
  end)()

  -- ── config ──────────────────────────────────────────────────────────────

  ---@class (exact) TSContext.Config
  ---@field enable boolean
  ---@field multiwindow boolean
  ---@field max_lines integer|string
  ---@field min_window_height integer
  ---@field line_numbers boolean
  ---@field multiline_threshold integer
  ---@field trim_scope 'outer'|'inner'
  ---@field zindex integer
  ---@field mode 'cursor'|'topline'
  ---@field separator? string
  ---@field on_attach? fun(buf: integer): boolean

  ---@class (exact) TSContext.UserConfig
  ---@field enable? boolean
  ---@field multiwindow? boolean
  ---@field max_lines? integer|string
  ---@field min_window_height? integer
  ---@field line_numbers? boolean
  ---@field multiline_threshold? integer
  ---@field trim_scope? 'outer'|'inner'
  ---@field zindex? integer
  ---@field mode? 'cursor'|'topline'
  ---@field separator? string
  ---@field on_attach? fun(buf: integer): boolean

  -- Personal defaults live here — M.setup just forwards options directly.
  ---@type TSContext.Config
  local default_config = {
    enable = true,
    multiwindow = false,
    max_lines = 5,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 10,
    trim_scope = 'outer',
    zindex = 20,
    mode = 'cursor',
  }

  local cfg_data = vim.deepcopy(default_config)

  ---@type TSContext.Config & { update: fun(c: TSContext.UserConfig) }
  local config = {}
  function config.update(c)
    cfg_data = vim.tbl_deep_extend('force', cfg_data, c)
  end
  setmetatable(config, {
    __index = function(_, k)
      return cfg_data[k]
    end,
  })

  -- ── render ──────────────────────────────────────────────────────────────

  local render = (function()
    local api, fn = vim.api, vim.fn
    local highlighter = vim.treesitter.highlighter
    local ns = api.nvim_create_namespace('nvim-treesitter-context')

    ---@type integer[]
    local buffer_pool = {}
    local MAX_BUFFER_POOL_SIZE = 20

    ---@class WindowContext
    ---@field context_winid integer?
    ---@field gutter_winid integer?

    ---@type table<integer, WindowContext>
    local window_contexts = {}

    ---@return integer
    local function create_or_get_buf()
      for index = #buffer_pool, 1, -1 do
        local buf = table.remove(buffer_pool, index)
        if api.nvim_buf_is_valid(buf) then
          return buf
        end
      end
      local buf = api.nvim_create_buf(false, true)
      vim.bo[buf].undolevels = -1
      return buf
    end

    ---@param winid integer
    ---@param context_winid integer?
    ---@param width integer
    ---@param height integer
    ---@param col integer
    ---@param ty string
    ---@param hl string
    ---@return integer
    local function display_window(winid, context_winid, width, height, col, ty, hl)
      if not context_winid then
        local sep = config.separator and { config.separator, 'TreesitterContextSeparator' } or nil
        context_winid = api.nvim_open_win(create_or_get_buf(), false, {
          win = winid,
          relative = 'win',
          width = width,
          height = height,
          row = 0,
          col = col,
          focusable = false,
          style = 'minimal',
          noautocmd = true,
          zindex = config.zindex,
          border = sep and { '', '', '', '', sep, sep, sep, '' } or 'none',
        })
        vim.w[context_winid][ty] = true
        vim.wo[context_winid].wrap = false
        vim.wo[context_winid].foldenable = false
        vim.wo[context_winid].winhl = 'NormalFloat:' .. hl
        vim.wo[context_winid].conceallevel = vim.wo[winid].conceallevel
      elseif api.nvim_win_is_valid(context_winid) then
        api.nvim_win_set_config(context_winid, {
          win = winid,
          relative = 'win',
          width = width,
          height = height,
          row = 0,
          col = col,
        })
      end
      return context_winid
    end

    ---@param winid integer
    ---@return integer
    local function get_gutter_width(winid)
      return fn.getwininfo(winid)[1].textoff
    end

    ---@param name string
    ---@param from_buf integer
    ---@param to_buf integer
    local function copy_option(name, from_buf, to_buf)
      ---@cast name any
      local current = vim.bo[from_buf][name]
      if current ~= vim.bo[to_buf][name] then
        vim.bo[to_buf][name] = current
      end
    end

    ---@param bufnr integer
    ---@param row integer
    ---@param col integer
    ---@param opts vim.api.keyset.set_extmark
    ---@param ns0? integer
    local function add_extmark(bufnr, row, col, opts, ns0)
      local ok, err = pcall(api.nvim_buf_set_extmark, bufnr, ns0 or ns, row, col, opts)
      if not ok then
        local range = vim.inspect({ row, col, opts.end_row, opts.end_col })
        error(string.format('Could not apply extmark to %s: %s', range, err), 2)
      end
    end

    ---@param buf_query vim.treesitter.highlighter.Query
    ---@param capture integer
    ---@return integer?
    local function get_hl(buf_query, capture)
      ---@diagnostic disable-next-line: invisible
      if buf_query.get_hl_from_capture then
        ---@diagnostic disable-next-line: invisible
        return buf_query:get_hl_from_capture(capture)
      end
      ---@diagnostic disable-next-line: invisible
      return buf_query.hl_cache[capture]
    end

    ---@param arow integer
    ---@param acol integer
    ---@param brow integer
    ---@param bcol integer
    ---@return boolean
    local function is_after(arow, acol, brow, bcol)
      return arow > brow or (arow == brow and acol > bcol)
    end

    ---@param bufnr integer
    ---@param ctx_bufnr integer
    ---@param contexts Range4[]
    local function highlight_contexts(bufnr, ctx_bufnr, contexts)
      local buf_highlighter = highlighter.active[bufnr]
      copy_option('tabstop', bufnr, ctx_bufnr)
      if not buf_highlighter then
        copy_option('filetype', bufnr, ctx_bufnr)
        return
      end
      local parser = buf_highlighter.tree
      parser:for_each_tree(function(tstree, ltree)
        ---@diagnostic disable-next-line: invisible
        local buf_query = buf_highlighter:get_query(ltree:lang())
        ---@diagnostic disable-next-line: invisible
        local query = buf_query:query()
        if not query then
          return
        end
        local offset = 0
        for _, ctx in ipairs(contexts) do
          local pri_offset = 0
          local start_row, end_row, end_col = ctx[1], ctx[3], ctx[4]
          for capture, node, metadata in
            query:iter_captures(tstree:root(), bufnr, start_row, end_row + 1)
          do
            local range = vim.treesitter.get_range(node, bufnr, metadata[capture])
            local nsrow, nscol, nerow, necol = range[1], range[2], range[4], range[5]
            if nsrow >= start_row then
              if is_after(nsrow, nscol, end_row, end_col) then
                break
              end
              if is_after(nerow, necol, end_row, end_col) then
                nerow, necol = end_row, end_col
              end
              local msrow = offset + (nsrow - start_row)
              local merow = offset + (nerow - start_row)
              local priority = tonumber(metadata.priority)
                or (vim.hl and vim.hl.priorities.treesitter)
                or vim.highlight.priorities.treesitter
              local conceal = metadata.conceal or metadata[capture] and metadata[capture].conceal
              add_extmark(ctx_bufnr, msrow, nscol, {
                end_row = merow,
                end_col = necol,
                priority = priority + pri_offset,
                hl_group = get_hl(buf_query, capture),
                conceal = conceal,
              })
              pri_offset = pri_offset + 1
            end
          end
          offset = offset + util.get_range_height(ctx)
        end
      end)
    end

    ---@class StatusLineHighlight
    ---@field group string
    ---@field groups? string[]
    ---@field start integer

    ---@param ctx_node_line_num integer
    ---@param win integer
    ---@return integer
    local function get_relative_line_num(ctx_node_line_num, win)
      local cursor_line_num = fn.line('.', win)
      local num_folded_lines = 0
      local current_line = ctx_node_line_num
      while current_line < cursor_line_num do
        local fold_end = fn.foldclosedend(current_line)
        if fold_end == -1 then
          current_line = current_line + 1
        else
          num_folded_lines = num_folded_lines + fold_end - current_line
          current_line = fold_end + 1
        end
      end
      return cursor_line_num - ctx_node_line_num - num_folded_lines
    end

    ---@param win integer
    ---@param lnum integer
    ---@param width integer
    ---@return string, StatusLineHighlight[]?
    local function build_lno_str(win, lnum, width)
      local has_col, statuscol =
        pcall(api.nvim_get_option_value, 'statuscolumn', { win = win, scope = 'local' })
      if has_col and statuscol and statuscol ~= '' then
        local ok, data = pcall(api.nvim_eval_statusline, statuscol, {
          winid = win,
          use_statuscol_lnum = lnum,
          highlights = true,
          fillchar = ' ',
        })
        if ok then
          return data.str, data.highlights
        end
      end
      local relnum ---@type integer?
      if vim.wo[win].relativenumber then
        relnum = get_relative_line_num(lnum, win)
      end
      return string.format('%' .. width .. 'd', relnum or lnum)
    end

    ---@param bufnr integer
    ---@param row integer
    ---@param hl_group 'TreesitterContextBottom'|'TreesitterContextLineNumberBottom'
    local function highlight_bottom(bufnr, row, hl_group)
      add_extmark(bufnr, row, 0, { end_line = row + 1, hl_group = hl_group, hl_eol = true })
    end

    ---@param buf integer
    ---@param text string[]
    ---@param highlights StatusLineHighlight[][]
    local function highlight_lno_str(buf, text, highlights)
      for line, linehl in ipairs(highlights) do
        for hlidx, hl in ipairs(linehl) do
          local col = hl.start
          local endcol = hlidx < #linehl and linehl[hlidx + 1].start or #text[line]
          if col ~= endcol then
            local hl_groups = hl.groups or { hl.group }
            for i, shl in ipairs(hl_groups) do
              hl_groups[i] = shl:find('LineNr') and 'TreesitterContextLineNumber' or shl
            end
            add_extmark(buf, line - 1, col, {
              end_col = endcol,
              ---@diagnostic disable-next-line: assign-type-mismatch
              hl_group = hl.groups and hl_groups or hl_groups[1],
            })
          end
        end
      end
    end

    ---@param bufnr integer
    ---@param lines string[]
    ---@return boolean
    local function set_lines(bufnr, lines)
      local clines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local redraw = #clines ~= #lines
      if not redraw then
        for i, l in ipairs(clines) do
          if l ~= lines[i] then
            redraw = true
            break
          end
        end
      end
      if redraw then
        vim.bo[bufnr].modifiable = true
        api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.bo[bufnr].modifiable = false
        vim.bo[bufnr].modified = false
      end
      return redraw
    end

    ---@param win integer
    ---@param bufnr integer
    ---@param contexts Range4[]
    ---@param gutter_width integer
    local function render_lno(win, bufnr, contexts, gutter_width)
      local lno_text = {} ---@type string[]
      local lno_highlights = {} ---@type StatusLineHighlight[][]
      for _, range in ipairs(contexts) do
        for i = 1, util.get_range_height(range) do
          local txt, hl = build_lno_str(win, range[1] + i, gutter_width - 1)
          table.insert(lno_text, txt)
          table.insert(lno_highlights, hl)
        end
      end
      set_lines(bufnr, lno_text)
      highlight_lno_str(bufnr, lno_text, lno_highlights)
      highlight_bottom(bufnr, #lno_text - 1, 'TreesitterContextLineNumberBottom')
    end

    ---@param context_winid? integer
    local function close_win(context_winid)
      vim.schedule(function()
        if not context_winid or not api.nvim_win_is_valid(context_winid) then
          return
        end
        local bufnr = api.nvim_win_get_buf(context_winid)
        api.nvim_win_close(context_winid, true)
        if bufnr and api.nvim_buf_is_valid(bufnr) then
          buffer_pool[#buffer_pool + 1] = bufnr
        end
        if fn.getcmdwintype() == '' then
          while #buffer_pool > MAX_BUFFER_POOL_SIZE do
            local buf = table.remove(buffer_pool, #buffer_pool)
            if api.nvim_buf_is_valid(buf) then
              api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end)
    end

    ---@param winid integer
    ---@param context_winid integer
    local function horizontal_scroll_contexts(winid, context_winid)
      local active_win_view = api.nvim_win_call(winid, fn.winsaveview)
      ---@type vim.fn.winsaveview.ret
      local context_win_view = api.nvim_win_call(context_winid, fn.winsaveview)
      if active_win_view.leftcol ~= context_win_view.leftcol then
        api.nvim_win_call(context_winid, function()
          return fn.winrestview({ leftcol = active_win_view.leftcol })
        end)
      end
    end

    ---@param bufnr integer
    ---@param ctx_bufnr integer
    ---@param contexts Range4[]
    local function copy_extmarks(bufnr, ctx_bufnr, contexts)
      -- Build the namespace filter once per call rather than once per context range.
      local namespaces = {} ---@type table<integer, true>
      for nm, id in pairs(api.nvim_get_namespaces()) do
        if vim.startswith(nm, 'nvim.') then
          namespaces[id] = true
        end
      end

      local offset = 0
      for _, ctx in ipairs(contexts) do
        local ctx_srow, ctx_scol, ctx_erow, ctx_ecol = ctx[1], ctx[2], ctx[3], ctx[4]
        local extmarks = api.nvim_buf_get_extmarks(
          bufnr,
          -1,
          { ctx_srow, ctx_scol },
          { ctx_erow, ctx_ecol },
          { details = true }
        )

        ---@param e vim.api.keyset.get_extmark_item
        extmarks = vim.tbl_filter(function(e)
          return namespaces[
            (e[4] --[[@as vim.api.keyset.extmark_details]]).ns_id
          ]
        end, extmarks)

        for _, m_entry in ipairs(extmarks) do
          local id, row, col = m_entry[1], m_entry[2], m_entry[3]
          local opts = m_entry[4] --[[@as vim.api.keyset.extmark_details]]
          local start_row = offset + (row - ctx_srow)
          local end_row ---@type integer?
          local end_col = opts.end_col
          local mend_row = opts.end_row
          if mend_row then
            if is_after(mend_row, assert(end_col), ctx_erow, ctx_ecol) then
              mend_row = ctx_erow
              end_col = ctx_ecol
            end
            end_row = offset + (mend_row - ctx_srow)
          end
          local virt_text_pos = opts.virt_text_pos
          if virt_text_pos == 'win_col' then
            virt_text_pos = nil
          end
          pcall(add_extmark, ctx_bufnr, start_row, col, {
            id = id,
            end_row = end_row,
            end_col = end_col,
            priority = opts.priority,
            hl_group = opts.hl_group,
            ---@diagnostic disable-next-line: assign-type-mismatch
            end_right_gravity = opts.end_right_gravity,
            right_gravity = opts.right_gravity,
            hl_eol = opts.hl_eol,
            virt_text = opts.virt_text,
            virt_text_hide = opts.virt_text_hide,
            virt_text_pos = virt_text_pos,
            virt_text_repeat_linebreak = opts.virt_text_repeat_linebreak,
            virt_text_win_col = opts.virt_text_win_col,
            hl_mode = opts.hl_mode,
            line_hl_group = opts.line_hl_group,
            spell = opts.spell,
            ---@diagnostic disable-next-line: assign-type-mismatch
            url = opts.url,
          }, opts.ns_id)
        end
        offset = offset + util.get_range_height(ctx)
      end
    end

    local R = {}

    ---@param winid integer
    ---@param ctx_ranges Range4[]
    ---@param ctx_lines string[]
    ---@param force_hl_update? boolean
    function R.open(winid, ctx_ranges, ctx_lines, force_hl_update)
      local bufnr = api.nvim_win_get_buf(winid)
      local gutter_width = get_gutter_width(winid)
      local win_width = math.max(1, api.nvim_win_get_width(winid) - gutter_width)
      local win_height = math.max(1, #ctx_lines)

      window_contexts[winid] = window_contexts[winid] or {}
      local wctx = window_contexts[winid]

      if gutter_width > 0 then
        wctx.gutter_winid = display_window(
          winid,
          wctx.gutter_winid,
          gutter_width,
          win_height,
          0,
          'treesitter_context_line_number',
          'TreesitterContextLineNumber'
        )
        if
          api.nvim_win_is_valid(wctx.gutter_winid)
          and (vim.wo[winid].number or vim.wo[winid].relativenumber)
        then
          render_lno(winid, api.nvim_win_get_buf(wctx.gutter_winid), ctx_ranges, gutter_width)
        end
      else
        close_win(wctx.gutter_winid)
        wctx.gutter_winid = nil
      end

      wctx.context_winid = display_window(
        winid,
        wctx.context_winid,
        win_width,
        win_height,
        gutter_width,
        'treesitter_context',
        'TreesitterContext'
      )

      if not api.nvim_win_is_valid(wctx.context_winid) then
        return
      end

      local ctx_bufnr = api.nvim_win_get_buf(wctx.context_winid)
      local changed = set_lines(ctx_bufnr, ctx_lines)

      if changed or force_hl_update then
        api.nvim_buf_clear_namespace(ctx_bufnr, -1, 0, -1)
        highlight_contexts(bufnr, ctx_bufnr, ctx_ranges)
        copy_extmarks(bufnr, ctx_bufnr, ctx_ranges)
        highlight_bottom(ctx_bufnr, win_height - 1, 'TreesitterContextBottom')
        horizontal_scroll_contexts(winid, wctx.context_winid)
      end
    end

    ---@param exclude_winids integer[]
    function R.close_contexts(exclude_winids)
      for winid in pairs(window_contexts) do
        if not vim.tbl_contains(exclude_winids, winid) then
          R.close(winid)
        end
      end
    end

    ---@param winid integer
    function R.close(winid)
      local wctx = window_contexts[winid]
      if wctx then
        close_win(wctx.context_winid)
        close_win(wctx.gutter_winid)
        window_contexts[winid] = nil
      end
    end

    return R
  end)()

  -- ── context.get ─────────────────────────────────────────────────────────

  local fn, api = vim.fn, vim.api
  local get_query = vim.treesitter.query.get or vim.treesitter.query.get_query

  ---@param langtree vim.treesitter.LanguageTree
  ---@param range Range4
  ---@return TSNode[]?
  local function get_parent_nodes(langtree, range)
    local tree = langtree:tree_for_range(range, { ignore_injections = true })
    if not tree then
      return
    end
    local root = tree:root()
    local n = root:named_descendant_for_range(unpack(range))
    if not n then
      return
    end
    local ret = {} ---@type TSNode[]
    ---@diagnostic disable-next-line: undefined-field
    if root.child_with_descendant ~= nil then
      local p = root ---@type TSNode?
      while p do
        ret[#ret + 1] = p
        ---@diagnostic disable-next-line: undefined-field
        p = p:child_with_descendant(n) ---@type TSNode?
      end
      ret[#ret + 1] = n
    else
      while n do
        table.insert(ret, 1, n)
        n = n:parent() ---@type TSNode?
      end
    end
    return ret
  end

  ---@param winid integer
  ---@param percent string
  ---@return integer
  local function max_lines_from_string(winid, percent)
    local win_height = api.nvim_win_get_height(winid)
    local percent_s = percent:match('^(%d+)%%$')
    local percent1 = percent_s and tonumber(percent_s, 10) or 0
    return math.ceil((percent1 / 100) * win_height)
  end

  ---@param winid integer
  ---@return integer
  local function calc_max_lines(winid)
    local max_lines = config.max_lines
    if type(max_lines) == 'string' then
      max_lines = max_lines_from_string(winid, max_lines)
    end
    max_lines = max_lines == 0 and -1 or max_lines
    local wintop = fn.line('w0', winid)
    local cursor = fn.line('.', winid)
    local max_from_cursor = cursor - wintop
    if config.separator and max_from_cursor > 0 then
      max_from_cursor = max_from_cursor - 1
    end
    return max_lines ~= -1 and math.min(max_lines, max_from_cursor) or max_from_cursor
  end

  ---@param node TSNode
  ---@param bufnr integer
  ---@return string
  local function hash_args(node, bufnr)
    return table.concat({
      node:id(),
      node:symbol(),
      node:child_count(),
      node:type(),
      node:range(),
      bufnr,
    }, ',')
  end

  ---@param node TSNode
  ---@param bufnr integer
  ---@param query vim.treesitter.Query
  ---@return Range4?
  local context_range = cache.memoize(function(node, bufnr, query)
    ---@diagnostic disable-next-line: missing-fields
    local range = { node:range() } ---@type Range4
    range[3] = range[1] + 1
    range[4] = 0
    for _, match in query:iter_matches(node, bufnr, 0, -1, { max_start_depth = 0 }) do
      local r = false
      for id, nodes in pairs(match) do
        ---@type TSNode
        local node0 = type(nodes) == 'table' and nodes[#nodes] or nodes
        local srow, scol, erow, ecol = node0:range()
        local name = query.captures[id]
        if name == 'context' then
          r = r or (node == node0)
        elseif name == 'context.start' then
          range[1] = srow
          range[2] = scol
        elseif name == 'context.final' then
          range[3] = erow
          range[4] = ecol
        elseif name == 'context.end' then
          range[3] = srow
          range[4] = scol
        end
      end
      if r then
        return range
      end
    end
  end, hash_args)

  ---@param lang string
  ---@return vim.treesitter.Query?
  local function get_context_query(lang)
    local ok, query = pcall(get_query, lang, 'context')
    if not ok then
      vim.notify_once(
        string.format('Unable to load context query for %s:\n%s', lang, query),
        vim.log.levels.ERROR,
        { title = 'nvim-treesitter-context' }
      )
      return
    end
    return query
  end

  ---@param context_ranges Range4[]
  ---@param context_lines string[][]
  ---@param trim integer
  ---@param top boolean
  local function trim_contexts(context_ranges, context_lines, trim, top)
    while trim > 0 do
      local idx = top and 1 or #context_ranges
      local context_to_trim = context_ranges[idx]
      if not context_to_trim then
        return
      end
      local height = util.get_range_height(context_to_trim)
      if height <= trim then
        table.remove(context_ranges, idx)
        table.remove(context_lines, idx)
      else
        context_to_trim[3] = context_to_trim[3] - trim + (context_to_trim[4] == 0 and 0 or 1)
        context_to_trim[4] = 0
        local lines_to_trim = context_lines[idx]
        for _ = 1, trim do
          lines_to_trim[#lines_to_trim] = nil
        end
      end
      trim = math.max(0, trim - height)
    end
  end

  ---@param range Range4
  ---@param bufnr integer
  ---@return Range4, string[]
  local function get_text_for_range(range, bufnr)
    local start_row, end_row, end_col = range[1], range[3], range[4]
    if end_col == 0 then
      end_row = end_row - 1
      end_col = -1
    end
    local lines = api.nvim_buf_get_text(bufnr, start_row, 0, end_row, -1, {})
    while #lines > 0 do
      local last_line_of_node = lines[#lines]:sub(1, end_col)
      if last_line_of_node:match('%S') and #lines <= config.multiline_threshold then
        break
      end
      lines[#lines] = nil
      end_col = -1
      end_row = end_row - 1
    end
    if end_col ~= 0 then
      end_col = 0
      end_row = end_row + 1
    end
    return { start_row, 0, end_row, end_col }, lines
  end

  ---@param bufnr integer
  ---@param range Range4
  ---@return vim.treesitter.LanguageTree[]
  local function get_parent_langtrees(bufnr, range)
    local root_tree = vim.treesitter.get_parser(bufnr)
    if not root_tree then
      return {}
    end
    ---@diagnostic disable-next-line: redundant-parameter
    root_tree:parse(range, function(...) end)
    local ret = { root_tree }
    while true do
      local child_langtree = nil
      for _, langtree in pairs(ret[#ret]:children()) do
        if langtree:contains(range) then
          child_langtree = langtree
          break
        end
      end
      if not child_langtree then
        break
      end
      ret[#ret + 1] = child_langtree
    end
    return ret
  end

  ---@param bufnr integer
  ---@param line_range Range4
  ---@return fun(): TSNode[]?, vim.treesitter.Query?
  local function iter_context_parents(bufnr, line_range)
    local i = 0
    local trees = get_parent_langtrees(bufnr, line_range)
    return function()
      ---@type TSNode[]?, vim.treesitter.Query?
      local parents, query
      repeat
        i = i + 1
        local tree = trees[i]
        if not tree then
          return
        end
        parents = get_parent_nodes(tree, line_range)
        query = get_context_query(tree:lang())
      until parents and query
      return parents, query
    end
  end

  ---@param range Range4
  ---@return boolean
  local function range_is_valid(range)
    return not (range[1] == range[3] and range[2] == range[4])
  end

  ---@param winid? integer
  ---@return Range4[]?, string[]?
  local function get(winid)
    winid = winid or api.nvim_get_current_win()
    local bufnr = api.nvim_win_get_buf(winid)
    if not api.nvim_buf_is_loaded(bufnr) then
      return
    end
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
      return
    end

    local max_lines = calc_max_lines(winid)
    local top_row = fn.line('w0', winid) - 1
    local row, col ---@type integer, integer

    if config.mode == 'topline' then
      row, col = top_row, 0
    else
      local c = api.nvim_win_get_cursor(winid)
      row, col = c[1] - 1, c[2]
    end

    local context_ranges = {} ---@type Range4[]
    local context_lines = {} ---@type string[][]
    local contexts_height = 0

    for offset = 0, max_lines do
      local node_row = row + offset
      local col0 = offset == 0 and col or 0
      local line_range = { node_row, col0, node_row, col0 + 1 }

      context_ranges = {}
      context_lines = {}
      contexts_height = 0

      for parents, query in iter_context_parents(bufnr, line_range) do
        for _, parent in ipairs(parents) do
          local parent_start_row = parent:range()
          local num_context_lines = math.min(max_lines, contexts_height)
          local separator_offset = (num_context_lines > 0 and config.separator) and 1 or 0
          local contexts_end_row = top_row + separator_offset + num_context_lines

          if parent_start_row < contexts_end_row then
            local range0 = context_range(parent, bufnr, query)
            if range0 and range_is_valid(range0) then
              local range, lines = get_text_for_range(range0, bufnr)
              if range_is_valid(range) then
                local last_context = context_ranges[#context_ranges]
                if last_context and parent_start_row == last_context[1] then
                  contexts_height = contexts_height - util.get_range_height(last_context)
                  context_ranges[#context_ranges] = nil
                  context_lines[#context_lines] = nil
                end
                contexts_height = contexts_height + util.get_range_height(range)
                context_ranges[#context_ranges + 1] = range
                context_lines[#context_lines + 1] = lines
              end
            end
          end
        end
      end

      local contexts_end_row = top_row + math.min(max_lines, contexts_height)
      if node_row >= contexts_end_row then
        break
      end
    end

    local trim = contexts_height - max_lines
    if trim > 0 then
      trim_contexts(context_ranges, context_lines, trim, config.trim_scope == 'outer')
    end

    -- vim.iter(...):flatten():totable() requires nvim 0.10+, which we target.
    return context_ranges, vim.iter(context_lines):flatten():totable()
  end

  return { get = get, config = config, render = render }
end)()

-- ============================================================
-- M  (the module your config returns)
-- ============================================================

local api = vim.api
local enabled = false
local attached = {} ---@type table<integer, true>

---@generic F: function
---@param f F
---@return F
local function throttle_by_id(f)
  local timers = {} ---@type table<any, uv.uv_timer_t>
  local scheduled = {} ---@type table<any, true?>
  local waiting = {} ---@type table<any, boolean>
  local function r(id)
    if not scheduled[id] then
      scheduled[id] = true
      vim.schedule(function()
        timers[id] = timers[id] or assert(vim.uv.new_timer())
        timers[id]:start(150, 0, function()
          scheduled[id] = nil
          if waiting[id] then
            waiting[id] = nil
            r(id)
          elseif timers[id] then
            if not timers[id]:is_closing() then
              timers[id]:stop()
              timers[id]:close()
            end
            timers[id] = nil
          end
        end)
        f(id)
      end)
    elseif timers[id] and timers[id]:get_due_in() > 0 then
      waiting[id] = true
    end
  end
  return r
end

---@param args table
local function au_close(args)
  local winid = args.event == 'WinClosed' and tonumber(args.match) or api.nvim_get_current_win()
  context.render.close(winid)
end

---@param winid integer
local function cannot_open(winid)
  local bufnr = api.nvim_win_get_buf(winid)
  return not attached[bufnr]
    or vim.bo[bufnr].filetype == ''
    or vim.wo[winid].previewwindow
    or api.nvim_win_get_height(winid) < context.config.min_window_height
end

---@param winid integer
---@param force_hl_update? boolean
local update_win = throttle_by_id(function(winid, force_hl_update)
  context.render.close_contexts(context.config.multiwindow and api.nvim_list_wins() or { winid })
  if not api.nvim_win_is_valid(winid) or vim.fn.getcmdtype() ~= '' then
    return
  end
  if
    cannot_open(winid) or not context.config.multiwindow and winid ~= api.nvim_get_current_win()
  then
    context.render.close(winid)
    return
  end
  local context_ranges, context_lines = context.get(winid)
  if not context_ranges or #context_ranges == 0 then
    context.render.close(winid)
    return
  end
  context.render.open(winid, context_ranges, assert(context_lines), force_hl_update)
end)

local multiwindow_events = { WinResized = true, User = true }
local force_hl_events = { DiagnosticChanged = true, LspRequest = true }

---@param event? string
local function update(event)
  local wins = (context.config.multiwindow and multiwindow_events[event]) and api.nvim_list_wins()
    or { api.nvim_get_current_win() }
  for _, win in ipairs(wins) do
    update_win(win, force_hl_events[event])
  end
end

---@param args table
local function au_update(args)
  if args.event == 'OptionSet' and args.match ~= 'number' and args.match ~= 'relativenumber' then
    return
  end
  update(args.event)
end

---@param bufnr integer
---@return boolean?
local function should_attach(bufnr)
  local on_attach = context.config.on_attach
  if not on_attach or on_attach(bufnr) ~= false then
    return true
  end
  return nil
end

---@param req { type: string, method: string }
---@return boolean
local function is_semantic_tokens_request(req)
  local ms = require('vim.lsp.protocol').Methods
  return req.type == 'complete'
    and (
      req.method == ms.textDocument_semanticTokens_full
      or req.method == ms.textDocument_semanticTokens_full_delta
      or req.method == ms.textDocument_semanticTokens_range
    )
end

---@param event string|string[]
---@param callback fun(args: table): boolean?
---@param opts? vim.api.keyset.create_autocmd
local function autocmd(event, callback, opts)
  opts = opts or {}
  opts.callback = callback
  -- group is set by the caller (M.enable) to ensure it uses the live group id.
  api.nvim_create_autocmd(event, opts)
end

function M.enable()
  if enabled then
    M.disable()
  end

  -- Create (or recreate) the augroup here so disable's clear is always paired
  -- with an enable, and we never hold a stale group id from file-load time.
  local group = api.nvim_create_augroup('treesitter_context_update', {})

  local function au(event, callback, opts)
    opts = opts or {}
    opts.group = group
    autocmd(event, callback, opts)
  end

  for _, bufnr in pairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) then
      attached[bufnr] = should_attach(bufnr)
    end
  end

  au({
    'WinScrolled',
    'BufEnter',
    'WinEnter',
    'VimResized',
    'CursorMoved',
    'OptionSet',
    'WinResized',
  }, au_update)
  au('DiagnosticChanged', vim.schedule_wrap(au_update))
  au({ 'BufReadPost', 'FileType' }, function(args)
    attached[args.buf] = should_attach(args.buf)
  end)
  au('BufDelete', function(args)
    attached[args.buf] = nil
  end)

  if context.config.multiwindow then
    au({ 'WinClosed' }, au_close)
  else
    au({ 'BufLeave', 'WinLeave', 'WinClosed' }, au_close)
  end

  au('User', au_close, { pattern = 'SessionSavePre' })
  au('User', au_update, { pattern = 'SessionSavePost' })
  au('LspRequest', function(args)
    if is_semantic_tokens_request(args.data.request) then
      vim.schedule(function()
        au_update(args)
      end)
    end
  end)

  update()
  enabled = true
end

function M.disable()
  api.nvim_create_augroup('treesitter_context_update', {})
  for _, winid in pairs(api.nvim_list_wins()) do
    context.render.close(winid)
  end
  attached = {}
  enabled = false
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

---@return boolean
function M.enabled()
  return enabled
end

---@param depth? integer default 1
function M.go_to_context(depth)
  depth = depth or 1
  local line = api.nvim_win_get_cursor(0)[1]
  local ctx = nil
  local contexts = context.get() or {}
  for idx = #contexts, 1, -1 do
    local c = contexts[idx]
    if depth == 0 then
      break
    end
    if c[1] + 1 < line then
      ctx = c
      depth = depth - 1
    end
  end
  if not ctx then
    return
  end
  vim.cmd([[ normal! m' ]])
  api.nvim_win_set_cursor(0, { ctx[1] + 1, ctx[2] })
end

-- ── highlights & user command ────────────────────────────────────────────

api.nvim_set_hl(0, 'TreesitterContext', { link = 'NormalFloat', default = true })
api.nvim_set_hl(0, 'TreesitterContextLineNumber', {
  link = 'LineNr',
  default = true,
})
api.nvim_set_hl(0, 'TreesitterContextBottom', { link = 'NONE', default = true })
api.nvim_set_hl(
  0,
  'TreesitterContextLineNumberBottom',
  { link = 'TreesitterContextBottom', default = true }
)
api.nvim_set_hl(0, 'TreesitterContextSeparator', {
  link = 'FloatBorder',
  default = true,
})

local subcmds = { 'enable', 'disable', 'toggle' }

api.nvim_create_user_command('TSContext', function(args)
  if #args.fargs == 0 then
    vim.ui.select(subcmds, {
      prompt = 'Treesitter Context: ',
      format_item = function(item)
        return item:sub(1, 1):upper() .. item:sub(2)
      end,
    }, function(choice)
      if choice and M[choice] then
        M[choice]()
      end
    end)
    return
  end
  local cmd = args.fargs[1]
  if M[cmd] then
    M[cmd]()
  else
    vim.notify('TSContext: Unknown command ' .. cmd, vim.log.levels.ERROR)
  end
end, {
  complete = function()
    return subcmds
  end,
  nargs = '*',
  desc = 'Manage Treesitter Context',
})

-- ── setup ────────────────────────────────────────────────────────────────

---@param options? TSContext.UserConfig
function M.setup(options)
  if options then
    context.config.update(options)
  end
  if context.config.enable then
    M.enable()
  else
    M.disable()
  end
end

return M
