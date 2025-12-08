return {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    dependencies = {
        { 'nvim-treesitter/nvim-treesitter' },
        { 'nvim-orgmode/org-bullets.nvim' },
        { 'lukas-reineke/headlines.nvim' },
    },
    config = function()
        -- Setup orgmode
        require('orgmode').setup({
            org_agenda_files = {
                '~/orgfiles/refile.org',
                '~/orgfiles/work/**/*',
                '~/orgfiles/personal/**/*',
            },
            org_default_notes_file = '~/orgfiles/refile.org',

            -- Refile configuration - refile to daily notes
            org_refile_targets = {
                ['~/orgfiles/work/%<%Y-%m-%d>.org'] = { ':maxlevel', 2 },
                ['~/orgfiles/personal/%<%Y-%m-%d>.org'] = { ':maxlevel', 2 },
                ['~/orgfiles/refile.org'] = { ':level', 1 },
            },
            org_refile_use_outline_path = 'file',
            org_refile_allow_creating_parent_nodes = true,

            -- Optional: Configure some useful settings
            org_startup_indented = true,
            org_hide_emphasis_markers = true,
            org_hide_leading_stars = true,

            -- Capture templates
            org_capture_templates = {
                t = {
                    description = 'Task',
                    template = '* TODO %?\n  %u',
                },
                n = {
                    description = 'Note',
                    template = '* %?\n  %u',
                },
                w = {
                    description = 'Work Note',
                    template = '* %?\n  %u',
                    target = '~/orgfiles/work/%<%Y-%m-%d>.org',
                },
                p = {
                    description = 'Personal Note',
                    template = '* %?\n  %u',
                    target = '~/orgfiles/personal/%<%Y-%m-%d>.org',
                },
                m = {
                    description = 'Meeting',
                    template = '* %? %U\n** Attendees\n- \n** Notes\n\n** Action Items\n- [ ] ',
                    target = '~/orgfiles/work/%<%Y-%m-%d>.org',
                },
                c = {
                    description = 'Checklist',
                    template = '* %?\n** Checklist\n- [ ] \n- [ ] \n- [ ] ',
                },
            },

            -- Optional: Custom TODO keywords
            org_todo_keywords = { 'TODO', 'PROGRESS', '|', 'DONE', 'DELEGATED' },

            -- Keybindings
            mappings = {
                global = {
                    org_agenda = '<leader>oa',
                    org_capture = '<leader>oc',
                },
                org = {
                    -- Navigation
                    org_next_visible_heading = '}',
                    org_previous_visible_heading = '{',
                    org_forward_heading_same_level = ']]',
                    org_backward_heading_same_level = '[[',
                    outline_up_heading = 'g{',

                    -- Editing
                    org_meta_return = '<leader><CR>',                        -- Add heading/item below
                    org_insert_heading_respect_content = '<leader>oih',      -- Add heading after content
                    org_insert_todo_heading = '<leader>oiT',                 -- Add TODO heading
                    org_insert_todo_heading_respect_content = '<leader>oit', -- Add TODO after content

                    -- TODO & Priority
                    org_todo = 'cit',            -- Cycle TODO state
                    org_todo_prev = 'ciT',       -- Cycle TODO backward
                    org_priority = '<leader>o,', -- Set priority
                    org_priority_up = 'ciR',     -- Increase priority
                    org_priority_down = 'cir',   -- Decrease priority

                    -- Dates & Scheduling
                    org_deadline = '<leader>oid',            -- Set/update deadline
                    org_schedule = '<leader>ois',            -- Set/update schedule
                    org_time_stamp = '<leader>oi.',          -- Insert date
                    org_time_stamp_inactive = '<leader>oi!', -- Insert inactive date
                    org_change_date = 'cid',                 -- Change date under cursor

                    -- Links
                    org_insert_link = '<leader>oli',  -- Insert/edit link
                    org_store_link = '<leader>ols',   -- Store link
                    org_open_at_point = '<leader>oo', -- Open link/date

                    -- Structure
                    org_do_promote = '<<',                -- Promote heading
                    org_do_demote = '>>',                 -- Demote heading
                    org_promote_subtree = '<s',           -- Promote subtree
                    org_demote_subtree = '>s',            -- Demote subtree
                    org_move_subtree_up = '<leader>oK',   -- Move subtree up
                    org_move_subtree_down = '<leader>oJ', -- Move subtree down

                    -- Tags & Archive
                    org_set_tags_command = '<leader>ot',   -- Set tags
                    org_toggle_archive_tag = '<leader>oA', -- Toggle ARCHIVE tag
                    org_archive_subtree = '<leader>o$',    -- Archive to file

                    -- Folding
                    org_cycle = '<TAB>',          -- Cycle fold current heading
                    org_global_cycle = '<S-TAB>', -- Cycle fold globally

                    -- Other
                    org_toggle_checkbox = '<C-Space>', -- Toggle checkbox
                    org_toggle_heading = '<leader>o*', -- Toggle heading/plain text
                    org_refile = '<leader>orr',        -- Refile (changed to orr)
                    org_add_note = '<leader>ona',      -- Add note
                    org_edit_special = "<leader>o'",   -- Edit code block
                    org_export = '<leader>oe',         -- Export
                    org_show_help = 'g?',              -- Show help
                },
                agenda = {
                    org_agenda_later = 'f',              -- Next span
                    org_agenda_earlier = 'b',            -- Previous span
                    org_agenda_goto_today = '.',         -- Go to today
                    org_agenda_day_view = 'vd',          -- Day view
                    org_agenda_week_view = 'vw',         -- Week view
                    org_agenda_month_view = 'vm',        -- Month view
                    org_agenda_year_view = 'vy',         -- Year view
                    org_agenda_quit = 'q',               -- Close agenda
                    org_agenda_switch_to = '<CR>',       -- Open in same window
                    org_agenda_goto = '<TAB>',           -- Open in split
                    org_agenda_goto_date = 'J',          -- Jump to date
                    org_agenda_redo = 'r',               -- Reload
                    org_agenda_todo = 't',               -- Change TODO state
                    org_agenda_priority = '<leader>o,',  -- Set priority
                    org_agenda_set_tags = '<leader>ot',  -- Set tags
                    org_agenda_deadline = '<leader>oid', -- Set deadline
                    org_agenda_schedule = '<leader>ois', -- Set schedule
                    org_agenda_archive = '<leader>o$',   -- Archive
                    org_agenda_refile = '<leader>orr',   -- Refile
                    org_agenda_filter = '/',             -- Filter
                    org_agenda_show_help = 'g?',         -- Show help
                },
                capture = {
                    org_capture_finalize = '<leader>os', -- Save capture
                    org_capture_refile = '<leader>orr',  -- Refile capture
                    org_capture_kill = '<leader>ok',     -- Abort capture
                    org_capture_show_help = 'g?',        -- Show help
                },
            },
        })

        -- Set conceallevel for links
        vim.opt.conceallevel = 2
        vim.opt.concealcursor = 'nc'

        -- Additional highlight customizations for agenda view
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'orgagenda',
            callback = function()
                -- Sky blue color for various agenda elements
                vim.api.nvim_set_hl(0, 'OrgAgendaScheduled', { fg = '#87CEEB' })
                vim.api.nvim_set_hl(0, 'OrgAgendaDeadline', { fg = '#87CEEB' })
                vim.api.nvim_set_hl(0, 'Comment', { fg = '#87CEEB' }) -- Often used for file names
            end,
        })

        -- Set highlight groups immediately (in case autocmd doesn't fire)
        vim.api.nvim_set_hl(0, 'OrgAgendaScheduled', { fg = '#87CEEB' })
        vim.api.nvim_set_hl(0, 'OrgAgendaDeadline', { fg = '#87CEEB' })

        -- Target treesitter highlights for org files
        vim.api.nvim_set_hl(0, '@org.agenda.scheduled', { fg = '#87CEEB' })
        vim.api.nvim_set_hl(0, '@org.agenda.deadline', { fg = '#87CEEB' })
        vim.api.nvim_set_hl(0, '@text.todo.unchecked.org', { fg = '#87CEEB' })
        vim.api.nvim_set_hl(0, '@org.timestamp.active', { fg = '#87CEEB' })

        -- Custom TODO keyword colors
        vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#00FF00', bold = true })
        vim.api.nvim_set_hl(0, '@org.keyword.done.org', { fg = '#00FF00', bold = true })

        -- For agenda view
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'orgagenda',
            callback = function()
                vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#00FF00', bold = true })
            end,
        })

        -- Custom keymaps for opening daily notes
        vim.keymap.set('n', '<leader>onw', function()
            local today = os.date('%Y-%m-%d')
            local work_file = vim.fn.expand('~/orgfiles/work/' .. today .. '.org')

            -- Create directory if it doesn't exist
            vim.fn.mkdir(vim.fn.expand('~/orgfiles/work'), 'p')

            -- Open or create the file
            vim.cmd('edit ' .. work_file)

            -- Add header if file is new/empty
            if vim.fn.getfsize(work_file) <= 0 then
                local lines = {
                    '#+TITLE: Work Notes - ' .. os.date('%B %d, %Y'),
                    '#+DATE: ' .. today,
                    '',
                    '* Tasks',
                    '',
                    '* Meetings',
                    '',
                    '* Notes',
                    '',
                }
                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
                vim.cmd('write')
            end
        end, { desc = 'Open work daily notes' })

        vim.keymap.set('n', '<leader>onp', function()
            local today = os.date('%Y-%m-%d')
            local personal_file = vim.fn.expand('~/orgfiles/personal/' .. today .. '.org')

            -- Create directory if it doesn't exist
            vim.fn.mkdir(vim.fn.expand('~/orgfiles/personal'), 'p')

            -- Open or create the file
            vim.cmd('edit ' .. personal_file)

            -- Add header if file is new/empty
            if vim.fn.getfsize(personal_file) <= 0 then
                local lines = {
                    '#+TITLE: Personal Notes - ' .. os.date('%B %d, %Y'),
                    '#+DATE: ' .. today,
                    '',
                    '* Tasks',
                    '',
                    '* Notes',
                    '',
                }
                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
                vim.cmd('write')
            end
        end, { desc = 'Open personal daily notes' })

        vim.keymap.set('n', '<leader>onr', function()
            vim.cmd('edit ~/orgfiles/refile.org')
        end, { desc = 'Open refile inbox' })

        -- Quick refile shortcuts
        vim.keymap.set('n', '<leader>orp', function()
            local today = os.date('%Y-%m-%d')
            local personal_file = vim.fn.expand('~/orgfiles/personal/' .. today .. '.org')

            -- Create directory if it doesn't exist
            vim.fn.mkdir(vim.fn.expand('~/orgfiles/personal'), 'p')

            -- Create file with template if it doesn't exist
            if vim.fn.filereadable(personal_file) == 0 then
                local lines = {
                    '#+TITLE: Personal Notes - ' .. os.date('%B %d, %Y'),
                    '#+DATE: ' .. today,
                    '',
                    '* Tasks',
                    '',
                    '* Notes',
                    '',
                }
                vim.fn.writefile(lines, personal_file)
            end

            -- Get the API
            local api = require('orgmode.api')

            -- Get the current headline
            local current_file = api.current()
            local headline = current_file:get_closest_headline()

            if not headline then
                vim.notify('No headline found at cursor', vim.log.levels.WARN)
                return
            end

            -- Load or reload the destination file
            local dest_file = api.load(personal_file)

            -- Find the Tasks heading in the destination file
            local tasks_headline = nil
            for _, h in ipairs(dest_file.headlines) do
                if h.title == 'Tasks' then
                    tasks_headline = h
                    break
                end
            end

            -- Refile to the destination
            if tasks_headline then
                api.refile({
                    source = headline,
                    destination = tasks_headline
                })
            else
                -- If no Tasks heading, refile to the file itself
                api.refile({
                    source = headline,
                    destination = dest_file
                })
            end

            vim.notify('Refiled to ' .. personal_file)
        end, { desc = 'Refile to today\'s personal notes' })

        vim.keymap.set('n', '<leader>orw', function()
            local today = os.date('%Y-%m-%d')
            local work_file = vim.fn.expand('~/orgfiles/work/' .. today .. '.org')

            -- Create directory if it doesn't exist
            vim.fn.mkdir(vim.fn.expand('~/orgfiles/work'), 'p')

            -- Create file with template if it doesn't exist
            if vim.fn.filereadable(work_file) == 0 then
                local lines = {
                    '#+TITLE: Work Notes - ' .. os.date('%B %d, %Y'),
                    '#+DATE: ' .. today,
                    '',
                    '* Tasks',
                    '',
                    '* Meetings',
                    '',
                    '* Notes',
                    '',
                }
                vim.fn.writefile(lines, work_file)
            end

            -- Get the API
            local api = require('orgmode.api')

            -- Get the current headline
            local current_file = api.current()
            local headline = current_file:get_closest_headline()

            if not headline then
                vim.notify('No headline found at cursor', vim.log.levels.WARN)
                return
            end

            -- Load or reload the destination file
            local dest_file = api.load(work_file)

            -- Find the Tasks heading in the destination file
            local tasks_headline = nil
            for _, h in ipairs(dest_file.headlines) do
                if h.title == 'Tasks' then
                    tasks_headline = h
                    break
                end
            end

            -- Refile to the destination
            if tasks_headline then
                api.refile({
                    source = headline,
                    destination = tasks_headline
                })
            else
                -- If no Tasks heading, refile to the file itself
                api.refile({
                    source = headline,
                    destination = dest_file
                })
            end

            vim.notify('Refiled to ' .. work_file)
        end, { desc = 'Refile to today\'s work notes' })
    end,
}
