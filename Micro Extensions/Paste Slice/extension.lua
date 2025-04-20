local DrawMode = {
    Stretch = "Stretch",
    Repeat = "Repeat",
    Mirror = "Mirror",
    Skip = "Skip"
}

local function GetImagePart(image, rectangle)
    local imagePart = Image(rectangle.width, rectangle.height)

    for pixel in image:pixels(rectangle) do
        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            pixel())
    end

    return imagePart
end

local function GetSliceImageParts(slice)
    local sprite = slice.sprite
    local spriteImage = Image(sprite)

    -- Get just the slice image
    local sliceImage = GetImagePart(spriteImage, slice.bounds)

    local leftWidth = slice.center.x
    local centerWidth = slice.center.width
    local rightWidth = sliceImage.width - (slice.center.x + slice.center.width)

    local topHeight = slice.center.y
    local middleHeight = slice.center.height
    local bottomHeight = sliceImage.height -
                             (slice.center.y + slice.center.height)

    local topLeft = Rectangle(0, 0, leftWidth, topHeight)
    local topCenter = Rectangle(leftWidth, 0, centerWidth, topHeight)
    local topRight =
        Rectangle(leftWidth + centerWidth, 0, rightWidth, topHeight)

    local middleLeft = Rectangle(0, topHeight, leftWidth, middleHeight)
    local middleCenter = Rectangle(leftWidth, topHeight, centerWidth,
                                   middleHeight)
    local middleRight = Rectangle(leftWidth + centerWidth, topHeight,
                                  rightWidth, middleHeight)

    local bottomLeft = Rectangle(0, topHeight + middleHeight, leftWidth,
                                 bottomHeight)
    local bottomCenter = Rectangle(leftWidth, topHeight + middleHeight,
                                   centerWidth, bottomHeight)
    local bottomRight = Rectangle(leftWidth + centerWidth,
                                  topHeight + middleHeight, rightWidth,
                                  bottomHeight)

    return {
        topLeft = GetImagePart(sliceImage, topLeft),
        topCenter = GetImagePart(sliceImage, topCenter),
        topRight = GetImagePart(sliceImage, topRight),
        middleLeft = GetImagePart(sliceImage, middleLeft),
        middleCenter = GetImagePart(sliceImage, middleCenter),
        middleRight = GetImagePart(sliceImage, middleRight),
        bottomLeft = GetImagePart(sliceImage, bottomLeft),
        bottomCenter = GetImagePart(sliceImage, bottomCenter),
        bottomRight = GetImagePart(sliceImage, bottomRight)
    }
end

local function DrawImageResized(sourceImage, targetImage, targetBounds)
    local sw, sh = sourceImage.width, sourceImage.height
    local tw, th = targetBounds.width, targetBounds.height

    for x = 0, tw - 1 do
        for y = 0, th - 1 do
            local sourceX = (x / tw) * sw
            local sourceY = (y / th) * sh

            local pixelValue = sourceImage:getPixel(sourceX, sourceY)

            local targetX = targetBounds.x + x
            local targetY = targetBounds.y + y

            targetImage:drawPixel(targetX, targetY, pixelValue)
        end
    end
end

local function GetSliceImageStretched(parts, bounds)
    local image = Image(bounds.width, bounds.height) -- TODO: What about supporting different color modes

    local leftX = 0
    local centerX = parts.topLeft.width
    local rightX = bounds.width - parts.topRight.width

    local topY = 0
    local middleY = parts.topLeft.height
    local bottomY = bounds.height - parts.bottomLeft.height

    -- Draw all corners
    image:drawImage(parts.topLeft, Point(leftX, topY))
    image:drawImage(parts.topRight, Point(rightX, topY))
    image:drawImage(parts.bottomLeft, Point(leftX, bottomY))
    image:drawImage(parts.bottomRight, Point(rightX, bottomY))

    DrawImageResized(parts.topCenter, image, Rectangle(centerX, topY,
                                                       bounds.width -
                                                           parts.topLeft.width -
                                                           parts.topRight.width,
                                                       parts.topCenter.height))

    DrawImageResized(parts.bottomCenter, image, Rectangle(centerX, bottomY,
                                                          bounds.width -
                                                              parts.bottomLeft
                                                                  .width -
                                                              parts.bottomRight
                                                                  .width,
                                                          parts.bottomCenter
                                                              .height))

    DrawImageResized(parts.middleLeft, image,
                     Rectangle(leftX, middleY, parts.middleLeft.width,
                               bounds.height - parts.topLeft.height -
                                   parts.bottomLeft.height))

    DrawImageResized(parts.middleRight, image,
                     Rectangle(rightX, middleY, parts.middleRight.width,
                               bounds.height - parts.topRight.height -
                                   parts.bottomRight.height))

    return image
end

local function GetSliceCenterImageStretched(parts, bounds)
    local image = Image(bounds.width - parts.topLeft.width -
                            parts.topRight.width, bounds.height -
                            parts.topLeft.height - parts.bottomLeft.height) -- TODO: What about supporting different color modes

    local w = bounds.width - parts.topLeft.width - parts.topRight.width
    local h = bounds.height - parts.topRight.height - parts.bottomRight.height

    DrawImageResized(parts.middleCenter, image, Rectangle(0, 0, w, h))

    return image
end

local function GetSliceImageTiled(parts, bounds)
    local image = Image(bounds.width, bounds.height) -- TODO: What about supporting different color modes

    -- We're working under an assumption that topCenter and bottomCenter parts have the same width
    local x = parts.topLeft.width
    while x < image.width do
        image:drawImage(parts.topCenter, Point(x, 0))
        image:drawImage(parts.bottomCenter,
                        Point(x, bounds.height - parts.bottomCenter.height))

        x = x + parts.topCenter.width
    end

    local y = parts.topLeft.height
    while y < image.height do
        image:drawImage(parts.middleLeft, Point(0, y))
        image:drawImage(parts.middleRight,
                        Point(bounds.width - parts.middleRight.width, y))

        y = y + parts.middleLeft.height
    end

    -- Draw all corners
    image:drawImage(parts.topLeft, Point(0, 0))
    image:drawImage(parts.topRight,
                    Point(bounds.width - parts.topRight.width, 0))
    image:drawImage(parts.bottomLeft,
                    Point(0, bounds.height - parts.bottomLeft.height))
    image:drawImage(parts.bottomRight,
                    Point(bounds.width - parts.bottomRight.width,
                          bounds.height - parts.bottomRight.height))

    return image
end

local function GetSliceCenterImageTiled(parts, bounds)
    local image = Image(bounds.width - parts.topLeft.width -
                            parts.topRight.width, bounds.height -
                            parts.topLeft.height - parts.bottomLeft.height) -- TODO: What about supporting different color modes

    print(image.width, image.height)

    local x = 0
    while x < image.width do
        local y = 0
        while y < image.height do
            print("drawing image at " .. tostring(x) .. " " .. tostring(y))
            image:drawImage(parts.middleCenter, Point(x, y))

            y = y + parts.middleCenter.height
        end

        x = x + parts.middleCenter.width
    end

    return image
end

local function GetSliceImage(parts, bounds, tileMode)
    if tileMode == DrawMode.Stretch then
        return GetSliceImageStretched(parts, bounds)
    elseif tileMode == DrawMode.Repeat then
        return GetSliceImageTiled(parts, bounds)
    elseif tileMode == DrawMode.Mirror then
        -- TODO: Implement the Mirror Tile Mode
    end
end

local function GetSliceCenterImage(parts, bounds, tileMode)
    if tileMode == DrawMode.Stretch then
        return GetSliceCenterImageStretched(parts, bounds)
    elseif tileMode == DrawMode.Repeat then
        return GetSliceCenterImageTiled(parts, bounds)
    elseif tileMode == DrawMode.Mirror then
        -- TODO: Implement the Mirror Tile Mode
    else
        return Image(0, 0)
    end
end

local function GetSlices()
    local activeSprite = app.activeSprite
    local slices = {}

    for _, sprite in ipairs(app.sprites) do
        local namePrefix = sprite == activeSprite and "" or
                               app.fs.fileTitle(sprite.filename) .. " \\ "

        for _, slice in ipairs(sprite.slices) do
            if slice.center then
                table.insert(slices, {
                    name = namePrefix .. slice.name,
                    sprite = slice.sprite,
                    bounds = slice.bounds,
                    center = slice.center
                })
            end
        end
    end

    local nameCount = {}
    local names = {}

    for _, slice in ipairs(slices) do
        if nameCount[slice.name] == nil then
            nameCount[slice.name] = 1
        else
            nameCount[slice.name] = nameCount[slice.name] + 1
        end

        slice.name = nameCount[slice.name] == 1 and slice.name or slice.name ..
                         " (" .. tostring(nameCount[slice.name]) .. ")"

        table.insert(names, slice.name)
    end

    table.sort(names)

    return slices, names
end

local function MergeImages(imageA, positionA, imageB, positionB)
    local minX = math.min(positionA.x, positionB.x)
    local minY = math.min(positionA.y, positionB.y)

    local maxX =
        math.max(positionA.x + imageA.width, positionB.x + imageB.width)
    local maxY = math.max(positionA.y + imageA.height,
                          positionB.y + imageB.height)

    local newImage = Image(maxX - minX, maxY - minY)
    local newPosition = Point(minX, minY)

    newImage:drawImage(imageA, Point(positionA.x - minX, positionA.y - minY))
    newImage:drawImage(imageB, Point(positionB.x - minX, positionB.y - minY))

    return newImage, newPosition
end

local function PasteSlice(cel, slice, selection, frameDrawMode, centerDrawMode)
    local sliceImagesParts = GetSliceImageParts(slice)
    local frameImage = GetSliceImage(sliceImagesParts, selection, frameDrawMode)
    local centerImage = GetSliceCenterImage(sliceImagesParts, selection,
                                            centerDrawMode)

    frameImage:drawImage(centerImage, Point(sliceImagesParts.topLeft.width,
                                            sliceImagesParts.topLeft.height))

    cel.image, cel.position = MergeImages(cel.image, cel.position, frameImage,
                                          selection)
end

local function PasteSliceDialog(options)
    local dialog = Dialog("Paste Slice")
    local slices, sliceNames = GetSlices()

    dialog --
    :combobox{
        id = "selected-slice",
        label = "Slice:",
        option = sliceNames[1],
        options = sliceNames
    } --
    :separator{text = "Draw Mode"} --
    :combobox{
        id = "frame-draw-mode",
        label = "Frame:",
        options = {DrawMode.Stretch, DrawMode.Repeat, DrawMode.Mirror},
        option = DrawMode.Stretch
    } ---
    :combobox{
        id = "center-draw-mode",
        label = "Center:",
        options = {
            DrawMode.Stretch, DrawMode.Repeat, DrawMode.Mirror, DrawMode.Skip
        },
        option = DrawMode.Stretch
    } ---
    :button{
        text = "OK",
        onclick = function()
            local selectedSlice = nil

            for _, slice in ipairs(slices) do
                if dialog.data["selected-slice"] == slice.name then
                    selectedSlice = slice
                    break
                end
            end

            local cel = app.activeCel
            local selection = app.activeSprite.selection.bounds
            local frameDrawMode = dialog.data["frame-draw-mode"]
            local centerDrawMode = dialog.data["center-draw-mode"]

            app.transaction(function()
                PasteSlice(cel, selectedSlice, selection, frameDrawMode,
                           centerDrawMode)
            end)

            app.refresh()
            dialog:close()
        end
    } --
    :button{text = "Cancel"}

    return dialog
end

function init(plugin)
    plugin:newCommand{
        id = "PasteSlice",
        title = "Paste Slice",
        group = "edit_paste_special_new",
        onenabled = function()
            if app.activeSprite == nil then return false end
            if app.activeCel == nil then return false end

            for _, sprite in ipairs(app.sprites) do
                if #sprite.slices > 0 then return true end
            end

            return false
        end,
        onclick = function()
            local dialog = PasteSliceDialog()
            dialog:show()
        end
    }
end

function exit(plugin) end

-- TODO: Test & optimize
-- TODO: Consider making an optional "Paste Slice as a frame" that frames the selection (no center) OR make this an option in the dialog window (probably better this way)
-- TODO: Consider remembering the last selected options in the dialog for quick repeats
