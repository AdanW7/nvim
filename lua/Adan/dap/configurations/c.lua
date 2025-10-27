local dap = require("dap")

-- Reuse Zig configurations
dap.configurations.c = dap.configurations.zig
