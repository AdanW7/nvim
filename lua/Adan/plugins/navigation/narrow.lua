return {
    "chrisbra/NrrwRgn",
    cmd = {
        "NR",
        "NW",
        "NRV",
        "NUD",
        "NRP",
        "NRM",
        "NRS",
        "NRN",
        "NRL",
    },
    keys = {
        -- Visual mode: Narrow selected region
        { "<leader>zn", ":NR<CR>",  mode = "v", desc = "Narrow region" },
        { "<leader>zw", ":NW<CR>",  mode = "v", desc = "Narrow visual window" },

        -- Normal mode: Narrow last visual selection
        { "<leader>zv", ":NRV<CR>", mode = "n", desc = "Narrow last visual" },
        { "<leader>zl", ":NRL<CR>", mode = "n", desc = "Reselect last narrow" },

        -- Multi-region narrowing (experimental)
        { "<leader>zp", ":NRP<CR>", mode = "v", desc = "Mark region for multi-narrow" },
        { "<leader>zm", ":NRM<CR>", mode = "n", desc = "Create multi-narrow window" },

        -- In narrowed window: Write back changes
        { "<leader>zw", ":WR<CR>",  mode = "n", desc = "Write narrow changes back" },
        { "<leader>zc", ":WR!<CR>", mode = "n", desc = "Write changes & close narrow" },

        -- Toggle sync
        { "<leader>zs", ":NRS<CR>", mode = "n", desc = "Enable narrow sync" },
        { "<leader>zd", ":NRN<CR>", mode = "n", desc = "Disable narrow sync" },
    },
    config = function()
        vim.g.nrrw_rgn_nomap_nr = 1
        vim.g.nrrw_rgn_nomap_Nr = 1

        vim.g.nrrw_rgn_vert = 1              -- Open narrowed window vertically
        vim.g.nrrw_rgn_wdth = 80             -- Width of narrowed window
        vim.g.nrrw_rgn_hl = 'Visual'         -- Highlight group for narrowed region
        vim.g.nrrw_topbot_leftright = 'botright' -- Window position

        -- Auto-write changes back on save in narrowed buffer
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "Nrrw_*",
            callback = function()
                vim.cmd("silent! :w")
            end,
            desc = "Auto-sync narrowed region on save",
        })
    end,
}
