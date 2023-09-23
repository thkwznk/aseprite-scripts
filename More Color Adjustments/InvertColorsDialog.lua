dofile("./ok_color.lua")
local ColorConverter = dofile('./ColorConverter.lua')
local GetPixels = dofile('./ImagePixels.lua')
local PreviewCanvas = dofile('./PreviewCanvas.lua')

local InvertColorSpace = {HSV = "HSV/HSL", OKHSV = "OKHSV/OKHSL"}
local InvertMode = {Hue = "Hue", Saturation = "Saturation", Value = "Value"}

function LerpColor(a, b, tt)
    return Color {
        hue = a.hue * (1 - tt) + b.hue * tt,
        saturation = a.saturation * (1 - tt) + b.saturation * tt,
        value = a.value * (1 - tt) + b.value * tt,
        alpha = 255
    }
end

function GetLight(pixelColor)
    return pixelColor.red * 0.3 + pixelColor.green * 0.59 + pixelColor.blue *
               0.11
end

function DarkenColor(c, v)
    local l = GetLight(c) -- current light
    -- v -- expected light
    local d = v / l

    local nc = Color(c)

    while true do
        local nl = GetLight(nc)

        if math.abs(nl - v) <= 3 then break end

        if nl > v then
            nc.hslLightness = nc.hslLightness - 0.01
        else
            nc.hslLightness = nc.hslLightness + 0.01
        end

        if nc.hslLightness <= 0 or nc.hslLightness >= 1 then break end

    end

    return nc
end

local InvertCelHSV = function(cel, mode)
    if not cel.layer.isEditable then return end

    local selection = cel.sprite.selection
    local image = cel.image
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local resultImage = Image(image)

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if selection.isEmpty or
                selection:contains(cel.position.x + x, cel.position.y + y) then

                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    local pixelColor = Color(pixelValue)

                    if mode == InvertMode.Hue then

                        if pixelColor.hslSaturation > 0 then
                            local key = tostring(pixelColor.rgbaPixel)

                            if cache[key] then
                                pixelColor = Color(cache[key])
                            else
                                local o = GetLight(pixelColor)

                                pixelColor.hslHue =
                                    (pixelColor.hslHue + 180) % 360

                                local maxColor = Color(pixelColor)
                                -- maxColor.hslLightness = 1.0
                                maxColor.value = 1.0

                                local minColor = Color(pixelColor)
                                -- minColor.hslLightness = 0.0
                                minColor.value = 0.0

                                local maxLum = GetLight(maxColor)
                                local minLum = GetLight(minColor)

                                print(minColor.red, minColor.green,
                                      maxColor.red, maxColor.green, minLum,
                                      maxLum)

                                pixelColor =
                                    LerpColor(minColor, maxColor, -- o / 255)
                                    (o - minLum) / (maxLum - minLum))

                                cache[key] = Color(pixelColor)
                            end
                        end
                    elseif mode == InvertMode.Saturation then
                        -- Ignore pixels in grayscale, they always have hue=0 so they would always end up red
                        if pixelColor.saturation > 0 then
                            pixelColor.hslSaturation = 1 -
                                                           pixelColor.hslSaturation
                        end
                    elseif mode == InvertMode.Value then
                        pixelColor.hslLightness = 1 - pixelColor.hslLightness
                    end

                    drawPixel(resultImage, x, y, pixelColor)
                end
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertColor = function(pixelValue, colorSpace)
    local color = Color(pixelValue)

    if colorSpace == InvertColorSpace.HSV then
        color.hue = (color.hue + 180) % 360
    elseif colorSpace == InvertColorSpace.OKHSV then
        local okhsv = ColorConverter:ColorToOkhsv(color)
        okhsv.h = (okhsv.h + 180) % 360
        color = ColorConverter:OkhsvToColor(okhsv)
    end

    return color
end

local InvertCelColors = function(cel, colorSpace)
    local selection = cel.sprite.selection
    local image = cel.image
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local resultImage = Image(image)

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if selection.isEmpty or
                selection:contains(cel.position.x + x, cel.position.y + y) then

                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    local key = tostring(pixelValue)

                    if cache[key] then
                        pixelValue = Color(cache[key])
                    else
                        pixelValue =
                            InvertColor(pixelValue, colorSpace).rgbaPixel
                        cache[key] = Color(pixelValue)
                    end

                    drawPixel(resultImage, x, y, pixelValue)
                end
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertColors = function(colorSpace)
    app.transaction(function()
        for _, cel in ipairs(app.range.cels) do
            -- Invert colors only for the editable cels
            if cel.layer.isEditable then
                InvertCelColors(cel, colorSpace)
            end
        end
    end)

    app.refresh()
end

local InvertPixels = function(image, pixels, parameters)
    local cache = {}
    local drawPixel = image.drawPixel

    for _, pixel in ipairs(pixels) do
        if pixel.isEditable then
            if not cache[pixel.value] then
                cache[pixel.value] = InvertColor(pixel.value,
                                                 parameters.colorSpace)
            end

            drawPixel(image, pixel.x, pixel.y, cache[pixel.value])
        else
            drawPixel(image, pixel.x, pixel.y, pixel.color)
        end
    end

    return image
end

local InvertColorsDialog = function(sprite)
    local image, pixels = GetPixels(sprite)
    local invertedImage = Image(image)
    invertedImage = InvertPixels(invertedImage, pixels,
                                 {colorSpace = InvertColorSpace.OKHSV})

    local dialog = Dialog("Invert Colors")
    local RepaintImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                       invertedImage)

    dialog --
    :combobox{
        id = "colorSpace",
        label = "Color Space:",
        option = InvertColorSpace.OKHSV,
        options = {InvertColorSpace.HSV, InvertColorSpace.OKHSV},
        onchange = function()
            invertedImage = InvertPixels(invertedImage, pixels, dialog.data)
            RepaintImage(invertedImage)
        end
    } --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            InvertColors(dialog.data.colorSpace)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

return InvertColorsDialog

-- TODO: Add options for inverting multiple components
-- TODO: Add RGB
