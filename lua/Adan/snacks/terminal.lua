return {
    "folke/snacks.nvim",
    opts = {
        terminal = {
            win = {
                style = "terminal",
            },
        },
    },
    keys = {
        -- Basic terminal toggles
        { "<leader>tf", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Toggle Terminal (float)" },
        { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal", mode = { "n", "t" } },
    },
}
