local function SelectedAnyCels()
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

function init(plugin)
    plugin:newCommand{
        id = "SelectContent",
        title = "Content",
        group = "select_simple",
        onenabled = SelectedAnyCels,
        onclick = function() SelectContent(SelectionMode.REPLACE) end
    }

    local parentGroup = "cel_popup_properties"

    if app.apiVersion >= 22 then
        plugin:newMenuSeparator{group = "cel_popup_properties"}

        parentGroup = "cel_popup_select_content"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Select Content",
            group = "cel_popup_properties"
        }

        plugin:newCommand{
            id = "SelectContent",
            title = "Replace selection",
            group = parentGroup,
            onenabled = SelectedAnyCels,
            onclick = function() SelectContent(SelectionMode.REPLACE) end
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
        plugin:newCommand{
            id = "SelectContent",
            title = "Select Content",
            group = parentGroup,
            onenabled = SelectedAnyCels,
            onclick = function() SelectContent(SelectionMode.REPLACE) end
        }
    end
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
