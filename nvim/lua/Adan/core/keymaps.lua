-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })


-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })


-- rather than enter ex mode pressing 'Q' no repeats last macro
vim.keymap.set('n', 'Q', '@@', { noremap = true, silent = true })

-- rebind redo to capital U
vim.keymap.set("n", "U", "<C-r>", { silent = true, noremap = true, desc = "Redo" })

-- *************Momvement**************
vim.keymap.set({ "n", "v", "o" }, "gh", "0", { noremap = true, silent = true, desc = "go to begining of line" })
vim.keymap.set({ "n", "v", "o" }, "gs", "^",
    { noremap = true, silent = true, desc = "go to first not white space in line" })
vim.keymap.set({ "n", "v", "o" }, "gl", "$", { noremap = true, silent = true, desc = "go to end of line" })
vim.keymap.set({ "n", "v", "o" }, "ge", "G", { noremap = true, silent = true, desc = "go to end of file" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true, desc = "jump up the page" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true, desc = "jump down the page" })


-- *************Leader**************
vim.keymap.set("n", "<space>", "<Nop>")

-- Set space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ' '


-- *************Tabs**************
vim.keymap.set({ "n", "t" }, "<Leader>ta", "<cmd>tabnew<CR>",
    { noremap = true, silent = true, desc = "create a new tab" })
vim.keymap.set({ "n", "t" }, "<Leader>tb", "<cmd>tabedit %<CR>",
    { noremap = true, silent = true, desc = "open current buffer in new tab" })                                                          --
vim.keymap.set({ "n", "t" }, "<Leader>tco", "<cmd>tabonly<CR>",
    { noremap = true, silent = true, desc = "close other tabs" })                                                                        -- “to” = tab only (close others)
vim.keymap.set({ "n", "t" }, "<Leader>tcc", "<cmd>tabclose<CR>",
    { noremap = true, silent = true, desc = "close current tab" })                                                                       -- “tc” = tab close
vim.keymap.set({ "n", "t" }, "<Leader>tn", "gt", { noremap = true, silent = true, desc = "next tab" })
vim.keymap.set({ "n", "t" }, "<Leader>tp", "gT", { noremap = true, silent = true, desc = "previous tab" })
vim.keymap.set({ "n", "t" }, "<Leader>tm>", "<cmd>tabmove +1<CR>",
    { noremap = true, silent = true, desc = "move current tab to the right" })
vim.keymap.set({ "n", "t" }, "<Leader>tm<", "<cmd>tabmove -1<CR>",
    { noremap = true, silent = true, desc = "move current tab to the left" })
vim.keymap.set({ "n", "t" }, "<Leader>t1", "1gt", { noremap = true, silent = true, desc = "goto tab 1" })
vim.keymap.set({ "n", "t" }, "<Leader>t2", "2gt", { noremap = true, silent = true, desc = "goto tab 2" })
vim.keymap.set({ "n", "t" }, "<Leader>t3", "3gt", { noremap = true, silent = true, desc = "goto tab 3" })

-- *************Windows**************
vim.keymap.set("n", "<Leader>wv", "<cmd>vsplit<CR>", { noremap = true, silent = true, desc = "Split Window vertically" })
vim.keymap.set("n", "<Leader>ws", "<cmd>split<CR>", { noremap = true, silent = true, desc = "Split Window horizontally" })
vim.keymap.set("n", "<Leader>wh", "<C-w>h", { noremap = true, silent = true, desc = "Move to left window" })
vim.keymap.set("n", "<Leader>wl", "<C-w>l", { noremap = true, silent = true, desc = "Move to right window" })
vim.keymap.set("n", "<Leader>wj", "<C-w>j", { noremap = true, silent = true, desc = "Move to window below" })
vim.keymap.set("n", "<Leader>wk", "<C-w>k", { noremap = true, silent = true, desc = "Move to window above" })
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


-- Buffer navigation
vim.keymap.set("n", "gn", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "gp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })


-- *************Copy and Paste**************
-- In normal + visual modes, remap y to use the *unnamed* (internal) register
vim.keymap.set({ "n", "v" }, "y", "y", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "Y", "Y", { noremap = true, silent = true })

-- In normal mode, remap p and P to use unnamed (internal) registers by default
vim.keymap.set("n", "p", "p", { noremap = true, silent = true, desc = "paste nvim clipboard at cursor" })
vim.keymap.set("n", "P", "P", { noremap = true, silent = true, desc = "paste nvim clipboard before cursor" })

-- Now map Leader + y, p, P to use the system clipboard (the + register)
vim.keymap.set({ "n", "v" }, "<Leader>y", [["+y]],
    { noremap = true, silent = true, desc = "save text to system clipboard" })
vim.keymap.set("n", "<Leader>Y", [["+Y]],
    { noremap = true, silent = true, desc = "save current line to system clipboard" })
vim.keymap.set("n", "<Leader>Pp", [["+p]],
    { noremap = true, silent = true, desc = "paste from system clipboard at cursor" })
vim.keymap.set("n", "<Leader>PP", [["+P]],
    { noremap = true, silent = true, desc = "paste from system clipboard before cursor" })


-- Exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-N>")


vim.keymap.set("n", "<leader>cd", '<cmd>lua vim.fn.chdir(vim.fn.expand("%:p:h"))<CR>',
    { desc = "Change directory to the current file" })


-- Go to definition
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })


-- Force close current buffer (like :bdelete!)
vim.keymap.set('n', '<Leader>bc', function()
    vim.cmd('bdelete!')
end, { desc = "Force close current buffer" })


vim.keymap.set("n", "<leader>e", ":Neotree filesystem reveal left<CR>", { desc = "Toggle Neo-tree" })


-- Navigate within the current quickfix list
vim.keymap.set('n', '<leader>cn', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '<leader>cp', '<cmd>cprev<CR>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', '<leader>cf', '<cmd>cfirst<CR>', { desc = 'First quickfix item' })
vim.keymap.set('n', '<leader>cl', '<cmd>clast<CR>', { desc = 'Last quickfix item' })

-- Navigate quickfix list history
vim.keymap.set('n', '<leader>co', '<cmd>colder<CR>', { desc = 'Older quickfix list' })
vim.keymap.set('n', '<leader>ce', '<cmd>cnewer<CR>', { desc = 'Newer quickfix list' })

-- Open/Close quickfix window
vim.keymap.set('n', '<leader>qo', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
vim.keymap.set('n', '<leader>qc', '<cmd>cclose<CR>', { desc = 'Close quickfix list' })


-- LSP restart
vim.keymap.set("n", "<leader>lr", function()
    vim.lsp.stop_client(vim.lsp.get_clients())
    vim.cmd("edit")
end, { desc = "LSP Restart" })


-- Search within visual selection and exit visual mode
vim.keymap.set("v", "/", function()
    -- Store the visual selection marks
    vim.cmd('normal! "vy')
    -- Exit visual mode and start search with \%V restriction
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>/\\%V', true, false, true), 'n', false)
end, { desc = "Search in visual selection" })

vim.api.nvim_set_keymap("n", "<leader>ro", ":luafile ~/.config/nvim/init.lua<CR>",
    { noremap = true, silent = true, desc = "reload nvim", })


vim.keymap.set('n', '<leader>br', '<cmd>checktime<CR>', { desc = 'Reload all buffers' })
