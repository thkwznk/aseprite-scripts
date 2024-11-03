local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local preferences = plugin.preferences

    local function CopyPrefernces(data)
        -- "data" can be either plugin.preferences or dialog.data
        preferences.searchCommands = data.searchCommands == nil and true or
                                         data.searchCommands
        preferences.searchScripts = data.searchScripts == nil and true or
                                        data.searchScripts
        preferences.showPaths = data.showPaths or false
        preferences.showDisabled = data.showDisabled == nil and true or
                                       data.showDisabled
    end

    CopyPrefernces(preferences)

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
                showDisabled = preferences.showDisabled,
                onrun = function(option, data)
                    CopyPrefernces(data)
                    lastRunOption = option
                end,
                onclose = function(data) CopyPrefernces(data) end
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
