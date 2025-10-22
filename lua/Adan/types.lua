---@alias Adan.LspConfig vim.lsp.Config
---@alias Adan.OilSetupOpts oil.SetupOpts
---@alias Adan.Bufnr integer
---@alias Adan.Winid integer

---@class Adan.FoldRange
---@field start_line integer
---@field end_line integer

---@alias Adan.FoldRanges table<Adan.Bufnr, Adan.FoldRange[]>
---@alias Adan.FoldRangeMap table<Adan.Bufnr, table<integer, Adan.FoldRange>>
---@alias Adan.LspRegistry table<string, boolean|vim.lsp.Config>
---
---@class Adan.TSVendorSpec
---@field name string
---@field repo string  "owner/repo" GitHub path
---@field queries_path string  Path inside the repo to the queries directory
---@field filename? string
---@field exclude? table<string, true>
