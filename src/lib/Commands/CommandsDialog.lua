function CreateCommandsDialog(commands)
    local result = Dialog("Commands")

    for i, command in ipairs(commands) do
        result
            :button{
                text=command,
                onclick=function()
                    app.command[command]()
                    -- result:close()
                end
            }
            :newrow()
    end

    return result
end