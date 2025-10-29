return {
    "coffebar/neovim-project",
    opts = function()
        local function get_root_path(subdir)
            local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
            return is_windows and ("C:/" .. subdir) or ("/" .. subdir)
        end

        local cache_file = vim.fn.stdpath("cache") .. "/notes-folders.json"

        -- Load from cache
        local function load_cache()
            local f = io.open(cache_file, "r")
            if f then
                local content = f:read("*all")
                f:close()
                local ok, data = pcall(vim.json.decode, content)
                if ok then return data end
            end
            return nil
        end

        -- Save to cache
        local function save_cache(folders)
            local f = io.open(cache_file, "w")
            if f then
                f:write(vim.json.encode({
                    timestamp = os.time(),
                    folders = folders
                }))
                f:close()
            end
        end

        -- Find Notes folders
        local function find_notes_folders()
            local notes_folders = {}
            local home = vim.fn.expand("~")

            local function search_dir(path, max_depth)
                if max_depth <= 0 then return end

                local ok, iter = pcall(vim.fs.dir, path)
                if not ok then return end

                for name, type in iter do
                    if name ~= "." and name ~= ".." then
                        local full_path = path .. "/" .. name

                        if not name:match("^%.") and
                            name ~= "node_modules" and
                            name ~= ".git" and
                            name ~= "Library" and
                            name ~= "AppData" and
                            name ~= "cache" and
                            name ~= "Cache" then
                            if type == "directory" then
                                if name == "Notes" then
                                    table.insert(notes_folders, full_path)
                                end
                                search_dir(full_path, max_depth - 1)
                            end
                        end
                    end
                end
            end

            search_dir(home, 4)
            return notes_folders
        end

        -- Try to load from cache (valid for 24 hours)
        local cache = load_cache()
        local notes_folders = {}

        if cache and cache.timestamp and (os.time() - cache.timestamp) < 86400 then
            notes_folders = cache.folders
        else
            -- Cache is old or missing, do a fresh search
            notes_folders = find_notes_folders()
            save_cache(notes_folders)
        end

        -- Build projects list
        local projects = {
            "~/.config/*",
            get_root_path("MTRepos/*"),
        }

        for _, folder in ipairs(notes_folders) do
            table.insert(projects, folder)
        end

        return {
            projects = projects,
            last_session_on_startup = false,
            dashboard_mode = false,
            session_manager_opts = {
                autosave_ignore_dirs = {
                    vim.fn.expand("~"),
                    "/tmp",
                },
                autosave_ignore_filetypes = {
                    "gitcommit",
                    "gitrebase",
                    "qf",
                    "toggleterm",
                },
            },
            picker = {
                type = "telescope",
            },
        }
    end,
    init = function()
        vim.opt.sessionoptions:append("globals")
    end,
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope.nvim" },
        { "Shatur/neovim-session-manager" },
    },
    lazy = false,
    priority = 100,
}
