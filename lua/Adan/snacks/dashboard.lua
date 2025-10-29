return {
    "folke/snacks.nvim",
    lazy= false,
    priority = 1000,
    init = function()
        -- Disable netrw
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
        dashboard = {
            enabled = true,
            preset = {
                header = [[
    ░█████    ░███    ░███████   ░██████████    ░██    ░██ ░██████░███     ░███
      ░██    ░██░██   ░██   ░██  ░██            ░██    ░██   ░██  ░████   ░████
      ░██   ░██  ░██  ░██    ░██ ░██            ░██    ░██   ░██  ░██░██ ░██░██
      ░██  ░█████████ ░██    ░██ ░█████████     ░██    ░██   ░██  ░██ ░████ ░██
░██   ░██  ░██    ░██ ░██    ░██ ░██             ░██  ░██    ░██  ░██  ░██  ░██
░██   ░██  ░██    ░██ ░██   ░██  ░██              ░██░██     ░██  ░██       ░██
 ░██████   ░██    ░██ ░███████   ░██████████       ░███    ░██████░██       ░██
]],
                keys = {
                    { icon = "󰈞 ", key = "f", desc = "Find File", action = ":Telescope find_files" },
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    { icon = "󰋚 ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
                    { icon = "󰱼 ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
                    { icon = " ", key = "c", desc = "Config", action = ":e $MYVIMRC" },
                    {
                        icon = "󰦛 ",
                        key = "s",
                        desc = "Restore Session",
                        action = function()
                            require("persistence").load()
                        end
                    },
                    { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                    { icon = "󰩈 ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
            sections = {
                { section = "header" },
                { section = "keys", gap = 1, padding = 1 },
                { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                { section = "startup" },
            },
        },
    },
}
