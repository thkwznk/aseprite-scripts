local IMPORT_DIALOG_WIDTH = 540

return function(decode, onok)
    local dialog = Dialog("Import")

    dialog --
    :entry{id = "code", label = "Code"} --
    :separator{id = "separator"} --
    :button{
        text = "Import",
        onclick = function()
            local theme = decode(dialog.data.code)

            if not theme then
                dialog:modify{id = "separator", text = "Incorrect code"}
                return
            end

            dialog:close()
            onok(theme)
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
