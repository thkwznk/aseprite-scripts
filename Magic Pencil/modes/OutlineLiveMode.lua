local ColorContext = dofile("../ColorContext.lua")

local OutlineLiveMode = {canExtend = true}

local function Distance(x, y, x2, y2)
    return math.sqrt((x - x2) ^ 2 + (y - y2) ^ 2)
end

local function IsErasing(change)
    if app.tool.id == "eraser" then return true end

    if change.leftPressed then
        return ColorContext:IsTransparent(app.fgColor)
    elseif change.rightPressed then
        return ColorContext:IsTransparent(app.bgColor)
    end

    return false
end

local function PixelCache(image)
    local getPixel = image.getPixel
    local cache = {pixels = {}}

    function cache:GetPixel(x, y)
        if self.pixels[x] then
            if self.pixels[x][y] then return self.pixels[x][y] end
        else
            self.pixels[x] = {}
        end

        self.pixels[x][y] = getPixel(image, x, y)
        return self.pixels[x][y]
    end

    function cache:SetPixel(x, y, value)
        if not self.pixels[x] then self.pixels[x] = {} end

        self.pixels[x][y] = value
    end

    return cache
end

function OutlineLiveMode:Process(change, sprite, cel, parameters)
    local color = parameters.outlineColor

    local selection = sprite.selection
    local InSelection = function(x, y)
        return selection.isEmpty or
                   (not selection.isEmpty and selection:contains(x, y))
    end

    local outlineSize = parameters.outlineSize

    local cx, cy = app.activeCel.position.x, app.activeCel.position.y
    local width = app.activeCel.image.width + outlineSize * 2
    local height = app.activeCel.image.height + outlineSize * 2

    local newImage = Image(width, height, cel.sprite.colorMode)
    local pixelCache = PixelCache(newImage)
    local outlinePixelCache = PixelCache(newImage)

    local dpx = outlineSize
    local dpy = outlineSize

    newImage:drawImage(app.activeCel.image, Point(dpx, dpy))

    if IsErasing(change) then
        for _, pixel in ipairs(change.pixels) do
            local ix = pixel.x - cx + dpx
            local iy = pixel.y - cy + dpy

            local isOutline = false

            for xx = -outlineSize, outlineSize do
                for yy = -outlineSize, outlineSize do
                    if (ix + xx >= 0 and ix + xx < width and iy + yy >= 0 and iy +
                        yy < height) and InSelection(pixel.x + xx, pixel.y + yy) and
                        Distance(ix, iy, ix + xx, iy + yy) <= outlineSize * 1.2 then
                        local pixelValue = pixelCache:GetPixel(ix + xx, iy + yy)

                        if not ColorContext:IsTransparentValue(pixelValue) and
                            not ColorContext:Equals(
                                ColorContext:Create(pixelValue), color) then
                            outlinePixelCache:SetPixel(ix, iy, true)

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
                    if InSelection(pixel.x + xx, pixel.y + yy) and
                        Distance(ix, iy, ix + xx, iy + yy) <= outlineSize * 1.2 then
                        local pixelValue = pixelCache:GetPixel(ix + xx, iy + yy)

                        if ColorContext:IsTransparentValue(pixelValue) then
                            outlinePixelCache:SetPixel(ix + xx, iy + yy, true)
                        end
                    end
                end
            end
        end
    end

    local drawPixel = newImage.drawPixel
    for x, column in pairs(outlinePixelCache.pixels) do
        for y, _ in pairs(column) do drawPixel(newImage, x, y, color) end
    end

    local shrunkBounds = newImage:shrinkBounds()
    app.activeCel.image = Image(newImage, shrunkBounds)
    app.activeCel.position = Point(cx - dpx + shrunkBounds.x,
                                   cy - dpy + shrunkBounds.y)
end

return OutlineLiveMode

-- TODO: Correctly blend (outline) colors with alpha
