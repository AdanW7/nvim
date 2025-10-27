-- =============================================================================
-- APPEARANCE & UI
-- =============================================================================

-- Color scheme
-- vim.cmd.colorscheme("helix")
vim.opt.termguicolors = true -- Enable true colors

-- Cursor
vim.opt.guicursor = {
  "n-v-c:block-Cursor/lCursor",     -- Normal, visual, command: block cursor
  "i-ci-ve:ver25-Cursor/lCursor",   -- Insert: vertical bar (25% width)
  "r-cr:hor20-Cursor/lCursor",      -- Replace: horizontal bar (20% height)
  "o:hor50-Cursor/lCursor",         -- Operator pending
  "sm:block-Cursor/lCursor",        -- Showmatch
}

-- Enable inverse/reverse video for cursor
vim.api.nvim_set_hl(0, "Cursor", { reverse = true })
vim.api.nvim_set_hl(0, "lCursor", { reverse = true })
vim.api.nvim_set_hl(0, "TermCursor", { reverse = true })

vim.opt.cursorline = true -- Highlight the current line

-- Line numbers
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Disable relative line numbers
vim.opt.numberwidth = 2 -- Width of the line number column

-- Columns
vim.opt.colorcolumn = "" -- No column highlight
vim.opt.signcolumn = "yes:1" -- Always show sign column

-- Whitespace visualization
vim.opt.list = true -- Show whitespace characters
vim.opt.listchars = {
    tab = "→ ",
    multispace = "┊   ",
    trail = "·",
    nbsp = "⎵",
} -- Characters to show for tabs and spaces

-- Mode display
vim.opt.showmode = false -- Don't show mode (statusline handles this)

-- Borders
vim.opt.winborder = "rounded" -- Use rounded borders for windows


-- =============================================================================
-- BEHAVIOR & EDITING
-- =============================================================================

-- Mouse
vim.opt.mouse = 'a' -- Enable mouse mode

-- Indentation
vim.opt.autoindent = true -- Enable auto indentation
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.tabstop = 4 -- Number of spaces for a tab
vim.opt.softtabstop = 4 -- Number of spaces for a tab when editing
vim.opt.shiftwidth = 4 -- Number of spaces for autoindent
vim.opt.shiftround = true -- Round indent to multiple of shiftwidth
vim.cmd.filetype("plugin indent on") -- Enable filetype detection, plugins, and indentation

-- Line wrapping
vim.opt.wrap = true -- Enable line wrapping
vim.opt.linebreak = true -- Wrap at word boundaries
vim.opt.breakindent = true -- Maintain indent when wrapping
vim.opt.showbreak = "↪ " -- Visual indicator for wrapped lines

-- Scrolling
vim.opt.scrolloff = 8 -- Keep 8 lines above and below cursor


-- =============================================================================
-- SEARCH
-- =============================================================================

vim.opt.ignorecase = true -- Ignore case in search
vim.opt.smartcase = true -- Override ignorecase if search contains uppercase
vim.opt.hlsearch = true -- Highlight search results
vim.opt.inccommand = "nosplit" -- Show effects of command incrementally


-- =============================================================================
-- COMPLETION
-- =============================================================================

vim.opt.completeopt = { "menuone", "popup", "noinsert" } -- Completion menu options


-- =============================================================================
-- FILES & PERSISTENCE
-- =============================================================================

-- Swap files
vim.opt.swapfile = false -- Disable swap files

-- Undo
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir' -- Directory for undo files
vim.opt.undofile = true -- Enable persistent undo


-- =============================================================================
-- WINDOWS & SPLITS
-- =============================================================================

vim.opt.splitright = true -- New vertical splits open to the right
vim.opt.splitbelow = true -- New horizontal splits open below


-- =============================================================================
-- TIMING
-- =============================================================================

vim.opt.timeoutlen = 300 -- Decrease mapped sequence wait time (ms)
vim.opt.updatetime = 250 -- Decrease update time (ms)


-- =============================================================================
-- FONTS
-- =============================================================================

vim.g.have_nerd_font = true -- Enable Nerd Font icons
