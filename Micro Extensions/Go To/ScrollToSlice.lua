local Sizes = {
    6400, 4800, 3200, 2400, 1600, 1200, 800, 600, 500, 400, 300, 200, 100, 50,
    33.3, 25, 20, 16.7, 12.5
}

return function(slice, autoZoom)
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

    if autoZoom then
        local maxWidth, maxHeight = app.window.width * 0.8,
                                    app.window.height * 0.6

        for _, size in ipairs(Sizes) do
            local sizeFraction = size / 100

            if (bounds.width * sizeFraction < maxWidth) and
                (bounds.height * sizeFraction < maxHeight) then
                app.command.Zoom {percentage = tostring(size), focus = "center"}
                break
            end
        end
    end
end
