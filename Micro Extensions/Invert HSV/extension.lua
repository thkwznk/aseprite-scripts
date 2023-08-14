local InvertMode = {Hue = "Hue", Saturation = "Saturation", Value = "Value"}

local InvertCelHSV = function(cel, mode)
    if not cel.layer.isEditable then return end

    local selection = cel.sprite.selection
    local image = cel.image
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local resultImage = Image(image.width, image.height, image.colorMode)

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local pixelValue = getPixel(image, x, y)

            if pixelValue > 0 then
                local pixelColor = Color(pixelValue)

                if selection.isEmpty or (not selection.isEmpty and
                    selection:contains(cel.position.x + x, cel.position.y + y)) then

                    if mode == InvertMode.Hue then
                        pixelColor.hue = (pixelColor.hue + 180) % 360
                    elseif mode == InvertMode.Saturation then
                        -- Ignore pixels in grayscale, they always have hue=0 so they would always end up red
                        if pixelColor.saturation > 0 then
                            pixelColor.saturation = 1 - pixelColor.saturation
                        end
                    elseif mode == InvertMode.Value then
                        pixelColor.value = 1 - pixelColor.value
                    end
                end

                drawPixel(resultImage, x, y, pixelColor)
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertHSV = function(mode)
    app.transaction(function()
        for _, cel in ipairs(app.range.cels) do InvertCelHSV(cel, mode) end
    end)

    app.refresh()
end

function init(plugin)
    local group = "edit_insert"
    local modes = {InvertMode.Hue, InvertMode.Saturation, InvertMode.Value}

    if app.apiVersion >= 22 then
        plugin:newMenuGroup{
            id = "edit_invert",
            title = "Invert Component",
            group = "edit_insert"
        }

        group = "edit_invert"
    end

    for _, mode in ipairs(modes) do
        plugin:newCommand{
            id = "Invert" .. mode,
            title = app.apiVersion >= 22 and mode or "Invert " .. mode,
            group = group,
            onenabled = function()
                local sprite = app.activeSprite

                if sprite == nil then return false end

                if sprite.colorMode == ColorMode.GRAY and
                    (mode == InvertMode.Hue or mode == InvertMode.Saturation) then
                    return false
                end

                return true
            end,
            onclick = function() InvertHSV(mode) end
        }
    end
end

function exit(plugin)
    -- You don't really need to do anything specific here
end
