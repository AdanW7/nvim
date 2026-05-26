local M = {}

local function powershell_settings_path()
  local path = (vim.uv.os_tmpdir() or '/private/tmp') .. '/psscriptanalyzer-settings.psd1'
  local lines = {
    '@{',
    '    IncludeRules = @()',
    '    ExcludeRules = @()',
    '    Rules = @{',
    '        PSUseConsistentIndentation = @{',
    '            Enable = $true',
    "            Kind = 'space'",
    '            IndentationSize = 4',
    '        }',
    '        PSUseConsistentWhitespace = @{ Enable = $true }',
    '        PSUseConsistentLineEndings = @{ Enable = $true }',
    '        PSPlaceOpenBrace = @{',
    '            Enable = $true',
    '            OnSameLine = $true',
    '            NewLineAfter = $true',
    '            IgnoreOneLineBlock = $false',
    '        }',
    '        PSPlaceCloseBrace = @{',
    '            Enable = $true',
    '            NewLineAfter = $true',
    '            IgnoreOneLineBlock = $false',
    '        }',
    '        PSUseCorrectCasing = @{ Enable = $true }',
    '        PSAvoidUsingCmdletAliases = @{ Enable = $false }',
    '        PSAvoidLongLines = @{',
    '            Enable = $true',
    '            MaximumLineLength = 120',
    '        }',
    '    }',
    '}',
  }

  local ok = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return nil
  end
  return path
end

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
        settingsPath = powershell_settings_path(),
      },
    },
  },
}

return M
