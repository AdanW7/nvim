return {
    "ahmedkhalf/project.nvim",
    config = function()
        require("project_nvim").setup({
            -- Manual mode doesn't automatically change directory
            manual_mode = false,
            -- Don't show hidden files in telescope
            show_hidden = false,

            -- Don't automatically change to project dir when opening a file
            silent_chdir = true,

            -- Path to store project history
            datapath = vim.fn.stdpath("data"),
        })
    end,
}
