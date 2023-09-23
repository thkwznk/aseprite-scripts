local ColorConverter = {}

function ColorConverter:ColorToOkhsv(color)
    -- TODO: Implement
    return {
        h = color.hue,
        s = color.saturation,
        v = color.value,
        a = color.alpha
    }
end

function ColorConverter:OkhsvToColor(okhsvColor)
    -- TODO: Implement
    return Color {
        hue = okhsvColor.h,
        saturation = okhsvColor.s,
        value = okhsvColor.v,
        alpha = okhsvColor.a
    }
end

function ColorConverter:ColorToOkhsl(color)
    -- TODO: Implement
    return {
        h = color.hslHue,
        s = color.hslSaturation,
        l = color.hslLightness,
        a = color.alpha
    }
end

function ColorConverter:OkhslToColor(okhslColor)
    -- TODO: Implement
    return Color {
        hue = okhslColor.h,
        saturation = okhslColor.s,
        lightness = okhslColor.l,
        alpha = okhslColor.a
    }
end

return ColorConverter
