local CutMode = {useMaskColor = true, deleteOnEmptyCel = true}

function CutMode:Process(change, sprite, cel, parameters)
    local newImage = Image(change.bounds.width, change.bounds.height)

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel
    local ox, oy = change.bounds.x, change.bounds.y

    local x, y, color = nil, nil, nil

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y

        color = getPixel(cel.image, x, y)

        drawPixel(cel.image, x, y, 0)
        drawPixel(newImage, pixel.x - ox, pixel.y - oy, color)
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position

    local activeLayerIndex = app.activeLayer.stackIndex
    local activeLayerParent = app.activeLayer.parent

    local newLayer = sprite:newLayer()
    newLayer.parent = activeLayerParent

    if change.leftPressed then
        newLayer.stackIndex = activeLayerIndex + 1
    else
        newLayer.stackIndex = activeLayerIndex
    end

    newLayer.name = "Lifted Content"
    sprite:newCel(newLayer, app.activeFrame.frameNumber, newImage, Point(ox, oy))
end

return CutMode
