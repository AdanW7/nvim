---Disable pyright capabilities that pyrefly handles better
---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach_pyright(client, bufnr)
  local caps = client.server_capabilities

  -- ══════════════════════════════════════════════════════════════════════════
  -- DISABLE: Let pyrefly/ruff handle these
  -- ══════════════════════════════════════════════════════════════════════════
  --
  -- Completions & Help
  caps.completionProvider = nil
  caps.hoverProvider = nil
  caps.signatureHelpProvider = nil

  -- Go-to navigation
  caps.definitionProvider = nil
  caps.declarationProvider = nil
  caps.typeDefinitionProvider = nil

  -- Inlay hints
  caps.inlayHintProvider = nil

  -- Diagnostics
  caps.diagnosticProvider = nil

  -- Formatting
  caps.documentFormattingProvider = nil
  caps.documentRangeFormattingProvider = nil
  caps.documentOnTypeFormattingProvider = nil

  -- ══════════════════════════════════════════════════════════════════════════
  -- KEEP: Pyright
  -- ══════════════════════════════════════════════════════════════════════════

  -- caps.referencesProvider         -- Find all references
  -- caps.documentHighlightProvider  -- Highlight other occurrences (uses references)
  -- caps.renameProvider             -- Rename across files (needs accurate references)
  -- caps.callHierarchyProvider      -- Incoming/outgoing calls (reference-based)
  -- caps.implementationProvider     -- Find implementations (reference-like)
  --
  -- caps.foldingRangeProvider        -- Code folding
  -- caps.selectionRangeProvider      -- Smart expand selection
  -- caps.semanticTokensProvider      -- enhance syntax highlighting
  -- caps.codeLensProvider            -- Inline reference counts, etc.

  -- ══════════════════════════════════════════════════════════════════════════
  -- CONSIDER: Could go either way
  -- ══════════════════════════════════════════════════════════════════════════

  -- Symbols
  -- caps.documentSymbolProvider = nil  -- Outline view
  -- caps.workspaceSymbolProvider = nil -- Workspace symbol search

  -- Code actions
  -- caps.codeActionProvider = nil

  -- These are less important for Python:
  caps.colorProvider = nil
  caps.linkedEditingRangeProvider = nil -- HTML/XML tag editing
  caps.inlineValueProvider = nil -- Debug inline values
  caps.monikerProvider = nil -- Cross-repo navigation
end

---@type vim.lsp.Config
return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'pyrightconfig.json', '.git' },
  on_attach = on_attach_pyright,
  settings = {
    pyright = {
      disableOrganizeImports = true,
    },
    python = {
      analysis = {
        autoImportCompletions = false,
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        ignore = { '*' },
        typeCheckingMode = 'off',
        useLibraryCodeForTypes = true,
      },
    },
  },
}
