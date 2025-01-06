local Mode = {
    Regular = "RegularMode",
    Graffiti = "GraffitiMode",
    Outline = "OutlineMode",
    OutlineLive = "OutlineLiveMode",
    Cut = "CutMode",
    Selection = "SelectionMode",
    Yeet = "YeetMode",
    Mix = "MixMode",
    MixProportional = "MixProportionalMode",
    Colorize = "ColorizeMode",
    Desaturate = "DesaturateMode",
    ShiftHsvHue = "ShiftHsvHueMode",
    ShiftHsvSaturation = "ShiftHsvSaturationMode",
    ShiftHsvValue = "ShiftHsvValueMode",
    ShiftHslHue = "ShiftHslHueMode",
    ShiftHslSaturation = "ShiftHslSaturationMode",
    ShiftHslLightness = "ShiftHslLightnessMode",
    ShiftRgbRed = "ShiftRgbRedMode",
    ShiftRgbGreen = "ShiftRgbGreenMode",
    ShiftRgbBlue = "ShiftRgbBlueMode"
}

Mode.ToHsvMap = {
    [Mode.ShiftHslHue] = Mode.ShiftHsvHue,
    [Mode.ShiftHslSaturation] = Mode.ShiftHsvSaturation,
    [Mode.ShiftHslLightness] = Mode.ShiftHsvValue,

    [Mode.ShiftRgbRed] = Mode.ShiftHsvHue,
    [Mode.ShiftRgbGreen] = Mode.ShiftHsvSaturation,
    [Mode.ShiftRgbBlue] = Mode.ShiftHsvValue
}

Mode.ToHslMap = {
    [Mode.ShiftHsvHue] = Mode.ShiftHslHue,
    [Mode.ShiftHsvSaturation] = Mode.ShiftHslSaturation,
    [Mode.ShiftHsvValue] = Mode.ShiftHslLightness,

    [Mode.ShiftRgbRed] = Mode.ShiftHslHue,
    [Mode.ShiftRgbGreen] = Mode.ShiftHslSaturation,
    [Mode.ShiftRgbBlue] = Mode.ShiftHslLightness
}

Mode.ToRgbMap = {
    [Mode.ShiftHsvHue] = Mode.ShiftRgbRed,
    [Mode.ShiftHsvSaturation] = Mode.ShiftRgbGreen,
    [Mode.ShiftHsvValue] = Mode.ShiftRgbBlue,

    [Mode.ShiftHslHue] = Mode.ShiftRgbRed,
    [Mode.ShiftHslSaturation] = Mode.ShiftRgbGreen,
    [Mode.ShiftHslLightness] = Mode.ShiftRgbBlue
}

return Mode
