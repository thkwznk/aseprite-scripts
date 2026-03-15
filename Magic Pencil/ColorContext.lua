local rgbaA = app.pixelColor.rgbaA
local sqrt = math.sqrt

local function Distance(a, b)
    return sqrt((a.red - b.red) ^ 2 + (a.green - b.green) ^ 2 +
                    (a.blue - b.blue) ^ 2 + (a.alpha - b.alpha) ^ 2)
end

return function(sprite)
    if sprite and sprite.colorMode ~= ColorMode.RGB then
        return {
            IsTransparent = function(color) return color.index == 0 end,
            IsTransparentValue = function(value) return value == 0 end,
            Create = function(value) return Color {index = value} end,
            Copy = function(color) return Color {index = color.index} end,
            Compare = function(a, b) return a.index == b.index end,
            Equals = function(a, b) return a.index == b.index end,
            Distance = Distance
        }
    end

    return {
        IsTransparent = function(color) return color.alpha == 0 end,
        IsTransparentValue = function(value) return rgbaA(value) == 0 end,
        Create = function(value) return Color(value) end,
        Copy = function(color) return Color(color.rgbaPixel) end,
        Compare = function(a, b)
            return a.red == b.red and a.green == b.green and a.blue == b.blue
        end,
        Equals = function(a, b) return a.rgbaPixel == b.rgbaPixel end,
        Distance = Distance
    }
end
