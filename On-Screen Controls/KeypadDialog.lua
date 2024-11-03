return function(options)
    local dialog = Dialog {title = "Keypad"}

    dialog --
    :button{text = "V", onclick = function() app.command.LayerVisibility() end} --
    :button{text = "^", onclick = function() app.command.GoToNextLayer() end} --
    :button{text = "L", onclick = function() app.command.LayerLock() end} --
    :newrow() --
    :button{
        text = "<",
        onclick = function() app.command.GotoPreviousFrame() end
    } --
    :button{
        text = "v",
        onclick = function() app.command.GoToPreviousLayer() end
    } --
    :button{text = ">", onclick = function() app.command.GoToNextFrame() end} --

    return dialog
end

-- TODO: Use a canvas dialog with custom buttons and actual arrow icons
-- TODO: Update the Visibility and Lock buttons (icons?) whenever site changes
