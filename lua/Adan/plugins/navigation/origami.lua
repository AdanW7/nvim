return {
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    opts = {
        foldtext = {
            lineCount = {
                template = " %d Lines"
            },
            diagnosticsCount = true, -- uses hlgroups and icons from `vim.diagnostic.config().signs`
            gitsignsCount = true,    -- requires `gitsigns.nvim`
        },
        foldKeymaps = {
            setup = false, -- modifies `h`, `l`, and `$`
            hOnlyOpensOnFirstColumn = false,
        },
    },
    init = function()
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99

        -- Load the custom fold utilities
        local fold_util = require("Adan.utils.code_folds")

        -- Keymaps
        vim.keymap.set("n", "<CR>", "za", { noremap = true, silent = true, desc = "Toggle fold" })
        vim.keymap.set("n", "zk", fold_util.goto_previous_fold,
            { noremap = true, silent = true, desc = "Go to previous fold" })
        vim.keymap.set("n", "zj", "zj", { noremap = true, silent = true, desc = "Go to next fold" })
        vim.keymap.set("n", "<Left>", function() require("origami").h() end)
        vim.keymap.set("n", "<Right>", function() require("origami").l() end)
        vim.keymap.set("n", "<End>", function() require("origami").dollar() end)

        -- Update fold ranges on text changes and LSP attach
        vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "LspAttach" }, {
            callback = function(opts)
                fold_util.update_ranges(opts.buf)
            end,
        })

        -- Track current fold based on cursor position
        local last_row = nil
        vim.api.nvim_create_autocmd("CursorMoved", {
            callback = function(opts)
                local row = vim.api.nvim_win_get_cursor(0)[1]
                if row ~= last_row then
                    last_row = row
                    fold_util.update_current_fold(row, opts.buf)
                end
            end,
        })

        -- Clean up fold data when buffer is closed
        vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
            callback = function(opts)
                fold_util.clear(opts.buf)
            end,
        })

        -- Set custom statuscolumn with fold icons
        vim.opt.statuscolumn = "%!v:lua.StatusCol()"
        function _G.StatusCol()
            return fold_util.statuscol()
        end
    end
}
