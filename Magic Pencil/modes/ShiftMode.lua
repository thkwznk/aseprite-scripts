local ShiftMode = {}

function ShiftMode:Process(change, sprite, cel, parameters)
    local mode = parameters.mode
    local shift = parameters.shiftPercentage / 100 *
                      If(change.leftPressed, 1, -1)
    local x, y, c

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            if mode == "ShiftHsvHueMode" then
                c.hsvHue = (c.hsvHue + shift * 360) % 360
            elseif mode == "ShiftHsvSaturationMode" then
                c.hsvSaturation = c.hsvSaturation + shift
            elseif mode == "ShiftHsvValueMode" then
                c.hsvValue = c.hsvValue + shift
            elseif mode == "ShiftHslHueMode" then
                c.hslHue = (c.hslHue + shift * 360) % 360
            elseif mode == "ShiftHslSaturationMode" then
                c.hslSaturation = c.hslSaturation + shift
            elseif mode == "ShiftHslLightnessMode" then
                c.hslLightness = c.hslLightness + shift
            elseif mode == "ShiftRgbRedMode" then
                c.red = math.min(math.max(c.red + shift * 255, 0), 255)
            elseif mode == "ShiftRgbGreenMode" then
                c.green = math.min(math.max(c.green + shift * 255, 0), 255)
            elseif mode == "ShiftRgbBlueMode" then
                c.blue = math.min(math.max(c.blue + shift * 255, 0), 255)
            end

            if parameters.indexedMode then
                c = sprite.palettes[1]:getColor(c.index)
            end

            drawPixel(cel.image, x, y, c)
        end
    end

    app.activeCel.image = cel.image
    app.activeCel.position = cel.position
end

return ShiftMode
