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

local PreviewCanvas = function(dialog, width, height, sprite, image)
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

            DrawGrid(gc, sprite)

            local destinationBounds = Rectangle(
                                          imagePositionDelta.x +
                                              (gc.width - image.width) / 2,
                                          imagePositionDelta.y +
                                              (gc.height - image.height) / 2,
                                          image.width * scale,
                                          image.height * scale)

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
            local newScale = math.max(scale - ev.deltaY, 1)

            local oldWidth = image.width * scale
            local newWidth = image.width * newScale
            local oldHeight = image.height * scale
            local newHeight = image.height * newScale

            imagePositionDelta.x =
                imagePositionDelta.x - (newWidth - oldWidth) / 2
            imagePositionDelta.y = imagePositionDelta.y -
                                       (newHeight - oldHeight) / 2

            scale = newScale
            dialog:repaint()
        end
    } --

end

return PreviewCanvas
