local Statistics = dofile("../Statistics.lua")

return function(options)
    Statistics:Init(options.preferences)

    local dialog = Dialog {title = "Add Milestone"}

    dialog:entry{id = "title", label = "Title:"} --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            Statistics:AddMilestone(options.sprite.filename, dialog.data.title)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end
