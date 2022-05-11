if not app.isUIAvailable then return end

local ScreenWidth<const> = 1920
local ScreenHeight<const> = 1080
local UIScale<const> = 2

local WorkspaceWidth<const> = ScreenWidth / UIScale
local WorkspaceHeight<const> = ScreenHeight / UIScale

local parentDialog = nil
local childDialog = nil

parentDialog = Dialog {
    title = "Parent",
    onclose = function() if childDialog then childDialog:close() end end
}
childDialog = Dialog {title = "Child"}
childDialog:separator{text = "Content placeholder"}

local lastBounds = nil

local function updateChildDialogBounds()
    local bounds = childDialog.bounds

    if lastBounds and
        (bounds.x ~= lastBounds.x or bounds.y ~= lastBounds.y or bounds.width ~=
            lastBounds.width or bounds.height ~= lastBounds.height) then

        -- TODO: There's still an issue where if you edit the slider value holding the right mouse button it will correct the value on the first change but then still jump

        parentDialog --
        :modify{id = "x", value = childDialog.bounds.x} --
        :modify{id = "y", value = childDialog.bounds.y} --
        :modify{id = "width", value = childDialog.bounds.width} --
        :modify{id = "height", value = childDialog.bounds.height}
    end

    bounds.x = parentDialog.data.x
    bounds.y = parentDialog.data.y
    bounds.width = parentDialog.data.width
    bounds.height = parentDialog.data.height

    -- If I don't close it a "phantom" dialog is left, but if I do then the parent dialog is refreshing as well and breaks the `onchange` event making the response not smooth 
    -- dialog:close()

    lastBounds = bounds
    childDialog:show{wait = false, bounds = bounds}

    -- Using this instead of closing the dialog fixes both issues
    app.refresh()
end

parentDialog --
:slider{
    id = "x",
    label = "X",
    min = 1,
    max = WorkspaceWidth,
    value = WorkspaceWidth / 2,
    onchange = updateChildDialogBounds
} --
:slider{
    id = "y",
    label = "Y",
    min = 1,
    max = WorkspaceHeight,
    value = WorkspaceHeight / 2,
    onchange = updateChildDialogBounds
} --
:slider{
    id = "width",
    label = "Width",
    min = 1,
    max = WorkspaceWidth,
    value = WorkspaceWidth / 4,
    onchange = updateChildDialogBounds
} --
:slider{
    id = "height",
    label = "Height",
    min = 1,
    max = WorkspaceHeight,
    value = WorkspaceHeight / 4,
    onchange = updateChildDialogBounds
} --
:button{text = "Cancel"}

parentDialog:show{wait = false}

-- Show the child dialog
updateChildDialogBounds()

