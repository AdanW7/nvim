
return {
    "snacks.nvim",
    opts = {
        explorer = {
            enabled = true,
            auto_close = true,
            hidden = true,
            git_icons = true,
        },
    },
    keys = {
        { "<leader>e", function() Snacks.explorer() end, desc = "Explorer" },
        { "<leader>E", function() Snacks.explorer({ cwd = vim.fn.expand("%:p:h") }) end, desc = "Explorer (cwd)" },
    },
}
