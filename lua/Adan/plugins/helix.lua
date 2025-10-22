local M = {}
local helix = require('helix')
function M.setup()
  helix.setup({
    highlights = {
      DiffAdd = { bg = '#2d4432' },
      DiffChange = { bg = '#344353' },
      DiffDelete = { bg = '#433234' },
      DiffText = { bg = '#385070' },
      DiffviewDiffAdd = { bg = '#2d4432' },
      DiffviewDiffChange = { bg = '#344353' },
      DiffviewDiffDelete = { bg = '#433234' },
      DiffviewDiffText = { bg = '#385070' },
      DiffviewDiffAddAsDelete = { bg = '#433234' },
      DiffviewDiffDeleteDim = { bg = '#322628' },
      DiffviewDiffAddDim = { bg = '#263225' },
    },
  })
  helix.load()
end

return M
