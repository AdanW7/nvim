---@type vim.lsp.Config
return {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },

    root_markers = {
        'pyrightconfig.json',
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        '.git',
    },
    settings = {
        pyright = {
            disableOrganizeImports = true, -- Let Ruff handle import organization
        },
        python = {
            analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
                -- diagnosticSeverityOverrides,
                -- exclude,
                -- extraPath,
                ignore = {"*"}, -- Let Ruff handle import linting
                -- include,
                -- logLevel,
                -- stubPath,
                typeCheckingMode = "standard", -- "off", "basic", "standard" and "strict"
                -- typeshedPaths,
                useLibraryCodeForTypes =true,
                -- 
            },
        },
        reportMissingTypeStubs = false,
    },
}
