return {
    "folke/snacks.nvim",
    keys = {
        -- Delete current buffer
        { "<leader>bd", function() Snacks.bufdelete() end,                 desc = "Delete Buffer" },

        -- Force delete current buffer
        { "<leader>bD", function() Snacks.bufdelete({ force = true }) end, desc = "Delete Buffer (Force)" },

        -- Delete all other buffers (keep current)
        { "<leader>bo", function() Snacks.bufdelete.other() end,           desc = "Delete Other Buffers" },

        -- Delete all buffers
        { "<leader>ba", function() Snacks.bufdelete.all() end,             desc = "Delete All Buffers" },

        -- Reload all buffers
        { "<leader>br", "<cmd>checktime<CR>",                              desc = "Reload All Buffers" },
    },
}
