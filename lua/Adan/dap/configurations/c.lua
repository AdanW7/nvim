local dap = require("dap")

-- Helper function to detect build system
local function detect_build_system()
    if vim.fn.filereadable("build.zig") == 1 then
        return "zig"
    elseif vim.fn.filereadable("CMakeLists.txt") == 1 then
        return "cmake"
    elseif vim.fn.filereadable("Makefile") == 1 then
        return "make"
    else
        return "none"
    end
end

-- Helper function to find executables based on build system
local function find_executable()
    local build_system = detect_build_system()
    local output_dir, build_cmd

    if build_system == "zig" then
        build_cmd = "zig build"
        output_dir = vim.fn.getcwd() .. "/zig-out/bin/"
    elseif build_system == "cmake" then
        build_cmd = "cmake --build build"
        output_dir = vim.fn.getcwd() .. "/build/"
    elseif build_system == "make" then
        build_cmd = "make"
        output_dir = vim.fn.getcwd() .. "/"
    else
        -- No build system detected, just look for executables
        output_dir = vim.fn.getcwd() .. "/"
    end

    -- Build if we have a build command
    if build_cmd then
        print("Building with: " .. build_cmd)
        vim.fn.system(build_cmd)
    end

    -- Find executables (excluding .o, .a, .so files)
    local executables = {}
    for _, file in ipairs(vim.fn.glob(output_dir .. "*", false, true)) do
        -- Check if file is executable and not a library/object file
        if vim.fn.executable(file) == 1 and
            not file:match("%.o$") and
            not file:match("%.a$") and
            not file:match("%.so$") then
            table.insert(executables, file)
        end
    end

    if #executables == 0 then
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    elseif #executables == 1 then
        return executables[1]
    else
        local selected = nil
        vim.ui.select(executables, {
            prompt = "Select executable:",
            format_item = function(item)
                return vim.fn.fnamemodify(item, ":t")
            end,
        }, function(choice)
            selected = choice
        end)
        return selected
    end
end

dap.configurations.c = {
    {
        name = "Launch (auto-detect build)",
        type = "lldb",
        request = "launch",
        program = find_executable,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " +")
        end,
        runInTerminal = false,
    },
    {
        name = "Launch (custom executable)",
        type = "lldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " +")
        end,
    },
    {
        name = "Attach to process",
        type = "lldb",
        request = "attach",
        pid = require("dap.utils").pick_process,
        args = {},
    },
}

