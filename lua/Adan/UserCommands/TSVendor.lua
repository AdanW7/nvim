---@class TSVendor.GitResult
---@field code integer
---@field stderr? string

---@param repo string "owner/repo" GitHub path
---@param callback fun(tmp_dir: string|nil)
local function git_shallow_clone(repo, callback)
  local tmp = vim.fn.tempname()
  ---@type string[]
  local args = {
    'git',
    'clone',
    '--depth=1',
    '--filter=blob:none',
    '--sparse',
    '--quiet',
    'https://github.com/' .. repo,
    tmp,
  }
  vim.system(args, { text = true }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: git clone failed for %s\n%s', repo, res.stderr or ''),
          vim.log.levels.ERROR
        )
      end)
      callback(nil)
    else
      callback(tmp)
    end
  end)
end

---@param tmp_dir string
---@param sparse_path string Path inside the repo to sparse-checkout, e.g. "runtime/queries"
---@param callback fun(ok: boolean)
local function git_sparse_checkout(tmp_dir, sparse_path, callback)
  vim.system(
    { 'git', '-C', tmp_dir, 'sparse-checkout', 'set', '--no-cone', sparse_path },
    { text = true },
    function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          vim.notify(
            string.format(
              'TSVendor: sparse-checkout failed for %s\n%s',
              sparse_path,
              res.stderr or ''
            ),
            vim.log.levels.ERROR
          )
        end)
        callback(false)
      else
        callback(true)
      end
    end
  )
end

-- TSVendor command ---------------------------------------------------------

vim.api.nvim_create_user_command('TSVendor', function()
  local queries_dir = vim.fn.stdpath('config') .. '/after/queries'

  ---@type Adan.TSVendorSpec[]
  local source_specs = {
    {
      name = 'tree-sitter-manager',
      repo = 'romus204/tree-sitter-manager.nvim',
      queries_path = 'runtime/queries',
      exclude = { ['textobjects.scm'] = true },
    },
    {
      name = 'nvim-treesitter-textobjects',
      repo = 'nvim-treesitter/nvim-treesitter-textobjects',
      queries_path = 'queries',
      filename = 'textobjects.scm',
    },
    {
      name = 'nvim-treesitter-context',
      repo = 'nvim-treesitter/nvim-treesitter-context',
      queries_path = 'queries',
      filename = 'context.scm',
    },
  }

  ---@type integer
  local installed = 0
  ---@type string[]
  local failed = {}
  ---@type integer
  local phases_done = 0
  local total_phases = #source_specs

  local function check_complete()
    if phases_done == total_phases then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: %d files installed, %d failed', installed, #failed),
          vim.log.levels.INFO
        )
        if #failed > 0 then
          vim.notify('TSVendor failed:\n' .. table.concat(failed, '\n'), vim.log.levels.WARN)
        end
      end)
    end
  end

  ---@param src string Absolute path to source file
  ---@param dst string Absolute path to destination file
  ---@param label string Relative path used in failure messages, e.g. "lua/highlights.scm"
  local function copy_file(src, dst, label)
    local ok, err = vim.uv.fs_copyfile(src, dst)
    if ok then
      installed = installed + 1
    else
      table.insert(failed, string.format('%s (%s)', label, err or 'unknown error'))
    end
  end

  ---@param spec Adan.TSVendorSpec
  ---@param tmp_dir string
  local function install_files(spec, tmp_dir)
    local src_queries = tmp_dir .. '/' .. spec.queries_path

    local top_handle, err = vim.uv.fs_scandir(src_queries)
    if not top_handle then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: could not scan queries dir from %s: %s', spec.name, err or ''),
          vim.log.levels.ERROR
        )
      end)
      return
    end

    ---@type string[]
    local langs = {}
    while true do
      local entry_name, entry_type = vim.uv.fs_scandir_next(top_handle)
      if not entry_name then
        break
      end
      if entry_type == 'directory' then
        table.insert(langs, entry_name)
      end
    end

    vim.schedule(function()
      vim.notify(
        string.format('TSVendor: installing %d languages from %s', #langs, spec.name),
        vim.log.levels.INFO
      )

      for _, lang in ipairs(langs) do
        local src_lang = src_queries .. '/' .. lang
        local dst_lang = queries_dir .. '/' .. lang
        vim.fn.mkdir(dst_lang, 'p')

        if spec.filename then
          local src = src_lang .. '/' .. spec.filename
          if vim.uv.fs_stat(src) then
            copy_file(src, dst_lang .. '/' .. spec.filename, lang .. '/' .. spec.filename)
          end
        else
          local lang_handle = vim.uv.fs_scandir(src_lang)
          if lang_handle then
            while true do
              local fname = vim.uv.fs_scandir_next(lang_handle)
              if not fname then
                break
              end
              if fname:match('%.scm$') and not (spec.exclude or {})[fname] then
                copy_file(src_lang .. '/' .. fname, dst_lang .. '/' .. fname, lang .. '/' .. fname)
              end
            end
          end
        end
      end

      vim.fn.delete(tmp_dir, 'rf')
      phases_done = phases_done + 1
      check_complete()
    end)
  end

  ---@param spec Adan.TSVendorSpec
  local function run_phase(spec)
    vim.notify('TSVendor: cloning ' .. spec.name .. '...', vim.log.levels.INFO)

    git_shallow_clone(spec.repo, function(tmp_dir)
      if not tmp_dir then
        phases_done = phases_done + 1
        check_complete()
        return
      end

      git_sparse_checkout(tmp_dir, spec.queries_path, function(ok)
        if not ok then
          vim.fn.delete(tmp_dir, 'rf')
          phases_done = phases_done + 1
          check_complete()
          return
        end

        install_files(spec, tmp_dir)
      end)
    end)
  end

  for _, spec in ipairs(source_specs) do
    run_phase(spec)
  end
end, {
  desc = 'Vendor all treesitter query files from tree-sitter-manager and nvim-treesitter-textobjects',
})
