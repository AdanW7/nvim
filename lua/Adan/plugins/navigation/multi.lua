---@type Adan.LazySpec
return {
  'AdanW7/Multi_Cursor.nvim',
  branch = 'main',
  dependencies = {
    { 'nvim-telescope/telescope.nvim', optional = true }, -- Optional picker backend (preferred in auto mode)
    { 'folke/snacks.nvim', optional = true }, -- Optional picker backend fallback
  },
  opts = {
    backend = 'lua', -- Use native Lua backend
    picker = 'telescope', -- Picker strategy: auto | telescope | snacks | builtin
    insert_mode = 'native', -- Use native insert handling for multicursor insert
    multicursor_leader = '<leader>m', -- Base leader used to derive default VM-style mappings

    default_mappings = true, -- Keep plugin default mappings enabled
    check_mappings = true, -- Detect and report conflicting keymaps
    show_warnings = true, -- Show runtime warnings (conflicts, edge cases, etc.)

    use_visual_mode = true, -- Enable visual-selection driven multicursor actions
    mouse_mappings = true, -- Enable mouse-based cursor add/word/column mappings

    theme = 'helix', -- Multi-cursor highlight theme
    highlight_matches = 'underline', -- Search match highlight style

    single_mode_maps = true, -- Enable single-region cycling maps in insert mode
    single_mode_auto_reset = true, -- Auto-disable single-region mode after insert ends

    set_statusline = 2, -- Update statusline while active (balanced refresh mode)
    silent_exit = true, -- Do not notify when leaving multicursor mode
    skip_shorter_lines = false, -- Allow vertical cursor add on shorter lines

    enable_normal_key_passthrough = true, -- Replay listed normal-mode motions across cursors
    normal_keys = {
      'h',
      'j',
      'k',
      'l', -- Basic motions
      'w',
      'W',
      'b',
      'B',
      'e',
      'E',
      'ge',
      'gE', -- Word motions
      '0',
      '^',
      '$',
      '%', -- Line/jump motions
      'f',
      'F',
      't',
      'T',
      ',',
      ';',
      '|', -- Character-find motions
      'gh',
      'gs',
      'gl', -- Custom remapped motions
    },

    mappings = {
      find_under = '<leader>mn', -- Add/find next occurrence of word under cursor
      find_subword_under = '<leader>mN', -- Add/find subword under cursor
      select_all = '<leader>mA', -- Select all matches for current search
      regex_search = '<leader>m/', -- Prompt regex and create regions

      add_cursor_at_pos = '<leader>ma', -- Toggle cursor at current position
      add_cursor_down = { '<leader>mj', 'C' }, -- Add cursor below
      add_cursor_up = '<leader>mk', -- Add cursor above

      search_menu = '<leader>mp', -- Open search menu via configured picker
      tools_menu = '<leader>mt', -- Open tools menu via configured picker

      skip = '<leader>mq', -- Skip current match and move on
      remove = '<leader>mQ', -- Remove current region/cursor
      reselect_last = '<leader>mg', -- Restore last cleared cursor set

      toggle_mode = '<Tab>', -- Toggle cursor mode <-> extend mode
      toggle_mappings = '<leader>m<Space>', -- Temporarily enable/disable MC mappings
      clear = '<leader>m<Esc>', -- Clear all cursors and exit multicursor mode

      show_registers = '<leader>m"', -- Show multicursor register state
      rewrite_last_search = '<leader>mr', -- Rewrite last search from current word/selection
    },
  },
  keys = {
    { '<leader>mp', mode = { 'n', 'x' }, desc = 'MC: Search menu (picker)' }, -- Picker-backed search actions
    { '<leader>mt', mode = { 'n', 'x' }, desc = 'MC: Tools menu (picker)' }, -- Picker-backed tools actions
    { '<leader>mn', mode = { 'n', 'x' }, desc = 'MC: Find word' }, -- Word match add/find
    { '<leader>mN', mode = { 'n', 'x' }, desc = 'MC: Find subword' }, -- Subword match add/find
    { '<leader>mA', mode = { 'n', 'x' }, desc = 'MC: Select all' }, -- Select all matches
    { '<leader>m/', mode = { 'n', 'x' }, desc = 'MC: Regex search' }, -- Regex search entry
    { '<leader>ma', mode = { 'n' }, desc = 'MC: Add cursor at pos' }, -- Cursor toggle
    { '<leader>mj', '<Cmd>MultiCursorAddCursorDown<CR>', mode = 'n', desc = 'MC: Add cursor down' },
    { 'C', '<Cmd>MultiCursorAddCursorDown<CR>', mode = 'n', desc = 'MC: Add cursor down' },
    { '<leader>mk', mode = { 'n' }, desc = 'MC: Add cursor up' }, -- Vertical add up
    { '<Tab>', mode = { 'n' }, desc = 'MC: Toggle extend/cursor' }, -- Fast mode switch
    { '<leader>m<Space>', mode = { 'n' }, desc = 'MC: Toggle mappings' }, -- Freeze/unfreeze keymap takeover
    { '<leader>m<Esc>', mode = { 'n' }, desc = 'MC: Clear' }, -- Hard exit + clear
  },
}
