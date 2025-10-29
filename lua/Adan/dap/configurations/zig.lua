local dap = require("dap")

dap.configurations.zig = {
    {
        name = "Launch (zig build)",
        type = "lldb",
        request = "launch",
        program = function()
            vim.fn.system("zig build")

            local output_dir = vim.fn.getcwd() .. "/zig-out/bin/"
            local executables = vim.fn.glob(output_dir .. "*", false, true)

            if #executables == 0 then
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            elseif #executables == 1 then
                return executables[1]
            else
                vim.ui.select(executables, {
                    prompt = "Select executable:",
                    format_item = function(item)
                        return vim.fn.fnamemodify(item, ":t")
                    end,
                }, function(choice)
                    return choice
                end)
            end
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " ")
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
            return vim.split(args_string, " ")
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
