local MergeMode = {
    useMaskColor = true,
    canExtend = true,
    deleteOnEmptyCel = true
}

local function GetLayersRecursively(layers, operation)
    for _, l in ipairs(layers) do
        if l.isGroup then
            GetLayersRecursively(l.layers)
        elseif not l.isReference then
            operation(l)
        end
    end
end

local function GetLayersUnderneath(layer, operation)
    local parent = layer.parent

    if not layer.isGroup and not layer.isReference then operation(layer) end

    for stackIndex = layer.stackIndex - 1, 1, -1 do
        local l = parent.layers[stackIndex]

        if l.isGroup then
            GetLayersRecursively(l.layers, operation)
        elseif not l.isReference then
            operation(l)
        end
    end

    if parent ~= layer.sprite then GetLayersUnderneath(parent, operation) end
end

local function RectangleContains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width - 1 and --
    y >= rect.y and y <= rect.y + rect.height - 1
end

local function NewCelShrunk(sprite, layer, frame, image, position)
    local shrunkBounds = image:shrinkBounds()
    local shrunkImage = Image(image, shrunkBounds)
    local newPosition = Point(position.x + shrunkBounds.x,
                              position.y + shrunkBounds.y)

    sprite:newCel(layer, frame, shrunkImage, newPosition)
end

function MergeMode:Process(change, sprite, cel, parameters)
    local newImage = Image(change.bounds.width, change.bounds.height,
                           sprite.colorMode)

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel
    local ox, oy = change.bounds.x, change.bounds.y
    local x, y, color = nil, nil, nil

    -- Revert the active cel
    app.activeCel.image = cel.image
    app.activeCel.position = cel.position

    local frameNumber = app.activeFrame.frameNumber
    local layerCels = {}
    GetLayersUnderneath(app.activeLayer, function(layer)
        local layerCel = layer:cel(frameNumber)
        if layerCel ~= nil then
            table.insert(layerCels, {
                position = layerCel.position,
                bounds = layerCel.bounds,
                image = Image(layerCel.image),
                layer = layerCel.layer,
                frame = layerCel.frame
            })
        end
    end)

    for _, pixel in ipairs(change.pixels) do
        for i = #layerCels, 1, -1 do
            local layerCel = layerCels[i]
            if RectangleContains(layerCel.bounds, pixel.x, pixel.y) then
                x = pixel.x - layerCel.position.x
                y = pixel.y - layerCel.position.y

                color = getPixel(layerCel.image, x, y)

                if color > 0 then
                    drawPixel(newImage, pixel.x - change.bounds.x,
                              pixel.y - change.bounds.y, color)
                    drawPixel(layerCel.image, x, y, 0)

                    layerCel.updated = true
                end
            end
        end
    end

    for _, layerCel in ipairs(layerCels) do
        if layerCel.updated then
            NewCelShrunk(sprite, layerCel.layer, layerCel.frame, layerCel.image,
                         layerCel.position)
        end
    end

    local activeLayerIndex = app.activeLayer.stackIndex
    local activeLayerParent = app.activeLayer.parent

    local newLayer = sprite:newLayer()
    newLayer.name = "Merged Content"
    newLayer.parent = activeLayerParent
    newLayer.stackIndex = activeLayerIndex
    if change.leftPressed then newLayer.stackIndex = newLayer.stackIndex + 1 end

    NewCelShrunk(sprite, app.activeLayer, app.activeFrame.frameNumber, newImage,
                 Point(ox, oy))

    -- Set the new layer as the active one for the GUI to correctly update
    app.activeLayer = newLayer
end

return MergeMode
