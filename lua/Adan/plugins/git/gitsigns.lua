return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add          = { text = '+' },
            change       = { text = '│' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        current_line_blame = true,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 500,
            ignore_whitespace = false,
            virt_text_priority = 100,
        },
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        on_attach = function(bufnr)
            local gs = require('gitsigns')

            -- Toggle inline blame
            vim.keymap.set('n', '<leader>gb', gs.toggle_current_line_blame, {
                buffer = bufnr, desc = 'Toggle Git Blame (inline)'
            })

            -- Hunk navigation
            vim.keymap.set('n', ']h', function()
                if vim.wo.diff then
                    vim.cmd.normal({ ']c', bang = true })
                else
                    gs.nav_hunk('next')
                end
            end, { buffer = bufnr, desc = 'Next hunk' })

            vim.keymap.set('n', '[h', function()
                if vim.wo.diff then
                    vim.cmd.normal({ '[c', bang = true })
                else
                    gs.nav_hunk('prev')
                end
            end, { buffer = bufnr, desc = 'Prev hunk' })

            -- Actions
            vim.keymap.set('n', '<leader>ghs', gs.stage_hunk, { buffer = bufnr, desc = 'Stage hunk' })
            vim.keymap.set('n', '<leader>ghr', gs.reset_hunk, { buffer = bufnr, desc = 'Reset hunk' })
            vim.keymap.set('n', '<leader>ghS', gs.stage_buffer, { buffer = bufnr, desc = 'Stage buffer' })
            vim.keymap.set('n', '<leader>ghR', gs.reset_buffer, { buffer = bufnr, desc = 'Reset buffer' })
            vim.keymap.set('n', '<leader>ghp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview hunk' })
            vim.keymap.set('n', '<leader>ghb',
                function()
                    gs.blame_line({ full = true })
                end,
                { buffer = bufnr, desc = 'Blame line (popup)' }
            )
            vim.keymap.set('n', '<leader>hd', gs.diffthis, { buffer = bufnr, desc = 'Diff this' })

            -- Text object
            vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Select hunk' })
        end,
    },
}
