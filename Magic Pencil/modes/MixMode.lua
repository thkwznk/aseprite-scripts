local MixMode = dofile("./MixModeBase.lua")

local function Contains(collection, expectedValue)
    for _, value in ipairs(collection) do
        if value == expectedValue then return true end
    end
end

function MixMode:_GetColors(pixels)
    local colors = {}
    local ci = 0
    local color
    for _, pixel in ipairs(pixels) do
        color = pixel.color
        if color and color.alpha == 255 then
            if not Contains(colors, color) then
                ci = ci + 1
                colors[ci] = color
            end
        end
    end

    return colors
end

return MixMode
