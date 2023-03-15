local MixMode = {}

function MixMode:Process(change, sprite, cel, parameters)
    local colors = {}

    for _, pixel in ipairs(change.pixels) do
        if pixel.color and pixel.color.alpha == 255 then
            if parameters.mode == "MixMode" then
                if not Contains(colors, pixel.color) then
                    table.insert(colors, pixel.color)
                end
            elseif parameters.mode == "MixProportionalMode" then
                table.insert(colors, pixel.color)
            end
        end
    end

    local averageColor = (change.leftPressed and AverageColorRGB or
                             AverageColorHSV)(colors)

    if parameters.indexedMode then
        averageColor = sprite.palettes[1]:getColor(averageColor.index)
    end

    local newBounds = app.activeCel.bounds
    local shift = Point(cel.bounds.x - newBounds.x, cel.bounds.y - newBounds.y)

    local newImage =
        Image(app.activeCel.image.width, app.activeCel.image.height)
    newImage:drawImage(cel.image, shift.x, shift.y)

    local drawPixel = newImage.drawPixel

    for _, pixel in ipairs(change.pixels) do
        drawPixel(newImage, pixel.x - newBounds.x, pixel.y - newBounds.y,
                  averageColor)
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(newBounds.x, newBounds.y)
end

return MixMode
