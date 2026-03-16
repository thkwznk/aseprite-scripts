local MixMode = dofile("./MixModeBase.lua")
local insert = table.insert

local function Contains(collection, expectedValue)
    for _, value in ipairs(collection) do
        if value == expectedValue then return true end
    end
end

function MixMode:_GetColors(pixels)
    local colors = {}

    local color
    for _, pixel in ipairs(pixels) do
        color = pixel.color
        if color and color.alpha == 255 then
            if not Contains(colors, color) then insert(colors, color) end
        end
    end

    return colors
end

return MixMode
