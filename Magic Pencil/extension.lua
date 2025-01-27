local MagicPencilDialog = dofile("./MagicPencilDialog.lua")

function init(plugin)
    local isDialogOpen = false

    if plugin.preferences.isMinimized == nil then
        plugin.preferences.isMinimized = false
    end

    plugin:newCommand{
        id = "MagicPencil",
        title = "Magic Pencil",
        group = "edit_fill",
        onenabled = function()
            return app.activeSprite ~= nil and not isDialogOpen
        end,
        onclick = function()
            local dialog = MagicPencilDialog {
                isminimized = plugin.preferences.isMinimized,
                onclose = function(isMinimized)
                    isDialogOpen = false
                    plugin.preferences.isMinimized = isMinimized
                end
            }
            dialog:show{wait = false}

            isDialogOpen = true
        end
    }
end

function exit(plugin) end
