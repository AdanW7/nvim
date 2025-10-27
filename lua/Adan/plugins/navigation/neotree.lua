return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
    { "<leader>ge", "<cmd>Neotree git_status toggle<cr>", desc = "Git Explorer" },
    { "<leader>be", "<cmd>Neotree buffers toggle<cr>", desc = "Buffer Explorer" },
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        local directory = vim.fn.isdirectory(data.file) == 1
        if directory then
          vim.cmd.enew()
          vim.cmd.bw(data.buf)
          vim.cmd("Neotree show")
        end
      end,
    })
  end,
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      bind_to_cwd = false,  -- Allow navigation outside initial directory
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      mappings = {
        ["l"] = "open",
        ["h"] = "close_node",
        ["<space>"] = "none",
        ["r"] = "rename",
        ["y"] = "copy_to_clipboard",
        ["p"] = "paste_from_clipboard",
        ["d"] = "delete",
      },
    },
  },
}
