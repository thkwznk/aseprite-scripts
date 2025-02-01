-- ActiveElementsCache = dofile("./shared/ActiveElementsCache.lua")
ImportAnimationDialog = dofile("./ImportAnimationDialog.lua")
LoopDialog = dofile("./LoopDialog.lua")

function init(plugin)
    plugin:newCommand{
        id = "import-animation",
        title = "Import Animation",
        group = "edit_insert",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            -- TODO: Verify if this is needed
            -- ActiveElementsCache:Clear()

            -- TODO: Consider splitting the process into selection of a source in one dialog
            -- And after that the placement of it in the sprite

            local dialog
            dialog = ImportAnimationDialog {
                title = "Import Animation",
                onclose = function()
                    -- TODO: Make sure the position is saved
                    plugin.preferences.bounds = dialog.bounds or
                                                    plugin.preferences.bounds
                end
            }
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "loop-animation",
        title = "Loop Animation",
        group = "edit_insert",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            local dialog = LoopDialog {title = "Loop Animation"}
            dialog:show()
        end
    }
end

function exit(plugin) end
