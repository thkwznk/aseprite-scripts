local Mode = dofile("../Mode.lua")

local Variant = {Unique = Mode.Mix, Propotional = Mode.MixProportional}

local function Contains(collection, expectedValue)
    for _, value in ipairs(collection) do
        if value == expectedValue then return true end
    end
end

local MixModeBase = {
    canExtend = true,
    useMaskColor = true,
    ignoreEmptyCel = true,
    deleteOnEmptyCel = true,
    variantId = ""
}

function MixModeBase:New(id)
    local o = {variantId = id}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MixModeBase:Process(change, sprite, cel, parameters)
    local colors = {}

    for _, pixel in ipairs(change.pixels) do
        if pixel.color and pixel.color.alpha == 255 then
            if self.variantId == Variant.Unique then
                if not Contains(colors, pixel.color) then
                    table.insert(colors, pixel.color)
                end
            elseif self.variantId == Variant.Propotional then
                table.insert(colors, pixel.color)
            end
        end
    end

    local averageColor = change.leftPressed and self:_AverageColorRGB(colors) or
                             self:_AverageColorHSV(colors)

    if parameters.indexedMode and cel.sprite.colorMode == ColorMode.RGB then
        averageColor = sprite.palettes[1]:getColor(averageColor.index)
    end

    local newBounds = app.activeCel.bounds
    local shift = Point(cel.bounds.x - newBounds.x, cel.bounds.y - newBounds.y)

    local newImage = Image(app.activeCel.image.width,
                           app.activeCel.image.height, cel.sprite.colorMode)
    newImage:drawImage(cel.image, shift)

    local drawPixel = newImage.drawPixel

    for _, pixel in ipairs(change.pixels) do
        drawPixel(newImage, pixel.x - newBounds.x, pixel.y - newBounds.y,
                  averageColor)
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(newBounds.x, newBounds.y)
end

-- TODO: Move these to the ColorContext

function MixModeBase:_AverageColorRGB(colors)
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

function MixModeBase:_AverageColorHSV(colors)
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

local variants = {}

for _, variantId in pairs(Variant) do
    table.insert(variants, MixModeBase:New(variantId))
end

return variants

-- TODO: Refactor this to remove variants
