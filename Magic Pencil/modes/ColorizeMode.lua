local ColorizeMode = {deleteOnEmptyCel = true}

function ColorizeMode:Process(change, sprite, cel, parameters)
    local x, y, c
    local hue = If(change.leftPressed, app.fgColor.hsvHue, app.bgColor.hsvHue)

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            c.hsvHue = hue
            c.hsvSaturation = (c.hsvSaturation + app.fgColor.hsvSaturation) / 2

            if parameters.indexedMode then
                c = sprite.palettes[1]:getColor(c.index)
            end

            drawPixel(cel.image, x, y, c)
        end
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position
end

return ColorizeMode
