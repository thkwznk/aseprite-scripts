local MixProportionalMode = dofile("./MixModeBase.lua")

function MixProportionalMode:_GetColors(pixels)
    local colors = {}
    local ci = 0
    local color
    for _, pixel in ipairs(pixels) do
        color = pixel.color
        if color and color.alpha == 255 then
            ci = ci + 1
            colors[ci] = color
        end
    end

    return colors
end

return MixProportionalMode
