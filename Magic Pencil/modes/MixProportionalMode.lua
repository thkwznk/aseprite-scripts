local MixProportionalMode = dofile("./MixModeBase.lua")

function MixProportionalMode:_GetColors(pixels)
    local colors = {}

    for _, pixel in ipairs(pixels) do
        if pixel.color and pixel.color.alpha == 255 then
            table.insert(colors, pixel.color)
        end
    end

    return colors
end

return MixProportionalMode
