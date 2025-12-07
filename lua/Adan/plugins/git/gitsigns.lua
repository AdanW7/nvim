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
        signs_staged = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        signs_staged_enable = true,  -- Show staged hunks separately
        watch_gitdir = {
            enable = true,              -- Enable watching .git directory
            follow_files = true         -- Follow files when moved with git mv
        },
        update_debounce = 100,          -- Debounce time for updates (ms)
        current_line_blame = true,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 500,
            ignore_whitespace = false,
            virt_text_priority = 100,
            use_focus = true,            -- Enable only when buffer is in focus
        },
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        on_attach = function(bufnr)
            local gs = require('gitsigns')

            -- Toggle inline blame
            vim.keymap.set('n', '<leader>gbb', gs.toggle_current_line_blame, {
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
            vim.keymap.set('n', '<leader>hs', gs.stage_hunk, { buffer = bufnr, desc = 'Stage hunk' })
            vim.keymap.set('n', '<leader>hr', gs.reset_hunk, { buffer = bufnr, desc = 'Reset hunk' })
            vim.keymap.set('n', '<leader>hS', gs.stage_buffer, { buffer = bufnr, desc = 'Stage buffer' })
            vim.keymap.set('n', '<leader>hR', gs.reset_buffer, { buffer = bufnr, desc = 'Reset buffer' })
            vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview hunk' })
            vim.keymap.set('n', '<leader>hb',
                function()
                    gs.blame_line({ full = true })
                end,
                { buffer = bufnr, desc = 'Blame line (popup)' }
            )
            vim.keymap.set('n', '<leader>hd', gs.diffthis, { buffer = bufnr, desc = 'Diff this' })

            -- Refresh keybinding (useful for manual refresh)
            vim.keymap.set('n', '<leader>gR', gs.refresh, { buffer = bufnr, desc = 'Refresh git signs' })

            -- Visual mode stage/reset
            vim.keymap.set('v', '<leader>hs', function()
                gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { buffer = bufnr, desc = 'Stage hunk (visual)' })

            vim.keymap.set('v', '<leader>hr', function()
                gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { buffer = bufnr, desc = 'Reset hunk (visual)' })

            -- Text object
            vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Select hunk' })
        end,
    },
}
