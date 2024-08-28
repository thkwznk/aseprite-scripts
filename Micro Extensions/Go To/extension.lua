local SearchDialog = dofile("./SearchDialog.lua")

function init(plugin)
    plugin:newCommand{
        id = "GoTo",
        title = "Go to...",
        group = "sprite_properties",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = SearchDialog {
                title = "Go to",
                sources = {layers = true, tags = true, frames = true}
            }
            dialog:show()
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
