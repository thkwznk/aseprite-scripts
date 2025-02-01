-- v1.1
local AdjustScale = function(scale)
    if scale < 0 then return 1 / (math.abs(scale) + 1) end
    return scale
end

local DrawCanvasGrid = function(sprite, image)
    local docPref = app.preferences.document(sprite)

    local color1 = docPref.bg.color1
    local color2 = docPref.bg.color2
    local size = docPref.bg.size

    image:clear(color2)

    local startRowGap = false
    local isGap = false

    for x = 0, math.ceil(image.width / size.width) do
        isGap = startRowGap

        for y = 0, math.ceil(image.height / size.height) do
            if not isGap then
                local bounds = Rectangle(x * size.width, y * size.height,
                                         size.width, size.height)

                image:clear(bounds, color1)
            end

            isGap = not isGap
        end

        startRowGap = not startRowGap
    end
end

local DrawImageOnCanvas = function(sprite, image, position)
    local result = Image(sprite.width, sprite.height, sprite.colorMode)
    DrawCanvasGrid(sprite, result)

    result:drawImage(image, position)

    return result
end

local PreviewCanvas = function(dialog, width, height, sprite, image, position)
    local border = 3
    local padding = 8
    local maxCanvasSize = Rectangle(0, 0, 200, 200)
    local isMouseDown = false
    local lastMouse = nil
    local imagePositionDelta = Point(0, 0)
    local scale = 1

    image = DrawImageOnCanvas(sprite, image, position)

    local RepaintImage = function(newSprite, newImage, newPosition)
        image = DrawImageOnCanvas(newSprite, newImage, newPosition or position)
        dialog:repaint()
    end

    dialog --
    :canvas{
        label = "Preview:",
        width = math.min(width + border * 2 + padding * 2, maxCanvasSize.width),
        height = math.min(height + border * 2 + padding * 2,
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

            local adjustedScale = AdjustScale(scale)
            local destinationBounds = Rectangle(
                                          imagePositionDelta.x +
                                              (gc.width - image.width) / 2,
                                          imagePositionDelta.y +
                                              (gc.height - image.height) / 2,
                                          image.width * adjustedScale,
                                          image.height * adjustedScale)

            -- Fill the canvas with the editor face color
            gc.color = app.theme.color.editor_face
            gc:fillRect(Rectangle(0, 0, gc.width, gc.height))

            -- Draw the black border around the canvas
            gc.color = app.theme.color.editor_sprite_border
            gc:strokeRect(Rectangle(destinationBounds.x - 1,
                                    destinationBounds.y - 1,
                                    destinationBounds.width + 2,
                                    destinationBounds.height + 2))

            -- Draw the shadow under the canvas
            gc.color = app.theme.color.editor_sprite_bottom_border
            gc:fillRect(Rectangle(destinationBounds.x - 1,
                                  destinationBounds.y + destinationBounds.height +
                                      1, destinationBounds.width + 2, 1))

            -- Draw the canvas
            gc:drawImage(image, image.bounds, destinationBounds)
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
            local newScale = scale - ev.deltaY
            if newScale == 0 then
                if scale == 1 then
                    newScale = -1
                else
                    newScale = 1
                end
            end

            local oldAdjustedScale = AdjustScale(scale)
            local newAdjustedScale = AdjustScale(newScale)

            local oldWidth = image.width * oldAdjustedScale
            local newWidth = image.width * newAdjustedScale
            local oldHeight = image.height * oldAdjustedScale
            local newHeight = image.height * newAdjustedScale

            imagePositionDelta.x =
                imagePositionDelta.x - (newWidth - oldWidth) / 2
            imagePositionDelta.y = imagePositionDelta.y -
                                       (newHeight - oldHeight) / 2

            scale = newScale
            dialog:repaint()
        end
    } --

    return RepaintImage
end

return PreviewCanvas
