local MagicPencilDialog = dofile("./MagicPencilDialog.lua")

function init(plugin)
    local isDialogOpen = false

    plugin:newCommand{
        id = "MagicPencil",
        title = "Magic Pencil",
        group = "edit_fill",
        onenabled = function()
            return app.activeSprite ~= nil and not isDialogOpen
        end,
        onclick = function()
            local dialog = MagicPencilDialog {
                onclose = function() isDialogOpen = false end
            }
            dialog:show{wait = false}

            isDialogOpen = true
        end
    }
end

function exit(plugin) end
