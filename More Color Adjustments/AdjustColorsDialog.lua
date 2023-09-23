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
    Max = {RGB = (255 ^ 2) * 3, HSV = 2 ^ 2 + 1 + 1, HSL = 2 ^ 2 + 1 + 1}
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

    adjustedColor.hue = (adjustedColor.hue + parameters.hueShift) % 360
    if adjustedColor.saturation > 0 then
        adjustedColor.saturation = adjustedColor.saturation +
                                       parameters.saturationShift / 100
    end

    adjustedColor.value = adjustedColor.value + parameters.valueShift / 100

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
        mode = "HSV",
        tolerance = 0,
        hueShift = 0,
        saturationShift = 0,
        valueShift = 0
    })

    UpdatePixelDistance(pixels, "HSV", app.fgColor)

    local dialog = Dialog("Adjust Color")
    local RepaintImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                       adjustedImage)

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
        option = "HSV",
        options = {"RGB", "HSV", "HSL"},
        onchange = function()
            local data = dialog.data
            UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            UpdateTargetColor(adjustedImage, pixels, data)
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
        id = "hueShift",
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
        id = "saturationShift",
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
        id = "valueShift",
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

-- TODO: Support all colord modes - RGB, HSV, HSL, OKHSV (Default), OKHSL
