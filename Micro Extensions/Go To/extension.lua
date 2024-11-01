local SearchDialog = dofile("./SearchDialog.lua")

function init(plugin)
    local preferences = plugin.preferences
    preferences.searchAll = preferences.searchAll or false
    preferences.autoZoomOnSlice = preferences.autoZoomOnSlice or false

    plugin:newCommand{
        id = "GoTo",
        title = "Go to...",
        group = "sprite_properties",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = SearchDialog {
                title = "Go to",
                searchAll = preferences.searchAll,
                autoZoomOnSlice = preferences.autoZoomOnSlice,
                onclose = function(data)
                    preferences.searchAll = data.searchAll
                    preferences.autoZoomOnSlice = data.autoZoomOnSlice
                end
            }
            dialog:show()
        end
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
