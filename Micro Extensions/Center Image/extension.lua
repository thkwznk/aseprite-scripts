local function FindCenterMass(collection, startIndex, endIndex)
    local totalMass = 0
    local total = 0

    for i = startIndex, endIndex do
        local c = collection[i]
        if c then
            totalMass = totalMass + c
            total = total + (c * i)
        end
    end

    return total / totalMass
end

local function GetImageCenter(image, options)
    local width, height, getPixel = image.width, image.height, image.getPixel
    local centerX, centerY = 0, 0

    if options.weighted then
        local rows, columns = {}, {}
        -- Rows need to be initialized beforehand
        for y = 0, height do rows[y] = 0 end

        for x = 0, width - 1 do
            local xx = 0
            for y = 0, height - 1 do
                if getPixel(image, x, y) > 0 then
                    rows[y] = rows[y] + 1
                    xx = xx + 1
                end
            end

            columns[x] = xx
        end

        centerX = FindCenterMass(columns, 0, width - 1)
        centerY = FindCenterMass(rows, 0, height - 1)
    else
        centerX = math.floor(width / 2) - 1
        centerY = math.floor(height / 2) - 1
    end

    return Point(centerX, centerY)
end

local function GetSelectedImageBounds(cel, selection)
    local bounds = Rectangle(selection.bounds)

    if selection.isEmpty then
        bounds = Rectangle(0, 0, cel.sprite.width, cel.sprite.height)
    end

    bounds.x = bounds.x - cel.bounds.x
    bounds.y = bounds.y - cel.bounds.y

    return bounds
end

local function FindFirstAndLastIndex(table, start, stop)
    local min, max
    for i = start, stop do
        if table[i] and table[i] > 0 then
            if min == nil then
                min = i
            else
                max = i
            end
        end
    end
    return min, max
end

local function GetContentCenter(image, options)
    local bgColorValue =
        options.ignoreBackgroundColor and app.bgColor.rgbaPixel or 0

    local hasAlpha = false

    -- Keep references to these to save time on indexing
    local insert = table.insert
    local getPixel, width, height = image.getPixel, image.width, image.height

    local rows, columns, pixels = {}, {}, {}
    -- Rows need to be initialized beforehand
    for y = 0, height - 1 do rows[y] = 0 end

    -- Using xy coordinates and getPixel is a bit faster than :pixels
    for x = 0, width - 1 do
        local xx = 0

        for y = 0, height - 1 do
            local value = getPixel(image, x, y)

            if value == 0 then
                hasAlpha = true
            elseif value ~= bgColorValue then
                insert(pixels, {x = x, y = y, value = value})

                rows[y] = rows[y] + 1
                xx = xx + 1
            end
        end

        columns[x] = xx
    end

    local centerX = 0
    local centerY = 0

    if options.weighted then
        centerX = FindCenterMass(columns, 0, width - 1)
        centerY = FindCenterMass(rows, 0, height - 1)
    else
        local minX, maxX = FindFirstAndLastIndex(columns, 0, width - 1)
        local minY, maxY = FindFirstAndLastIndex(rows, 0, height - 1)
        local w = maxX - minX + 1
        local h = maxY - minY + 1
        centerX = minX + math.floor(w / 2) - 1
        centerY = minY + math.floor(h / 2) - 1
    end

    return Point(centerX, centerY), pixels, hasAlpha
end

local function GetSelectedContentCenter(cel, selection, options)
    local imagePartBounds = GetSelectedImageBounds(cel, selection)
    local imagePart = Image(cel.image, imagePartBounds)

    -- Calculate selected content bounds
    local shrunkImagePartBounds = imagePart:shrinkBounds()
    if shrunkImagePartBounds.x > 0 --
    or shrunkImagePartBounds.y > 0 --
    or shrunkImagePartBounds.width < imagePartBounds.width --
    or shrunkImagePartBounds.height < imagePartBounds.height then
        imagePart = Image(imagePart, shrunkImagePartBounds)
    end

    local center, pixels, hasAlpha = GetContentCenter(imagePart, options)

    -- Map coordinates to the plane of the entire image
    for _, pixel in ipairs(pixels) do
        pixel.x = pixel.x + shrunkImagePartBounds.x + imagePartBounds.x
        pixel.y = pixel.y + shrunkImagePartBounds.y + imagePartBounds.y
    end

    return (center + shrunkImagePartBounds.origin + imagePartBounds.origin),
           pixels, hasAlpha
end

local function GetSelectionCenter(sprite, options)
    local selection = sprite.selection
    if selection.isEmpty then
        return Point(math.floor(sprite.width / 2) - 1,
                     math.floor(sprite.height / 2) - 1)
    end

    local bounds = selection.bounds
    local centerX, centerY = 0, 0

    if options.weightedSelectionCenter then
        local rows, columns = {}, {}

        local contains = selection.contains
        local xStart, xEnd, yStart, yEnd = bounds.x,
                                           bounds.x + bounds.width - 1,
                                           bounds.y,
                                           bounds.y + bounds.height - 1

        -- Rows need to be initialized beforehand
        for y = yStart, yEnd do rows[y] = 0 end

        for x = xStart, xEnd do
            local xx = 0
            for y = yStart, yEnd do
                if contains(selection, x, y) then
                    rows[y] = rows[y] + 1
                    xx = xx + 1
                end
            end

            columns[x] = xx
        end

        centerX = FindCenterMass(columns, xStart, xEnd)
        centerY = FindCenterMass(rows, yStart, yEnd)
    else
        centerX = bounds.x + math.floor(bounds.width / 2) - 1
        centerY = bounds.y + math.floor(bounds.height / 2) - 1
    end

    return Point(centerX, centerY)
end

local function CenterPart(cel, options, sprite)
    local selection = sprite.selection
    local center, pixels, hasAlpha = GetSelectedContentCenter(cel, selection,
                                                              options)

    if #pixels == 0 then return end

    local selectionCenter = GetSelectionCenter(sprite, options)
    local shiftX, shiftY = 0, 0

    if options.xAxis then
        shiftX = (selectionCenter.x - cel.position.x) - center.x
    end
    if options.yAxis then
        shiftY = (selectionCenter.y - cel.position.y) - center.y
    end

    print("center", center)
    print("selectionCenter", selectionCenter)
    print("shiftX, shiftY", shiftX, shiftY)
    print("---")

    -- Expand the image
    local cx, cy = cel.position.x, cel.position.y
    local iw, ih = cel.image.width, cel.image.height
    local left, right, up, down = 0, 0, 0, 0

    local InSelection = function(x, y)
        return selection.isEmpty or selection:contains(cx + x, cy + y)
    end

    local CanBeMoved = function(x, y)
        return (options.cut and InSelection(x, y)) or options.moveOutside
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

    print("left, right, up, down", left, right, up, down)
    print("===")

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

    local drawPixel = cel.image.drawPixel

    -- Clear pixels
    -- Use the mask color if at least one pixel in the selection is empty
    local bgColorValue = app.bgColor.rgbaPixel
    if hasAlpha then bgColorValue = 0 end

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

    -- Trim the image at the end
    if left > 0 or right > 0 or up > 0 or down > 0 then
        local shrunkBounds = newImage:shrinkBounds()
        newImage = Image(newImage, shrunkBounds)
        cx = cx + shrunkBounds.x
        cy = cy + shrunkBounds.y
    end

    -- Replace the image with the new one
    cel.image = newImage
    cel.position = Point(cx, cy)
end

local function IsWhollyWithin(boundsA, boundsB)
    return boundsA ~= boundsB and boundsB:contains(boundsA)
end

local function CenterCel(cel, options, sprite)
    local x, y = cel.bounds.x, cel.bounds.y

    local center = GetSelectionCenter(sprite, options)
    local imageCenter = GetImageCenter(cel.image, options)

    if options.xAxis then x = center.x - imageCenter.x end
    if options.yAxis then y = center.y - imageCenter.y end

    cel.position = Point(x, y)

    local selection = sprite.selection
    if options.cut -- 
    and not selection.isEmpty --
    and not IsWhollyWithin(cel.bounds, selection.bounds) then
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

local function JoinStrings(strings, separator)
    local result = ""
    for i, s in ipairs(strings) do
        result = result .. s
        if i < #strings then result = result .. separator end
    end
    return result
end

local function GetOptionsTooltip(options)
    local optionNames = {}

    if options.weighted then table.insert(optionNames, "weighted") end

    if options.ignoreBackgroundColor then
        table.insert(optionNames, "ignored Background Color")
    end

    if #optionNames == 0 then return "" end

    return "(" .. JoinStrings(optionNames, ", ") .. ")"
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
                local centerWhole = selection.isEmpty or
                                        IsWhollyWithin(cel.bounds,
                                                       selection.bounds)

                local selectionOutsideOfImage =
                    not selection.isEmpty and
                        not cel.bounds:intersects(selection.bounds)

                if selectionOutsideOfImage then
                    -- If the cel is fully outside of these selection, do nothing
                elseif centerWhole and not options.ignoreBackgroundColor then
                    CenterCel(cel, options, sprite)
                else
                    CenterPart(cel, options, sprite)
                end
            end
        end
    end)

    if app.apiVersion >= 35 then
        local tooltip = "Image centered"
        local optionsTooltip = GetOptionsTooltip(options)
        if optionsTooltip then tooltip = tooltip .. " " .. optionsTooltip end

        app.tip(tooltip)
    end

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
