return {
    "coffebar/neovim-project",
    opts = {
        projects = {
            "~/.config/*",
        },
        -- Load most recent session on startup
        last_session_on_startup = true,
        dashboard_mode = false,

        -- Session manager options
        session_manager_opts = {
            autosave_ignore_dirs = {
                vim.fn.expand("~"),
                "/tmp",
            },
            autosave_ignore_filetypes = {
                "gitcommit",
                "gitrebase",
                "qf",
                "toggleterm",
            },
        },

        -- Telescope picker
        picker = {
            type = "telescope",
        },
    },
    init = function()
        -- Enable saving plugin state in sessions
        vim.opt.sessionoptions:append("globals")
    end,
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope.nvim" },
        { "Shatur/neovim-session-manager" },
    },
    lazy = false,
    priority = 100,
}
