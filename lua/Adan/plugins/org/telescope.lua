return {
	"nvim-orgmode/telescope-orgmode.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-orgmode/orgmode",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("telescope").load_extension("orgmode")

		vim.keymap.set("n", "<leader>ofr", require("telescope").extensions.orgmode.refile_heading,{ desc = "Refile Heading" })
		vim.keymap.set("n", "<leader>off", require("telescope").extensions.orgmode.search_headings,{ desc = "Search Headings" })
		vim.keymap.set("n", "<leader>ofl", require("telescope").extensions.orgmode.insert_link,{ desc = "Insert Link" })
		vim.keymap.set("n", "<leader>oft", require("telescope").extensions.orgmode.search_tags,{ desc = "Seach Tags" })
	end,
}
