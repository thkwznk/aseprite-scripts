local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local preferences = plugin.preferences
    preferences.searchCommands = preferences.searchCommands or true
    preferences.searchScripts = preferences.searchScripts or true
    preferences.showPaths = preferences.showPaths or false

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
                showPaths = preferences.showPaths,
                onrun = function(option, data)
                    preferences.searchCommands = data.searchCommands
                    preferences.searchScripts = data.searchScripts
                    preferences.showPaths = data.showPaths

                    lastRunOption = option
                end,
                onclose = function(data)
                    preferences.searchCommands = data.searchCommands
                    preferences.searchScripts = data.searchScripts
                    preferences.showPaths = data.showPaths
                end
            }
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "RepeatScriptAdvanced",
        title = "Run Last Script",
        onenabled = function() return lastRunOption ~= nil end,
        onclick = function()
            if lastRunOption.filepath and app.fs.isFile(lastRunOption.filepath) then
                dofile(lastRunOption.filepath)
            end

            if lastRunOption.command and
                (lastRunOption.onenable == nil or lastRunOption.onenable()) then
                app.command[lastRunOption.command](lastRunOption.parameters)
            end
        end
    }
end

function exit(plugin) end
