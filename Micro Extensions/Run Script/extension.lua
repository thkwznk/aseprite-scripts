local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local lastScriptPath, lastCommand

    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run...",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {
                title = "Run",
                onrun = function(option)
                    if option.path then
                        lastScriptPath = option.path
                        lastCommand = nil
                    end

                    if option.command then
                        lastScriptPath = nil
                        lastCommand = option.command
                    end
                end
            }
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "RepeatScriptAdvanced",
        title = "Run Last Script",
        onclick = function()
            if lastScriptPath and app.fs.isFile(lastScriptPath) then
                dofile(lastScriptPath)
            end

            if lastCommand then app.command[lastCommand]() end
        end
    }
end

function exit(plugin) end
