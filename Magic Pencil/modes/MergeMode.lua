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
        elseif not l.isReference and l.isVisible then
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

    local chx, chy = change.bounds.x, change.bounds.y

    for i = #layerCels, 1, -1 do
        local layerCel = layerCels[i]
        local lx, ly = layerCel.position.x, layerCel.position.y
        local image, bounds = layerCel.image, layerCel.bounds

        local px, py
        for _, pixel in ipairs(change.pixels) do
            px, py = pixel.x, pixel.y

            if RectangleContains(bounds, px, py) then
                x = px - lx
                y = py - ly

                color = getPixel(image, x, y)

                if color > 0 then
                    drawPixel(newImage, px - chx, py - chy, color)

                    -- I'm not sure if the Merge Mode should clear pixels
                    -- drawPixel(image, x, y, 0)

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
