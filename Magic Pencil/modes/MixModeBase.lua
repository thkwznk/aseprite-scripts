local function AverageColorsRGB(colors)
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

local cos, sin, rad = math.cos, math.sin, math.rad

local function AverageColorsHSV(colors)
    local h1, h2, s, v = 0, 0, 0, 0

    for _, color in ipairs(colors) do
        local hsvHue = color.hsvHue
        h1 = h1 + cos(rad(hsvHue))
        h2 = h2 + sin(rad(hsvHue))
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

local MixModeBase = {
    canExtend = true,
    useMaskColor = true,
    ignoreEmptyCel = true,
    deleteOnEmptyCel = true,
    variantId = ""
}

function MixModeBase:Process(change, sprite, cel, parameters)
    local colors = self:_GetColors(change.pixels)

    local averageColor = change.leftPressed and AverageColorsRGB(colors) or
                             AverageColorsHSV(colors)

    if parameters.indexedMode and cel.sprite.colorMode == ColorMode.RGB then
        averageColor = sprite.palettes[1]:getColor(averageColor.index)
    end

    local newBoundsX, newBoundsY = app.activeCel.bounds.x,
                                   app.activeCel.bounds.y
    local shift = Point(cel.bounds.x - newBoundsX, cel.bounds.y - newBoundsY)

    local newImage = Image(app.activeCel.image.width,
                           app.activeCel.image.height, cel.sprite.colorMode)
    newImage:drawImage(cel.image, shift)

    local drawPixel = newImage.drawPixel

    for _, pixel in ipairs(change.pixels) do
        drawPixel(newImage, pixel.x - newBoundsX, pixel.y - newBoundsY,
                  averageColor)
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(newBoundsX, newBoundsY)
end

return MixModeBase
