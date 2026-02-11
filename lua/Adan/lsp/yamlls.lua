---@type vim.lsp.Config
return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'yaml.helm-values' },
  root_markers = { '.git' },
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
    -- formatting disabled by default in yaml-language-server; enable it
    yaml = {
      format = {
        enable = true,
        singleQuote = true,
      },
      hover = true,
      validate = true,
      completion = true,
      schemaStore = {
        enabled = true,
        url = 'https://www.schemastore.org/api/json/catalog.json',
      },
      schemas = {
        -- custom schema
        [vim.fn.getcwd() .. '/schemas/hil_pipeline.schema.json'] = {
          'configs/pipeline_configs/Hil_Pipelines/**/*.yml',
          'configs/pipeline_configs/Hil_Pipelines/**/*.yaml',
          'configs/pipeline_configs/*.yml',
          'configs/pipeline_configs/*.yaml',
          '!configs/pipeline_configs/*build_pipeline.yml',
          '!configs/pipeline_configs/*uhilt_downstream.yml',
        },
      },
    },
  },
  on_init = function(client)
    --- Since formatting is disabled by default if you check `client:supports_method('textDocument/formatting')`
    --- during `LspAttach` it will return `false`. This hack sets the capability to `true` to facilitate
    --- autocmd's which check this capability
    client.server_capabilities.documentFormattingProvider = true
  end,
}
