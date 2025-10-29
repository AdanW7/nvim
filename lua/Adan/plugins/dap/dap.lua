return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
            "mason-org/mason.nvim",
            "leoluz/nvim-dap-go",
            {
                "mfussenegger/nvim-dap-python",
                cond = vim.fn.has("unix") == 1,
            },
        },
        config = function()
            -- Load UI configuration
            require("Adan.dap.ui")

            -- Load adapters
            require("Adan.dap.adapters.lldb")
            require("Adan.dap.adapters.go")
            require("Adan.dap.adapters.python")

            -- Load configurations
            require("Adan.dap.configurations.zig")
            require("Adan.dap.configurations.c")
            require("Adan.dap.configurations.cpp")
            require("Adan.dap.configurations.rust")
            require("Adan.dap.configurations.go")
            require("Adan.dap.configurations.python")

            -- Load keymaps
            require("Adan.dap.keymaps")
        end,
    },
}
