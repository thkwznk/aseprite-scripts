local ShiftMode = {useMaskColor = true, deleteOnEmptyCel = true, variantId = ""}

function ShiftMode:New(id)
    local o = {variantId = id}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ShiftMode:Process(change, sprite, cel, parameters)
    local direction = change.leftPressed and 1 or -1
    local firstShift = parameters.shiftFirstPercentage / 100 * direction
    local secondShift = parameters.shiftSecondPercentage / 100 * direction
    local thirdShift = parameters.shiftThirdPercentage / 100 * direction
    local x, y, c

    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    -- TODO: Cache colors

    for _, pixel in ipairs(change.pixels) do
        x = pixel.x - cel.position.x
        y = pixel.y - cel.position.y
        c = Color(getPixel(cel.image, x, y))

        if c.alpha > 0 then
            if parameters.colorModel == "RGB" then
                if parameters.shiftFirstOption then
                    c.red = math.min(math.max(c.red + firstShift * 255, 0), 255)
                end
                if parameters.shiftSecondOption then
                    c.green = math.min(math.max(c.green + secondShift * 255, 0),
                                       255)
                end
                if parameters.shiftThirdOption then
                    c.blue = math.min(math.max(c.blue + thirdShift * 255, 0),
                                      255)
                end
            elseif parameters.colorModel == "HSV" then
                if parameters.shiftFirstOption then
                    c.hsvHue = (c.hsvHue + firstShift * 360) % 360
                end
                if parameters.shiftSecondOption then
                    c.hsvSaturation = c.hsvSaturation + secondShift
                end
                if parameters.shiftThirdOption then
                    c.hsvValue = c.hsvValue + thirdShift
                end
            elseif parameters.colorModel == "HSL" then
                if parameters.shiftFirstOption then
                    c.hslHue = (c.hslHue + firstShift * 360) % 360
                end
                if parameters.shiftSecondOption then
                    c.hslSaturation = c.hslSaturation + secondShift
                end
                if parameters.shiftThirdOption then
                    c.hslLightness = c.hslLightness + thirdShift
                end
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

