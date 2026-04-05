local M = {}

function M.extend_opts(opts)
  opts.input = {
    enabled = true,
    icon = ' ',
    icon_hl = 'SnacksInputIcon',
    icon_pos = 'left',
    prompt_pos = 'title',
  }

  opts.styles = opts.styles or {}
  opts.styles.input = {
    backdrop = false,
    position = 'float',
    border = true,
    title_pos = 'center',
    height = 1,
    width = 60,
    relative = 'editor',
    row = 2,
    wo = {
      winhighlight = 'NormalFloat:SnacksInputNormal,FloatBorder:SnacksInputBorder,FloatTitle:SnacksInputTitle',
      cursorline = false,
    },
    bo = {
      filetype = 'snacks_input',
      buftype = 'prompt',
    },
  }
end

return M
