vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    callback = function()
        local opts = { buffer = true, silent = true }

        -- Compile with latexmk (continuous mode) - ASYNC
        vim.keymap.set('n', '<leader>lc', function()
            vim.fn.jobstart('latexmk -pdf -pvc -interaction=nonstopmode ' .. vim.fn.expand('%'), {
                detach = true,  -- Run in background
            })
            vim.notify("Started continuous LaTeX compilation", vim.log.levels.INFO)
        end, vim.tbl_extend('force', opts, { desc = 'Compile LaTeX (continuous)' }))

        -- Compile once - ASYNC
        vim.keymap.set('n', '<leader>ls', function()
            vim.fn.jobstart('latexmk -pdf -interaction=nonstopmode ' .. vim.fn.expand('%'), {
                on_exit = function(_, code)
                    if code == 0 then
                        vim.notify("LaTeX compilation successful", vim.log.levels.INFO)
                    else
                        vim.notify("LaTeX compilation failed", vim.log.levels.ERROR)
                    end
                end,
            })
        end, vim.tbl_extend('force', opts, { desc = 'Compile LaTeX (single)' }))

        -- Compile with XeLaTeX (for unicode/fonts) - ASYNC
        vim.keymap.set('n', '<leader>lx', function()
            vim.fn.jobstart('latexmk -xelatex -interaction=nonstopmode ' .. vim.fn.expand('%'), {
                on_exit = function(_, code)
                    if code == 0 then
                        vim.notify("XeLaTeX compilation successful", vim.log.levels.INFO)
                    else
                        vim.notify("XeLaTeX compilation failed", vim.log.levels.ERROR)
                    end
                end,
            })
        end, vim.tbl_extend('force', opts, { desc = 'Compile with XeLaTeX' }))

        -- View PDF in Skim
        vim.keymap.set('n', '<leader>lv', function()
            local pdf = vim.fn.expand('%:r') .. '.pdf'
            vim.fn.jobstart('open -a Skim ' .. vim.fn.shellescape(pdf), { detach = true })
        end, vim.tbl_extend('force', opts, { desc = 'View PDF in Skim' }))

        -- Clean auxiliary files
        vim.keymap.set('n', '<leader>lk', function()
            vim.fn.jobstart('latexmk -c', {
                on_exit = function()
                    vim.notify("Cleaned auxiliary files", vim.log.levels.INFO)
                end,
            })
        end, vim.tbl_extend('force', opts, { desc = 'Clean auxiliary files' }))

        -- Clean all generated files (including PDF)
        vim.keymap.set('n', '<leader>lK', function()
            vim.fn.jobstart('latexmk -C', {
                on_exit = function()
                    vim.notify("Cleaned all files", vim.log.levels.INFO)
                end,
            })
        end, vim.tbl_extend('force', opts, { desc = 'Clean all files' }))

        -- Stop latexmk continuous compilation
        vim.keymap.set('n', '<leader>lq', function()
            vim.fn.jobstart('killall latexmk', {
                on_exit = function()
                    vim.notify("Stopped LaTeX compilation", vim.log.levels.INFO)
                end,
            })
        end, vim.tbl_extend('force', opts, { desc = 'Stop compilation' }))
    end,
})

-- LaTeX-specific settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    callback = function()
        vim.opt_local.spell = true           -- Enable spell check
        vim.opt_local.wrap = true            -- Wrap long lines
        vim.opt_local.linebreak = true       -- Break at word boundaries
        vim.opt_local.conceallevel = 0       -- Don't hide LaTeX syntax
        vim.opt_local.textwidth = 80         -- Wrap at 80 characters (optional)
    end,
})
