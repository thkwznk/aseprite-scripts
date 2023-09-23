dofile("./ok_color.lua")
local ColorConverter = dofile('./ColorConverter.lua')
local GetPixels = dofile('./ImagePixels.lua')
local PreviewCanvas = dofile('./PreviewCanvas.lua')

local ColorDistance = {
    RGB = function(a, b)
        return
            (a.red - b.red) ^ 2 + (a.green - b.green) ^ 2 + (a.blue - b.blue) ^
                2
    end,
    HSV = function(a, b)
        local h0, h1 = a.hsvHue, b.hsvHue
        local s0, s1 = a.hsvSaturation, b.hsvSaturation
        local v0, v1 = a.hsvValue, b.hsvValue

        local dh = math.min(math.abs(h1 - h0), 360 - math.abs(h1 - h0)) / 180.0
        local ds = math.abs(s1 - s0)
        local dv = math.abs(v1 - v0) / 255.0

        return (dh ^ 2 + ds ^ 2 + dv ^ 2)
    end,
    HSL = function(a, b)
        local h0, h1 = a.hslHue, b.hslHue
        local s0, s1 = a.hslSaturation, b.hslSaturation
        local v0, v1 = a.hslLightness, b.hslLightness

        local dh = math.min(math.abs(h1 - h0), 360 - math.abs(h1 - h0)) / 180.0
        local ds = math.abs(s1 - s0)
        local dv = math.abs(v1 - v0) / 255.0

        return (dh ^ 2 + ds ^ 2 + dv ^ 2)
    end,
    OKHSV = function(a, b)
        a = ColorConverter:ColorToOkhsv(a)
        b = ColorConverter:ColorToOkhsv(b)

        local h0, h1 = a.h, b.h
        local s0, s1 = a.s, b.s
        local v0, v1 = a.v, b.v

        local dh = math.min(math.abs(h1 - h0), 360 - math.abs(h1 - h0)) / 180.0
        local ds = math.abs(s1 - s0)
        local dv = math.abs(v1 - v0)

        return (dh ^ 2 + ds ^ 2 + dv ^ 2)
    end,
    OKHSL = function(a, b)
        a = ColorConverter:ColorToOkhsl(a)
        b = ColorConverter:ColorToOkhsl(b)

        local h0, h1 = a.h, b.h
        local s0, s1 = a.s, b.s
        local v0, v1 = a.l, b.l

        local dh = math.min(math.abs(h1 - h0), 360 - math.abs(h1 - h0)) / 180.0
        local ds = math.abs(s1 - s0)
        local dv = math.abs(v1 - v0)

        return (dh ^ 2 + ds ^ 2 + dv ^ 2)
    end,
    Max = {
        RGB = (255 ^ 2) * 3,
        HSV = 2 ^ 2 + 1 + 1,
        HSL = 2 ^ 2 + 1 + 1,
        OKHSV = 2 ^ 2 + 1 + 1,
        OKHSL = 2 ^ 2 + 1 + 1
    }
}

local UpdatePixelDistance = function(pixels, mode, color)
    local calculate = ColorDistance[mode]
    local max = ColorDistance.Max[mode]
    local cache = {}

    for _, pixel in ipairs(pixels) do
        if not cache[pixel.value] then
            cache[pixel.value] = calculate(color, pixel.color) / max
        end

        pixel.distance = cache[pixel.value]
    end
end

local AdjustColor = function(color, parameters)
    local adjustedColor = Color(color)

    if parameters.mode == "RGB" then
        adjustedColor.red = math.min(math.max(
                                         adjustedColor.red +
                                             parameters.componentA, 0), 255)
        adjustedColor.green = math.min(math.max(
                                           adjustedColor.green +
                                               parameters.componentB, 0), 255)
        adjustedColor.blue = math.min(math.max(
                                          adjustedColor.blue +
                                              parameters.componentC, 0), 255)
    elseif parameters.mode == "HSV" then
        adjustedColor.hsvHue = (adjustedColor.hsvHue + parameters.componentA) %
                                   360
        if adjustedColor.hsvSaturation > 0 then
            adjustedColor.hsvSaturation =
                adjustedColor.hsvSaturation + parameters.componentB / 100
        end

        adjustedColor.hsvValue =
            adjustedColor.hsvValue + parameters.componentC / 100
    elseif parameters.mode == "HSL" then
        adjustedColor.hslHue = (adjustedColor.hslHue + parameters.componentA) %
                                   360
        if adjustedColor.hslSaturation > 0 then
            adjustedColor.hslSaturation =
                adjustedColor.hslSaturation + parameters.componentB / 100
        end

        adjustedColor.hslLightness = adjustedColor.hslLightness +
                                         parameters.componentC / 100
    elseif parameters.mode == "OKHSV" then
        local okhsv = ColorConverter:ColorToOkhsv(adjustedColor)

        okhsv.h = (okhsv.h + parameters.componentA) % 360
        okhsv.s = okhsv.s + parameters.componentB / 100
        okhsv.v = okhsv.v + parameters.componentC / 100

        adjustedColor = ColorConverter:OkhsvToColor(okhsv)
    elseif parameters.mode == "OKHSL" then
        local okhsl = ColorConverter:ColorToOkhsl(adjustedColor)

        okhsl.h = (okhsl.h + parameters.componentA) % 360
        okhsl.s = okhsl.s + parameters.componentB / 100
        okhsl.l = okhsl.l + parameters.componentC / 100

        adjustedColor = ColorConverter:OkhslToColor(okhsl)
    end

    return adjustedColor
end

local AdjustImage = function(image, selection, parameters)
    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local cache = {}
    local adjustedImage = Image(image)

    local calculate = ColorDistance[parameters.mode]
    local max = ColorDistance.Max[parameters.mode]
    local distanceCache = {}

    local tolerance = parameters.tolerance / 5 -- Correct tolerance for better results
    tolerance = tolerance / 100 -- Correct to the 0.0 to 1.0 range

    for x = 0, image.width do
        for y = 0, image.height do
            if selection.isEmpty or selection:contains(x, y) then
                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    if not distanceCache[pixelValue] then
                        distanceCache[pixelValue] =
                            calculate(Color(pixelValue), parameters.sourceColor) /
                                max
                    end

                    if distanceCache[pixelValue] <= tolerance then
                        if not cache[pixelValue] then
                            cache[pixelValue] =
                                AdjustColor(Color(pixelValue), parameters)
                        end

                        drawPixel(adjustedImage, x, y, cache[pixelValue])
                    end
                end
            end
        end
    end

    return adjustedImage
end

local Apply = function(parameters)
    for _, cel in ipairs(app.range.cels) do
        if cel.layer.isEditable then
            local bounds = cel.sprite.selection.bounds
            local selection = Selection(Rectangle(bounds.x - cel.position.x,
                                                  bounds.y - cel.position.y,
                                                  bounds.width, bounds.height))

            cel.image = AdjustImage(cel.image, selection, parameters)
        end
    end
end

local UpdateTargetColor = function(image, pixels, data)
    local cache = {}
    local drawPixel = image.drawPixel

    local tolerance = data.tolerance / 5 -- Correct tolerance for better results
    tolerance = tolerance / 100 -- Correct to the 0.0 to 1.0 range

    for _, pixel in ipairs(pixels) do
        if pixel.isEditable and pixel.distance <= tolerance then
            local valueId = pixel.value

            if not cache[valueId] then
                cache[valueId] = AdjustColor(pixel.color, data)
            end

            drawPixel(image, pixel.x, pixel.y, cache[valueId])
        else
            drawPixel(image, pixel.x, pixel.y, pixel.color)
        end
    end
end

local AdjustColorsDialog = function(sprite)
    local image, pixels = GetPixels(sprite)
    local adjustedImage = Image(image.width, image.height, ColorMode.RGB)

    UpdateTargetColor(adjustedImage, pixels, {
        mode = "OKHSV",
        tolerance = 0,
        componentA = 0,
        componentB = 0,
        componentC = 0
    })

    UpdatePixelDistance(pixels, "HSV", app.fgColor)

    local dialog = Dialog("Adjust Color")
    local RepaintImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                       adjustedImage)

    local UpdateComponents = function(mode)
        if mode == "RGB" then
            dialog --
            :modify{id = "componentA", label = "Red", min = -255, max = 255} --
            :modify{id = "componentB", label = "Green", min = -255, max = 255} --
            :modify{id = "componentC", label = "Blue", min = -255, max = 255} --
        elseif mode == "HSV" or mode == "OKHSV" then
            dialog --
            :modify{id = "componentA", label = "Hue", min = -180, max = 180} --
            :modify{
                id = "componentB",
                label = "Saturation",
                min = -100,
                max = 100
            } --
            :modify{id = "componentC", label = "Value", min = -100, max = 100} --
        elseif mode == "HSL" or mode == "OKHSL" then
            dialog --
            :modify{id = "componentA", label = "Hue", min = -180, max = 180} --
            :modify{
                id = "componentB",
                label = "Saturation",
                min = -100,
                max = 100
            } --
            :modify{
                id = "componentC",
                label = "Lightness",
                min = -100,
                max = 100
            } --
        end
    end

    dialog --
    :color{
        id = "sourceColor",
        label = "Color:",
        color = app.fgColor,
        onchange = function()
            local data = dialog.data
            UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            UpdateTargetColor(adjustedImage, pixels, data)
            RepaintImage(adjustedImage)
        end
    } --
    :separator{text = "Tolerance:"} --
    :combobox{
        id = "mode",
        label = "Mode:",
        option = "OKHSV",
        options = {"RGB", "HSV", "HSL", "OKHSV", "OKHSL"},
        onchange = function()
            local data = dialog.data
            UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            UpdateTargetColor(adjustedImage, pixels, data)
            UpdateComponents(data.mode)
            RepaintImage(adjustedImage)
        end
    } --
    :slider{
        id = "tolerance",
        label = "Tolerance:",
        min = 0,
        max = 100,
        value = 0,
        onrelease = function()
            local data = dialog.data
            UpdateTargetColor(adjustedImage, pixels, data)
            RepaintImage(adjustedImage)
        end
    } --
    :separator{text = "Adjustments:"} --
    :slider{
        id = "componentA",
        label = "Hue:",
        min = 0,
        max = 360,
        value = 0,
        onrelease = function()
            local data = dialog.data
            UpdateTargetColor(adjustedImage, pixels, data)
            RepaintImage(adjustedImage)
        end
    } --
    :newrow() --
    :slider{
        id = "componentB",
        label = "Saturation:",
        min = -100,
        max = 100,
        value = 0,
        onrelease = function()
            local data = dialog.data
            UpdateTargetColor(adjustedImage, pixels, data)
            RepaintImage(adjustedImage)
        end
    } --
    :newrow() --
    :slider{
        id = "componentC",
        label = "Value:",
        min = -100,
        max = 100,
        value = 0,
        onrelease = function()
            local data = dialog.data
            UpdateTargetColor(adjustedImage, pixels, data)
            RepaintImage(adjustedImage)
        end
    } --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            app.transaction(function() Apply(dialog.data) end)
            app.refresh()

            dialog:close()
        end
    } -- 
    :button{
        text = "Apply",
        onclick = function()
            local data = dialog.data
            app.transaction(function() Apply(data) end)
            app.refresh()

            image, pixels = GetPixels(sprite)

            UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            UpdateTargetColor(adjustedImage, pixels, data)
        end
    } -- 
    :button{text = "Cancel"} -- 

    return dialog
end

return AdjustColorsDialog
