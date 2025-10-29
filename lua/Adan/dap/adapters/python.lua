if vim.fn.has("unix") == 1 then
  require("dap-python").setup("python")
end
