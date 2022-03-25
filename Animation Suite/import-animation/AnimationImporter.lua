local AnimationImporter = {sprite = nil, layer = nil, fromFrame = nil}

function AnimationImporter:Init(sprite, layer, fromFrame)
    self.sprite = sprite
    self.layer = layer
    self.fromFrame = fromFrame
end

function AnimationImporter:Import(imageProvider, positionCalculator)
    if self.sprite == nil or self.layer == nil or self.fromFrame == nil then
        return
    end

    local frameNumber = self.fromFrame

    app.transaction(function()
        local imageProviderIterator = imageProvider:GetImagesIterator()

        for x, y in positionCalculator:GetPositions() do
            local image = imageProviderIterator()
            self:_ImportFrame(image, x, y, frameNumber)

            frameNumber = frameNumber + 1
        end
    end)
    app.refresh()

    return frameNumber - 1
end

function AnimationImporter:_ImportFrame(image, x, y, frameNumber)
    if frameNumber > #self.sprite.frames then self.sprite:newEmptyFrame() end

    -- Shift position to align with the preview
    local position = Point(x - (image.width / 2), y - (image.height / 2))

    local originalCel = self.layer:cel(frameNumber)
    if originalCel ~= nil then
        image, position = self:_MergeImages(originalCel.image,
                                            originalCel.position, image,
                                            position)
    end

    self.sprite:newCel(self.layer, frameNumber, image, position)
end

function AnimationImporter:_MergeImages(imageA, positionA, imageB, positionB)
    local minX = math.min(positionA.x, positionB.x)
    local minY = math.min(positionA.y, positionB.y)

    local maxX =
        math.max(positionA.x + imageA.width, positionB.x + imageB.width)
    local maxY = math.max(positionA.y + imageA.height,
                          positionB.y + imageB.height)

    local newImage = Image(maxX - minX, maxY - minY)
    local newPosition = Point(minX, minY)

    newImage:drawImage(imageA, Point(positionA.x - minX, positionA.y - minY))
    self:_DrawImageOver(newImage, imageB,
                        Point(positionB.x - minX, positionB.y - minY))

    return newImage, newPosition
end

function AnimationImporter:_DrawImageOver(backgroundImage, image, position)
    -- TODO: Could be calculated only for the common part
    for pixel in image:pixels() do
        local pixelValue = pixel()
        local pixelColor = Color(pixelValue)

        local x = position.x + pixel.x
        local y = position.y + pixel.y

        local backgroundPixelValue = backgroundImage:getPixel(x, y)
        local backgroundColor = Color(backgroundPixelValue)

        if backgroundColor.alpha == 0 then
            backgroundImage:drawPixel(x, y, pixelValue)
        else
            local backgroundAlpha = (backgroundColor.alpha / 255)
            local pixelAlpha = (pixelColor.alpha / 255)

            local finalAlpha = backgroundColor.alpha + pixelColor.alpha -
                                   (backgroundAlpha * pixelAlpha * 255)

            local backgroundRed = backgroundColor.red * backgroundAlpha
            local backgroundGreen = backgroundColor.green * backgroundAlpha
            local backgroundBlue = backgroundColor.blue * backgroundAlpha

            local pixelRed = pixelColor.red * pixelAlpha
            local pixelGreen = pixelColor.green * pixelAlpha
            local pixelBlue = pixelColor.blue * pixelAlpha

            local pixelOpaqueness = ((255 - pixelColor.alpha) / 255)

            local finalRed = pixelRed + backgroundRed * pixelOpaqueness
            local finalGreen = pixelGreen + backgroundGreen * pixelOpaqueness
            local finalBlue = pixelBlue + backgroundBlue * pixelOpaqueness

            backgroundImage:drawPixel(x, y, Color {
                r = finalRed / (finalAlpha / 255),
                g = finalGreen / (finalAlpha / 255),
                b = finalBlue / (finalAlpha / 255),
                a = finalAlpha
            })
        end
    end
end

return AnimationImporter
