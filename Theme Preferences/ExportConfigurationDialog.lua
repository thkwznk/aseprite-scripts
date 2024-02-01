return function(name, code, onClose)
    local dialog = Dialog {title = "Export " .. name, onclose = onClose}

    dialog --
    :entry{label = "Code", text = code} --
    :separator() --
    :button{text = "Close"} --

    return dialog
end
