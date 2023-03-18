local CutMode = {useMaskColor = true}

function CutMode:Process(change, sprite, cel, parameters)
    local intersection = Rectangle(cel.bounds):intersect(change.bounds)
    local image = Image(intersection.width, intersection.height)
    local color = nil

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        if RectangleContains(intersection, pixel.x, pixel.y) then
            color = getPixel(cel.image, pixel.x - cel.position.x,
                             pixel.y - cel.position.y)
            drawPixel(cel.image, pixel.x - cel.position.x,
                      pixel.y - cel.position.y, 0)

            drawPixel(image, pixel.x - intersection.x, pixel.y - intersection.y,
                      color)
        end
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

    sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, image,
                  Point(intersection.x, intersection.y))
end

return CutMode
