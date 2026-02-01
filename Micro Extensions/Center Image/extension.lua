local function GetContentCenter(cel, selection, options)
    local imageSelection = Rectangle(selection.bounds.x - cel.bounds.x,
                                     selection.bounds.y - cel.bounds.y,
                                     selection.bounds.width,
                                     selection.bounds.height)

    -- Calculate selection content bounds
    local minX, maxX, minY, maxY = math.maxinteger, math.mininteger,
                                   math.maxinteger, math.mininteger

    local bgColorValue =
        options.ignoreBackgroundColor and app.bgColor.rgbaPixel or 0

    local rows, columns, pixels = {}, {}, {}
    local total = 0
    local hasAlpha = false

    for pixel in cel.image:pixels(imageSelection) do
        local x, y, value = pixel.x, pixel.y, pixel()
        local inSelection = selection:contains(x + cel.bounds.x,
                                               y + cel.bounds.y)

        if value == 0 and inSelection then hasAlpha = true end

        if value > 0 and value ~= bgColorValue and inSelection then
            minX = math.min(minX, x)
            maxX = math.max(maxX, x)

            minY = math.min(minY, y)
            maxY = math.max(maxY, y)

            table.insert(pixels, {x = x, y = y, value = value})

            rows[y] = (rows[y] or 0) + 1
            columns[x] = (columns[x] or 0) + 1
            total = total + 1
        end
    end

    local centerX = minX + (maxX - minX + 1) / 2
    local centerY = minY + (maxY - minY + 1) / 2

    -- TODO: Test these calculations, they seem to be off by a single pixel

    if options.weighted then
        local centerValue = total / 2
        local rowsTotal, columnsTotal = 0, 0

        for y = imageSelection.y, imageSelection.y + imageSelection.height - 1 do
            if rows[y] then
                rowsTotal = rowsTotal + rows[y]
                if rowsTotal >= centerValue then
                    centerY = y - 1
                    break
                end
            end
        end

        for x = imageSelection.x, imageSelection.x + imageSelection.width - 1 do
            if columns[x] then
                columnsTotal = columnsTotal + columns[x]
                if columnsTotal >= centerValue then
                    centerX = x - 1
                    break
                end
            end
        end
    end

    return Point(centerX, centerY), pixels, hasAlpha
end

local function FindFirstGreaterOrEqual(collection, value)
    for i = 1, #collection do if collection[i] >= value then return i end end
end

local function GetSelectionCenter(selection, options)
    local bounds = selection.bounds
    local centerX, centerY = math.floor(bounds.width / 2),
                             math.floor(bounds.height / 2)

    if options.weightedSelectionCenter then
        local count = 0
        local rows, columns = {}, {}

        for x = bounds.x, bounds.x + bounds.width - 1 do
            for y = bounds.y, bounds.y + bounds.height - 1 do
                if selection:contains(x, y) then
                    count = count + 1
                end
            end

            table.insert(columns, count)
        end

        local centerValue = count / 2
        centerX = FindFirstGreaterOrEqual(columns, centerValue) - 1

        count = 0

        for y = bounds.y, bounds.y + bounds.height - 1 do
            for x = bounds.x, bounds.x + bounds.width - 1 do
                if selection:contains(x, y) then
                    count = count + 1
                end
            end

            table.insert(rows, count)
        end

        centerY = FindFirstGreaterOrEqual(rows, centerValue) - 1
    end

    return Point(bounds.x + centerX, bounds.y + centerY)
end

local function CenterSelection(cel, options, sprite)
    local selection = sprite.selection

    local imagePartBounds = Rectangle(selection.bounds)
    imagePartBounds.x = imagePartBounds.x - cel.bounds.x
    imagePartBounds.y = imagePartBounds.y - cel.bounds.y

    local drawPixel = cel.image.drawPixel
    local bgColorValue = app.bgColor.rgbaPixel

    local center, pixels, hasAlpha = GetContentCenter(cel, selection, options)

    -- Use the mask color if at least one pixel in the selection is empty
    if hasAlpha then bgColorValue = 0 end

    local selectionCenter = GetSelectionCenter(selection, options)
    local shiftX, shiftY = 0, 0

    if options.xAxis then
        shiftX = (selectionCenter.x - cel.position.x) - center.x
    end
    if options.yAxis then
        shiftY = (selectionCenter.y - cel.position.y) - center.y
    end

    -- Expand the image
    local cx, cy = cel.position.x, cel.position.y
    local iw, ih = cel.image.width, cel.image.height
    local left, right, up, down = 0, 0, 0, 0

    local CanBeMoved = function(x, y)
        return (options.cut and selection:contains(cx + x, cy + y)) or
                   options.moveOutside
    end

    for _, pixel in ipairs(pixels) do
        local x, y = pixel.x, pixel.y

        if options.xAxis then x = x + shiftX end
        if options.yAxis then y = y + shiftY end

        if CanBeMoved(x, y) then
            if x < 0 then left = math.max(math.abs(x), left) end
            if y < 0 then up = math.max(math.abs(y), up) end
            if x >= iw then right = math.max(x - iw + 1, right) end
            if y >= ih then down = math.max(y - ih + 1, down) end
        end
    end

    local newImage
    if left > 0 or right > 0 or up > 0 or down > 0 then
        cx = cx - left
        cy = cy - up

        local resizedImage = Image(iw + left + right, ih + up + down,
                                   cel.image.colorMode)
        resizedImage:drawImage(cel.image, Point(left, up))
        newImage = resizedImage
    else
        newImage = Image(cel.image)
    end

    -- Clear pixels
    for _, pixel in ipairs(pixels) do
        drawPixel(newImage, pixel.x + left, pixel.y + up, bgColorValue)
    end

    -- Draw pixels in their new positions
    for _, pixel in ipairs(pixels) do
        local x, y = pixel.x + left, pixel.y + up

        if options.xAxis then x = x + shiftX end
        if options.yAxis then y = y + shiftY end

        if CanBeMoved(x, y) then drawPixel(newImage, x, y, pixel.value) end
    end

    -- Replace the image with the new one
    cel.image = newImage
    cel.position = Point(cx, cy)
end

local function GetImageCenter(image, options)
    local getPixel = image.getPixel
    local centerX = 0

    if options.weighted then
        local total = 0
        local columns = {}

        for x = 0, image.width do
            for y = 0, image.height do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(columns, total)
        end

        local centerValue = total / 2
        centerX = FindFirstGreaterOrEqual(columns, centerValue) - 1
    else
        centerX = math.floor(image.width / 2)
    end

    local centerY = 0

    if options.weighted then
        local total = 0
        local rows = {}

        for y = 0, image.height do
            for x = 0, image.width do
                if getPixel(image, x, y) > 0 then
                    total = total + 1
                end
            end

            table.insert(rows, total)
        end

        local centerValue = total / 2
        centerY = FindFirstGreaterOrEqual(rows, centerValue) - 1
    else
        centerY = math.floor(image.height / 2)
    end

    return Point(centerX, centerY)
end

local function GetCanvasCenter(sprite)
    return Point(math.floor(sprite.width / 2), math.floor(sprite.height / 2))
end

local function IsWhollyWithin(boundsA, boundsB)
    return boundsA ~= boundsB and boundsB:contains(boundsA)
end

local function CenterCel(cel, options, sprite)
    local selection = sprite.selection
    local x, y = cel.bounds.x, cel.bounds.y

    local center = selection.isEmpty and GetCanvasCenter(sprite) or
                       GetSelectionCenter(selection, options)

    local imageCenter = GetImageCenter(cel.image, options)

    if options.xAxis then x = center.x - imageCenter.x end
    if options.yAxis then y = center.y - imageCenter.y end

    cel.position = Point(x, y)

    if options.cut and not IsWhollyWithin(cel.bounds, selection.bounds) then
        local common = cel.bounds:intersect(selection.bounds)
        local imagePart = Rectangle(common)
        imagePart.x = imagePart.x - cel.bounds.x
        imagePart.y = imagePart.y - cel.bounds.y

        cel.image = Image(cel.image, imagePart)
        cel.position = Point(common.x, common.y)
    end
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

    app.transaction("Center", function()
        local sprite = app.activeSprite
        local selection = sprite.selection

        for _, cel in ipairs(app.range.cels) do
            if cel.layer.isEditable then
                if (selection.isEmpty or
                    IsWhollyWithin(cel.bounds, selection.bounds)) and
                    not options.ignoreBackgroundColor then
                    CenterCel(cel, options, sprite)
                else
                    CenterSelection(cel, options, sprite)
                end
            end
        end
    end)

    if app.apiVersion >= 35 then app.tip("Image centered") end

    app.refresh()
end

function init(plugin)
    local preferences = plugin.preferences

    -- Set defaults preferences
    if preferences.cut == nil and preferences.moveOutside == nil then
        preferences.moveOutside = true
    end

    local function CenterOptions(options)
        return {
            xAxis = options.xAxis or false,
            yAxis = options.yAxis or false,
            weighted = options.weighted or false,
            weightedSelectionCenter = preferences.weightedSelectionCenter,
            ignoreBackgroundColor = preferences.ignoreBackgroundColor,
            cut = preferences.cut,
            moveOutside = preferences.moveOutside
        }
    end

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
            local options = CenterOptions {xAxis = true, yAxis = true}
            CenterImageInActiveSprite(options)
        end
    }

    plugin:newCommand{
        id = "CenterX",
        title = "Center X",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            local options = CenterOptions {xAxis = true}
            CenterImageInActiveSprite(options)
        end
    }

    plugin:newCommand{
        id = "CenterY",
        title = "Center Y",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            local options = CenterOptions {yAxis = true}
            CenterImageInActiveSprite(options)
        end
    }

    if app.apiVersion >= 22 then plugin:newMenuSeparator{group = parentGroup} end

    plugin:newCommand{
        id = "CenterWeighted",
        title = "Center (Weighted)",
        group = parentGroup,
        onenabled = CanCenterImage,
        onclick = function()
            local options = CenterOptions {
                xAxis = true,
                yAxis = true,
                weighted = true
            }
            CenterImageInActiveSprite(options)
        end
    }

    plugin:newCommand{
        id = "CenterXWeighted",
        title = "Center X (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            local options = CenterOptions {xAxis = true, weighted = true}
            CenterImageInActiveSprite(options)
        end
    }

    plugin:newCommand{
        id = "CenterYWeighted",
        title = "Center Y (Weighted)",
        group = app.apiVersion >= 22 and parentGroup or nil,
        onenabled = CanCenterImage,
        onclick = function()
            local options = CenterOptions {yAxis = true, weighted = true}
            CenterImageInActiveSprite(options)
        end
    }

    if app.apiVersion >= 35 then
        plugin:newMenuSeparator{group = parentGroup}

        plugin:newMenuGroup{
            id = "center_options",
            title = "Options",
            group = parentGroup
        }

        plugin:newCommand{
            id = "EnableCenterCut",
            title = "Cut Pixels Outside Selection",
            group = "center_options",
            onchecked = function() return preferences.cut end,
            onclick = function()
                preferences.cut = true
                preferences.moveOutside = false
            end
        }

        plugin:newCommand{
            id = "EnableCenterMoveOutside",
            title = "Move Pixels Outside Selection",
            group = "center_options",
            onchecked = function() return preferences.moveOutside end,
            onclick = function()
                preferences.cut = false
                preferences.moveOutside = true
            end
        }

        plugin:newMenuSeparator{group = "center_options"}

        plugin:newCommand{
            id = "WeightedSelectionCenterToggle",
            title = "Use Weighted Selection Center",
            group = "center_options",
            onchecked = function()
                return preferences.weightedSelectionCenter
            end,
            onclick = function()
                preferences.weightedSelectionCenter =
                    not preferences.weightedSelectionCenter
            end
        }

        plugin:newMenuSeparator{group = "center_options"}

        plugin:newCommand{
            id = "IgnoreBackgroundColorToggle",
            title = "Ignore Background Color",
            group = "center_options",
            onchecked = function()
                return preferences.ignoreBackgroundColor
            end,
            onclick = function()
                preferences.ignoreBackgroundColor =
                    not preferences.ignoreBackgroundColor
            end
        }
    end
end

function exit(plugin) end
