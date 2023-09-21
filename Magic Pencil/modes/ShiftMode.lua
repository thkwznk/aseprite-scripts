local Variant = {
    ShiftHsvHue = "ShiftHsvHueMode",
    ShiftHsvSaturation = "ShiftHsvSaturationMode",
    ShiftHsvValue = "ShiftHsvValueMode",
    ShiftHslHue = "ShiftHslHueMode",
    ShiftHslSaturation = "ShiftHslSaturationMode",
    ShiftHslLightness = "ShiftHslLightnessMode",
    ShiftRgbRed = "ShiftRgbRedMode",
    ShiftRgbGreen = "ShiftRgbGreenMode",
    ShiftRgbBlue = "ShiftRgbBlueMode"
}

local ShiftModeBase = {
    useMaskColor = true,
    deleteOnEmptyCel = true,
    variantId = ""
}

function ShiftModeBase:New(id)
    local o = {variantId = id}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ShiftModeBase:Process(change, sprite, cel, parameters)
    local direction = change.leftPressed and 1 or -1
    local shift = parameters.shiftPercentage / 100 * direction
    local x, y, c

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            if self.variantId == Variant.ShiftHsvHue then
                c.hsvHue = (c.hsvHue + shift * 360) % 360
            elseif self.variantId == Variant.ShiftHsvSaturation then
                c.hsvSaturation = c.hsvSaturation + shift
            elseif self.variantId == Variant.ShiftHsvValue then
                c.hsvValue = c.hsvValue + shift
            elseif self.variantId == Variant.ShiftHslHue then
                c.hslHue = (c.hslHue + shift * 360) % 360
            elseif self.variantId == Variant.ShiftHslSaturation then
                c.hslSaturation = c.hslSaturation + shift
            elseif self.variantId == Variant.ShiftHslLightness then
                c.hslLightness = c.hslLightness + shift
            elseif self.variantId == Variant.ShiftRgbRed then
                c.red = math.min(math.max(c.red + shift * 255, 0), 255)
            elseif self.variantId == Variant.ShiftRgbGreen then
                c.green = math.min(math.max(c.green + shift * 255, 0), 255)
            elseif self.variantId == Variant.ShiftRgbBlue then
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

local variants = {}

for _, variantId in pairs(Variant) do
    table.insert(variants, ShiftModeBase:New(variantId))
end

return variants

