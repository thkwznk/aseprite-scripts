local EXPORT_DIALOG_WIDTH = 540

return function(name, code, onclose)
    -- TODO: Simplify this using just the window size
    local isFirstOpen = true

    local dialog = Dialog {
        title = "Export " .. name,
        onclose = function() if not isFirstOpen then onclose() end end
    }

    dialog --
    :entry{label = "Code", text = code} --
    :separator() --
    :button{text = "Close"} --

    -- Open and close to initialize bounds
    dialog:show{wait = false}
    dialog:close()

    isFirstOpen = false

    local bounds = dialog.bounds
    bounds.x = bounds.x - (EXPORT_DIALOG_WIDTH - bounds.width) / 2
    bounds.width = EXPORT_DIALOG_WIDTH
    dialog.bounds = bounds

    return dialog
end
