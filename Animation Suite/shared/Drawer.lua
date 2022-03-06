local Drawer = {}

function Drawer:DrawDashLine(image, axis, value, color)
    local l = 4

    if axis == "X" then
        for y = 0, image.height - 1 do
            if (y % (l * 2) >= l) then
                image:drawPixel(value, y, color)
            end
        end
    end

    if axis == "Y" then
        for x = 0, image.width - 1 do
            if (x % (l * 2) >= l) then
                image:drawPixel(x, value, color)
            end
        end
    end
end

function Drawer:DrawRectangleFill(image, x, y, w, h, color)
    for nx = x, x + w - 1 do
        for ny = y, y + h - 1 do image:drawPixel(nx, ny, color) end
    end
end

function Drawer:DrawRectangle(image, x, y, w, h, color)
    for nx = x, (x + w - 1) do
        image:drawPixel(nx, y, color)
        image:drawPixel(nx, y + h - 1, color)
    end

    for ny = y, (y + h - 1) do
        image:drawPixel(x, ny, color)
        image:drawPixel(x + w - 1, ny, color)
    end
end

function Drawer:DrawCrosshair(image, x, y, color, backgroundColor)
    self:DrawRectangleFill(image, x - 2, y - 2, 5, 5, backgroundColor)
    self:DrawRectangle(image, x - 2, y - 2, 5, 5, color)

    image:drawPixel(x, y, color)
end

return Drawer
