KeyboardDialog = dofile("./KeyboardDialog.lua")
MenuEntryType = dofile("./NestedMenuEntryType.lua")
NestedMenuDialog = dofile("./NestedMenuDialog.lua")
local KeypadDialog = dofile("./KeypadDialog.lua")

local gridSubmenu = {
    {
        text = "Toggle",
        type = MenuEntryType.Action,
        onclick = function() app.command.ShowGrid() end
    }, {
        text = "Snap To",
        type = MenuEntryType.Action,
        onclick = function() app.command.SnapToGrid() end
    }, {type = MenuEntryType.NewRow}, {
        text = "Settings",
        type = MenuEntryType.Action,
        onclick = function() app.command.GridSettings() end
    }
}

local frameSubmenu = {
    {
        text = "|<",
        type = MenuEntryType.Action,
        onclick = function() app.command.GotoFirstFrame() end
    }, {
        text = "<",
        type = MenuEntryType.Action,
        onclick = function() app.command.GotoPreviousFrame() end
    }, {
        text = ">",
        type = MenuEntryType.Action,
        onclick = function() app.command.GoToNextFrame() end
    }, {
        text = ">|",
        type = MenuEntryType.Action,
        onclick = function() app.command.GoToLastFrame() end
    }, {type = MenuEntryType.NewRow}, {
        text = "+",
        type = MenuEntryType.Action,
        onclick = function() app.command.NewFrame() end
    }, {
        text = "-",
        type = MenuEntryType.Action,
        onclick = function() app.command.RemoveFrame() end
    }
}

local controlsDialogConfig = {
    {
        text = "Undo",
        type = MenuEntryType.Action,
        onclick = function() app.command.Undo() end
    }, {
        text = "Redo",
        type = MenuEntryType.Action,
        onclick = function() app.command.Redo() end
    }, {type = MenuEntryType.NewRow}, {
        text = "Copy",
        type = MenuEntryType.Action,
        onclick = function() app.command.Copy() end
    }, {
        text = "Paste",
        type = MenuEntryType.Action,
        onclick = function() app.command.Paste() end
    }, {type = MenuEntryType.NewRow}, {
        text = "Cut",
        type = MenuEntryType.Action,
        onclick = function() app.command.Cut() end
    }, {
        text = "Clear",
        type = MenuEntryType.Action,
        onclick = function() app.command.Clear() end
    }, {type = MenuEntryType.NewRow}, {
        text = "Cancel",
        type = MenuEntryType.Action,
        onclick = function() app.command.Cancel {type = "all"} end
    }, {type = MenuEntryType.Separator}, {
        text = "Select All",
        type = MenuEntryType.Action,
        onclick = function()
            app.activeSprite.selection:selectAll()
            app.refresh()
        end
    }, {type = MenuEntryType.Separator},
    {text = "Grid", type = MenuEntryType.Submenu, data = gridSubmenu},
    {type = MenuEntryType.Separator},
    {text = "Frame", type = MenuEntryType.Submenu, data = frameSubmenu},
    {type = MenuEntryType.Separator}, {
        text = "Layer",
        type = MenuEntryType.Submenu,
        data = {
            {
                text = "New",
                type = MenuEntryType.Action,
                onclick = function() app.command.NewLayer() end
            }
        }
    }, {type = MenuEntryType.Separator}, {
        text = "Save",
        type = MenuEntryType.Action,
        onclick = function() app.command.SaveFile() end
    }, {type = MenuEntryType.Separator}, {
        text = "Command",
        type = MenuEntryType.Action,
        onclick = function()
            KeyboardDialog:Create()
            KeyboardDialog:Show()
        end
    }, {type = MenuEntryType.Separator}, {
        text = "Keypad",
        type = MenuEntryType.Action,
        onclick = function()
            local dialog = KeypadDialog {title = "Keypad"}
            dialog:show{wait = false}
        end
    }
}

function ControlsDialog(parameters)
    local onclose = function()
        KeyboardDialog:Close()

        parameters.onclose()
    end

    local controlsDialog = NestedMenuDialog(parameters.title,
                                            controlsDialogConfig, onclose)

    if parameters.preferences.x and parameters.preferences.y then
        local bounds = controlsDialog.bounds

        bounds.x = parameters.preferences.x
        bounds.y = parameters.preferences.y

        controlsDialog.bounds = bounds
    end

    return controlsDialog
end

return ControlsDialog
