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

    local x, y, c
    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cx
        y = pixel.y - cy
        c = Color(getPixel(image, x, y))

        if c.alpha > 0 then
            c.hsvHue = hue
            c.hsvSaturation = (c.hsvSaturation + saturation) / 2

            if isIndexed then c = getColor(palette, c.index) end

            drawPixel(image, x, y, c)
        end
    end

    app.activeCel.image = image
    app.activeCel.position = cel.position
end

return ColorizeMode
