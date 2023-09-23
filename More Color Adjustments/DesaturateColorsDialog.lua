local PreviewCanvas = dofile('./PreviewCanvas.lua')
local ColorConverter = dofile('./ColorConverter.lua')
local GetPixels = dofile('./ImagePixels.lua')

local DesaturateMode = {
    Grayscale = "Grayscale",
    HSV = "HSV",
    HSL = "HSL",
    OKHSV = "OKHSV",
    OKHSL = "OKHSL"
}

local DesaturateColor = function(pixelValue, mode)
    local color = Color(pixelValue)

    if mode == DesaturateMode.Grayscale then
        return Color {
            gray = color.red * 0.3 + color.green * 0.59 + color.blue * 0.11,
            alpha = color.alpha
        }
    elseif mode == DesaturateMode.HSV then
        color.hsvSaturation = 0
    elseif mode == DesaturateMode.HSL then
        color.hslSaturation = 0
    elseif mode == DesaturateMode.OKHSV then
        local okhsv = ColorConverter:ColorToOkhsv(color)
        okhsv.s = 0
        color = ColorConverter:OkhsvToColor(okhsv)
    elseif mode == DesaturateMode.OKHSL then
        local okhsl = ColorConverter:ColorToOkhsl(color)
        okhsl.s = 0
        color = ColorConverter:OkhslToColor(okhsl)
    end

    return color
end

local DesaturateCelColors = function(image, selection, mode)
    local getPixel, drawPixel = image.getPixel, image.drawPixel
    local resultImage = Image(image)

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if selection.isEmpty or selection:contains(x, y) then

                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    local key = tostring(pixelValue)

                    if cache[key] then
                        pixelValue = Color(cache[key])
                    else
                        pixelValue = DesaturateColor(pixelValue, mode).rgbaPixel
                        cache[key] = Color(pixelValue)
                    end

                    drawPixel(resultImage, x, y, pixelValue)
                end
            end
        end
    end

    return resultImage
end

local DesaturateColors = function(mode)
    app.transaction(function()
        local bounds = app.activeSprite.selection.bounds

        for _, cel in ipairs(app.range.cels) do
            -- Desaturate colors only for the editable cels
            if cel.layer.isEditable then
                local selection = Selection(
                                      Rectangle(bounds.x - cel.position.x,
                                                bounds.y - cel.position.y,
                                                bounds.width, bounds.height))

                local image = DesaturateCelColors(cel.image, selection, mode)

                -- Update only the image to preserve cel properties
                cel.image = image
            end
        end
    end)

    app.refresh()
end

local DesaturatePixels = function(image, pixels, mode)
    local cache = {}
    local drawPixel = image.drawPixel

    for _, pixel in ipairs(pixels) do
        if pixel.isEditable then
            if not cache[pixel.value] then
                cache[pixel.value] = DesaturateColor(pixel.value, mode)
            end

            drawPixel(image, pixel.x, pixel.y, cache[pixel.value])
        else
            drawPixel(image, pixel.x, pixel.y, pixel.color)
        end
    end

    return image
end

local DesaturateColorsDialog = function()
    local image, pixels = GetPixels()
    local desaturatedImage = DesaturatePixels(image, pixels,
                                              DesaturateMode.Grayscale)

    local dialog = Dialog("Desaturate Colors")
    local RepaintImage = PreviewCanvas(dialog, 100, 100, app.activeSprite,
                                       desaturatedImage)

    dialog --
    :combobox{
        id = "mode",
        label = "Mode:",
        option = DesaturateMode.Grayscale,
        options = {
            DesaturateMode.Grayscale, DesaturateMode.HSV, DesaturateMode.HSL,
            DesaturateMode.OKHSV, DesaturateMode.OKHSL
        },
        onchange = function()
            desaturatedImage = DesaturatePixels(image, pixels, dialog.data.mode)

            RepaintImage(desaturatedImage)
        end
    } --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            DesaturateColors(dialog.data.mode)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

return DesaturateColorsDialog
