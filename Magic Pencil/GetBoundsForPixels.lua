return function(pixels)
    if pixels and #pixels == 0 then return end

    local minX, maxX = pixels[1].x, pixels[1].x
    local minY, maxY = pixels[1].y, pixels[1].y

    for _, pixel in ipairs(pixels) do
        minX = math.min(minX, pixel.x)
        maxX = math.max(maxX, pixel.x)

        minY = math.min(minY, pixel.y)
        maxY = math.max(maxY, pixel.y)
    end

    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end
