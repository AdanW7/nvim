---What this does:
---  * Highlights keywords (TODO, FIXME, HACK, WARN, PERF, NOTE, TEST) but
---    ONLY when they appear inside a comment, as determined by Tree-sitter
---    (preferred) or the buffer's :syntax highlighting (fallback).
---  * Highlights Doxygen tags (`@brief`, `@param`, `\brief`, `@{`, `@}`, ...)
---    and the trailing-doc `<` marker (as in `/**<`, `/*!<`, `///<`, `//!<`),
---    again only inside comments. Purely cosmetic - no quickfix support.
---  * Exposes two user commands that populate the quickfix list with
---    keyword matches that are actually inside comments:
---      `:TodoQuickFix`     - only currently open (loaded, listed) buffers
---      `:TodoQuickFixRepo` - the whole project, via ripgrep
---
---Usage (in your config):
---  require('todo').setup()
---
---  -- or, to override/extend keywords -> highlight group:
---  require('todo').setup({
---    keywords = {
---      TODO = 'DiagnosticInfo',
---      XXX = 'DiagnosticWarn',
---    },
---    doxygen = {
---      enabled = true,
---      tag_hl = 'Special',
---      angle_hl = 'Special',
---    },
---  })
---@class TodoComments
local M = {}

local ns = vim.api.nvim_create_namespace('todo_comments')

---Default keyword -> highlight group. Groups are linked with `default = true`
---so a colorscheme or user config can override them freely.
local default_keywords = {
  TODO = 'DiagnosticInfo',
  FIXME = 'DiagnosticError',
  HACK = 'DiagnosticWarn',
  WARN = 'DiagnosticWarn',
  PERF = 'DiagnosticHint',
  NOTE = 'DiagnosticHint',
  TEST = 'DiagnosticInfo',
}

---Default Doxygen highlighting config.
---@class DoxygenConfig
---@field enabled boolean
---@field tag_hl string
---@field angle_hl string }
local default_doxygen = {
  enabled = true,
  tag_hl = 'Special', ---@type string highlight group for @tag / \tag
  angle_hl = 'Special', ---@type string highlight group for the trailing `<` marker
}

---@class TodoCommentsConfig
---@field keywords table<string,string> keyword -> highlight group to link to
---@field doxygen DoxygenConfig
local config = {
  keywords = vim.deepcopy(default_keywords),
  doxygen = vim.deepcopy(default_doxygen),
  regex = nil, ---@type vim.regex?
}

--------------------------------------------------------------------------------
-- Comment detection
--------------------------------------------------------------------------------

---Whether the given 0-indexed (row, col) position in `bufnr` is inside a
---comment. Tries Tree-sitter first (querying the parser's `highlights`
---capture group directly - NOT via `vim.treesitter.highlighter.active`,
---which only exists for buffers with an actively-started highlighter and
---silently reports nothing otherwise), then falls back to the legacy
---:syntax engine if no parser is available for the buffer's language.
---@param bufnr integer
---@param row integer 0-indexed line
---@param col integer 0-indexed byte column
---@return boolean
local function is_comment(bufnr, row, col)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
  if ok_parser and parser then
    pcall(function()
      parser:parse()
    end)

    local found = false
    parser:for_each_tree(function(tree, lang_tree)
      if found then
        return
      end
      local root = tree:root()
      local srow, _, erow, _ = root:range()
      if row < srow or row > erow then
        return
      end
      local ok_query, query = pcall(vim.treesitter.query.get, lang_tree:lang(), 'highlights')
      if ok_query and query then
        for id, node in query:iter_captures(root, bufnr, row, row + 1) do
          local name = query.captures[id]
          if name and name:find('comment') then
            local nsrow, nscol, nerow, necol = node:range()
            local after_start = row > nsrow or (row == nsrow and col >= nscol)
            local before_end = row < nerow or (row == nerow and col < necol)
            if after_start and before_end then
              found = true
              return
            end
          end
        end
      end
    end)
    -- A parser attached and got queried successfully: trust that result
    -- rather than falling through to the window-dependent legacy check.
    return found
  end

  -- No Tree-sitter parser available for this buffer's language: fall back
  -- to legacy syntax highlighting. synID() always inspects the *current*
  -- buffer, so run it inside nvim_buf_call to make sure `bufnr` is the
  -- active one for the duration of the check.
  local ok, name = pcall(vim.api.nvim_buf_call, bufnr, function()
    local id = vim.fn.synID(row + 1, col + 1, 1)
    if id == 0 then
      return nil
    end
    return vim.fn.synIDattr(id, 'name') or ''
  end)
  if ok and name then
    return name:lower():find('comment') ~= nil
  end
  return false
end

---Make sure `bufnr` has a filetype set. Buffers opened normally (via
---:edit, BufReadPost, etc.) get this for free, but a buffer created with
---`vim.fn.bufadd()` + `vim.fn.bufload()` (as :TodoQuickFixRepo does for
---files you don't currently have open) is NOT guaranteed to have one.
---Without a filetype, both the Tree-sitter parser lookup and legacy
---:syntax highlighting have nothing to attach to, so `is_comment()` would
---always report false for those files. This is what was silently
---dropping every match outside of already-open buffers.
---@param bufnr integer
---@param filename string
local function ensure_filetype(bufnr, filename)
  if vim.bo[bufnr].filetype ~= '' then
    return
  end
  local ok, ft = pcall(vim.filetype.match, { buf = bufnr, filename = filename })
  if ok and ft then
    vim.bo[bufnr].filetype = ft
  end
end

--------------------------------------------------------------------------------
-- Keyword scanning
--------------------------------------------------------------------------------

---Build (and cache) the vim.regex used to find keyword occurrences.
---@return vim.regex
local function get_regex()
  if not config.regex then
    local words = vim.tbl_keys(config.keywords)
    table.sort(words)
    config.regex = vim.regex('\\<\\(' .. table.concat(words, '\\|') .. '\\)\\>')
  end
  return config.regex
end

---Find every non-overlapping match of the keyword regex in `line`.
---@param line string
---@return { [1]: integer, [2]: integer }[] list of {start_col, end_col} (0-indexed, end exclusive)
local function find_matches(line)
  local regex = get_regex()
  local matches = {}
  local offset = 0
  while offset <= #line do
    local rest = line:sub(offset + 1)
    local s, e = regex:match_str(rest)
    if not s then
      break
    end
    table.insert(matches, { offset + s, offset + e })
    offset = offset + (e > s and e or e + 1)
  end
  return matches
end

---Scan `bufnr` and return every keyword match that sits inside a comment.
---@param bufnr integer
---@return { lnum: integer, col: integer, end_col: integer, keyword: string }[] 1-indexed lnum/col
function M.scan_buffer(bufnr)
  local results = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:find('%u') then -- cheap pre-filter before running the regex
      local row = i - 1
      for _, m in ipairs(find_matches(line)) do
        local start_col, end_col = m[1], m[2]
        if is_comment(bufnr, row, start_col) then
          table.insert(results, {
            lnum = i,
            col = start_col + 1,
            end_col = end_col,
            keyword = line:sub(start_col + 1, end_col),
          })
        end
      end
    end
  end
  return results
end

--------------------------------------------------------------------------------
-- Doxygen scanning
--------------------------------------------------------------------------------

-- @word / \word (also @{ and @} for \addtogroup ... @{ ... @} blocks).
local doxygen_tag_pattern = '[@\\][%a{}]+'

-- Comment openers whose last character is the "this documents the
-- preceding declaration" marker, e.g. `uint16_t x; /**< comment */`.
local doxygen_angle_markers = { '/**<', '/*!<', '///<', '//!<' }

---Find every non-overlapping match of `pattern` in `line` using plain Lua
---string patterns (not vim.regex - these patterns are simple enough that
---Lua's own matcher is sufficient and avoids the escaping headaches of
---translating `\` and `{}` into vim regex syntax).
---@param line string
---@param pattern string
---@return { [1]: integer, [2]: integer }[] list of {start_col, end_col} (0-indexed, end exclusive)
local function find_lua_pattern_matches(line, pattern)
  local matches = {}
  local start = 1
  while start <= #line do
    local s, e = line:find(pattern, start)
    if not s then
      break
    end
    table.insert(matches, { s - 1, e })
    start = e + 1
  end
  return matches
end

---Find the 0-indexed column of the trailing `<` for every occurrence of
---any `doxygen_angle_markers` entry in `line`.
---@param line string
---@return { [1]: integer, [2]: integer }[] list of {start_col, end_col} (0-indexed, end exclusive)
local function find_doxygen_angle_matches(line)
  local matches = {}
  for _, marker in ipairs(doxygen_angle_markers) do
    local start = 1
    while start <= #line do
      local s, e = line:find(marker, start, true)
      if not s then
        break
      end
      table.insert(matches, { e - 1, e })
      start = e + 1
    end
  end
  return matches
end

---Scan `bufnr` and return every Doxygen tag / trailing-`<` match that sits
---inside a comment.
---@param bufnr integer
---@return { lnum: integer, col: integer, end_col: integer, hl_group: string }[] 1-indexed lnum/col
function M.scan_doxygen(bufnr)
  local results = {}
  if not config.doxygen.enabled then
    return results
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local row = i - 1
    if line:find('[@\\]') then
      for _, m in ipairs(find_lua_pattern_matches(line, doxygen_tag_pattern)) do
        if is_comment(bufnr, row, m[1]) then
          table.insert(results, { lnum = i, col = m[1] + 1, end_col = m[2], hl_group = 'TodoDoxygenTag' })
        end
      end
    end
    if line:find('<', 1, true) then
      for _, m in ipairs(find_doxygen_angle_matches(line)) do
        if is_comment(bufnr, row, m[1]) then
          table.insert(results, { lnum = i, col = m[1] + 1, end_col = m[2], hl_group = 'TodoDoxygenAngle' })
        end
      end
    end
  end
  return results
end

--------------------------------------------------------------------------------
-- Highlighting
--------------------------------------------------------------------------------

local function define_highlights()
  for keyword, link in pairs(config.keywords) do
    vim.api.nvim_set_hl(0, 'Todo' .. keyword, { link = link, default = true })
  end
  vim.api.nvim_set_hl(0, 'TodoDoxygenTag', { link = config.doxygen.tag_hl, default = true })
  vim.api.nvim_set_hl(0, 'TodoDoxygenAngle', { link = config.doxygen.angle_hl, default = true })
end

---Re-scan `bufnr` (default: current buffer) and refresh its extmarks.
---@param bufnr integer?
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  if vim.bo[bufnr].buftype ~= '' then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for _, match in ipairs(M.scan_buffer(bufnr)) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, match.lnum - 1, match.col - 1, {
      end_col = match.end_col,
      hl_group = 'Todo' .. match.keyword,
    })
  end
  for _, match in ipairs(M.scan_doxygen(bufnr)) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, match.lnum - 1, match.col - 1, {
      end_col = match.end_col,
      hl_group = match.hl_group,
    })
  end
end

--------------------------------------------------------------------------------
-- Debounced auto-refresh
--------------------------------------------------------------------------------

local uv = vim.uv or vim.loop
local timers = {} ---@type table<integer, uv.uv_timer_t>

local function schedule_refresh(bufnr)
  local existing = timers[bufnr]
  if existing then
    existing:stop()
    existing:close()
  end
  local timer = uv.new_timer()
  if not timer then
    return
  end
  timers[bufnr] = timer
  timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        M.refresh(bufnr)
      end
    end)
  )
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup('TodoComments', { clear = true })
  vim.api.nvim_create_autocmd(
    { 'BufEnter', 'TextChanged', 'TextChangedI', 'InsertLeave', 'BufWritePost' },
    {
      group = group,
      callback = function(args)
        schedule_refresh(args.buf)
      end,
    }
  )
end

--------------------------------------------------------------------------------
-- :TodoQuickFix / :TodoQuickFixRepo
--------------------------------------------------------------------------------

---Best-effort project root: walk up from `start_dir` looking for a `.git`
---entry. Falls back to `start_dir` itself if no repo is found.
---@param start_dir string
---@return string
local function find_project_root(start_dir)
  local found = vim.fs.find('.git', { path = start_dir, upward = true, limit = 1 })[1]
  if found then
    return vim.fn.fnamemodify(found, ':h')
  end
  return start_dir
end

---Resolve the directory ripgrep should search from when no explicit path
---is given.
---  1. If the current tab has an explicit `:tcd` set, use that as-is -
---     that's a deliberate per-tab scope and should be respected, not
---     second-guessed by walking further up to a git root.
---  2. Otherwise, derive it from the *current buffer's* file location,
---     walking up to the nearest `.git`. This deliberately ignores the
---     global cwd: many configs (autochdir, LSP root detection,
---     project.nvim, etc.) change the global cwd as a side effect of
---     which buffers you've had open, which would otherwise make search
---     results silently depend on your buffer history rather than any
---     directory you actually chose.
---@return string
local function default_search_root()
  -- haslocaldir(-1, 0): 2 means the CURRENT TAB has an explicit :tcd
  -- (ignoring any window-local :lcd). getcwd(-1, 0) then returns that
  -- tab's directory.
  if vim.fn.haslocaldir(-1, 0) == 2 then
    return vim.fn.getcwd(-1, 0)
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  local start_dir = bufname ~= '' and vim.fn.fnamemodify(bufname, ':p:h') or vim.fn.getcwd()
  return find_project_root(start_dir)
end

---Run `rg --vimgrep` for the keyword pattern, scoped to `path` (a
---directory or file to search; always required so results don't depend
---on Neovim's ambient/global cwd).
---@param path string
---@return { file: string, lnum: integer, col: integer, text: string }[]
local function ripgrep_search(path)
  local words = vim.tbl_keys(config.keywords)
  table.sort(words)
  local pattern = '\\b(' .. table.concat(words, '|') .. ')\\b'
  local cmd =
    { 'rg', '--vimgrep', '--no-heading', '--color=never', '--hidden', '-e', pattern, path }
  local res = vim.system(cmd, { text = true }):wait()
  -- rg exits 1 when there are simply no matches; only >1 is a real error.
  if res.code ~= 0 and res.code ~= 1 then
    vim.notify('TodoQuickFix: rg failed: ' .. (res.stderr or 'unknown error'), vim.log.levels.ERROR)
    return {}
  end
  local items = {}
  for _, line in ipairs(vim.split(res.stdout or '', '\n', { trimempty = true })) do
    local file, lnum, col, text = line:match('^(.-):(%d+):(%d+):(.*)$')
    if file then
      file = vim.fn.fnamemodify(file, ':p')
      table.insert(items, { file = file, lnum = tonumber(lnum), col = tonumber(col), text = text })
    end
  end
  return items
end

---Scan every currently loaded, listed buffer (i.e. buffers you have open).
---@return { file: string, lnum: integer, col: integer, text: string }[]
local function loaded_buffers_search()
  local items = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= '' then
        for _, match in ipairs(M.scan_buffer(bufnr)) do
          local line = vim.api.nvim_buf_get_lines(bufnr, match.lnum - 1, match.lnum, false)[1] or ''
          table.insert(items, { file = name, lnum = match.lnum, col = match.col, text = line })
        end
      end
    end
  end
  return items
end

---Re-verify each candidate is actually inside a comment (loading its file
---into a real buffer if needed) and populate the quickfix list with the
---survivors.
---@param candidates { file: string, lnum: integer, col: integer, text: string }[]
---@param title string
local function populate_quickfix(candidates, title)
  local items = {}
  for _, candidate in ipairs(candidates) do
    local ok, bufnr = pcall(vim.fn.bufadd, candidate.file)
    if ok then
      vim.fn.bufload(bufnr)
      ensure_filetype(bufnr, candidate.file)
      local row, col = candidate.lnum - 1, candidate.col - 1
      local in_comment = vim.api.nvim_buf_call(bufnr, function()
        return is_comment(bufnr, row, col)
      end)
      if in_comment then
        table.insert(items, {
          filename = candidate.file,
          lnum = candidate.lnum,
          col = candidate.col,
          text = vim.trim(candidate.text),
        })
      end
    end
  end

  vim.fn.setqflist({}, ' ', { title = title, items = items })
  if #items > 0 then
    vim.cmd('copen')
  else
    vim.notify(title .. ': no todo comments found', vim.log.levels.INFO)
  end
end

---Populate the quickfix list with keyword matches found only in currently
---open (loaded, listed) buffers.
function M.quickfix()
  populate_quickfix(loaded_buffers_search(), 'TodoQuickFix')
end

---Populate the quickfix list with keyword matches found across the whole
---project via ripgrep, optionally scoped to `path`.
---@param path string? optional path/glob to restrict the ripgrep search to
function M.quickfix_repo(path)
  if vim.fn.executable('rg') ~= 1 then
    vim.notify('TodoQuickFixRepo: `rg` not found on PATH', vim.log.levels.ERROR)
    return
  end
  path = (path and path ~= '') and path or default_search_root()
  populate_quickfix(ripgrep_search(path), 'TodoQuickFixRepo')
end

local function create_commands()
  vim.api.nvim_create_user_command('TodoQuickFix', function()
    M.quickfix()
  end, {
    desc = 'Populate quickfix with TODO/FIXME/... comments from open buffers',
  })

  vim.api.nvim_create_user_command('TodoQuickFixRepo', function(opts)
    M.quickfix_repo(opts.args ~= '' and opts.args or nil)
  end, {
    nargs = '?',
    complete = 'file',
    desc = 'Populate quickfix with TODO/FIXME/... comments from the whole repo (optionally scoped to a path)',
  })
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@param opts { keywords: table<string,string>?, doxygen: { enabled: boolean?, tag_hl: string?, angle_hl: string? }? }?
function M.setup(opts)
  opts = opts or {}
  config.keywords = vim.tbl_extend('force', vim.deepcopy(default_keywords), opts.keywords or {})
  config.doxygen = vim.tbl_extend('force', vim.deepcopy(default_doxygen), opts.doxygen or {})
  config.regex = nil -- force rebuild with the (possibly new) keyword set

  define_highlights()
  create_autocmds()
  create_commands()

  -- Highlight the buffer(s) already open when setup() runs.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.refresh(bufnr)
    end
  end
end

return M
