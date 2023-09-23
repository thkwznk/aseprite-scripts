local PreviewCanvas = dofile('./PreviewCanvas.lua')
local ColorConverter = dofile('./ColorConverter.lua')

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
        local selection = app.activeSprite.selection

        for _, cel in ipairs(app.range.cels) do
            -- Invert colors only for the editable cels
            if cel.layer.isEditable then
                local localSelection = Selection(selection.bounds)
                localSelection.bounds.x =
                    localSelection.bounds.x + cel.position.x
                localSelection.bounds.y =
                    localSelection.bounds.y + cel.position.y

                local image = DesaturateCelColors(cel.image, localSelection,
                                                  mode)

                -- Update only the image to preserve cel properties
                cel.image = image
            end
        end
    end)

    app.refresh()
end

local DesaturateColorsDialog = function()
    local dialog = Dialog("Desaturate Colors")

    -- TODO: Get the full/partial image just like when adjusting the colors
    local desaturatedImage = DesaturateCelColors(app.activeCel.image,
                                                 app.activeSprite.selection,
                                                 DesaturateMode.Grayscale)

    -- TODO: Fix so it updates the image in the preview correctly, right now it only shows the initial image because it's passed as a reference and edits create a new image
    -- Probably this needs a function/provider... somewhere
    PreviewCanvas(dialog, 100, 100, app.activeSprite, desaturatedImage)

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
            desaturatedImage = DesaturateCelColors(app.activeCel.image,
                                                   app.activeSprite.selection,
                                                   dialog.data.mode)
            dialog:repaint()
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
