local ColorContext = dofile("../ColorContext.lua")
local PixelCache = dofile("../PixelCache.lua")

local OutlineLiveMode = {canExtend = true}

local sqrt = math.sqrt

local function Distance(x, y, x2, y2) return sqrt((x - x2) ^ 2 + (y - y2) ^ 2) end

local function IsErasing(change, sprite)
    if app.tool.id == "eraser" then return true end

    local colorContext = ColorContext(sprite)

    if change.leftPressed then
        return colorContext.IsTransparent(app.fgColor)
    elseif change.rightPressed then
        return colorContext.IsTransparent(app.bgColor)
    end

    return false
end

function OutlineLiveMode:Process(change, sprite, cel, parameters)
    local isErasing = IsErasing(change, sprite)
    if isErasing and not parameters.outlineErasingEnable then return end

    local color = parameters.outlineColor

    local selection = sprite.selection
    local InSelection
    if selection.isEmpty then
        InSelection = function() return true end
    else
        local constains = selection.contains
        InSelection = function(x, y) return constains(selection, x, y) end
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

    local colorContext = ColorContext(sprite)
    local IsTransparentValue, Equals, Create = colorContext.IsTransparentValue,
                                               colorContext.Equals,
                                               colorContext.Create

    local GetPixel = pixelCache.GetPixel
    local SetPixel = outlinePixelCache.SetPixel

    if isErasing then
        for _, pixel in ipairs(change.pixels) do
            local x = pixel.x - cx + dpx
            local y = pixel.y - cy + dpy

            local isOutline = false

            for dx = -outlineSize, outlineSize do
                for dy = -outlineSize, outlineSize do
                    local nx, ny = x + dx, y + dy

                    if (nx >= 0 and nx < width and ny >= 0 and y + dy < height) and
                        InSelection(pixel.x + dx, pixel.y + dy) and
                        Distance(x, y, nx, ny) <= outlineSize * 1.2 then
                        local pixelValue = GetPixel(pixelCache, nx, ny)

                        if not IsTransparentValue(pixelValue) and
                            not Equals(Create(pixelValue), color) then
                            SetPixel(outlinePixelCache, x, y, true)

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
            local x = pixel.x - cx + dpx
            local y = pixel.y - cy + dpy

            for dx = -outlineSize, outlineSize do
                for dy = -outlineSize, outlineSize do
                    local nx, ny = x + dx, y + dy

                    if InSelection(pixel.x + dx, pixel.y + dy) and
                        Distance(x, y, nx, ny) <= outlineSize * 1.2 then
                        local pixelValue = GetPixel(pixelCache, nx, ny)

                        if parameters.outlineOtherColors then
                            if not Equals(Create(pixelValue), pixel.newColor) then
                                SetPixel(outlinePixelCache, nx, ny, true)
                            end
                        else
                            if IsTransparentValue(pixelValue) then
                                SetPixel(outlinePixelCache, nx, ny, true)
                            end
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
