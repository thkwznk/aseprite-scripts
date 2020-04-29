include("Commands")
include("CommandsDialog")

local commandPrefix = ""

local keyboardDialog = nil

local commandsDialog = nil

function RefreshDialogs()
    if commandsDialog then commandsDialog:close() end

    if commandPrefix:len() > 0 then
        local availableCommands = GetCommands(commandPrefix)

        if #availableCommands > 0 then
            commandsDialog = CreateCommandsDialog(availableCommands)
            commandsDialog:show{ wait=false }
            commandsDialog.bounds = Rectangle(keyboardDialog.bounds.x + keyboardDialog.bounds.width, commandsDialog.bounds.y, commandsDialog.bounds.width, commandsDialog.bounds.height)
        end
    end
    
    keyboardDialog:close()
    keyboardDialog = CreateKeyboardDialog(commandPrefix)
    keyboardDialog:show{wait=false}
end

function AddLetter(letter)
    commandPrefix = commandPrefix .. letter

    RefreshDialogs()
end

function AddLetterButton(d, letter)
    d:button{
            text=letter,
            selected=false,
            onclick=function()
                AddLetter(letter)
            end
        }
end

function CreateKeyboardDialog(prefix)
    local result = Dialog("Keyboard")
    result
        :separator{
            text=prefix
        }
    AddLetterButton(result, "Q")
    AddLetterButton(result, "W")
    AddLetterButton(result, "E")
    AddLetterButton(result, "R")
    AddLetterButton(result, "T")
    AddLetterButton(result, "Y")
    AddLetterButton(result, "U")
    AddLetterButton(result, "I")
    AddLetterButton(result, "O")
    AddLetterButton(result, "P")
    result:newrow()
    AddLetterButton(result, "A")
    AddLetterButton(result, "S")
    AddLetterButton(result, "D")
    AddLetterButton(result, "F")
    AddLetterButton(result, "G")
    AddLetterButton(result, "H")
    AddLetterButton(result, "J")
    AddLetterButton(result, "K")
    AddLetterButton(result, "L")
    result
        :button{
            text="<",
            onclick=function()
                commandPrefix = commandPrefix:removeLast()
                RefreshDialogs()
            end
        }
    result:newrow()
    AddLetterButton(result, "")
    AddLetterButton(result, "Z")
    AddLetterButton(result, "X")
    AddLetterButton(result, "C")
    AddLetterButton(result, "V")
    AddLetterButton(result, "B")
    AddLetterButton(result, "N")
    AddLetterButton(result, "M")
    AddLetterButton(result, "")
    AddLetterButton(result, "")
        
    return result
end
