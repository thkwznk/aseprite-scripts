local function AnyCelsSelected()
    return app.activeSprite ~= nil and #app.range.cels > 0
end

local function SpriteHasSelection() return
    not app.activeSprite.selection.isEmpty end

local function SelectContent(mode)
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        for pixel in cel.image:pixels() do
            if pixel() > 0 then
                local rectangle = Rectangle(pixel.x + cel.position.x,
                                            pixel.y + cel.position.y, 1, 1)

                selection:add(rectangle)
            end
        end
    end

    if mode == SelectionMode.REPLACE then
        app.activeSprite.selection = selection
    elseif mode == SelectionMode.ADD then
        app.activeSprite.selection:add(selection)
    elseif mode == SelectionMode.SUBTRACT then
        app.activeSprite.selection:subtract(selection)
    elseif mode == SelectionMode.INTERSECT then
        app.activeSprite.selection:intersect(selection)
    end

    app.refresh()
end

local function SelectContentIntersection()
    local selection

    for _, cel in ipairs(app.range.cels) do
        local currentSelection = Selection()
        for pixel in cel.image:pixels() do
            if pixel() > 0 then
                local rectangle = Rectangle(pixel.x + cel.position.x,
                                            pixel.y + cel.position.y, 1, 1)

                currentSelection:add(rectangle)
            end
        end

        if selection == nil then
            selection = currentSelection
        else
            selection:intersect(currentSelection)
        end
    end

    app.activeSprite.selection = selection
    app.refresh()
end

local function SelectContentDifference()
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        for pixel in cel.image:pixels() do
            if pixel() > 0 then
                local rectangle = Rectangle(pixel.x + cel.position.x,
                                            pixel.y + cel.position.y, 1, 1)

                selection:add(rectangle)
            end
        end
    end

    selection:subtract(app.activeSprite.selection)
    app.activeSprite.selection = selection
    app.refresh()
end

local function SelectContentComplement()
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        for pixel in cel.image:pixels() do
            if pixel() > 0 then
                local rectangle = Rectangle(pixel.x + cel.position.x,
                                            pixel.y + cel.position.y, 1, 1)

                selection:add(rectangle)
            end
        end
    end

    app.activeSprite.selection:selectAll()
    app.activeSprite.selection:subtract(selection)
    app.refresh()
end

function init(plugin)
    local function AddSelectContentCommand(title, group)
        plugin:newCommand{
            id = "SelectContent",
            title = title,
            group = group,
            onenabled = AnyCelsSelected,
            onclick = function() SelectContent(SelectionMode.REPLACE) end
        }
    end

    AddSelectContentCommand("Content", "select_simple")

    local parentGroup = "cel_popup_properties"

    if app.apiVersion >= 22 then
        plugin:newMenuSeparator{group = "cel_popup_properties"}

        parentGroup = "cel_popup_select_content"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Select Cel(s) Content",
            group = "cel_popup_properties"
        }

        AddSelectContentCommand("Union", parentGroup)

        plugin:newCommand{
            id = "SelectCelContentReplaceIntersect",
            title = "Intersection",
            group = parentGroup,
            onenabled = function() return #app.range.cels > 1 end,
            onclick = function() SelectContentIntersection() end
        }

        plugin:newCommand{
            id = "SelectCelContentReplaceComplement",
            title = "Inverse",
            group = parentGroup,
            onenabled = AnyCelsSelected,
            onclick = function() SelectContentComplement() end
        }

        plugin:newCommand{
            id = "SelectCelContentReplaceDifference",
            title = "Difference",
            group = parentGroup,
            onenabled = SpriteHasSelection,
            onclick = function() SelectContentDifference() end
        }

        plugin:newMenuSeparator{group = parentGroup}

        plugin:newCommand{
            id = "SelectCelContentAdd",
            title = "Add to selection",
            group = parentGroup,
            onenabled = SpriteHasSelection,
            onclick = function() SelectContent(SelectionMode.ADD) end
        }

        plugin:newCommand{
            id = "SelectCelContentSubtract",
            title = "Subtract from selection",
            group = parentGroup,
            onenabled = SpriteHasSelection,
            onclick = function()
                SelectContent(SelectionMode.SUBTRACT)
            end
        }

        plugin:newCommand{
            id = "SelectCelContentIntersect",
            title = "Intersect selection",
            group = parentGroup,
            onenabled = SpriteHasSelection,
            onclick = function()
                SelectContent(SelectionMode.INTERSECT)
            end
        }
    else
        AddSelectContentCommand("Select Cel(s) Content", parentGroup)
    end
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
