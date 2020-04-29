include("CommandButton")

function CreateCommandsDialog(commands)
    local result = Dialog("Commands")

    for i, command in ipairs(commands) do
        addCommandButton(result, command)
        result:newrow()
    end

    return result
end