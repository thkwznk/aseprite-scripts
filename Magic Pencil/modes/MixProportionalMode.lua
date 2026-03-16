local MixProportionalMode = dofile("./MixModeBase.lua")
local insert = table.insert

function MixProportionalMode:_GetColors(pixels)
    local colors = {}

    local color
    for _, pixel in ipairs(pixels) do
        color = pixel.color
        if color and color.alpha == 255 then insert(colors, color) end
    end

    return colors
end

return MixProportionalMode
