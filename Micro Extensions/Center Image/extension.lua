function CanCenterImage()
    -- If there's no active sprite
    if app.activeSprite == nil then return false end

    -- If there's no cels in range
    if #app.range.cels == 0 then return false end

    return true
end

function CenterImageInActiveSprite(options)
    if options == nil then return end
    if not options.xAxis and not options.yAxis then return end

    app.transaction(function()
        local sprite = app.activeSprite

        if not sprite.selection.isEmpty then
            CenterSelection(options, sprite)
        else
            CenterCels(options, sprite)
        end
    end)

    app.refresh()
end

function CenterSelection(options, sprite)
    -- TODO: Trim the transparency

    local selection = sprite.selection.bounds

    for _, cel in ipairs(app.range.cels) do
        local contentBounds = GetContentBounds(cel, selection)
        local oldImage, contentImage = CutImagePart(cel.image, contentBounds)

        local centerX = cel.bounds.x + contentBounds.x

        if options.xAxis then
            centerX = selection.x + math.floor(selection.width / 2) -
                          math.floor(contentBounds.width / 2)
        end

        local centerY = cel.bounds.y + contentBounds.y

        if options.yAxis then
            centerY = selection.y + math.floor(selection.height / 2) -
                          math.floor(contentBounds.height / 2)
        end

        local contentNewBounds = Rectangle(centerX, centerY, contentImage.width,
                                           contentImage.height)

        local newImageBounds = contentNewBounds:union(cel.bounds)
        local newImage = Image(newImageBounds.width, newImageBounds.height,
                               sprite.colorMode)

        newImage:drawImage(oldImage, Point(cel.position.x - newImageBounds.x,
                                           cel.position.y - newImageBounds.y))
        newImage:drawImage(contentImage, Point(centerX - newImageBounds.x,
                                               centerY - newImageBounds.y))

        local trimmedImage, trimmedPosition =
            TrimImage(newImage, Point(newImageBounds.x, newImageBounds.y))

        sprite:newCel(cel.layer, cel.frameNumber, trimmedImage, trimmedPosition)
    end
end

function CenterCels(options, sprite)
    for _, cel in ipairs(app.range.cels) do
        local x = cel.bounds.x
        local y = cel.bounds.y

        if options.xAxis then
            x = math.floor(sprite.width / 2) - math.floor(cel.bounds.width / 2)
        end

        if options.yAxis then
            y = math.floor(sprite.height / 2) -
                    math.floor(cel.bounds.height / 2)
        end

        cel.position = Point(x, y)
    end
end

function GetContentBounds(cel, selection)
    local imageSelection = Rectangle(selection.x - cel.bounds.x,
                                     selection.y - cel.bounds.y,
                                     selection.width, selection.height)

    -- Calculate selection content bounds
    local minX, maxX, minY, maxY = math.maxinteger, math.mininteger,
                                   math.maxinteger, math.mininteger

    for pixel in cel.image:pixels(imageSelection) do
        if pixel() > 0 then
            minX = math.min(minX, pixel.x)
            maxX = math.max(maxX, pixel.x)

            minY = math.min(minY, pixel.y)
            maxY = math.max(maxY, pixel.y)
        end
    end

    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

function CutImagePart(image, rectangle)
    local oldImage = Image(image)
    local imagePart = Image(rectangle.width, rectangle.height, image.colorMode)

    for pixel in oldImage:pixels(rectangle) do
        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            pixel())
        pixel(0)
    end

    return oldImage, imagePart
end

function TrimImage(image, position)
    local found, left, top, right, bottom

    -- Left
    found = false

    for x = 0, image.width - 1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                left = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Top
    found = false

    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                top = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Right
    found = false

    for x = image.width - 1, 0, -1 do
        for y = 0, image.height - 1 do
            if image:getPixel(x, y) > 0 then
                right = x
                found = true
                break
            end
        end

        if found then break end
    end

    -- Bottom
    found = false

    for y = image.height - 1, 0, -1 do
        for x = 0, image.width - 1 do
            if image:getPixel(x, y) > 0 then
                bottom = y
                found = true
                break
            end
        end

        if found then break end
    end

    -- Trim image
    local trimmedImage = Image(right - left + 1, bottom - top + 1,
                               image.colorMode)
    trimmedImage:drawImage(image, Point(-left, -top))

    return trimmedImage, Point(position.x + left, position.y + top)
end

function init(plugin)
    plugin:newCommand{
        id = "Center",
        title = "Center",
        group = "edit_transform",
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = true}
        end
    }

    plugin:newCommand{
        id = "CenterX",
        title = "Center X",
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = false}
        end
    }

    plugin:newCommand{
        id = "CenterY",
        title = "Center Y",
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = false, yAxis = true}
        end
    }
end

function exit(plugin) end
