dofile("./ok_color.lua")
local ColorConverter = dofile('./ColorConverter.lua')
local GetPixels = dofile('./ImagePixels.lua')
local PreviewCanvas = dofile('./PreviewCanvas.lua')

local InvertColorSpace = {
    RGB = "RGB",
    HSV = "HSV",
    HSL = "HSL",
    OKHSV = "OKHSV",
    OKHSL = "OKHSL"
}

local InvertColor = function(pixelValue, parameters)
    local color = Color(pixelValue)

    if parameters.colorSpace == InvertColorSpace.RGB then
        if parameters.componentA then color.red = 255 - color.red end
        if parameters.componentB then color.green = 255 - color.green end
        if parameters.componentC then color.blue = 255 - color.blue end
    elseif parameters.colorSpace == InvertColorSpace.HSV then
        if parameters.componentA then
            color.hsvHue = (color.hsvHue + 180) % 360
        end
        if parameters.componentB then
            color.hsvSaturation = 1 - color.hsvSaturation
        end
        if parameters.componentC then color.hsvValue = 1 - color.hsvValue end
    elseif parameters.colorSpace == InvertColorSpace.HSL then
        if parameters.componentA then
            color.hslHue = (color.hslHue + 180) % 360
        end
        if parameters.componentB then
            color.hslSaturation = 1 - color.hslSaturation
        end
        if parameters.componentC then
            color.hslLightness = 1 - color.hslLightness
        end
    elseif parameters.colorSpace == InvertColorSpace.OKHSV then
        local okhsv = ColorConverter:ColorToOkhsv(color)

        if parameters.componentA then okhsv.h = (okhsv.h + 180) % 360 end
        if parameters.componentB then okhsv.s = 1 - okhsv.s end
        if parameters.componentC then okhsv.v = 1 - okhsv.v end

        color = ColorConverter:OkhsvToColor(okhsv)
    elseif parameters.colorSpace == InvertColorSpace.OKHSL then
        local okhsl = ColorConverter:ColorToOkhsl(color)

        if parameters.componentA then okhsl.h = (okhsl.h + 180) % 360 end
        if parameters.componentB then okhsl.s = 1 - okhsl.s end
        if parameters.componentC then okhsl.l = 1 - okhsl.l end

        color = ColorConverter:OkhslToColor(okhsl)
    end

    return color
end

local InvertCelColors = function(cel, parameters)
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
                    if not cache[pixelValue] then
                        cache[pixelValue] = InvertColor(pixelValue, parameters)
                    end

                    drawPixel(resultImage, x, y, cache[pixelValue])
                end
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertColors = function(parameters)
    app.transaction(function()
        for _, cel in ipairs(app.range.cels) do
            -- Invert colors only for the editable cels
            if cel.layer.isEditable then
                InvertCelColors(cel, parameters)
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
                cache[pixel.value] = InvertColor(pixel.value, parameters)
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
    invertedImage = InvertPixels(invertedImage, pixels, {
        colorSpace = InvertColorSpace.OKHSV,
        componentA = true
    })

    local dialog = Dialog("Invert Colors")
    local RepaintImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                       invertedImage)

    local RefreshInvertedImage = function()
        invertedImage = InvertPixels(invertedImage, pixels, dialog.data)
        RepaintImage(invertedImage)
    end

    local RefreshComponentLabels = function(colorSpace)
        if colorSpace == InvertColorSpace.RGB then
            dialog --
            :modify{id = "componentA", label = "Red"} --
            :modify{id = "componentB", label = "Green"} --
            :modify{id = "componentC", label = "Blue"} --
        elseif colorSpace == InvertColorSpace.HSV or colorSpace ==
            InvertColorSpace.OKHSV then
            dialog --
            :modify{id = "componentA", label = "Hue"} --
            :modify{id = "componentB", label = "Saturation"} --
            :modify{id = "componentC", label = "Value"} --
        elseif colorSpace == InvertColorSpace.HSL or colorSpace ==
            InvertColorSpace.OKHSL then
            dialog --
            :modify{id = "componentA", label = "Hue"} --
            :modify{id = "componentB", label = "Saturation"} --
            :modify{id = "componentC", label = "Lightness"} --
        end
    end

    dialog --
    :combobox{
        id = "colorSpace",
        label = "Color Space:",
        option = InvertColorSpace.OKHSV,
        options = {
            InvertColorSpace.RGB, InvertColorSpace.HSV, InvertColorSpace.HSL,
            InvertColorSpace.OKHSV, InvertColorSpace.OKHSL
        },
        onchange = function()
            RefreshComponentLabels(dialog.data.colorSpace)
            RefreshInvertedImage()
        end
    } --
    :separator{text = "Components to Invert:"} --
    :check{
        id = "componentA",
        label = "A",
        selected = true,
        onclick = RefreshInvertedImage
    } --
    :check{id = "componentB", label = "B", onclick = RefreshInvertedImage} --
    :check{id = "componentC", label = "C", onclick = RefreshInvertedImage} --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            InvertColors(dialog.data)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    RefreshComponentLabels(InvertColorSpace.OKHSV)

    return dialog
end

return InvertColorsDialog
