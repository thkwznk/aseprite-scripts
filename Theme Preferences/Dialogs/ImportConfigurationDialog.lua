local Base64 = dofile("../Base64.lua")

local IMPORT_DIALOG_WIDTH = 540

return function(options)
    local dialog = Dialog("Import")

    dialog --
    :entry{id = "code", label = "Code"} --
    :separator{id = "separator"} --
    :button{
        text = "Import",
        onclick = function()
            local theme = Base64.DecodeSigned(dialog.data.code)

            if not theme then
                dialog:modify{id = "separator", text = "Incorrect code"}
                return
            end

            dialog:close()

            if options.onclick then options.onclick(theme) end
        end
    } --
    :button{text = "Cancel"} --

    -- Open and close to initialize bounds
    dialog:show{wait = false}
    dialog:close()

    local bounds = dialog.bounds
    bounds.x = bounds.x - (IMPORT_DIALOG_WIDTH - bounds.width) / 2
    bounds.width = IMPORT_DIALOG_WIDTH
    dialog.bounds = bounds

    return dialog
end
