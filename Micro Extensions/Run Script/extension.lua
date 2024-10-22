local RunScriptDialog = dofile("./RunScriptDialog.lua")

function init(plugin)
    local lastScriptPath

    plugin:newCommand{
        id = "RunScriptAdvanced", -- RunScript is already a native command
        title = "Run Script",
        group = "file_scripts",
        onclick = function()
            local dialog = RunScriptDialog {
                title = "Run Script",
                onrun = function(filePath)
                    lastScriptPath = filePath
                end
            }
            dialog:show()

            -- TODO: Add an option to "Import Script" that copies a script from a given location to the APP_DATA directory of Aseprite
        end
    }

    plugin:newCommand{
        id = "RepeatScriptAdvanced",
        title = "Run Last Script",
        onclick = function()
            if app.fs.isFile(lastScriptPath) then
                dofile(lastScriptPath)
            end
        end
    }
end

function exit(plugin) end
