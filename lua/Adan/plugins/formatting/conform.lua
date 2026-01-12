return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            rust = { "rustfmt", lsp_format = "fallback" },
            go = { "goimports", "gofmt" },
            zig = { "zigfmt" },
            python = { "ruff_format" },
            ocaml = { "ocamlformat" },
            org = {},
        },

        -- Set this to change the default values when calling conform.format()
        -- This will also affect the default values for format_on_save/format_after_save
        default_format_opts = {
            lsp_format = "fallback",
        },

        formatters = {},
        -- If this is set, Conform will run the formatter on save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        -- format_on_save = {
        --   -- I recommend these options. See :help conform.format for details.
        --   lsp_format = "fallback",
        --   timeout_ms = 500,
        -- },
        -- If this is set, Conform will run the formatter asynchronously after save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        -- format_after_save = {
        --   lsp_format = "fallback",
        -- },
        -- Set the log level. Use `:ConformInfo` to see the location of the log file.
        -- log_level = vim.log.levels.ERROR,
        -- Conform will notify you when a formatter errors
        notify_on_error = true,
        -- Conform will notify you when no formatters are available for the buffer
        notify_no_formatters = true,
    },
    keys = {
        {
            "<leader>lf",
            function()
                -- For org files, use orgmode's built-in formatting
                if vim.bo.filetype == "org" then
                    vim.cmd("normal! gggqG") -- Format whole file
                else
                    require("conform").format({ async = true, lsp_fallback = true })
                end
            end,
            mode = { "n", "v" },
            desc = "LSP Format",
        },
    },
}
