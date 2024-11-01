return function(slice, autoZoom)
    -- Center the canvas first
    app.command.ScrollCenter()

    local sliceCenterX = slice.bounds.x + slice.bounds.width / 2
    local sliceCenterY = slice.bounds.y + slice.bounds.height / 2

    local centerX = slice.sprite.width / 2
    local centerY = slice.sprite.height / 2

    if sliceCenterX < centerX then
        app.command.Scroll {
            direction = "left",
            units = "zoomed-pixel",
            quantity = tostring(centerX - sliceCenterX)
        }
    else
        app.command.Scroll {
            direction = "right",
            units = "zoomed-pixel",
            quantity = tostring(sliceCenterX - centerX)
        }
    end

    if sliceCenterY < centerY then
        app.command.Scroll {
            direction = "up",
            units = "zoomed-pixel",
            quantity = tostring(centerY - sliceCenterY)
        }
    else
        app.command.Scroll {
            direction = "down",
            units = "zoomed-pixel",
            quantity = tostring(sliceCenterY - centerY)
        }
    end

    if autoZoom then
        local sizes = {
            64, 48, 32, 24, 16, 12, 8, 6, 5, 4, 3, 2, 1, 0.5, 0.333, 0.25, 0.20,
            0.167, 0.125
        }

        for _, size in ipairs(sizes) do
            if slice.bounds.width * size < app.window.width * 0.8 and
                slice.bounds.height * size < app.window.height * 0.6 then
                app.command.Zoom {
                    percentage = tostring(size * 100),
                    focus = "center"
                }
                break
            end
        end
    end
end
