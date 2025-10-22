--- @brief
---
--- https://github.com/PowerShell/PowerShellEditorServices
---
--- Language server for PowerShell.
---
--- To install, download and extract PowerShellEditorServices.zip
--- from the [releases](https://github.com/PowerShell/PowerShellEditorServices/releases).
--- To configure the language server, set the property `bundle_path` to the root
--- of the extracted PowerShellEditorServices.zip.
---
--- ```lua
--- vim.lsp.config('powershell_es', {
---   bundle_path = 'c:/w/PowerShellEditorServices',
--- })
--- ```
---
--- By default the language server is started in `pwsh` (PowerShell Core). This can be changed by specifying `shell`.
---
--- ```lua
--- vim.lsp.config('powershell_es', {
---   bundle_path = 'c:/w/PowerShellEditorServices',
---   shell = 'powershell.exe',
--- })
--- ```
---
--- Note that the execution policy needs to be set to `Unrestricted` for the languageserver run under PowerShell
---
--- If necessary, specific `cmd` can be defined instead of `bundle_path`.
--- See [PowerShellEditorServices](https://github.com/PowerShell/PowerShellEditorServices#standard-input-and-output)
--- to learn more.
---
--- ```lua
--- vim.lsp.config('powershell_es', {
---   cmd = {'pwsh', '-NoLogo', '-NoProfile', '-Command', "c:/PSES/Start-EditorServices.ps1 ..."},
--- })
--- ```

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

---@type vim.lsp.Config
return {
  bundle_path = vim.env.POWERSHELL_ES_BUNDLE_PATH
    or (vim.fn.stdpath('data') .. '/mason/packages/powershell-editor-services'),
  shell = (vim.fn.executable('pwsh') == 1 and 'pwsh')
    or (vim.fn.has('win32') == 1 and 'powershell.exe')
    or 'powershell',
  cmd = function(dispatchers)
    local temp_path = vim.fn.stdpath('cache')
    local bundle_path = vim.lsp.config.powershell_es.bundle_path

    local shell = vim.lsp.config.powershell_es.shell or 'pwsh'

    local command_fmt =
      [[& '%s/PowerShellEditorServices/Start-EditorServices.ps1' -BundledModulesPath '%s' -LogPath '%s/powershell_es.log' -SessionDetailsPath '%s/powershell_es.session.json' -FeatureFlags @() -AdditionalModules @() -HostName nvim -HostProfileId 0 -HostVersion 1.0.0 -Stdio -LogLevel Normal]]
    local command = command_fmt:format(bundle_path, bundle_path, temp_path, temp_path)
    local cmd = { shell, '-NoLogo', '-NoProfile', '-Command', command }

    return vim.lsp.rpc.start(cmd, dispatchers)
  end,
  filetypes = { 'ps1', 'psm1', 'psd1', 'ps1xml', 'powershell' },
  root_markers = { 'PSScriptAnalyzerSettings.psd1', '.git' },
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
