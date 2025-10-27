return {
    "AdanW7/helix.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("helix").setup({
            -- Transparent background (for transparent terminals)
            transparent = false,

            -- Enable terminal colors
            term_colors = true,

            -- Show end-of-buffer tildes
            ending_tildes = false,

            -- Code style options
            code_style = {
                comments = 'italic', -- 'italic', 'bold', 'underline', 'none'
                keywords = 'none',
                functions = 'none',
                strings = 'none',
                variables = 'none',
                constants = 'none',
            },

            -- Diagnostics appearance
            diagnostics = {
                darker = false, -- Use darker diagnostic colors
                undercurl = true, -- Use undercurl for diagnostics
                background = false, -- Use background color for virtual text
            },

            -- Override specific colors (optional)
            colors = {
                -- Example: red = "#ff0000",
            },

            -- Override highlight groups (optional)
            highlights = {
                -- Example: Comment = { fg = "$grey", fmt = "italic" },
            },

        })
        require("helix").load()
    end,
}
