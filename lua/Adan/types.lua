---@alias Adan.LazySpec LazySpec
---@alias Adan.LazySpecArray LazySpec[]
---@alias Adan.LspConfig vim.lsp.Config
---@alias Adan.Bufnr integer
---@alias Adan.Winid integer

---@class Adan.FoldRange
---@field start_line integer
---@field end_line integer

---@alias Adan.FoldRanges table<Adan.Bufnr, Adan.FoldRange[]>
---@alias Adan.FoldRangeMap table<Adan.Bufnr, table<integer, Adan.FoldRange>>
