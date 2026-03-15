---@type vim.lsp.Config
local pyrefly_config = {
  settings = {
    python = {
      pyrefly = {
        displayTypeErrors = 'force-on',
      },
    },
  },
}

vim.lsp.config('pyrefly', pyrefly_config)

local ruff_config = {
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

vim.lsp.config('ruff', ruff_config)

local powershell_config = {
  bundle_path = vim.env.POWERSHELL_ES_BUNDLE_PATH
    or (vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services'),
  shell = (vim.fn.has('win32') == 1 and 'powershell.exe')
    or (vim.fn.executable('pwsh') == 1 and 'pwsh')
    or 'powershell',
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

vim.lsp.config('powershell_es', powershell_config)
