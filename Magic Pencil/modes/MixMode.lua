local MixMode = dofile("./MixModeBase.lua")

local function Contains(collection, expectedValue)
    for _, value in ipairs(collection) do
        if value == expectedValue then return true end
    end
end

function MixMode:_GetColors(pixels)
    local colors = {}

    for _, pixel in ipairs(pixels) do
        if pixel.color and pixel.color.alpha == 255 then
            if not Contains(colors, pixel.color) then
                table.insert(colors, pixel.color)
            end
        end
    end

    return colors
end

return MixMode
