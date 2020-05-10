function addCommandButton(dialog, text, command)
    dialog:button{
        id = command,
        text = text,
        onclick = function() app.command[command or text]() end
    }
end
