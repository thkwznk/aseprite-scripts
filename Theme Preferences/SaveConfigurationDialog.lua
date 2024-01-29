return function(theme, isImport, onConfirmation)
    local title = "Save Configuration"
    local okButtonText = "&OK"

    if isImport then
        title = "Import Configuration"
        okButtonText = "Save"
    end

    local dialog = Dialog(title)

    dialog --
    :entry{
        id = "name",
        label = "Name",
        text = theme.name,
        onchange = function()
            dialog:modify{id = "ok", enabled = #dialog.data.name > 0} --
        end
    } --
    :separator() --
    :button{
        id = "ok",
        text = okButtonText,
        enabled = #theme.name > 0,
        onclick = function() onConfirmation(dialog.data.name) end
    } --

    if isImport then
        dialog:button{
            text = "Save and Apply",
            enabled = #theme.name > 0,
            onclick = function()
                onConfirmation(dialog.data.name, true)
            end
        }
    end

    dialog:button{text = "Cancel"}

    return dialog
end
