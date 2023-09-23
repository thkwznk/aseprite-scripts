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

local GetLayersArray
GetLayersArray = function(layers)
    local result = {}

    for _, layer in ipairs(layers) do
        if layer.isGroup then
            local nestedLayers = GetLayersArray(layer.layers)

            for _, nestedLayer in ipairs(nestedLayers) do
                table.insert(result, nestedLayer)
            end
        else
            table.insert(result, layer)
        end
    end

    return result
end

local GetJoinedImageBounds = function(layers, frame)
    local joinedBounds = nil

    for _, layer in ipairs(layers) do
        local cel = layer:cel(frame)

        if cel then
            local imageBounds = Rectangle(cel.image.bounds)
            imageBounds.x = cel.position.x
            imageBounds.y = cel.position.y

            if joinedBounds then
                joinedBounds = joinedBounds:union(imageBounds)
            else
                joinedBounds = imageBounds
            end
        end
    end

    return joinedBounds
end

local GetPixels = function() -- image)
    local sprite = app.activeSprite
    local layers = GetLayersArray(sprite.layers)
    local frame = app.activeFrame

    local joinedImageBounds = GetJoinedImageBounds(layers, frame)
    local joinedImage = Image(joinedImageBounds.width, joinedImageBounds.height,
                              sprite.colorMode)

    local pixels = {}

    for x = 1, joinedImage.width do
        pixels[x] = {}
        for y = 1, joinedImage.height do pixels[x][y] = false end
    end

    for _, layer in ipairs(layers) do
        local cel = layer:cel(frame)

        if cel then
            local image = cel.image
            local getPixel = image.getPixel

            local p = Point(cel.position.x - joinedImageBounds.x,
                            cel.position.y - joinedImageBounds.y)

            joinedImage:drawImage(image, p)

            for x = 0, image.width - 1 do
                for y = 0, image.height - 1 do
                    local pixelValue = getPixel(image, x, y)

                    if pixelValue > 0 then
                        local pixelColor = Color(pixelValue)

                        local inRange = false

                        for _, layerInRange in ipairs(app.range.layers) do
                            if layer == layerInRange then
                                inRange = true
                                break
                            end
                        end

                        pixels[p.x + x + 1][p.y + y + 1] = {
                            x = p.x + x,
                            y = p.y + y,
                            value = pixelValue,
                            color = pixelColor,
                            isEditable = inRange,
                            distance = 0
                        }
                    end
                end
            end
        end
    end

    local flatPixels = {}

    for x = 1, joinedImage.width do
        for y = 1, joinedImage.height do
            if pixels[x][y] ~= false then
                table.insert(flatPixels, pixels[x][y])
            end
        end
    end

    return joinedImage, flatPixels
end

local UpdatePixelDistance = function(pixels, mode, color)
    local calculate = ColorDistance[mode]
    local max = ColorDistance.Max[mode]

    for _, pixel in ipairs(pixels) do
        pixel.distance = calculate(color, pixel.color) / max
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
                local targetColor = Color(pixel.color)

                targetColor.hue = (targetColor.hue + data.hueShift) % 360
                if targetColor.saturation > 0 then
                    targetColor.saturation =
                        targetColor.saturation + data.saturationShift / 100
                end

                targetColor.value = targetColor.value + data.valueShift / 100

                cache[valueId] = targetColor
            end

            drawPixel(image, pixel.x, pixel.y, cache[valueId])
        else
            drawPixel(image, pixel.x, pixel.y, pixel.color)
        end
    end
end

-- local UpdateSelectedImages = function(data)
--     for _, cel in ipairs(app.range.cels) do
--         if cel.image then
--             local pixels = GetPixels(cel.image)

--             local image = Image(cel.image.width, cel.image.height,
--                                 cel.image.colorMode)

--             UpdatePixelDistance(pixels, data.mode, data.sourceColor)
--             UpdateTargetColor(image, pixels, data)

--             cel.sprite:newCel(cel.layer, cel.frame, image, cel.position)
--         end
--     end
-- end

local DrawGrid = function(graphicsContext, sprite)
    local docPref = app.preferences.document(sprite)

    local color1 = docPref.bg.color1
    local color2 = docPref.bg.color2
    local size = docPref.bg.size

    graphicsContext.color = color1
    graphicsContext:fillRect(Rectangle(0, 0, graphicsContext.width,
                                       graphicsContext.height))

    local startRowGap = false
    local isGap = false

    for x = 0, math.ceil(graphicsContext.width / size.width) do
        isGap = startRowGap

        for y = 0, math.ceil(graphicsContext.height / size.height) do
            if not isGap then
                local bounds = Rectangle(x * size.width, y * size.height,
                                         size.width, size.height)

                graphicsContext.color = color2
                graphicsContext:fillRect(bounds)
            end

            isGap = not isGap
        end

        startRowGap = not startRowGap
    end
end

local AdjustColorsDialog = function()
    local sprite = app.activeSprite
    local image, pixels = GetPixels() -- GetPixels(image)

    -- destinationImage:drawSprite(sourceSprite, frameNumber, [, position ] )

    local adjustedImage = Image(image.width, image.height, ColorMode.RGB)

    UpdateTargetColor(adjustedImage, pixels, {
        mode = "HSV",
        tolerance = 0,
        hueShift = 0,
        saturationShift = 0,
        valueShift = 0
    })

    UpdatePixelDistance(pixels, "HSV", app.fgColor)

    -- group="edit_insert"
    -- title="Adjust Color..."
    -- TODO: Disable the menu option for this IF the sprite is in the Grayscale mode

    local dialog = Dialog("Adjust Color")

    local border = 3
    local padding = 8
    local maxCanvasSize = Rectangle(0, 0, 200, 200)
    local isMouseDown = false
    local lastMouse = nil
    local imagePositionDelta = Point(0, 0)
    local scale = 1

    dialog --
    :canvas{
        label = "Preview:",
        width = math.min(image.width + border * 2 + padding * 2,
                         maxCanvasSize.width),
        height = math.min(image.height + border * 2 + padding * 2,
                          maxCanvasSize.height),
        onpaint = function(ev)
            local gc = ev.context

            -- Draw the editor background with a border first
            gc:drawThemeRect("sunken_focused",
                             Rectangle(0, 0, gc.width, gc.height))

            local innerCanvasBounds = Rectangle(border, border,
                                                gc.width - border * 2,
                                                gc.height - border * 2)

            -- Clip to the area withing the drawn editor border
            -- All drawing operations after taht will only draw within the clipping region
            -- This assure that no shape will be drawn over the borders
            gc:beginPath()
            gc:rect(innerCanvasBounds)
            gc:clip()

            DrawGrid(gc, sprite)

            local destinationBounds = Rectangle(
                                          imagePositionDelta.x +
                                              (gc.width - adjustedImage.width) /
                                              2, imagePositionDelta.y +
                                              (gc.height - adjustedImage.height) /
                                              2, adjustedImage.width * scale,
                                          adjustedImage.height * scale)

            gc:drawImage(adjustedImage, adjustedImage.bounds, destinationBounds)
        end,
        onmousemove = function(ev)
            if isMouseDown and lastMouse then
                imagePositionDelta.x = imagePositionDelta.x -
                                           (lastMouse.x - ev.x)
                imagePositionDelta.y = imagePositionDelta.y -
                                           (lastMouse.y - ev.y)

                lastMouse = Point(ev.x, ev.y)
                dialog:repaint()
            end
        end,
        onmousedown = function(ev)
            isMouseDown = ev.button == MouseButton.LEFT
            if isMouseDown then lastMouse = Point(ev.x, ev.y) end
        end,
        onmouseup = function(ev)
            isMouseDown = not (ev.button == MouseButton.LEFT)
        end,
        onwheel = function(ev)
            local newScale = math.max(scale - ev.deltaY, 1)

            local oldWidth = adjustedImage.width * scale
            local newWidth = adjustedImage.width * newScale
            local oldHeight = adjustedImage.height * scale
            local newHeight = adjustedImage.height * newScale

            imagePositionDelta.x =
                imagePositionDelta.x - (newWidth - oldWidth) / 2
            imagePositionDelta.y = imagePositionDelta.y -
                                       (newHeight - oldHeight) / 2

            scale = newScale
            dialog:repaint()
        end
    } --
    :color{
        id = "sourceColor",
        label = "Color:",
        color = app.fgColor,
        onchange = function()
            local data = dialog.data
            UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            UpdateTargetColor(adjustedImage, pixels, data)
            dialog:repaint()
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

            dialog:repaint()
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

            dialog:repaint()
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
            dialog:repaint()
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

            dialog:repaint()
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

            dialog:repaint()
        end
    } --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            -- app.transaction(function() UpdateSelectedImages(dialog.data) end)

            -- app.refresh()
            -- dialog:close()
        end
    } -- 
    :button{
        text = "Apply",
        onclick = function()
            -- app.transaction(function() UpdateSelectedImages(dialog.data) end)

            -- app.refresh()

            -- -- TODO: Update correctly
            -- cel = app.activeCel
            -- image = cel.image
            -- pixels = GetPixels(image)

            -- local data = dialog.data
            -- UpdatePixelDistance(pixels, data.mode, data.sourceColor)
            -- UpdateTargetColor(adjustedImage, pixels, data)
        end
    } -- 
    :button{text = "Cancel"} -- 

    return dialog
end

return AdjustColorsDialog

-- TODO: Reimplement applying color adjustment
-- TODO: Add an option to only show the pixel from selected layers 
-- TODO: Add an option to disable preview (non-edited colors)
-- TODO: Support respecting selection
-- TODO: Shift+Alt+R keyboard shortcut
-- TODO: Add zooming out
