local ColorContext = dofile("../ColorContext.lua")

local MixModeBase = {
    canExtend = true,
    useMaskColor = true,
    ignoreEmptyCel = true,
    deleteOnEmptyCel = true,
    variantId = ""
}

function MixModeBase:Process(change, sprite, cel, parameters)
    local colors = self:_GetColors(change.pixels)

    local averageColor = change.leftPressed and
                             ColorContext:AverageColorsRGB(colors) or
                             ColorContext:AverageColorsHSV(colors)

    if parameters.indexedMode and cel.sprite.colorMode == ColorMode.RGB then
        averageColor = sprite.palettes[1]:getColor(averageColor.index)
    end

    local newBounds = app.activeCel.bounds
    local shift = Point(cel.bounds.x - newBounds.x, cel.bounds.y - newBounds.y)

    local newImage = Image(app.activeCel.image.width,
                           app.activeCel.image.height, cel.sprite.colorMode)
    newImage:drawImage(cel.image, shift)

    local drawPixel = newImage.drawPixel

    for _, pixel in ipairs(change.pixels) do
        drawPixel(newImage, pixel.x - newBounds.x, pixel.y - newBounds.y,
                  averageColor)
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(newBounds.x, newBounds.y)
end

return MixModeBase
