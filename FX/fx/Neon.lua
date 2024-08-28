local ImageProcessor = dofile("../ImageProcessor.lua")

local Neon = {}

function Neon:_SplitImageByColors(image)
    local maskImage = Image(image.spec)
    local colorImages = {}

    for pixel in image:pixels() do
        local color = Color(pixel())

        if color.alpha > 0 then
            maskImage:drawPixel(pixel.x, pixel.y,
                                Color {gray = 255, alpha = color.alpha})

            local colorId = tostring(color.rgbaPixel)

            if colorImages[colorId] == nil then
                colorImages[colorId] = Image(image.spec)
            end

            colorImages[colorId]:drawPixel(pixel.x, pixel.y, color)
        end
    end

    return maskImage, colorImages
end

function Neon:_SelectContent(cel)
    local image = cel.image
    local getPixel = image.getPixel

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if getPixel(image, x + cel.position.x, y + cel.position.y) == 0 then
                app.useTool {
                    tool = "magic_wand",
                    points = {Point(x, y)},
                    button = MouseButton.LEFT,
                    contiguous = false,
                    selection = SelectionMode.REPLACE
                }

                app.command.InvertMask()

                return
            end
        end
    end
end

function Neon:_UnpackParameters(parameters)
    local expand = 1
    local blurMode = "blur-3x3"

    if parameters.strength == "2" then
        expand = 2
        blurMode = "blur-5x5"
    elseif parameters.strength == "3" then
        expand = 3
        blurMode = "blur-7x7"
    elseif parameters.strength == "4" then
        expand = 4
        blurMode = "blur-9x9"
    elseif parameters.strength == "5" then
        expand = 5
        blurMode = "blur-17x17"
    end

    return expand, blurMode
end

function Neon:Generate(parameters)
    local sprite = app.activeSprite
    local cel = app.activeCel
    local originalSelection = Selection()
    originalSelection:add(sprite.selection)

    local expand, blurMode = self:_UnpackParameters(parameters)

    local frameNumber = app.activeFrame.frameNumber
    local image = cel.image
    local position = cel.position

    -- Get only image from selection
    if not originalSelection.isEmpty then
        local selectedImageBounds = originalSelection.bounds:intersect(
                                        cel.bounds)
        local newPosition = Point(selectedImageBounds.x, selectedImageBounds.y)

        selectedImageBounds.x = selectedImageBounds.x - position.x
        selectedImageBounds.y = selectedImageBounds.y - position.y

        position = newPosition

        image = ImageProcessor:GetImagePart(image, selectedImageBounds)
    end

    local maskImage, colorImages = self:_SplitImageByColors(image)

    local groupLayer = sprite:newGroup()
    groupLayer.name = "Neon"

    -- Glow Source
    local sourceLayer = sprite:newLayer()
    sourceLayer.name = "Source"
    sourceLayer.parent = groupLayer
    sourceLayer.opacity = 192
    sprite:newCel(sourceLayer, frameNumber, maskImage, position)

    local sourceBlurLayer = sprite:newLayer()
    sourceBlurLayer.name = "Source Blur"
    sourceBlurLayer.parent = groupLayer
    sourceBlurLayer.opacity = 192
    sprite:newCel(sourceBlurLayer, frameNumber, maskImage, position)
    app.command.ConvolutionMatrix {ui = false, fromResource = "blur-3x3"}

    local colorNumber = 0

    -- Color
    for colorId, colorImage in pairs(colorImages) do
        colorNumber = colorNumber + 1

        local color = Color(tonumber(colorId))

        local colorLayer = sprite:newLayer()
        colorLayer.name = "Color Blur #" .. tostring(colorNumber)
        colorLayer.parent = groupLayer
        colorLayer.stackIndex = 1
        colorLayer.blendMode = BlendMode.SCREEN
        local colorCel = sprite:newCel(colorLayer, frameNumber, colorImage,
                                       position)

        if expand > 0 then
            self:_SelectContent(colorCel)

            app.command.ModifySelection {
                modifier = "expand",
                quantity = expand,
                brush = "square"
            }

            if not originalSelection.isEmpty then
                sprite.selection:intersect(originalSelection)
            end

            app.useTool {
                tool = "paint_bucket",
                points = {Point(-1, -1)},
                button = MouseButton.LEFT,
                contiguous = false,
                color = color
            }
            app.command.DeselectMask()
        end

        sprite.selection = originalSelection

        app.command.ConvolutionMatrix {ui = false, fromResource = blurMode}
        app.command.ConvolutionMatrix {ui = false, fromResource = blurMode}
    end

    sprite.selection = originalSelection
end

return Neon

-- TODO: Process all active cels - that doesn't seem possible at the moment, looks like the Convolution Matrix FX is not synchronous and it can skip cels to process
-- TODO: Merge cels on the same frame from multiple layers
