local DropShadow = {}

--- Generates a drop shadow for the active sprite.
function DropShadow:Generate(parameters)
    local sprite = app.activeSprite

    -- Split all selected cels by layer - into units
    local units = {}

    for _, cel in ipairs(app.range.cels) do
        local unit = nil

        for _, existingUnit in ipairs(units) do
            if cel.layer == existingUnit.layer then
                unit = existingUnit
                break
            end
        end

        if unit == nil then
            unit = {layer = cel.layer, cels = {}}
            table.insert(units, unit)
        end

        table.insert(unit.cels, cel)
    end

    -- Generate a drop shadow layer for each layer that has selected cels
    for _, unit in ipairs(units) do
        local layer = self:_CreateDropShadowLayer(sprite, unit.layer)

        -- Populate the drop shadow layer
        for _, cel in ipairs(unit.cels) do
            local shadowCel = self:_GenerateShadowCel(cel, parameters)

            if shadowCel then
                sprite:newCel(layer, shadowCel.frameNumber, shadowCel.image,
                              shadowCel.position)
            end
        end
    end
end

function DropShadow:_CreateDropShadowLayer(sprite, layer)
    local dropShadowLayer = sprite:newLayer()
    dropShadowLayer.name = "Drop Shadow (" .. layer.name .. ")"
    dropShadowLayer.color = Color {r = 128, g = 128, b = 128, a = 255}
    dropShadowLayer.stackIndex = layer.stackIndex

    return dropShadowLayer
end

function DropShadow:_GenerateShadowCel(cel, parameters)
    local sprite = cel.sprite
    local selection = sprite.selection
    local color = parameters.color
    local xOffset = parameters.xOffset
    local yOffset = parameters.yOffset

    local newImage, newPosition

    local shiftedSelection = nil

    if not selection.isEmpty then
        shiftedSelection = Rectangle(selection.bounds.x - xOffset,
                                     selection.bounds.y - yOffset,
                                     selection.bounds.width,
                                     selection.bounds.height)
    end

    if selection.isEmpty then
        newImage = Image(cel.image.spec)

        for pixel in cel.image:pixels() do
            local pixelValue = pixel()

            if pixelValue > 0 then
                local pixelColor = Color(pixelValue)
                local newColor = Color(color)
                newColor.alpha = pixelColor.alpha

                newImage:drawPixel(pixel.x, pixel.y, newColor)
            end
        end

        newPosition = Point(cel.position.x + xOffset, cel.position.y + yOffset)
    elseif cel.bounds:intersects(shiftedSelection) then
        newImage = Image(shiftedSelection.width, shiftedSelection.height,
                         sprite.colorMode)

        local rectangle = Rectangle(shiftedSelection.x - cel.position.x,
                                    shiftedSelection.y - cel.position.y,
                                    shiftedSelection.width,
                                    shiftedSelection.height)

        for pixel in cel.image:pixels(rectangle) do
            local pixelColor = Color(pixel())
            local newColor = Color(color)
            newColor.alpha = pixelColor.alpha

            newImage:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                               newColor.rgbaPixel)
        end

        newPosition = Point(shiftedSelection.x + xOffset,
                            shiftedSelection.y + yOffset)
    else
        return nil
    end

    return {
        frameNumber = cel.frameNumber,
        image = newImage,
        position = newPosition
    }
end

return DropShadow
