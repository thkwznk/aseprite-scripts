dofile("./DeepCopy.lua")

local function ColorFromId(colorId) return Color(tonumber(colorId)) end
local function ColorToId(color) return color and tostring(color.rgbaPixel) end

local function Contains(colorsArrayA, colorsArrayB)
    for _, colorB in ipairs(colorsArrayB) do
        local isContained = false

        for _, colorA in ipairs(colorsArrayA) do
            if colorA.rgbaPixel == colorB.rgbaPixel then
                isContained = true
                break
            end
        end

        if not isContained then return false end
    end

    return true
end

local PaletteExtractor = {imageProvider = nil}

function PaletteExtractor:New(options)
    options = options or {}
    setmetatable(options, self)
    self.__index = self

    -- Initialize colors
    options.colors = self:GetColorsFromImage(options.imageProvider:GetImage())

    return options
end

function PaletteExtractor:GetOutlineColors()
    if self.outlineColors == nil then
        self.outlineColors = self:ExtractOutlineColors(self.colors)
    end

    return self.outlineColors
end

function PaletteExtractor:SetOutlineColors(outlineColors)
    self.outlineColors = outlineColors
end

function PaletteExtractor:GetColorsFromImage(image)
    local colors = {}

    for pixel in image:pixels() do
        local pixelColorId = tostring(pixel())
        colors[pixelColorId] = colors[pixelColorId] or {}

        local left = math.max(pixel.x - 1, 0)
        local right = math.min(pixel.x + 1, image.width - 1)
        local up = math.max(pixel.y - 1, 0)
        local down = math.min(pixel.y + 1, image.height - 1)

        local related = {
            image:getPixel(left, pixel.y), image:getPixel(right, pixel.y),
            image:getPixel(pixel.x, up), image:getPixel(pixel.x, down)
        }

        for _, relatedColorValue in ipairs(related) do
            local relatedColorId = tostring(relatedColorValue)

            if relatedColorId ~= pixelColorId then
                colors[pixelColorId][relatedColorId] =
                    (colors[pixelColorId][relatedColorId] or 0) + 1
            end
        end
    end

    return colors
end

function PaletteExtractor:ExtractOutlineColors(colors)
    local transparentColorValue = tostring(Color{gray = 0, alpha = 0}.rgbaPixel)

    local outlineColors = {}

    for outlineColorId, _ in pairs(colors[transparentColorValue]) do
        local outlineColorValue = tonumber(outlineColorId)
        table.insert(outlineColors, Color(outlineColorValue))
    end

    table.sort(outlineColors,
               function(a, b) return a.lightness > b.lightness end)

    return outlineColors
end

local function HueDifference(a, b)
    local smallerValue = math.min(a, b)
    local biggerValue = math.max(a, b)

    return
        math.min(biggerValue - smallerValue, 360 + smallerValue - biggerValue)
end

local function GetQ(array, percent)
    local indexApproximation = #array * percent

    local indexA = math.floor(indexApproximation)
    local indexB = math.ceil(indexApproximation)

    local a = array[indexA] or 0
    local b = array[indexB] or 0

    return (a + b) / 2
end

function PaletteExtractor:GetCountValues(colors)
    local counts = {}

    for _, relatedColorIds in pairs(colors) do
        for _, relatedColorCount in pairs(relatedColorIds) do
            table.insert(counts, relatedColorCount)
        end
    end

    return counts
end

local function GetColorDistance(a, b)
    return (HueDifference(a.hue, b.hue) / 360) ^ 2 +
               ((a.saturation - b.saturation)) ^ 2 +
               ((a.lightness - b.lightness)) ^ 2
end

function PaletteExtractor:CreatePalettes(colors, tolerance, countTolerance)
    local chain = {}
    local diffs = {}

    local countValues = self:GetCountValues(colors)
    table.sort(countValues)
    local maxCount = GetQ(countValues, countTolerance / 100)

    for colorId, relatedColorIds in pairs(colors) do
        local color = ColorFromId(colorId)
        local relatedColors = {}

        for relatedColorId, relatedColorCount in pairs(relatedColorIds) do
            local relatedColor = ColorFromId(relatedColorId)

            -- Include only darker colors & ignore transparency
            if relatedColor.alpha ~= 0 and color.lightness >
                relatedColor.lightness and relatedColorCount > maxCount then
                table.insert(relatedColors, relatedColor)
            end
        end

        table.sort(relatedColors, function(a, b)
            return GetColorDistance(color, a) < GetColorDistance(color, b)
        end)

        local closestRelatedColor = relatedColors[1]

        local diff = nil

        if closestRelatedColor ~= nil then
            diff = (HueDifference(color.hue, closestRelatedColor.hue) / 360)
            table.insert(diffs, diff)
        end

        chain[colorId] = {diff = diff, color = closestRelatedColor}
    end

    table.sort(diffs)
    local maxDiff = GetQ(diffs, tolerance / 100)

    for colorId, relatedColor in pairs(chain) do
        if relatedColor.diff ~= nil and relatedColor.diff < maxDiff and
            relatedColor.color ~= nil then
            chain[colorId] = relatedColor.color
        else
            chain[colorId] = Color {gray = 0, alpha = 0}
        end
    end

    return chain
end

function PaletteExtractor:CreateColorRamps(tolerance, countTolerance)
    local transparentColorValue = tostring(Color{gray = 0, alpha = 0}.rgbaPixel)

    local colors = deepcopy(self.colors)
    local outlineColors = self:GetOutlineColors()

    -- Remove transparency from the list of colors
    colors[transparentColorValue] = nil

    -- Remove outline colors from the list of colors
    for _, outlineColor in ipairs(outlineColors) do
        local outlineColorId = tostring(outlineColor.rgbaPixel)
        for colorValue, relatedColors in pairs(colors) do
            -- Remove the outline colors from the list of colors
            if colorValue == outlineColorId then
                colors[colorValue] = nil
            else
                -- Remove the outline colors from the list of related colors for other colors
                for relatedColorValue, _ in pairs(relatedColors) do
                    if relatedColorValue == outlineColorId then
                        relatedColors[relatedColorValue] = nil
                    end
                end
            end
        end
    end

    -- v This actually just chains colors together
    local palettes = self:CreatePalettes(colors, tolerance, countTolerance)
    local colorRamps = {}

    -- Create colors ramps from palette
    for mainColorId, relatedColor in pairs(palettes) do
        local colorRamp = {ColorFromId(mainColorId)}

        local nextColorId = ColorToId(relatedColor)

        local failSafe = 20 -- This value is completely arbitrary

        while nextColorId ~= nil do
            local nextColor = ColorFromId(nextColorId)

            -- Transparency marks the end of a color ramp
            if nextColor.alpha == 0 then break end

            table.insert(colorRamp, nextColor)

            nextColorId = ColorToId(palettes[nextColorId])

            -- Fail safe against circular references
            failSafe = failSafe - 1
            if failSafe < 0 then break end
        end

        table.insert(colorRamps, colorRamp)
    end

    -- Sort by lightness
    table.sort(colorRamps,
               function(a, b) return a[1].lightness > b[1].lightness end)

    local uniqueColorRamps = {}

    -- Remove color ramps already included in other color ramps
    for i, colorRamp in ipairs(colorRamps) do
        local alreadyIncluded = false

        for j = 1, i - 1 do
            local otherColorRamp = colorRamps[j]

            if Contains(otherColorRamp, colorRamp) then
                alreadyIncluded = true
                break
            end
        end

        if not alreadyIncluded then
            table.insert(uniqueColorRamps, colorRamp)
        end
    end

    return uniqueColorRamps
end

return PaletteExtractor
