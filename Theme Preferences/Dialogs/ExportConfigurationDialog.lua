local EXPORT_DIALOG_WIDTH = 540

return function(options)
    local isFirstOpen = true

    local dialog = Dialog {
        title = "Export " .. options.name,
        onclose = function()
            if not isFirstOpen then
                if options.onclose then options.onclose() end
            end
        end
    }

    dialog --
    :entry{label = "Code", text = options.code} --
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
