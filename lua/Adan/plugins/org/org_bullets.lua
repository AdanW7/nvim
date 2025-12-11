return {
	"nvim-orgmode/org-bullets.nvim",
	ft = { "org" },
	opts = {
		concealcursor = false, -- Show bullets when cursor is on that line
		symbols = {
			headlines = { "◉", "○", "✸", "✿" },
			-- Alternative styles you can try:
			-- headlines = { "⁖", "◉", "○", "✸", "✿" },
			-- headlines = { "I", "II", "III", "IV" },
			-- headlines = { "1.", "2.", "3.", "4." },
			list = "•",
			checkboxes = {
				half = { "◔", "@org.checkbox.halfchecked" },
				done = { "✓", "@org.keyword.done" },
				todo = { "˟", "@org.keyword.todo" },
			},
		},
	},
}
