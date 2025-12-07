return {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
        "nvim-lua/plenary.nvim", -- required
        -- "sindrets/diffview.nvim", -- optional - Diff integration
        {
            "sindrets/diffview.nvim", -- Diff integration
            opts = {
                diff_binaries = false,
                enhanced_diff_hl = true,
                use_icons = true,
                view = {
                    default = {
                        layout = "diff2_horizontal", -- Side-by-side diffs
                    },
                    merge_tool = {
                        layout = "diff3_horizontal",
                    },
                    file_history = {
                        layout = "diff2_horizontal",
                    },
                },
            },
        },

        -- Only one of these is needed.
        "nvim-telescope/telescope.nvim", -- optional
    },
    cmd = "Neogit",
    keys = {
        { "<leader>gn", "<cmd>Neogit<cr>",      desc = "Show Neogit UI" },
        { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit Pull" },
        { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit Push" },
        { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
        { "<leader>gl", "<cmd>Neogit log<cr>", desc = "Neogit Log" },

        {
            "<leader>gd",
            function()
                local lib = require("diffview.lib")
                local view = lib.get_current_view()
                if view then
                    -- If a Diffview is open, close it
                    vim.cmd("DiffviewClose")
                else
                    -- If no Diffview is open, open one
                    vim.cmd("DiffviewOpen")
                end
            end,
            desc = "Toggle Diffview"
        },

    },
    opts = {
        -- Neogit window settings
        kind = "tab", -- "tab", "split", "split_above", "vsplit", "floating"

        -- Commit editor settings
        commit_editor = {
            kind = "tab", -- "tab", "split", "vsplit", "floating", "auto"
        },

        -- Popup settings
        commit_popup = {
            kind = "split", -- "split", "vsplit", "floating"
        },

        -- Enable signs in status buffer
        signs = {
            hunk = { "", "" },
            item = { "", "" },
            section = { "", "" },
        },
        -- Integrations
        integrations = {
            telescope = true,
            diffview = true,
        },
        -- Customize sections in status buffer
        sections = {
            untracked = {
                folded = false,
            },
            unstaged = {
                folded = false,
            },
            staged = {
                folded = false,
            },
            stashes = {
                folded = true,
            },
            unpulled_upstream = {
                folded = true,
            },
            unmerged_upstream = {
                folded = false,
            },
            unpulled_pushRemote = {
                folded = true,
            },
            unmerged_pushRemote = {
                folded = false,
            },
            recent = {
                folded = true,
            },
            rebase = {
                folded = true,
            },
        },

        -- Automatically show console on error
        auto_show_console = true,

        -- Remember Neogit state across sessions
        remember_settings = true,

        -- Use per-project settings
        use_per_project_settings = true,

        -- Highlight staged/unstaged changes
        highlight = {
            italic = true,
            bold = true,
            underline = true,
        },

    },
}
