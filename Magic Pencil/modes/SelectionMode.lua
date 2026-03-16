local SelectionMode = {
    canExtend = true,
    useMaskColor = true,
    deleteOnEmptyCel = true
}

function SelectionMode:Process(change, sprite, cel, parameters)
    local newSelection = Selection()
    local add = newSelection.add

    for _, pixel in ipairs(change.pixels) do
        add(newSelection, Rectangle(pixel.x, pixel.y, 1, 1))
    end

    if change.leftPressed then
        if sprite.selection.isEmpty then
            sprite.selection:add(newSelection)
        else
            sprite.selection:intersect(newSelection)
        end
    else
        sprite.selection:subtract(newSelection)
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position
end

return SelectionMode
