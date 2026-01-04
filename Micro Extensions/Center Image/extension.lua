local function GetContentBounds(cel, selection)
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

local function CutImagePart(cel, selection)
    local partBounds = GetContentBounds(cel, selection)
    local imagePart = Image(cel.image, partBounds)

    return imagePart,
           Rectangle(cel.bounds.x + partBounds.x, cel.bounds.y + partBounds.y,
                     partBounds.width, partBounds.height)
end

local function GetImageCenter(image, options)
    local getPixel = image.getPixel
    local centerX = 0

    if options.weighted then
        local total = 0
        local rows = {}

        for x = 0, image.width do
            for y = 0, image.height do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(rows, total)
        end

        local centerValue = total / 2
        centerX = 0

        for i = 1, #rows do
            if rows[i] >= centerValue then
                centerX = i - 1
                break
            end
        end
    else
        centerX = math.floor(image.width / 2)
    end

    local centerY = 0

    if options.weighted then
        local total = 0
        local columns = {}

        for y = 0, image.height do
            for x = 0, image.width do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(columns, total)
        end

        local centerValue = total / 2
        centerY = 0

        for i = 1, #columns do
            if columns[i] >= centerValue then
                centerY = i - 1
                break
            end
        end
    else
        centerY = math.floor(image.height / 2)
    end

    return Point(centerX, centerY)
end

local function ClearImage(image, bounds, outerBounds)
    if outerBounds then
        bounds = Rectangle(bounds.x - outerBounds.x, bounds.y - outerBounds.y,
                           bounds.width, bounds.height)
    end

    if app.apiVersion >= 23 then
        image:clear(bounds)
    else
        -- Draw an empty image to erase the part
        image:drawImage(Image(bounds.width, bounds.height),
                        Point(bounds.x, bounds.y), 255, BlendMode.SRC)
    end
end

local function GetTrimmedImageBounds(image)
    -- From API v21, we can use Image:shrinkBounds() for this
    if app.apiVersion >= 21 then return image:shrinkBounds() end

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

    return Rectangle(left, top, right - left + 1, bottom - top + 1)
end

local function CenterSelection(cel, options, sprite)
    local selection = sprite.selection.bounds

    local selectedImagePart, selectedImagePartBounds = CutImagePart(cel,
                                                                    selection)
    local imageCenter = GetImageCenter(selectedImagePart, options)

    local x = selectedImagePartBounds.x
    local y = selectedImagePartBounds.y

    if options.xAxis then
        x = selection.x + math.floor(selection.width / 2) - imageCenter.x
    end

    if options.yAxis then
        y = selection.y + math.floor(selection.height / 2) - imageCenter.y
    end

    local contentNewBounds = Rectangle(x, y, selectedImagePart.width,
                                       selectedImagePart.height)

    local newImageBounds = contentNewBounds:union(cel.bounds)
    local newImage = Image(newImageBounds.width, newImageBounds.height,
                           sprite.colorMode)

    -- Draw the original image
    newImage:drawImage(cel.image, Point(cel.position.x - newImageBounds.x,
                                        cel.position.y - newImageBounds.y))

    -- Clear the selected image part from it's original position
    ClearImage(newImage, selectedImagePartBounds, newImageBounds)

    -- Redraw the selected image part in the new position
    newImage:drawImage(selectedImagePart,
                       Point(x - newImageBounds.x, y - newImageBounds.y))

    local newPosition = Point(newImageBounds.x, newImageBounds.y)
    local trimmedBounds = GetTrimmedImageBounds(newImage)

    -- Only trim image if necessary
    if trimmedBounds.width ~= newImage.width or trimmedBounds.height ~=
        newImage.height then
        newPosition = Point(newPosition.x + trimmedBounds.x,
                            newPosition.y + trimmedBounds.y)
        newImage = Image(newImage, trimmedBounds)
    end

    sprite:newCel(cel.layer, cel.frameNumber, newImage, newPosition)

end

local function GetCanvasCenter(sprite)
    local selection = sprite.selection
    local x, y

    if selection.isEmpty then

        x = sprite.width / 2
        y = sprite.height / 2
    else
        x = selection.bounds.width / 2 + selection.bounds.x
        y = selection.bounds.height / 2 + selection.bounds.y
    end

    return Point(math.floor(x), math.floor(y))
end

local function CenterCel(cel, options, sprite)
    local x = cel.bounds.x
    local y = cel.bounds.y

    local canvasCenter = GetCanvasCenter(sprite)
    local imageCenter = GetImageCenter(cel.image, options)

    if options.xAxis then x = canvasCenter.x - imageCenter.x end
    if options.yAxis then y = canvasCenter.y - imageCenter.y end

    cel.position = Point(x, y)
end

local function CanCenterImage()
    -- If there's no active sprite
    if app.activeSprite == nil then return false end

    -- If there's no cels in range
    if #app.range.cels == 0 then return false end

    return true
end

local function CenterImageInActiveSprite(options)
    if options == nil or (not options.xAxis and not options.yAxis) then
        return
    end

    app.transaction(function()
        local sprite = app.activeSprite
        local selection = sprite.selection

        for _, cel in ipairs(app.range.cels) do
            if cel.layer.isEditable then
                -- If the entire cel image is within the selection, then move the cel
                if selection.isEmpty or selection.bounds:contains(cel.bounds) then
                    CenterCel(cel, options, sprite)
                else
                    CenterSelection(cel, options, sprite)
                end
            end
        end
    end)

    app.refresh()
end

function init(plugin)
    local parentGroup = "edit_transform"

    if app.apiVersion >= 22 then
        parentGroup = "edit_center"

        plugin:newMenuGroup{
            id = parentGroup,
            title = "Center",
            group = "edit_transform"
        }
    end

    plugin:newCommand{
        id = "Center",
        title = "Center",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = true}
        end
    }

    plugin:newCommand{
        id = "CenterX",
        title = "Center X",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, yAxis = false}
        end
    }

    plugin:newCommand{
        id = "CenterY",
        title = "Center Y",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = false, yAxis = true}
        end
    }

    if app.apiVersion >= 22 then plugin:newMenuSeparator{group = parentGroup} end

    plugin:newCommand{
        id = "CenterWeighted",
        title = "Center (Weighted)",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {
                xAxis = true,
                yAxis = true,
                weighted = true
            }
        end
    }

    plugin:newCommand{
        id = "CenterXWeighted",
        title = "Center X (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {xAxis = true, weighted = true}
        end
    }

    plugin:newCommand{
        id = "CenterYWeighted",
        title = "Center Y (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            CenterImageInActiveSprite {yAxis = true, weighted = true}
        end
    }
end

function exit(plugin) end
