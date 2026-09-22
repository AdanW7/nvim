local M = {}

---@class TSSetupOpts
---@field ensure_installed string[]  Parsers to install at startup if missing.
---@field auto_install boolean       Install a missing parser when a matching filetype is opened.
---@field install_dir string         Where parsers and queries are installed.
---@field max_jobs integer           Max parallel parser installs.
---@field highlight { enable: boolean, disable: string[], max_filesize: integer? }
---@field fold { enable: boolean, open_by_default: boolean }
---@field indent string[]            Languages that use treesitter indent (experimental).
M.defaults = {
  ensure_installed = {
    'bash',
    'c',
    'cmake',
    'cpp',
    'css',
    'html',
    'javascript',
    'json',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'python',
    'powershell',
    'query',
    'regex',
    'rust',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'xml',
    'yaml',
  },
  auto_install = true,
  install_dir = vim.fn.stdpath('data') .. '/site',
  max_jobs = 8,
  highlight = {
    enable = true,
    disable = {}, -- parser names, e.g. { 'latex' }
    max_filesize = 1024 * 1024, -- skip highlighting for files larger than this (bytes); nil = no limit
  },
  fold = {
    enable = true,
    open_by_default = true, -- sets 'foldlevelstart' to 99 so folds start open
  },
  indent = {}, -- e.g. { 'lua', 'rust', 'typescript' }
}

---@param msg string
---@param level? integer
local function notify(msg, level)
  vim.schedule(function()
    vim.notify('treesitter: ' .. msg, level or vim.log.levels.INFO)
  end)
end

--- Returns true if a parser can be built (all external tools are present).
---@return boolean can_install
local function check_tools()
  local missing = {}
  for _, exe in ipairs({ 'tar', 'curl', 'tree-sitter' }) do
    if vim.fn.executable(exe) == 0 then
      missing[#missing + 1] = exe
    end
  end

  local has_compiler = false
  for _, cc in ipairs({ 'cc', 'gcc', 'clang', 'cl', 'zig' }) do
    if vim.fn.executable(cc) == 1 then
      has_compiler = true
      break
    end
  end
  if not has_compiler then
    missing[#missing + 1] = 'a C compiler'
  end

  if #missing > 0 then
    notify(
      'parser installation disabled, missing: '
        .. table.concat(missing, ', ')
        .. '\nAlready-installed parsers still work. See the header of this file for requirements.',
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

---@param user_opts? TSSetupOpts
function M.setup(user_opts)
  if vim.fn.has('nvim-0.12') == 0 then
    notify(
      'Neovim 0.12+ is required (uses vim.pack and the nvim-treesitter main branch).',
      vim.log.levels.ERROR
    )
    return
  end

  local opts = vim.tbl_deep_extend('force', M.defaults, user_opts or {})
  local can_install = check_tools()

  local indent = {}
  for _, lang in ipairs(opts.indent) do
    indent[lang] = true
  end
  local no_highlight = {}
  for _, lang in ipairs(opts.highlight.disable) do
    no_highlight[lang] = true
  end

  -----------------------------------------------------------------------------
  -- Plugin install / update
  -----------------------------------------------------------------------------

  -- Registered BEFORE vim.pack.add so it also fires on the very first install.
  -- nvim-treesitter is only guaranteed to work with matching parser versions,
  -- so every plugin install/update must be followed by :TSUpdate.
  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('treesitter_pack', { clear = true }),
    callback = function(ev)
      local data = ev.data
      if
        data.spec.name == 'nvim-treesitter' and (data.kind == 'install' or data.kind == 'update')
      then
        if not data.active then
          vim.cmd.packadd('nvim-treesitter')
        end
        if can_install then
          vim.cmd('TSUpdate')
        end
      end
    end,
  })

  vim.pack.add({
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  }, { load = true, confirm = false })

  local ts = require('nvim-treesitter')
  ts.setup({ install_dir = opts.install_dir })

  -- No-op for parsers that are already installed; runs asynchronously.
  if can_install and #opts.ensure_installed > 0 then
    ts.install(opts.ensure_installed, { max_jobs = opts.max_jobs })
  end

  if opts.fold.enable and opts.fold.open_by_default then
    vim.o.foldlevelstart = 99
  end

  -----------------------------------------------------------------------------
  -- Per-buffer features
  -----------------------------------------------------------------------------

  ---@type table<string, boolean>?
  local available
  local function is_available(lang)
    if not available then
      available = {}
      for _, l in ipairs(ts.get_available()) do
        available[l] = true
      end
    end
    return available[lang] == true
  end

  local function too_large(buf)
    local max = opts.highlight.max_filesize
    if not max then
      return false
    end
    local name = vim.api.nvim_buf_get_name(buf)
    if name == '' then
      return false
    end
    local ok, stat = pcall(vim.uv.fs_stat, name)
    return ok and stat ~= nil and stat.size > max
  end

  --- Enable treesitter features for a buffer. Returns false if no parser is available.
  ---@param buf integer
  ---@param lang string
  ---@return boolean
  local function attach(buf, lang)
    if not vim.api.nvim_buf_is_valid(buf) then
      return false
    end

    if opts.highlight.enable and not no_highlight[lang] and not too_large(buf) then
      -- Errors if no parser can be loaded for this language.
      if not pcall(vim.treesitter.start, buf, lang) then
        return false
      end
    elseif not pcall(vim.treesitter.language.add, lang) then
      return false
    end

    if opts.fold.enable then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.wo[win][0].foldmethod = 'expr'
        vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end
    end

    if indent[lang] then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
    return true
  end

  local pending = {} ---@type table<string, boolean>

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter_attach', { clear = true }),
    callback = function(ev)
      local lang = vim.treesitter.language.get_lang(ev.match)
      if not lang or attach(ev.buf, lang) then
        return
      end

      -- No parser yet: install on demand, then attach to every matching open buffer.
      if not (opts.auto_install and can_install) or pending[lang] or not is_available(lang) then
        return
      end
      pending[lang] = true
      ts.install(lang, { max_jobs = opts.max_jobs }):await(function()
        pending[lang] = nil
        vim.schedule(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if
              vim.api.nvim_buf_is_loaded(buf)
              and vim.treesitter.language.get_lang(vim.bo[buf].filetype) == lang
            then
              attach(buf, lang)
            end
          end
        end)
      end)
    end,
  })
end

return M
