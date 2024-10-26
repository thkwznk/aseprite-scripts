local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local searchCommands, searchScripts = true, true
    local lastScriptPath, lastCommand

    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run...",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {
                title = "Run",
                searchCommands = searchCommands,
                searchScripts = searchScripts,
                onrun = function(option, data)
                    searchCommands = data.searchCommands
                    searchScripts = data.searchScripts

                    if option.path then
                        lastScriptPath = option.path
                        lastCommand = nil
                    end

                    if option.command then
                        lastScriptPath = nil
                        lastCommand = option.command
                    end
                end,
                onclose = function(data)
                    searchCommands = data.searchCommands
                    searchScripts = data.searchScripts
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
