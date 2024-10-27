local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local searchCommands, searchScripts = true, true
    local lastRunOption

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
                    lastRunOption = option
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
            if lastRunOption.path and app.fs.isFile(lastRunOption.path) then
                dofile(lastRunOption.path)
            end

            if lastRunOption.command then
                app.command[lastRunOption.command](lastRunOption.parameters)
            end
        end
    }
end

function exit(plugin) end
