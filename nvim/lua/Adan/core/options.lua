-- mouse and cursor
vim.opt.mouse = 'a'-- Enable mouse mode, can be useful for resizing splits for example
vim.opt.guicursor = {"v:block","n:block","i:ver25"} -- Use block cursor in normal and visual mode, beam in insert mode

-- color options
vim.opt.termguicolors = true -- Enable true colors

-- colomn options
vim.opt.colorcolumn = "" -- Highlight column
vim.opt.signcolumn = "yes:1" -- Always show sign column

-- search 
vim.opt.ignorecase = true -- Ignore case in search
vim.opt.smartcase = true
vim.opt.hlsearch = true -- Enable/Disable highlighting of search results

-- swap file settings
vim.opt.swapfile = false

-- indenting
vim.opt.autoindent = true -- Enable auto indentation
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 4 -- Number of spaces for a tab
vim.opt.softtabstop = 4 -- Number of spaces for a tab when editing
vim.opt.shiftwidth = 4 -- Number of spaces for autoindent
vim.opt.shiftround = true -- Round indent to multiple of shiftwidth
vim.cmd.filetype("plugin indent on") -- Enable filetype detection, plugins, and indentation

-- white space representation
vim.opt.list = true -- Show whitespace characters
-- vim.opt.listchars = "tab: ,multispace:|   ,eol:󰌑" -- Characters to show for tabs, spaces, and end of line
vim.opt.listchars = "tab: ,multispace:|   " -- Characters to show for tabs, spaces, and end of line

-- line numbers
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Show relative line numbers
vim.opt.numberwidth = 2 -- Width of the line number column
vim.opt.cursorline = true -- Highlight the current line
vim.opt.scrolloff = 8 -- Keep N lines above and below the cursor

-- wrapping
vim.opt.wrap = true -- Enable/Disable line wrapping
vim.opt.linebreak = true -- Enable/Disable line wrapping
vim.opt.breakindent = true -- Enable break indent
vim.opt.showbreak = "↪ " -- Optional: Visual indicator for wrapped lines


-- command options
vim.opt.inccommand = "nosplit" -- Shows the effects of a command incrementally in the buffer

-- undo options
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir' -- Directory for undo files
vim.opt.undofile = true -- Enable persistent undo

-- window options
vim.opt.splitright = true --makes new vertical splits open to the right of the current window
vim.opt.splitbelow = true -- makes new horizontal splits open below the current window
vim.opt.winborder = "rounded" -- Use rounded borders for windows

--completion
vim.opt.completeopt = { "menuone", "popup", "noinsert" } -- Options for completion menu

-- color scheme
-- vim.cmd.colorscheme("techbase")

-- enable nerdfont
vim.g.have_nerd_font = true

-- show current mode
vim.opt.showmode = false

-- timing options
-- 
vim.opt.timeoutlen = 300-- Decrease mapped sequence wait time
vim.opt.updatetime = 250-- Decrease update time
