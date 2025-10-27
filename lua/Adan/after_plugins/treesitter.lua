require 'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all" (the listed parsers MUST always be installed)
    ensure_installed = {
        "bash",
        "bibtex",
        "c",
        "cmake",
        "cpp",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "http",
        "latex",
        "lua",
        "markdown",
        "markdown_inline",
        "powershell",
        "python",
        "query",
        "rust",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "zig"
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- List of parsers to ignore installing (or "all")
    ignore_install = { "javascript" },

    ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

    highlight = {
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        -- disable = { "c", "rust" },
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        -- disable = function(lang, buf)
        --     local max_filesize = 100 * 1024 -- 100 KB
        --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        --     if ok and stats and stats.size > max_filesize then
        --         return true
        --     end
        -- end,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true
    },
    context = {
        enable = true,
        max_lines = 5,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = 'outer',
        mode = 'cursor',
    },
    textobjects = {
        select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj
            keymaps = {
                -- Functions
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",

                -- Classes
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",

                -- Conditionals (if statements)
                ["ai"] = "@conditional.outer",
                ["ii"] = "@conditional.inner",

                -- Loops
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",

                -- Parameters/arguments
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",

                -- Comments
                ["a/"] = "@comment.outer",
                ["i/"] = "@comment.inner",

                -- Blocks
                ["ab"] = "@block.outer",
                ["ib"] = "@block.inner",

                -- Calls (function calls)
                ["aC"] = "@call.outer",
                ["iC"] = "@call.inner",
            },
        },
        move = {
            enable = true,
            set_jumps = true, -- Add to jumplist
            goto_next_start = {
                ["]f"] = "@function.outer",
                ["]c"] = "@class.outer",
                ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
                ["]F"] = "@function.outer",
                ["]C"] = "@class.outer",
                ["]A"] = "@parameter.inner",
            },
            goto_previous_start = {
                ["[f"] = "@function.outer",
                ["[c"] = "@class.outer",
                ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
                ["[F"] = "@function.outer",
                ["[C"] = "@class.outer",
                ["[A"] = "@parameter.inner",
            },
        },
        swap = {
            enable = true,
            swap_next = {
                ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
                ["<leader>A"] = "@parameter.inner",
            },
        },
    },

}
