local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local preferences = plugin.preferences
    preferences.searchCommands = preferences.searchCommands or true
    preferences.searchScripts = preferences.searchScripts or true
    preferences.showCommandPaths = preferences.showCommandPaths or false

    local lastRunOption

    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run...",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {
                title = "Run",
                searchCommands = preferences.searchCommands,
                searchScripts = preferences.searchScripts,
                showCommandPaths = preferences.showCommandPaths,
                onrun = function(option, data)
                    preferences.searchCommands = data.searchCommands
                    preferences.searchScripts = data.searchScripts
                    preferences.showCommandPaths = data.showCommandPaths

                    lastRunOption = option
                end,
                onclose = function(data)
                    preferences.searchCommands = data.searchCommands
                    preferences.searchScripts = data.searchScripts
                    preferences.showCommandPaths = data.showCommandPaths
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
