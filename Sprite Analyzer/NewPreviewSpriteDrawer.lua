PreviewDirection = dofile("./PreviewDirection.lua")

local function Flip(image)
    if app.apiVersion >= 24 then
        image:flip(FlipType.HORIZONTAL)
        return image
    end

    -- TODO: Rewrite this for better performance
    local flippedImage = Image(image.spec)

    for pixel in image:pixels() do
        flippedImage:drawPixel(image.width - 1 - pixel.x, pixel.y, pixel())
    end

    return flippedImage
end

local function Desaturate(image)
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local value = getPixel(image, x, y)

            if value > 0 then
                local r = app.pixelColor.rgbaR(value)
                local g = app.pixelColor.rgbaG(value)
                local b = app.pixelColor.rgbaB(value)

                drawPixel(image, x, y, Color {
                    gray = 0.299 * r + 0.114 * b + 0.587 * g,
                    alpha = app.pixelColor.rgbaA(value)
                })
            end
        end
    end

    return image
end

local function Silhouette(image)
    local getPixel, drawPixel = image.getPixel, image.drawPixel

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            local value = getPixel(image, x, y)

            drawPixel(image, x, y, Color {
                gray = app.pixelColor.rgbaA(value),
                alpha = app.pixelColor.rgbaA(value)
            })
        end
    end

    return image
end

local function OnlyOutline(image, outlineColors)
    if outlineColors == nil or #outlineColors == 0 then return image end

    local outlineImage = Image(image.spec)

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())

        for i = 1, #outlineColors do
            if pixelColor == outlineColors[i] then
                outlineImage:drawPixel(pixel.x, pixel.y, Color {
                    gray = 0,
                    alpha = pixelColor.alpha
                })
                break
            end
        end
    end

    return outlineImage
end

local function SilhouetteWithoutOutline(image, outlineColors)
    local silhouetteImage = Image(image.spec)
    if outlineColors == nil then return silhouetteImage end

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())
        local isOutline = false

        for i = 1, #outlineColors do
            if pixelColor == outlineColors[i] then
                isOutline = true
                break
            end
        end

        if not isOutline then
            silhouetteImage:drawPixel(pixel.x, pixel.y, Color {
                gray = 0,
                alpha = pixelColor.alpha
            })
        end
    end

    return silhouetteImage
end

local function FlattenColors(image, flatColorEntries)
    if flatColorEntries == nil or #flatColorEntries == 0 then return image end

    local flattedImage = Image(image.spec)

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())
        flattedImage:drawPixel(pixel.x, pixel.y,
                               Color {gray = 0, alpha = pixelColor.alpha})

        for _, flatColorEntry in ipairs(flatColorEntries) do
            local mainColor = flatColorEntry[1]

            for _, flatColor in ipairs(flatColorEntry) do
                if pixelColor == flatColor then
                    flattedImage:drawPixel(pixel.x, pixel.y, mainColor)
                    break
                end
            end
        end

    end

    return flattedImage
end

local PreviewSpriteDrawer = {}

function PreviewSpriteDrawer:Update(image, mode, flip, outlineColors, flatColors)
    local AnalysisMode = {
        Silhouette = "Silhouette",
        Outline = "Outline",
        Values = "Values",
        ColorBlocks = "Color Blocks"
    }

    -- Prepare a list of all images
    local previewImage = {}

    if mode == AnalysisMode.Silhouette then
        previewImage = Silhouette(image)
    elseif mode == AnalysisMode.Outline and self:HasOutlineColors(outlineColors) then
        previewImage = OnlyOutline(image, outlineColors)
    elseif mode == AnalysisMode.Values then
        previewImage = Desaturate(image)
    elseif mode == AnalysisMode.ColorBlocks and self:HasFlatColors(flatColors) then
        previewImage = FlattenColors(image, flatColors)
    end

    if flip then previewImage = Flip(previewImage) end

    return previewImage
end

function PreviewSpriteDrawer:HasOutlineColors(outlineColors)
    return outlineColors and #outlineColors > 0 and outlineColors[1].alpha ~= 0
end

function PreviewSpriteDrawer:HasFlatColors(flatColors)
    return flatColors and #flatColors > 0 and flatColors[1] and #flatColors[1] >
               0 and flatColors[1].alpha ~= 0
end

return PreviewSpriteDrawer
