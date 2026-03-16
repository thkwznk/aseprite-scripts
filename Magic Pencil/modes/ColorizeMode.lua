local ColorizeMode = {ignoreEmptyCel = true, deleteOnEmptyCel = true}

function ColorizeMode:Process(change, sprite, cel, parameters)
    local targetColor = change.leftPressed and app.fgColor or app.bgColor
    local hue = targetColor.hsvHue
    local saturation = targetColor.hsvSaturation

    local cx, cy, image = cel.position.x, cel.position.y, cel.image
    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    local palette = sprite.palettes[1]
    local getColor = palette.getColor

    local isIndexed = parameters.indexedMode and sprite.colorMode ==
                          ColorMode.RGB

    local x, y, color
    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cx
        y = pixel.y - cy
        color = Color(getPixel(image, x, y))

        if color.alpha > 0 then
            color.hsvHue = hue
            color.hsvSaturation = (color.hsvSaturation + saturation) / 2

            if isIndexed then color = getColor(palette, color.index) end

            drawPixel(image, x, y, color)
        end
    end

    app.activeCel.image = image
    app.activeCel.position = cel.position
end

return ColorizeMode
