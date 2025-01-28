local ColorContext = {}

function ColorContext:IsTransparent(color)
    local sprite = app.activeSprite
    if sprite and sprite.colorMode == ColorMode.RGB then
        return color.alpha == 0
    end

    return color.index == 0
end

function ColorContext:Create(value)
    local sprite = app.activeSprite
    if sprite and sprite.colorMode == ColorMode.RGB then return Color(value) end

    return Color {index = value}
end

function ColorContext:Copy(color)
    local sprite = app.activeSprite
    if sprite and sprite.colorMode == ColorMode.RGB then
        return Color(color.rgbaPixel)
    end

    return Color {index = color.index}
end

function ColorContext:Compare(a, b)
    local sprite = app.activeSprite
    if sprite and sprite.colorMode == ColorMode.RGB then
        return a.red == b.red and a.green == b.green and a.blue == b.blue
    end

    return a.index == b.index
end

function ColorContext:Distance(a, b)
    return math.sqrt((a.red - b.red) ^ 2 + (a.green - b.green) ^ 2 +
                         (a.blue - b.blue) ^ 2 + (a.alpha - b.alpha) ^ 2)
end

function ColorContext:AverageColorsRGB(colors)
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

function ColorContext:AverageColorsHSV(colors)
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

return ColorContext
