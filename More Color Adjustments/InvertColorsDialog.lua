dofile("./ok_color.lua")
local ColorConverter = dofile('./ColorConverter.lua')

local InvertMode = {Hue = "Hue", Saturation = "Saturation", Value = "Value"}

function HueDifference(a, b)
    local smallerValue = math.min(a, b)
    local biggerValue = math.max(a, b)

    return
        math.min(biggerValue - smallerValue, 360 + smallerValue - biggerValue)
end

function LerpColor(a, b, tt)
    return Color {
        hue = a.hue * (1 - tt) + b.hue * tt,
        saturation = a.saturation * (1 - tt) + b.saturation * tt,
        value = a.value * (1 - tt) + b.value * tt,
        -- hue = a.hslHue * (1 - tt) + b.hslHue * tt,
        -- saturation = a.hslSaturation * (1 - tt) + b.hslSaturation * tt,
        -- lightness = a.hslLightness * (1 - tt) + b.hslLightness * tt,
        -- red = a.red * (1 - tt) + b.red * tt,
        -- green = a.green * (1 - tt) + b.green * tt,
        -- blue = a.blue * (1 - tt) + b.blue * tt,
        alpha = 255
    }
    -- a * (1 - t) + b * t
end

-- local srgb = {
--     r = pixelColor.red / 255.0,
--     g = pixelColor.green / 255.0,
--     b = pixelColor.blue / 255.0
-- }
-- local oklab = ok_color.srgb_to_oklab(srgb)
-- -- local okhsx = ok_color.oklab_to_okhsv(oklab)

-- -- local okhsvNew = {
-- --     h = okhsx.h + 0.5,
-- --     s = okhsx.s,
-- --     v = okhsx.v
-- -- }
-- -- local oklabNew = ok_color.okhsv_to_oklab(okhsvNew)

-- -- local srgbNew = ok_color.oklab_to_srgb(oklabNew)

-- -- print(oklab.a, oklab.b)

-- local t = oklab.a
-- oklab.a = oklab.b
-- oklab.b = t

-- local srgbNew = ok_color.oklab_to_srgb(oklab)
-- local b255n = math.floor(math.min(
--                              math.max(srgbNew.b, 0.0),
--                              1.0) * 255 + 0.5)
-- local g255n = math.floor(math.min(
--                              math.max(srgbNew.g, 0.0),
--                              1.0) * 255 + 0.5)
-- local r255n = math.floor(math.min(
--                              math.max(srgbNew.r, 0.0),
--                              1.0) * 255 + 0.5)

-- pixelColor.red = r255n
-- pixelColor.green = g255n
-- pixelColor.blue = b255n

-- 81 162 16 = 121.64
-- 37 74  7  = 55.53

-- 55.53 / 121.64 = 0.4565
-- 

function GetLight(pixelColor)
    return pixelColor.red * 0.3 + pixelColor.green * 0.59 + pixelColor.blue *
               0.11
    -- return pixelColor.red * 0.35 + pixelColor.green * 0.5 + pixelColor.blue *
    --            0.15
end

function DarkenColor(c, v)
    local l = GetLight(c) -- current light
    -- v -- expected light
    local d = v / l

    local nc = Color(c)

    while true do
        local nl = GetLight(nc)

        if math.abs(nl - v) <= 3 then break end

        if nl > v then
            nc.hslLightness = nc.hslLightness - 0.01
        else
            nc.hslLightness = nc.hslLightness + 0.01
        end

        if nc.hslLightness <= 0 or nc.hslLightness >= 1 then break end

    end

    -- nc.hslLightness = c.hslLightness - ((l - v) / 255)

    return nc

    -- return Color {
    --     red = c.red * d,
    --     green = c.green * d,
    --     blue = c.blue * d,
    --     alpha = c.alpha
    -- }
end

local InvertCelHSV = function(cel, mode)
    if not cel.layer.isEditable then return end

    local selection = cel.sprite.selection
    local image = cel.image
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local resultImage = Image(image)

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if selection.isEmpty or
                selection:contains(cel.position.x + x, cel.position.y + y) then

                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    local pixelColor = Color(pixelValue)

                    if mode == InvertMode.Hue then

                        if pixelColor.hslSaturation > 0 then
                            local key = tostring(pixelColor.rgbaPixel)

                            if cache[key] then
                                pixelColor = Color(cache[key])
                            else
                                local o = GetLight(pixelColor)

                                pixelColor.hslHue =
                                    (pixelColor.hslHue + 180) % 360

                                local maxColor = Color(pixelColor)
                                -- maxColor.hslLightness = 1.0
                                maxColor.value = 1.0

                                local minColor = Color(pixelColor)
                                -- minColor.hslLightness = 0.0
                                minColor.value = 0.0

                                local maxLum = GetLight(maxColor)
                                local minLum = GetLight(minColor)

                                print(minColor.red, minColor.green,
                                      maxColor.red, maxColor.green, minLum,
                                      maxLum)

                                pixelColor =
                                    LerpColor(minColor, maxColor, -- o / 255)
                                    (o - minLum) / (maxLum - minLum))

                                -- local ooklab =
                                --     ok_color.srgb_to_oklab({
                                --         r = pixelColor.red / 255.0,
                                --         g = pixelColor.green / 255.0,
                                --         b = pixelColor.blue / 255.0
                                --     })

                                -- pixelColor.hslHue =
                                --     (pixelColor.hslHue + 180) % 360

                                -- local noklab =
                                --     ok_color.srgb_to_oklab({
                                --         r = pixelColor.red / 255.0,
                                --         g = pixelColor.green / 255.0,
                                --         b = pixelColor.blue / 255.0
                                --     })

                                -- noklab.L = ooklab.L

                                -- local srgbNew = ok_color.oklab_to_srgb(noklab)

                                -- local b255n =
                                --     math.floor(math.min(math.max(srgbNew.b, 0.0),
                                --                         1.0) * 255 + 0.5)
                                -- local g255n =
                                --     math.floor(math.min(math.max(srgbNew.g, 0.0),
                                --                         1.0) * 255 + 0.5)
                                -- local r255n =
                                --     math.floor(math.min(math.max(srgbNew.r, 0.0),
                                --                         1.0) * 255 + 0.5)

                                -- pixelColor.red = r255n
                                -- pixelColor.green = g255n
                                -- pixelColor.blue = b255n

                                -- local o = GetLight(pixelColor)

                                -- pixelColor.hslHue =
                                --     (pixelColor.hslHue + 180) % 360

                                -- pixelColor = DarkenColor(pixelColor, o)
                                cache[key] = Color(pixelColor)
                            end

                            -- local n = GetLight(pixelColor)

                            -- local d = ((n - o) / 255)

                            -- pixelColor.hslLightness =
                            --     pixelColor.hslLightness - d
                        end

                        -- local ol = pixelColor.red * 0.3 + pixelColor.green *
                        --                0.59 + pixelColor.blue * 0.11 -- 30/59/11

                        -- local og = pixelColor.green

                        -- pixelColor.hslHue = (pixelColor.hslHue + 180) % 360

                        -- local nl = pixelColor.red * 0.3 + pixelColor.green *
                        --                0.59 + pixelColor.blue * 0.11 -- 30/59/11

                        -- local ng = pixelColor.green

                        -- -- local dl = (nl - ol) / 255
                        -- -- pixelColor.hslLightness = pixelColor.hslLightness - dl

                        -- -- local dl = ol / nl
                        -- local dl = 1 + ((ol - nl) / 255)
                        -- pixelColor.hslLightness = pixelColor.hslLightness * dl
                    elseif mode == InvertMode.Saturation then
                        -- Ignore pixels in grayscale, they always have hue=0 so they would always end up red
                        if pixelColor.saturation > 0 then
                            pixelColor.hslSaturation = 1 -
                                                           pixelColor.hslSaturation
                        end
                    elseif mode == InvertMode.Value then
                        pixelColor.hslLightness = 1 - pixelColor.hslLightness
                    end

                    drawPixel(resultImage, x, y, pixelColor)
                end
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertHSV = function(mode)
    app.transaction(function()
        for _, cel in ipairs(app.range.cels) do InvertCelHSV(cel, mode) end
    end)

    app.refresh()
end

local InvertColor = function(pixelValue, colorSpace)
    local color = Color(pixelValue)

    if colorSpace == "OKHSV" then
        local okhsv = ColorConverter:ColorToOkhsv(color)
        okhsv.h = (okhsv.h + 180) % 360
        color = ColorConverter:OkhsvToColor(okhsv)
    elseif colorSpace == "OKHSL" then
        local okhsl = ColorConverter:ColorToOkhsl(color)
        okhsl.h = (okhsl.h + 180) % 360
        color = ColorConverter:OkhslToColor(okhsl)
    end

    return color
end

local InvertCelColors = function(cel, colorSpace)
    local selection = cel.sprite.selection
    local image = cel.image
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    local resultImage = Image(image)

    local cache = {}

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if selection.isEmpty or
                selection:contains(cel.position.x + x, cel.position.y + y) then

                local pixelValue = getPixel(image, x, y)

                if pixelValue > 0 then
                    local key = tostring(pixelValue)

                    if cache[key] then
                        pixelValue = Color(cache[key])
                    else
                        pixelValue =
                            InvertColor(pixelValue, colorSpace).rgbaPixel
                        cache[key] = Color(pixelValue)
                    end

                    drawPixel(resultImage, x, y, pixelValue)
                end
            end
        end
    end

    -- Update only the image to preserve cel properties
    cel.image = resultImage
end

local InvertColors = function(colorSpace)
    app.transaction(function()
        for _, cel in ipairs(app.range.cels) do
            -- Invert colors only for the editable cels
            if cel.layer.isEditable then
                InvertCelColors(cel, colorSpace)
            end
        end
    end)

    app.refresh()
end

local InvertColorsDialog = function()
    local dialog = Dialog("Invert Colors")

    -- TODO: Implement the preview, perhaps create a common code for it?
    -- TODO: Probably I should group HSV+HSL and OKHSV+OKHSL as they produce identical results
    -- TODO: Cleanup this file

    dialog --
    :canvas{label = "Preview:", width = 100, height = 100} --
    :combobox{
        id = "colorSpace",
        label = "Color Space:",
        option = "OKHSV",
        options = {"HSV", "HSL", "OKHSV", "OKHSL"}
    } --
    :separator() --
    :button{
        text = "&OK",
        onclick = function()
            InvertColors(dialog.data.colorSpace)
            dialog:close()
        end
    } --
    :button{text = "&Cancel"}

    return dialog
end

return InvertColorsDialog
