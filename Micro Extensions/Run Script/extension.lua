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
