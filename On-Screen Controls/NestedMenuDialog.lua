MenuEntryType = dofile("./NestedMenuEntryType.lua")

local ButtonHeight = 21
local SeparatorHeight = 8

local function GetScreenWidth()
    local screenTestDialog = Dialog("...")
    screenTestDialog:show{wait = false}
    screenTestDialog:close()
    local bounds = screenTestDialog.bounds

    return bounds.x * 2 + bounds.width
end

local function NestedMenuDialog(title, data, onclose, isSubmenu)
    local dialog = Dialog {title = title, onclose = onclose}

    local dialogEntryDepth = 0

    dialog --
    :button{id = "0", text = (isSubmenu and "<" or "X")} --
    :separator()

    dialogEntryDepth = dialogEntryDepth + ButtonHeight + SeparatorHeight

    local buttonIds = {}

    local depthBuffer = 0

    for i, entry in ipairs(data) do
        local currentDepth = dialogEntryDepth

        if entry.type == MenuEntryType.Action then
            dialog:button{
                id = tostring(i),
                text = entry.text,
                onclick = entry.onclick
            }

            table.insert(buttonIds, i)

            if depthBuffer == 0 then depthBuffer = ButtonHeight end
        end

        if entry.type == MenuEntryType.NewRow then
            dialog:newrow()

            if depthBuffer > 0 then
                dialogEntryDepth = dialogEntryDepth + depthBuffer
                depthBuffer = 0
            end
        end

        if entry.type == MenuEntryType.Separator then
            dialog:separator{id = tostring(i), text = entry.text}

            dialogEntryDepth = dialogEntryDepth + SeparatorHeight

            if depthBuffer > 0 then
                dialogEntryDepth = dialogEntryDepth + depthBuffer
                depthBuffer = 0
            end
        end

        if entry.type == MenuEntryType.Submenu then
            dialog:button{
                id = tostring(i),
                text = entry.text .. " >",
                onclick = function()
                    for _, buttonId in ipairs(buttonIds) do
                        dialog:modify{id = tostring(buttonId), enabled = false}
                    end

                    local onSubmenuClose = function()
                        for _, buttonId in ipairs(buttonIds) do
                            dialog:modify{
                                id = tostring(buttonId),
                                enabled = true,
                                focus = buttonId == i
                            }
                        end
                    end

                    local submenuDialog =
                        NestedMenuDialog(entry.text, entry.data, onSubmenuClose,
                                         true)

                    local screenWidth = GetScreenWidth()
                    local bounds = submenuDialog.bounds
                    if dialog.bounds.x + dialog.bounds.width +
                        submenuDialog.bounds.width < screenWidth then
                        bounds.x = dialog.bounds.x + dialog.bounds.width
                    else
                        bounds.x = dialog.bounds.x - submenuDialog.bounds.width
                    end
                    bounds.y = dialog.bounds.y + currentDepth
                    submenuDialog.bounds = bounds

                    submenuDialog:show()
                end
            }:newrow()

            table.insert(buttonIds, i)

            dialogEntryDepth = dialogEntryDepth + ButtonHeight
        end
    end

    return dialog
end

return NestedMenuDialog
