function CanSelectContent()
    return app.activeSprite ~= nil and #app.range.cels > 0
end

function SelectContent()
    local mode = app.preferences.selection.mode
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
        onenabled = CanSelectContent,
        onclick = SelectContent
    }
end

function exit(plugin)
    -- You don't really need to do anything specific here
end

-- TODO: For v2.0.0 add support for respecting the current selection mode (app.preferences.selection.mode) 
