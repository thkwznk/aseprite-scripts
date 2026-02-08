local function AnyCelsSelected()
    return app.activeSprite ~= nil and #app.range.cels > 0
end

local function MultipleCelsSelected()
    return app.activeSprite ~= nil and #app.range.cels > 1
end

local function SpriteHasSelection()
    return app.activeSprite ~= nil and not app.activeSprite.selection.isEmpty
end

local function AddCelContentToSelection(cel, selection)
    -- Keep references to improve performance
    local add = selection.add
    local cx, cy = cel.position.x, cel.position.y
    local image = cel.image
    local getPixel, width, height = image.getPixel, image.width, image.height

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if getPixel(image, x, y) > 0 then
                add(selection, Rectangle(x + cx, y + cy, 1, 1))
            end
        end
    end
end

local function SelectContent(mode)
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        AddCelContentToSelection(cel, selection)
    end

    if mode == SelectionMode.REPLACE then
        app.activeSprite.selection = selection
        app.tip("Selected Cels Content")
    elseif mode == SelectionMode.ADD then
        app.activeSprite.selection:add(selection)
        app.tip("Added Cels Content to selection")
    elseif mode == SelectionMode.SUBTRACT then
        app.activeSprite.selection:subtract(selection)
        app.tip("Subtracted Cels Content from selection")
    elseif mode == SelectionMode.INTERSECT then
        app.activeSprite.selection:intersect(selection)
        app.tip("Intersected Cels Content with selection")
    end

    app.refresh()
end

local function SelectContentIntersection()
    local selection

    for _, cel in ipairs(app.range.cels) do
        local currentSelection = Selection()
        AddCelContentToSelection(cel, currentSelection)

        if selection == nil then
            selection = currentSelection
        else
            selection:intersect(currentSelection)
        end
    end

    app.activeSprite.selection = selection
    app.tip("Selected an intersection of Cels Content")
    app.refresh()
end

local function SelectContentDifference()
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        AddCelContentToSelection(cel, selection)
    end

    selection:subtract(app.activeSprite.selection)
    app.activeSprite.selection = selection
    app.tip("Selected a difference with Cels Content")
    app.refresh()
end

local function SelectContentComplement()
    local selection = Selection()

    for _, cel in ipairs(app.range.cels) do
        AddCelContentToSelection(cel, selection)
    end

    app.activeSprite.selection:selectAll()
    app.activeSprite.selection:subtract(selection)
    app.tip("Selected an inverse of Cels Content")
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
            onenabled = MultipleCelsSelected,
            onclick = SelectContentIntersection
        }

        plugin:newCommand{
            id = "SelectCelContentReplaceComplement",
            title = "Inverse",
            group = parentGroup,
            onenabled = AnyCelsSelected,
            onclick = SelectContentComplement
        }

        plugin:newCommand{
            id = "SelectCelContentReplaceDifference",
            title = "Difference",
            group = parentGroup,
            onenabled = SpriteHasSelection,
            onclick = SelectContentDifference
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
