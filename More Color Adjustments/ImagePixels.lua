local GetLayersArray
GetLayersArray = function(layers)
    local result = {}

    for _, layer in ipairs(layers) do
        if layer.isGroup then
            local nestedLayers = GetLayersArray(layer.layers)

            for _, nestedLayer in ipairs(nestedLayers) do
                table.insert(result, nestedLayer)
            end
        else
            table.insert(result, layer)
        end
    end

    return result
end

local GetJoinedImageBounds = function(layers, frame)
    local joinedBounds = nil

    for _, layer in ipairs(layers) do
        local cel = layer:cel(frame)

        if cel then
            local imageBounds = Rectangle(cel.image.bounds)
            imageBounds.x = cel.position.x
            imageBounds.y = cel.position.y

            if joinedBounds then
                joinedBounds = joinedBounds:union(imageBounds)
            else
                joinedBounds = imageBounds
            end
        end
    end

    return joinedBounds
end

local GetPixels = function(sprite)
    local layers = GetLayersArray(sprite.layers)
    local frame = app.activeFrame

    local joinedImageBounds = GetJoinedImageBounds(layers, frame)
    local joinedImage = Image(joinedImageBounds.width, joinedImageBounds.height,
                              sprite.colorMode)

    local pixels = {}

    for x = 1, joinedImage.width do
        pixels[x] = {}
        for y = 1, joinedImage.height do pixels[x][y] = false end
    end

    for _, layer in ipairs(layers) do
        local cel = layer:cel(frame)

        if cel then
            local image = cel.image
            local getPixel = image.getPixel

            local p = Point(cel.position.x - joinedImageBounds.x,
                            cel.position.y - joinedImageBounds.y)

            joinedImage:drawImage(image, p)

            for x = 0, image.width - 1 do
                for y = 0, image.height - 1 do
                    local pixelValue = getPixel(image, x, y)

                    if pixelValue > 0 then
                        local pixelColor = Color(pixelValue)

                        local inRange, inSelection = false, true

                        for _, layerInRange in ipairs(app.range.layers) do
                            if layer == layerInRange then
                                inRange = true
                                break
                            end
                        end

                        if not sprite.selection.isEmpty then
                            inSelection =
                                sprite.selection:contains(cel.position.x + x,
                                                          cel.position.y + y)
                        end

                        pixels[p.x + x + 1][p.y + y + 1] = {
                            x = p.x + x,
                            y = p.y + y,
                            value = pixelValue,
                            color = pixelColor,
                            isEditable = inRange and inSelection,
                            distance = 0
                        }
                    end
                end
            end
        end
    end

    local flatPixels = {}

    for x = 1, joinedImage.width do
        for y = 1, joinedImage.height do
            if pixels[x][y] ~= false then
                table.insert(flatPixels, pixels[x][y])
            end
        end
    end

    return joinedImage, flatPixels
end

return GetPixels
