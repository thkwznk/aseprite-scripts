local ColorizeMode = {ignoreEmptyCel = true, deleteOnEmptyCel = true}

function ColorizeMode:Process(change, sprite, cel, parameters)
    local x, y, c
    local hue = change.leftPressed and app.fgColor.hsvHue or app.bgColor.hsvHue

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            c.hsvHue = hue
            c.hsvSaturation = (c.hsvSaturation + app.fgColor.hsvSaturation) / 2

            if parameters.indexedMode and cel.sprite.colorMode == ColorMode.RGB then
                c = sprite.palettes[1]:getColor(c.index)
            end

            drawPixel(cel.image, x, y, c)
        end
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position
end

return ColorizeMode
