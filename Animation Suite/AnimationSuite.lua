ActiveElementsCache = dofile("./shared/ActiveElementsCache.lua")
ImportAnimationDialog = dofile("./import-animation/ImportAnimationDialog.lua")
LoopDialog = dofile("./loop/LoopDialog.lua")

function init(plugin)
    plugin:newCommand{
        id = "import-animation",
        title = "Import Animation",
        group = "edit_insert",
        onenabled = function()
            return app.activeSprite ~= nil and #app.sprites > 1
        end,
        onclick = function()
            -- Check is UI available
            if not app.isUIAvailable then return end

            ActiveElementsCache:Clear()

            ImportAnimationDialog:Create{
                title = "Import Animation",
                targetSprite = app.activeSprite,
                targetLayer = app.activeLayer,
                targetFrameNumber = app.activeFrame.frameNumber
            }
            ImportAnimationDialog:Show()
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

            LoopDialog:Create("Loop Animation")
            LoopDialog:Show()
        end
    }
end

function exit(plugin) end
