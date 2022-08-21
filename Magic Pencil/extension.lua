local MagicPencil = dofile("./magicPencil.lua")

local isMagicPencilOpen = false

function init(plugin)
    plugin:newCommand{
        id = "MagicPencil",
        title = "Magic Pencil",
        group = "edit_fill",
        onenabled = function()
            return app.activeSprite ~= nil and not isMagicPencilOpen
        end,
        onclick = function()
            MagicPencil:Execute{
                onclose = function() isMagicPencilOpen = false end
            }
            isMagicPencilOpen = true
        end
    }
end

function exit(plugin) end
