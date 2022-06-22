local ImageProcessor = {}

function ImageProcessor:CalculateScale(image)
    -- First, go throught each row - look for the narrowest part that doesn't change color
    local narrowest = image.width

    for y = 0, image.height - 1 do
        local lastColor = image:getPixel(0, y)
        local currentWidth = 1

        for x = 1, image.width - 1 do
            local currentColor = image:getPixel(x, y)

            if currentColor == lastColor then
                currentWidth = currentWidth + 1
            else
                if currentWidth < narrowest then
                    narrowest = currentWidth
                end

                currentWidth = 1
            end

            lastColor = currentColor
        end
    end

    -- Second, go throught each column - look for the shortest part that doesn't change color
    local shortest = image.height

    for x = 1, image.width - 1, narrowest do
        local lastColor = image:getPixel(x, 0)
        local currentHeight = 1

        for y = 0, image.height - 1 do

            local currentColor = image:getPixel(x, y)

            if currentColor == lastColor then
                currentHeight = currentHeight + 1
            else
                if currentHeight < shortest then
                    shortest = currentHeight
                end

                lastColor = currentColor
                currentHeight = 1
            end
        end
    end

    return narrowest, shortest
end

function ImageProcessor:GetImagePart(image, rectangle)
    local imagePart = Image(rectangle.width, rectangle.height)

    for pixel in image:pixels(rectangle) do
        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            pixel())
    end

    return imagePart
end

return ImageProcessor
