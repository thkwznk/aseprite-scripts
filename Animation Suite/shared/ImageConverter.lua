local ImageConverter = {}

function ImageConverter:Convert(sourceImage, sourcePalette, targetPalette,
                                targetColorMode)
    local sourceColorMode = sourceImage.colorMode

    if sourceColorMode == targetColorMode then return sourceImage end

    if sourceColorMode == ColorMode.INDEXED and targetColorMode == ColorMode.RGB then
        return self:ConvertIndexedToRGB(sourceImage, sourcePalette)
    end

    if sourceColorMode == ColorMode.GRAY and targetColorMode == ColorMode.RGB then
        return self:ConvertGrayToRGB(sourceImage)
    end

    if sourceColorMode == ColorMode.INDEXED and targetColorMode ==
        ColorMode.GRAY then
        return self:ConvertIndexedToGray(sourceImage, sourcePalette)
    end

    if sourceColorMode == ColorMode.RGB and targetColorMode == ColorMode.GRAY then
        return self:ConvertRGBToGray(sourceImage)
    end

    if sourceColorMode == ColorMode.GRAY and targetColorMode ==
        ColorMode.INDEXED then
        return self:ConvertGrayToIndexed(sourceImage, targetPalette)
    end

    if sourceColorMode == ColorMode.RGB and targetColorMode == ColorMode.INDEXED then
        return self:ConvertRGBToIndexed(sourceImage, targetPalette)
    end
end

function ImageConverter:ConvertIndexedToRGB(sourceImage, sourcePalette)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.RGB)

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()
        convertedImage:drawPixel(pixel.x, pixel.y,
                                 sourcePalette:getColor(pixelValue))
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

function ImageConverter:ConvertIndexedToGray(sourceImage, sourcePalette)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.GRAY)

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()
        convertedImage:drawPixel(pixel.x, pixel.y,
                                 sourcePalette:getColor(pixelValue))
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
            cache[pixelValue] = self:_GetClosestColorFromPalette(app.pixelColor
                                                                     .rgbaR(
                                                                     pixelValue),
                                                                 app.pixelColor
                                                                     .rgbaG(
                                                                     pixelValue),
                                                                 app.pixelColor
                                                                     .rgbaB(
                                                                     pixelValue),
                                                                 app.pixelColor
                                                                     .rgbaA(
                                                                     pixelValue),
                                                                 targetPalette)
        end

        convertedImage:drawPixel(pixel.x, pixel.y, cache[pixelValue])
    end

    return convertedImage
end

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

function ImageConverter:ConvertGrayToIndexed(sourceImage, targetPalette)
    local convertedImage = Image(sourceImage.width, sourceImage.height,
                                 ColorMode.INDEXED)

    local cache = {}

    for pixel in sourceImage:pixels() do
        local pixelValue = pixel()

        if cache[pixelValue] == nil then
            cache[pixelValue] = self:_GetClosestGrayFromPalette(app.pixelColor
                                                                    .grayaV(
                                                                    pixelValue),
                                                                app.pixelColor
                                                                    .grayaA(
                                                                    pixelValue),
                                                                targetPalette)
        end

        convertedImage:drawPixel(pixel.x, pixel.y, cache[pixelValue])
    end

    return convertedImage
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

return ImageConverter
