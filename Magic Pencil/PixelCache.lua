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

return PixelCache
