if not app.isUIAvailable then return end

local MenuEntryType = {
    Action = "Action",
    Separator = "Separator",
    Submenu = "Submenu"
}

local ButtonHeight<const> = 21
local SeparatorHeight<const> = 8

local function NestedMenuDialog(title, data, onclose)
    local dialog = Dialog {title = title, onclose = onclose}

    local dialogEntryDepth = 0

    dialog --
    :button{id = "0", text = (onclose ~= nil and "<" or "X")} --
    :separator()

    dialogEntryDepth = dialogEntryDepth + ButtonHeight + SeparatorHeight

    for i, entry in ipairs(data) do
        local currentDepth = dialogEntryDepth

        if entry.type == MenuEntryType.Action then
            dialog:button{
                id = tostring(i),
                text = entry.text,
                onclick = entry.onclick
            }:newrow()

            dialogEntryDepth = dialogEntryDepth + ButtonHeight
        end

        if entry.type == MenuEntryType.Separator then
            dialog:separator{id = tostring(i), text = entry.text}

            dialogEntryDepth = dialogEntryDepth + SeparatorHeight
        end

        if entry.type == MenuEntryType.Submenu then
            dialog:button{
                id = tostring(i),
                text = entry.text .. " >",
                onclick = function()
                    for j = 0, #data do
                        dialog:modify{id = tostring(j), enabled = false}
                    end

                    local onSubmenuClose = function()
                        for j = 0, #data do
                            dialog:modify{
                                id = tostring(j),
                                enabled = true,
                                focus = j == i
                            }
                        end
                    end

                    local submenuDialog =
                        NestedMenuDialog(entry.text, entry.data, onSubmenuClose)

                    local bounds = submenuDialog.bounds
                    bounds.x = dialog.bounds.x + dialog.bounds.width
                    bounds.y = dialog.bounds.y + currentDepth
                    submenuDialog.bounds = bounds

                    submenuDialog:show()

                end
            }:newrow()

            dialogEntryDepth = dialogEntryDepth + ButtonHeight
        end
    end

    return dialog
end

local data = {
    {
        text = "Menu Action #1",
        type = MenuEntryType.Action,
        onclick = function() end
    }, {
        text = "Menu Action #2",
        type = MenuEntryType.Action,
        onclick = function() end
    }, {type = MenuEntryType.Separator}, {
        text = "Submenu #1",
        type = MenuEntryType.Submenu,
        data = {
            {
                text = "Menu Action #3",
                type = MenuEntryType.Action,
                onclick = function() end
            }, {type = MenuEntryType.Separator}, {
                text = "Submenu #2",
                type = MenuEntryType.Submenu,
                data = {
                    {
                        text = "Menu Action #4",
                        type = MenuEntryType.Action,
                        onclick = function() end
                    }, {
                        text = "Menu Action #5",
                        type = MenuEntryType.Action,
                        onclick = function() end
                    }
                }
            }
        }
    }
}

local menuDialog = NestedMenuDialog("Menu", data)
menuDialog:show{wait = true}
