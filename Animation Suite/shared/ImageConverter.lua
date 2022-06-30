local ImageConverter = {}

function ImageConverter:Flip(sourceImage, flipHorizontal, flipVertical)
    local flippedImage = Image(sourceImage.spec)

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()
        local x = flipHorizontal and (sourceImage.width - 1 - pixel.x) or
                      pixel.x
        local y = flipVertical and (sourceImage.height - 1 - pixel.y) or pixel.y

        flippedImage:drawPixel(x, y, pixelValue)
    end

    return flippedImage
end

function ImageConverter:Convert(sourceImage, sourcePalette, targetPalette,
                                targetColorMode)
    if sourceImage.colorMode == targetColorMode then return sourceImage end

    if sourceImage.colorMode == ColorMode.RGB then
        if targetColorMode == ColorMode.GRAY then
            return self:ConvertRGBToGray(sourceImage)
        elseif targetColorMode == ColorMode.INDEXED then
            return self:ConvertRGBToIndexed(sourceImage, targetPalette)
        end
    end

    if sourceImage.colorMode == ColorMode.INDEXED then
        return
            self:ConvertIndexedTo(sourceImage, sourcePalette, targetColorMode)
    end

    if sourceImage.colorMode == ColorMode.GRAY then
        if targetColorMode == ColorMode.RGB then
            return self:ConvertGrayToRGB(sourceImage)
        elseif targetColorMode == ColorMode.INDEXED then
            return self:ConvertGrayToIndexed(sourceImage, targetPalette)
        end
    end
end

function ImageConverter:ConvertRGBToGray(sourceImage)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.GRAY)

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()
        convertedImage:drawPixel(pixel.x, pixel.y, Color {
            r = app.pixelColor.rgbaR(pixelValue),
            g = app.pixelColor.rgbaG(pixelValue),
            b = app.pixelColor.rgbaB(pixelValue),
            a = app.pixelColor.rgbaA(pixelValue)
        })
    end

    return convertedImage
end

function ImageConverter:ConvertRGBToIndexed(sourceImage, targetPalette)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.INDEXED)

    local cache = {}

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()

        if cache[pixelValue] == nil then
            local r = app.pixelColor.rgbaR(pixelValue)
            local g = app.pixelColor.rgbaG(pixelValue)
            local b = app.pixelColor.rgbaB(pixelValue)
            local a = app.pixelColor.rgbaA(pixelValue)
            cache[pixelValue] = self:_GetClosestColorFromPalette(r, g, b, a,
                                                                 targetPalette)
        end

        convertedImage:drawPixel(pixel.x, pixel.y, cache[pixelValue])
    end

    return convertedImage
end

function ImageConverter:ConvertIndexedTo(sourceImage, sourcePalette,
                                         targetColorMode)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 targetColorMode)

    for pixel in sourceImage:pixels() do
        local paletteIndex = pixel()
        convertedImage:drawPixel(pixel.x, pixel.y,
                                 sourcePalette:getColor(paletteIndex))
    end

    return convertedImage
end

function ImageConverter:ConvertGrayToRGB(sourceImage)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.RGB)

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()
        convertedImage:drawPixel(pixel.x, pixel.y, Color {
            gray = app.pixelColor.grayaV(pixelValue),
            alpha = app.pixelColor.grayaA(pixelValue)
        })
    end

    return convertedImage
end

function ImageConverter:ConvertGrayToIndexed(sourceImage, targetPalette)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.INDEXED)

    local cache = {}

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()

        if cache[pixelValue] == nil then
            local v = app.pixelColor.grayaV(pixelValue)
            local a = app.pixelColor.grayaA(pixelValue)
            cache[pixelValue] = self:_GetClosestGrayFromPalette(v, a,
                                                                targetPalette)
        end

        convertedImage:drawPixel(pixel.x, pixel.y, cache[pixelValue])
    end

    return convertedImage
end

-- Color.index doesn't work here, most probably due to the image being from another sprite
function ImageConverter:_GetClosestColorFromPalette(r, g, b, a, palette)
    local resultIndex = 1
    local closestValue = math.maxinteger

    for i = 0, #palette - 1 do
        local color = palette:getColor(i)
        local diff = (r - color.red) ^ 2 + (g - color.green) ^ 2 +
                         (b - color.blue) ^ 2 + (a - color.alpha) ^ 2

        if diff < closestValue then
            closestValue = diff
            resultIndex = i
        end
    end

    return resultIndex
end

function ImageConverter:_GetClosestGrayFromPalette(g, a, palette)
    local resultIndex = 0
    local closestValue = math.maxinteger

    for i = 0, #palette - 1 do
        local color = palette:getColor(i)
        local diff = (g - color.gray) ^ 2 + (a - color.alpha) ^ 2

        if diff < closestValue then
            closestValue = diff
            resultIndex = i
        end
    end

    return resultIndex
end

return ImageConverter
