return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 200,
    spec = {
      { "<leader>b", group = "Buffers" },
      { "<leader>w", group = "Windows" },
      { "<leader>t", group = "Tabs" },
      { "<leader>l", group = "LSP" },
      { "<leader>p", group = "Projects" },
      { "<leader>P", group = "Paste" },
      { "<leader>c", group = "Navigate Quick fix list" },
      { "<leader>q", group = "Open / Close Quick fix list" },
      { "<leader>s", group = "sessions" },
      { "<leader>r", group = "reload" },
      { "<leader>f", group = "Telescope" },
      { "<leader>", group = "Git" },
      { "<leader>wn", group = "Scratch buffer in New Window" },
    },
    plugins = {
      marks = true,           -- shows list of marks on ' and `
      registers = true,       -- shows registers on " and @ in normal/visual mode
      spelling = {
        enabled = true,       -- z= to select spelling suggestions
        suggestions = 20,
      },
      presets = {
        operators = true,          -- adds help for operators like d, y, c
        motions = true,            -- adds help for motions
        text_objects = true,       -- adds help for text objects like iw, aw
        windows = true,            -- default bindings on <c-w>
        nav = true,                -- misc bindings for navigation
        z = true,                  -- bindings for folds, spelling, etc.
        g = true,                  -- bindings for g prefix
      },
    },
    win = {
      border = "rounded",       -- "none", "single", "double", "rounded", "solid", "shadow"
      -- padding = { 1, 1},  -- {top/bottom, left/right}
      title = true,             -- show window title
      title_pos = "center",     -- "left", "center", "right"
      -- wo = {
      --     winblend = 0,      -- transparency (0-100)
      -- },
    },
    disable = {
      ft = { "TelescopePrompt" },
      bt = { "terminal" },
    },
    replace = {
      key = {
        { "<Space>", "SPC" },
        { "<CR>",    "RET" },
        { "<Tab>",   "TAB" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
