local SearchDialog = dofile("./SearchDialog.lua")

function init(plugin)
    local searchAll = false
    local autoZoomOnSlice = false

    plugin:newCommand{
        id = "GoTo",
        title = "Go to...",
        group = "sprite_properties",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = SearchDialog {
                title = "Go to",
                searchAll = searchAll,
                autoZoomOnSlice = autoZoomOnSlice,
                onclose = function(data)
                    searchAll = data.searchAll
                    autoZoomOnSlice = data.autoZoomOnSlice
                end
            }
            dialog:show()
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
