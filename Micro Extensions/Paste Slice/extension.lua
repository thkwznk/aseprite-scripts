local GetImagePart = function(image, rectangle)
    local imagePart = Image(rectangle.width, rectangle.height)

    for pixel in image:pixels(rectangle) do
        imagePart:drawPixel(pixel.x - rectangle.x, pixel.y - rectangle.y,
                            pixel())
    end

    return imagePart
end

local GetSliceImage = function(slice)
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

    -- local sliceImage = Image(slice.bounds.width, slice.bounds.height)

    -- for x = 0, slice.bounds.width - 1 do
    --     for y = 0, slice.bounds.height - 1 do
    --         sliceImage:drawPixel(x, y, spriteImage:getPixel(x + slice.bounds.x,
    --                                                         y + slice.bounds.y))
    --     end
    -- end

    -- return sliceImage
end

local DrawImageResized = function(sourceImage, targetImage, targetBounds)
    for x = 0, targetBounds.width - 1 do
        for y = 0, targetBounds.height - 1 do
            -- TODO: Cache these for better performance
            local sourceX = (x / (targetBounds.width - 1)) *
                                (sourceImage.width - 1)
            local sourceY = (y / (targetBounds.height - 1)) *
                                (sourceImage.height - 1)

            local pixelValue = sourceImage:getPixel(sourceX, sourceY)

            local targetX = targetBounds.x + x
            local targetY = targetBounds.y + y

            targetImage:drawPixel(targetX, targetY, pixelValue)
        end
    end
end

local GetSlices = function()
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

local PasteSliceDialog = function(options)
    local sprite = app.activeSprite
    local dialog = Dialog("Paste Slice")

    local slices, sliceNames = GetSlices()

    dialog --
    :combobox{
        id = "selected-slice",
        option = sliceNames[1],
        options = sliceNames
    } --
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

            local sliceImages = GetSliceImage(selectedSlice)

            local cel = app.activeCel

            -- Copy the selection bounds and convert the position to the cel's space
            local selection = Rectangle(app.activeSprite.selection.bounds)
            selection.x = selection.x - cel.position.x
            selection.y = selection.y - cel.position.y

            -- TODO: In the future, create the result slice in a separate image and only after that merge

            local leftX = selection.x
            local centerX = selection.x + sliceImages.topLeft.width
            local rightX = selection.x + selection.width -
                               sliceImages.topRight.width

            local topY = selection.y
            local middleY = selection.y + sliceImages.topLeft.height
            local bottomY = selection.y + selection.height -
                                sliceImages.bottomLeft.height

            -- Draw all corners
            cel.image:drawImage(sliceImages.topLeft, Point(leftX, topY))
            cel.image:drawImage(sliceImages.topRight, Point(rightX, topY))
            cel.image:drawImage(sliceImages.bottomLeft, Point(leftX, bottomY))
            cel.image:drawImage(sliceImages.bottomRight, Point(rightX, bottomY))

            DrawImageResized(sliceImages.topCenter, cel.image,
                             Rectangle(centerX, topY,
                                       selection.width -
                                           sliceImages.topLeft.width -
                                           sliceImages.topRight.width,
                                       sliceImages.topCenter.height))

            DrawImageResized(sliceImages.bottomCenter, cel.image,
                             Rectangle(centerX, bottomY,
                                       selection.width -
                                           sliceImages.bottomLeft.width -
                                           sliceImages.bottomRight.width,
                                       sliceImages.bottomCenter.height))

            DrawImageResized(sliceImages.middleLeft, cel.image,
                             Rectangle(leftX, middleY,
                                       sliceImages.middleLeft.width,
                                       selection.height -
                                           sliceImages.topLeft.height -
                                           sliceImages.bottomLeft.height))

            DrawImageResized(sliceImages.middleRight, cel.image,
                             Rectangle(rightX, middleY,
                                       sliceImages.middleRight.width,
                                       selection.height -
                                           sliceImages.topRight.height -
                                           sliceImages.bottomRight.height))

            DrawImageResized(sliceImages.middleCenter, cel.image,
                             Rectangle(centerX, middleY,
                                       selection.width -
                                           sliceImages.topLeft.width -
                                           sliceImages.topRight.width,
                                       selection.height -
                                           sliceImages.topRight.height -
                                           sliceImages.bottomRight.height))

            -- TODO: cel might need to be resized, I already have code for this in another extension

            app.refresh()
            dialog:close()
            sprite.selection:deselect()
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

-- TODO: Add a combobox for the Tile Modes - Stretch, Repeat, Mirror
-- TODO: Implement the Repeat Tile Mode
-- TODO: Implement the Mirror Tile Mode
