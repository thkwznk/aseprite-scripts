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

    local cel = self.layer:cel(frameNumber)
    if cel ~= nil then
        image, position = self:_MergeImages(image, position, cel.image,
                                            cel.position)
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
    newImage:drawImage(imageB, Point(positionB.x - minX, positionB.y - minY))

    return newImage, newPosition
end

return AnimationImporter
