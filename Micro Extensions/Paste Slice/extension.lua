local Red, Green, Blue, Alpha = app.pixelColor.rgbaR, app.pixelColor.rgbaG,
                                app.pixelColor.rgbaB, app.pixelColor.rgbaA
local Gray, GrayAlpha = app.pixelColor.grayaV, app.pixelColor.grayaA

local SelectionMode = {Fill = "Fill", Frame = "Frame"}

local DrawMode = {
    Stretch = "Stretch",
    Repeat = "Repeat",
    Center = "Center",
    Skip = "Skip"
}

local function GetColor(value, colorMode, palette)
    if colorMode == ColorMode.INDEXED then
        local color = palette:getColor(value)

        -- Correction for the indexed mask color
        if value == 0 then color.alpha = 0 end

        return color
    elseif colorMode == ColorMode.GRAY then
        return Color {gray = Gray(value), alpha = GrayAlpha(value)}
    end

    return Color {
        r = Red(value),
        g = Green(value),
        b = Blue(value),
        a = Alpha(value)
    }
end

local function GetColorValue(color, colorMode)
    if colorMode == ColorMode.INDEXED then
        return color.index
    elseif colorMode == ColorMode.GRAY then
        return color.grayPixel
    end

    return color.rgbaPixel
end

local function GetImagePartInColorMode(sourceSprite, rectangle, colorMode)
    local sourceImage = Image(sourceSprite)
    local sourceColorMode = sourceSprite.colorMode
    local sourcePalette = sourceSprite.palettes[1]

    local imagePart = Image(rectangle.width, rectangle.height, colorMode)

    for pixel in sourceImage:pixels(rectangle) do
        local color = GetColor(pixel(), sourceColorMode, sourcePalette)

        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            GetColorValue(color, colorMode))
    end

    return imagePart
end

local function GetImagePart(image, rectangle)
    local imagePart = Image(rectangle.width, rectangle.height, image.colorMode)

    for pixel in image:pixels(rectangle) do
        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            pixel())
    end

    return imagePart
end

local function GetSliceParts(slice, targetSprite)
    local sourceSprite = slice.sprite

    -- Get just the slice image
    local sliceImage = GetImagePartInColorMode(sourceSprite, slice.bounds,
                                               targetSprite.colorMode)

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

local function GetCenterBounds(parts, bounds)
    return Rectangle( --
    parts.topLeft.width, --
    parts.topLeft.height, --
    bounds.width - parts.topLeft.width - parts.topRight.width, --
    bounds.height - parts.topLeft.height - parts.bottomLeft.height --
    )
end

local function GetFrameImageStretched(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

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

local function GetCenterImageStretched(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

    DrawImageResized(parts.middleCenter, image, image.bounds)

    return image
end

local function GetFrameImageTiled(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

    local function DrawTiledLeft(frameBounds, part)
        local stop = frameBounds.x + frameBounds.width / 2
        local middle = (frameBounds.width / 2) % part.width

        local x = frameBounds.x

        while x + part.width < stop do
            image:drawImage(part, Point(x, frameBounds.y))
            x = x + part.width
        end

        local partial = Image(part, Rectangle(0, 0, middle, part.height))
        image:drawImage(partial, Point(x, frameBounds.y))
    end

    local function DrawTiledRight(frameBounds, part)
        local stop = frameBounds.x + frameBounds.width / 2
        local middle = (frameBounds.width / 2) % part.width

        local x = frameBounds.x + frameBounds.width

        while x - part.width > stop do
            x = x - part.width
            image:drawImage(part, Point(x, frameBounds.y))
        end

        x = x - middle
        local partial = Image(part, Rectangle(0, 0, middle, part.height))
        image:drawImage(partial, Point(x, frameBounds.y))
    end

    local function DrawTiledTop(frameBounds, part)
        local stop = frameBounds.y + frameBounds.height / 2
        local middle = (frameBounds.height / 2) % part.height

        local y = frameBounds.y

        while y + part.height < stop do
            image:drawImage(part, Point(frameBounds.x, y))
            y = y + part.height
        end

        local partial = Image(part, Rectangle(0, 0, part.width, middle))
        image:drawImage(partial, Point(frameBounds.x, y))
    end

    local function DrawTiledBottom(frameBounds, part)
        local stop = frameBounds.y + frameBounds.height / 2
        local middle = (frameBounds.height / 2) % part.height

        local y = frameBounds.y + frameBounds.height

        while y - part.height > stop do
            y = y - part.height
            image:drawImage(part, Point(frameBounds.x, y))
        end

        y = y - middle
        local partial = Image(part, Rectangle(0, 0, part.width, middle))
        image:drawImage(partial, Point(frameBounds.x, y))
    end

    local topBounds = Rectangle(parts.topLeft.width, 0, image.width -
                                    parts.topLeft.width - parts.topRight.width,
                                parts.topCenter.height)

    DrawTiledLeft(topBounds, parts.topCenter)
    DrawTiledRight(topBounds, parts.topCenter)

    local bottomBounds = Rectangle(parts.topLeft.width,
                                   image.height - parts.bottomCenter.height,
                                   image.width - parts.topLeft.width -
                                       parts.topRight.width,
                                   parts.bottomCenter.height)

    DrawTiledLeft(bottomBounds, parts.bottomCenter)
    DrawTiledRight(bottomBounds, parts.bottomCenter)

    local leftBounds = Rectangle(0, parts.topLeft.height,
                                 parts.middleLeft.width, image.height -
                                     parts.topLeft.height -
                                     parts.bottomLeft.height)

    DrawTiledTop(leftBounds, parts.middleLeft)
    DrawTiledBottom(leftBounds, parts.middleLeft)

    local rightBounds = Rectangle(image.width - parts.topRight.width,
                                  parts.topRight.height,
                                  parts.middleRight.width, image.height -
                                      parts.topRight.height -
                                      parts.bottomRight.height)

    DrawTiledTop(rightBounds, parts.middleRight)
    DrawTiledBottom(rightBounds, parts.middleRight)

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

local function GetCenterImageTiled(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

    local x = 0
    while x < image.width do
        local y = 0
        while y < image.height do
            image:drawImage(parts.middleCenter, Point(x, y))

            y = y + parts.middleCenter.height
        end

        x = x + parts.middleCenter.width
    end

    return image
end

local function GetFrameImageCentered(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

    local function DrawCenteredHorizontally(frameBounds, part)
        local topX = frameBounds.x + frameBounds.width / 2 - part.width / 2
        image:drawImage(part, Point(topX, frameBounds.y))

        for y = 0, part.height - 1 do
            local leftPixel = part:getPixel(0, y)
            for x = frameBounds.x, topX - 1 do
                image:drawPixel(x, frameBounds.y + y, leftPixel)
            end

            local rightPixel = part:getPixel(part.width - 1, y)
            for x = topX + part.width, frameBounds.x + frameBounds.width - 1 do
                image:drawPixel(x, frameBounds.y + y, rightPixel)
            end
        end
    end

    local function DrawCenteredVertically(frameBounds, part)
        local topY = frameBounds.y + frameBounds.height / 2 - part.height / 2
        image:drawImage(part, Point(frameBounds.x, topY))

        for x = 0, part.width - 1 do
            local topPixel = part:getPixel(x, 0)
            for y = frameBounds.y, topY - 1 do
                image:drawPixel(frameBounds.x + x, y, topPixel)
            end

            local bottomPixel = part:getPixel(x, part.height - 1)
            for y = topY + part.height, frameBounds.y + frameBounds.height - 1 do
                image:drawPixel(frameBounds.x + x, y, bottomPixel)
            end
        end
    end

    -- Top
    DrawCenteredHorizontally(Rectangle(parts.topLeft.width, 0, bounds.width -
                                           parts.topLeft.width -
                                           parts.topRight.width,
                                       parts.topCenter.height), parts.topCenter)

    -- Bottom
    DrawCenteredHorizontally(Rectangle(parts.topLeft.width, bounds.height -
                                           parts.bottomCenter.height,
                                       bounds.width - parts.topLeft.width -
                                           parts.topRight.width,
                                       parts.bottomCenter.height),
                             parts.bottomCenter)

    -- Left
    DrawCenteredVertically(Rectangle(0, parts.topLeft.height,
                                     parts.middleLeft.width, bounds.height -
                                         parts.topLeft.height -
                                         parts.bottomLeft.height),
                           parts.middleLeft)

    -- Right
    DrawCenteredVertically(Rectangle(bounds.width - parts.topRight.width,
                                     parts.topRight.height,
                                     parts.middleRight.width, bounds.height -
                                         parts.topRight.height -
                                         parts.bottomRight.height),
                           parts.middleRight)

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

local function GetCenterImageCentered(parts, bounds, colorMode)
    local image = Image(bounds.width, bounds.height, colorMode)

    local cx = image.width / 2 - parts.middleCenter.width / 2
    local cy = image.height / 2 - parts.middleCenter.height / 2

    for x = 0, image.width do
        for y = 0, image.height do
            local lx = math.max(math.min(x - cx, parts.middleCenter.width - 1),
                                0)
            local ly = math.max(math.min(y - cy, parts.middleCenter.height - 1),
                                0)
            local pixel = parts.middleCenter:getPixel(lx, ly)
            image:drawPixel(x, y, pixel)
        end
    end

    return image
end

local function GetFrameImage(parts, bounds, tileMode, colorMode)
    if tileMode == DrawMode.Stretch then
        return GetFrameImageStretched(parts, bounds, colorMode)
    elseif tileMode == DrawMode.Repeat then
        return GetFrameImageTiled(parts, bounds, colorMode)
    elseif tileMode == DrawMode.Center then
        return GetFrameImageCentered(parts, bounds, colorMode)
    end
end

local function GetCenterImage(parts, bounds, tileMode, colorMode)
    if tileMode == DrawMode.Stretch then
        return GetCenterImageStretched(parts, bounds, colorMode)
    elseif tileMode == DrawMode.Repeat then
        return GetCenterImageTiled(parts, bounds, colorMode)
    elseif tileMode == DrawMode.Center then
        return GetCenterImageCentered(parts, bounds, colorMode)
    else
        return Image(0, 0, colorMode)
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

local function MergeImages(imageA, positionA, imageB, positionB, colorMode)
    local minX = math.min(positionA.x, positionB.x)
    local minY = math.min(positionA.y, positionB.y)

    local maxX =
        math.max(positionA.x + imageA.width, positionB.x + imageB.width)
    local maxY = math.max(positionA.y + imageA.height,
                          positionB.y + imageB.height)

    local newImage = Image(maxX - minX, maxY - minY, colorMode)
    local newPosition = Point(minX, minY)

    newImage:drawImage(imageA, Point(positionA.x - minX, positionA.y - minY))
    newImage:drawImage(imageB, Point(positionB.x - minX, positionB.y - minY))

    return newImage, newPosition
end

local function PasteSlice(sprite, cel, slice, selection, selectionMode,
                          frameDrawMode, centerDrawMode)
    local sliceParts = GetSliceParts(slice, sprite)

    if selectionMode == SelectionMode.Frame then
        selection = Rectangle(selection.x - sliceParts.topLeft.width,
                              selection.y - sliceParts.topLeft.height,
                              selection.width + sliceParts.topLeft.width +
                                  sliceParts.topRight.width, selection.height +
                                  sliceParts.topLeft.height +
                                  sliceParts.bottomRight.height)
    end

    local frameImage = GetFrameImage(sliceParts, selection, frameDrawMode,
                                     sprite.colorMode)

    local center = GetCenterBounds(sliceParts, selection)
    local centerImage = GetCenterImage(sliceParts, center, centerDrawMode,
                                       sprite.colorMode)

    frameImage:drawImage(centerImage, Point(center.x, center.y))

    if cel == nil then
        app.activeSprite:newCel(app.activeLayer, app.activeFrame, frameImage,
                                Point(selection.x, selection.y))
    else
        cel.image, cel.position = MergeImages(cel.image, cel.position,
                                              frameImage, selection,
                                              sprite.colorMode)
    end
end

local function PasteSliceDialog(options)
    local dialog
    dialog = Dialog {
        title = "Paste Slice",
        onclose = function() options.onclose(dialog.data) end
    }
    local slices, sliceNames = GetSlices()

    dialog --
    :combobox{
        id = "selected-slice",
        label = "Slice:",
        option = options.selectedSlice or sliceNames[1],
        options = sliceNames
    } --
    :separator{text = "Options"} --
    :combobox{
        id = "selection-mode",
        label = "Selection:",
        options = {SelectionMode.Fill, SelectionMode.Frame},
        option = options.selectionMode or SelectionMode.Fill
    } --
    :combobox{
        id = "frame-draw-mode",
        label = "Frame:",
        options = {DrawMode.Stretch, DrawMode.Repeat, DrawMode.Center},
        option = options.frameDrawMode or DrawMode.Stretch
    } ---
    :combobox{
        id = "center-draw-mode",
        label = "Center:",
        enabled = not options.isFrame,
        options = {
            DrawMode.Stretch, DrawMode.Repeat, DrawMode.Center, DrawMode.Skip
        },
        option = options.centerDrawMode or DrawMode.Stretch
    } --
    :separator() --
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

            local sprite = app.activeSprite
            local cel = app.activeCel
            local selection = app.activeSprite.selection.bounds
            local selectionMode = dialog.data["selection-mode"]
            local frameDrawMode = dialog.data["frame-draw-mode"]
            local centerDrawMode = dialog.data["center-draw-mode"]

            app.transaction(function()
                PasteSlice(sprite, cel, selectedSlice, selection, selectionMode,
                           frameDrawMode, centerDrawMode)
            end)

            app.refresh()
            dialog:close()
        end
    } --
    :button{text = "Cancel"}

    return dialog
end

function init(plugin)
    local session = {}

    plugin:newCommand{
        id = "PasteSlice",
        title = "Paste Slice",
        group = "edit_paste_special_new",
        onenabled = function()
            if app.activeSprite == nil then return false end

            for _, sprite in ipairs(app.sprites) do
                if #sprite.slices > 0 then return true end
            end

            return false
        end,
        onclick = function()
            local dialog = PasteSliceDialog {
                selectedSlice = session.selectedSlice,
                frameDrawMode = session.frameDrawMode,
                centerDrawMode = session.centerDrawMode,
                selectionMode = session.selectionMode,
                onclose = function(data)
                    session.selectedSlice = data["selected-slice"]
                    session.frameDrawMode = data["frame-draw-mode"]
                    session.centerDrawMode = data["center-draw-mode"]
                    session.selectionMode = data["selection-mode"]
                end
            }
            dialog:show()
        end
    }
end

function exit(plugin) end
