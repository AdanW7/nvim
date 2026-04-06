local M = {}

---@type Adan.LspConfig
M.pyrefly = {
  cmd = { 'pyrefly', 'lsp' },
  settings = {
    python = {
      pyrefly = {
        displayTypeErrors = 'force-on',
      },
    },
  },
}

---@type Adan.LspConfig
M.ty = {
  settings = {
    ty = {
      diagnosticMode = 'openFilesOnly',
    },
  },
}

---@type Adan.LspConfig
M.ruff = {
  settings = {
    ['indent-width'] = 4,
    ['line-length'] = 120,
    ['target-version'] = 'py311',
    format = {
      preview = true,
    },
    lint = {
      fixable = { 'ALL' },
      ignore = { 'E501', 'F403', 'F405' },
      preview = true,
      select = { 'E4', 'E7', 'E9', 'F', 'B' },
    },
  },
}

---@type Adan.LspConfig
M.powershell_es = {
  bundle_path = vim.env.POWERSHELL_ES_BUNDLE_PATH
    or (vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services'),
  shell = (vim.fn.executable('pwsh') == 1 and 'pwsh')
    or (vim.fn.has('win32') == 1 and 'powershell.exe')
    or 'powershell',
  filetypes = { 'ps1', 'psm1', 'psd1', 'ps1xml', 'powershell' },
  settings = {
    powershell = {
      codeFormatting = {
        autoCorrectAliases = true,
        useCorrectCasing = true,
        pipelineIndentationStyle = 'IncreaseIndentationForFirstPipeline',
        preset = 'Stroustrup',
        openBraceOnSameLine = true,
        ignoreOneLineBlock = false,
        newLineAfterOpenBrace = true,
        newLineAfterCloseBrace = true,
        whitespaceAfterSeparator = true,
        whitespaceAroundOperator = true,
      },
      scriptAnalysis = {
        settingsPath = vim.fn.stdpath('config') .. '/psscriptanalyzer/Settings.psd1',
      },
    },
  },
}

---@type Adan.LspConfig
M.jade_toml = {
  cmd = (function()
    local uname = vim.uv.os_uname()
    local sys = uname.sysname
    local machine = uname.machine
    local os
    if sys == 'Darwin' then
      os = 'macos'
    elseif sys == 'Linux' then
      os = 'linux'
    elseif sys:match('Windows') then
      os = 'windows'
    else
      os = sys:lower()
    end

    local arch
    if machine == 'x86_64' or machine == 'amd64' then
      arch = 'x86_64'
    elseif machine == 'arm64' or machine == 'aarch64' then
      arch = 'aarch64'
    else
      arch = machine
    end

    local exe = 'jade_toml_lsp' .. (os == 'windows' and '.exe' or '')
    local root = vim.fn.expand('~/.config/nvim/custom_lsp/jade_toml/bin')
    local release_path = string.format('%s/%s/%s/release/%s', root, os, arch, exe)
    if vim.fn.executable(release_path) == 1 then
      return { release_path }
    end

    local debug_path = string.format('%s/%s/%s/debug/%s', root, os, arch, exe)
    return { vim.fn.executable(debug_path) == 1 and debug_path or release_path }
  end)(),
  filetypes = { 'toml', },
  root_markers = { 'jade.toml', '.git' },
  settings = {
    jade = {
      diagnostics = {
        enabled = true,
        severity = 'warning',
      },
    },
  },
}

return M
