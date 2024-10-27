local function CanTransformBrush()
    local sprite = app.activeSprite
    if sprite == nil then return false end

    local brush = app.activeBrush
    if brush == nil then return false end

    local image = brush.image
    if image == nil then return false end

    return true
end

local function TransformBrush(options)
    local brush = app.activeBrush
    local image, width, height = brush.image, brush.image.width,
                                 brush.image.height

    local transformedImage

    if options.rotateCw then
        transformedImage = Image(height, width, image.colorMode)

        for pixel in image:pixels() do
            transformedImage:drawPixel(height - 1 - pixel.y, pixel.x, pixel())
        end
    elseif options.rotateCcw then
        transformedImage = Image(height, width, image.colorMode)

        for pixel in image:pixels() do
            transformedImage:drawPixel(pixel.y, width - 1 - pixel.x, pixel())
        end
    elseif options.flipHorizontal then
        transformedImage = Image(width, height, image.colorMode)

        for pixel in image:pixels() do
            transformedImage:drawPixel(width - 1 - pixel.x, pixel.y, pixel())
        end
    elseif options.flipVertical then
        transformedImage = Image(width, height, image.colorMode)

        for pixel in image:pixels() do
            transformedImage:drawPixel(pixel.x, height - 1 - pixel.y, pixel())
        end
    end

    app.activeBrush = Brush {
        type = brush.type,
        size = brush.size,
        angle = brush.angle,
        center = brush.center,
        image = transformedImage,
        pattern = brush.pattern,
        patternOrigin = brush.patternOrigin
    }
end

function init(plugin)
    local parentGroup = "edit_transform"

    if app.apiVersion >= 22 then
        parentGroup = "edit_brush_transformations"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Brush Transformations",
            group = "edit_transform"
        }
    end

    plugin:newCommand{
        id = "BrushRotateCW",
        title = "Brush Rotate 90 CW",
        group = parentGroup,
        onenabled = CanTransformBrush,
        onclick = function() TransformBrush {rotateCw = true} end
    }

    plugin:newCommand{
        id = "BrushRotateCCW",
        title = "Brush Rotate 90 CCW",
        group = parentGroup,
        onenabled = CanTransformBrush,
        onclick = function() TransformBrush {rotateCcw = true} end
    }

    plugin:newCommand{
        id = "BrushFlipHorizontal",
        title = "Brush Flip Horizontal",
        group = parentGroup,
        onenabled = CanTransformBrush,
        onclick = function() TransformBrush {flipHorizontal = true} end
    }

    plugin:newCommand{
        id = "BrushFlipVertical",
        title = "Brush Flip Vertical",
        group = parentGroup,
        onenabled = CanTransformBrush,
        onclick = function() TransformBrush {flipVertical = true} end
    }
end

function exit(plugin) end
