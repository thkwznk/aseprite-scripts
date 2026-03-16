local CutMode = {
    useMaskColor = true,
    ignoreEmptyCel = true,
    deleteOnEmptyCel = true
}

function CutMode:Process(change, sprite, cel, parameters)
    local newImage = Image(change.bounds.width, change.bounds.height,
                           cel.sprite.colorMode)

    local cx, cy, image = cel.position.x, cel.position.y, cel.image
    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel
    local ox, oy = change.bounds.x, change.bounds.y

    local x, y, color
    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cx
        y = pixel.y - cy

        color = getPixel(image, x, y)

        drawPixel(image, x, y, 0)
        drawPixel(newImage, pixel.x - ox, pixel.y - oy, color)
    end

    app.activeCel.image = image
    app.activeCel.position = cel.position

    local activeLayerIndex = app.activeLayer.stackIndex
    local activeLayerParent = app.activeLayer.parent

    -- v This causes a site change and that calls the UpdateLast in MagicPencilDialog
    local newLayer = sprite:newLayer()
    newLayer.name = "Lifted Content"
    newLayer.parent = activeLayerParent
    newLayer.stackIndex = activeLayerIndex
    if change.leftPressed then newLayer.stackIndex = newLayer.stackIndex + 1 end

    sprite:newCel(newLayer, app.activeFrame.frameNumber, newImage, Point(ox, oy))

    -- Set the new layer as the active one for the GUI to correctly update
    app.activeLayer = newLayer
end

return CutMode
