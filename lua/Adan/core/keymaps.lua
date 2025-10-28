-- =============================================================================
-- LEADER KEY SETUP
-- =============================================================================
vim.keymap.set("n", "<space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = ' '


-- =============================================================================
-- BASIC EDITOR BEHAVIOR
-- =============================================================================

-- Clear search highlights
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Redo with capital U
vim.keymap.set("n", "U", "<C-r>", { silent = true, noremap = true, desc = "Redo" })

-- Q repeats last macro instead of entering ex mode
vim.keymap.set('n', 'Q', '@@', { noremap = true, silent = true })


-- =============================================================================
-- MOVEMENT & NAVIGATION
-- =============================================================================

-- Line navigation
vim.keymap.set({ "n", "v", "o", "x" }, "gh", "0", { noremap = true, silent = true, desc = "go to begining of line" })
vim.keymap.set({ "n", "v", "o", "x" }, "gs", "^", {
    noremap = true,
    silent = true,
    desc = "go to first not white space in line"
})
vim.keymap.set({ "n", "v", "o", "x" }, "gl", "$", {
    noremap = true,
    silent = true,
    desc = "go to end of line"
})
vim.keymap.set({ "n", "v", "o", "x" }, "ge", "G", {
    noremap = true,
    silent = true,
    desc = "go to end of file"
})

-- Page navigation (centered)
vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz", {
    noremap = true,
    silent = true,
    desc = "jump up the page"
})
vim.keymap.set({ "n", "v" }, "<C-u>", "<C-u>zz", {
    noremap = true,
    silent = true,
    desc = "jump down the page"
})


-- =============================================================================
-- SEARCH
-- =============================================================================

-- Search within visual selection
vim.keymap.set("v", "/", function()
    vim.cmd('normal! "vy')
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>/\\%V', true, false, true), 'n', false)
end, { desc = "Search in visual selection" })


-- =============================================================================
-- COPY, PASTE & CLIPBOARD
-- =============================================================================

-- Internal (unnamed) register operations
vim.keymap.set({ "n", "v" }, "y", "y", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "Y", "Y", { noremap = true, silent = true })
vim.keymap.set("n", "p", "p", { noremap = true, silent = true, desc = "paste nvim clipboard at cursor" })
vim.keymap.set("n", "P", "P", { noremap = true, silent = true, desc = "paste nvim clipboard before cursor" })

-- System clipboard operations (Leader prefix)
vim.keymap.set({ "n", "v" }, "<Leader>y", [["+y]], {
    noremap = true,
    silent = true,
    desc = "save text to system clipboard"
})
vim.keymap.set("n", "<Leader>Y", [["+Y]], {
    noremap = true,
    silent = true,
    desc = "save current line to system clipboard"
})
vim.keymap.set("n", "<Leader>pp", [["+p]], {
    noremap = true,
    silent = true,
    desc = "paste from system clipboard at cursor"
})
vim.keymap.set("n", "<Leader>pP", [["+P]], {
    noremap = true,
    silent = true,
    desc = "paste from system clipboard before cursor"
})

-- Replace selection without yanking
vim.keymap.set({ "v", "x" }, "R", [["_dP]], {
    noremap = true,
    silent = true,
    desc = "Replace selection with unnamed register"
})
vim.keymap.set({ "v", "x" }, "<Leader>R", [["+p]], {
    noremap = true,
    silent = true,
    desc = "Replace selection with system clipboard"
})


-- =============================================================================
-- BUFFER MANAGEMENT
-- =============================================================================

-- Buffer navigation
vim.keymap.set("n", "gn", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "gp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- Buffer operations (Leader + b prefix)
vim.keymap.set('n', '<Leader>bcc', function()
    vim.cmd('bdelete!')
end, { desc = "Force close current buffer" })

vim.keymap.set('n', '<Leader>bca', function()
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = false })
        end
    end
end, { desc = "Close all buffers (skip unsaved)" })

vim.keymap.set('n', '<Leader>bco', function()
    local current = vim.api.nvim_get_current_buf()
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
        if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = false })
        end
    end
end, { desc = "Close all buffers except current (skip unsaved)" })

vim.keymap.set('n', '<leader>br', '<cmd>checktime<CR>', { desc = 'Reload all buffers' })


-- =============================================================================
-- WINDOW MANAGEMENT
-- =============================================================================

-- Window splits
vim.keymap.set("n", "<Leader>wv", "<cmd>vsplit<CR>", {
    noremap = true,
    silent = true,
    desc = "Split Window vertically"
})
vim.keymap.set("n", "<Leader>ws", "<cmd>split<CR>", {
    noremap = true,
    silent = true,
    desc = "Split Window horizontally"
})

-- Window navigation
vim.keymap.set("n", "<Leader>wh", "<C-w>h", { noremap = true, silent = true, desc = "Move to left window" })
vim.keymap.set("n", "<Leader>wl", "<C-w>l", { noremap = true, silent = true, desc = "Move to right window" })
vim.keymap.set("n", "<Leader>wj", "<C-w>j", { noremap = true, silent = true, desc = "Move to window below" })
vim.keymap.set("n", "<Leader>wk", "<C-w>k", { noremap = true, silent = true, desc = "Move to window above" })

-- Window close
vim.keymap.set("n", "<Leader>wq", "<cmd>close<CR>", { noremap = true, silent = true, desc = "Close current window" })

-- Scratch buffers
vim.keymap.set("n", "<leader>wnv", function()
    vim.cmd("vnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "hide"
    vim.bo.swapfile = false
end, { desc = "New scratch buffer (vertical)" })

vim.keymap.set("n", "<leader>wns", function()
    vim.cmd("new")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "hide"
    vim.bo.swapfile = false
end, { desc = "New scratch buffer (horizontal)" })


-- =============================================================================
-- TAB MANAGEMENT
-- =============================================================================

-- Tab creation
vim.keymap.set({ "n", "t" }, "<Leader>ta", "<cmd>tabnew<CR>",
    { noremap = true, silent = true, desc = "create a new tab" })
vim.keymap.set({ "n", "t" }, "<Leader>tb", "<cmd>tabedit %<CR>",
    { noremap = true, silent = true, desc = "open current buffer in new tab" })

-- Tab closing
vim.keymap.set({ "n", "t" }, "<Leader>tcc", "<cmd>tabclose<CR>",
    { noremap = true, silent = true, desc = "close current tab" })
vim.keymap.set({ "n", "t" }, "<Leader>tco", "<cmd>tabonly<CR>",
    { noremap = true, silent = true, desc = "close other tabs" })

-- Tab navigation
vim.keymap.set({ "n", "t" }, "tn", "gt", { noremap = true, silent = true, desc = "next tab" })
vim.keymap.set({ "n", "t" }, "tp", "gT", { noremap = true, silent = true, desc = "previous tab" })
vim.keymap.set({ "n", "t" }, "<Leader>t1", "1gt", { noremap = true, silent = true, desc = "goto tab 1" })
vim.keymap.set({ "n", "t" }, "<Leader>t2", "2gt", { noremap = true, silent = true, desc = "goto tab 2" })
vim.keymap.set({ "n", "t" }, "<Leader>t3", "3gt", { noremap = true, silent = true, desc = "goto tab 3" })

-- Tab reordering
vim.keymap.set({ "n", "t" }, "<Leader>tm>", "<cmd>tabmove +1<CR>",
    { noremap = true, silent = true, desc = "move current tab to the right" })
vim.keymap.set({ "n", "t" }, "<Leader>tm<", "<cmd>tabmove -1<CR>",
    { noremap = true, silent = true, desc = "move current tab to the left" })


-- =============================================================================
-- TERMINAL MODE
-- =============================================================================

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal window navigation
vim.keymap.set('t', '<A-h>', '<C-\\><C-n><C-w>h', { desc = 'Exit terminal to left split' })
vim.keymap.set('t', '<A-j>', '<C-\\><C-n><C-w>j', { desc = 'Exit terminal to lower split' })
vim.keymap.set('t', '<A-k>', '<C-\\><C-n><C-w>k', { desc = 'Exit terminal to above split' })
vim.keymap.set('t', '<A-l>', '<C-\\><C-n><C-w>l', { desc = 'Exit terminal to right mode' })


-- =============================================================================
-- QUICKFIX LIST
-- =============================================================================

-- Quickfix navigation
vim.keymap.set('n', '<leader>cn', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '<leader>cp', '<cmd>cprev<CR>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', '<leader>cf', '<cmd>cfirst<CR>', { desc = 'First quickfix item' })
vim.keymap.set('n', '<leader>cl', '<cmd>clast<CR>', { desc = 'Last quickfix item' })

-- Quickfix history
vim.keymap.set('n', '<leader>co', '<cmd>colder<CR>', { desc = 'Older quickfix list' })
vim.keymap.set('n', '<leader>ce', '<cmd>cnewer<CR>', { desc = 'Newer quickfix list' })

-- Quickfix window
vim.keymap.set('n', '<leader>qo', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
vim.keymap.set('n', '<leader>qc', '<cmd>cclose<CR>', { desc = 'Close quickfix list' })


-- =============================================================================
-- DIAGNOSTICS
-- =============================================================================

vim.keymap.set('n', '<leader>qd', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })


-- =============================================================================
-- LSP
-- =============================================================================

-- Go to definition
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })

-- Code actions
vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, { desc = "LSP code actions" })

-- LSP restart
vim.keymap.set("n", "<leader>lr", function()
    vim.lsp.stop_client(vim.lsp.get_clients())
    vim.cmd("edit")
end, { desc = "LSP Restart" })


-- =============================================================================
-- FILE & DIRECTORY
-- =============================================================================

-- Change directory to current file
vim.keymap.set("n", "<leader>cd", '<cmd>lua vim.fn.chdir(vim.fn.expand("%:p:h"))<CR>', {
    desc = "Change directory to the current file"
})


-- =============================================================================
-- PLUGIN-SPECIFIC
-- =============================================================================

-- Neo-tree
vim.keymap.set("n", "<leader>e", ":Neotree filesystem reveal left<CR>", { desc = "Toggle Neo-tree" })


-- =============================================================================
-- RELOAD CONFIG
-- =============================================================================

vim.keymap.set("n", "<leader>rc", function()
    for name, _ in pairs(package.loaded) do
        if name:match('^Adan') then
            package.loaded[name] = nil
        end
    end
    dofile(vim.fn.stdpath('config') .. '/init.lua')
    vim.notify("Config reloaded!", vim.log.levels.INFO)
end, { desc = "Reload config" })


-- =============================================================================
-- Create / Open a Daily Note Markdown file
-- =============================================================================
vim.keymap.set('n', '<leader>n', function()
    -- Get today's date in Obsidian format (YYYY-MM-DD)
    local date = os.date("%Y-%m-%d")

    -- Detect OS and set path accordingly
    local dir
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        -- Windows OneDrive path
        dir = "C:/Users/awodzins/OneDrive - Milwaukee Tool/Documents/Notes/Daily notes"
    else
        -- Linux/Mac path
        dir = vim.fn.expand("~/Notes/DailyNotes")
    end

    local filepath = dir .. "/" .. date .. ".md"

    -- Create directory if it doesn't exist
    vim.fn.mkdir(dir, "p")

    -- Open the file (creates it if it doesn't exist)
    vim.cmd("edit " .. filepath)
end, { desc = "Open today's daily note" })
