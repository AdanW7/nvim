return {
  'mg979/vim-visual-multi',
  branch = 'master',
  init = function()
    -- Set VM leader to <leader>m
    vim.g.VM_leader = vim.g.mapleader .. 'm'

    -- Enable visual mode for all cursors
    vim.g.VM_use_visual_mode = 1

    -- Custom key mappings
    vim.g.VM_maps = {
      -- Core functionality
      ['Find Under'] = '<leader>mn', -- Find word under cursor
      ['Find Subword Under'] = '<leader>mN', -- Find subword under cursor

      -- Add cursors
      ['Add Cursor Down'] = 'C', -- Add cursor down
      ['Add Cursor Up'] = '<leader>mk', -- Add cursor up
      ['Add Cursor At Pos'] = '<leader>ma', -- Add cursor at position

      -- Selection
      ['Select All'] = '<leader>mA', -- Select all occurrences
      ['Start Regex Search'] = '<leader>m/', -- Regex search
      ['Select l'] = '<leader>ml', -- Select right
      ['Select h'] = '<leader>mh', -- Select left

      -- Navigation
      ['Find Next'] = 'n', -- Find next (buffer local)
      ['Find Prev'] = 'N', -- Find previous (buffer local)
      ['Goto Next'] = ']', -- Go to next
      ['Goto Prev'] = '[', -- Go to previous
      ['Skip Region'] = 'q', -- Skip and find next
      ['Remove Region'] = 'Q', -- Remove region

      -- Operations
      ['Reselect Last'] = '<leader>mgS', -- Reselect last selections
      ['Toggle Mappings'] = '<leader>m<Space>', -- Toggle mappings

      -- Alignment and formatting
      ['Align'] = '<leader>m=', -- Align regions
      ['Align Char'] = '<leader>m<', -- Align by character
      ['Align Regex'] = '<leader>m>', -- Align by regex

      -- Advanced operations
      ['Replace Pattern'] = 'R', -- Replace in regions (buffer local)
      ['Subtract Pattern'] = '<leader>ms', -- Subtract pattern
      ['Transpose'] = '<leader>mt', -- Transpose
      ['Duplicate'] = '<leader>md', -- Duplicate

      -- Case conversion
      ['Case Conversion Menu'] = '<leader>mC', -- Case conversion menu

      -- Numbers
      ['Numbers'] = '<leader>mn', -- Append numbers
      ['Numbers Append'] = '<leader>mN', -- Prepend numbers

      -- Filters and transforms
      ['Filter Regions'] = '<leader>mf', -- Filter regions
      ['Transform Regions'] = '<leader>me', -- Transform with expression

      -- Run commands
      ['Run Normal'] = '<leader>mz', -- Run normal command
      ['Run Visual'] = '<leader>mv', -- Run visual command
      ['Run Ex'] = '<leader>mx', -- Run ex command
      ['Run Macro'] = '<leader>m@', -- Run macro

      -- Misc
      ['Show Infoline'] = '<leader>mi', -- Show infoline
      ['Toggle Single Region'] = '<leader>m<CR>', -- Single region mode

      -- Undo/Redo (optional - uncomment if desired)
      -- ["Undo"] = "u",
      -- ["Redo"] = "<C-r>",

      -- Operators
      ['Select Operator'] = 's', -- Select operator (buffer local)
      ['Find Operator'] = 'm', -- Find operator (buffer local)

      -- Slash motion
      ['Slash Search'] = 'g/', -- Slash motion (buffer local)

      -- Mouse support (optional)
      ['Mouse Cursor'] = '<C-LeftMouse>',
      ['Mouse Word'] = '<C-RightMouse>',
      ['Mouse Column'] = '<M-C-RightMouse>',
    }

    -- Additional settings
    vim.g.VM_mouse_mappings = 1 -- Enable mouse support
    vim.g.VM_theme = 'iceblue' -- Color scheme
    vim.g.VM_highlight_matches = 'underline' -- How to highlight matches

    -- Single region mode settings
    vim.g.VM_single_mode_maps = {
      ['<Tab>'] = '1', -- Cycle to next cursor in insert mode
      ['<S-Tab>'] = '-1', -- Cycle to previous cursor in insert mode
    }
    vim.g.VM_single_mode_auto_reset = 1 -- Auto-exit single mode

    -- Other useful settings
    vim.g.VM_set_statusline = 2 -- Update statusline
    vim.g.VM_silent_exit = 1 -- Don't show messages on exit
    vim.g.VM_skip_shorter_lines = 0 -- Don't skip shorter lines
  end,
  keys = {
    { '<leader>mn', mode = { 'n', 'x' }, desc = 'VM: Find word' },
    { '<leader>mA', mode = { 'n', 'x' }, desc = 'VM: Select all' },
    { '<leader>m/', mode = { 'n', 'x' }, desc = 'VM: Regex search' },
    { '<leader>ma', mode = { 'n' }, desc = 'VM: Add cursor' },
    { 'C', mode = { 'n' }, desc = 'VM: Add cursor down' },
    { '<leader>mk', mode = { 'n' }, desc = 'VM: Add cursor up' },
  },
}
