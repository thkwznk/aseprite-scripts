local function ZoomValue(fraction, percentage)
    return {fraction = fraction, percentage = percentage}
end

local ZoomValues = {
    ZoomValue(64, "6400"), ZoomValue(48, "4800"), ZoomValue(32, "3200"),
    ZoomValue(24, "2400"), ZoomValue(16, "1600"), ZoomValue(12, "1200"),
    ZoomValue(8, "800"), ZoomValue(6, "600"), ZoomValue(5, "500"),
    ZoomValue(4, "400"), ZoomValue(3, "300"), ZoomValue(2, "200"),
    ZoomValue(1, "100"), ZoomValue(0.5, "50"), ZoomValue(0.333, "33.3"),
    ZoomValue(0.25, "25"), ZoomValue(0.20, "20"), ZoomValue(0.167, "16.7"),
    ZoomValue(0.125, "12.5")
}

local function ZoomOnBounds(bounds)
    local width = bounds.width
    local height = bounds.height
    local maxWidth = app.window.width * 0.8
    local maxHeight = app.window.height * 0.6

    for _, zoom in ipairs(ZoomValues) do
        local fraction = zoom.fraction
        if (width * fraction < maxWidth) and (height * fraction < maxHeight) then
            app.command.Zoom {percentage = zoom.percentage, focus = "center"}
            break
        end
    end
end

local function ScrollToSliceV30(slice, autoZoom)
    local bounds = slice.bounds

    -- Avoid using "zoomed-pixel" as its doesnt't work if zoom is less than 100%
    local zoom = app.editor.zoom

    local editorScrollX = app.editor.scroll.x
    local editorScrollY = app.editor.scroll.y

    local sliceCenterX = bounds.x + bounds.width / 2
    local sliceCenterY = bounds.y + bounds.height / 2

    if sliceCenterX < editorScrollX then
        app.command.Scroll {
            direction = "left",
            units = "pixel",
            quantity = tostring((editorScrollX - sliceCenterX) * zoom)
        }
    else
        app.command.Scroll {
            direction = "right",
            units = "pixel",
            quantity = tostring((sliceCenterX - editorScrollX) * zoom)
        }
    end

    if sliceCenterY < editorScrollY then
        app.command.Scroll {
            direction = "up",
            units = "pixel",
            quantity = tostring((editorScrollY - sliceCenterY) * zoom)
        }
    else
        app.command.Scroll {
            direction = "down",
            units = "pixel",
            quantity = tostring((sliceCenterY - editorScrollY) * zoom)
        }
    end

    if autoZoom then ZoomOnBounds(bounds) end
end

return function(slice, autoZoom)
    if app.apiVersion >= 30 then
        ScrollToSliceV30(slice, autoZoom)
        return
    end

    local bounds = slice.bounds

    -- If auto zooming reset the zoom first to avoid using "zoomed-pixel" units
    -- TODO: When API will allow for getting information about the zoom do this for every attempt and restore zoom level
    if autoZoom then app.command.Zoom {percentage = "100", focus = "center"} end

    -- Center the canvas first
    app.command.ScrollCenter()

    local sliceCenterX = bounds.x + bounds.width / 2
    local sliceCenterY = bounds.y + bounds.height / 2

    local centerX = slice.sprite.width / 2
    local centerY = slice.sprite.height / 2

    -- "zoomed-pixel" don't work if zoom is less than 100% 
    local units = autoZoom and "pixel" or "zoomed-pixel"

    if sliceCenterX < centerX then
        app.command.Scroll {
            direction = "left",
            units = units,
            quantity = tostring(centerX - sliceCenterX)
        }
    else
        app.command.Scroll {
            direction = "right",
            units = units,
            quantity = tostring(sliceCenterX - centerX)
        }
    end

    if sliceCenterY < centerY then
        app.command.Scroll {
            direction = "up",
            units = units,
            quantity = tostring(centerY - sliceCenterY)
        }
    else
        app.command.Scroll {
            direction = "down",
            units = units,
            quantity = tostring(sliceCenterY - centerY)
        }
    end

    if autoZoom then ZoomOnBounds(bounds) end
end
