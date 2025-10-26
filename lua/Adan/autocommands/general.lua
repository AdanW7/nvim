-- Highlight yanked text
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({ timeout = 170 })
    end,
    group = highlight_group,
})

vim.api.nvim_create_user_command('IndentStyle', function(opts)
    local width = tonumber(opts.args)

    if not width or width < 1 then
        vim.notify('Usage: :IndentStyle <width>', vim.log.levels.ERROR)
        return
    end

    -- Set for current buffer only
    vim.bo.tabstop = width
    vim.bo.shiftwidth = width
    vim.bo.softtabstop = width

    vim.notify('Indent width set to ' .. width .. ' for current buffer', vim.log.levels.INFO)
end, {
    nargs = 1,
    desc = 'Set indent width for current buffer',
})
