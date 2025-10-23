return {
    "nvzone/floaterm",
    dependencies = "nvzone/volt",
    cmd = "FloatermToggle",
    keys = {
        { "<leader>tf", "<cmd>FloatermToggle<cr>", desc = "Toggle Floaterm" },
    },
    opts = {
        border = true,
        size = { h = 60, w = 70 },

        mappings = {
            term = function(buf)
                -- Add <leader>tf to close from within terminal
                vim.keymap.set({ "n", "t" }, "<leader>tf", "<cmd>FloatermToggle<cr>", { buffer = buf })
            end,
        },

        terminals = {
            { name = "Terminal" },
            { name = "Yazi", cmd = "yazi" },
        },
    },
}
