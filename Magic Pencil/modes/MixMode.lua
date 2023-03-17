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

    local averageColor = change.leftPressed and self:_AverageColorRGB(colors) or
                             self:_AverageColorHSV(colors)

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

function MixMode:_AverageColorRGB(colors)
    local r, g, b = 0, 0, 0

    for _, color in ipairs(colors) do
        r = r + color.red
        g = g + color.green
        b = b + color.blue
    end

    return Color {
        red = math.floor(r / #colors),
        green = math.floor(g / #colors),
        blue = math.floor(b / #colors),
        alpha = 255
    }
end

function MixMode:_AverageColorHSV(colors)
    local h1, h2, s, v = 0, 0, 0, 0

    for _, color in ipairs(colors) do
        h1 = h1 + math.cos(math.rad(color.hsvHue))
        h2 = h2 + math.sin(math.rad(color.hsvHue))
        s = s + color.hsvSaturation
        v = v + color.hsvValue
    end

    return Color {
        hue = math.deg(math.atan(h2, h1)) % 360,
        saturation = s / #colors,
        value = v / #colors,
        alpha = 255
    }
end

return MixMode
