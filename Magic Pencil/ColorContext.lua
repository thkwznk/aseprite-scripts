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

return ColorContext

-- TODO: This should be refactored
