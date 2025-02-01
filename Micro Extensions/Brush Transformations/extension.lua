local function TransformRegularBrush(brush, options)
    local angle = brush.angle

    if options.rotateCw then
        angle = angle + 90
    elseif options.rotateCcw then
        angle = angle - 90
    elseif options.flipHorizontal or options.flipVertical then
        angle = 360 - angle
    end

    -- Updating a regular brush requires updating properties directly
    -- Instead of updating the active brush 
    local tool = app.preferences.tool(app.activeTool)
    tool.brush.angle = (angle % 360) - 180
end

local function TransformImageBrush(brush, options)
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

local function TransformBrush(options)
    local brush = app.activeBrush

    if brush.type == BrushType.IMAGE then
        TransformImageBrush(brush, options)
    else
        TransformRegularBrush(brush, options)
    end

    app.refresh()
end

function init(plugin)
    local parentGroup = "edit_transform"

    if app.apiVersion >= 22 then
        parentGroup = "edit_brush_transformations"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Brush",
            group = "edit_transform"
        }
    end

    plugin:newCommand{
        id = "BrushRotateCW",
        title = app.apiVersion >= 22 and "Rotate 90 CW" or "Brush Rotate 90 CW",
        group = parentGroup,
        onclick = function() TransformBrush {rotateCw = true} end
    }

    plugin:newCommand{
        id = "BrushRotateCCW",
        title = app.apiVersion >= 22 and "Rotate 90 CCW" or
            "Brush Rotate 90 CCW",
        group = parentGroup,
        onclick = function() TransformBrush {rotateCcw = true} end
    }

    if app.apiVersion >= 22 then plugin:newMenuSeparator{group = parentGroup} end

    plugin:newCommand{
        id = "BrushFlipHorizontal",
        title = app.apiVersion >= 22 and "Flip Horizontal" or
            "Brush Flip Horizontal",
        group = parentGroup,
        onclick = function() TransformBrush {flipHorizontal = true} end
    }

    plugin:newCommand{
        id = "BrushFlipVertical",
        title = app.apiVersion >= 22 and "Flip Vertical" or
            "Brush Flip Vertical",
        group = parentGroup,
        onclick = function() TransformBrush {flipVertical = true} end
    }
end

function exit(plugin) end
