local OutlineLiveMode = {canExtend = true}

function OutlineLiveMode:Process(change, sprite, cel, parameters)
    local color = parameters.outlineColor

    local selection = sprite.selection
    local extend = {}

    local outlineSize = parameters.outlineSize

    local cx, cy = app.activeCel.position.x, app.activeCel.position.y
    local width, height = app.activeCel.image.width, app.activeCel.image.height
    local getPixel, drawPixel = cel.image.getPixel, cel.image.drawPixel

    local pixelCache = {}
    local getPixelCached = function(image, x, y)
        if pixelCache[x] then
            if pixelCache[x][y] then return pixelCache[x][y] end
        else
            pixelCache[x] = {}
        end

        pixelCache[x][y] = getPixel(image, x, y)
        return pixelCache[x][y]
    end

    local outlinePixelCache = {}

    local drawOutline = function(x, y)
        if not outlinePixelCache[x] then outlinePixelCache[x] = {} end

        outlinePixelCache[x][y] = true
    end

    for _, pixel in ipairs(change.pixels) do
        local ix = pixel.x - cx
        local iy = pixel.y - cy

        if ix <= outlineSize - 1 then extend.left = true end
        if ix >= width - outlineSize then extend.right = true end
        if iy <= outlineSize - 1 then extend.up = true end
        if iy >= height - outlineSize then extend.down = true end
    end

    if extend.left then width = width + outlineSize end
    if extend.right then width = width + outlineSize end
    if extend.up then height = height + outlineSize end
    if extend.down then height = height + outlineSize end

    local newImage = Image(width, height, cel.sprite.colorMode)

    local dpx = extend.left and outlineSize or 0
    local dpy = extend.up and outlineSize or 0

    newImage:drawImage(app.activeCel.image, Point(dpx, dpy))

    local CanOutline = function(x, y)
        return selection.isEmpty or
                   (not selection.isEmpty and selection:contains(x, y))
    end

    local d = function(x, y, x2, y2)
        return math.sqrt((x - x2) ^ 2 + (y - y2) ^ 2)
    end

    -- TODO: Optimize image read/write

    local isErasing = app.tool.id == "eraser"

    if cel.sprite.colorMode == "RGB" then
        if app.fgColor.rgbaPixel == 0 then isErasing = true end
    else
        if app.fgColor.index == 0 then isErasing = true end
    end

    if isErasing then
        for _, pixel in ipairs(change.pixels) do
            local ix = pixel.x - cx + dpx
            local iy = pixel.y - cy + dpy

            local isOutline = false

            for xx = -outlineSize, outlineSize do
                for yy = -outlineSize, outlineSize do
                    if CanOutline(pixel.x + xx, pixel.y + yy) and
                        d(ix, iy, ix + xx, iy + yy) <= outlineSize * 1.2 then
                        local pixelValue =
                            getPixelCached(newImage, ix + xx, iy + yy)

                        if pixelValue ~= 0 then
                            drawOutline(ix, iy)

                            isOutline = true
                            break
                        end
                    end
                end

                if isOutline then break end
            end
        end
    else
        for _, pixel in ipairs(change.pixels) do
            local ix = pixel.x - cx + dpx
            local iy = pixel.y - cy + dpy

            for xx = -outlineSize, outlineSize do
                for yy = -outlineSize, outlineSize do
                    if CanOutline(pixel.x + xx, pixel.y + yy) and
                        d(ix, iy, ix + xx, iy + yy) <= outlineSize * 1.2 then
                        local pixelValue =
                            getPixelCached(newImage, ix + xx, iy + yy)

                        if pixelValue == 0 then
                            drawOutline(ix + xx, iy + yy)
                        end
                    end
                end
            end
        end
    end

    for x, column in pairs(outlinePixelCache) do
        for y, _ in pairs(column) do drawPixel(newImage, x, y, color) end
    end

    app.activeCel.image = newImage
    app.activeCel.position = Point(cx - dpx, cy - dpy)
end

return OutlineLiveMode
