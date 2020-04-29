function addCommandButton(dialog, text, command)
    dialog
        :button{
            text=text,
            onclick=function()
                app.command[command and command or text]()
            end
        }
end