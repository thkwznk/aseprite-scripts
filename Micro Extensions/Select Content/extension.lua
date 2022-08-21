function CanSelectContent()
    return app.activeSprite ~= nil and #app.range.cels > 0
end

function SelectContent()
    local newSelection = Selection()

    for _, cel in ipairs(app.range.cels) do
        for pixel in cel.image:pixels() do
            if pixel() > 0 then
                newSelection:add(Rectangle(pixel.x + cel.position.x,
                                           pixel.y + cel.position.y, 1, 1))
            end
        end
    end

    app.activeSprite.selection = newSelection
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
