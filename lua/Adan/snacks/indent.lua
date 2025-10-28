return {
    "snacks.nvim",   -- only the name of the plugin needs to be specified since it already exists
    opts = {
        indent = {
            indent = {
                char = "▎",
            },
            scope = {
                char = "▎",
                only_current = true,
            },
            animate = {
                enabled = false,
            },
        },
    },
}
