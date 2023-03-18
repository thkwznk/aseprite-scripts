local OutlineLiveMode = {canExtend = true}

function OutlineLiveMode:Process(change, sprite, cel, parameters)
    local color = parameters.outlineColor.rgbaPixel

    local selection = sprite.selection
    local extend = {}

    for _, pixel in ipairs(change.pixels) do
        local ix = pixel.x - app.activeCel.bounds.x
        local iy = pixel.y - app.activeCel.bounds.y

        if ix == 0 then extend.left = true end
        if ix == app.activeCel.image.width - 1 then extend.right = true end
        if iy == 0 then extend.up = true end
        if iy == app.activeCel.image.height - 1 then extend.down = true end
    end

    local width = app.activeCel.image.width
    local height = app.activeCel.image.height

    if extend.left then width = width + 1 end
    if extend.right then width = width + 1 end
    if extend.up then height = height + 1 end
    if extend.down then height = height + 1 end

    local newImage = Image(width, height)

    local dpx = If(extend.left, 1, 0)
    local dpy = If(extend.up, 1, 0)

    newImage:drawImage(app.activeCel.image, Point(dpx, dpy))

    local CanOutline = function(x, y)
        return selection.isEmpty or
                   (not selection.isEmpty and selection:contains(x, y))
    end

    local getPixel, drawPixel = newImage.getPixel, newImage.drawPixel

    for _, pixel in ipairs(change.pixels) do
        local ix = pixel.x - app.activeCel.bounds.x + dpx
        local iy = pixel.y - app.activeCel.bounds.y + dpy

        if CanOutline(pixel.x - 1, pixel.y) then
            if getPixel(newImage, ix - 1, iy) == 0 then
                drawPixel(newImage, ix - 1, iy, color)
            end
        end

        if CanOutline(pixel.x + 1, pixel.y) then
            if getPixel(newImage, ix + 1, iy) == 0 then
                drawPixel(newImage, ix + 1, iy, color)
            end
        end

        if CanOutline(pixel.x, pixel.y - 1) then
            if getPixel(newImage, ix, iy - 1) == 0 then
                drawPixel(newImage, ix, iy - 1, color)
            end
        end

        if CanOutline(pixel.x, pixel.y + 1) then
            if getPixel(newImage, ix, iy + 1) == 0 then
                drawPixel(newImage, ix, iy + 1, color)
            end
        end
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(app.activeCel.position.x - dpx,
                                   app.activeCel.position.y - dpy)
end

return OutlineLiveMode
