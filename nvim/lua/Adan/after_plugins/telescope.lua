local telescope = require("telescope")
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Telescope jump list' })
vim.keymap.set('n', '<leader>fF', function()
    builtin.find_files({ cwd = vim.fn.expand('%:p:h') })
end, { desc = 'Find files in current dir' })

-- Grep in current file's directory
vim.keymap.set('n', '<leader>fG', function()
    builtin.live_grep({ cwd = vim.fn.expand('%:p:h') })
end, { desc = 'Grep in current dir' })

-- project command
telescope.load_extension("projects")
vim.keymap.set('n', '<leader>fp', '<cmd>Telescope projects<CR>', { desc = 'Find projects' })
-- After switching project, useful commands:
vim.keymap.set('n', '<leader>pf', function()
    builtin.find_files({ cwd = vim.fn.getcwd() })
end, { desc = 'Find files in project' })

vim.keymap.set('n', '<leader>pg', function()
    builtin.live_grep({ cwd = vim.fn.getcwd() })
end, { desc = 'Grep in project' })

vim.keymap.set('n', '<leader>pr', function()
    builtin.oldfiles({ cwd = vim.fn.getcwd() })
end, { desc = 'Recent files in project' })


-- add projects
vim.keymap.set('n', '<leader>pa', function()
    local history = require("project_nvim.utils.history")
    local cwd = vim.fn.getcwd()
    -- Check if already in history
    for _, v in pairs(history.recent_projects) do
        if v == cwd then
            vim.notify("Project already in history: " .. cwd, vim.log.levels.INFO)
            return
        end
    end
    -- Add to recent projects
    table.insert(history.recent_projects, 1, cwd)
    -- Save to file
    history.write_projects_to_history()
    vim.notify("Added '" .. cwd .. "' to projects", vim.log.levels.INFO)
end, { desc = 'Add current dir as project' })

vim.keymap.set('n', '<leader>pA', function()
    vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
        if path and path ~= "" then
            local expanded = vim.fn.expand(path)
            if vim.fn.isdirectory(expanded) == 1 then
                local history = require("project_nvim.utils.history")

                -- Check if already exists
                for _, v in pairs(history.recent_projects) do
                    if v == expanded then
                        vim.notify("Project already in history: " .. expanded, vim.log.levels.INFO)
                        return
                    end
                end

                -- Add and save
                table.insert(history.recent_projects, 1, expanded)
                history.write_projects_to_history()

                vim.notify("Added '" .. expanded .. "' to projects", vim.log.levels.INFO)
            else
                vim.notify("Invalid directory: " .. expanded, vim.log.levels.ERROR)
            end
        end
    end)
end, { desc = 'Add folder as project' })


