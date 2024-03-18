function SheerImageHorizontal(image, ratio)
    local skew = image.height * ratio
    local result = Image(image.width + math.abs(skew), image.height)

    local offset = 0 -- math.abs(skew) / 2
    if skew < 0 then offset = math.abs(skew) end

    for y = 0, image.height - 1 do
        local dx = offset + y * ratio -- ((y / h) * skew) - (skew / 2)

        for x = 0, image.width - 1 do
            result:drawPixel(x + dx, y, image:getPixel(x, y))
        end
    end

    return result
end

function SheerImageVertical(image, ratio)
    local skew = image.width * ratio
    local result = Image(image.width, image.height + math.abs(skew))

    local offset = 0 -- math.abs(skew) / 2
    if skew < 0 then offset = math.abs(skew) end

    for x = 0, image.width - 1 do
        local dy = offset + x * ratio -- ((x / w) * skew) - (skew / 2)

        for y = 0, image.height - 1 do
            result:drawPixel(x, y + dy, image:getPixel(x, y))
        end
    end

    return result
end

function ThreeShearRotation(image, imageFlipped, angle)
    if angle >= math.pi / 2 and angle <= math.pi * 1.5 then
        image = imageFlipped
        angle = angle - math.pi
    end

    local skewX = -math.tan(angle / 2)
    local skewY = math.sin(angle)

    local skewedImage = SheerImageHorizontal(image, skewX)
    skewedImage = SheerImageVertical(skewedImage, skewY)
    skewedImage = SheerImageHorizontal(skewedImage, skewX)

    return skewedImage
end

return ThreeShearRotation
